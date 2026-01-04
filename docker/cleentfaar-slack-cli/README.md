# cleentfaar/slack-cli Docker Setup

A Dockerized PHP CLI tool for interacting with the Slack API.

## About

[cleentfaar/slack-cli](https://github.com/cleentfaar/slack-cli) is a command-line interface for Slack built with PHP. It provides commands for various Slack API operations including:

* Sending messages to channels
* Managing users and channels
* File uploads
* And more Slack API interactions

## Quick Start

Build the image:

```bash
./manage.sh build
```

Run with help:

```bash
./manage.sh run --help
```

## Configuration

The tool requires Slack API credentials. Set the `SLACK_API_TOKEN` environment variable:

```bash
docker run --rm -e SLACK_API_TOKEN=xoxb-your-token slack-cli-tools-cleentfaar-slack-cli chat:post-message --channel=#general --text="Hello"
```

## Management Commands

The `manage.sh` script provides these commands:

* `status` - Show container and image status
* `build` - Build the Docker image
* `start` - Start a container
* `stop` - Stop the container
* `shell` - Open a shell in the container
* `run` - Run slack-cli commands
* `test` - Verify the binary works
* `verify` - Alias for test
* `clean` - Remove container and image
* `logs` - Show container logs

## Example Usage

```bash
# Build the image
./manage.sh build

# Test the installation
./manage.sh test

# Run a command
./manage.sh run chat:post-message --channel=#general --text="Hello from Docker"

# Clean up
./manage.sh clean
```

## Source

* GitHub: https://github.com/cleentfaar/slack-cli
