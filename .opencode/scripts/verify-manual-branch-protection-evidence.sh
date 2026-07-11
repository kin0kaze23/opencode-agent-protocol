#!/usr/bin/env bash
# verify-manual-branch-protection-evidence.sh — v4.41 Manual Evidence Validator
#
# Validates manual branch protection evidence recorded in
# branch-protection-evidence.yaml.
#
# Usage:
#   bash verify-manual-branch-protection-evidence.sh [--repo <name>] [--strict]
#
# Exit codes:
#   0 — evidence valid or advisory (non-strict mode)
#   1 — evidence invalid or missing (strict mode)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EVIDENCE_FILE="$WORKSPACE_ROOT/.opencode/config/branch-protection-evidence.yaml"
FLEET_CONFIG="$WORKSPACE_ROOT/.opencode/config/fleet-repos.yaml"
TARGET_REPO=""
STRICT="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) TARGET_REPO="$2"; shift 2 ;;
    --strict) STRICT="true"; shift ;;
    *) shift ;;
  esac
done

PASS=0
FAIL=0
WARN=0

check_pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
check_fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
check_warn() { echo "  ⚠️  $1"; WARN=$((WARN + 1)); }

echo "=== Manual Branch Protection Evidence Validator ==="
echo ""

if [[ ! -f "$EVIDENCE_FILE" ]]; then
  echo "ERROR: Evidence file not found: $EVIDENCE_FILE"
  exit 1
fi

# ─── Get repo names from evidence file ──────────────────────────────────
REPO_NAMES=$(awk '/^  - name:/ {print $3}' "$EVIDENCE_FILE")

# ─── Current date for staleness check ────────────────────────────────────
CURRENT_DATE=$(date +%Y%m%d)
WARNING_DAYS=60
EXPIRY_DAYS=90
CRITICAL_EXPIRY_DAYS=120

while IFS= read -r REPO_NAME; do
  [[ -z "$REPO_NAME" ]] && continue

  # Filter by --repo if specified
  if [[ -n "$TARGET_REPO" && "$REPO_NAME" != "$TARGET_REPO" ]]; then
    continue
  fi

  echo "## $REPO_NAME"
  echo ""

  # ─── Extract evidence fields ──────────────────────────────────────────
  EVIDENCE_STATUS=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /evidence_status:/{print \$2; exit}" "$EVIDENCE_FILE")
  RECORDED_AT=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /recorded_at:/{gsub(/\"/,\"\"); print \$2; exit}" "$EVIDENCE_FILE")
  RELEASE_GATE_REQUIRED=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /release_gate_required:/{print \$2; exit}" "$EVIDENCE_FILE")
  APPROVING_REVIEWS=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /approving_reviews_required:/{print \$2; exit}" "$EVIDENCE_FILE")
  CODEOWNERS_REVIEW=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /codeowners_review_required:/{print \$2; exit}" "$EVIDENCE_FILE")
  STALE_DISMISSAL=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /stale_approvals_dismissed:/{print \$2; exit}" "$EVIDENCE_FILE")
  DIRECT_PUSH=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /direct_push_restricted:/{print \$2; exit}" "$EVIDENCE_FILE")
  FORCE_PUSHES=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /force_pushes_blocked:/{print \$2; exit}" "$EVIDENCE_FILE")
  DELETIONS=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /deletions_blocked:/{print \$2; exit}" "$EVIDENCE_FILE")
  ADMIN_BYPASS=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /admin_bypass_disabled:/{print \$2; exit}" "$EVIDENCE_FILE")
  DEPLOY_PREVIEW_REQ=$(awk "/^  - name: $REPO_NAME\$/{found=1; next} /^  - name:/{found=0} found && /deploy_preview_required:/{print \$2; exit}" "$EVIDENCE_FILE")

  # ─── Check evidence status ────────────────────────────────────────────
  if [[ "$EVIDENCE_STATUS" == "none" || -z "$EVIDENCE_STATUS" ]]; then
    check_warn "No evidence recorded (status: none)"
    echo "  Classification: no_evidence"
    echo ""
    continue
  fi

  # ─── Check freshness (v4.43: 4-level classification) ──────────────────
  FRESHNESS_STATUS="unknown"
  EVIDENCE_AGE_DAYS=0
  if [[ -z "$RECORDED_AT" || "$RECORDED_AT" == "" ]]; then
    check_fail "Missing recorded_at timestamp"
    echo "  Classification: inconsistent_evidence"
    echo "  Freshness: missing_timestamp"
    echo ""
    continue
  fi

  EVIDENCE_DATE=$(echo "$RECORDED_AT" | tr -d '-' | cut -dT -f1)
  if [[ -z "$EVIDENCE_DATE" || ! "$EVIDENCE_DATE" =~ ^[0-9]+$ ]]; then
    check_fail "Invalid recorded_at format: $RECORDED_AT"
    echo "  Classification: inconsistent_evidence"
    echo "  Freshness: invalid_timestamp"
    echo ""
    continue
  fi

  AGE_DAYS=$(( (CURRENT_DATE - EVIDENCE_DATE) ))
  EVIDENCE_AGE_DAYS=$AGE_DAYS

  # Check for future timestamp
  if [[ $AGE_DAYS -lt 0 ]]; then
    check_fail "Evidence recorded_at is in the future ($RECORDED_AT)"
    echo "  Classification: inconsistent_evidence"
    echo "  Freshness: future_timestamp"
    echo ""
    continue
  fi

  # Classify freshness
  if [[ $AGE_DAYS -lt $WARNING_DAYS ]]; then
    FRESHNESS_STATUS="fresh_evidence"
    check_pass "Evidence is fresh ($AGE_DAYS days old)"
  elif [[ $AGE_DAYS -lt $EXPIRY_DAYS ]]; then
    FRESHNESS_STATUS="expiring_soon"
    check_warn "Evidence expiring soon ($AGE_DAYS days old, expires at $EXPIRY_DAYS days)"
  elif [[ $AGE_DAYS -lt $CRITICAL_EXPIRY_DAYS ]]; then
    FRESHNESS_STATUS="stale_evidence"
    check_warn "Evidence is stale ($AGE_DAYS days old, expired at $EXPIRY_DAYS days)"
  else
    FRESHNESS_STATUS="critically_stale"
    check_fail "Evidence is critically stale ($AGE_DAYS days old, critical at $CRITICAL_EXPIRY_DAYS days)"
  fi

  # If stale or critical, don't allow manually_verified
  if [[ "$FRESHNESS_STATUS" == "stale_evidence" || "$FRESHNESS_STATUS" == "critically_stale" ]]; then
    echo "  Classification: $FRESHNESS_STATUS"
    echo "  Freshness: $FRESHNESS_STATUS (age: $AGE_DAYS days)"
    echo ""
    continue
  fi

  # ─── Validate required fields for manually_verified ───────────────────
  if [[ "$EVIDENCE_STATUS" == "manually_verified" ]]; then
    # Release Gate required
    if [[ "$RELEASE_GATE_REQUIRED" == "true" ]]; then
      check_pass "Release Gate required: true"
    else
      check_fail "Release Gate required must be true for manually_verified (got: $RELEASE_GATE_REQUIRED)"
    fi

    # Approving reviews required
    if [[ "$APPROVING_REVIEWS" == "true" ]]; then
      check_pass "Approving reviews required: true"
    else
      check_fail "Approving reviews required must be true for manually_verified (got: $APPROVING_REVIEWS)"
    fi

    # CODEOWNERS review required
    if [[ "$CODEOWNERS_REVIEW" == "true" ]]; then
      check_pass "CODEOWNERS review required: true"
    else
      check_fail "CODEOWNERS review required must be true for manually_verified (got: $CODEOWNERS_REVIEW)"
    fi

    # Stale approvals dismissed
    if [[ "$STALE_DISMISSAL" == "true" ]]; then
      check_pass "Stale approvals dismissed: true"
    else
      check_fail "Stale approvals dismissed must be true for manually_verified (got: $STALE_DISMISSAL)"
    fi

    # Direct push restricted
    if [[ "$DIRECT_PUSH" == "true" ]]; then
      check_pass "Direct push restricted: true"
    else
      check_fail "Direct push restricted must be true for manually_verified (got: $DIRECT_PUSH)"
    fi

    # Force pushes blocked
    if [[ "$FORCE_PUSHES" == "true" ]]; then
      check_pass "Force pushes blocked: true"
    else
      check_fail "Force pushes blocked must be true for manually_verified (got: $FORCE_PUSHES)"
    fi

    # Admin bypass disabled
    if [[ "$ADMIN_BYPASS" == "true" ]]; then
      check_pass "Admin bypass disabled: true"
    else
      check_warn "Admin bypass disabled should be true (got: $ADMIN_BYPASS)"
    fi

    # demo-project-specific: deploy-preview must not be required
    if [[ "$REPO_NAME" == "demo-project" ]]; then
      if [[ "$DEPLOY_PREVIEW_REQ" == "true" ]]; then
        check_fail "demo-project deploy-preview must NOT be required (VERCEL_TOKEN baseline failure exists)"
      else
        check_pass "demo-project deploy-preview not required (correct — VERCEL_TOKEN missing)"
      fi
    fi

    # ─── Determine classification ───────────────────────────────────────
    if [[ $FAIL -gt 0 ]]; then
      echo "  Classification: inconsistent_evidence"
    else
      echo "  Classification: manually_verified"
    fi
    echo "  Freshness: $FRESHNESS_STATUS (age: $EVIDENCE_AGE_DAYS days)"
  elif [[ "$EVIDENCE_STATUS" == "partial" ]]; then
    check_warn "Evidence status: partial"
    echo "  Classification: partial_evidence"
  else
    check_warn "Unknown evidence status: $EVIDENCE_STATUS"
    echo "  Classification: no_evidence"
  fi

  echo ""
done <<< "$REPO_NAMES"

# ─── Summary ────────────────────────────────────────────────────────────
echo "=========================================="
echo "PASSED: $PASS"
echo "FAILED: $FAIL"
echo "WARNINGS: $WARN"
echo "=========================================="

if [[ "$FAIL" -gt 0 ]]; then
  echo "Classification: inconsistent_evidence"
  if [[ "$STRICT" == "true" ]]; then exit 1; fi
elif [[ "$WARN" -gt 0 ]]; then
  echo "Classification: partial_evidence_or_no_evidence"
else
  echo "Classification: manually_verified"
fi

exit 0
