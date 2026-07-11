#!/bin/bash
# Benchmarking Ops Tests - Measurement, adversarial fixtures, and ROI telemetry contracts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/benchmarking-ops-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

BENCH_DIR="$ROOT_DIR/.opencode/benchmarks"
README_FILE="$BENCH_DIR/README.md"
SCHEMA_FILE="$BENCH_DIR/case-schema.md"
BRAIN_CONFIG="$ROOT_DIR/.opencode/brain-config.json"
CHECKPOINT="$ROOT_DIR/.opencode/commands/checkpoint.md"
GATES="$ROOT_DIR/.opencode/commands/gates.md"
RULES="$ROOT_DIR/.opencode/rules.md"

echo "=========================================="
echo "Protocol Conformance Suite - Benchmarking Ops Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

test_start "BMK-001" "Benchmark rubric and case schema exist"
assert_file_exists "$README_FILE" "Benchmark README exists"
assert_file_exists "$SCHEMA_FILE" "Benchmark case schema exists"
assert_file_contains "$README_FILE" "correctness" "Rubric includes correctness"
assert_file_contains "$README_FILE" "evidence_quality" "Rubric includes evidence quality"
assert_file_contains "$SCHEMA_FILE" "expected files touched" "Schema includes expected files touched"

test_start "BMK-002" "Seed corpus exists across task types"
for bucket in feature hotfix refactor research deploy design; do
  COUNT=$(find "$BENCH_DIR/cases/$bucket" -type f -name '*.md' | wc -l | tr -d ' ')
  assert_equals "4" "$COUNT" "Gold corpus count for $bucket"
done

test_start "BMK-003" "Adversarial fixtures exist"
ADVERSARIAL_COUNT=$(find "$BENCH_DIR/adversarial" -type f -name '*.md' | wc -l | tr -d ' ')
assert_equals "6" "$ADVERSARIAL_COUNT" "Adversarial fixture count"
assert_file_contains "$RULES" "## Adversarial Validation" "Rules define adversarial validation"
assert_file_contains "$BENCH_DIR/adversarial/SENSITIVE-SAST-001.md" "SAST" "Sensitive SAST fixture exists"

test_start "BMK-004" "Helper ROI probes exist"
for helper in EXPLORER PLANNER IMPLEMENTER REVIEWER ARCHITECT; do
  assert_file_exists "$BENCH_DIR/helper-roi/$helper.md" "Helper ROI probe exists: $helper"
done
assert_file_contains "$RULES" "Helper ROI is helper-specific" "Rules describe helper-specific ROI"

test_start "BMK-005" "Runtime simulations and aggregation support exist"
SIM_COUNT=$(find "$BENCH_DIR/simulations" -type f -name '*.md' | wc -l | tr -d ' ')
assert_equals "4" "$SIM_COUNT" "Runtime simulation count"
assert_file_exists "$ROOT_DIR/.opencode/scripts/run-runtime-simulations.sh" "Runtime simulation runner exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/aggregate-benchmark-telemetry.sh" "Aggregation runner exists"
assert_file_contains "$BRAIN_CONFIG" "\"runtime_simulations\"" "brain-config defines runtime simulations"
assert_file_contains "$BRAIN_CONFIG" "\"aggregation\"" "brain-config defines aggregation support"

test_start "BMK-006" "Checkpoint benchmark telemetry is documented"
assert_file_contains "$CHECKPOINT" "benchmark-log.md" "Checkpoint persists benchmark log"
assert_file_contains "$CHECKPOINT" "Benchmark telemetry:" "Checkpoint outputs benchmark telemetry"
assert_file_contains "$BRAIN_CONFIG" "\"checkpoint_telemetry\"" "brain-config defines benchmark telemetry"

test_start "BMK-007" "Scoped SAST is enforced for sensitive work"
assert_file_contains "$GATES" "scoped SAST when required" "Gates include scoped SAST"
assert_file_contains "$BRAIN_CONFIG" "\"scoped_triggers\"" "brain-config defines scoped SAST triggers"
assert_file_contains "$BRAIN_CONFIG" "\"blocking\": true" "Scoped SAST is blocking"

echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
