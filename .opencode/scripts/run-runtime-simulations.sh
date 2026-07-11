#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SIM_DIR="$ROOT_DIR/.opencode/benchmarks/simulations"
AGENTS="$ROOT_DIR/.opencode/AGENTS.md"
BRAIN="$ROOT_DIR/.opencode/brain-config.json"
IMPLEMENT="$ROOT_DIR/.opencode/commands/implement.md"
GATES="$ROOT_DIR/.opencode/commands/gates.md"
DEBUG="$ROOT_DIR/.opencode/commands/debug.md"

check_contains() {
  local file="$1"
  local pattern="$2"
  grep -q "$pattern" "$file"
}

assert_case() {
  local name="$1"
  local ok=1
  local file="$SIM_DIR/$name.md"
  [ -f "$file" ] || { echo "FAIL $name missing"; return 1; }

  case "$name" in
    FAST-001)
      check_contains "$AGENTS" "FAST Lane Abbreviated Preflight" || ok=0
      check_contains "$BRAIN" "\"field_count\": 8" || ok=0
      ;;
    STANDARD-001)
      check_contains "$IMPLEMENT" "Reads" || ok=0
      check_contains "$IMPLEMENT" "PLAN.md" || ok=0
      check_contains "$BRAIN" "\"approval_batching\"" || ok=0
      check_contains "$BRAIN" "\"allowed_steps\": \\[\"/implement\", \"/gates\", \"/review\", \"/checkpoint\"\\]" || ok=0
      ;;
    HIGH-RISK-001)
      check_contains "$BRAIN" "\"forced_high_risk\"" || ok=0
      check_contains "$GATES" "stateful-sensitive" || ok=0
      check_contains "$GATES" "scoped SAST when required" || ok=0
      ;;
    DEBUG-001)
      check_contains "$DEBUG" "Forms 2-4 ranked falsifiable hypotheses" || ok=0
      check_contains "$DEBUG" "Max 12 shell commands before a summary" || ok=0
      ;;
    *)
      echo "FAIL $name unknown"
      return 1
      ;;
  esac

  if [ "$ok" -eq 1 ]; then
    echo "PASS $name"
    return 0
  fi

  echo "FAIL $name"
  return 1
}

pass=0
fail=0

for sim in "$SIM_DIR"/*.md; do
  name="$(basename "$sim" .md)"
  if assert_case "$name"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
  fi
done

echo ""
echo "Runtime simulations summary: pass=$pass fail=$fail"

if [ "$fail" -gt 0 ]; then
  exit 1
fi
