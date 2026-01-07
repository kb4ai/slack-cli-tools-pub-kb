#!/bin/sh
# =============================================================================
# WIP: List Slack Channels via MCP
# =============================================================================
# STATUS: Work In Progress - To Be Tested
#
# This script wraps mcptools to list available Slack channels.
#
# Usage:
#   ./slack-list-channels.sh [channel_types] [limit]
#
# Examples:
#   ./slack-list-channels.sh                              # All channel types
#   ./slack-list-channels.sh "public_channel"             # Only public
#   ./slack-list-channels.sh "public_channel,im" 50       # Public + DMs, limit 50
#
# =============================================================================

CHANNEL_TYPES="${1:-public_channel,private_channel,mpim,im}"
LIMIT="${2:-100}"

# The MCP server command (runs in same container)
MCP_SERVER="slack-mcp-server"

echo "# Listing Slack channels (types: $CHANNEL_TYPES, limit: $LIMIT)..."
echo "# WIP: This script is untested - please report issues"
echo ""

mcp call channels_list \
    --params "{\"channel_types\":\"$CHANNEL_TYPES\",\"limit\":\"$LIMIT\"}" \
    --format pretty \
    $MCP_SERVER
