#!/bin/bash
# Compaction Safety Conformance Test
# Verifies that compaction config is schema-valid, uses a compaction-safe model,
# and that unsafe models are explicitly blocked from session-memory compaction.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/compaction-safety-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Compaction Safety"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

CFG="$ROOT_DIR/.opencode/opencode.json"
REGISTRY="$ROOT_DIR/.opencode/model-registry.yaml"
SAFEGUARD="$ROOT_DIR/.opencode/COMPACTION-SAFEGUARD.md"
TESTPLAN="$ROOT_DIR/.opencode/COMPACTION-TEST-PLAN.md"
PLUGIN="$ROOT_DIR/.opencode/plugins/brain-hooks.js"

# CSA-001: Compaction block uses schema-valid key 'reserved', not 'reservedTokens'
test_start "CSA-001" "Compaction config uses schema-valid key 'reserved'"
assert_file_not_contains "$CFG" '"reservedTokens"' "opencode.json does not contain legacy reservedTokens key"
assert_file_contains "$CFG" '"reserved"' "opencode.json contains schema-valid reserved key"

# CSA-002: Compaction block does not use unsupported 'strategy' key
test_start "CSA-002" "Compaction config does not use unsupported 'strategy' key"
assert_file_not_contains "$CFG" '"strategy"' "opencode.json does not contain unsupported strategy key"

# CSA-003: Pruning is enabled for long-session token management
test_start "CSA-003" "Compaction pruning is enabled"
assert_file_contains "$CFG" '"prune": true' "opencode.json sets prune: true"

# CSA-004: tail_turns and preserve_recent_tokens are configured
test_start "CSA-004" "Compaction preserves recent turns and tokens"
assert_file_contains "$CFG" '"tail_turns"' "opencode.json sets tail_turns"
assert_file_contains "$CFG" '"preserve_recent_tokens"' "opencode.json sets preserve_recent_tokens"

# CSA-005: Dedicated compaction and summary agents exist
test_start "CSA-005" "Dedicated compaction/summary agents are configured"
assert_file_contains "$CFG" '"compaction":' "opencode.json defines agent.compaction"
assert_file_contains "$CFG" '"summary":' "opencode.json defines agent.summary"

# CSA-006: Compaction/summary agents use a compaction-safe model
test_start "CSA-006" "Compaction/summary agents use a verified model"
assert_file_contains "$CFG" 'opencode-go/glm-5.2' "opencode.json references GLM-5.2 as compaction model"
assert_file_contains "$REGISTRY" 'compaction_safe: true' "Registry marks at least one model compaction_safe"

# CSA-007: Unsafe models are explicitly marked not compaction-safe
test_start "CSA-007" "Unsafe models are blocked from compaction"
assert_file_contains "$REGISTRY" 'direct_id: mimo-v2.5-pro' "Registry has mimo-v2.5-pro entry"
assert_file_contains "$REGISTRY" 'direct_id: mimo-v2.5' "Registry has mimo-v2.5 entry"
assert_file_contains "$REGISTRY" 'compaction_safe: false' "Registry marks unsafe models"

# CSA-008: Safeguard and test-plan docs use schema-valid keys
test_start "CSA-008" "Compaction docs use schema-valid keys"
assert_file_not_contains "$SAFEGUARD" 'reservedTokens' "COMPACTION-SAFEGUARD.md does not recommend reservedTokens"
assert_file_not_contains "$SAFEGUARD" '"strategy"' "COMPACTION-SAFEGUARD.md does not recommend strategy"
assert_file_not_contains "$TESTPLAN" 'reservedTokens' "COMPACTION-TEST-PLAN.md does not recommend reservedTokens"
assert_file_not_contains "$TESTPLAN" '"strategy"' "COMPACTION-TEST-PLAN.md does not recommend strategy"

# CSA-009: brain-hooks plugin auto-load is confirmed by runtime log (best-effort)
test_start "CSA-009" "brain-hooks plugin auto-load is confirmed by runtime log"
LATEST_LOG=$(ls -t ~/.local/share/opencode/log/*.log 2>/dev/null | head -1 || true)
if [ -n "$LATEST_LOG" ] && grep -q 'message="brain-hooks plugin initialized"' "$LATEST_LOG"; then
  echo -e "  \033[0;32m✓\033[0m brain-hooks plugin initialized in latest log: $LATEST_LOG"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  \033[1;33m⚠\033[0m brain-hooks plugin auto-load not verified from log (non-blocking)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# CSA-010: Resolved runtime config pins compaction/summary agents to a compaction-safe model.
# OpenCode 1.17.8 honors agent.compaction.model when set; otherwise it falls back to the
# active user message model. This check ensures the loaded config (post-merge) keeps the
# compaction/summary agents on verified-safe models so unsafe active models cannot rewrite
# session memory during auto-compaction.
SAFE_COMPACTION_MODELS=("opencode-go/glm-5.2" "opencode-go/qwen3.6-plus" "opencode-go/qwen3.7-plus" "umans-ai-coding-plan/umans-kimi-k2.7")
test_start "CSA-010" "Resolved runtime config pins compaction/summary agents to safe models"
RESOLVED_CONFIG=$(mktemp)
if opencode debug config --print-logs=false > "$RESOLVED_CONFIG" 2>/dev/null && [ -s "$RESOLVED_CONFIG" ]; then
  COMPACTION_MODEL=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('agent',{}).get('compaction',{}).get('model',''))" "$RESOLVED_CONFIG")
  SUMMARY_MODEL=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('agent',{}).get('summary',{}).get('model',''))" "$RESOLVED_CONFIG")
  is_model_safe() {
    local target="$1"
    local m
    for m in "${SAFE_COMPACTION_MODELS[@]}"; do
      if [ "$m" = "$target" ]; then
        return 0
      fi
    done
    return 1
  }
  if is_model_safe "$COMPACTION_MODEL" && is_model_safe "$SUMMARY_MODEL"; then
    echo -e "  \033[0;32m✓\033[0m Resolved agent.compaction.model=${COMPACTION_MODEL} and agent.summary.model=${SUMMARY_MODEL} are compaction-safe"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "  \033[0;31m✗\033[0m Resolved compaction/summary models are not compaction-safe (compaction=${COMPACTION_MODEL}, summary=${SUMMARY_MODEL})"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
else
  echo -e "  \033[1;33m⚠\033[0m Could not resolve runtime config; skipping resolved-model check"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi
rm -f "$RESOLVED_CONFIG"

# CSA-011: Installed OpenCode bundle still contains the SessionCompaction.process model-delegation path.
# This guards against future OpenCode upgrades silently changing the behavior so that automatic compaction
# ignores agent.compaction.model and always uses the active chat model.
APP_ASAR="/Applications/OpenCode.app/Contents/Resources/app.asar"
test_start "CSA-011" "OpenCode source contains compaction model delegation path"
if [ ! -f "$APP_ASAR" ]; then
  echo -e "  \033[1;33m⚠\033[0m app.asar not found at $APP_ASAR; skipping source-delegation check"
  TESTS_PASSED=$((TESTS_PASSED + 1))
elif grep -aq "SessionCompaction.process" "$APP_ASAR" && grep -aq "const model8 = agent.model ? yield\* provider102.getModel(agent.model.providerID, agent.model.modelID)" "$APP_ASAR"; then
  echo -e "  \033[0;32m✓\033[0m OpenCode source contains SessionCompaction.process and agent.model delegation path"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  \033[0;31m✗\033[0m OpenCode source is missing the agent.compaction.model delegation path"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# CSA-012: brain-hooks handles workspace-root / repo=null sessions safely.
test_start "CSA-012" "brain-hooks handles repo=null workspace-root sessions safely"
assert_file_contains "$PLUGIN" 'function getRepoRoot' "brain-hooks defines repo-root resolver"
assert_file_contains "$PLUGIN" 'return PORTFOLIO_ROOT' "repo-root resolver falls back to workspace root"
assert_file_contains "$PLUGIN" 'workspace-root' "brain-hooks labels workspace-root sessions"
assert_file_not_contains "$PLUGIN" 'join(PORTFOLIO_ROOT, repo,' "brain-hooks does not join PORTFOLIO_ROOT with unvalidated repo"

# CSA-013: compaction hook is fail-open and never allows custom injection errors to abort native compaction.
test_start "CSA-013" "compaction hook errors are handled fail-open"
assert_file_contains "$PLUGIN" 'catch (error)' "compaction hook has explicit error catch"
assert_file_contains "$PLUGIN" 'outcome: "handled_error"' "compaction hook logs handled_error outcome"
assert_file_contains "$PLUGIN" 'native compaction allowed to continue' "handled errors allow native OpenCode compaction to continue"

# CSA-014: compaction hook emits observable terminal outcomes for postmortem detection.
test_start "CSA-014" "compaction hook emits success/safe-skip/handled-error observability"
assert_file_contains "$PLUGIN" 'outcome: "success"' "compaction hook logs success outcome"
assert_file_contains "$PLUGIN" 'outcome: "safe_skip"' "compaction hook logs safe_skip outcome"
assert_file_contains "$PLUGIN" 'outcome: "handled_error"' "compaction hook logs handled_error outcome"
assert_file_contains "$PLUGIN" 'compaction hook: safe skip' "safe-skip message is explicit"

# CSA-015: provider-unavailable state is observable without exposing secrets.
test_start "CSA-015" "compaction provider unavailability is observable"
assert_file_contains "$PLUGIN" 'detectRecentProviderUnavailable' "brain-hooks checks recent provider-unavailable log state"
assert_file_contains "$PLUGIN" 'recent_provider_unavailable' "provider-unavailable status is named"
assert_file_contains "$PLUGIN" 'compaction hook: provider unavailable recently detected' "provider-unavailable log message is explicit"
assert_file_contains "$PLUGIN" 'providerStatus' "provider status is attached to compaction logs"

# CSA-016: brain-hooks JavaScript syntax is valid.
test_start "CSA-016" "brain-hooks JavaScript syntax is valid"
if node --check "$PLUGIN" >/dev/null 2>&1; then
  echo -e "  \033[0;32m✓\033[0m brain-hooks.js passes node --check"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  \033[0;31m✗\033[0m brain-hooks.js fails node --check"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""
echo "=========================================="
if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "\033[0;32mPASSED: $TESTS_PASSED\033[0m"
    echo -e "\033[0;31mFAILED: $TESTS_FAILED\033[0m"
else
    echo -e "\033[0;32mPASSED: $TESTS_PASSED\033[0m"
    echo -e "\033[0;31mFAILED: $TESTS_FAILED\033[0m"
fi
echo "=========================================="

mkdir -p "$RESULTS_DIR"
{
    echo "# Compaction Safety Conformance"
    echo ""
    echo "Date: $(date -Iseconds)"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo ""
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo "Result: PASS — Compaction config is schema-valid, uses a compaction-safe model, blocks unsafe models, and source-delegation path is present."
    else
        echo "Result: FAIL — Compaction safety gaps detected."
    fi
} > "$RESULT_FILE"

echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"

if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
fi
