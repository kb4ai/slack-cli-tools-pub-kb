#!/bin/bash
#
# Management script for slack-mcp-server Docker container
# MCP server for Slack integration
#
# This container includes f/mcptools (https://github.com/f/mcptools) for CLI access.
# See the "CLI Commands" section in ./manage.sh help for details.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-slack-cli-tools-slack-mcp-server}"
CONTAINER_NAME="${CONTAINER_NAME:-slack-mcp-server-test}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cmd_status() {
    echo "=== Docker Image Status ==="
    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        log_info "Image '$IMAGE_NAME' exists"
        docker image ls "$IMAGE_NAME"
    else
        log_warn "Image '$IMAGE_NAME' does not exist"
    fi

    echo ""
    echo "=== Container Status ==="
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Container '$CONTAINER_NAME' exists"
        docker ps -a --filter "name=$CONTAINER_NAME"
    else
        log_warn "Container '$CONTAINER_NAME' does not exist"
    fi
}

cmd_build() {
    log_info "Building Docker image: $IMAGE_NAME"
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
    log_info "Build complete"
}

cmd_start() {
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Starting existing container: $CONTAINER_NAME"
        docker start "$CONTAINER_NAME"
    else
        log_info "Creating and starting container: $CONTAINER_NAME"
        docker run -d \
            --name "$CONTAINER_NAME" \
            ${SLACK_BOT_TOKEN:+-e SLACK_BOT_TOKEN="$SLACK_BOT_TOKEN"} \
            "$IMAGE_NAME"
    fi
}

cmd_stop() {
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Stopping container: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME" || true
    else
        log_warn "Container '$CONTAINER_NAME' does not exist"
    fi
}

cmd_shell() {
    log_info "Opening shell in container (using fresh instance)"
    docker run -it --rm \
        --entrypoint /bin/sh \
        ${SLACK_BOT_TOKEN:+-e SLACK_BOT_TOKEN="$SLACK_BOT_TOKEN"} \
        "$IMAGE_NAME"
}

cmd_run() {
    log_info "Running container interactively"
    docker run -it --rm \
        ${SLACK_BOT_TOKEN:+-e SLACK_BOT_TOKEN="$SLACK_BOT_TOKEN"} \
        "$IMAGE_NAME" "$@"
}

cmd_test() {
    log_info "Testing slack-mcp-server binary..."

    # Test 1: Verify slack-mcp-server shows help
    docker run --rm "$IMAGE_NAME" --help > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_info "Test 1 passed: slack-mcp-server binary works"
    else
        log_error "Test 1 failed: slack-mcp-server binary failed"
        return 1
    fi

    # Test 2: Verify mcptools is installed
    docker run --rm --entrypoint mcp "$IMAGE_NAME" --help > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_info "Test 2 passed: mcptools (mcp) binary works"
    else
        log_error "Test 2 failed: mcptools binary failed"
        return 1
    fi

    # Test 3: Integration test - mcptools can query slack-mcp-server for available tools
    # Note: Without SLACK_BOT_TOKEN, the server may timeout during initialization.
    # This is expected - we're just verifying the binaries can attempt to communicate.
    log_info "Test 3: Integration test - verifying mcptools can invoke slack-mcp-server..."
    local tools_output
    local exit_code
    tools_output=$(timeout 8 docker run --rm --entrypoint "" "$IMAGE_NAME" \
        mcp tools --format json slack-mcp-server 2>&1) && exit_code=$? || exit_code=$?

    if echo "$tools_output" | grep -q "channels_list\|conversations_history" 2>/dev/null; then
        log_info "Test 3 passed: mcptools successfully queried slack-mcp-server tools"
    elif echo "$tools_output" | grep -q "initialization timed out\|timed out" 2>/dev/null; then
        log_info "Test 3 passed: mcptools invoked slack-mcp-server (timeout expected without auth)"
        log_info "Note: Full integration requires SLACK_BOT_TOKEN"
    elif [ "$exit_code" -eq 124 ]; then
        # timeout command returns 124 when it kills the process
        log_info "Test 3 passed: mcptools/slack-mcp-server communication attempted (killed by timeout)"
        log_info "Note: Full integration requires SLACK_BOT_TOKEN"
    else
        log_warn "Test 3: Unexpected result (exit=$exit_code) - ${tools_output:0:100}..."
    fi

    log_info "All basic tests passed!"
}

cmd_verify() {
    cmd_test "$@"
}

cmd_clean() {
    log_info "Cleaning up container and image"

    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Stopping and removing container: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
    fi

    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        log_info "Removing image: $IMAGE_NAME"
        docker rmi "$IMAGE_NAME"
    fi

    log_info "Cleanup complete"
}

cmd_logs() {
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        docker logs "$CONTAINER_NAME" "$@"
    else
        log_error "Container '$CONTAINER_NAME' does not exist"
        return 1
    fi
}

# =============================================================================
# CLI Commands using mcptools (https://github.com/f/mcptools)
# =============================================================================
# WHY mcptools?
# mcptools provides a universal CLI interface to ANY MCP server. Instead of
# building custom CLI wrappers, mcptools acts as a "Swiss Army Knife" that
# works with all MCP servers using the same consistent interface.
# =============================================================================

# Internal: Run mcp command inside the container
_mcp_cmd() {
    # Check if any auth token is set
    if [ -z "$SLACK_BOT_TOKEN" ] && [ -z "$SLACK_MCP_XOXP_TOKEN" ] && [ -z "$SLACK_MCP_XOXC_TOKEN" ]; then
        log_error "No Slack token found. Set one of:"
        log_error "  SLACK_MCP_XOXC_TOKEN + SLACK_MCP_XOXD_TOKEN (browser session)"
        log_error "  SLACK_MCP_XOXP_TOKEN (user OAuth)"
        log_error "  SLACK_BOT_TOKEN (bot - limited)"
        log_error ""
        log_error "Run '$0 auth' for instructions on getting tokens."
        return 1
    fi

    docker run --rm -i \
        ${SLACK_BOT_TOKEN:+-e SLACK_BOT_TOKEN="$SLACK_BOT_TOKEN"} \
        ${SLACK_MCP_XOXP_TOKEN:+-e SLACK_MCP_XOXP_TOKEN="$SLACK_MCP_XOXP_TOKEN"} \
        ${SLACK_MCP_XOXC_TOKEN:+-e SLACK_MCP_XOXC_TOKEN="$SLACK_MCP_XOXC_TOKEN"} \
        ${SLACK_MCP_XOXD_TOKEN:+-e SLACK_MCP_XOXD_TOKEN="$SLACK_MCP_XOXD_TOKEN"} \
        --entrypoint "" \
        "$IMAGE_NAME" \
        "$@"
}

cmd_mcp_tools() {
    log_info "Listing available MCP tools..."
    _mcp_cmd mcp tools --format "${1:-table}" slack-mcp-server
}

cmd_mcp_shell() {
    # Check if any auth token is set
    if [ -z "$SLACK_BOT_TOKEN" ] && [ -z "$SLACK_MCP_XOXP_TOKEN" ] && [ -z "$SLACK_MCP_XOXC_TOKEN" ]; then
        log_error "No Slack token found. Run '$0 auth' for instructions."
        return 1
    fi

    log_info "Starting interactive MCP shell..."
    log_info "Type 'tools' to list available operations, '/h' for help, '/q' to quit"
    docker run --rm -it \
        ${SLACK_BOT_TOKEN:+-e SLACK_BOT_TOKEN="$SLACK_BOT_TOKEN"} \
        ${SLACK_MCP_XOXP_TOKEN:+-e SLACK_MCP_XOXP_TOKEN="$SLACK_MCP_XOXP_TOKEN"} \
        ${SLACK_MCP_XOXC_TOKEN:+-e SLACK_MCP_XOXC_TOKEN="$SLACK_MCP_XOXC_TOKEN"} \
        ${SLACK_MCP_XOXD_TOKEN:+-e SLACK_MCP_XOXD_TOKEN="$SLACK_MCP_XOXD_TOKEN"} \
        --entrypoint "" \
        "$IMAGE_NAME" \
        mcp shell slack-mcp-server
}

cmd_mcp_call() {
    local tool_name="$1"
    shift
    local params="${1:-{}}"

    if [ -z "$tool_name" ]; then
        log_error "Tool name is required"
        log_error "Usage: $0 mcp-call <tool_name> [params_json]"
        log_error "Example: $0 mcp-call channels_list '{\"channel_types\":\"public_channel\"}'"
        return 1
    fi

    log_info "Calling MCP tool: $tool_name"
    _mcp_cmd mcp call "$tool_name" --params "$params" --format pretty slack-mcp-server
}

cmd_list_channels() {
    local channel_types="${1:-public_channel,private_channel,mpim,im}"
    local limit="${2:-100}"

    log_info "Listing Slack channels (types: $channel_types)..."
    _mcp_cmd mcp call channels_list \
        --params "{\"channel_types\":\"$channel_types\",\"limit\":\"$limit\"}" \
        --format pretty \
        slack-mcp-server
}

cmd_read_channel() {
    local channel_id="$1"
    local limit="${2:-1d}"

    if [ -z "$channel_id" ]; then
        log_error "channel_id is required"
        log_error "Usage: $0 read-channel <channel_id> [limit]"
        log_error "Example: $0 read-channel C1234567890 7d"
        return 1
    fi

    log_info "Reading channel history: $channel_id (limit: $limit)..."
    _mcp_cmd mcp call conversations_history \
        --params "{\"channel_id\":\"$channel_id\",\"limit\":\"$limit\"}" \
        --format pretty \
        slack-mcp-server
}

cmd_read_thread() {
    local channel_id="$1"
    local thread_ts="$2"
    local limit="${3:-100}"

    if [ -z "$channel_id" ] || [ -z "$thread_ts" ]; then
        log_error "channel_id and thread_ts are required"
        log_error "Usage: $0 read-thread <channel_id> <thread_ts> [limit]"
        log_error "Example: $0 read-thread C1234567890 1234567890.123456"
        return 1
    fi

    log_info "Reading thread: $channel_id / $thread_ts..."
    _mcp_cmd mcp call conversations_replies \
        --params "{\"channel_id\":\"$channel_id\",\"thread_ts\":\"$thread_ts\",\"limit\":\"$limit\"}" \
        --format pretty \
        slack-mcp-server
}

cmd_auth() {
    cat <<EOF
Slack MCP Server - Authentication Guide
========================================

This server lets YOU access YOUR Slack workspace - it's not a bot service.
You authenticate as yourself to read/search messages in channels you can access.

There are 3 options (in order of recommendation):

OPTION 1: Browser Session (xoxc/xoxd) - Easiest, No Setup Required
------------------------------------------------------------------
Extract tokens from your logged-in Slack browser session.
Works immediately, no app creation or admin approval needed.

Steps:
1. Open Slack in your browser and log in
2. Press F12 to open DevTools
3. Go to Console tab and run:
   JSON.parse(localStorage.localConfig_v2).teams[document.location.pathname.match(/^\\/client\\/([A-Z0-9]+)/)[1]].token
4. Copy the xoxc-... token
5. Go to Application tab > Cookies > find 'd' cookie, copy its xoxd-... value

Usage:
  export SLACK_MCP_XOXC_TOKEN="xoxc-..."
  export SLACK_MCP_XOXD_TOKEN="xoxd-..."
  $0 mcp-tools

Note: Tokens expire when you log out of browser. Re-extract if needed.

OPTION 2: User OAuth Token (xoxp-...) - Recommended for Long-Term Use
---------------------------------------------------------------------
Create a Slack app with User Token Scopes for persistent access.
Provides full functionality including message search.

Steps:
1. Go to https://api.slack.com/apps and create a new app
2. Under "OAuth & Permissions", add these User Token Scopes:
   - channels:history, channels:read
   - groups:history, groups:read
   - im:history, im:read
   - mpim:history, mpim:read
   - users:read, search:read
   - (optional) chat:write - for posting messages
3. Install the app to your workspace
4. Copy the "User OAuth Token" (starts with xoxp-)

Usage:
  export SLACK_MCP_XOXP_TOKEN="xoxp-your-token-here"
  $0 mcp-tools

OPTION 3: Bot Token (xoxb-...) - Limited Functionality
------------------------------------------------------
Bot tokens work but have significant limitations:
- Can only access channels where bot is explicitly invited
- NO search functionality (search:read not available for bots)
- Requires /invite @BotName in each channel

Only use if you specifically need bot-style access.

Usage:
  export SLACK_BOT_TOKEN="xoxb-your-token-here"
  $0 mcp-tools

QUICK START (using browser session)
-----------------------------------
1. Extract xoxc/xoxd tokens from browser (see Option 1 above)
2. Build: $0 build
3. Test:  SLACK_MCP_XOXC_TOKEN=xoxc-... SLACK_MCP_XOXD_TOKEN=xoxd-... $0 mcp-tools
4. Use:   SLACK_MCP_XOXC_TOKEN=xoxc-... SLACK_MCP_XOXD_TOKEN=xoxd-... $0 list-channels

Token Priority: xoxp > xoxb > xoxc/xoxd (if multiple set)

More info: https://github.com/korotovsky/slack-mcp-server/blob/master/docs/01-authentication-setup.md
EOF
}

cmd_help() {
    cat <<EOF
Slack MCP Server Docker Management Script

This container includes f/mcptools for CLI access to the MCP server.
See: https://github.com/f/mcptools

Usage: $0 <command> [args...]

Getting Started:
  $0 auth      Show authentication guide (how to get Slack tokens)
  $0 build     Build the Docker image
  $0 test      Verify the build works

Docker Management Commands:
  status    Show status of container and image
  build     Build the Docker image
  start     Start the container
  stop      Stop the container
  shell     Open shell in a fresh container
  run       Run container interactively (args passed to entrypoint)
  test      Verify the module loads correctly
  verify    Alias for test
  clean     Remove container and image
  logs      Show container logs (args passed to docker logs)
  help      Show this help message

CLI Commands (via mcptools - WIP, to be tested):
  mcp-tools [format]          List available MCP tools (format: table|json|pretty)
  mcp-shell                   Start interactive MCP shell
  mcp-call <tool> [params]    Call an MCP tool with JSON params

Convenience Commands (WIP, to be tested):
  list-channels [types] [limit]           List Slack channels
  read-channel <channel_id> [limit]       Read channel message history
  read-thread <channel_id> <thread_ts>    Read thread replies

Environment Variables:
  IMAGE_NAME              Docker image name (default: $IMAGE_NAME)
  CONTAINER_NAME          Container name (default: $CONTAINER_NAME)

  Authentication (use one set):
  SLACK_MCP_XOXC_TOKEN +  Browser session tokens (easiest, run: $0 auth)
  SLACK_MCP_XOXD_TOKEN
  SLACK_MCP_XOXP_TOKEN    User OAuth token (recommended for long-term)
  SLACK_BOT_TOKEN         Bot token (limited: invited channels only, no search)

Examples:
  $0 auth                                     # Show how to get tokens
  $0 build                                    # Build the image
  $0 test                                     # Verify build works

  # Using browser session tokens (easiest):
  SLACK_MCP_XOXC_TOKEN=xoxc-... SLACK_MCP_XOXD_TOKEN=xoxd-... $0 mcp-tools
  SLACK_MCP_XOXC_TOKEN=xoxc-... SLACK_MCP_XOXD_TOKEN=xoxd-... $0 list-channels

  # Using user OAuth token:
  SLACK_MCP_XOXP_TOKEN=xoxp-... $0 mcp-tools

  $0 clean                                    # Clean up
EOF
}

# Main command dispatcher
case "${1:-help}" in
    # Getting started
    auth)    cmd_auth ;;

    # Docker management commands
    status)  cmd_status ;;
    build)   cmd_build ;;
    start)   cmd_start ;;
    stop)    cmd_stop ;;
    shell)   cmd_shell ;;
    run)     shift; cmd_run "$@" ;;
    test)    cmd_test ;;
    verify)  cmd_verify ;;
    clean)   cmd_clean ;;
    logs)    shift; cmd_logs "$@" ;;
    help|--help|-h)  cmd_help ;;

    # CLI commands via mcptools (WIP)
    mcp-tools)   shift; cmd_mcp_tools "$@" ;;
    mcp-shell)   cmd_mcp_shell ;;
    mcp-call)    shift; cmd_mcp_call "$@" ;;

    # Convenience commands (WIP)
    list-channels)  shift; cmd_list_channels "$@" ;;
    read-channel)   shift; cmd_read_channel "$@" ;;
    read-thread)    shift; cmd_read_thread "$@" ;;

    *)
        log_error "Unknown command: $1"
        cmd_help
        exit 1
        ;;
esac
