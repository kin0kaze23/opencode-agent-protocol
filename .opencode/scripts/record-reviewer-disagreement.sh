#!/usr/bin/env bash
# record-reviewer-disagreement.sh — v4.49 Disagreement Tracker
#
# Records cases where implementer and reviewer disagree.
#
# Usage: bash record-reviewer-disagreement.sh [options]
#
# Options:
#   --finding-id <id>       Related finding ID
#   --type <type>           Disagreement type: implementer_disagrees, owner_accepts, owner_rejects, reviewer_missed, gate_caught
#   --description <text>    Description of disagreement
#   --reviewer-position <text>  Reviewer's position
#   --implementer-position <text> Implementer's position
#   --owner-decision <text>     Owner's decision
#   --outcome <outcome>     true_positive, false_positive, false_negative, unresolved
#   --list                  List all disagreements
#   --help                  Show this help

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DISAGREEMENTS_FILE="$WORKSPACE_ROOT/.opencode/metrics/reviewer-calibration/disagreements.jsonl"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

mkdir -p "$(dirname "$DISAGREEMENTS_FILE")"

# ─── Defaults ────────────────────────────────────────────────────────────
FINDING_ID=""
DISAGREEMENT_TYPE=""
DESCRIPTION=""
REVIEWER_POSITION=""
IMPLEMENTER_POSITION=""
OWNER_DECISION=""
OUTCOME="unresolved"
LIST_MODE=false

# ─── Parse arguments ─────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --finding-id)           FINDING_ID="$2"; shift 2 ;;
    --type)                 DISAGREEMENT_TYPE="$2"; shift 2 ;;
    --description)          DESCRIPTION="$2"; shift 2 ;;
    --reviewer-position)    REVIEWER_POSITION="$2"; shift 2 ;;
    --implementer-position) IMPLEMENTER_POSITION="$2"; shift 2 ;;
    --owner-decision)       OWNER_DECISION="$2"; shift 2 ;;
    --outcome)              OUTCOME="$2"; shift 2 ;;
    --list)                 LIST_MODE=true; shift ;;
    --help|-h)              head -20 "$0"; exit 0 ;;
    *) shift ;;
  esac
done

# ─── List mode ──────────────────────────────────────────────────────────
if [[ "$LIST_MODE" == true ]]; then
  echo "=== Reviewer Disagreements ==="
  echo ""
  if [[ ! -f "$DISAGREEMENTS_FILE" ]] || [[ ! -s "$DISAGREEMENTS_FILE" ]]; then
    echo "No disagreements recorded."
    exit 0
  fi
  cat "$DISAGREEMENTS_FILE" | jq -c '{id: .disagreement_id, type: .disagreement_type, outcome: .outcome, description: .description}' 2>/dev/null
  exit 0
fi

# ─── Validate required fields ────────────────────────────────────────────
if [[ -z "$DISAGREEMENT_TYPE" ]]; then
  echo "ERROR: --type is required"
  exit 1
fi

if [[ -z "$DESCRIPTION" ]]; then
  echo "ERROR: --description is required"
  exit 1
fi

# ─── Generate disagreement ID ────────────────────────────────────────────
EXISTING_COUNT=$(wc -l < "$DISAGREEMENTS_FILE" 2>/dev/null | tr -d ' ' || echo 0)
DISAGREEMENT_ID="RD-$(printf '%03d' $((EXISTING_COUNT + 1)))"

# ─── Record disagreement ─────────────────────────────────────────────────
RECORD=$(cat << EOF
{
  "disagreement_id": "$DISAGREEMENT_ID",
  "finding_id": "$FINDING_ID",
  "disagreement_type": "$DISAGREEMENT_TYPE",
  "description": "$DESCRIPTION",
  "reviewer_position": "$REVIEWER_POSITION",
  "implementer_position": "$IMPLEMENTER_POSITION",
  "owner_decision": "$OWNER_DECISION",
  "outcome": "$OUTCOME",
  "recorded_at": "$TIMESTAMP"
}
EOF
)

echo "$RECORD" | jq -c '.' >> "$DISAGREEMENTS_FILE"

echo "[disagreement] Recorded: $DISAGREEMENT_ID"
echo "[disagreement] Type: $DISAGREEMENT_TYPE"
echo "[disagreement] Outcome: $OUTCOME"
echo "[disagreement] Saved to: $DISAGREEMENTS_FILE"
