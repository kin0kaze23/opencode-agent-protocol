#!/bin/bash
# Guard 6: Repo Exception Guard
# Purpose: Ensure repo-level .opencode/ folders stay clean (hooks only).
#
# Usage: bash .opencode/conformance/tests/repo-exception-guard.sh [--mode enforce]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/repo-exception-guard-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../guard-assert.sh"

# Parse mode
MODE="audit"
for arg in "$@"; do
    case "$arg" in
        --mode) shift; MODE="$1" ;;
    esac
done

echo "=========================================="
echo "Guard 6: Repo Exception Guard"
echo "Mode: $MODE"
echo "Date: $(date -Iseconds)"
echo "=========================================="

reset_guard_counters
load_drift_registry "$WORKSPACE_ROOT"

# ============================================================
# Approved repo exceptions (from ADRs)
# Format: one line per repo: "repo_name:item1,item2,item3"
# ============================================================
EXCEPTIONS_FILE="$WORKSPACE_ROOT/.opencode/policies/repo-exceptions.json"

# Check if a repo+item is an approved exception
is_approved_exception() {
    local repo_name="$1"
    local item="$2"
    if [ ! -f "$EXCEPTIONS_FILE" ]; then
        return 1
    fi
    python3 -c "
import json, sys
with open('$EXCEPTIONS_FILE') as f:
    data = json.load(f)
exceptions = data.get('exceptions', {})
repo = exceptions.get('$repo_name', {})
allowed = repo.get('allowed_contents', [])
if '$item' in allowed:
    sys.exit(0)
sys.exit(1)
" 2>/dev/null
}

# Allowed contents for repo .opencode/
ALLOWED_CONTENTS="hooks"
FORBIDDEN_FILES="opencode.json opencode.jsonc brain-config.json agents models mcp permissions"

# ============================================================
# 1. FIND ALL REPOS WITH .opencode/
# ============================================================
test_start "REG-001" "discover repos with .opencode/"

repos_with_opencode=$(find "$WORKSPACE_ROOT" -maxdepth 2 -name ".opencode" -type d 2>/dev/null | while read -r dir; do
    # Skip workspace root itself
    if [ "$dir" != "$WORKSPACE_ROOT/.opencode" ]; then
        dirname "$dir"
    fi
done)

repo_count=$(echo "$repos_with_opencode" | grep -c . 2>/dev/null || echo "0")
guard_pass "REG-001" "found $repo_count repos with .opencode/"
echo -e "    ${CYAN}→${NC} Repos: $(echo "$repos_with_opencode" | tr '\n' ', ' | sed 's/,$//')"

# ============================================================
# 2. CHECK EACH REPO .opencode/ CONTENTS
# ============================================================
test_start "REG-002" "repo .opencode/ contents are allowed"

for repo in $repos_with_opencode; do
    repo_name=$(basename "$repo")
    opencode_dir="$repo/.opencode"

    if [ ! -d "$opencode_dir" ]; then
        continue
    fi

    # List contents
    contents=$(ls -1 "$opencode_dir" 2>/dev/null || true)

    for item in $contents; do
        # Check if item is allowed (standard)
        if echo "$ALLOWED_CONTENTS" | grep -q "^${item}$"; then
            guard_pass "REG-002-$repo_name-$item" "$repo_name/.opencode/$item is allowed"
        # Check if item is an approved exception for this repo
        elif is_approved_exception "$repo_name" "$item"; then
            guard_pass "REG-002-$repo_name-$item" "$repo_name/.opencode/$item is approved exception (ADR)"
        else
            # Check if it's a forbidden file
            if echo "$FORBIDDEN_FILES" | grep -q "^${item}$"; then
                guard_fail "REG-002-$repo_name-$item" "$repo_name/.opencode/$item is forbidden" "" "Only '$ALLOWED_CONTENTS' allowed without ADR"
            else
                # Unknown item — warn in audit mode, fail in enforce mode
                if [ "$MODE" = "enforce" ]; then
                    guard_fail "REG-002-$repo_name-$item" "$repo_name/.opencode/$item is not explicitly allowed" "" "Only '$ALLOWED_CONTENTS' allowed"
                else
                    guard_warn "REG-002-$repo_name-$item" "$repo_name/.opencode/$item is not in allowed list" "" "Review: is this an intentional exception?"
                fi
            fi
        fi
    done
done

# ============================================================
# 3. CHECK FOR FORBIDDEN FILES SPECIFICALLY
# ============================================================
test_start "REG-003" "no forbidden files in repo .opencode/"

for repo in $repos_with_opencode; do
    repo_name=$(basename "$repo")
    opencode_dir="$repo/.opencode"

    for forbidden in $FORBIDDEN_FILES; do
        if [ -e "$opencode_dir/$forbidden" ]; then
            # Check if this is an approved exception for this repo
            if is_approved_exception "$repo_name" "$forbidden"; then
                guard_pass "REG-003-$repo_name-$forbidden" "$repo_name/.opencode/$forbidden exists (approved exception)"
            else
                guard_fail "REG-003-$repo_name-$forbidden" "$repo_name/.opencode/$forbidden exists (forbidden)"
            fi
        else
            guard_pass "REG-003-$repo_name-$forbidden" "$repo_name/.opencode/$forbidden absent"
        fi
    done
done

# ============================================================
# 4. CHECK HOOKS ARE VALID
# ============================================================
test_start "REG-004" "repo hooks are valid scripts"

for repo in $repos_with_opencode; do
    repo_name=$(basename "$repo")
    hooks_dir="$repo/.opencode/hooks"

    if [ ! -d "$hooks_dir" ]; then
        continue
    fi

    hooks=$(ls -1 "$hooks_dir" 2>/dev/null || true)
    for hook in $hooks; do
        hook_path="$hooks_dir/$hook"
        if [ -f "$hook_path" ]; then
            if [ -x "$hook_path" ] || head -1 "$hook_path" 2>/dev/null | grep -q "^#!"; then
                guard_pass "REG-004-$repo_name-$hook" "$repo_name hooks/$hook is valid"
            else
                guard_warn "REG-004-$repo_name-$hook" "$repo_name hooks/$hook may not be executable" "" "No shebang or execute permission"
            fi
        fi
    done
done

# ============================================================
# 5. REPOS WITHOUT .opencode/ (should be clean)
# ============================================================
test_start "REG-005" "repos without .opencode/ are clean"

# Find all git repos
all_repos=$(find "$WORKSPACE_ROOT" -maxdepth 2 -name ".git" -type d 2>/dev/null | while read -r dir; do
    dirname "$dir"
done)

for repo in $all_repos; do
    repo_name=$(basename "$repo")
    if [ ! -d "$repo/.opencode" ]; then
        guard_pass "REG-005-$repo_name" "$repo_name has no .opencode/ (pure inheritance)"
    fi
done

# ============================================================
# RESULTS
# ============================================================
echo ""
guard_report "$RESULT_FILE" "Repo Exception Guard"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
