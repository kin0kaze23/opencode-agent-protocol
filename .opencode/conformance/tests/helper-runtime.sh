#!/bin/bash
# Helper Runtime Behavior Tests
# Tests protocol behavior for Implementer and Reviewer helper integration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/helper-runtime-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Helper Runtime Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

# ============================================================
# HELPER-001: Implementer gate FAIL blocks Owner commit
# ============================================================
test_start "HELPER-001" "Implementer gate FAIL blocks commit"
assert_file_contains "$ROOT_DIR/.opencode/agents/implementer.md" "If any gate is FAIL" "Gate FAIL handling"
assert_file_contains "$ROOT_DIR/.opencode/agents/implementer.md" "must fix" "Must fix requirement"
assert_file_contains "$ROOT_DIR/.opencode/agents/implementer.md" "before proceeding to commit" "Before commit"
assert_file_contains "$ROOT_DIR/.opencode/agents/implementer.md" "Do not commit with failing gates" "Explicit block"

# ============================================================
# HELPER-002: Implementer blockers block Owner
# ============================================================
test_start "HELPER-002" "Implementer blockers block Owner"
assert_file_contains "$ROOT_DIR/.opencode/agents/implementer.md" "If blockers are reported" "Blockers reported"
assert_file_contains "$ROOT_DIR/.opencode/agents/implementer.md" "must resolve blockers" "Must resolve"

# ============================================================
# HELPER-003: Reviewer Critical findings block commit/ship
# ============================================================
test_start "HELPER-003" "Reviewer Critical findings block commit"
assert_file_contains "$ROOT_DIR/.opencode/agents/reviewer.md" "If Critical findings exist" "Critical findings"
assert_file_contains "$ROOT_DIR/.opencode/agents/reviewer.md" "must resolve" "Must resolve"
assert_file_contains "$ROOT_DIR/.opencode/agents/reviewer.md" "before commit or PR creation" "Before commit/ship"
assert_file_contains "$ROOT_DIR/.opencode/agents/reviewer.md" "Do not proceed" "Explicit block"

# ============================================================
# HELPER-004: Reviewer verdict semantics
# ============================================================
test_start "HELPER-004" "Reviewer verdict semantics"
assert_file_contains "$ROOT_DIR/.opencode/agents/reviewer.md" "Requires changes" "Requires changes verdict"
assert_file_contains "$ROOT_DIR/.opencode/agents/reviewer.md" "Approve with minor fixes" "Approve with minor fixes"
assert_file_contains "$ROOT_DIR/.opencode/agents/reviewer.md" "Approve" "Approve verdict"

# ============================================================
# HELPER-005: Owner retains final authority
# ============================================================
test_start "HELPER-005" "Owner retains final authority"
assert_file_contains "$ROOT_DIR/.opencode/agents/implementer.md" "Owner retains final authority" "Implementer authority"
assert_file_contains "$ROOT_DIR/.opencode/agents/reviewer.md" "Owner retains final authority" "Reviewer authority"
assert_file_contains "$ROOT_DIR/.opencode/agents/implementer.md" "advisory" "Advisory output"
assert_file_contains "$ROOT_DIR/.opencode/agents/reviewer.md" "advisory" "Advisory output"

# ============================================================
# HELPER-006: Helper output reflected in Owner summary
# ============================================================
test_start "HELPER-006" "Helper output reflected in Owner decision"
assert_file_contains "$ROOT_DIR/.opencode/agents/implementer.md" "incorporates" "Incorporates diff"
assert_file_contains "$ROOT_DIR/.opencode/agents/implementer.md" "final commit" "Final commit"

# ============================================================
# HELPER-007: Reviewer requirement trigger (4+ files)
# ============================================================
test_start "HELPER-007" "Reviewer trigger: 4+ files"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "4+ files" "4+ files trigger"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Spawn Reviewer" "Spawn Reviewer"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "non-optional" "Non-optional"

# ============================================================
# HELPER-008: Reviewer trigger: sensitive paths
# ============================================================
test_start "HELPER-008" "Reviewer trigger: sensitive paths"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "auth" "Auth paths"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "payment" "Payment paths"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "schema" "Schema paths"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "security" "Security paths"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "crypto" "Crypto paths"

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
