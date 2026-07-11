#!/bin/bash
# Code Intelligence + Lesson Retrieval Conformance Tests (v4.21)
# Verifies that code indexing, search, and lesson retrieval scripts exist,
# are executable, and are wired into the implement and checkpoint commands.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Code Intelligence + Lesson Retrieval (v4.21)"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

BUILD_INDEX="$ROOT_DIR/.opencode/scripts/build-code-index.sh"
SEARCH_INDEX="$ROOT_DIR/.opencode/scripts/search-code-index.sh"
RETRIEVE_LESSONS="$ROOT_DIR/.opencode/scripts/retrieve-lessons.sh"
IMPLEMENT_CMD="$ROOT_DIR/.opencode/commands/implement.md"
CHECKPOINT_CMD="$ROOT_DIR/.opencode/commands/checkpoint.md"
PROJECT_MEMORY_TEMPLATE="$ROOT_DIR/.opencode/templates/PROJECT_MEMORY.md"

# --- Section 1: Scripts exist and are executable ---

test_start "CI-001" "build-code-index.sh exists"
assert_file_exists "$BUILD_INDEX" "build-code-index.sh exists"

test_start "CI-002" "build-code-index.sh is executable"
if [ -x "$BUILD_INDEX" ]; then
  echo -e "  ${GREEN}✓${NC} build-code-index.sh is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} build-code-index.sh is not executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_start "CI-003" "search-code-index.sh exists"
assert_file_exists "$SEARCH_INDEX" "search-code-index.sh exists"

test_start "CI-004" "search-code-index.sh is executable"
if [ -x "$SEARCH_INDEX" ]; then
  echo -e "  ${GREEN}✓${NC} search-code-index.sh is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} search-code-index.sh is not executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_start "CI-005" "retrieve-lessons.sh exists"
assert_file_exists "$RETRIEVE_LESSONS" "retrieve-lessons.sh exists"

test_start "CI-006" "retrieve-lessons.sh is executable"
if [ -x "$RETRIEVE_LESSONS" ]; then
  echo -e "  ${GREEN}✓${NC} retrieve-lessons.sh is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} retrieve-lessons.sh is not executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# --- Section 2: Scripts produce correct output format ---

test_start "CI-007" "build-code-index.sh produces index files"
# Use protected-repo-prod as test repo if it exists, otherwise use a temp dir
TEST_REPO="$ROOT_DIR/protected-repo-prod"
if [ ! -d "$TEST_REPO" ]; then
  TEST_REPO="$ROOT_DIR"
fi
bash "$BUILD_INDEX" "$TEST_REPO" >/dev/null 2>&1 || true
assert_file_exists "$TEST_REPO/.code-index/files.txt" "Index produces files.txt"
assert_file_exists "$TEST_REPO/.code-index/symbols.txt" "Index produces symbols.txt"
assert_file_exists "$TEST_REPO/.code-index/meta.txt" "Index produces meta.txt"

test_start "CI-008" "search-code-index.sh produces structured output"
RESULT=$(bash "$SEARCH_INDEX" "$TEST_REPO" "test" 2>&1 || true)
assert_output_contains "$RESULT" "CODE_INDEX_MATCHES:" "Search output has structured header"
assert_output_contains "$RESULT" "files:" "Search output has files section"
assert_output_contains "$RESULT" "Suggested next reads:" "Search output has suggested reads"

test_start "CI-009" "retrieve-lessons.sh produces structured output"
RESULT=$(bash "$RETRIEVE_LESSONS" "$TEST_REPO" "test" 2>&1 || true)
assert_output_contains "$RESULT" "RELEVANT_LESSONS:" "Lesson retrieval has structured header"
assert_output_contains "$RESULT" "lessons:" "Lesson retrieval has lessons section"
assert_output_contains "$RESULT" "risks:" "Lesson retrieval has risks section"
assert_output_contains "$RESULT" "decisions:" "Lesson retrieval has decisions section"
assert_output_contains "$RESULT" "Escalation hints:" "Lesson retrieval has escalation hints"

# --- Section 3: implement.md references code intelligence ---

test_start "CI-010" "implement.md references code index search"
assert_file_contains "$IMPLEMENT_CMD" "search-code-index.sh" "implement.md references code index search"

test_start "CI-011" "implement.md references lesson retrieval"
assert_file_contains "$IMPLEMENT_CMD" "retrieve-lessons.sh" "implement.md references lesson retrieval"

test_start "CI-012" "implement.md has Code Intelligence section"
assert_file_contains "$IMPLEMENT_CMD" "Code Intelligence + Lesson Retrieval" "implement.md has v4.21 code intelligence section"

test_start "CI-013" "implement.md keeps DIRECT Lite lightweight"
assert_file_contains "$IMPLEMENT_CMD" "DIRECT Lite.*Skip code index" "DIRECT Lite skips code index" || \
assert_file_contains "$IMPLEMENT_CMD" "DIRECT Lite.*skip code index" "DIRECT Lite skips code index" || \
assert_file_contains "$IMPLEMENT_CMD" "DIRECT Lite:" "DIRECT Lite path documented"

test_start "CI-014" "implement.md requires lesson retrieval for STANDARD/HIGH-RISK"
assert_file_contains "$IMPLEMENT_CMD" "STANDARD / HIGH-RISK.*always run" "STANDARD/HIGH-RISK requires lesson retrieval" || \
assert_file_contains "$IMPLEMENT_CMD" "STANDARD.*always run" "STANDARD requires lesson retrieval"

test_start "CI-015" "implement.md has escalation from lessons"
assert_file_contains "$IMPLEMENT_CMD" "Escalation from lessons" "implement.md has lesson-based escalation"

# --- Section 4: checkpoint.md has PROJECT_MEMORY update rules ---

test_start "CI-016" "checkpoint.md has PROJECT_MEMORY update rules"
assert_file_contains "$CHECKPOINT_CMD" "PROJECT_MEMORY.md update" "checkpoint.md has PROJECT_MEMORY update section"

test_start "CI-017" "checkpoint.md documents meaningful update triggers"
assert_file_contains "$CHECKPOINT_CMD" "architecture decision" "Meaningful: architecture decision"
assert_file_contains "$CHECKPOINT_CMD" "recurring lesson" "Meaningful: recurring lesson"
assert_file_contains "$CHECKPOINT_CMD" "known risk" "Meaningful: known risk"

test_start "CI-018" "checkpoint.md documents when NOT to update PROJECT_MEMORY"
assert_file_contains "$CHECKPOINT_CMD" "Do NOT update PROJECT_MEMORY" "checkpoint.md has exclusion rules"
assert_file_contains "$CHECKPOINT_CMD" "Trivial typo" "checkpoint.md excludes trivial changes"

# --- Section 5: Lite Mode remains lightweight ---

test_start "CI-019" "implement.md still has Lite Delegation Mode"
assert_file_contains "$IMPLEMENT_CMD" "Lite Delegation Mode" "Lite Delegation Mode preserved"

test_start "CI-020" "implement.md still has lite-mode-eligibility.sh reference"
assert_file_contains "$IMPLEMENT_CMD" "lite-mode-eligibility.sh" "Lite Mode classifier preserved"

# --- Section 6: PROJECT_MEMORY template still exists ---

test_start "CI-021" "PROJECT_MEMORY.md template still exists"
assert_file_exists "$PROJECT_MEMORY_TEMPLATE" "PROJECT_MEMORY.md template preserved"

# --- Section 7: protected-repo-prod pilot ---

test_start "CI-022" "protected-repo-prod has PROJECT_MEMORY.md pilot"
assert_file_exists "$ROOT_DIR/protected-repo-prod/PROJECT_MEMORY.md" "protected-repo-prod PROJECT_MEMORY.md exists"

test_start "CI-023" "protected-repo-prod PROJECT_MEMORY has required sections"
assert_file_contains "$ROOT_DIR/protected-repo-prod/PROJECT_MEMORY.md" "Architecture Notes" "Pilot has Architecture Notes"
assert_file_contains "$ROOT_DIR/protected-repo-prod/PROJECT_MEMORY.md" "Key Decisions" "Pilot has Key Decisions"
assert_file_contains "$ROOT_DIR/protected-repo-prod/PROJECT_MEMORY.md" "Known Risks" "Pilot has Known Risks"
assert_file_contains "$ROOT_DIR/protected-repo-prod/PROJECT_MEMORY.md" "Testing Commands" "Pilot has Testing Commands"
assert_file_contains "$ROOT_DIR/protected-repo-prod/PROJECT_MEMORY.md" "Deployment Notes" "Pilot has Deployment Notes"

# --- Report ---

echo ""
report_results "$SCRIPT_DIR/../results/code-intelligence-lesson-retrieval-$(date +%Y%m%d-%H%M%S).md"
