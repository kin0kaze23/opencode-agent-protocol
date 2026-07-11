#!/bin/bash
# Failure Recovery Tests - Edge Cases and Error Handling
# Tests protocol behavior under failure conditions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"  # Go up 3 levels to workspace root
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/failure-recovery-${TIMESTAMP}.md"

# Source assertion helpers
source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Failure Recovery Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

# ============================================================
# FAILURE-001: Dirty-state detection in startup
# ============================================================
test_start "FAILURE-001" "Dirty-state detection documented"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "git status --short" "Dirty-state check"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "Major risks" "Dirty state reported"

# ============================================================
# FAILURE-002: Gate double-failure triggers postmortem
# ============================================================
test_start "FAILURE-002" "Gate double-failure postmortem"
assert_file_contains "$ROOT_DIR/.opencode/commands/gates.md" "Two failures" "Double failure detected"
assert_file_contains "$ROOT_DIR/.opencode/commands/gates.md" "postmortem" "Postmortem triggered"
assert_file_contains "$ROOT_DIR/.opencode/commands/gates.md" "lessons.md" "Lesson recorded"

# ============================================================
# FAILURE-003: /ship refuses without separate approval
# ============================================================
test_start "FAILURE-003" "/ship approval boundary"
assert_file_contains "$ROOT_DIR/.opencode/commands/ship.md" "separate.*approval" "Separate approval required"
assert_file_contains "$ROOT_DIR/.opencode/commands/ship.md" "continue end to end" "E2E does NOT authorize ship"

# ============================================================
# FAILURE-004: /ship enforces gates before PR
# ============================================================
test_start "FAILURE-004" "/ship gates before PR"
assert_file_contains "$ROOT_DIR/.opencode/commands/ship.md" "gates" "Gates run"
assert_file_contains "$ROOT_DIR/.opencode/commands/ship.md" "If gates fail" "Failure stops ship"

# ============================================================
# FAILURE-005: "continue end to end" scope limited
# ============================================================
test_start "FAILURE-005" "E2E scope limited to local"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "continue end to end" "E2E mentioned"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "does NOT authorize remote" "Remote excluded"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "push" "Push requires approval"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "PR creation" "PR requires approval"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "deployment" "Deploy requires approval"

# ============================================================
# FAILURE-006: Vault dirty does NOT block checkpoint
# ============================================================
test_start "FAILURE-006" "Vault dirty is DEFERRED not BLOCKED"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "Vault is non-authoritative" "Non-authoritative stated"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "does NOT block" "Does not block"

# ============================================================
# FAILURE-007: Touch-list expansion cannot be silent
# ============================================================
test_start "FAILURE-007" "Touch-list expansion disclosure required"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "TOUCH LIST EXPANSION" "Expansion block documented"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Silent edits outside the touch list are never allowed" "Silent expansion forbidden"

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
