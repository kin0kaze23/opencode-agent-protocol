#!/usr/bin/env bash
# oc-status.sh — Read-only OpenCode operator health check
#
# Usage:
#   bash .opencode/scripts/oc-status.sh          # Fast mode (default)
#   bash .opencode/scripts/oc-status.sh --full   # Full mode (runs conformance)
#
# Rules:
#   - Read-only: never mutates files
#   - Fast by default: no sync, no benchmarks
#   - Never prints API keys or secret values
#   --full runs conformance suite (may take 10-30 seconds)

set -euo pipefail

# Suppress benign SIGPIPE (141) from head/tail closing pipe early.
# Does NOT suppress real command failures — only 0 and 141 pass through.
sigpipe_ok() { local c=$?; [[ $c -eq 0 || $c -eq 141 ]] && return 0; return $c; }

# Suppress benign SIGPIPE (141) and grep no-match (1) for optional filter pipelines.
# Used only where grep producing zero results is a valid outcome.
grep_pipe_ok() { local c=$?; [[ $c -eq 0 || $c -eq 1 || $c -eq 141 ]] && return 0; return $c; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

FULL_MODE=0
if [[ "${1:-}" == "--full" ]]; then
  FULL_MODE=1
fi

# ── Header ────────────────────────────────────────────────────────────────────
echo -e "${BLUE}═══════════════════════════════════════════════════════${RESET}"
echo -e "${BLUE}  OpenCode Status${RESET}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${CYAN}Timestamp:${RESET} $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo ""

# ── 1. OpenCode Version ──────────────────────────────────────────────────────
echo -e "${BLUE}── OpenCode Version ──────────────────────────────────${RESET}"
if command -v opencode &>/dev/null; then
  OC_VERSION=$(opencode --version 2>/dev/null || echo "unknown")
  echo -e "  ${CYAN}Version:${RESET} $OC_VERSION"
else
  echo -e "  ${RED}✗${RESET} opencode not found in PATH"
fi
echo ""

# ── 2. Home OpenCode Config Drift ─────────────────────────────────────────────
echo -e "${BLUE}── Home OpenCode Config Drift ────────────────────────${RESET}"
HOME_OPENCODE_JSON="$HOME/opencode.json"

if [[ ! -e "$HOME_OPENCODE_JSON" ]]; then
  echo -e "  ${GREEN}✓${RESET} ~/opencode.json absent; no home-project config drift detected"
elif [[ ! -f "$HOME_OPENCODE_JSON" ]]; then
  echo -e "  ${YELLOW}⚠${RESET} ~/opencode.json exists but is not a regular file; inspect manually"
else
  if ! jq empty "$HOME_OPENCODE_JSON" &>/dev/null; then
    echo -e "  ${YELLOW}⚠${RESET} ~/opencode.json exists but is not valid JSON; inspect manually"
  elif jq -e '((.mcp.enabled? // null | type) == "array") or ((.mcp.disabled? // null | type) == "array")' "$HOME_OPENCODE_JSON" &>/dev/null; then
    echo -e "  ${RED}✗${RESET} ~/opencode.json contains legacy MCP array syntax"
    echo -e "  ${CYAN}Fix:${RESET} mv ~/opencode.json ~/opencode.json.disabled-\$(date +%F)"
  else
    echo -e "  ${YELLOW}⚠${RESET} ~/opencode.json exists, but legacy MCP arrays were not detected; inspect manually"
  fi
fi
echo ""

# ── 3. Alias Targets ─────────────────────────────────────────────────────────
echo -e "${BLUE}── Alias Targets ─────────────────────────────────────${RESET}"
for alias_name in oc oc-fresh oc-clean oc-status; do
  # Parse alias from .zshrc directly (aliases not available in non-interactive shell)
  alias_line=$(grep -E "^alias $alias_name=" "$HOME/.zshrc" 2>/dev/null | head -1) || grep_pipe_ok
  if [[ -n "$alias_line" ]]; then
    # Extract the path from the alias line (handles both single and double quotes)
    target_path=$(echo "$alias_line" | grep -oE '/[^"]+' | head -1 | sed 's/"$//') || grep_pipe_ok
    if [[ -n "$target_path" && -f "$target_path" ]]; then
      echo -e "  ${GREEN}✓${RESET} $alias_name → $target_path"
    else
      echo -e "  ${YELLOW}⚠${RESET} $alias_name → ${target_path:-unknown} (file not found)"
    fi
  else
    echo -e "  ${RED}✗${RESET} $alias_name not defined in .zshrc"
  fi
done
echo ""

# ── 3. Prompt Sync State ─────────────────────────────────────────────────────
echo -e "${BLUE}── Prompt Sync State ─────────────────────────────────${RESET}"
SYNC_SCRIPT="$ROOT_DIR/.opencode/scripts/sync-opencode-runtime.sh"
if [[ -f "$SYNC_SCRIPT" ]]; then
  echo -e "  ${CYAN}Sync script:${RESET} present"
else
  echo -e "  ${RED}✗${RESET} Sync script missing"
fi

DRIFT=0
SYNC_NEEDED=0
for agent in architect budget explorer implementer planner reviewer; do
  canonical="$ROOT_DIR/.opencode/agents/${agent}.md"
  mirror="$ROOT_DIR/.opencode/global-runtime/prompts/${agent}.md"
  installed="$HOME/.config/opencode/prompts/${agent}.md"

  if [[ -f "$canonical" && -f "$mirror" && -f "$installed" ]]; then
    # Generated mirrors have a 6-line header added by sync-opencode-runtime.sh:
    #   # <Agent> Helper — Personal Projects Workspace
    #   (blank)
    #   > GENERATED FILE — DO NOT EDIT DIRECTLY.
    #   > Canonical source: .opencode/agents/<agent>.md
    #   > To regenerate: bash .opencode/scripts/sync-opencode-runtime.sh
    #   (blank)
    # Strip these 6 lines before comparing against canonical content.
    mirror_content=$(sed '1,6d' "$mirror")
    canonical_content=$(cat "$canonical")
    if [[ "$mirror_content" != "$canonical_content" ]]; then
      echo -e "  ${RED}✗${RESET} ${agent}.md: canonical ≠ mirror (content drift)"
      DRIFT=1
      SYNC_NEEDED=1
    elif ! diff -q "$mirror" "$installed" &>/dev/null; then
      echo -e "  ${YELLOW}⚠${RESET} ${agent}.md: mirror ≠ installed (runtime drift)"
      DRIFT=1
      SYNC_NEEDED=1
    else
      echo -e "  ${GREEN}✓${RESET} ${agent}.md: synced"
    fi
  else
    echo -e "  ${YELLOW}⚠${RESET} ${agent}.md: missing file(s)"
    DRIFT=1
  fi
done

# Check orchestrator
orch_canonical="$ROOT_DIR/.opencode/global-runtime/prompts/orchestrator.md"
orch_installed="$HOME/.config/opencode/prompts/orchestrator.md"
if [[ -f "$orch_canonical" && -f "$orch_installed" ]]; then
  if diff -q "$orch_canonical" "$orch_installed" &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} orchestrator.md: synced"
  else
    echo -e "  ${YELLOW}⚠${RESET} orchestrator.md: drift detected"
    DRIFT=1
  fi
else
  echo -e "  ${YELLOW}⚠${RESET} orchestrator.md: missing file(s)"
  DRIFT=1
fi

if [[ $DRIFT -eq 0 ]]; then
  echo -e "  ${GREEN}Overall: All prompts in sync${RESET}"
else
  echo -e "  ${YELLOW}Overall: Drift detected${RESET}"
  if [[ $SYNC_NEEDED -eq 1 ]]; then
    echo -e "  ${CYAN}Fix:${RESET} bash .opencode/scripts/sync-opencode-runtime.sh"
    echo -e "  ${CYAN}Verify:${RESET} bash .opencode/conformance/tests/global-opencode-runtime.sh"
    echo -e "  ${CYAN}Refresh:${RESET} oc-fresh"
  else
    echo -e "  ${CYAN}Fix:${RESET} Check missing files and run sync"
  fi
fi
echo ""

# ── 4. Conformance Summary ───────────────────────────────────────────────────
echo -e "${BLUE}── Conformance Summary ───────────────────────────────${RESET}"
CONFORMANCE_TEST="$ROOT_DIR/.opencode/conformance/tests/global-opencode-runtime.sh"
RESULTS_DIR="$ROOT_DIR/.opencode/conformance/results"

if [[ -d "$RESULTS_DIR" ]]; then
  LATEST_RESULT=$(find "$RESULTS_DIR" -name 'global-opencode-runtime-*.md' -type f 2>/dev/null | sort -r | head -1) || sigpipe_ok
  if [[ -n "$LATEST_RESULT" ]]; then
    LAST_RUN=$(basename "$LATEST_RESULT" | grep -oE '[0-9]{8}-[0-9]{6}' | head -1) || grep_pipe_ok
    PASS_COUNT=$(grep -iE 'passed: [0-9]+' "$LATEST_RESULT" 2>/dev/null | grep -oE '[0-9]+' || echo "?")
    FAIL_COUNT=$(grep -iE 'failed: [0-9]+' "$LATEST_RESULT" 2>/dev/null | grep -oE '[0-9]+' || echo "?")
    echo -e "  ${CYAN}Last run:${RESET} $LAST_RUN"
    echo -e "  ${GREEN}Passed:${RESET} $PASS_COUNT"
    echo -e "  ${RED}Failed:${RESET} $FAIL_COUNT"
  else
    echo -e "  ${YELLOW}⚠${RESET} No conformance results found"
  fi
else
  echo -e "  ${YELLOW}⚠${RESET} Results directory missing"
fi

if [[ $FULL_MODE -eq 1 ]]; then
  echo ""
  echo -e "  ${CYAN}Running full conformance suite (--full mode)...${RESET}"
  if [[ -f "$CONFORMANCE_TEST" ]]; then
    # Capture conformance output and exit code separately to avoid
    # SIGPIPE from tail masking real conformance failures
    set +e
    CONF_OUTPUT=$(bash "$CONFORMANCE_TEST" 2>&1)
    CONF_EXIT=$?
    set -e
    printf '%s\n' "$CONF_OUTPUT" | tail -10 || sigpipe_ok
    if [[ $CONF_EXIT -ne 0 ]]; then
      echo -e "  ${RED}✗${RESET} Conformance test reported failures (exit $CONF_EXIT)"
    fi
  else
    echo -e "  ${RED}✗${RESET} Conformance test not found"
  fi
fi
echo ""

# ── 5. Git Dirty Summary ─────────────────────────────────────────────────────
echo -e "${BLUE}── Workspace State ───────────────────────────────────${RESET}"
DIRTY_COUNT=$(git -C "$ROOT_DIR" status --short 2>/dev/null | wc -l | tr -d ' ')
if [[ "$DIRTY_COUNT" -gt 0 ]]; then
  echo -e "  ${YELLOW}⚠${RESET} $DIRTY_COUNT dirty file(s) in workspace"
  git -C "$ROOT_DIR" status --short 2>/dev/null | head -10 | sed 's/^/    /' || sigpipe_ok
  if [[ "$DIRTY_COUNT" -gt 10 ]]; then
    echo "    ... and $((DIRTY_COUNT - 10)) more"
  fi
else
  echo -e "  ${GREEN}✓${RESET} Workspace clean"
fi
echo ""

# ── 6. Legacy Agent Script Shim Status ───────────────────────────────────────
echo -e "${BLUE}── Legacy agent script shims ────────────────────────${RESET}"
echo -e "  ${CYAN}Canonical scripts:${RESET} .opencode/scripts/"
echo -e "  ${GREEN}✓${RESET} Legacy root-agent script shims are retired from daily-driver status checks"
echo -e "  ${CYAN}Detailed enforcement:${RESET} workspace protocol guard"
echo ""

# ── 7. Steward Observation Status ────────────────────────────────────────────
echo -e "${BLUE}── Steward Status ────────────────────────────────────${RESET}"
STEWARD_MARKER_DIR="$HOME/.config/steward"
TODAY=$(date +%F)
STEWARD_MARKER="$STEWARD_MARKER_DIR/autopilot-$TODAY"

if [[ -f "$STEWARD_MARKER" ]]; then
  echo -e "  ${YELLOW}⚠${RESET} Autopilot marker exists for today (disabled but marker present)"
else
  echo -e "  ${GREEN}✓${RESET} Autopilot disabled (no marker for today)"
fi

echo -e "  ${CYAN}Observation detail:${RESET} managed by workspace protocol guard"
echo ""

# ── 9. Provider/Model Summary ────────────────────────────────────────────────
echo -e "${BLUE}── Provider/Model Summary ────────────────────────────${RESET}"
OPENCODE_JSON="$ROOT_DIR/.opencode/opencode.json"
BRAIN_CONFIG="$ROOT_DIR/.opencode/brain-config.json"

if [[ -f "$OPENCODE_JSON" ]]; then
  DEFAULT_MODEL=$(jq -r '.model // "not set"' "$OPENCODE_JSON" 2>/dev/null || echo "parse error")
  SMALL_MODEL=$(jq -r '.small_model // "not set"' "$OPENCODE_JSON" 2>/dev/null || echo "parse error")
  echo -e "  ${CYAN}Default model:${RESET} $DEFAULT_MODEL"
  echo -e "  ${CYAN}Small model:${RESET} $SMALL_MODEL"
fi

if [[ -f "$BRAIN_CONFIG" ]]; then
  FALLBACK=$(jq -r '.provider_migration.rollback_provider // "not set"' "$BRAIN_CONFIG" 2>/dev/null || echo "parse error")
  echo -e "  ${CYAN}Fallback provider:${RESET} $FALLBACK"
fi
echo ""

# ── Footer ────────────────────────────────────────────────────────────────────
echo -e "${BLUE}═══════════════════════════════════════════════════════${RESET}"
echo -e "  ${CYAN}oc${RESET} = daily work  ${CYAN}oc-fresh${RESET} = resync  ${CYAN}oc-clean${RESET} = stuck sessions"
echo -e "${BLUE}═══════════════════════════════════════════════════════${RESET}"
