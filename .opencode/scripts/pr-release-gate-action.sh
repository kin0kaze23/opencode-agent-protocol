#!/usr/bin/env bash
# pr-release-gate-action.sh — v4.34.2 PR Release Gate Action
#
# Runs the sensitive change classifier and release decision report on PR changes.
# Writes a structured GitHub job summary and sets step outputs.
#
# v4.34.2: Runs classifier ONCE and passes output to release-decision-report
# via --classifier-output flag, eliminating fragile eval/bash cross-repo issues.
#
# Environment variables:
#   GITHUB_STEP_SUMMARY — file path for job summary (set by GitHub Actions)
#   GITHUB_EVENT_PULL_REQUEST_BASE_REF — base branch name
#   GITHUB_EVENT_PULL_REQUEST_HEAD_REF — head branch name
#   GITHUB_EVENT_PULL_REQUEST_NUMBER — PR number
#
# Exit codes:
#   0 — advisory or pass (PR not blocked)
#   1 — block (expired allowed failure or policy violation)

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT_DIR"

# ─── Determine diff range ────────────────────────────────────────────────
BASE_REF="${GITHUB_EVENT_PULL_REQUEST_BASE_REF:-main}"
HEAD_REF="${GITHUB_EVENT_PULL_REQUEST_HEAD_REF:-HEAD}"
DIFF_RANGE="origin/${BASE_REF}...HEAD"

# For workflow_dispatch or local testing, fall back to HEAD
if ! git rev-parse --verify "origin/${BASE_REF}" >/dev/null 2>&1; then
  echo "[pr-release-gate] Base branch origin/${BASE_REF} not found, using HEAD~1"
  DIFF_RANGE="HEAD~1...HEAD"
fi

echo "[pr-release-gate] Diff range: ${DIFF_RANGE}"

# ─── Run sensitive change classifier ─────────────────────────────────────
CLASSIFIER_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/sensitive-change-classifier.sh" --diff "$DIFF_RANGE" 2>/dev/null || echo "")
echo "$CLASSIFIER_OUTPUT"

# Save classifier output for reuse by release-decision-report (v4.34.2: eliminates
# fragile eval/bash cross-repo path dependency)
echo "$CLASSIFIER_OUTPUT" > /tmp/classifier-output.txt

# Parse classifier output
RISK_LEVEL=$(echo "$CLASSIFIER_OUTPUT" | grep "risk_level:" | awk '{print $2}')
SENSITIVE_AREAS=$(echo "$CLASSIFIER_OUTPUT" | grep "sensitive_areas:" | sed 's/.*sensitive_areas: //')
MUST_ESCALATE=$(echo "$CLASSIFIER_OUTPUT" | grep "must_escalate:" | awk '{print $2}')
DETECTION_TYPE=$(echo "$CLASSIFIER_OUTPUT" | grep "classifier_detection_type:" | awk '{print $2}')
CLASSIFIER_DETECTED=$(echo "$CLASSIFIER_OUTPUT" | grep "classifier_detected_sensitive:" | awk '{print $2}')
MATCHED_PATTERNS=$(echo "$CLASSIFIER_OUTPUT" | grep "matched_content_patterns:" | sed 's/.*matched_content_patterns: //')
ADVISORY_PATTERNS=$(echo "$CLASSIFIER_OUTPUT" | grep "matched_advisory_patterns:" | sed 's/.*matched_advisory_patterns: //')
CLASSIFIER_REASON=$(echo "$CLASSIFIER_OUTPUT" | grep "classifier_reason:" | sed 's/.*classifier_reason: //')

# Defaults for empty values
RISK_LEVEL="${RISK_LEVEL:-none}"
SENSITIVE_AREAS="${SENSITIVE_AREAS:-}"
MUST_ESCALATE="${MUST_ESCALATE:-false}"
DETECTION_TYPE="${DETECTION_TYPE:-none}"
CLASSIFIER_DETECTED="${CLASSIFIER_DETECTED:-false}"
MATCHED_PATTERNS="${MATCHED_PATTERNS:-}"
ADVISORY_PATTERNS="${ADVISORY_PATTERNS:-}"
CLASSIFIER_REASON="${CLASSIFIER_REASON:-No sensitive patterns detected}"

# ─── Run release decision report ─────────────────────────────────────────
# v4.34.2: Pass precomputed classifier output to avoid fragile internal eval/bash
# calls that fail in cross-repo contexts (example-app v4.34.1 validation gap)
REPORT_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/release-decision-report.sh" --diff "$DIFF_RANGE" --repo "$ROOT_DIR" --classifier-output /tmp/classifier-output.txt 2>/dev/null || echo "")
echo "$REPORT_OUTPUT"

# Save report to file for artifact upload
echo "$REPORT_OUTPUT" > /tmp/release-decision-report.txt

# Parse report output
RELEASE_STATUS=$(echo "$REPORT_OUTPUT" | grep "release_status:" | awk '{print $2}')
TESTS_REQUIRED=$(echo "$REPORT_OUTPUT" | grep "tests_required:" | awk '{print $2}')
REVIEWER_REQUIRED=$(echo "$REPORT_OUTPUT" | grep "reviewer_required:" | awk '{print $2}')
ALLOWED_FAILURES=$(echo "$REPORT_OUTPUT" | grep "allowed_failures_used:" | sed 's/.*allowed_failures_used: //')
EXPIRY_WARNINGS=$(echo "$REPORT_OUTPUT" | grep "expiry_warnings:" | sed 's/.*expiry_warnings: //')
RECOMMENDATION=$(echo "$REPORT_OUTPUT" | grep "final_recommendation:" | sed 's/.*final_recommendation: //')

# Defaults
RELEASE_STATUS="${RELEASE_STATUS:-pass}"
TESTS_REQUIRED="${TESTS_REQUIRED:-false}"
REVIEWER_REQUIRED="${REVIEWER_REQUIRED:-false}"
ALLOWED_FAILURES="${ALLOWED_FAILURES:-none}"
EXPIRY_WARNINGS="${EXPIRY_WARNINGS:-none}"
RECOMMENDATION="${RECOMMENDATION:-Safe to merge}"

# ─── v4.35: Reviewer evidence enforcement ───────────────────────────────
# When reviewer is required (high/medium risk), check for trusted reviewer evidence.
# High-risk + no trusted evidence → block
# High-risk + trusted evidence → advisory
# v4.36: Includes stale approval, PR author exclusion, trust policy
REVIEWER_EVIDENCE_FOUND="false"
EVIDENCE_TYPE="none"
EVIDENCE_TRUSTED="false"
EVIDENCE_REASON="Not checked"
REVIEWER_IS_AUTHOR="false"
APPROVAL_FRESH="unknown"
TRUST_POLICY_SOURCE="default"
ENFORCEMENT_STATUS="$RELEASE_STATUS"
ENFORCEMENT_REASON=""

if [[ "$REVIEWER_REQUIRED" == "true" ]]; then
  PR_NUMBER="${GITHUB_EVENT_PULL_REQUEST_NUMBER:-}"
  REVIEWER_EVIDENCE_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/reviewer-evidence-detector.sh" --pr "$PR_NUMBER" 2>/dev/null || echo "")
  echo "$REVIEWER_EVIDENCE_OUTPUT"

  REVIEWER_EVIDENCE_FOUND=$(echo "$REVIEWER_EVIDENCE_OUTPUT" | grep "reviewer_evidence_found:" | awk '{print $2}')
  EVIDENCE_TYPE=$(echo "$REVIEWER_EVIDENCE_OUTPUT" | grep "evidence_type:" | awk '{print $2}')
  EVIDENCE_TRUSTED=$(echo "$REVIEWER_EVIDENCE_OUTPUT" | grep "evidence_trusted:" | awk '{print $2}')
  EVIDENCE_REASON=$(echo "$REVIEWER_EVIDENCE_OUTPUT" | grep "reason:" | sed 's/.*reason: //')
  REVIEWER_IS_AUTHOR=$(echo "$REVIEWER_EVIDENCE_OUTPUT" | grep "reviewer_is_author:" | awk '{print $2}')
  APPROVAL_FRESH=$(echo "$REVIEWER_EVIDENCE_OUTPUT" | grep "approval_fresh:" | awk '{print $2}')
  TRUST_POLICY_SOURCE=$(echo "$REVIEWER_EVIDENCE_OUTPUT" | grep "trust_policy_source:" | awk '{print $2}')

  REVIEWER_EVIDENCE_FOUND="${REVIEWER_EVIDENCE_FOUND:-false}"
  EVIDENCE_TYPE="${EVIDENCE_TYPE:-none}"
  EVIDENCE_TRUSTED="${EVIDENCE_TRUSTED:-false}"
  EVIDENCE_REASON="${EVIDENCE_REASON:-Not checked}"
  REVIEWER_IS_AUTHOR="${REVIEWER_IS_AUTHOR:-false}"
  APPROVAL_FRESH="${APPROVAL_FRESH:-unknown}"
  TRUST_POLICY_SOURCE="${TRUST_POLICY_SOURCE:-default}"

  # Determine enforcement status
  if [[ "$RELEASE_STATUS" == "block" ]]; then
    ENFORCEMENT_STATUS="block"
    ENFORCEMENT_REASON="Blocked by release decision report (expired allowed failure or policy violation)"
  elif [[ "$RISK_LEVEL" == "high" && "$EVIDENCE_TRUSTED" != "true" ]]; then
    ENFORCEMENT_STATUS="block"
    ENFORCEMENT_REASON="High-risk sensitive change requires trusted reviewer evidence. No trusted evidence found: ${EVIDENCE_REASON}"
  elif [[ "$RISK_LEVEL" == "high" && "$EVIDENCE_TRUSTED" == "true" ]]; then
    ENFORCEMENT_STATUS="advisory"
    ENFORCEMENT_REASON="High-risk change with trusted reviewer evidence ($EVIDENCE_TYPE). Advisory only."
  elif [[ "$RISK_LEVEL" == "medium" ]]; then
    ENFORCEMENT_STATUS="advisory"
    ENFORCEMENT_REASON="Medium-risk change. Reviewer recommended."
  fi
fi

# ─── Determine status icon ───────────────────────────────────────────────
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

# ─── Determine owner next action ──────────────────────────────────────────
OWNER_ACTION=""
if [[ "$ENFORCEMENT_STATUS" == "block" ]]; then
  if [[ "$RISK_LEVEL" == "high" && "$EVIDENCE_TRUSTED" != "true" ]]; then
    OWNER_ACTION="🚫 BLOCKED: High-risk sensitive change requires reviewer evidence. Get a GitHub approving review or apply the 'reviewer-approved' label."
  else
    OWNER_ACTION="🚫 BLOCKED: Resolve expired allowed failure or policy violation before merge."
  fi
elif [[ "$RISK_LEVEL" == "high" ]]; then
  OWNER_ACTION="⚠️ High-risk change with trusted reviewer evidence. Ensure full tests pass before merge."
elif [[ "$RISK_LEVEL" == "medium" ]]; then
  OWNER_ACTION="⚠️ Medium-risk changes detected. Reviewer recommended."
else
  OWNER_ACTION="✅ No action required — safe to merge."
fi

# ─── Write GitHub job summary ────────────────────────────────────────────
SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

cat >> "$SUMMARY_FILE" << EOF

## Release Gate Summary

| Field | Value |
|-------|-------|
| Enforcement Status | ${STATUS_ICON} ${ENFORCEMENT_STATUS} |
| Risk Level | ${RISK_ICON} ${RISK_LEVEL} |
| Detection Type | ${DETECTION_TYPE} |
| Classifier Detected Sensitive | ${CLASSIFIER_DETECTED} |
| Reviewer Required | ${REVIEWER_REQUIRED} |
| Reviewer Evidence Found | ${REVIEWER_EVIDENCE_FOUND} |
| Evidence Type | ${EVIDENCE_TYPE} |
| Evidence Trusted | ${EVIDENCE_TRUSTED} |
| Reviewer Is Author | ${REVIEWER_IS_AUTHOR} |
| Approval Freshness | ${APPROVAL_FRESH} |
| Trust Policy Source | ${TRUST_POLICY_SOURCE} |
| Tests Required | ${TESTS_REQUIRED} |

### Sensitive Areas
${SENSITIVE_AREAS:-None}

### Matched Sensitive Patterns
${MATCHED_PATTERNS:-None}

### Advisory Patterns
${ADVISORY_PATTERNS:-None}

### Classifier Reason
${CLASSIFIER_REASON}

### Reviewer Evidence
${EVIDENCE_REASON}

### Enforcement Reason
${ENFORCEMENT_REASON:-No enforcement needed}

### Allowed Failures
${ALLOWED_FAILURES}

### Expiry Warnings
${EXPIRY_WARNINGS}

### Recommendation
${RECOMMENDATION}

### Owner Next Action
${OWNER_ACTION}

---
*Generated by v4.36 PR Release Gate with Reviewer Trust Hardening. See [docs/PR_RELEASE_GATE.md](docs/PR_RELEASE_GATE.md) for how to read this summary.*
EOF

# ─── Set step outputs ────────────────────────────────────────────────────
echo "release_status=${ENFORCEMENT_STATUS}" >> "$GITHUB_OUTPUT"
echo "risk_level=${RISK_LEVEL}" >> "$GITHUB_OUTPUT"
echo "reviewer_required=${REVIEWER_REQUIRED}" >> "$GITHUB_OUTPUT"
echo "reviewer_evidence_found=${REVIEWER_EVIDENCE_FOUND}" >> "$GITHUB_OUTPUT"
echo "evidence_type=${EVIDENCE_TYPE}" >> "$GITHUB_OUTPUT"
echo "evidence_trusted=${EVIDENCE_TRUSTED}" >> "$GITHUB_OUTPUT"
echo "reviewer_is_author=${REVIEWER_IS_AUTHOR}" >> "$GITHUB_OUTPUT"
echo "approval_fresh=${APPROVAL_FRESH}" >> "$GITHUB_OUTPUT"
echo "trust_policy_source=${TRUST_POLICY_SOURCE}" >> "$GITHUB_OUTPUT"
echo "detection_type=${DETECTION_TYPE}" >> "$GITHUB_OUTPUT"
echo "classifier_detected_sensitive=${CLASSIFIER_DETECTED}" >> "$GITHUB_OUTPUT"

# ─── Exit with appropriate code ──────────────────────────────────────────
# v4.35: Block on:
#   - release_status: block (expired allowed failures, policy violations)
#   - high-risk + no trusted reviewer evidence
# Advisory for:
#   - high-risk + trusted reviewer evidence
#   - medium-risk
# Pass for:
#   - low-risk / no sensitive changes
if [[ "$ENFORCEMENT_STATUS" == "block" ]]; then
  echo "[pr-release-gate] 🚫 BLOCKED: ${ENFORCEMENT_REASON:-${RECOMMENDATION}}"
  exit 1
fi

echo "[pr-release-gate] ✅ Not blocked (status: ${ENFORCEMENT_STATUS}, risk: ${RISK_LEVEL}, evidence: ${EVIDENCE_TRUSTED})"
exit 0
