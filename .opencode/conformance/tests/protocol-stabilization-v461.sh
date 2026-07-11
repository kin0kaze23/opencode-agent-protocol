#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"

FAILED=0
PASS=0

check_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -Fq "$pattern" "$file"; then
    printf '[PASS] %s\n' "$label"
    PASS=$((PASS + 1))
  else
    printf '[FAIL] %s\n  missing: %s in %s\n' "$label" "$pattern" "$file"
    FAILED=$((FAILED + 1))
  fi
}

check_file_exists() {
  local file="$1"
  local label="$2"
  if [[ -f "$file" ]]; then
    printf '[PASS] %s\n' "$label"
    PASS=$((PASS + 1))
  else
    printf '[FAIL] %s\n  missing file: %s\n' "$label" "$file"
    FAILED=$((FAILED + 1))
  fi
}

BRAIN_CONFIG="$ROOT_DIR/.opencode/brain-config.json"
AGENTS="$ROOT_DIR/.opencode/AGENTS.md"
RULES="$ROOT_DIR/.opencode/rules.md"
GATES="$ROOT_DIR/.opencode/commands/gates.md"
IMPLEMENT="$ROOT_DIR/.opencode/commands/implement.md"
REVIEW="$ROOT_DIR/.opencode/commands/review.md"
SHIP="$ROOT_DIR/.opencode/commands/ship.md"
PREFLIGHT="$ROOT_DIR/.opencode/scripts/browser-verification-preflight.sh"

printf 'OpenCode v4.6.1 stabilization checks\n'
printf 'Root: %s\n' "$ROOT_DIR"

for label in TARGETED_FAILURE BROAD_BASELINE_FAILURE FLAKY_OR_INFRA_FAILURE NOT_RUN ACCEPTED_NON_BLOCKING BLOCKING_UNKNOWN; do
  check_contains "$RULES" "$label" "Rules define $label"
  check_contains "$GATES" "$label" "/gates emits $label"
  check_contains "$BRAIN_CONFIG" "$label" "brain-config metadata includes $label"
done

check_contains "$AGENTS" 'Gate classifications' 'Completion summary requires gate classifications'
check_contains "$AGENTS" 'Dirty workspace inventory' 'Completion summary requires dirty workspace inventory'
check_contains "$AGENTS" 'Browser route preflight' 'Completion summary requires browser route preflight'
check_contains "$IMPLEMENT" 'Dirty workspace inventory' '/implement requires dirty workspace inventory'
check_contains "$REVIEW" 'Dirty workspace inventory' '/review checks dirty workspace inventory'
check_contains "$SHIP" 'dirty workspace inventory' '/ship reports dirty workspace inventory'

check_contains "$GATES" 'Browser route preflight' '/gates documents browser route preflight'
check_contains "$GATES" 'Python Playwright' '/gates documents Python Playwright fallback'
check_contains "$GATES" 'agent-browser' '/gates documents agent-browser state'
check_contains "$IMPLEMENT" 'browser route preflight' '/implement runs browser route preflight before browser evidence'
check_file_exists "$PREFLIGHT" 'browser verification preflight script exists'
check_contains "$PREFLIGHT" 'Playwright MCP' 'preflight checks Playwright MCP state'
check_contains "$PREFLIGHT" 'Python Playwright' 'preflight checks Python Playwright state'
check_contains "$PREFLIGHT" 'agent-browser' 'preflight checks agent-browser state'
check_contains "$PREFLIGHT" 'do not install or enable dependencies without owner approval' 'preflight avoids unapproved installs'

check_contains "$IMPLEMENT" 'dev_url' 'structured browser evidence still requires dev_url'
check_contains "$IMPLEMENT" 'screenshot_path' 'structured browser evidence still requires screenshot_path'
check_contains "$IMPLEMENT" 'known_visual_risks' 'structured browser evidence still requires known_visual_risks'

printf '\nSummary: %d passed, %d failed\n' "$PASS" "$FAILED"
if [[ "$FAILED" -eq 0 ]]; then
  printf '[PASS] v4.6.1 stabilization checks passed.\n'
else
  printf '[FAIL] v4.6.1 stabilization checks failed.\n'
fi
exit "$FAILED"
