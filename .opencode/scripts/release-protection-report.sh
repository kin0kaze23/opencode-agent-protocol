#!/usr/bin/env bash
# release-protection-report.sh — v4.38 Release Protection Report
#
# Combines release gate installation, branch protection, required checks,
# CODEOWNERS, and trust policy into a single protection status report.
#
# Usage:
#   bash release-protection-report.sh [--repo <path>] [--branch <name>] [--strict]
#
# Exit codes:
#   0 — protected or partially protected (non-strict mode)
#   1 — not protected (strict mode)
#   2 — permission limited

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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Release Protection Report ==="
echo "Repo: $REPO_PATH"
echo "Branch: $BRANCH"
echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# ─── 1. Release Gate Installation ───────────────────────────────────────
echo "## 1. Release Gate Installation"
GATE_STATUS="unknown"
if [[ -f "$REPO_PATH/.github/workflows/pr-release-gate.yml" ]]; then
  echo "  ✅ PR release gate workflow installed"
  GATE_STATUS="installed"
else
  echo "  ❌ PR release gate workflow NOT installed"
  GATE_STATUS="not_installed"
fi

if [[ -f "$REPO_PATH/.github/scripts/validate-release-gate.sh" ]]; then
  echo "  ✅ Release gate validator installed"
else
  echo "  ⚠️  Release gate validator not installed"
fi

if [[ -f "$REPO_PATH/.opencode/config/reviewer-trust-policy.yaml" ]]; then
  echo "  ✅ Reviewer trust policy installed"
else
  echo "  ⚠️  Reviewer trust policy not installed"
fi

# ─── 2. Branch Protection ──────────────────────────────────────────────
echo ""
echo "## 2. Branch Protection"
BP_OUTPUT=$(bash "$SCRIPT_DIR/verify-branch-protection.sh" --repo "$REPO_PATH" --branch "$BRANCH" 2>&1)
BP_EXIT=$?
echo "$BP_OUTPUT" | grep -E "✅|❌|⚠️|Classification:" | sed 's/^/  /'

case $BP_EXIT in
  0) BP_CLASSIFICATION=$(echo "$BP_OUTPUT" | grep "Classification:" | awk '{print $2}') ;;
  1) BP_CLASSIFICATION="blocked_misconfigured" ;;
  2) BP_CLASSIFICATION="unknown_permission_limited" ;;
  *) BP_CLASSIFICATION="unknown" ;;
esac

# ─── 3. CODEOWNERS ──────────────────────────────────────────────────────
echo ""
echo "## 3. CODEOWNERS"
CO_OUTPUT=$(bash "$SCRIPT_DIR/verify-codeowners.sh" --repo "$REPO_PATH" 2>&1)
CO_EXIT=$?
echo "$CO_OUTPUT" | grep -E "✅|❌|⚠️|Classification:" | sed 's/^/  /'

CO_CLASSIFICATION=$(echo "$CO_OUTPUT" | grep "Classification:" | awk '{print $2}')

# ─── 4. Trust Policy ────────────────────────────────────────────────────
echo ""
echo "## 4. Trust Policy"
TRUST_POLICY="$REPO_PATH/.opencode/config/reviewer-trust-policy.yaml"
if [[ -f "$TRUST_POLICY" ]]; then
  echo "  ✅ Trust policy file exists"
  ALLOW_LABEL=$(grep "^allow_label_evidence:" "$TRUST_POLICY" 2>/dev/null | awk '{print $2}')
  FRESH_APPROVAL=$(grep "^require_fresh_approval:" "$TRUST_POLICY" 2>/dev/null | awk '{print $2}')
  echo "  allow_label_evidence: ${ALLOW_LABEL:-true}"
  echo "  require_fresh_approval: ${FRESH_APPROVAL:-true}"
else
  echo "  ⚠️  No trust policy file — using defaults"
fi

# ─── 5. Final Recommendation ─────────────────────────────────────────────
echo ""
echo "=========================================="
echo "## Final Recommendation"
echo "=========================================="

if [[ "$GATE_STATUS" == "not_installed" ]]; then
  RECOMMENDATION="not_protected"
  echo "Classification: not_protected"
  echo "Reason: Release gate not installed"
elif [[ "$BP_CLASSIFICATION" == "not_configured" ]]; then
  RECOMMENDATION="not_protected"
  echo "Classification: not_protected"
  echo "Reason: Branch protection not configured"
  echo "Action: Configure branch protection to require Release Gate check"
elif [[ "$BP_CLASSIFICATION" == "blocked_misconfigured" ]]; then
  RECOMMENDATION="partially_protected"
  echo "Classification: partially_protected"
  echo "Reason: Branch protection configured but missing required checks"
  echo "Action: Add Release Gate to required status checks"
elif [[ "$BP_CLASSIFICATION" == "unknown_permission_limited" ]]; then
  RECOMMENDATION="unknown_permission_limited"
  echo "Classification: unknown_permission_limited"
  echo "Reason: Cannot verify branch protection via API (private repo / GitHub plan)"
  echo "Action: Manually verify Settings → Branches → Branch protection rules"
elif [[ "$BP_CLASSIFICATION" == "verified" && "$CO_CLASSIFICATION" == "verified" ]]; then
  RECOMMENDATION="protected"
  echo "Classification: protected"
  echo "Reason: Release gate installed, branch protection verified, CODEOWNERS covers sensitive paths"
elif [[ "$BP_CLASSIFICATION" == "verified" ]]; then
  RECOMMENDATION="partially_protected"
  echo "Classification: partially_protected"
  echo "Reason: Branch protection verified but CODEOWNERS incomplete"
  echo "Action: Add CODEOWNERS coverage for sensitive paths"
else
  RECOMMENDATION="partially_protected"
  echo "Classification: partially_protected"
  echo "Reason: Some protection in place but gaps remain"
fi

echo ""
echo "Gate: $GATE_STATUS | Protection: $BP_CLASSIFICATION | CODEOWNERS: $CO_CLASSIFICATION"
echo "=========================================="

if [[ "$STRICT" == "true" && "$RECOMMENDATION" != "protected" ]]; then
  exit 1
fi
exit 0
