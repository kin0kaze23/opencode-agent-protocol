#!/usr/bin/env bash
# record-task-outcome.sh — Append task outcome telemetry (v4.33)
#
# Usage:
#   bash .opencode/scripts/record-task-outcome.sh \
#     --repo <repo> --lane <lane> --task-type <type> --outcome <outcome> \
#     [--branch <branch>] [--model <model>] [--reviewer <reviewer>] \
#     [--reviewer-value <no_issue_found|minor_issue_found|significant_issue_found|none>] \
#     [--reviewer-severity <low|medium|high|none>] \
#     [--premium-model <model>] [--files <count>] [--tests <count>] \
#     [--test-cmd <cmd>] [--ci-status <status>] [--ci-first-try <bool>] \
#     [--repair-cycles <n>] [--pattern-memory <bool>] [--project-memory <bool>] \
#     [--human-acceptance <accepted|revised|rejected|unknown>] [--notes <text>] \
#     [--task-id <id>] [--allow-duplicate] \
#     [--classifier-detected-sensitive <bool>] \
#     [--manual-sensitive-override <bool>] \
#     [--classifier-false-negative <bool>] \
#     [--classifier-detection-type <path|content|path+content|manual|none>]
#
# Design:
# - Append-only JSONL format
# - Non-blocking: never fails the task if telemetry can't be written
# - No secrets, no file contents, no prompts/responses
# - Tolerates missing optional fields
# - v4.29.2: Notes safety scanning, duplicate task_id guard, env override
# - v4.33: Classifier telemetry fields (classifier_detected_sensitive, manual_sensitive_override, classifier_false_negative, classifier_detection_type)

set -euo pipefail

METRICS_FILE="${METRICS_FILE:-.opencode/metrics/task-outcomes.jsonl}"
METRICS_DIR="$(dirname "$METRICS_FILE")"

# Ensure directory exists
mkdir -p "$METRICS_DIR" 2>/dev/null || true

# Parse arguments
REPO=""
LANE=""
TASK_TYPE=""
OUTCOME=""
BRANCH=""
MODEL=""
REVIEWER=""
REVIEWER_VALUE="none"
REVIEWER_SEVERITY="none"
REVIEW_REPAIR_CYCLES="0"
PRE_CI_REVIEWER_BLOCKED="false"
PREMIUM_MODEL=""
FILES_CHANGED=""
TESTS_ADDED=""
TEST_CMD=""
CI_STATUS=""
CI_FIRST_TRY=""
REPAIR_CYCLES=""
PATTERN_MEMORY=""
PROJECT_MEMORY=""
HUMAN_ACCEPTANCE="unknown"
NOTES=""
CUSTOM_TASK_ID=""
ALLOW_DUPLICATE=false
COLLECTION_MODE="live"
EVIDENCE_LEVEL="full"
SOURCE_TYPE="live"
# v4.33: Classifier telemetry fields
CLASSIFIER_DETECTED_SENSITIVE="false"
MANUAL_SENSITIVE_OVERRIDE="false"
CLASSIFIER_FALSE_NEGATIVE="false"
CLASSIFIER_DETECTION_TYPE="none"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --lane) LANE="$2"; shift 2 ;;
    --task-type) TASK_TYPE="$2"; shift 2 ;;
    --outcome) OUTCOME="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --reviewer) REVIEWER="$2"; shift 2 ;;
    --reviewer-value) REVIEWER_VALUE="$2"; shift 2 ;;
    --reviewer-severity) REVIEWER_SEVERITY="$2"; shift 2 ;;
    --review-repair-cycles) REVIEW_REPAIR_CYCLES="$2"; shift 2 ;;
    --pre-ci-reviewer-blocked) PRE_CI_REVIEWER_BLOCKED="$2"; shift 2 ;;
    --premium-model) PREMIUM_MODEL="$2"; shift 2 ;;
    --files) FILES_CHANGED="$2"; shift 2 ;;
    --tests) TESTS_ADDED="$2"; shift 2 ;;
    --test-cmd) TEST_CMD="$2"; shift 2 ;;
    --ci-status) CI_STATUS="$2"; shift 2 ;;
    --ci-first-try) CI_FIRST_TRY="$2"; shift 2 ;;
    --repair-cycles) REPAIR_CYCLES="$2"; shift 2 ;;
    --pattern-memory) PATTERN_MEMORY="$2"; shift 2 ;;
    --project-memory) PROJECT_MEMORY="$2"; shift 2 ;;
    --human-acceptance) HUMAN_ACCEPTANCE="$2"; shift 2 ;;
    --notes) NOTES="$2"; shift 2 ;;
    --task-id) CUSTOM_TASK_ID="$2"; shift 2 ;;
    --collection-mode) COLLECTION_MODE="$2"; shift 2 ;;
    --evidence-level) EVIDENCE_LEVEL="$2"; shift 2 ;;
    --source-type) SOURCE_TYPE="$2"; shift 2 ;;
    --allow-duplicate) ALLOW_DUPLICATE=true; shift ;;
    --classifier-detected-sensitive) CLASSIFIER_DETECTED_SENSITIVE="$2"; shift 2 ;;
    --manual-sensitive-override) MANUAL_SENSITIVE_OVERRIDE="$2"; shift 2 ;;
    --classifier-false-negative) CLASSIFIER_FALSE_NEGATIVE="$2"; shift 2 ;;
    --classifier-detection-type) CLASSIFIER_DETECTION_TYPE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Validate required fields (v4.29.1 schema validation)
if [[ -z "$REPO" || -z "$LANE" || -z "$TASK_TYPE" || -z "$OUTCOME" ]]; then
  echo "[record-task-outcome] Missing required fields. Usage:" >&2
  echo "  --repo <repo> --lane <lane> --task-type <type> --outcome <outcome>" >&2
  exit 0  # Non-blocking
fi

# Validate enum fields against schema
case "$LANE" in
  DIRECT|FAST|STANDARD|HIGH_RISK) ;;
  *) echo "[record-task-outcome] Invalid lane: $LANE (expected: DIRECT|FAST|STANDARD|HIGH_RISK)" >&2; exit 0 ;;
esac
case "$TASK_TYPE" in
  bugfix|feature|refactor|docs|test|infra|protocol) ;;
  *) echo "[record-task-outcome] Invalid task_type: $TASK_TYPE" >&2; exit 0 ;;
esac
case "$OUTCOME" in
  success|partial|failed|reverted) ;;
  *) echo "[record-task-outcome] Invalid outcome: $OUTCOME" >&2; exit 0 ;;
esac
case "$HUMAN_ACCEPTANCE" in
  accepted|revised|rejected|unknown) ;;
  *) HUMAN_ACCEPTANCE="unknown" ;;
esac
case "$COLLECTION_MODE" in
  live|retrospective|synthetic_eval) ;;
  *) COLLECTION_MODE="live" ;;
esac
case "$EVIDENCE_LEVEL" in
  full|partial|fixture|unknown) ;;
  *) EVIDENCE_LEVEL="full" ;;
esac
case "$SOURCE_TYPE" in
  live|retrospective|eval_fixture) ;;
  *) SOURCE_TYPE="live" ;;
esac
case "$REVIEWER_VALUE" in
  no_issue_found|minor_issue_found|significant_issue_found|none) ;;
  *) REVIEWER_VALUE="none" ;;
esac
case "$REVIEWER_SEVERITY" in
  low|medium|high|none) ;;
  *) REVIEWER_SEVERITY="none" ;;
esac
case "$PRE_CI_REVIEWER_BLOCKED" in
  true|false) ;;
  *) PRE_CI_REVIEWER_BLOCKED="false" ;;
esac
# v4.33: Validate classifier fields
case "$CLASSIFIER_DETECTED_SENSITIVE" in
  true|false) ;;
  *) CLASSIFIER_DETECTED_SENSITIVE="false" ;;
esac
case "$MANUAL_SENSITIVE_OVERRIDE" in
  true|false) ;;
  *) MANUAL_SENSITIVE_OVERRIDE="false" ;;
esac
case "$CLASSIFIER_FALSE_NEGATIVE" in
  true|false) ;;
  *) CLASSIFIER_FALSE_NEGATIVE="false" ;;
esac
case "$CLASSIFIER_DETECTION_TYPE" in
  path|content|path+content|manual|none) ;;
  *) CLASSIFIER_DETECTION_TYPE="none" ;;
esac

# v4.29.2: Notes safety scanning
if [[ -n "$NOTES" ]]; then
  # Limit note length
  if [[ ${#NOTES} -gt 500 ]]; then
    NOTES="${NOTES:0:500}"
    echo "[record-task-outcome] Warning: notes truncated to 500 chars" >&2
  fi
  # Check for obvious secret patterns (case-insensitive)
  NOTES_LOWER=$(echo "$NOTES" | tr '[:upper:]' '[:lower:]')
  for pattern in api_key token password secret private_key credential sk- bearer; do
    if [[ "$NOTES_LOWER" == *"$pattern"* ]]; then
      echo "[record-task-outcome] Warning: notes may contain sensitive pattern '$pattern' — clearing notes" >&2
      NOTES="[redacted: potential secret pattern detected]"
      break
    fi
  done
fi

# v4.29.2: Generate or use custom task ID
if [[ -n "$CUSTOM_TASK_ID" ]]; then
  TASK_ID="$CUSTOM_TASK_ID"
else
  TASK_ID="$(date +%Y%m%d%H%M%S)-$$"
fi

# v4.29.2: Duplicate task_id guard
if [[ "$ALLOW_DUPLICATE" == false && -f "$METRICS_FILE" ]]; then
  if grep -q "\"task_id\".*:.*\"$TASK_ID\"" "$METRICS_FILE" 2>/dev/null; then
    echo "[record-task-outcome] Warning: duplicate task_id '$TASK_ID' — use --allow-duplicate to override" >&2
    exit 0  # Non-blocking
  fi
fi

# Build JSON record
# Use jq if available, otherwise fall back to manual JSON construction
if command -v jq &>/dev/null; then
  RECORD=$(jq -c -n \
    --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg task_id "$TASK_ID" \
    --arg repo "$REPO" \
    --arg branch "${BRANCH:-unknown}" \
    --arg lane "$LANE" \
    --arg task_type "$TASK_TYPE" \
    --arg outcome "$OUTCOME" \
    --arg model_used "${MODEL:-unknown}" \
    --arg reviewer_used "${REVIEWER:-none}" \
    --arg reviewer_value_classification "$REVIEWER_VALUE" \
    --arg reviewer_issue_severity "$REVIEWER_SEVERITY" \
    --argjson review_repair_cycles "${REVIEW_REPAIR_CYCLES:-0}" \
    --arg pre_ci_reviewer_blocked "$PRE_CI_REVIEWER_BLOCKED" \
    --arg premium_model_used "${PREMIUM_MODEL:-none}" \
    --argjson files_changed_count "${FILES_CHANGED:-0}" \
    --argjson tests_added_or_updated "${TESTS_ADDED:-0}" \
    --arg test_command_run "${TEST_CMD:-none}" \
    --arg ci_status "${CI_STATUS:-unknown}" \
    --arg ci_first_try "${CI_FIRST_TRY:-unknown}" \
    --argjson repair_cycles "${REPAIR_CYCLES:-0}" \
    --arg pattern_memory_used "${PATTERN_MEMORY:-false}" \
    --arg project_memory_used "${PROJECT_MEMORY:-false}" \
    --arg human_acceptance "$HUMAN_ACCEPTANCE" \
    --arg notes "$NOTES" \
    --arg collection_mode "$COLLECTION_MODE" \
    --arg evidence_level "$EVIDENCE_LEVEL" \
    --arg source_type "$SOURCE_TYPE" \
    --arg classifier_detected_sensitive "$CLASSIFIER_DETECTED_SENSITIVE" \
    --arg manual_sensitive_override "$MANUAL_SENSITIVE_OVERRIDE" \
    --arg classifier_false_negative "$CLASSIFIER_FALSE_NEGATIVE" \
    --arg classifier_detection_type "$CLASSIFIER_DETECTION_TYPE" \
    '{
      timestamp: $timestamp,
      task_id: $task_id,
      repo: $repo,
      branch: $branch,
      lane: $lane,
      task_type: $task_type,
      files_changed_count: $files_changed_count,
      model_used: $model_used,
      reviewer_used: $reviewer_used,
      reviewer_value_classification: $reviewer_value_classification,
      reviewer_issue_severity: $reviewer_issue_severity,
      review_repair_cycles: $review_repair_cycles,
      pre_ci_reviewer_blocked: $pre_ci_reviewer_blocked,
      premium_model_used: $premium_model_used,
      tests_added_or_updated: $tests_added_or_updated,
      test_command_run: $test_command_run,
      ci_status: $ci_status,
      ci_first_try: $ci_first_try,
      repair_cycles: $repair_cycles,
      pattern_memory_used: $pattern_memory_used,
      project_memory_used: $project_memory_used,
      human_acceptance: $human_acceptance,
      outcome: $outcome,
      notes: $notes,
      collection_mode: $collection_mode,
      evidence_level: $evidence_level,
      source_type: $source_type,
      classifier_detected_sensitive: $classifier_detected_sensitive,
      manual_sensitive_override: $manual_sensitive_override,
      classifier_false_negative: $classifier_false_negative,
      classifier_detection_type: $classifier_detection_type
    }')
else
  # Fallback without jq
  RECORD="{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"task_id\":\"$TASK_ID\",\"repo\":\"$REPO\",\"branch\":\"${BRANCH:-unknown}\",\"lane\":\"$LANE\",\"task_type\":\"$TASK_TYPE\",\"files_changed_count\":${FILES_CHANGED:-0},\"model_used\":\"${MODEL:-unknown}\",\"reviewer_used\":\"${REVIEWER:-none}\",\"reviewer_value_classification\":\"$REVIEWER_VALUE\",\"reviewer_issue_severity\":\"$REVIEWER_SEVERITY\",\"review_repair_cycles\":${REVIEW_REPAIR_CYCLES:-0},\"pre_ci_reviewer_blocked\":\"$PRE_CI_REVIEWER_BLOCKED\",\"premium_model_used\":\"${PREMIUM_MODEL:-none}\",\"tests_added_or_updated\":${TESTS_ADDED:-0},\"test_command_run\":\"${TEST_CMD:-none}\",\"ci_status\":\"${CI_STATUS:-unknown}\",\"ci_first_try\":\"${CI_FIRST_TRY:-unknown}\",\"repair_cycles\":${REPAIR_CYCLES:-0},\"pattern_memory_used\":\"${PATTERN_MEMORY:-false}\",\"project_memory_used\":\"${PROJECT_MEMORY:-false}\",\"human_acceptance\":\"$HUMAN_ACCEPTANCE\",\"outcome\":\"$OUTCOME\",\"notes\":\"$NOTES\",\"collection_mode\":\"$COLLECTION_MODE\",\"evidence_level\":\"$EVIDENCE_LEVEL\",\"source_type\":\"$SOURCE_TYPE\",\"classifier_detected_sensitive\":\"$CLASSIFIER_DETECTED_SENSITIVE\",\"manual_sensitive_override\":\"$MANUAL_SENSITIVE_OVERRIDE\",\"classifier_false_negative\":\"$CLASSIFIER_FALSE_NEGATIVE\",\"classifier_detection_type\":\"$CLASSIFIER_DETECTION_TYPE\"}"
fi

# Append to file (non-blocking)
echo "$RECORD" >> "$METRICS_FILE" 2>/dev/null || {
  echo "[record-task-outcome] Warning: could not write to $METRICS_FILE" >&2
}

echo "[record-task-outcome] Recorded: $TASK_ID ($OUTCOME)"
