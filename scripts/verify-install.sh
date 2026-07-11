#!/bin/bash
# verify-install.sh — Full installation verification
# Usage: bash scripts/verify-install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0

echo "=========================================="
echo "OpenCode Protocol — Install Verification"
echo "=========================================="
echo "Root: $ROOT_DIR"
echo ""

# Run all verification suites
SUITES=(
  ".opencode/scripts/verify-environment.sh --mode workspace"
  ".opencode/scripts/brain-config-coherence.sh"
  ".opencode/conformance/tests/protocol-coherence-phase1.sh"
  ".opencode/conformance/tests/implementation-readiness.sh"
  ".opencode/conformance/tests/git-guard-compliance.sh"
  ".opencode/conformance/tests/environment-consistency.sh"
  ".opencode/conformance/tests/model-routing-coherence.sh"
  ".opencode/conformance/tests/lite-delegation-mode.sh"
  ".opencode/conformance/tests/usage-aware-autonomy.sh"
  ".opencode/conformance/tests/pattern-memory.sh"
)

for suite in "${SUITES[@]}"; do
  name=$(echo "$suite" | sed 's|.*/||; s|\.sh.*||')
  echo ">>> $name"
  if bash $suite 2>&1 | tail -5; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "  FAILED"
  fi
  echo ""
done

echo "=========================================="
printf '  Suites passed: %d\n' "$PASS"
printf '  Suites failed: %d\n' "$FAIL"
echo "=========================================="

if [[ "$FAIL" -gt 0 ]]; then
  echo "[FAIL] Install verification failed."
  exit 1
else
  echo "[PASS] Install verification passed."
  exit 0
fi
