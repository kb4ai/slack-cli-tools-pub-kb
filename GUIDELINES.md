# Repository Guidelines

## Purpose

This repository maintains a curated comparison of Slack CLI tools for Linux and other platforms. It serves users seeking the right tool for their needs and contributors who want to help keep the data accurate.

## Repository Structure

```
slack-cli-tools-pub-kb/
├── README.md           # Entry point with quick navigation
├── spec.yaml           # YAML schema specification
├── GUIDELINES.md       # This file
├── PROCESS.md          # Research and maintenance process
├── CONTRIBUTING.md     # How to contribute
├── projects/           # Tool data (one YAML per tool)
├── scripts/            # Automation scripts
├── comparisons/        # Generated and manual comparison docs
├── ramblings/          # Research notes and findings
└── tmp/                # Cloned repositories (gitignored)
```

## YAML File Requirements

### Naming Convention

Files in `projects/` must follow: `{github-owner}--{repo-name}.yaml`

Examples:

* `slackapi--slack-cli.yaml`
* `bcicen--slackcat.yaml`
* `shaharia-lab--slackcli.yaml`

### Required Fields

Every project YAML must include:

1. `last-update` - Date in YYYY-MM-DD format
2. `repo-url` - Full repository URL
3. `name` - Tool display name
4. `description` - Brief description
5. `language` - Primary programming language
6. `category` - One of the defined categories

### Field Ordering

Follow this order for consistency:

1. **Tracking**: `last-update`, `repo-commit`, `repo-url`
2. **Basic Info**: `name`, `description`, `language`, `languages`, `license`
3. **Metrics**: `stars`, `forks`, `watchers`, `contributors`, `open-issues`
4. **Dates**: `last-commit`, `created`, `last-release`
5. **Status**: `reputable-source`, `organization`, `archived`, `maintenance-tier`
6. **Classification**: `category`, `secondary-categories`
7. **Features**: `features`, `slack-features`
8. **Technical**: `authentication`, `output-formats`, `terminal-features`
9. **Installation**: `installation`, `documentation`
10. **AI/Automation**: `ai-friendly`
11. **Notes**: `notes`, `warnings`

## Comparison Dimensions

### Categories

* `official-cli` - Official Slack development CLI
* `messaging-cli` - CLIs for sending/receiving messages
* `terminal-ui` - Full terminal user interfaces
* `file-upload` - File/log upload specialists
* `notification-tool` - Multi-service notification utilities
* `libpurple-plugin` - Pidgin/Finch plugins
* `bot-framework` - Bot building frameworks
* `api-wrapper` - Low-level API wrappers

### Maintenance Tiers

* `active-development` - Regular releases, responsive
* `maintenance-mode` - Security fixes only
* `community-sustained` - Sporadic community activity
* `unmaintained` - No response to issues
* `archived` - Repository is read-only

### Key Comparison Axes

1. **Reputation**: Official vs. community, star count, organization backing
2. **Functionality**: Features supported, Slack API coverage
3. **Authentication**: OAuth 2.0, legacy tokens, browser tokens
4. **Output**: JSON, structured data, pipe-friendliness
5. **Maintenance**: Activity level, issue response, release frequency
6. **Installation**: Package managers, binaries, dependencies

## Script Conventions

### check-yaml.py

* Validates all YAML files against spec.yaml schema
* Reports errors (blocking) and warnings (informational)
* Use `--strict` to fail on warnings

### generate-tables.py

* Generates markdown comparison tables
* Multiple output modes: `--by-category`, `--by-language`, etc.
* Default output is full report

### clone-all.sh

* Clones repositories to `tmp/` for analysis
* Use `--shallow` for faster cloning
* Use `--update` to pull latest changes

## Git Commit Practices

* Keep commits focused and descriptive
* Separate data updates from script changes
* Use present tense imperative mood

Example commit messages:

* `Add slackcat project tracking`
* `Update star counts for all projects`
* `Fix generate-tables.py null handling`

## Update Procedures

### Adding a New Tool

1. Create YAML file following naming convention
2. Fill required fields from repository inspection
3. Run `check-yaml.py` to validate
4. Regenerate tables
5. Commit with descriptive message

### Updating Existing Tools

1. Update relevant fields
2. Update `last-update` to today's date
3. Optionally update `repo-commit` if re-analyzing
4. Run validation and regenerate tables

### Periodic Maintenance

* **Monthly**: Update star counts, check for releases
* **Quarterly**: Discovery sweep for new tools, deep-dive on changes
