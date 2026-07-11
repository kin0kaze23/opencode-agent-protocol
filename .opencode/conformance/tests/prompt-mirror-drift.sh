#!/bin/bash
# Guard 5: Prompt Mirror Drift
# Purpose: Ensure prompt checksums match across global, workspace, and installed copies.
#
# Usage: bash .opencode/conformance/tests/prompt-mirror-drift.sh [--mode enforce]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/prompt-mirror-drift-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../guard-assert.sh"

# Parse mode
MODE="audit"
for arg in "$@"; do
    case "$arg" in
        --mode) shift; MODE="$1" ;;
    esac
done

# Prompt paths
GLOBAL_PROMPTS="$HOME/.config/opencode/prompts"
WORKSPACE_PROMPTS="$WORKSPACE_ROOT/.opencode/global-runtime/prompts"
AGENT_DIR="$WORKSPACE_ROOT/.opencode/agents"

echo "=========================================="
echo "Guard 5: Prompt Mirror Drift"
echo "Mode: $MODE"
echo "Date: $(date -Iseconds)"
echo "=========================================="

reset_guard_counters
load_drift_registry "$WORKSPACE_ROOT"

# Agent list
agents="orchestrator explorer planner implementer reviewer architect budget"

# Map agent name to known C0-DRIFT id for pending v0.2 prompt drift.
# The same composite entry covers both PMD-002 (global-vs-workspace) and
# PMD-003 (workspace-vs-baseline) because both checks fail on the same
# underlying pending v0.2 prompt candidate work from different angles.
# When a new prompt drift is registered, add the agent-to-id mapping here.
get_pmd_drift_id() {
    local agent="$1"
    case "$agent" in
        orchestrator) echo "C0-DRIFT-021" ;;
        explorer)     echo "C0-DRIFT-022" ;;
        planner)      echo "C0-DRIFT-023" ;;
        implementer)  echo "C0-DRIFT-024" ;;
        reviewer)     echo "C0-DRIFT-027" ;;
        architect)    echo "C0-DRIFT-025" ;;
        budget)       echo "C0-DRIFT-026" ;;
        *)            echo "" ;;
    esac
}

# ============================================================
# 1. ALL PROMPT FILES EXIST IN ALL LOCATIONS
# ============================================================
test_start "PMD-001" "prompt file existence"

for agent in $agents; do
    global_path="$GLOBAL_PROMPTS/${agent}.md"
    ws_path="$WORKSPACE_PROMPTS/${agent}.md"
    source_path="$AGENT_DIR/${agent}.md"

    # Global
    if [ -f "$global_path" ]; then
        guard_pass "PMD-001-global-$agent" "${agent}.md exists in global prompts"
    else
        guard_fail "PMD-001-global-$agent" "${agent}.md missing from global prompts" "" "$global_path"
    fi

    # Workspace
    if [ -f "$ws_path" ]; then
        guard_pass "PMD-001-ws-$agent" "${agent}.md exists in workspace prompts"
    else
        guard_fail "PMD-001-ws-$agent" "${agent}.md missing from workspace prompts" "" "$ws_path"
    fi

    # Source (orchestrator is manual-canonical, no agents/ source file)
    if [ "$agent" = "orchestrator" ]; then
        guard_skip "PMD-001-source-$agent" "orchestrator is manual-canonical (no agents/ source)" "Intentional: orchestrator prompt is workspace-specific policy"
    elif [ -f "$source_path" ]; then
        guard_pass "PMD-001-source-$agent" "${agent}.md exists in agents source"
    else
        guard_warn "PMD-001-source-$agent" "${agent}.md missing from agents source" "" "$source_path (may be generated)"
    fi
done

# ============================================================
# 2. CHECKSUM MATCH: GLOBAL vs WORKSPACE
# ============================================================
test_start "PMD-002" "prompt checksum match: global vs workspace"

for agent in $agents; do
    global_path="$GLOBAL_PROMPTS/${agent}.md"
    ws_path="$WORKSPACE_PROMPTS/${agent}.md"

    if [ ! -f "$global_path" ] || [ ! -f "$ws_path" ]; then
        guard_skip "PMD-002-$agent" "cannot compare (file missing)"
        continue
    fi

    global_md5=$(md5sum "$global_path" | awk '{print $1}')
    ws_md5=$(md5sum "$ws_path" | awk '{print $1}')

    if [ "$global_md5" = "$ws_md5" ]; then
        guard_pass "PMD-002-$agent" "${agent}.md checksums match" "$global_md5"
    else
        # Pending v0.2 prompt drift may be registered as known drift.
        # PMD-002 and PMD-003 consult the SAME composite entry because
        # both checks fail on the same underlying pending v0.2 work:
        # PMD-002 sees global-vs-workspace, PMD-003 sees workspace-vs-baseline.
        # Follows the same pattern as mcp-policy-guard.sh.
        drift_id="$(get_pmd_drift_id "$agent")"
        if [ -n "$drift_id" ] && is_known_drift "$drift_id"; then
            guard_warn "PMD-002-$agent" "${agent}.md checksum mismatch (registered)" "$drift_id" "global=$global_md5, workspace=$ws_md5"
        else
            guard_fail "PMD-002-$agent" "${agent}.md checksum mismatch" "" "global=$global_md5, workspace=$ws_md5"
        fi
    fi
done

# ============================================================
# 3. BASELINE CHECKSUM RECORD
# ============================================================
test_start "PMD-003" "baseline checksum record"

baseline_file="$WORKSPACE_ROOT/.opencode/policies/prompt-baseline.json"

if [ -f "$baseline_file" ]; then
    # Compare current checksums against baseline
    for agent in $agents; do
        ws_path="$WORKSPACE_PROMPTS/${agent}.md"
        if [ ! -f "$ws_path" ]; then
            continue
        fi

        current_md5=$(md5sum "$ws_path" | awk '{print $1}')
        baseline_md5=$(python3 -c "
import json
with open('$baseline_file') as f:
    data = json.load(f)
print(data.get('$agent', 'not_found'))
" 2>/dev/null || echo "not_found")

        if [ "$baseline_md5" = "not_found" ]; then
            guard_warn "PMD-003-$agent" "${agent}.md not in baseline" "" "Current: $current_md5"
        elif [ "$current_md5" = "$baseline_md5" ]; then
            guard_pass "PMD-003-$agent" "${agent}.md matches baseline" "$current_md5"
        else
            # Pending v0.2 prompt drift may be registered as known drift.
            # PMD-002 and PMD-003 consult the SAME composite entry because
            # both checks fail on the same underlying pending v0.2 work:
            # PMD-002 sees global-vs-workspace, PMD-003 sees workspace-vs-baseline.
            # Follows the same pattern as mcp-policy-guard.sh.
            drift_id="$(get_pmd_drift_id "$agent")"
            if [ -n "$drift_id" ] && is_known_drift "$drift_id"; then
                guard_warn "PMD-003-$agent" "${agent}.md drifted from baseline (registered)" "$drift_id" "baseline=$baseline_md5, current=$current_md5"
            else
                guard_fail "PMD-003-$agent" "${agent}.md drifted from baseline" "" "baseline=$baseline_md5, current=$current_md5"
            fi
        fi
    done
else
    guard_warn "PMD-003" "no baseline file found" "" "Will create baseline on first successful run"

    # Create baseline
    python3 -c "
import json, hashlib, os
baseline = {}
agents = ['orchestrator', 'explorer', 'planner', 'implementer', 'reviewer', 'architect', 'budget']
ws_dir = '$WORKSPACE_PROMPTS'
for agent in agents:
    path = os.path.join(ws_dir, f'{agent}.md')
    if os.path.exists(path):
        with open(path, 'rb') as f:
            baseline[agent] = hashlib.md5(f.read()).hexdigest()
with open('$baseline_file', 'w') as f:
    json.dump(baseline, f, indent=2)
print('Baseline created with', len(baseline), 'entries')
" 2>/dev/null
fi

# ============================================================
# 4. PROMPT FILE SIZES (sanity check)
# ============================================================
test_start "PMD-004" "prompt file sizes (sanity)"

for agent in $agents; do
    ws_path="$WORKSPACE_PROMPTS/${agent}.md"
    if [ -f "$ws_path" ]; then
        size=$(wc -c < "$ws_path")
        lines=$(wc -l < "$ws_path")
        if [ "$size" -gt 100 ]; then
            guard_pass "PMD-004-$agent" "${agent}.md has content" "${size} bytes, ${lines} lines"
        else
            guard_warn "PMD-004-$agent" "${agent}.md seems too small" "" "${size} bytes, ${lines} lines"
        fi
    fi
done

# ============================================================
# RESULTS
# ============================================================
echo ""
guard_report "$RESULT_FILE" "Prompt Mirror Drift"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
