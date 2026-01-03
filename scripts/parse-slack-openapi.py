#!/usr/bin/env python3
"""
Parse Slack OpenAPI specification and extract API methods by category.

This script reads the archived Slack OpenAPI spec and outputs structured data
about all available API methods, grouped by category.

Usage:
    python parse-slack-openapi.py [--json] [--summary] [--list-methods]

Output modes:
    --json          Output full structured JSON
    --summary       Output category summary with method counts
    --list-methods  Output flat list of all method names
"""

import argparse
import json
from pathlib import Path
from collections import defaultdict


def load_openapi_spec(spec_path: Path) -> dict:
    """Load the OpenAPI specification JSON file."""
    with open(spec_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def extract_methods(spec: dict) -> dict:
    """
    Extract all API methods from the OpenAPI spec.

    Returns dict with structure:
    {
        "category": {
            "method_name": {
                "path": "/api/method.name",
                "description": "...",
                "parameters": [...],
                "http_method": "get|post"
            }
        }
    }
    """
    methods_by_category = defaultdict(dict)

    paths = spec.get('paths', {})

    for path, path_data in paths.items():
        # Extract method name from path (e.g., "/conversations.history" -> "conversations.history")
        method_name = path.lstrip('/')

        # Get category from method name (e.g., "conversations.history" -> "conversations")
        if '.' in method_name:
            category = method_name.split('.')[0]
        else:
            category = 'other'

        # Get HTTP method details (usually GET or POST)
        for http_method in ['get', 'post', 'put', 'delete', 'patch']:
            if http_method in path_data:
                method_details = path_data[http_method]

                # Extract parameters
                parameters = []
                for param in method_details.get('parameters', []):
                    param_info = {
                        'name': param.get('name'),
                        'required': param.get('required', False),
                        'type': param.get('type', 'unknown'),
                        'description': param.get('description', '')[:100]  # Truncate
                    }
                    parameters.append(param_info)

                methods_by_category[category][method_name] = {
                    'path': path,
                    'http_method': http_method.upper(),
                    'description': method_details.get('description', '')[:200],
                    'summary': method_details.get('summary', ''),
                    'parameters': parameters,
                    'parameter_count': len(parameters),
                    'required_params': [p['name'] for p in parameters if p['required']]
                }
                break  # Only process first HTTP method found

    return dict(methods_by_category)


def get_summary(methods_by_category: dict) -> dict:
    """Generate summary statistics."""
    summary = {
        'total_methods': 0,
        'total_categories': len(methods_by_category),
        'categories': {}
    }

    for category, methods in sorted(methods_by_category.items()):
        count = len(methods)
        summary['total_methods'] += count
        summary['categories'][category] = {
            'count': count,
            'methods': sorted(methods.keys())
        }

    return summary


def main():
    parser = argparse.ArgumentParser(description='Parse Slack OpenAPI specification')
    parser.add_argument('--json', action='store_true', help='Output full JSON')
    parser.add_argument('--summary', action='store_true', help='Output summary only')
    parser.add_argument('--list-methods', action='store_true', help='List all method names')
    parser.add_argument('--category', type=str, help='Filter to specific category')
    parser.add_argument('--spec-path', type=str,
                        default='archived-sources/slack-api/slack-web-openapi-v2.json',
                        help='Path to OpenAPI spec file')

    args = parser.parse_args()

    # Find spec file
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    spec_path = repo_root / args.spec_path

    if not spec_path.exists():
        print(f"Error: OpenAPI spec not found at {spec_path}")
        print("Run the archiver to download the spec first.")
        return 1

    # Load and parse spec
    spec = load_openapi_spec(spec_path)
    methods = extract_methods(spec)

    # Filter by category if specified
    if args.category:
        if args.category in methods:
            methods = {args.category: methods[args.category]}
        else:
            print(f"Error: Category '{args.category}' not found")
            print(f"Available categories: {', '.join(sorted(methods.keys()))}")
            return 1

    # Output based on mode
    if args.list_methods:
        # Flat list of all method names
        all_methods = []
        for category_methods in methods.values():
            all_methods.extend(category_methods.keys())
        for method in sorted(all_methods):
            print(method)

    elif args.summary:
        # Summary statistics
        summary = get_summary(methods)
        print(f"Slack Web API Methods Summary")
        print(f"=" * 50)
        print(f"Total Methods: {summary['total_methods']}")
        print(f"Total Categories: {summary['total_categories']}")
        print()
        print(f"{'Category':<20} {'Methods':>8}")
        print(f"{'-' * 20} {'-' * 8}")
        for cat, info in sorted(summary['categories'].items(),
                                key=lambda x: -x[1]['count']):
            print(f"{cat:<20} {info['count']:>8}")

    elif args.json:
        # Full JSON output
        output = {
            'spec_info': {
                'title': spec.get('info', {}).get('title', 'Slack Web API'),
                'version': spec.get('info', {}).get('version', 'unknown'),
                'source': str(spec_path)
            },
            'summary': get_summary(methods),
            'methods_by_category': methods
        }
        print(json.dumps(output, indent=2))

    else:
        # Default: summary with method lists
        summary = get_summary(methods)
        print(f"Slack Web API Methods")
        print(f"=" * 60)
        print(f"Total: {summary['total_methods']} methods in {summary['total_categories']} categories")
        print()

        for cat, info in sorted(summary['categories'].items(),
                                key=lambda x: -x[1]['count']):
            print(f"\n{cat} ({info['count']} methods):")
            for method in info['methods']:
                print(f"  - {method}")

    return 0


if __name__ == '__main__':
    exit(main())
