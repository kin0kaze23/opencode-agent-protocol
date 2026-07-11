#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VAULT_DIR="$ROOT_DIR/vault/projects"
OUT_PATH="${1:-}"

tmp_file=""
if [ -n "$OUT_PATH" ]; then
  tmp_file="$OUT_PATH"
else
  tmp_file="$(mktemp)"
fi

declare -a LOGS=()
while IFS= read -r log; do
  LOGS+=("$log")
done < <(find "$VAULT_DIR" -maxdepth 2 -name 'benchmark-log.md' | sort)

log_count="${#LOGS[@]}"
task_lines=0
lane_lines=0
rollback_yes=0
helper_lines=0
explorer_hits=0
planner_hits=0
implementer_hits=0
reviewer_hits=0
architect_hits=0

if [ "$log_count" -gt 0 ]; then
  for log in "${LOGS[@]}"; do
    task_lines=$((task_lines + $(grep -c "^- Task type:" "$log" 2>/dev/null || true)))
    lane_lines=$((lane_lines + $(grep -c "^- Lane:" "$log" 2>/dev/null || true)))
    rollback_yes=$((rollback_yes + $(grep -ci "^- Rollback used: yes" "$log" 2>/dev/null || true)))
    helper_lines=$((helper_lines + $(grep -c "^- Helpers:" "$log" 2>/dev/null || true)))
    explorer_hits=$((explorer_hits + $(grep -ci "Explorer" "$log" 2>/dev/null || true)))
    planner_hits=$((planner_hits + $(grep -ci "Planner" "$log" 2>/dev/null || true)))
    implementer_hits=$((implementer_hits + $(grep -ci "Implementer" "$log" 2>/dev/null || true)))
    reviewer_hits=$((reviewer_hits + $(grep -ci "Reviewer" "$log" 2>/dev/null || true)))
    architect_hits=$((architect_hits + $(grep -ci "Architect" "$log" 2>/dev/null || true)))
  done
fi

{
  echo "# Benchmark Telemetry Summary"
  echo
  echo "- Generated: $(date -Iseconds)"
  echo "- Benchmark logs scanned: $log_count"
  echo "- Observable task entries: $task_lines"
  echo "- Observable lane entries: $lane_lines"
  echo "- Rollback yes entries: $rollback_yes"
  echo "- Helper telemetry entries: $helper_lines"
  echo
  echo "## Helper usage hits"
  echo
  echo "- Explorer: $explorer_hits"
  echo "- Planner: $planner_hits"
  echo "- Implementer: $implementer_hits"
  echo "- Reviewer: $reviewer_hits"
  echo "- Architect: $architect_hits"
  echo
  echo "## Notes"
  echo
  echo "- This summary only counts observable benchmark-log lines."
  echo "- It does not fabricate missing telemetry."
  echo "- If no benchmark logs exist yet, this report stays valid and low-signal."
} > "$tmp_file"

if [ -n "$OUT_PATH" ]; then
  echo "Wrote benchmark telemetry summary to $OUT_PATH"
else
  cat "$tmp_file"
  rm -f "$tmp_file"
fi
