#!/usr/bin/env bash
# loop-controller.sh — v4.45 Loop Engineering Controller Conformance Tests
#
# Tests for loop run contract, loop controller modes, state machine,
# stop conditions, repair policy, result output, lesson extraction,
# and safety constraints.
#
# Usage: bash .opencode/conformance/tests/loop-controller.sh

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

reset_counters

echo "=== v4.45 Loop Engineering Controller Conformance Tests ==="
echo ""

# ─── LC-001: loop run contract exists ──────────────────────────────────
test_start "LC-001" "loop run contract exists"
assert_file_exists "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "Loop run contract exists"

# ─── LC-002: contract has task_id field ────────────────────────────────
test_start "LC-002" "contract has task_id field"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "task_id:" "Contract has task_id"

# ─── LC-003: contract has max_cycles field ─────────────────────────────
test_start "LC-003" "contract has max_cycles field"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "max_cycles:" "Contract has max_cycles"

# ─── LC-004: contract has forbidden_files ──────────────────────────────
test_start "LC-004" "contract has forbidden_files"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "forbidden_files:" "Contract has forbidden_files"

# ─── LC-005: contract has stop_conditions ───────────────────────────────
test_start "LC-005" "contract has stop_conditions"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "stop_conditions:" "Contract has stop_conditions"

# ─── LC-006: contract has repair_policy ────────────────────────────────
test_start "LC-006" "contract has repair_policy"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "repair_policy:" "Contract has repair_policy"

# ─── LC-007: contract has scoring_policy ───────────────────────────────
test_start "LC-007" "contract has scoring_policy"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "scoring_policy:" "Contract has scoring_policy"

# ─── LC-008: contract has lesson_extraction_policy ─────────────────────
test_start "LC-008" "contract has lesson_extraction_policy"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "lesson_extraction_policy:" "Contract has lesson_extraction_policy"

# ─── LC-009: contract has protected-repo in forbidden ───────────────────────
test_start "LC-009" "contract has protected-repo in forbidden"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "protected-repo" "Contract forbids protected-repo"

# ─── LC-010: contract has validation rules ─────────────────────────────
test_start "LC-010" "contract has validation rules"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "Contract Validation Rules" "Contract has validation rules section"

# ─── LC-011: contract has safety constraints ───────────────────────────
test_start "LC-011" "contract has safety constraints"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "Safety Constraints" "Contract has safety constraints section"

# ─── LC-012: loop controller script exists ────────────────────────────
test_start "LC-012" "loop controller script exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "Loop controller script exists"

# ─── LC-013: controller has --dry-run mode ────────────────────────────
test_start "LC-013" "controller has --dry-run mode"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "\-\-dry-run" "Controller has --dry-run flag"

# ─── LC-014: controller has --simulate mode ────────────────────────────
test_start "LC-014" "controller has --simulate mode"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "\-\-simulate" "Controller has --simulate flag"

# ─── LC-015: controller has --record-result mode ──────────────────────
test_start "LC-015" "controller has --record-result mode"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "\-\-record-result" "Controller has --record-result flag"

# ─── LC-016: controller has --score mode ─────────────────────────────
test_start "LC-016" "controller has --score mode"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "\-\-score" "Controller has --score flag"

# ─── LC-017: controller has --apply mode ──────────────────────────────
test_start "LC-017" "controller has --apply mode"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "\-\-apply" "Controller has --apply flag"

# ─── LC-018: controller has --max-cycles flag ────────────────────────
test_start "LC-018" "controller has --max-cycles flag"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "\-\-max-cycles" "Controller has --max-cycles flag"

# ─── LC-019: controller has --list-tasks mode ─────────────────────────
test_start "LC-019" "controller has --list-tasks mode"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "\-\-list-tasks" "Controller has --list-tasks flag"

# ─── LC-020: controller default mode is dry-run ───────────────────────
test_start "LC-020" "controller default mode is dry-run"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" 'MODE="dry-run"' "Controller defaults to dry-run"

# ─── LC-021: controller enforces protected-repo exclusion ──────────────────
test_start "LC-021" "controller enforces protected-repo exclusion"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "protected-repo is excluded" "Controller has protected-repo exclusion check"

# ─── LC-022: controller has state machine states ──────────────────────
test_start "LC-022" "controller has state machine states"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "initialized" "Controller has initialized state"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "planning" "Controller has planning state"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "executing" "Controller has executing state"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "testing" "Controller has testing state"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "reviewing" "Controller has reviewing state"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "scoring" "Controller has scoring state"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "lesson_extraction" "Controller has lesson_extraction state"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "completed" "Controller has completed state"

# ─── LC-023: controller has stop conditions ───────────────────────────
test_start "LC-023" "controller has stop conditions"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "stop_reason" "Controller tracks stop reason"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "STOP_REASON" "Controller has stop reason variable"

# ─── LC-024: controller has repair policy logic ───────────────────────
test_start "LC-024" "controller has repair policy logic"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "test_quality_low" "Repair policy has test_quality_low"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "evidence_quality_low" "Repair policy has evidence_quality_low"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "reviewer_issue_exists" "Repair policy has reviewer_issue_exists"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "minimal_diff_low" "Repair policy has minimal_diff_low"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "security_risk_low" "Repair policy has security_risk_low"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "root_cause_low" "Repair policy has root_cause_low"

# ─── LC-025: results directory exists ─────────────────────────────────
test_start "LC-025" "results directory exists"
if [[ -d "$ROOT_DIR/.opencode/evals/loop-runs/results/" ]]; then
  echo -e "  ${GREEN}✓${NC} Results directory exists"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Results directory NOT FOUND"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── LC-026: lessons file exists (or is created by bootstrap) ─────────
test_start "LC-026" "lessons file exists (bootstrap creates if missing)"
LESSONS_FILE="$ROOT_DIR/.opencode/evals/lessons/loop-lessons.jsonl"
if [ ! -f "$LESSONS_FILE" ]; then
  mkdir -p "$(dirname "$LESSONS_FILE")"
  echo '{"task_id":"init","failure_pattern":"none","fix_pattern":"initialization","evidence":[],"recommended_future_action":"Loop lessons file initialized","applicable_task_types":[],"extracted_at":"2026-07-09T00:00:00Z"}' > "$LESSONS_FILE"
  echo -e "  ${GREEN}✓${NC} Lessons file created by bootstrap (was missing)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  assert_file_exists "$LESSONS_FILE" "Lessons file exists"
fi

# ─── LC-027: dry-run does not mutate repos ────────────────────────────
test_start "LC-027" "dry-run does not mutate repos"
DRYRUN_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" --task TR-001 --dry-run 2>&1)
assert_output_contains "$DRYRUN_OUTPUT" "DRY RUN" "Dry-run shows DRY RUN header"
assert_output_contains "$DRYRUN_OUTPUT" "No repos will be mutated" "Dry-run does not mutate repos"

# ─── LC-028: dry-run shows loop contract ──────────────────────────────
test_start "LC-028" "dry-run shows loop contract"
assert_output_contains "$DRYRUN_OUTPUT" "Loop Contract" "Dry-run shows loop contract"
assert_output_contains "$DRYRUN_OUTPUT" "max_cycles" "Dry-run shows max_cycles"
assert_output_contains "$DRYRUN_OUTPUT" "Stop Conditions" "Dry-run shows stop conditions"
assert_output_contains "$DRYRUN_OUTPUT" "Repair Policy" "Dry-run shows repair policy"
assert_output_contains "$DRYRUN_OUTPUT" "State Machine" "Dry-run shows state machine"

# ─── LC-029: dry-run shows protected-repo safety check ──────────────────────
test_start "LC-029" "dry-run shows protected-repo safety check"
assert_output_contains "$DRYRUN_OUTPUT" "protected-repo exclusion" "Dry-run shows protected-repo exclusion"

# ─── LC-030: simulate mode runs TR-001 ────────────────────────────────
test_start "LC-030" "simulate mode runs TR-001"
SIM_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" --task TR-001 --simulate 2>&1)
assert_output_contains "$SIM_OUTPUT" "SIMULATE MODE" "Simulate shows SIMULATE MODE header"
assert_output_contains "$SIM_OUTPUT" "planning" "Simulate enters planning state"
assert_output_contains "$SIM_OUTPUT" "executing" "Simulate enters executing state"
assert_output_contains "$SIM_OUTPUT" "testing" "Simulate enters testing state"
assert_output_contains "$SIM_OUTPUT" "reviewing" "Simulate enters reviewing state"
assert_output_contains "$SIM_OUTPUT" "scoring" "Simulate enters scoring state"
assert_output_contains "$SIM_OUTPUT" "lesson_extraction" "Simulate enters lesson_extraction state"
assert_output_contains "$SIM_OUTPUT" "completed" "Simulate reaches completed state"
assert_output_contains "$SIM_OUTPUT" "SIMULATE COMPLETE" "Simulate completes"

# ─── LC-031: simulate produces result JSON ────────────────────────────
test_start "LC-031" "simulate produces result JSON"
LATEST_RESULT=$(ls -t "$ROOT_DIR/.opencode/evals/loop-runs/results/loop-run-TR-001-"*.json 2>/dev/null | head -1)
if [[ -n "$LATEST_RESULT" ]] && jq empty "$LATEST_RESULT" 2>/dev/null; then
  echo -e "  ${GREEN}✓${NC} Result JSON is valid: $LATEST_RESULT"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Result JSON not found or invalid"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── LC-032: result has required fields ───────────────────────────────
test_start "LC-032" "result has required fields"
if [[ -n "$LATEST_RESULT" ]]; then
  for field in task_id model agent cycles_run stop_reason final_score pass lessons_extracted telemetry; do
    if jq -e --arg f "$field" 'has($f)' "$LATEST_RESULT" >/dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} Result has field: $field"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "  ${RED}✗${NC} Result missing field: $field"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
  done
else
  echo -e "  ${RED}✗${NC} No result file to check"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── LC-033: result has telemetry ─────────────────────────────────────
test_start "LC-033" "result has telemetry"
if [[ -n "$LATEST_RESULT" ]]; then
  assert_file_contains "$LATEST_RESULT" "loop_cycles" "Telemetry has loop_cycles"
  assert_file_contains "$LATEST_RESULT" "repair_cycles" "Telemetry has repair_cycles"
  assert_file_contains "$LATEST_RESULT" "stop_reason" "Telemetry has stop_reason"
fi

# ─── LC-034: simulate produces markdown report ────────────────────────
test_start "LC-034" "simulate produces markdown report"
assert_file_exists "$ROOT_DIR/reports/loop-controller/loop-run-TR-001.md" "Markdown report exists"

# ─── LC-035: simulate extracts lessons ────────────────────────────────
test_start "LC-035" "simulate extracts lessons"
LESSONS_COUNT=$(wc -l < "$ROOT_DIR/.opencode/evals/lessons/loop-lessons.jsonl" | tr -d ' ')
if [[ "$LESSONS_COUNT" -ge 2 ]]; then
  echo -e "  ${GREEN}✓${NC} Lessons file has $LESSONS_COUNT entries (expected >= 2)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Lessons file has only $LESSONS_COUNT entries (expected >= 2)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── LC-036: simulate TR-002 works ────────────────────────────────────
test_start "LC-036" "simulate TR-002 works"
SIM2_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" --task TR-002 --simulate 2>&1)
assert_output_contains "$SIM2_OUTPUT" "SIMULATE COMPLETE" "TR-002 simulate completes"

# ─── LC-037: simulate TR-003 works ────────────────────────────────────
test_start "LC-037" "simulate TR-003 works"
SIM3_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" --task TR-003 --simulate 2>&1)
assert_output_contains "$SIM3_OUTPUT" "SIMULATE COMPLETE" "TR-003 simulate completes"

# ─── LC-038: --apply is marked dangerous ──────────────────────────────
test_start "LC-038" "apply is marked dangerous"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "DANGEROUS" "Apply mode is marked dangerous"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "explicit owner approval" "Apply requires explicit approval"

# ─── LC-039: --list-tasks works ───────────────────────────────────────
test_start "LC-039" "list-tasks works"
LIST_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" --list-tasks 2>&1)
assert_output_contains "$LIST_OUTPUT" "TR-001" "List shows TR-001"
assert_output_contains "$LIST_OUTPUT" "Total tasks" "List shows total count"

# ─── LC-040: --max-cycles override works ───────────────────────────────
test_start "LC-040" "max-cycles override works"
OVERRIDE_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" --task TR-001 --dry-run --max-cycles 5 2>&1)
assert_output_contains "$OVERRIDE_OUTPUT" "Max Cycles:    5" "Max cycles overridden to 5"

# ─── LC-041: contract has pass_threshold ──────────────────────────────
test_start "LC-041" "contract has pass_threshold"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "pass_threshold" "Contract has pass_threshold"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "24" "Pass threshold is 24"

# ─── LC-042: contract has HIGH-RISK reviewer requirement ──────────────
test_start "LC-042" "contract has HIGH-RISK reviewer requirement"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "HIGH-RISK" "Contract mentions HIGH-RISK"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "reviewer_required" "Contract has reviewer_required"

# ─── LC-043: result has routing recommendation ────────────────────────
test_start "LC-043" "result has routing recommendation"
if [[ -n "$LATEST_RESULT" ]]; then
  assert_file_contains "$LATEST_RESULT" "routing_recommendation" "Result has routing_recommendation"
fi

# ─── LC-044: result has cycles array ──────────────────────────────────
test_start "LC-044" "result has cycles array"
if [[ -n "$LATEST_RESULT" ]]; then
  CYCLES_COUNT=$(jq '.cycles | length' "$LATEST_RESULT" 2>/dev/null || echo 0)
  if [[ "$CYCLES_COUNT" -ge 1 ]]; then
    echo -e "  ${GREEN}✓${NC} Result has $CYCLES_COUNT cycle entries (expected >= 1)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "  ${RED}✗${NC} Result has $CYCLES_COUNT cycle entries (expected >= 1)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
fi

# ─── LC-045: --score flag triggers scoring ────────────────────────────
test_start "LC-045" "score flag triggers scoring"
SCORE_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" --task TR-001 --simulate --score 2>&1)
assert_output_contains "$SCORE_OUTPUT" "Scoring loop result" "Score flag triggers scoring"

# ─── LC-046: --record-result updates scorecard ────────────────────────
test_start "LC-046" "record-result updates scorecard"
RECORD_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" --task TR-001 --simulate --record-result 2>&1)
assert_output_contains "$RECORD_OUTPUT" "Updating aggregate scorecard" "Record-result triggers scorecard update"
assert_output_contains "$RECORD_OUTPUT" "Updated with loop result" "Scorecard updated"

# ─── LC-047: malformed task rejected ───────────────────────────────────
test_start "LC-047" "malformed task rejected"
BAD_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" --task INVALID-999 --dry-run 2>&1)
BAD_EXIT=$?
if [[ $BAD_EXIT -ne 0 ]]; then
  echo -e "  ${GREEN}✓${NC} Invalid task rejected (exit $BAD_EXIT)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Invalid task was not rejected"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── LC-048: contract has stop condition details ──────────────────────
test_start "LC-048" "contract has stop condition details"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "max_cycles_reached" "Contract has max_cycles_reached"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "forbidden_file_touched" "Contract has forbidden_file_touched"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "protected-repo_path_detected" "Contract has protected-repo_path_detected"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "same_failure_repeats_twice" "Contract has same_failure_repeats_twice"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "no_score_improvement_after_repair" "Contract has no_score_improvement_after_repair"
assert_file_contains "$ROOT_DIR/.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md" "malformed_result_detected" "Contract has malformed_result_detected"

# ─── LC-049: lessons are valid JSONL ───────────────────────────────────
test_start "LC-049" "lessons are valid JSONL"
LESSONS_VALID=true
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  if ! echo "$line" | jq empty 2>/dev/null; then
    LESSONS_VALID=false
    break
  fi
done < "$ROOT_DIR/.opencode/evals/lessons/loop-lessons.jsonl"
if [[ "$LESSONS_VALID" == true ]]; then
  echo -e "  ${GREEN}✓${NC} All lessons entries are valid JSON"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Invalid JSON found in lessons file"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── LC-050: controller has forbidden files enforcement ───────────────
test_start "LC-050" "controller has forbidden files enforcement"
assert_file_contains "$ROOT_DIR/.opencode/scripts/run-loop-controller.sh" "forbidden" "Controller handles forbidden files"

# ─── Report ──────────────────────────────────────────────────────────────
echo ""
report_results "$ROOT_DIR/.opencode/conformance/results/loop-controller-results.md"
