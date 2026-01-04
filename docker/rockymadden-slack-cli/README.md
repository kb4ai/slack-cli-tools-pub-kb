# rockymadden/slack-cli Docker Setup

Docker containerization for [rockymadden/slack-cli](https://github.com/rockymadden/slack-cli), a powerful Bash-based command-line interface for Slack.

## Overview

This Docker setup packages the slack-cli tool in an Alpine Linux container with all required dependencies (bash, curl, jq, git).

## Quick Start

```bash
# Build the image
./manage.sh build

# Test the installation
./manage.sh test

# Run slack commands
./manage.sh run --help
./manage.sh run init
./manage.sh run send -c general -m "Hello from CLI"

# Interactive shell
./manage.sh shell
```

## Management Commands

| Command | Description |
|---------|-------------|
| `status` | Show container and image status |
| `build` | Build the Docker image |
| `start` | Start the container |
| `stop` | Stop the container |
| `shell` | Open interactive shell in container |
| `run` | Run slack command with arguments |
| `test` | Verify slack-cli works correctly |
| `verify` | Alias for test |
| `clean` | Remove container and image |
| `logs` | Show container logs |

## Configuration

To use slack-cli, you need to initialize it with your Slack token:

```bash
# Interactive initialization
./manage.sh run init

# Or set environment variable
export SLACK_CLI_TOKEN="xoxp-your-token-here"
./manage.sh run send -c general -m "Hello!"
```

## Environment Variables

* `SLACK_CLI_TOKEN` - Your Slack API token

## Image Details

* Base: Alpine Linux 3.19
* Dependencies: bash, curl, jq, git
* Image name: `slack-cli-tools-rockymadden-slack-cli`
