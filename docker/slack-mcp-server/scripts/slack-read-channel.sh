#!/bin/sh
# =============================================================================
# WIP: Read Slack Channel History via MCP
# =============================================================================
# STATUS: Work In Progress - To Be Tested
#
# This script wraps mcptools to read messages from a Slack channel.
#
# Usage:
#   ./slack-read-channel.sh <channel_id> [limit]
#
# Examples:
#   ./slack-read-channel.sh C1234567890           # Last day of messages
#   ./slack-read-channel.sh C1234567890 "7d"      # Last 7 days
#   ./slack-read-channel.sh C1234567890 "100"     # Last 100 messages
#
# Note: The channel_id can be found via channels_list or in Slack URL.
#
# =============================================================================

if [ -z "$1" ]; then
    echo "Error: channel_id is required"
    echo "Usage: $0 <channel_id> [limit]"
    echo "Example: $0 C1234567890"
    exit 1
fi

CHANNEL_ID="$1"
LIMIT="${2:-1d}"

# The MCP server command (runs in same container)
MCP_SERVER="slack-mcp-server"

echo "# Reading channel history (channel: $CHANNEL_ID, limit: $LIMIT)..."
echo "# WIP: This script is untested - please report issues"
echo ""

mcp call conversations_history \
    --params "{\"channel_id\":\"$CHANNEL_ID\",\"limit\":\"$LIMIT\"}" \
    --format pretty \
    $MCP_SERVER
