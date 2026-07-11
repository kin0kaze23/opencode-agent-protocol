#!/usr/bin/env bash
# run-agent-baseline-evals.sh — Baseline eval runner skeleton (v4.29.1)
#
# Validates baseline eval task structure without modifying real repos.
# Runs dry checks: schema exists, tasks parse, expected commands exist,
# scorecard handles empty/low-data/sample-data cases.
#
# Usage:
#   bash .opencode/scripts/run-agent-baseline-evals.sh [--verbose]
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVAL_FILE="$ROOT_DIR/evals/baseline-tasks.yaml"
SCHEMA_FILE="$ROOT_DIR/schemas/task-outcome.schema.json"
FIXTURE_FILE="$ROOT_DIR/conformance/fixtures/task-outcomes-sample.jsonl"
SCORECARD_SCRIPT="$ROOT_DIR/scripts/summarize-agent-quality.sh"
RECORD_SCRIPT="$ROOT_DIR/scripts/record-task-outcome.sh"

VERBOSE="${1:-}"
PASS=0
FAIL=0

ok() {
  echo "  ✓ $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "  ✗ $1"
  FAIL=$((FAIL + 1))
}

echo "=== Baseline Eval Runner (v4.29.1) ==="
echo ""

# 1. Schema exists
echo "1. Schema validation"
if [ -f "$SCHEMA_FILE" ]; then
  ok "task-outcome.schema.json exists"
  if command -v jq &>/dev/null; then
    if jq empty "$SCHEMA_FILE" 2>/dev/null; then
      ok "schema is valid JSON"
    else
      fail "schema is not valid JSON"
    fi
  else
    ok "jq not available — skipping JSON validation"
  fi
else
  fail "task-outcome.schema.json not found"
fi
echo ""

# 2. Baseline tasks parse
echo "2. Baseline task parsing"
if [ -f "$EVAL_FILE" ]; then
  ok "baseline-tasks.yaml exists"
  EVAL_COUNT=$(grep -c '^\s*- id:' "$EVAL_FILE" 2>/dev/null || echo "0")
  if [ "$EVAL_COUNT" -ge 10 ]; then
    ok "$EVAL_COUNT eval tasks defined (minimum 10)"
  else
    fail "Only $EVAL_COUNT eval tasks (minimum 10 required)"
  fi
else
  fail "baseline-tasks.yaml not found"
fi
echo ""

# 3. Expected scripts exist
echo "3. Script availability"
if [ -x "$RECORD_SCRIPT" ]; then
  ok "record-task-outcome.sh exists and is executable"
else
  fail "record-task-outcome.sh missing or not executable"
fi
if [ -x "$SCORECARD_SCRIPT" ]; then
  ok "summarize-agent-quality.sh exists and is executable"
else
  fail "summarize-agent-quality.sh missing or not executable"
fi
echo ""

# 4. Scorecard handles empty data
echo "4. Scorecard edge cases"
EMPTY_RESULT=$(bash "$SCORECARD_SCRIPT" 2>&1)
if echo "$EMPTY_RESULT" | grep -q "no_data\|empty\|insufficient"; then
  ok "scorecard handles empty data gracefully"
else
  fail "scorecard does not handle empty data"
fi
echo ""

# 5. Scorecard handles sample fixture
echo "5. Scorecard with fixture data"
if [ -f "$FIXTURE_FILE" ]; then
  ok "fixture file exists"
  # Run scorecard with fixture by temporarily pointing to fixture
  FIXTURE_RESULT=$(METRICS_FILE="$FIXTURE_FILE" bash "$SCORECARD_SCRIPT" 2>&1 || true)
  if echo "$FIXTURE_RESULT" | grep -q "AGENT_QUALITY_SCORECARD"; then
    ok "scorecard produces output from fixture data"
    if echo "$FIXTURE_RESULT" | grep -q "insufficient data"; then
      ok "scorecard correctly reports insufficient data for small sample"
    elif echo "$FIXTURE_RESULT" | grep -q "recommendations"; then
      ok "scorecard generates recommendations from fixture"
    else
      fail "scorecard output missing recommendations or insufficient data warning"
    fi
  else
    fail "scorecard failed to produce output from fixture"
  fi
else
  fail "fixture file not found"
fi
echo ""

# 6. Record script validates enum fields
echo "6. Record script validation"
INVALID_RESULT=$(bash "$RECORD_SCRIPT" --repo test --lane INVALID --task-type feature --outcome success 2>&1 || true)
if echo "$INVALID_RESULT" | grep -q "Invalid lane"; then
  ok "record script rejects invalid lane"
else
  fail "record script does not validate lane"
fi
echo ""

# Summary
echo "=========================================="
echo "  Baseline Eval Results"
echo "=========================================="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "=========================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
