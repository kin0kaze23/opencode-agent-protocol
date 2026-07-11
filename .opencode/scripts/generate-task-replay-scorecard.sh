#!/usr/bin/env bash
# generate-task-replay-scorecard.sh — v4.44 Aggregate Task Replay Scorecard
#
# Aggregates all task replay results into a comparative scorecard.
# Shows pass rates, average scores by model, best model per task category,
# common failure patterns, and recommended routing changes.
#
# Output:
#   reports/task-replay-scorecard.md
#   reports/task-replay-scorecard.json
#
# Usage:
#   bash generate-task-replay-scorecard.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORTS_DIR="$WORKSPACE_ROOT/reports"
RESULTS_DIR="$WORKSPACE_ROOT/.opencode/evals/task-replay/results"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p "$REPORTS_DIR"

echo "=== Task Replay Scorecard Generation ==="
echo ""

# ─── Collect all result files ───────────────────────────────────────────
RESULT_FILES=()
if [[ -d "$RESULTS_DIR" ]]; then
  while IFS= read -r f; do
    RESULT_FILES+=("$f")
  done < <(find "$RESULTS_DIR" -name '*.json' -type f 2>/dev/null | sort)
fi

TOTAL_RESULTS=${#RESULT_FILES[@]}
echo "[scorecard] Found $TOTAL_RESULTS result files"

if [[ $TOTAL_RESULTS -eq 0 ]]; then
  echo "[scorecard] No results found. Run task replays first."
  echo "[scorecard] Use: bash run-task-replay-eval.sh --task <task_id> --record-result"
fi

# ─── Generate JSON scorecard ─────────────────────────────────────────────
JSON_SCORECARD="$REPORTS_DIR/task-replay-scorecard.json"

# Build results array
RESULTS_JSON="[]"
for f in "${RESULT_FILES[@]}"; do
  if jq empty "$f" 2>/dev/null; then
    RESULT_CONTENT=$(cat "$f")
    RESULTS_JSON=$(echo "$RESULTS_JSON" | jq --argjson result "$RESULT_CONTENT" '. + [$result]')
  fi
done

# Calculate aggregate stats
cat > "$JSON_SCORECARD" << EOF
{
  "generated_at": "$TIMESTAMP",
  "total_results": $TOTAL_RESULTS,
  "results": $RESULTS_JSON,
  "summary": $(echo "$RESULTS_JSON" | jq '{
    total_tasks: length,
    passed: [.[] | select(.pass == true)] | length,
    failed: [.[] | select(.pass == false)] | length,
    pass_rate: (if length > 0 then ([.[] | select(.pass == true)] | length) / length * 100 else 0 end),
    avg_score: (if length > 0 then ([.[] | .final_score // 0] | add / length) else 0 end),
    avg_repair_cycles: (if length > 0 then ([.[] | .repair_cycles // 0] | add / length) else 0 end),
    avg_reviewer_issues: (if length > 0 then ([.[] | .reviewer_issue_count // 0] | add / length) else 0 end)
  }'),
  "by_model": $(echo "$RESULTS_JSON" | jq 'group_by(.model) | map({
    model: .[0].model,
    count: length,
    avg_score: ([.[] | .final_score // 0] | add / length),
    pass_rate: ([.[] | select(.pass == true)] | length) / length * 100,
    avg_repair_cycles: ([.[] | .repair_cycles // 0] | add / length)
  })'),
  "by_task_type": $(echo "$RESULTS_JSON" | jq 'group_by(.task_type) | map({
    task_type: .[0].task_type,
    count: length,
    avg_score: ([.[] | .final_score // 0] | add / length),
    pass_rate: ([.[] | select(.pass == true)] | length) / length * 100
  })'),
  "by_task_id": $(echo "$RESULTS_JSON" | jq 'group_by(.task_id) | map({
    task_id: .[0].task_id,
    count: length,
    best_score: ([.[] | .final_score // 0] | max),
    best_model: (sort_by(.final_score) | last | .model // "N/A"),
    avg_score: ([.[] | .final_score // 0] | add / length)
  })'),
  "common_failures": $(echo "$RESULTS_JSON" | jq '[.[] | select(.pass == false)] | {
    total_failures: length,
    low_root_cause: [.[] | select(.scores.root_cause_correct <= 2)] | length,
    low_minimal_diff: [.[] | select(.scores.minimal_diff <= 2)] | length,
    low_test_quality: [.[] | select(.scores.test_quality <= 2)] | length,
    low_ci_success: [.[] | select(.scores.ci_success <= 2)] | length,
    low_security: [.[] | select(.scores.security_risk_handling <= 2)] | length,
    low_evidence: [.[] | select(.scores.evidence_quality <= 2)] | length,
    high_repair_cycles: [.[] | select(.repair_cycles > 1)] | length,
    high_reviewer_issues: [.[] | select(.reviewer_issue_count > 2)] | length
  }'),
  "recommendations": []
}
EOF

echo "[scorecard] JSON saved: $JSON_SCORECARD"

# ─── Generate markdown scorecard ─────────────────────────────────────────
MD_SCORECARD="$REPORTS_DIR/task-replay-scorecard.md"

# Extract summary stats
TOTAL_TASKS=$(jq -r '.summary.total_tasks // 0' "$JSON_SCORECARD")
PASSED=$(jq -r '.summary.passed // 0' "$JSON_SCORECARD")
FAILED=$(jq -r '.summary.failed // 0' "$JSON_SCORECARD")
PASS_RATE=$(jq -r '.summary.pass_rate // 0' "$JSON_SCORECARD")
AVG_SCORE=$(jq -r '.summary.avg_score // 0' "$JSON_SCORECARD")
AVG_REPAIR=$(jq -r '.summary.avg_repair_cycles // 0' "$JSON_SCORECARD")
AVG_REVIEWER=$(jq -r '.summary.avg_reviewer_issues // 0' "$JSON_SCORECARD")

cat > "$MD_SCORECARD" << EOF
# Task Replay Scorecard

> Generated: $TIMESTAMP
> Total results: $TOTAL_RESULTS

## Summary

| Metric | Value |
|--------|-------|
| Total tasks evaluated | $TOTAL_TASKS |
| Passed | $PASSED |
| Failed | $FAILED |
| Pass rate | ${PASS_RATE}% |
| Average score | $AVG_SCORE / 35 |
| Average repair cycles | $AVG_REPAIR |
| Average reviewer issues | $AVG_REVIEWER |

## Scores by Model

| Model | Tasks | Avg Score | Pass Rate | Avg Repair Cycles |
|-------|-------|-----------|-----------|-------------------|
$(jq -r '.by_model[] | "| \(.model) | \(.count) | \(.avg_score | floor) | \(.pass_rate | floor)% | \(.avg_repair_cycles | floor) |"' "$JSON_SCORECARD" 2>/dev/null || echo "| (no data) | | | | |")

## Scores by Task Type

| Task Type | Count | Avg Score | Pass Rate |
|-----------|-------|-----------|-----------|
$(jq -r '.by_task_type[] | "| \(.task_type) | \(.count) | \(.avg_score | floor) | \(.pass_rate | floor)% |"' "$JSON_SCORECARD" 2>/dev/null || echo "| (no data) | | | |")

## Best Model per Task

| Task ID | Best Score | Best Model | Avg Score |
|---------|-----------|------------|-----------|
$(jq -r '.by_task_id[] | "| \(.task_id) | \(.best_score) | \(.best_model) | \(.avg_score | floor) |"' "$JSON_SCORECARD" 2>/dev/null || echo "| (no data) | | | |")

## Common Failure Patterns

| Pattern | Count |
|---------|-------|
| Low root cause score (≤2) | $(jq -r '.common_failures.low_root_cause // 0' "$JSON_SCORECARD") |
| Low minimal diff (≤2) | $(jq -r '.common_failures.low_minimal_diff // 0' "$JSON_SCORECARD") |
| Low test quality (≤2) | $(jq -r '.common_failures.low_test_quality // 0' "$JSON_SCORECARD") |
| Low CI success (≤2) | $(jq -r '.common_failures.low_ci_success // 0' "$JSON_SCORECARD") |
| Low security handling (≤2) | $(jq -r '.common_failures.low_security // 0' "$JSON_SCORECARD") |
| Low evidence quality (≤2) | $(jq -r '.common_failures.low_evidence // 0' "$JSON_SCORECARD") |
| High repair cycles (>1) | $(jq -r '.common_failures.high_repair_cycles // 0' "$JSON_SCORECARD") |
| High reviewer issues (>2) | $(jq -r '.common_failures.high_reviewer_issues // 0' "$JSON_SCORECARD") |

## Recommendations

$(jq -r '.recommendations[]? // "No recommendations yet — run more replays to generate insights."' "$JSON_SCORECARD")

---

*Generated by generate-task-replay-scorecard.sh (v4.44)*
EOF

echo "[scorecard] Markdown saved: $MD_SCORECARD"
echo ""
echo "=== SCORECARD COMPLETE ==="
