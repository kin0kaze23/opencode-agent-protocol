#!/usr/bin/env bash
# post-release-gate-comment.sh — v4.39 PR Comment / Annotations
#
# Posts or updates a sticky PR comment with the release gate result.
# Uses a stable HTML comment marker to find and update existing comments.
# Fails gracefully if PR comment permissions are unavailable.
#
# Usage:
#   bash post-release-gate-comment.sh [--pr <number>] [--strict]
#
# Environment variables (from gate step outputs):
#   RELEASE_STATUS, RISK_LEVEL, ENFORCEMENT_STATUS, SENSITIVE_AREAS,
#   REVIEWER_REQUIRED, REVIEWER_EVIDENCE_FOUND, EVIDENCE_TYPE,
#   EVIDENCE_TRUSTED, MATCHED_PATTERNS, DETECTION_TYPE
#
# Exit codes:
#   0 — comment posted or skipped (non-strict mode)
#   1 — comment failed (strict mode)

set -uo pipefail

PR_NUMBER="${GITHUB_EVENT_PULL_REQUEST_NUMBER:-}"
STRICT="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr) PR_NUMBER="$2"; shift 2 ;;
    --strict) STRICT="true"; shift ;;
    *) shift ;;
  esac
done

# ─── Gate data from environment ──────────────────────────────────────────
RELEASE_STATUS="${RELEASE_STATUS:-pass}"
RISK_LEVEL="${RISK_LEVEL:-none}"
ENFORCEMENT_STATUS="${ENFORCEMENT_STATUS:-pass}"
SENSITIVE_AREAS="${SENSITIVE_AREAS:-none}"
REVIEWER_REQUIRED="${REVIEWER_REQUIRED:-false}"
REVIEWER_EVIDENCE_FOUND="${REVIEWER_EVIDENCE_FOUND:-false}"
EVIDENCE_TYPE="${EVIDENCE_TYPE:-none}"
EVIDENCE_TRUSTED="${EVIDENCE_TRUSTED:-false}"
MATCHED_PATTERNS="${MATCHED_PATTERNS:-none}"
DETECTION_TYPE="${DETECTION_TYPE:-none}"
REPO_ROOT="${GITHUB_WORKSPACE:-.}"

COMMENT_MARKER="<!-- opencode-release-gate-comment -->"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# ─── Status icons ────────────────────────────────────────────────────────
case "$ENFORCEMENT_STATUS" in
  pass) STATUS_ICON="✅" ;;
  advisory) STATUS_ICON="⚠️" ;;
  block) STATUS_ICON="🚫" ;;
  *) STATUS_ICON="❓" ;;
esac

case "$RISK_LEVEL" in
  high) RISK_ICON="🔴" ;;
  medium) RISK_ICON="🟡" ;;
  none) RISK_ICON="🟢" ;;
  *) RISK_ICON="⚪" ;;
esac

# ─── Local protection checks (lightweight, no API calls) ────────────────
CODEOWNERS_STATUS="unknown"
if [[ -f "$REPO_ROOT/.github/CODEOWNERS" ]]; then
  CODEOWNERS_STATUS="✅ present"
elif [[ -f "$REPO_ROOT/CODEOWNERS" ]]; then
  CODEOWNERS_STATUS="✅ present"
else
  CODEOWNERS_STATUS="❌ missing"
fi

TRUST_POLICY_STATUS="unknown"
if [[ -f "$REPO_ROOT/.opencode/config/reviewer-trust-policy.yaml" ]]; then
  TRUST_POLICY_STATUS="✅ installed"
else
  TRUST_POLICY_STATUS="❌ missing"
fi

BRANCH_PROTECTION_STATUS="⚠️ unknown (API permission limited)"

# ─── Owner next action ──────────────────────────────────────────────────
OWNER_ACTION=""
if [[ "$ENFORCEMENT_STATUS" == "block" ]]; then
  if [[ "$RISK_LEVEL" == "high" && "$EVIDENCE_TRUSTED" != "true" ]]; then
    OWNER_ACTION="🚫 **BLOCKED**: High-risk sensitive change requires reviewer evidence.
To unblock: Get a GitHub approving review, or apply the \`reviewer-approved\` label if label evidence is enabled."
  else
    OWNER_ACTION="🚫 **BLOCKED**: Resolve expired allowed failure or policy violation before merge."
  fi
elif [[ "$RISK_LEVEL" == "high" ]]; then
  OWNER_ACTION="⚠️ High-risk change with trusted reviewer evidence. Ensure full tests pass before merge."
elif [[ "$RISK_LEVEL" == "medium" ]]; then
  OWNER_ACTION="⚠️ Medium-risk changes detected. Reviewer recommended but not blocking."
else
  OWNER_ACTION="✅ No action required — safe to merge."
fi

# Add branch protection note
if [[ "$BRANCH_PROTECTION_STATUS" == *"unknown"* ]]; then
  OWNER_ACTION="$OWNER_ACTION
⚠️ Branch protection could not be verified (private repo / GitHub plan). Configure manually in Settings → Branches."
fi

# ─── Generate markdown comment ──────────────────────────────────────────
read -r -d '' COMMENT_BODY << EOF || true
$COMMENT_MARKER
## 🛡️ Release Gate

| Field | Value |
|-------|-------|
| Release Status | $STATUS_ICON $RELEASE_STATUS |
| Risk Level | $RISK_ICON $RISK_LEVEL |
| Enforcement | $ENFORCEMENT_STATUS |
| Sensitive Areas | $SENSITIVE_AREAS |
| Detection Type | $DETECTION_TYPE |

### 👤 Reviewer Evidence

| Field | Value |
|-------|-------|
| Reviewer Required | $REVIEWER_REQUIRED |
| Evidence Found | $REVIEWER_EVIDENCE_FOUND |
| Evidence Type | $EVIDENCE_TYPE |
| Evidence Trusted | $EVIDENCE_TRUSTED |

### 🔒 Protection Status

| Check | Status |
|-------|--------|
| CODEOWNERS | $CODEOWNERS_STATUS |
| Branch Protection | $BRANCH_PROTECTION_STATUS |
| Trust Policy | $TRUST_POLICY_STATUS |

### 📋 Owner Next Action

$OWNER_ACTION

---
*Updated: $TIMESTAMP | Release Gate v4.39*
EOF

# ─── Post or update sticky comment ──────────────────────────────────────
if [[ -z "$PR_NUMBER" ]]; then
  echo "[post-release-gate-comment] No PR number — skipping comment"
  exit 0
fi

# Get repo full name
REPO_FULL_NAME=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
if [[ -z "$REPO_FULL_NAME" ]]; then
  REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
  if echo "$REMOTE_URL" | grep -q "github.com"; then
    REPO_FULL_NAME=$(echo "$REMOTE_URL" | sed 's|.*github.com[:/]||' | sed 's|\.git$||')
  fi
fi

if [[ -z "$REPO_FULL_NAME" ]]; then
  echo "[post-release-gate-comment] Could not determine repo name — skipping comment"
  if [[ "$STRICT" == "true" ]]; then exit 1; fi
  exit 0
fi

echo "[post-release-gate-comment] Posting comment to PR #$PR_NUMBER in $REPO_FULL_NAME"

# Find existing comment with marker
EXISTING_COMMENT_ID=$(gh api "repos/$REPO_FULL_NAME/issues/$PR_NUMBER/comments" \
  --jq ".[] | select(.body | contains(\"$COMMENT_MARKER\")) | .id" 2>/dev/null | head -1)

if [[ -n "$EXISTING_COMMENT_ID" ]]; then
  # Update existing comment
  echo "[post-release-gate-comment] Updating existing comment (ID: $EXISTING_COMMENT_ID)"
  gh api "repos/$REPO_FULL_NAME/issues/comments/$EXISTING_COMMENT_ID" \
    -X PATCH \
    -f body="$COMMENT_BODY" 2>/dev/null

  if [[ $? -eq 0 ]]; then
    echo "[post-release-gate-comment] ✅ Comment updated"
  else
    echo "[post-release-gate-comment] ⚠️ Failed to update comment"
    if [[ "$STRICT" == "true" ]]; then exit 1; fi
  fi
else
  # Create new comment
  echo "[post-release-gate-comment] Creating new comment"
  gh pr comment "$PR_NUMBER" --body "$COMMENT_BODY" 2>/dev/null

  if [[ $? -eq 0 ]]; then
    echo "[post-release-gate-comment] ✅ Comment posted"
  else
    echo "[post-release-gate-comment] ⚠️ Failed to post comment (permission denied?)"
    if [[ "$STRICT" == "true" ]]; then exit 1; fi
  fi
fi

exit 0
