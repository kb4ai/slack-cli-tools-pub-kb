# Research and Maintenance Process

## Overview

This document describes the workflow for discovering, analyzing, documenting, and maintaining Slack CLI tool comparisons.

## Research Workflow

### Phase 1: Discovery

Sources for finding Slack CLI tools:

* GitHub search: `slack cli`, `slack terminal`, `slack command line`
* Awesome lists and curated collections
* Reddit (r/commandline, r/Slack, r/linux)
* Hacker News discussions
* Package managers (npm, PyPI, crates.io, Homebrew)
* Web search for "Slack CLI Linux"

### Phase 2: Initial Assessment

For each discovered tool, quickly assess:

1. **Is it relevant?** (Slack-focused CLI tool)
2. **Is it accessible?** (Open source, public repo)
3. **Is it distinct?** (Not a fork of existing tracked tool)

### Phase 3: Repository Cloning

```bash
# Clone all tracked repos
./scripts/clone-all.sh --shallow

# Update existing clones
./scripts/clone-all.sh --update
```

### Phase 4: Analysis

For each repository, investigate:

| Field | Source |
|-------|--------|
| Stars, forks | GitHub API or web UI |
| Language | GitHub repo page |
| License | LICENSE file or GitHub |
| Last commit | `git log -1` |
| Features | README, code inspection |
| Authentication | README, config files, code |
| Output formats | `--help`, code inspection |
| Installation | README, package registries |

### Phase 5: Documentation

1. Create/update YAML file in `projects/`
2. Fill in all discoverable fields
3. Add notes for subjective observations
4. Add warnings for important caveats

### Phase 6: Comparison Generation

```bash
# Validate all YAML
./scripts/check-yaml.py

# Generate tables
./scripts/generate-tables.py > comparisons/auto-generated.md
```

## Data Sources

### GitHub Metrics

```bash
# Using GitHub CLI
gh api repos/{owner}/{repo} --jq '.stargazers_count, .forks_count, .open_issues_count'

# Using curl
curl -s https://api.github.com/repos/{owner}/{repo} | jq '.stargazers_count'
```

### Package Registry Metrics

```bash
# npm
npm info {package} | grep downloads

# PyPI
curl -s https://pypistats.org/api/packages/{package}/recent | jq '.data.last_month'
```

### Repository Analysis

```bash
# Last commit date
git log -1 --format=%ci

# Contributors count
git shortlog -sn | wc -l

# Commit frequency (commits per month in last year)
git log --since="1 year ago" --format="%h" | wc -l
```

## Maintenance Schedule

### Monthly Tasks

* Update GitHub star counts
* Check for new releases
* Review open issues for maintenance signals

### Quarterly Tasks

* Discovery sweep for new tools
* Re-analyze repos with significant changes
* Update authentication information
* Review and update warnings

### On Major Slack API Changes

* Update authentication fields
* Check tool compatibility
* Update warnings for affected tools

## Quality Checklist

Before committing updates:

- [ ] All required fields present
- [ ] `last-update` is today's date
- [ ] URLs are valid and accessible
- [ ] Star counts are current
- [ ] Maintenance tier reflects reality
- [ ] Warnings capture important caveats
- [ ] `check-yaml.py` passes
- [ ] Generated tables look correct

## Research Notes

Document significant findings in `ramblings/`:

```
ramblings/
├── YYYY-MM-DD--discovery-sweep.md
├── YYYY-MM-DD--authentication-analysis.md
└── YYYY-MM-DD--{topic}.md
```

Format:

```markdown
# Topic Title

Date: YYYY-MM-DD

## Summary

Brief summary of findings.

## Details

Detailed notes, code snippets, observations.

## References

* [Link 1](url)
* [Link 2](url)
```
