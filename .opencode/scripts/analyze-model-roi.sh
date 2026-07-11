#!/usr/bin/env bash
# analyze-model-roi.sh — v4.46 Model ROI Analyzer
#
# Consumes normalized model performance records and generates an ROI scorecard
# with quality, reliability, cost, and confidence metrics by model, task type,
# and risk lane.
#
# Output:
#   reports/model-roi-scorecard.md
#   reports/model-roi-scorecard.json
#
# Usage:
#   bash analyze-model-roi.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PERF_FILE="$WORKSPACE_ROOT/.opencode/metrics/model-performance/performance-records.jsonl"
REPORTS_DIR="$WORKSPACE_ROOT/reports"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p "$REPORTS_DIR"

echo "=== Model ROI Analyzer ==="
echo "Timestamp: $TIMESTAMP"
echo ""

# ─── Normalize first ─────────────────────────────────────────────────────
bash "$SCRIPT_DIR/normalize-model-performance.sh" > /dev/null 2>&1

if [[ ! -f "$PERF_FILE" ]]; then
  echo "ERROR: Performance records file not found: $PERF_FILE"
  echo "Run normalize-model-performance.sh first"
  exit 1
fi

RECORD_COUNT=$(wc -l < "$PERF_FILE" | tr -d ' ')
echo "[roi] Found $RECORD_COUNT performance records"
echo ""

if [[ $RECORD_COUNT -eq 0 ]]; then
  echo "[roi] No records found. Run task replays or loop simulations first."
fi

# ─── Generate JSON scorecard ─────────────────────────────────────────────
JSON_SCORECARD="$REPORTS_DIR/model-roi-scorecard.json"

# Read all records into a JSON array
RECORDS=$(jq -s '.' "$PERF_FILE" 2>/dev/null || echo "[]")

cat > "$JSON_SCORECARD" << EOF
{
  "generated_at": "$TIMESTAMP",
  "total_records": $RECORD_COUNT,
  "records": $RECORDS,
  "summary": $(echo "$RECORDS" | jq '{
    total_evals: length,
    total_pass: [.[] | select(.pass == true)] | length,
    total_fail: [.[] | select(.pass == false)] | length,
    pass_rate: (if length > 0 then ([.[] | select(.pass == true)] | length) / length * 100 else 0 end),
    avg_score: (if length > 0 then ([.[] | .final_score] | add / length) else 0 end),
    avg_repair_cycles: (if length > 0 then ([.[] | .repair_cycles] | add / length) else 0 end),
    avg_reviewer_issues: (if length > 0 then ([.[] | .reviewer_issue_count] | add / length) else 0 end),
    avg_evidence_quality: (if length > 0 then ([.[] | .evidence_quality] | add / length) else 0 end),
    avg_security_handling: (if length > 0 then ([.[] | .security_risk_handling] | add / length) else 0 end),
    record_count: length,
    unique_task_count: ([.[] | .task_id] | unique | length),
    unique_task_type_count: ([.[] | .task_type] | unique | length),
    unique_model_count: ([.[] | .model] | unique | length),
    result_type_count: ([.[] | .result_type] | unique | length),
    independent_run_count: ([.[] | {task_id, result_type}] | unique | length),
    single_model_warning: ([.[] | .model] | unique | length) <= 1,
    cross_model_comparison_available: ([.[] | .model] | unique | length) >= 2
  }'),
  "by_model": $(echo "$RECORDS" | jq 'group_by(.model) | map({
    model: .[0].model,
    sample_count: length,
    unique_task_count: ([.[] | .task_id] | unique | length),
    independent_run_count: ([.[] | {task_id, result_type}] | unique | length),
    avg_score: ([.[] | .final_score] | add / length),
    pass_rate: ([.[] | select(.pass == true)] | length) / length * 100,
    avg_repair_cycles: ([.[] | .repair_cycles] | add / length),
    avg_reviewer_issues: ([.[] | .reviewer_issue_count] | add / length),
    avg_evidence_quality: ([.[] | .evidence_quality] | add / length),
    avg_security_handling: ([.[] | .security_risk_handling] | add / length),
    avg_time_seconds: ([.[] | .time_seconds] | add / length),
    has_cost_data: ([.[] | .estimated_cost // null | select(. != null)] | length > 0),
    avg_cost: ([.[] | .estimated_cost // 0] | add / length),
    confidence: (if (([.[] | .task_id] | unique | length) >= 3) then "high" elif (([.[] | .task_id] | unique | length) >= 1) then "low" else "insufficient" end),
    confidence_rationale: (if (([.[] | .task_id] | unique | length) >= 3) then "adequate unique tasks" elif (([.[] | .task_id] | unique | length) >= 1) then "only \(([.[] | .task_id] | unique | length)) unique tasks — more needed" else "no data" end)
  })'),
  "by_task_type": $(echo "$RECORDS" | jq 'group_by(.task_type) | map({
    task_type: .[0].task_type,
    sample_count: length,
    avg_score: ([.[] | .final_score] | add / length),
    pass_rate: ([.[] | select(.pass == true)] | length) / length * 100,
    avg_repair_cycles: ([.[] | .repair_cycles] | add / length),
    best_model: (sort_by(-.final_score) | .[0].model // "N/A"),
    best_score: ([.[] | .final_score] | max)
  })'),
  "by_risk_lane": $(echo "$RECORDS" | jq 'group_by(.risk_lane) | map({
    risk_lane: .[0].risk_lane,
    sample_count: length,
    avg_score: ([.[] | .final_score] | add / length),
    pass_rate: ([.[] | select(.pass == true)] | length) / length * 100,
    avg_security_handling: ([.[] | .security_risk_handling] | add / length),
    best_model: (sort_by(-.final_score) | .[0].model // "N/A")
  })'),
  "by_result_type": $(echo "$RECORDS" | jq 'group_by(.result_type) | map({
    result_type: .[0].result_type,
    sample_count: length,
    avg_score: ([.[] | .final_score] | add / length),
    pass_rate: ([.[] | select(.pass == true)] | length) / length * 100
  })'),
  "roi_analysis": $(echo "$RECORDS" | jq 'group_by(.model) | map({
    model: .[0].model,
    sample_count: length,
    unique_task_count: ([.[] | .task_id] | unique | length),
    independent_run_count: ([.[] | {task_id, result_type}] | unique | length),
    quality_score: ([.[] | .final_score] | add / length),
    reliability_score: ([.[] | select(.pass == true)] | length) / length * 100,
    efficiency_score: (35 - ([.[] | .repair_cycles] | add / length) * 3),
    cost_classification: (if ([.[] | .estimated_cost // null | select(. != null)] | length) > 0 then "cost_tracked" else "quality_only" end),
    avg_cost: ([.[] | .estimated_cost // 0] | add / length),
    confidence: (if (([.[] | .task_id] | unique | length) >= 3) then "high" elif (([.[] | .task_id] | unique | length) >= 1) then "low" else "insufficient" end),
    confidence_rationale: (if (([.[] | .task_id] | unique | length) >= 3) then "adequate unique tasks (\(([.[] | .task_id] | unique | length)) unique tasks)" else "only \(([.[] | .task_id] | unique | length)) unique tasks — more needed for high confidence" end),
    is_best_observed: true,
    is_best_overall: (([.[] | .model] | unique | length) >= 2)
  })')
}
EOF

echo "[roi] JSON scorecard saved: $JSON_SCORECARD"

# ─── Generate markdown scorecard ────────────────────────────────────────
MD_SCORECARD="$REPORTS_DIR/model-roi-scorecard.md"

# Extract summary
TOTAL_EVALS=$(jq -r '.summary.total_evals // 0' "$JSON_SCORECARD")
PASS_RATE=$(jq -r '.summary.pass_rate // 0' "$JSON_SCORECARD")
AVG_SCORE=$(jq -r '.summary.avg_score // 0' "$JSON_SCORECARD")
AVG_REPAIR=$(jq -r '.summary.avg_repair_cycles // 0' "$JSON_SCORECARD")
AVG_EVIDENCE=$(jq -r '.summary.avg_evidence_quality // 0' "$JSON_SCORECARD")
AVG_SECURITY=$(jq -r '.summary.avg_security_handling // 0' "$JSON_SCORECARD")

cat > "$MD_SCORECARD" << EOF
# Model ROI Scorecard

> Generated: $TIMESTAMP
> Total records: $RECORD_COUNT

## Summary

| Metric | Value |
|--------|-------|
| Total evaluations | $TOTAL_EVALS |
| Pass rate | ${PASS_RATE}% |
| Average score | $AVG_SCORE / 35 |
| Average repair cycles | $AVG_REPAIR |
| Average evidence quality | $AVG_EVIDENCE / 5 |
| Average security handling | $AVG_SECURITY / 5 |
| Unique tasks | $(jq -r '.summary.unique_task_count // 0' "$JSON_SCORECARD") |
| Unique models | $(jq -r '.summary.unique_model_count // 0' "$JSON_SCORECARD") |
| Independent runs | $(jq -r '.summary.independent_run_count // 0' "$JSON_SCORECARD") |
| Cross-model comparison | $(jq -r 'if .summary.cross_model_comparison_available then "available" else "unavailable — single model only" end' "$JSON_SCORECARD") |

$(jq -r 'if .summary.single_model_warning then "> ⚠️ **Single-model warning**: Only one model has been evaluated. Recommendations are \"best observed\", not \"best overall\"." else "" end' "$JSON_SCORECARD")

## ROI by Model

| Model | Samples | Unique Tasks | Avg Score | Pass Rate | Avg Repair | Cost Class | Confidence | Rationale |
|-------|---------|-------------|-----------|-----------|------------|------------|------------|-----------|
$(jq -r '.roi_analysis[] | "| \(.model) | \(.sample_count) | \(.unique_task_count) | \(.quality_score | floor) | \(.reliability_score | floor)% | \(.efficiency_score | floor) | \(.cost_classification) | \(.confidence) | \(.confidence_rationale) |"' "$JSON_SCORECARD" 2>/dev/null || echo "| (no data) | | | | | | | | |")

## Performance by Task Type

| Task Type | Samples | Avg Score | Pass Rate | Best Model | Best Score |
|-----------|---------|-----------|-----------|------------|------------|
$(jq -r '.by_task_type[] | "| \(.task_type) | \(.sample_count) | \(.avg_score | floor) | \(.pass_rate | floor)% | \(.best_model) | \(.best_score) |"' "$JSON_SCORECARD" 2>/dev/null || echo "| (no data) | | | | | |")

## Performance by Risk Lane

| Risk Lane | Samples | Avg Score | Pass Rate | Avg Security | Best Model |
|-----------|---------|-----------|-----------|-------------|------------|
$(jq -r '.by_risk_lane[] | "| \(.risk_lane) | \(.sample_count) | \(.avg_score | floor) | \(.pass_rate | floor)% | \(.avg_security_handling | floor) | \(.best_model) |"' "$JSON_SCORECARD" 2>/dev/null || echo "| (no data) | | | | | |")

## Result Type Breakdown

| Result Type | Samples | Avg Score | Pass Rate |
|-------------|---------|-----------|-----------|
$(jq -r '.by_result_type[] | "| \(.result_type) | \(.sample_count) | \(.avg_score | floor) | \(.pass_rate | floor)% |"' "$JSON_SCORECARD" 2>/dev/null || echo "| (no data) | | | |")

## Confidence Assessment

$(jq -r '.roi_analysis[] | "- **\(.model)**: \(.confidence) confidence — \(.confidence_rationale) (\(.unique_task_count) unique tasks, \(.sample_count) records, \(.independent_run_count) independent runs)"' "$JSON_SCORECARD" 2>/dev/null || echo "- No data")

$(jq -r 'if .summary.single_model_warning then "## Cross-Model Comparison\n\n⚠️ **Unavailable** — only one model has been evaluated. Run cross-model evals to enable comparison." else "## Cross-Model Comparison\n\n✅ Multiple models evaluated — comparison available." end' "$JSON_SCORECARD")

## Notes

- Confidence is based on unique task count, not raw record count
- High confidence requires at least 3 unique tasks
- Single-model recommendations are "best observed", not "best overall"
- result_type prevents double-counting between replay and loop results
- Cost data is tracked when available; otherwise classified as quality_only
- HIGH-RISK tasks require strong security_risk_handling average for recommendation

---

*Generated by analyze-model-roi.sh (v4.47)*
EOF

echo "[roi] Markdown scorecard saved: $MD_SCORECARD"
echo ""
echo "=== ROI ANALYSIS COMPLETE ==="
