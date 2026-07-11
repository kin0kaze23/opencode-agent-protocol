#!/usr/bin/env bash
# telemetry-pilot-readiness.sh — Conformance test for v4.29.2 eval pilot readiness
#
# Verifies:
# - aggregate report path/template exists
# - notes safety checks exist
# - duplicate task_id guard exists
# - scorecard distinguishes fixture vs real data
# - routing optimization remains blocked below threshold
# - record-task-outcome supports --task-id and --allow-duplicate

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

RESULT_FILE="$ROOT_DIR/.opencode/conformance/results/telemetry-pilot-readiness-$(date +%Y%m%d-%H%M%S).md"

# ============================================================
# TPR-001: Aggregate report path exists
# ============================================================
test_start "TPR-001" "aggregate report path exists"
if [ -d "$ROOT_DIR/.opencode/reports/agent-quality" ]; then
  echo -e "  ${GREEN}✓${NC} report directory exists"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} report directory missing"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
assert_file_exists "$ROOT_DIR/.opencode/reports/agent-quality/README.md" "report README exists"

# ============================================================
# TPR-002: Notes safety checks exist
# ============================================================
test_start "TPR-002" "notes safety checks exist"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "truncated to 500" "notes length limit"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "sensitive pattern" "secret pattern detection"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "redacted" "notes redaction on detection"

# ============================================================
# TPR-003: Duplicate task_id guard exists
# ============================================================
test_start "TPR-003" "duplicate task_id guard exists"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "allow-duplicate" "allow-duplicate flag"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "duplicate task_id" "duplicate warning message"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "task-id" "custom task-id flag"

# ============================================================
# TPR-004: Scorecard distinguishes fixture vs real data
# ============================================================
test_start "TPR-004" "scorecard distinguishes fixture vs real data"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "data_source" "data_source field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "fixture" "fixture detection"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "real" "real data detection"

# ============================================================
# TPR-005: Routing optimization remains blocked below threshold
# ============================================================
test_start "TPR-005" "routing optimization blocked below threshold"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "routing_optimization" "routing_optimization field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "blocked" "blocked status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "insufficient data" "insufficient data warning"

# ============================================================
# TPR-006: Trend placeholder exists
# ============================================================
test_start "TPR-006" "trend placeholder exists"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "trend" "trend field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "not yet available" "trend placeholder"

# ============================================================
# TPR-007: Compact JSON output
# ============================================================
test_start "TPR-007" "record script outputs compact JSON"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "jq -c" "compact JSON flag"

# ============================================================
# TPR-008: METRICS_FILE env override
# ============================================================
test_start "TPR-008" "METRICS_FILE env override in record script"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "METRICS_FILE" "env override"

# ============================================================
# TPR-009: Scorecard with fixture still works
# ============================================================
test_start "TPR-009" "scorecard with fixture data works"
FIXTURE_RESULT=$(METRICS_FILE="$ROOT_DIR/.opencode/conformance/fixtures/task-outcomes-sample.jsonl" bash "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" 2>&1 || true)
if echo "$FIXTURE_RESULT" | grep -q "data_source: fixture"; then
  echo -e "  ${GREEN}✓${NC} scorecard identifies fixture data"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} scorecard does not identify fixture data"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$FIXTURE_RESULT" | grep -q "routing_optimization"; then
  echo -e "  ${GREEN}✓${NC} fixture scorecard includes routing_optimization field"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} fixture scorecard missing routing_optimization field"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# TPR-010: Aggregate report generated
# ============================================================
test_start "TPR-010" "aggregate report generated"
# Check if at least one monthly report exists
REPORT_COUNT=$(find "$ROOT_DIR/.opencode/reports/agent-quality" -name "*-scorecard.md" -not -name "README.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$REPORT_COUNT" -ge 1 ]; then
  echo -e "  ${GREEN}✓${NC} $REPORT_COUNT scorecard report(s) exist"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} No scorecard reports found"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"
