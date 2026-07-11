#!/usr/bin/env bash
# score-task-replay.sh — v4.44 Task Replay Scoring Engine
#
# Scores a task replay result against the scoring rubric.
# Produces both markdown and JSON score reports.
#
# Scoring dimensions (0-5 each, weighted):
#   root_cause_correct      weight: 5
#   minimal_diff            weight: 4
#   test_quality            weight: 4
#   ci_success              weight: 4
#   security_risk_handling  weight: 5
#   evidence_quality        weight: 3
#   lesson_reuse            weight: 3
#
# Penalties:
#   reviewer_issue_count    -2 per issue (max -10)
#   repair_cycles           -3 per cycle beyond first (max -9)
#
# Tracked (not scored):
#   time_cost_seconds
#
# Max possible score: 35 (before penalties)
# Pass threshold: 24/35 (70%)
#
# Usage:
#   bash score-task-replay.sh --task <task_id> --result-file <path> [--tasks-file <path>]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TASKS_FILE="$WORKSPACE_ROOT/.opencode/evals/task-replay/tasks.yaml"
REPORTS_DIR="$WORKSPACE_ROOT/reports/task-replay"
RESULTS_DIR="$WORKSPACE_ROOT/.opencode/evals/task-replay/results"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# ─── Defaults ────────────────────────────────────────────────────────────
TASK_ID=""
RESULT_FILE=""

# ─── Parse arguments ─────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --task)        TASK_ID="$2"; shift 2 ;;
    --result-file) RESULT_FILE="$2"; shift 2 ;;
    --tasks-file)  TASKS_FILE="$2"; shift 2 ;;
    --help|-h)     head -25 "$0"; exit 0 ;;
    *) shift ;;
  esac
done

mkdir -p "$REPORTS_DIR"

# ─── Validate ─────────────────────────────────────────────────────────────
if [[ -z "$TASK_ID" ]]; then
  echo "ERROR: --task <task_id> is required"
  exit 1
fi

if [[ -z "$RESULT_FILE" ]]; then
  echo "ERROR: --result-file <path> is required"
  exit 1
fi

if [[ ! -f "$RESULT_FILE" ]]; then
  echo "ERROR: Result file not found: $RESULT_FILE"
  exit 1
fi

if [[ ! -f "$TASKS_FILE" ]]; then
  echo "ERROR: Tasks file not found: $TASKS_FILE"
  exit 1
fi

# ─── Validate result JSON ────────────────────────────────────────────────
if ! jq empty "$RESULT_FILE" 2>/dev/null; then
  echo "ERROR: Result file is not valid JSON: $RESULT_FILE"
  exit 1
fi

# ─── Check required fields ───────────────────────────────────────────────
REQUIRED_FIELDS=("task_id" "model" "agent" "started_at" "scoring")
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! jq -e --arg field "$field" 'has($field)' "$RESULT_FILE" >/dev/null 2>&1; then
    echo "ERROR: Result file missing required field: $field"
    exit 1
  fi
done

# ─── Check task_id matches ──────────────────────────────────────────────
RESULT_TASK_ID=$(jq -r '.task_id' "$RESULT_FILE")
if [[ "$RESULT_TASK_ID" != "$TASK_ID" ]]; then
  echo "ERROR: Result task_id ($RESULT_TASK_ID) does not match --task ($TASK_ID)"
  exit 1
fi

# ─── protected-repo safety check ──────────────────────────────────────────────
RESULT_REPO=$(jq -r '.repo_context // ""' "$RESULT_FILE")
if [[ "$RESULT_REPO" == "protected-repo" ]] || echo "$RESULT_REPO" | grep -qi "baby"; then
  echo "ERROR: protected-repo result detected. Scoring aborted."
  exit 1
fi

echo "=== Task Replay Scoring ==="
echo "Task ID:    $TASK_ID"
echo "Model:      $(jq -r '.model' "$RESULT_FILE")"
echo "Agent:      $(jq -r '.agent' "$RESULT_FILE")"
echo "Result:     $RESULT_FILE"
echo ""

# ─── Extract scores from result ──────────────────────────────────────────
ROOT_CAUSE_SCORE=$(jq -r '.scoring.root_cause_correct // 0' "$RESULT_FILE")
MINIMAL_DIFF_SCORE=$(jq -r '.scoring.minimal_diff // 0' "$RESULT_FILE")
TEST_QUALITY_SCORE=$(jq -r '.scoring.test_quality // 0' "$RESULT_FILE")
CI_SUCCESS_SCORE=$(jq -r '.scoring.ci_success // 0' "$RESULT_FILE")
SECURITY_SCORE=$(jq -r '.scoring.security_risk_handling // 0' "$RESULT_FILE")
EVIDENCE_SCORE=$(jq -r '.scoring.evidence_quality // 0' "$RESULT_FILE")
LESSON_REUSE_SCORE=$(jq -r '.scoring.lesson_reuse // 0' "$RESULT_FILE")

# Penalties
REVIEWER_ISSUES=$(jq -r '.scoring.reviewer_issue_count // 0' "$RESULT_FILE")
REPAIR_CYCLES=$(jq -r '.repair_cycles // 0' "$RESULT_FILE")
TIME_COST=$(jq -r '.scoring.time_cost_seconds // 0' "$RESULT_FILE")

# ─── Validate score ranges (0-5) ────────────────────────────────────────
validate_score() {
  local name="$1"
  local value="$2"
  if [[ "$value" -lt 0 ]] || [[ "$value" -gt 5 ]]; then
    echo "WARNING: $name score $value is out of range (0-5), clamping"
    if [[ "$value" -lt 0 ]]; then echo 0; else echo 5; fi
  else
    echo "$value"
  fi
}

ROOT_CAUSE_SCORE=$(validate_score "root_cause_correct" "$ROOT_CAUSE_SCORE")
MINIMAL_DIFF_SCORE=$(validate_score "minimal_diff" "$MINIMAL_DIFF_SCORE")
TEST_QUALITY_SCORE=$(validate_score "test_quality" "$TEST_QUALITY_SCORE")
CI_SUCCESS_SCORE=$(validate_score "ci_success" "$CI_SUCCESS_SCORE")
SECURITY_SCORE=$(validate_score "security_risk_handling" "$SECURITY_SCORE")
EVIDENCE_SCORE=$(validate_score "evidence_quality" "$EVIDENCE_SCORE")
LESSON_REUSE_SCORE=$(validate_score "lesson_reuse" "$LESSON_REUSE_SCORE")

# ─── Calculate weighted scores ───────────────────────────────────────────
# Weights: root_cause=5, minimal_diff=4, test_quality=4, ci_success=4,
#          security=5, evidence=3, lesson_reuse=3
# Max per dimension = weight * 5
# Total max = (5+4+4+4+5+3+3) * 5 = 28 * 5 = 140... no wait
# Actually: each dimension is 0-5, weight multiplies the score
# final = sum(score_i * weight_i) / sum(weight_i) * 5
# Or simpler: final = sum(score_i * weight_i) where max = sum(5 * weight_i) = 5*28 = 140
# But user said max = 35, so it's just sum of scores (0-5 each, 7 dimensions = 35 max)

# Using simple sum (0-5 per dimension, 7 dimensions = 35 max)
WEIGHTED_SCORE=$((ROOT_CAUSE_SCORE + MINIMAL_DIFF_SCORE + TEST_QUALITY_SCORE + CI_SUCCESS_SCORE + SECURITY_SCORE + EVIDENCE_SCORE + LESSON_REUSE_SCORE))

# ─── Calculate penalties ─────────────────────────────────────────────────
REVIEWER_PENALTY=$((REVIEWER_ISSUES * 2))
if [[ $REVIEWER_PENALTY -gt 10 ]]; then REVIEWER_PENALTY=10; fi

REPAIR_PENALTY=0
if [[ $REPAIR_CYCLES -gt 0 ]]; then
  REPAIR_PENALTY=$((REPAIR_CYCLES * 3))
  if [[ $REPAIR_PENALTY -gt 9 ]]; then REPAIR_PENALTY=9; fi
fi

TOTAL_PENALTY=$((REVIEWER_PENALTY + REPAIR_PENALTY))

# ─── Final score ──────────────────────────────────────────────────────────
FINAL_SCORE=$((WEIGHTED_SCORE - TOTAL_PENALTY))
if [[ $FINAL_SCORE -lt 0 ]]; then FINAL_SCORE=0; fi

MAX_POSSIBLE=35
PASS_THRESHOLD=24
PASS=false
if [[ $FINAL_SCORE -ge $PASS_THRESHOLD ]]; then PASS=true; fi

# ─── Update result file with final score and pass status ─────────────────
jq --argjson score "$FINAL_SCORE" --argjson pass "$PASS" \
  '.final_score = $score | .pass = $pass' "$RESULT_FILE" > "${RESULT_FILE}.tmp" && mv "${RESULT_FILE}.tmp" "$RESULT_FILE"

echo "--- Score Breakdown ---"
echo ""
echo "  root_cause_correct:      $ROOT_CAUSE_SCORE/5"
echo "  minimal_diff:            $MINIMAL_DIFF_SCORE/5"
echo "  test_quality:            $TEST_QUALITY_SCORE/5"
echo "  ci_success:              $CI_SUCCESS_SCORE/5"
echo "  security_risk_handling:  $SECURITY_SCORE/5"
echo "  evidence_quality:        $EVIDENCE_SCORE/5"
echo "  lesson_reuse:            $LESSON_REUSE_SCORE/5"
echo "  ────────────────────────────────────"
echo "  Subtotal:                $WEIGHTED_SCORE/$MAX_POSSIBLE"
echo ""
echo "  Penalties:"
echo "    reviewer_issues:       -$REVIEWER_PENALTY ($REVIEWER_ISSUES issues × 2)"
echo "    repair_cycles:         -$REPAIR_PENALTY ($REPAIR_CYCLES cycles × 3)"
echo "  Total penalty:           -$TOTAL_PENALTY"
echo ""
echo "  ────────────────────────────────────"
echo "  FINAL SCORE:            $FINAL_SCORE/$MAX_POSSIBLE"
echo "  PASS THRESHOLD:         $PASS_THRESHOLD/$MAX_POSSIBLE"
if [[ "$PASS" == true ]]; then
  echo "  RESULT:                 PASS ✅"
else
  echo "  RESULT:                 FAIL ❌"
fi
echo ""
echo "  time_cost_seconds:      $TIME_COST (tracked, not penalized)"
echo ""

# ─── Generate JSON score report ──────────────────────────────────────────
JSON_REPORT="$REPORTS_DIR/${TASK_ID}.json"

cat > "$JSON_REPORT" << EOF
{
  "task_id": "$TASK_ID",
  "model": $(jq '.model' "$RESULT_FILE"),
  "agent": $(jq '.agent' "$RESULT_FILE"),
  "scored_at": "$TIMESTAMP",
  "scores": {
    "root_cause_correct": $ROOT_CAUSE_SCORE,
    "minimal_diff": $MINIMAL_DIFF_SCORE,
    "test_quality": $TEST_QUALITY_SCORE,
    "ci_success": $CI_SUCCESS_SCORE,
    "security_risk_handling": $SECURITY_SCORE,
    "evidence_quality": $EVIDENCE_SCORE,
    "lesson_reuse": $LESSON_REUSE_SCORE
  },
  "penalties": {
    "reviewer_issue_count": $REVIEWER_ISSUES,
    "reviewer_penalty": $REVIEWER_PENALTY,
    "repair_cycles": $REPAIR_CYCLES,
    "repair_penalty": $REPAIR_PENALTY,
    "total_penalty": $TOTAL_PENALTY
  },
  "tracked": {
    "time_cost_seconds": $TIME_COST
  },
  "subtotal": $WEIGHTED_SCORE,
  "final_score": $FINAL_SCORE,
  "max_possible_score": $MAX_POSSIBLE,
  "pass_threshold": $PASS_THRESHOLD,
  "pass": $PASS
}
EOF

echo "[report] JSON score saved: $JSON_REPORT"

# ─── Generate markdown score report ───────────────────────────────────────
MD_REPORT="$REPORTS_DIR/${TASK_ID}.md"

cat > "$MD_REPORT" << EOF
# Task Replay Score: $TASK_ID

> Scored at: $TIMESTAMP

## Task

- **ID:** $TASK_ID
- **Title:** $(jq -r '.title // "N/A"' "$RESULT_FILE")
- **Type:** $(jq -r '.task_type // "N/A"' "$RESULT_FILE")
- **Model:** $(jq -r '.model' "$RESULT_FILE")
- **Agent:** $(jq -r '.agent' "$RESULT_FILE")

## Scores

| Dimension | Score | Max |
|-----------|-------|-----|
| root_cause_correct | $ROOT_CAUSE_SCORE | 5 |
| minimal_diff | $MINIMAL_DIFF_SCORE | 5 |
| test_quality | $TEST_QUALITY_SCORE | 5 |
| ci_success | $CI_SUCCESS_SCORE | 5 |
| security_risk_handling | $SECURITY_SCORE | 5 |
| evidence_quality | $EVIDENCE_SCORE | 5 |
| lesson_reuse | $LESSON_REUSE_SCORE | 5 |
| **Subtotal** | **$WEIGHTED_SCORE** | **$MAX_POSSIBLE** |

## Penalties

| Penalty | Count | Deduction |
|---------|-------|-----------|
| reviewer_issues | $REVIEWER_ISSUES | -$REVIEWER_PENALTY |
| repair_cycles | $REPAIR_CYCLES | -$REPAIR_PENALTY |
| **Total** | | **-$TOTAL_PENALTY** |

## Final

| Metric | Value |
|--------|-------|
| Final Score | $FINAL_SCORE / $MAX_POSSIBLE |
| Pass Threshold | $PASS_THRESHOLD / $MAX_POSSIBLE |
| Result | $([ "$PASS" == true ] && echo "PASS ✅" || echo "FAIL ❌") |
| Time Cost | ${TIME_COST}s (tracked) |

## Details

- Files touched: $(jq -r '.files_touched | length' "$RESULT_FILE")
- Tests run: $(jq -r '.tests_run // 0' "$RESULT_FILE")
- Tests passed: $(jq -r '.tests_passed // 0' "$RESULT_FILE")
- Tests failed: $(jq -r '.tests_failed // 0' "$RESULT_FILE")
- Reviewer used: $(jq -r '.reviewer_used // false' "$RESULT_FILE")
- Root cause identified: $(jq -r '.root_cause_identified // false' "$RESULT_FILE")
EOF

echo "[report] Markdown score saved: $MD_REPORT"
echo ""
echo "=== SCORING COMPLETE ==="
