#!/usr/bin/env bash
# pr-release-gate.sh — v4.34 Conformance test for PR release gate
#
# Verifies:
# - Workflow file exists and has correct triggers
# - Action script exists and is executable
# - Workflow references classifier and report scripts
# - Workflow uses GITHUB_STEP_SUMMARY
# - Workflow uses actions/upload-artifact
# - Blocking semantics are documented
# - Classifier fixture still triggers high-risk
# - Docs-only changes stay non-sensitive
# - PR summary fields are documented
# - Low-risk PRs do not require reviewer

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

RESULT_FILE="$ROOT_DIR/.opencode/conformance/results/pr-release-gate-$(date +%Y%m%d-%H%M%S).md"

# ============================================================
# PRG-001: Workflow file exists
# ============================================================
test_start "PRG-001" "pr-release-gate.yml workflow exists"
assert_file_exists "$ROOT_DIR/.github/workflows/pr-release-gate.yml" "workflow file exists"

# ============================================================
# PRG-002: Workflow has correct triggers
# ============================================================
test_start "PRG-002" "workflow triggers on pull_request"
assert_file_contains "$ROOT_DIR/.github/workflows/pr-release-gate.yml" "pull_request" "triggers on pull_request"
assert_file_contains "$ROOT_DIR/.github/workflows/pr-release-gate.yml" "workflow_dispatch" "supports manual dispatch"

# ============================================================
# PRG-003: Action script exists and is executable
# ============================================================
test_start "PRG-003" "pr-release-gate-action.sh exists and is executable"
assert_file_exists "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "action script exists"
if [ -x "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" ]; then
  echo -e "  ${GREEN}✓${NC} action script is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} action script is NOT executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-004: Workflow references classifier and report scripts
# ============================================================
test_start "PRG-004" "workflow references classifier and report scripts"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "sensitive-change-classifier.sh" "action calls classifier"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "release-decision-report.sh" "action calls release report"

# ============================================================
# PRG-005: Action uses GITHUB_STEP_SUMMARY
# ============================================================
test_start "PRG-005" "action writes GITHUB_STEP_SUMMARY"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "GITHUB_STEP_SUMMARY" "action uses GITHUB_STEP_SUMMARY"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "Release Gate Summary" "summary has title"

# ============================================================
# PRG-006: Workflow uses actions/upload-artifact
# ============================================================
test_start "PRG-006" "workflow uploads report artifact"
assert_file_contains "$ROOT_DIR/.github/workflows/pr-release-gate.yml" "actions/upload-artifact" "workflow uploads artifact"
assert_file_contains "$ROOT_DIR/.github/workflows/pr-release-gate.yml" "release-decision-report" "artifact named correctly"

# ============================================================
# PRG-007: PR summary includes required fields
# ============================================================
test_start "PRG-007" "PR summary includes required fields"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "release_status" "summary has release_status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "risk_level" "summary has risk_level"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "classifier_detection_type" "summary has detection_type"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "sensitive_areas\|Sensitive Areas" "summary has sensitive areas"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "matched_sensitive_patterns\|Matched Sensitive Patterns" "summary has matched patterns"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "reviewer_required\|Reviewer Required" "summary has reviewer required"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "allowed_failures\|Allowed Failures" "summary has allowed failures"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "expiry_warnings\|Expiry Warnings" "summary has expiry warnings"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "Owner Next Action\|owner_next_action\|owner action" "summary has owner next action"

# ============================================================
# PRG-008: Blocking semantics documented
# ============================================================
test_start "PRG-008" "blocking semantics are implemented"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" 'RELEASE_STATUS.*block' "action checks for block status"
assert_file_contains "$ROOT_DIR/.github/workflows/pr-release-gate.yml" "Check blocking" "workflow has blocking check step"

# ============================================================
# PRG-009: Classifier fixture triggers high-risk
# ============================================================
test_start "PRG-009" "classifier fixture triggers high-risk"
FIXTURE="$ROOT_DIR/.opencode/conformance/fixtures/app-App-tsx-false-negative.txt"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "$FIXTURE" 2>/dev/null)
if echo "$OUTPUT" | grep -q "risk_level: high"; then
  echo -e "  ${GREEN}✓${NC} fixture classified as high risk"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} fixture not classified as high risk"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "reviewer"; then
  echo -e "  ${GREEN}✓${NC} reviewer required for high-risk fixture"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} reviewer not required for high-risk fixture"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-010: Docs-only changes stay non-sensitive
# ============================================================
test_start "PRG-010" "docs-only changes stay non-sensitive"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "docs/guide.md" "CHANGELOG.md" 2>/dev/null)
if echo "$OUTPUT" | grep -q "risk_level: none"; then
  echo -e "  ${GREEN}✓${NC} docs-only changes return risk_level: none"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} docs-only changes do not return risk_level: none"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-011: Low-risk PRs do not require reviewer
# ============================================================
test_start "PRG-011" "low-risk PRs do not require reviewer"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "README.md" "src/utils.ts" 2>/dev/null)
if echo "$OUTPUT" | grep -q "must_escalate: false"; then
  echo -e "  ${GREEN}✓${NC} low-risk changes do not escalate"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} low-risk changes escalate (should not)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "risk_level: none"; then
  echo -e "  ${GREEN}✓${NC} low-risk changes return risk_level: none"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} low-risk changes do not return risk_level: none"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-012: Action script syntax valid
# ============================================================
test_start "PRG-012" "action script syntax is valid"
if bash -n "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" 2>&1; then
  echo -e "  ${GREEN}✓${NC} action script syntax valid"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} action script syntax invalid"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-013: Workflow syntax valid
# ============================================================
test_start "PRG-013" "workflow YAML is valid"
if python3 -c "import yaml; yaml.safe_load(open('$ROOT_DIR/.github/workflows/pr-release-gate.yml'))" 2>/dev/null; then
  echo -e "  ${GREEN}✓${NC} workflow YAML is valid"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} workflow YAML is invalid"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-014: Documentation exists
# ============================================================
test_start "PRG-014" "PR release gate documentation exists"
assert_file_exists "$ROOT_DIR/docs/PR_RELEASE_GATE.md" "documentation exists"
assert_file_contains "$ROOT_DIR/docs/PR_RELEASE_GATE.md" "Release Gate Summary" "docs reference summary format"
assert_file_contains "$ROOT_DIR/docs/PR_RELEASE_GATE.md" "release_status" "docs explain release_status"
assert_file_contains "$ROOT_DIR/docs/PR_RELEASE_GATE.md" "block" "docs explain blocking semantics"

# ============================================================
# PRG-015: v4.34.2 — Release report accepts precomputed classifier output
# ============================================================
test_start "PRG-015" "release-decision-report.sh accepts --classifier-output"
assert_file_contains "$ROOT_DIR/.opencode/scripts/release-decision-report.sh" "classifier-output" "report script has --classifier-output flag"

# Test: run classifier, save to file, pass to report
FIXTURE="$ROOT_DIR/.opencode/conformance/fixtures/app-App-tsx-false-negative.txt"
CLASSIFIER_OUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "$FIXTURE" 2>/dev/null)
echo "$CLASSIFIER_OUT" > /tmp/test-classifier-output.txt

REPORT_OUT=$(bash "$ROOT_DIR/.opencode/scripts/release-decision-report.sh" --classifier-output /tmp/test-classifier-output.txt --repo "$ROOT_DIR" 2>/dev/null)
if echo "$REPORT_OUT" | grep -q "release_status: advisory"; then
  echo -e "  ${GREEN}✓${NC} report shows advisory for high-risk classifier output"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} report does not show advisory for high-risk classifier output"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$REPORT_OUT" | grep -q "risk_level: high"; then
  echo -e "  ${GREEN}✓${NC} report shows risk_level: high from precomputed output"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} report does not show risk_level: high from precomputed output"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$REPORT_OUT" | grep -q "reviewer_required: true"; then
  echo -e "  ${GREEN}✓${NC} report shows reviewer_required: true from precomputed output"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} report does not show reviewer_required: true from precomputed output"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

rm -f /tmp/test-classifier-output.txt

# ============================================================
# PRG-016: v4.34.2 — Action script passes classifier output to report
# ============================================================
test_start "PRG-016" "action script passes classifier output to report"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "classifier-output" "action passes --classifier-output to report"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "/tmp/classifier-output.txt" "action saves classifier output to temp file"

# ============================================================
# PRG-017: v4.34.2 — Classifier scripts don't trigger content self-noise
# ============================================================
test_start "PRG-017" "classifier scripts don't trigger content self-noise"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files ".opencode/scripts/sensitive-change-classifier.sh" 2>/dev/null)
if echo "$OUTPUT" | grep -q "matched_content_patterns: \[\]"; then
  echo -e "  ${GREEN}✓${NC} classifier script has no content self-noise"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} classifier script has content self-noise (should not)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "deployment"; then
  echo -e "  ${GREEN}✓${NC} classifier script classified as deployment tooling"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} classifier script not classified as deployment tooling"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "risk_level: medium"; then
  echo -e "  ${GREEN}✓${NC} classifier script is medium risk (not high from self-noise)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} classifier script is not medium risk"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-018: v4.34.2 — GitHub scripts path also skips content self-noise
# ============================================================
test_start "PRG-018" "github scripts path skips content self-noise"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files ".github/scripts/sensitive-change-classifier.sh" 2>/dev/null)
if echo "$OUTPUT" | grep -q "matched_content_patterns: \[\]"; then
  echo -e "  ${GREEN}✓${NC} github scripts path has no content self-noise"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} github scripts path has content self-noise (should not)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-019: v4.35 — Reviewer evidence detector script exists
# ============================================================
test_start "PRG-019" "reviewer-evidence-detector.sh exists and is executable"
assert_file_exists "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" "detector script exists"
if [ -x "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" ]; then
  echo -e "  ${GREEN}✓${NC} detector script is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} detector script is NOT executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-020: v4.35 — Detector produces correct output format
# ============================================================
test_start "PRG-020" "detector produces correct output format"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" 2>/dev/null)
if echo "$OUTPUT" | grep -q "REVIEWER_EVIDENCE:"; then
  echo -e "  ${GREEN}✓${NC} detector produces REVIEWER_EVIDENCE output"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} detector does not produce REVIEWER_EVIDENCE output"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "reviewer_evidence_found:"; then
  echo -e "  ${GREEN}✓${NC} output includes reviewer_evidence_found"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} output missing reviewer_evidence_found"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "evidence_type:"; then
  echo -e "  ${GREEN}✓${NC} output includes evidence_type"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} output missing evidence_type"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "evidence_trusted:"; then
  echo -e "  ${GREEN}✓${NC} output includes evidence_trusted"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} output missing evidence_trusted"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-021: v4.35 — Detector defaults to no evidence without PR number
# ============================================================
test_start "PRG-021" "detector defaults to no evidence without PR number"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" 2>/dev/null)
if echo "$OUTPUT" | grep -q "reviewer_evidence_found: false"; then
  echo -e "  ${GREEN}✓${NC} defaults to false without PR number"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} does not default to false without PR number"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "evidence_trusted: false"; then
  echo -e "  ${GREEN}✓${NC} defaults to untrusted without PR number"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} does not default to untrusted without PR number"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-022: v4.35 — Detector accepts --evidence-file for testing
# ============================================================
test_start "PRG-022" "detector accepts --evidence-file for testing"
TMPFILE=$(mktemp /tmp/test-evidence-XXXXXX.txt)
cat > "$TMPFILE" << 'EVIDENCE'
reviewer_evidence_found: true
evidence_type: github_review
reviewer_identity: test-reviewer
evidence_trusted: true
reason: GitHub approving review from test-reviewer
EVIDENCE
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" --evidence-file "$TMPFILE" 2>/dev/null)
if echo "$OUTPUT" | grep -q "reviewer_evidence_found: true"; then
  echo -e "  ${GREEN}✓${NC} reads evidence from file"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} does not read evidence from file"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "evidence_type: github_review"; then
  echo -e "  ${GREEN}✓${NC} reads evidence_type from file"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} does not read evidence_type from file"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "evidence_trusted: true"; then
  echo -e "  ${GREEN}✓${NC} reads evidence_trusted from file"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} does not read evidence_trusted from file"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f "$TMPFILE"

# ============================================================
# PRG-023: v4.35 — Action script calls detector when reviewer required
# ============================================================
test_start "PRG-023" "action script calls reviewer evidence detector"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "reviewer-evidence-detector.sh" "action calls detector"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "REVIEWER_REQUIRED" "action checks reviewer_required"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "ENFORCEMENT_STATUS" "action has enforcement status"

# ============================================================
# PRG-024: v4.35 — Action script blocks high-risk without evidence
# ============================================================
test_start "PRG-024" "action script blocks high-risk without evidence"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" 'RISK_LEVEL.*high.*EVIDENCE_TRUSTED.*true' "action checks high-risk + evidence"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "ENFORCEMENT_STATUS.*block" "action can block"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "High-risk sensitive change requires trusted reviewer evidence" "action has block reason"

# ============================================================
# PRG-025: v4.35 — PR summary includes reviewer evidence fields
# ============================================================
test_start "PRG-025" "PR summary includes reviewer evidence fields"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "Reviewer Evidence Found" "summary has reviewer evidence found"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "Evidence Type" "summary has evidence type"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "Evidence Trusted" "summary has evidence trusted"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "Enforcement Status" "summary has enforcement status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "Enforcement Reason" "summary has enforcement reason"

# ============================================================
# PRG-026: v4.35 — Workflow passes GITHUB_TOKEN for gh CLI
# ============================================================
test_start "PRG-026" "workflow passes GITHUB_TOKEN for gh CLI"
assert_file_contains "$ROOT_DIR/.github/workflows/pr-release-gate.yml" "GITHUB_TOKEN" "workflow has GITHUB_TOKEN"
assert_file_contains "$ROOT_DIR/.github/workflows/pr-release-gate.yml" "secrets.GITHUB_TOKEN" "workflow uses secrets.GITHUB_TOKEN"

# ============================================================
# PRG-027: v4.35 — Workflow blocking step updated for enforcement
# ============================================================
test_start "PRG-027" "workflow blocking step handles enforcement"
assert_file_contains "$ROOT_DIR/.github/workflows/pr-release-gate.yml" "reviewer_evidence_found" "blocking step checks evidence"
assert_file_contains "$ROOT_DIR/.github/workflows/pr-release-gate.yml" "reviewer-approved" "blocking step mentions label"

# ============================================================
# PRG-028: v4.36 — Trust policy config exists
# ============================================================
test_start "PRG-028" "trust policy config exists"
assert_file_exists "$ROOT_DIR/.opencode/config/reviewer-trust-policy.yaml" "trust policy config exists"
assert_file_contains "$ROOT_DIR/.opencode/config/reviewer-trust-policy.yaml" "trusted_reviewers" "config has trusted_reviewers"
assert_file_contains "$ROOT_DIR/.opencode/config/reviewer-trust-policy.yaml" "trusted_labels" "config has trusted_labels"
assert_file_contains "$ROOT_DIR/.opencode/config/reviewer-trust-policy.yaml" "allow_label_evidence" "config has allow_label_evidence"
assert_file_contains "$ROOT_DIR/.opencode/config/reviewer-trust-policy.yaml" "require_fresh_approval" "config has require_fresh_approval"

# ============================================================
# PRG-029: v4.36 — Detector loads trust policy
# ============================================================
test_start "PRG-029" "detector loads trust policy"
assert_file_contains "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" "reviewer-trust-policy.yaml" "detector references trust policy"
assert_file_contains "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" "TRUST_POLICY_SOURCE" "detector outputs trust policy source"
assert_file_contains "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" "ALLOW_LABEL_EVIDENCE" "detector reads allow_label_evidence"
assert_file_contains "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" "REQUIRE_FRESH_APPROVAL" "detector reads require_fresh_approval"

# ============================================================
# PRG-030: v4.36 — Detector excludes PR author approvals
# ============================================================
test_start "PRG-030" "detector excludes PR author approvals"
assert_file_contains "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" "PR_AUTHOR" "detector fetches PR author"
assert_file_contains "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" "REVIEWER_IS_AUTHOR" "detector has reviewer_is_author field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" "Skip author" "detector skips author approvals"

# ============================================================
# PRG-031: v4.36 — Detector checks stale approvals
# ============================================================
test_start "PRG-031" "detector checks stale approvals"
assert_file_contains "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" "PR_HEAD_SHA" "detector fetches head SHA"
assert_file_contains "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" "APPROVAL_FRESH" "detector has approval_fresh field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" "stale" "detector can detect stale approvals"

# ============================================================
# PRG-032: v4.36 — Detector outputs new fields
# ============================================================
test_start "PRG-032" "detector outputs v4.36 fields"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" 2>/dev/null)
if echo "$OUTPUT" | grep -q "reviewer_is_author:"; then
  echo -e "  ${GREEN}✓${NC} output includes reviewer_is_author"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} output missing reviewer_is_author"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "approval_fresh:"; then
  echo -e "  ${GREEN}✓${NC} output includes approval_fresh"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} output missing approval_fresh"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "trust_policy_source:"; then
  echo -e "  ${GREEN}✓${NC} output includes trust_policy_source"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} output missing trust_policy_source"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-033: v4.36 — Action script includes new summary fields
# ============================================================
test_start "PRG-033" "action script includes v4.36 summary fields"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "Reviewer Is Author" "summary has reviewer_is_author"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "Approval Freshness" "summary has approval_fresh"
assert_file_contains "$ROOT_DIR/.opencode/scripts/pr-release-gate-action.sh" "Trust Policy Source" "summary has trust_policy_source"

# ============================================================
# PRG-034: v4.36 — Branch protection documentation exists
# ============================================================
test_start "PRG-034" "branch protection documentation exists"
assert_file_exists "$ROOT_DIR/docs/BRANCH_PROTECTION.md" "branch protection docs exist"
assert_file_contains "$ROOT_DIR/docs/BRANCH_PROTECTION.md" "Release Gate" "docs mention Release Gate check"
assert_file_contains "$ROOT_DIR/docs/BRANCH_PROTECTION.md" "Dismiss stale" "docs mention stale approval dismissal"
assert_file_contains "$ROOT_DIR/docs/BRANCH_PROTECTION.md" "reviewer-approved" "docs mention label restriction"

# ============================================================
# PRG-035: v4.36 — Evidence file mode includes new fields
# ============================================================
test_start "PRG-035" "evidence file mode includes new fields"
TMPFILE=$(mktemp /tmp/test-evidence-v436-XXXXXX.txt)
cat > "$TMPFILE" << 'EVIDENCE'
reviewer_evidence_found: true
evidence_type: github_review
reviewer_identity: trusted-reviewer
evidence_trusted: true
reviewer_is_author: false
approval_fresh: true
trust_policy_source: config
reason: GitHub approving review from trusted-reviewer (fresh, matches current head)
EVIDENCE
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" --evidence-file "$TMPFILE" 2>/dev/null)
if echo "$OUTPUT" | grep -q "reviewer_is_author: false"; then
  echo -e "  ${GREEN}✓${NC} reads reviewer_is_author from file"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} does not read reviewer_is_author from file"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "approval_fresh: true"; then
  echo -e "  ${GREEN}✓${NC} reads approval_fresh from file"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} does not read approval_fresh from file"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "trust_policy_source: config"; then
  echo -e "  ${GREEN}✓${NC} reads trust_policy_source from file"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} does not read trust_policy_source from file"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f "$TMPFILE"

# ============================================================
# PRG-036: v4.36.1a — Label name exact match (not substring)
# ============================================================
test_start "PRG-036" "label name exact match — reviewer-approved not approved"
assert_file_contains "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" 'grep -qxi' "detector uses exact match (grep -x)"
PARSED_LABEL=$(echo "  - reviewer-approved" | sed 's/^[[:space:]]*-[[:space:]]*//')
if [[ "$PARSED_LABEL" == "reviewer-approved" ]]; then
  echo -e "  ${GREEN}✓${NC} sed correctly extracts 'reviewer-approved'"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} sed extracts '$PARSED_LABEL' (expected 'reviewer-approved')"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo '{"labels":[{"name":"approved"}]}' | jq -r '.labels[].name' 2>/dev/null | grep -qxi "reviewer-approved"; then
  echo -e "  ${RED}✗${NC} 'approved' incorrectly matches 'reviewer-approved' (should not)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
else
  echo -e "  ${GREEN}✓${NC} 'approved' does not match 'reviewer-approved'"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# ============================================================
# PRG-037: v4.37 — Install script exists
# ============================================================
test_start "PRG-037" "install-release-gate.sh exists and is executable"
assert_file_exists "$ROOT_DIR/.opencode/scripts/install-release-gate.sh" "install script exists"
if [ -x "$ROOT_DIR/.opencode/scripts/install-release-gate.sh" ]; then
  echo -e "  ${GREEN}✓${NC} install script is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} install script is NOT executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-038: v4.37 — Validate script exists
# ============================================================
test_start "PRG-038" "validate-release-gate.sh exists and is executable"
assert_file_exists "$ROOT_DIR/.opencode/scripts/validate-release-gate.sh" "validate script exists"
if [ -x "$ROOT_DIR/.opencode/scripts/validate-release-gate.sh" ]; then
  echo -e "  ${GREEN}✓${NC} validate script is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} validate script is NOT executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PRG-039: v4.37 — Install script supports dry-run
# ============================================================
test_start "PRG-039" "install script supports dry-run"
assert_file_contains "$ROOT_DIR/.opencode/scripts/install-release-gate.sh" "dry-run" "install script has dry-run mode"
assert_file_contains "$ROOT_DIR/.opencode/scripts/install-release-gate.sh" "--dry-run" "install script has --dry-run flag"

# ============================================================
# PRG-040: v4.37 — Install script refuses legacy repos
# ============================================================
test_start "PRG-040" "install script refuses legacy repos"
assert_file_contains "$ROOT_DIR/.opencode/scripts/install-release-gate.sh" "legacy" "install script checks for legacy repos"
assert_file_contains "$ROOT_DIR/.opencode/scripts/install-release-gate.sh" "protected-repo" "install script refuses protected-repo"

# ============================================================
# PRG-041: v4.37 — Validate script checks required files
# ============================================================
test_start "PRG-041" "validate script checks required files"
assert_file_contains "$ROOT_DIR/.opencode/scripts/validate-release-gate.sh" "sensitive-change-classifier" "validate checks classifier"
assert_file_contains "$ROOT_DIR/.opencode/scripts/validate-release-gate.sh" "release-decision-report" "validate checks report"
assert_file_contains "$ROOT_DIR/.opencode/scripts/validate-release-gate.sh" "reviewer-evidence-detector" "validate checks detector"
assert_file_contains "$ROOT_DIR/.opencode/scripts/validate-release-gate.sh" "pr-release-gate" "validate checks workflow"
assert_file_contains "$ROOT_DIR/.opencode/scripts/validate-release-gate.sh" "reviewer-trust-policy" "validate checks trust policy"
