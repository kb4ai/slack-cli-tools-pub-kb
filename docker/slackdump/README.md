# slackdump Docker Setup

Docker containerization for [rusq/slackdump](https://github.com/rusq/slackdump) - a Go CLI tool for exporting Slack workspace data including messages, files, and users.

## Features

* Export conversations, threads, and files from Slack workspaces
* Multiple authentication methods (browser login, token, cookies)
* Supports various output formats (JSON, text, Mattermost import)
* Can dump entire workspaces or specific channels/DMs

## Quick Start

```bash
# Build the image
./manage.sh build

# Verify the build
./manage.sh test

# Run slackdump with arguments
./manage.sh run -- version

# Interactive shell
./manage.sh shell
```

## Usage Examples

```bash
# Show help
./manage.sh run -- --help

# Export a channel (requires authentication setup)
./manage.sh run -- export -o /data C12345678

# List available options
./manage.sh run -- list --help
```

## Authentication

slackdump supports multiple authentication methods. When running in Docker, you may need to mount volumes for:

* Token-based auth: Pass `SLACK_TOKEN` environment variable
* Cookie-based auth: Mount a cookies file
* Browser login: May require additional setup for headless environments

See the [slackdump documentation](https://github.com/rusq/slackdump#authentication) for details.

## Management Commands

| Command | Description |
|---------|-------------|
| `./manage.sh build` | Build the Docker image |
| `./manage.sh test` | Run tests to verify the binary works |
| `./manage.sh verify` | Alias for test |
| `./manage.sh run -- [args]` | Run slackdump with arguments |
| `./manage.sh shell` | Start an interactive shell in the container |
| `./manage.sh status` | Show container and image status |
| `./manage.sh logs` | View container logs |
| `./manage.sh stop` | Stop running container |
| `./manage.sh clean` | Remove container and image |
