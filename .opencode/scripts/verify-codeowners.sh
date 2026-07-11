#!/usr/bin/env bash
# verify-codeowners.sh — v4.38 CODEOWNERS Verifier
#
# Checks whether a repo has a CODEOWNERS file and whether
# sensitive paths are covered by owner rules.
#
# Usage:
#   bash verify-codeowners.sh [--repo <path>] [--strict]
#
# Exit codes:
#   0 — verified or advisory (non-strict mode)
#   1 — missing CODEOWNERS (strict mode)

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

check_pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
check_fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
check_warn() { echo "  ⚠️  $1"; WARN=$((WARN + 1)); }

echo "=== CODEOWNERS Verifier ==="
echo "Repo: $REPO_PATH"
echo ""

# ─── Find CODEOWNERS file ────────────────────────────────────────────────
echo "== CODEOWNERS File =="
CODEOWNERS_FILE=""

for location in ".github/CODEOWNERS" "CODEOWNERS" "docs/CODEOWNERS"; do
  if [[ -f "$REPO_PATH/$location" ]]; then
    CODEOWNERS_FILE="$location"
    break
  fi
done

if [[ -z "$CODEOWNERS_FILE" ]]; then
  check_fail "No CODEOWNERS file found"
  echo "  Searched: .github/CODEOWNERS, CODEOWNERS, docs/CODEOWNERS"
  echo ""
  echo "=========================================="
  echo "PASSED: $PASS"
  echo "FAILED: $FAIL"
  echo "WARNINGS: $WARN"
  echo "=========================================="
  echo "Classification: missing_codeowners"
  if [[ "$STRICT" == "true" ]]; then exit 1; fi
  exit 0
fi

check_pass "CODEOWNERS found: $CODEOWNERS_FILE"

# ─── Check sensitive path coverage ───────────────────────────────────────
echo ""
echo "== Sensitive Path Coverage =="
CODEOWNERS_CONTENT=$(cat "$REPO_PATH/$CODEOWNERS_FILE" 2>/dev/null || echo "")

# Define sensitive paths that should have owners
declare -a SENSITIVE_PATHS=(
  ".github/workflows/ — CI/CD workflows"
  ".github/scripts/ — Release gate scripts"
  ".opencode/config/ — Trust policy and security config"
  "auth/ — Authentication code"
  "security/ — Security code"
  "secrets/ — Secrets management"
  "payment/ — Payment processing"
  "billing/ — Billing code"
  "schema/ — Database schema"
  "migrations/ — Database migrations"
  "supabase/ — Supabase config"
  "prisma/ — Prisma schema"
  "drizzle/ — Drizzle schema"
  ".env* — Environment files (should not be in CODEOWNERS but noted)"
  "Dockerfile — Container build config"
  "docker-compose* — Container orchestration"
  "vercel.json — Deploy config"
  "wrangler.toml — Cloudflare config"
)

COVERED=0
UNCOVERED=0

for entry in "${SENSITIVE_PATHS[@]}"; do
  path_pattern="${entry%% *}"
  description="${entry#* — }"

  # Check if this path pattern exists in the repo
  # (skip if the path doesn't exist in the repo)
  case "$path_pattern" in
    .env*) continue ;; # .env files shouldn't be in CODEOWNERS
    *) ;;
  esac

  # Check if CODEOWNERS covers this path
  if echo "$CODEOWNERS_CONTENT" | grep -q -- "$path_pattern" 2>/dev/null; then
    check_pass "$description: covered"
    COVERED=$((COVERED + 1))
  else
    # Only warn if the path exists in the repo
    base_path="${path_pattern%%/*}"
    if [[ -d "$REPO_PATH/$base_path" || -f "$REPO_PATH/$base_path" ]]; then
      check_warn "$description: path exists but NOT covered in CODEOWNERS"
      UNCOVERED=$((UNCOVERED + 1))
    fi
  fi
done

# ─── Check for wildcard default owner ───────────────────────────────────
echo ""
echo "== Default Owner =="
if echo "$CODEOWNERS_CONTENT" | grep -qE "^\*\s+" 2>/dev/null; then
  check_pass "Default owner (* pattern) is set"
else
  check_warn "No default owner (* pattern) — unlisted paths have no owner"
fi

# ─── Summary ────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "PASSED: $PASS"
echo "FAILED: $FAIL"
echo "WARNINGS: $WARN"
echo "Covered sensitive paths: $COVERED"
echo "Uncovered sensitive paths: $UNCOVERED"
echo "=========================================="

if [[ "$FAIL" -gt 0 ]]; then
  echo "Classification: missing_codeowners"
  if [[ "$STRICT" == "true" ]]; then exit 1; fi
elif [[ "$WARN" -gt 0 ]]; then
  echo "Classification: partially_covered"
else
  echo "Classification: verified"
fi

exit 0
