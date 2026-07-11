#!/usr/bin/env bash
# Detect Untested Code (v4.25)
#
# Inspects changed source files and reports exported functions/components/classes
# that lack nearby test coverage. Suggests test file paths and commands.
#
# Usage: bash .opencode/scripts/detect-untested.sh <repo-path> <changed-file-1> [changed-file-2...]
# Example: bash .opencode/scripts/detect-untested.sh protected-repo-prod src/components/GrowthChart.tsx
#
# Output:
#   UNTESTED_ANALYSIS:
#     framework: vitest
#     test_command: pnpm test
#     changed_files:
#       - src/components/GrowthChart.tsx
#     exported_symbols:
#       - src/components/GrowthChart.tsx: GrowthChart (component)
#       - src/components/GrowthChart.tsx: calculatePercentile (function)
#     nearby_tests:
#       - (none found)
#     missing_coverage:
#       - src/components/GrowthChart.tsx: GrowthChart — no test found
#       - src/components/GrowthChart.tsx: calculatePercentile — no test found
#     suggested_test_files:
#       - src/components/GrowthChart.test.tsx
#     recommended_test_command: pnpm test -- --grep GrowthChart
#     change_type_hint: (agent should classify: bug-fix / logic-change / refactor / ui-only / config)

set -uo pipefail

REPO_PATH="${1:-.}"
shift
CHANGED_FILES=("$@")

if [ ${#CHANGED_FILES[@]} -eq 0 ]; then
  echo "Usage: detect-untested.sh <repo-path> <changed-file-1> [changed-file-2...]"
  exit 1
fi

REPO_ABS="$(cd "$REPO_PATH" 2>/dev/null && pwd || echo "$REPO_PATH")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================================
# Detect test framework and command (reuse find-tests.sh logic)
# ============================================================

FRAMEWORK="unknown"
TEST_CMD="unknown"

if [ -f "$REPO_ABS/package.json" ]; then
  HAS_VITEST=$(jq -r '.devDependencies.vitest // empty' "$REPO_ABS/package.json" 2>/dev/null)
  HAS_JEST=$(jq -r '.devDependencies.jest // .devDependencies["@jest/core"] // empty' "$REPO_ABS/package.json" 2>/dev/null)
  HAS_PLAYWRIGHT=$(jq -r '.devDependencies["@playwright/test"] // empty' "$REPO_ABS/package.json" 2>/dev/null)

  if [ -f "$REPO_ABS/pnpm-lock.yaml" ]; then PM="pnpm"
  elif [ -f "$REPO_ABS/bun.lock" ] || [ -f "$REPO_ABS/bun.lockb" ]; then PM="bun"
  elif [ -f "$REPO_ABS/yarn.lock" ]; then PM="yarn"
  else PM="npm"; fi

  if [ -n "$HAS_VITEST" ]; then FRAMEWORK="vitest"
  elif [ -n "$HAS_JEST" ]; then FRAMEWORK="jest"
  elif [ -n "$HAS_PLAYWRIGHT" ]; then FRAMEWORK="playwright"; fi

  TEST_SCRIPT=$(jq -r '.scripts.test // empty' "$REPO_ABS/package.json" 2>/dev/null)
  if [ -n "$TEST_SCRIPT" ]; then
    case $PM in
      pnpm) TEST_CMD="pnpm test" ;;
      npm) TEST_CMD="npm test" ;;
      yarn) TEST_CMD="yarn test" ;;
      bun) TEST_CMD="bun test" ;;
    esac
  fi
elif [ -f "$REPO_ABS/Cargo.toml" ]; then
  FRAMEWORK="cargo"; TEST_CMD="cargo test"
elif [ -f "$REPO_ABS/requirements.txt" ] || [ -f "$REPO_ABS/pyproject.toml" ]; then
  FRAMEWORK="pytest"; TEST_CMD="pytest"
fi

# ============================================================
# Analyze each changed file
# ============================================================

EXPORTED_SYMBOLS=""
NEARBY_TESTS=""
MISSING_COVERAGE=""
SUGGESTED_TESTS=""

for changed_file in "${CHANGED_FILES[@]}"; do
  rel_file="${changed_file#$REPO_ABS/}"
  rel_file="${rel_file#./}"

  # Skip non-source files
  if ! echo "$rel_file" | grep -qE '\.(ts|tsx|js|jsx|py|rs|go)$'; then
    continue
  fi

  # Skip test files themselves
  if echo "$rel_file" | grep -qE '\.(test|spec)\.'; then
    continue
  fi

  file_abs="$REPO_ABS/$rel_file"
  [ -f "$file_abs" ] || continue

  base_name=$(basename "$rel_file")
  dir_name=$(dirname "$rel_file")
  stem="${base_name%.*}"
  ext="${base_name##*.}"

  # --- Extract exported symbols ---
  # Match: export function X, export const X, export class X, export default function X, export interface X
  symbols=$(grep -nE '^\s*export\s+(default\s+)?(function|const|class|interface|type|enum)\s+\w+' "$file_abs" 2>/dev/null || true)

  if [ -n "$symbols" ]; then
    while IFS= read -r sym_line; do
      [ -n "$sym_line" ] || continue
      # Extract symbol name and type
      sym_name=$(echo "$sym_line" | sed -n 's/.*export\s*\(default\s*\)\?\(function\|const\|class\|interface\|type\|enum\)\s\+\([A-Za-z_][A-Za-z0-9_]*\).*/\3/p')
      sym_type=$(echo "$sym_line" | sed -n 's/.*export\s*\(default\s*\)\?\(function\|const\|class\|interface\|type\|enum\)\s\+\([A-Za-z_][A-Za-z0-9_]*\).*/\2/p')

      if [ -n "$sym_name" ]; then
        # Capitalized name = likely component
        if echo "$sym_name" | grep -qE '^[A-Z]'; then
          sym_type="component"
        fi

        EXPORTED_SYMBOLS="${EXPORTED_SYMBOLS}  - $rel_file: $sym_name ($sym_type)\n"

        # --- Check if this symbol has test coverage ---
        # Look for the symbol name in nearby test files
        found_coverage=false

        # Check same-directory test files
        for pattern in ".test." ".spec."; do
          test_file="$REPO_ABS/$dir_name/${stem}${pattern}${ext}"
          if [ -f "$test_file" ] && grep -q "$sym_name" "$test_file" 2>/dev/null; then
            found_coverage=true
            NEARBY_TESTS="${NEARBY_TESTS}  - $dir_name/${stem}${pattern}${ext} (covers $sym_name)\n"
            break
          fi
        done

        # Check __tests__ directories
        if [ "$found_coverage" = "false" ]; then
          for test_dir in "__tests__" "tests" "test"; do
            for pattern in ".test." ".spec." "."; do
              test_file="$REPO_ABS/$dir_name/$test_dir/${stem}${pattern}${ext}"
              if [ -f "$test_file" ] && grep -q "$sym_name" "$test_file" 2>/dev/null; then
                found_coverage=true
                NEARBY_TESTS="${NEARBY_TESTS}  - $dir_name/$test_dir/${stem}${pattern}${ext} (covers $sym_name)\n"
                break 2
              fi
            done
          done
        fi

        # Check root-level test directories
        if [ "$found_coverage" = "false" ]; then
          for test_dir in "tests" "test" "e2e" "__tests__"; do
            for pattern in ".test." ".spec." "."; do
              test_file="$REPO_ABS/$test_dir/${stem}${pattern}${ext}"
              if [ -f "$test_file" ] && grep -q "$sym_name" "$test_file" 2>/dev/null; then
                found_coverage=true
                NEARBY_TESTS="${NEARBY_TESTS}  - $test_dir/${stem}${pattern}${ext} (covers $sym_name)\n"
                break 2
              fi
            done
          done
        fi

        if [ "$found_coverage" = "false" ]; then
          MISSING_COVERAGE="${MISSING_COVERAGE}  - $rel_file: $sym_name — no test found\n"
        fi
      fi
    done <<< "$symbols"
  fi

  # --- Suggest test file path if no test exists ---
  test_exists=false
  for pattern in ".test." ".spec."; do
    if [ -f "$REPO_ABS/$dir_name/${stem}${pattern}${ext}" ]; then
      test_exists=true
      break
    fi
  done

  if [ "$test_exists" = "false" ]; then
    SUGGESTED_TESTS="${SUGGESTED_TESTS}  - $dir_name/${stem}.test.${ext}\n"
  fi
done

# ============================================================
# Output
# ============================================================

echo "UNTESTED_ANALYSIS:"
echo "  framework: $FRAMEWORK"
echo "  test_command: $TEST_CMD"
echo "  changed_files:"
for f in "${CHANGED_FILES[@]}"; do
  rel="${f#$REPO_ABS/}"
  rel="${rel#./}"
  echo "    - $rel"
done

echo "  exported_symbols:"
if [ -n "$EXPORTED_SYMBOLS" ]; then
  printf "%b" "$EXPORTED_SYMBOLS"
else
  echo "    (no exported symbols found in changed files)"
fi

echo "  nearby_tests:"
if [ -n "$NEARBY_TESTS" ]; then
  printf "%b" "$NEARBY_TESTS"
else
  echo "    (no nearby tests found)"
fi

echo "  missing_coverage:"
if [ -n "$MISSING_COVERAGE" ]; then
  printf "%b" "$MISSING_COVERAGE"
else
  echo "    (none — all exported symbols have test coverage)"
fi

echo "  suggested_test_files:"
if [ -n "$SUGGESTED_TESTS" ]; then
  printf "%b" "$SUGGESTED_TESTS"
else
  echo "    (test files already exist for all changed files)"
fi

echo "  recommended_test_command: $TEST_CMD"
echo "  change_type_hint: (agent should classify: bug-fix / logic-change / refactor / ui-only / config)"
