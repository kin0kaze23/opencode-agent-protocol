#!/bin/bash
# v4.17.2 Snapshot Lineage Conformance Test
# Purpose: Verify every version in VERSIONS.md from v4.15.0 onward has a matching snapshot
#
# Usage: bash .opencode/conformance/tests/v4172-snapshot-lineage.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/v4172-snapshot-lineage-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../guard-assert.sh" 2>/dev/null || {
  PASS_COUNT=0; FAIL_COUNT=0; WARN_COUNT=0
  guard_pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "[PASS] $1"; }
  guard_fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); echo "[FAIL] $1 — $2"; }
  guard_warn() { WARN_COUNT=$((WARN_COUNT + 1)); echo "[WARN] $1 — $2"; }
  reset_guard_counters() { PASS_COUNT=0; FAIL_COUNT=0; WARN_COUNT=0; }
  guard_report() { echo ""; echo "Results: $PASS_COUNT PASS, $FAIL_COUNT FAIL, $WARN_COUNT WARN"; }
  load_drift_registry() { true; }
}

echo "=========================================="
echo "v4.17.2 Snapshot Lineage Test"
echo "Date: $(date -Iseconds)"
echo "=========================================="

reset_guard_counters
load_drift_registry "$WORKSPACE_ROOT"

SNAPSHOTS_DIR="$WORKSPACE_ROOT/vault/protocols/opencode/snapshots"
VERSIONS_FILE="$WORKSPACE_ROOT/vault/protocols/opencode/VERSIONS.md"
CURRENT_FILE="$WORKSPACE_ROOT/vault/protocols/opencode/CURRENT.md"

# ============================================================
# 1. SNAPSHOTS DIRECTORY EXISTS
# ============================================================
test_start "V4172-SL-001" "snapshots directory exists"

if [[ -d "$SNAPSHOTS_DIR" ]]; then
  guard_pass "V4172-SL-001" "snapshots directory exists"
else
  guard_fail "V4172-SL-001" "snapshots directory missing" "" "Create vault/protocols/opencode/snapshots/"
fi

# ============================================================
# 2. EVERY VERSION IN VERSIONS.md FROM v4.15.0 HAS A SNAPSHOT
# ============================================================
test_start "V4172-SL-002" "every v4.15+ version has a matching snapshot"

# Extract version numbers from VERSIONS.md (v4.15.0 onward)
VERSIONS=$(grep '^| v4\.1[5-9]' "$VERSIONS_FILE" 2>/dev/null | sed 's/^| \(v4\.[0-9]*\.[0-9]*\).*/\1/' | sort -V)

if [[ -z "$VERSIONS" ]]; then
  guard_fail "V4172-SL-002" "no versions found in VERSIONS.md"
else
  for ver in $VERSIONS; do
    if [[ -d "$SNAPSHOTS_DIR/$ver" ]]; then
      if [[ -f "$SNAPSHOTS_DIR/$ver/protocol.md" ]]; then
        guard_pass "V4172-SL-002-$ver" "$ver has snapshot with protocol.md"
      else
        guard_fail "V4172-SL-002-$ver" "$ver snapshot directory exists but protocol.md missing" "" "Create protocol.md"
      fi
    else
      guard_fail "V4172-SL-002-$ver" "$ver snapshot directory missing" "" "Create snapshots/$ver/protocol.md"
    fi
  done
fi

# ============================================================
# 3. ACTIVE VERSION SNAPSHOT EXISTS AND MATCHES CURRENT.md
# ============================================================
test_start "V4172-SL-003" "active version snapshot matches CURRENT.md"

# Get active version from CURRENT.md
ACTIVE_VERSION=$(grep '| \*\*Version\*\*' "$CURRENT_FILE" 2>/dev/null | sed 's/.*| \*\*Version\*\* | \(v[0-9.]*\) |.*/\1/' | tr -d ' ')

if [[ -z "$ACTIVE_VERSION" ]]; then
  guard_fail "V4172-SL-003" "could not determine active version from CURRENT.md"
else
  if [[ -f "$SNAPSHOTS_DIR/$ACTIVE_VERSION/protocol.md" ]]; then
    guard_pass "V4172-SL-003-snapshot" "active version $ACTIVE_VERSION has snapshot"

    # Check snapshot status matches CURRENT.md
    SNAPSHOT_STATUS=$(grep -i 'Status:' "$SNAPSHOTS_DIR/$ACTIVE_VERSION/protocol.md" 2>/dev/null | head -1 | sed 's/.*Status:.*\(✅.*\)/\1/' | tr -d ' ')
    if grep -qi 'Production Core' "$SNAPSHOTS_DIR/$ACTIVE_VERSION/protocol.md" 2>/dev/null; then
      guard_pass "V4172-SL-003-status" "active snapshot marked as Production Core"
    else
      guard_warn "V4172-SL-003-status" "active snapshot status: $SNAPSHOT_STATUS" "" "Should be Production Core"
    fi
  else
    guard_fail "V4172-SL-003" "active version $ACTIVE_VERSION snapshot missing"
  fi
fi

# ============================================================
# 4. NO STALE ACTIVE MARKERS IN OLDER SNAPSHOTS
# ============================================================
test_start "V4172-SL-004" "no stale active markers in older snapshots"

for snapshot_dir in "$SNAPSHOTS_DIR"/v4.1[5-7]*; do
  [[ -d "$snapshot_dir" ]] || continue
  ver=$(basename "$snapshot_dir")
  if [[ "$ver" == "$ACTIVE_VERSION" ]]; then
    continue
  fi
  protocol_file="$snapshot_dir/protocol.md"
  if [[ -f "$protocol_file" ]]; then
    if grep -qi 'Production Core (Sealed)' "$protocol_file" 2>/dev/null && ! grep -qi 'Superseded' "$protocol_file" 2>/dev/null; then
      guard_fail "V4172-SL-004-$ver" "$ver snapshot marked as Production Core but is not active" "" "Mark as Superseded"
    else
      guard_pass "V4172-SL-004-$ver" "$ver snapshot correctly not marked as active Production Core"
    fi
  fi
done

# ============================================================
# RESULTS
# ============================================================
echo ""
guard_report "$RESULT_FILE" "v4.17.2 Snapshot Lineage"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
