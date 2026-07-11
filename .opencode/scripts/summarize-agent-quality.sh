#!/usr/bin/env bash
# summarize-agent-quality.sh — Quality scorecard from task outcome telemetry (v4.29)
#
# Usage:
#   bash .opencode/scripts/summarize-agent-quality.sh [--days <N>] [--repo <repo>]
#
# Reads .opencode/metrics/task-outcomes.jsonl and produces a summary.
# Requires jq for JSON parsing.
# Non-blocking: exits 0 even if no data is available.

set -uo pipefail

METRICS_FILE="${METRICS_FILE:-.opencode/metrics/task-outcomes.jsonl}"
DAYS="30"
REPO_FILTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days) DAYS="$2"; shift 2 ;;
    --repo) REPO_FILTER="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ ! -f "$METRICS_FILE" ]]; then
  echo "AGENT_QUALITY_SCORECARD:"
  echo "  status: no_data"
  echo "  reason: $METRICS_FILE does not exist yet"
  echo "  recommendation: Run tasks and record outcomes to populate telemetry"
  exit 0
fi

if ! command -v jq &>/dev/null; then
  echo "AGENT_QUALITY_SCORECARD:"
  echo "  status: jq_required"
  echo "  reason: jq is required for JSON parsing"
  echo "  install: brew install jq"
  exit 0
fi

RECORD_COUNT=$(wc -l < "$METRICS_FILE" | tr -d ' ')

if [[ "$RECORD_COUNT" -eq 0 ]]; then
  echo "AGENT_QUALITY_SCORECARD:"
  echo "  status: empty"
  echo "  reason: No task outcomes recorded yet"
  exit 0
fi

# v4.29.1: Sample-size guardrails
# Do not generate routing recommendations from low sample sizes
MIN_TASKS_FOR_ROUTING=10
MIN_TASKS_PER_TYPE=5

# v4.29.2: Distinguish fixture vs real data
DATA_SOURCE="real"
case "$METRICS_FILE" in
  *fixtures*|*sample*) DATA_SOURCE="fixture" ;;
esac

# Use jq -s to slurp all records into an array, then compute summary
# v4.29.4: Filter out eval_fixture records from production routing thresholds
# v4.29.4: Weight evidence_level for confidence-sensitive metrics
jq -s -r --arg days "$DAYS" --argjson min_tasks "$MIN_TASKS_FOR_ROUTING" --argjson min_per_type "$MIN_TASKS_PER_TYPE" --arg env_data_source "$DATA_SOURCE" '
  # Flatten any nested arrays from multi-line JSON
  flatten
  # v4.29.4: Separate production records from eval fixtures
  | . as $all
  | (map(select(.source_type != "eval_fixture")) as $prod
    | $prod) as $records
  # v4.29.4: Evidence-weighted subsets for confidence-sensitive metrics
  | ($records | map(select(.evidence_level == "full" or .evidence_level == null or .evidence_level == ""))) as $full_ev
  | ($records | map(select(.evidence_level == "partial"))) as $partial_ev
  | {
      period: ("last_" + $days + "_days"),
      tasks_count: ($records | length),
      all_records_count: ($all | length),
      eval_fixture_excluded: ($all | map(select(.source_type == "eval_fixture")) | length),
      success_count: ($records | map(select(.outcome == "success")) | length),
      partial_count: ($records | map(select(.outcome == "partial")) | length),
      failed_count: ($records | map(select(.outcome == "failed" or .outcome == "reverted")) | length),
      ci_first_try_count: ($records | map(select(.ci_first_try == "true")) | length),
      ci_first_try_known: ($records | map(select(.ci_first_try != "unknown" and .ci_first_try != null and .ci_first_try != "")) | length),
      # v4.29.4: Confidence-weighted CI first-pass (full evidence only)
      ci_first_try_full: ($full_ev | map(select(.ci_first_try == "true")) | length),
      ci_first_try_full_known: ($full_ev | map(select(.ci_first_try != "unknown" and .ci_first_try != null and .ci_first_try != "")) | length),
      total_repair_cycles: ($records | map(.repair_cycles // 0) | add // 0),
      reviewer_tasks: ($records | map(select(.reviewer_used != "none" and .reviewer_used != "" and .reviewer_used != null)) | length),
      reviewer_found_issues: ($records | map(select((.reviewer_used != "none" and .reviewer_used != "" and .reviewer_used != null) and (.reviewer_value_classification == "minor_issue_found" or .reviewer_value_classification == "significant_issue_found"))) | length),
      premium_tasks: ($records | map(select(.premium_model_used != "none" and .premium_model_used != "" and .premium_model_used != null)) | length),
      tasks_with_tests: ($records | map(select((.tests_added_or_updated // 0) > 0)) | length),
      tasks_without_tests: ($records | map(select((.tests_added_or_updated // 0) == 0)) | length),
      pattern_memory_used: ($records | map(select(.pattern_memory_used == "true")) | length),
      project_memory_used: ($records | map(select(.project_memory_used == "true")) | length),
      accepted: ($records | map(select(.human_acceptance == "accepted")) | length),
      revised: ($records | map(select(.human_acceptance == "revised")) | length),
      rejected: ($records | map(select(.human_acceptance == "rejected")) | length),
      unknown_acceptance: ($records | map(select(.human_acceptance == "unknown" or .human_acceptance == null or .human_acceptance == "")) | length),
      failures_by_type: (
        $records
        | map(select(.outcome != "success"))
        | group_by(.task_type)
        | map({task_type: .[0].task_type, failure_count: length})
        | sort_by(-.failure_count)
      ),
      models_used: (
        $records
        | group_by(.model_used)
        | map({model: .[0].model_used, tasks: length, successes: (map(select(.outcome == "success")) | length)})
        | sort_by(-.tasks)
      ),
      # v4.29.3: collection mode and evidence breakdown
      live_count: ($records | map(select(.collection_mode == "live" or .collection_mode == null or .collection_mode == "")) | length),
      retrospective_count: ($records | map(select(.collection_mode == "retrospective")) | length),
      synthetic_count: ($records | map(select(.collection_mode == "synthetic_eval")) | length),
      full_evidence: ($records | map(select(.evidence_level == "full" or .evidence_level == null or .evidence_level == "")) | length),
      partial_evidence: ($records | map(select(.evidence_level == "partial")) | length),
      # v4.29.4: source type breakdown
      source_live: ($records | map(select(.source_type == "live" or .source_type == null or .source_type == "")) | length),
      source_retrospective: ($records | map(select(.source_type == "retrospective")) | length),
      source_eval_fixture: ($all | map(select(.source_type == "eval_fixture")) | length),
      # v4.29.3: distributions
      repo_distribution: ($records | group_by(.repo) | map({repo: .[0].repo, count: length}) | sort_by(-.count)),
      lane_distribution: ($records | group_by(.lane) | map({lane: .[0].lane, count: length}) | sort_by(-.count)),
      task_type_distribution: ($records | group_by(.task_type) | map({task_type: .[0].task_type, count: length}) | sort_by(-.count)),
      # v4.29.3: non-perfect outcomes for failure analysis
      ci_failures: ($records | map(select(.ci_status == "failed")) | length),
      non_perfect_outcomes: ($records | map(select(.outcome != "success" or .ci_status == "failed" or (.repair_cycles // 0) > 0)) | length),
      # v4.29.4: confidence metrics (full evidence only)
      confidence_full_count: ($full_ev | length),
      confidence_partial_count: ($partial_ev | length),
      confidence_weight: (if ($records | length) > 0 then (($full_ev | length) / ($records | length) * 100 | floor) else 0 end)
    }
  | . as $s
  | ($s.tasks_count // 0) as $tc
  | ($s.success_count // 0) as $sc
  | ($s.ci_first_try_known // 0) as $cftk
  | ($s.ci_first_try_count // 0) as $cftc
  | ($s.total_repair_cycles // 0) as $trc
  | (if $tc > 0 then (($sc * 100 / $tc) | floor) else 0 end) as $sr
  | (if $cftk > 0 then (($cftc * 100 / $cftk) | floor) else 0 end) as $cfpr
  | (if $tc > 0 then (($trc / $tc) | floor) else 0 end) as $arc
  # v4.29.4: Confidence-weighted CI first-pass rate (full evidence only)
  | (if ($s.ci_first_try_full_known // 0) > 0 then (($s.ci_first_try_full // 0) * 100 / ($s.ci_first_try_full_known // 1) | floor) else 0 end) as $cfpr_conf
  | "AGENT_QUALITY_SCORECARD:",
    "  period: \($s.period)",
    "  data_source: \($env_data_source)",
    "  tasks_count: \($tc)",
    "  eval_fixtures_excluded: \($s.eval_fixture_excluded)",
    "  source_type: live=\($s.source_live), retrospective=\($s.source_retrospective), eval_fixture=\($s.source_eval_fixture)",
    "  collection_mode: live=\($s.live_count), retrospective=\($s.retrospective_count), synthetic=\($s.synthetic_count)",
    "  evidence_level: full=\($s.full_evidence), partial=\($s.partial_evidence)",
    "  confidence_weight: \($s.confidence_weight)% full-evidence (\($s.confidence_full_count) full, \($s.confidence_partial_count) partial)",
    "  success_rate: \($sr)%",
    "  ci_first_pass_rate: \($cfpr)% (all evidence)",
    "  ci_first_pass_rate_confidence: \($cfpr_conf)% (full evidence only)",
    "  avg_repair_cycles: \($arc)",
    "  reviewer_value: \($s.reviewer_tasks) tasks with reviewer, \($s.reviewer_found_issues) found issues",
    "  model_roi: \($s.models_used | length) models used, \($s.premium_tasks) premium tasks",
    "  test_quality_signal: \($s.tasks_with_tests) with tests, \($s.tasks_without_tests) without",
    "  memory_reuse: pattern=\($s.pattern_memory_used), project=\($s.project_memory_used)",
    "  recurring_failure_patterns: \($s.failures_by_type | length) types with failures",
    "  human_acceptance: accepted=\($s.accepted), revised=\($s.revised), rejected=\($s.rejected), unknown=\($s.unknown_acceptance)",
    "  distributions:",
    "    repos: \([$s.repo_distribution[] | "\(.repo)=\(.count)"] | join(", "))",
    "    lanes: \([$s.lane_distribution[] | "\(.lane)=\(.count)"] | join(", "))",
    "    types: \([$s.task_type_distribution[] | "\(.task_type)=\(.count)"] | join(", "))",
    "  thresholds:",
    "    total: \($tc)/\($min_tasks) \((if $tc >= $min_tasks then "✓" else "✗" end))",
    "    reviewer: \($s.reviewer_tasks)/5 \((if $s.reviewer_tasks >= 5 then "✓" else "✗" end))",
    "    non_perfect: \($s.non_perfect_outcomes)/3 \((if $s.non_perfect_outcomes >= 3 then "✓" else "✗" end))",
    "    per_type_max: \([$s.task_type_distribution[] | .count] | max)/\($min_per_type) \((if ([$s.task_type_distribution[] | .count] | max) >= $min_per_type then "✓" else "✗" end))",
    (if $tc < $min_tasks then
      "  recommendations: insufficient data — collect at least \($min_tasks) task outcomes before routing changes (current: \($tc))"
    elif ($s.failures_by_type | length) > 0 then
      "  recommendations:",
      ($s.failures_by_type
        | map(select(.failure_count >= $min_per_type))
        | if length > 0 then
            .[] | "    - \(.task_type): \(.failure_count) failures — review routing/checklist for this task type"
          else
            "    - Failure patterns exist but sample size per type is below \($min_per_type) — collect more data"
          end)
    elif $sr < 80 then
      "  recommendations:",
      "    - Success rate below 80% — review failure causes and routing"
    elif $cfpr < 70 then
      "  recommendations:",
      "    - CI first-pass rate below 70% — add pre-commit lint or local gate"
    else
      "  recommendations: exploratory_only — total threshold met but reviewer/failure/per-type thresholds not yet satisfied"
    end),
    "  trend: (not yet available — requires multiple reporting periods)",
    "  routing_optimization: \((if $tc < $min_tasks then "blocked — insufficient total data (\($tc)/\($min_tasks))" elif $s.reviewer_tasks < 5 then "partially_blocked — reviewer coverage insufficient (\($s.reviewer_tasks)/5)" elif $s.non_perfect_outcomes < 3 then "partially_blocked — non-perfect outcomes insufficient (\($s.non_perfect_outcomes)/3)" elif ([$s.task_type_distribution[] | .count] | max) < $min_per_type then "partially_blocked — per-type max insufficient (\([$s.task_type_distribution[] | .count] | max)/\($min_per_type))" elif $s.confidence_weight < 70 then "partially_blocked — low confidence (\($s.confidence_weight)% full evidence, need 70%+)" else "eligible — all thresholds met" end))",
    "  reviewer_hit_rate: \($s.reviewer_found_issues)/\($s.reviewer_tasks) \((if $s.reviewer_tasks > 0 then (($s.reviewer_found_issues * 100 / $s.reviewer_tasks) | floor) else 0 end))% \((if $s.reviewer_found_issues > 0 then "(reviewer is valuable)" elif $s.reviewer_tasks > 0 then "(reviewer confirmed quality)" else "(no reviewer data)" end))",
    "  evidence_scope: \([$s.repo_distribution[] | select(.count > 0) | "\(.repo)=\(.count)"] | join(", "))",
    "  recommendation_status: \((if $tc >= $min_tasks and $s.reviewer_tasks >= 5 and $s.non_perfect_outcomes >= 3 and ([$s.task_type_distribution[] | .count] | max) >= $min_per_type and $s.confidence_weight >= 70 then "evidence_based — run recommend-routing-adjustments.sh for detailed recommendations" else "exploratory_only" end))"
' "$METRICS_FILE" 2>/dev/null || {
  echo "AGENT_QUALITY_SCORECARD:"
  echo "  status: parse_error"
  echo "  reason: Could not parse $METRICS_FILE"
  echo "  hint: Ensure records are valid JSON, one per line"
  exit 0
}
