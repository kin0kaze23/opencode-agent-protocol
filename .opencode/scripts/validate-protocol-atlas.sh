#!/usr/bin/env bash
# validate-protocol-atlas.sh — v4.48.1 Protocol Atlas Validator
#
# Validates that the Protocol Atlas exists, all diagrams are present,
# and key content is included.
#
# Usage: bash validate-protocol-atlas.sh

set -uo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ATLAS_FILE="$WORKSPACE_ROOT/docs/protocol/PROTOCOL_ATLAS.md"
DIAGRAMS_DIR="$WORKSPACE_ROOT/docs/protocol/diagrams"

ERRORS=0

echo "=== Protocol Atlas Validator ==="
echo ""

# ─── Check atlas exists ──────────────────────────────────────────────────
if [[ ! -f "$ATLAS_FILE" ]]; then
  echo "ERROR: PROTOCOL_ATLAS.md not found at $ATLAS_FILE"
  ERRORS=$((ERRORS + 1))
fi
echo "[check] Atlas file: $([ -f "$ATLAS_FILE" ] && echo 'PASS' || echo 'FAIL')"

# ─── Check all required diagrams ─────────────────────────────────────────
REQUIRED_DIAGRAMS=(
  "system-overview.mmd"
  "task-lifecycle.mmd"
  "risk-routing-decision-tree.mmd"
  "release-gate-flow.mmd"
  "reviewer-evidence-flow.mmd"
  "eval-loop-flow.mmd"
  "model-roi-routing-flow.mmd"
  "fleet-protection-flow.mmd"
  "operator-responsibility-map.mmd"
  "artifact-map.mmd"
)

for diagram in "${REQUIRED_DIAGRAMS[@]}"; do
  DIAGRAM_PATH="$DIAGRAMS_DIR/$diagram"
  if [[ ! -f "$DIAGRAM_PATH" ]]; then
    echo "ERROR: Diagram not found: $diagram"
    ERRORS=$((ERRORS + 1))
  elif [[ ! -s "$DIAGRAM_PATH" ]]; then
    echo "ERROR: Diagram is empty: $diagram"
    ERRORS=$((ERRORS + 1))
  fi
done
echo "[check] Diagrams: $([ $ERRORS -eq 0 ] && echo "PASS (${#REQUIRED_DIAGRAMS[@]} files)" || echo "FAIL")"

# ─── Check key content in atlas ──────────────────────────────────────────
if [[ -f "$ATLAS_FILE" ]]; then
  # Current version mentioned
  if ! grep -q "v4.48" "$ATLAS_FILE" 2>/dev/null; then
    echo "ERROR: Current version not mentioned in atlas"
    ERRORS=$((ERRORS + 1))
  fi
  echo "[check] Version mentioned: $(grep -q 'v4.48' "$ATLAS_FILE" 2>/dev/null && echo 'PASS' || echo 'FAIL')"

  # protected-repo exclusion documented
  if ! grep -qi "protected-repo" "$ATLAS_FILE" 2>/dev/null; then
    echo "ERROR: protected-repo exclusion not documented"
    ERRORS=$((ERRORS + 1))
  fi
  echo "[check] protected-repo documented: $(grep -qi 'protected-repo' "$ATLAS_FILE" 2>/dev/null && echo 'PASS' || echo 'FAIL')"

  # Core operating loop present
  if ! grep -q "Operating Loop" "$ATLAS_FILE" 2>/dev/null; then
    echo "ERROR: Core operating loop not present"
    ERRORS=$((ERRORS + 1))
  fi
  echo "[check] Operating loop: $(grep -q 'Operating Loop' "$ATLAS_FILE" 2>/dev/null && echo 'PASS' || echo 'FAIL')"

  # Release gate documented
  if ! grep -q "Release Gate" "$ATLAS_FILE" 2>/dev/null; then
    echo "ERROR: Release gate not documented"
    ERRORS=$((ERRORS + 1))
  fi
  echo "[check] Release gate: $(grep -q 'Release Gate' "$ATLAS_FILE" 2>/dev/null && echo 'PASS' || echo 'FAIL')"

  # Eval/loop/ROI flow documented
  if ! grep -q "Model ROI" "$ATLAS_FILE" 2>/dev/null; then
    echo "ERROR: Model ROI not documented"
    ERRORS=$((ERRORS + 1))
  fi
  echo "[check] Model ROI: $(grep -q 'Model ROI' "$ATLAS_FILE" 2>/dev/null && echo 'PASS' || echo 'FAIL')"

  # Loop controller documented
  if ! grep -qi "loop controller" "$ATLAS_FILE" 2>/dev/null; then
    echo "ERROR: Loop controller not documented"
    ERRORS=$((ERRORS + 1))
  fi
  echo "[check] Loop controller: $(grep -qi 'loop controller' "$ATLAS_FILE" 2>/dev/null && echo 'PASS' || echo 'FAIL')"

  # Maintenance rules present
  if ! grep -q "Maintenance Rules" "$ATLAS_FILE" 2>/dev/null; then
    echo "ERROR: Maintenance rules not present"
    ERRORS=$((ERRORS + 1))
  fi
  echo "[check] Maintenance rules: $(grep -q 'Maintenance Rules' "$ATLAS_FILE" 2>/dev/null && echo 'PASS' || echo 'FAIL')"

  # Glossary present
  if ! grep -q "Glossary" "$ATLAS_FILE" 2>/dev/null; then
    echo "ERROR: Glossary not present"
    ERRORS=$((ERRORS + 1))
  fi
  echo "[check] Glossary: $(grep -q 'Glossary' "$ATLAS_FILE" 2>/dev/null && echo 'PASS' || echo 'FAIL')"

  # 5-minute explanation present
  if ! grep -qi "5-minute\|5 minute" "$ATLAS_FILE" 2>/dev/null; then
    echo "ERROR: 5-minute explanation not present"
    ERRORS=$((ERRORS + 1))
  fi
  echo "[check] 5-minute explanation: $(grep -qi '5-minute\|5 minute' "$ATLAS_FILE" 2>/dev/null && echo 'PASS' || echo 'FAIL')"

  # How to use this atlas section
  if ! grep -q "How to Use" "$ATLAS_FILE" 2>/dev/null; then
    echo "ERROR: How to use section not present"
    ERRORS=$((ERRORS + 1))
  fi
  echo "[check] How to use section: $(grep -q 'How to Use' "$ATLAS_FILE" 2>/dev/null && echo 'PASS' || echo 'FAIL')"
fi

# ─── Check Mermaid syntax for all diagrams ────────────────────────────────
echo ""
echo "--- Mermaid Syntax Checks ---"
SYNTAX_ERRORS=0

for diagram in "${REQUIRED_DIAGRAMS[@]}"; do
  DIAGRAM_PATH="$DIAGRAMS_DIR/$diagram"
  [[ ! -f "$DIAGRAM_PATH" ]] && continue

  # Check file starts with valid Mermaid syntax
  FIRST_LINE=$(head -1 "$DIAGRAM_PATH")
  if ! echo "$FIRST_LINE" | grep -qE '^(graph|flowchart|stateDiagram|sequenceDiagram|classDiagram|erDiagram|gantt|pie|journey|gitGraph|%%{)' 2>/dev/null; then
    echo "ERROR: $diagram does not start with valid Mermaid syntax"
    SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
    continue
  fi

  # Check for obvious malformed arrows (--> without source or target)
  if grep -qE '^\s*-->\s*$' "$DIAGRAM_PATH" 2>/dev/null; then
    echo "ERROR: $diagram has malformed arrow (empty target)"
    SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
    continue
  fi

  # Check for unescaped parentheses in node labels (common Mermaid issue)
  # Parentheses inside [] or {} labels can cause parse errors
  if grep -qE '\[[^]]*\([^]]*\)' "$DIAGRAM_PATH" 2>/dev/null; then
    # This might be fine in newer Mermaid versions, just warn
    :
  fi

  echo "[syntax] $diagram: PASS"
done

if [[ $SYNTAX_ERRORS -gt 0 ]]; then
  ERRORS=$((ERRORS + SYNTAX_ERRORS))
fi

# ─── Check rendered SVGs exist ────────────────────────────────────────────
RENDERED_DIR="$WORKSPACE_ROOT/docs/protocol/rendered"
if [[ -d "$RENDERED_DIR" ]]; then
  SVG_COUNT=$(find "$RENDERED_DIR" -name '*.svg' -type f 2>/dev/null | wc -l | tr -d ' ')
  echo ""
  echo "[check] Rendered SVGs: $SVG_COUNT found"
else
  echo ""
  echo "[check] Rendered SVGs: directory not found (run npx @mermaid-js/mermaid-cli to generate)"
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo "=== VALIDATION PASS ==="
  exit 0
else
  echo "=== VALIDATION FAIL ($ERRORS errors) ==="
  exit 1
fi
