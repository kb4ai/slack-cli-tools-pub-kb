# slackcat Docker Setup

Docker containerization for [bcicen/slackcat](https://github.com/bcicen/slackcat) - a CLI tool to pipe content to Slack channels.

## Overview

slackcat is a command-line utility for sending messages and files to Slack. It reads from stdin or files and posts content to specified Slack channels or direct messages.

## Features

* Stream content to Slack channels in real-time
* Upload files to Slack
* Support for multiple Slack workspaces via configuration
* Snippets and file upload modes
* Tee mode for simultaneous stdout and Slack output

## Quick Start

```bash
# Build the Docker image
./manage.sh build

# Test the build
./manage.sh test

# Run with --help
./manage.sh run --help

# Pipe content to Slack (requires configuration)
echo "Hello Slack" | docker run -i --rm \
  -v ~/.slackcat:/root/.slackcat:ro \
  slack-cli-tools-slackcat -c general
```

## Configuration

slackcat requires a configuration file at `~/.slackcat` with your Slack token. See the [official documentation](https://github.com/bcicen/slackcat#configuration) for setup instructions.

To use with Docker, mount your config file:

```bash
docker run -i --rm \
  -v ~/.slackcat:/root/.slackcat:ro \
  slack-cli-tools-slackcat -c channel-name
```

## Management Script

The `manage.sh` script provides common operations:

| Command | Description |
|---------|-------------|
| `status` | Show container and image status |
| `build` | Build the Docker image |
| `start` | Start the container |
| `stop` | Stop the container |
| `shell` | Open a shell in the container |
| `run` | Run slackcat with arguments |
| `test` | Run basic tests |
| `verify` | Verify the binary works |
| `clean` | Remove container and image |
| `logs` | Show container logs |

## Examples

```bash
# Send a message
echo "Hello from Docker!" | docker run -i --rm \
  -v ~/.slackcat:/root/.slackcat:ro \
  slack-cli-tools-slackcat -c general

# Upload a file
docker run -i --rm \
  -v ~/.slackcat:/root/.slackcat:ro \
  -v /path/to/file.txt:/data/file.txt:ro \
  slack-cli-tools-slackcat -c general /data/file.txt

# Tee mode (output to both stdout and Slack)
echo "Hello" | docker run -i --rm \
  -v ~/.slackcat:/root/.slackcat:ro \
  slack-cli-tools-slackcat --tee -c general
```

## License

slackcat is MIT licensed. See the [upstream repository](https://github.com/bcicen/slackcat) for details.
