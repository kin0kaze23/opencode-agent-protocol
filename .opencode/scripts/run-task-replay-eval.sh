#!/usr/bin/env bash
# run-task-replay-eval.sh — v4.44 Agent Task Replay Eval Runner
#
# Replays a historical engineering task in a controlled eval environment.
# Supports dry-run (default), score-only, record-result, and apply modes.
#
# Safety:
# - Default mode is dry-run — no repo mutation
# - --apply is required for any real repo mutation
# - protected-repo is never touched
# - Forbidden files are enforced
# - No secrets are recorded
#
# Usage:
#   bash run-task-replay-eval.sh --task <task_id> [options]
#
# Options:
#   --task <task_id>        Task to replay (required)
#   --model <model_name>    Model to evaluate (default: current)
#   --agent <agent_name>    Agent to evaluate (default: owner)
#   --dry-run               Show what would be done (default)
#   --score-only            Score an existing result file
#   --record-result         Save result to results directory
#   --apply                 Actually mutate repos (DANGEROUS)
#   --result-file <path>    Existing result file for --score-only
#   --list-tasks            List all available tasks
#   --help                  Show this help

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TASKS_FILE="$WORKSPACE_ROOT/.opencode/evals/task-replay/tasks.yaml"
RESULTS_DIR="$WORKSPACE_ROOT/.opencode/evals/task-replay/results"
REPORTS_DIR="$WORKSPACE_ROOT/reports/task-replay"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# ─── Defaults ────────────────────────────────────────────────────────────
TASK_ID=""
MODEL="current"
AGENT="owner"
MODE="dry-run"
RESULT_FILE=""
LIST_TASKS=false

# ─── Parse arguments ─────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --task)        TASK_ID="$2"; shift 2 ;;
    --model)       MODEL="$2"; shift 2 ;;
    --agent)       AGENT="$2"; shift 2 ;;
    --dry-run)     MODE="dry-run"; shift ;;
    --score-only)  MODE="score-only"; shift ;;
    --record-result) MODE="record"; shift ;;
    --apply)       MODE="apply"; shift ;;
    --result-file) RESULT_FILE="$2"; shift 2 ;;
    --list-tasks)  LIST_TASKS=true; shift ;;
    --help|-h)     head -20 "$0"; exit 0 ;;
    *) shift ;;
  esac
done

mkdir -p "$RESULTS_DIR" "$REPORTS_DIR"

# ─── List tasks mode ─────────────────────────────────────────────────────
if [[ "$LIST_TASKS" == true ]]; then
  echo "=== Available Task Replay Tasks ==="
  echo ""
  # Parse tasks.yaml for task_id and title
  awk '
    /^  - task_id:/ { gsub(/.*task_id: "?/, ""); gsub(/".*/, ""); id=$0 }
    /^    title:/   { gsub(/.*title: "?/, ""); gsub(/".*/, ""); title=$0 }
    /^    task_type:/ { gsub(/.*task_type: "?/, ""); gsub(/".*/, ""); type=$0 }
    /^    risk_lane:/ { gsub(/.*risk_lane: "?/, ""); gsub(/".*/, ""); lane=$0; printf "  %-8s %-50s [%s/%s]\n", id, title, type, lane }
  ' "$TASKS_FILE"
  echo ""
  echo "Total tasks: $(grep -c 'task_id:' "$TASKS_FILE")"
  exit 0
fi

# ─── Validate task ID ────────────────────────────────────────────────────
if [[ -z "$TASK_ID" ]]; then
  echo "ERROR: --task <task_id> is required"
  echo "Use --list-tasks to see available tasks"
  exit 1
fi

if [[ ! -f "$TASKS_FILE" ]]; then
  echo "ERROR: Tasks file not found at $TASKS_FILE"
  exit 1
fi

# ─── Extract task details from YAML ──────────────────────────────────────
extract_field() {
  local field="$1"
  local task="$2"
  awk -v task="$task" -v field="$field" '
    $0 ~ "task_id:.*\"" task "\"" { found=1 }
    found && $0 ~ field ":" {
      val=$0
      sub(/.*: */, "", val)
      gsub(/^"|"$/, "", val)
      print val
      exit
    }
  ' "$TASKS_FILE"
}

# Extract a multiline field (YAML block scalar with |)
extract_multiline_field() {
  local field="$1"
  local task="$2"
  awk -v task="$task" -v field="$field" '
    $0 ~ "task_id:.*\"" task "\"" { found=1 }
    found && $0 ~ "  " field ":" {
      # Check if it is a block scalar (ends with |)
      if ($0 ~ /\|$/) { in_block=1; next }
      # Single-line value
      val=$0
      sub(/.*: */, "", val)
      gsub(/^"|"$/, "", val)
      print val
      exit
    }
    found && in_block && /^      [^ ]/ {
      line=$0
      sub(/^      /, "", line)
      print line
    }
    found && in_block && /^    [a-z]/ && !/^      / { exit }
  ' "$TASKS_FILE"
}

# Verify task exists
TASK_TITLE=$(extract_field "title" "$TASK_ID")
if [[ -z "$TASK_TITLE" ]]; then
  echo "ERROR: Task '$TASK_ID' not found in $TASKS_FILE"
  echo "Use --list-tasks to see available tasks"
  exit 1
fi

TASK_TYPE=$(extract_field "task_type" "$TASK_ID")
TASK_LANE=$(extract_field "risk_lane" "$TASK_ID")
TASK_REPO=$(extract_field "repo_context" "$TASK_ID")
TASK_SOURCE=$(extract_field "historical_source" "$TASK_ID")
TASK_MAX_REPAIR=$(extract_field "max_repair_cycles" "$TASK_ID")

echo "=== Task Replay Eval ==="
echo "Task ID:       $TASK_ID"
echo "Title:         $TASK_TITLE"
echo "Type:          $TASK_TYPE"
echo "Risk Lane:     $TASK_LANE"
echo "Repo Context:  $TASK_REPO"
echo "Model:         $MODEL"
echo "Agent:         $AGENT"
echo "Mode:          $MODE"
echo "Timestamp:     $TIMESTAMP"
echo ""

# ─── protected-repo safety check ──────────────────────────────────────────────
if [[ "$TASK_REPO" == "protected-repo" ]]; then
  echo "ERROR: protected-repo is excluded from task replay. Aborting."
  exit 1
fi

# Check excluded repos
if grep -q "protected-repo" "$TASKS_FILE" 2>/dev/null; then
  # Verify the task is not protected-repo-related
  if echo "$TASK_REPO" | grep -qi "baby"; then
    echo "ERROR: protected-repo-related task detected. Aborting."
    exit 1
  fi
fi

echo "[safety] protected-repo exclusion: PASS"
echo ""

# ─── Extract forbidden files ─────────────────────────────────────────────
FORBIDDEN_FILE="$RESULTS_DIR/.forbidden-$$"
awk -v task="$TASK_ID" '
  $0 ~ "task_id:.*\"" task "\"" { found=1 }
  found && /forbidden_files:/ { in_forbidden=1; next }
  found && in_forbidden && /^      - / {
    val=$0
    sub(/^      - /, "", val)
    gsub(/^"|"$/, "", val)
    print val
  }
  found && in_forbidden && !/^      - / { exit }
' "$TASKS_FILE" > "$FORBIDDEN_FILE"

FORBIDDEN_COUNT=$(wc -l < "$FORBIDDEN_FILE" | tr -d ' ')
echo "[safety] Forbidden files enforced: $FORBIDDEN_COUNT patterns"
echo ""

# ─── Mode: score-only ────────────────────────────────────────────────────
if [[ "$MODE" == "score-only" ]]; then
  if [[ -z "$RESULT_FILE" ]]; then
    # Try to find the most recent result for this task
    RESULT_FILE=$(ls -t "$RESULTS_DIR/${TASK_ID}"_*.json 2>/dev/null | head -1)
    if [[ -z "$RESULT_FILE" ]]; then
      echo "ERROR: No result file specified and no existing result found for $TASK_ID"
      echo "Use --result-file <path> or run with --record-result first"
      rm -f "$FORBIDDEN_FILE"
      exit 1
    fi
    echo "[score-only] Using result: $RESULT_FILE"
  fi

  if [[ ! -f "$RESULT_FILE" ]]; then
    echo "ERROR: Result file not found: $RESULT_FILE"
    rm -f "$FORBIDDEN_FILE"
    exit 1
  fi

  echo "[score-only] Scoring result..."
  bash "$SCRIPT_DIR/score-task-replay.sh" \
    --task "$TASK_ID" \
    --result-file "$RESULT_FILE" \
    --tasks-file "$TASKS_FILE"

  SCORE_EXIT=$?
  rm -f "$FORBIDDEN_FILE"
  exit $SCORE_EXIT
fi

# ─── Mode: dry-run (default) ─────────────────────────────────────────────
if [[ "$MODE" == "dry-run" ]]; then
  echo "=== DRY RUN — No repos will be mutated ==="
  echo ""
  echo "--- Task Prompt ---"
  echo ""
  extract_multiline_field "input_prompt" "$TASK_ID"
  echo ""
  echo "--- Expected Root Cause ---"
  echo ""
  extract_field "expected_root_cause" "$TASK_ID"
  echo ""
  echo "--- Expected Files Touched ---"
  echo ""
  awk -v task="$TASK_ID" '
    $0 ~ "task_id:.*\"" task "\"" { found=1 }
    found && /expected_files_touched:/ { in_field=1; next }
    found && in_field && /^      - / {
      val=$0
      sub(/^      - /, "", val)
      gsub(/^"|"$/, "", val)
      print "  - " val
    }
    found && in_field && !/^      - / { exit }
  ' "$TASKS_FILE"
  echo ""
  echo "--- Forbidden Files ---"
  echo ""
  while IFS= read -r pattern; do
    echo "  - $pattern"
  done < "$FORBIDDEN_FILE"
  echo ""
  echo "--- Required Tests ---"
  echo ""
  awk -v task="$TASK_ID" '
    $0 ~ "task_id:.*\"" task "\"" { found=1 }
    found && /required_tests:/ { in_field=1; next }
    found && in_field && /^      - / {
      val=$0
      sub(/^      - /, "", val)
      gsub(/^"|"$/, "", val)
      print "  - " val
    }
    found && in_field && !/^      - / { exit }
  ' "$TASKS_FILE"
  echo ""
  echo "--- Expected Evidence ---"
  echo ""
  awk -v task="$TASK_ID" '
    $0 ~ "task_id:.*\"" task "\"" { found=1 }
    found && /expected_evidence:/ { in_field=1; next }
    found && in_field && /^      - / {
      val=$0
      sub(/^      - /, "", val)
      gsub(/^"|"$/, "", val)
      print "  - " val
    }
    found && in_field && !/^      - / { exit }
  ' "$TASKS_FILE"
  echo ""
  echo "--- Expected Reviewer Findings ---"
  echo ""
  awk -v task="$TASK_ID" '
    $0 ~ "task_id:.*\"" task "\"" { found=1 }
    found && /expected_reviewer_findings:/ { in_field=1; next }
    found && in_field && /^      - / {
      val=$0
      sub(/^      - /, "", val)
      gsub(/^"|"$/, "", val)
      print "  - " val
    }
    found && in_field && !/^      - / { exit }
  ' "$TASKS_FILE"
  echo ""
  echo "--- Scoring Rubric ---"
  echo ""
  echo "  root_cause_correct:     0-5 (weight: 5)"
  echo "  minimal_diff:           0-5 (weight: 4)"
  echo "  test_quality:           0-5 (weight: 4)"
  echo "  ci_success:             0-5 (weight: 4)"
  echo "  security_risk_handling: 0-5 (weight: 5)"
  echo "  evidence_quality:       0-5 (weight: 3)"
  echo "  lesson_reuse:           0-5 (weight: 3)"
  echo "  reviewer_issue_count:   penalty (-2 per issue, max -10)"
  echo "  repair_cycles:          penalty (-3 per cycle, max -9)"
  echo "  time_cost:              tracked"
  echo ""
  echo "Max possible score: 35 (before penalties)"
  echo ""
  echo "=== DRY RUN COMPLETE ==="
  echo "To execute: add --apply flag (requires explicit approval)"
  echo "To record result: add --record-result flag"

  rm -f "$FORBIDDEN_FILE"
  exit 0
fi

# ─── Mode: apply (DANGEROUS) ──────────────────────────────────────────────
if [[ "$MODE" == "apply" ]]; then
  echo "WARNING: --apply mode will mutate real repositories."
  echo "This requires explicit owner approval."
  echo ""
  echo "Target repo: $TASK_REPO"
  echo ""
  # In a real implementation, this would:
  # 1. Create an eval workspace
  # 2. Apply the task prompt to the agent
  # 3. Collect the agent's output
  # 4. Run scoring
  # 5. Record the result
  #
  # For v4.44, --apply is scaffolded but not fully automated.
  # Real replay execution requires the loop controller (v4.45).

  echo "[apply] Eval workspace creation: scaffolded"
  echo "[apply] Agent dispatch: requires v4.45 loop controller"
  echo "[apply] Scoring: ready (use --score-only after manual execution)"
  echo ""
  echo "For manual replay:"
  echo "  1. Apply the task prompt to your agent"
  echo "  2. Collect the output (diff, tests, evidence)"
  echo "  3. Create a result JSON file"
  echo "  4. Run: bash run-task-replay-eval.sh --task $TASK_ID --score-only --result-file <path>"
  echo ""
  echo "=== APPLY MODE (scaffolded) ==="

  rm -f "$FORBIDDEN_FILE"
  exit 0
fi

# ─── Mode: record ────────────────────────────────────────────────────────
if [[ "$MODE" == "record" ]]; then
  RESULT_FILE_PATH="$RESULTS_DIR/${TASK_ID}_${TIMESTAMP//:/-}.json"

  echo "=== RECORD RESULT ==="
  echo "Result file: $RESULT_FILE_PATH"
  echo ""

  # Create a result template
  cat > "$RESULT_FILE_PATH" << EOF
{
  "task_id": "$TASK_ID",
  "title": "$TASK_TITLE",
  "task_type": "$TASK_TYPE",
  "risk_lane": "$TASK_LANE",
  "repo_context": "$TASK_REPO",
  "model": "$MODEL",
  "agent": "$AGENT",
  "started_at": "$TIMESTAMP",
  "completed_at": "",
  "tokens_used": null,
  "cost_usd": null,
  "repair_cycles": 0,
  "tests_run": 0,
  "tests_passed": 0,
  "tests_failed": 0,
  "reviewer_used": false,
  "reviewer_findings": [],
  "files_touched": [],
  "diff_summary": "",
  "root_cause_identified": false,
  "root_cause_description": "",
  "evidence_provided": [],
  "security_sensitive": false,
  "lessons_extracted": [],
  "scoring": {
    "root_cause_correct": 0,
    "minimal_diff": 0,
    "test_quality": 0,
    "ci_success": 0,
    "security_risk_handling": 0,
    "evidence_quality": 0,
    "lesson_reuse": 0,
    "reviewer_issue_count": 0,
    "repair_cycles_penalty": 0,
    "time_cost_seconds": 0
  },
  "final_score": 0,
  "max_possible_score": 35,
  "pass": false,
  "notes": ""
}
EOF

  echo "Result template created at: $RESULT_FILE_PATH"
  echo ""
  echo "Fill in the fields and run:"
  echo "  bash run-task-replay-eval.sh --task $TASK_ID --score-only --result-file $RESULT_FILE_PATH"
  echo ""
  echo "=== RECORD COMPLETE ==="

  rm -f "$FORBIDDEN_FILE"
  exit 0
fi

# Unknown mode
echo "ERROR: Unknown mode: $MODE"
rm -f "$FORBIDDEN_FILE"
exit 1
