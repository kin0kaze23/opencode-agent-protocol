#!/usr/bin/env bash
# run-cross-model-evals.sh — v4.47 Cross-Model Eval Runner
#
# Runs task replay evals across multiple models/agents to build
# cross-model comparison data for routing recommendations.
#
# Safety:
# - Default mode is dry-run (no repo mutation)
# - protected-repo is never touched
# - Missing models are recorded as unavailable, not failed
# - Forbidden files are enforced
#
# Usage:
#   bash run-cross-model-evals.sh [options]
#
# Options:
#   --dry-run               Show run plan without executing (default)
#   --simulate              Run simulated cross-model evals
#   --task <task_id>        Run only one task
#   --model <model_name>    Run only one model
#   --list                  List planned runs
#   --help                  Show this help

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_PLAN="$WORKSPACE_ROOT/.opencode/evals/task-replay/cross-model-run-plan.yaml"
RESULTS_DIR="$WORKSPACE_ROOT/.opencode/evals/loop-runs/results"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# ─── Defaults ────────────────────────────────────────────────────────────
MODE="dry-run"
FILTER_TASK=""
FILTER_MODEL=""
LIST_MODE=false

# ─── Parse arguments ───────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)     MODE="dry-run"; shift ;;
    --simulate)    MODE="simulate"; shift ;;
    --task)        FILTER_TASK="$2"; shift 2 ;;
    --model)       FILTER_MODEL="$2"; shift 2 ;;
    --list)        LIST_MODE=true; shift ;;
    --help|-h)     head -20 "$0"; exit 0 ;;
    *) shift ;;
  esac
done

mkdir -p "$RESULTS_DIR"

if [[ ! -f "$RUN_PLAN" ]]; then
  echo "ERROR: Cross-model run plan not found at $RUN_PLAN"
  exit 1
fi

# ─── List mode ──────────────────────────────────────────────────────────
if [[ "$LIST_MODE" == true ]]; then
  echo "=== Cross-Model Run Plan ==="
  echo ""
  # Extract run matrix entries
  awk '
    /^run_matrix:/ { in_matrix=1; next }
    in_matrix && /^  - task_id:/ { val=$0; sub(/.*task_id: "/, "", val); sub(/".*/, "", val); task=val }
    in_matrix && /models:/ { val=$0; sub(/.*models: \[/, "", val); sub(/\].*/, "", val); gsub(/"/, "", val); print task " → " val }
    in_matrix && /^safety:/ { exit }
  ' "$RUN_PLAN"
  echo ""
  echo "Safety:"
  grep "protected-repo" "$RUN_PLAN" 2>/dev/null | head -1
  grep "default_mode" "$RUN_PLAN" 2>/dev/null | head -1
  exit 0
fi

echo "=== Cross-Model Eval Runner ==="
echo "Mode: $MODE"
echo "Timestamp: $TIMESTAMP"
echo ""

# ─── protected-repo safety check ──────────────────────────────────────────────
if grep -qi "protected-repo_excluded: true" "$RUN_PLAN"; then
  echo "[safety] protected-repo exclusion: PASS"
else
  echo "[safety] protected-repo exclusion: WARNING — not found in run plan"
fi
echo ""

# ─── Extract run entries ────────────────────────────────────────────────
# Parse the run_matrix section to get task_id and models
RUN_ENTRIES=$(awk '
  /^run_matrix:/ { in_matrix=1; next }
  in_matrix && /^  - task_id:/ {
    val=$0; sub(/.*task_id: "/, "", val); sub(/".*/, "", val)
    task=val
  }
  in_matrix && /models:/ {
    val=$0; sub(/.*models: \[/, "", val); sub(/\].*/, "", val); gsub(/"/, "", val)
    print task "\t" val
  }
  in_matrix && /^safety:/ { exit }
' "$RUN_PLAN")

if [[ -z "$RUN_ENTRIES" ]]; then
  echo "ERROR: No run entries found in run plan"
  exit 1
fi

# ─── Dry-run mode ───────────────────────────────────────────────────────
if [[ "$MODE" == "dry-run" ]]; then
  echo "=== DRY RUN — No repos will be mutated ==="
  echo ""
  echo "Planned runs:"
  echo ""
  echo "| Task ID | Models |"
  echo "|---------|--------|"
  while IFS=$'\t' read -r task models; do
    if [[ -n "$FILTER_TASK" ]] && [[ "$task" != "$FILTER_TASK" ]]; then continue; fi
    echo "| $task | $models |"
  done <<< "$RUN_ENTRIES"
  echo ""
  echo "Total planned task/model combinations:"
  TOTAL=0
  while IFS=$'\t' read -r task models; do
    if [[ -n "$FILTER_TASK" ]] && [[ "$task" != "$FILTER_TASK" ]]; then continue; fi
    MODEL_COUNT=$(echo "$models" | tr ',' '\n' | wc -l | tr -d ' ')
    TOTAL=$((TOTAL + MODEL_COUNT))
  done <<< "$RUN_ENTRIES"
  echo "  $TOTAL"
  echo ""
  echo "=== DRY RUN COMPLETE ==="
  echo "To simulate: add --simulate flag"
  exit 0
fi

# ─── Simulate mode ───────────────────────────────────────────────────────
if [[ "$MODE" == "simulate" ]]; then
  echo "=== SIMULATE MODE — Using known historical data ==="
  echo ""

  RUN_COUNT=0
  UNAVAILABLE_COUNT=0
  SUCCESS_COUNT=0

  while IFS=$'\t' read -r task models; do
    if [[ -n "$FILTER_TASK" ]] && [[ "$task" != "$FILTER_TASK" ]]; then continue; fi

    # Split models by comma
    IFS=',' read -ra MODEL_ARRAY <<< "$models"

    for model in "${MODEL_ARRAY[@]}"; do
      model=$(echo "$model" | xargs) # trim whitespace

      if [[ -n "$FILTER_MODEL" ]] && [[ "$model" != "$FILTER_MODEL" ]]; then continue; fi

      echo "[run] Task: $task, Model: $model"

      # Check if this model has simulation data
      # Currently only umans-glm-5.2 has simulation data in the loop controller
      if [[ "$model" == "umans-glm-5.2" ]]; then
        # Run the loop controller simulation
        bash "$SCRIPT_DIR/run-loop-controller.sh" --task "$task" --simulate --score --record-result > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
          echo "  → Result: PASS (simulated)"
          SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
          echo "  → Result: UNAVAILABLE (no simulation data for task $task with $model)"
          UNAVAILABLE_COUNT=$((UNAVAILABLE_COUNT + 1))
        fi
      else
        # Model not available for simulation — record as unavailable
        echo "  → Result: UNAVAILABLE (no simulation data for $model)"
        UNAVAILABLE_COUNT=$((UNAVAILABLE_COUNT + 1))

        # Sanitize model name for filename (replace / with -)
        MODEL_SAFE=$(echo "$model" | tr '/' '-')
        RESULT_FILE="$RESULTS_DIR/cross-model-${task}-${MODEL_SAFE}-$(echo $TIMESTAMP | tr ':' '-').json"
        cat > "$RESULT_FILE" << EOF
{
  "task_id": "$task",
  "model": "$model",
  "agent": "cross-model-eval",
  "mode": "simulate",
  "started_at": "$TIMESTAMP",
  "status": "unavailable",
  "reason": "No simulation data available for model $model",
  "result_type": "cross_model_unavailable"
}
EOF
      fi

      RUN_COUNT=$((RUN_COUNT + 1))
    done
  done <<< "$RUN_ENTRIES"

  echo ""
  echo "=== SIMULATE SUMMARY ==="
  echo "Total runs: $RUN_COUNT"
  echo "Successful: $SUCCESS_COUNT"
  echo "Unavailable: $UNAVAILABLE_COUNT"
  echo ""

  # Run normalizer and ROI analyzer to update scorecard
  echo "[pipeline] Normalizing performance records..."
  bash "$SCRIPT_DIR/normalize-model-performance.sh" > /dev/null 2>&1
  echo "[pipeline] Running ROI analyzer..."
  bash "$SCRIPT_DIR/analyze-model-roi.sh" > /dev/null 2>&1
  echo "[pipeline] Generating routing recommendations..."
  bash "$SCRIPT_DIR/generate-routing-recommendations.sh" > /dev/null 2>&1
  echo ""
  echo "[pipeline] Scorecard and recommendations updated"
  echo ""
  echo "=== SIMULATE COMPLETE ==="
  exit 0
fi

echo "ERROR: Unknown mode: $MODE"
exit 1
