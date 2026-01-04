#!/bin/bash
#
# Management script for slack-libpurple Docker setup
# Note: This is a libpurple PLUGIN for Pidgin/Finch, NOT a standalone CLI
#

set -e

# Configuration - can be overridden via environment variables
IMAGE_NAME="${SLACK_LIBPURPLE_IMAGE_NAME:-slack-cli-tools-slack-libpurple}"
CONTAINER_NAME="${SLACK_LIBPURPLE_CONTAINER_NAME:-slack-libpurple-test}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<EOF
Usage: $0 <command>

Commands:
    status    Show status of image and container
    build     Build the Docker image
    start     Start the container in background
    stop      Stop and remove the container
    shell     Get a shell inside the container
    run       Run Finch interactively
    test      Verify the plugin compiled successfully
    verify    Alias for test
    clean     Remove container and image
    logs      Show container logs

Environment variables:
    SLACK_LIBPURPLE_IMAGE_NAME      Override image name (default: $IMAGE_NAME)
    SLACK_LIBPURPLE_CONTAINER_NAME  Override container name (default: $CONTAINER_NAME)
EOF
}

cmd_status() {
    echo "=== Image Status ==="
    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        echo "Image '$IMAGE_NAME' exists"
        docker image ls "$IMAGE_NAME"
    else
        echo "Image '$IMAGE_NAME' does not exist"
    fi

    echo ""
    echo "=== Container Status ==="
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        echo "Container '$CONTAINER_NAME' exists"
        docker container ls -a --filter "name=$CONTAINER_NAME"
    else
        echo "Container '$CONTAINER_NAME' does not exist"
    fi
}

cmd_build() {
    echo "Building image '$IMAGE_NAME'..."
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
    echo "Build complete."
}

cmd_start() {
    echo "Starting container '$CONTAINER_NAME'..."
    docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME" tail -f /dev/null
    echo "Container started."
}

cmd_stop() {
    echo "Stopping container '$CONTAINER_NAME'..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    echo "Container stopped and removed."
}

cmd_shell() {
    if ! docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        echo "Container not running. Starting temporarily..."
        docker run -it --rm --name "$CONTAINER_NAME" --entrypoint /bin/bash "$IMAGE_NAME"
    else
        docker exec -it "$CONTAINER_NAME" /bin/bash
    fi
}

cmd_run() {
    echo "Running Finch interactively..."
    echo "Note: This is a TUI application. Press Ctrl+C to exit."
    docker run -it --rm --name "${CONTAINER_NAME}-interactive" "$IMAGE_NAME"
}

cmd_test() {
    echo "Testing slack-libpurple plugin..."
    echo ""

    # Check if image exists
    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        echo "ERROR: Image '$IMAGE_NAME' not found. Run './manage.sh build' first."
        exit 1
    fi

    # Check if libslack.so exists in the image
    echo "Checking for libslack.so in /usr/lib/purple-2/..."
    if docker run --rm --entrypoint /bin/sh "$IMAGE_NAME" -c "test -f /usr/lib/purple-2/libslack.so"; then
        echo "SUCCESS: libslack.so found!"
        echo ""
        echo "Plugin details:"
        docker run --rm --entrypoint /bin/sh "$IMAGE_NAME" -c "ls -la /usr/lib/purple-2/libslack.so"
        echo ""
        echo "The slack-libpurple plugin was successfully compiled and installed."
        echo "Note: This is a Pidgin/Finch plugin, not a standalone CLI tool."
    else
        echo "FAILURE: libslack.so not found in /usr/lib/purple-2/"
        exit 1
    fi
}

cmd_verify() {
    cmd_test
}

cmd_clean() {
    echo "Cleaning up Docker artifacts..."

    # Stop and remove container if exists
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        echo "Removing container '$CONTAINER_NAME'..."
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
    fi

    # Remove image if exists
    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        echo "Removing image '$IMAGE_NAME'..."
        docker rmi "$IMAGE_NAME"
    fi

    echo "Cleanup complete."
}

cmd_logs() {
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        docker logs "$CONTAINER_NAME"
    else
        echo "Container '$CONTAINER_NAME' not found."
        exit 1
    fi
}

# Main command dispatch
case "${1:-}" in
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
    -h|--help|help)
        usage
        ;;
    "")
        usage
        exit 1
        ;;
    *)
        echo "Unknown command: $1"
        usage
        exit 1
        ;;
esac
