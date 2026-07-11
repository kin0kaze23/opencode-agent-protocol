#!/usr/bin/env bash
# Build Code Index (v4.21)
#
# Creates a lightweight, repo-local code index using shell tools.
# No vector DB, no external services. Uses ctags if available, grep fallback.
#
# Usage: bash .opencode/scripts/build-code-index.sh <repo-path>
# Output: <repo-path>/.code-index/
#   files.txt          — source file list
#   symbols.txt        — function/class/component/type declarations
#   routes.txt         — route/page/screen/view files
#   package-scripts.txt — npm/pnpm scripts
#
# The .code-index/ directory should be gitignored. It is ephemeral.

set -uo pipefail

REPO_PATH="${1:-.}"
INDEX_DIR="$REPO_PATH/.code-index"

# Resolve to absolute path for reliable file operations
REPO_ABS="$(cd "$REPO_PATH" && pwd)"
INDEX_DIR="$REPO_ABS/.code-index"

mkdir -p "$INDEX_DIR"

# ============================================================
# 1. File list — source files only, excluding generated dirs
# ============================================================

find "$REPO_ABS" \
  -type f \
  \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
     -o -name "*.py" -o -name "*.rs" -o -name "*.swift" \
     -o -name "*.css" -o -name "*.scss" -o -name "*.vue" -o -name "*.svelte" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  -not -path "*/.next/*" \
  -not -path "*/.turbo/*" \
  -not -path "*/target/*" \
  -not -path "*/__pycache__/*" \
  -not -path "*/.git/*" \
  -not -path "*/.code-index/*" \
  -not -path "*/venv/*" \
  -not -path "*/.venv/*" \
  2>/dev/null \
  | sed "s|$REPO_ABS/||" \
  | sort > "$INDEX_DIR/files.txt"

FILE_COUNT=$(wc -l < "$INDEX_DIR/files.txt" | tr -d ' ')

# ============================================================
# 2. Symbols — ctags if available, grep fallback
# ============================================================

SYMBOLS_FILE="$INDEX_DIR/symbols.txt"
> "$SYMBOLS_FILE"

if command -v ctags &>/dev/null; then
  # ctags: extract function/class/component/type declarations
  ctags -R \
    --fields=+Kzn \
    --output-format=plain \
    -f "$SYMBOLS_FILE" \
    "$REPO_ABS" 2>/dev/null || true

  # If ctags produced empty output, fall back to grep
  if [ ! -s "$SYMBOLS_FILE" ]; then
    while IFS= read -r f; do
      grep -nE '^\s*(export\s+)?(default\s+)?(function|class|const|interface|type|enum)\s+\w+' "$REPO_ABS/$f" 2>/dev/null \
        | sed "s|$REPO_ABS/||" >> "$SYMBOLS_FILE"
    done < "$INDEX_DIR/files.txt"
  fi
else
  # Grep fallback — extract export/function/class/const/type declarations
  while IFS= read -r f; do
    grep -nE '^\s*(export\s+)?(default\s+)?(function|class|const|interface|type|enum)\s+\w+' "$REPO_ABS/$f" 2>/dev/null \
      | sed "s|$REPO_ABS/||" >> "$SYMBOLS_FILE"
  done < "$INDEX_DIR/files.txt"
fi

SYMBOL_COUNT=$(wc -l < "$SYMBOLS_FILE" | tr -d ' ')

# ============================================================
# 3. Routes/pages — detect common patterns
# ============================================================

ROUTES_FILE="$INDEX_DIR/routes.txt"
> "$ROUTES_FILE"

# Match files with route/page/screen/view in path or name
grep -iE '(route|page|screen|view|layout|app/)' "$INDEX_DIR/files.txt" 2>/dev/null \
  | grep -E '\.(tsx|jsx|ts|js|vue|svelte)$' >> "$ROUTES_FILE" || true

# Also match common router patterns (React Router, Next.js, etc.)
grep -E '(router|navigation|navigator|tabbar|sidebar|drawer|modal|dialog)' "$INDEX_DIR/files.txt" 2>/dev/null \
  | grep -E '\.(tsx|jsx|ts|js)$' >> "$ROUTES_FILE" || true

# Deduplicate
sort -u -o "$ROUTES_FILE" "$ROUTES_FILE" 2>/dev/null || true

ROUTE_COUNT=$(wc -l < "$ROUTES_FILE" | tr -d ' ')

# ============================================================
# 4. Package scripts
# ============================================================

SCRIPTS_FILE="$INDEX_DIR/package-scripts.txt"
> "$SCRIPTS_FILE"

if [ -f "$REPO_ABS/package.json" ]; then
  python3 -c "
import json, sys
try:
    with open('$REPO_ABS/package.json') as f:
        pkg = json.load(f)
    scripts = pkg.get('scripts', {})
    for name, cmd in sorted(scripts.items()):
        print(f'{name}: {cmd}')
except Exception:
    pass
" > "$SCRIPTS_FILE" 2>/dev/null || true
fi

SCRIPT_COUNT=$(wc -l < "$SCRIPTS_FILE" | tr -d ' ')

# ============================================================
# 5. Index metadata
# ============================================================

cat > "$INDEX_DIR/meta.txt" << EOF
built: $(date -Iseconds)
repo: $REPO_ABS
files: $FILE_COUNT
symbols: $SYMBOL_COUNT
routes: $ROUTE_COUNT
scripts: $SCRIPT_COUNT
ctags: $(command -v ctags &>/dev/null && echo "yes" || echo "no (grep fallback)")
EOF

# ============================================================
# Output
# ============================================================

echo "Code index built at $INDEX_DIR"
echo "  files: $FILE_COUNT"
echo "  symbols: $SYMBOL_COUNT"
echo "  routes: $ROUTE_COUNT"
echo "  scripts: $SCRIPT_COUNT"
echo "  ctags: $(command -v ctags &>/dev/null && echo "yes" || echo "no (grep fallback)")"
