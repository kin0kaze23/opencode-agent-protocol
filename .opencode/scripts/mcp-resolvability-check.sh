#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$ROOT_DIR/.opencode/opencode.json"

section() { printf '\n== %s ==\n' "$1"; }
flag() { local label="$1"; shift; FAILED=1; printf '[FAIL] %s\n' "$label"; printf '%s\n' "$@"; }

PASS=0; FAILED=0

section "MCP Package Resolvability"

mcp_servers=$(jq -r '.mcp | keys[]' "$CONFIG_FILE" 2>/dev/null || echo "")

for server in $mcp_servers; do
  cmd_type=$(jq -r ".mcp.$server.type // empty" "$CONFIG_FILE" 2>/dev/null || echo "")

  if [[ "$cmd_type" == "local" ]]; then
    # Command format: ["npx", "-y", "package-name"]
    pkg_name=$(jq -r ".mcp.$server.command[2] // empty" "$CONFIG_FILE" 2>/dev/null || echo "")

    if [[ -n "$pkg_name" ]]; then
      if npm view "$pkg_name" name >/dev/null 2>&1; then
        echo "[PASS] $server: npm package '$pkg_name' exists"
        ((PASS++))
      else
        flag "$server: npm package '$pkg_name' does NOT exist on npm"
        ((FAILED++))
      fi
    else
      flag "$server: no package name found in command"
      ((FAILED++))
    fi
  elif [[ "$cmd_type" == "remote" ]]; then
    url=$(jq -r ".mcp.$server.url" "$CONFIG_FILE" 2>/dev/null || echo "")
    if [[ -n "$url" ]]; then
      echo "[PASS] $server: remote MCP at $url (no npm check needed)"
      ((PASS++))
    fi
  fi
done

section "Summary"
echo "=========================================="
printf '  PASSED: %d\n' "$PASS"
printf '  FAILED: %d\n' "$FAILED"
echo "=========================================="
[[ "$FAILED" -eq 0 ]] && echo "[PASS] MCP resolvability: all checks passed." || echo "[FAIL] MCP resolvability: $FAILED check(s) failed."
exit "$FAILED"
