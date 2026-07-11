#!/bin/bash
# Implementation Readiness Protocol Tests
# Verifies runtime-authority, touch-list, and readiness-gating safeguards

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/implementation-readiness-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Implementation Readiness Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

# ============================================================
# READY-001: runtime authority rule exists in owner protocol
# ============================================================
test_start "READY-001" "Runtime authority rule exists"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "verify the active runtime entrypoint or mount path" "Owner runtime authority rule"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "runtime authority" "Rules mention runtime authority"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "runtime-wiring-audit/SKILL.md" "Plan command activates runtime wiring audit"

# ============================================================
# READY-002: contract touch-list rule exists
# ============================================================
test_start "READY-002" "Contract touch-list rule exists"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "constructors, defaults, migrations, helper builders, adapters, prompts/tests" "Owner contract touch-list rule"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "constructors, defaults, migrations, helper builders/adapters, and runtime consumers" "Rules contract touch-list rule"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "touch list does not explicitly cover constructors, defaults, migrations, helper builders/adapters, and runtime consumers" "Implement command blocks incomplete touch list"

# ============================================================
# READY-003: implementation-ready threshold exists
# ============================================================
test_start "READY-003" "Implementation-ready threshold exists"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "Do not mark a plan or slice" "Owner implementation-ready guard"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Do not label a phase" "Rules implementation-ready guard"
assert_file_contains "$ROOT_DIR/.opencode/commands/review.md" "implementation-readiness-gate/SKILL.md" "Review command uses readiness gate"

# ============================================================
# READY-004: dependent blocker rule exists
# ============================================================
test_start "READY-004" "Dependent blocker rule exists"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "keep the phase in" "Owner dependent blocker rule"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "keep the phase in" "Rules dependent blocker rule"
assert_file_contains "$ROOT_DIR/.opencode/skills/plan-correction-discipline/SKILL.md" "narrow correction pass" "Plan correction discipline guidance"

# ============================================================
# READY-005: helper roster exists as reference (v4.20: moved from startup instructions to reference-only)
# ============================================================
test_start "READY-005" "Helper roster exists as reference document"
assert_file_exists "$ROOT_DIR/.opencode/helper-roster.md" "Helper roster doc"
assert_file_contains "$ROOT_DIR/.opencode/helper-roster.md" "Planner" "Planner listed"
assert_file_contains "$ROOT_DIR/.opencode/helper-roster.md" "Implementer" "Implementer listed"
assert_file_contains "$ROOT_DIR/.opencode/helper-roster.md" "Reviewer" "Reviewer listed"
assert_file_contains "$ROOT_DIR/.opencode/helper-roster.md" "Architect" "Architect listed"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "helper-roster.md" "AGENTS.md references helper-roster as reference"

# ============================================================
# READY-006: new audit skills exist
# ============================================================
test_start "READY-006" "Audit skills exist"
assert_file_exists "$ROOT_DIR/.opencode/skills/runtime-wiring-audit/SKILL.md" "runtime-wiring-audit skill"
assert_file_exists "$ROOT_DIR/.opencode/skills/contract-touchlist-audit/SKILL.md" "contract-touchlist-audit skill"
assert_file_exists "$ROOT_DIR/.opencode/skills/implementation-readiness-gate/SKILL.md" "implementation-readiness-gate skill"
assert_file_exists "$ROOT_DIR/.opencode/skills/plan-correction-discipline/SKILL.md" "plan-correction-discipline skill"
assert_file_contains "$ROOT_DIR/.opencode/brain-config.json" "runtime-wiring-audit/SKILL.md" "runtime skill in config"
assert_file_contains "$ROOT_DIR/.opencode/brain-config.json" "contract-touchlist-audit/SKILL.md" "touch-list skill in config"

# ============================================================
# READY-007: model routing reflects planner + implementer split
# ============================================================
test_start "READY-007" "Model routing reflects planner + implementer split"
assert_file_contains "$ROOT_DIR/.opencode/brain-config.json" "\"planner\"" "Planner role present"
assert_file_contains "$ROOT_DIR/.opencode/brain-config.json" "opencode-go/qwen3.7-plus" "OpenCode Go implementer model present (v1.1-production)"
assert_file_contains "$ROOT_DIR/.opencode/helper-roster.md" "Switch to" "Switch guidance present"
assert_file_contains "$ROOT_DIR/.opencode/helper-roster.md" "plan is explicit" "Switch guidance detail"
assert_file_contains "$ROOT_DIR/.opencode/commands/review.md" "qwen3.7-plus" "Review escalates to qwen3.7-plus (v1.1-production)"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "opencode-go/qwen3.7-plus" "Implement defaults to OpenCode Go qwen3.7-plus (v1.1-production)"

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
