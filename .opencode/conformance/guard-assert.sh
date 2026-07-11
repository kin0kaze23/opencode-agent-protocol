#!/bin/bash
# Conformance Guard Assertion Helpers — Phase C1
# Extends assert.sh with PASS/WARN/FAIL semantics and drift classification.
# Usage: source .opencode/conformance/guard-assert.sh

set -uo pipefail

# Source base assertions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/assert.sh"

# Colors
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'

# Counters
GUARD_PASSED=0
GUARD_WARNED=0
GUARD_FAILED=0
GUARD_SKIPPED=0

# Drift registry (loaded from known-c0-drift.json)
DRIFT_FILE=""
MODE="audit"  # audit or enforce

# Load drift registry
load_drift_registry() {
    local workspace_root="$1"
    DRIFT_FILE="$workspace_root/.opencode/policies/known-c0-drift.json"
    if [ ! -f "$DRIFT_FILE" ]; then
        echo -e "${YELLOW}⚠ Drift registry not found at $DRIFT_FILE${NC}"
        return 1
    fi
    return 0
}

# Check if a drift ID is known
is_known_drift() {
    local drift_id="$1"
    if [ -z "$DRIFT_FILE" ] || [ ! -f "$DRIFT_FILE" ]; then
        return 1
    fi
    grep -q "\"$drift_id\"" "$DRIFT_FILE" 2>/dev/null
}

# Get drift classification for a known drift ID
get_drift_classification() {
    local drift_id="$1"
    if [ -z "$DRIFT_FILE" ] || [ ! -f "$DRIFT_FILE" ]; then
        echo "UNKNOWN"
        return
    fi
    # Extract classification for this drift ID
    python3 -c "
import json, sys
with open('$DRIFT_FILE') as f:
    data = json.load(f)
for item in data.get('drift_items', []):
    if item.get('id') == '$drift_id':
        print(item.get('classification', 'UNKNOWN'))
        sys.exit(0)
print('UNKNOWN')
" 2>/dev/null || echo "UNKNOWN"
}

# Guard check: PASS
guard_pass() {
    local check_id="$1"
    local description="$2"
    local detail="${3:-}"
    echo -e "  ${GREEN}✓ PASS${NC} [$check_id] $description"
    if [ -n "$detail" ]; then
        echo -e "    ${CYAN}→${NC} $detail"
    fi
    GUARD_PASSED=$((GUARD_PASSED + 1))
}

# Guard check: WARN (known drift or audit-mode issue)
guard_warn() {
    local check_id="$1"
    local description="$2"
    local drift_id="${3:-}"
    local detail="${4:-}"
    local classification=""

    if [ -n "$drift_id" ] && is_known_drift "$drift_id"; then
        classification=$(get_drift_classification "$drift_id")
        echo -e "  ${YELLOW}⚠ WARN${NC} [$check_id] $description"
        echo -e "    ${YELLOW}→${NC} Known drift: $drift_id ($classification)"
    else
        echo -e "  ${YELLOW}⚠ WARN${NC} [$check_id] $description"
        echo -e "    ${YELLOW}→${NC} Unclassified drift — review needed"
    fi
    if [ -n "$detail" ]; then
        echo -e "    ${CYAN}→${NC} $detail"
    fi
    GUARD_WARNED=$((GUARD_WARNED + 1))
}

# Guard check: FAIL (new/unexpected drift or enforce-mode violation)
guard_fail() {
    local check_id="$1"
    local description="$2"
    local expected="${3:-}"
    local actual="${4:-}"
    local detail="${5:-}"
    echo -e "  ${RED}✗ FAIL${NC} [$check_id] $description"
    if [ -n "$expected" ]; then
        echo -e "    ${RED}→${NC} Expected: $expected"
    fi
    if [ -n "$actual" ]; then
        echo -e "    ${RED}→${NC} Actual: $actual"
    fi
    if [ -n "$detail" ]; then
        echo -e "    ${CYAN}→${NC} $detail"
    fi
    GUARD_FAILED=$((GUARD_FAILED + 1))
}

# Guard check: SKIP (not applicable in current mode)
guard_skip() {
    local check_id="$1"
    local description="$2"
    local reason="${3:-}"
    echo -e "  ${BLUE}○ SKIP${NC} [$check_id] $description"
    if [ -n "$reason" ]; then
        echo -e "    ${CYAN}→${NC} $reason"
    fi
    GUARD_SKIPPED=$((GUARD_SKIPPED + 1))
}

# JSON value extractor using jq
json_value() {
    local file="$1"
    local key="$2"
    # Convert dot notation to jq path, handling hyphenated keys
    # e.g., "provider.bailian-coding-plan" → ".provider[\"bailian-coding-plan\"]"
    local jq_path=""
    IFS='.' read -ra parts <<< "$key"
    for part in "${parts[@]}"; do
        if [[ "$part" == *-* ]]; then
            jq_path="${jq_path}[\"${part}\"]"
        else
            jq_path="${jq_path}.${part}"
        fi
    done
    # Use jq to get raw value, but handle false/null correctly
    local result
    result=$(jq -r "if $jq_path == null then \"NULL\" elif $jq_path == false then \"false\" elif $jq_path == true then \"true\" else ($jq_path | tostring) end" "$file" 2>/dev/null) || result="NULL"
    echo "$result"
}

# JSON key exists check
json_key_exists() {
    local file="$1"
    local key="$2"
    # Convert dot notation to jq path, handling hyphenated keys
    local jq_path=""
    IFS='.' read -ra parts <<< "$key"
    for part in "${parts[@]}"; do
        if [[ "$part" == *-* ]]; then
            jq_path="${jq_path}[\"${part}\"]"
        else
            jq_path="${jq_path}.${part}"
        fi
    done
    local val
    val=$(jq "$jq_path" "$file" 2>/dev/null) || val="null"
    if [ "$val" = "null" ]; then
        return 1
    else
        return 0
    fi
}

# Report guard results
guard_report() {
    local output_file="$1"
    local guard_name="$2"
    echo ""
    echo "=========================================="
    echo -e "${GREEN}PASS: $GUARD_PASSED${NC}"
    echo -e "${YELLOW}WARN: $GUARD_WARNED${NC}"
    echo -e "${RED}FAIL: $GUARD_FAILED${NC}"
    echo -e "${BLUE}SKIP: $GUARD_SKIPPED${NC}"
    echo "=========================================="

    if [ -n "$output_file" ]; then
        {
            echo "# Guard Results: $guard_name"
            echo "# Date: $(date -Iseconds)"
            echo "# Mode: $MODE"
            echo ""
            echo "- PASS: $GUARD_PASSED"
            echo "- WARN: $GUARD_WARNED"
            echo "- FAIL: $GUARD_FAILED"
            echo "- SKIP: $GUARD_SKIPPED"
            echo ""
        } >> "$output_file"
    fi

    if [ "$GUARD_FAILED" -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Reset guard counters
reset_guard_counters() {
    GUARD_PASSED=0
    GUARD_WARNED=0
    GUARD_FAILED=0
    GUARD_SKIPPED=0
}
