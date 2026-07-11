#!/usr/bin/env bash
# Commit Scope Guard
# Validates that staged files exactly match an expected allowlist.
# Prevents accidental inclusion of unrelated staged files in scoped commits.
#
# Usage:
#   bash .opencode/scripts/commit-scope-guard.sh --allowed <file1> [<file2> ...]
#
# Exit codes:
#   0 - PASS: staged files exactly match allowlist
#   1 - FAIL: extra or missing staged files
#   2 - ERROR: invalid arguments, not a git repo, or git command failure
#
# This script is read-only and does not modify git state.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}=== Commit Scope Guard ===${NC}"
echo ""

# Parse arguments
if [[ $# -eq 0 ]]; then
  echo -e "${RED}ERROR: No arguments provided${NC}"
  echo ""
  echo "Usage:"
  echo "  bash .opencode/scripts/commit-scope-guard.sh --allowed <file1> [<file2> ...]"
  echo ""
  echo "Exit codes:"
  echo "  0 - PASS: staged files exactly match allowlist"
  echo "  1 - FAIL: extra or missing staged files"
  echo "  2 - ERROR: invalid arguments, not a git repo, or git command failure"
  exit 2
fi

if [[ "$1" != "--allowed" ]]; then
  echo -e "${RED}ERROR: First argument must be --allowed${NC}"
  echo ""
  echo "Usage:"
  echo "  bash .opencode/scripts/commit-scope-guard.sh --allowed <file1> [<file2> ...]"
  exit 2
fi

shift

if [[ $# -eq 0 ]]; then
  echo -e "${RED}ERROR: No files provided after --allowed${NC}"
  echo ""
  echo "Usage:"
  echo "  bash .opencode/scripts/commit-scope-guard.sh --allowed <file1> [<file2> ...]"
  exit 2
fi

# Store allowed files in array
declare -a ALLOWED_FILES=("$@")

# Verify we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${RED}ERROR: Not a git repository${NC}"
  exit 2
fi

# Get staged files
declare -a STAGED_FILES=()
while IFS= read -r line; do
  [[ -n "$line" ]] && STAGED_FILES+=("$line")
done < <(git diff --cached --name-only 2>/dev/null) || {
  echo -e "${RED}ERROR: Failed to get staged files${NC}"
  exit 2
}

# Print expected files
echo "Expected files:"
for file in "${ALLOWED_FILES[@]}"; do
  echo "  - $file"
done
echo ""

# Handle zero staged files
if [[ ${#STAGED_FILES[@]} -eq 0 ]] || [[ -z "${STAGED_FILES[0]}" ]]; then
  echo -e "${YELLOW}Staged files:${NC}"
  echo "  (none)"
  echo ""
  echo -e "${RED}Result: FAIL${NC}"
  echo ""
  echo -e "${YELLOW}Missing files:${NC}"
  for file in "${ALLOWED_FILES[@]}"; do
    echo "  - $file"
  done
  echo ""
  echo "Remediation:"
  echo "  Stage the expected files:"
  for file in "${ALLOWED_FILES[@]}"; do
    echo "    git add $file"
  done
  exit 1
fi

# Print staged files
echo "Staged files:"
for file in "${STAGED_FILES[@]}"; do
  echo "  - $file"
done
echo ""

# Sort and deduplicate both lists for comparison
declare -a ALLOWED_SORTED=()
while IFS= read -r line; do
  [[ -n "$line" ]] && ALLOWED_SORTED+=("$line")
done < <(printf '%s\n' "${ALLOWED_FILES[@]}" | sort -u)

declare -a STAGED_SORTED=()
while IFS= read -r line; do
  [[ -n "$line" ]] && STAGED_SORTED+=("$line")
done < <(printf '%s\n' "${STAGED_FILES[@]}" | sort -u)

# Find extra files (in staged but not in allowed)
declare -a EXTRA_FILES=()
for staged in "${STAGED_SORTED[@]}"; do
  found=false
  for allowed in "${ALLOWED_SORTED[@]}"; do
    if [[ "$staged" == "$allowed" ]]; then
      found=true
      break
    fi
  done
  if [[ "$found" == "false" ]]; then
    EXTRA_FILES+=("$staged")
  fi
done

# Find missing files (in allowed but not in staged)
declare -a MISSING_FILES=()
for allowed in "${ALLOWED_SORTED[@]}"; do
  found=false
  for staged in "${STAGED_SORTED[@]}"; do
    if [[ "$allowed" == "$staged" ]]; then
      found=true
      break
    fi
  done
  if [[ "$found" == "false" ]]; then
    MISSING_FILES+=("$allowed")
  fi
done

# Determine result
if [[ ${#EXTRA_FILES[@]} -eq 0 ]] && [[ ${#MISSING_FILES[@]} -eq 0 ]]; then
  echo -e "${GREEN}Result: PASS${NC}"
  echo ""
  echo "Staged files exactly match expected files."
  exit 0
else
  echo -e "${RED}Result: FAIL${NC}"
  echo ""

  if [[ ${#EXTRA_FILES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Extra files staged:${NC}"
    for file in "${EXTRA_FILES[@]}"; do
      echo "  - $file"
    done
    echo ""
  fi

  if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Missing files:${NC}"
    for file in "${MISSING_FILES[@]}"; do
      echo "  - $file"
    done
    echo ""
  fi

  echo "Remediation:"
  if [[ ${#EXTRA_FILES[@]} -gt 0 ]]; then
    echo "  Unstage unrelated files:"
    for file in "${EXTRA_FILES[@]}"; do
      echo "    git restore --staged $file"
    done
    echo ""
  fi

  if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
    echo "  Stage missing files:"
    for file in "${MISSING_FILES[@]}"; do
      echo "    git add $file"
    done
    echo ""
  fi

  echo "  Or update the allowlist to include these files if they should be committed."
  exit 1
fi
