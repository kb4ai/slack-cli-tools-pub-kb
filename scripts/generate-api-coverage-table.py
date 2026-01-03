#!/usr/bin/env python3
"""
Generate Slack API coverage comparison tables.

This script compares tools against the official Slack OpenAPI specification
to show which API methods each tool supports.

Features:
- Intelligent filtering: Skip methods with 0% coverage
- Category grouping: Match Slack's API categories
- Percentage display: "6/12 (50%)" format
- Multiple output modes: by-category, by-tool, full-matrix, gaps, summary

Usage:
    python generate-api-coverage-table.py [--by-category] [--by-tool] [--summary]
"""

import argparse
import json
import yaml
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Set, Tuple


def load_openapi_methods(spec_path: Path) -> Dict[str, List[str]]:
    """Load all API methods from OpenAPI spec, grouped by category."""
    with open(spec_path, 'r', encoding='utf-8') as f:
        spec = json.load(f)

    methods_by_category = defaultdict(list)

    for path in spec.get('paths', {}).keys():
        method_name = path.lstrip('/')
        if '.' in method_name:
            category = method_name.split('.')[0]
        else:
            category = 'other'
        methods_by_category[category].append(method_name)

    # Sort methods within each category
    for category in methods_by_category:
        methods_by_category[category].sort()

    return dict(methods_by_category)


def load_projects(projects_dir: Path) -> List[dict]:
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
            print(f"Warning: Error loading {filepath}: {e}")
    return projects


def get_tool_methods(project: dict) -> Tuple[Set[str], Set[str]]:
    """
    Get supported and partial methods for a tool.

    Returns (supported_methods, partial_methods)
    """
    api_coverage = project.get('api-coverage', {})

    supported = set(api_coverage.get('methods-supported', []))

    partial = set()
    for item in api_coverage.get('methods-partial', []):
        if isinstance(item, dict):
            partial.add(item.get('method', ''))
        else:
            partial.add(str(item))

    return supported, partial


def calculate_coverage(project: dict, all_methods: Dict[str, List[str]]) -> Dict[str, dict]:
    """Calculate coverage statistics for a project by category."""
    supported, partial = get_tool_methods(project)
    all_supported = supported | partial

    coverage = {}
    for category, methods in all_methods.items():
        category_methods = set(methods)
        covered = category_methods & all_supported
        coverage[category] = {
            'covered': len(covered),
            'total': len(methods),
            'percentage': round(len(covered) / len(methods) * 100, 1) if methods else 0,
            'methods': sorted(covered)
        }

    # Calculate overall
    total_methods = sum(len(m) for m in all_methods.values())
    total_covered = len(all_supported)
    coverage['_overall'] = {
        'covered': total_covered,
        'total': total_methods,
        'percentage': round(total_covered / total_methods * 100, 1) if total_methods else 0
    }

    return coverage


def filter_active_tools(projects: List[dict]) -> Tuple[List[dict], List[dict]]:
    """
    Filter projects to those with API coverage data.

    Returns (active_tools, excluded_tools)
    """
    active = []
    excluded = []

    for p in projects:
        api_coverage = p.get('api-coverage', {})
        methods = api_coverage.get('methods-supported', [])
        partial = api_coverage.get('methods-partial', [])

        if methods or partial:
            active.append(p)
        else:
            excluded.append(p)

    return active, excluded


def format_coverage(covered: int, total: int) -> str:
    """Format coverage as 'X/Y (Z%)'."""
    if total == 0:
        return '-'
    pct = round(covered / total * 100)
    return f"{covered}/{total} ({pct}%)"


def generate_by_category_table(projects: List[dict], all_methods: Dict[str, List[str]]) -> str:
    """Generate coverage table grouped by API category."""
    active, excluded = filter_active_tools(projects)

    if not active:
        return "No tools have API coverage data.\n"

    # Calculate coverage for each tool
    tool_coverage = {}
    for p in active:
        tool_coverage[p['name']] = calculate_coverage(p, all_methods)

    # Find categories with at least some coverage
    covered_categories = set()
    for name, coverage in tool_coverage.items():
        for cat, data in coverage.items():
            if cat != '_overall' and data['covered'] > 0:
                covered_categories.add(cat)

    if not covered_categories:
        return "No API methods are covered by any tool.\n"

    # Build table
    lines = []
    lines.append("## API Coverage by Category\n")
    lines.append("Coverage shown as: `covered/total (percentage)`\n")

    # Header
    tool_names = [p['name'] for p in sorted(active, key=lambda x: -(x.get('stars') or 0))]
    header = "| Category | " + " | ".join(tool_names) + " |"
    separator = "|" + "|".join(["---"] * (len(tool_names) + 1)) + "|"

    lines.append(header)
    lines.append(separator)

    # Rows for covered categories (sorted by total methods descending)
    for cat in sorted(covered_categories,
                      key=lambda c: -len(all_methods.get(c, []))):
        total = len(all_methods[cat])
        row = f"| **{cat}** ({total}) |"
        for name in tool_names:
            data = tool_coverage[name].get(cat, {'covered': 0, 'total': total})
            row += f" {format_coverage(data['covered'], data['total'])} |"
        lines.append(row)

    # Overall row
    lines.append("|" + "-" * 20 + "|" + "|".join(["-" * 15] * len(tool_names)) + "|")
    row = "| **TOTAL** |"
    for name in tool_names:
        data = tool_coverage[name]['_overall']
        row += f" {format_coverage(data['covered'], data['total'])} |"
    lines.append(row)

    # Uncovered categories
    uncovered = set(all_methods.keys()) - covered_categories
    if uncovered:
        lines.append("\n### Categories Without Tool Coverage\n")
        lines.append("The following API categories have no coverage from any tool:\n")
        for cat in sorted(uncovered, key=lambda c: -len(all_methods.get(c, []))):
            count = len(all_methods[cat])
            lines.append(f"- **{cat}** ({count} methods)")

    # Excluded tools
    if excluded:
        lines.append("\n### Tools Without API Coverage Data\n")
        lines.append("The following tools have no `api-coverage` section:\n")
        for p in excluded:
            reason = p.get('warnings', ['No API coverage data'])[0]
            lines.append(f"- **{p['name']}**: {reason[:60]}...")

    return "\n".join(lines)


def generate_by_tool_table(projects: List[dict], all_methods: Dict[str, List[str]]) -> str:
    """Generate summary table showing each tool's overall coverage."""
    active, excluded = filter_active_tools(projects)

    lines = []
    lines.append("## API Coverage by Tool\n")

    if not active:
        lines.append("No tools have API coverage data.\n")
        return "\n".join(lines)

    # Header
    lines.append("| Tool | Stars | Methods Covered | Coverage % | Top Categories |")
    lines.append("|------|-------|-----------------|------------|----------------|")

    # Calculate and sort by coverage
    tool_data = []
    for p in active:
        coverage = calculate_coverage(p, all_methods)
        overall = coverage['_overall']

        # Find top 3 categories
        top_cats = sorted(
            [(cat, data) for cat, data in coverage.items() if cat != '_overall' and data['covered'] > 0],
            key=lambda x: -x[1]['covered']
        )[:3]
        top_cats_str = ", ".join([f"{cat}({data['covered']})" for cat, data in top_cats])

        tool_data.append({
            'project': p,
            'covered': overall['covered'],
            'total': overall['total'],
            'percentage': overall['percentage'],
            'top_cats': top_cats_str
        })

    # Sort by coverage percentage descending
    tool_data.sort(key=lambda x: -x['percentage'])

    for td in tool_data:
        p = td['project']
        name = f"[{p['name']}]({p.get('repo-url', '#')})"
        stars = p.get('stars') or 0
        lines.append(
            f"| {name} | {stars} | {td['covered']}/{td['total']} | {td['percentage']}% | {td['top_cats']} |"
        )

    return "\n".join(lines)


def generate_summary(projects: List[dict], all_methods: Dict[str, List[str]]) -> str:
    """Generate high-level summary statistics."""
    active, excluded = filter_active_tools(projects)

    total_methods = sum(len(m) for m in all_methods.values())
    total_categories = len(all_methods)

    # Find all covered methods across all tools
    all_covered = set()
    for p in active:
        supported, partial = get_tool_methods(p)
        all_covered |= supported | partial

    lines = []
    lines.append("## Slack API Coverage Summary\n")
    lines.append(f"- **Total API Methods**: {total_methods}")
    lines.append(f"- **Total Categories**: {total_categories}")
    lines.append(f"- **Tools with Coverage Data**: {len(active)}")
    lines.append(f"- **Tools without Coverage Data**: {len(excluded)}")
    lines.append(f"- **Methods Covered by At Least One Tool**: {len(all_covered)} ({round(len(all_covered)/total_methods*100, 1)}%)")
    lines.append(f"- **Methods Not Covered by Any Tool**: {total_methods - len(all_covered)}")

    return "\n".join(lines)


def generate_gaps_table(projects: List[dict], all_methods: Dict[str, List[str]]) -> str:
    """Show methods not covered by each tool."""
    active, _ = filter_active_tools(projects)

    if not active:
        return "No tools have API coverage data.\n"

    all_method_names = set()
    for methods in all_methods.values():
        all_method_names.update(methods)

    lines = []
    lines.append("## API Coverage Gaps by Tool\n")

    for p in sorted(active, key=lambda x: -(x.get('stars') or 0)):
        supported, partial = get_tool_methods(p)
        covered = supported | partial
        gaps = all_method_names - covered

        lines.append(f"\n### {p['name']}")
        lines.append(f"Covered: {len(covered)}/{len(all_method_names)} ({round(len(covered)/len(all_method_names)*100, 1)}%)\n")

        if gaps:
            # Group gaps by category
            gaps_by_cat = defaultdict(list)
            for method in gaps:
                if '.' in method:
                    cat = method.split('.')[0]
                else:
                    cat = 'other'
                gaps_by_cat[cat].append(method)

            lines.append("<details>")
            lines.append(f"<summary>Missing {len(gaps)} methods</summary>\n")
            for cat in sorted(gaps_by_cat.keys()):
                lines.append(f"**{cat}** ({len(gaps_by_cat[cat])}): " +
                            ", ".join(sorted(gaps_by_cat[cat])[:10]))
                if len(gaps_by_cat[cat]) > 10:
                    lines.append(f"  ... and {len(gaps_by_cat[cat]) - 10} more")
            lines.append("</details>")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description='Generate Slack API coverage tables')
    parser.add_argument('--by-category', action='store_true', help='Coverage by API category')
    parser.add_argument('--by-tool', action='store_true', help='Coverage summary by tool')
    parser.add_argument('--summary', action='store_true', help='High-level summary')
    parser.add_argument('--gaps', action='store_true', help='Show coverage gaps')
    parser.add_argument('--all', action='store_true', help='Generate all tables')
    parser.add_argument('--output', type=str, help='Output file path')
    parser.add_argument('--spec-path', type=str,
                        default='archived-sources/slack-api/slack-web-openapi-v2.json')
    parser.add_argument('--projects-dir', type=str, default='projects')

    args = parser.parse_args()

    # Find paths
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    spec_path = repo_root / args.spec_path
    projects_dir = repo_root / args.projects_dir

    if not spec_path.exists():
        print(f"Error: OpenAPI spec not found at {spec_path}")
        return 1

    if not projects_dir.exists():
        print(f"Error: Projects directory not found at {projects_dir}")
        return 1

    # Load data
    all_methods = load_openapi_methods(spec_path)
    projects = load_projects(projects_dir)

    # Default to --all if no specific option
    if not any([args.by_category, args.by_tool, args.summary, args.gaps]):
        args.all = True

    # Generate output
    output_parts = []

    output_parts.append("# Slack API Coverage Comparison\n")
    output_parts.append("*Auto-generated from project YAML files and official Slack OpenAPI spec*\n")

    if args.summary or args.all:
        output_parts.append(generate_summary(projects, all_methods))
        output_parts.append("")

    if args.by_tool or args.all:
        output_parts.append(generate_by_tool_table(projects, all_methods))
        output_parts.append("")

    if args.by_category or args.all:
        output_parts.append(generate_by_category_table(projects, all_methods))
        output_parts.append("")

    if args.gaps or args.all:
        output_parts.append(generate_gaps_table(projects, all_methods))
        output_parts.append("")

    output = "\n".join(output_parts)

    # Write or print output
    if args.output:
        output_path = Path(args.output)
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(output)
        print(f"Output written to {output_path}")
    else:
        print(output)

    return 0


if __name__ == '__main__':
    exit(main())
