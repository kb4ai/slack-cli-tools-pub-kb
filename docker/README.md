# Docker Images for Slack CLI Tools

This directory contains Dockerfiles and management scripts for each Slack CLI tool in the comparison.

## Directory Structure

Each tool has its own subdirectory with:

* `Dockerfile` - Minimal container image (Alpine/Debian-slim/Distroless where possible)
* `README.md` - Tool-specific documentation
* `manage.sh` - Management script for building, testing, and running

## Quick Start

```bash
# Build and test a specific tool
cd slackdump
./manage.sh build
./manage.sh test
./manage.sh shell

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
| `clean` | Remove container and image |
| `logs` | Show container logs |

## Image Naming Convention

All images are prefixed with `slack-cli-tools-` to avoid collisions:

* `slack-cli-tools-slackdump`
* `slack-cli-tools-slackcat`
* `slack-cli-tools-slack-term`
* etc.

## Base Images Used

| Language | Base Image | Rationale |
|----------|------------|-----------|
| Go | `golang:alpine` → `alpine:3.19` | Multi-stage, static binary |
| Node/TS | `node:20-alpine` | Small footprint |
| Bun | `oven/bun:alpine` | Native Bun support |
| Python | `python:3.12-alpine` | Minimal Python |
| Bash | `alpine:3.19` | Just needs bash/curl/jq |
| PHP | `php:8.3-cli-alpine` | PHP CLI only |
| Java | `eclipse-temurin:21-jre-alpine` | JRE only, not JDK |
| C | `debian:bookworm-slim` | Needs libpurple libs |

## Testing All Tools

```bash
# Test all tools (from docker directory)
for dir in */; do
    echo "=== Testing $dir ==="
    cd "$dir"
    ./manage.sh build && ./manage.sh test && ./manage.sh clean
    cd ..
done
```
