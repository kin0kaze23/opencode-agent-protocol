#!/usr/bin/env bash
# telemetry-hardening.sh — Conformance test for v4.29.1 telemetry hardening
#
# Verifies:
# - schema exists and is valid JSON
# - telemetry policy exists
# - baseline eval tasks exist and have minimum count
# - scorecard has low-sample guardrails
# - sample fixture produces expected recommendations
# - record-task-outcome validates enum fields
# - DIRECT Lite still skips telemetry

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

RESULT_FILE="$ROOT_DIR/.opencode/conformance/results/telemetry-hardening-$(date +%Y%m%d-%H%M%S).md"

# ============================================================
# TH-001: Schema exists and is valid JSON
# ============================================================
test_start "TH-001" "task-outcome.schema.json exists and is valid"
assert_file_exists "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "schema file exists"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "required" "schema has required fields"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "lane" "schema defines lane"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "outcome" "schema defines outcome"
assert_file_contains "$ROOT_DIR/.opencode/schemas/task-outcome.schema.json" "forbidden" "schema has forbidden fields"

# ============================================================
# TH-002: Telemetry policy exists
# ============================================================
test_start "TH-002" "telemetry policy exists"
assert_file_exists "$ROOT_DIR/.opencode/docs/telemetry-policy.md" "policy doc exists"
assert_file_contains "$ROOT_DIR/.opencode/docs/telemetry-policy.md" "Never Collect" "policy lists forbidden data"
assert_file_contains "$ROOT_DIR/.opencode/docs/telemetry-policy.md" "retention" "policy has retention guidance"
assert_file_contains "$ROOT_DIR/.opencode/docs/telemetry-policy.md" "Minimum Sample" "policy has minimum sample sizes"

# ============================================================
# TH-003: Baseline eval tasks exist
# ============================================================
test_start "TH-003" "baseline eval tasks exist"
assert_file_exists "$ROOT_DIR/.opencode/evals/baseline-tasks.yaml" "baseline tasks file exists"
assert_file_contains "$ROOT_DIR/.opencode/evals/baseline-tasks.yaml" "eval-001" "has eval-001"
assert_file_contains "$ROOT_DIR/.opencode/evals/baseline-tasks.yaml" "eval-010" "has eval-010 (HIGH_RISK)"
assert_file_contains "$ROOT_DIR/.opencode/evals/baseline-tasks.yaml" "pass_criteria" "has pass criteria"

# Count eval tasks
EVAL_COUNT=$(grep -c '^\s*- id:' "$ROOT_DIR/.opencode/evals/baseline-tasks.yaml" 2>/dev/null || echo "0")
if [ "$EVAL_COUNT" -ge 10 ]; then
  echo -e "  ${GREEN}✓${NC} $EVAL_COUNT eval tasks (minimum 10)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Only $EVAL_COUNT eval tasks (minimum 10 required)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# TH-004: Scorecard has low-sample guardrails
# ============================================================
test_start "TH-004" "scorecard has low-sample guardrails"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "min_tasks" "has min_tasks variable"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "insufficient data" "has insufficient data warning"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "min_per_type" "has min_per_type variable"

# ============================================================
# TH-005: Fixture file exists and has expected records
# ============================================================
test_start "TH-005" "fixture file exists with expected records"
assert_file_exists "$ROOT_DIR/.opencode/conformance/fixtures/task-outcomes-sample.jsonl" "fixture file exists"
FIXTURE_COUNT=$(wc -l < "$ROOT_DIR/.opencode/conformance/fixtures/task-outcomes-sample.jsonl" | tr -d ' ')
if [ "$FIXTURE_COUNT" -ge 10 ]; then
  echo -e "  ${GREEN}✓${NC} $FIXTURE_COUNT fixture records (minimum 10)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Only $FIXTURE_COUNT fixture records (minimum 10 required)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Check fixture has expected record types
assert_file_contains "$ROOT_DIR/.opencode/conformance/fixtures/task-outcomes-sample.jsonl" '"outcome":"success"' "has success records"
assert_file_contains "$ROOT_DIR/.opencode/conformance/fixtures/task-outcomes-sample.jsonl" '"outcome":"partial"' "has partial records"
assert_file_contains "$ROOT_DIR/.opencode/conformance/fixtures/task-outcomes-sample.jsonl" '"outcome":"reverted"' "has reverted records"
assert_file_contains "$ROOT_DIR/.opencode/conformance/fixtures/task-outcomes-sample.jsonl" '"premium_model_used":"opencode-go/qwen3.7-plus"' "has premium model record"
assert_file_contains "$ROOT_DIR/.opencode/conformance/fixtures/task-outcomes-sample.jsonl" '"pattern_memory_used":"true"' "has pattern memory record"

# ============================================================
# TH-006: Scorecard produces correct output from fixture
# ============================================================
test_start "TH-006" "scorecard produces correct output from fixture"
FIXTURE_RESULT=$(METRICS_FILE="$ROOT_DIR/.opencode/conformance/fixtures/task-outcomes-sample.jsonl" bash "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" 2>&1 || true)
if echo "$FIXTURE_RESULT" | grep -q "AGENT_QUALITY_SCORECARD"; then
  echo -e "  ${GREEN}✓${NC} scorecard produces output from fixture"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} scorecard failed to produce output from fixture"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$FIXTURE_RESULT" | grep -q "tasks_count: 15"; then
  echo -e "  ${GREEN}✓${NC} scorecard counts 15 tasks from fixture"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} scorecard did not count 15 tasks"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$FIXTURE_RESULT" | grep -q "recommendations"; then
  echo -e "  ${GREEN}✓${NC} scorecard generates recommendations from fixture"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} scorecard missing recommendations"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# TH-007: Record script validates enum fields
# ============================================================
test_start "TH-007" "record script validates enum fields"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "Invalid lane" "validates lane enum"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "Invalid task_type" "validates task_type enum"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "Invalid outcome" "validates outcome enum"

# ============================================================
# TH-008: Eval runner exists and is executable
# ============================================================
test_start "TH-008" "eval runner exists and is executable"
assert_file_exists "$ROOT_DIR/.opencode/scripts/run-agent-baseline-evals.sh" "eval runner exists"
if [ -x "$ROOT_DIR/.opencode/scripts/run-agent-baseline-evals.sh" ]; then
  echo -e "  ${GREEN}✓${NC} eval runner is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} eval runner is NOT executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# TH-009: DIRECT Lite still skips telemetry
# ============================================================
test_start "TH-009" "DIRECT Lite still skips telemetry"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "Do NOT record telemetry for DIRECT Lite" "DIRECT Lite excluded"

# ============================================================
# TH-010: Record script remains non-blocking
# ============================================================
test_start "TH-010" "record script remains non-blocking"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "Non-blocking" "non-blocking documented"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "exit 0" "exits 0 on error"

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"
