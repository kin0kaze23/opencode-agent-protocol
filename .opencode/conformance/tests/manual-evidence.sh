#!/usr/bin/env bash
# manual-evidence.sh — v4.41 Manual Branch Protection Evidence Conformance Tests
#
# Tests for branch-protection-evidence.yaml, verify-manual-branch-protection-evidence.sh,
# and dashboard integration.
#
# Usage: bash .opencode/conformance/tests/manual-evidence.sh

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

reset_counters

echo "=== v4.41 Manual Branch Protection Evidence Conformance Tests ==="
echo ""

# ─── ME-001: evidence config exists ────────────────────────────────────
test_start "ME-001" "evidence config exists"
assert_file_exists "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "Evidence config exists"

# ─── ME-002: evidence validator exists ──────────────────────────────────
test_start "ME-002" "evidence validator exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "Evidence validator exists"

# ─── ME-003: evidence config includes sample-service ────────────────────
test_start "ME-003" "evidence config includes sample-service"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "sample-service" "Evidence config includes sample-service"

# ─── ME-004: evidence config includes demo-project ────────────────────────
test_start "ME-004" "evidence config includes demo-project"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "demo-project" "Evidence config includes demo-project"

# ─── ME-005: evidence config has evidence_status field ──────────────────
test_start "ME-005" "evidence config has evidence_status field"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "evidence_status" "Config has evidence_status field"

# ─── ME-006: evidence config has release_gate_required field ────────────
test_start "ME-006" "evidence config has release_gate_required field"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "release_gate_required" "Config has release_gate_required field"

# ─── ME-007: evidence config has codeowners_review_required field ───────
test_start "ME-007" "evidence config has codeowners_review_required field"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "codeowners_review_required" "Config has codeowners_review_required field"

# ─── ME-008: evidence config has stale_approvals_dismissed field ────────
test_start "ME-008" "evidence config has stale_approvals_dismissed field"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "stale_approvals_dismissed" "Config has stale_approvals_dismissed field"

# ─── ME-009: evidence config has force_pushes_blocked field ────────────
test_start "ME-009" "evidence config has force_pushes_blocked field"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "force_pushes_blocked" "Config has force_pushes_blocked field"

# ─── ME-010: evidence config has direct_push_restricted field ──────────
test_start "ME-010" "evidence config has direct_push_restricted field"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "direct_push_restricted" "Config has direct_push_restricted field"

# ─── ME-011: evidence config has admin_bypass_disabled field ───────────
test_start "ME-011" "evidence config has admin_bypass_disabled field"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "admin_bypass_disabled" "Config has admin_bypass_disabled field"

# ─── ME-012: evidence config has deploy_preview_required for demo-project ─
test_start "ME-012" "evidence config has deploy_preview_required"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "deploy_preview_required" "Config has deploy_preview_required field"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "VERCEL_TOKEN" "Config references VERCEL_TOKEN constraint"

# ─── ME-013: evidence validator has --strict flag ──────────────────────
test_start "ME-013" "evidence validator has --strict flag"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "--strict" "Validator has --strict flag"

# ─── ME-014: evidence validator checks staleness ───────────────────────
test_start "ME-014" "evidence validator checks staleness"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "stale" "Validator checks for stale evidence"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "EXPIRY_DAYS" "Validator has expiry threshold"

# ─── ME-015: evidence validator classifies no_evidence ─────────────────
test_start "ME-015" "evidence validator classifies no_evidence"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "no_evidence" "Validator has no_evidence classification"

# ─── ME-016: evidence validator classifies manually_verified ───────────
test_start "ME-016" "evidence validator classifies manually_verified"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "manually_verified" "Validator has manually_verified classification"

# ─── ME-017: evidence validator classifies inconsistent_evidence ───────
test_start "ME-017" "evidence validator classifies inconsistent_evidence"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "inconsistent_evidence" "Validator has inconsistent_evidence classification"

# ─── ME-018: evidence validator classifies stale_evidence ──────────────
test_start "ME-018" "evidence validator classifies stale_evidence"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "stale_evidence" "Validator has stale_evidence classification"

# ─── ME-019: evidence validator checks Release Gate required ───────────
test_start "ME-019" "evidence validator checks Release Gate required"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "Release Gate required" "Validator checks Release Gate required"

# ─── ME-020: evidence validator checks demo-project deploy-preview ────────
test_start "ME-020" "evidence validator checks demo-project deploy-preview"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "deploy-preview" "Validator checks demo-project deploy-preview"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "VERCEL_TOKEN" "Validator references VERCEL_TOKEN"

# ─── ME-021: dashboard includes manual evidence field ───────────────────
test_start "ME-021" "dashboard includes manual evidence field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "Manual Evidence" "Dashboard includes manual evidence field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "MANUAL_EVIDENCE_STATUS" "Dashboard uses MANUAL_EVIDENCE_STATUS variable"

# ─── ME-022: dashboard includes manually_verified count ────────────────
test_start "ME-022" "dashboard includes manually_verified count"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "Manually Verified" "Dashboard has Manually Verified in executive summary"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "MANUALLY_VERIFIED" "Dashboard uses MANUALLY_VERIFIED counter"

# ─── ME-023: dashboard has manually_verified classification ─────────────
test_start "ME-023" "dashboard has manually_verified classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "manually_verified" "Dashboard has manually_verified classification"

# ─── ME-024: dashboard does not count manually_verified as protected ────
test_start "ME-024" "manually_verified is not protected"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "manually_verified is separate from protected" "Dashboard documents separation"

# ─── ME-025: snapshot tracks manually_verified ─────────────────────────
test_start "ME-025" "snapshot tracks manually_verified"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-fleet-snapshot.sh" "manually_verified" "Snapshot tracks manually_verified"

# ─── ME-026: evidence config has recorded_by field ─────────────────────
test_start "ME-026" "evidence config has recorded_by field"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "recorded_by" "Config has recorded_by field"

# ─── ME-027: evidence config has recorded_at field ─────────────────────
test_start "ME-027" "evidence config has recorded_at field"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "recorded_at" "Config has recorded_at field"

# ─── ME-028: evidence config has evidence_source field ─────────────────
test_start "ME-028" "evidence config has evidence_source field"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "evidence_source" "Config has evidence_source field"

# ─── ME-029: evidence config has evidence_notes field ───────────────────
test_start "ME-029" "evidence config has evidence_notes field"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "evidence_notes" "Config has evidence_notes field"

# ─── ME-030: evidence config has approving_reviews_required field ───────
test_start "ME-030" "evidence config has approving_reviews_required field"
assert_file_contains "$ROOT_DIR/.opencode/config/branch-protection-evidence.yaml" "approving_reviews_required" "Config has approving_reviews_required field"

# ─── Summary ────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo -e "${GREEN}PASSED: $TESTS_PASSED${NC}"
echo -e "${RED}FAILED: $TESTS_FAILED${NC}"
echo "=========================================="

if [ "$TESTS_FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
