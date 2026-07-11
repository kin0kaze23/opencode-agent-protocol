#!/bin/bash
# Lesson Promotion Tests
# Tests durable protocol support for promoting confirmed orchestrator lessons

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/lesson-promotion-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Lesson Promotion Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

# ============================================================
# LESSON-001: promote-lesson command exists
# ============================================================
test_start "LESSON-001" "/promote-lesson command exists"
assert_file_exists "$ROOT_DIR/.opencode/commands/promote-lesson.md" "promote-lesson command"
assert_file_contains "$ROOT_DIR/.opencode/commands/promote-lesson.md" "Purpose" "Command metadata"

# ============================================================
# LESSON-002: command classifies repo-local vs protocol-wide
# ============================================================
test_start "LESSON-002" "Promotion classification rules documented"
assert_file_contains "$ROOT_DIR/.opencode/commands/promote-lesson.md" "repo-local" "Repo-local classification"
assert_file_contains "$ROOT_DIR/.opencode/commands/promote-lesson.md" "protocol-wide" "Protocol-wide classification"
assert_file_contains "$ROOT_DIR/.opencode/commands/promote-lesson.md" "both" "Both classification"

# ============================================================
# LESSON-003: command writes durable lesson shape
# ============================================================
test_start "LESSON-003" "Durable lesson shape documented"
assert_file_contains "$ROOT_DIR/.opencode/commands/promote-lesson.md" "Mistake pattern" "Mistake pattern"
assert_file_contains "$ROOT_DIR/.opencode/commands/promote-lesson.md" "Evidence" "Evidence"
assert_file_contains "$ROOT_DIR/.opencode/commands/promote-lesson.md" "Fix pattern" "Fix pattern"
assert_file_contains "$ROOT_DIR/.opencode/commands/promote-lesson.md" "Prevention rule" "Prevention rule"

# ============================================================
# LESSON-004: duplicate handling documented
# ============================================================
test_start "LESSON-004" "Duplicate handling documented"
assert_file_contains "$ROOT_DIR/.opencode/commands/promote-lesson.md" "duplicate" "Duplicate search"
assert_file_contains "$ROOT_DIR/.opencode/commands/promote-lesson.md" "append, update, or promote" "Append/update/promote logic"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "avoid duplicate append-only entries" "Duplicate guardrail"

# ============================================================
# LESSON-005: generic promotion rules documented
# ============================================================
test_start "LESSON-005" "Generic promotion rules documented"
assert_file_contains "$ROOT_DIR/.opencode/commands/promote-lesson.md" "most generic rule" "Generic rule preference"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Default to the most generic accurate scope" "Generic scope in rules"

# ============================================================
# LESSON-006: protocol references explicit promotion workflow
# ============================================================
test_start "LESSON-006" "Protocol references explicit promotion workflow"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "/promote-lesson" "Command listed in AGENTS"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "/promote-lesson" "Command referenced in rules"

# ============================================================
# LESSON-007: protocol requires persistence not chat-only memory
# ============================================================
test_start "LESSON-007" "Persistence required"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "Do not claim the orchestrator has \"self-learned\"" "Self-learn guard"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Do not leave a confirmed repeatable mistake as chat-only feedback" "No chat-only feedback"

# ============================================================
# LESSON-008: file growth guardrails documented
# ============================================================
test_start "LESSON-008" "File growth guardrails documented"
assert_file_contains "$ROOT_DIR/.opencode/commands/promote-lesson.md" "file-growth guardrails" "Growth guardrails"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Control growth" "Growth control in rules"

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
