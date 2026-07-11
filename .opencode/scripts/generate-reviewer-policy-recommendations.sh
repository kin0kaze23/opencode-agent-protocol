#!/usr/bin/env bash
# generate-reviewer-policy-recommendations.sh — v4.49 Reviewer Policy Generator
#
# Consumes reviewer calibration data and generates advisory policy recommendations
# for when reviewer should be required, recommended, or optional by task type and lane.
#
# Output:
#   reports/reviewer-policy-recommendations.md
#   reports/reviewer-policy-recommendations.json
#   .opencode/config/reviewer-policy.recommended.yaml
#
# Usage: bash generate-reviewer-policy-recommendations.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FINDINGS_FILE="$WORKSPACE_ROOT/.opencode/metrics/reviewer-calibration/reviewer-findings.jsonl"
REPORTS_DIR="$WORKSPACE_ROOT/reports"
CONFIG_DIR="$WORKSPACE_ROOT/.opencode/config"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p "$REPORTS_DIR" "$CONFIG_DIR"

echo "=== Reviewer Policy Recommendations Generator ==="
echo "Timestamp: $TIMESTAMP"
echo ""

# ─── Run calibration analysis first ──────────────────────────────────────
bash "$SCRIPT_DIR/analyze-reviewer-calibration.sh" > /dev/null 2>&1

if [[ ! -f "$FINDINGS_FILE" ]]; then
  echo "ERROR: Findings file not found: $FINDINGS_FILE"
  exit 1
fi

FINDINGS=$(jq -s '.' "$FINDINGS_FILE" 2>/dev/null || echo "[]")

# ─── Generate JSON recommendations ───────────────────────────────────────
JSON_REC="$REPORTS_DIR/reviewer-policy-recommendations.json"
MD_REC="$REPORTS_DIR/reviewer-policy-recommendations.md"
YAML_REC="$CONFIG_DIR/reviewer-policy.recommended.yaml"

cat > "$JSON_REC" << EOF
{
  "generated_at": "$TIMESTAMP",
  "advisory_only": true,
  "auto_applied": false,
  "guardrails": {
    "high_risk_remains_required": true,
    "security_auth_deployment_conservative": true,
    "no_auto_change_active_policy": true,
    "protected-repo_excluded": true
  },
  "recommendations": $(echo "$FINDINGS" | jq '
    # Group by task_type + risk_lane
    group_by({task_type: .task_type, risk_lane: .risk_lane}) | map({
      task_type: .[0].task_type,
      risk_lane: .[0].risk_lane,
      finding_count: length,
      true_positive_rate: ([.[] | select(.outcome == "true_positive")] | length) / length * 100,
      false_positive_rate: ([.[] | select(.outcome == "false_positive")] | length) / length * 100,
      repair_cycles_triggered: [.[] | select(.repair_cycle_triggered == true)] | length,
      avg_score_delta: ([.[] | .score_delta_after_fix // 0] | add / length),
      evidence_sources: ([.[] | .evidence_source // "unknown"] | unique),
      seed_only: (([.[] | .evidence_source // "unknown"] | unique | length == 1) and ([.[] | .evidence_source // "unknown"] | unique | .[0] == "seed")),
      real_finding_count: ([.[] | select(.evidence_source != "seed")] | length),
      recommended_reviewer_setting: (
        if (.[0].risk_lane == "HIGH-RISK") then "required"
        elif (([.[] | select(.outcome == "true_positive")] | length) / length * 100) >= 75 then "required"
        elif (([.[] | select(.outcome == "false_positive")] | length) / length * 100) >= 50 then "optional"
        else "recommended"
        end
      ),
      confidence: (
        if (.[0].risk_lane == "HIGH-RISK") then "high"
        elif (([.[] | select(.evidence_source != "seed")] | length) >= 3) then "high"
        elif (([.[] | select(.evidence_source != "seed")] | length) >= 1) then "low"
        else "low"
        end
      ),
      minimum_sample_warning: (if length < 5 then true else false end),
      reason: (
        if (.[0].risk_lane == "HIGH-RISK") then
          "HIGH-RISK lane always requires reviewer"
        elif (([.[] | .evidence_source // "unknown"] | unique | length == 1) and ([.[] | .evidence_source // "unknown"] | unique | .[0] == "seed")) then
          "seed_data_only — low confidence, needs real PR validation"
        elif (([.[] | select(.outcome == "true_positive")] | length) / length * 100) >= 75 then
          "high true positive rate — reviewer adds significant value"
        elif (([.[] | select(.outcome == "false_positive")] | length) / length * 100) >= 50 then
          "high false positive rate — reviewer may be optional for this task type"
        else
          "moderate signal — reviewer recommended"
        end
      )
    })
  '),
  "category_insights": $(echo "$FINDINGS" | jq 'group_by(.finding_category) | map({
    category: .[0].finding_category,
    count: length,
    true_positive_rate: ([.[] | select(.outcome == "true_positive")] | length) / length * 100,
    signal: (if (([.[] | select(.outcome == "true_positive")] | length) / length * 100) >= 75 then "high_signal" elif (([.[] | select(.outcome == "false_positive")] | length) / length * 100) >= 50 then "noisy" else "moderate" end)
  })')
}
EOF

echo "[policy] JSON recommendations saved: $JSON_REC"

# ─── Generate markdown ───────────────────────────────────────────────────
cat > "$MD_REC" << EOF
# Reviewer Policy Recommendations

> Generated: $TIMESTAMP
> **Advisory only — no auto-apply**

## Guardrails

- HIGH-RISK tasks always require reviewer
- Security/auth/deployment changes remain conservative
- No auto-change to active reviewer policy
- protected-repo excluded

## Recommendations by Task Type and Lane

$(jq -r '.recommendations[] |
  "### \(.task_type) / \(.risk_lane)\n\n" +
  "| Metric | Value |\n" +
  "|--------|--------|\n" +
  "| Findings | \(.finding_count) |\n" +
  "| TP Rate | \(.true_positive_rate | floor)% |\n" +
  "| FP Rate | \(.false_positive_rate | floor)% |\n" +
  "| Repair Cycles | \(.repair_cycles_triggered) |\n" +
  "| Avg Score Delta | \(.avg_score_delta | floor) |\n\n" +
  "**Recommended setting:** \(.recommended_reviewer_setting)\n" +
  "**Reason:** \(.reason)\n"
' "$JSON_REC" 2>/dev/null || echo "No recommendations available yet.")

## Category Insights

| Category | Count | TP Rate | Signal |
|----------|-------|---------|--------|
$(jq -r '.category_insights[] | "| \(.category) | \(.count) | \(.true_positive_rate | floor)% | \(.signal) |"' "$JSON_REC" 2>/dev/null || echo "| (no data) | | | |")

## Rules

- HIGH-RISK always requires reviewer — no exceptions
- If TP rate >= 75%, reviewer is required (high value)
- If FP rate >= 50%, reviewer is optional (noisy for this task type)
- Otherwise, reviewer is recommended
- Security, auth, and deployment changes remain conservative
- No auto-change to active reviewer policy

---

*Generated by generate-reviewer-policy-recommendations.sh (v4.49)*
EOF

echo "[policy] Markdown recommendations saved: $MD_REC"

# ─── Generate YAML policy ────────────────────────────────────────────────
cat > "$YAML_REC" << EOF
# Reviewer Policy (Recommended) — v4.49
#
# ADVISORY ONLY — do not auto-apply.
# Generated by generate-reviewer-policy-recommendations.sh
#
# Generated: $TIMESTAMP

version: "1.0.0"
advisory: true
auto_applied: false

guardrails:
  high_risk_always_required: true
  security_auth_deployment_conservative: true
  no_auto_change: true
  protected-repo_excluded: true

policy:
$(jq -r '.recommendations[] |
  "  - task_type: \"\(.task_type)\"\n" +
  "    risk_lane: \(.risk_lane)\n" +
  "    reviewer_setting: \(.recommended_reviewer_setting)\n" +
  "    reason: \"\(.reason)\"\n" +
  "    tp_rate: \(.true_positive_rate | floor)\n" +
  "    fp_rate: \(.false_positive_rate | floor)"
' "$JSON_REC" 2>/dev/null || echo "  # No recommendations available")
EOF

echo "[policy] YAML policy saved: $YAML_REC"
echo ""
echo "=== POLICY RECOMMENDATIONS COMPLETE ==="
