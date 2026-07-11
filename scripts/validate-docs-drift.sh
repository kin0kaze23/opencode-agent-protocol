#!/usr/bin/env bash
# scripts/validate-docs-drift.sh
# Validates that documentation references real files, scripts, configs, and tests.
# Fails (exit 1) if any referenced file does not exist.
#
# Usage: bash scripts/validate-docs-drift.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
CHECKS=0

fail() {
  echo "  FAIL: $1"
  FAILURES=$((FAILURES + 1))
}

pass() {
  CHECKS=$((CHECKS + 1))
}

check_file_exists() {
  local ref="$1"
  local source_file="$2"
  if [ -e "$ROOT_DIR/$ref" ]; then
    pass
  else
    fail "$source_file references '$ref' but file/directory does not exist"
  fi
}

echo "=== Docs Drift Validation ==="
echo "Scanning: $ROOT_DIR"
echo ""

# ─────────────────────────────────────────────────────────────
# 1. Capability Catalog — verify referenced files exist
# ─────────────────────────────────────────────────────────────
echo "--- Capability Catalog references ---"
CATALOG="$ROOT_DIR/docs/CAPABILITY_CATALOG.md"
if [ -f "$CATALOG" ]; then
  # Extract file paths from the catalog (look for .opencode/, scripts/, docs/, .github/ patterns)
  REFS=$(grep -oE '`(\.opencode/[a-zA-Z0-9._/-]+|scripts/[a-zA-Z0-9._/-]+|docs/[a-zA-Z0-9._/-]+|\.github/[a-zA-Z0-9._/-]+)`' "$CATALOG" | tr -d '`' | sort -u)
  for ref in $REFS; do
    check_file_exists "$ref" "CAPABILITY_CATALOG.md"
  done
  echo "  Checked $(echo "$REFS" | wc -l | tr -d ' ') file references"
else
  fail "docs/CAPABILITY_CATALOG.md not found"
fi

# ─────────────────────────────────────────────────────────────
# 2. Runtime Map — verify referenced files exist
# ─────────────────────────────────────────────────────────────
echo "--- Runtime Map references ---"
RUNTIME_MAP="$ROOT_DIR/docs/RUNTIME_MAP.md"
if [ -f "$RUNTIME_MAP" ]; then
  REFS=$(grep -oE '`(\.opencode/[a-zA-Z0-9._/-]+|scripts/[a-zA-Z0-9._/-]+|docs/[a-zA-Z0-9._/-]+|\.github/[a-zA-Z0-9._/-]+)`' "$RUNTIME_MAP" | tr -d '`' | sort -u)
  for ref in $REFS; do
    check_file_exists "$ref" "RUNTIME_MAP.md"
  done
  echo "  Checked $(echo "$REFS" | wc -l | tr -d ' ') file references"
else
  fail "docs/RUNTIME_MAP.md not found"
fi

# ─────────────────────────────────────────────────────────────
# 3. Protocol Atlas — verify diagrams and SVGs exist
# ─────────────────────────────────────────────────────────────
echo "--- Protocol Atlas diagrams ---"
DIAGRAM_DIR="$ROOT_DIR/docs/protocol/diagrams"
RENDERED_DIR="$ROOT_DIR/docs/protocol/rendered"
MMD_COUNT=$(ls "$DIAGRAM_DIR"/*.mmd 2>/dev/null | wc -l | tr -d ' ')
SVG_COUNT=$(ls "$RENDERED_DIR"/*.svg 2>/dev/null | wc -l | tr -d ' ')

if [ "$MMD_COUNT" -ge 10 ]; then
  pass
  echo "  Mermaid diagrams: $MMD_COUNT found (≥10 required)"
else
  fail "Protocol Atlas has $MMD_COUNT Mermaid diagrams (expected ≥10)"
fi

if [ "$SVG_COUNT" -ge 10 ]; then
  pass
  echo "  Rendered SVGs: $SVG_COUNT found (≥10 required)"
else
  fail "Protocol Atlas has $SVG_COUNT rendered SVGs (expected ≥10)"
fi

# Verify each .mmd has a corresponding .svg
for mmd in "$DIAGRAM_DIR"/*.mmd; do
  base=$(basename "$mmd" .mmd)
  if [ -f "$RENDERED_DIR/$base.svg" ]; then
    pass
  else
    fail "Missing rendered SVG for $base.mmd"
  fi
done

# ─────────────────────────────────────────────────────────────
# 4. Version consistency — Atlas version matches NOW.md version
# ─────────────────────────────────────────────────────────────
echo "--- Version consistency ---"
ATLAS="$ROOT_DIR/docs/protocol/PROTOCOL_ATLAS.md"
ATLAS_VERSION=$(grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' "$ATLAS" | head -1)
NOW_VERSION=$(grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' "$ROOT_DIR/NOW.md" | head -1)
README_VERSION=$(grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' "$ROOT_DIR/README.md" | head -1)

if [ "$ATLAS_VERSION" = "$NOW_VERSION" ]; then
  pass
  echo "  Atlas ($ATLAS_VERSION) matches NOW.md ($NOW_VERSION)"
else
  fail "Atlas version ($ATLAS_VERSION) does not match NOW.md ($NOW_VERSION)"
fi

if [ "$ATLAS_VERSION" = "$README_VERSION" ]; then
  pass
  echo "  Atlas ($ATLAS_VERSION) matches README ($README_VERSION)"
else
  fail "Atlas version ($ATLAS_VERSION) does not match README ($README_VERSION)"
fi

# ─────────────────────────────────────────────────────────────
# 5. CI workflow references — verify workflow files exist
# ─────────────────────────────────────────────────────────────
echo "--- CI workflow references ---"
for wf in .github/workflows/validation.yml .github/workflows/gates.yml; do
  if [ -f "$ROOT_DIR/$wf" ]; then
    pass
    echo "  $wf exists"
  else
    fail "Referenced workflow $wf does not exist"
  fi
done

# ─────────────────────────────────────────────────────────────
# 6. README doc links — verify linked docs exist
# ─────────────────────────────────────────────────────────────
echo "--- README doc links ---"
README="$ROOT_DIR/README.md"
DOC_REFS=$(grep -oE '\[.*\]\((docs/[a-zA-Z0-9._/-]+)\)' "$README" | grep -oE 'docs/[a-zA-Z0-9._/-]+')
for ref in $DOC_REFS; do
  check_file_exists "$ref" "README.md"
done
echo "  Checked $(echo "$DOC_REFS" | wc -l | tr -d ' ') doc links"

# ─────────────────────────────────────────────────────────────
# 7. Conformance test scripts exist
# ─────────────────────────────────────────────────────────────
echo "--- Conformance test scripts ---"
TEST_COUNT=$(ls "$ROOT_DIR"/.opencode/conformance/tests/*.sh 2>/dev/null | wc -l | tr -d ' ')
if [ "$TEST_COUNT" -ge 20 ]; then
  pass
  echo "  $TEST_COUNT conformance test scripts found (≥20 required)"
else
  fail "Only $TEST_COUNT conformance test scripts found (expected ≥20)"
fi

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== PASS: Docs drift validation clean ($CHECKS checks) ==="
  exit 0
else
  echo "=== FAIL: $FAILURES drift issue(s) found ($CHECKS checks passed) ==="
  exit 1
fi
