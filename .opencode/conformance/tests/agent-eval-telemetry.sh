#!/usr/bin/env bash
# agent-eval-telemetry.sh — Conformance test for v4.29 agent eval telemetry
#
# Verifies:
# - task-outcomes.jsonl path is documented and gitignored
# - record-task-outcome.sh exists and is executable
# - summarize-agent-quality.sh exists and is executable
# - checkpoint.md references telemetry for STANDARD/HIGH-RISK
# - DIRECT Lite is not bloated with telemetry
# - senior-self-review includes outcome/repair/reviewer/memory fields
# - scorecard doc exists
# - telemetry avoids secrets (no secret fields in schema)
# - scripts tolerate missing optional data

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

RESULT_FILE="$ROOT_DIR/.opencode/conformance/results/agent-eval-telemetry-$(date +%Y%m%d-%H%M%S).md"

# ============================================================
# AET-001: Telemetry file path is gitignored
# ============================================================
test_start "AET-001" "task-outcomes.jsonl is gitignored"
assert_file_contains "$ROOT_DIR/.gitignore" "task-outcomes.jsonl" "gitignore covers task-outcomes.jsonl"

# ============================================================
# AET-002: record-task-outcome.sh exists and is executable
# ============================================================
test_start "AET-002" "record-task-outcome.sh exists and is executable"
assert_file_exists "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "record-task-outcome.sh exists"
if [ -x "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" ]; then
  echo -e "  ${GREEN}✓${NC} record-task-outcome.sh is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} record-task-outcome.sh is NOT executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# AET-003: summarize-agent-quality.sh exists and is executable
# ============================================================
test_start "AET-003" "summarize-agent-quality.sh exists and is executable"
assert_file_exists "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "summarize-agent-quality.sh exists"
if [ -x "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" ]; then
  echo -e "  ${GREEN}✓${NC} summarize-agent-quality.sh is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} summarize-agent-quality.sh is NOT executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# AET-004: checkpoint.md references telemetry for STANDARD/HIGH-RISK
# ============================================================
test_start "AET-004" "checkpoint.md references task outcome telemetry"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "Task outcome telemetry" "checkpoint references telemetry"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "record-task-outcome.sh" "checkpoint references recording script"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "STANDARD/HIGH-RISK" "telemetry scoped to STANDARD/HIGH-RISK"

# ============================================================
# AET-005: DIRECT Lite is not bloated with telemetry
# ============================================================
test_start "AET-005" "DIRECT Lite is not bloated with telemetry"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "Do NOT record telemetry for DIRECT Lite" "DIRECT Lite excluded from telemetry"

# ============================================================
# AET-006: senior-self-review includes outcome/repair/reviewer/memory fields
# ============================================================
test_start "AET-006" "senior-self-review includes v4.29 outcome fields"
assert_file_contains "$ROOT_DIR/.opencode/scripts/senior-self-review.sh" "outcome_expected" "outcome_expected field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/senior-self-review.sh" "ci_first_try" "ci_first_try field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/senior-self-review.sh" "repair_cycles" "repair_cycles field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/senior-self-review.sh" "reviewer_found_material_issue" "reviewer_found_material_issue field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/senior-self-review.sh" "tests_caught_issue" "tests_caught_issue field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/senior-self-review.sh" "memory_or_pattern_helped" "memory_or_pattern_helped field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/senior-self-review.sh" "routing_recommendation_next_time" "routing_recommendation field"

# ============================================================
# AET-007: Scorecard doc exists
# ============================================================
test_start "AET-007" "agent-quality-scorecard.md exists"
assert_file_exists "$ROOT_DIR/.opencode/docs/agent-quality-scorecard.md" "scorecard doc exists"
assert_file_contains "$ROOT_DIR/.opencode/docs/agent-quality-scorecard.md" "Task Success" "scorecard has Task Success dimension"
assert_file_contains "$ROOT_DIR/.opencode/docs/agent-quality-scorecard.md" "CI Reliability" "scorecard has CI Reliability dimension"
assert_file_contains "$ROOT_DIR/.opencode/docs/agent-quality-scorecard.md" "Reviewer Usefulness" "scorecard has Reviewer Usefulness dimension"
assert_file_contains "$ROOT_DIR/.opencode/docs/agent-quality-scorecard.md" "Model Cost/ROI" "scorecard has Model Cost/ROI dimension"

# ============================================================
# AET-008: Telemetry script avoids secrets
# ============================================================
test_start "AET-008" "telemetry script avoids secrets"
assert_file_not_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "DOPPLER" "no Doppler references"
assert_file_not_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "API_KEY" "no API key references"
assert_file_not_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" '"prompt"' "no prompt field in JSON output"
assert_file_not_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" '"response"' "no response field in JSON output"

# ============================================================
# AET-009: Scripts tolerate missing optional data
# ============================================================
test_start "AET-009" "scripts tolerate missing optional data"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "Non-blocking" "non-blocking design documented"
assert_file_contains "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" "no_data" "scorecard handles no data gracefully"

# ============================================================
# AET-010: record-task-outcome.sh has required fields
# ============================================================
test_start "AET-010" "record-task-outcome.sh has required telemetry fields"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "task_id" "task_id field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "repo" "repo field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "lane" "lane field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "task_type" "task_type field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "outcome" "outcome field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "model_used" "model_used field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "reviewer_used" "reviewer_used field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "ci_status" "ci_status field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "repair_cycles" "repair_cycles field"
assert_file_contains "$ROOT_DIR/.opencode/scripts/record-task-outcome.sh" "human_acceptance" "human_acceptance field"

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"
