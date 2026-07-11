#!/bin/bash
# Elite Ops Tests - Lane, budget, and isolation safeguards

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/elite-ops-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Elite Ops Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

test_start "ELITE-001" "Execution lanes documented"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "## Execution Lanes" "Lane section exists"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "FAST" "FAST lane documented"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "STANDARD" "STANDARD lane documented"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "HIGH-RISK" "HIGH-RISK lane documented"

test_start "ELITE-002" "Risk score documented"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "Risk score" "Risk score in preflight"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "## Lane And Risk Selection" "Rules lane selection section"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Risk score" "Plan writes risk score"

test_start "ELITE-003" "Autonomy budget documented"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "Autonomy budget" "Budget in preflight"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "Bounded Autonomy" "Bounded autonomy section"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Autonomy budget" "Plan writes autonomy budget"

test_start "ELITE-004" "Touch-list expansion protocol documented"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "## Touch-List Expansion Rule" "Rules expansion section"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "TOUCH LIST EXPANSION" "Implement expansion block"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Silent edits outside the touch list are never allowed" "Silent expansion forbidden"

test_start "ELITE-005" "Branch and worktree discipline documented"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "## Branch And Worktree Isolation" "Owner branch isolation section"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "## Branch And Worktree Discipline" "Rules branch discipline section"
assert_file_contains "$ROOT_DIR/.opencode/commands/ship.md" "hotfix/<repo>/<task-slug>" "Hotfix branch rule"

test_start "ELITE-006" "Verification profile documented"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "## Verification Profiles" "Rules verification profiles"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Verification profile" "Plan writes verification profile"
assert_file_contains "$ROOT_DIR/.opencode/commands/gates.md" "Verification profile rule" "Gates honors profile"

test_start "ELITE-007" "Rollback note documented"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Rollback note" "Plan rollback note"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Rollback note" "Implement completion summary rollback note"
assert_file_contains "$ROOT_DIR/.opencode/commands/checkpoint.md" "rollback note" "Checkpoint handoff rollback note"

test_start "ELITE-008" "Multi-repo planning pattern documented"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Cross-repo dependencies" "Plan documents cross-repo section"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "primary repo" "Plan names primary repo"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "more than one repo needs code changes in the same slice" "Plan blocks unapproved multi-repo implementation"

echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
