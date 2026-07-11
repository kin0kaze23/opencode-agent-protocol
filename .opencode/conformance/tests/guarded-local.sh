#!/bin/bash
# Guarded Local Tests - Full Local Command Behavior
# Tests observable protocol contracts without remote side effects

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"  # Go up 3 levels to workspace root
RESULTS_DIR="$SCRIPT_DIR/../results"
FIXTURES_DIR="$SCRIPT_DIR/../fixtures"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/guarded-local-${TIMESTAMP}.md"

# Source assertion helpers
source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Guarded Local Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

# ============================================================
# LOCAL-001: Preflight block has all 13 fields
# ============================================================
test_start "LOCAL-001" "Preflight block completeness"
PREFLIGHT_FIELDS=(
    "Repo:"
    "Why this repo:"
    "Confidence:"
    "Mode:"
    "Lane:"
    "Risk score:"
    "Model:"
    "Autonomy budget:"
    "Likely files:"
    "Commands likely:"
    "Helpers needed:"
    "Success criteria:"
    "Major risks:"
)
MISSING=0
for field in "${PREFLIGHT_FIELDS[@]}"; do
    if ! grep -q "$field" "$ROOT_DIR/.opencode/AGENTS.md" 2>/dev/null; then
        echo -e "  ${RED}✗${NC} Missing field: $field"
        ((MISSING++))
        ((TESTS_FAILED++))
    fi
done
if [ "$MISSING" -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} All 13 preflight fields documented"
    ((TESTS_PASSED++))
fi

# ============================================================
# LOCAL-002: /plan-feature writes PLAN.md
# ============================================================
test_start "LOCAL-002" "/plan-feature writes PLAN.md"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "PLAN.md" "PLAN.md mentioned"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "PENDING USER REVIEW" "Approval status"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Touch list" "Touch list required"

# ============================================================
# LOCAL-003: /plan-feature stops for approval
# ============================================================
test_start "LOCAL-003" "/plan-feature stops for approval"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Stops. Does not proceed" "Explicit stop"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "approved" "Approval keyword"

# ============================================================
# LOCAL-004: /implement reads PLAN.md touch list
# ============================================================
test_start "LOCAL-004" "/implement reads touch list"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "touch list" "Touch list referenced"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "PLAN.md" "Plan file read"

# ============================================================
# LOCAL-005: /implement gates sequence
# ============================================================
test_start "LOCAL-005" "/implement gates sequence"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "lint" "Lint gate"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "typecheck" "Typecheck gate"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "test" "Test gate"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "build" "Build gate"

# ============================================================
# LOCAL-006: /gates stops at first failure
# ============================================================
test_start "LOCAL-006" "/gates stops at failure"
assert_file_contains "$ROOT_DIR/.opencode/commands/gates.md" "Stops at first failure" "Stop on failure"
assert_file_contains "$ROOT_DIR/.opencode/commands/gates.md" "exit" "Exit codes captured"

# ============================================================
# LOCAL-007: /review evidence classification
# ============================================================
test_start "LOCAL-007" "/review evidence classification"
assert_file_contains "$ROOT_DIR/.opencode/commands/review.md" "VERIFIED" "VERIFIED tag"
assert_file_contains "$ROOT_DIR/.opencode/commands/review.md" "INFERRED" "INFERRED tag"
assert_file_contains "$ROOT_DIR/.opencode/commands/review.md" "OUT-OF-SCOPE" "OUT-OF-SCOPE tag"

# ============================================================
# LOCAL-008: /review contract references
# ============================================================
test_start "LOCAL-008" "/review contract references"
assert_file_contains "$ROOT_DIR/.opencode/commands/review.md" "contract" "Contract mentioned"
assert_file_contains "$ROOT_DIR/.opencode/commands/review.md" "governing" "Governing contract"

# ============================================================
# LOCAL-009: /checkpoint writes NOW.md
# ============================================================
test_start "LOCAL-009" "/checkpoint writes NOW.md"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "NOW.md" "NOW.md written"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "canonical" "Canonical state"

# ============================================================
# LOCAL-010: /checkpoint archives PLAN.md
# ============================================================
test_start "LOCAL-010" "/checkpoint archives PLAN.md"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "archived-plans" "Archive directory"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "Deletes" "Original deleted"

# ============================================================
# LOCAL-011: ADR-002 PERSISTED outcome
# ============================================================
test_start "LOCAL-011" "ADR-002 PERSISTED documented"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "PERSISTED" "PERSISTED outcome"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "dedicated.*commit" "Dedicated commit"

# ============================================================
# LOCAL-012: ADR-002 DEFERRED outcome
# ============================================================
test_start "LOCAL-012" "ADR-002 DEFERRED documented"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "DEFERRED" "DEFERRED outcome"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "/tmp/" "Patch path"

# ============================================================
# LOCAL-013: Verification-before-recommendation rule exists
# ============================================================
test_start "LOCAL-013" "Verification-before-recommendation rule exists"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Verification-before-recommendation" "Rule exists"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Before claiming a feature is" "Rule scope defined"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "\[VERIFIED\]" "VERIFIED tag mentioned"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "\[INFERRED\]" "INFERRED tag mentioned"

# ============================================================
# LOCAL-014: Evidence discipline includes file-reading requirement
# ============================================================
test_start "LOCAL-014" "Evidence discipline includes file-reading requirement"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Read the actual file" "File reading required"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "do not rely on memory" "Memory reliance forbidden"

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
