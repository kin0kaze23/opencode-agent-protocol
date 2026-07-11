#!/usr/bin/env bash
# reviewer-calibration.sh — v4.49 Reviewer Calibration Conformance Tests
#
# Tests for reviewer findings schema, calibration analyzer, disagreement
# tracker, policy recommendations, and safety constraints.
#
# Usage: bash .opencode/conformance/tests/reviewer-calibration.sh

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

reset_counters

echo "=== v4.49 Reviewer Calibration Conformance Tests ==="
echo ""

FINDINGS="$ROOT_DIR/.opencode/metrics/reviewer-calibration/reviewer-findings.jsonl"
DISAGREEMENTS="$ROOT_DIR/.opencode/metrics/reviewer-calibration/disagreements.jsonl"

# ─── RC-001: findings file exists ─────────────────────────────────────
test_start "RC-001" "findings file exists"
assert_file_exists "$FINDINGS" "Reviewer findings file exists"

# ─── RC-002: findings are valid JSONL ──────────────────────────────────
test_start "RC-002" "findings are valid JSONL"
FINDINGS_VALID=true
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  if ! echo "$line" | jq empty 2>/dev/null; then
    FINDINGS_VALID=false
    break
  fi
done < "$FINDINGS"
if [[ "$FINDINGS_VALID" == true ]]; then
  echo -e "  ${GREEN}✓${NC} All findings are valid JSON"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Invalid JSON found in findings"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── RC-003: findings have required fields ─────────────────────────────
test_start "RC-003" "findings have required fields"
REQUIRED_FIELDS=("finding_id" "task_id" "task_type" "risk_lane" "finding_severity" "finding_category" "outcome")
ALL_FIELDS_PRESENT=true
for field in "${REQUIRED_FIELDS[@]}"; do
  if ! grep -q "\"$field\"" "$FINDINGS" 2>/dev/null; then
    echo -e "  ${RED}✗${NC} Field '$field' missing from findings"
    ALL_FIELDS_PRESENT=false
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
done
if [[ "$ALL_FIELDS_PRESENT" == true ]]; then
  echo -e "  ${GREEN}✓${NC} All required fields present"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# ─── RC-004: no protected-repo in findings ──────────────────────────────────
test_start "RC-004" "no protected-repo in findings"
if grep -qi "baby" "$FINDINGS" 2>/dev/null; then
  echo -e "  ${RED}✗${NC} protected-repo found in findings"
  TESTS_FAILED=$((TESTS_FAILED + 1))
else
  echo -e "  ${GREEN}✓${NC} No protected-repo in findings"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# ─── RC-005: analyzer script exists ────────────────────────────────────
test_start "RC-005" "analyzer script exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/analyze-reviewer-calibration.sh" "Analyzer script exists"

# ─── RC-006: calibration report JSON exists ────────────────────────────
test_start "RC-006" "calibration report JSON exists"
assert_file_exists "$ROOT_DIR/reports/reviewer-calibration.json" "Calibration JSON exists"

# ─── RC-007: calibration report markdown exists ─────────────────────────
test_start "RC-007" "calibration report markdown exists"
assert_file_exists "$ROOT_DIR/reports/reviewer-calibration.md" "Calibration markdown exists"

# ─── RC-008: report has true positive rate ─────────────────────────────
test_start "RC-008" "report has true positive rate"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "true_positive_rate" "Report has true_positive_rate"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.md" "True positive rate" "Markdown has TP rate"

# ─── RC-009: report has false positive rate ─────────────────────────────
test_start "RC-009" "report has false positive rate"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "false_positive_rate" "Report has false_positive_rate"

# ─── RC-010: report has by_severity ────────────────────────────────────
test_start "RC-010" "report has by_severity"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "by_severity" "Report has by_severity"

# ─── RC-011: report has by_category ────────────────────────────────────
test_start "RC-011" "report has by_category"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "by_category" "Report has by_category"

# ─── RC-012: report has by_task_type ───────────────────────────────────
test_start "RC-012" "report has by_task_type"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "by_task_type" "Report has by_task_type"

# ─── RC-013: report has by_risk_lane ───────────────────────────────────
test_start "RC-013" "report has by_risk_lane"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "by_risk_lane" "Report has by_risk_lane"

# ─── RC-014: report has high_signal_categories ─────────────────────────
test_start "RC-014" "report has high_signal_categories"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "high_signal_categories" "Report has high_signal_categories"

# ─── RC-015: report has noisy_categories ───────────────────────────────
test_start "RC-015" "report has noisy_categories"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "noisy_categories" "Report has noisy_categories"

# ─── RC-016: disagreement tracker exists ───────────────────────────────
test_start "RC-016" "disagreement tracker exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/record-reviewer-disagreement.sh" "Disagreement tracker exists"

# ─── RC-017: disagreements file exists ─────────────────────────────────
test_start "RC-017" "disagreements file exists"
assert_file_exists "$DISAGREEMENTS" "Disagreements file exists"

# ─── RC-018: disagreements are valid JSONL ──────────────────────────────
test_start "RC-018" "disagreements are valid JSONL"
DISAGREE_VALID=true
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  if ! echo "$line" | jq empty 2>/dev/null; then
    DISAGREE_VALID=false
    break
  fi
done < "$DISAGREEMENTS"
if [[ "$DISAGREE_VALID" == true ]]; then
  echo -e "  ${GREEN}✓${NC} All disagreements are valid JSON"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Invalid JSON found in disagreements"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── RC-019: policy recommendation generator exists ────────────────────
test_start "RC-019" "policy recommendation generator exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/generate-reviewer-policy-recommendations.sh" "Policy generator exists"

# ─── RC-020: policy recommendations JSON exists ────────────────────────
test_start "RC-020" "policy recommendations JSON exists"
assert_file_exists "$ROOT_DIR/reports/reviewer-policy-recommendations.json" "Policy JSON exists"

# ─── RC-021: policy recommendations markdown exists ────────────────────
test_start "RC-021" "policy recommendations markdown exists"
assert_file_exists "$ROOT_DIR/reports/reviewer-policy-recommendations.md" "Policy markdown exists"

# ─── RC-022: recommended YAML policy exists ────────────────────────────
test_start "RC-022" "recommended YAML policy exists"
assert_file_exists "$ROOT_DIR/.opencode/config/reviewer-policy.recommended.yaml" "YAML policy exists"

# ─── RC-023: policy is advisory only ──────────────────────────────────
test_start "RC-023" "policy is advisory only"
assert_file_contains "$ROOT_DIR/reports/reviewer-policy-recommendations.json" "advisory_only" "Policy is advisory_only"
assert_file_contains "$ROOT_DIR/reports/reviewer-policy-recommendations.json" "\"auto_applied\": false" "Policy is not auto-applied"

# ─── RC-024: HIGH-RISK remains required ────────────────────────────────
test_start "RC-024" "HIGH-RISK remains required"
assert_file_contains "$ROOT_DIR/reports/reviewer-policy-recommendations.json" "high_risk_remains_required" "Guardrail: HIGH-RISK always required"
HIGHRISK_SETTING=$(jq -r '.recommendations[] | select(.risk_lane == "HIGH-RISK") | .recommended_reviewer_setting' "$ROOT_DIR/reports/reviewer-policy-recommendations.json" 2>/dev/null)
assert_equals "required" "$HIGHRISK_SETTING" "HIGH-RISK reviewer setting is required"

# ─── RC-025: policy has guardrails ─────────────────────────────────────
test_start "RC-025" "policy has guardrails"
assert_file_contains "$ROOT_DIR/reports/reviewer-policy-recommendations.json" "guardrails" "Policy has guardrails"
assert_file_contains "$ROOT_DIR/reports/reviewer-policy-recommendations.json" "protected-repo_excluded" "Guardrails include protected-repo exclusion"

# ─── RC-026: policy has category insights ──────────────────────────────
test_start "RC-026" "policy has category insights"
assert_file_contains "$ROOT_DIR/reports/reviewer-policy-recommendations.json" "category_insights" "Policy has category_insights"

# ─── RC-027: analyzer runs without error ───────────────────────────────
test_start "RC-027" "analyzer runs without error"
ANALYZE_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/analyze-reviewer-calibration.sh" 2>&1)
ANALYZE_EXIT=$?
if [[ $ANALYZE_EXIT -eq 0 ]]; then
  echo -e "  ${GREEN}✓${NC} Analyzer runs successfully (exit 0)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Analyzer failed (exit $ANALYZE_EXIT)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── RC-028: policy generator runs without error ───────────────────────
test_start "RC-028" "policy generator runs without error"
POLICY_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/generate-reviewer-policy-recommendations.sh" 2>&1)
POLICY_EXIT=$?
if [[ $POLICY_EXIT -eq 0 ]]; then
  echo -e "  ${GREEN}✓${NC} Policy generator runs successfully (exit 0)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Policy generator failed (exit $POLICY_EXIT)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── RC-029: YAML policy is advisory ───────────────────────────────────
test_start "RC-029" "YAML policy is advisory"
assert_file_contains "$ROOT_DIR/.opencode/config/reviewer-policy.recommended.yaml" "advisory: true" "YAML policy is advisory"
assert_file_contains "$ROOT_DIR/.opencode/config/reviewer-policy.recommended.yaml" "auto_applied: false" "YAML policy is not auto-applied"

# ─── RC-030: markdown has recommendations section ──────────────────────
test_start "RC-030" "markdown has recommendations section"
assert_file_contains "$ROOT_DIR/reports/reviewer-policy-recommendations.md" "Recommendations by Task Type" "Markdown has recommendations section"

# ─── RC-031: markdown has category insights ────────────────────────────
test_start "RC-031" "markdown has category insights"
assert_file_contains "$ROOT_DIR/reports/reviewer-policy-recommendations.md" "Category Insights" "Markdown has category insights"

# ─── RC-032: disagreement tracker --list works ──────────────────────────
test_start "RC-032" "disagreement tracker --list works"
LIST_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/record-reviewer-disagreement.sh" --list 2>&1)
assert_output_contains "$LIST_OUTPUT" "Disagreements" "List shows disagreements header"

# ─── RC-033: findings have outcome field ────────────────────────────────
test_start "RC-033" "findings have outcome field"
assert_file_contains "$FINDINGS" "true_positive" "Findings include true_positive outcome"
assert_file_contains "$FINDINGS" "false_positive" "Findings include false_positive outcome"

# ─── RC-034: findings have severity levels ──────────────────────────────
test_start "RC-034" "findings have severity levels"
assert_file_contains "$FINDINGS" "blocker" "Findings include blocker severity"
assert_file_contains "$FINDINGS" "high" "Findings include high severity"
assert_file_contains "$FINDINGS" "medium" "Findings include medium severity"
assert_file_contains "$FINDINGS" "low" "Findings include low severity"

# ─── RC-035: findings have finding categories ───────────────────────────
test_start "RC-035" "findings have finding categories"
assert_file_contains "$FINDINGS" "correctness" "Findings include correctness category"
assert_file_contains "$FINDINGS" "security" "Findings include security category"
assert_file_contains "$FINDINGS" "test_gap" "Findings include test_gap category"

# ─── RC-036: findings have evidence_source field ──────────────────────
test_start "RC-036" "findings have evidence_source field"
assert_file_contains "$FINDINGS" "evidence_source" "Findings have evidence_source field"
assert_file_contains "$FINDINGS" "seed" "Findings include seed evidence_source"
assert_file_contains "$FINDINGS" "historical_pr" "Findings include historical_pr evidence_source"

# ─── RC-037: report has seed vs real data separation ──────────────────
test_start "RC-037" "report has seed vs real data separation"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "seed_data" "Report has seed_data section"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "real_data" "Report has real_data section"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.md" "Seed vs Real Data" "Markdown has seed vs real data section"

# ─── RC-038: report has minimum_sample_warning ─────────────────────────
test_start "RC-038" "report has minimum_sample_warning"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "minimum_sample_warning" "Report has minimum_sample_warning"

# ─── RC-039: report has confidence_rationale ───────────────────────────
test_start "RC-039" "report has confidence_rationale"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "confidence_rationale" "Report has confidence_rationale"

# ─── RC-040: report has unique counts ─────────────────────────────────
test_start "RC-040" "report has unique counts"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "unique_pr_count" "Report has unique_pr_count"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "unique_task_count" "Report has unique_task_count"
assert_file_contains "$ROOT_DIR/reports/reviewer-calibration.json" "unique_repo_count" "Report has unique_repo_count"

# ─── RC-041: policy has evidence_sources ──────────────────────────────
test_start "RC-041" "policy has evidence_sources"
assert_file_contains "$ROOT_DIR/reports/reviewer-policy-recommendations.json" "evidence_sources" "Policy has evidence_sources"

# ─── RC-042: policy has seed_only flag ────────────────────────────────
test_start "RC-042" "policy has seed_only flag"
assert_file_contains "$ROOT_DIR/reports/reviewer-policy-recommendations.json" "seed_only" "Policy has seed_only flag"

# ─── RC-043: policy has real_finding_count ─────────────────────────────
test_start "RC-043" "policy has real_finding_count"
assert_file_contains "$ROOT_DIR/reports/reviewer-policy-recommendations.json" "real_finding_count" "Policy has real_finding_count"

# ─── RC-044: policy has minimum_sample_warning ────────────────────────
test_start "RC-044" "policy has minimum_sample_warning"
assert_file_contains "$ROOT_DIR/reports/reviewer-policy-recommendations.json" "minimum_sample_warning" "Policy has minimum_sample_warning"

# ─── RC-045: unresolved outcomes not counted as TP ─────────────────────
test_start "RC-045" "unresolved outcomes not counted as TP"
TP_COUNT=$(jq -r '.summary.true_positives // 0' "$ROOT_DIR/reports/reviewer-calibration.json" 2>/dev/null)
UNRESOLVED_COUNT=$(jq -r '.summary.unresolved // 0' "$ROOT_DIR/reports/reviewer-calibration.json" 2>/dev/null)
TOTAL_COUNT=$(jq -r '.summary.total_findings // 0' "$ROOT_DIR/reports/reviewer-calibration.json" 2>/dev/null)
if [[ $((TP_COUNT + UNRESOLVED_COUNT)) -le $TOTAL_COUNT ]]; then
  echo -e "  ${GREEN}✓${NC} Unresolved ($UNRESOLVED_COUNT) not counted as TP ($TP_COUNT)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Unresolved may be counted as TP"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── RC-046: real PR findings exist ───────────────────────────────────
test_start "RC-046" "real PR findings exist"
REAL_COUNT=$(jq -r '.real_data.count // 0' "$ROOT_DIR/reports/reviewer-calibration.json" 2>/dev/null)
if [[ "$REAL_COUNT" -ge 1 ]]; then
  echo -e "  ${GREEN}✓${NC} Real PR findings: $REAL_COUNT"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} No real PR findings found"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── RC-047: seed-only does not produce high confidence ────────────────
test_start "RC-047" "seed-only does not produce high confidence"
# Check that no recommendation with seed_only=true has confidence=high
# (except HIGH-RISK which is always required)
SEED_ONLY_HIGH=$(jq -r '.recommendations[] | select(.seed_only == true and .risk_lane != "HIGH-RISK") | .confidence' "$ROOT_DIR/reports/reviewer-policy-recommendations.json" 2>/dev/null | grep -c "high" || echo 0)
SEED_ONLY_HIGH=${SEED_ONLY_HIGH//[^0-9]/}
SEED_ONLY_HIGH=${SEED_ONLY_HIGH:-0}
if [[ "$SEED_ONLY_HIGH" -eq 0 ]]; then
  echo -e "  ${GREEN}✓${NC} No seed-only recommendations have high confidence (excluding HIGH-RISK)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} $SEED_ONLY_HIGH seed-only recommendations have high confidence"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── Report ──────────────────────────────────────────────────────────────
echo ""
report_results "$ROOT_DIR/.opencode/conformance/results/reviewer-calibration-results.md"
