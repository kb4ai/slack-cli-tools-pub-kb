#!/usr/bin/env bash
set -euo pipefail

# Configuration
IMAGE_NAME="${IMAGE_NAME:-slack-cli-tools-regisb-slack-cli}"
CONTAINER_NAME="${CONTAINER_NAME:-regisb-slack-cli-test}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
    echo "=== Image ==="
    if docker image inspect "${IMAGE_NAME}" &>/dev/null; then
        docker images "${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    else
        echo "Image '${IMAGE_NAME}' not found"
    fi
    echo ""
    echo "=== Container ==="
    if docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        docker ps -a --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "Container '${CONTAINER_NAME}' not found"
    fi
}

cmd_build() {
    log_info "Building Docker image: ${IMAGE_NAME}"
    docker build -t "${IMAGE_NAME}" "${SCRIPT_DIR}"
    log_info "Build complete"
}

cmd_start() {
    log_info "Starting container: ${CONTAINER_NAME}"
    if docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        docker start "${CONTAINER_NAME}"
    else
        docker run -d --name "${CONTAINER_NAME}" "${IMAGE_NAME}" tail -f /dev/null
    fi
    log_info "Container started"
}

cmd_stop() {
    log_info "Stopping container: ${CONTAINER_NAME}"
    if docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        docker stop "${CONTAINER_NAME}" || true
        log_info "Container stopped"
    else
        log_warn "Container not found"
    fi
}

cmd_shell() {
    log_info "Opening shell in container..."
    if ! docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        log_info "Container not running, starting temporary container..."
        docker run --rm -it --entrypoint /bin/sh "${IMAGE_NAME}"
    else
        docker exec -it "${CONTAINER_NAME}" /bin/sh
    fi
}

cmd_run() {
    shift || true
    log_info "Running slack-cli with args: $*"
    docker run --rm "${IMAGE_NAME}" "$@"
}

cmd_test() {
    log_info "Testing slack-cli installation..."

    # Check if image exists, build if not
    if ! docker image inspect "${IMAGE_NAME}" &>/dev/null; then
        log_warn "Image not found, building first..."
        cmd_build
    fi

    # Run --help and capture output
    log_info "Running: slack-cli --help"
    if docker run --rm "${IMAGE_NAME}" --help; then
        echo ""
        log_info "Test PASSED: slack-cli --help executed successfully"
        return 0
    else
        echo ""
        log_error "Test FAILED: slack-cli --help returned non-zero exit code"
        return 1
    fi
}

cmd_verify() {
    cmd_test
}

cmd_clean() {
    log_info "Cleaning up..."

    # Stop and remove container
    if docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        log_info "Stopping container: ${CONTAINER_NAME}"
        docker stop "${CONTAINER_NAME}" || true
        log_info "Removing container: ${CONTAINER_NAME}"
        docker rm "${CONTAINER_NAME}" || true
    else
        log_info "Container '${CONTAINER_NAME}' not found, skipping"
    fi

    # Remove image
    if docker image inspect "${IMAGE_NAME}" &>/dev/null; then
        log_info "Removing image: ${IMAGE_NAME}"
        docker rmi "${IMAGE_NAME}" || true
    else
        log_info "Image '${IMAGE_NAME}' not found, skipping"
    fi

    log_info "Cleanup complete"
}

cmd_logs() {
    if docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        docker logs "${CONTAINER_NAME}" "$@"
    else
        log_error "Container '${CONTAINER_NAME}' not found"
        return 1
    fi
}

cmd_help() {
    echo "Usage: $0 <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  status    Show container and image status"
    echo "  build     Build the Docker image"
    echo "  start     Start the container"
    echo "  stop      Stop the container"
    echo "  shell     Open an interactive shell in the container"
    echo "  run       Run slack-cli with custom arguments"
    echo "  test      Verify the installation works"
    echo "  verify    Alias for test"
    echo "  clean     Remove container and image"
    echo "  logs      Show container logs"
    echo "  help      Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  IMAGE_NAME       Docker image name (default: ${IMAGE_NAME})"
    echo "  CONTAINER_NAME   Container name (default: ${CONTAINER_NAME})"
}

# Main entry point
main() {
    local cmd="${1:-help}"

    case "$cmd" in
        status)  cmd_status ;;
        build)   cmd_build ;;
        start)   cmd_start ;;
        stop)    cmd_stop ;;
        shell)   cmd_shell ;;
        run)     cmd_run "$@" ;;
        test)    cmd_test ;;
        verify)  cmd_verify ;;
        clean)   cmd_clean ;;
        logs)    shift; cmd_logs "$@" ;;
        help|--help|-h) cmd_help ;;
        *)
            log_error "Unknown command: $cmd"
            echo ""
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
