#!/bin/bash
# public-sync-coverage.sh — Regression test for public-sync validation coverage
#
# Proves that forbidden patterns are detected in brain-config.json and
# model-registry.yaml, and that public templates are sanitized.
# Includes false-negative patterns that escaped the initial sed-based scrub.
#
# Usage: bash .opencode/conformance/tests/public-sync-coverage.sh

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

PASS=0
FAIL=0

pass() { printf '  PASS: %s\n' "$1" PASS=$((PASS + 1)); }
fail() { printf '  FAIL: %s\n' "$1" FAIL=$((FAIL + 1)); }

echo "=== Public Sync Coverage Regression Test ==="

# ── Test 1: brain-config forbidden pattern detection
TEMP_BRAIN=$(mktemp /tmp/brain-test-XXXX.json)
printf '{"default_model":"opencode-go/qwen3.7-plus","project":"nuggie-be","provider":"doppler"}' > "$TEMP_BRAIN"
F=0
for p in "opencode-go/" "nuggie-be" "doppler"; do grep -q "$p" "$TEMP_BRAIN" && F=$((F+1)); done
[ "$F" -ge 3 ] && pass "brain-config: $F forbidden patterns detected" || fail "brain-config: only $F detected"
rm -f "$TEMP_BRAIN"

# ── Test 2: model-registry forbidden pattern detection
TEMP_REG=$(mktemp /tmp/reg-test-XXXX.yaml)
printf 'primary_provider: umans-ai-coding-plan\nsecret_env: OPENCODE_GO_API_KEY\nproject: nuggie-be' > "$TEMP_REG"
F=0
for p in "umans-ai-coding-plan" "OPENCODE_GO_API_KEY" "nuggie-be"; do grep -q "$p" "$TEMP_REG" && F=$((F+1)); done
[ "$F" -ge 3 ] && pass "model-registry: $F forbidden patterns detected" || fail "model-registry: only $F detected"
rm -f "$TEMP_REG"

# ── Test 3: Internal files contain forbidden patterns
BC="$ROOT_DIR/.opencode/brain-config.json"
MR="$ROOT_DIR/.opencode/model-registry.yaml"
[ -f "$BC" ] && { F=0; for p in "opencode-go/" "nuggie-be" "doppler"; do grep -q "$p" "$BC" && F=$((F+1)); done; [ "$F" -gt 0 ] && pass "brain-config.json: internal ($F patterns)" || fail "brain-config.json: expected forbidden patterns"; } || fail "brain-config.json: not found"
[ -f "$MR" ] && { F=0; for p in "umans-ai-coding-plan" "opencode-go/" "nuggie-be"; do grep -q "$p" "$MR" && F=$((F+1)); done; [ "$F" -gt 0 ] && pass "model-registry.yaml: internal ($F patterns)" || fail "model-registry.yaml: expected forbidden patterns"; } || fail "model-registry.yaml: not found"

# ── Test 4: Public templates are sanitized
BT="$ROOT_DIR/.opencode/templates/brain-config.public.json"
RT="$ROOT_DIR/.opencode/templates/model-registry.public.yaml"
OT="$ROOT_DIR/.opencode/templates/opencode.public.json"
[ -f "$BT" ] && { F=0; for p in "opencode-go/" "nuggie-be" "doppler" "umans-ai-coding-plan"; do grep -q "$p" "$BT" && F=$((F+1)); done; [ "$F" -eq 0 ] && pass "brain-config.public.json: sanitized" || fail "brain-config.public.json: $F forbidden patterns"; } || fail "brain-config.public.json: not found"
[ -f "$RT" ] && { F=0; for p in "opencode-go/" "nuggie-be" "doppler" "umans-ai-coding-plan"; do grep -q "$p" "$RT" && F=$((F+1)); done; [ "$F" -eq 0 ] && pass "model-registry.public.yaml: sanitized" || fail "model-registry.public.yaml: $F forbidden patterns"; } || fail "model-registry.public.yaml: not found"
[ -f "$OT" ] && { F=0; for p in "opencode-go/" "nuggie-be" "doppler" "umans-ai-coding-plan"; do grep -q "$p" "$OT" && F=$((F+1)); done; [ "$F" -eq 0 ] && pass "opencode.public.json: sanitized" || fail "opencode.public.json: $F forbidden patterns"; } || fail "opencode.public.json: not found"

# ── Test 5: Manifest exists and declares required files
MN="$ROOT_DIR/.opencode/config/public-sync-manifest.yaml"
[ -f "$MN" ] && { grep -q "brain-config.json" "$MN" && pass "manifest declares brain-config.json" || fail "manifest missing brain-config.json"; grep -q "model-registry.yaml" "$MN" && pass "manifest declares model-registry.yaml" || fail "manifest missing model-registry.yaml"; } || fail "manifest not found"

# ── Test 6: False-negative patterns from initial sed scrub
# These patterns escaped the sed-based sanitization but are caught by public-surface-scan.sh
TEMP_FN=$(mktemp /tmp/false-neg-XXXX.md)
printf 'OpenCode Workspace Protocol — Personal Projects\nWORKSPACE_MAP.md\nvault/projects/\nvault/owner-memory/\nvault/agent-protocols/\nInternal Clean Public Baseline\numans-glm-5.2\numans-coder\numans-flash' > "$TEMP_FN"
F=0
for p in "Personal Projects" "WORKSPACE_MAP" "vault/projects/" "vault/owner-memory/" "vault/agent-protocols/" "Internal Clean Public Baseline" "umans-glm-5.2" "umans-coder" "umans-flash"; do
  grep -q "$p" "$TEMP_FN" && F=$((F+1))
done
[ "$F" -ge 9 ] && pass "false-negative patterns: $F detected" || fail "false-negative patterns: only $F detected"
rm -f "$TEMP_FN"

# ── Test 7: Public-surface-scan.sh exists
[ -f "$ROOT_DIR/scripts/public-surface-scan.sh" ] && pass "public-surface-scan.sh exists" || fail "public-surface-scan.sh not found"

echo ""
echo "PASSED: $PASS  FAILED: $FAIL"
[ "$FAIL" -gt 0 ] && exit 1 || exit 0
