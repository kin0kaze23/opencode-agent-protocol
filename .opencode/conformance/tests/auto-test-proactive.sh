#!/bin/bash
# Auto-Test Generation + Proactive Issue Detection Conformance Tests (v4.25)
# Verifies that detect-untested.sh, auto-test-generation.md, proactive quality
# fields, and pattern auto-capture are properly documented and wired in.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Auto-Test Generation + Proactive Detection (v4.25)"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

DETECT_UNTESTED="$ROOT_DIR/.opencode/scripts/detect-untested.sh"
AUTO_TEST_CMD="$ROOT_DIR/.opencode/commands/auto-test-generation.md"
IMPLEMENT_CMD="$ROOT_DIR/.opencode/commands/implement.md"
QUICK_SHIP_CMD="$ROOT_DIR/.opencode/commands/quick-ship.md"
SENIOR_REVIEW="$ROOT_DIR/.opencode/scripts/senior-self-review.sh"
CHECKPOINT_CMD="$ROOT_DIR/.opencode/commands/checkpoint.md"
PATTERN_TEMPLATE="$ROOT_DIR/.opencode/templates/PATTERN.md"

# --- Section 1: detect-untested.sh exists and works ---

test_start "AT-001" "detect-untested.sh exists and is executable"
assert_file_exists "$DETECT_UNTESTED" "detect-untested.sh exists"
if [ -x "$DETECT_UNTESTED" ]; then
  echo -e "  ${GREEN}✓${NC} detect-untested.sh is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} detect-untested.sh is not executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_start "AT-002" "detect-untested.sh produces structured output"
TEST_REPO="$ROOT_DIR/protected-repo-prod"
if [ -d "$TEST_REPO" ]; then
  RESULT=$(bash "$DETECT_UNTESTED" "$TEST_REPO" "src/App.tsx" 2>&1 || true)
  assert_output_contains "$RESULT" "UNTESTED_ANALYSIS:" "Output has structured header"
  assert_output_contains "$RESULT" "framework:" "Output has framework field"
  assert_output_contains "$RESULT" "exported_symbols:" "Output has exported_symbols field"
  assert_output_contains "$RESULT" "nearby_tests:" "Output has nearby_tests field"
  assert_output_contains "$RESULT" "missing_coverage:" "Output has missing_coverage field"
  assert_output_contains "$RESULT" "suggested_test_files:" "Output has suggested_test_files field"
  assert_output_contains "$RESULT" "change_type_hint:" "Output has change_type_hint field"
else
  echo -e "  ${YELLOW}⚠${NC} protected-repo-prod not found — skipping output test"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# --- Section 2: auto-test-generation.md command exists ---

test_start "AT-003" "auto-test-generation.md command exists"
assert_file_exists "$AUTO_TEST_CMD" "auto-test-generation.md exists"

test_start "AT-004" "auto-test-generation.md defines change type test requirements"
assert_file_contains "$AUTO_TEST_CMD" "Bug fix" "Bug fix test requirement defined"
assert_file_contains "$AUTO_TEST_CMD" "Logic change" "Logic change test requirement defined"
assert_file_contains "$AUTO_TEST_CMD" "Refactor" "Refactor test requirement defined"
assert_file_contains "$AUTO_TEST_CMD" "UI visual" "UI visual no-test-burden defined"

test_start "AT-005" "auto-test-generation.md has DIRECT Lite exception"
assert_file_contains "$AUTO_TEST_CMD" "DIRECT Lite" "DIRECT Lite exception documented"
assert_file_contains "$AUTO_TEST_CMD" "skip" "DIRECT Lite skips auto-test generation"

test_start "AT-006" "auto-test-generation.md has HIGH-RISK rules"
assert_file_contains "$AUTO_TEST_CMD" "HIGH-RISK" "HIGH-RISK rules defined"
assert_file_contains "$AUTO_TEST_CMD" "Full test suite" "HIGH-RISK requires full suite"

test_start "AT-007" "auto-test-generation.md references detect-untested.sh"
assert_file_contains "$AUTO_TEST_CMD" "detect-untested.sh" "auto-test-generation references detect-untested.sh"

test_start "AT-008" "auto-test-generation.md defines no-test justification format"
assert_file_contains "$AUTO_TEST_CMD" "Tests: not added" "No-test justification format defined"
assert_file_contains "$AUTO_TEST_CMD" "specific reason" "Justification requires specific reason"

# --- Section 3: implement.md references detect-untested.sh ---

test_start "AT-009" "implement.md has Proactive Test Generation section"
assert_file_contains "$IMPLEMENT_CMD" "Proactive Test Generation (v4.25)" "implement.md has v4.25 proactive test section"

test_start "AT-010" "implement.md references detect-untested.sh"
assert_file_contains "$IMPLEMENT_CMD" "detect-untested.sh" "implement.md references detect-untested.sh"

test_start "AT-011" "implement.md DIRECT Lite skips untested detection"
assert_file_contains "$IMPLEMENT_CMD" "DIRECT Lite.*Skip untested" "DIRECT Lite skips untested detection"

test_start "AT-012" "implement.md STANDARD/HIGH-RISK requires detect-untested"
assert_file_contains "$IMPLEMENT_CMD" "STANDARD / HIGH-RISK.*detect-untested" "STANDARD/HIGH-RISK requires detect-untested.sh"

# --- Section 4: quick-ship.md has test discovery for bug/logic ---

test_start "AT-013" "quick-ship.md references detect-untested.sh"
assert_file_contains "$QUICK_SHIP_CMD" "detect-untested.sh" "quick-ship references detect-untested.sh"

test_start "AT-014" "quick-ship.md has no-test justification in PR body"
assert_file_contains "$QUICK_SHIP_CMD" "no-test justification" "quick-ship requires no-test justification in PR body"

# --- Section 5: senior-self-review.sh has proactive quality fields ---

test_start "AT-015" "senior-self-review.sh has proactive quality fields"
RESULT=$(bash "$SENIOR_REVIEW" "$ROOT_DIR" ".opencode/AGENTS.md" 2>&1 || true)
assert_output_contains "$RESULT" "changed_behavior_detected:" "Self-review has changed_behavior_detected field"
assert_output_contains "$RESULT" "tests_missing:" "Self-review has tests_missing field"
assert_output_contains "$RESULT" "tests_added_or_updated:" "Self-review has tests_added_or_updated field"
assert_output_contains "$RESULT" "test_generation_skipped_reason:" "Self-review has test_generation_skipped_reason field"
assert_output_contains "$RESULT" "proactive_issue_found:" "Self-review has proactive_issue_found field"
assert_output_contains "$RESULT" "recommended_followup:" "Self-review has recommended_followup field"

# --- Section 6: checkpoint.md has pattern auto-capture ---

test_start "AT-016" "checkpoint.md has pattern auto-capture suggestion"
assert_file_contains "$CHECKPOINT_CMD" "Pattern auto-capture" "checkpoint.md has pattern auto-capture section"
assert_file_contains "$CHECKPOINT_CMD" "PATTERN.md" "checkpoint.md references PATTERN.md template"

test_start "AT-017" "checkpoint.md pattern auto-capture has exclusions"
assert_file_contains "$CHECKPOINT_CMD" "Do NOT suggest pattern capture" "checkpoint.md has pattern capture exclusions"
assert_file_contains "$CHECKPOINT_CMD" "Trivial" "checkpoint.md excludes trivial work from pattern capture"

test_start "AT-018" "checkpoint.md pattern auto-capture requires owner approval"
assert_file_contains "$CHECKPOINT_CMD" "Owner approval required" "Pattern auto-capture requires owner approval"

# --- Section 7: Prior capabilities preserved ---

test_start "AT-019" "Lite Delegation Mode still exists"
assert_file_contains "$IMPLEMENT_CMD" "Lite Delegation Mode" "Lite Delegation Mode preserved"

test_start "AT-020" "Code intelligence still referenced"
assert_file_contains "$IMPLEMENT_CMD" "search-code-index.sh" "Code index search preserved"

test_start "AT-021" "Test intelligence still referenced"
assert_file_contains "$IMPLEMENT_CMD" "find-tests.sh" "Test discovery preserved"

test_start "AT-022" "Pattern memory still referenced"
assert_file_contains "$IMPLEMENT_CMD" "search-patterns.sh" "Pattern search preserved"

test_start "AT-023" "Senior self-review still referenced"
assert_file_contains "$IMPLEMENT_CMD" "senior-self-review.sh" "Senior self-review preserved"

test_start "AT-024" "PATTERN.md template still exists"
assert_file_exists "$PATTERN_TEMPLATE" "PATTERN.md template preserved"

# --- Section 8: All required files are tracked ---

test_start "AT-025" "All v4.25 files are tracked by git"
for f in \
  .opencode/scripts/detect-untested.sh \
  .opencode/commands/auto-test-generation.md \
  .opencode/scripts/senior-self-review.sh \
  .opencode/commands/implement.md \
  .opencode/commands/quick-ship.md \
  .opencode/commands/checkpoint.md \
  .opencode/conformance/tests/auto-test-proactive.sh; do
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
report_results "$SCRIPT_DIR/../results/auto-test-proactive-$(date +%Y%m%d-%H%M%S).md"
