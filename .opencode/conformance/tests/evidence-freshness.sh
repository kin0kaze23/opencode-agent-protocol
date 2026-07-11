#!/usr/bin/env bash
# evidence-freshness.sh — v4.43 Evidence Freshness Conformance Tests
#
# Tests for evidence freshness classification, validator updates,
# dashboard integration, and freshness report generation.
#
# Usage: bash .opencode/conformance/tests/evidence-freshness.sh

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

reset_counters

echo "=== v4.43 Evidence Freshness Conformance Tests ==="
echo ""

# ─── EF-001: freshness report script exists ────────────────────────────
test_start "EF-001" "freshness report script exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "Freshness report script exists"

# ─── EF-002: freshness report generates markdown ──────────────────────
test_start "EF-002" "freshness report generates markdown"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "evidence-freshness.md" "Report outputs markdown"

# ─── EF-003: freshness report generates JSON ──────────────────────────
test_start "EF-003" "freshness report generates JSON"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "evidence-freshness.json" "Report outputs JSON"

# ─── EF-004: validator has 4-level freshness classification ─────────────
test_start "EF-004" "validator has 4-level freshness"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "fresh_evidence" "Validator has fresh_evidence"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "expiring_soon" "Validator has expiring_soon"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "stale_evidence" "Validator has stale_evidence"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "critically_stale" "Validator has critically_stale"

# ─── EF-005: validator has warning threshold ───────────────────────────
test_start "EF-005" "validator has warning threshold"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "WARNING_DAYS" "Validator has WARNING_DAYS"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "60" "Warning threshold is 60 days"

# ─── EF-006: validator has expiry threshold ─────────────────────────────
test_start "EF-006" "validator has expiry threshold"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "EXPIRY_DAYS" "Validator has EXPIRY_DAYS"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "90" "Expiry threshold is 90 days"

# ─── EF-007: validator has critical threshold ───────────────────────────
test_start "EF-007" "validator has critical threshold"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "CRITICAL_EXPIRY_DAYS" "Validator has CRITICAL_EXPIRY_DAYS"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "120" "Critical threshold is 120 days"

# ─── EF-008: validator checks future timestamp ──────────────────────────
test_start "EF-008" "validator checks future timestamp"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "future" "Validator checks for future timestamps"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "future_timestamp" "Validator classifies future as future_timestamp"

# ─── EF-009: validator checks missing timestamp ────────────────────────
test_start "EF-009" "validator checks missing timestamp"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "Missing recorded_at" "Validator checks for missing timestamp"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "missing_timestamp" "Validator classifies missing as missing_timestamp"

# ─── EF-010: validator outputs freshness status ────────────────────────
test_start "EF-010" "validator outputs freshness status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "Freshness:" "Validator outputs Freshness field"

# ─── EF-011: dashboard shows evidence age ──────────────────────────────
test_start "EF-011" "dashboard shows evidence age"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "Evidence Age" "Dashboard includes Evidence Age field"

# ─── EF-012: dashboard shows freshness status ──────────────────────────
test_start "EF-012" "dashboard shows freshness status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "Freshness" "Dashboard includes Freshness field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "FRESHNESS_STATUS" "Dashboard uses FRESHNESS_STATUS variable"

# ─── EF-013: stale evidence reverts to protection_ready ────────────────
test_start "EF-013" "stale evidence reverts to protection_ready"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "stale" "Dashboard checks for stale freshness"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" "protection_ready" "Dashboard can classify as protection_ready"

# ─── EF-014: freshness report has thresholds ───────────────────────────
test_start "EF-014" "freshness report has thresholds"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "warning_days" "Report has warning_days"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "expiry_days" "Report has expiry_days"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "critical_expiry_days" "Report has critical_expiry_days"

# ─── EF-015: freshness report has owner action ─────────────────────────
test_start "EF-015" "freshness report has owner action"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "owner_action" "Report has owner_action field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "Refresh" "Report includes refresh action"

# ─── EF-016: freshness report has days until expiry ─────────────────────
test_start "EF-016" "freshness report has days until expiry"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "days_until_expiry" "Report has days_until_expiry field"

# ─── EF-017: freshness report has evidence age ─────────────────────────
test_start "EF-017" "freshness report has evidence age"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "evidence_age" "Report has evidence_age field"

# ─── EF-018: freshness report has marker ───────────────────────────────
test_start "EF-018" "freshness report has marker"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "evidence-freshness" "Report has evidence-freshness marker"

# ─── EF-019: freshness report has version tag ──────────────────────────
test_start "EF-019" "freshness report has version tag"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "v4.43" "Report references v4.43"

# ─── EF-020: dashboard checks freshness before manually_verified ───────
test_start "EF-020" "dashboard checks freshness before manually_verified"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" 'FRESHNESS_STATUS" == "fresh"' "Dashboard requires fresh for manually_verified"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-fleet-dashboard.sh" 'FRESHNESS_STATUS" == "expiring_soon"' "Dashboard allows expiring_soon for manually_verified"

# ─── EF-021: validator has inconsistent_evidence for future ────────────
test_start "EF-021" "validator has inconsistent_evidence for future"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-manual-branch-protection-evidence.sh" "inconsistent_evidence" "Validator has inconsistent_evidence classification"

# ─── EF-022: freshness report handles no evidence ──────────────────────
test_start "EF-022" "freshness report handles no evidence"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "no_evidence" "Report handles no_evidence status"

# ─── EF-023: freshness report handles missing timestamp ────────────────
test_start "EF-023" "freshness report handles missing timestamp"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "missing_timestamp" "Report handles missing timestamp"

# ─── EF-024: freshness report handles future timestamp ──────────────────
test_start "EF-024" "freshness report handles future timestamp"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "future_timestamp" "Report handles future timestamp"

# ─── EF-025: freshness report has URGENT action for critical ───────────
test_start "EF-025" "freshness report has URGENT action for critical"
assert_file_contains "$ROOT_DIR/.opencode/scripts/evidence-freshness-report.sh" "URGENT" "Report has URGENT action for critically stale"

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
