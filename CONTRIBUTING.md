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

### Maintenance Tiers

* `active-development` - Actively maintained
* `maintenance-mode` - Security fixes only
* `community-sustained` - Community contributions
* `unmaintained` - No activity
* `archived` - Repository archived

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
