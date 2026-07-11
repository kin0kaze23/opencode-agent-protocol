#!/bin/bash
# Guard 2: MCP Policy Guard (Profile-Based)
# Purpose: Ensure MCP state matches the assigned repo profile.
# Compares against .opencode/policies/mcp-profiles.json and repo-mcp-profiles.json.
#
# Usage: bash .opencode/conformance/tests/mcp-policy-guard.sh [--mode audit|enforce] [--repo <repo_name>]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/mcp-policy-guard-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../guard-assert.sh"

# Parse arguments
MODE="audit"
TARGET_REPO=""
for arg in "$@"; do
    case "$arg" in
        --mode) shift; MODE="$1" ;;
        --repo) shift; TARGET_REPO="$1" ;;
    esac
done

# Config paths
GLOBAL_CONFIG="$HOME/.config/opencode/opencode.json"
WORKSPACE_CONFIG="$WORKSPACE_ROOT/.opencode/opencode.json"
MCP_PROFILES="$WORKSPACE_ROOT/.opencode/policies/mcp-profiles.json"
REPO_MAPPINGS="$WORKSPACE_ROOT/.opencode/policies/repo-mcp-profiles.json"

echo "=========================================="
echo "Guard 2: MCP Policy Guard (Profile-Based)"
echo "Mode: $MODE"
echo "Date: $(date -Iseconds)"
echo "=========================================="

reset_guard_counters
load_drift_registry "$WORKSPACE_ROOT"

if [ ! -f "$MCP_PROFILES" ]; then
    echo -e "${RED}✗ MCP profiles file not found: $MCP_PROFILES${NC}"
    exit 1
fi

if [ ! -f "$REPO_MAPPINGS" ]; then
    echo -e "${RED}✗ Repo mappings file not found: $REPO_MAPPINGS${NC}"
    exit 1
fi

# ============================================================
# 1. VALIDATE PROFILE DEFINITIONS
# ============================================================
test_start "MCP-PROFILE-001" "MCP profile definitions exist"

for profile in baseline ui_ux research automation apa_product_factory archived; do
    profile_exists=$(python3 -c "
import json
with open('$MCP_PROFILES') as f:
    data = json.load(f)
print('yes' if '$profile' in data.get('profiles', {}) else 'no')
" 2>/dev/null)
    if [ "$profile_exists" = "yes" ]; then
        guard_pass "MCP-PROFILE-001-$profile" "profile '$profile' defined"
    else
        guard_fail "MCP-PROFILE-001-$profile" "profile '$profile' missing"
    fi
done

# ============================================================
# 2. VALIDATE REPO-TO-PROFILE MAPPINGS
# ============================================================
test_start "MCP-PROFILE-002" "repo-to-profile mappings"

# Get all repos with .opencode/ or that are git repos
all_repos=$(find "$WORKSPACE_ROOT" -maxdepth 2 -name ".git" -type d 2>/dev/null | while read -r dir; do
    dirname "$dir"
done)

for repo_path in $all_repos; do
    repo_name=$(basename "$repo_path")

    # Skip if targeting a specific repo
    if [ -n "$TARGET_REPO" ] && [ "$repo_name" != "$TARGET_REPO" ]; then
        continue
    fi

    # Get assigned profile
    assigned_profile=$(python3 -c "
import json
with open('$REPO_MAPPINGS') as f:
    data = json.load(f)
mapping = data.get('mappings', {}).get('$repo_name', {})
print(mapping.get('profile', data.get('default_profile', 'baseline')))
" 2>/dev/null)

    guard_pass "MCP-PROFILE-002-$repo_name" "$repo_name mapped to '$assigned_profile'"
done

# ============================================================
# 3. VALIDATE WORKSPACE MCP STATE AGAINST BASELINE PROFILE
# ============================================================
test_start "MCP-PROFILE-003" "workspace MCP state matches baseline profile"

# Get baseline profile MCP requirements
baseline_mcp=$(python3 -c "
import json
with open('$MCP_PROFILES') as f:
    data = json.load(f)
profile = data.get('profiles', {}).get('baseline', {})
mcp = profile.get('mcp', {})
for name, config in mcp.items():
    print(f'{name}={config.get(\"status\", \"unknown\")}')
" 2>/dev/null)

while IFS='=' read -r mcp_name expected_status; do
    [ -z "$mcp_name" ] && continue

    # Get actual workspace state
    ws_exists=$(json_key_exists "$WORKSPACE_CONFIG" "mcp.$mcp_name" && echo "true" || echo "false")

    if [ "$ws_exists" = "true" ]; then
        ws_enabled=$(json_value "$WORKSPACE_CONFIG" "mcp.$mcp_name.enabled")
    else
        ws_enabled="missing"
    fi

    # Check against profile
    case "$expected_status" in
        required)
            if [ "$ws_enabled" = "true" ]; then
                guard_pass "MCP-PROFILE-003-$mcp_name" "$mcp_name is required and enabled"
            elif [ "$ws_enabled" = "false" ] || [ "$ws_enabled" = "missing" ]; then
                # Check if this is known C0 drift
                drift_id=""
                [ "$mcp_name" = "playwright" ] && drift_id="C0-DRIFT-001"
                [ "$mcp_name" = "firecrawl" ] && drift_id="C0-DRIFT-002"
                [ "$mcp_name" = "pencil" ] && drift_id="C0-DRIFT-003"
                if [ -n "$drift_id" ] && is_known_drift "$drift_id"; then
                    guard_warn "MCP-PROFILE-003-$mcp_name" "$mcp_name should be required but is $ws_enabled" "$drift_id" "Baseline profile requires this MCP"
                else
                    guard_fail "MCP-PROFILE-003-$mcp_name" "$mcp_name should be required" "enabled=true" "actual=$ws_enabled"
                fi
            fi
            ;;
        disabled)
            if [ "$ws_enabled" = "false" ] || [ "$ws_enabled" = "missing" ]; then
                guard_pass "MCP-PROFILE-003-$mcp_name" "$mcp_name is disabled as expected"
            else
                guard_fail "MCP-PROFILE-003-$mcp_name" "$mcp_name should be disabled" "enabled=false" "actual=$ws_enabled"
            fi
            ;;
        optional|task-based)
            # Optional/task-based MCPs are allowed in any state
            guard_pass "MCP-PROFILE-003-$mcp_name" "$mcp_name is $expected_status (any state allowed)" "actual=$ws_enabled"
            ;;
        deprecated)
            # Deprecated MCPs should be absent from workspace config
            if [ "$ws_enabled" = "missing" ]; then
                guard_pass "MCP-PROFILE-003-$mcp_name" "$mcp_name is deprecated and absent from config"
            else
                guard_fail "MCP-PROFILE-003-$mcp_name" "$mcp_name is deprecated but still present in config" "missing" "actual=$ws_enabled"
            fi
            ;;
        *)
            guard_warn "MCP-PROFILE-003-$mcp_name" "$mcp_name has unknown status '$expected_status'"
            ;;
    esac
done <<< "$baseline_mcp"

# ============================================================
# 4. CHECK GLOBAL vs WORKSPACE MCP DRIFT IS INTENTIONAL
# ============================================================
test_start "MCP-PROFILE-004" "global vs workspace MCP drift is intentional"

all_mcp_servers=$(python3 -c "
import json
with open('$MCP_PROFILES') as f:
    data = json.load(f)
profile = data.get('profiles', {}).get('baseline', {})
mcp = profile.get('mcp', {})
for name in mcp:
    print(name)
" 2>/dev/null)

for mcp in $all_mcp_servers; do
    global_enabled=$(json_value "$GLOBAL_CONFIG" "mcp.$mcp.enabled")
    ws_exists=$(json_key_exists "$WORKSPACE_CONFIG" "mcp.$mcp" && echo "true" || echo "false")

    if [ "$ws_exists" = "true" ]; then
        ws_enabled=$(json_value "$WORKSPACE_CONFIG" "mcp.$mcp.enabled")
    else
        ws_enabled="missing"
    fi

    if [ "$global_enabled" != "$ws_enabled" ]; then
        # Check if this drift is documented in the profile policy
        profile_status=$(python3 -c "
import json
with open('$MCP_PROFILES') as f:
    data = json.load(f)
profile = data.get('profiles', {}).get('baseline', {})
mcp = profile.get('mcp', {}).get('$mcp', {})
print(mcp.get('status', 'unknown'))
" 2>/dev/null)

        if [ "$profile_status" = "disabled" ] && [ "$ws_enabled" = "false" -o "$ws_enabled" = "missing" ]; then
            # Workspace correctly disables this MCP per baseline profile
            guard_pass "MCP-PROFILE-004-$mcp" "$mcp drift is intentional (baseline disables, global enables)" "global=$global_enabled, workspace=$ws_enabled"
        elif [ "$profile_status" = "required" ] && [ "$ws_enabled" != "true" ]; then
            # Workspace should enable but doesn't — this is drift
            drift_id=""
            [ "$mcp" = "playwright" ] && drift_id="C0-DRIFT-001"
            [ "$mcp" = "firecrawl" ] && drift_id="C0-DRIFT-002"
            [ "$mcp" = "pencil" ] && drift_id="C0-DRIFT-003"
            if [ -n "$drift_id" ] && is_known_drift "$drift_id"; then
                guard_warn "MCP-PROFILE-004-$mcp" "$mcp drift: global=$global_enabled, workspace=$ws_enabled" "$drift_id" "Baseline profile requires this MCP"
            else
                guard_fail "MCP-PROFILE-004-$mcp" "$mcp drift is unclassified" "global=$global_enabled" "workspace=$ws_enabled"
            fi
        else
            guard_pass "MCP-PROFILE-004-$mcp" "$mcp drift is documented" "global=$global_enabled, workspace=$ws_enabled, profile=$profile_status"
        fi
    else
        guard_pass "MCP-PROFILE-004-$mcp" "$mcp consistent across global and workspace" "enabled=$global_enabled"
    fi
done

# ============================================================
# 5. CHECK FOR ORPHAN MCP SERVERS
# ============================================================
test_start "MCP-PROFILE-005" "no orphan MCP servers in workspace config"

config_mcp_servers=$(python3 -c "
import json
with open('$WORKSPACE_CONFIG') as f:
    data = json.load(f)
mcp = data.get('mcp', {})
for name in mcp:
    print(name)
" 2>/dev/null || true)

profile_mcp_servers=$(python3 -c "
import json
with open('$MCP_PROFILES') as f:
    data = json.load(f)
profile = data.get('profiles', {}).get('baseline', {})
mcp = profile.get('mcp', {})
for name in mcp:
    print(name)
" 2>/dev/null)

orphan_found=false
for mcp in $config_mcp_servers; do
    if ! echo "$profile_mcp_servers" | grep -q "^${mcp}$"; then
        guard_fail "MCP-PROFILE-005-$mcp" "MCP server '$mcp' in workspace config but not in baseline profile"
        orphan_found=true
    fi
done

if [ "$orphan_found" = "false" ]; then
    guard_pass "MCP-PROFILE-005" "All workspace MCP servers are covered by baseline profile"
fi

# ============================================================
# RESULTS
# ============================================================
echo ""
guard_report "$RESULT_FILE" "MCP Policy Guard (Profile-Based)"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
