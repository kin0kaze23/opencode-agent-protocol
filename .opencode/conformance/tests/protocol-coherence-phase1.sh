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

check_json_equals() {
  local file="$1"
  local jq_expr="$2"
  local expected="$3"
  local label="$4"
  local actual
  actual="$(jq -r "$jq_expr" "$file")"
  if [[ "$actual" == "$expected" ]]; then
    printf '[PASS] %s\n' "$label"
    PASS=$((PASS + 1))
  else
    printf '[FAIL] %s\n  expected: %s\n  actual:   %s\n' "$label" "$expected" "$actual"
    FAILED=$((FAILED + 1))
  fi
}

OPENCODE_JSON="$ROOT_DIR/.opencode/opencode.json"
BRAIN_CONFIG="$ROOT_DIR/.opencode/brain-config.json"
AGENTS="$ROOT_DIR/.opencode/AGENTS.md"
HELPER_ROSTER="$ROOT_DIR/.opencode/helper-roster.md"
ANALYZE="$ROOT_DIR/.opencode/commands/analyze.md"
PLAN_FEATURE="$ROOT_DIR/.opencode/commands/plan-feature.md"
IMPLEMENT="$ROOT_DIR/.opencode/commands/implement.md"
REVIEW="$ROOT_DIR/.opencode/commands/review.md"
GATES="$ROOT_DIR/.opencode/commands/gates.md"
NOW="$ROOT_DIR/NOW.md"

printf 'Protocol coherence Phase 1 checks\n'
printf 'Root: %s\n' "$ROOT_DIR"

# v4.20.1: Version checks are now dynamic — read version from brain-config.json
# and verify all surfaces match, rather than hardcoding a specific version.
PROTOCOL_VERSION="$(jq -r '.version' "$BRAIN_CONFIG")"
check_json_equals "$BRAIN_CONFIG" '.version' "$PROTOCOL_VERSION" "brain-config version is v$PROTOCOL_VERSION"
check_contains "$AGENTS" "Protocol: OpenCode v$PROTOCOL_VERSION" "AGENTS banner matches protocol version ($PROTOCOL_VERSION)"
check_contains "$NOW" "$PROTOCOL_VERSION" "NOW documents protocol version ($PROTOCOL_VERSION)"
check_contains "$BRAIN_CONFIG" "v$PROTOCOL_VERSION" "brain-config name includes protocol version ($PROTOCOL_VERSION)"

owner_model="$(jq -r '.model' "$OPENCODE_JSON")"
brain_default="$(jq -r '.default_model' "$BRAIN_CONFIG")"
if [[ "$owner_model" == "$brain_default" ]]; then
  printf '[PASS] Owner model matches brain-config default_model\n'
  PASS=$((PASS + 1))
else
  printf '[FAIL] Owner model mismatch\n  opencode.json: %s\n  brain-config: %s\n' "$owner_model" "$brain_default"
  FAILED=$((FAILED + 1))
fi
check_contains "$HELPER_ROSTER" 'Owner session default' 'helper roster distinguishes Owner default from helper defaults'

for key in context7 exa sequential-thinking github playwright firecrawl; do
  runtime="$(jq -r --arg key "$key" '.mcp[$key].enabled // false' "$OPENCODE_JSON")"
  metadata="$(jq -r --arg key "$key" '.mcp_servers[$key].enabled // false' "$BRAIN_CONFIG")"
  if [[ "$runtime" == "$metadata" ]]; then
    printf '[PASS] MCP %s enabled metadata matches runtime (%s)\n' "$key" "$runtime"
    PASS=$((PASS + 1))
  else
    printf '[FAIL] MCP %s enabled mismatch\n  runtime: %s\n  metadata: %s\n' "$key" "$runtime" "$metadata"
    FAILED=$((FAILED + 1))
  fi
done

# web-tools was deprecated and removed from active config (2026-07-01).
# Skip coherence check — it should be absent from both runtime and metadata.

if jq -e '.mcp.pencil' "$OPENCODE_JSON" >/dev/null; then
  printf '[FAIL] Pencil MCP unexpectedly present in opencode.json\n'
  FAILED=$((FAILED + 1))
else
  check_json_equals "$BRAIN_CONFIG" '.mcp_servers.pencil.enabled' 'false' 'Pencil metadata disabled when runtime MCP is absent'
fi

check_contains "$ANALYZE" 'Product Brief / PRD-lite Gate' '/analyze requires Product Brief gate'
check_contains "$PLAN_FEATURE" 'Product Brief / PRD-lite Gate' '/plan-feature requires Product Brief gate'
check_contains "$PLAN_FEATURE" 'UI Design Brief Gate' '/plan-feature requires UI Design Brief gate'
check_contains "$PLAN_FEATURE" 'Responsive target matrix' '/plan-feature captures responsive target matrix'
check_contains "$PLAN_FEATURE" 'UI state matrix' '/plan-feature captures UI state matrix'
check_contains "$IMPLEMENT" 'verify existing plan artifacts instead of inventing decisions' '/implement verifies existing design artifacts'
check_contains "$IMPLEMENT" 'dev_url' '/implement requires structured browser dev_url'
check_contains "$IMPLEMENT" 'screenshot_path' '/implement requires structured browser screenshot_path'
check_contains "$IMPLEMENT" 'known_visual_risks' '/implement requires known visual risks'
check_contains "$REVIEW" 'Product/UI review pass' '/review requires Product/UI review pass'
check_contains "$REVIEW" 'generic, unpolished, or inconsistent' '/review checks polish/generic output risk'
check_contains "$GATES" 'Structured browser evidence check' '/gates checks structured browser evidence'

printf '\nSummary: %d passed, %d failed\n' "$PASS" "$FAILED"
if [[ "$FAILED" -eq 0 ]]; then
  printf '[PASS] Protocol coherence Phase 1 checks passed.\n'
else
  printf '[FAIL] Protocol coherence Phase 1 checks failed.\n'
fi
exit "$FAILED"
