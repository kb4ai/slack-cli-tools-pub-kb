#!/usr/bin/env bash
#
# Management script for rockymadden/slack-cli Docker container
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-slack-cli-tools-rockymadden-slack-cli}"
CONTAINER_NAME="${CONTAINER_NAME:-rockymadden-slack-cli-test}"

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
    log_info "Checking status..."
    echo ""
    echo "Image:"
    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        docker images "$IMAGE_NAME" --format "  {{.Repository}}:{{.Tag}} - {{.Size}} (created {{.CreatedSince}})"
    else
        echo "  Not found"
    fi
    echo ""
    echo "Container:"
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        docker ps -a --filter "name=$CONTAINER_NAME" --format "  {{.Names}} - {{.Status}}"
    else
        echo "  Not found"
    fi
}

cmd_build() {
    log_info "Building Docker image: $IMAGE_NAME"
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
    log_info "Build complete"
}

cmd_start() {
    log_info "Starting container: $CONTAINER_NAME"
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        docker start "$CONTAINER_NAME"
    else
        docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME" sleep infinity
    fi
    log_info "Container started"
}

cmd_stop() {
    log_info "Stopping container: $CONTAINER_NAME"
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        docker stop "$CONTAINER_NAME" || true
        log_info "Container stopped"
    else
        log_warn "Container not found"
    fi
}

cmd_shell() {
    log_info "Opening shell in container..."
    if ! docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Starting temporary container..."
        docker run -it --rm --name "$CONTAINER_NAME" --entrypoint /bin/bash "$IMAGE_NAME"
    else
        docker exec -it "$CONTAINER_NAME" /bin/bash
    fi
}

cmd_run() {
    docker run --rm "$IMAGE_NAME" "$@"
}

cmd_test() {
    log_info "Testing slack-cli installation..."

    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        log_error "Image not found. Run './manage.sh build' first."
        exit 1
    fi

    log_info "Running 'slack --help'..."
    if docker run --rm "$IMAGE_NAME" --help; then
        echo ""
        log_info "Test PASSED: slack-cli is working correctly"
        return 0
    else
        log_error "Test FAILED: slack --help returned non-zero exit code"
        return 1
    fi
}

cmd_verify() {
    cmd_test "$@"
}

cmd_clean() {
    log_info "Cleaning up..."

    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Removing container: $CONTAINER_NAME"
        docker rm -f "$CONTAINER_NAME" || true
    fi

    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        log_info "Removing image: $IMAGE_NAME"
        docker rmi "$IMAGE_NAME" || true
    fi

    log_info "Cleanup complete"
}

cmd_logs() {
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        docker logs "$CONTAINER_NAME" "$@"
    else
        log_warn "Container not found"
    fi
}

cmd_help() {
    cat <<EOF
Usage: $0 <command> [args...]

Commands:
  status    Show container and image status
  build     Build the Docker image
  start     Start the container
  stop      Stop the container
  shell     Open interactive shell in container
  run       Run slack command with arguments
  test      Verify slack-cli works correctly
  verify    Alias for test
  clean     Remove container and image
  logs      Show container logs
  help      Show this help message

Environment Variables:
  IMAGE_NAME      Docker image name (default: $IMAGE_NAME)
  CONTAINER_NAME  Container name (default: $CONTAINER_NAME)

Examples:
  $0 build                    # Build the image
  $0 test                     # Test the installation
  $0 run send -c general -m "Hello"  # Send a message
  $0 clean                    # Clean up
EOF
}

# Main command dispatch
case "${1:-help}" in
    status)  shift; cmd_status "$@" ;;
    build)   shift; cmd_build "$@" ;;
    start)   shift; cmd_start "$@" ;;
    stop)    shift; cmd_stop "$@" ;;
    shell)   shift; cmd_shell "$@" ;;
    run)     shift; cmd_run "$@" ;;
    test)    shift; cmd_test "$@" ;;
    verify)  shift; cmd_verify "$@" ;;
    clean)   shift; cmd_clean "$@" ;;
    logs)    shift; cmd_logs "$@" ;;
    help|--help|-h) cmd_help ;;
    *)
        log_error "Unknown command: $1"
        cmd_help
        exit 1
        ;;
esac
