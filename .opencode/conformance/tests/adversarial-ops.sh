#!/bin/bash
# Adversarial Ops Tests - Executable fixture validation for protocol refusal and conflict handling

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/adversarial-ops-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

BENCH_DIR="$ROOT_DIR/.opencode/benchmarks/adversarial"
RUNNER="$ROOT_DIR/.opencode/scripts/run-adversarial-harness.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Adversarial Ops Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

test_start "ADV-001" "Adversarial harness runner exists"
assert_file_exists "$RUNNER" "Adversarial harness runner exists"

test_start "ADV-002" "Adversarial fixtures have executable fields"
COUNT=$(find "$BENCH_DIR" -type f -name '*.md' | wc -l | tr -d ' ')
assert_equals "6" "$COUNT" "Adversarial fixture count"
for fixture in "$BENCH_DIR"/*.md; do
  assert_file_contains "$fixture" "## Attack prompt" "Fixture has attack prompt: $(basename "$fixture")"
  assert_file_contains "$fixture" "## Expected behavior" "Fixture has expected behavior: $(basename "$fixture")"
  assert_file_contains "$fixture" "## Pass conditions" "Fixture has pass conditions: $(basename "$fixture")"
done

test_start "ADV-003" "Executable adversarial harness passes"
HARNESS_OUTPUT="$(bash "$RUNNER")"
assert_output_contains "$HARNESS_OUTPUT" "PASS PROMPT-INJECTION-001" "Prompt injection case passes"
assert_output_contains "$HARNESS_OUTPUT" "PASS CAPABILITY-ESCALATION-001" "Capability escalation case passes"
assert_output_contains "$HARNESS_OUTPUT" "PASS EVIDENCE-BYPASS-001" "Evidence bypass case passes"
assert_output_contains "$HARNESS_OUTPUT" "PASS APPROVAL-BYPASS-001" "Approval bypass case passes"
assert_output_contains "$HARNESS_OUTPUT" "PASS RUNTIME-CONFLICT-001" "Runtime conflict case passes"
assert_output_contains "$HARNESS_OUTPUT" "PASS SENSITIVE-SAST-001" "Sensitive SAST case passes"
assert_output_contains "$HARNESS_OUTPUT" "pass=6 fail=0" "Harness summary passes"

echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
