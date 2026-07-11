#!/usr/bin/env bash
#
# Pre-commit hook (pre-commit framework compatible): block internal/working files.
#
# This script receives file paths as arguments (from pre-commit framework).
# For standalone git hooks, use .opencode/templates/block-internal-files.sh instead.
#
# Install:
#   Add the local hook entry from .opencode/templates/pre-commit-internal-files.yaml
#   to your .pre-commit-config.yaml, then run `pre-commit install`.

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

if [ $# -eq 0 ]; then
    exit 0
fi

blocked=()
reasons=()

# ============================================================================
# Rule 1: Internal working doc patterns (root-level)
# ============================================================================
internal_patterns=(
    "^SPRINT[0-9]+_DELIVERABLES\.md$"
    "^ALPHA_.*\.md$"
    "^DOGFOOD_.*\.md$"
    "^LAUNCH_.*\.md$"
    "^PYPI_.*\.md$"
    "^FEEDBACK_.*\.md$"
    "^VALIDATION_REPORT\.md$"
    "^TODO.*\.md$"
    "^WORKING_.*\.md$"
    "^DRAFT_.*\.md$"
    "^NOTES_.*\.md$"
    "^INTERNAL_.*\.md$"
)

# ============================================================================
# Rule 2: AI assistant working directories
# ============================================================================
internal_dirs=(
    "^docs/superpowers/"
    "^docs/agent-notes/"
    "^docs/planning/"
    "^docs/internal/"
    "^\.opencode/working/"
    "^plans/"
    "^working/"
)

# ============================================================================
# Rule 3: Build artifacts and caches
# ============================================================================
artifact_patterns=(
    "\.DS_Store$"
    "^\.pytest_cache/"
    "^\.ruff_cache/"
    "^\.mypy_cache/"
    "^\.venv/"
    "^venv/"
    "^env/"
    "^dist/"
    "^build/"
    "\.egg-info/"
    "^__pycache__/"
)

# ============================================================================
# Rule 4: Root markdown allowlist (extend per repo if needed)
# ============================================================================
allowed_root_md=(
    "README.md"
    "AGENTS.md"
    "APPROVALS.md"
    "CLAUDE.md"
    "CHANGELOG.md"
    "CONTRIBUTING.md"
    "GATES.md"
    "INSTALL.md"
    "RELEASE_NOTES.md"
    "RELEASES.md"
    "NOW.md"
    "PLAN.md"
    "RUNBOOK.md"
    "SECURITY.md"
    "TECH_DEBT.md"
    "WORKSPACE_HYGIENE.md"
    "WORKSPACE_MAP.md"
    "WORKSPACE-NAVIGATION.md"
    "LICENSE.md"
    "LICENSE"
)

check_file() {
    local file="$1"

    # Deleted files should not be blocked; this hook validates files being added or kept.
    [ -e "$file" ] || return

    for pattern in "${internal_patterns[@]}"; do
        if echo "$file" | grep -qiE "$pattern"; then
            blocked+=("$file")
            reasons+=("Internal working document (matches: $pattern)")
            return
        fi
    done

    for pattern in "${internal_dirs[@]}"; do
        if echo "$file" | grep -qE "$pattern"; then
            blocked+=("$file")
            reasons+=("Internal working directory (matches: $pattern)")
            return
        fi
    done

    for pattern in "${artifact_patterns[@]}"; do
        if echo "$file" | grep -qE "$pattern"; then
            blocked+=("$file")
            reasons+=("Build artifact/cache (matches: $pattern) — add to .gitignore")
            return
        fi
    done

    # Extract basename for root-md check
    local basename_file
    basename_file="$(basename "$file")"
    if [[ "$file" != */* && "$basename_file" =~ \.md$ ]]; then
        local allowed=false
        for allowed_file in "${allowed_root_md[@]}"; do
            if [ "$basename_file" = "$allowed_file" ]; then
                allowed=true
                break
            fi
        done
        if [ "$allowed" = false ]; then
            blocked+=("$file")
            reasons+=("Unapproved .md file in repo root. Move to docs/ or extend allowed_root_md.")
        fi
    fi
}

for file in "$@"; do
    [ -n "$file" ] && check_file "$file"
done

if [ ${#blocked[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}========================================"
    echo "  PRE-COMMIT BLOCK: Internal files detected"
    echo "========================================${NC}"
    echo ""
    for i in "${!blocked[@]}"; do
        echo -e "  ${RED}✗${NC} ${blocked[$i]}"
        echo -e "    ${YELLOW}Reason: ${reasons[$i]}${NC}"
        echo ""
    done

    echo -e "${GREEN}Allowed root .md files:${NC} ${allowed_root_md[*]}"
    echo -e "${GREEN}Need to commit anyway?${NC} Use: git commit --no-verify"
    echo ""
    echo -e "${YELLOW}Tip: Run 'git reset HEAD <file>' to unstage, then move or delete the file.${NC}"
    echo ""
    exit 1
fi

exit 0
