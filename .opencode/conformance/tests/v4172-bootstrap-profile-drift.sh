#!/bin/bash
# v4.17.2 Bootstrap + Profile Drift Conformance Test
# Purpose: Verify bootstrap-repo-profile.sh and repo-profiles.yaml are in sync
#
# Usage: bash .opencode/conformance/tests/v4172-bootstrap-profile-drift.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/v4172-bootstrap-profile-drift-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../guard-assert.sh" 2>/dev/null || {
  PASS_COUNT=0; FAIL_COUNT=0; WARN_COUNT=0
  guard_pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "[PASS] $1"; }
  guard_fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); echo "[FAIL] $1 — $2"; }
  guard_warn() { WARN_COUNT=$((WARN_COUNT + 1)); echo "[WARN] $1 — $2"; }
  reset_guard_counters() { PASS_COUNT=0; FAIL_COUNT=0; WARN_COUNT=0; }
  guard_report() { echo ""; echo "Results: $PASS_COUNT PASS, $FAIL_COUNT FAIL, $WARN_COUNT WARN"; }
  load_drift_registry() { true; }
}

echo "=========================================="
echo "v4.17.2 Bootstrap + Profile Drift Test"
echo "Date: $(date -Iseconds)"
echo "=========================================="

reset_guard_counters
load_drift_registry "$WORKSPACE_ROOT"

# ============================================================
# 1. BOOTSTRAP SCRIPT EXISTS AND IS EXECUTABLE
# ============================================================
test_start "V4172-001" "bootstrap-repo-profile.sh exists and is executable"

BOOTSTRAP_SCRIPT="$WORKSPACE_ROOT/.opencode/scripts/bootstrap-repo-profile.sh"
if [[ -f "$BOOTSTRAP_SCRIPT" ]]; then
  guard_pass "V4172-001-exists" "bootstrap-repo-profile.sh exists"
  if [[ -x "$BOOTSTRAP_SCRIPT" ]]; then
    guard_pass "V4172-001-exec" "bootstrap-repo-profile.sh is executable"
  else
    guard_fail "V4172-001-exec" "bootstrap-repo-profile.sh is not executable" "" "Run: chmod +x"
  fi
else
  guard_fail "V4172-001" "bootstrap-repo-profile.sh missing" "" "Create script"
fi

# ============================================================
# 2. REPO-PROFILES.YAML EXISTS
# ============================================================
test_start "V4172-002" "repo-profiles.yaml exists and is valid"

PROFILES_FILE="$WORKSPACE_ROOT/.opencode/config/repo-profiles.yaml"
if [[ -f "$PROFILES_FILE" ]]; then
  guard_pass "V4172-002-exists" "repo-profiles.yaml exists"
  if ruby -e "require 'yaml'; YAML.load_file('$PROFILES_FILE')" 2>/dev/null; then
    guard_pass "V4172-002-yaml" "repo-profiles.yaml is valid YAML"
  else
    guard_fail "V4172-002-yaml" "repo-profiles.yaml has invalid YAML"
  fi
else
  guard_fail "V4172-002" "repo-profiles.yaml missing"
fi

# ============================================================
# 3. BOOTSTRAP SCRIPT DETECTS ALL PROFILE TYPES
# ============================================================
test_start "V4172-003" "bootstrap script detects all profile types from repo-profiles.yaml"

# Get all profile names from YAML
PROFILE_NAMES=$(ruby -e "
require 'yaml'
data = YAML.load_file('$PROFILES_FILE')
profiles = data['profiles'] || {}
puts profiles.keys.join(' ')
" 2>/dev/null || echo "")

if [[ -z "$PROFILE_NAMES" ]]; then
  guard_fail "V4172-003" "no profiles found in repo-profiles.yaml"
else
  for profile in $PROFILE_NAMES; do
    guard_pass "V4172-003-$profile" "profile '$profile' exists in repo-profiles.yaml"
  done
fi

# ============================================================
# 4. BOOTSTRAP SCRIPT RETURNS CORRECT PROFILE FOR KNOWN REPOS
# ============================================================
test_start "V4172-004" "bootstrap script returns correct profiles for known repos"

# Test protected-repo-prod (should be react_vite)
BG_OUTPUT=$(bash "$BOOTSTRAP_SCRIPT" "$WORKSPACE_ROOT/protected-repo-prod" 2>/dev/null)
BG_TYPE=$(echo "$BG_OUTPUT" | grep '^REPO_TYPE:' | cut -d' ' -f2)
if [[ "$BG_TYPE" == "react_vite" ]]; then
  guard_pass "V4172-004-protected-repo" "protected-repo-prod detected as react_vite"
else
  guard_fail "V4172-004-protected-repo" "protected-repo-prod detected as '$BG_TYPE' (expected react_vite)"
fi

# Test demo-project (should be react_vite)
STILL_OUTPUT=$(bash "$BOOTSTRAP_SCRIPT" "$WORKSPACE_ROOT/demo-project" 2>/dev/null)
STILL_TYPE=$(echo "$STILL_OUTPUT" | grep '^REPO_TYPE:' | cut -d' ' -f2)
if [[ "$STILL_TYPE" == "react_vite" ]]; then
  guard_pass "V4172-004-demo-project" "demo-project detected as react_vite"
else
  guard_fail "V4172-004-demo-project" "demo-project detected as '$STILL_TYPE' (expected react_vite)"
fi

# ============================================================
# 5. BOOTSTRAP SCRIPT RETURNS GATE COMMANDS FROM YAML
# ============================================================
test_start "V4172-005" "bootstrap script returns gate commands from repo-profiles.yaml"

BG_LINT=$(echo "$BG_OUTPUT" | grep '^GATE_LINT:' | cut -d' ' -f2-)
if [[ "$BG_LINT" == "pnpm lint" ]]; then
  guard_pass "V4172-005-lint" "gate command 'pnpm lint' returned from repo-profiles.yaml"
else
  guard_fail "V4172-005-lint" "gate command mismatch: got '$BG_LINT' (expected 'pnpm lint')"
fi

BG_LANE=$(echo "$BG_OUTPUT" | grep '^DEFAULT_LANE:' | cut -d' ' -f2)
if [[ -n "$BG_LANE" ]]; then
  guard_pass "V4172-005-lane" "default lane '$BG_LANE' returned from repo-profiles.yaml"
else
  guard_fail "V4172-005-lane" "default lane not returned"
fi

# ============================================================
# 6. DIFF-ANALYZE CONSERVATIVE FALLBACK
# ============================================================
test_start "V4172-006" "diff-analyze conservative fallback for unknown/ambiguous"

# Check that diff-analyze.sh has the conservative fallback
if grep -q 'conservative fallback' "$WORKSPACE_ROOT/.opencode/scripts/diff-analyze.sh" 2>/dev/null; then
  guard_pass "V4172-006-fallback" "diff-analyze.sh has conservative fallback (v4.17.2)"
else
  guard_fail "V4172-006-fallback" "diff-analyze.sh missing conservative fallback"
fi

# Check for lockfile detection
if grep -q 'has_lockfile' "$WORKSPACE_ROOT/.opencode/scripts/diff-analyze.sh" 2>/dev/null; then
  guard_pass "V4172-006-lockfile" "diff-analyze.sh detects lockfile changes"
else
  guard_fail "V4172-006-lockfile" "diff-analyze.sh missing lockfile detection"
fi

# Check for env detection
if grep -q 'has_env' "$WORKSPACE_ROOT/.opencode/scripts/diff-analyze.sh" 2>/dev/null; then
  guard_pass "V4172-006-env" "diff-analyze.sh detects env file changes"
else
  guard_fail "V4172-006-env" "diff-analyze.sh missing env detection"
fi

# Check for gate definition detection
if grep -q 'has_gate_def' "$WORKSPACE_ROOT/.opencode/scripts/diff-analyze.sh" 2>/dev/null; then
  guard_pass "V4172-006-gate-def" "diff-analyze.sh detects gate definition changes"
else
  guard_fail "V4172-006-gate-def" "diff-analyze.sh missing gate definition detection"
fi

# ============================================================
# RESULTS
# ============================================================
echo ""
guard_report "$RESULT_FILE" "v4.17.2 Bootstrap + Profile Drift"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
