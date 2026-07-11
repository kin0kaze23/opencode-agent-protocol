#!/usr/bin/env bash
# analyze-fleet-trends.sh — v4.42 Enhanced Trend Analytics
#
# Reads fleet snapshots and generates trend analysis with:
# - Classification changes over time
# - Regression detection
# - Lifecycle timeline per repo
# - Compact trend summary for dashboard integration
#
# Usage:
#   bash analyze-fleet-trends.sh [--output-dir <path>]
#
# Output:
#   reports/fleet-trends.md
#   reports/fleet-trends.json

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SNAPSHOTS_DIR="$WORKSPACE_ROOT/.opencode/metrics/fleet-snapshots"
OUTPUT_DIR="$WORKSPACE_ROOT/reports"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    *) shift ;;
  esac
done

mkdir -p "$OUTPUT_DIR"

echo "[fleet-trends] Analyzing fleet trends..."

# ─── Collect all snapshot files sorted by name (timestamp) ──────────────
SNAPSHOT_FILES=$(find "$SNAPSHOTS_DIR" -name "*.json" -type f 2>/dev/null | sort)

if [[ -z "$SNAPSHOT_FILES" ]]; then
  echo "[fleet-trends] No snapshots found — generating empty trend report"
  cat > "$OUTPUT_DIR/fleet-trends.md" << EOF
<!-- fleet-trends -->
# 📈 Fleet Trend Analytics

**Generated:** $TIMESTAMP

No snapshots available. Run \`record-fleet-snapshot.sh\` to start collecting trend data.
EOF

  echo '{"generated":"'"$TIMESTAMP"'","snapshots":[],"summary":{"total_snapshots":0,"regressions":0,"improvements":0},"regressions":[],"improvements":[]}' | jq '.' > "$OUTPUT_DIR/fleet-trends.json" 2>/dev/null
  echo "[fleet-trends] ✅ Empty trend report generated (no snapshots)"
  exit 0
fi

SNAPSHOT_COUNT=$(echo "$SNAPSHOT_FILES" | wc -l | tr -d ' ')
echo "[fleet-trends] Found $SNAPSHOT_COUNT snapshots"

# ─── Build combined JSON from all snapshots ─────────────────────────────
TMP_DIR="/tmp/fleet-trends-$$"
mkdir -p "$TMP_DIR"

ALL_SNAPSHOTS_JSON="[]"
SNAPSHOT_INDEX=0

while IFS= read -r SNAPSHOT_FILE; do
  [[ -z "$SNAPSHOT_FILE" ]] && continue

  # Validate JSON
  if ! jq '.' "$SNAPSHOT_FILE" > /dev/null 2>&1; then
    echo "[fleet-trends] ⚠️ Skipping malformed snapshot: $SNAPSHOT_FILE"
    continue
  fi

  # Extract metrics with old-schema fallback
  SNAPSHOT_TS=$(jq -r '.timestamp // "unknown"' "$SNAPSHOT_FILE")
  TOTAL_REPOS=$(jq -r '.metrics.total_repos // 0' "$SNAPSHOT_FILE")
  GATE_INSTALLED=$(jq -r '.metrics.release_gate_installed // 0' "$SNAPSHOT_FILE")
  CODEOWNERS_VERIFIED=$(jq -r '.metrics.codeowners_verified // 0' "$SNAPSHOT_FILE")
  BP_VERIFIED=$(jq -r '.metrics.branch_protection_verified // 0' "$SNAPSHOT_FILE")
  MANUALLY_VERIFIED=$(jq -r '.metrics.manually_verified // 0' "$SNAPSHOT_FILE")
  UNKNOWN_PERM=$(jq -r '.metrics.unknown_permission_limited // 0' "$SNAPSHOT_FILE")
  BASELINE_FAILURES=$(jq -r '.metrics.known_baseline_failures // 0' "$SNAPSHOT_FILE")

  # Build snapshot entry
  ALL_SNAPSHOTS_JSON=$(echo "$ALL_SNAPSHOTS_JSON" | jq ". + [{\"timestamp\":\"$SNAPSHOT_TS\",\"total_repos\":$TOTAL_REPOS,\"gate_installed\":$GATE_INSTALLED,\"codeowners_verified\":$CODEOWNERS_VERIFIED,\"branch_protection_verified\":$BP_VERIFIED,\"manually_verified\":$MANUALLY_VERIFIED,\"unknown_permission\":$UNKNOWN_PERM,\"baseline_failures\":$BASELINE_FAILURES}]")

  # Extract per-repo data to temp file
  jq -r ".repos[]? | \"\(.name // \"unknown\")|\(.classification // \"unknown\")|\(.release_gate // \"unknown\")|\(.codeowners // \"unknown\")|\(.status // \"unknown\")\"" "$SNAPSHOT_FILE" > "$TMP_DIR/snapshot-$SNAPSHOT_INDEX.txt" 2>/dev/null || true

  SNAPSHOT_INDEX=$((SNAPSHOT_INDEX + 1))
done <<< "$SNAPSHOT_FILES"

# ─── Detect regressions and improvements ────────────────────────────────
REGRESSIONS=""
IMPROVEMENTS=""
REG_COUNT=0
IMP_COUNT=0

if [[ $SNAPSHOT_COUNT -ge 2 ]]; then
  PREV_INDEX=$((SNAPSHOT_COUNT - 2))
  CURR_INDEX=$((SNAPSHOT_COUNT - 1))

  PREV_FILE="$TMP_DIR/snapshot-$PREV_INDEX.txt"
  CURR_FILE="$TMP_DIR/snapshot-$CURR_INDEX.txt"

  if [[ -f "$PREV_FILE" && -f "$CURR_FILE" ]]; then
    # Compare per-repo classifications
    while IFS='|' read -r NAME CLASS GATE CO STATUS; do
      [[ -z "$NAME" ]] && continue

      PREV_LINE=$(grep "^${NAME}|" "$PREV_FILE" 2>/dev/null | head -1)
      PREV_CLASS=$(echo "$PREV_LINE" | cut -d'|' -f2)
      PREV_GATE=$(echo "$PREV_LINE" | cut -d'|' -f3)
      PREV_CO=$(echo "$PREV_LINE" | cut -d'|' -f4)

      [[ -z "$PREV_CLASS" ]] && PREV_CLASS="unknown"

      # Detect regressions
      if [[ "$PREV_CLASS" == "manually_verified" && "$CLASS" == "protection_ready" ]]; then
        REGRESSIONS="${REGRESSIONS}- HIGH: ${NAME} regressed from manually_verified to protection_ready\n"
        REG_COUNT=$((REG_COUNT + 1))
      elif [[ "$PREV_CLASS" == "protected" && "$CLASS" == "manually_verified" ]]; then
        REGRESSIONS="${REGRESSIONS}- HIGH: ${NAME} regressed from protected to manually_verified\n"
        REG_COUNT=$((REG_COUNT + 1))
      elif [[ "$PREV_CLASS" == "manually_verified" && "$CLASS" == "partially_protected" ]]; then
        REGRESSIONS="${REGRESSIONS}- HIGH: ${NAME} regressed from manually_verified to partially_protected\n"
        REG_COUNT=$((REG_COUNT + 1))
      elif [[ "$GATE" == "not_installed" && "$PREV_GATE" == "installed" ]]; then
        REGRESSIONS="${REGRESSIONS}- HIGH: ${NAME} release gate disappeared\n"
        REG_COUNT=$((REG_COUNT + 1))
      elif [[ "$CO" == "missing" && "$PREV_CO" == "present" ]]; then
        REGRESSIONS="${REGRESSIONS}- MEDIUM: ${NAME} CODEOWNERS disappeared\n"
        REG_COUNT=$((REG_COUNT + 1))
      elif [[ "$STATUS" == "active" && "$NAME" == "protected-repo" ]]; then
        REGRESSIONS="${REGRESSIONS}- HIGH: protected-repo appeared as active (should be excluded)\n"
        REG_COUNT=$((REG_COUNT + 1))
      fi

      # Detect improvements
      if [[ "$PREV_CLASS" == "protection_ready" && "$CLASS" == "manually_verified" ]]; then
        IMPROVEMENTS="${IMPROVEMENTS}- ${NAME} improved from protection_ready to manually_verified\n"
        IMP_COUNT=$((IMP_COUNT + 1))
      elif [[ "$PREV_CLASS" == "partially_protected" && "$CLASS" == "protected" ]]; then
        IMPROVEMENTS="${IMPROVEMENTS}- ${NAME} improved from partially_protected to protected\n"
        IMP_COUNT=$((IMP_COUNT + 1))
      fi
    done < "$CURR_FILE"
  fi
fi

# ─── Build per-repo lifecycle from all snapshots ────────────────────────
LIFECYCLE_MD=""
LIFECYCLE_JSON="[]"

# Get unique repo names from latest snapshot
LATEST_FILE="$TMP_DIR/snapshot-$((SNAPSHOT_COUNT - 1)).txt"
if [[ -f "$LATEST_FILE" ]]; then
  while IFS='|' read -r NAME CLASS GATE CO STATUS; do
    [[ -z "$NAME" ]] && continue

    FIRST_SEEN=""
    for i in $(seq 0 $((SNAPSHOT_COUNT - 1))); do
      if grep -q "^${NAME}|" "$TMP_DIR/snapshot-$i.txt" 2>/dev/null; then
        FIRST_TS=$(jq -r '.timestamp' "$(echo "$SNAPSHOT_FILES" | sed -n "$((i+1))p")" 2>/dev/null || echo "unknown")
        FIRST_SEEN="$FIRST_TS"
        break
      fi
    done

    LIFECYCLE_MD+="### $NAME\n- First seen: ${FIRST_SEEN:-unknown}\n- Latest classification: $CLASS\n\n"
    LIFECYCLE_JSON=$(echo "$LIFECYCLE_JSON" | jq ". + [{\"name\":\"$NAME\",\"first_seen\":\"${FIRST_SEEN:-unknown}\",\"latest_classification\":\"$CLASS\"}]")
  done < "$LATEST_FILE"
fi

# ─── Generate markdown trend report ────────────────────────────────────
MD_FILE="$OUTPUT_DIR/fleet-trends.md"
{
  echo "<!-- fleet-trends -->"
  echo "# 📈 Fleet Trend Analytics"
  echo ""
  echo "**Generated:** $TIMESTAMP"
  echo "**Snapshots analyzed:** $SNAPSHOT_COUNT"
  echo ""
  echo "---"
  echo ""
  echo "## 📊 Metrics Over Time"
  echo ""
  echo "| Timestamp | Repos | Gate | CODEOWNERS | API Verified | Manual Verified | Unknown | Baseline Failures |"
  echo "|------------|-------|------|------------|-------------|-----------------|---------|-------------------|"
  echo "$ALL_SNAPSHOTS_JSON" | jq -r '.[] | "| \(.timestamp) | \(.total_repos) | \(.gate_installed) | \(.codeowners_verified) | \(.branch_protection_verified) | \(.manually_verified) | \(.unknown_permission) | \(.baseline_failures) |"'
  echo ""
  echo "---"
  echo ""
  echo "## 🔄 Lifecycle Timeline"
  echo ""
  echo -e "$LIFECYCLE_MD"
  echo "---"
  echo ""
  echo "## 🚨 Regressions Detected"
  echo ""
  if [[ -n "$REGRESSIONS" ]]; then
    echo -e "$REGRESSIONS"
  else
    echo "✅ No regressions detected"
  fi
  echo ""
  echo "## ✅ Improvements Detected"
  echo ""
  if [[ -n "$IMPROVEMENTS" ]]; then
    echo -e "$IMPROVEMENTS"
  else
    echo "No improvements detected (or first snapshot)"
  fi
  echo ""
  echo "---"
  echo "*Generated by v4.42 Fleet Trend Analyzer*"
} > "$MD_FILE"

# ─── Generate JSON trend report ────────────────────────────────────────
JSON_FILE="$OUTPUT_DIR/fleet-trends.json"

REG_JSON="[]"
IMP_JSON="[]"
[[ -n "$REGRESSIONS" ]] && REG_JSON=$(echo -e "$REGRESSIONS" | grep -v '^$' | jq -R '.' | jq -s '.' 2>/dev/null || echo '[]')
[[ -n "$IMPROVEMENTS" ]] && IMP_JSON=$(echo -e "$IMPROVEMENTS" | grep -v '^$' | jq -R '.' | jq -s '.' 2>/dev/null || echo '[]')

cat > "$JSON_FILE" << ENDJSON
{
  "generated": "$TIMESTAMP",
  "snapshots_analyzed": $SNAPSHOT_COUNT,
  "snapshots": $ALL_SNAPSHOTS_JSON,
  "lifecycle": $LIFECYCLE_JSON,
  "summary": {
    "total_snapshots": $SNAPSHOT_COUNT,
    "regressions": $REG_COUNT,
    "improvements": $IMP_COUNT
  },
  "regressions": $REG_JSON,
  "improvements": $IMP_JSON
}
ENDJSON

if command -v jq &> /dev/null; then
  jq '.' "$JSON_FILE" > "${JSON_FILE}.tmp" && mv "${JSON_FILE}.tmp" "$JSON_FILE"
fi

# ─── Cleanup ───────────────────────────────────────────────────────────
rm -rf "$TMP_DIR"

echo "[fleet-trends] ✅ Trend report generated:"
echo "  Markdown: $MD_FILE"
echo "  JSON: $JSON_FILE"
echo ""
echo "[fleet-trends] Summary:"
echo "  Snapshots: $SNAPSHOT_COUNT | Regressions: $REG_COUNT | Improvements: $IMP_COUNT"
