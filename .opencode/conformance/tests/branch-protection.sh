#!/usr/bin/env bash
# branch-protection.sh — v4.38 Branch Protection Conformance Tests
#
# Tests for verify-branch-protection.sh, verify-codeowners.sh,
# and release-protection-report.sh.
#
# Usage: bash .opencode/conformance/tests/branch-protection.sh

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

reset_counters

echo "=== v4.38 Branch Protection Conformance Tests ==="
echo ""

# ─── BP-001: verify-branch-protection.sh exists and is executable ──────
test_start "BP-001" "verify-branch-protection.sh exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "Branch protection verifier exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "Verifier is executable"

# ─── BP-002: verify-codeowners.sh exists and is executable ─────────────
test_start "BP-002" "verify-codeowners.sh exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "CODEOWNERS verifier exists"

# ─── BP-003: release-protection-report.sh exists and is executable ────
test_start "BP-003" "release-protection-report.sh exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/release-protection-report.sh" "Protection report script exists"

# ─── BP-004: verify-branch-protection.sh has --strict flag ──────────────
test_start "BP-004" "branch protection verifier supports --strict"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "--strict" "Verifier has --strict flag"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "STRICT" "Verifier has STRICT mode"

# ─── BP-005: verify-branch-protection.sh handles 403 ───────────────────
test_start "BP-005" "branch protection verifier handles 403"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "403" "Verifier checks for 403"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "permission_limited" "Verifier classifies as permission_limited"

# ─── BP-006: verify-branch-protection.sh checks for Release Gate required ─
test_start "BP-006" "verifier checks Release Gate required"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "Release Gate" "Verifier checks for Release Gate"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "required" "Verifier checks required checks"

# ─── BP-007: verify-branch-protection.sh checks stale approval dismissal ─
test_start "BP-007" "verifier checks stale approval dismissal"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "stale" "Verifier checks stale approvals"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "dismiss" "Verifier checks dismissal"

# ─── BP-008: verify-branch-protection.sh checks direct push restriction ──
test_start "BP-008" "verifier checks direct push restriction"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "force_push" "Verifier checks force push"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "Force pushes" "Verifier reports force push status"

# ─── BP-009: verify-branch-protection.sh has classification output ──────
test_start "BP-009" "verifier has classification output"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "Classification:" "Verifier outputs classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "not_configured" "Verifier has not_configured classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "unknown_permission_limited" "Verifier has permission_limited classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "blocked_misconfigured" "Verifier has misconfigured classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "verified" "Verifier has verified classification"

# ─── BP-010: verify-codeowners.sh checks standard locations ─────────────
test_start "BP-010" "CODEOWNERS verifier checks standard locations"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" ".github/CODEOWNERS" "Checks .github/CODEOWNERS"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "CODEOWNERS" "Checks root CODEOWNERS"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "docs/CODEOWNERS" "Checks docs/CODEOWNERS"

# ─── BP-011: verify-codeowners.sh checks sensitive paths ────────────────
test_start "BP-011" "CODEOWNERS verifier checks sensitive paths"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "workflows" "Checks workflows path"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "scripts" "Checks scripts path"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "config" "Checks config path"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "auth" "Checks auth path"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "migrations" "Checks migrations path"

# ─── BP-012: verify-codeowners.sh has --strict flag ─────────────────────
test_start "BP-012" "CODEOWNERS verifier supports --strict"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "--strict" "CODEOWNERS verifier has --strict flag"

# ─── BP-013: verify-codeowners.sh has classification output ──────────────
test_start "BP-013" "CODEOWNERS verifier has classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "Classification:" "CODEOWNERS verifier outputs classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "missing_codeowners" "Has missing_codeowners classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "partially_covered" "Has partially_covered classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "verified" "Has verified classification"

# ─── BP-014: release-protection-report.sh combines all checks ───────────
test_start "BP-014" "protection report combines all checks"
assert_file_contains "$ROOT_DIR/.opencode/scripts/release-protection-report.sh" "verify-branch-protection.sh" "Report calls branch protection verifier"
assert_file_contains "$ROOT_DIR/.opencode/scripts/release-protection-report.sh" "verify-codeowners.sh" "Report calls CODEOWNERS verifier"
assert_file_contains "$ROOT_DIR/.opencode/scripts/release-protection-report.sh" "trust" "Report checks trust policy"

# ─── BP-015: release-protection-report.sh has final recommendation ──────
test_start "BP-015" "protection report has final recommendation"
assert_file_contains "$ROOT_DIR/.opencode/scripts/release-protection-report.sh" "protected" "Report has protected classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/release-protection-report.sh" "partially_protected" "Report has partially_protected classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/release-protection-report.sh" "not_protected" "Report has not_protected classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/release-protection-report.sh" "unknown_permission_limited" "Report has permission_limited classification"

# ─── BP-016: release-protection-report.sh has --strict flag ─────────────
test_start "BP-016" "protection report supports --strict"
assert_file_contains "$ROOT_DIR/.opencode/scripts/release-protection-report.sh" "--strict" "Report has --strict flag"

# ─── BP-017: validate-release-gate.sh has --strict flag ─────────────────
test_start "BP-017" "validator supports --strict"
assert_file_contains "$ROOT_DIR/.opencode/scripts/validate-release-gate.sh" "--strict" "Validator has --strict flag"
assert_file_contains "$ROOT_DIR/.opencode/scripts/validate-release-gate.sh" "STRICT" "Validator has STRICT mode"

# ─── BP-018: validate-release-gate.sh calls branch protection verifier ──
test_start "BP-018" "validator calls branch protection verifier"
assert_file_contains "$ROOT_DIR/.opencode/scripts/validate-release-gate.sh" "verify-branch-protection.sh" "Validator calls branch protection verifier"

# ─── BP-019: validate-release-gate.sh calls CODEOWNERS verifier ─────────
test_start "BP-019" "validator calls CODEOWNERS verifier"
assert_file_contains "$ROOT_DIR/.opencode/scripts/validate-release-gate.sh" "verify-codeowners.sh" "Validator calls CODEOWNERS verifier"

# ─── BP-020: CODEOWNERS template exists ─────────────────────────────────
test_start "BP-020" "CODEOWNERS template exists"
assert_file_exists "$ROOT_DIR/docs/CODEOWNERS_TEMPLATE.md" "CODEOWNERS template exists"
assert_file_contains "$ROOT_DIR/docs/CODEOWNERS_TEMPLATE.md" "workflows" "Template covers workflows"
assert_file_contains "$ROOT_DIR/docs/CODEOWNERS_TEMPLATE.md" "scripts" "Template covers scripts"
assert_file_contains "$ROOT_DIR/docs/CODEOWNERS_TEMPLATE.md" "auth" "Template covers auth"
assert_file_contains "$ROOT_DIR/docs/CODEOWNERS_TEMPLATE.md" "migrations" "Template covers migrations"

# ─── BP-021: verify-branch-protection.sh checks admin enforcement ──────
test_start "BP-021" "verifier checks admin enforcement"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "enforce_admins" "Verifier checks admin enforcement"

# ─── BP-022: verify-branch-protection.sh checks required reviews ────────
test_start "BP-022" "verifier checks required reviews"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "required_approving_review_count" "Verifier checks approving review count"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "dismiss_stale_reviews" "Verifier checks stale review dismissal"

# ─── BP-023: verify-branch-protection.sh checks build/test required ─────
test_start "BP-023" "verifier checks build/test required"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "build" "Verifier checks for build check"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-branch-protection.sh" "secret" "Verifier checks for secret scanning"

# ─── BP-024: release-protection-report.sh checks gate installation ──────
test_start "BP-024" "report checks gate installation"
assert_file_contains "$ROOT_DIR/.opencode/scripts/release-protection-report.sh" "pr-release-gate.yml" "Report checks for release gate workflow"
assert_file_contains "$ROOT_DIR/.opencode/scripts/release-protection-report.sh" "validate-release-gate.sh" "Report checks for validator"

# ─── BP-025: verify-codeowners.sh checks for default owner ─────────────
test_start "BP-025" "CODEOWNERS verifier checks default owner"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "Default owner" "Verifier checks for default owner"
assert_file_contains "$ROOT_DIR/.opencode/scripts/verify-codeowners.sh" "pattern" "Verifier checks wildcard pattern"

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
