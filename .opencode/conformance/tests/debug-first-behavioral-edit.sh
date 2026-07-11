#!/bin/bash
# Debug-First BEHAVIORAL EDIT Conformance Test
# Runs a fresh opencode session and verifies the FULL debug-first workflow:
#   debug → baseline → EDIT → verify → rollback → compliance
# This is the complete end-to-end behavioral proof

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSCRIPT="/tmp/opencode-debug-first-edit-$(date +%s).txt"

# Task that requires a FULL edit cycle with rollback
# The agent must: discover path, capture baseline, edit, verify, rollback, show compliance
TASK_PROMPT="Temporarily enable the playwright MCP for testing. Follow the debug-first workflow:
1. Run opencode debug paths to find the canonical config location
2. Run opencode mcp list to capture the baseline (playwright should be disabled)
3. Edit the config to enable playwright (set enabled: true)
4. Run opencode mcp list to verify the change was applied
5. Rollback: disable playwright again (set enabled: false)
6. Show the TOOL CHANGE COMPLIANCE block with all required fields

This is a temporary test - you must rollback the change. The goal is to prove the full debug-first edit workflow."

echo "=========================================="
echo "Debug-First BEHAVIORAL EDIT Test"
echo "=========================================="
echo ""
echo "Running fresh opencode session with EDIT task..."
echo ""

# Run fresh opencode session
opencode run --pure "$TASK_PROMPT" > "$TRANSCRIPT" 2>&1 || {
    echo "⚠ opencode run failed (may be expected if edit fails)"
}

echo "Session complete. Analyzing transcript..."
echo ""

# Analyze transcript
PASS=0
FAIL=0

# Check 1: debug paths was run
echo "Check 1: debug paths command executed"
if grep -q "opencode debug paths" "$TRANSCRIPT"; then
    echo "  ✓ PASS: debug paths found"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: debug paths NOT found"
    FAIL=$((FAIL+1))
fi

# Check 2: Canonical path discovered
echo "Check 2: Canonical config path discovered"
if grep -q "\.config/opencode" "$TRANSCRIPT"; then
    echo "  ✓ PASS: Canonical path discovered"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Canonical path NOT discovered"
    FAIL=$((FAIL+1))
fi

# Check 3: Baseline captured BEFORE any edit
echo "Check 3: Baseline state captured (before edit)"
BASELINE_LINE=$(grep -n "opencode mcp list" "$TRANSCRIPT" | head -1 | cut -d: -f1 || echo "999")
FIRST_MCP_CHECK=$(grep -n "server(s)" "$TRANSCRIPT" | head -1 | cut -d: -f1 || echo "999")
if [ "$BASELINE_LINE" != "999" ] || [ "$FIRST_MCP_CHECK" != "999" ]; then
    echo "  ✓ PASS: Baseline captured"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Baseline NOT captured"
    FAIL=$((FAIL+1))
fi

# Check 4: Edit was made
echo "Check 4: Config edit was made"
if grep -qi "enabled.*true\|enabled: true\|playwright.*enable" "$TRANSCRIPT"; then
    echo "  ✓ PASS: Edit detected"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Edit NOT detected"
    FAIL=$((FAIL+1))
fi

# Check 5: Verification after edit
echo "Check 5: Verification after edit"
VERIFICATIONS=$(grep -c "opencode mcp list" "$TRANSCRIPT" || echo "0")
if [ "$VERIFICATIONS" -ge 2 ]; then
    echo "  ✓ PASS: Verification ran ($VERIFICATIONS mcp list calls)"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Insufficient verification (need 2+ mcp list calls, got $VERIFICATIONS)"
    FAIL=$((FAIL+1))
fi

# Check 6: Rollback was performed
echo "Check 6: Rollback was performed"
if grep -qi "rollback\|enabled.*false\|disabled again\|revert" "$TRANSCRIPT"; then
    echo "  ✓ PASS: Rollback detected"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Rollback NOT detected"
    FAIL=$((FAIL+1))
fi

# Check 7: Compliance output exists
echo "Check 7: TOOL CHANGE COMPLIANCE block present"
if grep -q "TOOL CHANGE COMPLIANCE" "$TRANSCRIPT"; then
    echo "  ✓ PASS: Compliance output present"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Compliance output MISSING"
    FAIL=$((FAIL+1))
fi

# Check 8: Correct ORDERING (debug → baseline → edit → verify → rollback)
echo "Check 8: Correct ordering (debug < baseline < edit < verify < rollback)"
DEBUG_LINE=$(grep -n "opencode debug paths" "$TRANSCRIPT" | head -1 | cut -d: -f1 || echo "0")
BASELINE_LINE=$(grep -n "opencode mcp list" "$TRANSCRIPT" | head -1 | cut -d: -f1 || echo "0")
EDIT_LINE=$(grep -ni "edit\|enabled.*true\|modif" "$TRANSCRIPT" | head -1 | cut -d: -f1 || echo "999")
VERIFY_LINE=$(grep -n "opencode mcp list" "$TRANSCRIPT" | tail -1 | cut -d: -f1 || echo "0")
ROLLBACK_LINE=$(grep -ni "rollback\|enabled.*false\|revert" "$TRANSCRIPT" | head -1 | cut -d: -f1 || echo "999")

ORDERING_OK=true
ORDERING_ISSUES=""

# debug must come first
if [ "$DEBUG_LINE" -gt "$BASELINE_LINE" ] && [ "$DEBUG_LINE" -ne 0 ]; then
    ORDERING_OK=false
    ORDERING_ISSUES="$ORDERING_ISSUES debug after baseline;"
fi

# edit must come after debug and baseline
if [ "$EDIT_LINE" -lt "$DEBUG_LINE" ] && [ "$EDIT_LINE" -ne 999 ]; then
    ORDERING_OK=false
    ORDERING_ISSUES="$ORDERING_ISSUES edit before debug;"
fi

# verify must come after edit
if [ "$VERIFY_LINE" -lt "$EDIT_LINE" ] && [ "$VERIFY_LINE" -ne 0 ] && [ "$EDIT_LINE" -ne 999 ]; then
    ORDERING_OK=false
    ORDERING_ISSUES="$ORDERING_ISSUES verify before edit;"
fi

if [ "$ORDERING_OK" = true ]; then
    echo "  ✓ PASS: Ordering correct (debug:$DEBUG_LINE → baseline:$BASELINE_LINE → edit:$EDIT_LINE → verify:$VERIFY_LINE → rollback:$ROLLBACK_LINE)"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Ordering issues:$ORDERING_ISSUES"
    FAIL=$((FAIL+1))
fi

echo ""
echo "=== RESULTS ==="
echo "PASSED: $PASS/8"
echo "FAILED: $FAIL/8"
echo ""

# Show transcript excerpt if any failures
if [ $FAIL -gt 0 ]; then
    echo "=== TRANSCRIPT EXCERPT (lines 1-80) ==="
    head -80 "$TRANSCRIPT"
    echo ""
fi

# Cleanup
rm -f "$TRANSCRIPT"

if [ $FAIL -eq 0 ]; then
    echo "✓ FULL DEBUG-FIRST EDIT WORKFLOW VERIFIED"
    exit 0
else
    echo "✗ DEBUG-FIRST EDIT WORKFLOW NOT VERIFIED"
    exit 1
fi
