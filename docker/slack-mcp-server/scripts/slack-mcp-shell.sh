#!/bin/sh
# =============================================================================
# WIP: Interactive MCP Shell for Slack Server
# =============================================================================
# STATUS: Work In Progress - To Be Tested
#
# This script starts an interactive MCP shell for exploring and calling
# Slack MCP tools interactively.
#
# Usage:
#   ./slack-mcp-shell.sh
#
# In the shell, you can:
#   - Type 'tools' to list available tools
#   - Type 'resources' to list available resources
#   - Call tools directly: channels_list {"channel_types":"public_channel"}
#   - Type '/h' for help
#   - Type '/q' to quit
#
# =============================================================================

# The MCP server command (runs in same container)
MCP_SERVER="slack-mcp-server"

echo "# Starting interactive Slack MCP shell..."
echo "# WIP: This script is untested - please report issues"
echo ""
echo "# Tips:"
echo "#   - Type 'tools' to see available operations"
echo "#   - Type '/h' for help"
echo "#   - Type '/q' to quit"
echo ""

mcp shell $MCP_SERVER
