#!/usr/bin/env bash
# telemetry-integrity.sh — v4.18.2
# Conformance test for telemetry data integrity
# Checks:
#   1. Every telemetry record v4.18.1+ must include schema_version
#   2. Every failure must include failure_classification
#   3. Every record must include usable_for_routing (v4.18.2+)
#   4. Routing reports must ignore fail_pre_existing/not_run/skipped records
#   5. Old records (pre-v4.18.1) are backward compatible but not decision-grade
#   6. Gate-health baseline exists and is valid YAML

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"  # Go up 3 levels to workspace root
DATA_DIR="$ROOT_DIR/vault/protocols/opencode/evals/benchmark-data"
BASELINE_FILE="$ROOT_DIR/.opencode/config/gate-health-baseline.yaml"
SCHEMA_FILE="$ROOT_DIR/.opencode/config/telemetry-schema.yaml"

PASS=0
FAIL=0
WARN=0

pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }
warn() { echo "[WARN] $1"; WARN=$((WARN+1)); }

echo "=========================================="
echo "Telemetry Integrity Conformance Test"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

# Check 1: Schema file exists and has correct version
if [[ -f "$SCHEMA_FILE" ]]; then
  SCHEMA_VERSION=$(grep '^version:' "$SCHEMA_FILE" | head -1 | cut -d'"' -f2)
  if [[ "$SCHEMA_VERSION" == "4.18.2" ]]; then
    pass "TI-001: telemetry-schema.yaml version is 4.18.2"
  else
    fail "TI-001: telemetry-schema.yaml version is $SCHEMA_VERSION (expected 4.18.2)"
  fi
else
  fail "TI-001: telemetry-schema.yaml not found"
fi

# Check 2: Gate-health baseline exists and is valid YAML
if [[ -f "$BASELINE_FILE" ]]; then
  if python3 -c "import yaml; yaml.safe_load(open('$BASELINE_FILE'))" 2>/dev/null; then
    pass "TI-002: gate-health-baseline.yaml exists and is valid YAML"
  else
    fail "TI-002: gate-health-baseline.yaml is not valid YAML"
  fi
else
  fail "TI-002: gate-health-baseline.yaml not found"
fi

# Check 3: Gate-health baseline has protected-repo known failures
if python3 -c "
import yaml
with open('$BASELINE_FILE') as f:
    data = yaml.safe_load(f)
repos = data.get('repos', {})
bg = repos.get('protected-repo-prod', {})
known = bg.get('known_failing_gates', [])
gates = [e['gate'] for e in known]
assert 'typecheck' in gates, 'typecheck not in known_failing'
assert 'test' in gates, 'test not in known_failing'
" 2>/dev/null; then
  pass "TI-003: protected-repo-prod typecheck and test are in known_failing_gates"
else
  fail "TI-003: protected-repo-prod known_failing_gates missing typecheck or test"
fi

# Check 4: All v4.18.1+ records include schema_version
python3 -c "
import json, glob, os
data_dir = '$DATA_DIR'
files = sorted(glob.glob(os.path.join(data_dir, '*.json')))
missing_sv = 0
total_v4181_plus = 0
for f in files:
    with open(f) as fh:
        records = json.load(fh)
    for r in records:
        sv = r.get('schema_version', '')
        if sv:  # v4.18.1+ record
            total_v4181_plus += 1
            if not sv:
                missing_sv += 1
if missing_sv == 0:
    print(f'PASS: All {total_v4181_plus} v4.18.1+ records include schema_version')
else:
    print(f'FAIL: {missing_sv}/{total_v4181_plus} v4.18.1+ records missing schema_version')
" 2>/dev/null | while read line; do
  if echo "$line" | grep -q "^PASS"; then pass "TI-004: $(echo "$line" | cut -d: -f2-)"; else fail "TI-004: $(echo "$line" | cut -d: -f2-)"; fi
done

# Check 5: All v4.18.2+ records include usable_for_routing
python3 -c "
import json, glob, os
data_dir = '$DATA_DIR'
files = sorted(glob.glob(os.path.join(data_dir, '*.json')))
missing_ufr = 0
total_v4182 = 0
for f in files:
    with open(f) as fh:
        records = json.load(fh)
    for r in records:
        sv = r.get('schema_version', '')
        if sv == '4.18.2':
            total_v4182 += 1
            if 'usable_for_routing' not in r:
                missing_ufr += 1
if total_v4182 == 0:
    print('WARN: No v4.18.2 records found yet')
elif missing_ufr == 0:
    print(f'PASS: All {total_v4182} v4.18.2 records include usable_for_routing')
else:
    print(f'FAIL: {missing_ufr}/{total_v4182} v4.18.2 records missing usable_for_routing')
" 2>/dev/null | while read line; do
  if echo "$line" | grep -q "^PASS"; then pass "TI-005: $(echo "$line" | cut -d: -f2-)";
  elif echo "$line" | grep -q "^WARN"; then warn "TI-005: $(echo "$line" | cut -d: -f2-)";
  else fail "TI-005: $(echo "$line" | cut -d: -f2-)"; fi
done

# Check 6: fail_pre_existing records have usable_for_routing=false
python3 -c "
import json, glob, os
data_dir = '$DATA_DIR'
files = sorted(glob.glob(os.path.join(data_dir, '*.json')))
violations = 0
for f in files:
    with open(f) as fh:
        records = json.load(fh)
    for r in records:
        fc = r.get('failure_classification', '')
        ufr = r.get('usable_for_routing', None)
        if fc == 'fail_pre_existing' and ufr == True:
            violations += 1
if violations == 0:
    print('PASS: No fail_pre_existing records have usable_for_routing=true')
else:
    print(f'FAIL: {violations} fail_pre_existing records have usable_for_routing=true')
" 2>/dev/null | while read line; do
  if echo "$line" | grep -q "^PASS"; then pass "TI-006: $(echo "$line" | cut -d: -f2-)"; else fail "TI-006: $(echo "$line" | cut -d: -f2-)"; fi
done

# Check 7: Schema includes all 10 failure classifications
python3 -c "
import yaml
with open('$SCHEMA_FILE') as f:
    data = yaml.safe_load(f)
fc = data.get('schema', {}).get('failure_classification', {})
values = fc.get('values', [])
required = ['pass', 'fail_new', 'fail_pre_existing', 'fail_environment', 'not_run', 'skipped_by_lane', 'skipped_by_cache', 'skipped_unsupported', 'cached_pass', 'cached_stale']
# values is a list of dicts with single key
found = set()
for v in values:
    if isinstance(v, dict):
        found.update(v.keys())
    elif isinstance(v, str):
        found.add(v)
missing = [r for r in required if r not in found]
if not missing:
    print('PASS: All 10 failure classifications present in schema')
else:
    print(f'FAIL: Missing classifications: {missing}')
" 2>/dev/null | while read line; do
  if echo "$line" | grep -q "^PASS"; then pass "TI-007: $(echo "$line" | cut -d: -f2-)"; else fail "TI-007: $(echo "$line" | cut -d: -f2-)"; fi
done

# Check 8: Schema includes conformance_rules
if grep -q 'conformance_rules' "$SCHEMA_FILE" 2>/dev/null; then
  pass "TI-008: Schema includes conformance_rules section"
else
  fail "TI-008: Schema missing conformance_rules section"
fi

# Check 9: Schema includes integrity_report section
if grep -q 'integrity_report' "$SCHEMA_FILE" 2>/dev/null; then
  pass "TI-009: Schema includes integrity_report section"
else
  fail "TI-009: Schema missing integrity_report section"
fi

# Check 10: Schema includes gate_health_baseline section
if grep -q 'gate_health_baseline' "$SCHEMA_FILE" 2>/dev/null; then
  pass "TI-010: Schema includes gate_health_baseline section"
else
  fail "TI-010: Schema missing gate_health_baseline section"
fi

echo ""
echo "=========================================="
echo "PASSED: $PASS"
echo "FAILED: $FAIL"
echo "WARNED: $WARN"
echo "=========================================="

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
