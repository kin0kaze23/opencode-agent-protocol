#!/usr/bin/env bash
# verify-release-history.sh — v4.55 Release History Verifier
#
# Checks that release history is coherent across:
# - Git tags
# - GitHub Releases
# - RELEASES.md
# - vault snapshots
# - vault CHANGELOG
# - vault VERSIONS.md
#
# Usage: bash .opencode/scripts/verify-release-history.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Release History Verifier ==="
echo ""

PASS=0
FAIL=0
SKIP=0

# Get all v4.x tags
TAGS=$(git tag -l 'v4.*' | sort -V)

for TAG in $TAGS; do
  HAS_TAG="yes"
  HAS_RELEASE=$(gh release view "$TAG" --json tagName -q '.tagName' 2>/dev/null || echo "")
  HAS_RELEASES_MD=$(grep -c "| $TAG " "$ROOT_DIR/RELEASES.md" 2>/dev/null || echo "0")
  HAS_SNAPSHOT=$([ -f "$ROOT_DIR/vault/protocols/opencode/snapshots/$TAG/protocol.md" ] && echo "yes" || echo "no")
  HAS_CHANGELOG=$(grep -c "$TAG" "$ROOT_DIR/vault/protocols/opencode/CHANGELOG.md" 2>/dev/null || echo "0")
  HAS_VERSIONS=$(grep -c "$TAG" "$ROOT_DIR/vault/protocols/opencode/VERSIONS.md" 2>/dev/null || echo "0")

  STATUS="✅"
  GAPS=""

  [ -z "$HAS_RELEASE" ] && GAPS="$GAPS no-release" && STATUS="⚠️"
  [ "$HAS_RELEASES_MD" -eq 0 ] && GAPS="$GAPS no-releases-md" && STATUS="⚠️"
  [ "$HAS_SNAPSHOT" = "no" ] && GAPS="$GAPS no-snapshot" && STATUS="⚠️"
  [ "$HAS_CHANGELOG" -eq 0 ] && GAPS="$GAPS no-changelog" && STATUS="⚠️"
  [ "$HAS_VERSIONS" -eq 0 ] && GAPS="$Gaps no-versions" && STATUS="⚠️"

  if [ -z "$GAPS" ]; then
    PASS=$((PASS + 1))
  else
    # Check if it's a retrospective tag (acceptable to not have GitHub Release)
    if echo "$TAG" | grep -qE 'v4\.(2[0-9]|3[0-2])'; then
      SKIP=$((SKIP + 1))
      STATUS="⊘ (retrospective)"
    else
      FAIL=$((FAIL + 1))
    fi
  fi

  printf "%-12s %s%s\n" "$TAG" "$STATUS" "$GAPS"
done

echo ""
echo "=========================================="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "SKIP (retrospective): $SKIP"
echo "=========================================="

# Version coherence check
echo ""
echo "=== Version Coherence ==="
CURRENT_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "none")
NOW_VERSION=$(grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' "$ROOT_DIR/NOW.md" | head -1)
AGENTS_VERSION=$(grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' "$ROOT_DIR/.opencode/AGENTS.md" | head -1)
RULES_VERSION=$(grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' "$ROOT_DIR/.opencode/rules.md" | head -1)
BRAIN_VERSION=$(grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' "$ROOT_DIR/.opencode/brain-config.json" | head -1)
ATLAS_VERSION=$(grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' "$ROOT_DIR/docs/protocol/PROTOCOL_ATLAS.md" | head -1)

echo "Git tag:        $CURRENT_TAG"
echo "NOW.md:         $NOW_VERSION"
echo "AGENTS.md:      $AGENTS_VERSION"
echo "rules.md:       $RULES_VERSION"
echo "brain-config:   $BRAIN_VERSION"
echo "Protocol Atlas: $ATLAS_VERSION"

if [ "$NOW_VERSION" = "$AGENTS_VERSION" ] && [ "$AGENTS_VERSION" = "$RULES_VERSION" ] && [ "$AGENTS_VERSION" = "$ATLAS_VERSION" ]; then
  echo "✅ Version coherence: PASS"
else
  echo "⚠️ Version coherence: MISMATCH"
fi
