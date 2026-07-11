#!/usr/bin/env bash
# Retrieve Lessons (v4.21 → v4.24)
#
# Searches project memory, vault lessons, and progress for keywords relevant to a task.
# Uses grep/ripgrep — no vector DB.
#
# Usage: bash .opencode/scripts/retrieve-lessons.sh <repo-path> "<task keywords>" [--cross-project]
# Example: bash .opencode/scripts/retrieve-lessons.sh protected-repo-prod "growth chart supabase"
# Example: bash .opencode/scripts/retrieve-lessons.sh demo-project "auth state" --cross-project
#
# Output:
#   RELEVANT_LESSONS:
#     lessons:
#       - <lesson text>
#     risks:
#       - <risk text>
#     decisions:
#       - <decision text>
#     memory_notes:
#       - <project memory note>
#   Escalation hints:
#     - <if auth/RLS/payment/migration/secrets/crypto/deploy/production mentioned, flag escalation>

set -uo pipefail

# Parse arguments — check for --cross-project flag
CROSS_PROJECT=false
ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--cross-project" ]; then
    CROSS_PROJECT=true
  else
    ARGS+=("$arg")
  fi
done

REPO_PATH="${ARGS[0]:-.}"
KEYWORDS="${ARGS[1]:-}"

if [ -z "$KEYWORDS" ]; then
  echo "Usage: retrieve-lessons.sh <repo-path> \"<task keywords>\" [--cross-project]"
  exit 1
fi

# Resolve paths
REPO_ABS="$(cd "$REPO_PATH" 2>/dev/null && pwd || echo "$REPO_PATH")"
REPO_NAME="$(basename "$REPO_ABS")"
WORKSPACE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Source files to search (in priority order)
PROJECT_MEMORY="$REPO_ABS/PROJECT_MEMORY.md"
NOW_MD="$REPO_ABS/NOW.md"
LESSONS_MD="$WORKSPACE_ROOT/vault/projects/$REPO_NAME/lessons.md"
PROGRESS_MD="$WORKSPACE_ROOT/vault/projects/$REPO_NAME/progress.md"

# Escalation keywords — if any lesson mentions these, flag for escalation
ESCALATION_KEYWORDS="auth|rls|payment|migration|schema|secrets|crypto|deploy|production|destructive|drop|delete|truncate"

# Convert keywords to individual words for matching
KEYWORD_LIST=$(echo "$KEYWORDS" | tr '[:upper:]' '[:lower:]' | tr ' ' '\n' | grep -v '^$' | sort -u)

# ============================================================
# Search each source
# ============================================================

LESSONS_FOUND=""
RISKS_FOUND=""
DECISIONS_FOUND=""
MEMORY_NOTES=""
ESCALATION_HINTS=""

search_file() {
  local file="$1"
  local section_prefix="$2"
  local result_var="$3"

  if [ ! -f "$file" ]; then
    return 0
  fi

  local matches=""
  for word in $KEYWORD_LIST; do
    # Search for lines containing the keyword, with context
    grep -i "$word" "$file" 2>/dev/null | head -5
  done | sort -u | head -10 >> "/tmp/lessons-search.$$" || true

  while IFS= read -r line; do
    [ -n "$line" ] && matches="${matches}${line}\n"
  done < "/tmp/lessons-search.$$" 2>/dev/null
  rm -f "/tmp/lessons-search.$$"

  if [ -n "$matches" ]; then
    eval "$result_var=\"\${$result_var}${matches}\""
  fi
}

# Search PROJECT_MEMORY.md — extract sections using grep with line ranges
if [ -f "$PROJECT_MEMORY" ]; then
  for word in $KEYWORD_LIST; do
    # Search Known Risks section
    grep -i "$word" "$PROJECT_MEMORY" 2>/dev/null | grep -i "risk\|warning\|danger\|blocker\|unmitigated\|non-blocking" | head -3
  done | sort -u | head -5 > /tmp/rl-risks.$$ 2>/dev/null || true
  while IFS= read -r line; do
    [ -n "$line" ] && RISKS_FOUND="${RISKS_FOUND}  - $line\n"
  done < /tmp/rl-risks.$$ 2>/dev/null
  rm -f /tmp/rl-risks.$$

  for word in $KEYWORD_LIST; do
    # Search Key Decisions section
    grep -i "$word" "$PROJECT_MEMORY" 2>/dev/null | grep -i "decision\|chosen\|because\|why\|2026" | head -3
  done | sort -u | head -5 > /tmp/rl-decisions.$$ 2>/dev/null || true
  while IFS= read -r line; do
    [ -n "$line" ] && DECISIONS_FOUND="${DECISIONS_FOUND}  - $line\n"
  done < /tmp/rl-decisions.$$ 2>/dev/null
  rm -f /tmp/rl-decisions.$$

  for word in $KEYWORD_LIST; do
    # Search Recurring Lessons section
    grep -i "$word" "$PROJECT_MEMORY" 2>/dev/null | grep -i "lesson\|never\|always\|must\|do not\|require" | head -3
  done | sort -u | head -5 > /tmp/rl-lessons.$$ 2>/dev/null || true
  while IFS= read -r line; do
    [ -n "$line" ] && LESSONS_FOUND="${LESSONS_FOUND}  - $line\n"
  done < /tmp/rl-lessons.$$ 2>/dev/null
  rm -f /tmp/rl-lessons.$$

  for word in $KEYWORD_LIST; do
    # Search Architecture Notes section + general content
    grep -i "$word" "$PROJECT_MEMORY" 2>/dev/null | grep -iv "^(no matching" | head -3
  done | sort -u | head -5 > /tmp/rl-memory.$$ 2>/dev/null || true
  while IFS= read -r line; do
    [ -n "$line" ] && MEMORY_NOTES="${MEMORY_NOTES}  - $line\n"
  done < /tmp/rl-memory.$$ 2>/dev/null
  rm -f /tmp/rl-memory.$$
fi

# Search lessons.md — grep for keywords
if [ -f "$LESSONS_MD" ]; then
  for word in $KEYWORD_LIST; do
    grep -i "$word" "$LESSONS_MD" 2>/dev/null | head -5
  done | sort -u | head -10 > /tmp/rl-vault-lessons.$$ 2>/dev/null || true
  while IFS= read -r line; do
    [ -n "$line" ] && LESSONS_FOUND="${LESSONS_FOUND}  - $line\n"
  done < /tmp/rl-vault-lessons.$$ 2>/dev/null
  rm -f /tmp/rl-vault-lessons.$$
fi

# Search NOW.md — grep for keywords (current task context)
if [ -f "$NOW_MD" ]; then
  for word in $KEYWORD_LIST; do
    grep -i "$word" "$NOW_MD" 2>/dev/null | head -3
  done | sort -u | head -5 > /tmp/rl-now.$$ 2>/dev/null || true
  while IFS= read -r line; do
    [ -n "$line" ] && MEMORY_NOTES="${MEMORY_NOTES}  - $line\n"
  done < /tmp/rl-now.$$ 2>/dev/null
  rm -f /tmp/rl-now.$$
fi

# Search progress.md — grep for keywords
if [ -f "$PROGRESS_MD" ]; then
  for word in $KEYWORD_LIST; do
    grep -i "$word" "$PROGRESS_MD" 2>/dev/null | head -3
  done | sort -u | head -5 > /tmp/rl-progress.$$ 2>/dev/null || true
  while IFS= read -r line; do
    [ -n "$line" ] && MEMORY_NOTES="${MEMORY_NOTES}  - $line\n"
  done < /tmp/rl-progress.$$ 2>/dev/null
  rm -f /tmp/rl-progress.$$
fi

# ============================================================
# Cross-project search (v4.24) — search other repos' lessons
# ============================================================

CROSS_PROJECT_LESSONS=""
CROSS_PROJECT_REPOS=""

if [ "$CROSS_PROJECT" = "true" ]; then
  # Find all repos with lessons.md in vault
  for other_lessons in "$WORKSPACE_ROOT"/vault/projects/*/lessons.md; do
    [ -f "$other_lessons" ] || continue
    other_repo=$(basename "$(dirname "$other_lessons")")
    # Skip the current repo — already searched above
    [ "$other_repo" = "$REPO_NAME" ] && continue

    for word in $KEYWORD_LIST; do
      grep -i "$word" "$other_lessons" 2>/dev/null | head -3
    done | sort -u | head -5 > /tmp/rl-cross.$$ 2>/dev/null || true

    while IFS= read -r line; do
      [ -n "$line" ] && CROSS_PROJECT_LESSONS="${CROSS_PROJECT_LESSONS}  - [$other_repo] $line\n"
    done < /tmp/rl-cross.$$ 2>/dev/null
    rm -f /tmp/rl-cross.$$

    # Also search other repos' PROJECT_MEMORY.md if it exists
    for repo_dir in "$WORKSPACE_ROOT"/*/; do
      repo_basename=$(basename "$repo_dir")
      [ "$repo_basename" = "$REPO_NAME" ] && continue
      [ "$repo_basename" = "vault" ] && continue
      [ "$repo_basename" = ".opencode" ] && continue
      [ "$repo_basename" = ".github" ] && continue
      other_memory="$repo_dir/PROJECT_MEMORY.md"
      [ -f "$other_memory" ] || continue

      for word in $KEYWORD_LIST; do
        grep -i "$word" "$other_memory" 2>/dev/null | grep -iv "^(no matching" | head -2
      done | sort -u | head -3 > /tmp/rl-cross-mem.$$ 2>/dev/null || true

      while IFS= read -r line; do
        [ -n "$line" ] && CROSS_PROJECT_LESSONS="${CROSS_PROJECT_LESSONS}  - [$repo_basename] $line\n"
      done < /tmp/rl-cross-mem.$$ 2>/dev/null
      rm -f /tmp/rl-cross-mem.$$
    done
  done

  # Count source repos
  CROSS_PROJECT_REPOS=$(echo "$CROSS_PROJECT_LESSONS" | grep -oE '\[.*?\]' | sort -u | tr '\n' ' ')
fi

# ============================================================
# Check for escalation hints
# ============================================================

ALL_RESULTS="${LESSONS_FOUND}${RISKS_FOUND}${DECISIONS_FOUND}${MEMORY_NOTES}${CROSS_PROJECT_LESSONS}"

if echo "$ALL_RESULTS" | grep -iqE "$ESCALATION_KEYWORDS"; then
  # Extract which escalation keywords were found
  for kw in auth rls payment migration schema secrets crypto deploy production destructive drop delete truncate; do
    if echo "$ALL_RESULTS" | grep -iq "$kw"; then
      ESCALATION_HINTS="${ESCALATION_HINTS}  - Lesson mentions '$kw' — consider escalation or reviewer\n"
    fi
  done
fi

# ============================================================
# Output
# ============================================================

echo "RELEVANT_LESSONS:"

echo "  lessons:"
if [ -n "$LESSONS_FOUND" ]; then
  printf "%b" "$LESSONS_FOUND"
else
  echo "    (no matching lessons found)"
fi

echo "  risks:"
if [ -n "$RISKS_FOUND" ]; then
  printf "%b" "$RISKS_FOUND"
else
  echo "    (no matching risks found)"
fi

echo "  decisions:"
if [ -n "$DECISIONS_FOUND" ]; then
  printf "%b" "$DECISIONS_FOUND"
else
  echo "    (no matching decisions found)"
fi

echo "  memory_notes:"
if [ -n "$MEMORY_NOTES" ]; then
  printf "%b" "$MEMORY_NOTES"
else
  echo "    (no matching memory notes found)"
fi

if [ "$CROSS_PROJECT" = "true" ]; then
  echo "  cross_project_lessons:"
  if [ -n "$CROSS_PROJECT_LESSONS" ]; then
    printf "%b" "$CROSS_PROJECT_LESSONS"
    echo "  source_repos: $CROSS_PROJECT_REPOS"
  else
    echo "    (no cross-project lessons found)"
  fi
fi

echo "  Escalation hints:"
if [ -n "$ESCALATION_HINTS" ]; then
  printf "%b" "$ESCALATION_HINTS"
else
  echo "    (none)"
fi
