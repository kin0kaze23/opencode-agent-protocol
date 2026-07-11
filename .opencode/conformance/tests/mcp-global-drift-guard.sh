#!/bin/bash
# Guard: MCP Global Config Drift Guard
# Purpose: Ensure repo_only and requires_service MCPs do not leak into the global config.
# Enforces the MCP lifecycle policy declared in .opencode/policies/mcp-lifecycle.json.
#
# Usage: bash .opencode/conformance/tests/mcp-global-drift-guard.sh [--mode audit|enforce]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/mcp-global-drift-guard-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../guard-assert.sh"

MODE="audit"
for arg in "$@"; do
    case "$arg" in
        --mode) shift; MODE="$1" ;;
    esac
done

GLOBAL_CONFIG="$HOME/.config/opencode/opencode.json"
LIFECYCLE_POLICY="$WORKSPACE_ROOT/.opencode/policies/mcp-lifecycle.json"

echo "=========================================="
echo "Guard: MCP Global Config Drift Guard"
echo "Mode: $MODE"
echo "Date: $(date -Iseconds)"
echo "=========================================="

reset_guard_counters
load_drift_registry "$WORKSPACE_ROOT"

# ============================================================
# 1. VERIFY LIFECYCLE POLICY EXISTS
# ============================================================
test_start "DRIFT-001" "lifecycle policy exists"

if [ ! -f "$LIFECYCLE_POLICY" ]; then
    guard_fail "DRIFT-001" "MCP lifecycle policy not found: $LIFECYCLE_POLICY"
else
    guard_pass "DRIFT-001" "lifecycle policy exists"
fi

# ============================================================
# 2. CHECK GLOBAL CONFIG FOR REPO_ONLY MCP LEAKAGE
# ============================================================
test_start "DRIFT-002" "no repo_only MCPs in global config"

repo_only_mcps=$(python3 -c "
import json
with open('$LIFECYCLE_POLICY') as f:
    data = json.load(f)
for name, cfg in data.get('mcp_servers', {}).items():
    if cfg.get('lifecycle_state') == 'repo_only':
        print(name)
" 2>/dev/null || echo "")

for mcp_name in $repo_only_mcps; do
    exists=$(python3 -c "
import json
with open('$GLOBAL_CONFIG') as f:
    data = json.load(f)
print('yes' if '$mcp_name' in data.get('mcp', {}) else 'no')
" 2>/dev/null || echo "error")

    if [ "$exists" = "yes" ]; then
        guard_fail "DRIFT-002-$mcp_name" "repo_only MCP '$mcp_name' found in global config — should only exist in repo-level .opencode/opencode.json" "" "Run: bash .opencode/scripts/sync-opencode-runtime.sh"
    else
        guard_pass "DRIFT-002-$mcp_name" "repo_only MCP '$mcp_name' absent from global config"
    fi
done

# ============================================================
# 3. CHECK REQUIRES_SERVICE MCPs ARE NOT ENABLED WITHOUT HEALTH
# ============================================================
test_start "DRIFT-003" "requires_service MCPs not enabled without health check"

requires_service_mcps=$(python3 -c "
import json
with open('$LIFECYCLE_POLICY') as f:
    data = json.load(f)
for name, cfg in data.get('mcp_servers', {}).items():
    if cfg.get('lifecycle_state') == 'requires_service':
        print(name)
" 2>/dev/null || echo "")

for mcp_name in $requires_service_mcps; do
    enabled=$(python3 -c "
import json
with open('$GLOBAL_CONFIG') as f:
    data = json.load(f)
mcp = data.get('mcp', {}).get('$mcp_name', {})
print(str(mcp.get('enabled', False)).lower())
" 2>/dev/null || echo "error")

    if [ "$enabled" = "true" ]; then
        guard_fail "DRIFT-003-$mcp_name" "requires_service MCP '$mcp_name' is enabled in global config without service health check" "" "Run: bash .opencode/scripts/sync-opencode-runtime.sh to disable. Then either restore the service or formally deprecate."
    else
        guard_pass "DRIFT-003-$mcp_name" "requires_service MCP '$mcp_name' is disabled in global config"
    fi
done

# ============================================================
# 4. CHECK DEPRECATED MCPs ARE ABSENT
# ============================================================
test_start "DRIFT-004" "no deprecated MCPs in global config"

deprecated_mcps=$(python3 -c "
import json
with open('$LIFECYCLE_POLICY') as f:
    data = json.load(f)
for name, cfg in data.get('mcp_servers', {}).items():
    if cfg.get('lifecycle_state') == 'deprecated':
        print(name)
" 2>/dev/null || echo "")

for mcp_name in $deprecated_mcps; do
    exists=$(python3 -c "
import json
with open('$GLOBAL_CONFIG') as f:
    data = json.load(f)
print('yes' if '$mcp_name' in data.get('mcp', {}) else 'no')
" 2>/dev/null || echo "error")

    if [ "$exists" = "yes" ]; then
        guard_fail "DRIFT-004-$mcp_name" "deprecated MCP '$mcp_name' found in global config" "" "Remove from config and run sync-opencode-runtime.sh"
    else
        guard_pass "DRIFT-004-$mcp_name" "deprecated MCP '$mcp_name' absent from global config"
    fi
done

# ============================================================
# 5. CHECK GLOBAL CONFIG MATCHES WORKSPACE CONFIG FOR BASELINE MCPs
# ============================================================
test_start "DRIFT-005" "global config baseline MCPs match workspace config"

baseline_mcps=$(python3 -c "
import json
with open('$LIFECYCLE_POLICY') as f:
    data = json.load(f)
for name, cfg in data.get('mcp_servers', {}).items():
    state = cfg.get('lifecycle_state', '')
    if state in ('enabled', 'disabled', 'requires_service'):
        print(name)
" 2>/dev/null || echo "")

WORKSPACE_CONFIG="$WORKSPACE_ROOT/.opencode/opencode.json"

for mcp_name in $baseline_mcps; do
    global_enabled=$(python3 -c "
import json
with open('$GLOBAL_CONFIG') as f:
    data = json.load(f)
mcp = data.get('mcp', {}).get('$mcp_name', {})
print(str(mcp.get('enabled', 'absent')).lower())
" 2>/dev/null || echo "error")

    workspace_enabled=$(python3 -c "
import json
with open('$WORKSPACE_CONFIG') as f:
    data = json.load(f)
mcp = data.get('mcp', {}).get('$mcp_name', {})
print(str(mcp.get('enabled', 'absent')).lower())
" 2>/dev/null || echo "error")

    if [ "$global_enabled" != "$workspace_enabled" ]; then
        guard_fail "DRIFT-005-$mcp_name" "global/workspace drift: global=$global_enabled, workspace=$workspace_enabled" "" "Run: bash .opencode/scripts/sync-opencode-runtime.sh"
    else
        guard_pass "DRIFT-005-$mcp_name" "$mcp_name consistent: enabled=$global_enabled"
    fi
done

# ============================================================
# RESULTS
# ============================================================
echo ""
guard_report "$RESULT_FILE" "MCP Global Config Drift Guard"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
