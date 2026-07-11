#!/bin/bash
# Runtime Simulation Tests - Validate representative workflow scenarios against canonical protocol

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/runtime-simulations-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

SIM_DIR="$ROOT_DIR/.opencode/benchmarks/simulations"
RUNNER="$ROOT_DIR/.opencode/scripts/run-runtime-simulations.sh"
BRAIN_CONFIG="$ROOT_DIR/.opencode/brain-config.json"

echo "=========================================="
echo "Protocol Conformance Suite - Runtime Simulation Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

test_start "SIM-001" "Runtime simulation runner and metadata exist"
assert_file_exists "$RUNNER" "Runtime simulation runner exists"
assert_file_contains "$BRAIN_CONFIG" "\"runtime_simulations\"" "brain-config defines runtime simulations"

test_start "SIM-002" "Simulation cases cover the required flows"
COUNT=$(find "$SIM_DIR" -type f -name '*.md' | wc -l | tr -d ' ')
assert_equals "4" "$COUNT" "Runtime simulation case count"
for sim in "$SIM_DIR"/*.md; do
  assert_file_contains "$sim" "Scenario:" "Simulation has scenario: $(basename "$sim")"
  assert_file_contains "$sim" "## Pass conditions" "Simulation has pass conditions: $(basename "$sim")"
done

test_start "SIM-003" "Runtime simulation runner passes"
SIM_OUTPUT="$(bash "$RUNNER")"
assert_output_contains "$SIM_OUTPUT" "PASS FAST-001" "FAST simulation passes"
assert_output_contains "$SIM_OUTPUT" "PASS STANDARD-001" "STANDARD simulation passes"
assert_output_contains "$SIM_OUTPUT" "PASS HIGH-RISK-001" "HIGH-RISK simulation passes"
assert_output_contains "$SIM_OUTPUT" "PASS DEBUG-001" "DEBUG simulation passes"
assert_output_contains "$SIM_OUTPUT" "pass=4 fail=0" "Simulation summary passes"

echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
