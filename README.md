# Slack CLI Tools Comparison

A curated comparison of command-line tools for interacting with Slack on Linux and other platforms. This repository tracks CLI clients, terminal UIs, file uploaders, and automation tools for Slack.

## Quick Navigation

| I want to... | Go to |
|--------------|-------|
| Use Slack from the terminal with a full TUI | [Terminal UIs](#-terminal-user-interfaces) |
| Send messages/files via scripts | [Messaging CLIs](#-messaging-clis) |
| Stream logs to Slack channels | [File Uploaders](#-file-uploaders) |
| Build Slack apps from CLI | [Official CLI](#-official-slack-cli) |
| Find AI-friendly tools for automation | [AI/Automation](#-aiautomation-friendly-tools) |
| See all tools in one table | [Full Comparison](comparisons/auto-generated.md) |
| Understand authentication options | [Authentication Guide](#authentication-considerations) |

## Tool Categories

### Official Slack CLI

The official Slack CLI for building and deploying Slack apps.

| Tool | Language | Stars | Status | Key Feature |
|------|----------|-------|--------|-------------|
| [slack-cli](https://github.com/slackapi/slack-cli) | Go | 79 | Active | App development & deployment |

**Best for:** Developers building Slack apps with Deno SDK or Bolt frameworks.

### Terminal User Interfaces

Full-featured terminal clients for daily Slack usage.

| Tool | Language | Stars | Status | Key Feature |
|------|----------|-------|--------|-------------|
| [slack-term](https://github.com/jpbruinsslot/slack-term) | Go | ~1,800 | Maintenance | ncurses-style TUI |
| [slack-libpurple](https://github.com/dylex/slack-libpurple) | C | N/A | Community | Pidgin/Finch integration |

**Best for:** Users who prefer staying in the terminal for all communication.

### Messaging CLIs

Command-line tools for sending and receiving messages.

| Tool | Language | Stars | Status | Key Feature |
|------|----------|-------|--------|-------------|
| [slackcli](https://github.com/shaharia-lab/slackcli) | TypeScript | N/A | Active | AI-friendly JSON output |
| [slack-cli (regisb)](https://github.com/regisb/slack-cli) | Python | 170 | Maintenance | Multi-team management |
| [slack-cli (rockymadden)](https://github.com/rockymadden/slack-cli) | Bash | ~1,100 | Unmaintained | Pipe-friendly, zero deps |

**Best for:** Scripting, automation, and quick message sending.

### File Uploaders

Tools specialized for posting files and logs to Slack.

| Tool | Language | Stars | Status | Key Feature |
|------|----------|-------|--------|-------------|
| [slackcat](https://github.com/bcicen/slackcat) | Go | 1,200 | Stable | `tail -f` streaming mode |

**Best for:** DevOps engineers streaming logs or uploading files.

### Notification Tools

Multi-service notification utilities that include Slack.

| Tool | Language | Stars | Status | Key Feature |
|------|----------|-------|--------|-------------|
| [yfiton](https://github.com/yfiton/yfiton) | Java | N/A | Community | Multi-service (Slack, email, etc.) |

**Best for:** Teams using multiple notification channels.

## AI/Automation Friendly Tools

Tools designed for or suitable for AI agent integration:

| Tool | JSON Output | Structured | Scriptable | CI/CD Ready |
|------|-------------|------------|------------|-------------|
| [slackcli](https://github.com/shaharia-lab/slackcli) |  |  |  |  |
| [slack-cli (official)](https://github.com/slackapi/slack-cli) |  |  |  |  |
| [slackcat](https://github.com/bcicen/slackcat) |  |  |  |  |

## Maintenance Status Legend

| Status | Meaning |
|--------|---------|
| **Active** | Regular releases, responsive to issues |
| **Maintenance** | Security fixes only, limited new features |
| **Community** | Sporadic contributions, slow response |
| **Unmaintained** | No recent activity, issues unanswered |
| **Archived** | Read-only, no future development |

## Authentication Considerations

Slack has evolved its authentication requirements significantly:

* **OAuth 2.0** (Recommended): Modern standard, required for new apps
* **Legacy Tokens**: Deprecated in 2020, many old tools still require them
* **Browser Token Extraction**: Workaround for tools lacking OAuth support

| Tool | OAuth 2.0 | Legacy Token | Browser Token |
|------|-----------|--------------|---------------|
| slack-cli (official) |  |  |  |
| slackcli (shaharia) |  |  |  |
| slackcat |  |  |  |
| slack-term |  |  |  |
| regisb/slack-cli |  |  |  |
| rockymadden/slack-cli |  |  |  |

**Warning:** Tools requiring legacy tokens may not work with newer Slack workspaces.

## Detailed Comparisons

* [Full Comparison Table](comparisons/auto-generated.md) - All tools with all fields
* [Feature Matrix](comparisons/features.empty.md) - Detailed feature comparison
* [Authentication Guide](comparisons/authentication.empty.md) - Auth deep dive

## For Contributors

### Project Structure

```
slack-cli-tools-pub-kb/
├── README.md                 # This file
├── spec.yaml                 # YAML schema specification
├── projects/                 # YAML data files (one per tool)
│   ├── slackapi--slack-cli.yaml
│   ├── bcicen--slackcat.yaml
│   └── ...
├── scripts/                  # Tooling
│   ├── check-yaml.py         # Validate YAML files
│   ├── generate-tables.py    # Generate comparison tables
│   └── clone-all.sh          # Clone repos for analysis
├── comparisons/              # Generated and manual comparisons
│   └── auto-generated.md
├── ramblings/                # Research notes
└── tmp/                      # Cloned repos (gitignored)
```

### Quick Commands

```bash
# Validate all YAML files
./scripts/check-yaml.py

# Generate comparison tables
./scripts/generate-tables.py > comparisons/auto-generated.md

# Clone all repos for analysis
./scripts/clone-all.sh --shallow

# Update existing clones
./scripts/clone-all.sh --update
```

### Adding a New Tool

1. Create `projects/{owner}--{repo}.yaml` following `spec.yaml`
2. Fill in required fields: `last-update`, `repo-url`, `name`, `description`, `language`, `category`
3. Run `./scripts/check-yaml.py` to validate
4. Regenerate tables: `./scripts/generate-tables.py > comparisons/auto-generated.md`

## Resources

* [Slack CLI Official Docs](https://docs.slack.dev/tools/slack-cli/)
* [Slack API Documentation](https://api.slack.com/)
* [Initial Research (Perplexity)](https://www.perplexity.ai/search/slack-cli-linux-tools-comparis-jUKChWAcSBKD077.dWXvKw)

## License

This comparison repository is provided as-is for informational purposes. Individual tools have their own licenses - see their respective repositories.

---

*Last updated: 2025-12-23*
