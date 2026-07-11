#!/bin/bash
# Usage-Aware Autonomy + Model ROI Telemetry Conformance Tests (v4.26)
# Verifies that usage tracking, provider status checks, usage budgets,
# and ROI evidence fields are properly documented and wired in.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Usage-Aware Autonomy (v4.26)"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

TRACK_USAGE="$ROOT_DIR/.opencode/scripts/track-usage.sh"
CHECK_STATUS="$ROOT_DIR/.opencode/scripts/check-provider-status.sh"
TOKEN_BUDGET="$ROOT_DIR/.opencode/config/token-budget.yaml"
SENIOR_REVIEW="$ROOT_DIR/.opencode/scripts/senior-self-review.sh"
CHECKPOINT_CMD="$ROOT_DIR/.opencode/commands/checkpoint.md"
IMPLEMENT_CMD="$ROOT_DIR/.opencode/commands/implement.md"

# --- Section 1: track-usage.sh exists and works ---

test_start "UA-001" "track-usage.sh exists and is executable"
assert_file_exists "$TRACK_USAGE" "track-usage.sh exists"
if [ -x "$TRACK_USAGE" ]; then
  echo -e "  ${GREEN}✓${NC} track-usage.sh is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} track-usage.sh is not executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_start "UA-002" "track-usage.sh produces structured output"
RESULT=$(bash "$TRACK_USAGE" "test-repo" "STANDARD" "umans-coder" "yes" "pass" 2>&1 || true)
assert_output_contains "$RESULT" "USAGE_TRACKING:" "Output has structured header"
assert_output_contains "$RESULT" "repo:" "Output has repo field"
assert_output_contains "$RESULT" "lane:" "Output has lane field"
assert_output_contains "$RESULT" "model_used:" "Output has model_used field"
assert_output_contains "$RESULT" "provider:" "Output has provider field"
assert_output_contains "$RESULT" "reviewer_used:" "Output has reviewer_used field"
assert_output_contains "$RESULT" "premium_model_used:" "Output has premium_model_used field"
assert_output_contains "$RESULT" "approximate_tokens:" "Output has approximate_tokens field"
assert_output_contains "$RESULT" "outcome:" "Output has outcome field"
assert_output_contains "$RESULT" "cheaper_model_would_have_sufficed:" "Output has cheaper_model field"
assert_output_contains "$RESULT" "routing_recommendation_next_time:" "Output has routing recommendation field"

test_start "UA-003" "track-usage.sh detects provider from model name"
RESULT=$(bash "$TRACK_USAGE" "test-repo" "STANDARD" "umans-coder" "no" "pass" 2>&1 || true)
assert_output_contains "$RESULT" "umans-ai-coding-plan" "Umans provider detected"

RESULT=$(bash "$TRACK_USAGE" "test-repo" "HIGH-RISK" "opencode-go/qwen3.7-plus" "yes" "pass" 2>&1 || true)
assert_output_contains "$RESULT" "opencode-go" "OpenCode Go provider detected"

test_start "UA-004" "track-usage.sh detects premium model usage"
RESULT=$(bash "$TRACK_USAGE" "test-repo" "HIGH-RISK" "opencode-go/qwen3.7-plus" "yes" "pass" 2>&1 || true)
assert_output_contains "$RESULT" "premium_model_used: yes" "Premium model detected for qwen3.7-plus"

RESULT=$(bash "$TRACK_USAGE" "test-repo" "FAST" "umans-coder" "no" "pass" 2>&1 || true)
assert_output_contains "$RESULT" "premium_model_used: no" "Capacity model not flagged as premium"

# --- Section 2: check-provider-status.sh exists and works ---

test_start "UA-005" "check-provider-status.sh exists and is executable"
assert_file_exists "$CHECK_STATUS" "check-provider-status.sh exists"
if [ -x "$CHECK_STATUS" ]; then
  echo -e "  ${GREEN}✓${NC} check-provider-status.sh is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} check-provider-status.sh is not executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_start "UA-006" "check-provider-status.sh produces structured output"
RESULT=$(bash "$CHECK_STATUS" 2>&1 || true)
assert_output_contains "$RESULT" "PROVIDER_STATUS:" "Output has structured header"
assert_output_contains "$RESULT" "umans-ai-coding-plan:" "Output has Umans provider section"
assert_output_contains "$RESULT" "opencode-go:" "Output has OpenCode Go provider section"
assert_output_contains "$RESULT" "fallback_recommendation:" "Output has fallback recommendation"
assert_output_contains "$RESULT" "quota_status:" "Output has quota_status field"

test_start "UA-007" "check-provider-status.sh does not make network calls"
# Check that the script doesn't contain curl/wget/nc commands
if grep -qE "curl |wget |nc " "$CHECK_STATUS" 2>/dev/null; then
  echo -e "  ${RED}✗${NC} check-provider-status.sh contains network calls"
  TESTS_FAILED=$((TESTS_FAILED + 1))
else
  echo -e "  ${GREEN}✓${NC} check-provider-status.sh does not make network calls"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# --- Section 3: token-budget.yaml has usage budgets ---

test_start "UA-008" "token-budget.yaml has v4.26 usage budgets"
assert_file_contains "$TOKEN_BUDGET" "v4.26" "token-budget.yaml references v4.26"
assert_file_contains "$TOKEN_BUDGET" "reviewer_required" "Budget has reviewer_required field"
assert_file_contains "$TOKEN_BUDGET" "premium_model_allowed" "Budget has premium_model_allowed field"
assert_file_contains "$TOKEN_BUDGET" "usage_guidance" "Budget has usage_guidance field"

test_start "UA-009" "DIRECT lane has minimal usage budget"
assert_file_contains "$TOKEN_BUDGET" "premium_model_allowed: false" "DIRECT does not allow premium models"

test_start "UA-010" "HIGH-RISK lane allows premium models"
# Check that HIGH-RISK section allows premium models
if grep -A 20 "HIGH-RISK:" "$TOKEN_BUDGET" | grep -q "premium_model_allowed: true"; then
  echo -e "  ${GREEN}✓${NC} HIGH-RISK allows premium models"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} HIGH-RISK does not allow premium models"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_start "UA-011" "token-budget.yaml has usage routing rules"
assert_file_contains "$TOKEN_BUDGET" "usage_routing_rules" "Budget has usage routing rules section"
assert_file_contains "$TOKEN_BUDGET" "capacity_first" "Budget has capacity-first rule"
assert_file_contains "$TOKEN_BUDGET" "premium_escalation_triggers" "Budget has premium escalation triggers"
assert_file_contains "$TOKEN_BUDGET" "reviewer_routing" "Budget has reviewer routing rules"
assert_file_contains "$TOKEN_BUDGET" "quota_preservation" "Budget has quota preservation rules"

# --- Section 4: senior-self-review.sh has usage/ROI fields ---

test_start "UA-012" "senior-self-review.sh has usage/ROI evidence fields"
RESULT=$(bash "$SENIOR_REVIEW" "$ROOT_DIR" ".opencode/AGENTS.md" 2>&1 || true)
assert_output_contains "$RESULT" "usage_tracked:" "Self-review has usage_tracked field"
assert_output_contains "$RESULT" "model_used:" "Self-review has model_used field"
assert_output_contains "$RESULT" "reviewer_used:" "Self-review has reviewer_used field"
assert_output_contains "$RESULT" "reviewer_value:" "Self-review has reviewer_value field"
assert_output_contains "$RESULT" "premium_model_used:" "Self-review has premium_model_used field"
assert_output_contains "$RESULT" "cheaper_model_would_have_sufficed:" "Self-review has cheaper_model field"
assert_output_contains "$RESULT" "quota_or_capacity_issue:" "Self-review has quota_or_capacity_issue field"
assert_output_contains "$RESULT" "routing_recommendation_next_time:" "Self-review has routing recommendation field"

# --- Section 5: checkpoint.md has usage summary ---

test_start "UA-013" "checkpoint.md has usage summary section"
assert_file_contains "$CHECKPOINT_CMD" "Usage summary" "checkpoint.md has usage summary section"
assert_file_contains "$CHECKPOINT_CMD" "Model:" "Usage summary has Model field"
assert_file_contains "$CHECKPOINT_CMD" "Reviewer:" "Usage summary has Reviewer field"
assert_file_contains "$CHECKPOINT_CMD" "Premium model:" "Usage summary has Premium model field"
assert_file_contains "$CHECKPOINT_CMD" "Cheaper model would have sufficed:" "Usage summary has cheaper model field"
assert_file_contains "$CHECKPOINT_CMD" "Routing recommendation" "Usage summary has routing recommendation field"

test_start "UA-014" "checkpoint.md usage summary is for full checkpoint only"
assert_file_contains "$CHECKPOINT_CMD" "STANDARD/HIGH-RISK only" "Usage summary limited to full checkpoint"
assert_file_contains "$CHECKPOINT_CMD" "Do not bloat Lite checkpoint" "Lite checkpoint protected from usage bloat"

# --- Section 6: Safety rules not weakened ---

test_start "UA-015" "Usage budgets do not override safety escalation"
# Check that HIGH-RISK still requires reviewer
if grep -A 20 "HIGH-RISK:" "$TOKEN_BUDGET" | grep -q "reviewer_required: true"; then
  echo -e "  ${GREEN}✓${NC} HIGH-RISK still requires reviewer"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} HIGH-RISK reviewer requirement weakened"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

test_start "UA-016" "DIRECT Lite does not require reviewer"
# Check that DIRECT has reviewer_required: false
if grep -A 15 "DIRECT:" "$TOKEN_BUDGET" | grep -q "reviewer_required: false"; then
  echo -e "  ${GREEN}✓${NC} DIRECT does not require reviewer"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} DIRECT requires reviewer (should not)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# --- Section 7: Prior capabilities preserved ---

test_start "UA-017" "Lite Delegation Mode still exists"
assert_file_contains "$IMPLEMENT_CMD" "Lite Delegation Mode" "Lite Delegation Mode preserved"

test_start "UA-018" "Code intelligence still referenced"
assert_file_contains "$IMPLEMENT_CMD" "search-code-index.sh" "Code index search preserved"

test_start "UA-019" "Test intelligence still referenced"
assert_file_contains "$IMPLEMENT_CMD" "detect-untested.sh" "Test detection preserved"

test_start "UA-020" "Pattern memory still referenced"
assert_file_contains "$IMPLEMENT_CMD" "search-patterns.sh" "Pattern search preserved"

# --- Section 8: All required files are tracked ---

test_start "UA-021" "All v4.26 files are tracked by git"
for f in \
  .opencode/scripts/track-usage.sh \
  .opencode/scripts/check-provider-status.sh \
  .opencode/config/token-budget.yaml \
  .opencode/scripts/senior-self-review.sh \
  .opencode/commands/checkpoint.md \
  .opencode/conformance/tests/usage-aware-autonomy.sh; do
  if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} $f is tracked"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "  ${RED}✗${NC} $f is NOT tracked"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
done

# --- Report ---

echo ""
report_results "$SCRIPT_DIR/../results/usage-aware-autonomy-$(date +%Y%m%d-%H%M%S).md"
