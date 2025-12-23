#!/usr/bin/env python3
"""
Markdown Table Generator for Slack CLI Tools Comparison

Transforms YAML project files into markdown comparison tables.
Supports multiple output modes and filtering options.

Usage:
    ./scripts/generate-tables.py                    # Full report
    ./scripts/generate-tables.py --by-category      # Group by category
    ./scripts/generate-tables.py --by-language      # Group by language
    ./scripts/generate-tables.py --by-maintenance   # Group by maintenance status
    ./scripts/generate-tables.py --by-stars         # Sort by GitHub stars
    ./scripts/generate-tables.py --features         # Feature matrix
    ./scripts/generate-tables.py --auth             # Authentication matrix
    ./scripts/generate-tables.py --ai-friendly      # AI/automation readiness
    ./scripts/generate-tables.py --json             # JSON output
"""

import sys
import json
import argparse
from pathlib import Path
from datetime import datetime

try:
    import yaml
except ImportError:
    print("Error: PyYAML not installed. Run: pip install pyyaml")
    sys.exit(1)


# =============================================================================
# DATA LOADING
# =============================================================================

def load_projects(projects_dir: Path) -> list:
    """Load all project YAML files."""
    projects = []
    for filepath in sorted(projects_dir.glob('*.yaml')):
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                data = yaml.safe_load(f)
                if data:
                    data['_filename'] = filepath.name
                    projects.append(data)
        except Exception as e:
            print(f"Warning: Failed to load {filepath}: {e}", file=sys.stderr)
    return projects


# =============================================================================
# TABLE GENERATION FUNCTIONS
# =============================================================================

def generate_overview_table(projects: list) -> str:
    """Generate main overview table sorted by stars."""
    lines = []
    lines.append("## Overview\n")
    lines.append("| Tool | Language | Stars | Category | Maintenance | Description |")
    lines.append("|------|----------|-------|----------|-------------|-------------|")

    # Sort by stars (descending), handle None values
    sorted_projects = sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True)

    for p in sorted_projects:
        name = p.get('name', 'Unknown')
        url = p.get('repo-url', '#')
        language = p.get('language', 'N/A')
        stars = p.get('stars', 'N/A')
        if stars == 'N/A':
            stars_str = 'N/A'
        else:
            stars_str = f"{stars:,}" if isinstance(stars, int) else str(stars)
        category = p.get('category', 'N/A').replace('-', ' ').title()
        maintenance = p.get('maintenance-tier', 'N/A').replace('-', ' ').title()
        description = p.get('description', '')[:60]
        if len(p.get('description', '')) > 60:
            description += '...'

        lines.append(f"| [{name}]({url}) | {language} | {stars_str} | {category} | {maintenance} | {description} |")

    return '\n'.join(lines)


def generate_by_category(projects: list) -> str:
    """Generate tables grouped by category."""
    lines = []
    lines.append("## By Category\n")

    categories = {}
    for p in projects:
        cat = p.get('category', 'other')
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(p)

    for category, cat_projects in sorted(categories.items()):
        cat_title = category.replace('-', ' ').title()
        lines.append(f"### {cat_title}\n")
        lines.append("| Tool | Stars | Maintenance | Description |")
        lines.append("|------|-------|-------------|-------------|")

        sorted_cat = sorted(cat_projects, key=lambda p: p.get('stars') or 0, reverse=True)
        for p in sorted_cat:
            name = p.get('name', 'Unknown')
            url = p.get('repo-url', '#')
            stars = p.get('stars', 'N/A')
            stars_str = f"{stars:,}" if isinstance(stars, int) else str(stars)
            maintenance = p.get('maintenance-tier', 'N/A').replace('-', ' ').title()
            description = p.get('description', '')[:80]

            lines.append(f"| [{name}]({url}) | {stars_str} | {maintenance} | {description} |")

        lines.append("")

    return '\n'.join(lines)


def generate_by_language(projects: list) -> str:
    """Generate tables grouped by programming language."""
    lines = []
    lines.append("## By Programming Language\n")

    languages = {}
    for p in projects:
        lang = p.get('language', 'Other')
        if lang not in languages:
            languages[lang] = []
        languages[lang].append(p)

    for language, lang_projects in sorted(languages.items()):
        lines.append(f"### {language}\n")
        lines.append("| Tool | Stars | Category | Maintenance |")
        lines.append("|------|-------|----------|-------------|")

        sorted_lang = sorted(lang_projects, key=lambda p: p.get('stars') or 0, reverse=True)
        for p in sorted_lang:
            name = p.get('name', 'Unknown')
            url = p.get('repo-url', '#')
            stars = p.get('stars', 'N/A')
            stars_str = f"{stars:,}" if isinstance(stars, int) else str(stars)
            category = p.get('category', 'N/A').replace('-', ' ').title()
            maintenance = p.get('maintenance-tier', 'N/A').replace('-', ' ').title()

            lines.append(f"| [{name}]({url}) | {stars_str} | {category} | {maintenance} |")

        lines.append("")

    return '\n'.join(lines)


def generate_by_maintenance(projects: list) -> str:
    """Generate tables grouped by maintenance status."""
    lines = []
    lines.append("## By Maintenance Status\n")

    # Define order
    tier_order = ['active-development', 'maintenance-mode', 'community-sustained', 'unmaintained', 'archived']

    tiers = {}
    for p in projects:
        tier = p.get('maintenance-tier', 'unknown')
        if tier not in tiers:
            tiers[tier] = []
        tiers[tier].append(p)

    for tier in tier_order:
        if tier not in tiers:
            continue
        tier_projects = tiers[tier]
        tier_title = tier.replace('-', ' ').title()

        # Add emoji indicators
        emoji = {
            'active-development': '',
            'maintenance-mode': '',
            'community-sustained': '',
            'unmaintained': '',
            'archived': ''
        }.get(tier, '')

        lines.append(f"### {emoji} {tier_title}\n")
        lines.append("| Tool | Language | Stars | Last Activity |")
        lines.append("|------|----------|-------|---------------|")

        sorted_tier = sorted(tier_projects, key=lambda p: p.get('stars') or 0, reverse=True)
        for p in sorted_tier:
            name = p.get('name', 'Unknown')
            url = p.get('repo-url', '#')
            language = p.get('language', 'N/A')
            stars = p.get('stars', 'N/A')
            stars_str = f"{stars:,}" if isinstance(stars, int) else str(stars)
            last_commit = p.get('last-commit', 'N/A')

            lines.append(f"| [{name}]({url}) | {language} | {stars_str} | {last_commit} |")

        lines.append("")

    return '\n'.join(lines)


def generate_feature_matrix(projects: list) -> str:
    """Generate feature comparison matrix."""
    lines = []
    lines.append("## Feature Matrix\n")

    features = ['send-messages', 'receive-messages', 'file-upload', 'thread-support',
                'channel-browse', 'multi-workspace', 'search', 'app-development']

    # Header
    header = "| Tool |"
    for f in features:
        header += f" {f.replace('-', ' ').title()} |"
    lines.append(header)

    separator = "|------|" + "------|" * len(features)
    lines.append(separator)

    for p in sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True):
        name = p.get('name', 'Unknown')
        url = p.get('repo-url', '#')
        row = f"| [{name}]({url}) |"

        slack_features = p.get('slack-features', {}) or {}
        for f in features:
            value = slack_features.get(f)
            if value is True:
                row += " |"
            elif value is False:
                row += " |"
            else:
                row += " - |"

        lines.append(row)

    return '\n'.join(lines)


def generate_auth_matrix(projects: list) -> str:
    """Generate authentication comparison matrix."""
    lines = []
    lines.append("## Authentication Methods\n")

    auth_methods = ['oauth2', 'legacy-token', 'browser-token', 'api-key', 'env-var-auth']

    # Header
    header = "| Tool |"
    for a in auth_methods:
        header += f" {a.replace('-', ' ').title()} |"
    lines.append(header)

    separator = "|------|" + "------|" * len(auth_methods)
    lines.append(separator)

    for p in sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True):
        name = p.get('name', 'Unknown')
        url = p.get('repo-url', '#')
        row = f"| [{name}]({url}) |"

        auth = p.get('authentication', {}) or {}
        for a in auth_methods:
            value = auth.get(a)
            if value is True:
                row += " |"
            elif value is False:
                row += " |"
            else:
                row += " - |"

        lines.append(row)

    lines.append("\n**Legend:**  = Supported,  = Not Supported, - = Unknown\n")

    # Add authentication notes
    lines.append("### Authentication Notes\n")
    for p in sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True):
        auth = p.get('authentication', {}) or {}
        notes = auth.get('auth-notes', [])
        if notes:
            name = p.get('name', 'Unknown')
            lines.append(f"**{name}:**")
            for note in notes:
                lines.append(f"- {note}")
            lines.append("")

    return '\n'.join(lines)


def generate_ai_friendly_table(projects: list) -> str:
    """Generate AI/automation friendliness comparison."""
    lines = []
    lines.append("## AI/Automation Friendliness\n")

    ai_features = ['designed-for-ai', 'structured-output', 'scriptable', 'stateless', 'ci-cd-friendly']

    # Header
    header = "| Tool |"
    for f in ai_features:
        header += f" {f.replace('-', ' ').title()} |"
    lines.append(header)

    separator = "|------|" + "------|" * len(ai_features)
    lines.append(separator)

    for p in sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True):
        name = p.get('name', 'Unknown')
        url = p.get('repo-url', '#')
        row = f"| [{name}]({url}) |"

        ai_friendly = p.get('ai-friendly', {}) or {}
        for f in ai_features:
            value = ai_friendly.get(f)
            if value is True:
                row += " |"
            elif value is False:
                row += " |"
            else:
                row += " - |"

        lines.append(row)

    lines.append("\n**Best for AI/Automation:** Tools with  in 'Designed For Ai' or 'Structured Output'\n")

    return '\n'.join(lines)


def generate_output_formats_table(projects: list) -> str:
    """Generate output formats comparison."""
    lines = []
    lines.append("## Output Formats\n")

    formats = ['json', 'jsonl', 'yaml', 'table', 'plain-text', 'pipe-friendly']

    # Header
    header = "| Tool |"
    for f in formats:
        header += f" {f.upper() if f in ['json', 'jsonl', 'yaml'] else f.replace('-', ' ').title()} |"
    lines.append(header)

    separator = "|------|" + "------|" * len(formats)
    lines.append(separator)

    for p in sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True):
        name = p.get('name', 'Unknown')
        url = p.get('repo-url', '#')
        row = f"| [{name}]({url}) |"

        output_formats = p.get('output-formats', {}) or {}
        for f in formats:
            value = output_formats.get(f)
            if value is True:
                row += " |"
            elif value is False:
                row += " |"
            else:
                row += " - |"

        lines.append(row)

    return '\n'.join(lines)


def generate_installation_table(projects: list) -> str:
    """Generate installation methods comparison."""
    lines = []
    lines.append("## Installation Methods\n")

    methods = ['homebrew', 'pip', 'npm', 'snap', 'go-install', 'binary', 'aur', 'source-compile']

    # Header
    header = "| Tool |"
    for m in methods:
        header += f" {m.replace('-', ' ').title()} |"
    lines.append(header)

    separator = "|------|" + "------|" * len(methods)
    lines.append(separator)

    for p in sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True):
        name = p.get('name', 'Unknown')
        url = p.get('repo-url', '#')
        row = f"| [{name}]({url}) |"

        installation = p.get('installation', {}) or {}
        for m in methods:
            value = installation.get(m)
            if value is True or (isinstance(value, str) and value):
                row += " |"
            elif value is False:
                row += " |"
            else:
                row += " - |"

        lines.append(row)

    return '\n'.join(lines)


def generate_read_capabilities_table(projects: list) -> str:
    """Generate read capabilities comparison matrix."""
    lines = []
    lines.append("## Read Capabilities\n")

    capabilities = ['read-messages', 'read-channels', 'read-dms', 'read-group-dms',
                   'read-threads', 'message-search', 'user-info', 'export-history']

    # Header
    header = "| Tool |"
    for c in capabilities:
        header += f" {c.replace('-', ' ').title()} |"
    lines.append(header)

    separator = "|------|" + "------|" * len(capabilities)
    lines.append(separator)

    for p in sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True):
        name = p.get('name', 'Unknown')
        url = p.get('repo-url', '#')
        row = f"| [{name}]({url}) |"

        read_caps = p.get('read-capabilities', {}) or {}
        for c in capabilities:
            value = read_caps.get(c)
            if value is True:
                row += " ✓ |"
            elif value is False:
                row += " ✗ |"
            else:
                row += " - |"

        lines.append(row)

    return '\n'.join(lines)


def generate_query_options_table(projects: list) -> str:
    """Generate query options comparison matrix."""
    lines = []
    lines.append("## Query Options\n")

    options = ['date-range-filter', 'limit-results', 'pagination', 'channel-filter',
              'user-filter', 'keyword-search', 'thread-filter']

    # Header
    header = "| Tool |"
    for o in options:
        header += f" {o.replace('-', ' ').title()} |"
    lines.append(header)

    separator = "|------|" + "------|" * len(options)
    lines.append(separator)

    for p in sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True):
        name = p.get('name', 'Unknown')
        url = p.get('repo-url', '#')
        row = f"| [{name}]({url}) |"

        query_opts = p.get('query-options', {}) or {}
        for o in options:
            value = query_opts.get(o)
            if value is True:
                row += " ✓ |"
            elif value is False:
                row += " ✗ |"
            else:
                row += " - |"

        lines.append(row)

    return '\n'.join(lines)


def generate_communication_features_table(projects: list) -> str:
    """Generate communication features comparison matrix."""
    lines = []
    lines.append("## Communication Features\n")

    features = ['reply-to-thread', 'reply-with-broadcast', 'start-new-thread',
               'send-to-dm', 'send-to-channel', 'send-to-group-dm', 'message-formatting']

    # Header
    header = "| Tool |"
    for f in features:
        header += f" {f.replace('-', ' ').title()} |"
    lines.append(header)

    separator = "|------|" + "------|" * len(features)
    lines.append(separator)

    for p in sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True):
        name = p.get('name', 'Unknown')
        url = p.get('repo-url', '#')
        row = f"| [{name}]({url}) |"

        comm_features = p.get('communication-features', {}) or {}
        for f in features:
            value = comm_features.get(f)
            if value is True:
                row += " ✓ |"
            elif value is False:
                row += " ✗ |"
            else:
                row += " - |"

        lines.append(row)

    return '\n'.join(lines)


def generate_attachment_handling_table(projects: list) -> str:
    """Generate attachment handling comparison matrix."""
    lines = []
    lines.append("## Attachment Handling\n")

    features = ['upload-files', 'download-files', 'upload-from-stdin',
               'upload-images', 'upload-audio', 'upload-video']

    # Header
    header = "| Tool |"
    for f in features:
        header += f" {f.replace('-', ' ').title()} |"
    lines.append(header)

    separator = "|------|" + "------|" * len(features)
    lines.append(separator)

    for p in sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True):
        name = p.get('name', 'Unknown')
        url = p.get('repo-url', '#')
        row = f"| [{name}]({url}) |"

        attachment = p.get('attachment-handling', {}) or {}
        for f in features:
            value = attachment.get(f)
            if value is True:
                row += " ✓ |"
            elif value is False:
                row += " ✗ |"
            else:
                row += " - |"

        lines.append(row)

    return '\n'.join(lines)


def generate_export_capabilities_table(projects: list) -> str:
    """Generate export capabilities comparison matrix."""
    lines = []
    lines.append("## Export Capabilities\n")

    features = ['full-workspace-export', 'channel-export', 'dm-export',
               'thread-export', 'include-attachments']

    # Header
    header = "| Tool |"
    for f in features:
        header += f" {f.replace('-', ' ').title()} |"
    lines.append(header)

    separator = "|------|" + "------|" * len(features)
    lines.append(separator)

    for p in sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True):
        name = p.get('name', 'Unknown')
        url = p.get('repo-url', '#')
        row = f"| [{name}]({url}) |"

        export_caps = p.get('export-capabilities', {}) or {}
        for f in features:
            value = export_caps.get(f)
            if value is True:
                row += " ✓ |"
            elif value is False:
                row += " ✗ |"
            else:
                row += " - |"

        lines.append(row)

    return '\n'.join(lines)


def generate_mcp_integration_table(projects: list) -> str:
    """Generate MCP integration comparison matrix."""
    lines = []
    lines.append("## MCP Integration\n")

    features = ['is-mcp-server', 'stealth-mode', 'rate-limit-handling',
               'supports-enterprise']

    # Header
    header = "| Tool |"
    for f in features:
        header += f" {f.replace('-', ' ').title()} |"
    lines.append(header)

    separator = "|------|" + "------|" * len(features)
    lines.append(separator)

    for p in sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True):
        name = p.get('name', 'Unknown')
        url = p.get('repo-url', '#')
        row = f"| [{name}]({url}) |"

        mcp = p.get('mcp-integration', {}) or {}
        for f in features:
            value = mcp.get(f)
            if value is True:
                row += " ✓ |"
            elif value is False:
                row += " ✗ |"
            else:
                row += " - |"

        lines.append(row)

    # Add MCP tools/resources info
    lines.append("\n### MCP Tools and Resources\n")
    for p in sorted(projects, key=lambda p: p.get('stars') or 0, reverse=True):
        mcp = p.get('mcp-integration', {}) or {}
        if mcp.get('is-mcp-server'):
            name = p.get('name', 'Unknown')
            lines.append(f"**{name}:**")

            tools = mcp.get('mcp-tools', [])
            if tools:
                lines.append("- Tools:")
                for tool in tools:
                    lines.append(f"  - {tool}")

            resources = mcp.get('mcp-resources', [])
            if resources:
                lines.append("- Resources:")
                for resource in resources:
                    lines.append(f"  - {resource}")

            notes = mcp.get('notes', [])
            if notes:
                lines.append("- Notes:")
                for note in notes:
                    lines.append(f"  - {note}")

            lines.append("")

    return '\n'.join(lines)


def generate_statistics(projects: list) -> str:
    """Generate summary statistics."""
    lines = []
    lines.append("## Statistics\n")

    total = len(projects)
    total_stars = sum(p.get('stars', 0) or 0 for p in projects)

    lines.append(f"- **Total tools tracked:** {total}")
    lines.append(f"- **Combined GitHub stars:** {total_stars:,}")
    lines.append("")

    # By category
    lines.append("### By Category\n")
    categories = {}
    for p in projects:
        cat = p.get('category', 'other')
        if cat not in categories:
            categories[cat] = 0
        categories[cat] += 1

    for cat, count in sorted(categories.items(), key=lambda x: x[1], reverse=True):
        lines.append(f"- {cat.replace('-', ' ').title()}: {count}")
    lines.append("")

    # By language
    lines.append("### By Language\n")
    languages = {}
    for p in projects:
        lang = p.get('language', 'Other')
        if lang not in languages:
            languages[lang] = 0
        languages[lang] += 1

    for lang, count in sorted(languages.items(), key=lambda x: x[1], reverse=True):
        lines.append(f"- {lang}: {count}")
    lines.append("")

    # By maintenance
    lines.append("### By Maintenance Status\n")
    tiers = {}
    for p in projects:
        tier = p.get('maintenance-tier', 'unknown')
        if tier not in tiers:
            tiers[tier] = 0
        tiers[tier] += 1

    for tier, count in sorted(tiers.items(), key=lambda x: x[1], reverse=True):
        lines.append(f"- {tier.replace('-', ' ').title()}: {count}")

    return '\n'.join(lines)


def generate_full_report(projects: list) -> str:
    """Generate complete comparison report."""
    lines = []
    lines.append("# Slack CLI Tools Comparison")
    lines.append("")
    lines.append(f"*Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*")
    lines.append("")

    lines.append(generate_statistics(projects))
    lines.append("")
    lines.append(generate_overview_table(projects))
    lines.append("")
    lines.append(generate_by_category(projects))
    lines.append("")
    lines.append(generate_by_maintenance(projects))
    lines.append("")
    lines.append(generate_feature_matrix(projects))
    lines.append("")
    lines.append(generate_read_capabilities_table(projects))
    lines.append("")
    lines.append(generate_query_options_table(projects))
    lines.append("")
    lines.append(generate_communication_features_table(projects))
    lines.append("")
    lines.append(generate_attachment_handling_table(projects))
    lines.append("")
    lines.append(generate_export_capabilities_table(projects))
    lines.append("")
    lines.append(generate_mcp_integration_table(projects))
    lines.append("")
    lines.append(generate_auth_matrix(projects))
    lines.append("")
    lines.append(generate_ai_friendly_table(projects))
    lines.append("")
    lines.append(generate_output_formats_table(projects))
    lines.append("")
    lines.append(generate_installation_table(projects))

    return '\n'.join(lines)


# =============================================================================
# MAIN
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Generate markdown comparison tables from Slack CLI tools YAML files'
    )
    parser.add_argument('--by-category', action='store_true', help='Group by category')
    parser.add_argument('--by-language', action='store_true', help='Group by language')
    parser.add_argument('--by-maintenance', action='store_true', help='Group by maintenance status')
    parser.add_argument('--by-stars', action='store_true', help='Sort by GitHub stars')
    parser.add_argument('--features', action='store_true', help='Feature matrix only')
    parser.add_argument('--read-capabilities', action='store_true', help='Read capabilities matrix')
    parser.add_argument('--query-options', action='store_true', help='Query options matrix')
    parser.add_argument('--communication-features', action='store_true', help='Communication features matrix')
    parser.add_argument('--attachment-handling', action='store_true', help='Attachment handling matrix')
    parser.add_argument('--export-capabilities', action='store_true', help='Export capabilities matrix')
    parser.add_argument('--mcp-integration', action='store_true', help='MCP integration matrix')
    parser.add_argument('--auth', action='store_true', help='Authentication matrix only')
    parser.add_argument('--ai-friendly', action='store_true', help='AI friendliness matrix')
    parser.add_argument('--output-formats', action='store_true', help='Output formats matrix')
    parser.add_argument('--installation', action='store_true', help='Installation methods matrix')
    parser.add_argument('--stats', action='store_true', help='Statistics only')
    parser.add_argument('--json', action='store_true', help='Output as JSON')
    parser.add_argument('-o', '--output', help='Output file (default: stdout)')

    args = parser.parse_args()

    # Find project directory
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    projects_dir = repo_root / 'projects'

    if not projects_dir.exists():
        print(f"Error: Projects directory not found: {projects_dir}", file=sys.stderr)
        sys.exit(1)

    # Load projects
    projects = load_projects(projects_dir)

    if not projects:
        print("Error: No projects found", file=sys.stderr)
        sys.exit(1)

    # Generate output
    if args.json:
        output = json.dumps(projects, indent=2, default=str)
    elif args.by_category:
        output = generate_by_category(projects)
    elif args.by_language:
        output = generate_by_language(projects)
    elif args.by_maintenance:
        output = generate_by_maintenance(projects)
    elif args.by_stars:
        output = generate_overview_table(projects)
    elif args.features:
        output = generate_feature_matrix(projects)
    elif args.read_capabilities:
        output = generate_read_capabilities_table(projects)
    elif args.query_options:
        output = generate_query_options_table(projects)
    elif args.communication_features:
        output = generate_communication_features_table(projects)
    elif args.attachment_handling:
        output = generate_attachment_handling_table(projects)
    elif args.export_capabilities:
        output = generate_export_capabilities_table(projects)
    elif args.mcp_integration:
        output = generate_mcp_integration_table(projects)
    elif args.auth:
        output = generate_auth_matrix(projects)
    elif args.ai_friendly:
        output = generate_ai_friendly_table(projects)
    elif args.output_formats:
        output = generate_output_formats_table(projects)
    elif args.installation:
        output = generate_installation_table(projects)
    elif args.stats:
        output = generate_statistics(projects)
    else:
        output = generate_full_report(projects)

    # Write output
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(output)
        print(f"Output written to: {args.output}", file=sys.stderr)
    else:
        print(output)


if __name__ == '__main__':
    main()
