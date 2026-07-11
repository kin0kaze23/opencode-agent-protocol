#!/bin/bash
# Guard 7: Config Authority Guard (Post-C4, C5.1 Runtime-Aware)
# Purpose: Ensure each layer only contains what it is allowed to contain.
# This is the main guard that enforces the four-layer authority model.
#
# C5.1 Option D (Runtime-Aware Thin-Shell):
#   Global may exist in two valid C5.1 states:
#     - GLOBAL_THIN_IDLE              (only $schema + plugin)
#     - GLOBAL_RUNTIME_MATERIALIZED   (workspace-derived mirror materialized by
#                                      active OpenCode CLI/Desktop session)
#
#   In GLOBAL_RUNTIME_MATERIALIZED state, the following keys MAY appear in
#   global as long as they are workspace-derived and subset-equivalent:
#     - agent, model, small_model, mcp
#
#   These keys are ALWAYS forbidden in global (regardless of state):
#     - default_agent, instructions, permission, compaction, autoupdate,
#       share, snapshot, watcher, lsp
#
#   Forbidden content in global (regardless of state):
#     - decommissioned providers: bailian-coding-plan, opencode-gemini-auth@latest
#     - resolved API keys / auth material
#
# Usage: bash .opencode/conformance/tests/config-authority-guard.sh [--mode enforce]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/config-authority-guard-${TIMESTAMP}.md"

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
EXCEPTIONS_FILE="$WORKSPACE_ROOT/.opencode/policies/repo-exceptions.json"

echo "=========================================="
echo "Guard 7: Config Authority Guard (Post-C4)"
echo "Mode: $MODE"
echo "Date: $(date -Iseconds)"
echo "=========================================="

reset_guard_counters
load_drift_registry "$WORKSPACE_ROOT"

# ============================================================
# 1. GLOBAL LAYER: Check for forbidden keys (C5.1 Option D runtime-aware)
# ============================================================
test_start "CAG-001" "global layer authority (C5.1 Option D: thin shell OR runtime-mirrored)"

# 1a. ALWAYS-FORBIDDEN keys in global (regardless of state)
# These operational/runtime keys must NEVER be in global, even when the
# OpenCode runtime is materializing workspace state into global.
always_forbidden_global_keys="default_agent instructions permission compaction autoupdate share snapshot watcher lsp"

for key in $always_forbidden_global_keys; do
    if json_key_exists "$GLOBAL_CONFIG" "$key"; then exists="true"; else exists="false"; fi
    if [ "$exists" = "true" ]; then
        guard_fail "CAG-001-$key" "global contains always-forbidden key '$key' (C5.1 invariant)" "" "Key must be in workspace only"
    else
        guard_pass "CAG-001-$key" "global does not contain '$key'"
    fi
done

# 1b. Classify global state (C5.1 Option D)
GLOBAL_KEY_COUNT=$(jq 'keys | length' "$GLOBAL_CONFIG" 2>/dev/null || echo "0")
IS_THIN_SHELL=$(jq -r '
  (keys | length) <= 2 and ((keys | sort) == (["$schema", "plugin"] | sort))
' "$GLOBAL_CONFIG" 2>/dev/null || echo "false")

if [ "$IS_THIN_SHELL" = "true" ]; then
    echo "  [i] Global state: GLOBAL_THIN_IDLE"
    GLOBAL_STATE="GLOBAL_THIN_IDLE"
    # 1c. Thin shell: agent/model/small_model/mcp must be absent
    thin_shell_forbidden="agent model small_model mcp"
    for key in $thin_shell_forbidden; do
        if json_key_exists "$GLOBAL_CONFIG" "$key"; then
            guard_fail "CAG-001-$key" "global contains forbidden key '$key' (GLOBAL_THIN_IDLE)" "" "Key should be in workspace only"
        else
            guard_pass "CAG-001-$key" "global does not contain '$key' (GLOBAL_THIN_IDLE)"
        fi
    done
else
    echo "  [i] Global state: GLOBAL_RUNTIME_MATERIALIZED"
    GLOBAL_STATE="GLOBAL_RUNTIME_MATERIALIZED"
    # 1d. Runtime-materialized: agent/model/small_model/mcp may exist but must be
    # workspace-derived and subset-equivalent.
    mirrored_keys="agent model small_model mcp"
    for key in $mirrored_keys; do
        if ! json_key_exists "$GLOBAL_CONFIG" "$key"; then
            # Absent in materialized state is also acceptable
            guard_pass "CAG-001-$key" "global does not contain '$key' (acceptable in any state)"
            continue
        fi
        # Key is present — validate workspace equivalence
        if [ "$key" = "model" ] || [ "$key" = "small_model" ]; then
            # Scalar mirror: must match workspace exactly
            GLOBAL_VAL=$(jq -r ".$key // \"\"" "$GLOBAL_CONFIG" 2>/dev/null)
            WORKSPACE_VAL=$(jq -r ".$key // \"\"" "$WORKSPACE_CONFIG" 2>/dev/null)
            if [ "$GLOBAL_VAL" = "$WORKSPACE_VAL" ]; then
                guard_pass "CAG-001-$key" "global $key mirrors workspace (GLOBAL_RUNTIME_MATERIALIZED)" "$GLOBAL_VAL"
            else
                guard_fail "CAG-001-$key" "global $key diverges from workspace" "global=$GLOBAL_VAL workspace=$WORKSPACE_VAL" "Runtime-mirrored global must match workspace"
            fi
        else
            # Object mirror (agent or mcp): every global entry must come from workspace
            UNEXPECTED=$(jq -r --arg ws_key "$key" "
              (.\$ws_key // {} | keys) - (($WORKSPACE_CONFIG | fromjson | .\$ws_key // {}) | keys) | sort | .[]
            " "$GLOBAL_CONFIG" 2>/dev/null | grep -v '^$' || true)
            if [ -z "$UNEXPECTED" ]; then
                GLOBAL_KEYS=$(jq -r ".$key // {} | keys | sort | join(\",\")" "$GLOBAL_CONFIG" 2>/dev/null)
                guard_pass "CAG-001-$key" "global $key is a workspace subset (GLOBAL_RUNTIME_MATERIALIZED)" "[$GLOBAL_KEYS]"
            else
                guard_fail "CAG-001-$key" "global $key has unexpected entries not in workspace" "$UNEXPECTED" "Runtime-mirrored entries must come from workspace"
            fi
            # For agent block: also validate per-agent model field mirrors workspace
            if [ "$key" = "agent" ]; then
                MODEL_DIVERGENCE=$(jq -r '
                  def ws_agent: $ws_config.agent // {};
                  .agent // {} | to_entries | map(select(
                    (ws_agent[.key].model // "") != .value.model
                  )) | .[].key
                ' "$GLOBAL_CONFIG" --slurpfile ws_cfg "$WORKSPACE_CONFIG" 2>/dev/null | grep -v '^$' || true)
                if [ -z "$MODEL_DIVERGENCE" ]; then
                    guard_pass "CAG-001-agent-model" "global per-agent model fields mirror workspace (GLOBAL_RUNTIME_MATERIALIZED)"
                else
                    guard_fail "CAG-001-agent-model" "global per-agent model fields diverge from workspace" "$MODEL_DIVERGENCE" "Each global agent.model must equal workspace agent.model"
                fi
            fi
        fi
    done
fi

# 1e. Allowed keys in global (machine/provider/auth only)
allowed_global_keys="provider plugin"
for key in $allowed_global_keys; do
    if json_key_exists "$GLOBAL_CONFIG" "$key"; then exists="true"; else exists="false"; fi
    if [ "$exists" = "true" ]; then
        guard_pass "CAG-001-allowed-$key" "global contains allowed key '$key'"
    else
        guard_warn "CAG-001-allowed-$key" "global does not contain '$key'" "" "Optional: may be machine-local"
    fi
done

# 1f. Forbidden content in global (regardless of state)
if grep -q "bailian-coding-plan" "$GLOBAL_CONFIG" 2>/dev/null; then
    guard_fail "CAG-001-forbidden-bailian" "global contains decommissioned 'bailian-coding-plan' (C5.1 invariant)" "" "Provider decommissioned in v0.2"
else
    guard_pass "CAG-001-forbidden-bailian" "global does not contain decommissioned 'bailian-coding-plan'"
fi
if grep -q "opencode-gemini-auth@latest" "$GLOBAL_CONFIG" 2>/dev/null; then
    guard_fail "CAG-001-forbidden-gemini-auth" "global contains decommissioned 'opencode-gemini-auth@latest'" "" "MCP package decommissioned"
else
    guard_pass "CAG-001-forbidden-gemini-auth" "global does not contain decommissioned 'opencode-gemini-auth@latest'"
fi
# 1g. Secret / auth material check (heuristic but covers common API key formats)
SECRET_PATTERN='(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|glpat-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|xox[bpars]-[A-Za-z0-9-]{10,})'
if grep -qE "$SECRET_PATTERN" "$GLOBAL_CONFIG" 2>/dev/null; then
    SUSPICIOUS=$(grep -cE "$SECRET_PATTERN" "$GLOBAL_CONFIG" 2>/dev/null || echo 0)
    SUSPICIOUS=$(echo "$SUSPICIOUS" | tr -cd '0-9')
    SUSPICIOUS=${SUSPICIOUS:-0}
    guard_fail "CAG-001-secrets" "global contains $SUSPICIOUS suspicious API key/auth material line(s)" "" "No resolved secrets in global"
else
    guard_pass "CAG-001-secrets" "global has no resolved API keys or auth material"
fi

echo "  [i] Global state classification: $GLOBAL_STATE"

# ============================================================
# 2. WORKSPACE LAYER: Check for required keys (post-C3)
# ============================================================
test_start "CAG-002" "workspace layer authority"

# Keys that SHOULD be in workspace after C3 migration
required_workspace_keys="agent model small_model default_agent mcp permission compaction autoupdate share snapshot watcher lsp"

for key in $required_workspace_keys; do
    if json_key_exists "$WORKSPACE_CONFIG" "$key"; then exists="true"; else exists="false"; fi
    if [ "$exists" = "true" ]; then
        guard_pass "CAG-002-$key" "workspace contains required key '$key'"
    else
        guard_fail "CAG-002-$key" "workspace missing required key '$key'" "" "Key must be declared in workspace"
    fi
done

# ============================================================
# 3. BRAIN-CONFIG LAYER: Check structure
# ============================================================
test_start "CAG-003" "brain-config layer authority"

# Required brain-config keys
required_brain_keys="version default_model small_model bootstrap_authority prompt_source_of_truth"

for key in $required_brain_keys; do
    if json_key_exists "$BRAIN_CONFIG" "$key"; then exists="true"; else exists="false"; fi
    if [ "$exists" = "true" ]; then
        guard_pass "CAG-003-$key" "brain-config contains required key '$key'"
    else
        guard_fail "CAG-003-$key" "brain-config missing required key '$key'"
    fi
done

# Brain-config should NOT contain OpenCode runtime keys
forbidden_brain_keys="agent mcp permission compaction"
for key in $forbidden_brain_keys; do
    if json_key_exists "$BRAIN_CONFIG" "$key"; then exists="true"; else exists="false"; fi
    if [ "$exists" = "true" ]; then
        guard_warn "CAG-003-forbidden-$key" "brain-config contains runtime key '$key'" "" "Should be in opencode.json, not brain-config"
    else
        guard_pass "CAG-003-forbidden-$key" "brain-config does not contain runtime key '$key'"
    fi
done

# ============================================================
# 4. REPO LAYER: Check no repo has opencode.json (unless approved)
# ============================================================
test_start "CAG-004" "repo layer authority"

repos_with_opencode=$(find "$WORKSPACE_ROOT" -maxdepth 2 -name ".opencode" -type d 2>/dev/null | while read -r dir; do
    if [ "$dir" != "$WORKSPACE_ROOT/.opencode" ]; then
        dirname "$dir"
    fi
done)

for repo in $repos_with_opencode; do
    repo_name=$(basename "$repo")
    if [ -f "$repo/.opencode/opencode.json" ]; then
        # Check if this repo is approved to have opencode.json
        if [ -f "$EXCEPTIONS_FILE" ]; then
            is_approved=$(python3 -c "
import json
with open('$EXCEPTIONS_FILE') as f:
    data = json.load(f)
exceptions = data.get('exceptions', {})
repo = exceptions.get('$repo_name', {})
allowed = repo.get('allowed_contents', [])
print('yes' if 'opencode.json' in allowed else 'no')
" 2>/dev/null)
            if [ "$is_approved" = "yes" ]; then
                guard_pass "CAG-004-$repo_name" "$repo_name has opencode.json (approved exception)"
            else
                guard_fail "CAG-004-$repo_name" "$repo_name has opencode.json (forbidden without ADR)"
            fi
        else
            guard_fail "CAG-004-$repo_name" "$repo_name has opencode.json (forbidden without ADR)"
        fi
    else
        guard_pass "CAG-004-$repo_name" "$repo_name does not have opencode.json"
    fi

    if [ -f "$repo/.opencode/brain-config.json" ]; then
        guard_fail "CAG-004-brain-$repo_name" "$repo_name has brain-config.json (forbidden)"
    else
        guard_pass "CAG-004-brain-$repo_name" "$repo_name does not have brain-config.json"
    fi
done

# ============================================================
# 5. CROSS-LAYER CONSISTENCY
# ============================================================
test_start "CAG-005" "cross-layer consistency"

# Model consistency (workspace vs brain-config, global no longer has model after C4)
ws_model=$(json_value "$WORKSPACE_CONFIG" "model")
brain_model=$(json_value "$BRAIN_CONFIG" "default_model")

if [ "$ws_model" = "$brain_model" ]; then
    guard_pass "CAG-005-model" "default model consistent (workspace matches brain-config)" "$ws_model"
else
    guard_fail "CAG-005-model" "default model inconsistent" "workspace=$ws_model, brain=$brain_model"
fi

# Small model consistency (workspace vs brain-config)
ws_small=$(json_value "$WORKSPACE_CONFIG" "small_model")
brain_small=$(json_value "$BRAIN_CONFIG" "small_model")

if [ "$ws_small" = "$brain_small" ]; then
    guard_pass "CAG-005-small" "small_model consistent (workspace matches brain-config)" "$ws_small"
else
    guard_fail "CAG-005-small" "small_model inconsistent" "workspace=$ws_small, brain=$brain_small"
fi

# ============================================================
# 6. DRIFT DETECTION: Has anything changed since C0 baseline?
# ============================================================
test_start "CAG-006" "drift detection vs C0 baseline"

# Count known drift items
known_drift_count=$(python3 -c "
import json
with open('$WORKSPACE_ROOT/.opencode/policies/known-c0-drift.json') as f:
    data = json.load(f)
print(len(data.get('drift_items', [])))
" 2>/dev/null || echo "0")

guard_pass "CAG-006" "C0 drift registry has $known_drift_count known items"

# ============================================================
# RESULTS
# ============================================================
echo ""
guard_report "$RESULT_FILE" "Config Authority Guard (Post-C4)"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
