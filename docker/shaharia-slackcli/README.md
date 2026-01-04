# shaharia-lab/slackcli Docker Setup

Docker containerization for [shaharia-lab/slackcli](https://github.com/shaharia-lab/slackcli) - a command-line interface for Slack built with Bun/TypeScript.

## Overview

This setup provides a containerized version of the slackcli tool, allowing you to interact with Slack from the command line without installing dependencies on your host system.

## Quick Start

```bash
# Build the image
./manage.sh build

# Test the installation
./manage.sh test

# Run with arguments
./manage.sh run --help
```

## Management Script Commands

| Command | Description |
|---------|-------------|
| `status` | Show container and image status |
| `build` | Build the Docker image |
| `start` | Start the container |
| `stop` | Stop the container |
| `shell` | Open a shell in the container |
| `run` | Run slackcli with arguments |
| `test` | Run basic tests (--help check) |
| `verify` | Verify the binary works |
| `clean` | Remove container and image |
| `logs` | Show container logs |

## Environment Variables

The slackcli tool requires Slack API credentials. Set these environment variables:

* `SLACK_TOKEN` - Your Slack API token

Example:

```bash
export SLACK_TOKEN="xoxb-your-token-here"
./manage.sh run channels list
```

## Image Details

* **Base Image**: `oven/bun:alpine`
* **Image Name**: `slack-cli-tools-shaharia-slackcli`
* **Container Name**: `shaharia-slackcli-test`
