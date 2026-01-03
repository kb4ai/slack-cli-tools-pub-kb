# regisb/slack-cli - Comprehensive Feature Analysis

**Repository**: https://github.com/regisb/slack-cli
**Language**: Python (97.4%)
**License**: MIT
**Current Version**: 2.2.10
**Status**: ⚠️ **MAINTENANCE MODE** - Author no longer actively developing; accepting PRs

## Project Status & Limitations

* **Legacy Token Deprecation**: As of December 2020, Slack API no longer allows creation of legacy tokens, making initial setup problematic
* **API Deprecation Issues**: channels.list deprecated June 10, 2020; workaround: modify `slackcli.messaging:iter_resources` → `lambda: slack.client().conversations.list().body["channels"]`
* **Authentication Incompatibility**: Not compatible with new Slack authentication mechanisms
* **Maintenance Only**: Author will review/merge PRs but won't actively develop

---

## Installation & Configuration

### Installation

```bash
pip install slack-cli
```

### Configuration

* **Config Directory**: `~/.config/slack-cli` (Linux default)
* **Custom Location**: Set `SLACK_CLI_CONFIG_ROOT` environment variable
* **Token Storage**: OAuth tokens saved to config directory after first use
* **Token Format**: Requires Slack App creation with OAuth scopes (legacy tokens deprecated)

### Required OAuth Scopes

* `chat:write` - Send messages
* `channels:read` / `groups:read` - Read public/private channels
* `channels:history` / `groups:history` - Read message history
* `files:write` - Upload files
* `users:read` - List/identify users
* `rtm:stream` - Real-time message streaming (legacy RTM API)

---

## Reading/Query Capabilities

### ✅ List Channels

**Implementation**: Via `slack.client().channels.list()`, `slack.client().groups.list()`, `slack.client().im.list()`

**API Methods**:

* `channels.list` (deprecated → use `conversations.list`)
* `groups.list` (deprecated → use `conversations.list`)
* `im.list` - Direct message channels

**Notes**:

* Channel listing used for name resolution and autocomplete
* Cached in memory via singleton pattern
* Performance: "really slow" per source comments - parses entire user list

### ✅ Get Message History

**CLI Option**: `-l LAST, --last LAST`

**Usage**:

```bash
slack-cli -s general --last 10000 > general.log  # Export channel history
slack-cli -s @username --last 50                  # Last 50 DMs
```

**API Methods**:

* `channels.history` (deprecated)
* `groups.history` (deprecated)
* `conversations.history` (replacement)

**Features**:

* Retrieve last N messages from channel/group/user
* Pagination support
* Output to stdout (pipe-friendly)

### ✅ Stream Messages (Real-time)

**CLI Option**: `-s SRC, --src SRC` (repeatable)

**Usage**:

```bash
slack-cli -s general                    # Stream from #general
slack-cli -s general -s dev-team        # Stream from multiple channels
slack-cli -s all                        # Stream from ALL channels
```

**Implementation**:

* **RTM API**: `slack.client().rtm.start()` → WebSocket URL
* **WebSocket**: `websocket.create_connection(url)`
* **Event Loop**: Infinite `connection.recv()` loop, JSON parsing
* **Filtering**:
  - Skips "hello" handshake messages
  - Processes only "message" type events (no subtypes)
  - Filters by source list (or "all")
  - Excludes replayed historical messages (no "team" key)
* **Output**: Formatted via `messaging.format_incoming_message()`

**Graceful Shutdown**: KeyboardInterrupt (Ctrl+C) handling

### ❌ Search Functionality

**Status**: **NOT IMPLEMENTED**

**Workaround**: Use `--last N` with external tools (grep, jq):

```bash
slack-cli -s general --last 10000 | grep "error"
```

**Note**: Slack API provides `search.messages` method but slack-cli doesn't expose it

### ❌ Get Thread Replies

**Status**: **NOT IMPLEMENTED**

**Missing Features**:

* No `thread_ts` parameter support
* No `conversations.replies` API usage
* Cannot read or reply to threaded messages

**Workaround**: None - would require code modification

---

## Output Formats

### ✅ Plain Text (Default)

**Format**:

```
[2018-12-21 14:32:18] @username: Message content
    Attachments or file metadata (indented)
```

**Features**:

* Timestamp `[YYYY-MM-DD HH:MM:SS]`
* Username/channel ID → name resolution
* User mentions `<@U123ABC>` → `@username`
* Channel mentions `<#C123ABC>` → `#channel-name`
* Emoji conversion `:smile:` → 😄 (via 59KB emoji.json)
* Hyperlink formatting (blue + underline)
* Indented attachments/nested content

### ✅ Colored Output

**Control**: `SLACK_CLI_NO_COLOR=1` disables colors

**Color Features**:

* **ANSI 256-color codes**: Terminal compatibility detection
* **Fingerprint-based colors**: MD5(fingerprint) % 256 → consistent user/channel colors
* **Special colors**:
  - `#general` → Slack purple
  - Hyperlinks → blue + underline
* **Effects**: bold, faint, standout, underline, blink

**Platform Support**:

* Linux/macOS: Native support
* Windows: Requires ANSICON
* Auto-disabled if: Pocket PC, non-TTY, env var set

### ✅ Pipe-friendly

**Features**:

* Stdout output (no stderr noise)
* Line-buffered
* Color auto-disabled for non-TTY
* Redirect/pipe compatible:

```bash
slack-cli -s general --last 100 | grep "ERROR" > errors.txt
```

### ✅ Verbatim/Code Formatting

**CLI Option**: `--pre`

**Usage**:

```bash
tail -f /var/log/nginx/access.log | slack-cli -d devteam --pre
```

**Output**: Wraps content in triple backticks (Slack code block)

### ❌ JSON Output

**Status**: **NOT IMPLEMENTED**

**Notes**:

* JSON only used internally for API communication (`json.dumps(profile)`)
* No `--json` flag or structured output option
* Workaround: Parse text output with custom scripts

### ❌ Streaming Format (Special)

**Status**: Uses plain text format (see above)

**Note**: Real-time streaming uses same format as `--last` output

---

## Communication Features

### ✅ Send Message

**CLI Option**: `-d DST, --dst DST`

**Usage**:

```bash
slack-cli -d general "Hello everyone!"
slack-cli -d @username "Direct message"
slack-cli -d '#channel-name' "Message to channel"
```

**API Method**: `chat.postMessage`

**Features**:

* User mention conversion: `@username` → `<@U123ABC>`
* Channel name resolution
* Emoji support `:emoji:` → Unicode
* stdin piping support
* Status updates: `/status :office: Working from office`

**Status Update Special Syntax**:

```bash
slack-cli -d general "/status :house: Working from home"
slack-cli -d general "/status clear"  # Clear status
```

### ❌ Reply to Thread

**Status**: **NOT IMPLEMENTED**

**Missing**:

* No `thread_ts` parameter
* Cannot specify parent message
* No threading awareness

### ✅ Send to Multiple Channels

**Status**: **PARTIAL SUPPORT**

**Current Behavior**: Single `-d DST` per invocation

**Workaround**: Shell loops

```bash
for channel in general dev-team announcements; do
  slack-cli -d "$channel" "Deployment complete"
done
```

### ✅ Team/Workspace Switching

**CLI Option**: `-T TEAM, --team TEAM`

**Usage**:

```bash
slack-cli -T myworkspace -d general "Message"
slack-cli -T otherworkspace -d general "Message"
```

**Features**:

* Multi-team token storage in `~/.config/slack-cli/`
* Team domain identifier (from Slack URL: `teamname.slack.com`)
* Defaults to last used team
* Token persistence per team

**Team Management**:

* `slack.client().team.info()` retrieves team metadata
* Tokens saved separately per team domain
* Automatic team detection on first use

---

## Attachment Handling

### ✅ File Upload

**CLI Option**: `-f FILE, --file FILE`

**Usage**:

```bash
slack-cli -d general -f report.pdf
slack-cli -d @user -f screenshot.png
```

**API Method**: `files.upload`

**Features**:

* Any file type supported
* Sent to specified destination (channel/user)
* File metadata displayed in message

**Limitations**:

* Single file per invocation
* Cannot add message text with `-f` (mutually exclusive with message positional args)

### ❌ File Download

**Status**: **NOT IMPLEMENTED**

**Missing**:

* Cannot download files from Slack
* No `files.download` or URL fetching

**Alternative Tools**:

* [auino/slack-downloader](https://github.com/auino/slack-downloader)
* [n8n workflow for media downloads](https://n8n.io/workflows/4039-download-media-files-from-slack-messages/)

### ✅ Image/Media Display

**Status**: **PARTIAL** (metadata only)

**Behavior**:

* File attachments shown as indented metadata
* No inline image rendering (terminal limitation)
* Shows: filename, title, filetype, size

### ❌ Attachment Search/Filter

**Status**: **NOT IMPLEMENTED**

---

## Query Options

### ✅ Message Count Limits

**CLI Option**: `-l LAST, --last LAST`

**Usage**:

```bash
slack-cli -s general --last 50    # Last 50 messages
slack-cli -s general --last 10000 # Large history export
```

**Behavior**:

* Batch mode: Retrieve N messages and exit
* Streaming mode: Omit `--last` for real-time stream
* Pagination handled internally

### ❌ Date Filtering

**Status**: **NOT IMPLEMENTED**

**Missing**:

* No `--after`, `--before`, `--on` flags
* No timestamp parameters
* Cannot filter by date range

**Workaround**: Retrieve all messages, filter externally

```bash
slack-cli -s general --last 10000 | awk '/2025-01-15/,/2025-01-20/'
```

### ✅ Channel Selection

**CLI Option**: `-s SRC, --src SRC` (receive) / `-d DST, --dst DST` (send)

**Features**:

* Multiple `-s` flags: `slack-cli -s general -s dev-team`
* Special value `all`: Stream from all channels
* Autocomplete support (bash)
* Channel/user/group name resolution

**Autocomplete Setup**:

```bash
eval "$(register-python-argcomplete slack-cli)"
```

### ❌ Advanced Query Filters

**Status**: **NOT IMPLEMENTED**

**Missing**:

* No search query DSL
* No sender filter (from:@user)
* No keyword search
* No reaction filters
* No attachment type filters

---

## Special Features

### Execute Commands and Send Output

**CLI Option**: `--run`

**Usage**:

```bash
slack-cli -d devops --run "uptime"
slack-cli -d monitoring --run "docker ps"
```

**Behavior**:

* Executes message as shell command
* Sends both command and output to destination
* Useful for monitoring/alerting

### Send as Bot User

**CLI Option**: `-u USER, --user USER`

**Usage**:

```bash
slack-cli -d general -u "Deploy Bot" "Deployment started"
```

**Feature**: Customize bot display name (requires bot token)

### Emoji Support

**Environment**: `SLACK_CLI_NO_EMOJI=1` disables

**Features**:

* 59KB emoji.json database
* Shortcode → Unicode: `:smile:` → 😄
* Update script: `python -c "from slackcli.emoji import Emojis; Emojis.download()"`

### Stdin Piping

**Usage**:

```bash
cat log.txt | slack-cli -d devops --pre
tail -f app.log | grep ERROR | slack-cli -d alerts
```

**Features**:

* Read from stdin when no message positional args
* `--pre` for code block formatting
* Real-time pipe support

---

## Source Code Structure

**Package Files** (`slackcli/`):

| File | Size | Purpose |
|------|------|---------|
| `cli.py` | 5,798 B | Argument parsing, main entry point |
| `messaging.py` | 6,187 B | Send/receive messages, formatting |
| `stream.py` | 1,192 B | RTM WebSocket streaming |
| `names.py` | 3,565 B | User/channel name resolution |
| `slack.py` | 2,306 B | Slack API client initialization |
| `token.py` | 2,865 B | Token storage/retrieval |
| `ui.py` | 1,802 B | Color/formatting utilities |
| `emoji.py` | 2,815 B | Emoji processing |
| `emoji.json` | 59,495 B | Emoji database |
| `errors.py` | 90 B | Exception definitions |

**Dependencies**:

* `slacker` - Slack API wrapper
* `websocket-client` - RTM streaming
* `argcomplete` - Bash autocomplete

---

## Version History Highlights

| Version | Date | Key Features |
|---------|------|--------------|
| v1.0 | 2017-07-06 | Initial release, single command consolidation |
| v1.0.3 | 2017-09-04 | Added `--last` flag |
| v2.0.0 | 2017-09-09 | Multi-team support, streaming improvements |
| v2.1.0 | 2018-12-07 | `-s all` streaming, performance improvements |
| v2.1.2 | 2018-12-21 | Bash autocomplete |
| v2.2.1 | 2018-12-22 | Colorized output, emoji support |
| v2.2.6 | 2020-01-22 | Status updates |
| v2.2.7 | 2020-05-11 | `/status clear`, no-writable-config support |
| v2.2.10 | Current | Last PyPI release (maintenance mode) |

---

## Feature Comparison Matrix

### Reading/Query

| Feature | Status | CLI Option | API Method | Notes |
|---------|--------|------------|------------|-------|
| List channels | ✅ | (internal) | `channels.list` | Deprecated API, cached |
| Message history | ✅ | `--last N` | `channels.history` | Batch retrieval |
| Real-time stream | ✅ | `-s SRC` | `rtm.start` | WebSocket RTM |
| Search messages | ❌ | - | - | Not implemented |
| Thread replies | ❌ | - | - | Not implemented |
| Date filtering | ❌ | - | - | Use external tools |

### Output Formats

| Format | Status | Control | Notes |
|--------|--------|---------|-------|
| Plain text | ✅ | Default | Timestamped, formatted |
| Colored | ✅ | `SLACK_CLI_NO_COLOR=1` | ANSI 256-color |
| Pipe-friendly | ✅ | Auto-detect | stdout, line-buffered |
| Verbatim/code | ✅ | `--pre` | Triple backticks |
| JSON | ❌ | - | Not available |
| Streaming | ✅ | `-s` without `--last` | Real-time display |

### Communication

| Feature | Status | CLI Option | Notes |
|---------|--------|------------|-------|
| Send message | ✅ | `-d DST` | Channel/user/group |
| Reply to thread | ❌ | - | No thread support |
| Multiple channels | 🟡 | - | Use shell loops |
| Team switching | ✅ | `-T TEAM` | Multi-workspace |
| Send as bot | ✅ | `-u USER` | Custom username |
| Status update | ✅ | `/status ...` | Special syntax |

### Attachments

| Feature | Status | CLI Option | Notes |
|---------|--------|------------|-------|
| Upload file | ✅ | `-f FILE` | Any file type |
| Download file | ❌ | - | Not implemented |
| Image display | 🟡 | - | Metadata only |
| Media support | 🟡 | - | Upload only |

### Query Options

| Feature | Status | CLI Option | Notes |
|---------|--------|------------|-------|
| Count limits | ✅ | `--last N` | Batch size |
| Date filter | ❌ | - | Not implemented |
| Channel select | ✅ | `-s SRC` | Repeatable |
| Search query | ❌ | - | Not implemented |

**Legend**: ✅ Fully supported | 🟡 Partial support | ❌ Not supported

---

## Known Issues & Workarounds

### Issue: Legacy Token Deprecation

**Problem**: Slack no longer creates legacy tokens
**Workaround**: Create Slack App with OAuth, generate OAuth token with required scopes

### Issue: channels.list Deprecated

**Problem**: API method deprecated June 2020
**Workaround**: Modify `slackcli/messaging.py`:

```python
# Change in iter_resources():
lambda: slack.client().conversations.list().body["channels"]
```

### Issue: No Thread Support

**Problem**: Cannot read/reply to threads
**Workaround**: Use Slack Web UI or different tool (e.g., official Slack SDK)

### Issue: No JSON Output

**Problem**: Cannot export structured data
**Workaround**: Parse text output:

```bash
slack-cli -s general --last 100 | sed -E 's/\[([^\]]+)\] @([^:]+): (.*)/{"ts":"\1","user":"\2","text":"\3"}/'
```

### Issue: No File Download

**Problem**: Cannot retrieve uploaded files
**Workaround**: Use [auino/slack-downloader](https://github.com/auino/slack-downloader)

---

## Performance Notes

* **User listing**: Slow - iterates entire user list for name resolution
* **Channel caching**: Singleton pattern reduces API calls
* **Streaming**: Efficient WebSocket connection, minimal latency
* **Message history**: Paginated retrieval, handles large batches
* **Autocomplete**: Pre-cached channel/user names

---

## Security Considerations

* **Token storage**: Plain text in `~/.config/slack-cli/`
* **Environment variables**: `SLACK_TOKEN` not recommended (visible in process list)
* **OAuth scopes**: Requires appropriate permissions; overly broad scopes increase risk
* **Command execution**: `--run` executes arbitrary shell commands - use with caution

---

## Alternative Tools

For missing features, consider:

* **Official Slack SDK**: [slackapi/python-slack-sdk](https://github.com/slackapi/python-slack-sdk) - Full API coverage, thread support
* **rockymadden/slack-cli**: Pure bash alternative with rich formatting
* **cleentfaar/slack-cli**: PHP-based, all API methods
* **slackhq/slack-cli**: Official Slack CLI for workflow apps (different purpose)

---

## Sources

1. [GitHub - regisb/slack-cli](https://github.com/regisb/slack-cli)
2. [slack-cli PyPI Package](https://pypi.org/project/slack-cli/)
3. [README.rst](https://github.com/regisb/slack-cli/blob/master/README.rst)
4. [Source Code - slack.py](https://github.com/regisb/slack-cli/blob/master/slackcli/slack.py)
5. [Source Code - cli.py](https://github.com/regisb/slack-cli/blob/master/slackcli/cli.py)
6. [Source Code - messaging.py](https://github.com/regisb/slack-cli/blob/master/slackcli/messaging.py)
7. [Source Code - stream.py](https://github.com/regisb/slack-cli/blob/master/slackcli/stream.py)
8. [Source Code - names.py](https://github.com/regisb/slack-cli/blob/master/slackcli/names.py)
9. [Source Code - ui.py](https://github.com/regisb/slack-cli/blob/master/slackcli/ui.py)
10. [CHANGELOG.md](https://github.com/regisb/slack-cli/blob/master/CHANGELOG.md)
11. [Issue #40 - channels.list deprecated](https://github.com/regisb/slack-cli/issues/40)
12. [Issue #44 - Legacy tokens no longer supported](https://github.com/regisb/slack-cli/issues/44)
13. [Slack API - conversations.history](https://api.slack.com/methods/conversations.history)
14. [Slack API - conversations.replies](https://api.slack.com/methods/conversations.replies)
15. [Slack API - RTM (Legacy)](https://api.slack.com/rtm)

---

**Document Generated**: 2025-12-24
**Analysis Depth**: Complete source code review + documentation + issue tracking
**Confidence Level**: High (direct source code inspection)
