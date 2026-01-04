#!/bin/bash

# Docker management script for slackapi/slack-cli
# Official Slack CLI for app development

set -e

IMAGE_NAME="${IMAGE_NAME:-slack-cli-tools-slackapi-slack-cli}"
CONTAINER_NAME="${CONTAINER_NAME:-slackapi-slack-cli-test}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo "Usage: $0 {status|build|start|stop|shell|run|test|verify|clean|logs}"
    echo ""
    echo "Commands:"
    echo "  status  - Show container and image status"
    echo "  build   - Build the Docker image"
    echo "  start   - Start the container"
    echo "  stop    - Stop the container"
    echo "  shell   - Open a shell in a new container"
    echo "  run     - Run slack CLI with arguments"
    echo "  test    - Run basic tests (slack --help)"
    echo "  verify  - Alias for test"
    echo "  clean   - Remove container and image"
    echo "  logs    - Show container logs"
    exit 1
}

status() {
    echo "=== Image Status ==="
    docker images "${IMAGE_NAME}" 2>/dev/null || echo "Image not found"
    echo ""
    echo "=== Container Status ==="
    docker ps -a --filter "name=${CONTAINER_NAME}" 2>/dev/null || echo "No containers"
}

build() {
    echo "Building image: ${IMAGE_NAME}"
    docker build -t "${IMAGE_NAME}" "${SCRIPT_DIR}"
    echo "Build complete"
}

start() {
    echo "Starting container: ${CONTAINER_NAME}"
    docker run -d --name "${CONTAINER_NAME}" "${IMAGE_NAME}" sleep infinity
    echo "Container started"
}

stop() {
    echo "Stopping container: ${CONTAINER_NAME}"
    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true
    echo "Container stopped and removed"
}

shell() {
    echo "Opening shell in new container..."
    docker run -it --rm --entrypoint /bin/sh "${IMAGE_NAME}"
}

run_cmd() {
    docker run --rm "${IMAGE_NAME}" "$@"
}

test_cmd() {
    echo "=== Testing slack CLI ==="
    echo "Running: slack --help"
    echo ""
    if docker run --rm "${IMAGE_NAME}" --help; then
        echo ""
        echo "=== TEST PASSED ==="
        return 0
    else
        echo ""
        echo "=== TEST FAILED ==="
        return 1
    fi
}

clean() {
    echo "Cleaning up..."
    echo "Stopping container: ${CONTAINER_NAME}"
    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true
    echo "Removing image: ${IMAGE_NAME}"
    docker rmi "${IMAGE_NAME}" 2>/dev/null || true
    echo "Cleanup complete"
}

logs() {
    docker logs "${CONTAINER_NAME}"
}

case "${1:-}" in
    status)
        status
        ;;
    build)
        build
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    shell)
        shell
        ;;
    run)
        shift
        run_cmd "$@"
        ;;
    test|verify)
        test_cmd
        ;;
    clean)
        clean
        ;;
    logs)
        logs
        ;;
    *)
        usage
        ;;
esac
