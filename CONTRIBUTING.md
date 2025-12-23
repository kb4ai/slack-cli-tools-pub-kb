# Contributing Guide

Thank you for your interest in improving this Slack CLI tools comparison!

## Quick Reference

| Task | Command |
|------|---------|
| Validate YAML files | `./scripts/check-yaml.py` |
| Generate tables | `./scripts/generate-tables.py` |
| Clone all repos | `./scripts/clone-all.sh --shallow` |
| Update clones | `./scripts/clone-all.sh --update` |

## Adding a New Tool

### Step 1: Create YAML File

Create `projects/{owner}--{repo}.yaml`:

```yaml
last-update: "2025-12-23"
repo-url: "https://github.com/owner/repo"

name: "tool-name"
description: "Brief description of the tool"
language: "Go"
license: "MIT"

stars: 100
# Add more fields as discovered

category: "messaging-cli"

features:
  - "Feature 1"
  - "Feature 2"

notes:
  - "Additional observations"
```

### Step 2: Validate

```bash
./scripts/check-yaml.py projects/{owner}--{repo}.yaml
```

Fix any errors before proceeding.

### Step 3: Regenerate Tables

```bash
./scripts/generate-tables.py > comparisons/auto-generated.md
```

### Step 4: Commit

```bash
git add projects/{owner}--{repo}.yaml comparisons/auto-generated.md
git commit -m "Add {tool-name} to comparison

* Language: {language}
* Category: {category}
* Stars: {stars}"
```

## Updating Existing Tools

### Step 1: Update YAML

Edit the relevant file in `projects/`:

1. Update changed fields
2. Set `last-update` to today's date
3. Optionally set `repo-commit` if re-analyzing code

### Step 2: Validate and Regenerate

```bash
./scripts/check-yaml.py
./scripts/generate-tables.py > comparisons/auto-generated.md
```

### Step 3: Commit

```bash
git add projects/ comparisons/
git commit -m "Update {tool-name} metrics

* Stars: {old} -> {new}
* Last commit: {date}"
```

## Bulk Updates

### Update Star Counts

```bash
# Clone repos first
./scripts/clone-all.sh --update

# Then manually update YAML files or use GitHub API
for f in projects/*.yaml; do
  repo=$(yq -r '.["repo-url"]' "$f" | sed 's|https://github.com/||')
  stars=$(gh api "repos/$repo" --jq '.stargazers_count' 2>/dev/null || echo "N/A")
  echo "$f: $stars stars"
done
```

### Discovery Sweep

1. Search GitHub for new Slack CLI tools
2. Check Reddit, Hacker News for mentions
3. Search package registries (npm, PyPI, etc.)
4. Create YAML files for new discoveries

## Field Reference

### Required Fields

| Field | Format | Example |
|-------|--------|---------|
| `last-update` | YYYY-MM-DD | `"2025-12-23"` |
| `repo-url` | URL | `"https://github.com/..."` |
| `name` | string | `"slackcat"` |
| `description` | string | `"Post files to Slack"` |
| `language` | enum | `"Go"`, `"Python"`, etc. |
| `category` | enum | `"messaging-cli"`, etc. |

### Optional but Recommended

| Field | Type | Notes |
|-------|------|-------|
| `stars` | integer | GitHub star count |
| `license` | string | `"MIT"`, `"Apache-2.0"`, etc. |
| `maintenance-tier` | enum | Current maintenance status |
| `features` | array | List of features |
| `authentication` | object | Auth methods supported |
| `installation` | object | Install methods available |

### Categories

* `official-cli` - Official Slack CLI
* `messaging-cli` - Message sending/receiving
* `terminal-ui` - Full TUI clients
* `file-upload` - File/log uploaders
* `notification-tool` - Multi-service notifiers
* `libpurple-plugin` - Pidgin/Finch plugins
* `bot-framework` - Bot frameworks
* `api-wrapper` - API wrappers
* `export-tool` - Bulk export/backup tools
* `mcp-server` - MCP server implementations

### Maintenance Tiers

* `active-development` - Actively maintained
* `maintenance-mode` - Security fixes only
* `community-sustained` - Community contributions
* `unmaintained` - No activity
* `archived` - Repository archived

## Data Standards

### Tracking Repository Versions

When analyzing a repository, always record the commit hash you're examining:

```yaml
repo-commit: "a1b2c3d"  # 7-character commit hash
```

This ensures reproducibility and allows future reviewers to verify your analysis against the same code version.

**How to get the commit hash:**

```bash
# Get latest commit from remote
git ls-remote https://github.com/owner/repo.git HEAD | awk '{print substr($1,1,7)}'

# Or if you have the repo cloned
cd /path/to/repo
git rev-parse --short=7 HEAD
```

### Adding Evidence References

When documenting features or capabilities, include evidence in notes:

```yaml
read-capabilities:
  read-messages: true
  read-channels: true
  message-search: false

notes:
  - "Read capabilities verified in src/slack_client.py lines 45-67"
  - "Uses conversations.history API method (repo-commit: a1b2c3d)"
  - "No search functionality found in codebase"
```

**Evidence types:**

* Source code references: `"Found in src/file.py lines 10-20"`
* API methods used: `"Uses chat.postMessage API method"`
* Documentation quotes: `"README states: 'supports thread replies'"`
* Test verification: `"Confirmed in tests/test_threads.py"`
* Absence proof: `"No implementation found for feature X"`

### Ensuring Reproducibility

To make your analysis reproducible:

1. **Record the version analyzed:**

   ```yaml
   repo-commit: "a1b2c3d"
   last-update: "2025-12-24"
   ```

2. **Document your methodology:**

   ```yaml
   notes:
     - "Analysis method: Code review + README documentation"
     - "Tested features: file upload, message sending"
     - "Could not test: authentication (no credentials)"
   ```

3. **Link to specific evidence:**

   ```yaml
   notes:
     - "Thread support: src/messaging.py#L123-L145"
     - "Authentication methods: docs/auth.md"
   ```

4. **Note uncertainties:**

   ```yaml
   notes:
     - "Unknown: Whether rate limiting is handled (no tests found)"
     - "Unclear: Support for Enterprise Grid (docs mention but no code found)"
   ```

### New Feature Sections Added

Recent schema expansions include detailed capability tracking:

1. **read-capabilities** - What data can be read/queried

   * `read-messages`, `read-channels`, `read-dms`, `read-group-dms`
   * `read-threads`, `message-search`, `user-info`, `export-history`
   * Example: See `projects/rusq--slackdump.yaml`

2. **query-options** - Filtering and search capabilities

   * `date-range-filter`, `limit-results`, `pagination`
   * `channel-filter`, `user-filter`, `keyword-search`, `thread-filter`

3. **communication-features** - Interaction capabilities

   * `reply-to-thread`, `reply-with-broadcast`, `start-new-thread`
   * `send-to-dm`, `send-to-channel`, `send-to-group-dm`
   * `message-formatting`

4. **attachment-handling** - File operations

   * `upload-files`, `download-files`, `upload-from-stdin`
   * `upload-images`, `upload-audio`, `upload-video`

5. **export-capabilities** - Bulk export features

   * `full-workspace-export`, `channel-export`, `dm-export`
   * `thread-export`, `include-attachments`
   * `export-format`: Array of supported formats (json, jsonl, etc.)

6. **mcp-integration** - MCP server features

   * `is-mcp-server`, `stealth-mode`, `rate-limit-handling`
   * `supports-enterprise`
   * `mcp-tools`, `mcp-resources`: Arrays of exposed tools/resources
   * Example: See `projects/korotovsky--slack-mcp-server.yaml`

**Template for comprehensive analysis:**

```yaml
read-capabilities:
  read-messages: true
  read-channels: true
  read-dms: true
  read-threads: true
  message-search: false
  user-info: true
  export-history: true

query-options:
  date-range-filter: true
  limit-results: true
  pagination: true
  channel-filter: true
  user-filter: false
  keyword-search: false
  thread-filter: true

communication-features:
  reply-to-thread: true
  reply-with-broadcast: false
  send-to-dm: true
  send-to-channel: true
  send-to-group-dm: false
  message-formatting: true

attachment-handling:
  upload-files: true
  download-files: true
  upload-from-stdin: true
  upload-images: true
  upload-audio: false
  upload-video: false

export-capabilities:
  full-workspace-export: false
  channel-export: true
  dm-export: true
  thread-export: true
  include-attachments: true
  export-format:
    - "json"
    - "jsonl"

notes:
  - "Analysis based on repo-commit: a1b2c3d"
  - "Read capabilities verified in src/api_client.go"
  - "Export format determined from cmd/export/main.go lines 89-102"
```

## Code Style

### YAML Files

* Quote date strings: `"2025-12-23"`
* Use lowercase for enum values: `messaging-cli`
* Use arrays for lists, even single items
* Order fields according to GUIDELINES.md

### Commit Messages

* Use present tense imperative: "Add", "Update", "Fix"
* Include key changes in body
* Reference issues if applicable

## Questions?

Open an issue or check existing documentation:

* [README.md](README.md) - Overview and quick start
* [GUIDELINES.md](GUIDELINES.md) - Repository standards
* [PROCESS.md](PROCESS.md) - Research workflow
* [spec.yaml](spec.yaml) - Full schema specification
