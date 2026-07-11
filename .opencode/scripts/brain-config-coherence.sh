#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$ROOT_DIR/.opencode/brain-config.json"
NOW_MD="$ROOT_DIR/vault/protocols/opencode/NOW.md"
ROOT_NOW_MD="$ROOT_DIR/NOW.md"
REGISTRY="$ROOT_DIR/.opencode/skills/registry.md"

section() { printf '\n== %s ==\n' "$1"; }
flag() { local label="$1"; shift; FAILED=$((FAILED + 1)); printf '[FAIL] %s\n' "$label"; printf '%s\n' "$@"; }

PASS=0; FAILED=0

# Note: use PASS=$((PASS + 1)) instead of PASS=$((PASS + 1)) to avoid set -e exit when PASS=0

section "Brain-Config Version Coherence"
# v4.28.1: Fall back to root NOW.md if vault is not available (CI environment)
if [[ -f "$NOW_MD" ]]; then
  protocol_version=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+\.[0-9]+)?' "$NOW_MD" 2>/dev/null | head -1 || echo "unknown")
elif [[ -f "$ROOT_NOW_MD" ]]; then
  protocol_version=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+\.[0-9]+)?' "$ROOT_NOW_MD" 2>/dev/null | head -1 || echo "unknown")
else
  protocol_version="unknown"
fi
config_version=$(jq -r '.version' "$CONFIG_FILE" 2>/dev/null || echo "unknown")
if [[ "$config_version" == "$protocol_version" ]]; then
  echo "[PASS] brain-config.json version ($config_version) matches protocol ($protocol_version)"
  PASS=$((PASS + 1))
else
  flag "brain-config.json version ($config_version) does not match protocol ($protocol_version)"
  FAILED=$((FAILED + 1))
fi

section "Command Surface Coherence"
config_cmds=$(jq -r '.command_surface.commands[]' "$CONFIG_FILE" 2>/dev/null | sed 's|^/||' | sort)
actual_cmds=$(cd "$ROOT_DIR/.opencode/commands" && ls *.md 2>/dev/null | sed 's|\.md$||' | sort)
if [[ "$config_cmds" == "$actual_cmds" ]]; then
  echo "[PASS] command_surface.commands matches .opencode/commands/*.md exactly ($(echo "$config_cmds" | wc -l | tr -d ' ') commands)"
  PASS=$((PASS + 1))
else
  flag "command_surface.commands does not match actual .md files"
  FAILED=$((FAILED + 1))
fi

section "Skill Manual Load Coherence"
# Read Tier-1 skills from registry.md (single source of truth)
registry_tier1=$(sed -n '/^## Tier 1:/,/^## Tier 2:/p' "$REGISTRY" | grep '^| ' | grep -v 'Skill\|---' | awk '{print $2}')
missing=""
count=0
for skill in $registry_tier1; do
  skill_file="${skill}/SKILL.md"
  found=$(jq -r ".skills.manual_load_for | keys[]" "$CONFIG_FILE" 2>/dev/null | grep -Fx "$skill_file" || true)
  if [[ -z "$found" ]]; then
    missing+="  $skill_file"$'\n'
  fi
  count=$((count + 1))
done
if [[ -z "$missing" ]]; then
  echo "[PASS] manual_load_for contains all $count Tier-1 skills (from registry.md)"
  PASS=$((PASS + 1))
else
  flag "manual_load_for missing Tier-1 skills ($count expected)" "$missing"
  FAILED=$((FAILED + 1))
fi

section "Bootstrap Policy Coherence"
bootstrap=$(jq -r '.command_surface.bootstrap_policy' "$CONFIG_FILE" 2>/dev/null || echo "unknown")
if [[ "$bootstrap" == *"native"* ]] || [[ "$bootstrap" == *"minimal"* ]]; then
  echo "[PASS] bootstrap_policy aligns with v4.5 native-alignment"
  PASS=$((PASS + 1))
else
  flag "bootstrap_policy does not align with v4.5 native-alignment" "$bootstrap"
  FAILED=$((FAILED + 1))
fi

section "Required Fields Presence"
for field in "skills.skill_loading_policy" "mcp_servers"; do
  val=$(jq -r ".$field" "$CONFIG_FILE" 2>/dev/null || echo "null")
  if [[ "$val" == "null" || -z "$val" ]]; then
    flag "Required field '$field' is missing or null"
    FAILED=$((FAILED + 1))
  else
    echo "[PASS] Required field '$field' exists"
    PASS=$((PASS + 1))
  fi
done

section "Summary"
echo "=========================================="
printf '  PASSED: %d\n' "$PASS"
printf '  FAILED: %d\n' "$FAILED"
echo "=========================================="
[[ "$FAILED" -eq 0 ]] && echo "[PASS] Brain-config coherence: all checks passed." || echo "[FAIL] Brain-config coherence: $FAILED check(s) failed."
exit "$FAILED"
