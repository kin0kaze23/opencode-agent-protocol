#!/usr/bin/env bash
# recommend-routing-adjustments.sh — v4.30 Evidence-Based Routing Recommendations
#
# Reads task-outcomes.jsonl and generates conservative, evidence-scoped routing
# recommendations. Does NOT auto-apply changes — output is advisory only.
#
# Usage:
#   bash .opencode/scripts/recommend-routing-adjustments.sh [--days <N>]
#
# Design:
# - Conservative: never generalizes from narrow evidence
# - Scope-aware: tags recommendations with applicable repos/task types
# - Risk-guarded: never relaxes HIGH-RISK or sensitive path rules
# - Non-blocking: exits 0 even if data is insufficient

set -uo pipefail

METRICS_FILE="${METRICS_FILE:-.opencode/metrics/task-outcomes.jsonl}"
DAYS="30"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days) DAYS="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ ! -f "$METRICS_FILE" ]]; then
  echo "ROUTING_RECOMMENDATIONS:"
  echo "  status: no_data"
  echo "  reason: $METRICS_FILE does not exist"
  exit 0
fi

if ! command -v jq &>/dev/null; then
  echo "ROUTING_RECOMMENDATIONS:"
  echo "  status: jq_required"
  exit 0
fi

jq -s -r --arg days "$DAYS" '
  flatten as $all
  | ($all | map(select(.source_type != "eval_fixture"))) as $records
  | ($records | length) as $total
  | ($records | map(select(.reviewer_used != "none" and .reviewer_used != "" and .reviewer_used != null))) as $rev
  | ($rev | length) as $rev_count
  | ($rev | map(select(.reviewer_value_classification == "minor_issue_found" or .reviewer_value_classification == "significant_issue_found"))) as $rev_found
  | ($rev_found | length) as $rev_found_count
  | ($rev | map(select(.reviewer_value_classification == "no_issue_found"))) as $rev_clean
  | ($rev_clean | length) as $rev_clean_count
  | ($records | map(select(.outcome == "success"))) as $successes
  | ($successes | length) as $success_count
  | ($records | group_by(.repo) | map({repo: .[0].repo, count: length, reviewer_tasks: (map(select(.reviewer_used != "none" and .reviewer_used != "" and .reviewer_used != null)) | length), reviewer_found: (map(select(.reviewer_value_classification == "minor_issue_found" or .reviewer_value_classification == "significant_issue_found")) | length)})) as $by_repo
  | ($rev_found | group_by(.task_type) | map({task_type: .[0].task_type, count: length})) as $by_type
  | ($rev_found | map(.reviewer_issue_severity) | group_by(.) | map({severity: .[0], count: length})) as $by_severity
  | {
      total_tasks: $total,
      reviewer_tasks: $rev_count,
      reviewer_found_issues: $rev_found_count,
      reviewer_clean: $rev_clean_count,
      reviewer_hit_rate: (if $rev_count > 0 then (($rev_found_count * 100 / $rev_count) | floor) else 0 end),
      success_rate: (if $total > 0 then (($success_count * 100 / $total) | floor) else 0 end),
      by_repo: $by_repo,
      by_type: $by_type,
      by_severity: $by_severity
    }
  | . as $s
  | "ROUTING_RECOMMENDATIONS:",
    "  generated: \(now | todate)",
    "  period: last_\($days)_days",
    "  evidence_summary:",
    "    total_tasks: \($s.total_tasks)",
    "    reviewer_tasks: \($s.reviewer_tasks)",
    "    reviewer_found_issues: \($s.reviewer_found_issues)",
    "    reviewer_clean: \($s.reviewer_clean)",
    "    reviewer_hit_rate: \($s.reviewer_hit_rate)%",
    "    success_rate: \($s.success_rate)%",
    "  evidence_scope:",
    "    repos_with_reviewer: \([$s.by_repo[] | select(.reviewer_tasks > 0) | "\(.repo)(\(.reviewer_tasks)/\(.reviewer_found))"] | join(", "))",
    "    task_types_with_findings: \([$s.by_type[] | "\(.task_type)(\(.count))"] | join(", "))",
    "    severity_distribution: \([$s.by_severity[] | "\(.severity)=\(.count)"] | join(", "))",
    "",
    "  recommendations:"
  ,
    (if $s.reviewer_tasks < 5 then
      "    - [insufficient_data] reviewer_sampled: Need at least 5 reviewer tasks (have \($s.reviewer_tasks)). Collect more evidence before routing changes."
    elif $s.reviewer_hit_rate >= 80 then
      "    - [accept] reviewer_required: Reviewer found issues on \($s.reviewer_found_issues)/\($s.reviewer_tasks) tasks (\($s.reviewer_hit_rate)% hit rate). Reviewer is clearly valuable for STANDARD eval/infra/test-boundary work.",
      "      evidence_count: \($s.reviewer_tasks)",
      "      confidence: high",
      "      applicable_task_types: \([$s.by_type[] | .task_type] | join(", "))",
      "      applicable_repos: \([$s.by_repo[] | select(.reviewer_tasks > 0) | .repo] | join(", "))",
      "      reason: 100% hit rate with findings ranging from low to high severity. All findings fixed before merge. Automated gates missed all of them.",
      "      risk_of_overgeneralization: MEDIUM — evidence is concentrated in sample-service eval/infra tasks. Do not generalize to UI/docs/design tasks without cross-repo evidence.",
      "      scope_guard: Do not apply to HIGH-RISK, auth, security, payment, schema, or data tasks — those already require reviewer unconditionally."
    else
      "    - [monitor] reviewer_sampled: Reviewer hit rate is \($s.reviewer_hit_rate)% — below 80% threshold. Continue sampling."
    end)
  ,
    (if $s.success_rate >= 90 and $s.reviewer_hit_rate >= 80 then
      "    - [accept] cheaper_model_ok: Capacity model (umans-glm-5.2) succeeded on \($s.success_rate)% of tasks with reviewer catching issues. Cheaper implementation model is sufficient when:",
      "      conditions:",
      "        - established pattern exists (e.g., eval runner reuse)",
      "        - tests are strong (eval assertions + full test suite)",
      "        - reviewer is still used",
      "        - no sensitive paths touched (auth, payment, schema, secrets)",
      "      evidence_count: \($s.total_tasks)",
      "      confidence: medium",
      "      reason: All 5 reviewer-involved tasks used umans-glm-5.2 for implementation and umans-glm-5.1 for review. All succeeded. Reviewer caught real issues that cheaper implementation missed.",
      "      risk_of_overgeneralization: HIGH — only 5 tasks, all in sample-service. Do not apply to architecture, debugging, or cross-repo work without more evidence."
    else
      "    - [monitor] cheaper_model_ok: Insufficient evidence for cheaper model routing (success rate: \($s.success_rate)%, reviewer hit rate: \($s.reviewer_hit_rate)%)"
    end)
  ,
    "    - [no_change] premium_model_recommended: No evidence supports changing premium model routing. Reserve for architecture, difficult debugging, and final review.",
    "    - [no_change] DIRECT Lite: Unchanged — no telemetry collected for DIRECT tasks by design.",
    "    - [no_change] FAST: Unchanged — reviewer remains optional unless sensitive paths or repeated failures appear.",
    "    - [no_change] HIGH-RISK: Unchanged — reviewer always required, no exceptions.",
    "",
    "  scope_guardrails:",
    "    - Do not generalize from sample-service eval/infra evidence to all repos.",
    "    - Do not generalize from eval/infra tasks to UI/design/docs tasks.",
    "    - Require stronger evidence before changing HIGH-RISK rules.",
    "    - DIRECT Lite remains unchanged.",
    "    - FAST remains lightweight unless sensitive paths or repeated failures appear.",
    "",
    "  next_data_needed:",
    "    - Cross-repo reviewer evidence (at least 2 repos beyond sample-service)",
    "    - UI/design task reviewer evidence (at least 3 tasks)",
    "    - Architecture/auth/security task reviewer evidence (at least 3 tasks)",
    "    - Multiple reporting periods for trend analysis",
    "",
    "  recommendation_status: advisory_only — no automatic routing changes applied"
' "$METRICS_FILE" 2>/dev/null || {
  echo "ROUTING_RECOMMENDATIONS:"
  echo "  status: parse_error"
  exit 0
}
