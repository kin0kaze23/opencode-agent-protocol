#!/usr/bin/env bash
# analyze-reviewer-calibration.sh — v4.49 Reviewer Calibration Analyzer
#
# Analyzes reviewer findings to measure reviewer usefulness, precision,
# false positive rate, and ROI across task types and risk lanes.
#
# Output:
#   reports/reviewer-calibration.md
#   reports/reviewer-calibration.json
#
# Usage: bash analyze-reviewer-calibration.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FINDINGS_FILE="$WORKSPACE_ROOT/.opencode/metrics/reviewer-calibration/reviewer-findings.jsonl"
DISAGREEMENTS_FILE="$WORKSPACE_ROOT/.opencode/metrics/reviewer-calibration/disagreements.jsonl"
REPORTS_DIR="$WORKSPACE_ROOT/reports"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p "$REPORTS_DIR"

echo "=== Reviewer Calibration Analyzer ==="
echo "Timestamp: $TIMESTAMP"
echo ""

if [[ ! -f "$FINDINGS_FILE" ]]; then
  echo "ERROR: Findings file not found: $FINDINGS_FILE"
  exit 1
fi

FINDING_COUNT=$(wc -l < "$FINDINGS_FILE" | tr -d ' ')
echo "[calibration] Found $FINDING_COUNT reviewer findings"

DISAGREEMENT_COUNT=0
if [[ -f "$DISAGREEMENTS_FILE" ]]; then
  DISAGREEMENT_COUNT=$(wc -l < "$DISAGREEMENTS_FILE" | tr -d ' ')
  echo "[calibration] Found $DISAGREEMENT_COUNT disagreements"
fi

# ─── Read findings into JSON array ──────────────────────────────────────
FINDINGS=$(jq -s '.' "$FINDINGS_FILE" 2>/dev/null || echo "[]")
DISAGREEMENTS=$(jq -s '.' "$DISAGREEMENTS_FILE" 2>/dev/null || echo "[]")

# ─── Generate JSON report ───────────────────────────────────────────────
JSON_REPORT="$REPORTS_DIR/reviewer-calibration.json"

cat > "$JSON_REPORT" << EOF
{
  "generated_at": "$TIMESTAMP",
  "total_findings": $FINDING_COUNT,
  "total_disagreements": $DISAGREEMENT_COUNT,
  "findings": $FINDINGS,
  "disagreements": $DISAGREEMENTS,
  "summary": $(echo "$FINDINGS" | jq '{
    total_findings: length,
    true_positives: [.[] | select(.outcome == "true_positive")] | length,
    false_positives: [.[] | select(.outcome == "false_positive")] | length,
    false_negatives: [.[] | select(.outcome == "false_negative")] | length,
    unresolved: [.[] | select(.outcome == "unresolved")] | length,
    true_positive_rate: (if length > 0 then ([.[] | select(.outcome == "true_positive")] | length) / length * 100 else 0 end),
    false_positive_rate: (if length > 0 then ([.[] | select(.outcome == "false_positive")] | length) / length * 100 else 0 end),
    repair_cycles_triggered: [.[] | select(.repair_cycle_triggered == true)] | length,
    avg_score_delta_after_fix: (if length > 0 then ([.[] | .score_delta_after_fix // 0] | add / length) else 0 end),
    unique_pr_count: ([.[] | .pr_number // empty] | unique | length),
    unique_task_count: ([.[] | .task_id] | unique | length),
    unique_repo_count: ([.[] | .repo] | unique | length),
    evidence_sources: ([.[] | .evidence_source // "unknown"] | unique),
    seed_findings_count: ([.[] | select(.evidence_source == "seed")] | length),
    real_findings_count: ([.[] | select(.evidence_source != "seed")] | length),
    minimum_sample_warning: (if ([.[] | select(.evidence_source != "seed")] | length) < 10 then true else false end),
    confidence_rationale: (if ([.[] | select(.evidence_source != "seed")] | length) < 10 then "low real-PR sample size (\([.[] | select(.evidence_source != "seed")] | length) real findings out of \(length) total) — recommendations are advisory only" else "adequate real-PR sample size (\([.[] | select(.evidence_source != "seed")] | length) real findings)" end)
  }'),
  "seed_data": $(echo "$FINDINGS" | jq '[.[] | select(.evidence_source == "seed")] | {
    count: length,
    true_positive_rate: (if length > 0 then ([.[] | select(.outcome == "true_positive")] | length) / length * 100 else 0 end),
    false_positive_rate: (if length > 0 then ([.[] | select(.outcome == "false_positive")] | length) / length * 100 else 0 end)
  }'),
  "real_data": $(echo "$FINDINGS" | jq '[.[] | select(.evidence_source != "seed")] | {
    count: length,
    true_positive_rate: (if length > 0 then ([.[] | select(.outcome == "true_positive")] | length) / length * 100 else 0 end),
    false_positive_rate: (if length > 0 then ([.[] | select(.outcome == "false_positive")] | length) / length * 100 else 0 end),
    unique_prs: ([.[] | .pr_number // empty] | unique | length),
    unique_repos: ([.[] | .repo] | unique | length)
  }'),
  "by_severity": $(echo "$FINDINGS" | jq 'group_by(.finding_severity) | map({
    severity: .[0].finding_severity,
    count: length,
    true_positive_rate: ([.[] | select(.outcome == "true_positive")] | length) / length * 100,
    false_positive_rate: ([.[] | select(.outcome == "false_positive")] | length) / length * 100
  })'),
  "by_category": $(echo "$FINDINGS" | jq 'group_by(.finding_category) | map({
    category: .[0].finding_category,
    count: length,
    true_positive_rate: ([.[] | select(.outcome == "true_positive")] | length) / length * 100,
    false_positive_rate: ([.[] | select(.outcome == "false_positive")] | length) / length * 100,
    avg_score_delta: ([.[] | .score_delta_after_fix // 0] | add / length)
  })'),
  "by_task_type": $(echo "$FINDINGS" | jq 'group_by(.task_type) | map({
    task_type: .[0].task_type,
    count: length,
    true_positive_rate: ([.[] | select(.outcome == "true_positive")] | length) / length * 100,
    false_positive_rate: ([.[] | select(.outcome == "false_positive")] | length) / length * 100,
    repair_cycles_triggered: [.[] | select(.repair_cycle_triggered == true)] | length
  })'),
  "by_risk_lane": $(echo "$FINDINGS" | jq 'group_by(.risk_lane) | map({
    risk_lane: .[0].risk_lane,
    count: length,
    true_positive_rate: ([.[] | select(.outcome == "true_positive")] | length) / length * 100,
    false_positive_rate: ([.[] | select(.outcome == "false_positive")] | length) / length * 100,
    avg_severity: ([.[] | .finding_severity] | length)
  })'),
  "by_reviewer_model": $(echo "$FINDINGS" | jq 'group_by(.reviewer_model) | map({
    reviewer_model: .[0].reviewer_model,
    count: length,
    true_positive_rate: ([.[] | select(.outcome == "true_positive")] | length) / length * 100,
    false_positive_rate: ([.[] | select(.outcome == "false_positive")] | length) / length * 100
  })'),
  "high_signal_categories": $(echo "$FINDINGS" | jq 'group_by(.finding_category) | map({
    category: .[0].finding_category,
    true_positive_rate: ([.[] | select(.outcome == "true_positive")] | length) / length * 100
  }) | map(select(.true_positive_rate >= 75)) | map(.category)'),
  "noisy_categories": $(echo "$FINDINGS" | jq 'group_by(.finding_category) | map({
    category: .[0].finding_category,
    false_positive_rate: ([.[] | select(.outcome == "false_positive")] | length) / length * 100
  }) | map(select(.false_positive_rate >= 50)) | map(.category)')
}
EOF

echo "[calibration] JSON report saved: $JSON_REPORT"

# ─── Generate markdown report ───────────────────────────────────────────
MD_REPORT="$REPORTS_DIR/reviewer-calibration.md"

TP_RATE=$(jq -r '.summary.true_positive_rate // 0' "$JSON_REPORT")
FP_RATE=$(jq -r '.summary.false_positive_rate // 0' "$JSON_REPORT")
TP_COUNT=$(jq -r '.summary.true_positives // 0' "$JSON_REPORT")
FP_COUNT=$(jq -r '.summary.false_positives // 0' "$JSON_REPORT")
REPAIR_CYCLES=$(jq -r '.summary.repair_cycles_triggered // 0' "$JSON_REPORT")
AVG_DELTA=$(jq -r '.summary.avg_score_delta_after_fix // 0' "$JSON_REPORT")

cat > "$MD_REPORT" << EOF
# Reviewer Calibration Report

> Generated: $TIMESTAMP
> Total findings: $FINDING_COUNT
> Total disagreements: $DISAGREEMENT_COUNT

$(jq -r 'if .summary.minimum_sample_warning then "> ⚠️ **Minimum sample warning**: \(.summary.confidence_rationale)" else "" end' "$JSON_REPORT" 2>/dev/null)

## Summary

| Metric | Value |
|--------|-------|
| Total findings | $FINDING_COUNT |
| True positives | $TP_COUNT |
| False positives | $FP_COUNT |
| True positive rate | ${TP_RATE}% |
| False positive rate | ${FP_RATE}% |
| Repair cycles triggered | $REPAIR_CYCLES |
| Avg score delta after fix | $AVG_DELTA |
| Unique PRs | $(jq -r '.summary.unique_pr_count // 0' "$JSON_REPORT") |
| Unique tasks | $(jq -r '.summary.unique_task_count // 0' "$JSON_REPORT") |
| Unique repos | $(jq -r '.summary.unique_repo_count // 0' "$JSON_REPORT") |
| Evidence sources | $(jq -r '.summary.evidence_sources | join(", ")' "$JSON_REPORT" 2>/dev/null) |

## Seed vs Real Data Separation

| Source | Count | TP Rate | FP Rate |
|--------|-------|---------|---------|
| Seed | $(jq -r '.seed_data.count // 0' "$JSON_REPORT") | $(jq -r '.seed_data.true_positive_rate // 0 | floor' "$JSON_REPORT")% | $(jq -r '.seed_data.false_positive_rate // 0 | floor' "$JSON_REPORT")% |
| Real PR | $(jq -r '.real_data.count // 0' "$JSON_REPORT") | $(jq -r '.real_data.true_positive_rate // 0 | floor' "$JSON_REPORT")% | $(jq -r '.real_data.false_positive_rate // 0 | floor' "$JSON_REPORT")% |

$(jq -r 'if (.real_data.count // 0) < 3 then "> ⚠️ **Low real-data sample**: Only \(.real_data.count // 0) real PR findings. Seed data should not drive policy alone." else "" end' "$JSON_REPORT" 2>/dev/null)
| Avg score delta after fix | $AVG_DELTA |

## Findings by Severity

| Severity | Count | TP Rate | FP Rate |
|----------|-------|---------|---------|
$(jq -r '.by_severity[] | "| \(.severity) | \(.count) | \(.true_positive_rate | floor)% | \(.false_positive_rate | floor)% |"' "$JSON_REPORT" 2>/dev/null || echo "| (no data) | | | |")

## Findings by Category

| Category | Count | TP Rate | FP Rate | Avg Score Delta |
|----------|-------|---------|---------|-----------------|
$(jq -r '.by_category[] | "| \(.category) | \(.count) | \(.true_positive_rate | floor)% | \(.false_positive_rate | floor)% | \(.avg_score_delta | floor) |"' "$JSON_REPORT" 2>/dev/null || echo "| (no data) | | | | |")

## Reviewer Usefulness by Task Type

| Task Type | Findings | TP Rate | FP Rate | Repair Cycles |
|-----------|----------|---------|---------|---------------|
$(jq -r '.by_task_type[] | "| \(.task_type) | \(.count) | \(.true_positive_rate | floor)% | \(.false_positive_rate | floor)% | \(.repair_cycles_triggered) |"' "$JSON_REPORT" 2>/dev/null || echo "| (no data) | | | | |")

## Reviewer Usefulness by Risk Lane

| Risk Lane | Findings | TP Rate | FP Rate |
|-----------|----------|---------|---------|
$(jq -r '.by_risk_lane[] | "| \(.risk_lane) | \(.count) | \(.true_positive_rate | floor)% | \(.false_positive_rate | floor)% |"' "$JSON_REPORT" 2>/dev/null || echo "| (no data) | | | |")

## High-Signal Categories (TP rate >= 75%)

$(jq -r 'if (.high_signal_categories | length) > 0 then .high_signal_categories[] | "- **\(.)**" else "- No high-signal categories yet" end' "$JSON_REPORT" 2>/dev/null || echo "- No data")

## Noisy Categories (FP rate >= 50%)

$(jq -r 'if (.noisy_categories | length) > 0 then .noisy_categories[] | "- **\(.)**" else "- No noisy categories detected" end' "$JSON_REPORT" 2>/dev/null || echo "- No data")

## Disagreements

$(if [[ $DISAGREEMENT_COUNT -gt 0 ]]; then
  jq -r '.disagreements[] | "- **\(.disagreement_id)**: \(.disagreement_type) — \(.description) (outcome: \(.outcome))"' "$JSON_REPORT" 2>/dev/null
else
  echo "- No disagreements recorded"
fi)

## Notes

- True positive rate measures how often reviewer findings are real issues
- False positive rate measures how often reviewer findings are noise
- High-signal categories have TP rate >= 75%
- Noisy categories have FP rate >= 50%
- Reviewer policy recommendations are generated separately by generate-reviewer-policy-recommendations.sh

---

*Generated by analyze-reviewer-calibration.sh (v4.49)*
EOF

echo "[calibration] Markdown report saved: $MD_REPORT"
echo ""
echo "=== CALIBRATION ANALYSIS COMPLETE ==="
