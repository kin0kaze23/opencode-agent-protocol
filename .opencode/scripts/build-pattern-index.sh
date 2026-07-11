#!/usr/bin/env bash
# Build Pattern Index (v4.24)
#
# Scans active repos for reusable patterns, architecture decisions, and lessons.
# Outputs a local cache file that search-patterns.sh can query.
#
# Usage: bash .opencode/scripts/build-pattern-index.sh
# Output: .opencode/cache/pattern-index.md
#
# The cache is ephemeral — do not commit. Add .opencode/cache/ to .gitignore.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CACHE_DIR="$ROOT_DIR/.opencode/cache"
INDEX_FILE="$CACHE_DIR/pattern-index.md"

mkdir -p "$CACHE_DIR"

# ============================================================
# Find active repos (those with AGENTS.md)
# ============================================================

REPOS=()
while IFS= read -r f; do
  repo_dir=$(dirname "$f")
  repo_name=$(basename "$repo_dir")
  # Skip workspace root and vault
  [ "$repo_dir" = "$ROOT_DIR" ] && continue
  [ "$repo_name" = "vault" ] && continue
  REPOS+=("$repo_name:$repo_dir")
done < <(find "$ROOT_DIR" -maxdepth 2 -name "AGENTS.md" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null)

# ============================================================
# Build index
# ============================================================

cat > "$INDEX_FILE" << 'HEADER'
# Pattern Index — Auto-generated
# Do not edit manually. Run build-pattern-index.sh to regenerate.
# Format: entries are separated by --- lines.

HEADER

echo "Built: $(date -Iseconds)" >> "$INDEX_FILE"
echo "Repos scanned: ${#REPOS[@]}" >> "$INDEX_FILE"
echo "" >> "$INDEX_FILE"

PATTERN_COUNT=0

for entry in "${REPOS[@]}"; do
  repo_name="${entry%%:*}"
  repo_dir="${entry#*:}"
  repo_abs="$(cd "$repo_dir" 2>/dev/null && pwd || echo "$repo_dir")"

  # --- Extract from PROJECT_MEMORY.md ---
  if [ -f "$repo_abs/PROJECT_MEMORY.md" ]; then
    # Architecture Notes
    arch_notes=$(awk '/^## Architecture Notes/{f=1;next} /^## /{f=0} f' "$repo_abs/PROJECT_MEMORY.md" 2>/dev/null | head -20)
    if [ -n "$arch_notes" ]; then
      echo "---" >> "$INDEX_FILE"
      echo "type: architecture" >> "$INDEX_FILE"
      echo "source_repo: $repo_name" >> "$INDEX_FILE"
      echo "source_file: PROJECT_MEMORY.md" >> "$INDEX_FILE"
      echo "category: architecture" >> "$INDEX_FILE"
      echo "content:" >> "$INDEX_FILE"
      echo "$arch_notes" | grep -v "^$" | sed 's/^/  /' >> "$INDEX_FILE"
      echo "" >> "$INDEX_FILE"
      PATTERN_COUNT=$((PATTERN_COUNT + 1))
    fi

    # Key Decisions
    decisions=$(awk '/^## Key Decisions/{f=1;next} /^## /{f=0} f' "$repo_abs/PROJECT_MEMORY.md" 2>/dev/null | head -15)
    if [ -n "$decisions" ]; then
      echo "---" >> "$INDEX_FILE"
      echo "type: decision" >> "$INDEX_FILE"
      echo "source_repo: $repo_name" >> "$INDEX_FILE"
      echo "source_file: PROJECT_MEMORY.md" >> "$INDEX_FILE"
      echo "category: decision" >> "$INDEX_FILE"
      echo "content:" >> "$INDEX_FILE"
      echo "$decisions" | grep -v "^$" | sed 's/^/  /' >> "$INDEX_FILE"
      echo "" >> "$INDEX_FILE"
      PATTERN_COUNT=$((PATTERN_COUNT + 1))
    fi

    # Known Risks
    risks=$(awk '/^## Known Risks/{f=1;next} /^## /{f=0} f' "$repo_abs/PROJECT_MEMORY.md" 2>/dev/null | head -10)
    if [ -n "$risks" ]; then
      echo "---" >> "$INDEX_FILE"
      echo "type: risk" >> "$INDEX_FILE"
      echo "source_repo: $repo_name" >> "$INDEX_FILE"
      echo "source_file: PROJECT_MEMORY.md" >> "$INDEX_FILE"
      echo "category: risk" >> "$INDEX_FILE"
      echo "content:" >> "$INDEX_FILE"
      echo "$risks" | grep -v "^$" | sed 's/^/  /' >> "$INDEX_FILE"
      echo "" >> "$INDEX_FILE"
      PATTERN_COUNT=$((PATTERN_COUNT + 1))
    fi

    # Stack
    stack=$(awk '/^## Stack/{f=1;next} /^## /{f=0} f' "$repo_abs/PROJECT_MEMORY.md" 2>/dev/null | head -10)
    if [ -n "$stack" ]; then
      echo "---" >> "$INDEX_FILE"
      echo "type: stack" >> "$INDEX_FILE"
      echo "source_repo: $repo_name" >> "$INDEX_FILE"
      echo "source_file: PROJECT_MEMORY.md" >> "$INDEX_FILE"
      echo "category: stack" >> "$INDEX_FILE"
      echo "content:" >> "$INDEX_FILE"
      echo "$stack" | grep -v "^$" | sed 's/^/  /' >> "$INDEX_FILE"
      echo "" >> "$INDEX_FILE"
      PATTERN_COUNT=$((PATTERN_COUNT + 1))
    fi
  fi

  # --- Extract from AGENTS.md ---
  if [ -f "$repo_abs/AGENTS.md" ]; then
    # Architecture Hotspots
    hotspots=$(awk '/^## Architecture Hotspots/{f=1;next} /^## /{f=0} f' "$repo_abs/AGENTS.md" 2>/dev/null | head -10)
    if [ -n "$hotspots" ]; then
      echo "---" >> "$INDEX_FILE"
      echo "type: architecture" >> "$INDEX_FILE"
      echo "source_repo: $repo_name" >> "$INDEX_FILE"
      echo "source_file: AGENTS.md" >> "$INDEX_FILE"
      echo "category: hotspot" >> "$INDEX_FILE"
      echo "content:" >> "$INDEX_FILE"
      echo "$hotspots" | grep -v "^$" | sed 's/^/  /' >> "$INDEX_FILE"
      echo "" >> "$INDEX_FILE"
      PATTERN_COUNT=$((PATTERN_COUNT + 1))
    fi

    # Dangerous Areas
    dangers=$(awk '/^## Dangerous Areas/{f=1;next} /^## /{f=0} f' "$repo_abs/AGENTS.md" 2>/dev/null | head -10)
    if [ -n "$dangers" ]; then
      echo "---" >> "$INDEX_FILE"
      echo "type: risk" >> "$INDEX_FILE"
      echo "source_repo: $repo_name" >> "$INDEX_FILE"
      echo "source_file: AGENTS.md" >> "$INDEX_FILE"
      echo "category: danger" >> "$INDEX_FILE"
      echo "content:" >> "$INDEX_FILE"
      echo "$dangers" | grep -v "^$" | sed 's/^/  /' >> "$INDEX_FILE"
      echo "" >> "$INDEX_FILE"
      PATTERN_COUNT=$((PATTERN_COUNT + 1))
    fi
  fi

  # --- Extract from vault lessons ---
  lessons_file="$ROOT_DIR/vault/projects/$repo_name/lessons.md"
  if [ -f "$lessons_file" ]; then
    # Extract lesson lines (usually bullet points or numbered items)
    lessons=$(grep -E "^[-*] |^[0-9]+\." "$lessons_file" 2>/dev/null | head -15)
    if [ -n "$lessons" ]; then
      echo "---" >> "$INDEX_FILE"
      echo "type: lesson" >> "$INDEX_FILE"
      echo "source_repo: $repo_name" >> "$INDEX_FILE"
      echo "source_file: vault/projects/$repo_name/lessons.md" >> "$INDEX_FILE"
      echo "category: lesson" >> "$INDEX_FILE"
      echo "content:" >> "$INDEX_FILE"
      echo "$lessons" | sed 's/^/  /' >> "$INDEX_FILE"
      echo "" >> "$INDEX_FILE"
      PATTERN_COUNT=$((PATTERN_COUNT + 1))
    fi
  fi
done

# --- Extract from vault decisions ---
for dec_file in "$ROOT_DIR"/vault/projects/*/decisions.md; do
  [ -f "$dec_file" ] || continue
  repo_name=$(basename "$(dirname "$dec_file")")
  decisions=$(grep -E "^[-*] |^[0-9]+\." "$dec_file" 2>/dev/null | head -10)
  if [ -n "$decisions" ]; then
    echo "---" >> "$INDEX_FILE"
    echo "type: decision" >> "$INDEX_FILE"
    echo "source_repo: $repo_name" >> "$INDEX_FILE"
    echo "source_file: vault/projects/$repo_name/decisions.md" >> "$INDEX_FILE"
    echo "category: decision" >> "$INDEX_FILE"
    echo "content:" >> "$INDEX_FILE"
    echo "$decisions" | sed 's/^/  /' >> "$INDEX_FILE"
    echo "" >> "$INDEX_FILE"
    PATTERN_COUNT=$((PATTERN_COUNT + 1))
  fi
done

# --- Output ---
echo "Pattern index built at $INDEX_FILE"
echo "  repos scanned: ${#REPOS[@]}"
echo "  patterns indexed: $PATTERN_COUNT"
