#!/usr/bin/env bash
# normalize-model-performance.sh — v4.46 Model Performance Normalizer
#
# Reads all task replay results and loop controller results, normalizes them
# into a unified model performance registry with result_type to prevent
# double-counting.
#
# Output:
#   .opencode/metrics/model-performance/performance-records.jsonl
#
# Usage:
#   bash normalize-model-performance.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPLAY_RESULTS_DIR="$WORKSPACE_ROOT/.opencode/evals/task-replay/results"
LOOP_RESULTS_DIR="$WORKSPACE_ROOT/.opencode/evals/loop-runs/results"
OUTPUT_FILE="$WORKSPACE_ROOT/.opencode/metrics/model-performance/performance-records.jsonl"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "=== Model Performance Normalizer ==="
echo "Timestamp: $TIMESTAMP"
echo ""

# ─── Collect and normalize results ───────────────────────────────────────
RECORD_COUNT=0

# Start with empty file
> "$OUTPUT_FILE"

# ─── Process task replay results ─────────────────────────────────────────
if [[ -d "$REPLAY_RESULTS_DIR" ]]; then
  for f in "$REPLAY_RESULTS_DIR"/*.json; do
    [[ ! -f "$f" ]] && continue
    if ! jq empty "$f" 2>/dev/null; then continue; fi

    # Skip protected-repo results
    REPO=$(jq -r '.repo_context // ""' "$f")
    if echo "$REPO" | grep -qi "baby"; then continue; fi

    # Skip 0-score template results
    SCORE=$(jq -r '.final_score // 0' "$f")
    if [[ "$SCORE" == "0" ]] || [[ "$SCORE" == "null" ]]; then continue; fi

    # Determine result_type: loop results have "loop-" prefix
    BASENAME=$(basename "$f")
    if echo "$BASENAME" | grep -q "^loop-"; then
      RESULT_TYPE="loop_result"
    else
      RESULT_TYPE="replay_result"
    fi

    # Extract normalized record
    jq -c '{
      model: .model // "unknown",
      agent: .agent // "unknown",
      task_id: .task_id,
      task_type: .task_type // "unknown",
      risk_lane: .risk_lane // "unknown",
      result_type: "'"$RESULT_TYPE"'",
      final_score: .final_score // 0,
      pass: .pass // false,
      repair_cycles: (.repair_cycles // 0),
      reviewer_issue_count: ((.reviewer_findings // []) | length),
      tests_passed: (.tests_passed // 0),
      tests_run: (.tests_run // 0),
      evidence_quality: (.scoring.evidence_quality // 0),
      security_risk_handling: (.scoring.security_risk_handling // 0),
      root_cause_correct: (.scoring.root_cause_correct // 0),
      minimal_diff: (.scoring.minimal_diff // 0),
      test_quality: (.scoring.test_quality // 0),
      ci_success: (.scoring.ci_success // 0),
      lesson_reuse: (.scoring.lesson_reuse // 0),
      time_seconds: (.scoring.time_cost_seconds // 0),
      token_count: (.tokens_used // null),
      estimated_cost: (.cost_usd // null),
      stop_reason: (.stop_reason // "n/a"),
      source_file: "'"$BASENAME"'",
      normalized_at: "'"$TIMESTAMP"'"
    }' "$f" >> "$OUTPUT_FILE"

    RECORD_COUNT=$((RECORD_COUNT + 1))
  done
fi

# ─── Process loop controller results (if not already captured via replay) ──
# Loop results that were --record-result'd are already in replay results.
# Only process loop results that are NOT in replay results.
if [[ -d "$LOOP_RESULTS_DIR" ]]; then
  for f in "$LOOP_RESULTS_DIR"/loop-run-*.json; do
    [[ ! -f "$f" ]] && continue
    if ! jq empty "$f" 2>/dev/null; then continue; fi

    # Skip protected-repo results
    REPO=$(jq -r '.repo_context // ""' "$f")
    if echo "$REPO" | grep -qi "baby"; then continue; fi

    # Check if this task already has a loop_result in replay results
    TASK_ID=$(jq -r '.task_id // ""' "$f")
    LOOP_TIMESTAMP=$(jq -r '.started_at // ""' "$f")

    # Check if already in output (avoid duplicates)
    if grep -q "\"task_id\":\"$TASK_ID\".*\"result_type\":\"loop_result\"" "$OUTPUT_FILE" 2>/dev/null; then
      # Already have a loop_result for this task — skip
      continue
    fi

    # Extract normalized record
    jq -c '{
      model: .model // "unknown",
      agent: .agent // "unknown",
      task_id: .task_id,
      task_type: .task_type // "unknown",
      risk_lane: .risk_lane // "unknown",
      result_type: "loop_result",
      final_score: .final_score // 0,
      pass: .pass // false,
      repair_cycles: (.telemetry.repair_cycles // 0),
      reviewer_issue_count: ((.reviewer_findings // []) | length),
      tests_passed: (.tests_passed // 0),
      tests_run: (.tests_run // 0),
      evidence_quality: (.scoring.evidence_quality // 0),
      security_risk_handling: (.scoring.security_risk_handling // 0),
      root_cause_correct: (.scoring.root_cause_correct // 0),
      minimal_diff: (.scoring.minimal_diff // 0),
      test_quality: (.scoring.test_quality // 0),
      ci_success: (.scoring.ci_success // 0),
      lesson_reuse: (.scoring.lesson_reuse // 0),
      time_seconds: 0,
      token_count: null,
      estimated_cost: null,
      stop_reason: (.stop_reason // "n/a"),
      source_file: "'"$(basename "$f")"'",
      normalized_at: "'"$TIMESTAMP"'"
    }' "$f" >> "$OUTPUT_FILE"

    RECORD_COUNT=$((RECORD_COUNT + 1))
  done
fi

echo "[normalizer] Normalized $RECORD_COUNT records"
echo "[normalizer] Output: $OUTPUT_FILE"
echo ""
echo "=== NORMALIZE COMPLETE ==="
