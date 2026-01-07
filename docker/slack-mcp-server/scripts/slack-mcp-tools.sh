#!/bin/sh
# =============================================================================
# WIP: List Available MCP Tools for Slack Server
# =============================================================================
# STATUS: Work In Progress - To Be Tested
#
# This script lists all available MCP tools from the Slack MCP server.
# Useful for discovering what operations are available.
#
# Usage:
#   ./slack-mcp-tools.sh [format]
#
# Examples:
#   ./slack-mcp-tools.sh              # Table format (default)
#   ./slack-mcp-tools.sh table        # Table format
#   ./slack-mcp-tools.sh json         # JSON format
#   ./slack-mcp-tools.sh pretty       # Pretty-printed JSON
#
# =============================================================================

FORMAT="${1:-table}"

# The MCP server command (runs in same container)
MCP_SERVER="slack-mcp-server"

echo "# Listing available Slack MCP tools..."
echo "# WIP: This script is untested - please report issues"
echo ""

mcp tools --format "$FORMAT" $MCP_SERVER
