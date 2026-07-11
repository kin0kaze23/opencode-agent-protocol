#!/usr/bin/env bash
# generate-fleet-dashboard.sh — v4.40 Fleet Dashboard Generator
#
# Generates a multi-repo release protection dashboard in markdown and JSON.
# Reads fleet-repos.yaml and checks each active repo's protection status.
#
# Usage:
#   bash generate-fleet-dashboard.sh [--output-dir <path>]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="$WORKSPACE_ROOT/reports"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    *) shift ;;
  esac
done

FLEET_CONFIG="$WORKSPACE_ROOT/.opencode/config/fleet-repos.yaml"
EVIDENCE_FILE="$WORKSPACE_ROOT/.opencode/config/branch-protection-evidence.yaml"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p "$OUTPUT_DIR"

if [[ ! -f "$FLEET_CONFIG" ]]; then
  echo "ERROR: fleet-repos.yaml not found at $FLEET_CONFIG"
  exit 1
fi

echo "[fleet-dashboard] Generating dashboard..."
echo ""

# ─── Counters ───────────────────────────────────────────────────────────
GATE_INSTALLED=0
CODEOWNERS_VERIFIED=0
BRANCH_PROTECTION_VERIFIED=0
UNKNOWN_PERMISSION=0
MANUALLY_VERIFIED=0
TOTAL_ACTIVE=0
TOTAL_EXCLUDED=0
BASELINE_FAILURES=0

# ─── Markdown sections ──────────────────────────────────────────────────
MD_REPOS=""
MD_EXCLUDED=""

# ─── JSON repos array ───────────────────────────────────────────────────
JSON_REPOS=""

# ─── Process each repo ──────────────────────────────────────────────────
# Extract repo names using awk for reliable parsing
REPO_NAMES=$(awk '/^  - name:/ {print $3}' "$FLEET_CONFIG")

while IFS= read -r REPO_NAME; do
  [[ -z "$REPO_NAME" ]] && continue

  # Extract status for this repo
  REPO_STATUS=$(awk "/^  - name: $REPO_NAME\$/{found=1} found && /status:/ {print \$2; exit}" "$FLEET_CONFIG")

  # Skip excluded repos
  if [[ "$REPO_STATUS" == "excluded" ]]; then
    TOTAL_EXCLUDED=$((TOTAL_EXCLUDED + 1))
    EXCLUSION_NOTE=$(awk "/^  - name: $REPO_NAME\$/{found=1} found && /exclusion_note:/ {gsub(/.*exclusion_note: \"|\"/, \"\"); print; exit}" "$FLEET_CONFIG")
    MD_EXCLUDED+="## 🚫 $REPO_NAME (Excluded)\n\n$EXCLUSION_NOTE\n\n"
    continue
  fi

  TOTAL_ACTIVE=$((TOTAL_ACTIVE + 1))
  echo "[fleet-dashboard] Checking $REPO_NAME..."

  REPO_PATH="$WORKSPACE_ROOT/$REPO_NAME"

  # ─── Check release gate ───────────────────────────────────────────────
  GATE_STATUS="not_installed"
  if [[ -f "$REPO_PATH/.github/workflows/pr-release-gate.yml" ]]; then
    GATE_STATUS="installed"
    GATE_INSTALLED=$((GATE_INSTALLED + 1))
  fi

  # ─── Check CODEOWNERS ────────────────────────────────────────────────
  CODEOWNERS_STATUS="missing"
  if [[ -f "$REPO_PATH/.github/CODEOWNERS" ]] || [[ -f "$REPO_PATH/CODEOWNERS" ]] || [[ -f "$REPO_PATH/docs/CODEOWNERS" ]]; then
    CODEOWNERS_STATUS="present"
    CODEOWNERS_VERIFIED=$((CODEOWNERS_VERIFIED + 1))
  fi

  # ─── Check trust policy ──────────────────────────────────────────────
  TRUST_POLICY_STATUS="missing"
  if [[ -f "$REPO_PATH/.opencode/config/reviewer-trust-policy.yaml" ]]; then
    TRUST_POLICY_STATUS="installed"
  fi

  # ─── Check branch protection ────────────────────────────────────────
  BP_STATUS="unknown_permission_limited"
  if [[ -f "$SCRIPT_DIR/verify-branch-protection.sh" ]]; then
    BP_OUTPUT=$(bash "$SCRIPT_DIR/verify-branch-protection.sh" --repo "$REPO_PATH" 2>&1)
    BP_CLASSIFICATION=$(echo "$BP_OUTPUT" | grep "Classification:" | awk '{print $2}')
    BP_STATUS="${BP_CLASSIFICATION:-unknown_permission_limited}"
  fi

  case "$BP_STATUS" in
    verified) BRANCH_PROTECTION_VERIFIED=$((BRANCH_PROTECTION_VERIFIED + 1)) ;;
    unknown_permission_limited) UNKNOWN_PERMISSION=$((UNKNOWN_PERMISSION + 1)) ;;
  esac

  # ─── Check manual branch protection evidence (v4.41) ─────────────────
  MANUAL_EVIDENCE_STATUS="no_evidence"
  EVIDENCE_AGE="unknown"
  FRESHNESS_STATUS="unknown"
  if [[ -f "$EVIDENCE_FILE" ]]; then
    MANUAL_EVIDENCE_STATUS=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /evidence_status:/{print \$2; exit}" "$EVIDENCE_FILE")
    MANUAL_EVIDENCE_STATUS="${MANUAL_EVIDENCE_STATUS:-no_evidence}"

    # v4.43: Check evidence freshness
    RECORDED_AT=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /recorded_at:/{gsub(/\"/,\"\"); print \$2; exit}" "$EVIDENCE_FILE")
    if [[ -n "$RECORDED_AT" && "$RECORDED_AT" != "" ]]; then
      EVIDENCE_DATE=$(echo "$RECORDED_AT" | tr -d '-' | cut -dT -f1)
      CURRENT_DATE=$(date +%Y%m%d)
      if [[ -n "$EVIDENCE_DATE" && "$EVIDENCE_DATE" =~ ^[0-9]+$ ]]; then
        AGE_DAYS=$(( (CURRENT_DATE - EVIDENCE_DATE) ))
        EVIDENCE_AGE="${AGE_DAYS} days"
        if [[ $AGE_DAYS -lt 0 ]]; then
          FRESHNESS_STATUS="future_timestamp"
        elif [[ $AGE_DAYS -lt 60 ]]; then
          FRESHNESS_STATUS="fresh"
        elif [[ $AGE_DAYS -lt 90 ]]; then
          FRESHNESS_STATUS="expiring_soon"
        elif [[ $AGE_DAYS -lt 120 ]]; then
          FRESHNESS_STATUS="stale"
        else
          FRESHNESS_STATUS="critically_stale"
        fi
      fi
    fi
  fi

  # ─── Get known baseline failures ────────────────────────────────────
  BF_COUNT=0
  BF_MD=""
  # Check if this repo has baseline failures in the manifest
  BF_CHECKS=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /check:/ {print \$3}" "$FLEET_CONFIG")
  if [[ -n "$BF_CHECKS" ]]; then
    while IFS= read -r BF_CHECK; do
      [[ -z "$BF_CHECK" ]] && continue
      BF_MD+="- $BF_CHECK\n"
      BF_COUNT=$((BF_COUNT + 1))
      BASELINE_FAILURES=$((BASELINE_FAILURES + 1))
    done <<< "$BF_CHECKS"
  fi

  # ─── Determine final classification ──────────────────────────────────
  # v4.41: manually_verified is separate from protected
  #   protected = API-verified branch protection
  #   manually_verified = owner-recorded evidence passes validator
  #   protection_ready = gate + CODEOWNERS installed, no evidence
  # v4.43: stale evidence reverts to protection_ready
  if [[ "$GATE_STATUS" == "not_installed" ]]; then
    CLASSIFICATION="not_protected"
  elif [[ "$BP_STATUS" == "verified" && "$CODEOWNERS_STATUS" == "present" ]]; then
    CLASSIFICATION="protected"
  elif [[ "$BP_STATUS" == "verified" ]]; then
    CLASSIFICATION="partially_protected"
  elif [[ "$BP_STATUS" == "unknown_permission_limited" && "$MANUAL_EVIDENCE_STATUS" == "manually_verified" && "$FRESHNESS_STATUS" == "fresh" ]]; then
    CLASSIFICATION="manually_verified"
    MANUALLY_VERIFIED=$((MANUALLY_VERIFIED + 1))
  elif [[ "$BP_STATUS" == "unknown_permission_limited" && "$MANUAL_EVIDENCE_STATUS" == "manually_verified" && "$FRESHNESS_STATUS" == "expiring_soon" ]]; then
    CLASSIFICATION="manually_verified"
    MANUALLY_VERIFIED=$((MANUALLY_VERIFIED + 1))
  elif [[ "$BP_STATUS" == "unknown_permission_limited" ]]; then
    CLASSIFICATION="protection_ready"
  elif [[ "$BP_STATUS" == "not_configured" ]]; then
    CLASSIFICATION="not_protected"
  else
    CLASSIFICATION="partially_protected"
  fi

  # ─── Get owner next actions ─────────────────────────────────────────
  OWNER_ACTIONS=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0; in_actions=0} found && /owner_next_action:/{in_actions=1; next} found && /^  - name:/{in_actions=0} in_actions && /^      - / {sub(/^      - /, \"\"); print}" "$FLEET_CONFIG" | head -10)

  # ─── Status icons ───────────────────────────────────────────────────
  case "$CLASSIFICATION" in
    protected) CLASS_ICON="✅" ;;
    manually_verified) CLASS_ICON="🔷" ;;
    protection_ready) CLASS_ICON="🟡" ;;
    partially_protected) CLASS_ICON="⚠️" ;;
    not_protected) CLASS_ICON="❌" ;;
    *) CLASS_ICON="❓" ;;
  esac

  GATE_ICON=$([ "$GATE_STATUS" == "installed" ] && echo "✅" || echo "❌")
  CO_ICON=$([ "$CODEOWNERS_STATUS" == "present" ] && echo "✅" || echo "❌")
  TP_ICON=$([ "$TRUST_POLICY_STATUS" == "installed" ] && echo "✅" || echo "❌")
  BP_ICON="⚠️"
  [[ "$BP_STATUS" == "verified" ]] && BP_ICON="✅"
  [[ "$BP_STATUS" == "not_configured" ]] && BP_ICON="❌"

  # ─── Markdown output ────────────────────────────────────────────────
  MD_REPOS+="## $CLASS_ICON $REPO_NAME\n\n"
  MD_REPOS+="| Check | Status |\n"
  MD_REPOS+="|-------|--------|\n"
  MD_REPOS+="| Release Gate | $GATE_ICON $GATE_STATUS |\n"
  MD_REPOS+="| CODEOWNERS | $CO_ICON $CODEOWNERS_STATUS |\n"
  MD_REPOS+="| Trust Policy | $TP_ICON $TRUST_POLICY_STATUS |\n"
  MD_REPOS+="| Branch Protection | $BP_ICON $BP_STATUS |\n"
  MD_REPOS+="| Manual Evidence | $MANUAL_EVIDENCE_STATUS |\n"
  MD_REPOS+="| Evidence Age | $EVIDENCE_AGE |\n"
  MD_REPOS+="| Freshness | $FRESHNESS_STATUS |\n"
  MD_REPOS+="| Classification | $CLASS_ICON $CLASSIFICATION |\n\n"

  if [[ -n "$BF_MD" ]]; then
    MD_REPOS+="### Known Baseline Failures\n\n$BF_MD\n"
  fi

  if [[ -n "$OWNER_ACTIONS" ]]; then
    MD_REPOS+="### Owner Next Actions\n\n"
    while IFS= read -r action; do
      [[ -z "$action" ]] && continue
      MD_REPOS+="- $action\n"
    done <<< "$OWNER_ACTIONS"
    MD_REPOS+="\n"
  fi

  # ─── JSON output ─────────────────────────────────────────────────────
  [[ -n "$JSON_REPOS" ]] && JSON_REPOS+=","
  JSON_REPOS+="{\"name\":\"$REPO_NAME\",\"status\":\"$REPO_STATUS\",\"release_gate\":\"$GATE_STATUS\",\"codeowners\":\"$CODEOWNERS_STATUS\",\"trust_policy\":\"$TRUST_POLICY_STATUS\",\"branch_protection\":\"$BP_STATUS\",\"manual_evidence\":\"$MANUAL_EVIDENCE_STATUS\",\"classification\":\"$CLASSIFICATION\",\"baseline_failures\":$BF_COUNT}"

done <<< "$REPO_NAMES"

# ─── Generate executive summary ────────────────────────────────────────
EXEC_SUMMARY="## 📊 Executive Summary\n\n"
EXEC_SUMMARY+="| Metric | Count |\n"
EXEC_SUMMARY+="|--------|-------|\n"
EXEC_SUMMARY+="| Total Repos | $((TOTAL_ACTIVE + TOTAL_EXCLUDED)) |\n"
EXEC_SUMMARY+="| Active Repos | $TOTAL_ACTIVE |\n"
EXEC_SUMMARY+="| Excluded Repos | $TOTAL_EXCLUDED |\n"
EXEC_SUMMARY+="| Release Gate Installed | $GATE_INSTALLED / $TOTAL_ACTIVE |\n"
EXEC_SUMMARY+="| CODEOWNERS Verified | $CODEOWNERS_VERIFIED / $TOTAL_ACTIVE |\n"
EXEC_SUMMARY+="| Branch Protection Verified | $BRANCH_PROTECTION_VERIFIED / $TOTAL_ACTIVE |\n"
EXEC_SUMMARY+="| Manually Verified | $MANUALLY_VERIFIED / $TOTAL_ACTIVE |\n"
EXEC_SUMMARY+="| Unknown Permission Limited | $UNKNOWN_PERMISSION / $TOTAL_ACTIVE |\n"
EXEC_SUMMARY+="| Known Baseline Failures | $BASELINE_FAILURES |\n"

# ─── Write markdown ────────────────────────────────────────────────────
MD_FILE="$OUTPUT_DIR/fleet-dashboard.md"
{
  echo "<!-- fleet-dashboard -->"
  echo "# 🛡️ Fleet Protection Dashboard"
  echo ""
  echo "**Generated:** $TIMESTAMP"
  echo ""
  echo "---"
  echo ""
  echo -e "$EXEC_SUMMARY"
  echo "---"
  echo ""
  echo -e "$MD_REPOS"
  if [[ -n "$MD_EXCLUDED" ]]; then
    echo -e "$MD_EXCLUDED"
  fi
  echo "---"
  echo "*Generated by v4.40 Fleet Dashboard Generator*"
} > "$MD_FILE"

# ─── Write JSON ─────────────────────────────────────────────────────────
JSON_FILE="$OUTPUT_DIR/fleet-dashboard.json"
cat > "$JSON_FILE" << ENDJSON
{
  "generated": "$TIMESTAMP",
  "repos": [$JSON_REPOS],
  "summary": {
    "total_repos": $((TOTAL_ACTIVE + TOTAL_EXCLUDED)),
    "active_repos": $TOTAL_ACTIVE,
    "excluded_repos": $TOTAL_EXCLUDED,
    "gate_installed": $GATE_INSTALLED,
    "codeowners_verified": $CODEOWNERS_VERIFIED,
    "branch_protection_verified": $BRANCH_PROTECTION_VERIFIED,
    "manually_verified": $MANUALLY_VERIFIED,
    "unknown_permission": $UNKNOWN_PERMISSION,
    "baseline_failures": $BASELINE_FAILURES
  }
}
ENDJSON

# Pretty-print JSON if jq is available
if command -v jq &> /dev/null; then
  jq '.' "$JSON_FILE" > "${JSON_FILE}.tmp" && mv "${JSON_FILE}.tmp" "$JSON_FILE"
fi

echo ""
echo "[fleet-dashboard] ✅ Dashboard generated:"
echo "  Markdown: $MD_FILE"
echo "  JSON: $JSON_FILE"
echo ""
echo "[fleet-dashboard] Summary:"
echo "  Active: $TOTAL_ACTIVE | Excluded: $TOTAL_EXCLUDED"
echo "  Gate installed: $GATE_INSTALLED | CODEOWNERS: $CODEOWNERS_VERIFIED"
echo "  Branch protection verified: $BRANCH_PROTECTION_VERIFIED | Unknown: $UNKNOWN_PERMISSION"
echo "  Manually verified: $MANUALLY_VERIFIED"
echo "  Baseline failures: $BASELINE_FAILURES"
