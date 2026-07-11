#!/usr/bin/env bash
# production-hardening.sh — v4.33 Conformance test for production hardening
#
# Verifies:
# - Sensitive change classifier exists and works
# - DIRECT Lite escalates on sensitive paths
# - HIGH_RISK reviewer remains required
# - env/auth/payment/schema changes require reviewer
# - Broad allowed-failure swallowing is rejected
# - Expired allowed failures block
# - Release decision report exists and includes evidence
# - Low-risk DIRECT tasks remain fast
# - v4.33: Content-aware detection catches auth-adjacent changes in generic paths
# - v4.33: Casual auth mentions do not become high-risk
# - v4.33: Docs-only changes remain non-sensitive
# - v4.33: Manual override fields are supported
# - v4.33: Release report includes classifier detection type

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

RESULT_FILE="$ROOT_DIR/.opencode/conformance/results/production-hardening-$(date +%Y%m%d-%H%M%S).md"

# ============================================================
# PH-001: Sensitive change classifier exists and is executable
# ============================================================
test_start "PH-001" "sensitive-change-classifier.sh exists and is executable"
assert_file_exists "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" "classifier exists"
if [ -x "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" ]; then
  echo -e "  ${GREEN}✓${NC} classifier is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} classifier is NOT executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-002: Classifier detects auth paths
# ============================================================
test_start "PH-002" "classifier detects auth paths"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "app/auth/login.ts" 2>/dev/null)
if echo "$OUTPUT" | grep -q "auth"; then
  echo -e "  ${GREEN}✓${NC} classifier detects auth paths"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} classifier does not detect auth paths"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "must_escalate: true"; then
  echo -e "  ${GREEN}✓${NC} auth paths trigger escalation"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} auth paths do not trigger escalation"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-003: Classifier detects secrets paths
# ============================================================
test_start "PH-003" "classifier detects secrets/env paths"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files ".env.local" 2>/dev/null)
if echo "$OUTPUT" | grep -q "secrets"; then
  echo -e "  ${GREEN}✓${NC} classifier detects .env files"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} classifier does not detect .env files"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-004: Classifier detects schema/migration paths
# ============================================================
test_start "PH-004" "classifier detects schema/migration paths"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "db/migrations/001.sql" 2>/dev/null)
if echo "$OUTPUT" | grep -q "schema"; then
  echo -e "  ${GREEN}✓${NC} classifier detects migration paths"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} classifier does not detect migration paths"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-005: Classifier returns none for non-sensitive paths
# ============================================================
test_start "PH-005" "classifier returns none for non-sensitive paths"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "README.md" "src/utils.ts" 2>/dev/null)
if echo "$OUTPUT" | grep -q "risk_level: none"; then
  echo -e "  ${GREEN}✓${NC} non-sensitive paths return risk_level: none"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} non-sensitive paths do not return risk_level: none"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "must_escalate: false"; then
  echo -e "  ${GREEN}✓${NC} non-sensitive paths do not trigger escalation"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} non-sensitive paths trigger escalation (should not)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-006: Release decision report exists and works
# ============================================================
test_start "PH-006" "release-decision-report.sh exists and works"
assert_file_exists "$ROOT_DIR/.opencode/scripts/release-decision-report.sh" "report script exists"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/release-decision-report.sh" --repo "$ROOT_DIR" 2>/dev/null)
if echo "$OUTPUT" | grep -q "RELEASE_DECISION_REPORT:"; then
  echo -e "  ${GREEN}✓${NC} report produces output"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} report does not produce output"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "release_status:"; then
  echo -e "  ${GREEN}✓${NC} report includes release_status"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} report does not include release_status"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-007: HIGH-RISK reviewer remains required in token-budget
# ============================================================
test_start "PH-007" "HIGH-RISK reviewer remains required"
if grep -A15 "HIGH-RISK:" "$ROOT_DIR/.opencode/config/token-budget.yaml" | grep -q "reviewer_required: true"; then
  echo -e "  ${GREEN}✓${NC} HIGH-RISK reviewer_required: true"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} HIGH-RISK reviewer_required not found"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if grep -A15 "HIGH-RISK:" "$ROOT_DIR/.opencode/config/token-budget.yaml" | grep -q "always required"; then
  echo -e "  ${GREEN}✓${NC} HIGH-RISK reviewer condition is 'always required'"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} HIGH-RISK reviewer condition is not 'always required'"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-008: Sensitive-path escalation rules exist in token-budget
# ============================================================
test_start "PH-008" "sensitive-path escalation rules exist"
if grep -q "sensitive_path_escalation" "$ROOT_DIR/.opencode/config/token-budget.yaml"; then
  echo -e "  ${GREEN}✓${NC} sensitive_path_escalation section present"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} sensitive_path_escalation section missing"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if grep -q "allowed_failure_policy" "$ROOT_DIR/.opencode/config/token-budget.yaml"; then
  echo -e "  ${GREEN}✓${NC} allowed_failure_policy section present"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} allowed_failure_policy section missing"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if grep -q "broad_swallowing_forbidden" "$ROOT_DIR/.opencode/config/token-budget.yaml"; then
  echo -e "  ${GREEN}✓${NC} broad_swallowing_forbidden rule present"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} broad_swallowing_forbidden rule missing"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-009: Telemetry schema has new fields
# ============================================================
test_start "PH-009" "telemetry schema has review_repair_cycles and pre_ci_reviewer_blocked"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "review_repair_cycles" "schema has review_repair_cycles"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "pre_ci_reviewer_blocked" "schema has pre_ci_reviewer_blocked"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "review_repair_cycles" "record script has review_repair_cycles"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "pre_ci_reviewer_blocked" "record script has pre_ci_reviewer_blocked"

# ============================================================
# PH-010: DIRECT Lite remains fast (no sensitive-path overhead)
# ============================================================
test_start "PH-010" "DIRECT Lite remains fast for non-sensitive paths"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "README.md" 2>/dev/null)
if echo "$OUTPUT" | grep -q "must_escalate: false"; then
  echo -e "  ${GREEN}✓${NC} non-sensitive DIRECT paths do not escalate"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} non-sensitive DIRECT paths escalate (should not)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-011: v4.32.1 regression — app/App.tsx with VITE_E2E + SignedIn
#         must classify as high-risk auth/security (content-based)
# ============================================================
test_start "PH-011" "v4.32.1 regression: app/App.tsx with VITE_E2E + SignedIn is high-risk"
FIXTURE="$ROOT_DIR/.opencode/conformance/fixtures/app-App-tsx-false-negative.txt"
assert_file_exists "$FIXTURE" "regression fixture exists"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "$FIXTURE" 2>/dev/null)
if echo "$OUTPUT" | grep -q "risk_level: high"; then
  echo -e "  ${GREEN}✓${NC} fixture classified as high risk"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} fixture not classified as high risk"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "auth"; then
  echo -e "  ${GREEN}✓${NC} sensitive_areas includes auth"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} sensitive_areas does not include auth"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "must_escalate: true"; then
  echo -e "  ${GREEN}✓${NC} must_escalate is true"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} must_escalate is not true"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "detection_type: content"; then
  echo -e "  ${GREEN}✓${NC} detection_type is content"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} detection_type is not content"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "classifier_detected_sensitive: true"; then
  echo -e "  ${GREEN}✓${NC} classifier_detected_sensitive is true"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} classifier_detected_sensitive is not true"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-012: Casual "auth" mention in UI copy does not become high-risk
# ============================================================
test_start "PH-012" "casual auth mention does not become high-risk"
TMPFILE=$(mktemp /tmp/test-casual-auth-XXXXXX.tsx)
echo 'export function Welcome() { return <p>Authentication status shown here.</p>; }' > "$TMPFILE"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "$TMPFILE" 2>/dev/null)
if echo "$OUTPUT" | grep -q "risk_level: none"; then
  echo -e "  ${GREEN}✓${NC} casual auth mention stays risk_level: none"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} casual auth mention escalated risk (should not)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "must_escalate: false"; then
  echo -e "  ${GREEN}✓${NC} casual auth mention does not escalate"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} casual auth mention triggers escalation (should not)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f "$TMPFILE"

# ============================================================
# PH-013: Docs-only changes remain non-sensitive
# ============================================================
test_start "PH-013" "docs-only changes remain non-sensitive"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "docs/guide.md" "CHANGELOG.md" 2>/dev/null)
if echo "$OUTPUT" | grep -q "risk_level: none"; then
  echo -e "  ${GREEN}✓${NC} docs-only changes return risk_level: none"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} docs-only changes do not return risk_level: none"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "must_escalate: false"; then
  echo -e "  ${GREEN}✓${NC} docs-only changes do not escalate"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} docs-only changes trigger escalation (should not)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-014: Content-based detection triggers reviewer requirement
# ============================================================
test_start "PH-014" "content-based detection triggers reviewer requirement"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "$FIXTURE" 2>/dev/null)
if echo "$OUTPUT" | grep -q "required_gates:.*reviewer"; then
  echo -e "  ${GREEN}✓${NC} content-based detection requires reviewer"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} content-based detection does not require reviewer"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-015: Release report includes classifier_detection_type
# ============================================================
test_start "PH-015" "release report includes classifier_detection_type"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/release-decision-report.sh" --repo "$ROOT_DIR" 2>/dev/null)
if echo "$OUTPUT" | grep -q "classifier_detection_type:"; then
  echo -e "  ${GREEN}✓${NC} release report includes classifier_detection_type"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} release report missing classifier_detection_type"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "matched_sensitive_patterns:"; then
  echo -e "  ${GREEN}✓${NC} release report includes matched_sensitive_patterns"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} release report missing matched_sensitive_patterns"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "classifier_detected_sensitive:"; then
  echo -e "  ${GREEN}✓${NC} release report includes classifier_detected_sensitive"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} release report missing classifier_detected_sensitive"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-016: Manual override fields are supported and visible
# ============================================================
test_start "PH-016" "manual override fields are supported in classifier"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "src/utils.ts" --manual-override --manual-override-reason "v4.32.1 false negative" 2>/dev/null)
if echo "$OUTPUT" | grep -q "detection_type: manual"; then
  echo -e "  ${GREEN}✓${NC} manual override sets detection_type: manual"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} manual override does not set detection_type: manual"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "risk_level: high"; then
  echo -e "  ${GREEN}✓${NC} manual override sets risk_level: high"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} manual override does not set risk_level: high"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "manual_override: true"; then
  echo -e "  ${GREEN}✓${NC} manual_override field is true"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} manual_override field is not true"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "manual_override_reason: v4.32.1 false negative"; then
  echo -e "  ${GREEN}✓${NC} manual_override_reason is visible"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} manual_override_reason is not visible"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-017: Manual override visible in release report
# ============================================================
test_start "PH-017" "manual override visible in release report"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/release-decision-report.sh" --repo "$ROOT_DIR" --manual-override --manual-override-reason "v4.32.1 false negative: auth-adjacent change" 2>/dev/null)
if echo "$OUTPUT" | grep -q "classifier_false_negative_manual_override: true"; then
  echo -e "  ${GREEN}✓${NC} release report shows classifier_false_negative_manual_override: true"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} release report missing classifier_false_negative_manual_override: true"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "manual_sensitive_override_reason:"; then
  echo -e "  ${GREEN}✓${NC} release report shows manual_sensitive_override_reason"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} release report missing manual_sensitive_override_reason"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# PH-018: Task outcome schema has v4.33 classifier fields
# ============================================================
test_start "PH-018" "task outcome schema has v4.33 classifier fields"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "classifier_detected_sensitive" "schema has classifier_detected_sensitive"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "manual_sensitive_override" "schema has manual_sensitive_override"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "classifier_false_negative" "schema has classifier_false_negative"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "classifier_detection_type" "schema has classifier_detection_type"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "classifier_detected_sensitive" "record script has classifier_detected_sensitive"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "manual_sensitive_override" "record script has manual_sensitive_override"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "classifier_false_negative" "record script has classifier_false_negative"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "classifier_detection_type" "record script has classifier_detection_type"

# ============================================================
# PH-019: v4.34.2 — Classifier scripts don't trigger content self-noise
# ============================================================
test_start "PH-019" "classifier scripts don't trigger content self-noise"
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

# ============================================================
# PH-020: v4.34.2 — Release report accepts precomputed classifier output
# ============================================================
test_start "PH-020" "release report accepts precomputed classifier output"
FIXTURE="$ROOT_DIR/.opencode/conformance/fixtures/app-App-tsx-false-negative.txt"
CLASSIFIER_OUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --files "$FIXTURE" 2>/dev/null)
echo "$CLASSIFIER_OUT" > /tmp/test-ph-classifier-output.txt
REPORT_OUT=$(bash "$ROOT_DIR/.opencode/scripts/release-decision-report.sh" --classifier-output /tmp/test-ph-classifier-output.txt --repo "$ROOT_DIR" 2>/dev/null)
if echo "$REPORT_OUT" | grep -q "release_status: advisory"; then
  echo -e "  ${GREEN}✓${NC} report shows advisory for high-risk precomputed output"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} report does not show advisory for high-risk precomputed output"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$REPORT_OUT" | grep -q "reviewer_required: true"; then
  echo -e "  ${GREEN}✓${NC} report shows reviewer_required: true from precomputed output"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} report does not show reviewer_required: true from precomputed output"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f /tmp/test-ph-classifier-output.txt

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"
