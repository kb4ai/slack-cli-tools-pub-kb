#!/usr/bin/env bash
#
# Clone/Update All Tracked Repositories
# =====================================
#
# Clones or updates all repositories tracked in the projects/ directory
# into the tmp/ directory for analysis.
#
# Usage:
#     ./scripts/clone-all.sh              # Clone all missing repos
#     ./scripts/clone-all.sh --update     # Pull latest for existing clones
#     ./scripts/clone-all.sh --shallow    # Shallow clone (faster)
#     ./scripts/clone-all.sh --force      # Remove and re-clone all
#     ./scripts/clone-all.sh --dry-run    # Show what would be done
#
# Requirements:
#     - git
#     - yq (for YAML parsing) - install via: pip install yq, or brew install yq
#

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECTS_DIR="$REPO_ROOT/projects"
TMP_DIR="$REPO_ROOT/tmp"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat << EOF
Clone/Update All Tracked Slack CLI Tool Repositories

Usage: $(basename "$0") [OPTIONS]

Options:
    --update      Pull latest changes for existing clones
    --shallow     Use shallow clones (--depth 1)
    --force       Remove and re-clone all repositories
    --dry-run     Show what would be done without executing
    --help        Show this help message

Examples:
    $(basename "$0")                    # Clone missing repos
    $(basename "$0") --update           # Update all repos
    $(basename "$0") --shallow          # Shallow clone for speed
    $(basename "$0") --force --shallow  # Fresh shallow clones

EOF
}

check_dependencies() {
    if ! command -v git &> /dev/null; then
        log_error "git is required but not installed"
        exit 1
    fi

    if ! command -v yq &> /dev/null; then
        log_error "yq is required for YAML parsing"
        log_info "Install via: pip install yq  OR  brew install yq"
        exit 1
    fi
}

extract_repo_url() {
    local yaml_file="$1"
    yq -r '.["repo-url"] // empty' "$yaml_file"
}

url_to_dirname() {
    local url="$1"
    # Extract owner--repo from URL
    # https://github.com/owner/repo -> owner--repo
    echo "$url" | sed -E 's|https?://[^/]+/([^/]+)/([^/]+)/?.*|\1--\2|'
}

clone_repo() {
    local url="$1"
    local target_dir="$2"
    local shallow="${3:-false}"

    local clone_args=()
    if [[ "$shallow" == "true" ]]; then
        clone_args+=("--depth" "1")
    fi

    git clone "${clone_args[@]}" "$url" "$target_dir"
}

update_repo() {
    local target_dir="$1"

    cd "$target_dir"
    git fetch --all
    git pull --ff-only 2>/dev/null || {
        log_warning "Could not fast-forward pull, trying reset"
        git reset --hard origin/HEAD 2>/dev/null || \
        git reset --hard origin/main 2>/dev/null || \
        git reset --hard origin/master 2>/dev/null || \
        log_warning "Could not update $target_dir"
    }
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local update=false
    local shallow=false
    local force=false
    local dry_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --update)
                update=true
                shift
                ;;
            --shallow)
                shallow=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    check_dependencies

    # Ensure tmp directory exists
    if [[ ! -d "$TMP_DIR" ]]; then
        mkdir -p "$TMP_DIR"
    fi

    # Get list of YAML files
    local yaml_files=("$PROJECTS_DIR"/*.yaml)
    local total=${#yaml_files[@]}
    local cloned=0
    local updated=0
    local skipped=0
    local failed=0

    log_info "Processing $total project files..."
    echo

    for yaml_file in "${yaml_files[@]}"; do
        local filename=$(basename "$yaml_file")
        local url=$(extract_repo_url "$yaml_file")

        if [[ -z "$url" ]]; then
            log_warning "No repo-url in $filename, skipping"
            ((skipped++))
            continue
        fi

        local dirname=$(url_to_dirname "$url")
        local target_dir="$TMP_DIR/$dirname"

        echo -n "Processing $dirname... "

        if [[ "$dry_run" == "true" ]]; then
            if [[ -d "$target_dir" ]]; then
                if [[ "$update" == "true" ]]; then
                    echo "would update"
                elif [[ "$force" == "true" ]]; then
                    echo "would re-clone"
                else
                    echo "exists (skipped)"
                fi
            else
                echo "would clone"
            fi
            continue
        fi

        if [[ "$force" == "true" && -d "$target_dir" ]]; then
            rm -rf "$target_dir"
        fi

        if [[ -d "$target_dir" ]]; then
            if [[ "$update" == "true" ]]; then
                if update_repo "$target_dir"; then
                    log_success "updated"
                    ((updated++))
                else
                    log_error "update failed"
                    ((failed++))
                fi
                cd "$REPO_ROOT"
            else
                echo "exists (skipped)"
                ((skipped++))
            fi
        else
            if clone_repo "$url" "$target_dir" "$shallow" 2>/dev/null; then
                log_success "cloned"
                ((cloned++))
            else
                log_error "clone failed"
                ((failed++))
            fi
        fi
    done

    echo
    echo "========================================="
    echo "Summary:"
    echo "  Total:   $total"
    echo "  Cloned:  $cloned"
    echo "  Updated: $updated"
    echo "  Skipped: $skipped"
    echo "  Failed:  $failed"
    echo "========================================="
}

main "$@"
