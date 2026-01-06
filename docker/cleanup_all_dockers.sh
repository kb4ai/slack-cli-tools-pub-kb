#!/usr/bin/env bash
#
# cleanup_all_dockers.sh - Remove all Docker images and containers for Slack CLI tools
#
# Usage: ./cleanup_all_dockers.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

main() {
    cd "$SCRIPT_DIR"

    log_info "Cleaning up all Slack CLI Docker images and containers..."
    echo ""

    local success_count=0
    local fail_count=0

    for dir in */; do
        if [[ -f "${dir}manage.sh" ]]; then
            echo "=== Cleaning ${dir%/} ==="
            if (cd "$dir" && ./manage.sh clean 2>&1); then
                ((success_count++))
            else
                log_warn "Failed to clean ${dir%/}"
                ((fail_count++))
            fi
            echo ""
        fi
    done

    echo "=========================================="
    log_info "Cleanup complete: ${success_count} succeeded, ${fail_count} failed"

    # Also show any remaining slack-cli-tools images
    echo ""
    log_info "Checking for remaining slack-cli-tools images..."
    if docker images --filter "reference=slack-cli-tools-*" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q .; then
        log_warn "Found remaining images:"
        docker images --filter "reference=slack-cli-tools-*" --format "  {{.Repository}}:{{.Tag}} ({{.Size}})"
    else
        log_info "No slack-cli-tools images remaining"
    fi
}

main "$@"
