#!/usr/bin/env bash
# GitGuard Wrapper-Usage Compliance Tests
# Verifies that /implement, /ship, and /checkpoint command flows
# actually reference and require the git-guard.sh wrapper.
#
# These are BEHAVIORAL tests — they verify the command contracts
# mandate wrapper usage, not just that the wrapper exists.
#
# Usage:
#   bash .opencode/conformance/tests/git-guard-compliance.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/git-guard-compliance-${TIMESTAMP}.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

test_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo -e "  ${RED}✗${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

echo "=========================================="
echo "GitGuard Wrapper-Usage Compliance Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

WRAPPER="$ROOT_DIR/.opencode/git-guard/git-guard.sh"
IMPLEMENT_CMD="$ROOT_DIR/.opencode/commands/implement.md"
SHIP_CMD="$ROOT_DIR/.opencode/commands/ship.md"
CHECKPOINT_CMD="$ROOT_DIR/.opencode/commands/checkpoint.md"
GITGUARD_CMD="$ROOT_DIR/.opencode/commands/git-guard.md"
AGENTS_MD="$ROOT_DIR/.opencode/AGENTS.md"

# ============================================================
# /implement Flow Compliance
# ============================================================
echo "▶ /implement Flow Compliance"

# IMPL-001: implement.md references the wrapper script
test_start="IMPL-001"
if grep -q "git-guard.sh" "$IMPLEMENT_CMD" 2>/dev/null; then
    test_pass "$test_start: implement.md references git-guard.sh"
else
    test_fail "$test_start: implement.md does NOT reference git-guard.sh"
fi

# IMPL-002: implement.md specifies wrapper for commit operations
if grep -q "git-guard.sh.*commit\|commit.*git-guard.sh" "$IMPLEMENT_CMD" 2>/dev/null; then
    test_pass "IMPL-002: implement.md specifies wrapper for commit"
else
    # Check for general wrapper reference in commit context
    if grep -q "git-guard.sh" "$IMPLEMENT_CMD" 2>/dev/null && grep -q "commit" "$IMPLEMENT_CMD" 2>/dev/null; then
        test_pass "IMPL-002: implement.md has wrapper + commit in same flow"
    else
        test_fail "IMPL-002: implement.md missing wrapper for commit"
    fi
fi

# IMPL-003: implement.md lists blocked patterns
if grep -q "\-\-no-verify\|no-verify" "$IMPLEMENT_CMD" 2>/dev/null; then
    test_pass "IMPL-003: implement.md lists --no-verify as blocked"
else
    test_fail "IMPL-003: implement.md missing --no-verify block"
fi

# IMPL-004: implement.md references git-guard.md contract
if grep -q "git-guard.md" "$IMPLEMENT_CMD" 2>/dev/null; then
    test_pass "IMPL-004: implement.md references git-guard.md contract"
else
    test_fail "IMPL-004: implement.md missing git-guard.md reference"
fi

# IMPL-005: implement.md step is in the commit phase (step 13)
if grep -q "Step 13\|step 13\|13\." "$IMPLEMENT_CMD" 2>/dev/null; then
    test_pass "IMPL-005: implement.md has GitGuard at step 13"
else
    test_fail "IMPL-005: implement.md missing step 13 GitGuard"
fi

echo ""

# ============================================================
# /ship Flow Compliance
# ============================================================
echo "▶ /ship Flow Compliance"

# SHIP-001: ship.md references the wrapper script
if grep -q "git-guard.sh" "$SHIP_CMD" 2>/dev/null; then
    test_pass "SHIP-001: ship.md references git-guard.sh"
else
    test_fail "SHIP-001: ship.md does NOT reference git-guard.sh"
fi

# SHIP-002: ship.md specifies wrapper for git operations
if grep -q "mutating git operations\|git-guard.sh" "$SHIP_CMD" 2>/dev/null; then
    test_pass "SHIP-002: ship.md specifies wrapper for git operations"
else
    test_fail "SHIP-002: ship.md missing wrapper specification"
fi

# SHIP-003: ship.md lists blocked patterns
blocked_count=0
for pattern in "force" "no-verify" "main" "master"; do
    if grep -qi "$pattern" "$SHIP_CMD" 2>/dev/null; then
        blocked_count=$((blocked_count + 1))
    fi
done
if [ "$blocked_count" -ge 3 ]; then
    test_pass "SHIP-003: ship.md lists multiple blocked patterns ($blocked_count)"
else
    test_fail "SHIP-003: ship.md missing blocked patterns (found $blocked_count)"
fi

# SHIP-004: ship.md has GitGuard as a numbered step
if grep -q "Step 7\|step 7\|7\." "$SHIP_CMD" 2>/dev/null; then
    test_pass "SHIP-004: ship.md has GitGuard at step 7"
else
    test_fail "SHIP-004: ship.md missing step 7 GitGuard"
fi

# SHIP-005: ship.md has "Do not" rule for shipping without GitGuard
if grep -q "Ship without.*GitGuard\|GitGuard.*ship" "$SHIP_CMD" 2>/dev/null; then
    test_pass "SHIP-005: ship.md has Do-not rule for GitGuard"
else
    test_fail "SHIP-005: ship.md missing Do-not rule for GitGuard"
fi

echo ""

# ============================================================
# /checkpoint Flow Compliance
# ============================================================
echo "▶ /checkpoint Flow Compliance"

# CKPT-001: checkpoint.md references GitGuard
if grep -q "GitGuard\|git-guard" "$CHECKPOINT_CMD" 2>/dev/null; then
    test_pass "CKPT-001: checkpoint.md references GitGuard"
else
    test_fail "CKPT-001: checkpoint.md missing GitGuard reference"
fi

# CKPT-002: checkpoint.md has active/blocked state check
if grep -q "active/blocked\|PENDING WORK WARNING" "$CHECKPOINT_CMD" 2>/dev/null; then
    test_pass "CKPT-002: checkpoint.md has session-end check"
else
    test_fail "CKPT-002: checkpoint.md missing session-end check"
fi

echo ""

# ============================================================
# Wrapper Infrastructure Compliance
# ============================================================
echo "▶ Wrapper Infrastructure Compliance"

# INFRA-001: Wrapper script exists and is executable
if [ -f "$WRAPPER" ] && [ -x "$WRAPPER" ]; then
    test_pass "INFRA-001: Wrapper exists and is executable"
else
    test_fail "INFRA-001: Wrapper missing or not executable"
fi

# INFRA-002: Wrapper blocks --no-verify
if grep -q "\-\-no-verify" "$WRAPPER" 2>/dev/null; then
    test_pass "INFRA-002: Wrapper blocks --no-verify"
else
    test_fail "INFRA-002: Wrapper missing --no-verify block"
fi

# INFRA-003: Wrapper blocks --force
if grep -q "\-\-force" "$WRAPPER" 2>/dev/null; then
    test_pass "INFRA-003: Wrapper blocks --force"
else
    test_fail "INFRA-003: Wrapper missing --force block"
fi

# INFRA-004: Wrapper blocks direct main push
if grep -q "PROTECTED_BRANCHES\|protected_branches" "$WRAPPER" 2>/dev/null; then
    test_pass "INFRA-004: Wrapper blocks direct main/master push"
else
    test_fail "INFRA-004: Wrapper missing direct push block"
fi

# INFRA-005: Wrapper has override mechanism
if grep -q "override\|OVERRIDE" "$WRAPPER" 2>/dev/null; then
    test_pass "INFRA-005: Wrapper has override mechanism"
else
    test_fail "INFRA-005: Wrapper missing override mechanism"
fi

# INFRA-006: Wrapper has override logging
if grep -q "override-log" "$WRAPPER" 2>/dev/null; then
    test_pass "INFRA-006: Wrapper has override logging"
else
    test_fail "INFRA-006: Wrapper missing override logging"
fi

# INFRA-007: git-guard.md documents the wrapper
if grep -q "git-guard.sh" "$GITGUARD_CMD" 2>/dev/null; then
    test_pass "INFRA-007: git-guard.md documents the wrapper"
else
    test_fail "INFRA-007: git-guard.md missing wrapper documentation"
fi

# INFRA-008: AGENTS.md references the wrapper
if grep -q "git-guard.sh" "$AGENTS_MD" 2>/dev/null; then
    test_pass "INFRA-008: AGENTS.md references the wrapper"
else
    test_fail "INFRA-008: AGENTS.md missing wrapper reference"
fi

# INFRA-009: Pre-push hook exists
if [ -f "$ROOT_DIR/.opencode/git-guard/pre-push-hook.sh" ]; then
    test_pass "INFRA-009: Pre-push hook exists"
else
    test_fail "INFRA-009: Pre-push hook missing"
fi

# INFRA-010: Install script exists
if [ -f "$ROOT_DIR/.opencode/git-guard/install-hook.sh" ]; then
    test_pass "INFRA-010: Install script exists"
else
    test_fail "INFRA-010: Install script missing"
fi

echo ""

# ============================================================
# Cross-Flow Consistency
# ============================================================
echo "▶ Cross-Flow Consistency"

# CROSS-001: All three commands reference the same wrapper path
impl_ref=$(grep -o '\.opencode/git-guard/git-guard\.sh' "$IMPLEMENT_CMD" 2>/dev/null | head -1)
ship_ref=$(grep -o '\.opencode/git-guard/git-guard\.sh' "$SHIP_CMD" 2>/dev/null | head -1)
if [ "$impl_ref" = "$ship_ref" ] && [ -n "$impl_ref" ]; then
    test_pass "CROSS-001: /implement and /ship reference same wrapper path"
else
    test_fail "CROSS-001: /implement and /ship reference different wrapper paths"
fi

# CROSS-002: Wrapper path matches actual file location
if [ "$impl_ref" = ".opencode/git-guard/git-guard.sh" ] || [ "$ship_ref" = ".opencode/git-guard/git-guard.sh" ]; then
    test_pass "CROSS-002: Wrapper path matches actual file location"
else
    test_fail "CROSS-002: Wrapper path mismatch"
fi

# CROSS-003: git-guard.md lists all blocked patterns that wrapper blocks
wrapper_patterns=0
cmd_patterns=0
for pattern in "no-verify" "force" "origin main" "origin master" "HEAD:main" "HEAD:master" "reset --hard" "clean -fd"; do
    if grep -q "$pattern" "$WRAPPER" 2>/dev/null; then
        wrapper_patterns=$((wrapper_patterns + 1))
    fi
    if grep -q "$pattern" "$GITGUARD_CMD" 2>/dev/null; then
        cmd_patterns=$((cmd_patterns + 1))
    fi
done
if [ "$cmd_patterns" -ge "$wrapper_patterns" ]; then
    test_pass "CROSS-003: git-guard.md covers all wrapper-blocked patterns ($cmd_patterns >= $wrapper_patterns)"
else
    test_fail "CROSS-003: git-guard.md missing some wrapper-blocked patterns ($cmd_patterns < $wrapper_patterns)"
fi

echo ""

# ============================================================
# Results
# ============================================================
echo "=========================================="
echo -e "${GREEN}PASSED: $TESTS_PASSED${NC}"
echo -e "${RED}FAILED: $TESTS_FAILED${NC}"
echo "=========================================="

mkdir -p "$RESULTS_DIR"
{
    echo "# GitGuard Wrapper-Usage Compliance Results - $(date -Iseconds)"
    echo ""
    echo "- Passed: $TESTS_PASSED"
    echo "- Failed: $TESTS_FAILED"
    echo ""
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo "**VERDICT: ALL PASS** — All command flows mandate wrapper usage."
    else
        echo "**VERDICT: FAILURES DETECTED** — Review output above."
    fi
} > "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"

if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
fi
