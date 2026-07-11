#!/bin/bash
# Benchmark Aggregation Tests - Validate telemetry aggregation and protocol health reporting

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/benchmark-aggregation-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

BRAIN_CONFIG="$ROOT_DIR/.opencode/brain-config.json"
AGG_SCRIPT="$ROOT_DIR/.opencode/scripts/aggregate-benchmark-telemetry.sh"
HEALTH_SCRIPT="$ROOT_DIR/.opencode/scripts/protocol-health-report.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Benchmark Aggregation Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

test_start "AGG-001" "Aggregation scripts exist and are wired in config"
assert_file_exists "$AGG_SCRIPT" "Benchmark aggregation script exists"
assert_file_exists "$HEALTH_SCRIPT" "Protocol health script exists"
assert_file_contains "$BRAIN_CONFIG" "\"aggregation\"" "brain-config defines aggregation metadata"
assert_file_contains "$BRAIN_CONFIG" "\"summary_script\"" "brain-config defines summary script"
assert_file_contains "$BRAIN_CONFIG" "\"health_script\"" "brain-config defines health script"

test_start "AGG-002" "Benchmark aggregation script produces a valid summary"
AGG_OUTPUT="$(bash "$AGG_SCRIPT")"
assert_output_contains "$AGG_OUTPUT" "Benchmark Telemetry Summary" "Aggregation summary header exists"
assert_output_contains "$AGG_OUTPUT" "Benchmark logs scanned:" "Aggregation counts logs"
assert_output_contains "$AGG_OUTPUT" "does not fabricate missing telemetry" "Aggregation states fabrication rule"

test_start "AGG-003" "Protocol health script produces a valid snapshot"
HEALTH_OUTPUT="$(bash "$HEALTH_SCRIPT")"
assert_output_contains "$HEALTH_OUTPUT" "Protocol Health Snapshot" "Health snapshot header exists"
assert_output_contains "$HEALTH_OUTPUT" "Benchmark cases:" "Health snapshot counts benchmark cases"
assert_output_contains "$HEALTH_OUTPUT" "Conformance suites:" "Health snapshot counts suites"

echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
