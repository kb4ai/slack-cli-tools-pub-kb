# Docker Images for Slack CLI Tools

This directory contains Dockerfiles and management scripts for 11 Slack CLI tools.

## Summary

| Project | Language | Base Image | Notes |
|---------|----------|------------|-------|
| slackdump | Go | alpine:3.19 | Workspace exporter |
| slack-term | Go | alpine:3.19 | Terminal UI client |
| slackcat | Go | alpine:3.19 | Pipe content to Slack |
| slack-mcp-server | TypeScript | node:20-alpine | MCP server for AI |
| shaharia-slackcli | Bun/TS | oven/bun:alpine | Bun-based CLI |
| slackapi-slack-cli | Node.js | node:20-alpine | Official Slack CLI (app dev) |
| rockymadden-slack-cli | Bash | alpine:3.19 | curl/jq based |
| regisb-slack-cli | Python | python:3.12-alpine | pip install |
| cleentfaar-slack-cli | PHP | php:8.3-cli-alpine | Composer |
| yfiton | Java | eclipse-temurin:21-jre-alpine | Abandoned (2017) |
| slack-libpurple | C | debian:bookworm-slim | Pidgin/Finch plugin |

## Directory Structure

Each tool has its own subdirectory with:

* `Dockerfile` - Minimal container image (Alpine/Debian-slim where possible)
* `README.md` - Tool-specific documentation
* `manage.sh` - Management script for building, testing, and running

## Quick Start

```bash
# Build and test a specific tool
cd slackdump
./manage.sh build
./manage.sh test

# Run the tool
./manage.sh run --help

# Cleanup when done
./manage.sh clean
```

## Common manage.sh Commands

| Command | Description |
|---------|-------------|
| `status` | Show container/image status |
| `build` | Build the Docker image |
| `start` | Start container in background |
| `stop` | Stop running container |
| `shell` | Interactive shell in container |
| `run` | Run the CLI tool (pass args after) |
| `test` | Verify binary works (help output) |
| `verify` | Verify image integrity |
| `clean` | Stop container and remove image |
| `logs` | Show container logs |

## Cleanup

### Clean a single tool

```bash
cd slackdump
./manage.sh clean
```

### Clean all tools at once

```bash
./cleanup_all_dockers.sh
```

The `clean` command in each `manage.sh` properly stops running containers before removing them (using `docker stop` then `docker rm`), so no `--force` flag is needed.

## Image Naming Convention

All images are prefixed with `slack-cli-tools-` to avoid collisions:

* `slack-cli-tools-slackdump`
* `slack-cli-tools-slackcat`
* `slack-cli-tools-slack-term`
* etc.

## Testing All Tools

```bash
# Build, test, and clean all tools
for dir in */; do
    [[ -f "${dir}manage.sh" ]] || continue
    echo "=== Testing $dir ==="
    (cd "$dir" && ./manage.sh build && ./manage.sh test && ./manage.sh clean)
done
```
