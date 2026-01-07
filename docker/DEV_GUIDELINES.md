# Docker Development Guidelines

Best practices and patterns for implementing Docker setups and manage.sh scripts in this repository.

## Overview

Each Slack CLI tool has its own subdirectory containing:

* `Dockerfile` - Container image definition (Alpine/Debian-slim preferred)
* `manage.sh` - Management script for building, testing, running, and cleaning up
* `README.md` - Tool-specific documentation

All implementations follow consistent patterns to ensure maintainability and a unified developer experience.

## Dockerfile Best Practices

### Multi-Stage Builds

Use multi-stage builds to minimize final image size. The builder stage compiles/installs dependencies, and the final stage contains only runtime requirements.

```dockerfile
# Stage 1: Build
FROM golang:1.24-alpine AS builder
RUN apk add --no-cache git
WORKDIR /build
RUN git clone --depth 1 https://github.com/example/tool.git .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o tool ./cmd/tool

# Stage 2: Runtime
FROM alpine:3.19
RUN apk add --no-cache ca-certificates
COPY --from=builder /build/tool /usr/local/bin/
ENTRYPOINT ["tool"]
CMD ["--help"]
```

### Base Image Selection

Choose the smallest appropriate base image:

| Language | Builder Image | Runtime Image |
|----------|---------------|---------------|
| Go | `golang:1.24-alpine` | `alpine:3.19` |
| Python | N/A (single stage) | `python:3.12-alpine` |
| Node.js | N/A (single stage) | `node:20-alpine` |
| PHP | `php:8.3-cli-alpine` | `php:8.3-cli-alpine` |
| Java | `gradle:8-jdk21-alpine` | `eclipse-temurin:21-jre-alpine` |
| Bun/TS | `oven/bun:alpine` | `oven/bun:alpine` |
| C/C++ (with libs) | `debian:bookworm-slim` | `debian:bookworm-slim` |
| Bash scripts | N/A (single stage) | `alpine:3.19` |

**Alpine preference**: Use Alpine-based images whenever possible. Only use Debian-slim when Alpine lacks required libraries (e.g., libpurple for Pidgin plugins).

### Layer Ordering

Order Dockerfile instructions from most stable to least stable to maximize cache reuse:

1. Base image and system dependencies
2. Language/runtime dependencies
3. Source code clone/copy
4. Build step
5. Final configuration

**Good pattern** (dependencies cached separately from source):

```dockerfile
FROM golang:1.24-alpine AS builder
RUN apk add --no-cache git
WORKDIR /build
RUN git clone --depth 1 https://github.com/example/tool.git .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o tool .
```

### Go-Specific Optimizations

For Go projects, use these build flags for smaller binaries:

```dockerfile
ENV CGO_ENABLED=0
RUN go build -ldflags="-s -w" -o binary_name ./cmd/main
```

* `CGO_ENABLED=0` - Produces static binary, no C dependencies
* `-ldflags="-s -w"` - Strips symbol table and debug info

### Shallow Clones

Always use `--depth 1` when cloning repositories to minimize download size:

```dockerfile
RUN git clone --depth 1 https://github.com/example/repo.git .
```

### Entrypoint and CMD

Set ENTRYPOINT to the main binary and CMD to a sensible default (usually `--help`):

```dockerfile
ENTRYPOINT ["tool-name"]
CMD ["--help"]
```

This allows:

* `docker run image` - Shows help
* `docker run image --version` - Runs specific command
* `docker run --entrypoint /bin/sh image` - Opens shell

### Package Manager Cleanup

Always clean up package manager caches after installation:

**Alpine:**

```dockerfile
RUN apk add --no-cache git curl
```

**Debian:**

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl \
    && rm -rf /var/lib/apt/lists/*
```

### Commented Headers

Add a descriptive header comment to complex Dockerfiles:

```dockerfile
# =============================================================================
# Tool Name Docker Setup
# =============================================================================
#
# Description of what this builds and any special considerations.
#
# =============================================================================
```

## manage.sh Script Structure

### Required Commands

Every manage.sh must implement these commands:

| Command | Description |
|---------|-------------|
| `status` | Show container and image status |
| `build` | Build the Docker image |
| `start` | Start container in background |
| `stop` | Stop running container |
| `shell` | Interactive shell in container |
| `run` | Run the CLI tool (pass args after) |
| `test` | Verify binary works (typically --help) |
| `verify` | Alias for test |
| `clean` | Stop container and remove image |
| `logs` | Show container logs |
| `help` | Show usage information |

### Script Template

```bash
#!/usr/bin/env bash
#
# Management script for <tool-name> Docker container
# <Brief description of the tool>
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration - can be overridden via environment variables
IMAGE_NAME="${TOOLNAME_IMAGE_NAME:-slack-cli-tools-toolname}"
CONTAINER_NAME="${TOOLNAME_CONTAINER_NAME:-toolname-test}"

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
        log_info "Image '$IMAGE_NAME' exists"
        docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    else
        log_warn "Image '$IMAGE_NAME' not found"
    fi

    echo ""
    echo "=== Container Status ==="
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Container '$CONTAINER_NAME' exists"
        docker ps -a --filter "name=^${CONTAINER_NAME}$" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        log_warn "Container '$CONTAINER_NAME' not found"
    fi
}

cmd_build() {
    log_info "Building Docker image: $IMAGE_NAME"
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
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
    log_info "Running tool with args: $*"
    docker run --rm "$IMAGE_NAME" "$@"
}

cmd_test() {
    log_info "Testing binary..."

    # Check if image exists
    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        log_error "Image '$IMAGE_NAME' not found. Run './manage.sh build' first."
        exit 1
    fi

    # Test: Run with --help
    log_info "Test 1: Running --help"
    if docker run --rm "$IMAGE_NAME" --help; then
        log_info "Test 1 PASSED: --help executed successfully"
    else
        log_error "Test 1 FAILED: --help returned non-zero exit code"
        return 1
    fi

    log_info "All tests passed!"
}

cmd_verify() {
    cmd_test "$@"
}

cmd_clean() {
    log_info "Cleaning up Docker resources..."

    # Stop and remove container
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Stopping container: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        log_info "Removing container: $CONTAINER_NAME"
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
        docker logs "$CONTAINER_NAME" "$@"
    else
        log_error "Container '$CONTAINER_NAME' not found"
        return 1
    fi
}

cmd_help() {
    cat <<EOF
Usage: $0 <command> [args...]

Management script for <tool-name> Docker container.

Commands:
  status    Show container and image status
  build     Build the Docker image
  start     Start the container
  stop      Stop the container
  shell     Open a shell in the container
  run       Run the tool with arguments
  test      Verify the binary works
  verify    Alias for test
  clean     Remove container and image
  logs      Show container logs
  help      Show this help message

Environment Variables:
  TOOLNAME_IMAGE_NAME      Override image name (default: $IMAGE_NAME)
  TOOLNAME_CONTAINER_NAME  Override container name (default: $CONTAINER_NAME)

Examples:
  $0 build              # Build the Docker image
  $0 test               # Run tests
  $0 run --help         # Run tool --help
  $0 clean              # Remove all artifacts
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
    logs)    shift; cmd_logs "$@" ;;
    help|--help|-h) cmd_help ;;
    *)
        log_error "Unknown command: $1"
        cmd_help
        exit 1
        ;;
esac
```

### Bash Best Practices

**Use strict mode:**

```bash
set -euo pipefail
```

* `-e` - Exit on error
* `-u` - Error on undefined variables
* `-o pipefail` - Propagate pipe errors

**Alternative (less strict):**

```bash
set -e
```

Use this when you need more flexibility with undefined variables.

**Get script directory reliably:**

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

## Naming Conventions

### Image Names

All images use the prefix `slack-cli-tools-`:

```
slack-cli-tools-<tool-name>
```

Examples:

* `slack-cli-tools-slackdump`
* `slack-cli-tools-slackcat`
* `slack-cli-tools-slack-mcp-server`

### Container Names

Test containers use the suffix `-test`:

```
<tool-name>-test
```

Examples:

* `slackdump-test`
* `slackcat-test`
* `slack-mcp-server-test`

### Environment Variable Override

Allow customization via environment variables with tool-specific prefixes:

```bash
# Option 1: Tool-specific prefix (recommended for tools with common names)
IMAGE_NAME="${SLACKDUMP_IMAGE_NAME:-slack-cli-tools-slackdump}"
CONTAINER_NAME="${SLACKDUMP_CONTAINER_NAME:-slackdump-test}"

# Option 2: Generic names (acceptable for clearly named tools)
IMAGE_NAME="${IMAGE_NAME:-slack-cli-tools-slack-mcp-server}"
CONTAINER_NAME="${CONTAINER_NAME:-slack-mcp-server-test}"
```

## Testing Guidelines

### Basic Test Pattern

At minimum, verify the binary runs and shows help:

```bash
cmd_test() {
    log_info "Testing binary..."

    # Ensure image exists
    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        log_error "Image not found. Run './manage.sh build' first."
        exit 1
    fi

    # Test --help
    log_info "Test 1: Running --help"
    if docker run --rm "$IMAGE_NAME" --help; then
        log_info "Test 1 PASSED"
    else
        log_error "Test 1 FAILED"
        return 1
    fi

    log_info "All tests passed!"
}
```

### Multi-Part Testing

For complex tools, test multiple aspects:

```bash
cmd_test() {
    log_info "Testing binaries..."

    # Test 1: Primary binary --help
    log_info "Test 1: Running --help"
    docker run --rm "$IMAGE_NAME" --help > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_info "Test 1 passed: binary works"
    else
        log_error "Test 1 failed"
        return 1
    fi

    # Test 2: Additional binary (if container includes multiple tools)
    log_info "Test 2: Checking secondary tool"
    docker run --rm --entrypoint mcp "$IMAGE_NAME" --help > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log_info "Test 2 passed: secondary tool works"
    else
        log_error "Test 2 failed"
        return 1
    fi

    # Test 3: Integration test (with expected timeout for auth-required tools)
    log_info "Test 3: Integration test..."
    local output exit_code
    output=$(timeout 8 docker run --rm "$IMAGE_NAME" some-command 2>&1) && exit_code=$? || exit_code=$?

    if echo "$output" | grep -q "expected_string"; then
        log_info "Test 3 passed"
    elif [ "$exit_code" -eq 124 ]; then
        log_info "Test 3 passed (timeout expected without auth)"
    else
        log_warn "Test 3: Unexpected result"
    fi

    log_info "All tests passed!"
}
```

### Testing Exit Codes

Some tools return non-zero exit codes for help. Handle gracefully:

```bash
# Capture output even on non-zero exit
local help_output
help_output=$(docker run --rm "$IMAGE_NAME" --help 2>&1) || true

if echo "$help_output" | grep -q "Usage:"; then
    log_info "Test PASSED"
fi
```

## Authentication Patterns

### Tools Requiring Tokens

For tools that require Slack tokens, implement:

1. **Environment variable passthrough in run commands:**

```bash
cmd_run() {
    docker run --rm \
        ${SLACK_BOT_TOKEN:+-e SLACK_BOT_TOKEN="$SLACK_BOT_TOKEN"} \
        "$IMAGE_NAME" "$@"
}
```

2. **Token validation helper:**

```bash
_require_token() {
    if [ -z "${SLACK_BOT_TOKEN:-}" ]; then
        log_error "SLACK_BOT_TOKEN is required"
        log_error "Usage: SLACK_BOT_TOKEN=xoxb-... $0 $1"
        return 1
    fi
}
```

3. **Auth command with guidance:**

```bash
cmd_auth() {
    cat <<EOF
Authentication Guide
====================

OPTION 1: Bot Token (xoxb-...) - Recommended
--------------------------------------------
1. Go to https://api.slack.com/apps and create a new app
2. Under "OAuth & Permissions", add Bot Token Scopes:
   - channels:history, channels:read
   - groups:history, groups:read
   - im:history, im:read
   - mpim:history, mpim:read
   - users:read
3. Install the app to your workspace
4. Copy the "Bot User OAuth Token" (starts with xoxb-)

Usage:
  export SLACK_BOT_TOKEN="xoxb-your-token"
  $0 run
EOF
}
```

### Reference Implementation

See `slack-mcp-server/manage.sh` for a complete example with:

* `auth` command with detailed token setup instructions
* Multiple authentication options (bot token, user token, browser session)
* Token validation before commands
* MCP-specific CLI commands (mcp-tools, mcp-shell, mcp-call)
* Convenience commands (list-channels, read-channel, read-thread)

## Documentation Requirements

### README.md Structure

Each tool directory should have a README.md with:

```markdown
# <Tool Name> Docker Setup

Docker setup for [author/repo](https://github.com/author/repo) - brief description.

## Overview

What the tool does and why you'd use it.

## Prerequisites

* Docker installed and running
* Any tokens/credentials needed

## Quick Start

\`\`\`bash
./manage.sh build
./manage.sh test
./manage.sh run --help
\`\`\`

## Authentication

(If applicable) How to get and use tokens.

## Usage

### Management Commands

| Command | Description |
|---------|-------------|
| `./manage.sh build` | Build the Docker image |
| `./manage.sh test` | Verify the binary works |
| ... | ... |

### Examples

\`\`\`bash
./manage.sh run -- <specific example>
\`\`\`

## Environment Variables

* `TOOL_IMAGE_NAME` - Override image name
* `TOOL_CONTAINER_NAME` - Override container name
* `SLACK_BOT_TOKEN` - (If applicable) Slack token

## References

* [Original repository](https://github.com/author/repo)
* [Documentation](https://example.com/docs)
```

## Cleanup and Resource Management

### Clean Command Implementation

The clean command should:

1. Stop running container gracefully
2. Remove the container
3. Remove the image

```bash
cmd_clean() {
    log_info "Cleaning up Docker resources..."

    # Stop and remove container (graceful shutdown)
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log_info "Stopping container: $CONTAINER_NAME"
        docker stop "$CONTAINER_NAME" 2>/dev/null || true
        log_info "Removing container: $CONTAINER_NAME"
        docker rm "$CONTAINER_NAME" 2>/dev/null || true
    fi

    # Remove image
    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        log_info "Removing image: $IMAGE_NAME"
        docker rmi "$IMAGE_NAME" 2>/dev/null || true
    fi

    log_info "Cleanup complete"
}
```

**Important**: Use `docker stop` before `docker rm` to allow graceful shutdown. Avoid `docker rm --force` unless necessary.

### Bulk Cleanup

Use `./cleanup_all_dockers.sh` to clean all tools at once. It iterates through all subdirectories and runs their `clean` commands.

## Common Patterns and Snippets

### Conditional Environment Variable Passing

Pass environment variable only if set:

```bash
docker run --rm \
    ${SLACK_BOT_TOKEN:+-e SLACK_BOT_TOKEN="$SLACK_BOT_TOKEN"} \
    "$IMAGE_NAME" "$@"
```

### Interactive vs Non-Interactive Run

```bash
# Non-interactive (for scripting)
docker run --rm "$IMAGE_NAME" "$@"

# Interactive (for shells and interactive tools)
docker run --rm -it "$IMAGE_NAME" "$@"

# Interactive with stdin (for pipes)
docker run --rm -i "$IMAGE_NAME" "$@"
```

### Override Entrypoint

```bash
# Run shell instead of the default entrypoint
docker run --rm -it --entrypoint /bin/sh "$IMAGE_NAME"

# Run different command
docker run --rm --entrypoint mcp "$IMAGE_NAME" --help
```

### Build with Legacy Builder

If BuildKit causes issues (activity tracking, etc.):

```bash
DOCKER_BUILDKIT=0 docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"
```

### Timeout for Expected Failures

When testing without required auth:

```bash
local output exit_code
output=$(timeout 8 docker run --rm "$IMAGE_NAME" command 2>&1) && exit_code=$? || exit_code=$?

if [ "$exit_code" -eq 124 ]; then
    log_info "Timeout expected without auth - test passed"
fi
```

## Adding a New Tool

1. **Create directory**: `docker/<tool-name>/`

2. **Create Dockerfile** following the patterns above:
   * Use appropriate base image (Alpine preferred)
   * Multi-stage build if compiling from source
   * Shallow clone (`--depth 1`)
   * Clean package manager caches
   * Set ENTRYPOINT and CMD

3. **Create manage.sh** with all required commands:
   * Copy the template above
   * Adjust IMAGE_NAME and CONTAINER_NAME
   * Update help text
   * Add tool-specific commands if needed

4. **Create README.md** with:
   * Tool description and link
   * Quick start guide
   * Authentication instructions (if applicable)
   * Command reference

5. **Test the implementation**:

```bash
./manage.sh build
./manage.sh test
./manage.sh run --help
./manage.sh clean
```

6. **Update docker/README.md** with the new tool in the summary table.

## Troubleshooting

### Image Build Fails

* Check if the source repository still exists
* Verify Go/language version compatibility
* Check for breaking changes in upstream

### Binary Not Found

* Verify COPY path in Dockerfile
* Check ENTRYPOINT and PATH settings
* Use `./manage.sh shell` to explore container

### Permission Denied

* Ensure manage.sh has execute permission: `chmod +x manage.sh`
* Check if binary was built with execute permission

### Container Already Exists

* Run `./manage.sh clean` before rebuilding
* Or use a different container name via environment variable
