#!/usr/bin/env bash
# v4.37.2a — Autopilot Permission Validation Script
#
# Validates that the opencode.json contains the expected Safe Autopilot
# permission structure. Checks for presence of required allow/deny patterns
# for both orchestrator and implementer agents.
#
# Usage:
#   bash .opencode/scripts/validate-autopilot-permissions.sh
#
# Exit codes:
#   0 — All checks passed
#   1 — One or more checks failed

set -euo pipefail

CONFIG=".opencode/opencode.json"
PASS=0
FAIL=0
WARN=0

# ============================================================
# Helper functions
# ============================================================

check() {
  local description="$1"
  local result="$2"
  if [ "$result" = "true" ]; then
    echo "  [PASS] $description"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $description"
    FAIL=$((FAIL + 1))
  fi
}

check_warn() {
  local description="$1"
  local result="$2"
  if [ "$result" = "true" ]; then
    echo "  [PASS] $description"
    PASS=$((PASS + 1))
  else
    echo "  [WARN] $description"
    WARN=$((WARN + 1))
  fi
}

has_pattern() {
  local section="$1"
  local pattern="$2"
  python3 -c "
import json, sys
with open('$CONFIG') as f:
    cfg = json.load(f)
# Check global permission
found = False
perm = cfg.get('permission', {})
if '$section' in perm:
    val = perm['$section']
    if isinstance(val, dict) and '$pattern' in val:
        found = True
    elif isinstance(val, str) and val == '$pattern':
        found = True
# Check orchestrator
orch = cfg.get('agent', {}).get('orchestrator', {}).get('permission', {})
if '$section' in orch:
    val = orch['$section']
    if isinstance(val, dict) and '$pattern' in val:
        found = True
# Check implementer
impl = cfg.get('agent', {}).get('implementer', {}).get('permission', {})
if '$section' in impl:
    val = impl['$section']
    if isinstance(val, dict) and '$pattern' in val:
        found = True
print('true' if found else 'false')
" 2>/dev/null
}

has_orchestrator_pattern() {
  local section="$1"
  local pattern="$2"
  python3 -c "
import json
with open('$CONFIG') as f:
    cfg = json.load(f)
# Check global permission (orchestrator inherits from global)
perm = cfg.get('permission', {})
if '$section' in perm:
    val = perm['$section']
    if isinstance(val, dict) and '$pattern' in val:
        print('true')
        exit()
    elif isinstance(val, str) and val == '$pattern':
        print('true')
        exit()
# Check orchestrator per-agent override
orch = cfg.get('agent', {}).get('orchestrator', {}).get('permission', {})
val = orch.get('$section', {})
if isinstance(val, dict):
    print('true' if '$pattern' in val else 'false')
else:
    print('false')
" 2>/dev/null
}

has_implementer_pattern() {
  local section="$1"
  local pattern="$2"
  python3 -c "
import json
with open('$CONFIG') as f:
    cfg = json.load(f)
# Check global permission (implementer inherits from global)
perm = cfg.get('permission', {})
if '$section' in perm:
    val = perm['$section']
    if isinstance(val, dict) and '$pattern' in val:
        print('true')
        exit()
    elif isinstance(val, str) and val == '$pattern':
        print('true')
        exit()
# Check implementer per-agent override
impl = cfg.get('agent', {}).get('implementer', {}).get('permission', {})
val = impl.get('$section', {})
if isinstance(val, dict):
    print('true' if '$pattern' in val else 'false')
else:
    print('false')
" 2>/dev/null
}

get_permission_value() {
  local agent="$1"
  local section="$2"
  local pattern="$3"
  python3 -c "
import json
with open('$CONFIG') as f:
    cfg = json.load(f)
if '$agent' == 'global':
    val = cfg.get('permission', {}).get('$section', {})
else:
    val = cfg.get('agent', {}).get('$agent', {}).get('permission', {}).get('$section', {})
if isinstance(val, dict):
    print(val.get('$pattern', 'NOT_FOUND'))
else:
    print(val if val else 'NOT_FOUND')
" 2>/dev/null
}

# ============================================================
# Tests
# ============================================================

echo "=========================================="
echo "v4.37.2a Autopilot Permission Validation"
echo "=========================================="
echo ""

# --- 1. JSON validity ---
echo "1. JSON Syntax"
python3 -c "import json; json.load(open('$CONFIG'))" 2>/dev/null
check "opencode.json is valid JSON" "true"
echo ""

# --- 2. Global permission defaults ---
echo "2. Global Permission Defaults"
check "read: allow default" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); v=cfg.get('permission',{}).get('read',{}); print('true' if v.get('*')=='allow' else 'false')" 2>/dev/null)"
check "read: .env denied" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); v=cfg.get('permission',{}).get('read',{}); print('true' if v.get('.env')=='deny' else 'false')" 2>/dev/null)"
check "glob: allow" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); print('true' if cfg.get('permission',{}).get('glob')=='allow' else 'false')" 2>/dev/null)"
check "grep: allow" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); print('true' if cfg.get('permission',{}).get('grep')=='allow' else 'false')" 2>/dev/null)"
check "list: allow" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); print('true' if cfg.get('permission',{}).get('list')=='allow' else 'false')" 2>/dev/null)"
check "lsp: allow" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); print('true' if cfg.get('permission',{}).get('lsp')=='allow' else 'false')" 2>/dev/null)"
check "todowrite: allow" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); print('true' if cfg.get('permission',{}).get('todowrite')=='allow' else 'false')" 2>/dev/null)"
check "webfetch: allow" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); print('true' if cfg.get('permission',{}).get('webfetch')=='allow' else 'false')" 2>/dev/null)"
check "websearch: allow" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); print('true' if cfg.get('permission',{}).get('websearch')=='allow' else 'false')" 2>/dev/null)"
check "skill: allow" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); print('true' if cfg.get('permission',{}).get('skill')=='allow' else 'false')" 2>/dev/null)"
check "external_directory: deny" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); print('true' if cfg.get('permission',{}).get('external_directory')=='deny' else 'false')" 2>/dev/null)"
check "doom_loop: deny" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); print('true' if cfg.get('permission',{}).get('doom_loop')=='deny' else 'false')" 2>/dev/null)"
echo ""

# --- 3. Orchestrator edit denies ---
echo "3. Orchestrator Edit Denies"
for pattern in ".env" ".env.*" "*/.env" "*/.env.*" \
  "package.json" "*/package.json" "package-lock.json" "*/package-lock.json" \
  "pnpm-lock.yaml" "*/pnpm-lock.yaml" "yarn.lock" "*/yarn.lock" \
  "bun.lock" "*/bun.lock" "bun.lockb" "*/bun.lockb" \
  "Cargo.toml" "*/Cargo.toml" "Cargo.lock" "*/Cargo.lock" \
  "requirements.txt" "*/requirements.txt" "pyproject.toml" "*/pyproject.toml" \
  "poetry.lock" "*/poetry.lock" "go.mod" "*/go.mod" "go.sum" "*/go.sum" \
  "Gemfile" "*/Gemfile" "Gemfile.lock" "*/Gemfile.lock" \
  "AGENTS.md" "*/AGENTS.md" \
  ".opencode/*" "*/.opencode/*" ".github/*" "*/.github/*" \
  "supabase/*" "*/supabase/*" "prisma/*" "*/prisma/*" \
  "drizzle/*" "*/drizzle/*" "migrations/*" "*/migrations/*" \
  "auth/*" "*/auth/*" "payment/*" "*/payment/*" \
  "payments/*" "*/payments/*" "billing/*" "*/billing/*" \
  "secrets/*" "*/secrets/*" \
  "terraform/*" "*/terraform/*" "*.tf" \
  "kubernetes/*" "*/kubernetes/*" "k8s/*" "*/k8s/*" "helm/*" "*/helm/*" \
  "vercel.json" "*/vercel.json" "wrangler.toml" "*/wrangler.toml" \
  "firebase.json" "*/firebase.json" "netlify.toml" "*/netlify.toml" \
  "railway.json" "*/railway.json" \
  "Dockerfile" "Dockerfile*" "*/Dockerfile" "*/Dockerfile*" \
  "docker-compose*.yml" "*/docker-compose*.yml" \
  "docker-compose*.yaml" "*/docker-compose*.yaml" \
  "Makefile" "*/Makefile" "Procfile" "*/Procfile"; do
  result=$(has_orchestrator_pattern edit "$pattern")
  check "edit deny: $pattern" "$result"
done
echo ""

# --- 4. Orchestrator bash allows ---
echo "4. Orchestrator Bash Allows"
for pattern in "pwd" "ls *" "find *" "grep *" "rg *" "cat *" "head *" "tail *" \
  "wc *" "tree *" "file *" "diff *" \
  "git status*" "git diff*" "git log*" "git branch*" "git show*" "git rev-parse*" \
  "npm run lint*" "npm run typecheck*" "npm run test*" "npm run build*" "npm run dev*" \
  "pnpm lint*" "pnpm typecheck*" "pnpm test*" "pnpm build*" "pnpm dev*" \
  "npx tsc*" "npx eslint*" "npx prettier --check*" \
  "cargo check*" "cargo test*" "cargo build*" "cargo clippy*" "cargo fmt --check*" \
  "python -m pytest*" "pytest*" "python -m mypy*" "ruff check*" "ruff format --check*" \
  "swift build*" "swift test*" \
  "bash .opencode/scripts/lite-mode-eligibility.sh *" \
  "bash .opencode/scripts/workspace-protocol-guard.sh *" \
  "bash .opencode/scripts/senior-self-review.sh *" \
  "bash .opencode/scripts/find-tests.sh *" \
  "bash .opencode/scripts/detect-untested.sh *" \
  "bash .opencode/scripts/sensitive-change-classifier.sh *" \
  "bash .opencode/scripts/commit-scope-guard.sh *" \
  "bash .opencode/scripts/reviewer-evidence-detector.sh *" \
  "bash .opencode/scripts/browser-verification-preflight.sh *" \
  "bash .opencode/scripts/diff-analyze.sh *" \
  "bash .opencode/scripts/session-cache.sh *" \
  "bash .opencode/git-guard/git-guard.sh commit*"; do
  result=$(has_orchestrator_pattern bash "$pattern")
  check "bash allow: $pattern" "$result"
done
echo ""

# --- 5. Orchestrator bash denies ---
echo "5. Orchestrator Bash Denies"
for pattern in "cat .env*" "cat */.env*" "head .env*" "head */.env*" \
  "tail .env*" "tail */.env*" "grep * .env*" "grep * */.env*" \
  "rg * .env*" "rg * */.env*" "less .env*" "more .env*" \
  "git show *:.env*" "git show *:.env.*" \
  "git add *" "git commit *" "git push *" "git reset --hard*" "git clean *" \
  "rm -rf *" "chmod *" "chown *" \
  "npm install*" "npm uninstall*" "npm update*" \
  "pnpm add*" "pnpm remove*" "pnpm install*" \
  "yarn add*" "bun add*" \
  "cargo add*" "cargo install*" \
  "pip install*" "python -m pip install*" \
  "poetry add*" "poetry install*" \
  "go get*" "bundle install*" "gem install*" \
  "vercel *" "wrangler *" "supabase *" "firebase *" "railway *" "fly *" \
  "gh pr merge*" "gh release*" \
  "curl * | sh" "wget * | sh" \
  "npx eslint --fix*"; do
  result=$(has_orchestrator_pattern bash "$pattern")
  check "bash deny: $pattern" "$result"
done
echo ""

# --- 6. Implementer has same edit/bash config ---
echo "6. Implementer Permission Parity"
for pattern in ".env" "package.json" "*/package.json" "Cargo.toml" \
  "AGENTS.md" ".opencode/*" ".github/*" "supabase/*" "prisma/*" \
  "auth/*" "payment/*" "billing/*" "secrets/*" \
  "vercel.json" "Dockerfile" "Makefile" "Procfile"; do
  result=$(has_implementer_pattern edit "$pattern")
  check "implementer edit deny: $pattern" "$result"
done
for pattern in "git push *" "git commit *" "npm install*" "pnpm add*" \
  "cargo add*" "pip install*" "vercel *" "supabase *" "rm -rf *" "chmod *"; do
  result=$(has_implementer_pattern bash "$pattern")
  check "implementer bash deny: $pattern" "$result"
done
check "implementer task: deny all" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); v=cfg.get('agent',{}).get('implementer',{}).get('permission',{}).get('task',{}); print('true' if v.get('*')=='deny' else 'false')" 2>/dev/null)"
echo ""

# --- 7. NOW.md and PLAN.md NOT denied ---
echo "7. State Files Not Denied"
check "NOW.md not in edit deny" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); v=cfg.get('agent',{}).get('orchestrator',{}).get('permission',{}).get('edit',{}); print('true' if 'NOW.md' not in v else 'false')" 2>/dev/null)"
check "PLAN.md not in edit deny" "$(python3 -c "import json; cfg=json.load(open('$CONFIG')); v=cfg.get('agent',{}).get('orchestrator',{}).get('permission',{}).get('edit',{}); print('true' if 'PLAN.md' not in v else 'false')" 2>/dev/null)"
echo ""

# --- 8. Other agents still locked down ---
echo "8. Other Agents Still Locked Down"
for agent in explorer planner reviewer architect budget; do
  result=$(python3 -c "import json; cfg=json.load(open('$CONFIG')); v=cfg.get('agent',{}).get('$agent',{}).get('permission',{}).get('edit'); print('true' if v=='deny' else 'false')" 2>/dev/null)
  check "$agent edit: deny" "$result"
  result=$(python3 -c "import json; cfg=json.load(open('$CONFIG')); v=cfg.get('agent',{}).get('$agent',{}).get('permission',{}).get('bash'); print('true' if v=='deny' else 'false')" 2>/dev/null)
  check "$agent bash: deny" "$result"
done
echo ""

# --- 9. Autopilot launch script exists ---
echo "9. Autopilot Launch Script"
check ".opencode/bin/autopilot exists" "$(test -f .opencode/bin/autopilot && echo true || echo false)"
check ".opencode/bin/autopilot is executable" "$(test -x .opencode/bin/autopilot && echo true || echo false)"
echo ""

# --- 10. Git-guard preserved ---
echo "10. Git-Guard Preservation"
check "git-guard commit allowed" "$(has_orchestrator_pattern bash 'bash .opencode/git-guard/git-guard.sh commit*')"
check "raw git commit denied" "$(has_orchestrator_pattern bash 'git commit *')"
check "raw git push denied" "$(has_orchestrator_pattern bash 'git push *')"
echo ""

# ============================================================
# Summary
# ============================================================
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "  PASSED: $PASS"
echo "  WARNED: $WARN"
echo "  FAILED: $FAIL"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "[FAIL] $FAIL check(s) failed. Review the output above."
  exit 1
else
  echo "[PASS] All checks passed. Autopilot permission profile is valid."
  exit 0
fi
