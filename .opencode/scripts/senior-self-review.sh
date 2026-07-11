#!/usr/bin/env bash
# Senior Self-Review Checklist (v4.22 → v4.23)
#
# Outputs a structured self-review checklist for the agent to complete before PR creation.
# Mandatory for STANDARD and HIGH-RISK. Optional for FAST. Skipped for DIRECT Lite.
#
# Usage: bash .opencode/scripts/senior-self-review.sh [repo-path] [changed-file-1...]
#
# When changed files are provided, the script also runs test discovery
# and includes evidence-based fields in the output.

set -uo pipefail

REPO_PATH="${1:-.}"
shift 2>/dev/null
CHANGED_FILES=("$@")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "SENIOR_SELF_REVIEW:"
echo ""

# If changed files are provided, run test discovery for evidence
if [ ${#CHANGED_FILES[@]} -gt 0 ] && [ -f "$SCRIPT_DIR/find-tests.sh" ]; then
  echo "EVIDENCE:"
  TEST_RESULT=$(bash "$SCRIPT_DIR/find-tests.sh" "$REPO_PATH" "${CHANGED_FILES[@]}" 2>&1 || true)
  FRAMEWORK=$(echo "$TEST_RESULT" | grep "^  framework:" | sed 's/.*: //')
  TEST_CMD=$(echo "$TEST_RESULT" | grep "^  test_command:" | sed 's/.*: //')
  NEARBY=$(echo "$TEST_RESULT" | grep "nearby_tests:" -A1 | tail -1)
  MISSING=$(echo "$TEST_RESULT" | grep "missing_tests:" -A1 | tail -1)
  echo "  files_changed: ${#CHANGED_FILES[@]}"
  echo "  test_framework: $FRAMEWORK"
  echo "  test_command: $TEST_CMD"
  echo "  nearby_tests: $NEARBY"
  echo "  missing_tests: $MISSING"
  echo "  tests_added: (report: yes — <files> / no — <justification>)"
  echo "  test_result: (report: pass / fail / not-run)"
  echo "  ci_status: (report: pending / passing / failed / not-configured)"
  echo "  patterns_checked: (report: yes / no — not required for this lane)"
  echo "  reused_pattern: (report: <pattern-name> from <source-repo> / none)"
  echo "  rejected_pattern_reason: (report: <reason> / n/a)"
  echo "  cross_project_lessons_count: (report: N / 0 / not-searched)"
  echo "  source_repos: (report: <repo-list> / n/a)"
  echo "  changed_behavior_detected: (report: yes — <description> / no — visual-only/config)"
  echo "  tests_missing: (report: N symbols lack coverage / 0 / not-checked)"
  echo "  tests_added_or_updated: (report: yes — <file list> / no — <justification>)"
  echo "  test_generation_skipped_reason: (report: <reason> / n/a)"
  echo "  proactive_issue_found: (report: <issue> / none)"
  echo "  recommended_followup: (report: <action> / none)"
  echo "  usage_tracked: (report: yes / no — not required for this lane)"
  echo "  model_used: (report: <model-name> / unknown)"
  echo "  reviewer_used: (report: yes / no / skipped — <reason>)"
  echo "  reviewer_value: (report: caught N issues / no material findings / not-used)"
  echo "  premium_model_used: (report: yes — <reason> / no)"
  echo "  cheaper_model_would_have_sufficed: (report: yes / no / unknown)"
  echo "  quota_or_capacity_issue: (report: <issue> / none)"
  echo "  routing_recommendation_next_time: (report: <recommendation> / same-as-current)"
  echo ""
fi

echo "CHECKLIST:"
echo ""
echo "1. Problem solved: Did the implementation solve the actual user request?"
echo "   (Not just 'did I write code' — did I solve the problem?)"
echo ""
echo "2. Scope discipline: Did I touch only necessary files?"
echo "   (No scope creep, no unrelated refactoring, no drive-by fixes)"
echo ""
echo "3. Risk classification: Did risk classification change during work?"
echo "   (If yes, re-run lite-mode-eligibility.sh and escalate if needed)"
echo ""
echo "4. Test expectation: Are tests needed? Were they added or updated?"
echo "   - Bug fix or logic change: tests required or explicit no-test justification"
echo "   - Refactor: existing tests or characterization tests required"
echo "   - DIRECT style/copy change: no test burden"
echo "   - HIGH-RISK: full test suite + reviewer required"
echo "   - No-test justification format: Tests: not added — <specific reason>"
echo ""
echo "5. Architecture decisions: Was any architecture or product decision made?"
echo "   (If yes, update PROJECT_MEMORY.md during /checkpoint)"
echo ""
echo "6. Code simplicity: Is there simpler code that achieves the same result?"
echo "   (No over-engineering, no premature abstraction, no unnecessary complexity)"
echo ""
echo "7. Tech debt: Did I create future tech debt?"
echo "   (TODOs, workarounds, shortcuts that need follow-up — document or fix)"
echo ""
echo "8. Rollback clarity: Is the rollback path clear and tested?"
echo "   (Type, scope, preconditions, action, verify — all five fields)"
echo ""
echo "9. PR accuracy: Will the PR description accurately reflect what changed?"
echo "   (No surprises for the reviewer — what they see is what they get)"
echo ""
echo "OUTCOME_TELEMETRY (v4.29):"
echo "  outcome_expected: (report: success / partial / failed / reverted)"
echo "  ci_first_try: (report: yes / no / not-applicable)"
echo "  repair_cycles: (report: N / 0)"
echo "  reviewer_found_material_issue: (report: yes — <description> / no / not-used)"
echo "  tests_caught_issue: (report: yes — <which tests> / no / not-applicable)"
echo "  memory_or_pattern_helped: (report: yes — <which memory> / no / not-checked)"
echo "  routing_recommendation_next_time: (report: <recommendation> / same-as-current)"
echo ""
echo "REVIEWER_CALIBRATION (v4.29.4):"
echo "  reviewer_value_classification: (report: material_issue_found / minor_issue_found / no_material_findings / false_positive / not_used)"
echo "  reviewer_issue_severity: (report: high — would cause regression / medium — improvement / low — style / n/a)"
echo "  reviewer_false_positive: (report: yes — <what was flagged incorrectly> / no / n/a)"
echo "  reviewer_recommendation_next_time: (report: use-reviewer / skip-reviewer / escalate-to-kimi / same-as-current)"
echo ""
echo "VERDICT: (pass / fix-needed / blocked)"
echo "  If any answer reveals a problem: fix before PR."
echo "  If all answers are satisfactory: proceed to quick-ship or PR creation."
