# Slack API Coverage Comparison: Plan and Methodology

**Date**: 2026-01-04
**Status**: Implementation in progress

## Goal

Create systematic comparison of Slack CLI tools against official Slack REST API methods, with proper archiving of the OpenAPI spec and field-level provenance tracking.

## Background

During deep research of Slack CLI tools, we discovered that:

1. **Most tools don't read messages** - Only send capabilities
2. **MCP servers use REST API** - No official Slack MCP endpoint exists (announced for Summer 2025)
3. **No systematic API coverage tracking** existed - Tools were compared on features, not API method support

This led to the question: "If MCP servers just wrap REST API, what's the real benefit over direct CLI tools?"

Answer: **The benefit is the protocol/interface (MCP for AI agents), not additional API capabilities.**

To properly compare tools, we need to track which Slack API methods each tool actually supports.

## Methodology

### Phase 1: Archive Official Slack OpenAPI Spec

**Source**: https://github.com/slackapi/slack-api-specs (archived 2024-03-27)

**Archived to**: `archived-sources/slack-api/`

**Contents**:
- `slack-web-openapi-v2.json` - Full OpenAPI 2.0 specification
- `slack-web-openapi-v2.meta.json` - Structured metadata
- `slack-web-openapi-v2.url` - Source URL
- `ATTRIBUTION.md` - Full attribution and usage guidelines

**Spec Statistics**:
- 174 API methods across 25 categories
- Top categories: admin (56), conversations (18), files (13), users (12), chat (10)

### Phase 2: Schema Extensions

#### 2.1 `api-coverage` Section
New section in spec.yaml for tracking API method support:
```yaml
api-coverage:
  methods-supported:      # List of Slack API methods this tool supports
  methods-partial:        # Methods with limited parameter support
  methods-planned:        # Methods planned for future support
  undocumented-methods:   # APIs not in official OpenAPI spec (e.g., RTM)
  coverage-notes:         # Notes about limitations
```

#### 2.2 Reusable `evidence` Pattern
Generic provenance tracking that can be added to ANY section:
```yaml
evidence:
  source-type: "source-code" | "documentation" | "readme" | "github-api" | "manual-test" | "inferred"
  source-url: "https://github.com/..."
  source-commit: "abc1234"
  source-file: "src/api/messages.ts"
  source-lines: "45-67"
  retrieved-date: "2026-01-04"
  confidence: "verified" | "likely" | "inferred" | "uncertain"
  notes: "Additional context"
```

This pattern enables field-level provenance tracking, so data can be verified and cross-checked later.

### Phase 3: Intelligent Table Generation

#### Design Decisions

1. **Filter to active tools** - Only show tools with >0% API coverage in detailed tables
2. **Track undocumented APIs** - Separate array for APIs not in official spec (e.g., deprecated RTM API)
3. **Group by API category** - Match Slack's 25 categories
4. **Percentages over checkmarks** - "6/12 (50%)" more informative than ✓/✗
5. **Smart filtering** - Don't show 174 rows of "no support"

#### Scripts Created

1. **`parse-slack-openapi.py`** - Parse archived spec, extract methods by category
2. **`generate-api-coverage-table.py`** - Generate coverage comparison tables

#### Output Modes

- `--by-category`: Coverage grouped by API category
- `--by-tool`: Each tool's coverage summary
- `--full-matrix`: Complete method × tool matrix
- `--gaps`: Unsupported methods per tool
- `--summary`: High-level percentages

### Phase 4: Tool Research

For each of the 11 tools, analyze:
- Source code for API method calls
- Documentation for supported operations
- README feature lists

Document with evidence for reproducibility.

### Phase 5: Iteration

Test, validate, refine table formatting until results are clear and useful.

## Key Insights from Research

### Tools That Can Read Slack Data

| Tool | Read Messages | JSON Output | Threads | Best For |
|------|--------------|-------------|---------|----------|
| shaharia-lab/slackcli | ✓ | ✓ | ✓ | AI/Automation |
| rusq/slackdump | ✓ | ✓ | ✓ | Export/Backup |
| korotovsky/slack-mcp-server | ✓ | ✓ | ✓ | MCP/LLM Integration |
| regisb/slack-cli | ✓ | ✗ | ✗ | Legacy streaming |
| slack-term | ✓ (TUI) | ✗ | ✓ | Interactive use |

### Tools That CANNOT Read (Send-Only)

- slackapi/slack-cli - App development only
- bcicen/slackcat - File upload only
- rockymadden/slack-cli - Send messages only
- yfiton - Multi-service notifications
- cleentfaar/slack-cli - Archived, PHP

### MCP Server Value Proposition

MCP servers provide:
- **Standardized AI agent protocol** - Works with Claude, GPT, etc.
- **Stealth mode** (korotovsky) - User appears offline
- **No additional API capabilities** - Same REST API as CLI tools

## Files Modified/Created

| File | Action |
|------|--------|
| `archived-sources/slack-api/*` | Created - OpenAPI spec archive |
| `spec.yaml` | Extended - api-coverage and evidence sections |
| `scripts/parse-slack-openapi.py` | Created - OpenAPI parser |
| `scripts/generate-api-coverage-table.py` | Created - Coverage table generator |
| `scripts/check-yaml.py` | Modified - New field validation |
| `projects/*.yaml` | Modified - api-coverage sections |
| `comparisons/auto-generated.md` | Regenerated - New coverage tables |

## References

- [Slack Web API Methods](https://api.slack.com/methods)
- [slackapi/slack-api-specs](https://github.com/slackapi/slack-api-specs) (archived)
- [OpenAPI 2.0 Specification](https://swagger.io/specification/v2/)
- [Model Context Protocol](https://modelcontextprotocol.io/)

## Notes

- Slack announced official MCP server for "Summer 2025" - not yet available
- The OpenAPI spec is frozen (repo archived 2024-03-27) but still valid
- Some methods in tools use deprecated RTM API not in OpenAPI spec
- Enterprise admin.* methods (56) unlikely to be in any CLI tool
