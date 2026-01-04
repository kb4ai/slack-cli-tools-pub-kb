#!/usr/bin/env bash
#
# Management script for shaharia-lab/slackcli Docker container
#

set -euo pipefail

# Configuration - can be overridden via environment variables
IMAGE_NAME="${SHAHARIA_SLACKCLI_IMAGE_NAME:-slack-cli-tools-shaharia-slackcli}"
CONTAINER_NAME="${SHAHARIA_SLACKCLI_CONTAINER_NAME:-shaharia-slackcli-test}"

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
    echo "=== Docker Image Status ==="
    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        log_info "Image '$IMAGE_NAME' exists"
        docker image ls "$IMAGE_NAME"
    else
        log_warn "Image '$IMAGE_NAME' does not exist"
    fi

    echo ""
    echo "=== Docker Container Status ==="
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Container '$CONTAINER_NAME' exists"
        docker container ls -a --filter "name=$CONTAINER_NAME"
    else
        log_warn "Container '$CONTAINER_NAME' does not exist"
    fi
}

cmd_build() {
    log_info "Building Docker image '$IMAGE_NAME'..."
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
    log_info "Build complete"
}

cmd_start() {
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Starting existing container '$CONTAINER_NAME'..."
        docker start "$CONTAINER_NAME"
    else
        log_info "Creating and starting container '$CONTAINER_NAME'..."
        docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME" sleep infinity
    fi
    log_info "Container started"
}

cmd_stop() {
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Stopping container '$CONTAINER_NAME'..."
        docker stop "$CONTAINER_NAME" || true
        log_info "Container stopped"
    else
        log_warn "Container '$CONTAINER_NAME' does not exist"
    fi
}

cmd_shell() {
    log_info "Opening shell in container..."
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        docker exec -it "$CONTAINER_NAME" /bin/sh
    else
        docker run -it --rm "$IMAGE_NAME" /bin/sh
    fi
}

cmd_run() {
    log_info "Running slackcli with arguments: $*"
    docker run --rm \
        ${SLACK_TOKEN:+-e SLACK_TOKEN="$SLACK_TOKEN"} \
        "$IMAGE_NAME" "$@"
}

cmd_test() {
    log_info "Running basic tests..."

    echo ""
    echo "=== Test 1: Check --help output ==="
    local help_output
    if help_output=$(docker run --rm "$IMAGE_NAME" --help 2>&1); then
        log_info "Help command succeeded"
        echo "$help_output"

        # Verify help output contains expected content
        if echo "$help_output" | grep -qi "slack\|cli\|usage\|command\|help"; then
            log_info "Help output contains expected keywords"
        else
            log_warn "Help output may not contain expected keywords"
        fi
    else
        log_error "Help command failed"
        echo "$help_output"
        return 1
    fi

    echo ""
    log_info "All tests passed!"
}

cmd_verify() {
    log_info "Verifying binary works..."
    if docker run --rm "$IMAGE_NAME" --help &>/dev/null; then
        log_info "Binary verification passed"
    else
        log_error "Binary verification failed"
        return 1
    fi
}

cmd_clean() {
    log_info "Cleaning up container and image..."

    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Stopping and removing container '$CONTAINER_NAME'..."
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
        docker logs "$CONTAINER_NAME"
    else
        log_warn "Container '$CONTAINER_NAME' does not exist"
    fi
}

show_usage() {
    cat <<EOF
Usage: $(basename "$0") <command> [args]

Management script for shaharia-lab/slackcli Docker container.

Commands:
    status      Show container and image status
    build       Build the Docker image
    start       Start the container
    stop        Stop the container
    shell       Open a shell in the container
    run [args]  Run slackcli with given arguments
    test        Run basic tests (--help check)
    verify      Verify the binary works
    clean       Remove container and image
    logs        Show container logs

Environment Variables:
    SHAHARIA_SLACKCLI_IMAGE_NAME     Override image name (default: $IMAGE_NAME)
    SHAHARIA_SLACKCLI_CONTAINER_NAME Override container name (default: $CONTAINER_NAME)
    SLACK_TOKEN                      Slack API token (passed to container)

Examples:
    ./manage.sh build
    ./manage.sh test
    ./manage.sh run --help
    SLACK_TOKEN=xoxb-... ./manage.sh run channels list
    ./manage.sh clean
EOF
}

# Main entry point
main() {
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi

    local command="$1"
    shift

    case "$command" in
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
        -h|--help|help)
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
