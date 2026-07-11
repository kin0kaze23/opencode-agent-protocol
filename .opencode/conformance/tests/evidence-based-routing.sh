#!/usr/bin/env bash
# evidence-based-routing.sh — v4.30 Conformance test for evidence-based routing
#
# Verifies:
# - recommend-routing-adjustments.sh exists and produces output
# - Recommendations cite evidence counts
# - sample-service-specific evidence is not generalized globally
# - DIRECT Lite unchanged
# - HIGH-RISK reviewer remains required
# - STANDARD eval/infra tasks require reviewer
# - Cheaper implementation model allowed only with reviewer and pattern evidence
# - Routing report exists

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

RESULT_FILE="$ROOT_DIR/.opencode/conformance/results/evidence-based-routing-$(date +%Y%m%d-%H%M%S).md"

# ============================================================
# EBR-001: recommend-routing-adjustments.sh exists and is executable
# ============================================================
test_start "EBR-001" "recommend-routing-adjustments.sh exists and is executable"
assert_file_exists "$ROOT_DIR/.opencode/scripts/recommend-routing-adjustments.sh" "script exists"
if [ -x "$ROOT_DIR/.opencode/scripts/recommend-routing-adjustments.sh" ]; then
  echo -e "  ${GREEN}✓${NC} script is executable"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} script is NOT executable"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# EBR-002: Script produces output with evidence counts
# ============================================================
test_start "EBR-002" "script produces output with evidence counts"
OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/recommend-routing-adjustments.sh" 2>/dev/null)
if echo "$OUTPUT" | grep -q "ROUTING_RECOMMENDATIONS:"; then
  echo -e "  ${GREEN}✓${NC} produces ROUTING_RECOMMENDATIONS output"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} does not produce ROUTING_RECOMMENDATIONS output"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "evidence_count"; then
  echo -e "  ${GREEN}✓${NC} recommendations cite evidence counts"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} recommendations do not cite evidence counts"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "confidence:"; then
  echo -e "  ${GREEN}✓${NC} recommendations include confidence level"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} recommendations do not include confidence level"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# EBR-003: sample-service evidence is not generalized globally
# ============================================================
test_start "EBR-003" "sample-service evidence is not generalized globally"
if echo "$OUTPUT" | grep -q "risk_of_overgeneralization"; then
  echo -e "  ${GREEN}✓${NC} includes risk_of_overgeneralization warning"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} missing risk_of_overgeneralization warning"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "applicable_repos"; then
  echo -e "  ${GREEN}✓${NC} tags recommendations with applicable repos"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} does not tag recommendations with applicable repos"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# EBR-004: DIRECT Lite unchanged
# ============================================================
test_start "EBR-004" "DIRECT Lite unchanged"
if echo "$OUTPUT" | grep -q "\[no_change\] DIRECT Lite"; then
  echo -e "  ${GREEN}✓${NC} DIRECT Lite marked as no_change"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} DIRECT Lite not marked as no_change"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# EBR-005: HIGH-RISK reviewer remains required
# ============================================================
test_start "EBR-005" "HIGH-RISK reviewer remains required"
if echo "$OUTPUT" | grep -q "\[no_change\] HIGH-RISK"; then
  echo -e "  ${GREEN}✓${NC} HIGH-RISK marked as no_change"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} HIGH-RISK not marked as no_change"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
# Also verify token-budget.yaml still has HIGH-RISK reviewer required
assert_file_contains "$ROOT_DIR/.opencode/config/token-budget.yaml" "reviewer_required: true" "HIGH-RISK reviewer_required in token-budget"
# Verify the HIGH-RISK section has "always required"
if grep -A15 "HIGH-RISK:" "$ROOT_DIR/.opencode/config/token-budget.yaml" | grep -q "always required"; then
  echo -e "  ${GREEN}✓${NC} HIGH-RISK reviewer condition is 'always required'"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} HIGH-RISK reviewer condition is not 'always required'"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# EBR-006: STANDARD eval/infra tasks require reviewer
# ============================================================
test_start "EBR-006" "STANDARD eval/infra tasks require reviewer"
if echo "$OUTPUT" | grep -q "reviewer_required.*STANDARD"; then
  echo -e "  ${GREEN}✓${NC} reviewer_required recommendation for STANDARD tasks"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} no reviewer_required recommendation for STANDARD tasks"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
# Verify token-budget.yaml has STANDARD reviewer_required
if grep -A10 "STANDARD:" "$ROOT_DIR/.opencode/config/token-budget.yaml" | grep -q "reviewer_required: true"; then
  echo -e "  ${GREEN}✓${NC} STANDARD reviewer_required: true in token-budget"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} STANDARD reviewer_required not found in token-budget"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# EBR-007: Cheaper implementation model allowed only with conditions
# ============================================================
test_start "EBR-007" "cheaper implementation model has conditions"
if echo "$OUTPUT" | grep -q "cheaper_model_ok"; then
  echo -e "  ${GREEN}✓${NC} cheaper_model_ok recommendation present"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} cheaper_model_ok recommendation missing"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "reviewer is still used"; then
  echo -e "  ${GREEN}✓${NC} cheaper model requires reviewer"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} cheaper model does not require reviewer"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "no sensitive paths"; then
  echo -e "  ${GREEN}✓${NC} cheaper model requires no sensitive paths"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} cheaper model does not require no sensitive paths"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# EBR-008: Routing report exists
# ============================================================
test_start "EBR-008" "routing decision log exists"
assert_file_exists "$ROOT_DIR/.opencode/reports/routing/2026-07-routing-recommendations.md" "routing report exists"
assert_file_contains "$ROOT_DIR/.opencode/reports/routing/2026-07-routing-recommendations.md" "Evidence Summary" "report has evidence summary"
assert_file_contains "$ROOT_DIR/.opencode/reports/routing/2026-07-routing-recommendations.md" "Scope Guardrails" "report has scope guardrails"
assert_file_contains "$ROOT_DIR/.opencode/reports/routing/2026-07-routing-recommendations.md" "advisory_only" "report is advisory only"

# ============================================================
# EBR-009: Scope guardrails present in output
# ============================================================
test_start "EBR-009" "scope guardrails present in recommendations"
if echo "$OUTPUT" | grep -q "scope_guardrails"; then
  echo -e "  ${GREEN}✓${NC} scope_guardrails section present"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} scope_guardrails section missing"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$OUTPUT" | grep -q "Do not generalize from sample-service"; then
  echo -e "  ${GREEN}✓${NC} sample-service non-generalization guard present"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} sample-service non-generalization guard missing"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# EBR-010: Scorecard includes reviewer hit rate
# ============================================================
test_start "EBR-010" "scorecard includes reviewer hit rate"
SCORECARD_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/summarize-agent-quality.sh" 2>/dev/null)
if echo "$SCORECARD_OUTPUT" | grep -q "reviewer_hit_rate"; then
  echo -e "  ${GREEN}✓${NC} scorecard includes reviewer_hit_rate"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} scorecard does not include reviewer_hit_rate"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
if echo "$SCORECARD_OUTPUT" | grep -q "evidence_scope"; then
  echo -e "  ${GREEN}✓${NC} scorecard includes evidence_scope"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} scorecard does not include evidence_scope"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"
