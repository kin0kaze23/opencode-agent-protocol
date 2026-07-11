#!/usr/bin/env bash
# reviewer-evidence-detector.sh — v4.36 Reviewer Evidence Detector
#
# Detects trusted reviewer evidence for a PR using GitHub CLI.
# v4.36: Adds stale approval handling, PR author exclusion, trust policy.
#
# Checks for:
#   1. GitHub PR review approval (APPROVED state)
#      - Excludes approvals from PR author
#      - Verifies approval matches current head SHA (if require_fresh_approval)
#      - Optionally restricts to trusted_reviewers allowlist
#   2. Maintainer-applied trusted label (if allow_label_evidence)
#
# Does NOT trust:
#   - PR body text claiming reviewer was used
#   - Changed telemetry files in the PR diff
#   - Any file modified by the PR author
#   - Approvals from the PR author
#   - Stale approvals (on older commits, if require_fresh_approval)
#
# Usage:
#   bash reviewer-evidence-detector.sh --pr <number> [--repo <owner/repo>]
#   bash reviewer-evidence-detector.sh --evidence-file <file>  (for testing)
#
# Non-blocking: exits 0 always (advisory output only).

set -uo pipefail

PR_NUMBER=""
REPO=""
EVIDENCE_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr) PR_NUMBER="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --evidence-file) EVIDENCE_FILE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Default values
EVIDENCE_FOUND="false"
EVIDENCE_TYPE="none"
REVIEWER_IDENTITY="unknown"
EVIDENCE_TRUSTED="false"
REASON="No reviewer evidence found"
REVIEWER_IS_AUTHOR="false"
APPROVAL_FRESH="unknown"
TRUST_POLICY_SOURCE="default"

# ─── Load trust policy ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
POLICY_FILE="$SCRIPT_DIR/../config/reviewer-trust-policy.yaml"

ALLOW_LABEL_EVIDENCE="true"
REQUIRE_FRESH_APPROVAL="true"
TRUSTED_REVIEWERS=""
TRUSTED_LABELS="reviewer-approved"

if [[ -f "$POLICY_FILE" ]]; then
  TRUST_POLICY_SOURCE="config"
  # Parse simple YAML with grep
  ALLOW_LABEL_EVIDENCE=$(grep -E "^allow_label_evidence:" "$POLICY_FILE" 2>/dev/null | awk '{print $2}' || echo "true")
  REQUIRE_FRESH_APPROVAL=$(grep -E "^require_fresh_approval:" "$POLICY_FILE" 2>/dev/null | awk '{print $2}' || echo "true")
  # Parse trusted_labels list — use precise sed that only strips YAML list marker
  TRUSTED_LABELS=$(sed -n '/^trusted_labels:/,/^$/p' "$POLICY_FILE" 2>/dev/null | grep -E '^[[:space:]]+-' | sed 's/^[[:space:]]*-[[:space:]]*//' | tr '\n' ',' | sed 's/,$//' || echo "reviewer-approved")
  # Parse trusted_reviewers list
  TRUSTED_REVIEWERS=$(sed -n '/^trusted_reviewers:/,/^$/p' "$POLICY_FILE" 2>/dev/null | grep -E '^[[:space:]]+-' | sed 's/^[[:space:]]*-[[:space:]]*//' | tr '\n' ',' | sed 's/,$//' || echo "")
fi

# ─── Mode 1: Read from precomputed evidence file (for testing) ──────────
if [[ -n "$EVIDENCE_FILE" && -f "$EVIDENCE_FILE" ]]; then
  EVIDENCE_FOUND=$(grep "reviewer_evidence_found:" "$EVIDENCE_FILE" | awk '{print $2}')
  EVIDENCE_TYPE=$(grep "evidence_type:" "$EVIDENCE_FILE" | awk '{print $2}')
  REVIEWER_IDENTITY=$(grep "reviewer_identity:" "$EVIDENCE_FILE" | awk '{print $2}')
  EVIDENCE_TRUSTED=$(grep "evidence_trusted:" "$EVIDENCE_FILE" | awk '{print $2}')
  REASON=$(grep "reason:" "$EVIDENCE_FILE" | sed 's/.*reason: //')
  REVIEWER_IS_AUTHOR=$(grep "reviewer_is_author:" "$EVIDENCE_FILE" 2>/dev/null | awk '{print $2}' || echo "false")
  APPROVAL_FRESH=$(grep "approval_fresh:" "$EVIDENCE_FILE" 2>/dev/null | awk '{print $2}' || echo "unknown")

  echo "REVIEWER_EVIDENCE:"
  echo "  reviewer_evidence_found: ${EVIDENCE_FOUND:-false}"
  echo "  evidence_type: ${EVIDENCE_TYPE:-none}"
  echo "  reviewer_identity: ${REVIEWER_IDENTITY:-unknown}"
  echo "  evidence_trusted: ${EVIDENCE_TRUSTED:-false}"
  echo "  reviewer_is_author: ${REVIEWER_IS_AUTHOR:-false}"
  echo "  approval_fresh: ${APPROVAL_FRESH:-unknown}"
  echo "  trust_policy_source: $TRUST_POLICY_SOURCE"
  echo "  reason: ${REASON:-No reviewer evidence found}"
  exit 0
fi

# ─── Mode 2: Query GitHub via gh CLI ─────────────────────────────────────
if [[ -z "$PR_NUMBER" ]]; then
  REASON="No PR number provided — cannot check reviewer evidence"
  echo "REVIEWER_EVIDENCE:"
  echo "  reviewer_evidence_found: $EVIDENCE_FOUND"
  echo "  evidence_type: $EVIDENCE_TYPE"
  echo "  reviewer_identity: $REVIEWER_IDENTITY"
  echo "  evidence_trusted: $EVIDENCE_TRUSTED"
  echo "  reviewer_is_author: $REVIEWER_IS_AUTHOR"
  echo "  approval_fresh: $APPROVAL_FRESH"
  echo "  trust_policy_source: $TRUST_POLICY_SOURCE"
  echo "  reason: $REASON"
  exit 0
fi

# Check if gh CLI is available
if ! command -v gh &>/dev/null; then
  REASON="gh CLI not available — cannot check reviewer evidence"
  echo "REVIEWER_EVIDENCE:"
  echo "  reviewer_evidence_found: $EVIDENCE_FOUND"
  echo "  evidence_type: $EVIDENCE_TYPE"
  echo "  reviewer_identity: $REVIEWER_IDENTITY"
  echo "  evidence_trusted: $EVIDENCE_TRUSTED"
  echo "  reviewer_is_author: $REVIEWER_IS_AUTHOR"
  echo "  approval_fresh: $APPROVAL_FRESH"
  echo "  trust_policy_source: $TRUST_POLICY_SOURCE"
  echo "  reason: $REASON"
  exit 0
fi

GH_ARGS=""
if [[ -n "$REPO" ]]; then
  GH_ARGS="--repo $REPO"
fi

# ─── Fetch PR author and head SHA ────────────────────────────────────────
PR_AUTHOR=""
PR_HEAD_SHA=""

if command -v jq &>/dev/null; then
  PR_AUTHOR=$(gh pr view "$PR_NUMBER" $GH_ARGS --json author --jq '.author.login' 2>/dev/null || echo "")
  PR_HEAD_SHA=$(gh pr view "$PR_NUMBER" $GH_ARGS --json headRefOid --jq '.headRefOid' 2>/dev/null || echo "")
else
  PR_JSON=$(gh pr view "$PR_NUMBER" $GH_ARGS --json author,headRefOid 2>/dev/null || echo "")
  PR_AUTHOR=$(echo "$PR_JSON" | grep -o '"login":"[^"]*"' | head -1 | sed 's/"login":"//;s/"//' || echo "")
  PR_HEAD_SHA=$(echo "$PR_JSON" | grep -o '"headRefOid":"[^"]*"' | head -1 | sed 's/"headRefOid":"//;s/"//' || echo "")
fi

# ─── Check 1: GitHub PR review approval (APPROVED state) ─────────────────
REVIEWS_JSON=$(gh pr view "$PR_NUMBER" $GH_ARGS --json reviews 2>/dev/null || echo "")

if [[ -n "$REVIEWS_JSON" && "$REVIEWS_JSON" != "null" ]]; then
  if command -v jq &>/dev/null; then
    # Get all approving reviews with author and commit_id
    APPROVED_COUNT=$(echo "$REVIEWS_JSON" | jq -r '[.reviews[] | select(.state == "APPROVED")] | length' 2>/dev/null || echo "0")

    if [[ "$APPROVED_COUNT" -gt 0 ]]; then
      # Iterate through approvals to find a valid one
      for i in $(seq 0 $((APPROVED_COUNT - 1))); do
        REVIEWER_LOGIN=$(echo "$REVIEWS_JSON" | jq -r ".reviews[] | select(.state == \"APPROVED\") | .author.login" 2>/dev/null | sed -n "$((i + 1))p" || echo "")
        REVIEW_COMMIT=$(echo "$REVIEWS_JSON" | jq -r ".reviews[] | select(.state == \"APPROVED\") | .commit_id" 2>/dev/null | sed -n "$((i + 1))p" || echo "")

        # v4.36: Exclude PR author approvals
        if [[ -n "$PR_AUTHOR" && "$REVIEWER_LOGIN" == "$PR_AUTHOR" ]]; then
          REVIEWER_IS_AUTHOR="true"
          continue  # Skip author's own approval
        fi

        # v4.36: Check trusted_reviewers allowlist (if non-empty)
        if [[ -n "$TRUSTED_REVIEWERS" ]]; then
          if ! echo "$TRUSTED_REVIEWERS" | grep -q "$REVIEWER_LOGIN"; then
            continue  # Skip non-allowlisted reviewer
          fi
        fi

        # v4.36: Check stale approval (if require_fresh_approval)
        if [[ "$REQUIRE_FRESH_APPROVAL" == "true" && -n "$PR_HEAD_SHA" && -n "$REVIEW_COMMIT" && "$REVIEW_COMMIT" != "null" ]]; then
          if [[ "$REVIEW_COMMIT" != "$PR_HEAD_SHA" ]]; then
            APPROVAL_FRESH="stale"
            continue  # Skip stale approval
          fi
          APPROVAL_FRESH="true"
        else
          APPROVAL_FRESH="unknown"
        fi

        # Found a valid approval
        EVIDENCE_FOUND="true"
        EVIDENCE_TYPE="github_review"
        REVIEWER_IDENTITY="$REVIEWER_LOGIN"
        EVIDENCE_TRUSTED="true"
        if [[ "$APPROVAL_FRESH" == "true" ]]; then
          REASON="GitHub approving review from $REVIEWER_IDENTITY (fresh, matches current head)"
        else
          REASON="GitHub approving review from $REVIEWER_IDENTITY"
        fi
        break
      done

      # If no valid approval found but approvals exist
      if [[ "$EVIDENCE_FOUND" == "false" ]]; then
        if [[ "$REVIEWER_IS_AUTHOR" == "true" ]]; then
          REASON="Only approval found was from PR author — not trusted"
        elif [[ "$APPROVAL_FRESH" == "stale" ]]; then
          REASON="Approving review found but is stale (does not match current head SHA)"
        else
          REASON="Approving review found but did not pass trust policy checks"
        fi
      fi
    fi
  else
    # Fallback without jq — basic check only
    if echo "$REVIEWS_JSON" | grep -q '"state":"APPROVED"'; then
      EVIDENCE_FOUND="true"
      EVIDENCE_TYPE="github_review"
      REVIEWER_IDENTITY="approved-reviewer"
      EVIDENCE_TRUSTED="true"
      REASON="GitHub approving review detected"
    fi
  fi
fi

# ─── Check 2: Trusted label (if allow_label_evidence) ───────────────────
if [[ "$EVIDENCE_FOUND" == "false" && "$ALLOW_LABEL_EVIDENCE" == "true" ]]; then
  LABELS_JSON=$(gh pr view "$PR_NUMBER" $GH_ARGS --json labels 2>/dev/null || echo "")

  if [[ -n "$LABELS_JSON" && "$LABELS_JSON" != "null" ]]; then
    # Check each trusted label
    IFS=',' read -ra LABEL_ARRAY <<< "$TRUSTED_LABELS"
    for label in "${LABEL_ARRAY[@]}"; do
      label=$(echo "$label" | xargs)  # trim whitespace
      if command -v jq &>/dev/null; then
        # v4.36.1a: Use exact match (-x) to prevent "approved" matching "reviewer-approved"
        HAS_LABEL=$(echo "$LABELS_JSON" | jq -r '.labels[].name' 2>/dev/null | grep -qxi "$label" && echo "true" || echo "false")
      else
        HAS_LABEL=$(echo "$LABELS_JSON" | grep -qoi "\"$label\"" && echo "true" || echo "false")
      fi

      if [[ "$HAS_LABEL" == "true" ]]; then
        EVIDENCE_FOUND="true"
        EVIDENCE_TYPE="trusted_label"
        REVIEWER_IDENTITY="maintainer"
        EVIDENCE_TRUSTED="true"
        REASON="Trusted label '$label' applied by maintainer"
        break
      fi
    done
  fi
fi

# ─── Fork PR safety: if gh failed to read reviews/labels ─────────────────
if [[ "$EVIDENCE_FOUND" == "false" && -z "$REVIEWS_JSON" && -z "$PR_AUTHOR" ]]; then
  REASON="Unable to verify reviewer evidence — gh CLI may lack permissions for this PR (fork PR?)"
fi

# ─── Output ──────────────────────────────────────────────────────────────
echo "REVIEWER_EVIDENCE:"
echo "  reviewer_evidence_found: $EVIDENCE_FOUND"
echo "  evidence_type: $EVIDENCE_TYPE"
echo "  reviewer_identity: $REVIEWER_IDENTITY"
echo "  evidence_trusted: $EVIDENCE_TRUSTED"
echo "  reviewer_is_author: $REVIEWER_IS_AUTHOR"
echo "  approval_fresh: $APPROVAL_FRESH"
echo "  trust_policy_source: $TRUST_POLICY_SOURCE"
echo "  reason: $REASON"
