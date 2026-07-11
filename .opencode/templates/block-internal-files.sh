#!/usr/bin/env bash
#
# Pre-commit hook: block internal/working files from being committed.
#
# This is the workspace-level canonical source. Each repo installs a copy
# into .git/hooks/pre-commit (for repos without the pre-commit framework)
# OR uses it as a local hook via .pre-commit-config.yaml.
#
# Install (standalone repos):
#   cp .opencode/templates/block-internal-files.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
#
# Install (pre-commit framework repos):
#   Add the local hook entry from .opencode/templates/pre-commit-internal-files.yaml
#
# Override: git commit --no-verify (for emergencies only)

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get list of staged files (added, modified, renamed)
staged=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)

if [ -z "$staged" ]; then
    exit 0
fi

blocked=()
reasons=()

# ============================================================================
# Rule 1: Internal working doc patterns (root-level)
# These file patterns should never be committed to any repo.
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
# These directories hold AI agent scratch notes and should never be committed.
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
# Rule 4: Root markdown allowlist (override per repo if needed)
# Only these .md files are allowed at repo root by default.
# Repos can extend this list by editing the array below in their local copy.
# ============================================================================
allowed_root_md=(
    "README.md"
    "PLAN.md"
    "CHANGELOG.md"
    "CONTRIBUTING.md"
    "INSTALL.md"
    "RELEASE_NOTES.md"
    "RELEASES.md"
    "LICENSE.md"
)

check_file() {
    local file="$1"

    # Check internal patterns
    for pattern in "${internal_patterns[@]}"; do
        if echo "$file" | grep -qiE "$pattern"; then
            blocked+=("$file")
            reasons+=("Internal working document (matches: $pattern)")
            return
        fi
    done

    # Check internal directories
    for pattern in "${internal_dirs[@]}"; do
        if echo "$file" | grep -qE "$pattern"; then
            blocked+=("$file")
            reasons+=("Internal working directory (matches: $pattern)")
            return
        fi
    done

    # Check build artifacts
    for pattern in "${artifact_patterns[@]}"; do
        if echo "$file" | grep -qE "$pattern"; then
            blocked+=("$file")
            reasons+=("Build artifact/cache (matches: $pattern) — add to .gitignore")
            return
        fi
    done

    # Check root markdown allowlist
    if [[ "$file" =~ ^[^/]+\.md$ ]]; then
        local allowed=false
        for allowed_file in "${allowed_root_md[@]}"; do
            if [ "$file" = "$allowed_file" ]; then
                allowed=true
                break
            fi
        done
        if [ "$allowed" = false ]; then
            blocked+=("$file")
            reasons+=("Unapproved .md file in repo root. Move to docs/ or extend allowed_root_md in local copy.")
        fi
    fi
}

while IFS= read -r file; do
    [ -n "$file" ] && check_file "$file"
done <<< "$staged"

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
