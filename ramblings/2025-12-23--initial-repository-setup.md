# Initial Repository Setup

Date: 2025-12-23

## Summary

Created the slack-cli-tools-pub-kb repository based on patterns from the mcp-client-tools-comparison-pub-kb reference repository.

## Initial Tool Inventory

From Perplexity research, identified 9 Slack CLI tools:

1. **slackapi/slack-cli** (Go) - Official CLI for app development
2. **rockymadden/slack-cli** (Bash) - ~1,100 stars, unmaintained
3. **jpbruinsslot/slack-term** (Go) - ~1,800 stars, TUI client
4. **regisb/slack-cli** (Python) - 170 stars, maintenance mode
5. **shaharia-lab/slackcli** (TypeScript) - New, AI-friendly
6. **bcicen/slackcat** (Go) - 1,200 stars, file uploads
7. **cleentfaar/slack-cli** (PHP) - Archived
8. **yfiton/yfiton** (Java) - Multi-service notifier
9. **dylex/slack-libpurple** (C) - Pidgin plugin

## Key Patterns Adopted

From the reference repository:

* YAML files in `projects/` named `{owner}--{repo}.yaml`
* `spec.yaml` defining the schema
* Scripts: `check-yaml.py`, `generate-tables.py`, `clone-all.sh`
* Comparison docs in `comparisons/`
* Research notes in `ramblings/`
* `tmp/` directory gitignored for cloned repos

## Slack-Specific Additions

Extended schema for Slack CLI domain:

* `slack-features` object for Slack-specific capabilities
* `authentication` with OAuth, legacy token, browser token support
* `output-formats` for AI/automation friendliness
* `terminal-features` including TUI and image protocol support
* `ai-friendly` object for LLM integration assessment

## Category Taxonomy

Defined categories specific to Slack CLI ecosystem:

* `official-cli` - Official Slack development CLI
* `messaging-cli` - Message sending/receiving tools
* `terminal-ui` - Full TUI clients
* `file-upload` - File/log upload specialists
* `notification-tool` - Multi-service notifiers
* `libpurple-plugin` - Pidgin/Finch plugins

## Next Steps

1. Run parallel sub-agents to investigate each repository
2. Update YAML files with actual repository data
3. Add repository activity metrics (commits, issues)
4. Check for terminal image protocol support (Sixel, etc.)
5. Validate and regenerate tables

## References

* [Perplexity Research](https://www.perplexity.ai/search/slack-cli-linux-tools-comparis-jUKChWAcSBKD077.dWXvKw)
* [Reference Repository](../../../code-kb/mcp-servers/mcp-client-tools-comparison-pub-kb/)
