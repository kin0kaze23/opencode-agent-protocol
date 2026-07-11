#!/bin/bash
# Guard 1: Effective Runtime Diff (Post-C4)
# Purpose: Verify workspace is self-contained behavioral authority.
# Mode: audit (PASS/WARN on known drift, FAIL on new drift)
#
# Usage: bash .opencode/conformance/tests/effective-runtime-diff.sh [--mode enforce]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/effective-runtime-diff-${TIMESTAMP}.md"

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
BRAIN_CONFIG="$WORKSPACE_ROOT/.opencode/brain-config.json"

echo "=========================================="
echo "Guard 1: Effective Runtime Diff (Post-C4)"
echo "Mode: $MODE"
echo "Date: $(date -Iseconds)"
echo "=========================================="

reset_guard_counters
load_drift_registry "$WORKSPACE_ROOT"

# ============================================================
# 1. DEFAULT AGENT
# ============================================================
test_start "ERD-001" "default_agent declared in workspace"

ws_default=$(json_value "$WORKSPACE_CONFIG" "default_agent")
if [ "$ws_default" = "orchestrator" ]; then
    guard_pass "ERD-001" "default_agent is orchestrator (workspace declares)"
else
    guard_fail "ERD-001" "default_agent unexpected" "orchestrator" "$ws_default"
fi

# ============================================================
# 2. DEFAULT MODEL
# ============================================================
test_start "ERD-002" "default model consistency"

workspace_model=$(json_value "$WORKSPACE_CONFIG" "model")
brain_model=$(json_value "$BRAIN_CONFIG" "default_model")

if [ "$workspace_model" = "$brain_model" ]; then
    guard_pass "ERD-002" "default model consistent (workspace matches brain-config)" "$workspace_model"
else
    guard_fail "ERD-002" "default model mismatch" "$brain_model" "$workspace_model"
fi

# ============================================================
# 3. SMALL MODEL
# ============================================================
test_start "ERD-003" "small_model consistency"

workspace_small=$(json_value "$WORKSPACE_CONFIG" "small_model")
brain_small=$(json_value "$BRAIN_CONFIG" "small_model")

if [ "$workspace_small" = "$brain_small" ]; then
    guard_pass "ERD-003" "small_model consistent (workspace matches brain-config)" "$workspace_small"
else
    guard_fail "ERD-003" "small_model mismatch" "$brain_small" "$workspace_small"
fi

# ============================================================
# 4. PROVIDER/MODEL AVAILABILITY
# ============================================================
test_start "ERD-004" "provider model definitions available in workspace"

if json_key_exists "$WORKSPACE_CONFIG" "provider.bailian-coding-plan"; then
    workspace_has_bailian="true"
else
    workspace_has_bailian="false"
fi

if [ "$workspace_has_bailian" = "false" ]; then
    guard_pass "ERD-004" "bailian-coding-plan provider removed from workspace (M3C)"
else
    guard_fail "ERD-004" "bailian-coding-plan provider still present in workspace"
fi

# Check provider section is empty (OpenCode Go uses built-in routing)
workspace_provider_empty=$(python3 -c "
import json
with open('$WORKSPACE_CONFIG') as f:
    data = json.load(f)
provider = data.get('provider', {})
print('true' if provider == {} else 'false')
" 2>/dev/null || echo "false")

if [ "$workspace_provider_empty" = "true" ]; then
    guard_pass "ERD-004b" "workspace provider section empty (OpenCode Go built-in routing)"
else
    guard_fail "ERD-004b" "workspace provider section not empty" "empty" "has keys"
fi

# ============================================================
# 5. AGENT AVAILABILITY
# ============================================================
test_start "ERD-005" "agent availability in workspace"

if json_key_exists "$WORKSPACE_CONFIG" "agent"; then
    workspace_has_agents="true"
else
    workspace_has_agents="false"
fi

if [ "$workspace_has_agents" = "true" ]; then
    guard_pass "ERD-005" "agents declared in workspace"
else
    guard_fail "ERD-005" "agents missing from workspace config"
fi

# Count agents in workspace
workspace_agent_count=$(python3 -c "
import json
with open('$WORKSPACE_CONFIG') as f:
    data = json.load(f)
agents = data.get('agent', {})
print(len(agents))
" 2>/dev/null || echo "0")

if [ "$workspace_agent_count" -ge 9 ]; then
    guard_pass "ERD-005b" "workspace has $workspace_agent_count agents (expected >=9)"
else
    guard_fail "ERD-005b" "agent count mismatch" ">=9" "$workspace_agent_count"
fi

# ============================================================
# 6. HELPER ROSTER
# ============================================================
test_start "ERD-006" "helper roster in permission.task"

for helper in explorer planner implementer reviewer architect budget; do
    ws_helper=$(json_value "$WORKSPACE_CONFIG" "permission.task.$helper")
    if [ "$ws_helper" = "allow" ]; then
        guard_pass "ERD-006-$helper" "permission.task.$helper = allow"
    else
        guard_fail "ERD-006-$helper" "permission.task.$helper unexpected" "allow" "$ws_helper"
    fi
done

# ============================================================
# 7. MCP SERVER STATE
# ============================================================
test_start "ERD-007" "MCP server state in workspace"

for mcp in context7 exa sequential-thinking github; do
    ws_enabled=$(json_value "$WORKSPACE_CONFIG" "mcp.$mcp.enabled")
    if [ "$ws_enabled" = "true" ]; then
        guard_pass "ERD-007-$mcp" "mcp.$mcp enabled in workspace" "enabled=true"
    else
        guard_fail "ERD-007-$mcp" "mcp.$mcp not enabled in workspace" "enabled=true" "enabled=$ws_enabled"
    fi
done

# MCP servers with intentional disabled state (baseline profile)
for mcp in playwright firecrawl; do
    ws_enabled=$(json_value "$WORKSPACE_CONFIG" "mcp.$mcp.enabled")
    if [ "$ws_enabled" = "false" ]; then
        guard_pass "ERD-007-$mcp" "mcp.$mcp disabled in workspace (baseline profile)" "enabled=false"
    else
        guard_fail "ERD-007-$mcp" "mcp.$mcp should be disabled (baseline profile)" "enabled=false" "enabled=$ws_enabled"
    fi
done

# Pencil: disabled in baseline profile
if json_key_exists "$WORKSPACE_CONFIG" "mcp.pencil"; then
    ws_pencil_enabled=$(json_value "$WORKSPACE_CONFIG" "mcp.pencil.enabled")
    if [ "$ws_pencil_enabled" = "false" ]; then
        guard_pass "ERD-007-pencil" "mcp.pencil disabled in workspace (baseline profile)"
    else
        guard_fail "ERD-007-pencil" "mcp.pencil should be disabled (baseline profile)" "enabled=false" "enabled=$ws_pencil_enabled"
    fi
else
    guard_pass "ERD-007-pencil" "mcp.pencil not in workspace (baseline profile disables)"
fi

# ============================================================
# 8. COMPACTION SETTINGS
# ============================================================
test_start "ERD-008" "compaction settings in workspace"

# Check reserved (schema-valid key, migrated from reservedTokens in C5)
ws_reserved=$(json_value "$WORKSPACE_CONFIG" "compaction.reserved")
if [ -n "$ws_reserved" ] && [ "$ws_reserved" != "null" ]; then
    guard_pass "ERD-008" "compaction.reserved present in workspace" "$ws_reserved"
else
    guard_fail "ERD-008" "compaction.reserved missing" "present" "missing"
fi

ws_auto=$(json_value "$WORKSPACE_CONFIG" "compaction.auto")
if [ "$ws_auto" = "true" ]; then
    guard_pass "ERD-008-auto" "compaction.auto is true" "$ws_auto"
else
    guard_fail "ERD-008-auto" "compaction.auto unexpected" "true" "$ws_auto"
fi

# prune is optional and can be true or false
ws_prune=$(json_value "$WORKSPACE_CONFIG" "compaction.prune")
if [ -n "$ws_prune" ] && [ "$ws_prune" != "null" ]; then
    guard_pass "ERD-008-prune" "compaction.prune present in workspace" "$ws_prune"
else
    guard_pass "ERD-008-prune" "compaction.prune not set (optional)"
fi

# ============================================================
# 9. RUNTIME SETTINGS
# ============================================================
test_start "ERD-009" "runtime settings in workspace"

for setting in autoupdate share snapshot; do
    ws_val=$(json_value "$WORKSPACE_CONFIG" "$setting")
    if [ "$ws_val" != "NULL" ]; then
        guard_pass "ERD-009-$setting" "$setting declared in workspace" "$ws_val"
    else
        guard_fail "ERD-009-$setting" "$setting not declared in workspace"
    fi
done

# watcher.ignore
if json_key_exists "$WORKSPACE_CONFIG" "watcher"; then
    guard_pass "ERD-009-watcher" "watcher declared in workspace"
else
    guard_fail "ERD-009-watcher" "watcher not declared in workspace"
fi

# lsp
if json_key_exists "$WORKSPACE_CONFIG" "lsp"; then
    guard_pass "ERD-009-lsp" "lsp declared in workspace"
else
    guard_fail "ERD-009-lsp" "lsp not declared in workspace"
fi

# ============================================================
# RESULTS
# ============================================================
echo ""
guard_report "$RESULT_FILE" "Effective Runtime Diff (Post-C4)"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
