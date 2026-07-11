#!/usr/bin/env bash
# verify-branch-protection.sh — v4.38 Branch Protection Verifier
#
# Inspects a target repo's branch protection rules using gh API.
# Reports whether the Release Gate and related checks are required.
# Handles 403 (private repo without Pro) gracefully.
#
# Usage:
#   bash verify-branch-protection.sh [--repo <path>] [--branch <name>] [--strict]
#
# Exit codes:
#   0 — verified or advisory (non-strict mode)
#   1 — not configured or misconfigured (strict mode)
#   2 — permission limited (cannot verify)

set -uo pipefail

REPO_PATH="."
BRANCH="main"
STRICT="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO_PATH="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --strict) STRICT="true"; shift ;;
    *) shift ;;
  esac
done

PASS=0
FAIL=0
WARN=0
PERMISSION_LIMITED="false"

check_pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
check_fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
check_warn() { echo "  ⚠️  $1"; WARN=$((WARN + 1)); }

echo "=== Branch Protection Verifier ==="
echo "Repo: $REPO_PATH"
echo "Branch: $BRANCH"
echo "Mode: $([ "$STRICT" == "true" ] && echo "STRICT" || echo "ADVISORY")"
echo ""

# ─── Get repo full name ──────────────────────────────────────────────────
REPO_FULL_NAME=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null)
if [[ -z "$REPO_FULL_NAME" ]]; then
  # Try from git remote
  REMOTE_URL=$(git -C "$REPO_PATH" remote get-url origin 2>/dev/null || echo "")
  if echo "$REMOTE_URL" | grep -q "github.com"; then
    REPO_FULL_NAME=$(echo "$REMOTE_URL" | sed 's|.*github.com[:/]||' | sed 's|\.git$||')
  fi
fi

if [[ -z "$REPO_FULL_NAME" ]]; then
  echo "ERROR: Could not determine repo name from git remote"
  exit 2
fi

echo "Repo: $REPO_FULL_NAME"
echo ""

# ─── Fetch branch protection ────────────────────────────────────────────
echo "== Branch Protection Status =="
PROTECTION_JSON=$(gh api "repos/$REPO_FULL_NAME/branches/$BRANCH/protection" 2>&1)

if echo "$PROTECTION_JSON" | jq -e '.message' 2>/dev/null | grep -q "Branch not protected"; then
  echo "  ❌ Branch protection NOT configured for '$BRANCH'"
  echo ""
  echo "=========================================="
  echo "Classification: not_configured"
  echo "=========================================="
  if [[ "$STRICT" == "true" ]]; then exit 1; fi
  exit 0
fi

if echo "$PROTECTION_JSON" | jq -e '.message' 2>/dev/null | grep -q "403"; then
  echo "  ⚠️  Branch protection API returned 403 (likely private repo without GitHub Pro)"
  echo "  Cannot verify branch protection via API."
  echo "  Manual check required: Settings → Branches → Branch protection rules"
  PERMISSION_LIMITED="true"
elif echo "$PROTECTION_JSON" | jq -e '.message' 2>/dev/null | grep -q "Not Found"; then
  echo "  ❌ Branch protection NOT configured for '$BRANCH'"
  echo ""
  echo "=========================================="
  echo "Classification: not_configured"
  echo "=========================================="
  if [[ "$STRICT" == "true" ]]; then exit 1; fi
  exit 0
elif ! echo "$PROTECTION_JSON" | jq -e '.' >/dev/null 2>&1; then
  echo "  ⚠️  Could not parse branch protection API response"
  echo "  Raw: $(echo "$PROTECTION_JSON" | head -3)"
  PERMISSION_LIMITED="true"
else
  # ─── Parse protection rules ───────────────────────────────────────────
  echo "  ✅ Branch protection is configured for '$BRANCH'"
  PASS=$((PASS + 1))

  # Required status checks
  echo ""
  echo "== Required Status Checks =="
  REQUIRED_CHECKS=$(echo "$PROTECTION_JSON" | jq -r '.required_status_checks.contexts // [] | .[]' 2>/dev/null)
  CHECKS_ENFORCED=$(echo "$PROTECTION_JSON" | jq -r '.required_status_checks.strict // false' 2>/dev/null)

  if [[ -z "$REQUIRED_CHECKS" || "$REQUIRED_CHECKS" == "" ]]; then
    check_fail "No required status checks configured"
  else
    check_pass "Required status checks configured"
    echo "    Required checks:"
    echo "$REQUIRED_CHECKS" | while read -r check; do
      echo "      - $check"
    done

    # Check for Release Gate
    if echo "$REQUIRED_CHECKS" | grep -qi "release gate"; then
      check_pass "Release Gate is a required check"
    else
      check_fail "Release Gate is NOT a required check"
    fi

    # Check for build/test
    if echo "$REQUIRED_CHECKS" | grep -qi "build"; then
      check_pass "Build check is required"
    else
      check_warn "Build check is not explicitly required"
    fi

    # Check for secret scanning
    if echo "$REQUIRED_CHECKS" | grep -qi "gitleaks\|secret"; then
      check_pass "Secret scanning check is required"
    else
      check_warn "Secret scanning check is not explicitly required"
    fi
  fi

  # Strict status checks (dismiss stale approvals on new commits)
  echo ""
  echo "== Stale Approval Dismissal =="
  if [[ "$CHECKS_ENFORCED" == "true" ]]; then
    check_pass "Stale approvals are dismissed on new commits (strict: true)"
  else
    check_warn "Stale approvals may NOT be dismissed (strict: false)"
  fi

  # Required reviews
  echo ""
  echo "== Required Reviews =="
  REQUIRED_REVIEWS=$(echo "$PROTECTION_JSON" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0' 2>/dev/null)
  DISMISS_STALE=$(echo "$PROTECTION_JSON" | jq -r '.required_pull_request_reviews.dismiss_stale_reviews // false' 2>/dev/null)

  if [[ "$REQUIRED_REVIEWS" -gt 0 ]] 2>/dev/null; then
    check_pass "Approving reviews required: $REQUIRED_REVIEWS"
  else
    check_warn "No approving reviews required"
  fi

  if [[ "$DISMISS_STALE" == "true" ]]; then
    check_pass "Stale reviews are dismissed on new commits"
  else
    check_warn "Stale reviews may NOT be dismissed"
  fi

  # Allow force pushes
  echo ""
  echo "== Direct Push Restrictions =="
  ALLOW_FORCE=$(echo "$PROTECTION_JSON" | jq -r '.allow_force_pushes.enabled // false' 2>/dev/null)
  if [[ "$ALLOW_FORCE" == "true" ]]; then
    check_fail "Force pushes are ALLOWED to $BRANCH"
  else
    check_pass "Force pushes are blocked to $BRANCH"
  fi

  # Enforce admins
  echo ""
  echo "== Admin Enforcement =="
  ENFORCE_ADMINS=$(echo "$PROTECTION_JSON" | jq -r '.enforce_admins.enabled // false' 2>/dev/null)
  if [[ "$ENFORCE_ADMINS" == "true" ]]; then
    check_pass "Rules are enforced for admins"
  else
    check_warn "Rules may NOT be enforced for admins"
  fi
fi

# ─── Summary ────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "PASSED: $PASS"
echo "FAILED: $FAIL"
echo "WARNINGS: $WARN"
echo "=========================================="

if [[ "$PERMISSION_LIMITED" == "true" ]]; then
  echo "Classification: unknown_permission_limited"
  echo "Note: Cannot verify via API. Manual check required."
  exit 2
fi

if [[ "$FAIL" -gt 0 ]]; then
  echo "Classification: blocked_misconfigured"
  if [[ "$STRICT" == "true" ]]; then exit 1; fi
  exit 0
fi

if [[ "$WARN" -gt 0 ]]; then
  echo "Classification: partially_protected"
else
  echo "Classification: verified"
fi

exit 0
