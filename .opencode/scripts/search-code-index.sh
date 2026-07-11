#!/usr/bin/env bash
# Search Code Index (v4.21)
#
# Searches a repo's code index for files, symbols, and routes matching a query.
# Builds the index if it doesn't exist.
#
# Usage: bash .opencode/scripts/search-code-index.sh <repo-path> "<query>"
# Example: bash .opencode/scripts/search-code-index.sh protected-repo-prod "growth chart"
#
# Output:
#   CODE_INDEX_MATCHES:
#     files:
#       - src/components/GrowthChart.tsx
#     symbols:
#       - src/lib/growth.ts:42  function calculateGrowthPercentile
#     routes:
#       - src/pages/Growth.tsx
#     package_scripts:
#       - test: vitest
#   Suggested next reads:
#     - src/components/GrowthChart.tsx
#     - src/lib/growth.ts

set -uo pipefail

REPO_PATH="${1:-.}"
QUERY="${2:-}"

if [ -z "$QUERY" ]; then
  echo "Usage: search-code-index.sh <repo-path> \"<query>\""
  exit 1
fi

# Resolve to absolute path
REPO_ABS="$(cd "$REPO_PATH" 2>/dev/null && pwd || echo "$REPO_PATH")"
INDEX_DIR="$REPO_ABS/.code-index"

# Build index if missing or stale (older than 1 hour)
if [ ! -f "$INDEX_DIR/files.txt" ] || [ ! -f "$INDEX_DIR/meta.txt" ]; then
  bash "$(dirname "$0")/build-code-index.sh" "$REPO_ABS" >/dev/null 2>&1
elif [ -f "$INDEX_DIR/meta.txt" ]; then
  BUILT_TIME=$(grep "^built:" "$INDEX_DIR/meta.txt" | cut -d' ' -f2)
  CURRENT_TIME=$(date -Iseconds)
  # Simple staleness check: if index is older than 1 hour, rebuild
  if [ -n "$BUILT_TIME" ]; then
    BUILT_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${BUILT_TIME%%+*}" "+%s" 2>/dev/null || echo 0)
    CURRENT_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${CURRENT_TIME%%+*}" "+%s" 2>/dev/null || echo 0)
    if [ "$BUILT_EPOCH" -gt 0 ] && [ "$CURRENT_EPOCH" -gt 0 ]; then
      AGE=$((CURRENT_EPOCH - BUILT_EPOCH))
      if [ "$AGE" -gt 3600 ]; then
        bash "$(dirname "$0")/build-code-index.sh" "$REPO_ABS" >/dev/null 2>&1
      fi
    fi
  fi
fi

# Convert query to lowercase for case-insensitive matching
QUERY_LOWER=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')

# Split query into individual words for broader matching
QUERY_WORDS=$(echo "$QUERY_LOWER" | tr ' ' '\n' | grep -v '^$' | sort -u)

# ============================================================
# Search files
# ============================================================

FILE_MATCHES=""
if [ -f "$INDEX_DIR/files.txt" ]; then
  # Match any query word in filename
  for word in $QUERY_WORDS; do
    grep -i "$word" "$INDEX_DIR/files.txt" 2>/dev/null
  done | sort -u | head -20 > /tmp/code-index-file-matches.$$ || true
  FILE_MATCHES=$(cat /tmp/code-index-file-matches.$$ 2>/dev/null | head -20)
  rm -f /tmp/code-index-file-matches.$$
fi

# ============================================================
# Search symbols
# ============================================================

SYMBOL_MATCHES=""
if [ -f "$INDEX_DIR/symbols.txt" ] && [ -s "$INDEX_DIR/symbols.txt" ]; then
  for word in $QUERY_WORDS; do
    grep -i "$word" "$INDEX_DIR/symbols.txt" 2>/dev/null | head -10
  done | sort -u | head -15 > /tmp/code-index-sym-matches.$$ || true
  SYMBOL_MATCHES=$(cat /tmp/code-index-sym-matches.$$ 2>/dev/null | head -15)
  rm -f /tmp/code-index-sym-matches.$$
fi

# ============================================================
# Search routes
# ============================================================

ROUTE_MATCHES=""
if [ -f "$INDEX_DIR/routes.txt" ] && [ -s "$INDEX_DIR/routes.txt" ]; then
  for word in $QUERY_WORDS; do
    grep -i "$word" "$INDEX_DIR/routes.txt" 2>/dev/null
  done | sort -u | head -10 > /tmp/code-index-route-matches.$$ || true
  ROUTE_MATCHES=$(cat /tmp/code-index-route-matches.$$ 2>/dev/null | head -10)
  rm -f /tmp/code-index-route-matches.$$
fi

# ============================================================
# Search package scripts
# ============================================================

SCRIPT_MATCHES=""
if [ -f "$INDEX_DIR/package-scripts.txt" ] && [ -s "$INDEX_DIR/package-scripts.txt" ]; then
  for word in $QUERY_WORDS; do
    grep -i "$word" "$INDEX_DIR/package-scripts.txt" 2>/dev/null
  done | sort -u | head -5 > /tmp/code-index-script-matches.$$ || true
  SCRIPT_MATCHES=$(cat /tmp/code-index-script-matches.$$ 2>/dev/null | head -5)
  rm -f /tmp/code-index-script-matches.$$
fi

# ============================================================
# Output
# ============================================================

echo "CODE_INDEX_MATCHES:"

echo "  files:"
if [ -n "$FILE_MATCHES" ]; then
  echo "$FILE_MATCHES" | while IFS= read -r f; do
    [ -n "$f" ] && echo "    - $f"
  done
else
  echo "    (no matches)"
fi

echo "  symbols:"
if [ -n "$SYMBOL_MATCHES" ]; then
  echo "$SYMBOL_MATCHES" | while IFS= read -r s; do
    [ -n "$s" ] && echo "    - $s"
  done
else
  echo "    (no matches)"
fi

echo "  routes:"
if [ -n "$ROUTE_MATCHES" ]; then
  echo "$ROUTE_MATCHES" | while IFS= read -r r; do
    [ -n "$r" ] && echo "    - $r"
  done
else
  echo "    (no matches)"
fi

echo "  package_scripts:"
if [ -n "$SCRIPT_MATCHES" ]; then
  echo "$SCRIPT_MATCHES" | while IFS= read -r s; do
    [ -n "$s" ] && echo "    - $s"
  done
else
  echo "    (no matches)"
fi

# Suggested next reads — prioritize files that appear in both file and symbol matches
echo "  Suggested next reads:"
SUGGESTED=""
if [ -n "$FILE_MATCHES" ]; then
  # Take top 3 file matches as suggested reads
  SUGGESTED=$(echo "$FILE_MATCHES" | head -3)
elif [ -n "$SYMBOL_MATCHES" ]; then
  # Extract filenames from symbol matches
  SUGGESTED=$(echo "$SYMBOL_MATCHES" | head -3 | sed 's/^\([^:]*\):.*/\1/' | sort -u)
fi

if [ -n "$SUGGESTED" ]; then
  echo "$SUGGESTED" | while IFS= read -r s; do
    [ -n "$s" ] && echo "    - $s"
  done
else
  echo "    (no suggestions — try broadening your query)"
fi
