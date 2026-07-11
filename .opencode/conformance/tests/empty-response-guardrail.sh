#!/bin/bash
# Empty Response Guardrail Conformance Test
# Verifies that the empty-response guardrail is documented and actionable.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/empty-response-guardrail-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Empty Response Guardrail"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

RULES="$ROOT_DIR/.opencode/rules.md"
BRAIN_CFG="$ROOT_DIR/.opencode/brain-config.json"
HELPER_ROSTER="$ROOT_DIR/.opencode/helper-roster.md"
ORCHESTRATOR_PROMPT="$ROOT_DIR/.opencode/global-runtime/prompts/orchestrator.md"

# ERG-001: Guardrail documented in rules.md
test_start "ERG-001" "Empty-response guardrail documented in rules.md"
assert_file_contains "$RULES" "empty content" "Rules mention empty content detection"
assert_file_contains "$RULES" "Retry once with" "Rules specify retry with qwen3.6-plus"
assert_file_contains "$RULES" "Never allow an empty response" "Rules block empty response as success"
assert_file_contains "$RULES" "blocked from automatic production routing" "Rules block unreliable models"

# ERG-002: Guardrail configured in brain-config.json
test_start "ERG-002" "Empty-response guardrail configured in brain-config.json"
assert_file_contains "$BRAIN_CFG" "empty_response_guardrail" "Brain config has guardrail section"
assert_file_contains "$BRAIN_CFG" "retry_once_with_qwen3.6-plus" "Brain config specifies retry action"
assert_file_contains "$BRAIN_CFG" "Never allow empty response" "Brain config has guardrail rule"

# ERG-003: Blocked models listed in brain-config.json
test_start "ERG-003" "Blocked models listed in brain-config.json"
assert_file_contains "$BRAIN_CFG" "blocked_orchestrators" "Brain config has blocked orchestrators list"
assert_file_contains "$BRAIN_CFG" "deepseek-v4-pro" "Brain config blocks deepseek-v4-pro"
assert_file_contains "$BRAIN_CFG" "mimo-v2.5-pro" "Brain config blocks mimo-v2.5-pro"
assert_file_contains "$BRAIN_CFG" "minimax-m2.7" "Brain config blocks minimax-m2.7"

# ERG-004: Guardrail referenced in helper roster
test_start "ERG-004" "Empty-response evidence documented in helper roster"
assert_file_contains "$HELPER_ROSTER" "empty responses" "Helper roster documents empty response evidence"
assert_file_contains "$HELPER_ROSTER" "blocked from automatic routing" "Helper roster documents blocked models"

# ERG-005: Guardrail referenced in orchestrator prompt
test_start "ERG-005" "Empty-response caveat in orchestrator prompt"
assert_file_contains "$ORCHESTRATOR_PROMPT" "empty responses" "Orchestrator prompt mentions empty response risk"
assert_file_contains "$ORCHESTRATOR_PROMPT" "only model with 0 empty responses" "Orchestrator prompt identifies qwen as reliable"

# ERG-006: Model registry reflects blocked status
test_start "ERG-006" "Model registry reflects blocked status"
assert_file_contains "$ROOT_DIR/.opencode/model-registry.yaml" "blocked_from_auto_promotion" "Registry blocks mimo from auto promotion"
assert_file_contains "$ROOT_DIR/.opencode/model-registry.yaml" "blocked_for_runtime_tool_use" "Registry blocks deepseek from runtime tool use"
assert_file_contains "$ROOT_DIR/.opencode/model-registry.yaml" "blocked_until_retest" "Registry blocks minimax until retest"

# ERG-007: Role router uses capacity-first routing (v1.5)
test_start "ERG-007" "Role router uses capacity-first routing (v1.5)"
assert_file_contains "$ROOT_DIR/.opencode/model-registry.yaml" "orchestrator:.*umans-coder" "Router: orchestrator = umans-coder (v1.5: capacity-first)"
assert_file_contains "$ROOT_DIR/.opencode/model-registry.yaml" "fallback_orchestrator:.*qwen3.7-plus" "Router: fallback includes qwen3.7-plus (premium reserve)"
assert_file_contains "$ROOT_DIR/.opencode/model-registry.yaml" "fast_tasks:.*umans-coder" "Router: fast_tasks = umans-coder (v1.5: capacity-first)"
assert_file_contains "$ROOT_DIR/.opencode/model-registry.yaml" "implementation:.*umans-coder" "Router: implementation = umans-coder (v1.5: capacity-first)"
assert_file_contains "$ROOT_DIR/.opencode/model-registry.yaml" "hard_deep_repo_solver:.*qwen3.6-plus" "Router: hard_solver = qwen3.6-plus (premium reserve)"

# ERG-008: Runtime enforcement script exists
test_start "ERG-008" "Empty-response runtime enforcement script exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/empty-response-guard.sh" "Runtime enforcement script exists"
assert_file_contains "$ROOT_DIR/.opencode/scripts/empty-response-guard.sh" "retry_with_qwen3.6-plus" "Script specifies retry action"
assert_file_contains "$ROOT_DIR/.opencode/scripts/empty-response-guard.sh" "Never allow empty response" "Script documents guardrail rule"

# ERG-009: Plugin validation function exists
test_start "ERG-009" "Empty-response plugin validation function exists"
assert_file_contains "$ROOT_DIR/.opencode/plugins/brain-hooks.js" "validateResponse" "Plugin has validateResponse function"
assert_file_contains "$ROOT_DIR/.opencode/plugins/brain-hooks.js" "isEmptyResponse" "Plugin has isEmptyResponse helper"
assert_file_contains "$ROOT_DIR/.opencode/plugins/brain-hooks.js" "logEmptyResponse" "Plugin has logEmptyResponse function"
assert_file_contains "$ROOT_DIR/.opencode/plugins/brain-hooks.js" "retry_with_qwen3.6-plus" "Plugin specifies retry action"

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
    echo "# Empty Response Guardrail Conformance"
    echo ""
    echo "Date: $(date -Iseconds)"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo ""
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo "Result: PASS — Empty-response guardrail is documented and configured across all authority files."
    else
        echo "Result: FAIL — Guardrail gaps detected."
    fi
} > "$RESULT_FILE"

echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"

if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
fi
