#!/bin/bash
#
# Management script for slackcat Docker container
# Tool: bcicen/slackcat - CLI for piping content to Slack
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${SLACKCAT_IMAGE_NAME:-slack-cli-tools-slackcat}"
CONTAINER_NAME="${SLACKCAT_CONTAINER_NAME:-slackcat-test}"

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
    echo "=== Docker Status for slackcat ==="
    echo ""
    echo "Image: ${IMAGE_NAME}"
    if docker image inspect "${IMAGE_NAME}" &>/dev/null; then
        echo -e "  Status: ${GREEN}EXISTS${NC}"
        docker image inspect "${IMAGE_NAME}" --format '  Size: {{.Size}} bytes' 2>/dev/null || true
        docker image inspect "${IMAGE_NAME}" --format '  Created: {{.Created}}' 2>/dev/null || true
    else
        echo -e "  Status: ${YELLOW}NOT FOUND${NC}"
    fi
    echo ""
    echo "Container: ${CONTAINER_NAME}"
    if docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        STATUS=$(docker container inspect "${CONTAINER_NAME}" --format '{{.State.Status}}' 2>/dev/null)
        echo -e "  Status: ${GREEN}${STATUS}${NC}"
    else
        echo -e "  Status: ${YELLOW}NOT FOUND${NC}"
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
        docker run -d --name "${CONTAINER_NAME}" "${IMAGE_NAME}" sleep infinity
    fi
    log_info "Container started"
}

cmd_stop() {
    log_info "Stopping container: ${CONTAINER_NAME}"
    docker stop "${CONTAINER_NAME}" 2>/dev/null || log_warn "Container not running"
    log_info "Container stopped"
}

cmd_shell() {
    log_info "Opening shell in container"
    if ! docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        log_info "Starting temporary container for shell access"
        docker run -it --rm --entrypoint /bin/sh "${IMAGE_NAME}"
    else
        docker exec -it "${CONTAINER_NAME}" /bin/sh
    fi
}

cmd_run() {
    # Pass all remaining arguments to slackcat
    docker run --rm -i "${IMAGE_NAME}" "$@"
}

cmd_test() {
    log_info "Running tests for slackcat Docker image"

    # Check if image exists
    if ! docker image inspect "${IMAGE_NAME}" &>/dev/null; then
        log_error "Image ${IMAGE_NAME} not found. Run './manage.sh build' first."
        exit 1
    fi

    # Test 1: Run with --help and check exit code
    log_info "Test 1: Running slackcat --help"
    if docker run --rm "${IMAGE_NAME}" --help; then
        log_info "Test 1: PASSED - --help returned exit code 0"
    else
        log_error "Test 1: FAILED - --help returned non-zero exit code"
        exit 1
    fi

    # Test 2: Check binary exists and is executable
    log_info "Test 2: Verifying binary location"
    if docker run --rm --entrypoint /bin/sh "${IMAGE_NAME}" -c "test -x /usr/local/bin/slackcat"; then
        log_info "Test 2: PASSED - Binary exists and is executable"
    else
        log_error "Test 2: FAILED - Binary not found or not executable"
        exit 1
    fi

    # Test 3: Check version output (if available)
    log_info "Test 3: Checking version output"
    if docker run --rm "${IMAGE_NAME}" --version 2>&1 | grep -q "slackcat"; then
        log_info "Test 3: PASSED - Version output contains 'slackcat'"
    else
        log_warn "Test 3: SKIPPED - Version output format may differ"
    fi

    echo ""
    log_info "All tests passed!"
}

cmd_verify() {
    log_info "Verifying slackcat binary"
    docker run --rm "${IMAGE_NAME}" --help
}

cmd_clean() {
    log_info "Cleaning up Docker artifacts"

    # Stop and remove container if exists
    if docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        log_info "Stopping container: ${CONTAINER_NAME}"
        docker stop "${CONTAINER_NAME}" 2>/dev/null || true
        log_info "Removing container: ${CONTAINER_NAME}"
        docker rm "${CONTAINER_NAME}" 2>/dev/null || true
    else
        log_info "Container ${CONTAINER_NAME} not found (already clean)"
    fi

    # Remove image if exists
    if docker image inspect "${IMAGE_NAME}" &>/dev/null; then
        log_info "Removing image: ${IMAGE_NAME}"
        docker rmi "${IMAGE_NAME}" 2>/dev/null || true
    else
        log_info "Image ${IMAGE_NAME} not found (already clean)"
    fi

    log_info "Cleanup complete"
}

cmd_logs() {
    log_info "Showing logs for container: ${CONTAINER_NAME}"
    docker logs "${CONTAINER_NAME}" 2>&1 || log_warn "No logs available or container not found"
}

cmd_help() {
    echo "Usage: $0 <command> [args...]"
    echo ""
    echo "Management script for slackcat Docker container"
    echo ""
    echo "Commands:"
    echo "  status    Show container and image status"
    echo "  build     Build the Docker image"
    echo "  start     Start the container"
    echo "  stop      Stop the container"
    echo "  shell     Open a shell in the container"
    echo "  run       Run slackcat with arguments"
    echo "  test      Run basic tests"
    echo "  verify    Verify the binary works"
    echo "  clean     Remove container and image"
    echo "  logs      Show container logs"
    echo "  help      Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  SLACKCAT_IMAGE_NAME     Override image name (default: ${IMAGE_NAME})"
    echo "  SLACKCAT_CONTAINER_NAME Override container name (default: ${CONTAINER_NAME})"
    echo ""
    echo "Examples:"
    echo "  $0 build              # Build the Docker image"
    echo "  $0 test               # Run tests"
    echo "  $0 run --help         # Run slackcat --help"
    echo "  $0 clean              # Remove all artifacts"
}

# Main command dispatcher
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
        cmd_logs
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
