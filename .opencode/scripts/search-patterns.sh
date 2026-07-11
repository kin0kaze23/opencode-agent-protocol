#!/usr/bin/env bash
# Search Patterns (v4.24)
#
# Searches the cross-project pattern index for reusable solutions.
# Builds the index if missing or stale.
#
# Usage: bash .opencode/scripts/search-patterns.sh "<query>"
# Example: bash .opencode/scripts/search-patterns.sh "supabase auth state management"
#
# Output:
#   PATTERN_MATCHES:
#     - pattern:
#       source_repo:
#       type:
#       relevance:
#       when_to_use:
#       risks:
#       suggested_files_to_read:

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CACHE_DIR="$ROOT_DIR/.opencode/cache"
INDEX_FILE="$CACHE_DIR/pattern-index.md"

QUERY="${1:-}"

if [ -z "$QUERY" ]; then
  echo "Usage: search-patterns.sh \"<query>\""
  exit 1
fi

# Build index if missing or stale (older than 1 hour)
if [ ! -f "$INDEX_FILE" ]; then
  bash "$SCRIPT_DIR/build-pattern-index.sh" >/dev/null 2>&1
elif [ -f "$INDEX_FILE" ]; then
  BUILT_LINE=$(grep "^Built:" "$INDEX_FILE" 2>/dev/null | head -1)
  BUILT_TIME=$(echo "$BUILT_LINE" | cut -d' ' -f2)
  CURRENT_TIME=$(date -Iseconds)
  if [ -n "$BUILT_TIME" ]; then
    BUILT_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${BUILT_TIME%%+*}" "+%s" 2>/dev/null || echo 0)
    CURRENT_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${CURRENT_TIME%%+*}" "+%s" 2>/dev/null || echo 0)
    if [ "$BUILT_EPOCH" -gt 0 ] && [ "$CURRENT_EPOCH" -gt 0 ]; then
      AGE=$((CURRENT_EPOCH - BUILT_EPOCH))
      if [ "$AGE" -gt 3600 ]; then
        bash "$SCRIPT_DIR/build-pattern-index.sh" >/dev/null 2>&1
      fi
    fi
  fi
fi

if [ ! -f "$INDEX_FILE" ]; then
  echo "PATTERN_MATCHES:"
  echo "  (index build failed — no patterns available)"
  exit 0
fi

# Convert query to lowercase for case-insensitive matching
QUERY_LOWER=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')
QUERY_WORDS=$(echo "$QUERY_LOWER" | tr ' ' '\n' | grep -v '^$' | sort -u)

# ============================================================
# Search index — split by --- delimiter and match each block
# ============================================================

echo "PATTERN_MATCHES:"

MATCH_COUNT=0

# Read the index file and split by --- delimiter
# Each block is a pattern entry
CURRENT_BLOCK=""
while IFS= read -r line; do
  if [ "$line" = "---" ]; then
    # Process the current block
    if [ -n "$CURRENT_BLOCK" ]; then
      BLOCK_LOWER=$(echo "$CURRENT_BLOCK" | tr '[:upper:]' '[:lower:]')

      # Check if any query word matches
      MATCHED=false
      MATCHED_WORDS=""
      for word in $QUERY_WORDS; do
        if echo "$BLOCK_LOWER" | grep -q "$word"; then
          MATCHED=true
          MATCHED_WORDS="${MATCHED_WORDS}${word} "
        fi
      done

      if [ "$MATCHED" = "true" ]; then
        # Extract fields from block
        SOURCE_REPO=$(echo "$CURRENT_BLOCK" | grep "^source_repo:" | head -1 | sed 's/source_repo: //')
        TYPE=$(echo "$CURRENT_BLOCK" | grep "^type:" | head -1 | sed 's/type: //')
        CATEGORY=$(echo "$CURRENT_BLOCK" | grep "^category:" | head -1 | sed 's/category: //')
        SOURCE_FILE=$(echo "$CURRENT_BLOCK" | grep "^source_file:" | head -1 | sed 's/source_file: //')

        # Extract content (lines after "content:")
        CONTENT=$(echo "$CURRENT_BLOCK" | sed -n '/^content:/,/^$/p' | grep -v "^content:" | grep -v "^$" | head -5)

        # Count matched words for relevance scoring
        WORD_COUNT=$(echo "$MATCHED_WORDS" | wc -w | tr -d ' ')

        echo "  - pattern: $TYPE ($CATEGORY)"
        echo "    source_repo: $SOURCE_REPO"
        echo "    source_file: $SOURCE_FILE"
        echo "    relevance: $WORD_COUNT keyword(s) matched: $(echo $MATCHED_WORDS | tr ' ' ', ')"
        echo "    content_preview:"
        echo "$CONTENT" | sed 's/^/      /'
        echo "    suggested_files_to_read:"
        echo "      - $SOURCE_REPO/PROJECT_MEMORY.md"
        echo "      - $SOURCE_REPO/AGENTS.md"
        echo ""

        MATCH_COUNT=$((MATCH_COUNT + 1))
      fi
    fi
    CURRENT_BLOCK=""
  else
    CURRENT_BLOCK="${CURRENT_BLOCK}${line}
"
  fi
done < "$INDEX_FILE"

if [ "$MATCH_COUNT" -eq 0 ]; then
  echo "  (no matching patterns found)"
  echo ""
  echo "  Suggestion: try broader keywords or check if PROJECT_MEMORY.md exists in active repos."
fi

echo "  Total matches: $MATCH_COUNT"
