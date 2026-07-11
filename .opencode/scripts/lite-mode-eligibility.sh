#!/usr/bin/env bash
# Lite Mode Eligibility Classifier (v4.20.1)
#
# Determines whether Lite Mode is allowed for a given set of changed files.
# This is a MECHANICAL check — it does not rely on model judgment.
#
# Usage:
#   bash .opencode/scripts/lite-mode-eligibility.sh <file1> [file2] [file3] ...
#   git diff --name-only | bash .opencode/scripts/lite-mode-eligibility.sh
#
# Output (structured, machine-parseable):
#   LITE_MODE_ELIGIBILITY:
#     allowed: yes/no
#     detected_lane: DIRECT/FAST/STANDARD/HIGH-RISK
#     file_count: N
#     reasons:
#       - <reason 1>
#       - <reason 2>
#     required_escalation: none/STANDARD/HIGH-RISK
#
# Exit codes:
#   0 — Lite Mode is allowed
#   1 — Lite Mode is blocked (sensitive paths or thresholds exceeded)

set -uo pipefail

# ============================================================
# Sensitive path patterns — Lite Mode is blocked if any match
# ============================================================

# Auth/security/payment/crypto/schema patterns
SENSITIVE_KEYWORDS=(
  "auth" "login" "session" "token" "jwt" "password" "credential"
  "payment" "billing" "stripe" "checkout" "subscription"
  "crypto" "encrypt" "decrypt" "cipher" "hash" "salt"
  "schema" "migration" "migrate" "prisma" "drizzle"
  "supabase" "rls" "policy" "row-level"
  "secrets" ".env" "doppler" "api-key" "apikey"
  "permission" "rbac" "role" "guard" "middleware"
  "security" "vulnerability" "xss" "csrf" "csp"
  "user-data" "personal" "gdpr" "pii"
)

# Package manager / lockfile patterns
PACKAGE_PATTERNS=(
  "package.json" "package-lock.json" "pnpm-lock.yaml"
  "yarn.lock" "bun.lock" "Cargo.lock"
  "requirements.txt" "pyproject.toml" "poetry.lock"
  "go.mod" "go.sum" "Gemfile" "Gemfile.lock"
)

# Deployment / infra / CI patterns
DEPLOY_PATTERNS=(
  "vercel.json" "wrangler.toml" "Dockerfile" "docker-compose"
  ".github/workflows" "Makefile" "Procfile"
  "opencode.json" "brain-config.json" "model-registry.yaml"
  "helper-roster.md" "rules.md" "AGENTS.md"
  "git-guard" "pre-commit" "pre-push"
  "terraform" "kubernetes" "k8s" "helm"
)

# Destructive command patterns (checked in file content, not just paths)
DESTRUCTIVE_KEYWORDS=(
  "DROP TABLE" "DROP COLUMN" "TRUNCATE" "DELETE FROM"
  "git push --force" "git push -f" "git reset --hard"
  "git clean -fd" "rm -rf" "DROP DATABASE"
)

# ============================================================
# Classifier logic
# ============================================================

# Read file paths from arguments or stdin
FILES=()
if [ $# -gt 0 ]; then
  FILES=("$@")
else
  while IFS= read -r line; do
    [ -n "$line" ] && FILES+=("$line")
  done
fi

FILE_COUNT=${#FILES[@]}

# Initialize output
ALLOWED="yes"
DETECTED_LANE="DIRECT"
REASONS=()
REQUIRED_ESCALATION="none"

# --- Check 1: File count thresholds ---

if [ "$FILE_COUNT" -eq 0 ]; then
  ALLOWED="no"
  REASONS+=("No files provided — cannot classify")
  REQUIRED_ESCALATION="STANDARD"
elif [ "$FILE_COUNT" -eq 1 ]; then
  DETECTED_LANE="DIRECT"
elif [ "$FILE_COUNT" -le 3 ]; then
  DETECTED_LANE="FAST"
elif [ "$FILE_COUNT" -le 6 ]; then
  DETECTED_LANE="STANDARD"
  ALLOWED="no"
  REASONS+=("File count ($FILE_COUNT) exceeds FAST threshold (3) — STANDARD lane required")
  REQUIRED_ESCALATION="STANDARD"
elif [ "$FILE_COUNT" -le 10 ]; then
  DETECTED_LANE="HIGH-RISK"
  ALLOWED="no"
  REASONS+=("File count ($FILE_COUNT) exceeds STANDARD threshold (6) — HIGH-RISK lane required")
  REQUIRED_ESCALATION="HIGH-RISK"
else
  DETECTED_LANE="HIGH-RISK"
  ALLOWED="no"
  REASONS+=("File count ($FILE_COUNT) exceeds HIGH-RISK threshold (10) — manual review required")
  REQUIRED_ESCALATION="HIGH-RISK"
fi

# --- Check 2: Sensitive path patterns ---

check_sensitive_path() {
  local filepath="$1"
  local lower_path
  lower_path=$(echo "$filepath" | tr '[:upper:]' '[:lower:]')

  for keyword in "${SENSITIVE_KEYWORDS[@]}"; do
    if echo "$lower_path" | grep -q "$keyword"; then
      echo "sensitive:$keyword"
      return 0
    fi
  done

  for pattern in "${PACKAGE_PATTERNS[@]}"; do
    if echo "$lower_path" | grep -q "$pattern"; then
      echo "package:$pattern"
      return 0
    fi
  done

  for pattern in "${DEPLOY_PATTERNS[@]}"; do
    if echo "$lower_path" | grep -q "$pattern"; then
      echo "deploy:$pattern"
      return 0
    fi
  done

  echo "clean"
  return 1
}

SENSITIVE_HITS=()
for file in "${FILES[@]}"; do
  result=$(check_sensitive_path "$file")
  if [ "$result" != "clean" ]; then
    SENSITIVE_HITS+=("$file -> $result")
  fi
done

if [ ${#SENSITIVE_HITS[@]} -gt 0 ]; then
  ALLOWED="no"
  for hit in "${SENSITIVE_HITS[@]}"; do
    REASONS+=("Sensitive path detected: $hit")
  done
  # Determine escalation level based on sensitive type
  for hit in "${SENSITIVE_HITS[@]}"; do
    if echo "$hit" | grep -q "sensitive:\(auth\|payment\|crypto\|schema\|migration\|secrets\|user-data\)"; then
      REQUIRED_ESCALATION="HIGH-RISK"
      break
    elif echo "$hit" | grep -q "deploy:\(opencode.json\|brain-config.json\|model-registry.yaml\|helper-roster.md\|rules.md\|AGENTS.md\)"; then
      REQUIRED_ESCALATION="HIGH-RISK"
      break
    elif [ "$REQUIRED_ESCALATION" = "none" ]; then
      REQUIRED_ESCALATION="STANDARD"
    fi
  done
fi

# --- Check 3: Destructive content patterns (if files exist on disk) ---

DESTRUCTIVE_HITS=()
for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    for keyword in "${DESTRUCTIVE_KEYWORDS[@]}"; do
      if grep -qi "$keyword" "$file" 2>/dev/null; then
        DESTRUCTIVE_HITS+=("$file -> destructive:$keyword")
      fi
    done
  fi
done

if [ ${#DESTRUCTIVE_HITS[@]} -gt 0 ]; then
  ALLOWED="no"
  for hit in "${DESTRUCTIVE_HITS[@]}"; do
    REASONS+=("Destructive content detected: $hit")
  done
  REQUIRED_ESCALATION="HIGH-RISK"
fi

# --- Output ---

echo "LITE_MODE_ELIGIBILITY:"
echo "  allowed: $ALLOWED"
echo "  detected_lane: $DETECTED_LANE"
echo "  file_count: $FILE_COUNT"

if [ ${#REASONS[@]} -gt 0 ]; then
  echo "  reasons:"
  for reason in "${REASONS[@]}"; do
    echo "    - $reason"
  done
else
  echo "  reasons: []"
fi

echo "  required_escalation: $REQUIRED_ESCALATION"

# Exit code
if [ "$ALLOWED" = "yes" ]; then
  exit 0
else
  exit 1
fi
