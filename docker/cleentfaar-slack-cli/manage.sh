#!/bin/bash
set -e

# Configuration
IMAGE_NAME="${IMAGE_NAME:-slack-cli-tools-cleentfaar-slack-cli}"
CONTAINER_NAME="${CONTAINER_NAME:-cleentfaar-slack-cli-test}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    echo "=== Image Status ==="
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
        docker container ls -a --filter "name=$CONTAINER_NAME"
    else
        log_warn "Container '$CONTAINER_NAME' does not exist"
    fi
}

cmd_build() {
    log_info "Building image '$IMAGE_NAME'..."
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
    log_info "Build complete"
}

cmd_start() {
    log_info "Starting container '$CONTAINER_NAME'..."
    docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME" tail -f /dev/null
    log_info "Container started"
}

cmd_stop() {
    log_info "Stopping container '$CONTAINER_NAME'..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || log_warn "Container not running"
    docker rm "$CONTAINER_NAME" 2>/dev/null || log_warn "Container not found"
    log_info "Container stopped and removed"
}

cmd_shell() {
    log_info "Opening shell in container..."
    docker run --rm -it "$IMAGE_NAME" /bin/sh
}

cmd_run() {
    docker run --rm "$IMAGE_NAME" "$@"
}

cmd_test() {
    log_info "Testing slack-cli binary..."

    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        log_error "Image '$IMAGE_NAME' not found. Run 'build' first."
        exit 1
    fi

    log_info "Running --help command..."
    if docker run --rm "$IMAGE_NAME" --help; then
        log_info "Test PASSED: slack-cli --help executed successfully"
        return 0
    else
        log_error "Test FAILED: slack-cli --help returned non-zero exit code"
        return 1
    fi
}

cmd_verify() {
    cmd_test "$@"
}

cmd_clean() {
    log_info "Cleaning up..."

    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Removing container '$CONTAINER_NAME'..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
    fi

    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        log_info "Removing image '$IMAGE_NAME'..."
        docker rmi "$IMAGE_NAME"
    fi

    log_info "Cleanup complete"
}

cmd_logs() {
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        docker logs "$CONTAINER_NAME" "$@"
    else
        log_error "Container '$CONTAINER_NAME' not found"
        exit 1
    fi
}

cmd_help() {
    echo "Usage: $0 <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  status    Show container and image status"
    echo "  build     Build the Docker image"
    echo "  start     Start a container"
    echo "  stop      Stop and remove the container"
    echo "  shell     Open a shell in the container"
    echo "  run       Run slack-cli commands (args passed through)"
    echo "  test      Verify the binary works"
    echo "  verify    Alias for test"
    echo "  clean     Remove container and image"
    echo "  logs      Show container logs"
    echo "  help      Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  IMAGE_NAME      Docker image name (default: $IMAGE_NAME)"
    echo "  CONTAINER_NAME  Docker container name (default: $CONTAINER_NAME)"
}

# Main command dispatch
case "${1:-help}" in
    status)
        cmd_status
        ;;
    build)
        cmd_build
        ;;
    start)
        cmd_start
        ;;
    stop)
        cmd_stop
        ;;
    shell)
        cmd_shell
        ;;
    run)
        shift
        cmd_run "$@"
        ;;
    test)
        cmd_test
        ;;
    verify)
        cmd_verify
        ;;
    clean)
        cmd_clean
        ;;
    logs)
        shift
        cmd_logs "$@"
        ;;
    help|--help|-h)
        cmd_help
        ;;
    *)
        log_error "Unknown command: $1"
        cmd_help
        exit 1
        ;;
esac
