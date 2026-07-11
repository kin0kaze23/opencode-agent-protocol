#!/bin/bash
# bootstrap-opencode.sh — Check prerequisites and verify workspace structure
# Usage: bash scripts/bootstrap-opencode.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
WARN=0

pass() { printf '  \033[0;32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
warn() { printf '  \033[0;33m⚠\033[0m %s\n' "$1"; WARN=$((WARN + 1)); }

echo "=========================================="
echo "OpenCode Protocol Bootstrap"
echo "=========================================="
echo "Root: $ROOT_DIR"
echo ""

# Check required tools
echo "== Required Tools =="
for tool in git node pnpm python3 jq; do
  if command -v "$tool" >/dev/null 2>&1; then
    version=$("$tool" --version 2>&1 | head -1)
    pass "$tool: $version"
  else
    fail "$tool: NOT FOUND"
  fi
done

# Check OpenCode CLI
echo ""
echo "== OpenCode CLI =="
if command -v opencode >/dev/null 2>&1; then
  pass "opencode CLI: $(opencode --version 2>&1 | head -1)"
else
  warn "opencode CLI: NOT FOUND (install from opencode.ai)"
fi

# Check Doppler
echo ""
echo "== Doppler =="
if command -v doppler >/dev/null 2>&1; then
  pass "doppler CLI: $(doppler --version 2>&1 | head -1)"
else
  warn "doppler CLI: NOT FOUND (install: brew install dopplerhq/doppler/doppler)"
fi

# Check workspace structure
echo ""
echo "== Workspace Structure =="
for f in .opencode/AGENTS.md .opencode/rules.md .opencode/opencode.json .opencode/brain-config.json; do
  if [ -f "$ROOT_DIR/$f" ]; then
    pass "$f exists"
  else
    fail "$f missing"
  fi
done

# Check .opencode/node_modules
if [ -d "$ROOT_DIR/.opencode/node_modules" ]; then
  pass ".opencode/node_modules installed"
else
  warn ".opencode/node_modules not found (run: cd .opencode && pnpm install)"
fi

# Check global config
echo ""
echo "== Global Config =="
GLOBAL_DIR="$HOME/.config/opencode"
if [ -f "$GLOBAL_DIR/opencode.json" ]; then
  pass "Global opencode.json exists"
  # Check it doesn't contain behavioral policy
  if jq -e '.lanes // .token_budget // .gate_matrix' "$GLOBAL_DIR/opencode.json" >/dev/null 2>&1; then
    fail "Global config contains behavioral policy (should be provider/auth only)"
  else
    pass "Global config is provider/auth only"
  fi
else
  warn "Global opencode.json not found (see INSTALL.md)"
fi

# Check global prompts
prompt_count=$(ls "$GLOBAL_DIR/prompts/"*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$prompt_count" -ge 9 ]; then
  pass "Global prompts: $prompt_count files"
else
  warn "Global prompts: $prompt_count files (expected 9, run: bash .opencode/scripts/sync-opencode-runtime.sh)"
fi

# Run workspace verification
echo ""
echo "== Workspace Verification =="
if [ -x "$ROOT_DIR/.opencode/scripts/verify-environment.sh" ]; then
  bash "$ROOT_DIR/.opencode/scripts/verify-environment.sh" --mode workspace 2>&1 | sed 's/^/  /'
else
  fail "verify-environment.sh not found or not executable"
fi

# Summary
echo ""
echo "=========================================="
printf '  PASSED: %d\n' "$PASS"
printf '  FAILED: %d\n' "$FAIL"
printf '  WARNED: %d\n' "$WARN"
echo "=========================================="

if [[ "$FAIL" -gt 0 ]]; then
  echo "[FAIL] Bootstrap incomplete. Fix failures above."
  exit 1
else
  echo "[PASS] Bootstrap complete."
  echo ""
  echo "Next steps:"
  echo "  1. Run: bash scripts/verify-install.sh"
  echo "  2. Clone project repos (see WORKSPACE_MAP.md)"
  echo "  3. Start OpenCode: opencode ."
  exit 0
fi
