#!/usr/bin/env bash
# record-fleet-snapshot.sh — v4.40 Fleet Snapshot Recorder
#
# Runs the fleet dashboard and appends a timestamped JSON snapshot
# to .opencode/metrics/fleet-snapshots/ for trend tracking.
#
# Usage:
#   bash record-fleet-snapshot.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
METRICS_DIR="$WORKSPACE_ROOT/.opencode/metrics/fleet-snapshots"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DATE_DIR=$(date -u +%Y-%m)

mkdir -p "$METRICS_DIR/$DATE_DIR"

# ─── Generate dashboard ─────────────────────────────────────────────────
TMP_DIR="/tmp/fleet-dashboard-$$"
echo "[fleet-snapshot] Generating dashboard..."
bash "$SCRIPT_DIR/generate-fleet-dashboard.sh" --output-dir "$TMP_DIR" > /dev/null 2>&1

# v4.43: Also generate freshness report for freshness metrics
bash "$SCRIPT_DIR/evidence-freshness-report.sh" --output-dir "$TMP_DIR" > /dev/null 2>&1

# ─── Read JSON dashboard ────────────────────────────────────────────────
JSON_FILE="$TMP_DIR/fleet-dashboard.json"
if [[ ! -f "$JSON_FILE" ]]; then
  echo "[fleet-snapshot] ERROR: Dashboard JSON not generated"
  exit 1
fi

# ─── Extract summary metrics ───────────────────────────────────────────
TOTAL_REPOS=$(jq -r '.summary.total_repos // 0' "$JSON_FILE" 2>/dev/null || echo 0)
ACTIVE_REPOS=$(jq -r '.summary.active_repos // 0' "$JSON_FILE" 2>/dev/null || echo 0)
EXCLUDED_REPOS=$(jq -r '.summary.excluded_repos // 0' "$JSON_FILE" 2>/dev/null || echo 0)
GATE_INSTALLED=$(jq -r '.summary.gate_installed // 0' "$JSON_FILE" 2>/dev/null || echo 0)
CODEOWNERS_VERIFIED=$(jq -r '.summary.codeowners_verified // 0' "$JSON_FILE" 2>/dev/null || echo 0)
BRANCH_PROTECTION_VERIFIED=$(jq -r '.summary.branch_protection_verified // 0' "$JSON_FILE" 2>/dev/null || echo 0)
MANUALLY_VERIFIED=$(jq -r '.summary.manually_verified // 0' "$JSON_FILE" 2>/dev/null || echo 0)
UNKNOWN_PERMISSION=$(jq -r '.summary.unknown_permission // 0' "$JSON_FILE" 2>/dev/null || echo 0)
BASELINE_FAILURES=$(jq -r '.summary.baseline_failures // 0' "$JSON_FILE" 2>/dev/null || echo 0)

# ─── Extract freshness metrics from freshness report (v4.43) ───────────
FRESHNESS_FILE="$TMP_DIR/evidence-freshness.json"
FRESH_COUNT=0
EXPIRING_COUNT=0
STALE_COUNT=0
CRITICAL_COUNT=0
if [[ -f "$FRESHNESS_FILE" ]]; then
  FRESH_COUNT=$(jq '[.repos[] | select(.freshness == "fresh")] | length' "$FRESHNESS_FILE" 2>/dev/null || echo 0)
  EXPIRING_COUNT=$(jq '[.repos[] | select(.freshness == "expiring_soon")] | length' "$FRESHNESS_FILE" 2>/dev/null || echo 0)
  STALE_COUNT=$(jq '[.repos[] | select(.freshness == "stale")] | length' "$FRESHNESS_FILE" 2>/dev/null || echo 0)
  CRITICAL_COUNT=$(jq '[.repos[] | select(.freshness == "critically_stale")] | length' "$FRESHNESS_FILE" 2>/dev/null || echo 0)
fi

# ─── Create snapshot ───────────────────────────────────────────────────
SNAPSHOT_FILE="$METRICS_DIR/$DATE_DIR/fleet-snapshot-$(date -u +%Y%m%dT%H%M%SZ).json"

cat > "$SNAPSHOT_FILE" << EOF
{
  "timestamp": "$TIMESTAMP",
  "metrics": {
    "total_repos": $TOTAL_REPOS,
    "active_repos": $ACTIVE_REPOS,
    "excluded_repos": $EXCLUDED_REPOS,
    "release_gate_installed": $GATE_INSTALLED,
    "codeowners_verified": $CODEOWNERS_VERIFIED,
    "branch_protection_verified": $BRANCH_PROTECTION_VERIFIED,
    "manually_verified": $MANUALLY_VERIFIED,
    "unknown_permission_limited": $UNKNOWN_PERMISSION,
    "known_baseline_failures": $BASELINE_FAILURES,
    "fresh_evidence_count": $FRESH_COUNT,
    "expiring_soon_count": $EXPIRING_COUNT,
    "stale_evidence_count": $STALE_COUNT,
    "critically_stale_count": $CRITICAL_COUNT
  },
  "repos": $(jq '.repos' "$JSON_FILE" 2>/dev/null || echo "[]")
}
EOF

# ─── Cleanup ───────────────────────────────────────────────────────────
rm -rf "$TMP_DIR"

echo "[fleet-snapshot] ✅ Snapshot saved: $SNAPSHOT_FILE"
echo "[fleet-snapshot] Metrics:"
echo "  repos: $TOTAL_REPOS (active: $ACTIVE_REPOS, excluded: $EXCLUDED_REPOS)"
echo "  gate_installed: $GATE_INSTALLED | codeowners: $CODEOWNERS_VERIFIED"
echo "  branch_protection_verified: $BRANCH_PROTECTION_VERIFIED | manually_verified: $MANUALLY_VERIFIED | unknown: $UNKNOWN_PERMISSION"
echo "  baseline_failures: $BASELINE_FAILURES"
