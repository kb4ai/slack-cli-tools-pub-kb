#!/usr/bin/env bash
# manage.sh - Management script for yfiton Docker container
# NOTE: yfiton is ABANDONED (last commit 2017) - build may fail

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${YFITON_IMAGE_NAME:-slack-cli-tools-yfiton}"
CONTAINER_NAME="${YFITON_CONTAINER_NAME:-yfiton-test}"

cd "$SCRIPT_DIR"

cmd_status() {
    echo "=== Image Status ==="
    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        echo "Image '$IMAGE_NAME' exists"
        docker image inspect "$IMAGE_NAME" --format '  Created: {{.Created}}'
        docker image inspect "$IMAGE_NAME" --format '  Size: {{.Size}} bytes'
    else
        echo "Image '$IMAGE_NAME' does not exist"
    fi

    echo ""
    echo "=== Container Status ==="
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        echo "Container '$CONTAINER_NAME' exists"
        docker container inspect "$CONTAINER_NAME" --format '  Status: {{.State.Status}}'
    else
        echo "Container '$CONTAINER_NAME' does not exist"
    fi
}

cmd_build() {
    echo "Building image '$IMAGE_NAME'..."
    echo "NOTE: yfiton is abandoned (2017) - build may fail due to outdated dependencies"
    docker build -t "$IMAGE_NAME" .
    echo "Build complete"
}

cmd_start() {
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        echo "Starting existing container '$CONTAINER_NAME'..."
        docker start "$CONTAINER_NAME"
    else
        echo "Creating and starting container '$CONTAINER_NAME'..."
        docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME" sleep infinity
    fi
    echo "Container started"
}

cmd_stop() {
    echo "Stopping container '$CONTAINER_NAME'..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || echo "Container not running"
}

cmd_shell() {
    echo "Opening shell in container..."
    if ! docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        echo "Container not found. Starting temporary container..."
        docker run -it --rm "$IMAGE_NAME" /bin/sh
    else
        docker exec -it "$CONTAINER_NAME" /bin/sh
    fi
}

cmd_run() {
    echo "Running yfiton with arguments: $*"
    docker run --rm "$IMAGE_NAME" "$@"
}

cmd_test() {
    echo "=== Running yfiton tests ==="
    echo ""
    echo "Test 1: Running 'yfiton --help'..."
    if docker run --rm "$IMAGE_NAME" --help; then
        echo "PASS: yfiton --help succeeded"
    else
        echo "FAIL: yfiton --help failed with exit code $?"
        return 1
    fi

    echo ""
    echo "Test 2: Checking yfiton binary exists..."
    if docker run --rm --entrypoint /bin/sh "$IMAGE_NAME" -c "test -x /app/bin/yfiton"; then
        echo "PASS: yfiton binary exists and is executable"
    else
        echo "FAIL: yfiton binary not found or not executable"
        return 1
    fi

    echo ""
    echo "=== All tests passed ==="
}

cmd_verify() {
    echo "Verifying yfiton installation..."
    docker run --rm --entrypoint /bin/sh "$IMAGE_NAME" -c "ls -la /app/bin/ && echo '---' && yfiton --version 2>/dev/null || yfiton --help | head -5"
}

cmd_clean() {
    echo "Cleaning up..."

    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        echo "Stopping and removing container '$CONTAINER_NAME'..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
    else
        echo "Container '$CONTAINER_NAME' not found"
    fi

    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        echo "Removing image '$IMAGE_NAME'..."
        docker rmi "$IMAGE_NAME"
    else
        echo "Image '$IMAGE_NAME' not found"
    fi

    echo "Cleanup complete"
}

cmd_logs() {
    echo "Container logs for '$CONTAINER_NAME':"
    docker logs "$CONTAINER_NAME" 2>&1 || echo "No logs available"
}

cmd_help() {
    cat <<EOF
yfiton Docker Management Script

USAGE:
    ./manage.sh <command> [arguments]

COMMANDS:
    status    Check image and container status
    build     Build Docker image
    start     Start container (create if needed)
    stop      Stop container
    shell     Open shell in container
    run       Run yfiton with arguments
    test      Run basic tests
    verify    Verify installation
    clean     Remove image and container
    logs      View container logs
    help      Show this help message

ENVIRONMENT VARIABLES:
    YFITON_IMAGE_NAME      Override image name (default: slack-cli-tools-yfiton)
    YFITON_CONTAINER_NAME  Override container name (default: yfiton-test)

EXAMPLES:
    ./manage.sh build
    ./manage.sh run --help
    ./manage.sh run slack --token TOKEN --channel general --message "Hello"
    ./manage.sh test
    ./manage.sh clean

NOTE: yfiton is ABANDONED (last commit 2017). Build may fail due to outdated dependencies.
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
    logs)    cmd_logs ;;
    help|--help|-h)  cmd_help ;;
    *)
        echo "Unknown command: $1"
        echo "Run './manage.sh help' for usage"
        exit 1
        ;;
esac
