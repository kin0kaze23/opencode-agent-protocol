#!/bin/bash
# Behavior Parity Tests — Phase 1
# Verifies: GitGuard, path-based auto-activation, session-end checkpoint
#
# These tests verify that the protocol CONTRACTS exist and contain the
# required enforcement language. They do NOT test runtime agent behavior
# (that requires Phase 3b+ runtime simulation infrastructure).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/behavior-parity-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Behavior Parity (Phase 1)"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

# ============================================================
# GITGUARD TESTS
# ============================================================

# BG-001: GitGuard command file exists
test_start "BG-001" "GitGuard command file exists"
assert_file_exists "$ROOT_DIR/.opencode/commands/git-guard.md" "GitGuard command"

# BG-002: GitGuard defines blocked operations
test_start "BG-002" "GitGuard defines blocked operations"
assert_file_contains "$ROOT_DIR/.opencode/commands/git-guard.md" "git push --force" "Force push blocked"
assert_file_contains "$ROOT_DIR/.opencode/commands/git-guard.md" "git push -f" "Force push -f blocked"
assert_file_contains "$ROOT_DIR/.opencode/commands/git-guard.md" "git push origin main" "Direct main push blocked"
assert_file_contains "$ROOT_DIR/.opencode/commands/git-guard.md" "git push origin master" "Direct master push blocked"
assert_file_contains "$ROOT_DIR/.opencode/commands/git-guard.md" "git commit --no-verify" "No-verify commit blocked"
assert_file_contains "$ROOT_DIR/.opencode/commands/git-guard.md" "git commit -n" "No-verify -n commit blocked"

# BG-003: GitGuard has denial messages with safer alternatives
test_start "BG-003" "GitGuard denial messages with alternatives"
assert_file_contains "$ROOT_DIR/.opencode/commands/git-guard.md" "BLOCKED:" "Denial message prefix"
assert_file_contains "$ROOT_DIR/.opencode/commands/git-guard.md" "Safer alternatives" "Safer alternatives provided"

# BG-004: GitGuard override protocol exists
test_start "BG-004" "GitGuard override protocol"
assert_file_contains "$ROOT_DIR/.opencode/commands/git-guard.md" "OVERRIDE RECORD" "Override record format"
assert_file_contains "$ROOT_DIR/.opencode/commands/git-guard.md" "Self-approval is NEVER permitted" "No self-override"

# BG-005: Pre-push hook script exists
test_start "BG-005" "Pre-push hook script exists"
assert_file_exists "$ROOT_DIR/.opencode/git-guard/pre-push-hook.sh" "Pre-push hook"

# BG-006: Pre-push hook is executable
test_start "BG-006" "Pre-push hook is executable"
if [ -x "$ROOT_DIR/.opencode/git-guard/pre-push-hook.sh" ]; then
    echo -e "  ${GREEN}✓${NC} Pre-push hook is executable"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} Pre-push hook is NOT executable"
    ((TESTS_FAILED++))
fi

# BG-007: Pre-push hook blocks protected branches
test_start "BG-007" "Pre-push hook blocks protected branches"
assert_file_contains "$ROOT_DIR/.opencode/git-guard/pre-push-hook.sh" "protected_branches=" "Protected branches defined"
assert_file_contains "$ROOT_DIR/.opencode/git-guard/pre-push-hook.sh" "BLOCKED:" "Block message in hook"

# BG-008: GitGuard referenced in rules.md
test_start "BG-008" "GitGuard in rules.md"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "GitGuard Enforcement" "GitGuard section in rules"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "git-guard.md" "GitGuard file reference"

# BG-009: GitGuard referenced in AGENTS.md
test_start "BG-009" "GitGuard in AGENTS.md"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "GitGuard Enforcement" "GitGuard section in AGENTS"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "git-guard.md" "GitGuard file reference in AGENTS"

# BG-010: GitGuard integrated into /implement
test_start "BG-010" "GitGuard in /implement command"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "GitGuard" "GitGuard mentioned in implement"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "git-guard.md" "GitGuard file ref in implement"

# BG-011: GitGuard integrated into /ship
test_start "BG-011" "GitGuard in /ship command"
assert_file_contains "$ROOT_DIR/.opencode/commands/ship.md" "GitGuard" "GitGuard mentioned in ship"
assert_file_contains "$ROOT_DIR/.opencode/commands/ship.md" "git-guard.md" "GitGuard file ref in ship"

# BG-012: Pre-push hook install instructions exist
test_start "BG-012" "Pre-push hook install instructions"
assert_file_contains "$ROOT_DIR/.opencode/commands/git-guard.md" "pre-push-hook.sh" "Hook install reference"
assert_file_contains "$ROOT_DIR/.opencode/commands/git-guard.md" "chmod +x" "Executable permission instruction"

# ============================================================
# PATH-BASED AUTO-ACTIVATION TESTS
# ============================================================

# PA-001: Testing rules file exists
test_start "PA-001" "Testing rules file exists"
assert_file_exists "$ROOT_DIR/.opencode/rules/testing.md" "Testing rules"

# PA-002: UI work rules file exists
test_start "PA-002" "UI work rules file exists"
assert_file_exists "$ROOT_DIR/.opencode/rules/ui-work.md" "UI work rules"

# PA-003: Auto-activation defined in rules.md
test_start "PA-003" "Auto-activation in rules.md"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Path-Based Auto-Activation" "Auto-activation section"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Auto-activated rules:" "Announcement format"

# PA-004: Auto-activation defined in AGENTS.md
test_start "PA-004" "Auto-activation in AGENTS.md"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "Path-Based Auto-Activation" "Auto-activation in AGENTS"

# PA-005: Testing path patterns defined
test_start "PA-005" "Testing path patterns defined"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "*.test.*" "Test file pattern"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "*.spec.*" "Spec file pattern"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "tests/" "Tests directory pattern"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "e2e/" "E2E directory pattern"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "__tests__/" "Jest tests pattern"

# PA-006: UI path patterns defined
test_start "PA-006" "UI path patterns defined"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "*.tsx" "TSX pattern"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "*.css" "CSS pattern"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "components/" "Components pattern"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "pages/" "Pages pattern"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "views/" "Views pattern"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "screens/" "Screens pattern"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "app/" "App pattern"

# PA-007: Auto-activation integrated into /implement
test_start "PA-007" "Auto-activation in /implement command"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Path-based auto-activation" "Auto-activation step"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Auto-activated rules:" "Announcement in implement"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "rules/testing.md" "Testing rules reference"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "rules/ui-work.md" "UI rules reference"

# PA-008: Testing rules contain test quality standards
test_start "PA-008" "Testing rules contain quality standards"
assert_file_contains "$ROOT_DIR/.opencode/rules/testing.md" "One assertion per test" "Single assertion rule"
assert_file_contains "$ROOT_DIR/.opencode/rules/testing.md" "Deterministic Verification" "Deterministic verification"
assert_file_contains "$ROOT_DIR/.opencode/rules/testing.md" "No feature ships without tests" "No-ship-without-tests"

# PA-009: UI rules contain design quality standards
test_start "PA-009" "UI rules contain design standards"
assert_file_contains "$ROOT_DIR/.opencode/rules/ui-work.md" "UI Non-Negotiables" "Non-negotiables section"
assert_file_contains "$ROOT_DIR/.opencode/rules/ui-work.md" "WCAG" "Accessibility mention"
assert_file_contains "$ROOT_DIR/.opencode/rules/ui-work.md" "Mobile-first" "Mobile-first rule"
assert_file_contains "$ROOT_DIR/.opencode/rules/ui-work.md" "Checklist Before Shipping UI" "Shipping checklist"

# PA-010: Anti-pattern includes auto-activation requirement
test_start "PA-010" "Anti-pattern includes auto-activation"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Edit test or UI files without auto-activating" "Auto-activation anti-pattern in rules"

# ============================================================
# SESSION-END CHECKPOINT TESTS
# ============================================================

# SC-001: Session-end checkpoint in rules.md
test_start "SC-001" "Session-end checkpoint in rules.md"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Session-End Checkpoint Enforcement" "Section exists"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "PENDING WORK WARNING" "Warning format defined"

# SC-002: Session-end checkpoint in AGENTS.md
test_start "SC-002" "Session-end checkpoint in AGENTS.md"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "Session-End Checkpoint Enforcement" "Section in AGENTS"

# SC-003: PENDING WORK WARNING format defined
test_start "SC-003" "PENDING WORK WARNING format"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Repo: <repo>" "Repo field"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Task: <current task" "Task field"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Status: <active|blocked>" "Status field"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Lane: <lane" "Lane field"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Blockers:" "Blockers field"

# SC-004: Session-end integrated into /ship
test_start "SC-004" "Session-end in /ship command"
assert_file_contains "$ROOT_DIR/.opencode/commands/ship.md" "PENDING WORK WARNING" "Warning in ship"
assert_file_contains "$ROOT_DIR/.opencode/commands/ship.md" "NOW.md shows active/blocked" "Active/blocked check in ship"

# SC-005: Session-end anti-pattern defined
test_start "SC-005" "Session-end anti-pattern"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "End a session with active/blocked NOW.md state" "Anti-pattern in rules"
assert_file_contains "$ROOT_DIR/.opencode/commands/ship.md" "PENDING WORK WARNING" "Anti-pattern in ship"

# SC-006: /checkpoint command references session-end
test_start "SC-006" "Checkpoint command references session-end"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "active/blocked" "Active/blocked detection"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "PENDING WORK WARNING" "Warning in checkpoint"

# SC-007: Session-end handles missing NOW.md (SE-05 fix)
test_start "SC-007" "Session-end handles missing NOW.md"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "If NOW.md is missing" "Missing NOW.md handling in rules"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "PHASE_STATE.md" "Legacy fallback in rules"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Do NOT assume no pending work" "No-assumption rule in rules"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "If NOW.md is missing" "Missing NOW.md handling in AGENTS"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "If NOW.md is missing" "Missing NOW.md handling in checkpoint"

# ============================================================
# CROSS-CUTTING INTEGRATION TESTS
# ============================================================

# CC-001: All three features referenced in opencode.json instructions
test_start "CC-001" "Protocol files in opencode.json"
assert_file_contains "$ROOT_DIR/.opencode/opencode.json" "git-guard.md" "GitGuard in instructions"

# CC-002: Conformance test suite exists
test_start "CC-002" "Behavior parity conformance test exists"
assert_file_exists "$ROOT_DIR/.opencode/conformance/tests/behavior-parity.sh" "Test file"

# CC-003: README updated with new test category
test_start "CC-003" "README lists behavior-parity tests"
assert_file_contains "$ROOT_DIR/.opencode/conformance/README.md" "behavior-parity" "Test category listed"

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
