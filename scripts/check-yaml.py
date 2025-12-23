#!/usr/bin/env python3
"""
YAML Validation Script for Slack CLI Tools Comparison

Validates project YAML files against the schema defined in spec.yaml.
Checks for required fields, type correctness, and format compliance.

Usage:
    ./scripts/check-yaml.py                     # Check all files in projects/
    ./scripts/check-yaml.py projects/foo.yaml   # Check specific file
    ./scripts/check-yaml.py --strict            # Fail on warnings too
    ./scripts/check-yaml.py --verbose           # Show all checks
"""

import sys
import os
import re
import argparse
from pathlib import Path
from datetime import datetime

try:
    import yaml
except ImportError:
    print("Error: PyYAML not installed. Run: pip install pyyaml")
    sys.exit(1)


# =============================================================================
# CONFIGURATION
# =============================================================================

REQUIRED_FIELDS = ['last-update', 'repo-url', 'name', 'description', 'language', 'category']

DATE_PATTERN = re.compile(r'^\d{4}-\d{2}-\d{2}$')
URL_PATTERN = re.compile(r'^https?://')
COMMIT_PATTERN = re.compile(r'^[a-fA-F0-9]{7,40}$')

VALID_LANGUAGES = [
    'Go', 'Python', 'TypeScript', 'JavaScript', 'Rust', 'Bash',
    'PHP', 'Java', 'C', 'Ruby', 'C++', 'Other'
]

VALID_CATEGORIES = [
    'official-cli', 'messaging-cli', 'terminal-ui', 'file-upload',
    'notification-tool', 'libpurple-plugin', 'bot-framework', 'api-wrapper',
    'export-tool', 'mcp-server'
]

VALID_MAINTENANCE_TIERS = [
    'active-development', 'maintenance-mode', 'community-sustained',
    'unmaintained', 'archived'
]

VALID_COMMIT_FREQUENCIES = [
    'very-active', 'active', 'moderate', 'sporadic', 'stale', 'abandoned'
]

INTEGER_FIELDS = ['stars', 'forks', 'watchers', 'contributors', 'open-issues',
                  'closed-issues', 'total-releases']

BOOLEAN_FIELDS = ['reputable-source', 'archived']

DATE_FIELDS = ['last-update', 'last-commit', 'created', 'last-release']


# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

class ValidationResult:
    def __init__(self, filename):
        self.filename = filename
        self.errors = []
        self.warnings = []

    def add_error(self, message):
        self.errors.append(message)

    def add_warning(self, message):
        self.warnings.append(message)

    @property
    def is_valid(self):
        return len(self.errors) == 0

    def print_results(self, verbose=False):
        if not self.errors and not self.warnings:
            if verbose:
                print(f"  {self.filename}")
            return

        print(f"\n{self.filename}:")
        for error in self.errors:
            print(f"  {error}")
        for warning in self.warnings:
            print(f"  {warning}")


def validate_date(value, field_name):
    """Validate date format (YYYY-MM-DD)."""
    if not DATE_PATTERN.match(str(value)):
        return f"Invalid date format for '{field_name}': {value} (expected YYYY-MM-DD)"
    try:
        datetime.strptime(str(value), '%Y-%m-%d')
    except ValueError:
        return f"Invalid date value for '{field_name}': {value}"
    return None


def validate_url(value, field_name):
    """Validate URL format."""
    if not URL_PATTERN.match(str(value)):
        return f"Invalid URL for '{field_name}': {value} (must start with http:// or https://)"
    return None


def validate_commit_hash(value, field_name):
    """Validate git commit hash format."""
    if not COMMIT_PATTERN.match(str(value)):
        return f"Invalid commit hash for '{field_name}': {value}"
    return None


def validate_enum(value, field_name, valid_values):
    """Validate value against allowed enum values."""
    if value not in valid_values:
        return f"Invalid value for '{field_name}': {value} (valid: {', '.join(valid_values)})"
    return None


def validate_type(value, field_name, expected_type, type_name):
    """Validate value type."""
    if not isinstance(value, expected_type):
        return f"Invalid type for '{field_name}': expected {type_name}, got {type(value).__name__}"
    return None


def validate_file(filepath: Path, verbose: bool = False) -> ValidationResult:
    """Validate a single YAML file."""
    result = ValidationResult(filepath.name)

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        result.add_error(f"YAML parsing error: {e}")
        return result
    except Exception as e:
        result.add_error(f"File read error: {e}")
        return result

    if data is None:
        result.add_error("Empty YAML file")
        return result

    # Check required fields
    for field in REQUIRED_FIELDS:
        if field not in data:
            result.add_error(f"Missing required field: '{field}'")

    # Validate date fields
    for field in DATE_FIELDS:
        if field in data and data[field]:
            error = validate_date(data[field], field)
            if error:
                result.add_error(error)

    # Validate URL fields
    if 'repo-url' in data and data['repo-url']:
        error = validate_url(data['repo-url'], 'repo-url')
        if error:
            result.add_error(error)

    if 'documentation' in data and isinstance(data['documentation'], dict):
        if 'website' in data['documentation'] and data['documentation']['website']:
            error = validate_url(data['documentation']['website'], 'documentation.website')
            if error:
                result.add_warning(error)

    # Validate commit hash
    if 'repo-commit' in data and data['repo-commit']:
        error = validate_commit_hash(data['repo-commit'], 'repo-commit')
        if error:
            result.add_warning(error)

    # Validate enum fields
    if 'language' in data and data['language']:
        error = validate_enum(data['language'], 'language', VALID_LANGUAGES)
        if error:
            result.add_error(error)

    if 'category' in data and data['category']:
        error = validate_enum(data['category'], 'category', VALID_CATEGORIES)
        if error:
            result.add_error(error)

    if 'maintenance-tier' in data and data['maintenance-tier']:
        error = validate_enum(data['maintenance-tier'], 'maintenance-tier', VALID_MAINTENANCE_TIERS)
        if error:
            result.add_warning(error)

    if 'commit-frequency' in data and data['commit-frequency']:
        error = validate_enum(data['commit-frequency'], 'commit-frequency', VALID_COMMIT_FREQUENCIES)
        if error:
            result.add_warning(error)

    # Validate integer fields
    for field in INTEGER_FIELDS:
        if field in data and data[field] is not None:
            if not isinstance(data[field], int):
                result.add_error(f"Field '{field}' must be an integer, got {type(data[field]).__name__}")

    # Validate boolean fields
    for field in BOOLEAN_FIELDS:
        if field in data and data[field] is not None:
            if not isinstance(data[field], bool):
                result.add_error(f"Field '{field}' must be a boolean, got {type(data[field]).__name__}")

    # Validate array fields
    for field in ['features', 'notes', 'warnings', 'languages', 'secondary-categories']:
        if field in data and data[field] is not None:
            if not isinstance(data[field], list):
                result.add_error(f"Field '{field}' must be an array, got {type(data[field]).__name__}")

    # Validate object fields
    for field in ['slack-features', 'authentication', 'output-formats', 'terminal-features',
                  'installation', 'documentation', 'ai-friendly']:
        if field in data and data[field] is not None:
            if not isinstance(data[field], dict):
                result.add_error(f"Field '{field}' must be an object, got {type(data[field]).__name__}")

    # Filename convention check
    expected_pattern = re.compile(r'^[a-zA-Z0-9_-]+--[a-zA-Z0-9_-]+\.yaml$')
    if not expected_pattern.match(filepath.name):
        result.add_warning(f"Filename should follow pattern: {{owner}}--{{repo}}.yaml")

    # Cross-field consistency checks
    if data.get('archived') and data.get('maintenance-tier') != 'archived':
        result.add_warning("If 'archived' is true, 'maintenance-tier' should be 'archived'")

    if data.get('reputable-source') and not data.get('organization'):
        result.add_warning("If 'reputable-source' is true, 'organization' should be specified")

    return result


def validate_all(projects_dir: Path, verbose: bool = False) -> list:
    """Validate all YAML files in the projects directory."""
    results = []
    yaml_files = sorted(projects_dir.glob('*.yaml'))

    for filepath in yaml_files:
        result = validate_file(filepath, verbose)
        results.append(result)

    return results


# =============================================================================
# MAIN
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Validate Slack CLI tools YAML files against schema'
    )
    parser.add_argument(
        'files',
        nargs='*',
        help='Specific YAML files to validate (default: all in projects/)'
    )
    parser.add_argument(
        '--strict',
        action='store_true',
        help='Fail on warnings too'
    )
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Show all checks including passes'
    )

    args = parser.parse_args()

    # Find project directory
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    projects_dir = repo_root / 'projects'

    if not projects_dir.exists():
        print(f"Error: Projects directory not found: {projects_dir}")
        sys.exit(1)

    # Validate files
    if args.files:
        results = []
        for file_path in args.files:
            filepath = Path(file_path)
            if not filepath.exists():
                print(f"Error: File not found: {filepath}")
                continue
            results.append(validate_file(filepath, args.verbose))
    else:
        results = validate_all(projects_dir, args.verbose)

    # Print results
    total_errors = 0
    total_warnings = 0
    valid_files = 0

    print("\n" + "=" * 60)
    print("SLACK CLI TOOLS YAML VALIDATION")
    print("=" * 60)

    for result in results:
        result.print_results(args.verbose)
        total_errors += len(result.errors)
        total_warnings += len(result.warnings)
        if result.is_valid:
            valid_files += 1

    # Summary
    print("\n" + "-" * 60)
    print(f"Files checked: {len(results)}")
    print(f"Valid files:   {valid_files}")
    print(f"Errors:        {total_errors}")
    print(f"Warnings:      {total_warnings}")
    print("-" * 60)

    if total_errors > 0:
        print("\nValidation FAILED")
        sys.exit(1)
    elif args.strict and total_warnings > 0:
        print("\nValidation FAILED (strict mode)")
        sys.exit(1)
    else:
        print("\nValidation PASSED")
        sys.exit(0)


if __name__ == '__main__':
    main()
