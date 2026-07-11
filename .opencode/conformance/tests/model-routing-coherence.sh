#!/bin/bash
# Model Routing Coherence Tests
# Verifies Release 1 OpenCode Go routing stays aligned across config, metadata, helper specs, registry, prompts, and installed runtime.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/model-routing-coherence-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Model Routing Coherence"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

LOCAL_CFG="$ROOT_DIR/.opencode/opencode.json"
BRAIN_CFG="$ROOT_DIR/.opencode/brain-config.json"
REGISTRY="$ROOT_DIR/.opencode/model-registry.yaml"
HELPER_ROSTER="$ROOT_DIR/.opencode/helper-roster.md"
ORCHESTRATOR_PROMPT="$ROOT_DIR/.opencode/global-runtime/prompts/orchestrator.md"
GLOBAL_CFG="$HOME/.config/opencode/opencode.json"
STALE_ORCHESTRATOR_MODEL='bailian-coding-plan/${ORCHESTRATOR_MODEL:-'
STALE_ORCHESTRATOR_MODEL="${STALE_ORCHESTRATOR_MODEL}orchestrator}"

ACTUALS=$(ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json, re, os
from pathlib import Path

root = Path(os.environ['ROOT_DIR'])
local = json.loads((root / '.opencode/opencode.json').read_text())
brain = json.loads((root / '.opencode/brain-config.json').read_text())
registry_text = (root / '.opencode/model-registry.yaml').read_text()
global_path = Path.home() / '.config' / 'opencode' / 'opencode.json'
global_cfg = json.loads(global_path.read_text()) if global_path.exists() else {}
workspace_cfg = local  # workspace authority is .opencode/opencode.json

def emit(key, value):
    print(f'{key}={value}')

def registry_role(role):
    match = re.search(rf'^\s*{re.escape(role)}:\s*\[([^\]]+)\]', registry_text, re.MULTILINE)
    if not match:
        return ''
    value = match.group(1).split(',')[0].strip()
    # Handle full provider prefixes
    if value.startswith('opencode-go/') or value.startswith('bailian-coding-plan/') or value.startswith('umans-ai-coding-plan/'):
        return value
    # Handle bare model names - assume opencode-go for backward compatibility
    # But check if it's a known Umans model first
    if value in ['umans-coder', 'umans-kimi-k2.7', 'umans-flash', 'umans-glm-5.1', 'umans-glm-5.2']:
        return f'umans-ai-coding-plan/{value}'
    return f'opencode-go/{value}'

def helper_model(name):
    path = root / f'.opencode/agents/{name}.md'
    if not path.exists():
        return ''
    match = re.search(r'^\*\*Model:\*\*\s+([^\s(]+)', path.read_text(), re.MULTILINE)
    return match.group(1) if match else ''

emit('local.default', local.get('model', ''))
emit('local.small', local.get('small_model', ''))
emit('local.fallback_provider_present', str('bailian-coding-plan' not in local.get('provider', {})).lower())

emit('brain.default', brain.get('default_model', ''))
emit('brain.small', brain.get('small_model', ''))
emit('brain.orchestrator_model', brain.get('orchestrator', {}).get('model', ''))
emit('brain.orchestrator_default', brain.get('orchestrator_mode', {}).get('default_model', ''))
emit('brain.fallback', brain.get('orchestrator_mode', {}).get('escalation', {}).get('fallback_during_soak', ''))

emit('brain.planner', brain['subagents']['roster']['core']['planner']['model'])
emit('brain.implementer', brain['subagents']['roster']['core']['implementer']['model'])
emit('brain.reviewer', brain['subagents']['roster']['core']['reviewer']['model'])
emit('brain.explorer', brain['subagents']['roster']['core']['explorer']['model'])
emit('brain.architect', brain['subagents']['roster']['specialized']['architect']['model'])
emit('brain.budget', brain['subagents']['roster']['specialized']['budget']['model'])

for role, registry_name in {
    'orchestrator': 'orchestrator',
    'planner': 'planner',
    'architect': 'architect',
    'implementer': 'implementation',
    'reviewer': 'reviewer',
    'explorer': 'explorer',
    'budget': 'budget',
    'fallback': 'emergency_fallback',
}.items():
    emit(f'registry.{role}', registry_role(registry_name))

for helper in ['planner', 'implementer', 'reviewer', 'explorer', 'architect', 'budget']:
    emit(f'agent_header.{helper}', helper_model(helper))

if global_cfg:
    emit('global.default', global_cfg.get('model', ''))
    emit('global.small', global_cfg.get('small_model', ''))
    for agent in ['orchestrator', 'planner', 'implementer', 'reviewer', 'explorer', 'architect', 'budget']:
        emit(f'global.agent.{agent}', global_cfg.get('agent', {}).get(agent, {}).get('model', ''))

if workspace_cfg:
    emit('workspace.model', workspace_cfg.get('model', ''))
    emit('workspace.small_model', workspace_cfg.get('small_model', ''))
PY
)

value_for() {
  local key="$1"
  printf '%s\n' "$ACTUALS" | awk -F= -v key="$key" '$1 == key {print substr($0, length(key) + 2)}'
}

test_start "MRC-001" "Local and brain-config owner routing authority agree"
assert_equals "opencode-go/qwen3.7-plus" "$(value_for local.default)" "Local OpenCode default model"
assert_equals "opencode-go/deepseek-v4-flash" "$(value_for local.small)" "Local OpenCode small model"
assert_equals "true" "$(value_for local.fallback_provider_present)" "Local OpenCode removed Bailian fallback provider (M3C)"
assert_equals "opencode-go/qwen3.7-plus" "$(value_for brain.default)" "Brain default model"
assert_equals "opencode-go/deepseek-v4-flash" "$(value_for brain.small)" "Brain small model"
assert_equals "umans-ai-coding-plan/umans-glm-5.2" "$(value_for brain.orchestrator_model)" "Brain orchestrator model (v1.5.2: umans-glm-5.2 promoted)"
assert_equals "umans-ai-coding-plan/umans-glm-5.2" "$(value_for brain.orchestrator_default)" "Brain active orchestrator default (v1.5.2: umans-glm-5.2 promoted)"
assert_equals "opencode-go/qwen3.6-plus" "$(value_for brain.fallback)" "Brain fallback model (v1.5: qwen3.6-plus retained)"

test_start "MRC-002" "Brain helper roster models match v1.5 routing"
assert_equals "umans-ai-coding-plan/umans-coder" "$(value_for brain.planner)" "Planner model (v1.5: capacity lane primary)"
assert_equals "opencode-go/qwen3.7-plus" "$(value_for brain.architect)" "Architect model (v1.5: premium reserve)"
assert_equals "umans-ai-coding-plan/umans-coder" "$(value_for brain.implementer)" "Implementer model (v1.5: capacity lane primary)"
assert_equals "umans-ai-coding-plan/umans-glm-5.1" "$(value_for brain.reviewer)" "Reviewer model (v1.5.2: umans-glm-5.1 promoted)"
assert_equals "umans-ai-coding-plan/umans-flash" "$(value_for brain.explorer)" "Explorer model (v1.5.2: umans-flash promoted)"
assert_equals "umans-ai-coding-plan/umans-flash" "$(value_for brain.budget)" "Budget model (v1.5.2: umans-flash promoted)"

test_start "MRC-003" "Model registry role router matches v1.5 routing"
assert_file_contains "$REGISTRY" "opencode_config_model_id: opencode-go/<model-id>" "Registry documents prefixed runtime IDs"
assert_file_contains "$REGISTRY" "direct_api_model_id: <model-id>" "Registry documents bare direct API IDs"
assert_equals "umans-ai-coding-plan/umans-glm-5.2" "$(value_for registry.orchestrator)" "Registry orchestrator route (v1.5.2: umans-glm-5.2 promoted)"
assert_equals "umans-ai-coding-plan/umans-coder" "$(value_for registry.planner)" "Registry planner route (v1.5: capacity lane)"
assert_equals "opencode-go/qwen3.7-plus" "$(value_for registry.architect)" "Registry architect route (v1.5: premium reserve)"
assert_equals "umans-ai-coding-plan/umans-coder" "$(value_for registry.implementer)" "Registry implementer route (v1.5: capacity lane)"
assert_equals "umans-ai-coding-plan/umans-glm-5.1" "$(value_for registry.reviewer)" "Registry reviewer route (v1.5.2: umans-glm-5.1 promoted)"
assert_equals "umans-ai-coding-plan/umans-flash" "$(value_for registry.explorer)" "Registry explorer route (v1.5.2: umans-flash promoted)"
assert_equals "umans-ai-coding-plan/umans-flash" "$(value_for registry.budget)" "Registry budget route (v1.5.2: umans-flash promoted)"
assert_equals "umans-ai-coding-plan/umans-coder" "$(value_for registry.fallback)" "Registry fallback route (v1.5: umans-coder primary emergency fallback)"

test_start "MRC-004" "Helper agent headers match v1.5 routing"
assert_equals "umans-ai-coding-plan/umans-coder" "$(value_for agent_header.planner)" "Planner header model (v1.5: capacity lane)"
assert_equals "opencode-go/qwen3.7-plus" "$(value_for agent_header.architect)" "Architect header model (v1.5: premium reserve)"
assert_equals "umans-ai-coding-plan/umans-coder" "$(value_for agent_header.implementer)" "Implementer header model (v1.5: capacity lane)"
assert_equals "umans-ai-coding-plan/umans-glm-5.1" "$(value_for agent_header.reviewer)" "Reviewer header model (v1.5.2: umans-glm-5.1 promoted)"
assert_equals "umans-ai-coding-plan/umans-flash" "$(value_for agent_header.explorer)" "Explorer header model (v1.5.2: umans-flash promoted)"
assert_equals "umans-ai-coding-plan/umans-flash" "$(value_for agent_header.budget)" "Budget header model (v1.5.2: umans-flash promoted)"

test_start "MRC-005" "Human-facing routing docs and orchestrator prompt match v1.1-production routing"
assert_file_contains "$HELPER_ROSTER" "opencode-go/qwen3.7-plus" "Helper roster mentions qwen3.7-plus canary model"
assert_file_contains "$HELPER_ROSTER" "opencode-go/qwen3.6-plus" "Helper roster mentions qwen3.6-plus fallback model"
assert_file_contains "$HELPER_ROSTER" "opencode-go/glm-5.1" "Helper roster mentions reviewer model"
assert_file_contains "$HELPER_ROSTER" "opencode-go/deepseek-v4-flash" "Helper roster mentions explorer/budget model"
assert_file_contains "$HELPER_ROSTER" "decommissioned" "Helper roster documents bailian as decommissioned (M3C)"
assert_file_contains "$ORCHESTRATOR_PROMPT" 'Default Owner/orchestrator: `umans-ai-coding-plan/umans-glm-5.2`' "Orchestrator prompt owner route (v1.5.2: umans-glm-5.2)"
assert_file_contains "$ORCHESTRATOR_PROMPT" 'Direct bounded implementation helper: `umans-ai-coding-plan/umans-coder`' "Orchestrator prompt implementer route (v1.5.2: umans-coder)"
assert_file_contains "$ORCHESTRATOR_PROMPT" 'Reviewer/judge: `umans-ai-coding-plan/umans-glm-5.1`' "Orchestrator prompt reviewer route (v1.5.2: umans-glm-5.1)"
assert_file_contains "$ORCHESTRATOR_PROMPT" 'Explorer/Budget cheap work: `umans-ai-coding-plan/umans-flash`' "Orchestrator prompt explorer/budget route (v1.5.2: umans-flash)"
assert_file_contains "$ORCHESTRATOR_PROMPT" 'Fallback until cutover rollback is needed: `opencode-go/qwen3.6-plus`' "Orchestrator prompt fallback route (v1.1-production: qwen3.6-plus retained)"

test_start "MRC-006" "C5 Option D: workspace carries canonical model authority; global is thin shell OR workspace mirror"
# v4.28.1b: Skip global config checks in CI (no global config installed)
if [ -f "$GLOBAL_CFG" ]; then
  assert_file_exists "$GLOBAL_CFG" "Installed global OpenCode config exists"
  # Workspace is always the canonical authority
  assert_equals "opencode-go/qwen3.7-plus" "$(value_for workspace.model)" "Workspace carries canonical default model (v1.1-production)"
  assert_equals "opencode-go/deepseek-v4-flash" "$(value_for workspace.small_model)" "Workspace carries canonical small model"
  # Classify global state (re-read to capture current snapshot)
  GLOBAL_FOR_MRC=$(cat "$GLOBAL_CFG" 2>/dev/null) || GLOBAL_FOR_MRC="{}"
  THIN_OK=$(echo "$GLOBAL_FOR_MRC" | python3 -c '
import json, sys
try:
    d = json.loads(sys.stdin.read())
except Exception:
    d = {}
keys = sorted(d.keys())
if len(keys) <= 2 and keys == ["$schema", "plugin"]:
    print("THIN_IDLE")
else:
    print("RUNTIME_MATERIALIZED")
')
  if [ "$THIN_OK" = "THIN_IDLE" ]; then
    # Thin shell: every model/agent field must be empty
    assert_equals "" "$(value_for global.default)" "Global thin shell: no model field (GLOBAL_THIN_IDLE)"
    assert_equals "" "$(value_for global.small)" "Global thin shell: no small_model field (GLOBAL_THIN_IDLE)"
    for agent in orchestrator planner architect implementer reviewer explorer budget; do
      assert_equals "" "$(value_for global.agent.$agent)" "Global thin shell: no $agent agent (GLOBAL_THIN_IDLE)"
    done
    echo -e "  ${GREEN}✓${NC} Global state: GLOBAL_THIN_IDLE — valid C5 Option D"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    # Runtime-materialized: every global model field MUST mirror workspace
    GLOBAL_DEFAULT=$(value_for global.default)
    WORKSPACE_DEFAULT=$(value_for workspace.model)
    if [ -z "$GLOBAL_DEFAULT" ] || [ "$GLOBAL_DEFAULT" = "$WORKSPACE_DEFAULT" ]; then
      echo -e "  ${GREEN}✓${NC} Global default model mirrors workspace: $WORKSPACE_DEFAULT"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "  ${RED}✗${NC} Global default model diverges: expected $WORKSPACE_DEFAULT, got $GLOBAL_DEFAULT"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    GLOBAL_SMALL=$(value_for global.small)
    WORKSPACE_SMALL=$(value_for workspace.small_model)
    if [ -z "$GLOBAL_SMALL" ] || [ "$GLOBAL_SMALL" = "$WORKSPACE_SMALL" ]; then
      echo -e "  ${GREEN}✓${NC} Global small_model mirrors workspace: $WORKSPACE_SMALL"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "  ${RED}✗${NC} Global small_model diverges: expected $WORKSPACE_SMALL, got $GLOBAL_SMALL"
      TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    # Per-agent global model: must match workspace (or be empty)
    for agent in orchestrator planner architect implementer reviewer explorer budget; do
      GLOBAL_AGENT_MODEL=$(value_for global.agent.$agent)
      WORKSPACE_AGENT_MODEL=$(python3 -c "
import json
cfg = json.loads(open('$ROOT_DIR/.opencode/opencode.json').read())
print(cfg.get('agent', {}).get('$agent', {}).get('model', ''))
")
      if [ -z "$GLOBAL_AGENT_MODEL" ] || [ "$GLOBAL_AGENT_MODEL" = "$WORKSPACE_AGENT_MODEL" ]; then
        echo -e "  ${GREEN}✓${NC} Global $agent model mirrors workspace"
        TESTS_PASSED=$((TESTS_PASSED + 1))
      else
        echo -e "  ${RED}✗${NC} Global $agent model diverges: expected $WORKSPACE_AGENT_MODEL, got $GLOBAL_AGENT_MODEL"
        TESTS_FAILED=$((TESTS_FAILED + 1))
      fi
    done
    echo -e "  ${GREEN}✓${NC} Global state: GLOBAL_RUNTIME_MATERIALIZED — valid C5 Option D (mirrors workspace)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  fi
  # Forbidden: global must never contain decommissioned providers
  assert_file_not_contains "$GLOBAL_CFG" "bailian-coding-plan" "Global has no decommissioned bailian-coding-plan"
  assert_file_not_contains "$GLOBAL_CFG" "opencode-gemini-auth@latest" "Global has no decommissioned opencode-gemini-auth@latest"
else
  echo -e "  ${YELLOW}⚠${NC} Global OpenCode config not found — skipping global config checks (CI/local without global config)"
fi

test_start "MRC-007" "No stale legacy orchestrator model string remains in routing surfaces"
assert_file_not_contains "$BRAIN_CFG" "$STALE_ORCHESTRATOR_MODEL" "Brain config stale orchestrator string removed"
assert_file_not_contains "$LOCAL_CFG" "$STALE_ORCHESTRATOR_MODEL" "Local OpenCode config stale orchestrator string absent"
assert_file_not_contains "$HELPER_ROSTER" "$STALE_ORCHESTRATOR_MODEL" "Helper roster stale orchestrator string absent"
assert_file_not_contains "$ORCHESTRATOR_PROMPT" "$STALE_ORCHESTRATOR_MODEL" "Orchestrator prompt stale orchestrator string absent"

echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
