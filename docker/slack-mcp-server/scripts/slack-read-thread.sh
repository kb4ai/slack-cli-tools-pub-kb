#!/bin/sh
# =============================================================================
# WIP: Read Slack Thread Replies via MCP
# =============================================================================
# STATUS: Work In Progress - To Be Tested
#
# This script wraps mcptools to read replies in a Slack thread.
#
# Usage:
#   ./slack-read-thread.sh <channel_id> <thread_ts> [limit]
#
# Examples:
#   ./slack-read-thread.sh C1234567890 1234567890.123456
#   ./slack-read-thread.sh C1234567890 1234567890.123456 "50"
#
# Note:
#   - channel_id: The channel containing the thread
#   - thread_ts: The timestamp of the parent message (from message URL or API)
#
# =============================================================================

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: channel_id and thread_ts are required"
    echo "Usage: $0 <channel_id> <thread_ts> [limit]"
    echo "Example: $0 C1234567890 1234567890.123456"
    exit 1
fi

CHANNEL_ID="$1"
THREAD_TS="$2"
LIMIT="${3:-100}"

# The MCP server command (runs in same container)
MCP_SERVER="slack-mcp-server"

echo "# Reading thread replies (channel: $CHANNEL_ID, thread: $THREAD_TS)..."
echo "# WIP: This script is untested - please report issues"
echo ""

mcp call conversations_replies \
    --params "{\"channel_id\":\"$CHANNEL_ID\",\"thread_ts\":\"$THREAD_TS\",\"limit\":\"$LIMIT\"}" \
    --format pretty \
    $MCP_SERVER
