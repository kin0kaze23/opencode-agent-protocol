#!/bin/bash
# verify-environment.sh — Environment consistency verification
# Usage:
#   bash .opencode/scripts/verify-environment.sh --mode global
#   bash .opencode/scripts/verify-environment.sh --mode workspace
#   bash .opencode/scripts/verify-environment.sh --mode repo <repo-path>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0
WARN=0

pass() { printf '  \033[0;32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  \033[0;31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
warn() { printf '  \033[0;33m⚠\033[0m %s\n' "$1"; WARN=$((WARN + 1)); }

check_file() {
  local file="$1"
  local label="$2"
  if [[ -f "$file" ]]; then
    pass "$label"
  else
    fail "$label (missing: $file)"
  fi
}

check_not_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -Fq "$pattern" "$file" 2>/dev/null; then
    fail "$label (found forbidden: '$pattern' in $file)"
  else
    pass "$label"
  fi
}

check_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -Fq "$pattern" "$file" 2>/dev/null; then
    pass "$label"
  else
    fail "$label (missing: '$pattern' in $file)"
  fi
}

check_ignored() {
  local path="$1"
  local label="$2"
  if git check-ignore "$path" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label (not gitignored: $path)"
  fi
}

# ============================================================
# Parse arguments
# ============================================================

MODE=""
REPO_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    *)
      REPO_PATH="$1"
      shift
      ;;
  esac
done

if [[ -z "$MODE" ]]; then
  echo "Usage: bash verify-environment.sh --mode <global|workspace|repo> [repo-path]"
  exit 1
fi

echo "=========================================="
echo "Environment Verification — Mode: $MODE"
echo "=========================================="
echo "Root: $ROOT_DIR"
echo ""

# ============================================================
# Global Mode
# ============================================================
if [[ "$MODE" == "global" ]]; then
  echo "== Global Environment =="

  GLOBAL_DIR="$HOME/.config/opencode"

  check_file "$GLOBAL_DIR/opencode.json" "Global opencode.json exists"

  # Global should NOT contain behavioral policy
  if [[ -f "$GLOBAL_DIR/opencode.json" ]]; then
    check_not_contains "$GLOBAL_DIR/opencode.json" '"lanes"' "Global has no lane definitions"
    check_not_contains "$GLOBAL_DIR/opencode.json" '"token_budget"' "Global has no token budget"
    check_not_contains "$GLOBAL_DIR/opencode.json" '"gate_matrix"' "Global has no gate matrix"
  fi

  # Global prompts should exist
  for prompt in orchestrator architect budget explorer implementer planner reviewer visual-reviewer visual-reviewer-fallback; do
    check_file "$GLOBAL_DIR/prompts/$prompt.md" "Global prompt: $prompt"
  done

# ============================================================
# Workspace Mode
# ============================================================
elif [[ "$MODE" == "workspace" ]]; then
  echo "== Workspace Environment =="

  # Startup-loaded files
  check_file "$ROOT_DIR/.opencode/AGENTS.md" "AGENTS.md exists"
  check_file "$ROOT_DIR/.opencode/rules.md" "rules.md exists"
  check_file "$ROOT_DIR/.opencode/opencode.json" "opencode.json exists"
  check_file "$ROOT_DIR/.opencode/brain-config.json" "brain-config.json exists"

  # Version coherence
  if [[ -f "$ROOT_DIR/.opencode/brain-config.json" ]]; then
    VERSION=$(jq -r '.version' "$ROOT_DIR/.opencode/brain-config.json" 2>/dev/null || echo "unknown")
    if [[ "$VERSION" != "unknown" ]]; then
      pass "brain-config version: $VERSION"
      check_contains "$ROOT_DIR/.opencode/AGENTS.md" "v$VERSION" "AGENTS.md contains version v$VERSION"
      check_contains "$ROOT_DIR/.opencode/rules.md" "v$VERSION" "rules.md contains version v$VERSION"
      check_contains "$ROOT_DIR/NOW.md" "v$VERSION" "NOW.md contains version v$VERSION"
    else
      fail "brain-config version is unknown"
    fi
  fi

  # Helper-roster is reference-only (not in opencode.json instructions)
  check_not_contains "$ROOT_DIR/.opencode/opencode.json" "helper-roster.md" "helper-roster.md is NOT in opencode.json instructions"
  check_file "$ROOT_DIR/.opencode/helper-roster.md" "helper-roster.md exists as reference"

  # Command surface sync
  if [[ -f "$ROOT_DIR/.opencode/brain-config.json" ]]; then
    config_cmds=$(jq -r '.command_surface.commands[]' "$ROOT_DIR/.opencode/brain-config.json" 2>/dev/null | sed 's|^/||' | sort)
    actual_cmds=$(cd "$ROOT_DIR/.opencode/commands" && ls *.md 2>/dev/null | sed 's|\.md$||' | sort)
    if [[ "$config_cmds" == "$actual_cmds" ]]; then
      pass "command_surface matches actual command files ($(echo "$config_cmds" | wc -l | tr -d ' ') commands)"
    else
      fail "command_surface does not match actual command files"
      echo "    Diff:"
      diff <(echo "$config_cmds") <(echo "$actual_cmds") | head -10 | sed 's/^/    /'
    fi
  fi

  # Cache directories are gitignored
  check_ignored "$ROOT_DIR/.opencode/cache/" ".opencode/cache/ is gitignored"
  check_ignored "$ROOT_DIR/.opencode/.session-cache/" ".opencode/.session-cache/ is gitignored"
  # conformance/results has .md files gitignored
  if git check-ignore "$ROOT_DIR/.opencode/conformance/results/test.md" >/dev/null 2>&1; then
    pass ".opencode/conformance/results/ .md files are gitignored"
  else
    fail ".opencode/conformance/results/ .md files are not gitignored"
  fi

  # Archive is NOT gitignored (needs to be tracked)
  if git check-ignore "$ROOT_DIR/.opencode/archive/MANIFEST.md" >/dev/null 2>&1; then
    fail ".opencode/archive/ is gitignored (should be tracked)"
  else
    pass ".opencode/archive/ is tracked (not gitignored)"
  fi

  # Contract docs exist
  check_file "$ROOT_DIR/.opencode/docs/environment-contract.md" "environment-contract.md exists"
  check_file "$ROOT_DIR/.opencode/docs/runtime-contract.md" "runtime-contract.md exists"
  check_file "$ROOT_DIR/.opencode/docs/sync-contract.md" "sync-contract.md exists"
  check_file "$ROOT_DIR/.opencode/templates/REPO_PROTOCOL_BASELINE.md" "REPO_PROTOCOL_BASELINE.md template exists"

  # No hardcoded user paths in scripts (portability check)
  # Exclude this script itself and opencode-safe-launch.sh (which intentionally uses $HOME)
  HARDCODED=$(grep -rl '/Users/[^/]*/' "$ROOT_DIR/.opencode/scripts/"*.sh 2>/dev/null | grep -v 'opencode-safe-launch.sh' | grep -v 'verify-environment.sh' | head -5 || true)
  if [[ -z "$HARDCODED" ]]; then
    pass "No hardcoded user paths in scripts (portable)"
  else
    warn "Hardcoded user paths found in scripts:"
    echo "$HARDCODED" | sed 's/^/    /'
  fi

  # Vault path valid
  if [[ -d "$ROOT_DIR/vault" ]]; then
    pass "vault/ directory exists"
    if git -C "$ROOT_DIR/vault" status >/dev/null 2>&1; then
      pass "vault/ is a valid git repo"
    else
      warn "vault/ is not a git repo"
    fi
  else
    warn "vault/ directory does not exist"
  fi

# ============================================================
# Repo Mode
# ============================================================
elif [[ "$MODE" == "repo" ]]; then
  if [[ -z "$REPO_PATH" ]]; then
    echo "Error: --mode repo requires a repo path"
    exit 1
  fi

  # Resolve repo path
  if [[ "$REPO_PATH" == /* ]]; then
    REPO_DIR="$REPO_PATH"
  else
    REPO_DIR="$ROOT_DIR/$REPO_PATH"
  fi

  echo "== Repo Environment: $REPO_DIR =="

  if [[ ! -d "$REPO_DIR" ]]; then
    fail "Repo directory does not exist: $REPO_DIR"
  else
    check_file "$REPO_DIR/AGENTS.md" "Repo AGENTS.md exists"
    check_file "$REPO_DIR/NOW.md" "Repo NOW.md exists"

    # PROJECT_MEMORY.md is optional but recommended
    if [[ -f "$REPO_DIR/PROJECT_MEMORY.md" ]]; then
      pass "PROJECT_MEMORY.md exists"
    else
      warn "PROJECT_MEMORY.md does not exist (recommended for active repos)"
    fi

    # Repo AGENTS.md should NOT define workspace-level concerns
    if [[ -f "$REPO_DIR/AGENTS.md" ]]; then
      check_not_contains "$REPO_DIR/AGENTS.md" '"lanes"' "Repo AGENTS.md has no lane definitions"
      check_not_contains "$REPO_DIR/AGENTS.md" '"token_budget"' "Repo AGENTS.md has no token budget"
      check_not_contains "$REPO_DIR/AGENTS.md" '"gate_matrix"' "Repo AGENTS.md has no gate matrix"
    fi

    # Repo .opencode/ is exception-only
    if [[ -d "$REPO_DIR/.opencode" ]]; then
      warn "Repo has .opencode/ directory (exception-only, requires ADR)"
    else
      pass "Repo has no .opencode/ directory (standard)"
    fi
  fi

else
  echo "Error: unknown mode '$MODE'"
  echo "Valid modes: global, workspace, repo"
  exit 1
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "=========================================="
printf '  PASSED: %d\n' "$PASS"
printf '  FAILED: %d\n' "$FAIL"
printf '  WARNED: %d\n' "$WARN"
echo "=========================================="

if [[ "$FAIL" -gt 0 ]]; then
  echo "[FAIL] Environment verification failed."
  exit 1
else
  echo "[PASS] Environment verification passed."
  exit 0
fi
