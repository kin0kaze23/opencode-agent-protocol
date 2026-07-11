#!/usr/bin/env bash
# Find Tests (v4.23)
#
# Discovers nearby test files for changed source files.
# Detects test framework, test commands, and coverage status.
#
# Usage: bash .opencode/scripts/find-tests.sh <repo-path> <changed-file-1> [changed-file-2...]
# Example: bash .opencode/scripts/find-tests.sh protected-repo-prod src/components/GrowthChart.tsx
#
# Output:
#   TEST_DISCOVERY:
#     framework: vitest
#     test_command: pnpm test
#     changed_files:
#       - src/components/GrowthChart.tsx
#     nearby_tests:
#       - src/components/GrowthChart.test.tsx
#       - src/components/__tests__/GrowthChart.test.ts
#     coverage_status:
#       - src/components/GrowthChart.tsx: covered (direct test found)
#     missing_tests:
#       - (none — all changed files have nearby tests)
#     notes:
#       - vitest configured in package.json
#       - Run: pnpm test -- --grep GrowthChart for targeted tests

set -uo pipefail

REPO_PATH="${1:-.}"
shift
CHANGED_FILES=("$@")

if [ ${#CHANGED_FILES[@]} -eq 0 ]; then
  echo "Usage: find-tests.sh <repo-path> <changed-file-1> [changed-file-2...]"
  exit 1
fi

REPO_ABS="$(cd "$REPO_PATH" 2>/dev/null && pwd || echo "$REPO_PATH")"

# ============================================================
# Detect test framework
# ============================================================

FRAMEWORK="unknown"
TEST_CMD="unknown"

if [ -f "$REPO_ABS/package.json" ]; then
  # Check devDependencies for test frameworks
  HAS_VITEST=$(jq -r '.devDependencies.vitest // empty' "$REPO_ABS/package.json" 2>/dev/null)
  HAS_JEST=$(jq -r '.devDependencies.jest // .devDependencies["@jest/core"] // empty' "$REPO_ABS/package.json" 2>/dev/null)
  HAS_PLAYWRIGHT=$(jq -r '.devDependencies["@playwright/test"] // empty' "$REPO_ABS/package.json" 2>/dev/null)
  HAS_MOCHA=$(jq -r '.devDependencies.mocha // empty' "$REPO_ABS/package.json" 2>/dev/null)

  # Detect package manager
  if [ -f "$REPO_ABS/pnpm-lock.yaml" ]; then
    PM="pnpm"
  elif [ -f "$REPO_ABS/bun.lock" ] || [ -f "$REPO_ABS/bun.lockb" ]; then
    PM="bun"
  elif [ -f "$REPO_ABS/yarn.lock" ]; then
    PM="yarn"
  else
    PM="npm"
  fi

  if [ -n "$HAS_VITEST" ]; then
    FRAMEWORK="vitest"
  elif [ -n "$HAS_JEST" ]; then
    FRAMEWORK="jest"
  elif [ -n "$HAS_PLAYWRIGHT" ]; then
    FRAMEWORK="playwright"
  elif [ -n "$HAS_MOCHA" ]; then
    FRAMEWORK="mocha"
  fi

  # Detect test command from scripts
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
  FRAMEWORK="cargo"
  TEST_CMD="cargo test"
elif [ -f "$REPO_ABS/requirements.txt" ] || [ -f "$REPO_ABS/pyproject.toml" ]; then
  FRAMEWORK="pytest"
  TEST_CMD="pytest"
elif [ -f "$REPO_ABS/go.mod" ]; then
  FRAMEWORK="go"
  TEST_CMD="go test ./..."
fi

# ============================================================
# Find nearby test files for each changed file
# ============================================================

NEARBY_TESTS=""
COVERAGE_STATUS=""
MISSING_TESTS=""

for changed_file in "${CHANGED_FILES[@]}"; do
  # Strip repo path prefix for matching
  rel_file="${changed_file#$REPO_ABS/}"
  rel_file="${rel_file#./}"

  # Skip test files themselves — they don't need their own tests
  if echo "$rel_file" | grep -qE '\.(test|spec)\.'; then
    COVERAGE_STATUS="${COVERAGE_STATUS}  - $rel_file: test file (no separate test needed)\n"
    continue
  fi

  # Skip non-source files
  if ! echo "$rel_file" | grep -qE '\.(ts|tsx|js|jsx|py|rs|go)$'; then
    continue
  fi

  # Extract base name without extension
  base_name=$(basename "$rel_file")
  dir_name=$(dirname "$rel_file")
  stem="${base_name%.*}"

  found_test=""

  # Pattern 1: Same directory, *.test.* or *.spec.*
  for pattern in ".test." ".spec."; do
    test_file="$REPO_ABS/$dir_name/${stem}${pattern}${base_name#*.}"
    # Handle .ts -> .test.ts, .tsx -> .test.tsx
    ext="${base_name##*.}"
    test_file="$REPO_ABS/$dir_name/${stem}${pattern}${ext}"
    if [ -f "$test_file" ]; then
      found_test="$dir_name/${stem}${pattern}${ext}"
      break
    fi
  done

  # Pattern 2: __tests__/ directory in same or parent directory
  if [ -z "$found_test" ]; then
    for test_dir in "__tests__" "tests" "test"; do
      # Same directory
      for pattern in ".test." ".spec." "."; do
        ext="${base_name##*.}"
        test_file="$REPO_ABS/$dir_name/$test_dir/${stem}${pattern}${ext}"
        if [ -f "$test_file" ]; then
          found_test="$dir_name/$test_dir/${stem}${pattern}${ext}"
          break
        fi
      done
      [ -n "$found_test" ] && break

      # Parent directory
      parent_dir=$(dirname "$dir_name")
      for pattern in ".test." ".spec." "."; do
        ext="${base_name##*.}"
        test_file="$REPO_ABS/$parent_dir/$test_dir/${stem}${pattern}${ext}"
        if [ -f "$test_file" ]; then
          found_test="$parent_dir/$test_dir/${stem}${pattern}${ext}"
          break
        fi
      done
      [ -n "$found_test" ] && break
    done
  fi

  # Pattern 3: Root-level tests/ or e2e/ directory
  if [ -z "$found_test" ]; then
    for test_dir in "tests" "test" "e2e" "__tests__"; do
      for pattern in ".test." ".spec." "."; do
        ext="${base_name##*.}"
        test_file="$REPO_ABS/$test_dir/${stem}${pattern}${ext}"
        if [ -f "$test_file" ]; then
          found_test="$test_dir/${stem}${pattern}${ext}"
          break
        fi
      done
      [ -n "$found_test" ] && break
    done
  fi

  if [ -n "$found_test" ]; then
    NEARBY_TESTS="${NEARBY_TESTS}  - $found_test\n"
    COVERAGE_STATUS="${COVERAGE_STATUS}  - $rel_file: covered (direct test found)\n"
  else
    MISSING_TESTS="${MISSING_TESTS}  - $rel_file: no nearby test found\n"
    COVERAGE_STATUS="${COVERAGE_STATUS}  - $rel_file: uncovered (no nearby test)\n"
  fi
done

# ============================================================
# Output
# ============================================================

echo "TEST_DISCOVERY:"
echo "  framework: $FRAMEWORK"
echo "  test_command: $TEST_CMD"
echo "  changed_files:"
for f in "${CHANGED_FILES[@]}"; do
  rel="${f#$REPO_ABS/}"
  rel="${rel#./}"
  echo "    - $rel"
done

echo "  nearby_tests:"
if [ -n "$NEARBY_TESTS" ]; then
  printf "%b" "$NEARBY_TESTS"
else
  echo "    (no nearby tests found)"
fi

echo "  coverage_status:"
if [ -n "$COVERAGE_STATUS" ]; then
  printf "%b" "$COVERAGE_STATUS"
else
  echo "    (no source files to check)"
fi

echo "  missing_tests:"
if [ -n "$MISSING_TESTS" ]; then
  printf "%b" "$MISSING_TESTS"
else
  echo "    (none — all changed files have nearby tests)"
fi

echo "  notes:"
if [ "$FRAMEWORK" != "unknown" ]; then
  echo "    - $FRAMEWORK configured in project"
  if [ "$TEST_CMD" != "unknown" ]; then
    # Suggest targeted test command
    echo "    - Run: $TEST_CMD for full suite"
    # Suggest grep-based targeted run if vitest/jest
    if [ "$FRAMEWORK" = "vitest" ] || [ "$FRAMEWORK" = "jest" ]; then
      FIRST_STEM=$(basename "${CHANGED_FILES[0]}" | sed 's/\..*//')
      echo "    - Run: $TEST_CMD -- --grep $FIRST_STEM for targeted tests"
    fi
  fi
else
  echo "    - No test framework detected"
fi
