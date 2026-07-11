#!/bin/bash
# Test Intelligence + Evidence-Based Review Conformance Tests (v4.23)
# Verifies that test discovery, test expectation rules, evidence-based self-review,
# and CI failure classification are properly documented and wired in.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Test Intelligence + Evidence-Based Review (v4.23)"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

FIND_TESTS="$ROOT_DIR/.opencode/scripts/find-tests.sh"
TEST_INTEL_CMD="$ROOT_DIR/.opencode/commands/test-intelligence.md"
SENIOR_REVIEW="$ROOT_DIR/.opencode/scripts/senior-self-review.sh"
IMPLEMENT_CMD="$ROOT_DIR/.opencode/commands/implement.md"
QUICK_SHIP_CMD="$ROOT_DIR/.opencode/commands/quick-ship.md"
GATES_YML="$ROOT_DIR/.github/workflows/gates.yml"

# --- Section 1: find-tests.sh exists and works ---

test_start "TI-001" "find-tests.sh exists and is executable"
assert_file_exists "$FIND_TESTS" "find-tests.sh exists"
if [ -x "$FIND_TESTS" ]; then
  echo -e "  ${GREEN}✓${NC} find-tests.sh is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} find-tests.sh is not executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_start "TI-002" "find-tests.sh produces structured output"
TEST_REPO="$ROOT_DIR/protected-repo-prod"
if [ -d "$TEST_REPO" ]; then
  RESULT=$(bash "$FIND_TESTS" "$TEST_REPO" "src/App.tsx" 2>&1 || true)
  assert_output_contains "$RESULT" "TEST_DISCOVERY:" "Output has structured header"
  assert_output_contains "$RESULT" "framework:" "Output has framework field"
  assert_output_contains "$RESULT" "test_command:" "Output has test_command field"
  assert_output_contains "$RESULT" "nearby_tests:" "Output has nearby_tests field"
  assert_output_contains "$RESULT" "coverage_status:" "Output has coverage_status field"
  assert_output_contains "$RESULT" "missing_tests:" "Output has missing_tests field"
else
  echo -e "  ${YELLOW}⚠${NC} protected-repo-prod not found — skipping output test"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

test_start "TI-003" "find-tests.sh detects vitest in protected-repo-prod"
if [ -d "$TEST_REPO" ]; then
  RESULT=$(bash "$FIND_TESTS" "$TEST_REPO" "src/App.tsx" 2>&1 || true)
  assert_output_contains "$RESULT" "vitest" "Framework detected as vitest"
else
  echo -e "  ${YELLOW}⚠${NC} protected-repo-prod not found — skipping"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# --- Section 2: test-intelligence.md command exists ---

test_start "TI-004" "test-intelligence.md command exists"
assert_file_exists "$TEST_INTEL_CMD" "test-intelligence.md exists"

test_start "TI-005" "test-intelligence.md defines change type test requirements"
assert_file_contains "$TEST_INTEL_CMD" "Bug fix" "Bug fix test requirement defined"
assert_file_contains "$TEST_INTEL_CMD" "Logic change" "Logic change test requirement defined"
assert_file_contains "$TEST_INTEL_CMD" "Refactor" "Refactor test requirement defined"
assert_file_contains "$TEST_INTEL_CMD" "UI visual" "UI visual no-test-burden defined"

test_start "TI-006" "test-intelligence.md defines no-test justification format"
assert_file_contains "$TEST_INTEL_CMD" "Tests: not added" "No-test justification format defined"
assert_file_contains "$TEST_INTEL_CMD" "specific reason" "Justification requires specific reason"

test_start "TI-007" "test-intelligence.md has DIRECT Lite exception"
assert_file_contains "$TEST_INTEL_CMD" "DIRECT Lite" "DIRECT Lite exception documented"
assert_file_contains "$TEST_INTEL_CMD" "skip" "DIRECT Lite skips test intelligence"

test_start "TI-008" "test-intelligence.md has HIGH-RISK additional rules"
assert_file_contains "$TEST_INTEL_CMD" "HIGH-RISK" "HIGH-RISK rules defined"
assert_file_contains "$TEST_INTEL_CMD" "Full test suite" "HIGH-RISK requires full suite"

# --- Section 3: senior-self-review.sh supports evidence-based fields ---

test_start "TI-009" "senior-self-review.sh accepts repo-path and changed files"
RESULT=$(bash "$SENIOR_REVIEW" "$ROOT_DIR" ".opencode/AGENTS.md" 2>&1 || true)
assert_output_contains "$RESULT" "SENIOR_SELF_REVIEW:" "Self-review still outputs structured header"
assert_output_contains "$RESULT" "EVIDENCE:" "Evidence section appears with file arguments"

test_start "TI-010" "senior-self-review.sh includes evidence fields"
RESULT=$(bash "$SENIOR_REVIEW" "$ROOT_DIR" ".opencode/AGENTS.md" 2>&1 || true)
assert_output_contains "$RESULT" "files_changed:" "Evidence has files_changed field"
assert_output_contains "$RESULT" "test_framework:" "Evidence has test_framework field"
assert_output_contains "$RESULT" "tests_added:" "Evidence has tests_added field"
assert_output_contains "$RESULT" "test_result:" "Evidence has test_result field"
assert_output_contains "$RESULT" "ci_status:" "Evidence has ci_status field"

test_start "TI-011" "senior-self-review.sh still has checklist questions"
RESULT=$(bash "$SENIOR_REVIEW" 2>&1 || true)
assert_output_contains "$RESULT" "Problem solved" "Checklist still asks about problem solved"
assert_output_contains "$RESULT" "Scope discipline" "Checklist still asks about scope"
assert_output_contains "$RESULT" "Test expectation" "Checklist still asks about tests"
assert_output_contains "$RESULT" "Rollback clarity" "Checklist still asks about rollback"

# --- Section 4: implement.md references test intelligence ---

test_start "TI-012" "implement.md references find-tests.sh"
assert_file_contains "$IMPLEMENT_CMD" "find-tests.sh" "implement.md references find-tests.sh"

test_start "TI-013" "implement.md has Test Intelligence section"
assert_file_contains "$IMPLEMENT_CMD" "Test Intelligence (v4.23)" "implement.md has v4.23 test intelligence section"

test_start "TI-014" "implement.md DIRECT Lite skips test discovery"
assert_file_contains "$IMPLEMENT_CMD" "DIRECT Lite.*Skip test discovery" "DIRECT Lite skips test discovery"

test_start "TI-015" "implement.md STANDARD/HIGH-RISK requires test discovery"
assert_file_contains "$IMPLEMENT_CMD" "STANDARD / HIGH-RISK.*Always run.*find-tests" "STANDARD/HIGH-RISK requires find-tests.sh"

test_start "TI-016" "implement.md has no-test justification format"
assert_file_contains "$IMPLEMENT_CMD" "Tests: not added" "implement.md has no-test justification format"

# --- Section 5: quick-ship.md has test awareness ---

test_start "TI-017" "quick-ship.md has test awareness section"
assert_file_contains "$QUICK_SHIP_CMD" "Test awareness" "quick-ship has test awareness section"

test_start "TI-018" "quick-ship.md references find-tests.sh"
assert_file_contains "$QUICK_SHIP_CMD" "find-tests.sh" "quick-ship references find-tests.sh"

test_start "TI-019" "quick-ship.md has no-test justification in PR body"
assert_file_contains "$QUICK_SHIP_CMD" "no-test justification" "quick-ship requires no-test justification in PR body"

# --- Section 6: CI repair failure classification ---

test_start "TI-020" "quick-ship.md has CI failure classification table"
assert_file_contains "$QUICK_SHIP_CMD" "lint" "CI failure: lint classified"
assert_file_contains "$QUICK_SHIP_CMD" "typecheck" "CI failure: typecheck classified"
assert_file_contains "$QUICK_SHIP_CMD" "unit test" "CI failure: unit test classified"
assert_file_contains "$QUICK_SHIP_CMD" "build" "CI failure: build classified"
assert_file_contains "$QUICK_SHIP_CMD" "flaky" "CI failure: flaky/infra classified"

test_start "TI-021" "quick-ship.md CI repair runs failing command locally"
assert_file_contains "$QUICK_SHIP_CMD" "locally" "CI repair runs failing command locally"

# --- Section 7: gates.yml properly skips missing scripts ---

test_start "TI-022" "gates.yml checks if script exists before running"
assert_file_contains "$GATES_YML" "jq -e" "gates.yml uses jq to check script existence"
assert_file_contains "$GATES_YML" "skipping" "gates.yml has skip message for missing scripts"

test_start "TI-023" "gates.yml fails on real failures"
assert_file_contains "$GATES_YML" "exit 1" "gates.yml exits 1 on real failures"

# --- Section 8: Lite Mode and code intelligence preserved ---

test_start "TI-024" "Lite Delegation Mode still exists"
assert_file_contains "$IMPLEMENT_CMD" "Lite Delegation Mode" "Lite Delegation Mode preserved"

test_start "TI-025" "Code intelligence still referenced"
assert_file_contains "$IMPLEMENT_CMD" "search-code-index.sh" "Code index search preserved"
assert_file_contains "$IMPLEMENT_CMD" "retrieve-lessons.sh" "Lesson retrieval preserved"

test_start "TI-026" "Senior self-review still referenced"
assert_file_contains "$IMPLEMENT_CMD" "senior-self-review.sh" "Senior self-review preserved"

# --- Section 9: All required files are tracked ---

test_start "TI-027" "All v4.21-v4.23 scripts are tracked by git"
for f in \
  .opencode/scripts/build-code-index.sh \
  .opencode/scripts/search-code-index.sh \
  .opencode/scripts/retrieve-lessons.sh \
  .opencode/scripts/find-tests.sh \
  .opencode/scripts/senior-self-review.sh \
  .opencode/scripts/lite-mode-eligibility.sh \
  .opencode/commands/test-intelligence.md \
  .opencode/commands/quick-ship.md; do
  if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} $f is tracked"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "  ${RED}✗${NC} $f is NOT tracked"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
done

# --- Report ---

echo ""
report_results "$SCRIPT_DIR/../results/test-intelligence-review-$(date +%Y%m%d-%H%M%S).md"
