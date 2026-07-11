#!/bin/bash
# Debug-First BEHAVIORAL Conformance Test
# Runs a fresh opencode session and verifies debug-first behavior in practice
# This is NOT a documentation check - it's a behavioral proof test

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRANSCRIPT="/tmp/opencode-debug-first-behavioral-$(date +%s).txt"

# Task that REQUIRES tool-specific diagnostics
# The agent MUST run debug commands to complete this correctly
TASK_PROMPT="Check the MCP configuration. Use opencode debug paths to find the canonical config location, then use opencode mcp list to report the baseline status. Do NOT edit anything - this is a diagnostic-only task. End your response with the TOOL CHANGE COMPLIANCE block showing the canonical path you discovered and the baseline state."

echo "=========================================="
echo "Debug-First BEHAVIORAL Conformance Test"
echo "=========================================="
echo ""
echo "Running fresh opencode session with tool-specific task..."
echo ""

# Run fresh opencode session (non-interactive)
# --pure ensures no plugins interfere with test
opencode run --pure "$TASK_PROMPT" > "$TRANSCRIPT" 2>&1 || {
    echo "✗ opencode run failed"
    cat "$TRANSCRIPT"
    exit 1
}

echo "Session complete. Analyzing transcript for debug-first evidence..."
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

# Check 3: Baseline captured (mcp list or similar)
echo "Check 3: Baseline state captured"
if grep -qE "opencode mcp list|server\(s\)|✓.*connected|○.*disabled" "$TRANSCRIPT"; then
    echo "  ✓ PASS: Baseline captured"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Baseline NOT captured"
    FAIL=$((FAIL+1))
fi

# Check 4: Compliance output exists
echo "Check 4: TOOL CHANGE COMPLIANCE block present"
if grep -q "TOOL CHANGE COMPLIANCE" "$TRANSCRIPT"; then
    echo "  ✓ PASS: Compliance output present"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Compliance output MISSING"
    FAIL=$((FAIL+1))
fi

# Check 5: Canonical path in compliance block
echo "Check 5: Canonical path documented in compliance block"
if grep -A15 "TOOL CHANGE COMPLIANCE" "$TRANSCRIPT" | grep -q "CANONICAL PATH DISCOVERED"; then
    echo "  ✓ PASS: Canonical path in compliance block"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Canonical path NOT in compliance block"
    FAIL=$((FAIL+1))
fi

# Check 6: No premature edits (debug before any edit mention)
echo "Check 6: Debug-first ordering (no edit before debug)"
DEBUG_LINE=$(grep -n "debug paths" "$TRANSCRIPT" 2>/dev/null | head -1 | cut -d: -f1 || echo "999")
EDIT_LINE=$(grep -n -i "edit\|modif" "$TRANSCRIPT" 2>/dev/null | head -1 | cut -d: -f1 || echo "999")

if [ "$DEBUG_LINE" != "999" ] && [ "$EDIT_LINE" != "999" ]; then
    if [ "$DEBUG_LINE" -lt "$EDIT_LINE" ]; then
        echo "  ✓ PASS: Debug (line $DEBUG_LINE) before edit (line $EDIT_LINE)"
        PASS=$((PASS+1))
    else
        echo "  ✗ FAIL: Edit (line $EDIT_LINE) before debug (line $DEBUG_LINE)"
        FAIL=$((FAIL+1))
    fi
elif [ "$DEBUG_LINE" != "999" ] && [ "$EDIT_LINE" = "999" ]; then
    echo "  ✓ PASS: No edit made (read-only task - correct behavior)"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: No debug found, may have edited without diagnostics"
    FAIL=$((FAIL+1))
fi

echo ""
echo "=== RESULTS ==="
echo "PASSED: $PASS/6"
echo "FAILED: $FAIL/6"
echo ""

# Show transcript excerpt if failed
if [ $FAIL -gt 0 ]; then
    echo "=== TRANSCRIPT EXCERPT (last 50 lines) ==="
    tail -50 "$TRANSCRIPT"
    echo ""
fi

# Cleanup
rm -f "$TRANSCRIPT"

if [ $FAIL -eq 0 ]; then
    echo "✓ DEBUG-FIRST BEHAVIOR VERIFIED - Agent follows debug-first in fresh session"
    exit 0
else
    echo "✗ DEBUG-FIRST BEHAVIOR NOT VERIFIED - Agent did not follow debug-first consistently"
    exit 1
fi
