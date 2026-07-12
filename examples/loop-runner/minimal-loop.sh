#!/usr/bin/env bash
# examples/loop-runner/minimal-loop.sh
#
# Illustrative loop runner showing the Plan → Act → Verify pattern.
# This is NOT a production autonomous agent. It demonstrates the loop concept.
#
# What it does:
#   1. Reads a goal from GOAL.md
#   2. Shows a plan placeholder
#   3. Runs a verification check
#   4. Stops on failure
#   5. Asks for human review before "merge"
#
# What it does NOT do:
#   - Call real model APIs
#   - Mutate arbitrary files
#   - Bypass human review
#   - Imply fully autonomous safety
#
# Usage: bash examples/loop-runner/minimal-loop.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GOAL_FILE="$ROOT_DIR/loop-runner/GOAL.md"
STATE_FILE="$ROOT_DIR/loop-runner/STATE.md"
MAX_ITERATIONS=3

echo "=== Minimal Loop Runner (Illustrative) ==="
echo ""

# ─────────────────────────────────────────────────────────────
# Step 1: Read goal
# ─────────────────────────────────────────────────────────────
echo "--- Step 1: Read Goal ---"
if [ ! -f "$GOAL_FILE" ]; then
  echo "No GOAL.md found. Creating a template..."
  cat > "$GOAL_FILE" << 'GOAL_TEMPLATE'
# Goal

Describe what "done" looks like here.

# Done When
- [ ] Condition 1
- [ ] Condition 2

# Never Touch
- file/you/must/not/edit
GOAL_TEMPLATE
  echo "Created GOAL.md template. Edit it and re-run."
  exit 0
fi

echo "Goal loaded from GOAL.md"
cat "$GOAL_FILE"
echo ""

# ─────────────────────────────────────────────────────────────
# Step 2: Plan (placeholder — real loop would call model here)
# ─────────────────────────────────────────────────────────────
echo "--- Step 2: Plan ---"
echo "In a real setup, the orchestrator would:"
echo "  1. Classify risk (DIRECT/FAST/STANDARD/HIGH-RISK)"
echo "  2. Select lane"
echo "  3. Create touch list"
echo "  4. Define success criteria"
echo "  5. Define rollback path"
echo ""

# Write state
cat > "$STATE_FILE" << 'STATE_TEMPLATE'
# Loop State

## Current Iteration: 1
## Status: planning

## What was done:
- (placeholder — real loop records actual actions here)

## What is next:
- Verify the plan against the goal spec
STATE_TEMPLATE
echo "State written to STATE.md"
echo ""

# ─────────────────────────────────────────────────────────────
# Step 3: Act (placeholder — real loop would implement here)
# ─────────────────────────────────────────────────────────────
echo "--- Step 3: Act ---"
echo "In a real setup, the implementer would:"
echo "  1. Make bounded code changes within the touch list"
echo "  2. Run lint/typecheck/test as it goes"
echo "  3. Commit with conventional message"
echo ""

# ─────────────────────────────────────────────────────────────
# Step 4: Verify
# ─────────────────────────────────────────────────────────────
echo "--- Step 4: Verify ---"
echo "Running validation checks..."

VERIFY_PASS=true

# Run privacy scan if available
if [ -f "$ROOT_DIR/../scripts/public-surface-scan.sh" ]; then
  echo "  Running public-surface-scan..."
  if bash "$ROOT_DIR/../scripts/public-surface-scan.sh" > /dev/null 2>&1; then
    echo "  Privacy scan: PASS"
  else
    echo "  Privacy scan: FAIL"
    VERIFY_PASS=false
  fi
fi

# Run docs drift if available
if [ -f "$ROOT_DIR/../scripts/validate-docs-drift.sh" ]; then
  echo "  Running docs drift validation..."
  if bash "$ROOT_DIR/../scripts/validate-docs-drift.sh" > /dev/null 2>&1; then
    echo "  Docs drift: PASS"
  else
    echo "  Docs drift: FAIL"
    VERIFY_PASS=false
  fi
fi

echo ""

# ─────────────────────────────────────────────────────────────
# Step 5: Stop on failure
# ─────────────────────────────────────────────────────────────
if [ "$VERIFY_PASS" = false ]; then
  echo "--- Step 5: STOP (verification failed) ---"
  echo "Verification failed. In a real loop:"
  echo "  1. The repair step would fix the failure"
  echo "  2. Verify would re-run (max 2 repair cycles)"
  echo "  3. If still failing, the loop stops and asks for human help"
  echo ""
  echo "State written to STATE.md"
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# Step 6: Ask for human review before merge
# ─────────────────────────────────────────────────────────────
echo "--- Step 5: Human Review Required ---"
echo ""
echo "Verification passed. Before merging:"
echo "  1. Review the diff manually"
echo "  2. Check for files not on the touch list"
echo "  3. Confirm the goal spec is satisfied"
echo "  4. Approve the PR"
echo ""
echo "In a real setup, this is where:"
echo "  - CI runs all 10 matrix checks (Ubuntu + macOS)"
echo "  - Branch protection blocks merge until all checks pass"
echo "  - HIGH-RISK changes require independent reviewer approval"
echo ""
echo "=== Loop Complete ==="
echo ""
echo "This was an illustrative loop. It did NOT:"
echo "  - Call any model API"
echo "  - Make any code changes"
echo "  - Merge anything"
echo ""
echo "To see the real protocol in action, follow:"
echo "  - docs/PROGRESSIVE_ONBOARDING.md"
echo "  - docs/FIRST_RUN_CHECKLIST.md"
