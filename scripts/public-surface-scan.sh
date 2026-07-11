#!/usr/bin/env bash
# scripts/public-surface-scan.sh
# Scans the repository for personal data that must not be published.
# Fails (exit 1) if any disallowed match is found.
# Prints path and category, never prints matched values.
#
# Usage: bash scripts/public-surface-scan.sh [--strict]
#   --strict  Also warn on generic /Users/ template references
#
# Exit codes:
#   0 = clean
#   1 = disallowed matches found

set -euo pipefail

STRICT="${1:-}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0

# Exclude this script, OOXML schema files (paperClips is a Word feature),
# and policy docs that intentionally list excluded names
EXCLUDE_PATTERN='^./.git/|^./scripts/public-surface-scan.sh|office/schemas/.*\.xsd$|^./docs/PUBLICATION_POLICY.md|^./NOW.md|^./.gitignore'

scan_category() {
  local category="$1"
  shift
  local patterns=("$@")
  local found=0

  for pattern in "${patterns[@]}"; do
    local matches
    matches=$(cd "$ROOT_DIR" && grep -rlE "$pattern" . 2>/dev/null | grep -vE "$EXCLUDE_PATTERN" || true)
    if [ -n "$matches" ]; then
      if [ "$found" -eq 0 ]; then
        echo ""
        echo "FAIL: $category"
      fi
      found=1
      echo "$matches" | while read -r file; do
        echo "  $file"
      done
    fi
  done

  if [ "$found" -eq 1 ]; then
    FAILURES=$((FAILURES + 1))
  fi
}

check_directory_absent() {
  local dirname="$1"
  if [ -d "$ROOT_DIR/$dirname" ]; then
    echo ""
    echo "FAIL: Forbidden directory present: $dirname/"
    FAILURES=$((FAILURES + 1))
  fi
}

echo "=== Public Surface Scan ==="
echo "Scanning: $ROOT_DIR"
echo ""

# ─────────────────────────────────────────────────────────────
# 1. Personal legal identity
# ─────────────────────────────────────────────────────────────
scan_category "Personal legal identity" \
  'Jonathan Nugroho' \
  'jonathannugroho'

# ─────────────────────────────────────────────────────────────
# 2. Personal project names — variant-aware
#    Covers: PascalCase, camelCase, space, kebab, snake, lowercase
# ─────────────────────────────────────────────────────────────
scan_category "Personal project names" \
  'AreteLifeOS|Arete Life OS|arete-life-os|arete_life_os|aretelifeos' \
  'AutomationHub|Automation Hub|automation-hub|automation_hub|automationhub' \
  'Stillness|stillness' \
  'LifePilot|Life Pilot|life-pilot|life_pilot|lifepilot' \
  'Hermes-agent|Hermes agent|hermes-agent|hermes_agent|hermesagent' \
  'ElizaDashboard|Eliza Dashboard|eliza-dashboard|eliza_dashboard|elizadashboard' \
  'PortfolioAnalyser|Portfolio Analyser|portfolio-analyser|portfolio_analyser' \
  'IronClaw|Iron Claw|iron-claw|iron_claw|ironclaw' \
  'OpenClaw|Open Claw|open-claw|open_claw|openclaw' \
  'Paperclip|paperclip' \
  'BabyGuide|Baby Guide|baby-guide|baby_guide|babyguide'

# ─────────────────────────────────────────────────────────────
# 3. Personal /Users/ paths (strict mode also catches templates)
# ─────────────────────────────────────────────────────────────
if [ "$STRICT" = "--strict" ]; then
  scan_category "Personal /Users/ paths (strict)" \
    '/Users/[^/]+/'
else
  # Non-strict: only flag real personal paths, allow /Users/<username>/ templates
  scan_category "Personal /Users/ paths" \
    '/Users/jonathannugroho'
fi

# ─────────────────────────────────────────────────────────────
# 4. Old repo name
# ─────────────────────────────────────────────────────────────
scan_category "Old repo name" \
  'personal-projects-control-plane'

# ─────────────────────────────────────────────────────────────
# 5. Secrets patterns (actual values, not pattern definitions)
# ─────────────────────────────────────────────────────────────
scan_category "Secrets patterns" \
  'sk-ant-[a-zA-Z0-9]{20,}' \
  'sk-sp-[a-zA-Z0-9]{20,}' \
  'AKIA[A-Z0-9]{16}' \
  'ghp_[a-zA-Z0-9]{36}' \
  'gho_[a-zA-Z0-9]{36}' \
  'sk-[a-zA-Z0-9]{48}'

# ─────────────────────────────────────────────────────────────
# 6. Forbidden directories
# ─────────────────────────────────────────────────────────────
check_directory_absent "vault"
check_directory_absent "reports"
check_directory_absent ".paperclip"
check_directory_absent "__pycache__"
check_directory_absent ".pytest_cache"
check_directory_absent "dist"
check_directory_absent "build"
check_directory_absent "node_modules"
check_directory_absent ".playwright-mcp"

# ─────────────────────────────────────────────────────────────
# 7. Generated artifacts
# ─────────────────────────────────────────────────────────────
scan_category "Generated artifacts" \
  '\.pyc$' \
  '\.class$'

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== PASS: Public surface scan clean ==="
  exit 0
else
  echo "=== FAIL: $FAILURES category(ies) with disallowed matches ==="
  echo ""
  echo "Fix these before publishing. Do not commit files that contain"
  echo "personal project names, identity, secrets, or forbidden directories."
  exit 1
fi
