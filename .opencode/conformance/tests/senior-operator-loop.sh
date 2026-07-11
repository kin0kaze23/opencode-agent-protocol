#!/bin/bash
# Senior Operator Loop Conformance Tests (v4.22)
# Verifies that the Senior Operator Loop, self-review, quick-ship, CI-first
# verification, and test expectation rules are properly documented.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Senior Operator Loop (v4.22)"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

AGENTS_MD="$ROOT_DIR/.opencode/AGENTS.md"
IMPLEMENT_CMD="$ROOT_DIR/.opencode/commands/implement.md"
QUICK_SHIP_CMD="$ROOT_DIR/.opencode/commands/quick-ship.md"
SENIOR_REVIEW="$ROOT_DIR/.opencode/scripts/senior-self-review.sh"
GATES_YML="$ROOT_DIR/.github/workflows/gates.yml"

# --- Section 1: Senior Operator Loop exists ---

test_start "SOL-001" "AGENTS.md contains Senior Operator Loop section"
assert_file_contains "$AGENTS_MD" "Senior Operator Loop (v4.22)" "AGENTS.md has Senior Operator Loop section"

test_start "SOL-002" "AGENTS.md defines the loop stages"
assert_file_contains "$AGENTS_MD" "Objective.*Context.*Risk.*Plan.*Implement.*Test.*Self-review.*PR.*CI.*Memory" "Loop stages defined"

test_start "SOL-003" "AGENTS.md defines when loop is mandatory"
assert_file_contains "$AGENTS_MD" "DIRECT Lite.*Skip" "DIRECT Lite skips senior loop"
assert_file_contains "$AGENTS_MD" "STANDARD.*Full loop" "STANDARD requires full loop"
assert_file_contains "$AGENTS_MD" "HIGH-RISK.*Full loop.*reviewer" "HIGH-RISK requires full loop + reviewer"

# --- Section 2: Senior self-review ---

test_start "SOL-004" "senior-self-review.sh exists and is executable"
assert_file_exists "$SENIOR_REVIEW" "senior-self-review.sh exists"
if [ -x "$SENIOR_REVIEW" ]; then
  echo -e "  ${GREEN}✓${NC} senior-self-review.sh is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} senior-self-review.sh is not executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_start "SOL-005" "Self-review script outputs structured checklist"
RESULT=$(bash "$SENIOR_REVIEW" 2>&1 || true)
assert_output_contains "$RESULT" "SENIOR_SELF_REVIEW:" "Output has structured header"
assert_output_contains "$RESULT" "Problem solved" "Checklist asks about problem solved"
assert_output_contains "$RESULT" "Scope discipline" "Checklist asks about scope"
assert_output_contains "$RESULT" "Risk classification" "Checklist asks about risk changes"
assert_output_contains "$RESULT" "Test expectation" "Checklist asks about tests"
assert_output_contains "$RESULT" "Code simplicity" "Checklist asks about simplicity"
assert_output_contains "$RESULT" "Tech debt" "Checklist asks about tech debt"
assert_output_contains "$RESULT" "Rollback clarity" "Checklist asks about rollback"
assert_output_contains "$RESULT" "PR accuracy" "Checklist asks about PR accuracy"

test_start "SOL-006" "AGENTS.md references senior self-review"
assert_file_contains "$AGENTS_MD" "senior-self-review.sh" "AGENTS.md references self-review script"

# --- Section 3: Quick-ship command ---

test_start "SOL-007" "quick-ship.md command exists"
assert_file_exists "$QUICK_SHIP_CMD" "quick-ship.md exists"

test_start "SOL-008" "quick-ship uses Lite Mode classifier"
assert_file_contains "$QUICK_SHIP_CMD" "lite-mode-eligibility.sh" "quick-ship references Lite Mode classifier"

test_start "SOL-009" "quick-ship creates PR"
assert_file_contains "$QUICK_SHIP_CMD" "gh pr create" "quick-ship creates PR"

test_start "SOL-010" "quick-ship has CI repair loop"
assert_file_contains "$QUICK_SHIP_CMD" "CI Repair Loop" "quick-ship has CI repair loop"
assert_file_contains "$QUICK_SHIP_CMD" "max 2 repair cycles" "CI repair has cycle limit"

test_start "SOL-011" "quick-ship excludes sensitive paths"
assert_file_contains "$QUICK_SHIP_CMD" "auth" "quick-ship excludes auth"
assert_file_contains "$QUICK_SHIP_CMD" "payment" "quick-ship excludes payment"
assert_file_contains "$QUICK_SHIP_CMD" "schema" "quick-ship excludes schema"
assert_file_contains "$QUICK_SHIP_CMD" "migration" "quick-ship excludes migration"
assert_file_contains "$QUICK_SHIP_CMD" "secrets" "quick-ship excludes secrets"

test_start "SOL-012" "quick-ship uses GitGuard"
assert_file_contains "$QUICK_SHIP_CMD" "git-guard" "quick-ship uses GitGuard"

# --- Section 4: CI-first verification ---

test_start "SOL-013" "Gates workflow exists"
assert_file_exists "$GATES_YML" "gates.yml exists"

test_start "SOL-014" "Gates workflow is reusable"
assert_file_contains "$GATES_YML" "workflow_call" "gates.yml is reusable via workflow_call"

test_start "SOL-015" "Gates workflow runs lint"
assert_file_contains "$GATES_YML" "lint" "gates.yml runs lint"

test_start "SOL-016" "Gates workflow runs typecheck"
assert_file_contains "$GATES_YML" "typecheck" "gates.yml runs typecheck"

test_start "SOL-017" "Gates workflow runs tests"
assert_file_contains "$GATES_YML" "test" "gates.yml runs tests"

test_start "SOL-018" "Gates workflow runs build"
assert_file_contains "$GATES_YML" "build" "gates.yml runs build"

test_start "SOL-019" "Gates workflow auto-detects package manager"
assert_file_contains "$GATES_YML" "pnpm-lock.yaml" "Detects pnpm"
assert_file_contains "$GATES_YML" "yarn.lock" "Detects yarn"
assert_file_contains "$GATES_YML" "bun.lock" "Detects bun"

test_start "SOL-020" "Gates workflow gracefully skips unavailable scripts"
assert_file_contains "$GATES_YML" "continue-on-error" "Gates use continue-on-error for graceful skip"

test_start "SOL-021" "AGENTS.md documents CI-first verification"
assert_file_contains "$AGENTS_MD" "CI-First Verification" "AGENTS.md has CI-first verification section"
assert_file_contains "$AGENTS_MD" "Agent creates PR first" "CI-first: PR before in-session gates"
assert_file_contains "$AGENTS_MD" "max 2 repair cycles" "CI-first: repair cycle limit"

# --- Section 5: Test expectation rule ---

test_start "SOL-022" "AGENTS.md has test expectation rule"
assert_file_contains "$AGENTS_MD" "Test Expectation Rule" "AGENTS.md has test expectation rule"
assert_file_contains "$AGENTS_MD" "Bug fix or logic change.*tests required" "Bug fixes require tests"
assert_file_contains "$AGENTS_MD" "DIRECT style.*copy change.*no test burden" "DIRECT has no test burden"

test_start "SOL-023" "implement.md has test expectation rule"
assert_file_contains "$IMPLEMENT_CMD" "Test Expectation Rule" "implement.md has test expectation rule"
assert_file_contains "$IMPLEMENT_CMD" "no-test justification" "implement.md has no-test justification format"

# --- Section 6: Lite Mode and code intelligence preserved ---

test_start "SOL-024" "Lite Delegation Mode still exists"
assert_file_contains "$AGENTS_MD" "Lite Delegation Mode" "Lite Delegation Mode preserved"

test_start "SOL-025" "Code intelligence still referenced in implement.md"
assert_file_contains "$IMPLEMENT_CMD" "search-code-index.sh" "Code index search preserved"
assert_file_contains "$IMPLEMENT_CMD" "retrieve-lessons.sh" "Lesson retrieval preserved"

test_start "SOL-026" "DIRECT Lite remains lightweight"
assert_file_contains "$AGENTS_MD" "DIRECT Lite.*Skip" "DIRECT Lite skips senior loop"
assert_file_contains "$AGENTS_MD" "DIRECT Lite.*No test burden" "DIRECT Lite has no test burden"

# --- Section 7: Quick-ship documented in AGENTS.md ---

test_start "SOL-027" "AGENTS.md references quick-ship"
assert_file_contains "$AGENTS_MD" "Quick-Ship" "AGENTS.md references quick-ship"
assert_file_contains "$AGENTS_MD" "quick-ship" "AGENTS.md references /quick-ship command"

# --- Report ---

echo ""
report_results "$SCRIPT_DIR/../results/senior-operator-loop-$(date +%Y%m%d-%H%M%S).md"
