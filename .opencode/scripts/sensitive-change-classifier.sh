#!/usr/bin/env bash
# sensitive-change-classifier.sh — v4.33 Content-Aware Sensitive Change Detection
#
# Detects sensitive changes using both path-based and content-based detection.
# Path-based: checks file paths against sensitive area patterns.
# Content-based: checks file content/diff for auth/security-sensitive keywords.
#
# Usage:
#   bash .opencode/scripts/sensitive-change-classifier.sh [--diff <ref>] [--files <file1> <file2> ...]
#
# Non-blocking: exits 0 always (advisory output only).

set -uo pipefail

# ─── Path-based patterns: "area|pattern|reason" ─────────────────────────
PATH_PATTERNS=(
  "auth|/auth/|Authentication module"
  "auth|/clerk/|Clerk authentication integration"
  "auth|middleware.ts|Auth middleware"
  "auth|/session/|Session management"
  "auth|/login/|Login flow"
  "auth|/signin/|Sign-in flow"
  "auth|/token/|Auth token handling"
  "security|/security/|Security module"
  "security|/crypto/|Cryptography"
  "security|/guard/|Security guards"
  "security|/rbac/|Role-based access control"
  "secrets|.env|Environment/secrets file"
  "secrets|/secrets/|Secrets directory"
  "secrets|/credentials/|Credentials directory"
  "secrets|/keys/|Key files"
  "secrets|.key|Cryptographic key file"
  "secrets|doppler|Doppler secrets config"
  "payments|/payment/|Payment processing"
  "payments|/billing/|Billing module"
  "payments|/stripe/|Stripe integration"
  "payments|/checkout/|Checkout flow"
  "schema|/migrations/|Database migration"
  "schema|/schema/|Database schema"
  "schema|/prisma/|Prisma schema"
  "schema|/drizzle/|Drizzle ORM schema"
  "schema|/sql/|SQL files"
  "schema|/rls/|Row-level security policies"
  "schema|/policies/|Database policies"
  "deployment|.github/workflows/|CI/CD workflow"
  "deployment|/deploy/|Deployment config"
  "deployment|Dockerfile|Docker build"
  "deployment|docker-compose|Docker Compose"
  "deployment|vercel.json|Vercel deployment config"
  "deployment|wrangler|Cloudflare Workers config"
  "deployment|railway|Railway deployment config"
  "deployment|.github/scripts/|CI/CD tooling scripts"
  "deployment|.opencode/scripts/|Protocol tooling scripts"
  "pii|/pii/|PII handling"
  "pii|/user-data/|User data handling"
  "pii|/personal/|Personal data"
  "storage|/storage/|Storage permissions"
  "storage|/bucket/|Storage bucket config"
  "storage|/permissions/|Permission policies"
)

# ─── Content-based patterns (high): "pattern|reason" ────────────────────
# These trigger high risk when found in file content or diff.
CONTENT_HIGH_PATTERNS=(
  "VITE_E2E|E2E auth bypass env var"
  "SignedIn|Clerk SignedIn auth component"
  "SignedOut|Clerk SignedOut auth component"
  "ClerkProvider|Clerk authentication provider"
  "useAuth|Clerk useAuth hook"
  "useUser|Clerk useUser hook"
  "@clerk|Clerk authentication import"
  "auth bypass|Auth bypass mechanism"
  "E2E bypass|E2E bypass mechanism"
  "mock auth|Mock authentication"
  "test auth|Test authentication"
  "createVault|Vault creation"
  "unlockVault|Vault unlock"
  "encryptVault|Vault encryption"
  "API_KEY|API key reference"
  "SECRET_KEY|Secret key reference"
  "PRIVATE_KEY|Private key reference"
  "PUBLIC_KEY|Public key reference"
)

# ─── Content-based patterns (medium): "pattern|reason" ──────────────────
# These trigger medium risk when found in file content or diff.
CONTENT_MEDIUM_PATTERNS=(
  "import.meta.env|Environment variable access"
  "process.env|Environment variable access"
  "permission|Permission handling"
  "role|Role-based access"
  "admin|Admin access"
  "RLS|Row-level security"
  "policy|Security policy"
  "authorize|Authorization logic"
  "session|Session management"
  "token|Token handling"
)

# ─── Content-based patterns (advisory): "pattern|reason" ─────────────────
# These are noted but do NOT escalate risk level on their own.
# They may contribute to higher classification when combined with high patterns.
CONTENT_ADVISORY_PATTERNS=(
  "auth|Auth keyword (advisory — may be casual reference)"
  "bypass|Bypass keyword (advisory — may be non-security context)"
  "allow|Allow keyword (advisory — may be CSS or logic)"
  "deny|Deny keyword (advisory — may be CSS or logic)"
  "user_id|User ID reference (advisory)"
  "household_id|Household ID reference (advisory)"
  "PII|PII reference (advisory)"
  "private|Private keyword (advisory — may be access modifier)"
  "upload|Upload reference (advisory)"
  "storage policy|Storage policy reference (advisory)"
)

# ─── Parse arguments ─────────────────────────────────────────────────────
DIFF_REF=""
FILES=()
MANUAL_OVERRIDE="false"
MANUAL_OVERRIDE_REASON=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --diff) DIFF_REF="$2"; shift 2 ;;
    --files) shift; while [[ $# -gt 0 && "$1" != --* ]]; do FILES+=("$1"); shift; done ;;
    --manual-override) MANUAL_OVERRIDE="true"; shift ;;
    --manual-override-reason) MANUAL_OVERRIDE_REASON="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# ─── Get changed files ───────────────────────────────────────────────────
if [[ -n "$DIFF_REF" ]]; then
  CHANGED_FILES=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && CHANGED_FILES+=("$line")
  done < <(git diff --name-only "$DIFF_REF" 2>/dev/null || echo "")
elif [[ ${#FILES[@]} -gt 0 ]]; then
  CHANGED_FILES=("${FILES[@]}")
else
  CHANGED_FILES=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && CHANGED_FILES+=("$line")
  done < <(git diff --name-only HEAD 2>/dev/null || echo "")
fi

FILE_COUNT=${#CHANGED_FILES[@]}

# ─── Classification state ───────────────────────────────────────────────
DETECTED_AREAS=""
DETAILS=""
RISK_LEVEL="none"
MUST_ESCALATE="false"
DETECTION_TYPE="none"
CONTENT_MATCHES=""
ADVISORY_MATCHES=""
CLASSIFIER_REASON=""

# ─── Helper: add area if not already present ─────────────────────────────
add_area() {
  local area="$1"
  if echo "$DETECTED_AREAS" | grep -qv "$area"; then
    if [[ -z "$DETECTED_AREAS" ]]; then
      DETECTED_AREAS="$area"
    else
      DETECTED_AREAS="$DETECTED_AREAS,$area"
    fi
  fi
}

# ─── Helper: upgrade risk level ──────────────────────────────────────────
upgrade_risk() {
  local new_level="$1"
  local escalate="$2"
  case "$new_level" in
    high)
      RISK_LEVEL="high"
      MUST_ESCALATE="true"
      ;;
    medium)
      if [[ "$RISK_LEVEL" != "high" ]]; then
        RISK_LEVEL="medium"
        if [[ "$escalate" == "true" ]]; then
          MUST_ESCALATE="true"
        fi
      fi
      ;;
  esac
}

# ─── 1. Path-based detection ────────────────────────────────────────────
for file in "${CHANGED_FILES[@]}"; do
  [[ -z "$file" ]] && continue
  file_lower=$(echo "$file" | tr '[:upper:]' '[:lower:]')

  for pattern_entry in "${PATH_PATTERNS[@]}"; do
    area="${pattern_entry%%|*}"
    rest="${pattern_entry#*|}"
    pattern="${rest%%|*}"
    reason="${rest#*|}"

    if echo "$file_lower" | grep -q "$pattern"; then
      add_area "$area"
      DETAILS="${DETAILS}    - $file: $area [path] ($reason)\n"
      DETECTION_TYPE="path"

      case "$area" in
        auth|security|secrets|payments) upgrade_risk "high" "true" ;;
        schema) upgrade_risk "medium" "true" ;;
        deployment|pii|storage) upgrade_risk "medium" "false" ;;
      esac
    fi
  done
done

# ─── 2. Content-based detection ─────────────────────────────────────────
for file in "${CHANGED_FILES[@]}"; do
  [[ -z "$file" ]] && continue

  # Skip content-based detection for documentation files
  # Docs often mention security terms descriptively without changing security behavior
  case "$file" in
    *.md|*.mdx|*.rst|LICENSE*|CHANGELOG*|CONTRIBUTING*|CODE_OF_CONDUCT*)
      continue
      ;;
  esac

  # Skip content-based detection for classifier/release-gate tooling scripts
  # These scripts contain auth/security regex patterns that cause self-detection noise.
  # Path-based detection still applies (classified as deployment tooling above).
  case "$file" in
    .github/scripts/*|.opencode/scripts/*)
      continue
      ;;
  esac

  # Get file content: use diff if --diff, otherwise read file directly
  if [[ -n "$DIFF_REF" ]]; then
    file_content=$(git diff "$DIFF_REF" -- "$file" 2>/dev/null || echo "")
  else
    # Read file if it exists and is not binary
    if [[ -f "$file" ]]; then
      # Skip binary files and files larger than 100KB
      file_size=$(wc -c < "$file" 2>/dev/null | tr -d ' ')
      if [[ -n "$file_size" && "$file_size" -lt 102400 ]]; then
        file_content=$(cat "$file" 2>/dev/null || echo "")
      else
        file_content=""
      fi
    else
      file_content=""
    fi
  fi

  [[ -z "$file_content" ]] && continue

  # Check for high-risk content patterns
  for pattern_entry in "${CONTENT_HIGH_PATTERNS[@]}"; do
    pattern="${pattern_entry%%|*}"
    reason="${pattern_entry#*|}"

    if echo "$file_content" | grep -q "$pattern"; then
      # Determine area based on pattern
      case "$pattern" in
        VITE_E2E|SignedIn|SignedOut|ClerkProvider|useAuth|useUser|@clerk|auth\ bypass|E2E\ bypass|mock\ auth|test\ auth)
          add_area "auth"
          add_area "security"
          ;;
        createVault|unlockVault|encryptVault)
          add_area "security"
          ;;
        API_KEY|SECRET_KEY|PRIVATE_KEY|PUBLIC_KEY)
          add_area "secrets"
          ;;
      esac

      DETAILS="${DETAILS}    - $file: content-high [content] ($reason: $pattern)\n"
      CONTENT_MATCHES="${CONTENT_MATCHES}${pattern},"
      upgrade_risk "high" "true"

      if [[ "$DETECTION_TYPE" == "path" ]]; then
        DETECTION_TYPE="path+content"
      else
        DETECTION_TYPE="content"
      fi
    fi
  done

  # Check for medium-risk content patterns
  for pattern_entry in "${CONTENT_MEDIUM_PATTERNS[@]}"; do
    pattern="${pattern_entry%%|*}"
    reason="${pattern_entry#*|}"

    if echo "$file_content" | grep -q "$pattern"; then
      case "$pattern" in
        import.meta.env|process.env) add_area "secrets" ;;
        permission|role|admin|RLS|policy|authorize) add_area "security" ;;
        session|token) add_area "auth" ;;
      esac

      # Only add detail if not already captured by high pattern
      if ! echo "$DETAILS" | grep -q "$file: content-high.*$pattern"; then
        DETAILS="${DETAILS}    - $file: content-medium [content] ($reason: $pattern)\n"
        CONTENT_MATCHES="${CONTENT_MATCHES}${pattern},"
      fi
      upgrade_risk "medium" "false"

      if [[ "$DETECTION_TYPE" == "none" ]]; then
        DETECTION_TYPE="content"
      elif [[ "$DETECTION_TYPE" == "path" ]]; then
        DETECTION_TYPE="path+content"
      fi
    fi
  done

  # Check for advisory content patterns (noted but do not escalate)
  for pattern_entry in "${CONTENT_ADVISORY_PATTERNS[@]}"; do
    pattern="${pattern_entry%%|*}"
    reason="${pattern_entry#*|}"

    if echo "$file_content" | grep -q "$pattern"; then
      # Special rule: if VITE_E2E is already detected AND advisory pattern is auth/bypass, upgrade to high
      if echo "$CONTENT_MATCHES" | grep -q "VITE_E2E" && [[ "$pattern" == "auth" || "$pattern" == "bypass" ]]; then
        add_area "auth"
        add_area "security"
        DETAILS="${DETAILS}    - $file: content-high [content] (VITE_E2E + $pattern combination → high auth/security)\n"
        CONTENT_MATCHES="${CONTENT_MATCHES}${pattern},"
        upgrade_risk "high" "true"
        if [[ "$DETECTION_TYPE" == "path" ]]; then
          DETECTION_TYPE="path+content"
        else
          DETECTION_TYPE="content"
        fi
      else
        # Advisory only — note but do not escalate
        ADVISORY_MATCHES="${ADVISORY_MATCHES}${pattern},"
        DETAILS="${DETAILS}    - $file: advisory [content] ($reason: $pattern)\n"

        # Set detection_type to content only if nothing higher has fired
        if [[ "$DETECTION_TYPE" == "none" ]]; then
          DETECTION_TYPE="content"
        elif [[ "$DETECTION_TYPE" == "path" ]]; then
          DETECTION_TYPE="path+content"
        fi
      fi
    fi
  done
done

# ─── 3. Apply manual override if supplied ───────────────────────────────
if [[ "$MANUAL_OVERRIDE" == "true" ]]; then
  DETECTION_TYPE="manual"
  if [[ "$RISK_LEVEL" != "high" ]]; then
    RISK_LEVEL="high"
    MUST_ESCALATE="true"
  fi
  if echo "$DETECTED_AREAS" | grep -qv "auth"; then
    if [[ -z "$DETECTED_AREAS" ]]; then
      DETECTED_AREAS="auth,security"
    else
      DETECTED_AREAS="${DETECTED_AREAS},auth,security"
    fi
  fi
  CLASSIFIER_REASON="Manual override: ${MANUAL_OVERRIDE_REASON:-unspecified false negative}"
  DETAILS="${DETAILS}    - MANUAL OVERRIDE: ${MANUAL_OVERRIDE_REASON:-unspecified}\n"
fi

# ─── 4. Build classifier_reason from matches ────────────────────────────
if [[ -z "$CLASSIFIER_REASON" ]]; then
  if [[ -n "$CONTENT_MATCHES" ]]; then
    CLASSIFIER_REASON="Content patterns matched: ${CONTENT_MATCHES%,}"
  elif [[ -n "$ADVISORY_MATCHES" ]]; then
    CLASSIFIER_REASON="Advisory patterns matched: ${ADVISORY_MATCHES%,}"
  elif [[ "$DETECTION_TYPE" == "path" ]]; then
    CLASSIFIER_REASON="Sensitive path detected"
  else
    CLASSIFIER_REASON="No sensitive patterns detected"
  fi
fi

# ─── 5. Determine required gates ────────────────────────────────────────
REQUIRED_GATES=""
if [[ "$RISK_LEVEL" == "high" || "$RISK_LEVEL" == "medium" ]]; then
  REQUIRED_GATES="reviewer"
fi
if [[ "$RISK_LEVEL" == "high" ]]; then
  REQUIRED_GATES="${REQUIRED_GATES},full_tests,ci,sast"
fi

# ─── 6. Determine classifier_detected_sensitive ─────────────────────────
CLASSIFIER_DETECTED_SENSITIVE="false"
if [[ "$RISK_LEVEL" != "none" ]]; then
  CLASSIFIER_DETECTED_SENSITIVE="true"
fi

# ─── 7. Output ───────────────────────────────────────────────────────────
# Remove trailing comma from content matches
CONTENT_MATCHES="${CONTENT_MATCHES%,}"
ADVISORY_MATCHES="${ADVISORY_MATCHES%,}"

echo "SENSITIVE_CHANGE_CLASSIFICATION:"
echo "  risk_level: $RISK_LEVEL"
echo "  sensitive_areas: [$DETECTED_AREAS]"
echo "  required_gates: [$REQUIRED_GATES]"
echo "  must_escalate: $MUST_ESCALATE"
echo "  detection_type: $DETECTION_TYPE"
echo "  classifier_detection_type: $DETECTION_TYPE"
echo "  classifier_detected_sensitive: $CLASSIFIER_DETECTED_SENSITIVE"
echo "  matched_content_patterns: [$CONTENT_MATCHES]"
echo "  matched_advisory_patterns: [$ADVISORY_MATCHES]"
echo "  classifier_reason: $CLASSIFIER_REASON"
echo "  manual_override: $MANUAL_OVERRIDE"
if [[ -n "$MANUAL_OVERRIDE_REASON" ]]; then
  echo "  manual_override_reason: $MANUAL_OVERRIDE_REASON"
fi
echo "  changed_files_checked: $FILE_COUNT"
if [[ -n "$DETAILS" ]]; then
  echo "  details:"
  echo -e "$DETAILS" | sed '/^$/d'
else
  echo "  details: none"
fi
