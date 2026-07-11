#!/bin/bash
# Lite Delegation Mode Conformance Tests (v4.20)
# Verifies that Lite Delegation Mode is properly documented and that
# full controls remain intact for STANDARD/HIGH-RISK lanes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Lite Delegation Mode (v4.20)"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

AGENTS_MD="$ROOT_DIR/.opencode/AGENTS.md"
RULES_MD="$ROOT_DIR/.opencode/rules.md"
IMPLEMENT_CMD="$ROOT_DIR/.opencode/commands/implement.md"
CHECKPOINT_CMD="$ROOT_DIR/.opencode/commands/checkpoint.md"
OPENCODE_JSON="$ROOT_DIR/.opencode/opencode.json"
PROJECT_MEMORY_TEMPLATE="$ROOT_DIR/.opencode/templates/PROJECT_MEMORY.md"

# --- Section 1: Lite Delegation Mode exists ---

test_start "LDM-001" "AGENTS.md contains Protocol Kernel section"
assert_file_contains "$AGENTS_MD" "Protocol Kernel (v4.20)" "AGENTS.md has Protocol Kernel section"

test_start "LDM-002" "AGENTS.md contains Lite Delegation Mode section"
assert_file_contains "$AGENTS_MD" "Lite Delegation Mode (v4.20)" "AGENTS.md has Lite Delegation Mode section"

test_start "LDM-003" "AGENTS.md contains DIRECT Lite Path"
assert_file_contains "$AGENTS_MD" "DIRECT Lite Path" "AGENTS.md documents DIRECT lite path"

test_start "LDM-004" "AGENTS.md contains FAST Lite Path"
assert_file_contains "$AGENTS_MD" "FAST Lite Path" "AGENTS.md documents FAST lite path"

test_start "LDM-005" "AGENTS.md contains Lite Mode Does NOT Apply section"
assert_file_contains "$AGENTS_MD" "When Lite Mode Does NOT Apply" "AGENTS.md documents lite mode exclusions"

# --- Section 2: rules.md has lite delegation rules ---

test_start "LDM-006" "rules.md contains Lite Delegation Mode section"
assert_file_contains "$RULES_MD" "Lite Delegation Mode (v4.20)" "rules.md has lite delegation rules"

test_start "LDM-007" "rules.md contains Lite Checkpoint section"
assert_file_contains "$RULES_MD" "Lite Checkpoint (v4.20)" "rules.md has lite checkpoint rules"

test_start "LDM-008" "rules.md contains Startup Instruction Budget"
assert_file_contains "$RULES_MD" "Startup Instruction Budget" "rules.md documents startup budget"

# --- Section 3: implement.md has lite mode short-circuit ---

test_start "LDM-009" "implement.md contains Lite Delegation Mode short-circuit"
assert_file_contains "$IMPLEMENT_CMD" "Lite Delegation Mode (v4.20)" "implement.md has lite mode short-circuit"

test_start "LDM-010" "implement.md lite mode skips steps for DIRECT"
assert_file_contains "$IMPLEMENT_CMD" "Skip steps 3-14" "implement.md skips heavy steps for DIRECT lite"

# --- Section 4: checkpoint.md has lite checkpoint path ---

test_start "LDM-011" "checkpoint.md contains Lite Checkpoint gate"
assert_file_contains "$CHECKPOINT_CMD" "Lite Checkpoint gate (v4.20)" "checkpoint.md has lite checkpoint gate"

test_start "LDM-012" "checkpoint.md documents when to use full checkpoint"
assert_file_contains "$CHECKPOINT_CMD" "When to use full checkpoint instead" "checkpoint.md documents full checkpoint trigger"

# --- Section 5: Startup instructions are slimmed ---

test_start "LDM-013" "opencode.json instructions do not include helper-roster.md"
assert_file_not_contains "$OPENCODE_JSON" "helper-roster.md" "opencode.json no longer loads helper-roster.md at startup"

test_start "LDM-014" "opencode.json instructions include AGENTS.md"
assert_file_contains "$OPENCODE_JSON" ".opencode/AGENTS.md" "opencode.json still loads AGENTS.md"

test_start "LDM-015" "opencode.json instructions include rules.md"
assert_file_contains "$OPENCODE_JSON" ".opencode/rules.md" "opencode.json still loads rules.md"

# --- Section 6: PROJECT_MEMORY.md template exists ---

test_start "LDM-016" "PROJECT_MEMORY.md template exists"
assert_file_exists "$PROJECT_MEMORY_TEMPLATE" "PROJECT_MEMORY.md template file exists"

test_start "LDM-017" "PROJECT_MEMORY.md template has required sections"
assert_file_contains "$PROJECT_MEMORY_TEMPLATE" "Architecture Notes" "template has Architecture Notes section"
assert_file_contains "$PROJECT_MEMORY_TEMPLATE" "Key Decisions" "template has Key Decisions section"
assert_file_contains "$PROJECT_MEMORY_TEMPLATE" "Known Risks" "template has Known Risks section"
assert_file_contains "$PROJECT_MEMORY_TEMPLATE" "Testing Commands" "template has Testing Commands section"
assert_file_contains "$PROJECT_MEMORY_TEMPLATE" "Deployment Notes" "template has Deployment Notes section"

# --- Section 7: Full controls remain for STANDARD/HIGH-RISK ---

test_start "LDM-018" "AGENTS.md still defines STANDARD lane with PLAN.md required"
assert_file_contains "$AGENTS_MD" "STANDARD.*PLAN.md required" "STANDARD lane still requires PLAN.md"

test_start "LDM-019" "AGENTS.md still defines HIGH-RISK lane with PLAN.md + ADR"
assert_file_contains "$AGENTS_MD" "HIGH-RISK.*PLAN.md + ADR" "HIGH-RISK lane still requires PLAN.md + ADR"

test_start "LDM-020" "AGENTS.md still has forced HIGH-RISK triggers"
assert_file_contains "$AGENTS_MD" "Forced HIGH-RISK" "Forced HIGH-RISK triggers preserved"

test_start "LDM-021" "AGENTS.md still has escalation triggers"
assert_file_contains "$AGENTS_MD" "Escalation Triggers" "Escalation triggers preserved"

test_start "LDM-022" "AGENTS.md still references git-guard for mutating operations"
assert_file_contains "$AGENTS_MD" "git-guard" "git-guard reference preserved"

test_start "LDM-023" "rules.md still has rollback discipline for STANDARD/HIGH-RISK"
assert_file_contains "$RULES_MD" "Rollback Discipline" "Rollback discipline preserved"

test_start "LDM-024" "rules.md still has compaction continuity rules"
assert_file_contains "$RULES_MD" "Compaction Continuity" "Compaction continuity preserved"

test_start "LDM-025" "rules.md still has guardrail conflict defense"
assert_file_contains "$RULES_MD" "Guardrail Conflict" "Guardrail conflict defense preserved"

# --- Section 8: Version coherence ---
# v4.27.1: Version checks are now dynamic — read version from brain-config.json
PROTOCOL_VERSION=$(python3 -c "import json; print(json.load(open('$ROOT_DIR/.opencode/brain-config.json'))['version'])" 2>/dev/null || echo "unknown")

test_start "LDM-026" "AGENTS.md contains protocol version"
assert_file_contains "$AGENTS_MD" "v$PROTOCOL_VERSION" "AGENTS.md contains v$PROTOCOL_VERSION"

test_start "LDM-027" "rules.md contains protocol version"
assert_file_contains "$RULES_MD" "v$PROTOCOL_VERSION" "rules.md contains v$PROTOCOL_VERSION"

test_start "LDM-028" "brain-config.json version is valid"
BRAIN_VERSION=$(python3 -c "import json; print(json.load(open('$ROOT_DIR/.opencode/brain-config.json'))['version'])" 2>/dev/null || echo "unknown")
assert_equals "$PROTOCOL_VERSION" "$BRAIN_VERSION" "brain-config.json version is $PROTOCOL_VERSION"

test_start "LDM-029" "AGENTS.md banner matches brain-config version"
assert_file_contains "$AGENTS_MD" "v$PROTOCOL_VERSION" "AGENTS.md banner contains v$PROTOCOL_VERSION"

# --- Section 9: Lite Mode eligibility classifier (v4.20.1) ---

CLASSIFIER="$ROOT_DIR/.opencode/scripts/lite-mode-eligibility.sh"

test_start "LDM-030" "Classifier script exists and is executable"
assert_file_exists "$CLASSIFIER" "lite-mode-eligibility.sh exists"
if [ -x "$CLASSIFIER" ]; then
  echo -e "  ${GREEN}✓${NC} classifier is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} classifier is not executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_start "LDM-031" "Classifier allows low-risk single-file change"
RESULT=$(bash "$CLASSIFIER" "src/components/Button.tsx" 2>&1 || true)
assert_output_contains "$RESULT" "allowed: yes" "DIRECT single-file change is allowed"
assert_output_contains "$RESULT" "detected_lane: DIRECT" "Correctly classified as DIRECT"

test_start "LDM-032" "Classifier allows low-risk 3-file FAST change"
RESULT=$(bash "$CLASSIFIER" "src/components/Button.tsx" "src/components/Input.tsx" "src/utils/helpers.ts" 2>&1 || true)
assert_output_contains "$RESULT" "allowed: yes" "3-file FAST change is allowed"
assert_output_contains "$RESULT" "detected_lane: FAST" "Correctly classified as FAST"

test_start "LDM-033" "Classifier blocks auth path"
RESULT=$(bash "$CLASSIFIER" "src/auth/login.ts" 2>&1 || true)
assert_output_contains "$RESULT" "allowed: no" "Auth path is blocked from Lite Mode"
assert_output_contains "$RESULT" "sensitive:auth" "Auth keyword detected"

test_start "LDM-034" "Classifier blocks payment path"
RESULT=$(bash "$CLASSIFIER" "src/payment/checkout.ts" 2>&1 || true)
assert_output_contains "$RESULT" "allowed: no" "Payment path is blocked from Lite Mode"
assert_output_contains "$RESULT" "sensitive:payment" "Payment keyword detected"

test_start "LDM-035" "Classifier blocks schema/migration path"
RESULT=$(bash "$CLASSIFIER" "prisma/migrations/001_init/migration.sql" 2>&1 || true)
assert_output_contains "$RESULT" "allowed: no" "Migration path is blocked from Lite Mode"
assert_output_contains "$RESULT" "sensitive:migration" "Migration keyword detected"

test_start "LDM-036" "Classifier blocks secrets/.env path"
RESULT=$(bash "$CLASSIFIER" ".env.production" 2>&1 || true)
assert_output_contains "$RESULT" "allowed: no" "Secrets path is blocked from Lite Mode"
assert_output_contains "$RESULT" "sensitive:.env" "Env keyword detected"

test_start "LDM-037" "Classifier blocks crypto path"
RESULT=$(bash "$CLASSIFIER" "src/crypto/encrypt.ts" 2>&1 || true)
assert_output_contains "$RESULT" "allowed: no" "Crypto path is blocked from Lite Mode"
assert_output_contains "$RESULT" "sensitive:crypto" "Crypto keyword detected"

test_start "LDM-038" "Classifier blocks security path"
RESULT=$(bash "$CLASSIFIER" "src/security/guard.ts" 2>&1 || true)
assert_output_contains "$RESULT" "allowed: no" "Security path is blocked from Lite Mode"
assert_output_contains "$RESULT" "sensitive:" "Security keyword detected (any sensitive match)"

test_start "LDM-039" "Classifier blocks package.json changes"
RESULT=$(bash "$CLASSIFIER" "package.json" 2>&1 || true)
assert_output_contains "$RESULT" "allowed: no" "Package.json change is blocked from Lite Mode"
assert_output_contains "$RESULT" "package:package.json" "Package pattern detected"

test_start "LDM-040" "Classifier blocks protocol/config files"
RESULT=$(bash "$CLASSIFIER" ".opencode/opencode.json" 2>&1 || true)
assert_output_contains "$RESULT" "allowed: no" "Protocol config is blocked from Lite Mode"
assert_output_contains "$RESULT" "deploy:opencode.json" "Deploy/config pattern detected"

test_start "LDM-041" "Classifier blocks when file count exceeds FAST threshold"
RESULT=$(bash "$CLASSIFIER" "src/a.ts" "src/b.ts" "src/c.ts" "src/d.ts" "src/e.ts" 2>&1 || true)
assert_output_contains "$RESULT" "allowed: no" "5-file change is blocked from Lite Mode"
assert_output_contains "$RESULT" "detected_lane: STANDARD" "Correctly classified as STANDARD"

test_start "LDM-042" "Classifier escalates auth to HIGH-RISK"
RESULT=$(bash "$CLASSIFIER" "src/auth/session.ts" 2>&1 || true)
assert_output_contains "$RESULT" "required_escalation: HIGH-RISK" "Auth path escalates to HIGH-RISK"

test_start "LDM-043" "Classifier escalates schema to HIGH-RISK"
RESULT=$(bash "$CLASSIFIER" "prisma/schema.prisma" 2>&1 || true)
assert_output_contains "$RESULT" "required_escalation: HIGH-RISK" "Schema path escalates to HIGH-RISK"

test_start "LDM-044" "Classifier escalates protocol files to HIGH-RISK"
RESULT=$(bash "$CLASSIFIER" ".opencode/brain-config.json" 2>&1 || true)
assert_output_contains "$RESULT" "required_escalation: HIGH-RISK" "Protocol file escalates to HIGH-RISK"

test_start "LDM-045" "Classifier outputs structured format"
RESULT=$(bash "$CLASSIFIER" "src/Button.tsx" 2>&1 || true)
assert_output_contains "$RESULT" "LITE_MODE_ELIGIBILITY:" "Output has structured header"
assert_output_contains "$RESULT" "allowed:" "Output has allowed field"
assert_output_contains "$RESULT" "detected_lane:" "Output has detected_lane field"
assert_output_contains "$RESULT" "file_count:" "Output has file_count field"
assert_output_contains "$RESULT" "required_escalation:" "Output has required_escalation field"

# --- Report ---

echo ""
report_results "$SCRIPT_DIR/../results/lite-delegation-mode-$(date +%Y%m%d-%H%M%S).md"
