#!/bin/bash
# Pattern Memory Conformance Tests (v4.24)
# Verifies that cross-project pattern memory, search, and evidence fields are
# properly documented and wired into the protocol.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Pattern Memory (v4.24)"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

PATTERN_TEMPLATE="$ROOT_DIR/.opencode/templates/PATTERN.md"
BUILD_PATTERN="$ROOT_DIR/.opencode/scripts/build-pattern-index.sh"
SEARCH_PATTERN="$ROOT_DIR/.opencode/scripts/search-patterns.sh"
RETRIEVE_LESSONS="$ROOT_DIR/.opencode/scripts/retrieve-lessons.sh"
IMPLEMENT_CMD="$ROOT_DIR/.opencode/commands/implement.md"
SENIOR_REVIEW="$ROOT_DIR/.opencode/scripts/senior-self-review.sh"
PROTECTED_REPO_MEMORY="$ROOT_DIR/protected-repo-prod/PROJECT_MEMORY.md"
DEMO_PROJECT_MEMORY="$ROOT_DIR/demo-project/PROJECT_MEMORY.md"

# --- Section 1: PATTERN.md template ---

test_start "PM-001" "PATTERN.md template exists"
assert_file_exists "$PATTERN_TEMPLATE" "PATTERN.md template exists"

test_start "PM-002" "PATTERN.md template has required sections"
assert_file_contains "$PATTERN_TEMPLATE" "Problem Solved" "Template has Problem Solved"
assert_file_contains "$PATTERN_TEMPLATE" "Source Repo" "Template has Source Repo"
assert_file_contains "$PATTERN_TEMPLATE" "When to Use" "Template has When to Use"
assert_file_contains "$PATTERN_TEMPLATE" "When Not to Use" "Template has When Not to Use"
assert_file_contains "$PATTERN_TEMPLATE" "Implementation Shape" "Template has Implementation Shape"
assert_file_contains "$PATTERN_TEMPLATE" "Risks" "Template has Risks"
assert_file_contains "$PATTERN_TEMPLATE" "Verification Commands" "Template has Verification Commands"
assert_file_contains "$PATTERN_TEMPLATE" "Related Lessons" "Template has Related Lessons"

# --- Section 2: build-pattern-index.sh ---

test_start "PM-003" "build-pattern-index.sh exists and is executable"
assert_file_exists "$BUILD_PATTERN" "build-pattern-index.sh exists"
if [ -x "$BUILD_PATTERN" ]; then
  echo -e "  ${GREEN}✓${NC} build-pattern-index.sh is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} build-pattern-index.sh is not executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_start "PM-004" "build-pattern-index.sh produces output"
RESULT=$(bash "$BUILD_PATTERN" 2>&1 || true)
assert_output_contains "$RESULT" "Pattern index built" "Index build produces output"
assert_output_contains "$RESULT" "patterns indexed" "Index reports pattern count"

test_start "PM-005" "Pattern index file is created"
INDEX_FILE="$ROOT_DIR/.opencode/cache/pattern-index.md"
assert_file_exists "$INDEX_FILE" "Pattern index file exists"

# --- Section 3: search-patterns.sh ---

test_start "PM-006" "search-patterns.sh exists and is executable"
assert_file_exists "$SEARCH_PATTERN" "search-patterns.sh exists"
if [ -x "$SEARCH_PATTERN" ]; then
  echo -e "  ${GREEN}✓${NC} search-patterns.sh is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} search-patterns.sh is not executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_start "PM-007" "search-patterns.sh produces structured output"
RESULT=$(bash "$SEARCH_PATTERN" "supabase auth" 2>&1 || true)
assert_output_contains "$RESULT" "PATTERN_MATCHES:" "Search output has structured header"
assert_output_contains "$RESULT" "source_repo:" "Search output has source_repo field"
assert_output_contains "$RESULT" "Total matches:" "Search output has match count"

# --- Section 4: retrieve-lessons.sh --cross-project ---

test_start "PM-008" "retrieve-lessons.sh supports --cross-project flag"
assert_file_contains "$RETRIEVE_LESSONS" "cross-project" "retrieve-lessons.sh documents cross-project flag"
assert_file_contains "$RETRIEVE_LESSONS" "CROSS_PROJECT" "retrieve-lessons.sh has cross-project variable"

test_start "PM-009" "retrieve-lessons.sh --cross-project produces cross-project output"
RESULT=$(bash "$RETRIEVE_LESSONS" "$ROOT_DIR/protected-repo-prod" "auth state" --cross-project 2>&1 || true)
assert_output_contains "$RESULT" "RELEVANT_LESSONS:" "Output has structured header"
# Cross-project section should appear (may have results or not, but section should exist)
assert_output_contains "$RESULT" "cross_project_lessons:" "Output has cross_project_lessons section"

test_start "PM-010" "retrieve-lessons.sh default mode does NOT include cross-project"
RESULT=$(bash "$RETRIEVE_LESSONS" "$ROOT_DIR/protected-repo-prod" "auth state" 2>&1 || true)
# Without --cross-project, the cross_project_lessons section should NOT appear
if echo "$RESULT" | grep -q "cross_project_lessons:"; then
  echo -e "  ${RED}✗${NC} Default mode includes cross-project (should not)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
else
  echo -e "  ${GREEN}✓${NC} Default mode does not include cross-project"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# --- Section 5: implement.md references pattern search ---

test_start "PM-011" "implement.md has Pattern Memory section"
assert_file_contains "$IMPLEMENT_CMD" "Pattern Memory (v4.24)" "implement.md has v4.24 pattern memory section"

test_start "PM-012" "implement.md references search-patterns.sh"
assert_file_contains "$IMPLEMENT_CMD" "search-patterns.sh" "implement.md references search-patterns.sh"

test_start "PM-013" "implement.md DIRECT Lite skips pattern search"
assert_file_contains "$IMPLEMENT_CMD" "DIRECT Lite.*Skip pattern search" "DIRECT Lite skips pattern search"

test_start "PM-014" "implement.md STANDARD/HIGH-RISK requires pattern search"
assert_file_contains "$IMPLEMENT_CMD" "STANDARD / HIGH-RISK" "STANDARD/HIGH-RISK pattern section exists"
assert_file_contains "$IMPLEMENT_CMD" "search-patterns.sh" "implement.md references search-patterns.sh for STANDARD/HIGH-RISK"

test_start "PM-015" "implement.md references cross-project lessons"
assert_file_contains "$IMPLEMENT_CMD" "cross-project" "implement.md references cross-project lessons"

# --- Section 6: senior-self-review.sh has pattern evidence ---

test_start "PM-016" "senior-self-review.sh has pattern evidence fields"
RESULT=$(bash "$SENIOR_REVIEW" "$ROOT_DIR" ".opencode/AGENTS.md" 2>&1 || true)
assert_output_contains "$RESULT" "patterns_checked:" "Self-review has patterns_checked field"
assert_output_contains "$RESULT" "reused_pattern:" "Self-review has reused_pattern field"
assert_output_contains "$RESULT" "rejected_pattern_reason:" "Self-review has rejected_pattern_reason field"
assert_output_contains "$RESULT" "cross_project_lessons_count:" "Self-review has cross_project_lessons_count field"
assert_output_contains "$RESULT" "source_repos:" "Self-review has source_repos field"

# --- Section 7: PROJECT_MEMORY.md exists in multiple repos ---

test_start "PM-017" "protected-repo-prod has PROJECT_MEMORY.md"
assert_file_exists "$PROTECTED_REPO_MEMORY" "protected-repo-prod PROJECT_MEMORY.md exists"

test_start "PM-018" "demo-project has PROJECT_MEMORY.md"
assert_file_exists "$DEMO_PROJECT_MEMORY" "demo-project PROJECT_MEMORY.md exists"

test_start "PM-019" "demo-project PROJECT_MEMORY has required sections"
assert_file_contains "$DEMO_PROJECT_MEMORY" "Architecture Notes" "demo-project has Architecture Notes"
assert_file_contains "$DEMO_PROJECT_MEMORY" "Key Decisions" "demo-project has Key Decisions"
assert_file_contains "$DEMO_PROJECT_MEMORY" "Known Risks" "demo-project has Known Risks"
assert_file_contains "$DEMO_PROJECT_MEMORY" "Testing Commands" "demo-project has Testing Commands"
assert_file_contains "$DEMO_PROJECT_MEMORY" "Deployment Notes" "demo-project has Deployment Notes"

# --- Section 8: Lite Mode and prior capabilities preserved ---

test_start "PM-020" "Lite Delegation Mode still exists"
assert_file_contains "$IMPLEMENT_CMD" "Lite Delegation Mode" "Lite Delegation Mode preserved"

test_start "PM-021" "Code intelligence still referenced"
assert_file_contains "$IMPLEMENT_CMD" "search-code-index.sh" "Code index search preserved"

test_start "PM-022" "Test intelligence still referenced"
assert_file_contains "$IMPLEMENT_CMD" "find-tests.sh" "Test discovery preserved"

test_start "PM-023" "Senior self-review still referenced"
assert_file_contains "$IMPLEMENT_CMD" "senior-self-review.sh" "Senior self-review preserved"

# --- Report ---

echo ""
report_results "$SCRIPT_DIR/../results/pattern-memory-$(date +%Y%m%d-%H%M%S).md"
