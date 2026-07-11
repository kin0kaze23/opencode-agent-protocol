#!/usr/bin/env bash
# reviewer-calibration-scorecard.sh — Conformance test for v4.29.4
#
# Verifies:
# - source_type exists in schema
# - evidence_level has unknown enum in schema
# - eval_fixture is excluded from routing thresholds
# - reviewer_count < 5 blocks reviewer routing changes
# - partial evidence is weighted lower (confidence metric)
# - non-perfect outcome policy forbids fabricated failures
# - senior-self-review has reviewer value fields
# - reviewer calibration policy exists

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

RESULT_FILE="$ROOT_DIR/.opencode/conformance/results/reviewer-calibration-$(date +%Y%m%d-%H%M%S).md"

# ============================================================
# RC-001: source_type exists in schema
# ============================================================
test_start "RC-001" "source_type exists in schema"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "source_type" "schema has source_type"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "eval_fixture" "schema has eval_fixture enum"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "retrospective" "schema has retrospective enum"

# ============================================================
# RC-002: evidence_level has unknown enum
# ============================================================
test_start "RC-002" "evidence_level has unknown enum"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "unknown" "schema has unknown evidence level"

# ============================================================
# RC-003: record script supports --source-type
# ============================================================
test_start "RC-003" "record script supports --source-type"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "source-type" "has --source-type flag"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "SOURCE_TYPE" "has SOURCE_TYPE variable"

# ============================================================
# RC-004: scorecard excludes eval_fixture from routing
# ============================================================
test_start "RC-004" "scorecard excludes eval_fixture from routing"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "eval_fixture" "scorecard handles eval_fixture"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "source_type" "scorecard has source_type filtering"

# ============================================================
# RC-005: scorecard has confidence weighting
# ============================================================
test_start "RC-005" "scorecard has confidence weighting"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "confidence_weight" "has confidence_weight"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "confidence_full_count" "has confidence_full_count"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "ci_first_pass_rate_confidence" "has confidence-weighted CI rate"

# ============================================================
# RC-006: scorecard blocks routing when reviewer < 5
# ============================================================
test_start "RC-006" "scorecard blocks routing when reviewer < 5"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "reviewer coverage insufficient" "has reviewer coverage block message"

# ============================================================
# RC-007: scorecard blocks routing when confidence < 70%
# ============================================================
test_start "RC-007" "scorecard blocks routing when confidence < 70%"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "low confidence" "has low confidence block message"

# ============================================================
# RC-008: reviewer calibration policy exists
# ============================================================
test_start "RC-008" "reviewer calibration policy exists"
assert_file_exists "$ROOT_DIR/.opencode/docs/reviewer-calibration.md" "policy doc exists"
assert_file_contains "$ROOT_DIR/.opencode/docs/reviewer-calibration.md" "material_issue_found" "has material_issue_found classification"
assert_file_contains "$ROOT_DIR/.opencode/docs/reviewer-calibration.md" "false_positive" "has false_positive classification"
assert_file_contains "$ROOT_DIR/.opencode/docs/reviewer-calibration.md" "Calibration Thresholds" "has calibration thresholds"

# ============================================================
# RC-009: senior-self-review has reviewer value fields
# ============================================================
test_start "RC-009" "senior-self-review has reviewer calibration fields"
assert_file_contains "$ROOT_DIR/.opencode/scripts/senior-self-review.sh" "reviewer_value_classification" "has reviewer_value_classification"
assert_file_contains "$ROOT_DIR/.opencode/scripts/senior-self-review.sh" "reviewer_issue_severity" "has reviewer_issue_severity"
assert_file_contains "$ROOT_DIR/.opencode/scripts/senior-self-review.sh" "reviewer_false_positive" "has reviewer_false_positive"
assert_file_contains "$ROOT_DIR/.opencode/scripts/senior-self-review.sh" "reviewer_recommendation_next_time" "has reviewer_recommendation_next_time"

# ============================================================
# RC-010: telemetry policy has non-perfect outcome rules
# ============================================================
test_start "RC-010" "telemetry policy has non-perfect outcome rules"
assert_file_contains "$ROOT_DIR/.opencode/docs/telemetry-policy.md" "Non-Perfect Outcome Policy" "has non-perfect outcome section"
assert_file_contains "$ROOT_DIR/.opencode/docs/telemetry-policy.md" "Do not fabricate" "forbids fabricated failures"
assert_file_contains "$ROOT_DIR/.opencode/docs/telemetry-policy.md" "Evidence Weighting" "has evidence weighting table"
assert_file_contains "$ROOT_DIR/.opencode/docs/telemetry-policy.md" "Source Type Rules" "has source type rules"

# ============================================================
# RC-011: scorecard shows source_type breakdown
# ============================================================
test_start "RC-011" "scorecard shows source_type breakdown"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "source_live" "has source_live"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "source_retrospective" "has source_retrospective"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "source_eval_fixture" "has source_eval_fixture"

# ============================================================
# RC-012: Real scorecard has correct routing status
# ============================================================
test_start "RC-012" "real scorecard has correct routing status"
REAL_RESULT=$(bash "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" 2>&1 || true)
if echo "$REAL_RESULT" | grep -q "partially_blocked"; then
  echo -e "  ${GREEN}✓${NC} real scorecard shows partially_blocked"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} real scorecard does not show partially_blocked"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$REAL_RESULT" | grep -q "confidence_weight"; then
  echo -e "  ${GREEN}✓${NC} real scorecard shows confidence_weight"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} real scorecard missing confidence_weight"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$REAL_RESULT" | grep -q "source_type"; then
  echo -e "  ${GREEN}✓${NC} real scorecard shows source_type"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} real scorecard missing source_type"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"
