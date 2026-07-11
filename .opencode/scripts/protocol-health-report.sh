#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BENCH_DIR="$ROOT_DIR/.opencode/benchmarks"
CONFORMANCE_DIR="$ROOT_DIR/.opencode/conformance/tests"
OUT_PATH="${1:-}"

tmp_file=""
if [ -n "$OUT_PATH" ]; then
  tmp_file="$OUT_PATH"
else
  tmp_file="$(mktemp)"
fi

case_count=$(find "$BENCH_DIR/cases" -type f -name '*.md' | wc -l | tr -d ' ')
adversarial_count=$(find "$BENCH_DIR/adversarial" -type f -name '*.md' | wc -l | tr -d ' ')
simulation_count=$(find "$BENCH_DIR/simulations" -type f -name '*.md' | wc -l | tr -d ' ')
helper_roi_count=$(find "$BENCH_DIR/helper-roi" -type f -name '*.md' | wc -l | tr -d ' ')
suite_count=$(find "$CONFORMANCE_DIR" -maxdepth 1 -type f -name '*.sh' | wc -l | tr -d ' ')

{
  echo "# Protocol Health Snapshot"
  echo
  echo "- Generated: $(date -Iseconds)"
  echo "- Benchmark cases: $case_count"
  echo "- Adversarial fixtures: $adversarial_count"
  echo "- Runtime simulations: $simulation_count"
  echo "- Helper ROI probes: $helper_roi_count"
  echo "- Conformance suites: $suite_count"
  echo
  echo "## Interpretation"
  echo
  echo "- This is a structural health snapshot, not a runtime success-rate report."
  echo "- Combine it with benchmark-log aggregation for actual task telemetry."
} > "$tmp_file"

if [ -n "$OUT_PATH" ]; then
  echo "Wrote protocol health snapshot to $OUT_PATH"
else
  cat "$tmp_file"
  rm -f "$tmp_file"
fi
