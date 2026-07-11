#!/usr/bin/env bash
# validate-release-gate.sh — v4.38 Release Gate Validator
#
# Validates that a repo has the release gate correctly installed.
# Checks for required scripts, workflow, trust policy, and docs.
# Runs a synthetic high-risk fixture to verify the classifier works.
# Optionally checks branch protection and CODEOWNERS with --strict.
#
# Usage:
#   bash validate-release-gate.sh [--repo <path>] [--strict]
#
# Exit codes:
#   0 — validation passed (or advisory in non-strict mode)
#   1 — validation failed

set -uo pipefail

REPO_PATH="."
STRICT="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO_PATH="$2"; shift 2 ;;
    --strict) STRICT="true"; shift ;;
    *) shift ;;
  esac
done

PASS=0
FAIL=0
WARN=0

check_exists() {
  local file="$1"
  local desc="$2"
  if [[ -f "$REPO_PATH/$file" ]]; then
    echo "  ✅ $desc: $file"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc: $file NOT FOUND"
    FAIL=$((FAIL + 1))
  fi
}

check_executable() {
  local file="$1"
  local desc="$2"
  if [[ -x "$REPO_PATH/$file" ]]; then
    echo "  ✅ $desc: executable"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc: NOT executable"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Release Gate Validator ==="
echo "Repo: $REPO_PATH"
echo ""

# ─── Check required scripts ──────────────────────────────────────────────
echo "== Required Scripts =="
check_exists ".github/scripts/sensitive-change-classifier.sh" "Classifier script"
check_exists ".github/scripts/release-decision-report.sh" "Release report script"
check_exists ".github/scripts/reviewer-evidence-detector.sh" "Reviewer evidence detector"
check_exists ".github/scripts/pr-release-gate-action.sh" "Gate action script"

check_executable ".github/scripts/sensitive-change-classifier.sh" "Classifier"
check_executable ".github/scripts/release-decision-report.sh" "Release report"
check_executable ".github/scripts/reviewer-evidence-detector.sh" "Detector"
check_executable ".github/scripts/pr-release-gate-action.sh" "Action"

# ─── Check workflow ───────────────────────────────────────────────────────
echo ""
echo "== Workflow =="
check_exists ".github/workflows/pr-release-gate.yml" "PR release gate workflow"

# ─── Check trust policy ──────────────────────────────────────────────────
echo ""
echo "== Trust Policy =="
check_exists ".opencode/config/reviewer-trust-policy.yaml" "Trust policy config"

# ─── Check docs ───────────────────────────────────────────────────────────
echo ""
echo "== Documentation =="
check_exists "docs/PR_RELEASE_GATE.md" "PR release gate docs"
check_exists "docs/BRANCH_PROTECTION.md" "Branch protection docs"

# ─── Run synthetic classifier test ───────────────────────────────────────
echo ""
echo "== Synthetic Classifier Test =="

# Create a temporary high-risk fixture
FIXTURE=$(mktemp /tmp/validate-gate-fixture-XXXXXX.tsx)
cat > "$FIXTURE" << 'EOF'
import { ClerkProvider, SignedIn, SignedOut, useAuth } from "@clerk/clerk-react"
const isE2E = import.meta.env.VITE_E2E === "true"
if (isE2E) { return <div>E2E auth bypass</div> }
EOF

CLASSIFIER_OUTPUT=$(bash "$REPO_PATH/.github/scripts/sensitive-change-classifier.sh" --files "$FIXTURE" 2>/dev/null || echo "")
rm -f "$FIXTURE"

if echo "$CLASSIFIER_OUTPUT" | grep -q "risk_level: high"; then
  echo "  ✅ Synthetic fixture classified as high risk"
  PASS=$((PASS + 1))
else
  echo "  ❌ Synthetic fixture not classified as high risk"
  FAIL=$((FAIL + 1))
fi

if echo "$CLASSIFIER_OUTPUT" | grep -q "detection_type: content"; then
  echo "  ✅ Content-based detection works"
  PASS=$((PASS + 1))
else
  echo "  ❌ Content-based detection not working"
  FAIL=$((FAIL + 1))
fi

# ─── Run reviewer evidence detector test ─────────────────────────────────
echo ""
echo "== Reviewer Evidence Detector Test =="

DETECTOR_OUTPUT=$(bash "$REPO_PATH/.github/scripts/reviewer-evidence-detector.sh" 2>/dev/null || echo "")

if echo "$DETECTOR_OUTPUT" | grep -q "REVIEWER_EVIDENCE:"; then
  echo "  ✅ Detector produces output"
  PASS=$((PASS + 1))
else
  echo "  ❌ Detector does not produce output"
  FAIL=$((FAIL + 1))
fi

if echo "$DETECTOR_OUTPUT" | grep -q "reviewer_evidence_found: false"; then
  echo "  ✅ Detector defaults to no evidence without PR"
  PASS=$((PASS + 1))
else
  echo "  ❌ Detector does not default to no evidence"
  FAIL=$((FAIL + 1))
fi

# ─── Branch protection check (v4.38 — advisory by default, strict with --strict) ─
echo ""
echo "== Branch Protection (v4.38) =="
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$SCRIPT_DIR/verify-branch-protection.sh" ]]; then
  BP_OUTPUT=$(bash "$SCRIPT_DIR/verify-branch-protection.sh" --repo "$REPO_PATH" 2>&1)
  BP_EXIT=$?
  BP_CLASSIFICATION=$(echo "$BP_OUTPUT" | grep "Classification:" | awk '{print $2}')
  case "$BP_CLASSIFICATION" in
    verified)
      echo "  ✅ Branch protection verified"
      PASS=$((PASS + 1))
      ;;
    not_configured)
      if [[ "$STRICT" == "true" ]]; then
        echo "  ❌ Branch protection not configured (strict mode)"
        FAIL=$((FAIL + 1))
      else
        echo "  ⚠️  Branch protection not configured (advisory — configure for enforcement)"
        WARN=$((WARN + 1))
      fi
      ;;
    unknown_permission_limited)
      echo "  ⚠️  Cannot verify branch protection (API permission limited)"
      WARN=$((WARN + 1))
      ;;
    blocked_misconfigured)
      if [[ "$STRICT" == "true" ]]; then
        echo "  ❌ Branch protection misconfigured (strict mode)"
        FAIL=$((FAIL + 1))
      else
        echo "  ⚠️  Branch protection has gaps (advisory)"
        WARN=$((WARN + 1))
      fi
      ;;
    *)
      echo "  ⚠️  Branch protection status unknown"
      WARN=$((WARN + 1))
      ;;
  esac
else
  echo "  ⏭️  Branch protection verifier not available — skipping"
fi

# ─── CODEOWNERS check (v4.38 — advisory by default) ─────────────────────
echo ""
echo "== CODEOWNERS (v4.38) =="
if [[ -f "$SCRIPT_DIR/verify-codeowners.sh" ]]; then
  CO_OUTPUT=$(bash "$SCRIPT_DIR/verify-codeowners.sh" --repo "$REPO_PATH" 2>&1)
  CO_EXIT=$?
  CO_CLASSIFICATION=$(echo "$CO_OUTPUT" | grep "Classification:" | awk '{print $2}')
  case "$CO_CLASSIFICATION" in
    verified)
      echo "  ✅ CODEOWNERS covers sensitive paths"
      PASS=$((PASS + 1))
      ;;
    missing_codeowners)
      if [[ "$STRICT" == "true" ]]; then
        echo "  ❌ No CODEOWNERS file (strict mode)"
        FAIL=$((FAIL + 1))
      else
        echo "  ⚠️  No CODEOWNERS file (advisory — see docs/CODEOWNERS_TEMPLATE.md)"
        WARN=$((WARN + 1))
      fi
      ;;
    partially_covered)
      echo "  ⚠️  CODEOWNERS exists but some sensitive paths uncovered"
      WARN=$((WARN + 1))
      ;;
    *)
      echo "  ⚠️  CODEOWNERS status unknown"
      WARN=$((WARN + 1))
      ;;
  esac
else
  echo "  ⏭️  CODEOWNERS verifier not available — skipping"
fi

# ─── Summary ─────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "PASSED: $PASS"
echo "FAILED: $FAIL"
echo "WARNINGS: ${WARN:-0}"
echo "=========================================="

if [[ "$FAIL" -gt 0 ]]; then
  echo "❌ Validation FAILED — fix issues before using release gate"
  exit 1
fi

if [[ "$WARN" -gt 0 ]] 2>/dev/null; then
  echo "✅ Validation PASSED (with warnings) — release gate is correctly installed"
  echo "⚠️  Warnings indicate protection gaps — run with --strict for blocking mode"
else
  echo "✅ Validation PASSED — release gate is correctly installed and protected"
fi
exit 0
