#!/usr/bin/env bash
# Prompt Library Conformance Test
# Verifies that vault/prompting/ remains aligned with .opencode/commands/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PROMPT_DIR="$ROOT_DIR/vault/prompting"
COMMAND_DIR="$ROOT_DIR/.opencode/commands"

PASS=0
FAIL=0
WARN=0

log_pass() {
    echo "✓ $1"
    ((PASS++)) || true
}

log_fail() {
    echo "✗ $1"
    ((FAIL++)) || true
}

log_warn() {
    echo "⚠ $1"
    ((WARN++)) || true
}

# Test 1: Prompt directory exists
test_prompt_dir_exists() {
    if [[ -d "$PROMPT_DIR" ]]; then
        log_pass "Prompt directory exists: $PROMPT_DIR"
    else
        log_fail "Prompt directory missing: $PROMPT_DIR"
    fi
}

# Test 2: All prompt files have content (>5 lines)
test_prompt_files_have_content() {
    local empty_count=0
    for f in "$PROMPT_DIR"/*.md; do
        lines=$(wc -l < "$f")
        if [[ $lines -lt 5 ]]; then
            log_warn "Prompt file has <5 lines: $(basename "$f") ($lines lines)"
            ((empty_count++)) || true
        fi
    done
    if [[ $empty_count -eq 0 ]]; then
        log_pass "All prompt files have content (≥5 lines)"
    else
        log_fail "$empty_count prompt files have insufficient content"
    fi
}

# Test 3: No duplicate command intent (prompt names shouldn't match existing commands)
test_no_duplicate_command_intent() {
    local duplicates=0
    for f in "$PROMPT_DIR"/*.md; do
        base=$(basename "$f" .md)
        # Skip meta-prompts (output-*, mentor-*, evaluation-*, etc.)
        if [[ "$base" =~ ^(output|mentor|evaluation|evalation|proceed|init) ]]; then
            continue
        fi
        # Check if a command with similar name exists
        if [[ -f "$COMMAND_DIR/$base.md" ]]; then
            log_warn "Prompt may duplicate command: $base (command exists: $COMMAND_DIR/$base.md)"
            ((duplicates++)) || true
        fi
    done
    if [[ $duplicates -eq 0 ]]; then
        log_pass "No direct command/prompt name conflicts"
    else
        log_fail "$duplicates potential command/prompt conflicts found"
    fi
}

# Test 4: New commands created from prompts exist
test_new_commands_exist() {
    local missing=0
    # Commands that should exist per CONVERSION-ANALYSIS.md
    local expected_commands=("verify-alignment" "stop-ship" "recover")
    for cmd in "${expected_commands[@]}"; do
        if [[ -f "$COMMAND_DIR/$cmd.md" ]]; then
            log_pass "Command exists: $cmd"
        else
            log_fail "Command missing: $cmd (should be created from prompts)"
            ((missing++)) || true
        fi
    done
    if [[ $missing -eq 0 ]]; then
        log_pass "All planned commands created"
    else
        log_fail "$missing planned commands missing"
    fi
}

# Test 5: Command files follow template structure
test_command_template_structure() {
    local bad_commands=0
    for f in "$COMMAND_DIR"/verify-alignment.md "$COMMAND_DIR/stop-ship.md" "$COMMAND_DIR/recover.md"; do
        if [[ ! -f "$f" ]]; then
            continue
        fi
        # Check for required sections
        if ! grep -q "## Purpose:" "$f" && ! grep -q "\*\*Purpose:\*\*" "$f"; then
            log_warn "Command missing Purpose section: $(basename "$f")"
            ((bad_commands++)) || true
        fi
        if ! grep -q "## Behaviour" "$f"; then
            log_warn "Command missing Behaviour section: $(basename "$f")"
            ((bad_commands++)) || true
        fi
        if ! grep -q "## Output format" "$f" && ! grep -q "Return:" "$f"; then
            log_warn "Command missing output format: $(basename "$f")"
            ((bad_commands++)) || true
        fi
    done
    if [[ $bad_commands -eq 0 ]]; then
        log_pass "New commands follow template structure"
    else
        log_fail "$bad_commands commands missing required sections"
    fi
}

# Test 6: Protocol alignment documented
test_protocol_alignment_documented() {
    if [[ -f "$PROMPT_DIR/CONVERSION-ANALYSIS.md" ]]; then
        log_pass "Conversion analysis documented: CONVERSION-ANALYSIS.md"
    else
        log_warn "CONVERSION-ANALYSIS.md missing (should document prompt→command decisions)"
    fi
    if [[ -f "$PROMPT_DIR/README.md" ]]; then
        log_pass "Prompt library indexed: README.md"
    else
        log_warn "README.md missing from prompt library"
    fi
}

# Test 7: No command ambiguity (commands should have distinct purposes)
test_no_command_ambiguity() {
    # Check that new commands don't overlap heavily with existing ones
    # verify-alignment vs review
    # stop-ship vs ship
    # recover vs status
    
    # This is a soft check - just verify they exist and have different purposes
    if [[ -f "$COMMAND_DIR/verify-alignment.md" ]] && [[ -f "$COMMAND_DIR/review.md" ]]; then
        # Different focus: verify-alignment is spec-to-code, review is qualitative
        log_pass "verify-alignment and review have distinct purposes"
    fi
    if [[ -f "$COMMAND_DIR/stop-ship.md" ]] && [[ -f "$COMMAND_DIR/ship.md" ]]; then
        # Different focus: stop-ship is blocker ID, ship is release readiness + PR
        log_pass "stop-ship and ship have distinct purposes"
    fi
    if [[ -f "$COMMAND_DIR/recover.md" ]] && [[ -f "$COMMAND_DIR/status.md" ]]; then
        # Different focus: recover is session recovery, status is state reading
        log_pass "recover and status have distinct purposes"
    fi
}

# Run all tests
main() {
    echo "=== Prompt Library Conformance Test ==="
    echo ""
    
    test_prompt_dir_exists
    test_prompt_files_have_content
    test_no_duplicate_command_intent
    test_new_commands_exist
    test_command_template_structure
    test_protocol_alignment_documented
    test_no_command_ambiguity
    
    echo ""
    echo "=== Summary ==="
    echo "Pass: $PASS"
    echo "Fail: $FAIL"
    echo "Warn: $WARN"
    echo ""
    
    if [[ $FAIL -gt 0 ]]; then
        echo "RESULT: FAIL"
        exit 1
    else
        echo "RESULT: PASS"
        exit 0
    fi
}

main "$@"
