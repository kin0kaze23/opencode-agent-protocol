#!/usr/bin/env bash
# GitGuard Wrapper Adversarial Tests
# Proves the execution wrapper blocks unsafe git commands.
#
# Usage:
#   bash .opencode/conformance/tests/git-guard-wrapper.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
WRAPPER="$ROOT_DIR/.opencode/git-guard/git-guard.sh"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/git-guard-wrapper-${TIMESTAMP}.md"

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
echo "GitGuard Wrapper Adversarial Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

# ============================================================
# Setup: Create sandbox repo
# ============================================================
SANDBOX_DIR=$(mktemp -d)
cd "$SANDBOX_DIR"
git init -q --initial-branch=main 2>/dev/null || git init -q
git config user.email "test@opencode.local"
git config user.name "Test User"
echo "# Sandbox" > README.md
git add README.md
git commit -q -m "Initial commit"

# Create a remote
REMOTE_DIR=$(mktemp -d)
git init -q --bare "$REMOTE_DIR"
git remote add origin "$REMOTE_DIR"

echo "Sandbox: $SANDBOX_DIR"
echo ""

# ============================================================
# TEST-001: Wrapper blocks commit --no-verify
# ============================================================
echo "▶ TEST-001: Wrapper blocks commit --no-verify"

output=$(bash "$WRAPPER" commit --no-verify -m "bypass hooks" 2>&1) && exit_code=0 || exit_code=$?

if [ "$exit_code" -eq 1 ] && echo "$output" | grep -q "DENIED"; then
    test_pass "commit --no-verify blocked with DENIED message"
else
    test_fail "commit --no-verify not blocked (exit=$exit_code): $output"
fi

# ============================================================
# TEST-002: Wrapper blocks commit -n (short form)
# ============================================================
echo "▶ TEST-002: Wrapper blocks commit -n"

output=$(bash "$WRAPPER" commit -n -m "bypass hooks" 2>&1) && exit_code=0 || exit_code=$?

if [ "$exit_code" -eq 1 ] && echo "$output" | grep -q "DENIED"; then
    test_pass "commit -n blocked with DENIED message"
else
    test_fail "commit -n not blocked (exit=$exit_code): $output"
fi

# ============================================================
# TEST-003: Wrapper blocks push --force
# ============================================================
echo "▶ TEST-003: Wrapper blocks push --force"

output=$(bash "$WRAPPER" push --force origin main 2>&1) && exit_code=0 || exit_code=$?

if [ "$exit_code" -eq 1 ] && echo "$output" | grep -q "DENIED"; then
    test_pass "push --force blocked with DENIED message"
else
    test_fail "push --force not blocked (exit=$exit_code): $output"
fi

# ============================================================
# TEST-004: Wrapper blocks push -f
# ============================================================
echo "▶ TEST-004: Wrapper blocks push -f"

output=$(bash "$WRAPPER" push -f origin main 2>&1) && exit_code=0 || exit_code=$?

if [ "$exit_code" -eq 1 ] && echo "$output" | grep -q "DENIED"; then
    test_pass "push -f blocked with DENIED message"
else
    test_fail "push -f not blocked (exit=$exit_code): $output"
fi

# ============================================================
# TEST-005: Wrapper blocks push origin main (direct protected branch)
# ============================================================
echo "▶ TEST-005: Wrapper blocks push origin main"

output=$(bash "$WRAPPER" push origin main 2>&1) && exit_code=0 || exit_code=$?

if [ "$exit_code" -eq 1 ] && echo "$output" | grep -q "DENIED"; then
    test_pass "push origin main blocked with DENIED message"
else
    test_fail "push origin main not blocked (exit=$exit_code): $output"
fi

# ============================================================
# TEST-006: Wrapper blocks push origin HEAD:main (refspec)
# ============================================================
echo "▶ TEST-006: Wrapper blocks push origin HEAD:main"

output=$(bash "$WRAPPER" push origin HEAD:main 2>&1) && exit_code=0 || exit_code=$?

if [ "$exit_code" -eq 1 ] && echo "$output" | grep -q "DENIED"; then
    test_pass "push origin HEAD:main blocked with DENIED message"
else
    test_fail "push origin HEAD:main not blocked (exit=$exit_code): $output"
fi

# ============================================================
# TEST-007: Wrapper blocks push origin HEAD:master (refspec)
# ============================================================
echo "▶ TEST-007: Wrapper blocks push origin HEAD:master"

output=$(bash "$WRAPPER" push origin HEAD:master 2>&1) && exit_code=0 || exit_code=$?

if [ "$exit_code" -eq 1 ] && echo "$output" | grep -q "DENIED"; then
    test_pass "push origin HEAD:master blocked with DENIED message"
else
    test_fail "push origin HEAD:master not blocked (exit=$exit_code): $output"
fi

# ============================================================
# TEST-008: Wrapper blocks reset --hard
# ============================================================
echo "▶ TEST-008: Wrapper blocks reset --hard"

output=$(bash "$WRAPPER" reset --hard HEAD 2>&1) && exit_code=0 || exit_code=$?

if [ "$exit_code" -eq 1 ] && echo "$output" | grep -q "DENIED"; then
    test_pass "reset --hard blocked with DENIED message"
else
    test_fail "reset --hard not blocked (exit=$exit_code): $output"
fi

# ============================================================
# TEST-009: Wrapper blocks clean -fd
# ============================================================
echo "▶ TEST-009: Wrapper blocks clean -fd"

output=$(bash "$WRAPPER" clean -fd 2>&1) && exit_code=0 || exit_code=$?

if [ "$exit_code" -eq 1 ] && echo "$output" | grep -q "DENIED"; then
    test_pass "clean -fd blocked with DENIED message"
else
    test_fail "clean -fd not blocked (exit=$exit_code): $output"
fi

# ============================================================
# TEST-010: Safe command passes through — git status
# ============================================================
echo "▶ TEST-010: Safe command passes through — git status"

output=$(bash "$WRAPPER" status 2>&1) && exit_code=0 || exit_code=$?

if [ "$exit_code" -eq 0 ]; then
    test_pass "git status allowed and executed"
else
    test_fail "git status blocked unexpectedly (exit=$exit_code): $output"
fi

# ============================================================
# TEST-011: Safe command passes through — git log
# ============================================================
echo "▶ TEST-011: Safe command passes through — git log"

output=$(bash "$WRAPPER" log --oneline -1 2>&1) && exit_code=0 || exit_code=$?

if [ "$exit_code" -eq 0 ]; then
    test_pass "git log allowed and executed"
else
    test_fail "git log blocked unexpectedly (exit=$exit_code): $output"
fi

# ============================================================
# TEST-012: Safe command passes through — git commit (normal)
# ============================================================
echo "▶ TEST-012: Safe command passes through — git commit (normal)"

echo "safe change" > safe.txt
git add safe.txt
output=$(bash "$WRAPPER" commit -m "Safe commit" 2>&1) && exit_code=0 || exit_code=$?

if [ "$exit_code" -eq 0 ]; then
    test_pass "git commit (normal) allowed and executed"
else
    test_fail "git commit (normal) blocked unexpectedly (exit=$exit_code): $output"
fi

# ============================================================
# TEST-013: Safe command passes through — git push to feature branch
# ============================================================
echo "▶ TEST-013: Safe command passes through — git push to feature branch"

git checkout -b feat/test-branch -q
echo "feature" > feature.txt
git add feature.txt
git commit -q -m "Feature work"
output=$(bash "$WRAPPER" push origin feat/test-branch 2>&1) && exit_code=0 || exit_code=$?

if [ "$exit_code" -eq 0 ]; then
    test_pass "git push to feature branch allowed and executed"
else
    test_fail "git push to feature branch blocked unexpectedly (exit=$exit_code): $output"
fi

# ============================================================
# TEST-014: Override mechanism works
# ============================================================
echo "▶ TEST-014: Override mechanism works"

# Create override file in sandbox (where the wrapper runs from)
cd "$SANDBOX_DIR"
echo "Test override for validation" > ".gitguard-override"

output=$(bash "$WRAPPER" commit --no-verify -m "override test" 2>&1) && exit_code=0 || exit_code=$?

# The override should be applied (exit code 3) OR git may fail for other reasons
# (e.g., nothing to commit). The key is that the wrapper didn't DENY the command.
if echo "$output" | grep -q "OVERRIDE APPLIED"; then
    test_pass "Override mechanism executed command with logging"
else
    test_fail "Override mechanism failed (exit=$exit_code): $output"
fi

# Verify override file was consumed (one-time use)
if [ ! -f ".gitguard-override" ]; then
    test_pass "Override file consumed after use (one-time)"
else
    test_fail "Override file not consumed after use"
fi

# Go back to workspace root for remaining tests
cd "$ROOT_DIR"

# ============================================================
# TEST-015: Override log exists
# ============================================================
echo "▶ TEST-015: Override log exists"

OVERRIDE_LOG="$ROOT_DIR/.opencode/git-guard/override-log.jsonl"
if [ -f "$OVERRIDE_LOG" ] && grep -q "Test override for validation" "$OVERRIDE_LOG"; then
    test_pass "Override logged to override-log.jsonl"
else
    test_fail "Override not logged"
fi

# ============================================================
# Cleanup
# ============================================================
echo ""
echo "Cleaning up sandbox..."
rm -rf "$SANDBOX_DIR" "$REMOTE_DIR"

# ============================================================
# Results
# ============================================================
echo ""
echo "=========================================="
echo -e "${GREEN}PASSED: $TESTS_PASSED${NC}"
echo -e "${RED}FAILED: $TESTS_FAILED${NC}"
echo "=========================================="

mkdir -p "$RESULTS_DIR"
{
    echo "# GitGuard Wrapper Test Results - $(date -Iseconds)"
    echo ""
    echo "- Passed: $TESTS_PASSED"
    echo "- Failed: $TESTS_FAILED"
    echo "- Sandbox: $(basename "$SANDBOX_DIR") (cleaned up)"
    echo ""
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo "**VERDICT: ALL PASS** — Wrapper enforcement verified."
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
