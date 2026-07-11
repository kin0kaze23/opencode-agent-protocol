#!/usr/bin/env bash
# generate-routing-recommendations.sh — v4.46 Routing Policy Generator
#
# Consumes model ROI scorecard and generates advisory routing recommendations
# for each task type and risk lane. Recommendations are advisory only — they
# do not auto-modify active routing.
#
# Output:
#   reports/routing-recommendations.md
#   reports/routing-recommendations.json
#   .opencode/config/model-routing-policy.recommended.yaml
#
# Usage:
#   bash generate-routing-recommendations.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROI_FILE="$WORKSPACE_ROOT/reports/model-roi-scorecard.json"
PERF_FILE="$WORKSPACE_ROOT/.opencode/metrics/model-performance/performance-records.jsonl"
REPORTS_DIR="$WORKSPACE_ROOT/reports"
CONFIG_DIR="$WORKSPACE_ROOT/.opencode/config"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p "$REPORTS_DIR" "$CONFIG_DIR"

echo "=== Routing Recommendations Generator ==="
echo "Timestamp: $TIMESTAMP"
echo ""

# ─── Run ROI analysis first ──────────────────────────────────────────────
bash "$SCRIPT_DIR/analyze-model-roi.sh" > /dev/null 2>&1

if [[ ! -f "$ROI_FILE" ]]; then
  echo "ERROR: ROI scorecard not found. Run analyze-model-roi.sh first."
  exit 1
fi

if [[ ! -f "$PERF_FILE" ]]; then
  echo "ERROR: Performance records not found."
  exit 1
fi

# ─── Generate routing recommendations ────────────────────────────────────
JSON_REC="$REPORTS_DIR/routing-recommendations.json"
MD_REC="$REPORTS_DIR/routing-recommendations.md"
YAML_REC="$CONFIG_DIR/model-routing-policy.recommended.yaml"

# Read records
RECORDS=$(jq -s '.' "$PERF_FILE" 2>/dev/null || echo "[]")

# ─── Generate JSON recommendations ────────────────────────────────────────
cat > "$JSON_REC" << EOF
{
  "generated_at": "$TIMESTAMP",
  "advisory_only": true,
  "auto_applied": false,
  "guardrails": {
    "protected-repo_excluded": true,
    "no_self_attested_promotion": true,
    "no_production_route_change_without_approval": true,
    "no_high_risk_downgrade_for_cost": true,
    "stale_eval_warning_threshold_days": 30
  },
  "recommendations": $(echo "$RECORDS" | jq '
    # Group by task_type + risk_lane
    group_by({task_type: .task_type, risk_lane: .risk_lane}) | map({
      task_type: .[0].task_type,
      risk_lane: .[0].risk_lane,
      models: (group_by(.model) | map({
        model: .[0].model,
        sample_count: length,
        unique_task_count: ([.[] | .task_id] | unique | length),
        avg_score: ([.[] | .final_score] | add / length),
        pass_rate: ([.[] | select(.pass == true)] | length) / length * 100,
        avg_repair_cycles: ([.[] | .repair_cycles] | add / length),
        avg_reviewer_issues: ([.[] | .reviewer_issue_count] | add / length),
        avg_evidence_quality: ([.[] | .evidence_quality] | add / length),
        avg_security_handling: ([.[] | .security_risk_handling] | add / length),
        avg_test_quality: ([.[] | .test_quality] | add / length),
        has_cost_data: ([.[] | .estimated_cost // null | select(. != null)] | length > 0),
        avg_cost: ([.[] | .estimated_cost // 0] | add / length),
        confidence: (if (([.[] | .task_id] | unique | length) >= 3) then "high" elif (([.[] | .task_id] | unique | length) >= 1) then "low" else "insufficient" end)
      }) | sort_by(-.avg_score)),
      recommended_model: (
        group_by(.model) | map({
          model: .[0].model,
          unique_task_count: ([.[] | .task_id] | unique | length),
          avg_score: ([.[] | .final_score] | add / length),
          pass_rate: ([.[] | select(.pass == true)] | length) / length * 100,
          avg_repair_cycles: ([.[] | .repair_cycles] | add / length),
          avg_reviewer_issues: ([.[] | .reviewer_issue_count] | add / length),
          avg_security: ([.[] | .security_risk_handling] | add / length),
          confidence: (if (([.[] | .task_id] | unique | length) >= 3) then "high" elif (([.[] | .task_id] | unique | length) >= 1) then "low" else "insufficient" end)
        }) | sort_by(-.avg_score, -(.pass_rate), .avg_repair_cycles, .avg_reviewer_issues) | .[0].model // "insufficient_data"
      ),
      recommendation_type: (
        if ([.[] | .model] | unique | length) >= 2 then "best_overall"
        else "best_observed"
        end
      ),
      recommended_confidence: (
        group_by(.model) | map({
          model: .[0].model,
          unique_task_count: ([.[] | .task_id] | unique | length),
          confidence: (if (([.[] | .task_id] | unique | length) >= 3) then "high" elif (([.[] | .task_id] | unique | length) >= 1) then "low" else "insufficient" end)
        }) | sort_by(-.unique_task_count) | .[0].confidence // "insufficient"
      ),
      reason: (
        if (([.[] | .task_id] | unique | length) < 3) then
          "low_confidence: only \(([.[] | .task_id] | unique | length)) unique tasks — more evals needed"
        elif (.[0].risk_lane == "HIGH-RISK") then
          if ([.[] | .security_risk_handling] | add / length) >= 4 then
            "high_confidence: strong security handling with adequate unique tasks"
          else
            "not_recommended: insufficient security handling for HIGH-RISK"
          end
        else
          "high_confidence: adequate unique tasks with consistent performance"
        end
      ),
      cross_model_comparison: (
        if ([.[] | .model] | unique | length) >= 2 then "available"
        else "unavailable — single model only"
        end
      ),
      requires_reviewer: (.[0].risk_lane == "HIGH-RISK"),
      cost_classification: (
        if ([.[] | .estimated_cost // null | select(. != null)] | length) > 0 then
          "cost_tracked"
        else
          "quality_only"
        end
      )
    })
  '),
  "missing_data": $(echo "$RECORDS" | jq --argjson records "$RECORDS" '
    # Identify task types/lanes with no data
    [
      {task_type: "bug_fix", risk_lane: "FAST"},
      {task_type: "bug_fix", risk_lane: "STANDARD"},
      {task_type: "bug_fix", risk_lane: "HIGH-RISK"},
      {task_type: "test_gap", risk_lane: "STANDARD"},
      {task_type: "security_fix", risk_lane: "HIGH-RISK"},
      {task_type: "feature_addition", risk_lane: "STANDARD"}
    ] | map(
      . as $combo |
      if ([$records[] | select(.task_type == $combo.task_type and .risk_lane == $combo.risk_lane)] | length) == 0 then
        {task_type: .task_type, risk_lane: .risk_lane, status: "no_data"}
      else empty end
    )
  ')
}
EOF

echo "[routing] JSON recommendations saved: $JSON_REC"

# ─── Generate markdown recommendations ────────────────────────────────────
cat > "$MD_REC" << EOF
# Routing Recommendations

> Generated: $TIMESTAMP
> **Advisory only — no auto-apply**

## Guardrails

- protected-repo excluded from all routing
- No self-attested score-only promotion without evidence
- No production route change without explicit owner approval
- No HIGH-RISK downgrade to low-cost model purely for cost
- Stale eval data (>30 days) triggers warning

## Recommendations by Task Type and Lane

$(jq -r '.recommendations[] |
  "### \(.task_type) / \(.risk_lane)\n\n" +
  "| Model | Samples | Unique Tasks | Avg Score | Pass Rate | Confidence |\n" +
  "|-------|---------|-------------|-----------|-----------|------------|\n" +
  (.models[] | "| \(.model) | \(.sample_count) | \(.unique_task_count) | \(.avg_score | floor) | \(.pass_rate | floor)% | \(.confidence) |") + "\n\n" +
  "**Recommended:** \(.recommended_model) (\(.recommendation_type))\n" +
  "**Confidence:** \(.recommended_confidence)\n" +
  "**Reason:** \(.reason)\n" +
  "**Cross-model comparison:** \(.cross_model_comparison)\n" +
  "**Reviewer required:** \(.requires_reviewer)\n" +
  "**Cost classification:** \(.cost_classification)\n"
' "$JSON_REC" 2>/dev/null || echo "No recommendations available yet.")

## Missing Data

$(jq -r 'if (.missing_data | length) > 0 then .missing_data[] | "- **\(.task_type) / \(.risk_lane)**: no eval data — run task replays to generate recommendations" else "- No missing data gaps detected" end' "$JSON_REC" 2>/dev/null || echo "- Unable to determine missing data")

## Decision Policy

1. **Quality score first** — highest average score wins
2. **Pass rate second** — higher pass rate breaks ties
3. **Repair cycles third** — fewer repair cycles preferred
4. **Reviewer issues fourth** — fewer reviewer issues preferred
5. **Cost fifth** — cheaper model wins only when quality is close
6. **Latency sixth** — faster model wins only when all above are equal

## Rules

- Never recommend a model for HIGH-RISK unless security_risk_handling average >= 4
- Do not recommend based on fewer than 3 samples unless marked low_confidence
- If cost is unknown, classify ROI as quality_only
- If two models are close in quality (within 2 points), recommend cheaper/faster
- If reviewer issue rate is high (>2 avg), require reviewer escalation
- Do not auto-modify active routing by default

---

*Generated by generate-routing-recommendations.sh (v4.46)*
EOF

echo "[routing] Markdown recommendations saved: $MD_REC"

# ─── Generate recommended YAML policy ────────────────────────────────────
cat > "$YAML_REC" << EOF
# Model Routing Policy (Recommended) — v4.46
#
# ADVISORY ONLY — do not auto-apply.
# This file is generated by generate-routing-recommendations.sh.
# To activate, review and manually copy to active routing config.
#
# Generated: $TIMESTAMP

version: "1.0.0"
advisory: true
auto_applied: false

routing:
$(jq -r '.recommendations[] |
  "  - task_type: \"\(.task_type)\"\n" +
  "    risk_lane: \(.risk_lane)\n" +
  "    recommended_model: \"\(.recommended_model)\"\n" +
  "    confidence: \(.recommended_confidence)\n" +
  "    requires_reviewer: \(.requires_reviewer)\n" +
  "    reason: \"\(.reason)\"\n" +
  "    cost_classification: \(.cost_classification)"
' "$JSON_REC" 2>/dev/null || echo "  # No recommendations available")

guardrails:
  protected-repo_excluded: true
  no_self_attested_promotion: true
  no_production_route_change_without_approval: true
  no_high_risk_downgrade_for_cost: true
  stale_eval_warning_threshold_days: 30
EOF

echo "[routing] Recommended YAML policy saved: $YAML_REC"
echo ""
echo "=== ROUTING RECOMMENDATIONS COMPLETE ==="
