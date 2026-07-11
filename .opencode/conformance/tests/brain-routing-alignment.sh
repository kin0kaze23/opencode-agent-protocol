#!/bin/bash
# Guard 3: Brain Routing Alignment
# Purpose: Ensure brain-config.json and .opencode/opencode.json do not disagree.
#
# Usage: bash .opencode/conformance/tests/brain-routing-alignment.sh [--mode enforce]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/brain-routing-alignment-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../guard-assert.sh"

# Parse mode
MODE="audit"
for arg in "$@"; do
    case "$arg" in
        --mode) shift; MODE="$1" ;;
    esac
done

# Config paths
GLOBAL_CONFIG="$HOME/.config/opencode/opencode.json"
WORKSPACE_CONFIG="$WORKSPACE_ROOT/.opencode/opencode.json"
BRAIN_CONFIG="$WORKSPACE_ROOT/.opencode/brain-config.json"

echo "=========================================="
echo "Guard 3: Brain Routing Alignment"
echo "Mode: $MODE"
echo "Date: $(date -Iseconds)"
echo "=========================================="

reset_guard_counters
load_drift_registry "$WORKSPACE_ROOT"

# ============================================================
# 1. DEFAULT MODEL ALIGNMENT
# ============================================================
test_start "BRA-001" "default_model alignment"

ws_model=$(json_value "$WORKSPACE_CONFIG" "model")
brain_model=$(json_value "$BRAIN_CONFIG" "default_model")

if [ "$ws_model" = "$brain_model" ]; then
    guard_pass "BRA-001" "default_model aligned" "$ws_model"
else
    guard_fail "BRA-001" "default_model mismatch" "$ws_model" "$brain_model"
fi

# ============================================================
# 2. SMALL MODEL ALIGNMENT
# ============================================================
test_start "BRA-002" "small_model alignment"

ws_small=$(json_value "$WORKSPACE_CONFIG" "small_model")
brain_small=$(json_value "$BRAIN_CONFIG" "small_model")

if [ "$ws_small" = "$brain_small" ]; then
    guard_pass "BRA-002" "small_model aligned" "$ws_small"
else
    guard_fail "BRA-002" "small_model mismatch" "$ws_small" "$brain_small"
fi

# ============================================================
# 3. HELPER ROSTER ALIGNMENT
# ============================================================
test_start "BRA-003" "helper roster alignment"

# Get helper roster from brain-config (subagents.roster structure)
brain_helpers=$(python3 -c "
import json
with open('$BRAIN_CONFIG') as f:
    data = json.load(f)
roster = data.get('subagents', {}).get('roster', {})
core = roster.get('core', {})
specialized = roster.get('specialized', {})
for name in list(core.keys()) + list(specialized.keys()):
    print(name)
" 2>/dev/null || echo "")

# Get helper roster from workspace permissions
ws_helpers=$(python3 -c "
import json
with open('$WORKSPACE_CONFIG') as f:
    data = json.load(f)
task = data.get('permission', {}).get('task', {})
for name, val in task.items():
    if val == 'allow':
        print(name)
" 2>/dev/null || echo "")

# Get helper roster from global agents
global_helpers=$(python3 -c "
import json
with open('$GLOBAL_CONFIG') as f:
    data = json.load(f)
agents = data.get('agent', {})
for name in agents:
    if name != 'orchestrator':
        print(name)
" 2>/dev/null || echo "")

# Compare brain vs workspace
if [ -n "$brain_helpers" ] && [ -n "$ws_helpers" ]; then
    brain_sorted=$(echo "$brain_helpers" | sort)
    ws_sorted=$(echo "$ws_helpers" | sort)
    if [ "$brain_sorted" = "$ws_sorted" ]; then
        guard_pass "BRA-003" "helper roster aligned (brain vs workspace)" "$ws_sorted"
    else
        guard_fail "BRA-003" "helper roster mismatch" "$brain_sorted" "$ws_sorted"
    fi
else
    guard_warn "BRA-003" "helper roster comparison incomplete" "" "brain_helpers='$brain_helpers', ws_helpers='$ws_helpers'"
fi

# ============================================================
# 4. HELPER MODEL ASSIGNMENTS
# ============================================================
test_start "BRA-004" "helper model assignments alignment"

for helper in explorer planner implementer reviewer architect budget; do
    # Get model from global agent definition
    global_model=$(json_value "$GLOBAL_CONFIG" "agent.$helper.model")

    # Get model from brain-config routing
    brain_model=$(python3 -c "
import json
with open('$BRAIN_CONFIG') as f:
    data = json.load(f)
# Search through helper_roles or routing
roles = data.get('helper_roles', {})
helper_data = roles.get('$helper', {})
model = helper_data.get('model', '')
if not model:
    # Try routing section
    routing = data.get('routing', {})
    helpers = routing.get('helpers', {})
    helper_data = helpers.get('$helper', {})
    model = helper_data.get('model', '')
print(model if model else 'not_found')
" 2>/dev/null || echo "not_found")

    if [ "$brain_model" = "not_found" ]; then
        guard_skip "BRA-004-$helper" "$helper model not in brain-config routing" "Brain-config may not declare individual helper models"
    elif [ "$global_model" = "$brain_model" ]; then
        guard_pass "BRA-004-$helper" "$helper model aligned" "$global_model"
    else
        guard_fail "BRA-004-$helper" "$helper model mismatch" "$global_model" "$brain_model"
    fi
done

# ============================================================
# 5. ORCHESTRATOR MODE
# ============================================================
test_start "BRA-005" "orchestrator mode alignment"

ws_orch_mode=$(json_value "$WORKSPACE_CONFIG" "agent.orchestrator.mode")
brain_default_role=$(json_value "$BRAIN_CONFIG" "default_model_role")

if [ "$ws_orch_mode" = "primary" ]; then
    if echo "$brain_default_role" | grep -qi "owner.*orchestrator"; then
        guard_pass "BRA-005" "orchestrator mode aligned" "primary / owner orchestrator"
    else
        guard_warn "BRA-005" "orchestrator role description may not match" "" "Workspace mode: $ws_orch_mode, Brain role: $brain_default_role"
    fi
else
    guard_fail "BRA-005" "orchestrator mode unexpected" "primary" "$ws_orch_mode"
fi

# ============================================================
# 6. BUDGET ASSUMPTIONS
# ============================================================
test_start "BRA-006" "budget assumptions present"

brain_has_budgets=$(python3 -c "
import json
with open('$BRAIN_CONFIG') as f:
    data = json.load(f)
# Check for budget-related keys
has_budget = 'budgets' in data or any('budget' in str(v).lower() for v in data.values())
print('yes' if has_budget else 'no')
" 2>/dev/null || echo "no")

if [ "$brain_has_budgets" = "yes" ]; then
    guard_pass "BRA-006" "budget assumptions present in brain-config"
else
    guard_warn "BRA-006" "no budget assumptions found in brain-config" "" "May be intentional if budgets are not yet defined"
fi

# ============================================================
# 7. EVAL ROUTING POLICY
# ============================================================
test_start "BRA-007" "eval routing policy present"

brain_has_eval=$(python3 -c "
import json
with open('$BRAIN_CONFIG') as f:
    data = json.load(f)
has_eval = 'eval' in data or any('eval' in str(k).lower() or 'eval' in str(v).lower() for k, v in data.items())
print('yes' if has_eval else 'no')
" 2>/dev/null || echo "no")

if [ "$brain_has_eval" = "yes" ]; then
    guard_pass "BRA-007" "eval routing policy present in brain-config"
else
    guard_warn "BRA-007" "no eval routing policy found in brain-config" "" "May be intentional if eval routing is not yet defined"
fi

# ============================================================
# 8. FALLBACK ASSUMPTIONS
# ============================================================
test_start "BRA-008" "fallback assumptions alignment"

brain_fallback_status=$(python3 -c "
import json
with open('$BRAIN_CONFIG') as f:
    data = json.load(f)
pm = data.get('provider_migration', {})
status = pm.get('status', 'unknown')
print(status)
" 2>/dev/null || echo "unknown")

if json_key_exists "$GLOBAL_CONFIG" "provider.bailian-coding-plan"; then global_has_bailian="true"; else global_has_bailian="false"; fi

if [ "$global_has_bailian" = "true" ]; then
    if echo "$brain_fallback_status" | grep -qi "promoted\|active"; then
        guard_pass "BRA-008" "fallback assumptions aligned" "bailian in global (M3C: removed from workspace), status=$brain_fallback_status"
    else
        guard_warn "BRA-008" "fallback status may need review" "" "Status: $brain_fallback_status"
    fi
else
    guard_pass "BRA-008" "bailian provider removed from global (M3C complete)"
fi

# ============================================================
# RESULTS
# ============================================================
echo ""
guard_report "$RESULT_FILE" "Brain Routing Alignment"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
