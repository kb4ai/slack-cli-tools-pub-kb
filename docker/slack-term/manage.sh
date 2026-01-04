#!/usr/bin/env bash
#
# manage.sh - Docker management script for slack-term
#
# Usage: ./manage.sh <command>
# Commands: status, build, start, stop, shell, run, test, verify, clean, logs

set -euo pipefail

# Configuration - can be overridden via environment variables
IMAGE_NAME="${SLACK_TERM_IMAGE_NAME:-slack-cli-tools-slack-term}"
CONTAINER_NAME="${SLACK_TERM_CONTAINER_NAME:-slack-term-test}"

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
    log_info "Checking status..."
    echo ""
    echo "Image:"
    if docker image inspect "${IMAGE_NAME}" &>/dev/null; then
        docker images "${IMAGE_NAME}" --format "  Name: {{.Repository}}\n  Tag: {{.Tag}}\n  Size: {{.Size}}\n  Created: {{.CreatedSince}}"
    else
        echo "  Not found"
    fi
    echo ""
    echo "Container:"
    if docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        docker ps -a --filter "name=${CONTAINER_NAME}" --format "  Name: {{.Names}}\n  Status: {{.Status}}\n  Created: {{.CreatedAt}}"
    else
        echo "  Not found"
    fi
}

cmd_build() {
    log_info "Building image: ${IMAGE_NAME}"
    docker build -t "${IMAGE_NAME}" "$(dirname "$0")"
    log_info "Build complete"
}

cmd_start() {
    log_info "Starting container: ${CONTAINER_NAME}"
    docker run -it --rm --name "${CONTAINER_NAME}" "${IMAGE_NAME}"
}

cmd_stop() {
    log_info "Stopping container: ${CONTAINER_NAME}"
    if docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        docker stop "${CONTAINER_NAME}"
        log_info "Container stopped"
    else
        log_warn "Container not running"
    fi
}

cmd_shell() {
    log_info "Opening shell in container"
    docker run -it --rm --name "${CONTAINER_NAME}-shell" --entrypoint /bin/sh "${IMAGE_NAME}"
}

cmd_run() {
    log_info "Running slack-term interactively"
    docker run -it --rm --name "${CONTAINER_NAME}" "${IMAGE_NAME}"
}

cmd_test() {
    log_info "Testing slack-term binary..."

    # Run with --help and capture exit code
    # Note: slack-term may exit with 0 or non-zero on --help depending on version
    # We check if the binary runs and produces some output
    set +e
    output=$(docker run --rm "${IMAGE_NAME}" --help 2>&1)
    exit_code=$?
    set -e

    # Check if we got any output (binary executed)
    if [[ -n "$output" ]]; then
        log_info "Binary executed successfully"
        echo ""
        echo "Output:"
        echo "$output"
        echo ""
        log_info "Exit code: ${exit_code}"

        # Consider test passed if binary ran (exit 0 or 1 with help text)
        if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
            log_info "Test PASSED"
            return 0
        fi
    fi

    log_error "Test FAILED"
    return 1
}

cmd_verify() {
    cmd_test
}

cmd_clean() {
    log_info "Cleaning up..."

    # Stop and remove container if exists
    if docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        log_info "Stopping container: ${CONTAINER_NAME}"
        docker stop "${CONTAINER_NAME}" 2>/dev/null || true
        docker rm "${CONTAINER_NAME}" 2>/dev/null || true
    fi

    # Remove image if exists
    if docker image inspect "${IMAGE_NAME}" &>/dev/null; then
        log_info "Removing image: ${IMAGE_NAME}"
        docker rmi "${IMAGE_NAME}"
    fi

    log_info "Cleanup complete"
}

cmd_logs() {
    log_info "Showing logs for: ${CONTAINER_NAME}"
    if docker container inspect "${CONTAINER_NAME}" &>/dev/null; then
        docker logs "${CONTAINER_NAME}"
    else
        log_warn "Container not found"
    fi
}

show_help() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  status  - Show container and image status"
    echo "  build   - Build the Docker image"
    echo "  start   - Start the container interactively"
    echo "  stop    - Stop the running container"
    echo "  shell   - Open a shell in the container"
    echo "  run     - Run slack-term interactively"
    echo "  test    - Verify the binary works"
    echo "  verify  - Alias for test"
    echo "  clean   - Remove container and image"
    echo "  logs    - Show container logs"
    echo ""
    echo "Environment variables:"
    echo "  SLACK_TERM_IMAGE_NAME     - Override image name (default: ${IMAGE_NAME})"
    echo "  SLACK_TERM_CONTAINER_NAME - Override container name (default: ${CONTAINER_NAME})"
}

# Main entry point
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
        cmd_run
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
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
