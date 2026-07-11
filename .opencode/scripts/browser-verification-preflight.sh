#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OPENCODE_JSON="$ROOT_DIR/.opencode/opencode.json"

# --- MCP browser availability detection ---
# Checks whether Playwright MCP can actually launch a browser.
# MCP enabled alone is NOT sufficient — browser binaries or Chrome channel required.
detect_mcp_browser_availability() {
  local opencode_json="${1:-}"

  # Check 1: Chromium cache in global location
  if [[ -d "$HOME/Library/Caches/ms-playwright" ]]; then
    local global_cache="$HOME/Library/Caches/ms-playwright"
    if ls -d "$global_cache"/chromium-* 2>/dev/null | head -1 >/dev/null; then
      echo "chromium_cache:$global_cache"
      return 0
    fi
    if ls -d "$global_cache"/chromium_headless_shell-* 2>/dev/null | head -1 >/dev/null; then
      echo "chromium_cache:$global_cache"
      return 0
    fi
  fi

  # Check 2: Chromium cache in workspace root
  if [[ -d "$ROOT_DIR/node_modules/.cache/ms-playwright" ]]; then
    local root_cache="$ROOT_DIR/node_modules/.cache/ms-playwright"
    if ls -d "$root_cache"/chromium-* 2>/dev/null | head -1 >/dev/null; then
      echo "chromium_cache:$root_cache"
      return 0
    fi
  fi

  # Check 3: Chrome channel — MCP command explicitly requests Chrome and it exists locally
  if [[ -n "$opencode_json" && -f "$opencode_json" ]]; then
    local mcp_command
    mcp_command="$(jq -r '.mcp.playwright.command // [] | join(" ")' "$opencode_json" 2>/dev/null)"
    if echo "$mcp_command" | grep -qE '\-\-browser\s+chrome'; then
      if [[ -d "/Applications/Google Chrome.app" ]]; then
        echo "chrome_channel:/Applications/Google Chrome.app"
        return 0
      fi
    fi
  fi

  echo "no_browser"
  return 1
}

# --- Target repo resolution ---
TARGET_REPO="${1:-}"
TARGET_PATH=""

# If no explicit target, determine context
if [[ -z "$TARGET_REPO" ]]; then
  # Check if current directory is inside a repo (has AGENTS.md or NOW.md)
  check_dir="$PWD"
  while [[ "$check_dir" != "/" && "$check_dir" != "$ROOT_DIR" ]]; do
    if [[ -f "$check_dir/AGENTS.md" || -f "$check_dir/NOW.md" ]]; then
      TARGET_PATH="$check_dir"
      TARGET_REPO="$(basename "$check_dir")"
      break
    fi
    check_dir="$(dirname "$check_dir")"
  done
fi

# If explicit target was given, resolve it
if [[ -n "$TARGET_REPO" && -z "$TARGET_PATH" ]]; then
  if [[ -d "$ROOT_DIR/$TARGET_REPO" ]]; then
    TARGET_PATH="$ROOT_DIR/$TARGET_REPO"
  elif [[ -d "$TARGET_REPO" ]]; then
    TARGET_PATH="$TARGET_REPO"
    TARGET_REPO="$(basename "$TARGET_REPO")"
  fi
fi

printf 'Browser verification preflight\n'
printf 'Root: %s\n' "$ROOT_DIR"
if [[ -n "$TARGET_REPO" && -n "$TARGET_PATH" ]]; then
  printf 'Target repo: %s (%s)\n' "$TARGET_REPO" "$TARGET_PATH"
else
  printf 'Target repo: none (workspace root — discovery mode)\n'
fi

# --- Playwright MCP check ---
playwright_mcp_enabled="unknown"
mcp_browser_state="unknown"
mcp_browser_detail=""
mcp_disabled_reason=""
if [[ -f "$OPENCODE_JSON" ]]; then
  playwright_mcp_enabled="$(jq -r '.mcp.playwright.enabled // false' "$OPENCODE_JSON")"
fi
printf 'Playwright MCP: %s\n' "$playwright_mcp_enabled"

# --- MCP browser availability (only check if MCP is enabled) ---
if [[ "$playwright_mcp_enabled" == "true" ]]; then
  set +e
  mcp_browser_result="$(detect_mcp_browser_availability "$OPENCODE_JSON" 2>/dev/null)" || true
  set -e
  if [[ "$mcp_browser_result" == no_browser ]]; then
    mcp_browser_state="missing"
    mcp_disabled_reason="playwright_mcp_enabled_but_browser_missing"
  elif [[ "$mcp_browser_result" == chromium_cache:* ]]; then
    mcp_browser_state="installed"
    mcp_browser_detail="${mcp_browser_result#*:}"
  elif [[ "$mcp_browser_result" == chrome_channel:* ]]; then
    mcp_browser_state="chrome_channel"
    mcp_browser_detail="${mcp_browser_result#*:}"
  fi
elif [[ "$playwright_mcp_enabled" == "false" ]]; then
  mcp_browser_state="not_checked"
  mcp_disabled_reason="playwright_mcp_disabled"
fi
printf 'MCP browser: %s\n' "$mcp_browser_state"
if [[ -n "$mcp_browser_detail" ]]; then
  printf 'MCP browser detail: %s\n' "$mcp_browser_detail"
fi
if [[ -n "$mcp_disabled_reason" ]]; then
  printf 'MCP disabled reason: %s\n' "$mcp_disabled_reason"
fi

# --- Repo-local Node Playwright detection ---
node_pw_state="not_detected"
node_pw_detail=""
node_pw_browser_state="unknown"
node_pw_target=""

detect_repo_playwright() {
  local check_dir="${1:-.}"

  # Require a Playwright config in the target repo — CLI alone is not enough
  if [[ ! -f "$check_dir/playwright.config.ts" && ! -f "$check_dir/playwright.config.js" ]]; then
    echo "no_config"
    return 1
  fi

  local pw_cli=""

  if command -v pnpm >/dev/null 2>&1; then
    set +e
    pw_cli="$(cd "$check_dir" && pnpm exec playwright --version 2>&1)"
    local pw_exit=$?
    set -e
    if [[ "$pw_exit" -eq 0 && "$pw_cli" == *"Version"* ]]; then
      echo "pnpm:$pw_cli"
      return 0
    fi
  fi

  if command -v npx >/dev/null 2>&1; then
    set +e
    pw_cli="$(cd "$check_dir" && npx playwright --version 2>&1)"
    local pw_exit=$?
    set -e
    if [[ "$pw_exit" -eq 0 && "$pw_cli" == *"Version"* ]]; then
      echo "npx:$pw_cli"
      return 0
    fi
  fi

  echo "not_found"
  return 1
}

detect_repo_playwright_browser() {
  local check_dir="${1:-.}"
  if [[ -d "$check_dir/node_modules/.cache/ms-playwright" ]]; then
    local cache_dir="$check_dir/node_modules/.cache/ms-playwright"
    if ls -d "$cache_dir"/chromium-* 2>/dev/null | head -1 >/dev/null; then
      echo "installed:$cache_dir"
      return 0
    fi
  fi
  if [[ -d "$HOME/Library/Caches/ms-playwright" ]]; then
    local global_cache="$HOME/Library/Caches/ms-playwright"
    if ls -d "$global_cache"/chromium-* 2>/dev/null | head -1 >/dev/null; then
      echo "installed:$global_cache"
      return 0
    fi
    if ls -d "$global_cache"/chromium_headless_shell-* 2>/dev/null | head -1 >/dev/null; then
      echo "installed:$global_cache"
      return 0
    fi
  fi
  echo "not_installed"
  return 1
}

# Detection strategy: target repo first, then workspace discovery
if [[ -n "$TARGET_PATH" ]]; then
  # Target-repo mode: check the specific repo
  set +e
  pw_result="$(detect_repo_playwright "$TARGET_PATH" 2>/dev/null)" || true
  set -e

  if [[ "$pw_result" != "not_found" && "$pw_result" != "no_config" ]]; then
    pw_tool="${pw_result%%:*}"
    pw_version="${pw_result#*:}"
    node_pw_state="detected"
    node_pw_detail="$pw_tool ($pw_version)"
    node_pw_target="$TARGET_PATH"

    set +e
    browser_result="$(detect_repo_playwright_browser "$TARGET_PATH" 2>/dev/null)" || true
    if [[ "$browser_result" == "not_installed" ]]; then
      set +e
      browser_result="$(detect_repo_playwright_browser "$ROOT_DIR" 2>/dev/null)" || true
      set -e
    else
      set -e
    fi

    if [[ "$browser_result" == installed:* ]]; then
      node_pw_browser_state="installed"
    else
      node_pw_browser_state="missing"
    fi
  fi
else
  # Discovery mode: scan repos and report what's found
  discovered_repos=()
  set +e
  for repo_dir in "$ROOT_DIR"/*/; do
    if [[ -f "$repo_dir/playwright.config.ts" || -f "$repo_dir/playwright.config.js" ]]; then
      pw_result="$(detect_repo_playwright "$repo_dir" 2>/dev/null)" || true
  if [[ "$pw_result" != "not_found" && "$pw_result" != "no_config" ]]; then
        pw_tool="${pw_result%%:*}"
        pw_version="${pw_result#*:}"
        repo_name="$(basename "$repo_dir")"

        set +e
        browser_result="$(detect_repo_playwright_browser "$repo_dir" 2>/dev/null)" || true
        if [[ "$browser_result" == "not_installed" ]]; then
          set +e
          browser_result="$(detect_repo_playwright_browser "$ROOT_DIR" 2>/dev/null)" || true
          set -e
        else
          set -e
        fi

        if [[ "$browser_result" == installed:* ]]; then
          discovered_repos+=("$repo_name")
          # Use first discovered repo as the selected target
          if [[ "$node_pw_state" == "not_detected" ]]; then
            node_pw_state="detected"
            node_pw_detail="$pw_tool ($pw_version)"
            node_pw_target="$repo_dir"
            node_pw_browser_state="installed"
          fi
        fi
      fi
    fi
  done
  set -e

  if [[ ${#discovered_repos[@]} -gt 0 ]]; then
    printf 'Discovered Playwright-capable repos: %s\n' "$(IFS=', '; echo "${discovered_repos[*]}")"
    printf 'Note: workspace-root preflight discovers capable repos; run from target repo or pass repo name for target-repo mode.\n'
  fi
fi

printf 'Repo-local Playwright: %s\n' "$node_pw_state"
if [[ -n "$node_pw_detail" ]]; then
  printf 'Repo-local Playwright detail: %s\n' "$node_pw_detail"
fi
if [[ -n "$node_pw_target" ]]; then
  printf 'Repo-local Playwright target: %s\n' "$node_pw_target"
fi
printf 'Repo-local Playwright browser: %s\n' "$node_pw_browser_state"

# --- Python Playwright fallback ---
python_state="unavailable"
browser_state="unknown"
python_detail=""
if command -v python3 >/dev/null 2>&1; then
  set +e
  python_output="$(python3 - <<'PY' 2>&1
try:
    from playwright.sync_api import sync_playwright
except Exception as exc:
    print(f"import_error: {exc}")
    raise SystemExit(2)

try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        browser.close()
    print("usable")
except Exception as exc:
    print(f"launch_error: {exc}")
    raise SystemExit(3)
PY
)"
  python_exit=$?
  set -e
  if [[ "$python_exit" -eq 0 ]]; then
    python_state="usable"
    browser_state="installed"
  elif [[ "$python_output" == import_error:* ]]; then
    python_state="missing_playwright_package"
    browser_state="unknown"
    python_detail="$python_output"
  elif [[ "$python_output" == launch_error:* ]]; then
    python_state="playwright_launch_failed"
    browser_state="missing_or_mismatched"
    python_detail="$python_output"
  else
    python_state="unknown_failure"
    browser_state="unknown"
    python_detail="$python_output"
  fi
else
  python_detail="python3 command not found"
fi
printf 'Python Playwright: %s\n' "$python_state"
printf 'Browser binary (Python): %s\n' "$browser_state"
if [[ -n "$python_detail" ]]; then
  printf 'Python detail: %s\n' "$python_detail"
fi

# --- agent-browser fallback ---
agent_browser_state="not_configured_or_unavailable"
agent_browser_detail=""
if command -v agent-browser >/dev/null 2>&1; then
  set +e
  agent_browser_output="$(agent-browser --version 2>&1)"
  agent_browser_exit=$?
  set -e
  if [[ "$agent_browser_exit" -eq 0 ]]; then
    agent_browser_state="available"
    agent_browser_detail="$agent_browser_output"
  else
    agent_browser_state="unavailable"
    agent_browser_detail="$agent_browser_output"
  fi
fi
printf 'agent-browser: %s\n' "$agent_browser_state"
if [[ -n "$agent_browser_detail" ]]; then
  printf 'agent-browser detail: %s\n' "$agent_browser_detail"
fi

# --- Route selection (priority order) ---
# MCP requires BOTH enabled flag AND browser availability to be usable.
selected_route="NOT_RUN"
selected_target=""
selected_detail=""
if [[ "$playwright_mcp_enabled" == "true" ]]; then
  if [[ "$mcp_browser_state" == "installed" || "$mcp_browser_state" == "chrome_channel" ]]; then
    selected_route="Playwright MCP"
    selected_target=""
  else
    # MCP enabled but browser not available — NOT_RUN, not PASS
    selected_route="NOT_RUN"
    selected_detail="playwright_mcp_enabled_but_browser_missing"
  fi
elif [[ "$node_pw_state" == "detected" && "$node_pw_browser_state" == "installed" ]]; then
  selected_route="Playwright CLI/runtime"
  selected_target="$node_pw_target"
elif [[ "$python_state" == "usable" ]]; then
  selected_route="Python Playwright"
elif [[ "$agent_browser_state" == "available" ]]; then
  selected_route="agent-browser"
fi
printf 'Selected route: %s\n' "$selected_route"
if [[ -n "$selected_target" ]]; then
  printf 'Selected target: %s\n' "$selected_target"
fi
if [[ -n "$selected_detail" ]]; then
  printf 'Selected detail: %s\n' "$selected_detail"
fi

if [[ "$selected_route" == "NOT_RUN" ]]; then
  if [[ -n "$selected_detail" ]]; then
    printf 'Result: NOT_RUN — %s; do not install or enable dependencies without owner approval.\n' "$selected_detail"
  else
    printf 'Result: NOT_RUN — no usable browser route detected; do not install or enable dependencies without owner approval.\n'
  fi
else
  printf 'Result: PASS — browser route preflight selected %s.\n' "$selected_route"
fi
