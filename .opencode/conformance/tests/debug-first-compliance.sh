#!/bin/bash
# Debug-First Compliance Test
# Verifies that tool-specific changes follow debug-first workflow

set -e

PASS=0
FAIL=0

echo "=== DEBUG-FIRST COMPLIANCE TEST ==="
echo ""

# Test 1: Verify debug-first rule exists in AGENTS.md
echo "Test 1: Debug-first rule in AGENTS.md"
if grep -q "Debug-First Execution Rule" .opencode/AGENTS.md; then
    echo "  ✓ PASS: Debug-first rule documented"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Debug-first rule not found in AGENTS.md"
    FAIL=$((FAIL+1))
fi

# Test 2: Verify failure-pivot rule exists
echo "Test 2: Failure-pivot rule in AGENTS.md"
if grep -q "Failure-pivot rule" .opencode/AGENTS.md; then
    echo "  ✓ PASS: Failure-pivot rule documented"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Failure-pivot rule not found in AGENTS.md"
    FAIL=$((FAIL+1))
fi

# Test 3: Verify compliance output format exists
echo "Test 3: Compliance output format in AGENTS.md"
if grep -q "TOOL CHANGE COMPLIANCE" .opencode/AGENTS.md; then
    echo "  ✓ PASS: Compliance output format documented"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Compliance output format not found in AGENTS.md"
    FAIL=$((FAIL+1))
fi

# Test 4: Verify opencode debug paths is mentioned
echo "Test 4: opencode debug paths mentioned"
if grep -q "opencode debug paths" .opencode/AGENTS.md; then
    echo "  ✓ PASS: opencode debug paths referenced"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: opencode debug paths not referenced"
    FAIL=$((FAIL+1))
fi

# Test 5: Verify "Do NOT edit tool configs without debug-first" rule
echo "Test 5: Edit prohibition rule in 'What You Do NOT Do'"
if grep -q "Edit tool configs without running debug-first" .opencode/AGENTS.md; then
    echo "  ✓ PASS: Edit prohibition rule documented"
    PASS=$((PASS+1))
else
    echo "  ✗ FAIL: Edit prohibition rule not found"
    FAIL=$((FAIL+1))
fi

echo ""
echo "=== RESULTS ==="
echo "PASSED: $PASS"
echo "FAILED: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "✓ Debug-first compliance rules are properly documented"
    exit 0
else
    echo "✗ Some debug-first compliance rules are missing"
    exit 1
fi
