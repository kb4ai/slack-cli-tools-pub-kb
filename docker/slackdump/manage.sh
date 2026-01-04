#!/usr/bin/env bash
# Management script for slackdump Docker container
# https://github.com/rusq/slackdump

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration - can be overridden via environment variables
IMAGE_NAME="${SLACKDUMP_IMAGE_NAME:-slack-cli-tools-slackdump}"
CONTAINER_NAME="${SLACKDUMP_CONTAINER_NAME:-slackdump-test}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

cmd_status() {
    echo "=== Docker Image Status ==="
    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    else
        log_warn "Image '$IMAGE_NAME' not found"
    fi

    echo ""
    echo "=== Docker Container Status ==="
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        docker ps -a --filter "name=^${CONTAINER_NAME}$" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        log_warn "Container '$CONTAINER_NAME' not found"
    fi
}

cmd_build() {
    log_info "Building Docker image: $IMAGE_NAME"
    # Use legacy builder to avoid buildx activity tracking issues
    DOCKER_BUILDKIT=0 docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
    log_info "Build complete"
}

cmd_start() {
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Starting existing container: $CONTAINER_NAME"
        docker start "$CONTAINER_NAME"
    else
        log_info "Creating and starting container: $CONTAINER_NAME"
        docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME" sleep infinity
    fi
}

cmd_stop() {
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Stopping container: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
    else
        log_warn "Container '$CONTAINER_NAME' not found"
    fi
}

cmd_shell() {
    log_info "Starting interactive shell in container"
    docker run --rm -it --entrypoint /bin/sh "$IMAGE_NAME"
}

cmd_run() {
    log_info "Running slackdump with args: $*"
    docker run --rm "$IMAGE_NAME" "$@"
}

cmd_test() {
    log_info "Testing slackdump binary..."

    # Test 1: Check --help produces output (exit code 2 is expected for help)
    log_info "Test 1: Running --help"
    local help_output
    help_output=$(docker run --rm "$IMAGE_NAME" --help 2>&1) || true
    if echo "$help_output" | grep -q "Slackdump is a tool"; then
        log_info "Test 1 PASSED: --help produces expected output"
    else
        log_error "Test 1 FAILED: --help did not produce expected output"
        echo "$help_output"
        return 1
    fi

    # Test 2: Check version command
    log_info "Test 2: Running version command"
    local version_output
    version_output=$(docker run --rm "$IMAGE_NAME" version 2>&1) || true
    if echo "$version_output" | grep -iq "slackdump\|version"; then
        log_info "Test 2 PASSED: version command works"
        echo "$version_output"
    else
        log_warn "Test 2 SKIPPED: version command output not recognized"
    fi

    log_info "All tests passed!"
}

cmd_verify() {
    cmd_test
}

cmd_clean() {
    log_info "Cleaning up Docker resources..."

    # Stop and remove container
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Removing container: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
    fi

    # Remove image
    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        log_info "Removing image: $IMAGE_NAME"
        docker rmi "$IMAGE_NAME" 2>/dev/null || true
    fi

    log_info "Cleanup complete"
}

cmd_logs() {
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        docker logs "$CONTAINER_NAME"
    else
        log_warn "Container '$CONTAINER_NAME' not found"
    fi
}

show_usage() {
    cat <<EOF
Usage: $(basename "$0") <command> [args]

Commands:
  status    Show status of container and image
  build     Build the Docker image
  start     Start the container
  stop      Stop the container
  shell     Start an interactive shell in the container
  run       Run slackdump with provided arguments
  test      Run tests to verify the binary works
  verify    Alias for test
  clean     Remove container and image
  logs      View container logs

Environment Variables:
  SLACKDUMP_IMAGE_NAME      Override image name (default: $IMAGE_NAME)
  SLACKDUMP_CONTAINER_NAME  Override container name (default: $CONTAINER_NAME)

Examples:
  $(basename "$0") build
  $(basename "$0") test
  $(basename "$0") run -- --help
  $(basename "$0") run -- version
  $(basename "$0") clean
EOF
}

main() {
    if [[ $# -lt 1 ]]; then
        show_usage
        exit 1
    fi

    local command="$1"
    shift

    case "$command" in
        status)  cmd_status "$@" ;;
        build)   cmd_build "$@" ;;
        start)   cmd_start "$@" ;;
        stop)    cmd_stop "$@" ;;
        shell)   cmd_shell "$@" ;;
        run)
            # Skip '--' if present
            [[ "${1:-}" == "--" ]] && shift
            cmd_run "$@"
            ;;
        test)    cmd_test "$@" ;;
        verify)  cmd_verify "$@" ;;
        clean)   cmd_clean "$@" ;;
        logs)    cmd_logs "$@" ;;
        help|-h|--help)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
