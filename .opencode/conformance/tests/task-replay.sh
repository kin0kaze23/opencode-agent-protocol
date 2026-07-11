#!/usr/bin/env bash
# task-replay.sh — v4.44 Agent Task Replay Eval Suite Conformance Tests
#
# Tests for task replay registry, replay runner, scoring engine,
# result schema, scorecard generation, and safety constraints.
#
# Usage: bash .opencode/conformance/tests/task-replay.sh

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

reset_counters

echo "=== v4.44 Agent Task Replay Eval Suite Conformance Tests ==="
echo ""

# ─── TR-001: task registry exists ───────────────────────────────────────
test_start "TR-001" "task registry exists"
assert_file_exists "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml" "Task registry exists"

# ─── TR-002: registry has version ──────────────────────────────────────
test_start "TR-002" "registry has version"
assert_file_contains "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml" "version:" "Registry has version field"

# ─── TR-003: registry has 9 benchmark tasks ─────────────────────────────
test_start "TR-003" "registry has 9 benchmark tasks"
TASK_COUNT=$(grep -c 'task_id:' "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml")
assert_equals "9" "$TASK_COUNT" "Registry has 9 benchmark tasks"

# ─── TR-004: all tasks have required fields ─────────────────────────────
test_start "TR-004" "all tasks have required fields"
REQUIRED_FIELDS=("task_id" "title" "repo_context" "task_type" "risk_lane" "historical_source" "input_prompt" "expected_root_cause" "expected_files_touched" "forbidden_files" "required_tests" "expected_evidence" "expected_reviewer_findings" "max_repair_cycles" "scoring_rubric")
ALL_FIELDS_PRESENT=true
for field in "${REQUIRED_FIELDS[@]}"; do
  # task_id is on the list item line (  - task_id:), others are at 4-space indent
  if [[ "$field" == "task_id" ]]; then
    FIELD_COUNT=$(grep -c "  - task_id:" "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml" 2>/dev/null)
  else
    FIELD_COUNT=$(grep -c "    $field:" "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml" 2>/dev/null)
  fi
  FIELD_COUNT=${FIELD_COUNT//[^0-9]/}
  FIELD_COUNT=${FIELD_COUNT:-0}
  if [[ "$FIELD_COUNT" -ne 9 ]]; then
    echo -e "  ${RED}✗${NC} Field '$field' appears $FIELD_COUNT times (expected 9)"
    ALL_FIELDS_PRESENT=false
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
done
if [[ "$ALL_FIELDS_PRESENT" == true ]]; then
  echo -e "  ${GREEN}✓${NC} All required fields present in all 9 tasks"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# ─── TR-005: protected-repo is excluded ──────────────────────────────────────
test_start "TR-005" "protected-repo is excluded"
assert_file_contains "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml" "excluded_repos:" "Registry has excluded_repos section"
assert_file_contains "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml" "protected-repo" "protected-repo is in exclusion list"

# ─── TR-006: no task references protected-repo as repo_context ────────────────
test_start "TR-006" "no task references protected-repo as repo_context"
PROTECTED_REPO_TASKS=$(grep 'repo_context:' "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml" | grep -ci "baby" 2>/dev/null)
PROTECTED_REPO_TASKS=${PROTECTED_REPO_TASKS//[^0-9]/}
PROTECTED_REPO_TASKS=${PROTECTED_REPO_TASKS:-0}
assert_equals "0" "$PROTECTED_REPO_TASKS" "No task has protected-repo as repo_context"

# ─── TR-007: replay runner exists ───────────────────────────────────────
test_start "TR-007" "replay runner exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" "Replay runner exists"

# ─── TR-008: runner has --dry-run mode ──────────────────────────────────
test_start "TR-008" "runner has --dry-run mode"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" "\-\-dry-run" "Runner has --dry-run flag"

# ─── TR-009: runner has --score-only mode ────────────────────────────────
test_start "TR-009" "runner has --score-only mode"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" "\-\-score-only" "Runner has --score-only flag"

# ─── TR-010: runner has --record-result mode ────────────────────────────
test_start "TR-010" "runner has --record-result mode"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" "\-\-record-result" "Runner has --record-result flag"

# ─── TR-011: runner has --apply mode ────────────────────────────────────
test_start "TR-011" "runner has --apply mode"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" "\-\-apply" "Runner has --apply flag"

# ─── TR-012: runner has --list-tasks mode ───────────────────────────────
test_start "TR-012" "runner has --list-tasks mode"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" "\-\-list-tasks" "Runner has --list-tasks flag"

# ─── TR-013: runner enforces protected-repo exclusion ────────────────────────
test_start "TR-013" "runner enforces protected-repo exclusion"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" "protected-repo is excluded" "Runner has protected-repo exclusion check"

# ─── TR-014: runner has forbidden files enforcement ────────────────────
test_start "TR-014" "runner has forbidden files enforcement"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" "forbidden" "Runner handles forbidden files"

# ─── TR-015: runner default mode is dry-run ─────────────────────────────
test_start "TR-015" "runner default mode is dry-run"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" 'MODE="dry-run"' "Runner defaults to dry-run"

# ─── TR-016: scoring script exists ──────────────────────────────────────
test_start "TR-016" "scoring script exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "Scoring script exists"

# ─── TR-017: scorer has all 7 score dimensions ──────────────────────────
test_start "TR-017" "scorer has all 7 score dimensions"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "root_cause_correct" "Scorer has root_cause_correct"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "minimal_diff" "Scorer has minimal_diff"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "test_quality" "Scorer has test_quality"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "ci_success" "Scorer has ci_success"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "security_risk_handling" "Scorer has security_risk_handling"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "evidence_quality" "Scorer has evidence_quality"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "lesson_reuse" "Scorer has lesson_reuse"

# ─── TR-018: scorer has reviewer issue penalty ──────────────────────────
test_start "TR-018" "scorer has reviewer issue penalty"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "reviewer_issue_count" "Scorer has reviewer_issue_count"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "REVIEWER_PENALTY" "Scorer calculates reviewer penalty"

# ─── TR-019: scorer has repair cycle penalty ────────────────────────────
test_start "TR-019" "scorer has repair cycle penalty"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "repair_cycles" "Scorer has repair_cycles"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "REPAIR_PENALTY" "Scorer calculates repair penalty"

# ─── TR-020: scorer has time cost tracking ──────────────────────────────
test_start "TR-020" "scorer has time cost tracking"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "time_cost" "Scorer tracks time cost"

# ─── TR-021: scorer has pass threshold ──────────────────────────────────
test_start "TR-021" "scorer has pass threshold"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "PASS_THRESHOLD" "Scorer has pass threshold"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "24" "Pass threshold is 24"

# ─── TR-022: scorer outputs JSON ────────────────────────────────────────
test_start "TR-022" "scorer outputs JSON"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" ".json" "Scorer outputs JSON"

# ─── TR-023: scorer outputs markdown ────────────────────────────────────
test_start "TR-023" "scorer outputs markdown"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" ".md" "Scorer outputs markdown"

# ─── TR-024: scorer validates result JSON ───────────────────────────────
test_start "TR-024" "scorer validates result JSON"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "jq empty" "Scorer validates JSON"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "not valid JSON" "Scorer rejects invalid JSON"

# ─── TR-025: scorer checks required fields ──────────────────────────────
test_start "TR-025" "scorer checks required fields"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "REQUIRED_FIELDS" "Scorer checks required fields"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "missing required field" "Scorer reports missing fields"

# ─── TR-026: scorer enforces protected-repo exclusion ────────────────────────
test_start "TR-026" "scorer enforces protected-repo exclusion"
assert_file_contains "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" "protected-repo" "Scorer checks for protected-repo"

# ─── TR-027: results directory exists ───────────────────────────────────
test_start "TR-027" "results directory exists"
if [[ -d "$ROOT_DIR/.opencode/evals/task-replay/results/" ]]; then
  echo -e "  ${GREEN}✓${NC} Results directory exists: $ROOT_DIR/.opencode/evals/task-replay/results/"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Results directory NOT FOUND: $ROOT_DIR/.opencode/evals/task-replay/results/"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── TR-028: scorecard generator exists ─────────────────────────────────
test_start "TR-028" "scorecard generator exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/generate-task-replay-scorecard.sh" "Scorecard generator exists"

# ─── TR-029: scorecard outputs markdown ─────────────────────────────────
test_start "TR-029" "scorecard outputs markdown"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-task-replay-scorecard.sh" "task-replay-scorecard.md" "Scorecard outputs markdown"

# ─── TR-030: scorecard outputs JSON ─────────────────────────────────────
test_start "TR-030" "scorecard outputs JSON"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-task-replay-scorecard.sh" "task-replay-scorecard.json" "Scorecard outputs JSON"

# ─── TR-031: scorecard has by_model breakdown ────────────────────────────
test_start "TR-031" "scorecard has by_model breakdown"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-task-replay-scorecard.sh" "by_model" "Scorecard has by_model section"

# ─── TR-032: scorecard has by_task_type breakdown ───────────────────────
test_start "TR-032" "scorecard has by_task_type breakdown"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-task-replay-scorecard.sh" "by_task_type" "Scorecard has by_task_type section"

# ─── TR-033: scorecard has common failure patterns ──────────────────────
test_start "TR-033" "scorecard has common failure patterns"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-task-replay-scorecard.sh" "common_failures" "Scorecard has common_failures section"

# ─── TR-034: scorecard has pass rate ────────────────────────────────────
test_start "TR-034" "scorecard has pass rate"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-task-replay-scorecard.sh" "pass_rate" "Scorecard has pass_rate"

# ─── TR-035: scorecard has best model per task ──────────────────────────
test_start "TR-035" "scorecard has best model per task"
assert_file_contains "$ROOT_DIR/.opencode/scripts/generate-task-replay-scorecard.sh" "best_model" "Scorecard has best_model"

# ─── TR-036: dry-run does not mutate repos ──────────────────────────────
test_start "TR-036" "dry-run does not mutate repos"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" "No repos will be mutated" "Dry-run mode does not mutate repos"

# ─── TR-037: --apply requires explicit approval ─────────────────────────
test_start "TR-037" "apply requires explicit approval"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" "DANGEROUS" "Apply mode is marked dangerous"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" "explicit owner approval" "Apply requires explicit approval"

# ─── TR-038: runner --list-tasks works ──────────────────────────────────
test_start "TR-038" "runner --list-tasks works"
LIST_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" --list-tasks 2>&1)
assert_output_contains "$LIST_OUTPUT" "TR-001" "List shows TR-001"
assert_output_contains "$LIST_OUTPUT" "TR-009" "List shows TR-009"
assert_output_contains "$LIST_OUTPUT" "Total tasks: 9" "List shows total count"

# ─── TR-039: dry-run produces task details ───────────────────────────────
test_start "TR-039" "dry-run produces task details"
DRYRUN_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" --task TR-001 --dry-run 2>&1)
assert_output_contains "$DRYRUN_OUTPUT" "DRY RUN" "Dry-run shows DRY RUN header"
assert_output_contains "$DRYRUN_OUTPUT" "Expected Root Cause" "Dry-run shows expected root cause"
assert_output_contains "$DRYRUN_OUTPUT" "Forbidden Files" "Dry-run shows forbidden files"
assert_output_contains "$DRYRUN_OUTPUT" "Required Tests" "Dry-run shows required tests"
assert_output_contains "$DRYRUN_OUTPUT" "Scoring Rubric" "Dry-run shows scoring rubric"

# ─── TR-040: dry-run shows protected-repo safety check ────────────────────────
test_start "TR-040" "dry-run shows protected-repo safety check"
assert_output_contains "$DRYRUN_OUTPUT" "protected-repo exclusion" "Dry-run shows protected-repo exclusion"

# ─── TR-041: record-result creates result template ──────────────────────
test_start "TR-041" "record-result creates result template"
RECORD_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" --task TR-003 --record-result 2>&1)
assert_output_contains "$RECORD_OUTPUT" "RECORD RESULT" "Record mode shows header"
assert_output_contains "$RECORD_OUTPUT" "Result template created" "Record mode creates template"

# Verify the template file was created and is valid JSON
LATEST_RESULT=$(ls -t "$ROOT_DIR/.opencode/evals/task-replay/results/TR-003_"*.json 2>/dev/null | head -1)
if [[ -n "$LATEST_RESULT" ]] && jq empty "$LATEST_RESULT" 2>/dev/null; then
  echo -e "  ${GREEN}✓${NC} Result template is valid JSON: $LATEST_RESULT"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Result template is not valid JSON or not found"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Verify template has required fields
if [[ -n "$LATEST_RESULT" ]]; then
  for field in task_id model agent started_at scoring final_score pass; do
    if jq -e --arg f "$field" 'has($f)' "$LATEST_RESULT" >/dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} Template has field: $field"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "  ${RED}✗${NC} Template missing field: $field"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  done
fi

# ─── TR-042: score-only works on existing result ─────────────────────────
test_start "TR-042" "score-only works on existing result"
if [[ -n "$LATEST_RESULT" ]]; then
  SCORE_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/run-task-replay-eval.sh" --task TR-003 --score-only --result-file "$LATEST_RESULT" 2>&1)
  assert_output_contains "$SCORE_OUTPUT" "FINAL SCORE" "Score-only produces final score"
  assert_output_contains "$SCORE_OUTPUT" "SCORING COMPLETE" "Score-only completes"
else
  echo -e "  ${RED}✗${NC} No result file to score"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── TR-043: scorer rejects malformed result ────────────────────────────
test_start "TR-043" "scorer rejects malformed result"
MALFORMED_FILE="/tmp/malformed-result-$$.json"
echo '{"task_id": "TR-003", "model": "test", "agent": "test", "started_at": "2026-01-01", "scoring": {}}' > "$MALFORMED_FILE"
# This should still work but with 0 scores — test that it doesn't crash
SCORE_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" --task TR-003 --result-file "$MALFORMED_FILE" 2>&1)
SCORE_EXIT=$?
if [[ $SCORE_EXIT -eq 0 ]]; then
  echo -e "  ${GREEN}✓${NC} Scorer handles minimal result without crash"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Scorer crashed on minimal result (exit $SCORE_EXIT)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f "$MALFORMED_FILE"

# ─── TR-044: scorer rejects invalid JSON ────────────────────────────────
test_start "TR-044" "scorer rejects invalid JSON"
INVALID_FILE="/tmp/invalid-result-$$.json"
echo 'not json at all' > "$INVALID_FILE"
INVALID_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" --task TR-003 --result-file "$INVALID_FILE" 2>&1)
INVALID_EXIT=$?
if [[ $INVALID_EXIT -ne 0 ]]; then
  echo -e "  ${GREEN}✓${NC} Scorer rejects invalid JSON (exit $INVALID_EXIT)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Scorer accepted invalid JSON"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f "$INVALID_FILE"

# ─── TR-045: missing evidence lowers score ──────────────────────────────
test_start "TR-045" "missing evidence lowers score"
# Create a result with 0 evidence quality
LOW_EVIDENCE_FILE="/tmp/low-evidence-result-$$.json"
cat > "$LOW_EVIDENCE_FILE" << 'EOFD'
{
  "task_id": "TR-003",
  "title": "Test",
  "task_type": "bug_fix",
  "risk_lane": "FAST",
  "repo_context": "control-plane",
  "model": "test-model",
  "agent": "test-agent",
  "started_at": "2026-01-01T00:00:00Z",
  "completed_at": "2026-01-01T00:05:00Z",
  "tokens_used": 1000,
  "cost_usd": 0.01,
  "repair_cycles": 0,
  "tests_run": 5,
  "tests_passed": 5,
  "tests_failed": 0,
  "reviewer_used": false,
  "reviewer_findings": [],
  "files_touched": ["test.ts"],
  "diff_summary": "fixed bug",
  "root_cause_identified": true,
  "root_cause_description": "found it",
  "evidence_provided": [],
  "security_sensitive": false,
  "lessons_extracted": [],
  "scoring": {
    "root_cause_correct": 5,
    "minimal_diff": 5,
    "test_quality": 5,
    "ci_success": 5,
    "security_risk_handling": 5,
    "evidence_quality": 0,
    "lesson_reuse": 5,
    "reviewer_issue_count": 0,
    "repair_cycles_penalty": 0,
    "time_cost_seconds": 300
  },
  "final_score": 0,
  "max_possible_score": 35,
  "pass": false,
  "notes": "low evidence test"
}
EOFD
LOW_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" --task TR-003 --result-file "$LOW_EVIDENCE_FILE" 2>&1)
LOW_SCORE=$(echo "$LOW_OUTPUT" | grep "FINAL SCORE" | awk '{print $3}' | cut -d/ -f1)
if [[ "$LOW_SCORE" -lt 35 ]]; then
  echo -e "  ${GREEN}✓${NC} Missing evidence lowers score: $LOW_SCORE/35 (expected < 35)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Missing evidence did not lower score: $LOW_SCORE/35"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f "$LOW_EVIDENCE_FILE"

# ─── TR-046: reviewer issue penalty works ────────────────────────────────
test_start "TR-046" "reviewer issue penalty works"
HIGH_REVIEWER_FILE="/tmp/high-reviewer-result-$$.json"
cat > "$HIGH_REVIEWER_FILE" << 'EOFD'
{
  "task_id": "TR-003",
  "title": "Test",
  "task_type": "bug_fix",
  "risk_lane": "FAST",
  "repo_context": "control-plane",
  "model": "test-model",
  "agent": "test-agent",
  "started_at": "2026-01-01T00:00:00Z",
  "completed_at": "2026-01-01T00:05:00Z",
  "tokens_used": 1000,
  "cost_usd": 0.01,
  "repair_cycles": 0,
  "tests_run": 5,
  "tests_passed": 5,
  "tests_failed": 0,
  "reviewer_used": true,
  "reviewer_findings": ["issue1", "issue2", "issue3"],
  "files_touched": ["test.ts"],
  "diff_summary": "fixed bug",
  "root_cause_identified": true,
  "root_cause_description": "found it",
  "evidence_provided": ["diff"],
  "security_sensitive": false,
  "lessons_extracted": [],
  "scoring": {
    "root_cause_correct": 5,
    "minimal_diff": 5,
    "test_quality": 5,
    "ci_success": 5,
    "security_risk_handling": 5,
    "evidence_quality": 5,
    "lesson_reuse": 5,
    "reviewer_issue_count": 3,
    "repair_cycles_penalty": 0,
    "time_cost_seconds": 300
  },
  "final_score": 0,
  "max_possible_score": 35,
  "pass": false,
  "notes": "high reviewer test"
}
EOFD
HIGH_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" --task TR-003 --result-file "$HIGH_REVIEWER_FILE" 2>&1)
HIGH_SCORE=$(echo "$HIGH_OUTPUT" | grep "FINAL SCORE" | awk '{print $3}' | cut -d/ -f1)
# 35 - 6 (3 issues * 2) = 29
if [[ "$HIGH_SCORE" -eq 29 ]]; then
  echo -e "  ${GREEN}✓${NC} Reviewer penalty works: 35 - 6 = $HIGH_SCORE/35"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Reviewer penalty wrong: expected 29, got $HIGH_SCORE"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f "$HIGH_REVIEWER_FILE"

# ─── TR-047: repair cycle penalty works ──────────────────────────────────
test_start "TR-047" "repair cycle penalty works"
REPAIR_FILE="/tmp/repair-result-$$.json"
cat > "$REPAIR_FILE" << 'EOFD'
{
  "task_id": "TR-003",
  "title": "Test",
  "task_type": "bug_fix",
  "risk_lane": "FAST",
  "repo_context": "control-plane",
  "model": "test-model",
  "agent": "test-agent",
  "started_at": "2026-01-01T00:00:00Z",
  "completed_at": "2026-01-01T00:05:00Z",
  "tokens_used": 1000,
  "cost_usd": 0.01,
  "repair_cycles": 2,
  "tests_run": 5,
  "tests_passed": 5,
  "tests_failed": 0,
  "reviewer_used": false,
  "reviewer_findings": [],
  "files_touched": ["test.ts"],
  "diff_summary": "fixed bug",
  "root_cause_identified": true,
  "root_cause_description": "found it",
  "evidence_provided": ["diff"],
  "security_sensitive": false,
  "lessons_extracted": [],
  "scoring": {
    "root_cause_correct": 5,
    "minimal_diff": 5,
    "test_quality": 5,
    "ci_success": 5,
    "security_risk_handling": 5,
    "evidence_quality": 5,
    "lesson_reuse": 5,
    "reviewer_issue_count": 0,
    "repair_cycles_penalty": 0,
    "time_cost_seconds": 300
  },
  "final_score": 0,
  "max_possible_score": 35,
  "pass": false,
  "notes": "repair cycle test"
}
EOFD
REPAIR_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/score-task-replay.sh" --task TR-003 --result-file "$REPAIR_FILE" 2>&1)
REPAIR_SCORE=$(echo "$REPAIR_OUTPUT" | grep "FINAL SCORE" | awk '{print $3}' | cut -d/ -f1)
# 35 - 6 (2 cycles * 3) = 29
if [[ "$REPAIR_SCORE" -eq 29 ]]; then
  echo -e "  ${GREEN}✓${NC} Repair cycle penalty works: 35 - 6 = $REPAIR_SCORE/35"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Repair cycle penalty wrong: expected 29, got $REPAIR_SCORE"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
rm -f "$REPAIR_FILE"

# ─── TR-048: scorecard generates with no results ─────────────────────────
test_start "TR-048" "scorecard generates with no results"
SCORECARD_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/generate-task-replay-scorecard.sh" 2>&1)
SCORECARD_EXIT=$?
if [[ $SCORECARD_EXIT -eq 0 ]]; then
  echo -e "  ${GREEN}✓${NC} Scorecard generates without crash (exit 0)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Scorecard crashed with no results (exit $SCORECARD_EXIT)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
# Verify scorecard files exist
assert_file_exists "$ROOT_DIR/reports/task-replay-scorecard.json" "Scorecard JSON exists"
assert_file_exists "$ROOT_DIR/reports/task-replay-scorecard.md" "Scorecard markdown exists"

# ─── TR-049: scorecard has summary section ──────────────────────────────
test_start "TR-049" "scorecard has summary section"
assert_file_contains "$ROOT_DIR/reports/task-replay-scorecard.md" "## Summary" "Scorecard has Summary section"
assert_file_contains "$ROOT_DIR/reports/task-replay-scorecard.md" "Pass rate" "Scorecard has pass rate"

# ─── TR-050: all task IDs are unique ────────────────────────────────────
test_start "TR-050" "all task IDs are unique"
TASK_IDS=$(grep 'task_id:' "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml" | sed 's/.*task_id: "//' | sed 's/".*//')
UNIQUE_IDS=$(echo "$TASK_IDS" | sort -u | wc -l | tr -d ' ')
TOTAL_IDS=$(echo "$TASK_IDS" | wc -l | tr -d ' ')
assert_equals "$TOTAL_IDS" "$UNIQUE_IDS" "All task IDs are unique"

# ─── TR-051: all tasks have forbidden_files including protected-repo ──────────
test_start "TR-051" "all tasks have protected-repo in forbidden_files"
PROTECTED_REPO_FORBIDDEN_COUNT=$(awk '
  /^  - task_id:/ { task_id=$0; gsub(/.*task_id: "/, "", task_id); gsub(/".*/, "", task_id); has_baby=0; in_forbidden=0 }
  /forbidden_files:/ { in_forbidden=1; next }
  in_forbidden && /protected-repo/ { has_baby=1 }
  in_forbidden && /^    [a-z]/ && !/forbidden_files/ {
    if (has_baby==1) { count++ }
    in_forbidden=0
  }
  END { print count+0 }
' "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml")
assert_equals "9" "$PROTECTED_REPO_FORBIDDEN_COUNT" "All 9 tasks forbid protected-repo"

# ─── TR-052: registry has scoring rubric ────────────────────────────────
test_start "TR-052" "registry has scoring rubric"
assert_file_contains "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml" "default_scoring_rubric:" "Registry has default scoring rubric"
assert_file_contains "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml" "root_cause_correct:" "Rubric has root_cause_correct"
assert_file_contains "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml" "reviewer_issue_count:" "Rubric has reviewer_issue_count"
assert_file_contains "$ROOT_DIR/.opencode/evals/task-replay/tasks.yaml" "time_cost:" "Rubric has time_cost"

# ─── Report ──────────────────────────────────────────────────────────────
echo ""
report_results "$ROOT_DIR/.opencode/conformance/results/task-replay-results.md"
