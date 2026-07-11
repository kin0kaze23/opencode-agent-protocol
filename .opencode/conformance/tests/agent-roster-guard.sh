#!/bin/bash
# Guard 4: Agent Roster Guard (Post-C4)
# Purpose: Ensure all 7 agents are resolvable and consistent in workspace.
#
# Usage: bash .opencode/conformance/tests/agent-roster-guard.sh [--mode enforce]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/agent-roster-guard-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../guard-assert.sh"

# Parse mode
MODE="audit"
for arg in "$@"; do
    case "$arg" in
        --mode) shift; MODE="$1" ;;
    esac
done

# Config paths
WORKSPACE_CONFIG="$WORKSPACE_ROOT/.opencode/opencode.json"
AGENT_POLICY="$WORKSPACE_ROOT/.opencode/policies/agent-roster.json"
AGENTS_DIR="$WORKSPACE_ROOT/.opencode/agents"
GLOBAL_PROMPTS="$HOME/.config/opencode/prompts"
WORKSPACE_PROMPTS="$WORKSPACE_ROOT/.opencode/global-runtime/prompts"

echo "=========================================="
echo "Guard 4: Agent Roster Guard (Post-C4)"
echo "Mode: $MODE"
echo "Date: $(date -Iseconds)"
echo "=========================================="

reset_guard_counters
load_drift_registry "$WORKSPACE_ROOT"

# Load expected roster from policy
expected_agents=$(python3 -c "
import json
with open('$AGENT_POLICY') as f:
    data = json.load(f)
agents = data.get('agents', {})
for name in agents:
    print(name)
" 2>/dev/null)

# ============================================================
# 1. ORCHESTRATOR EXISTS
# ============================================================
test_start "ARG-001" "orchestrator exists in workspace"

if json_key_exists "$WORKSPACE_CONFIG" "agent.orchestrator"; then
    guard_pass "ARG-001" "orchestrator declared in workspace"
else
    guard_fail "ARG-001" "orchestrator missing from workspace"
fi

# ============================================================
# 2. ALL 7 AGENTS EXIST
# ============================================================
test_start "ARG-002" "all 7 agents exist in workspace"

for agent in $expected_agents; do
    if json_key_exists "$WORKSPACE_CONFIG" "agent.$agent"; then
        guard_pass "ARG-002-$agent" "$agent declared in workspace"
    else
        guard_fail "ARG-002-$agent" "$agent missing from workspace"
    fi
done

# ============================================================
# 3. EACH HELPER HAS EXPECTED MODEL
# ============================================================
test_start "ARG-003" "helper model assignments in workspace"

for agent in $expected_agents; do
    expected_model=$(json_value "$AGENT_POLICY" "agents.$agent.model")
    ws_model=$(json_value "$WORKSPACE_CONFIG" "agent.$agent.model")

    if [ "$ws_model" = "$expected_model" ]; then
        guard_pass "ARG-003-$agent" "$agent model matches policy" "$ws_model"
    else
        guard_fail "ARG-003-$agent" "$agent model mismatch" "$expected_model" "$ws_model"
    fi
done

# ============================================================
# 4. EACH HELPER HAS EXPECTED PROMPT
# ============================================================
test_start "ARG-004" "helper prompt files"

for agent in $expected_agents; do
    expected_prompt=$(json_value "$AGENT_POLICY" "agents.$agent.prompt_source")
    global_prompt=$(json_value "$AGENT_POLICY" "agents.$agent.prompt_global")

    # Check global prompt exists
    if [ -f "$global_prompt" ]; then
        global_md5=$(md5sum "$global_prompt" 2>/dev/null | awk '{print $1}')
        guard_pass "ARG-004-global-$agent" "$agent global prompt exists" "md5=$global_md5"
    else
        guard_fail "ARG-004-global-$agent" "$agent global prompt missing" "" "$global_prompt"
    fi

    # Check workspace prompt exists
    ws_prompt_path="$WORKSPACE_PROMPTS/${agent}.md"
    if [ -f "$ws_prompt_path" ]; then
        ws_md5=$(md5sum "$ws_prompt_path" 2>/dev/null | awk '{print $1}')
        if [ "$global_md5" = "$ws_md5" ]; then
            guard_pass "ARG-004-ws-$agent" "$agent workspace prompt matches global" "md5=$ws_md5"
        else
            guard_fail "ARG-004-ws-$agent" "$agent prompt drift" "global=$global_md5" "workspace=$ws_md5"
        fi
    else
        guard_fail "ARG-004-ws-$agent" "$agent workspace prompt missing" "" "$ws_prompt_path"
    fi

    # Check agent source file exists (orchestrator is manual-canonical)
    agent_source="$AGENTS_DIR/${agent}.md"
    if [ "$agent" = "orchestrator" ]; then
        guard_skip "ARG-004-source-$agent" "orchestrator is manual-canonical (no agents/ source)" "Intentional: orchestrator prompt is workspace-specific policy"
    elif [ -f "$agent_source" ]; then
        guard_pass "ARG-004-source-$agent" "$agent source file exists" "$agent_source"
    else
        guard_warn "ARG-004-source-$agent" "$agent source file missing" "" "Expected: $agent_source"
    fi
done

# ============================================================
# 5. EACH HELPER HAS EXPECTED PERMISSION BOUNDARY
# ============================================================
test_start "ARG-005" "helper permission boundaries in workspace"

for agent in $expected_agents; do
    if [ "$agent" = "orchestrator" ]; then
        continue  # Orchestrator has different permissions
    fi

    expected_edit=$(json_value "$AGENT_POLICY" "agents.$agent.permission.edit")
    expected_bash=$(json_value "$AGENT_POLICY" "agents.$agent.permission.bash")
    ws_edit=$(json_value "$WORKSPACE_CONFIG" "agent.$agent.permission.edit")
    ws_bash=$(json_value "$WORKSPACE_CONFIG" "agent.$agent.permission.bash")

    if [ "$ws_edit" = "$expected_edit" ]; then
        guard_pass "ARG-005-edit-$agent" "$agent edit permission matches" "$ws_edit"
    else
        guard_fail "ARG-005-edit-$agent" "$agent edit permission mismatch" "$expected_edit" "$ws_edit"
    fi

    if [ "$ws_bash" = "$expected_bash" ]; then
        guard_pass "ARG-005-bash-$agent" "$agent bash permission matches" "$ws_bash"
    else
        guard_fail "ARG-005-bash-$agent" "$agent bash permission mismatch" "$expected_bash" "$ws_bash"
    fi
done

# ============================================================
# 6. PERMISSION.TASK INCLUDES ONLY APPROVED HELPERS
# ============================================================
test_start "ARG-006" "permission.task includes only approved helpers"

approved_helpers=$(python3 -c "
import json
with open('$AGENT_POLICY') as f:
    data = json.load(f)
for h in data.get('permission_task_allowed', []):
    print(h)
" 2>/dev/null)

actual_helpers=$(python3 -c "
import json
with open('$WORKSPACE_CONFIG') as f:
    data = json.load(f)
task = data.get('permission', {}).get('task', {})
for name, val in task.items():
    if val == 'allow':
        print(name)
" 2>/dev/null)

# Check all approved helpers are present
for helper in $approved_helpers; do
    if echo "$actual_helpers" | grep -q "^${helper}$"; then
        guard_pass "ARG-006-$helper" "$helper in permission.task"
    else
        guard_fail "ARG-006-$helper" "$helper missing from permission.task"
    fi
done

# Check no unapproved helpers
for helper in $actual_helpers; do
    if ! echo "$approved_helpers" | grep -q "^${helper}$"; then
        guard_fail "ARG-006-unapproved-$helper" "unapproved helper '$helper' in permission.task"
    fi
done

# ============================================================
# RESULTS
# ============================================================
echo ""
guard_report "$RESULT_FILE" "Agent Roster Guard (Post-C4)"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
