#!/bin/bash
# Guardrail Enforcement Tests - Refusal, circuit-breakers, freshness, and telemetry-first policy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/guardrail-enforcement-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Guardrail Enforcement Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

RULES="$ROOT_DIR/.opencode/rules.md"
AGENTS="$ROOT_DIR/.opencode/AGENTS.md"
GATES="$ROOT_DIR/.opencode/commands/gates.md"
POSTMORTEM="$ROOT_DIR/.opencode/commands/postmortem.md"
CHECKPOINT="$ROOT_DIR/.opencode/commands/checkpoint.md"
BRAIN_CONFIG="$ROOT_DIR/.opencode/brain-config.json"

test_start "GRD-001" "Prompt-injection and guardrail refusal are explicit"
assert_file_contains "$RULES" "Guardrail Conflict And Injection Defense" "Rules define guardrail conflict section"
assert_file_contains "$RULES" "Refuse the conflicting instruction explicitly" "Rules require explicit refusal"
assert_file_contains "$RULES" "Cite the governing contract path that blocks it" "Rules require governing contract citation"
assert_file_contains "$AGENTS" "## Guardrail Refusal" "Owner contract includes refusal section"
assert_file_contains "$AGENTS" "cite the governing contract file that blocks it" "Owner contract requires citation"

test_start "GRD-002" "Runtime/policy conflicts fail safe"
assert_file_contains "$RULES" "If runtime config and behavioral policy disagree" "Rules define runtime/policy conflict handling"
assert_file_contains "$RULES" "Fail safe" "Rules require fail-safe conflict response"
assert_file_contains "$BRAIN_CONFIG" "\"conflict_policy\"" "brain-config declares conflict policy"
assert_file_contains "$BRAIN_CONFIG" "fail safe, stop the ambiguous action" "brain-config conflict policy is fail-safe"

test_start "GRD-003" "Repeated-root-cause failures trigger a circuit breaker"
assert_file_contains "$GATES" "root-cause fingerprint" "Gates require root-cause fingerprinting"
assert_file_contains "$GATES" "Trigger the circuit breaker immediately" "Gates define circuit breaker"
assert_file_contains "$GATES" "same root cause recurred after postmortem-guided recovery" "Gates define repeated-root-cause escalation"
assert_file_contains "$POSTMORTEM" "Root-cause fingerprint" "Postmortem output includes fingerprint"

test_start "GRD-004" "Memory freshness review is checkpoint-driven"
assert_file_contains "$CHECKPOINT" "Reviews repo memory quality when relevant" "Checkpoint reviews memory quality"
assert_file_contains "$CHECKPOINT" "Last verified: <ISO-date>" "Checkpoint defines freshness stamp"
assert_file_contains "$CHECKPOINT" "Do not bulk-prune unrelated lessons" "Checkpoint avoids broad churn"
assert_file_contains "$BRAIN_CONFIG" "\"lesson_freshness_policy\"" "brain-config defines lesson freshness policy"
assert_file_contains "$BRAIN_CONFIG" "relevance-driven" "Lesson freshness is relevance-driven"

test_start "GRD-005" "Durable decisions are logged narrowly"
assert_file_contains "$RULES" "projects/<repo>/decisions.md" "Vault allowlist includes decisions log"
assert_file_contains "$CHECKPOINT" "architectural, expensive-to-reverse, or cross-session relevant decision" "Checkpoint narrows decision logging"
assert_file_contains "$CHECKPOINT" "full diary" "Checkpoint forbids diary-style decision logs"
assert_file_contains "$BRAIN_CONFIG" "\"durable_decision\"" "brain-config defines durable decision policy"

test_start "GRD-006" "Telemetry-first resource guardrails stay warning-only"
assert_file_contains "$AGENTS" "## Resource Visibility" "Owner contract documents resource visibility"
assert_file_contains "$AGENTS" "do not fabricate token or cost counts" "Owner contract forbids fabricated telemetry"
assert_file_contains "$BRAIN_CONFIG" "\"resource_guardrails\"" "brain-config defines resource guardrails"
assert_file_contains "$BRAIN_CONFIG" "\"mode\": \"telemetry-first\"" "Token policy is telemetry-first"
assert_file_contains "$BRAIN_CONFIG" "\"hard_caps_enabled\": false" "Hard caps remain disabled"
assert_file_contains "$BRAIN_CONFIG" "\"warning_only\": true" "Cost telemetry is warning-only"
assert_file_contains "$BRAIN_CONFIG" "mtime or digest invalidation" "Context cache requires invalidation before enablement"

echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
