#!/bin/bash
# Discipline Ops Tests - Rollback structure, compaction anchors, UX batching, and lifecycle policy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/discipline-ops-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Discipline Ops Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

AGENTS="$ROOT_DIR/.opencode/AGENTS.md"
RULES="$ROOT_DIR/.opencode/rules.md"
PLAN="$ROOT_DIR/.opencode/commands/plan-feature.md"
IMPLEMENT="$ROOT_DIR/.opencode/commands/implement.md"
SHIP="$ROOT_DIR/.opencode/commands/ship.md"
CHECKPOINT="$ROOT_DIR/.opencode/commands/checkpoint.md"
BRAIN_CONFIG="$ROOT_DIR/.opencode/brain-config.json"
HOOKS="$ROOT_DIR/.opencode/plugins/brain-hooks.js"

test_start "DISC-001" "Structured rollback recipes are required end to end"
assert_file_contains "$RULES" "## Rollback Discipline" "Rules define rollback discipline"
assert_file_contains "$RULES" "Type" "Rules require rollback type"
assert_file_contains "$RULES" "Preconditions" "Rules require rollback preconditions"
assert_file_contains "$PLAN" "Rollback note (structured recipe)" "Plan requires structured rollback note"
assert_file_contains "$IMPLEMENT" "If the rollback note is not structured" "Implement validates structured rollback note"
assert_file_contains "$SHIP" "structured rollback note" "Ship requires structured rollback note"

test_start "DISC-002" "Branch and worktree lifecycle is explicit"
assert_file_contains "$RULES" "## Branch And Worktree Lifecycle" "Rules define lifecycle section"
assert_file_contains "$RULES" "created" "Lifecycle includes created state"
assert_file_contains "$RULES" "blocked" "Lifecycle includes blocked state"
assert_file_contains "$RULES" "roughly 14 days" "Lifecycle includes stale review threshold"
assert_file_contains "$CHECKPOINT" "Reviews branch/worktree lifecycle when relevant" "Checkpoint reviews lifecycle"
assert_file_contains "$BRAIN_CONFIG" "\"branch_worktree_lifecycle\"" "brain-config defines lifecycle metadata"

test_start "DISC-003" "Compaction anchors are injected and continuity policy exists"
assert_file_contains "$RULES" "## Compaction Continuity" "Rules define compaction continuity"
assert_file_contains "$RULES" "touch-list short summary or digest" "Rules require touch-list anchor"
assert_file_contains "$HOOKS" "CONTINUITY ANCHORS" "Plugin injects continuity anchors"
assert_file_contains "$HOOKS" "Touch list digest" "Plugin emits touch-list digest"
assert_file_contains "$CHECKPOINT" "compaction anchor set exists" "Checkpoint checks continuity after compaction"
assert_file_contains "$BRAIN_CONFIG" "\"compaction\"" "brain-config defines compaction discipline metadata"
assert_file_contains "$CHECKPOINT" "Continuity: <OK / SUSPECT / UNKNOWN>" "Checkpoint emits continuity confidence"
assert_file_contains "$BRAIN_CONFIG" "\"continuity_statuses\"" "brain-config defines continuity statuses"

test_start "DISC-004" "FAST lane may use an abbreviated preflight"
assert_file_contains "$AGENTS" "### FAST Lane Abbreviated Preflight" "Owner contract documents FAST preflight"
assert_file_contains "$AGENTS" "abbreviated 8-field preflight" "FAST preflight field count documented"
assert_file_contains "$BRAIN_CONFIG" "\"fast_lane_abbreviated_format\"" "brain-config defines FAST preflight metadata"
assert_file_contains "$BRAIN_CONFIG" "\"field_count\": 8" "FAST preflight field count matches"

test_start "DISC-005" "Approval batching is bounded and local-only"
assert_file_contains "$AGENTS" "## Approval Batching" "Owner contract documents approval batching"
assert_file_contains "$AGENTS" "Approved, batch next <N> steps" "Batch approval syntax documented"
assert_file_contains "$PLAN" "Approved, batch next <N> steps" "Plan command exposes batching"
assert_file_contains "$IMPLEMENT" "batched approval phrase" "Implement command accepts batched approval"
assert_file_contains "$BRAIN_CONFIG" "\"approval_batching\"" "brain-config defines batching metadata"
assert_file_contains "$BRAIN_CONFIG" "\"max_steps\": 3" "Batching max step count enforced"

test_start "DISC-006" "Progress visibility is phase-based, not ETA-based"
assert_file_contains "$BRAIN_CONFIG" "\"progress_signals\"" "brain-config defines progress signals"
assert_file_contains "$BRAIN_CONFIG" "\"style\": \"phase-based\"" "Progress is phase-based"
assert_file_contains "$BRAIN_CONFIG" "\"eta_enabled\": false" "ETA remains disabled"
assert_file_contains "$BRAIN_CONFIG" "\"percentages_enabled\": false" "Percent progress remains disabled"

echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
