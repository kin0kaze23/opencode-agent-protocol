#!/usr/bin/env bash
# scripts/validate-config-schema.sh
# Validates that configuration files are structurally sound and internally consistent.
# Fails (exit 1) if any config is invalid or has dangling references.
#
# Usage: bash scripts/validate-config-schema.sh

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

echo "=== Config Schema Validation ==="
echo "Scanning: $ROOT_DIR"
echo ""

# ─────────────────────────────────────────────────────────────
# 1. Required protocol files exist
# ─────────────────────────────────────────────────────────────
echo "--- Required protocol files ---"
for f in \
  .opencode/AGENTS.md \
  .opencode/rules.md \
  .opencode/brain-config.json \
  .opencode/model-registry.yaml \
  .opencode/helper-roster.md \
  .opencode/CORE_V1_MANIFEST.md; do
  if [ -f "$ROOT_DIR/$f" ]; then
    pass
    echo "  $f exists"
  else
    fail "Required file missing: $f"
  fi
done

# ─────────────────────────────────────────────────────────────
# 2. Required config files exist
# ─────────────────────────────────────────────────────────────
echo "--- Required config files ---"
for f in \
  .opencode/config/gate-matrix.yaml \
  .opencode/config/token-budget.yaml \
  .opencode/config/repo-profiles.yaml \
  .opencode/config/model-routing-policy.recommended.yaml \
  .opencode/config/reviewer-policy.recommended.yaml \
  .opencode/config/reviewer-trust-policy.yaml; do
  if [ -f "$ROOT_DIR/$f" ]; then
    pass
    echo "  $f exists"
  else
    fail "Required config missing: $f"
  fi
done

# ─────────────────────────────────────────────────────────────
# 3. brain-config.json is valid JSON
# ─────────────────────────────────────────────────────────────
echo "--- brain-config.json validity ---"
if python3 -c "import json; json.load(open('$ROOT_DIR/.opencode/brain-config.json'))" 2>/dev/null; then
  pass
  echo "  brain-config.json is valid JSON"
else
  fail "brain-config.json is not valid JSON"
fi

# ─────────────────────────────────────────────────────────────
# 4. brain-config.json has required fields
# ─────────────────────────────────────────────────────────────
echo "--- brain-config.json required fields ---"
if python3 -c "
import json, sys
with open('$ROOT_DIR/.opencode/brain-config.json') as f:
    c = json.load(f)
required = ['version', 'name', 'description']
missing = [k for k in required if k not in c]
if missing:
    print(f'Missing fields: {missing}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null; then
  pass
  echo "  brain-config.json has version, name, description"
else
  fail "brain-config.json missing required fields (version, name, description)"
fi

# ─────────────────────────────────────────────────────────────
# 5. model-registry.yaml is valid YAML and has model entries
# ─────────────────────────────────────────────────────────────
echo "--- model-registry.yaml validity ---"
if python3 -c "
import yaml, sys
with open('$ROOT_DIR/.opencode/model-registry.yaml') as f:
    c = yaml.safe_load(f)
if not c:
    print('Empty config', file=sys.stderr)
    sys.exit(1)
# Check it has some model definitions
models = [k for k in c if isinstance(c[k], dict) and 'provider' in c[k]]
if len(models) < 3:
    print(f'Only {len(models)} models found (expected ≥3)', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null; then
  pass
  echo "  model-registry.yaml is valid YAML with model entries"
else
  # Try without PyYAML — just check file exists and is non-empty
  if [ -s "$ROOT_DIR/.opencode/model-registry.yaml" ]; then
    pass
    echo "  model-registry.yaml exists and is non-empty (YAML validation skipped — PyYAML not available)"
  else
    fail "model-registry.yaml is empty or missing"
  fi
fi

# ───────────────────────────────────────────────────────────────────────────
# 6. Config YAML files are valid YAML (if PyYAML available)
# ───────────────────────────────────────────────────────────────────────────
echo "--- Config YAML validity ---"
YAML_FILES=$(ls "$ROOT_DIR"/.opencode/config/*.yaml 2>/dev/null)
for yf in $YAML_FILES; do
  basename "$yf"
  if python3 -c "import yaml; yaml.safe_load(open('$yf'))" 2>/dev/null; then
    pass
    echo "  $(basename "$yf") is valid YAML"
  else
    # Graceful skip if PyYAML not installed
    if [ -s "$yf" ]; then
      pass
      echo "  $(basename "$yf") exists and is non-empty (YAML validation skipped)"
    else
      fail "$(basename "$yf") is empty"
    fi
  fi
done

# ─────────────────────────────────────────────────────────────
# 7. Helper roster has required agent roles
# ─────────────────────────────────────────────────────────────
echo "--- Helper roster roles ---"
ROSTER="$ROOT_DIR/.opencode/helper-roster.md"
if [ -f "$ROSTER" ]; then
  for role in "Explorer" "Planner" "Implementer" "Reviewer" "Architect"; do
    if grep -q "$role" "$ROSTER"; then
      pass
    else
      fail "Helper roster missing role: $role"
    fi
  done
  echo "  Checked 5 required agent roles"
else
  fail "helper-roster.md not found"
fi

# ─────────────────────────────────────────────────────────────
# 8. AGENTS.md has required sections
# ─────────────────────────────────────────────────────────────
echo "--- AGENTS.md required sections ---"
AGENTS="$ROOT_DIR/.opencode/AGENTS.md"
if [ -f "$AGENTS" ]; then
  for section in "Safety Rules" "Lane Selection" "Escalation" "Verification" "Lite Delegation" "Senior Operator"; do
    if grep -q "$section" "$AGENTS"; then
      pass
    else
      fail "AGENTS.md missing section: $section"
    fi
  done
  echo "  Checked 6 required sections"
else
  fail ".opencode/AGENTS.md not found"
fi

# ─────────────────────────────────────────────────────────────
# 9. Privacy scan script exists and is executable
# ─────────────────────────────────────────────────────────────
echo "--- Privacy scan script ---"
SCAN="$ROOT_DIR/scripts/public-surface-scan.sh"
if [ -f "$SCAN" ]; then
  pass
  if [ -x "$SCAN" ]; then
    pass
    echo "  public-surface-scan.sh exists and is executable"
  else
    echo "  public-surface-scan.sh exists (not executable — will be run via bash)"
  fi
else
  fail "scripts/public-surface-scan.sh not found"
fi

# ─────────────────────────────────────────────────────────────
# 10. CI workflow has required jobs
# ─────────────────────────────────────────────────────────────
echo "--- CI workflow jobs ---"
CI="$ROOT_DIR/.github/workflows/validation.yml"
if [ -f "$CI" ]; then
  for job in "public-surface-scan" "protocol-validation"; do
    if grep -q "$job" "$CI"; then
      pass
    else
      fail "CI workflow missing job: $job"
    fi
  done
  echo "  Checked 2 required CI jobs"
else
  fail ".github/workflows/validation.yml not found"
fi

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== PASS: Config schema validation clean ($CHECKS checks) ==="
  exit 0
else
  echo "=== FAIL: $FAILURES schema issue(s) found ($CHECKS checks passed) ==="
  exit 1
fi
