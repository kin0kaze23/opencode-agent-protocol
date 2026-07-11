#!/usr/bin/env bash
# exploratory-scorecard.sh — Conformance test for v4.29.3 exploratory scorecard
#
# Verifies:
# - collection_mode and evidence_level fields exist in schema
# - record-task-outcome.sh supports --collection-mode and --evidence-level
# - scorecard shows live/retrospective breakdown
# - scorecard shows repo/lane/type distributions
# - scorecard shows threshold breakdown (total, reviewer, non_perfect, per_type)
# - routing_optimization is partially_blocked when thresholds are not all met
# - recommendation_status is exploratory_only
# - synthetic eval records are excluded from real telemetry

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

RESULT_FILE="$ROOT_DIR/.opencode/conformance/results/exploratory-scorecard-$(date +%Y%m%d-%H%M%S).md"

# ============================================================
# ES-001: Schema has collection_mode and evidence_level
# ============================================================
test_start "ES-001" "schema has collection_mode and evidence_level"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "collection_mode" "schema has collection_mode"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "evidence_level" "schema has evidence_level"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "retrospective" "schema has retrospective enum"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "synthetic_eval" "schema has synthetic_eval enum"

# ============================================================
# ES-002: record-task-outcome.sh supports new flags
# ============================================================
test_start "ES-002" "record script supports --collection-mode and --evidence-level"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "collection-mode" "has --collection-mode flag"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "evidence-level" "has --evidence-level flag"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "COLLECTION_MODE" "has COLLECTION_MODE variable"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "EVIDENCE_LEVEL" "has EVIDENCE_LEVEL variable"

# ============================================================
# ES-003: Scorecard shows collection mode breakdown
# ============================================================
test_start "ES-003" "scorecard shows collection mode breakdown"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "collection_mode" "has collection_mode field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "live_count" "has live_count"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "retrospective_count" "has retrospective_count"

# ============================================================
# ES-004: Scorecard shows distributions
# ============================================================
test_start "ES-004" "scorecard shows distributions"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "repo_distribution" "has repo_distribution"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "lane_distribution" "has lane_distribution"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "task_type_distribution" "has task_type_distribution"

# ============================================================
# ES-005: Scorecard shows threshold breakdown
# ============================================================
test_start "ES-005" "scorecard shows threshold breakdown"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "thresholds" "has thresholds section"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "reviewer:" "has reviewer threshold"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "non_perfect" "has non_perfect threshold"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "per_type_max" "has per_type_max threshold"

# ============================================================
# ES-006: routing_optimization is partially_blocked when thresholds not met
# ============================================================
test_start "ES-006" "routing_optimization uses partially_blocked status"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "partially_blocked" "has partially_blocked status"

# ============================================================
# ES-007: recommendation_status is exploratory_only
# ============================================================
test_start "ES-007" "recommendation_status is exploratory_only"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "exploratory_only" "has exploratory_only"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "recommendation_status" "has recommendation_status field"

# ============================================================
# ES-008: Aggregate report exists and is updated
# ============================================================
test_start "ES-008" "aggregate report exists"
assert_file_exists "$ROOT_DIR/.opencode/reports/agent-quality/2026-07-scorecard.md" "scorecard report exists"
assert_file_contains "$ROOT_DIR/.opencode/reports/agent-quality/2026-07-scorecard.md" "collection_mode" "report has collection_mode"
assert_file_contains "$ROOT_DIR/.opencode/reports/agent-quality/2026-07-scorecard.md" "thresholds" "report has thresholds"
assert_file_contains "$ROOT_DIR/.opencode/reports/agent-quality/2026-07-scorecard.md" "exploratory_only" "report has exploratory_only"

# ============================================================
# ES-009: Fixture scorecard distinguishes from real
# ============================================================
test_start "ES-009" "fixture scorecard distinguishes from real"
FIXTURE_RESULT=$(METRICS_FILE="$ROOT_DIR/.opencode/conformance/fixtures/task-outcomes-sample.jsonl" bash "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" 2>&1 || true)
if echo "$FIXTURE_RESULT" | grep -q "data_source: fixture"; then
  echo -e "  ${GREEN}✓${NC} fixture scorecard identifies as fixture"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} fixture scorecard does not identify as fixture"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$FIXTURE_RESULT" | grep -q "recommendation_status: exploratory_only"; then
  echo -e "  ${GREEN}✓${NC} fixture scorecard has exploratory_only status"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} fixture scorecard missing exploratory_only status"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# ES-010: Real scorecard has correct routing status
# ============================================================
test_start "ES-010" "real scorecard has correct routing status"
REAL_RESULT=$(bash "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" 2>&1 || true)
if echo "$REAL_RESULT" | grep -q "partially_blocked"; then
  echo -e "  ${GREEN}✓${NC} real scorecard shows partially_blocked"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} real scorecard does not show partially_blocked"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$REAL_RESULT" | grep -q "exploratory_only"; then
  echo -e "  ${GREEN}✓${NC} real scorecard has exploratory_only status"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} real scorecard missing exploratory_only status"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"
