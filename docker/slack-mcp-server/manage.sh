#!/bin/bash
#
# Management script for slack-mcp-server Docker container
# MCP server for Slack integration
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
    log_info "Testing module load..."

    # Test that the module can be loaded without errors
    # For MCP servers, we verify the module loads by checking if require works
    docker run --rm \
        --entrypoint node \
        "$IMAGE_NAME" \
        -e "try { require('./dist/index.js'); console.log('Module loaded successfully'); process.exit(0); } catch(e) { console.error('Module load failed:', e.message); process.exit(1); }"

    if [ $? -eq 0 ]; then
        log_info "Test passed: Module loads correctly"
    else
        log_error "Test failed: Module failed to load"
        return 1
    fi
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

cmd_help() {
    cat <<EOF
Slack MCP Server Docker Management Script

Usage: $0 <command> [args...]

Commands:
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

Environment Variables:
  IMAGE_NAME        Docker image name (default: $IMAGE_NAME)
  CONTAINER_NAME    Container name (default: $CONTAINER_NAME)
  SLACK_BOT_TOKEN   Slack Bot OAuth Token (required for actual use)

Examples:
  $0 build                    # Build the image
  $0 test                     # Verify module loads
  SLACK_BOT_TOKEN=xoxb-... $0 run  # Run with token
  $0 clean                    # Clean up
EOF
}

# Main command dispatcher
case "${1:-help}" in
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
    *)
        log_error "Unknown command: $1"
        cmd_help
        exit 1
        ;;
esac
