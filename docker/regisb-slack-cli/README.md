# regisb/slack-cli Docker Setup

A Docker container for [regisb/slack-cli](https://github.com/regisb/slack-cli), a Python-based command-line interface for Slack.

## Features

* Send messages to Slack channels
* Upload files
* Pipe command output directly to Slack
* Lightweight Python-based CLI

## Quick Start

```bash
# Build the image
./manage.sh build

# Test the installation
./manage.sh test

# Run with custom arguments
./manage.sh run -- -t "your-slack-token" -d "#general" "Hello from Docker!"
```

## Configuration

The slack-cli tool requires a Slack API token. You can provide it via:

* `-t` / `--token` flag
* `SLACK_TOKEN` environment variable

To get a token, create a Slack App at https://api.slack.com/apps with the following scopes:

* `chat:write` - Send messages
* `files:write` - Upload files
* `channels:read` - List channels

## Usage Examples

### Send a message

```bash
docker run --rm -e SLACK_TOKEN="xoxb-your-token" slack-cli-tools-regisb-slack-cli \
    -d "#general" "Hello from Docker!"
```

### Pipe output to Slack

```bash
echo "System status: OK" | docker run --rm -i -e SLACK_TOKEN="xoxb-your-token" \
    slack-cli-tools-regisb-slack-cli -d "#alerts"
```

### Upload a file

```bash
docker run --rm -e SLACK_TOKEN="xoxb-your-token" \
    -v $(pwd):/data slack-cli-tools-regisb-slack-cli \
    -f /data/report.txt -d "#reports"
```

## Management Script

The `manage.sh` script provides convenient commands:

| Command | Description |
|---------|-------------|
| `status` | Show container and image status |
| `build` | Build the Docker image |
| `start` | Start the container |
| `stop` | Stop the container |
| `shell` | Open an interactive shell in the container |
| `run` | Run slack-cli with custom arguments |
| `test` | Verify the installation works |
| `verify` | Alias for test |
| `clean` | Remove container and image |
| `logs` | Show container logs |

## Links

* GitHub: https://github.com/regisb/slack-cli
* PyPI: https://pypi.org/project/slack-cli/
