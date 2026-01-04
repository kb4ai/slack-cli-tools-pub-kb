# Slack MCP Server Docker Setup

Docker setup for [korotovsky/slack-mcp-server](https://github.com/korotovsky/slack-mcp-server) - a Model Context Protocol (MCP) server for Slack integration.

## Overview

This MCP server enables AI assistants (like Claude) to interact with Slack workspaces through the MCP protocol. It provides tools for:

* Reading messages from channels
* Posting messages to channels
* Managing Slack workspace interactions

## Prerequisites

* Docker installed and running
* Slack Bot Token with appropriate permissions

## Usage

### Build the Image

```bash
./manage.sh build
```

### Run with Slack Token

```bash
SLACK_BOT_TOKEN="xoxb-your-token" ./manage.sh run
```

### Available Commands

```bash
./manage.sh status  # Check container/image status
./manage.sh build   # Build the Docker image
./manage.sh start   # Start the container
./manage.sh stop    # Stop the container
./manage.sh shell   # Open shell in container
./manage.sh run     # Run interactively
./manage.sh test    # Verify module loads
./manage.sh verify  # Alias for test
./manage.sh clean   # Remove container and image
./manage.sh logs    # Show container logs
```

## MCP Configuration

To use with Claude Desktop or other MCP clients, add to your MCP configuration:

```json
{
  "mcpServers": {
    "slack": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "SLACK_BOT_TOKEN", "slack-cli-tools-slack-mcp-server"],
      "env": {
        "SLACK_BOT_TOKEN": "xoxb-your-token"
      }
    }
  }
}
```

## Environment Variables

* `SLACK_BOT_TOKEN` - Required. Your Slack Bot OAuth Token (starts with `xoxb-`)

## References

* [korotovsky/slack-mcp-server](https://github.com/korotovsky/slack-mcp-server)
* [Model Context Protocol](https://modelcontextprotocol.io/)
