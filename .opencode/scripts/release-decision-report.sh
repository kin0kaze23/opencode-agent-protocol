#!/usr/bin/env bash
# release-decision-report.sh — v4.37.2 Release Decision Report
#
# Generates a release decision report by combining:
# - Sensitive change classification (path + content-aware)
# - Allowed failures and expiry warnings
# - Manual override support for false negative correction
#
# Usage:
#   bash .opencode/scripts/release-decision-report.sh [--diff <ref>] [--repo <path>] \
#     [--manual-override] [--manual-override-reason <text>] \
#     [--classifier-output <file>]
#
# When --classifier-output is provided, the report uses precomputed classifier
# output from the specified file instead of running the classifier internally.
# This eliminates fragile eval/bash path dependencies in cross-repo contexts.
#
# Non-blocking: exits 0 always (advisory output only).

set -uo pipefail

DIFF_REF=""
REPO_PATH="."
MANUAL_OVERRIDE="false"
MANUAL_OVERRIDE_REASON=""
CLASSIFIER_OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --diff) DIFF_REF="$2"; shift 2 ;;
    --repo) REPO_PATH="$2"; shift 2 ;;
    --manual-override) MANUAL_OVERRIDE="true"; shift ;;
    --manual-override-reason) MANUAL_OVERRIDE_REASON="$2"; shift 2 ;;
    --classifier-output) CLASSIFIER_OUTPUT_FILE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

WORKSPACE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# 1. Sensitive change classification
# Use precomputed output if provided, otherwise run classifier internally
if [[ -n "$CLASSIFIER_OUTPUT_FILE" && -f "$CLASSIFIER_OUTPUT_FILE" ]]; then
  CLASSIFIER_OUTPUT=$(cat "$CLASSIFIER_OUTPUT_FILE" 2>/dev/null || echo "")
elif [[ -n "$CLASSIFIER_OUTPUT_FILE" ]]; then
  # File specified but not found — fall back to internal call
  echo "[release-decision-report] Warning: classifier output file not found: $CLASSIFIER_OUTPUT_FILE" >&2
  CLASSIFIER_OUTPUT=""
  if [[ -n "$DIFF_REF" ]]; then
    CLASSIFIER_OUTPUT=$(cd "$REPO_PATH" && bash "$WORKSPACE_ROOT/.opencode/scripts/sensitive-change-classifier.sh" --diff "$DIFF_REF" 2>/dev/null || echo "")
  else
    CLASSIFIER_OUTPUT=$(cd "$REPO_PATH" && bash "$WORKSPACE_ROOT/.opencode/scripts/sensitive-change-classifier.sh" 2>/dev/null || echo "")
  fi
else
  # No precomputed output — run classifier internally (backward compatible)
  CLASSIFIER_ARGS=""
  if [[ -n "$DIFF_REF" ]]; then
    CLASSIFIER_ARGS="--diff $DIFF_REF"
  fi
  if [[ "$MANUAL_OVERRIDE" == "true" ]]; then
    CLASSIFIER_ARGS="$CLASSIFIER_ARGS --manual-override"
    if [[ -n "$MANUAL_OVERRIDE_REASON" ]]; then
      CLASSIFIER_ARGS="$CLASSIFIER_ARGS --manual-override-reason \"$MANUAL_OVERRIDE_REASON\""
    fi
  fi
  CLASSIFIER_OUTPUT=$(cd "$REPO_PATH" && eval bash "$WORKSPACE_ROOT/.opencode/scripts/sensitive-change-classifier.sh" $CLASSIFIER_ARGS 2>/dev/null || echo "")
fi

RISK_LEVEL=$(echo "$CLASSIFIER_OUTPUT" | grep "risk_level:" | awk '{print $2}')
SENSITIVE_AREAS=$(echo "$CLASSIFIER_OUTPUT" | grep "sensitive_areas:" | sed 's/.*sensitive_areas: //')
MUST_ESCALATE=$(echo "$CLASSIFIER_OUTPUT" | grep "must_escalate:" | awk '{print $2}')
REQUIRED_GATES=$(echo "$CLASSIFIER_OUTPUT" | grep "required_gates:" | sed 's/.*required_gates: //')
DETECTION_TYPE=$(echo "$CLASSIFIER_OUTPUT" | grep "classifier_detection_type:" | awk '{print $2}')
CLASSIFIER_DETECTED_SENSITIVE=$(echo "$CLASSIFIER_OUTPUT" | grep "classifier_detected_sensitive:" | awk '{print $2}')
MATCHED_CONTENT_PATTERNS=$(echo "$CLASSIFIER_OUTPUT" | grep "matched_content_patterns:" | sed 's/.*matched_content_patterns: //')
MATCHED_ADVISORY_PATTERNS=$(echo "$CLASSIFIER_OUTPUT" | grep "matched_advisory_patterns:" | sed 's/.*matched_advisory_patterns: //')
CLASSIFIER_REASON=$(echo "$CLASSIFIER_OUTPUT" | grep "classifier_reason:" | sed 's/.*classifier_reason: //')

# 2. Determine requirements
TESTS_REQUIRED="false"
REVIEWER_REQUIRED="false"

if echo "$REQUIRED_GATES" | grep -q "full_tests"; then
  TESTS_REQUIRED="true"
fi
if echo "$REQUIRED_GATES" | grep -q "reviewer"; then
  REVIEWER_REQUIRED="true"
fi

# 3. Check for allowed failures and expiry
ALLOWED_FAILURES=""
EXPIRY_WARNINGS=""

SMOKE_SCRIPT="$REPO_PATH/scripts/run-ui-smoke.sh"
if [[ -f "$SMOKE_SCRIPT" ]]; then
  AF_NAME=$(grep "ALLOWED_FAILURE_NAME=" "$SMOKE_SCRIPT" 2>/dev/null | cut -d'"' -f2)
  AF_EXPIRY=$(grep "ALLOWED_FAILURE_EXPIRY=" "$SMOKE_SCRIPT" 2>/dev/null | cut -d'"' -f2)
  if [[ -n "$AF_NAME" ]]; then
    ALLOWED_FAILURES="$AF_NAME"
    if [[ -n "$AF_EXPIRY" ]]; then
      CURRENT_DATE=$(date +%Y%m%d)
      EXPIRY_DATE=$(echo "$AF_EXPIRY" | tr -d '-')
      if [[ "$CURRENT_DATE" -gt "$EXPIRY_DATE" ]]; then
        EXPIRY_WARNINGS="$AF_NAME has EXPIRED on $AF_EXPIRY"
      elif [[ $((EXPIRY_DATE - CURRENT_DATE)) -lt 7 ]]; then
        EXPIRY_WARNINGS="$AF_NAME expires soon: $AF_EXPIRY"
      fi
    fi
  fi
fi

# 4. Determine release status
# Status semantics (v4.37.2):
#   pass      — no sensitive changes detected, safe to merge
#   advisory  — sensitive changes detected (medium or high risk), reviewer recommended/required
#   block     — expired allowed failure or blocking policy violation
# Note: For high-risk without reviewer evidence, the gate action upgrades advisory to block.
RELEASE_STATUS="pass"
RECOMMENDATION="Safe to merge"

if [[ -n "$EXPIRY_WARNINGS" ]]; then
  RELEASE_STATUS="block"
  RECOMMENDATION="BLOCKED: Allowed failure has expired or expires soon. Resolve before merge."
elif [[ "$RISK_LEVEL" == "high" ]]; then
  RELEASE_STATUS="advisory"
  RECOMMENDATION="ADVISORY: High-risk sensitive change. Reviewer evidence required before merge."
elif [[ "$RISK_LEVEL" == "medium" ]]; then
  RELEASE_STATUS="advisory"
  RECOMMENDATION="ADVISORY: Medium-risk sensitive change. Reviewer recommended before merge."
elif [[ "$MUST_ESCALATE" == "true" ]]; then
  RELEASE_STATUS="advisory"
  RECOMMENDATION="ADVISORY: Sensitive paths detected. Ensure reviewer is used and full tests pass before merge."
fi

# 5. Output
echo "RELEASE_DECISION_REPORT:"
echo "  generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "  repo: $REPO_PATH"
echo "  diff: ${DIFF_REF:-unstaged}"
echo "  release_status: $RELEASE_STATUS"
echo "  changed_sensitive_areas: $SENSITIVE_AREAS"
echo "  risk_level: $RISK_LEVEL"
echo "  tests_required: $TESTS_REQUIRED"
echo "  reviewer_required: $REVIEWER_REQUIRED"
echo "  classifier_detection_type: ${DETECTION_TYPE:-none}"
echo "  classifier_detected_sensitive: ${CLASSIFIER_DETECTED_SENSITIVE:-false}"
echo "  matched_sensitive_patterns: ${MATCHED_CONTENT_PATTERNS:-[]}"
echo "  matched_advisory_patterns: ${MATCHED_ADVISORY_PATTERNS:-[]}"
echo "  classifier_reason: ${CLASSIFIER_REASON:-none}"
echo "  classifier_false_negative_manual_override: $MANUAL_OVERRIDE"
if [[ -n "$MANUAL_OVERRIDE_REASON" ]]; then
  echo "  manual_sensitive_override_reason: $MANUAL_OVERRIDE_REASON"
fi
echo "  allowed_failures_used: $ALLOWED_FAILURES"
if [[ -n "$EXPIRY_WARNINGS" ]]; then
  echo "  expiry_warnings: $EXPIRY_WARNINGS"
else
  echo "  expiry_warnings: none"
fi
echo "  final_recommendation: $RECOMMENDATION"
