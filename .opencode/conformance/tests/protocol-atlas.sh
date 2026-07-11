#!/usr/bin/env bash
# protocol-atlas.sh — v4.48.1 Protocol Atlas Conformance Tests
#
# Tests for Protocol Atlas existence, diagram completeness,
# and key content requirements.
#
# Usage: bash .opencode/conformance/tests/protocol-atlas.sh

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$ROOT_DIR/.opencode/conformance/assert.sh"

reset_counters

echo "=== v4.48.1 Protocol Atlas Conformance Tests ==="
echo ""

ATLAS="$ROOT_DIR/docs/protocol/PROTOCOL_ATLAS.md"
DIAGRAMS="$ROOT_DIR/docs/protocol/diagrams"

# ─── PA-001: atlas exists ─────────────────────────────────────────────
test_start "PA-001" "atlas exists"
assert_file_exists "$ATLAS" "Protocol Atlas exists"

# ─── PA-002: atlas has executive overview ──────────────────────────────
test_start "PA-002" "atlas has executive overview"
assert_file_contains "$ATLAS" "Executive Overview" "Atlas has executive overview"

# ─── PA-003: atlas has full operating loop ─────────────────────────────
test_start "PA-003" "atlas has full operating loop"
assert_file_contains "$ATLAS" "Full Operating Loop" "Atlas has operating loop section"

# ─── PA-004: atlas has protected-repo exclusion ────────────────────────────
test_start "PA-004" "atlas has protected-repo exclusion"
assert_file_contains "$ATLAS" "protected-repo" "Atlas documents protected-repo exclusion"

# ─── PA-005: atlas has current version ────────────────────────────────
test_start "PA-005" "atlas has current version"
assert_file_contains "$ATLAS" "v4.48" "Atlas mentions current version"

# ─── PA-006: system-overview diagram exists ───────────────────────────
test_start "PA-006" "system-overview diagram exists"
assert_file_exists "$DIAGRAMS/system-overview.mmd" "system-overview.mmd exists"

# ─── PA-007: task-lifecycle diagram exists ────────────────────────────
test_start "PA-007" "task-lifecycle diagram exists"
assert_file_exists "$DIAGRAMS/task-lifecycle.mmd" "task-lifecycle.mmd exists"

# ─── PA-008: risk-routing-decision-tree diagram exists ────────────────
test_start "PA-008" "risk-routing-decision-tree diagram exists"
assert_file_exists "$DIAGRAMS/risk-routing-decision-tree.mmd" "risk-routing-decision-tree.mmd exists"

# ─── PA-009: release-gate-flow diagram exists ─────────────────────────
test_start "PA-009" "release-gate-flow diagram exists"
assert_file_exists "$DIAGRAMS/release-gate-flow.mmd" "release-gate-flow.mmd exists"

# ─── PA-010: reviewer-evidence-flow diagram exists ────────────────────
test_start "PA-010" "reviewer-evidence-flow diagram exists"
assert_file_exists "$DIAGRAMS/reviewer-evidence-flow.mmd" "reviewer-evidence-flow.mmd exists"

# ─── PA-011: eval-loop-flow diagram exists ────────────────────────────
test_start "PA-011" "eval-loop-flow diagram exists"
assert_file_exists "$DIAGRAMS/eval-loop-flow.mmd" "eval-loop-flow.mmd exists"

# ─── PA-012: model-roi-routing-flow diagram exists ─────────────────────
test_start "PA-012" "model-roi-routing-flow diagram exists"
assert_file_exists "$DIAGRAMS/model-roi-routing-flow.mmd" "model-roi-routing-flow.mmd exists"

# ─── PA-013: fleet-protection-flow diagram exists ─────────────────────
test_start "PA-013" "fleet-protection-flow diagram exists"
assert_file_exists "$DIAGRAMS/fleet-protection-flow.mmd" "fleet-protection-flow.mmd exists"

# ─── PA-014: operator-responsibility-map diagram exists ────────────────
test_start "PA-014" "operator-responsibility-map diagram exists"
assert_file_exists "$DIAGRAMS/operator-responsibility-map.mmd" "operator-responsibility-map.mmd exists"

# ─── PA-015: artifact-map diagram exists ───────────────────────────────
test_start "PA-015" "artifact-map diagram exists"
assert_file_exists "$DIAGRAMS/artifact-map.mmd" "artifact-map.mmd exists"

# ─── PA-016: all diagrams are non-empty ───────────────────────────────
test_start "PA-016" "all diagrams are non-empty"
ALL_NONEMPTY=true
for f in "$DIAGRAMS"/*.mmd; do
  if [[ ! -s "$f" ]]; then
    echo -e "  ${RED}✗${NC} Empty diagram: $(basename "$f")"
    ALL_NONEMPTY=false
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
done
if [[ "$ALL_NONEMPTY" == true ]]; then
  echo -e "  ${GREEN}✓${NC} All 10 diagrams are non-empty"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# ─── PA-017: atlas has component map ──────────────────────────────────
test_start "PA-017" "atlas has component map"
assert_file_contains "$ATLAS" "Artifact" "Atlas has artifact/source-of-truth map"

# ─── PA-018: atlas mentions release gate ──────────────────────────────
test_start "PA-018" "atlas mentions release gate"
assert_file_contains "$ATLAS" "Release Gate" "Atlas documents release gate"

# ─── PA-019: atlas mentions loop controller ───────────────────────────
test_start "PA-019" "atlas mentions loop controller"
assert_file_contains "$ATLAS" "Loop controller" "Atlas documents loop controller"

# ─── PA-020: atlas mentions model ROI ─────────────────────────────────
test_start "PA-020" "atlas mentions model ROI"
assert_file_contains "$ATLAS" "Model ROI" "Atlas documents model ROI"

# ─── PA-021: atlas has maintenance rules ──────────────────────────────
test_start "PA-021" "atlas has maintenance rules"
assert_file_contains "$ATLAS" "Maintenance Rules" "Atlas has maintenance rules"

# ─── PA-022: atlas has glossary ───────────────────────────────────────
test_start "PA-022" "atlas has glossary"
assert_file_contains "$ATLAS" "Glossary" "Atlas has glossary"

# ─── PA-023: atlas has 5-minute explanation ────────────────────────────
test_start "PA-023" "atlas has 5-minute explanation"
assert_file_contains "$ATLAS" "5-Minute" "Atlas has 5-minute explanation"

# ─── PA-024: atlas has scoring dimensions ─────────────────────────────
test_start "PA-024" "atlas has scoring dimensions"
assert_file_contains "$ATLAS" "root_cause_correct" "Atlas documents root_cause_correct"
assert_file_contains "$ATLAS" "minimal_diff" "Atlas documents minimal_diff"
assert_file_contains "$ATLAS" "evidence_quality" "Atlas documents evidence_quality"

# ─── PA-025: atlas has confidence levels ─────────────────────────────
test_start "PA-025" "atlas has confidence levels"
assert_file_contains "$ATLAS" "high" "Atlas documents high confidence"
assert_file_contains "$ATLAS" "low" "Atlas documents low confidence"

# ─── PA-026: atlas has guardrails ─────────────────────────────────────
test_start "PA-026" "atlas has guardrails"
assert_file_contains "$ATLAS" "guardrails" "Atlas documents guardrails"
assert_file_contains "$ATLAS" "advisory only" "Atlas documents advisory only"

# ─── PA-027: atlas has lane summary ───────────────────────────────────
test_start "PA-027" "atlas has lane summary"
assert_file_contains "$ATLAS" "DIRECT" "Atlas documents DIRECT lane"
assert_file_contains "$ATLAS" "FAST" "Atlas documents FAST lane"
assert_file_contains "$ATLAS" "STANDARD" "Atlas documents STANDARD lane"
assert_file_contains "$ATLAS" "HIGH-RISK" "Atlas documents HIGH-RISK lane"

# ─── PA-028: atlas has fleet status ───────────────────────────────────
test_start "PA-028" "atlas has fleet status"
assert_file_contains "$ATLAS" "sample-service" "Atlas documents sample-service"
assert_file_contains "$ATLAS" "demo-project" "Atlas documents demo-project"

# ─── PA-029: validate-protocol-atlas.sh exists ───────────────────────
test_start "PA-029" "validate-protocol-atlas.sh exists"
assert_file_exists "$ROOT_DIR/.opencode/scripts/validate-protocol-atlas.sh" "Validator script exists"

# ─── PA-030: validator passes ─────────────────────────────────────────
test_start "PA-030" "validator passes"
VALIDATOR_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/validate-protocol-atlas.sh" 2>&1)
VALIDATOR_EXIT=$?
if [[ $VALIDATOR_EXIT -eq 0 ]]; then
  echo -e "  ${GREEN}✓${NC} Validator passes (exit 0)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Validator fails (exit $VALIDATOR_EXIT)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── PA-031: atlas has How to Use section ─────────────────────────────
test_start "PA-031" "atlas has How to Use section"
assert_file_contains "$ATLAS" "How to Use" "Atlas has How to Use section"

# ─── PA-032: atlas has 15-minute deep dive ───────────────────────────
test_start "PA-032" "atlas has 15-minute deep dive"
assert_file_contains "$ATLAS" "15-Minute" "Atlas has 15-minute deep dive"

# ─── PA-033: atlas has non-technical stakeholder section ──────────────
test_start "PA-033" "atlas has non-technical stakeholder section"
assert_file_contains "$ATLAS" "Non-Technical" "Atlas has non-technical stakeholder section"

# ─── PA-034: atlas has rendered diagrams section ─────────────────────
test_start "PA-034" "atlas has rendered diagrams section"
assert_file_contains "$ATLAS" "Rendered Diagrams" "Atlas has rendered diagrams section"

# ─── PA-035: all diagrams start with valid Mermaid syntax ─────────────
test_start "PA-035" "all diagrams start with valid Mermaid syntax"
ALL_VALID=true
for f in "$DIAGRAMS"/*.mmd; do
  FIRST_LINE=$(head -1 "$f")
  if ! echo "$FIRST_LINE" | grep -qE '^(graph|flowchart|stateDiagram|sequenceDiagram|classDiagram|erDiagram|gantt|pie|journey|gitGraph|%%{)' 2>/dev/null; then
    echo -e "  ${RED}✗${NC} Invalid syntax: $(basename "$f")"
    ALL_VALID=false
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
done
if [[ "$ALL_VALID" == true ]]; then
  echo -e "  ${GREEN}✓${NC} All diagrams start with valid Mermaid syntax"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# ─── PA-036: rendered SVG directory exists ───────────────────────────
test_start "PA-036" "rendered SVG directory exists"
if [[ -d "$ROOT_DIR/docs/protocol/rendered" ]]; then
  SVG_COUNT=$(find "$ROOT_DIR/docs/protocol/rendered" -name '*.svg' -type f 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$SVG_COUNT" -ge 10 ]]; then
    echo -e "  ${GREEN}✓${NC} Rendered directory has $SVG_COUNT SVG files"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "  ${RED}✗${NC} Only $SVG_COUNT SVG files (expected 10)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
else
  echo -e "  ${RED}✗${NC} Rendered directory not found"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── PA-037: validator includes syntax checks ────────────────────────
test_start "PA-037" "validator includes syntax checks"
assert_file_contains "$ROOT_DIR/.opencode/scripts/validate-protocol-atlas.sh" "Mermaid Syntax" "Validator includes Mermaid syntax checks"

# ─── PA-038: atlas version matches NOW.md version (v4.51.1) ──────────
test_start "PA-038" "atlas version matches NOW.md version"
ATLAS_VERSION=$(grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' "$ATLAS" | head -1)
NOW_VERSION=$(grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' "$ROOT_DIR/NOW.md" | head -1)
if [ "$ATLAS_VERSION" = "$NOW_VERSION" ]; then
  echo -e "  ${GREEN}✓${NC} Atlas version ($ATLAS_VERSION) matches NOW.md version ($NOW_VERSION)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Atlas version ($ATLAS_VERSION) does not match NOW.md version ($NOW_VERSION)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── PA-039: atlas test count is not obviously stale (v4.51.1) ────────
test_start "PA-039" "atlas test count is not obviously stale"
ATLAS_COUNT=$(grep -oE '[0-9]+ targeted tests?' "$ATLAS" | head -1 | grep -oE '^[0-9]+')
if [ -n "$ATLAS_COUNT" ] && [ "$ATLAS_COUNT" -ge 800 ]; then
  echo -e "  ${GREEN}✓${NC} Atlas test count ($ATLAS_COUNT) is current (≥800)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Atlas test count ($ATLAS_COUNT) appears stale (<800)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── PA-040: atlas suite count is not obviously stale (v4.51.1) ───────
test_start "PA-040" "atlas suite count is not obviously stale"
ATLAS_SUITES=$(grep -oE '[0-9]+ suites?' "$ATLAS" | head -1 | grep -oE '^[0-9]+')
if [ -n "$ATLAS_SUITES" ] && [ "$ATLAS_SUITES" -ge 16 ]; then
  echo -e "  ${GREEN}✓${NC} Atlas suite count ($ATLAS_SUITES) is current (≥16)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "  ${RED}✗${NC} Atlas suite count ($ATLAS_SUITES) appears stale (<16)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─── Report ──────────────────────────────────────────────────────────────
echo ""
report_results "$ROOT_DIR/.opencode/conformance/results/protocol-atlas-results.md"
