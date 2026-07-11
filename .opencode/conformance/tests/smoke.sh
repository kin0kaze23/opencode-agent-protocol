#!/bin/bash
# Smoke Tests - Basic Protocol Sanity
# Runs in < 60 seconds, verifies core contract behavior

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"  # Go up 3 levels to workspace root
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/smoke-${TIMESTAMP}.md"

# Source assertion helpers
source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Smoke Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

# ============================================================
# SMOKE-001: WORKSPACE_MAP.md exists at startup
# ============================================================
test_start "SMOKE-001" "WORKSPACE_MAP.md exists"
assert_file_exists "$ROOT_DIR/WORKSPACE_MAP.md" "Workspace map file"

# ============================================================
# SMOKE-002: .opencode/AGENTS.md exists
# ============================================================
test_start "SMOKE-002" ".opencode/AGENTS.md exists"
assert_file_exists "$ROOT_DIR/.opencode/AGENTS.md" "Owner agent protocol"

# ============================================================
# SMOKE-003: Protocol commands directory exists
# ============================================================
test_start "SMOKE-003" "Protocol commands exist"
for cmd in checkpoint gates implement plan-feature review ship; do
    assert_file_exists "$ROOT_DIR/.opencode/commands/${cmd}.md" "Command: $cmd"
done

# ============================================================
# SMOKE-004: ADR-001 canonical state documented
# ============================================================
test_start "SMOKE-004" "ADR-001 canonical state documented"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "NOW.md" "Canonical state mentioned"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "CANONICAL" "Authority level defined"

# ============================================================
# SMOKE-005: ADR-002 vault persistence documented
# ============================================================
test_start "SMOKE-005" "ADR-002 vault persistence documented"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "PERSISTED" "PERSISTED outcome"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "DEFERRED" "DEFERRED outcome"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "git -C vault" "Nested repo detection"

# ============================================================
# SMOKE-006: Test repo fixture exists
# ============================================================
test_start "SMOKE-006" "Test fixture structure"
FIXTURES_DIR="$SCRIPT_DIR/../fixtures/repos"
if [ -d "$FIXTURES_DIR" ]; then
    echo -e "  ${GREEN}✓${NC} Fixtures directory exists: $FIXTURES_DIR"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} Fixtures directory NOT FOUND: $FIXTURES_DIR"
    ((TESTS_FAILED++))
fi

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
