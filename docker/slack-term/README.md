# slack-term Docker Setup

Docker containerization for [slack-term](https://github.com/jpbruinsslot/slack-term) - a Slack client for your terminal.

## Overview

slack-term is a Go-based TUI (Terminal User Interface) application that allows you to interact with Slack from the command line.

## Quick Start

```bash
# Build the image
./manage.sh build

# Test the binary works
./manage.sh test

# Run slack-term (requires config)
./manage.sh run

# Clean up
./manage.sh clean
```

## Configuration

slack-term requires a configuration file with your Slack token. Create a `slack-term.json` file:

```json
{
    "slack_token": "xoxs-your-slack-token"
}
```

Then mount it when running:

```bash
docker run -it --rm \
    -v /path/to/slack-term.json:/root/.config/slack-term/config \
    slack-cli-tools-slack-term
```

## Management Script Commands

| Command | Description |
|---------|-------------|
| `status` | Show container and image status |
| `build` | Build the Docker image |
| `start` | Start the container interactively |
| `stop` | Stop the running container |
| `shell` | Open a shell in the container |
| `run` | Run slack-term interactively |
| `test` | Verify the binary works |
| `verify` | Alias for test |
| `clean` | Remove container and image |
| `logs` | Show container logs |

## License

slack-term is licensed under the MIT License. See the [upstream repository](https://github.com/jpbruinsslot/slack-term) for details.
