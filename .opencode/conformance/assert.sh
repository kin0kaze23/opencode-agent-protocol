#!/bin/bash
# Conformance Suite Assertion Helpers
# Usage: source .opencode/conformance/assert.sh

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
CURRENT_TEST=""

# Start a test block
test_start() {
    local test_id="$1"
    local test_name="$2"
    CURRENT_TEST="$test_id: $test_name"
    echo -e "\n${YELLOW}▶ $CURRENT_TEST${NC}"
}

# Assert: file exists
assert_file_exists() {
    local file="$1"
    local description="${2:-file exists}"
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $description: $file"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description: $file NOT FOUND"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Assert: file does NOT exist
assert_file_not_exists() {
    local file="$1"
    local description="${2:-file does not exist}"
    if [ ! -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $description: $file"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description: $file EXISTS (should not)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Assert: file contains pattern
assert_file_contains() {
    local file="$1"
    local pattern="$2"
    local description="${3:-file contains pattern}"
    if grep -q -- "$pattern" "$file" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $description: '$pattern' in $file"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description: '$pattern' NOT FOUND in $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Assert: file does NOT contain pattern
assert_file_not_contains() {
    local file="$1"
    local pattern="$2"
    local description="${3:-file does not contain pattern}"
    if ! grep -q -- "$pattern" "$file" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $description: '$pattern' absent from $file"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description: '$pattern' FOUND in $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Assert: output contains pattern
assert_output_contains() {
    local output="$1"
    local pattern="$2"
    local description="${3:-output contains pattern}"
    if echo "$output" | grep -q -- "$pattern"; then
        echo -e "  ${GREEN}✓${NC} $description: '$pattern'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description: '$pattern' NOT FOUND"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Assert: git commit exists with message
assert_git_commit() {
    local repo="$1"
    local message_pattern="$2"
    local description="${3:-git commit exists}"
    if git -C "$repo" log --oneline -10 | grep -q "$message_pattern"; then
        local hash=$(git -C "$repo" log --oneline -1 | grep "$message_pattern" | awk '{print $1}')
        echo -e "  ${GREEN}✓${NC} $description: '$message_pattern' → $hash"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description: '$message_pattern' NOT FOUND"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Assert: directory is clean (no uncommitted changes)
assert_dir_clean() {
    local dir="$1"
    local description="${2:-directory is clean}"
    local changes=$(git -C "$dir" status --short 2>/dev/null | wc -l)
    if [ "$changes" -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} $description: 0 uncommitted changes"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description: $changes uncommitted changes"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Assert: value equals expected
assert_equals() {
    local expected="$1"
    local actual="$2"
    local description="${3:-values match}"
    if [ "$expected" = "$actual" ]; then
        echo -e "  ${GREEN}✓${NC} $description: '$actual'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description: expected '$expected', got '$actual'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Report test results
report_results() {
    local output_file="$1"
    echo ""
    echo "=========================================="
    echo -e "${GREEN}PASSED: $TESTS_PASSED${NC}"
    echo -e "${RED}FAILED: $TESTS_FAILED${NC}"
    if [ "$TESTS_SKIPPED" -gt 0 ]; then
        echo -e "${YELLOW}SKIPPED: $TESTS_SKIPPED${NC}"
    fi
    echo "=========================================="

    if [ -n "$output_file" ]; then
        mkdir -p "$(dirname "$output_file")"
        {
            echo "# Test Results - $(date -Iseconds)"
            echo ""
            echo "- Passed: $TESTS_PASSED"
            echo "- Failed: $TESTS_FAILED"
            if [ "$TESTS_SKIPPED" -gt 0 ]; then
                echo "- Skipped: $TESTS_SKIPPED"
            fi
            echo ""
        } >> "$output_file"
    fi

    if [ "$TESTS_FAILED" -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Reset counters
reset_counters() {
    TESTS_PASSED=0
    TESTS_FAILED=0
}
