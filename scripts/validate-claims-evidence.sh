#!/usr/bin/env bash
# scripts/validate-claims-evidence.sh
# Validates that public claims in docs/CLAIMS.md are either:
#   - allowed without evidence, or
#   - linked to evidence in docs/EVIDENCE.md
# Fails (exit 1) if disallowed claims are found or evidence is missing.
#
# Usage: bash scripts/validate-claims-evidence.sh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
CHECKS=0

fail() {
  echo "  FAIL: $1"
  FAILURES=$((FAILURES + 1))
}

pass() {
  CHECKS=$((CHECKS + 1))
}

echo "=== Claims & Evidence Validation ==="
echo "Scanning: $ROOT_DIR"
echo ""

# ─────────────────────────────────────────────────────────────
# 1. CLAIMS.md exists
# ─────────────────────────────────────────────────────────────
echo "--- Claims document ---"
CLAIMS="$ROOT_DIR/docs/CLAIMS.md"
EVIDENCE="$ROOT_DIR/docs/EVIDENCE.md"

if [ -f "$CLAIMS" ]; then
  pass
  echo "  docs/CLAIMS.md exists"
else
  fail "docs/CLAIMS.md not found"
  echo "Cannot continue without claims document."
  exit 1
fi

if [ -f "$EVIDENCE" ]; then
  pass
  echo "  docs/EVIDENCE.md exists"
else
  fail "docs/EVIDENCE.md not found"
fi

# ─────────────────────────────────────────────────────────────
# 2. Disallowed claims section exists
# ─────────────────────────────────────────────────────────────
echo "--- Disallowed claims section ---"
if grep -q "Disallowed Claims" "$CLAIMS"; then
  pass
  echo "  Disallowed claims section exists"
else
  fail "CLAIMS.md missing 'Disallowed Claims' section"
fi

# ─────────────────────────────────────────────────────────────
# 3. Check for known disallowed claim patterns in all docs
# ─────────────────────────────────────────────────────────────
echo "--- Disallowed claim patterns in docs ---"
DISALLOWED_PATTERNS=(
  "better than Anthropic"
  "better than OpenAI"
  "approved by.*Karpathy"
  "approved by.*Andrew Ng"
  "researcher-approved"
  "guaranteed productivity (improvement|gain|boost)"
  "fully autonomous.*safe"
)

for pattern in "${DISALLOWED_PATTERNS[@]}"; do
  # Check for the pattern but exclude lines that negate it (e.g., "No guaranteed productivity gains are claimed")
  MATCHES=$(grep -rlE "$pattern" "$ROOT_DIR"/docs/ "$ROOT_DIR"/README.md 2>/dev/null | grep -v '.git/' || true)
  if [ -z "$MATCHES" ]; then
    pass
  else
    # Filter out lines that negate the claim
    REAL_MATCHES=""
    for f in $MATCHES; do
      NEGATIVE=$(grep -nE "$pattern" "$f" 2>/dev/null | grep -iE 'no |not |never |without ' || true)
      POSITIVE=$(grep -nE "$pattern" "$f" 2>/dev/null | grep -ivE 'no |not |never |without ' || true)
      if [ -n "$POSITIVE" ]; then
        REAL_MATCHES="$REAL_MATCHES $f"
      fi
    done
    if [ -z "$REAL_MATCHES" ]; then
      pass
    else
      fail "Disallowed claim pattern found: '$pattern' in: $REAL_MATCHES"
    fi
  fi
done
echo "  Checked ${#DISALLOWED_PATTERNS[@]} disallowed patterns"

# ─────────────────────────────────────────────────────────────
# 4. Evidence doc references case studies
# ─────────────────────────────────────────────────────────────
echo "--- Evidence references ---"
if grep -q "Case Study" "$EVIDENCE" 2>/dev/null; then
  pass
  echo "  Evidence doc references case studies"
else
  fail "Evidence doc does not reference case studies"
fi

# ─────────────────────────────────────────────────────────────
# 5. Case studies doc exists and has entries
# ─────────────────────────────────────────────────────────────
echo "--- Case studies ---"
CASE_STUDIES="$ROOT_DIR/docs/CASE_STUDIES.md"
if [ -f "$CASE_STUDIES" ]; then
  pass
  CS_COUNT=$(grep -c "## Case Study" "$CASE_STUDIES" 2>/dev/null || echo 0)
  if [ "$CS_COUNT" -ge 3 ]; then
    pass
    echo "  $CS_COUNT case studies found (≥3 required)"
  else
    fail "Only $CS_COUNT case studies found (expected ≥3)"
  fi
else
  fail "docs/CASE_STUDIES.md not found"
fi

# ─────────────────────────────────────────────────────────────
# 6. Failure modes doc exists and has entries
# ─────────────────────────────────────────────────────────────
echo "--- Failure modes ---"
FAILURE_MODES="$ROOT_DIR/docs/FAILURE_MODES.md"
if [ -f "$FAILURE_MODES" ]; then
  pass
  FM_COUNT=$(grep -c "^## [0-9]" "$FAILURE_MODES" 2>/dev/null || echo 0)
  if [ "$FM_COUNT" -ge 5 ]; then
    pass
    echo "  $FM_COUNT failure modes documented (≥5 required)"
  else
    fail "Only $FM_COUNT failure modes documented (expected ≥5)"
  fi
else
  fail "docs/FAILURE_MODES.md not found"
fi

# ─────────────────────────────────────────────────────────────
# 7. Threat model doc exists and has threat categories
# ─────────────────────────────────────────────────────────────
echo "--- Threat model ---"
THREAT_MODEL="$ROOT_DIR/docs/THREAT_MODEL.md"
if [ -f "$THREAT_MODEL" ]; then
  pass
  TM_COUNT=$(grep -c "^### [0-9]" "$THREAT_MODEL" 2>/dev/null || echo 0)
  if [ "$TM_COUNT" -ge 5 ]; then
    pass
    echo "  $TM_COUNT threat categories documented (≥5 required)"
  else
    fail "Only $TM_COUNT threat categories documented (expected ≥5)"
  fi
else
  fail "docs/THREAT_MODEL.md not found"
fi

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== PASS: Claims & evidence validation clean ($CHECKS checks) ==="
  exit 0
else
  echo "=== FAIL: $FAILURES issue(s) found ($CHECKS checks passed) ==="
  exit 1
fi
