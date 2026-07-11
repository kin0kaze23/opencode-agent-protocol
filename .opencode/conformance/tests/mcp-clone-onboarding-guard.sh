#!/bin/bash
# Guard: MCP Clone Onboarding Guard
# Purpose: Warn when a cloned ui_ux repo lacks .opencode/opencode.json.
# Pre-registered but not-yet-cloned repos do NOT fail.
#
# Usage: bash .opencode/conformance/tests/mcp-clone-onboarding-guard.sh [--mode audit|enforce]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/mcp-clone-onboarding-guard-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../guard-assert.sh"

MODE="audit"
for arg in "$@"; do
    case "$arg" in
        --mode) shift; MODE="$1" ;;
    esac
done

REPO_MCP_PROFILES="$WORKSPACE_ROOT/.opencode/policies/repo-mcp-profiles.json"
LIFECYCLE_POLICY="$WORKSPACE_ROOT/.opencode/policies/mcp-lifecycle.json"

echo "=========================================="
echo "Guard: MCP Clone Onboarding Guard"
echo "Mode: $MODE"
echo "Date: $(date -Iseconds)"
echo "=========================================="

reset_guard_counters
load_drift_registry "$WORKSPACE_ROOT"

# ============================================================
# 1. VERIFY POLICY FILES EXIST
# ============================================================
test_start "ONBOARD-001" "policy files exist"

if [ ! -f "$REPO_MCP_PROFILES" ]; then
    guard_fail "ONBOARD-001" "repo-mcp-profiles.json not found"
else
    guard_pass "ONBOARD-001" "repo-mcp-profiles.json exists"
fi

if [ ! -f "$LIFECYCLE_POLICY" ]; then
    guard_fail "ONBOARD-001-lifecycle" "mcp-lifecycle.json not found"
else
    guard_pass "ONBOARD-001-lifecycle" "mcp-lifecycle.json exists"
fi

# ============================================================
# 2. CHECK CLONED UI_UX REPOS HAVE .opencode/opencode.json
# ============================================================
test_start "ONBOARD-002" "cloned ui_ux repos have .opencode/opencode.json"

# Get all repos mapped to ui_ux
ui_ux_repos=$(python3 -c "
import json
with open('$REPO_MCP_PROFILES') as f:
    data = json.load(f)
for name, mapping in data.get('mappings', {}).items():
    if mapping.get('profile') == 'ui_ux':
        print(name)
" 2>/dev/null || echo "")

# Get pre-registered repos (not yet cloned)
pre_registered=$(python3 -c "
import json
with open('$LIFECYCLE_POLICY') as f:
    data = json.load(f)
for repo in data.get('clone_onboarding', {}).get('pre_registered_repos', []):
    print(repo)
" 2>/dev/null || echo "")

for repo_name in $ui_ux_repos; do
    repo_path="$WORKSPACE_ROOT/$repo_name"

    # Check if repo is cloned (directory exists and has .git)
    if [ ! -d "$repo_path" ]; then
        # Pre-registered but not cloned — do not fail
        is_pre_registered=$(echo "$pre_registered" | grep -c "^${repo_name}$" 2>/dev/null || echo "0")
        if [ "$is_pre_registered" -gt 0 ]; then
            guard_pass "ONBOARD-002-$repo_name" "$repo_name is pre-registered (not yet cloned) — no action needed"
        else
            guard_warn "ONBOARD-002-$repo_name" "$repo_name is mapped to ui_ux but directory does not exist" "" "Clone the repo or update the profile mapping"
        fi
        continue
    fi

    # Check if repo has .git (is a proper git repo)
    if [ ! -d "$repo_path/.git" ] && [ ! -f "$repo_path/.git" ]; then
        guard_warn "ONBOARD-002-$repo_name" "$repo_name exists but is not a git repo — OpenCode may not detect it as a project root" "" "Run: cd $repo_path && git init"
        continue
    fi

    # Check if repo has .opencode/opencode.json
    if [ ! -f "$repo_path/.opencode/opencode.json" ]; then
        guard_warn "ONBOARD-002-$repo_name" "$repo_name is mapped to ui_ux but lacks .opencode/opencode.json — playwright and pencil MCPs will NOT be available" "" "Create .opencode/opencode.json with playwright + pencil enabled. See demo-project/.opencode/opencode.json for the template."
    else
        # Verify it has playwright and pencil enabled
        has_playwright=$(python3 -c "
import json
with open('$repo_path/.opencode/opencode.json') as f:
    mcp = json.load(f).get('mcp', {})
print(str(mcp.get('playwright', {}).get('enabled', False)).lower())
" 2>/dev/null || echo "error")

        has_pencil=$(python3 -c "
import json
with open('$repo_path/.opencode/opencode.json') as f:
    mcp = json.load(f).get('mcp', {})
print(str(mcp.get('pencil', {}).get('enabled', False)).lower())
" 2>/dev/null || echo "error")

        if [ "$has_playwright" = "true" ] && [ "$has_pencil" = "true" ]; then
            guard_pass "ONBOARD-002-$repo_name" "$repo_name has .opencode/opencode.json with playwright + pencil enabled"
        else
            guard_warn "ONBOARD-002-$repo_name" "$repo_name has .opencode/opencode.json but playwright=$has_playwright, pencil=$has_pencil" "" "Ensure both playwright and pencil are enabled in .opencode/opencode.json"
        fi
    fi
done

# ============================================================
# RESULTS
# ============================================================
echo ""
guard_report "$RESULT_FILE" "MCP Clone Onboarding Guard"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
