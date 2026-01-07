# Slack MCP Server Docker Setup

Docker setup for [korotovsky/slack-mcp-server](https://github.com/korotovsky/slack-mcp-server) - a Model Context Protocol (MCP) server for Slack integration.

**This container includes [f/mcptools](https://github.com/f/mcptools) for CLI access to the MCP server.**

## Overview

This MCP server enables AI assistants (like Claude) to interact with Slack workspaces through the MCP protocol. It provides tools for:

* Reading messages from channels
* Posting messages to channels
* Managing Slack workspace interactions

Additionally, with the included [f/mcptools](https://github.com/f/mcptools), you can interact with the MCP server directly from the command line without needing an AI assistant.

## Prerequisites

* Docker installed and running
* Slack token (see Authentication below)

## Quick Start

This tool lets **you** access **your own** Slack workspace - it's not a bot service.

```bash
# 1. See authentication options
./manage.sh auth

# 2. Build the image
./manage.sh build

# 3. Get tokens from your browser (easiest method):
#    - Open Slack in browser, F12 for DevTools
#    - Console: JSON.parse(localStorage.localConfig_v2).teams[document.location.pathname.match(/^\/client\/([A-Z0-9]+)/)[1]].token
#    - Application > Cookies > 'd' cookie value

# 4. Test with your tokens
SLACK_MCP_XOXC_TOKEN=xoxc-... SLACK_MCP_XOXD_TOKEN=xoxd-... ./manage.sh mcp-tools

# 5. List your channels
SLACK_MCP_XOXC_TOKEN=xoxc-... SLACK_MCP_XOXD_TOKEN=xoxd-... ./manage.sh list-channels
```

## Authentication

Run `./manage.sh auth` for detailed instructions. Summary:

### Option 1: Browser Session (Easiest - No Setup)

Extract tokens from your logged-in Slack browser session. No app creation needed.

```bash
export SLACK_MCP_XOXC_TOKEN="xoxc-..."
export SLACK_MCP_XOXD_TOKEN="xoxd-..."
./manage.sh list-channels
```

### Option 2: User OAuth Token (Recommended for Long-Term)

Create a Slack app with User Token Scopes for persistent access with full functionality.

1. Create app at https://api.slack.com/apps
2. Add User Token Scopes: `channels:history`, `channels:read`, `groups:history`, `groups:read`, `im:history`, `im:read`, `mpim:history`, `mpim:read`, `users:read`, `search:read`
3. Install to workspace and copy the `xoxp-...` token

```bash
export SLACK_MCP_XOXP_TOKEN="xoxp-your-token"
./manage.sh mcp-tools
```

### Option 3: Bot Token (Limited)

Bot tokens have restrictions: invited channels only, no search API.

```bash
export SLACK_BOT_TOKEN="xoxb-your-token"
./manage.sh mcp-tools  # Limited functionality
```

## Usage

### Build the Image

```bash
./manage.sh build
```

### Run with Slack Token

```bash
SLACK_BOT_TOKEN="xoxb-your-token" ./manage.sh run
```

### Docker Management Commands

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

## CLI Access via mcptools

This container includes [f/mcptools](https://github.com/f/mcptools) - the "Swiss Army Knife" for MCP servers. This provides a universal CLI interface to interact with any MCP server.

### Why mcptools?

Instead of building custom CLI wrappers for each MCP server, mcptools provides:

1. **One CLI for ALL MCP servers** - Same interface for Slack, GitHub, filesystem, etc.
2. **No custom wrappers needed** - Works with any MCP-compatible server
3. **Consistent interface** - Learn once, use everywhere
4. **Easy debugging** - Explore available tools and test them interactively

### CLI Commands (WIP - To Be Tested)

```bash
# List available MCP tools
SLACK_BOT_TOKEN=xoxb-... ./manage.sh mcp-tools

# Start interactive MCP shell
SLACK_BOT_TOKEN=xoxb-... ./manage.sh mcp-shell

# Call any MCP tool with JSON params
SLACK_BOT_TOKEN=xoxb-... ./manage.sh mcp-call channels_list '{"channel_types":"public_channel"}'
```

### Convenience Commands (WIP - To Be Tested)

```bash
# List Slack channels
SLACK_BOT_TOKEN=xoxb-... ./manage.sh list-channels
SLACK_BOT_TOKEN=xoxb-... ./manage.sh list-channels "public_channel" 50

# Read channel history
SLACK_BOT_TOKEN=xoxb-... ./manage.sh read-channel C1234567890
SLACK_BOT_TOKEN=xoxb-... ./manage.sh read-channel C1234567890 7d  # Last 7 days

# Read thread replies
SLACK_BOT_TOKEN=xoxb-... ./manage.sh read-thread C1234567890 1234567890.123456
```

### Available MCP Tools

The Slack MCP server provides these tools:

| Tool | Description |
|------|-------------|
| `channels_list` | List available channels and conversations |
| `conversations_history` | Read messages from channels/DMs |
| `conversations_replies` | Fetch threaded message replies |
| `conversations_add_message` | Post messages (disabled by default) |
| `conversations_search_messages` | Search messages (unavailable with bot tokens) |

### Interactive Shell Example

```bash
$ SLACK_BOT_TOKEN=xoxb-... ./manage.sh mcp-shell
mcp > tools                    # List available tools
mcp > channels_list {"channel_types":"public_channel"}
mcp > /h                       # Get help
mcp > /q                       # Quit
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

Authentication (use one):

* `SLACK_MCP_XOXC_TOKEN` + `SLACK_MCP_XOXD_TOKEN` - Browser session tokens (easiest)
* `SLACK_MCP_XOXP_TOKEN` - User OAuth token (recommended for long-term)
* `SLACK_BOT_TOKEN` - Bot token (limited functionality)

Priority when multiple set: `xoxp` > `xoxb` > `xoxc/xoxd`

## References

* [korotovsky/slack-mcp-server](https://github.com/korotovsky/slack-mcp-server)
* [f/mcptools](https://github.com/f/mcptools) - CLI Swiss Army Knife for MCP servers
* [Model Context Protocol](https://modelcontextprotocol.io/)
