#!/bin/bash
# v4.17.0 Throughput, Token Efficiency & Global Runtime Consistency Conformance Test
# Purpose: Verify that v4.17.0 config files, scripts, and rules are present and valid
#
# Usage: bash .opencode/conformance/tests/v417-throughput-token-consistency.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/v417-throughput-token-consistency-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../guard-assert.sh" 2>/dev/null || {
  # Minimal guard-assert fallback
  PASS_COUNT=0
  FAIL_COUNT=0
  WARN_COUNT=0
  guard_pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "[PASS] $1"; }
  guard_fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); echo "[FAIL] $1 — $2"; }
  guard_warn() { WARN_COUNT=$((WARN_COUNT + 1)); echo "[WARN] $1 — $2"; }
  reset_guard_counters() { PASS_COUNT=0; FAIL_COUNT=0; WARN_COUNT=0; }
  guard_report() { echo ""; echo "Results: $PASS_COUNT PASS, $FAIL_COUNT FAIL, $WARN_COUNT WARN"; }
  load_drift_registry() { true; }
}

echo "=========================================="
echo "v4.17.0 Throughput, Token & Consistency Test"
echo "Date: $(date -Iseconds)"
echo "=========================================="

reset_guard_counters
load_drift_registry "$WORKSPACE_ROOT"

# ============================================================
# 1. CONFIG FILES EXIST AND ARE VALID YAML
# ============================================================
test_start "V417-001" "v4.17.0 config files exist"

CONFIG_DIR="$WORKSPACE_ROOT/.opencode/config"

for config_file in token-budget.yaml gate-matrix.yaml repo-profiles.yaml; do
  if [[ -f "$CONFIG_DIR/$config_file" ]]; then
    guard_pass "V417-001-$config_file" "$config_file exists"
    # Validate YAML syntax
    if ruby -e "require 'yaml'; YAML.load_file('$CONFIG_DIR/$config_file')" 2>/dev/null; then
      guard_pass "V417-001-yaml-$config_file" "$config_file is valid YAML"
    else
      guard_fail "V417-001-yaml-$config_file" "$config_file has invalid YAML syntax" "" "Fix YAML syntax"
    fi
  else
    guard_fail "V417-001-$config_file" "$config_file missing" "" "Create .opencode/config/$config_file"
  fi
done

# ============================================================
# 2. SCRIPTS EXIST AND ARE EXECUTABLE
# ============================================================
test_start "V417-002" "v4.17.0 scripts exist and are executable"

SCRIPTS_DIR="$WORKSPACE_ROOT/.opencode/scripts"

for script in session-cache.sh diff-analyze.sh deploy-readiness-report.sh; do
  if [[ -f "$SCRIPTS_DIR/$script" ]]; then
    guard_pass "V417-002-exists-$script" "$script exists"
    if [[ -x "$SCRIPTS_DIR/$script" ]]; then
      guard_pass "V417-002-exec-$script" "$script is executable"
    else
      guard_fail "V417-002-exec-$script" "$script is not executable" "" "Run: chmod +x .opencode/scripts/$script"
    fi
  else
    guard_fail "V417-002-$script" "$script missing" "" "Create .opencode/scripts/$script"
  fi
done

# ============================================================
# 3. SESSION CACHE FUNCTIONALITY
# ============================================================
test_start "V417-003" "session-cache.sh basic functionality"

# Test init
CACHE_OUTPUT=$(bash "$SCRIPTS_DIR/session-cache.sh" init "test-v417" 2>&1 || true)
if echo "$CACHE_OUTPUT" | grep -q "Session cache initialized"; then
  guard_pass "V417-003-init" "session-cache.sh init works"
else
  guard_fail "V417-003-init" "session-cache.sh init failed" "$CACHE_OUTPUT" "Check script"
fi

# Test summary
SUMMARY_OUTPUT=$(bash "$SCRIPTS_DIR/session-cache.sh" summary 2>&1 || true)
if echo "$SUMMARY_OUTPUT" | grep -q "Session Cache Summary"; then
  guard_pass "V417-003-summary" "session-cache.sh summary works"
else
  guard_fail "V417-003-summary" "session-cache.sh summary failed" "$SUMMARY_OUTPUT" "Check script"
fi

# Test gate-set and gate-get
SET_OUTPUT=$(bash "$SCRIPTS_DIR/session-cache.sh" gate-set "lint" "pass" 0 2>&1 || true)
GET_OUTPUT=$(bash "$SCRIPTS_DIR/session-cache.sh" gate-get "lint" 2>&1 || true)
if echo "$GET_OUTPUT" | grep -q "pass"; then
  guard_pass "V417-003-gate-cache" "session-cache.sh gate-set/get works"
else
  guard_fail "V417-003-gate-cache" "session-cache.sh gate-set/get failed" "$GET_OUTPUT" "Check script"
fi

# Clean up test cache
bash "$SCRIPTS_DIR/session-cache.sh" invalidate "conformance-test-cleanup" 2>/dev/null || true

# ============================================================
# 4. DIFF ANALYZE FUNCTIONALITY
# ============================================================
test_start "V417-004" "diff-analyze.sh basic functionality"

# Test in workspace root (should have some changes or report no_changes)
DIFF_OUTPUT=$(bash "$SCRIPTS_DIR/diff-analyze.sh" "$WORKSPACE_ROOT" 2>&1 || true)
if echo "$DIFF_OUTPUT" | grep -q "DIFF_CLASSIFICATION:"; then
  guard_pass "V417-004-classification" "diff-analyze.sh produces classification"
else
  guard_fail "V417-004-classification" "diff-analyze.sh failed to produce classification" "$DIFF_OUTPUT" "Check script"
fi

if echo "$DIFF_OUTPUT" | grep -q "RECOMMENDED_GATES:"; then
  guard_pass "V417-004-gates" "diff-analyze.sh produces gate recommendations"
else
  guard_fail "V417-004-gates" "diff-analyze.sh failed to produce gate recommendations" "" "Check script"
fi

# ============================================================
# 5. GATE MATRIX COVERS ALL TASK TYPES
# ============================================================
test_start "V417-005" "gate-matrix.yaml covers all required task types"

GATE_MATRIX="$CONFIG_DIR/gate-matrix.yaml"
REQUIRED_TASK_TYPES="copy_content_only css_ui_polish isolated_component shared_component_design_system data_model_logic auth_security_rls routing_navigation deployment_config_env large_cross_surface"

if [[ -f "$GATE_MATRIX" ]]; then
  for task_type in $REQUIRED_TASK_TYPES; do
    if grep -q "$task_type" "$GATE_MATRIX" 2>/dev/null; then
      guard_pass "V417-005-$task_type" "gate-matrix covers $task_type"
    else
      guard_fail "V417-005-$task_type" "gate-matrix missing $task_type" "" "Add $task_type to gate-matrix.yaml"
    fi
  done
else
  for task_type in $REQUIRED_TASK_TYPES; do
    guard_fail "V417-005-$task_type" "gate-matrix.yaml missing" "" "Create gate-matrix.yaml"
  done
fi

# ============================================================
# 6. TOKEN BUDGET COVERS ALL LANES
# ============================================================
test_start "V417-006" "token-budget.yaml covers all lanes"

TOKEN_BUDGET="$CONFIG_DIR/token-budget.yaml"
REQUIRED_LANES="DIRECT FAST STANDARD HIGH-RISK"

if [[ -f "$TOKEN_BUDGET" ]]; then
  for lane in $REQUIRED_LANES; do
    if grep -q "  $lane:" "$TOKEN_BUDGET" 2>/dev/null; then
      guard_pass "V417-006-$lane" "token-budget covers $lane"
    else
      guard_fail "V417-006-$lane" "token-budget missing $lane" "" "Add $lane to token-budget.yaml"
    fi
  done
else
  for lane in $REQUIRED_LANES; do
    guard_fail "V417-006-$lane" "token-budget.yaml missing" "" "Create token-budget.yaml"
  done
fi

# ============================================================
# 7. REPO PROFILES COVER ALL REPO TYPES
# ============================================================
test_start "V417-007" "repo-profiles.yaml covers all repo types"

REPO_PROFILES="$CONFIG_DIR/repo-profiles.yaml"
REQUIRED_REPO_TYPES="react_vite nextjs node_backend python rust docs_only protocol_repo unknown"

if [[ -f "$REPO_PROFILES" ]]; then
  for repo_type in $REQUIRED_REPO_TYPES; do
    if grep -q "  $repo_type:" "$REPO_PROFILES" 2>/dev/null; then
      guard_pass "V417-007-$repo_type" "repo-profiles covers $repo_type"
    else
      guard_fail "V417-007-$repo_type" "repo-profiles missing $repo_type" "" "Add $repo_type to repo-profiles.yaml"
    fi
  done
else
  for repo_type in $REQUIRED_REPO_TYPES; do
    guard_fail "V417-007-$repo_type" "repo-profiles.yaml missing" "" "Create repo-profiles.yaml"
  done
fi

# ============================================================
# 8. AUTHORITY HIERARCHY NOT VIOLATED
# ============================================================
test_start "V417-008" "v4.17.0 files are in workspace layer only"

# Config files must be in workspace, not global or repo-local
for config_file in token-budget.yaml gate-matrix.yaml repo-profiles.yaml; do
  GLOBAL_PATH="$HOME/.config/opencode/$config_file"
  if [[ -f "$GLOBAL_PATH" ]]; then
    guard_fail "V417-008-global-$config_file" "$config_file found in global (forbidden)" "" "Must be workspace only"
  else
    guard_pass "V417-008-global-$config_file" "$config_file not in global"
  fi
done

# Scripts must be in workspace scripts, not repo-local
for script in session-cache.sh diff-analyze.sh deploy-readiness-report.sh; do
  # Check no repo has these scripts locally
  REPO_SCRIPTS=$(find "$WORKSPACE_ROOT" -maxdepth 3 -path "*/.opencode/scripts/$script" 2>/dev/null | grep -v "$WORKSPACE_ROOT/.opencode/scripts/$script" || true)
  if [[ -z "$REPO_SCRIPTS" ]]; then
    guard_pass "V417-008-repo-$script" "$script not duplicated in any repo"
  else
    guard_fail "V417-008-repo-$script" "$script found in repo-local .opencode/" "$REPO_SCRIPTS" "Remove repo-local copy"
  fi
done

# ============================================================
# 9. BRAIN-CONFIG CONTEXT CACHE POLICY
# ============================================================
test_start "V417-009" "brain-config.json context_cache_policy status"

BRAIN_CONFIG="$WORKSPACE_ROOT/.opencode/brain-config.json"
if [[ -f "$BRAIN_CONFIG" ]]; then
  CACHE_ENABLED=$(python3 -c "
import json
with open('$BRAIN_CONFIG') as f:
    data = json.load(f)
policy = data.get('resource_guardrails', {}).get('context_cache_policy', {})
print(str(policy.get('enabled', 'missing')).lower())
" 2>/dev/null || echo "error")

  if [[ "$CACHE_ENABLED" == "true" ]]; then
    guard_pass "V417-009-cache-enabled" "context_cache_policy is enabled"
  elif [[ "$CACHE_ENABLED" == "false" ]]; then
    guard_warn "V417-009-cache-enabled" "context_cache_policy is still disabled" "" "Enable in brain-config.json for v4.17.0"
  else
    guard_fail "V417-009-cache-enabled" "context_cache_policy missing or error" "$CACHE_ENABLED" "Add context_cache_policy to brain-config.json"
  fi
else
  guard_fail "V417-009-brain-config" "brain-config.json missing" "" "Create brain-config.json"
fi

# ============================================================
# RESULTS
# ============================================================
echo ""
guard_report "$RESULT_FILE" "v4.17.0 Throughput, Token & Consistency"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
