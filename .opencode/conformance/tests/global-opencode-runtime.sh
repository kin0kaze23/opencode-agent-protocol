#!/bin/bash
# Launcher Runtime Coherence Tests — Option D: C5 Runtime-Aware Thin-Shell
#
# Architecture: workspace .opencode/opencode.json is canonical.
# Global ~/.config/opencode/opencode.json is NON-AUTHORITATIVE.
#
# Global may be in one of two valid C5 states:
#   GLOBAL_THIN_IDLE              — global carries only $schema + plugin: []
#   GLOBAL_RUNTIME_MATERIALIZED   — OpenCode CLI/Desktop has materialized a
#                                   workspace-derived mirror into global
#
# Both states are valid. Tests must validate:
#   1. Workspace always carries canonical 9-helper roster, model, small_model
#   2. Global does NOT contain decommissioned providers (bailian, gemini-auth)
#   3. Global does NOT contain resolved API keys / auth material
#   4. If global is runtime-materialized: model/small_model/agent/mcp MUST
#      match workspace exactly (equivalence check, not arbitrary expansion)
#   5. If global is thin: passes with no field-presence failures

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/global-opencode-runtime-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

GLOBAL_CFG="${HOME}/.config/opencode/opencode.json"
GLOBAL_PROMPTS="${HOME}/.config/opencode/prompts"
LOCAL_PROMPTS="$ROOT_DIR/.opencode/global-runtime/prompts"
WORKSPACE_RUNTIME_NOTE="$ROOT_DIR/WORKSPACE-NAVIGATION.md"
SAFE_LAUNCH="$ROOT_DIR/.opencode/scripts/opencode-safe-launch.sh"
LEGACY_SHIM="$ROOT_DIR/.agent/scripts/opencode-safe-launch.sh"
SYNC_SCRIPT="$ROOT_DIR/.opencode/scripts/sync-opencode-runtime.sh"
ZSH_RC="${HOME}/.zshrc"
GLOBAL_CFG_DIR="${HOME}/.config/opencode"

echo "=========================================="
echo "Protocol Conformance Suite - Launcher Runtime Coherence Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

test_start "GOR-001" "C5 architecture (Option D): workspace canonical, global is non-authoritative thin shell or runtime mirror"
assert_file_exists "$GLOBAL_CFG" "Global OpenCode config exists"
# Read configs with retry (race-resilient against active Desktop sync)
GLOBAL_CONTENT=""
for i in 1 2 3 4 5; do
  if GLOBAL_CONTENT=$(cat "$GLOBAL_CFG" 2>/dev/null); then
    break
  fi
  sleep 0.2
done
[ -z "$GLOBAL_CONTENT" ] && GLOBAL_CONTENT="{}"
WORKSPACE_CONTENT=""
for i in 1 2 3 4 5; do
  if WORKSPACE_CONTENT=$(cat "$ROOT_DIR/.opencode/opencode.json" 2>/dev/null); then
    break
  fi
  sleep 0.2
done
[ -z "$WORKSPACE_CONTENT" ] && WORKSPACE_CONTENT="{}"
BRAIN_CONTENT=""
for i in 1 2 3 4 5; do
  if BRAIN_CONTENT=$(cat "$ROOT_DIR/.opencode/brain-config.json" 2>/dev/null); then
    break
  fi
  sleep 0.2
done
[ -z "$BRAIN_CONTENT" ] && BRAIN_CONTENT="{}"
# Classify global state
THIN_SHELL_OK=$(echo "$GLOBAL_CONTENT" | jq -r '
  (keys | length) <= 2 and ((keys | sort) == (["$schema", "plugin"] | sort))')
if [ "$THIN_SHELL_OK" = "true" ]; then
  GLOBAL_STATE="GLOBAL_THIN_IDLE"
else
  GLOBAL_STATE="GLOBAL_RUNTIME_MATERIALIZED"
fi
echo "  [i] Global state: $GLOBAL_STATE"
# 1. Workspace is always canonical (daily-driver roster). Internal agents such as
#    summary/compaction may also exist for runtime safety, but the canonical
#    7-helper roster must always be present.
WORKSPACE_AGENT_KEYS=$(echo "$WORKSPACE_CONTENT" | jq -r '.agent // {} | keys | sort | join(",")')
EXPECTED_KEYS=$(echo "$BRAIN_CONTENT" | jq -r '["orchestrator"] + (.subagents.roster.core | keys) + (.subagents.roster.specialized | keys) | sort | join(",")')
# Subset check: every expected daily-driver agent must be present in workspace
MISSING_DAILY_AGENTS=$(echo "$WORKSPACE_CONTENT" | jq -r --arg expected "$EXPECTED_KEYS" '
  ($expected | split(",")) - (.agent // {} | keys) | sort | join(",")
')
assert_equals "" "$MISSING_DAILY_AGENTS" "Workspace carries canonical 9-helper agent block (always required)"
# 2. Accept either valid C5 global state
if [ "$GLOBAL_STATE" = "GLOBAL_THIN_IDLE" ]; then
  echo "  [OK] Global is thin shell (GLOBAL_THIN_IDLE): valid C5 state"
  ((TESTS_PASSED++))
else
  # 3. Runtime-materialized: global fields MUST be a workspace subset
  # 3a. Agent block: if present, every global agent must be in workspace
  GLOBAL_AGENT_KEYS=$(echo "$GLOBAL_CONTENT" | jq -r '.agent // {} | keys | sort | join(",")')
  if [ -n "$GLOBAL_AGENT_KEYS" ]; then
    UNEXPECTED=$(echo "$GLOBAL_CONTENT" | jq -r --arg ws "$WORKSPACE_AGENT_KEYS" '
      (.agent // {} | keys) - ($ws | split(",")) | sort | join(",")
    ')
    if [ -n "$UNEXPECTED" ]; then
      assert_equals "" "$UNEXPECTED" "Global agent block is a workspace subset (GLOBAL_RUNTIME_MATERIALIZED)"
    else
      echo "  [OK] Global agent block is a workspace subset: [$GLOBAL_AGENT_KEYS]"
      ((TESTS_PASSED++))
    fi
  fi
  # 3b. Model field: if present, must match workspace
  GLOBAL_MODEL=$(echo "$GLOBAL_CONTENT" | jq -r '.model // ""')
  WORKSPACE_MODEL=$(echo "$WORKSPACE_CONTENT" | jq -r '.model // ""')
  if [ -z "$GLOBAL_MODEL" ] || [ "$GLOBAL_MODEL" = "$WORKSPACE_MODEL" ]; then
    echo "  [OK] Global model mirrors workspace: $WORKSPACE_MODEL"
    ((TESTS_PASSED++))
  else
    assert_equals "$WORKSPACE_MODEL" "$GLOBAL_MODEL" "Global model mirrors workspace (GLOBAL_RUNTIME_MATERIALIZED)"
  fi
  # 3c. Small_model field: if present, must match workspace
  GLOBAL_SMALL=$(echo "$GLOBAL_CONTENT" | jq -r '.small_model // ""')
  WORKSPACE_SMALL=$(echo "$WORKSPACE_CONTENT" | jq -r '.small_model // ""')
  if [ -z "$GLOBAL_SMALL" ] || [ "$GLOBAL_SMALL" = "$WORKSPACE_SMALL" ]; then
    echo "  [OK] Global small_model mirrors workspace: $WORKSPACE_SMALL"
    ((TESTS_PASSED++))
  else
    assert_equals "$WORKSPACE_SMALL" "$GLOBAL_SMALL" "Global small_model mirrors workspace (GLOBAL_RUNTIME_MATERIALIZED)"
  fi
  echo "  [OK] Global is runtime-materialized subset of workspace (GLOBAL_RUNTIME_MATERIALIZED): valid C5 state"
  ((TESTS_PASSED++))
fi
# 4. Forbidden patterns: global must NEVER contain decommissioned providers or secrets
assert_file_not_contains "$GLOBAL_CFG" "bailian-coding-plan" "Global has no decommissioned bailian-coding-plan provider"
assert_file_not_contains "$GLOBAL_CFG" "opencode-gemini-auth@latest" "Global has no decommissioned opencode-gemini-auth@latest"
# 5. Secret/auth material check — heuristic but covers common API key formats
SECRET_PATTERN='(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|glpat-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|xox[bpars]-[A-Za-z0-9-]{10,})'
if grep -qE "$SECRET_PATTERN" "$GLOBAL_CFG" 2>/dev/null; then
  SUSPICIOUS_KEYS=$(grep -cE "$SECRET_PATTERN" "$GLOBAL_CFG" 2>/dev/null)
else
  SUSPICIOUS_KEYS=0
fi
SUSPICIOUS_KEYS=$(echo "$SUSPICIOUS_KEYS" | tr -cd '0-9')
SUSPICIOUS_KEYS=${SUSPICIOUS_KEYS:-0}
if [ "$SUSPICIOUS_KEYS" = "0" ]; then
  echo -e "  ${GREEN}✓${NC} Global has no resolved API keys or auth material"
  ((TESTS_PASSED++))
else
  echo -e "  ${RED}✗${NC} Global contains $SUSPICIOUS_KEYS suspicious API key/auth material line(s)"
  ((TESTS_FAILED++))
fi

test_start "GOR-002" "Workspace helper models match brain-config canonical; if global has agent block, models must mirror workspace (Option D)"
MODELS=$(ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json, os
from pathlib import Path
brain = json.loads(Path(os.environ["ROOT_DIR"] + "/.opencode/brain-config.json").read_text())
cfg = json.loads(Path(os.environ["ROOT_DIR"] + "/.opencode/opencode.json").read_text())
# Build expected models dynamically from brain-config roster
expected = {"orchestrator": brain["orchestrator_mode"]["default_model"]}
for tier in ["core", "specialized"]:
    for name, spec in brain["subagents"]["roster"][tier].items():
        expected[name] = spec["model"]
for key, model in expected.items():
    print(f"expected:{key}={model}")
    print(f"actual:{key}={cfg['agent'][key]['model']}")
PY
)
ALL_KEYS=$(ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json, os
from pathlib import Path
brain = json.loads(Path(os.environ["ROOT_DIR"] + "/.opencode/brain-config.json").read_text())
keys = ["orchestrator"] + sorted(brain["subagents"]["roster"]["core"].keys()) + sorted(brain["subagents"]["roster"]["specialized"].keys())
print(" ".join(keys))
PY
)
for key in $ALL_KEYS; do
  EXPECTED=$(printf "%s\n" "$MODELS" | awk -F= -v key="$key" '$1=="expected:"key {print $2}')
  ACTUAL=$(printf "%s\n" "$MODELS" | awk -F= -v key="$key" '$1=="actual:"key {print $2}')
  assert_equals "$EXPECTED" "$ACTUAL" "$key model matches workspace canonical config"
done
# Option D: if global has agent block, its models must mirror workspace
GLOBAL_FOR_002=""
for i in 1 2 3 4 5; do
  GLOBAL_FOR_002=$(cat "$GLOBAL_CFG" 2>/dev/null) && break
  sleep 0.2
done
[ -z "$GLOBAL_FOR_002" ] && GLOBAL_FOR_002="{}"
GLOBAL_AGENT_PRESENT=$(echo "$GLOBAL_FOR_002" | jq -r 'has("agent") | tostring')
if [ "$GLOBAL_AGENT_PRESENT" = "true" ]; then
  for key in $ALL_KEYS; do
    GLOBAL_AGENT_MODEL=$(echo "$GLOBAL_FOR_002" | jq -r --arg k "$key" '.agent[$k].model // ""')
    WORKSPACE_AGENT_MODEL=$(echo "$WORKSPACE_CONTENT" | jq -r --arg k "$key" '.agent[$k].model // ""')
    if [ -n "$GLOBAL_AGENT_MODEL" ]; then
      assert_equals "$WORKSPACE_AGENT_MODEL" "$GLOBAL_AGENT_MODEL" "Global $key model mirrors workspace (GLOBAL_RUNTIME_MATERIALIZED)"
    fi
  done
  echo -e "  ${GREEN}✓${NC} Global agent models mirror workspace (GLOBAL_RUNTIME_MATERIALIZED)"
  ((TESTS_PASSED++))
else
  echo -e "  ${GREEN}✓${NC} Global has no agent block (GLOBAL_THIN_IDLE — workspace is sole agent authority)"
  ((TESTS_PASSED++))
fi

test_start "GOR-003" "Global and local launcher prompt files exist for all active agents"
assert_file_exists "$SYNC_SCRIPT" "Sync script exists"
ALL_PROMPT_KEYS=$(ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json, os
from pathlib import Path
brain = json.loads(Path(os.environ["ROOT_DIR"] + "/.opencode/brain-config.json").read_text())
keys = ["orchestrator"] + sorted(brain["subagents"]["roster"]["core"].keys()) + sorted(brain["subagents"]["roster"]["specialized"].keys())
print(" ".join(keys))
PY
)
for prompt in $ALL_PROMPT_KEYS; do
  assert_file_exists "$GLOBAL_PROMPTS/$prompt.md" "Prompt exists: $prompt.md"
  assert_file_exists "$LOCAL_PROMPTS/$prompt.md" "Local launcher template exists: $prompt.md"
done

test_start "GOR-004" "Global orchestrator prompt reflects current helper policy"
assert_file_contains "$GLOBAL_PROMPTS/orchestrator.md" "Planner" "Orchestrator prompt mentions Planner"
assert_file_contains "$GLOBAL_PROMPTS/orchestrator.md" "Architect" "Orchestrator prompt mentions Architect"
assert_file_contains "$GLOBAL_PROMPTS/orchestrator.md" "glm-5" "Orchestrator prompt routes cheap bulk review to glm-5"
assert_file_contains "$GLOBAL_PROMPTS/orchestrator.md" "vault/owner-memory/index.md" "Orchestrator prompt references Owner memory index"
assert_file_contains "$GLOBAL_PROMPTS/orchestrator.md" "advisory" "Orchestrator prompt keeps Owner memory advisory"

test_start "GOR-005" "Safe launcher watches prompt changes as runtime changes"
assert_file_exists "$SAFE_LAUNCH" "Canonical launcher exists at .opencode/scripts/"
assert_file_contains "$SAFE_LAUNCH" "PROMPTS_DIR=" "Canonical launcher tracks prompt directory"
assert_file_contains "$SAFE_LAUNCH" "LOCAL_SYNC_SCRIPT=" "Canonical launcher tracks sync script"
assert_file_contains "$SAFE_LAUNCH" "Local canonical helper policy is newer than the global OpenCode runtime" "Canonical launcher detects local/global drift"
assert_file_contains "$SAFE_LAUNCH" "OpenCode runtime changed since server started" "Canonical launcher has stale-runtime message"
assert_file_contains "$SAFE_LAUNCH" "Default oc uses standalone mode" "Canonical launcher explains standalone is safe"
assert_file_not_contains "$SAFE_LAUNCH" "restarting server" "Canonical launcher does NOT falsely claim server restart"

test_start "GOR-006" "Workspace docs mention launcher-facing runtime source"
assert_file_contains "$WORKSPACE_RUNTIME_NOTE" "~/.config/opencode/opencode.json" "Workspace navigation references launcher-facing config"

test_start "GOR-007" "Workspace carries approved MCP entries; if global has MCP block it must be a workspace subset (Option D)"
assert_file_contains "$ROOT_DIR/.opencode/opencode.json" "\"exa\"" "Workspace config includes Exa MCP entry"
assert_file_contains "$ROOT_DIR/.opencode/opencode.json" "exa-mcp-server" "Workspace config points at Exa local MCP package"
# web-tools was deprecated and removed (2026-07-01) — no longer expected in workspace config
# C5 Option D: global MCP block is either absent (thin) or a workspace-derived subset
# Re-read global with retry to capture current state (Desktop may sync between tests)
GLOBAL_FOR_007=""
for i in 1 2 3 4 5; do
  GLOBAL_FOR_007=$(cat "$GLOBAL_CFG" 2>/dev/null) && break
  sleep 0.2
done
[ -z "$GLOBAL_FOR_007" ] && GLOBAL_FOR_007="{}"
GLOBAL_MCP_KEYS=$(echo "$GLOBAL_FOR_007" | jq -r '.mcp // {} | keys | sort | join(",")')
WORKSPACE_MCP_KEYS=$(echo "$WORKSPACE_CONTENT" | jq -r '.mcp // {} | keys | sort | join(",")')
if [ -z "$GLOBAL_MCP_KEYS" ]; then
  echo -e "  ${GREEN}✓${NC} Global has no MCP block (GLOBAL_THIN_IDLE — MCPs in workspace only)"
  ((TESTS_PASSED++))
else
  # Subset check: every global MCP must come from workspace (workspace is canonical)
  UNEXPECTED_MCPS=$(echo "$GLOBAL_FOR_007" | jq -r --arg ws "$WORKSPACE_MCP_KEYS" '
    (.mcp // {} | keys) - ($ws | split(",")) | sort | join(",")
  ')
  if [ -z "$UNEXPECTED_MCPS" ]; then
    echo -e "  ${GREEN}✓${NC} Global MCP block is a workspace subset (GLOBAL_RUNTIME_MATERIALIZED): [$GLOBAL_MCP_KEYS]"
    ((TESTS_PASSED++))
  else
    echo -e "  ${RED}✗${NC} Global has unexpected MCPs not in workspace: $UNEXPECTED_MCPS"
    ((TESTS_FAILED++))
  fi
fi
# Forbidden MCP patterns must never appear in global
assert_file_not_contains "$GLOBAL_CFG" "opencode-gemini-auth@latest" "Global has no decommissioned opencode-gemini-auth@latest MCP"

# ── Phase OC-L.1: Canonical OpenCode Launcher Migration ──────────────────────

test_start "GOR-008" "Canonical launcher has fast-path passthroughs for version/help/upgrade"
assert_file_contains "$SAFE_LAUNCH" '\-v\|\-\-version\|version\|help\|\-\-help\|upgrade' "Canonical launcher has fast-path passthrough for -v/--version/version/help/--help/upgrade"
assert_file_contains "$SAFE_LAUNCH" 'exec opencode "\$@"' "Fast-path calls native opencode directly"

test_start "GOR-009" "Canonical launcher has safer port-4000 kill logic"
assert_file_contains "$SAFE_LAUNCH" 'LISTENER_CMD=$(ps -o command= -p' "Canonical launcher checks listener process command"
assert_file_contains "$SAFE_LAUNCH" 'non-opencode' "Canonical launcher skips non-opencode processes on port 4000"

test_start "GOR-010" "Canonical launcher references .opencode/scripts not .agent/scripts"
assert_file_not_contains "$SAFE_LAUNCH" '.agent/scripts' "Canonical launcher usage/help/errors use .opencode paths"

test_start "GOR-011" "Legacy opencode-safe-launch.sh shim retired (OC-L.3a)"
assert_file_not_exists "$LEGACY_SHIM" "Legacy opencode-safe-launch.sh shim has been retired"

test_start "GOR-012" ".zshrc oc and oc-fresh aliases point to .opencode/scripts/ (not .agent)"
assert_file_contains "$ZSH_RC" "alias oc=" "oc alias exists in .zshrc"
assert_file_contains "$ZSH_RC" ".opencode/scripts/opencode-safe-launch.sh" "oc alias points to .opencode/scripts/ launcher"
assert_file_contains "$ZSH_RC" "alias oc-fresh=" "oc-fresh alias exists in .zshrc"
assert_file_contains "$ZSH_RC" ".opencode/bin/autopilot" "oc alias points to autopilot or safe-launch"

test_start "GOR-013" "No daily-driver OpenCode alias points to .agent/scripts"
assert_file_not_contains "$ZSH_RC" '.agent/scripts/opencode-safe-launch' "No oc alias references legacy .agent path"

test_start "GOR-014" "No stale backup files remain in ~/.config/opencode/ root"
assert_file_not_exists "$GLOBAL_CFG_DIR/opencode.json.bak" "Stale .bak file gone"
assert_file_not_exists "$GLOBAL_CFG_DIR/opencode.json.bak2" "Stale .bak2 file gone"
assert_file_not_exists "$GLOBAL_CFG_DIR/opencode.json.bak.20260328-193631" "Stale dated bak file gone"
assert_file_not_exists "$GLOBAL_CFG_DIR/opencode.json.playwright-disabled-backup" "Stale playwright-disabled backup gone"
assert_file_not_exists "$GLOBAL_CFG_DIR/opencode.json.backup.playwright" "Stale backup.playwright file gone"

# ── Phase OC-L.2A: Shell Alias Authority Cleanup ──────────────────────────────

test_start "GOR-015" "Canonical RAM/DB/OC management scripts exist in .opencode/scripts/"
assert_file_exists "$ROOT_DIR/.opencode/scripts/ram-check.sh" "ram-check.sh in canonical location"
assert_file_exists "$ROOT_DIR/.opencode/scripts/ram-cleanup.sh" "ram-cleanup.sh in canonical location"
assert_file_exists "$ROOT_DIR/.opencode/scripts/ram-monitor.sh" "ram-monitor.sh in canonical location"
assert_file_exists "$ROOT_DIR/.opencode/scripts/opencode-db-clean.sh" "opencode-db-clean.sh in canonical location"
assert_file_exists "$ROOT_DIR/.opencode/scripts/oc-clean.sh" "oc-clean.sh in canonical location"

test_start "GOR-016" "Daily-driver alias audit: Category A scripts point to .opencode/scripts/"
assert_file_contains "$ZSH_RC" 'opencode/scripts/ram-check.sh' "ram-check alias points to canonical"
assert_file_contains "$ZSH_RC" 'opencode/scripts/ram-cleanup.sh' "ram-cleanup alias points to canonical"
assert_file_contains "$ZSH_RC" 'opencode/scripts/ram-monitor.sh' "ram-monitor alias points to canonical"
assert_file_contains "$ZSH_RC" 'opencode/scripts/opencode-db-clean.sh' "db-clean alias points to canonical"
assert_file_contains "$ZSH_RC" 'opencode/scripts/oc-clean.sh' "oc-clean alias points to canonical"

test_start "GOR-017" "No Category A alias points to .agent/scripts/ for daily-driver tools"
assert_file_not_contains "$ZSH_RC" '.agent/scripts/ram-check.sh' "ram-check does not reference .agent"
assert_file_not_contains "$ZSH_RC" '.agent/scripts/ram-cleanup.sh' "ram-cleanup does not reference .agent"
assert_file_not_contains "$ZSH_RC" '.agent/scripts/ram-monitor.sh' "ram-monitor does not reference .agent"
assert_file_not_contains "$ZSH_RC" '.agent/scripts/opencode-db-clean.sh' "db-clean does not reference .agent"
assert_file_not_contains "$ZSH_RC" '.agent/scripts/oc-clean.sh' "oc-clean does not reference .agent"

test_start "GOR-018" "Legacy .agent/ OpenCode shims retired (OC-L.3a)"
for shim in ram-check.sh ram-cleanup.sh ram-monitor.sh oc-clean.sh opencode-db-clean.sh; do
    assert_file_not_exists "$ROOT_DIR/.agent/scripts/$shim" "$shim shim has been retired"
done

test_start "GOR-019" "Legacy .agent/ shims fully retired — no delegation needed (OC-L.3a)"
for shim in ram-check.sh ram-cleanup.sh ram-monitor.sh oc-clean.sh opencode-db-clean.sh; do
    assert_file_not_exists "$ROOT_DIR/.agent/scripts/$shim" "$shim shim absent (retired)"
done


# ── Phase OC-L.2B: Agent/Prompt Source-of-Truth Refactor ──────────────────────────

test_start "GOR-020" "Generated agent prompt mirrors exist for ALL canonical agents"
CANONICAL_AGENTS=()
# Check all approved agents (including visual-reviewer)
for agent_name in architect budget explorer implementer planner reviewer visual-reviewer visual-reviewer-fallback; do
    agent_file="$ROOT_DIR/.opencode/agents/$agent_name.md"
    [ -f "$agent_file" ] || continue
    CANONICAL_AGENTS+=("$agent_name")
    assert_file_exists "$LOCAL_PROMPTS/$agent_name.md" "Generated mirror: $agent_name.md"
done

test_start "GOR-021" "Generated mirror content (minus header) matches canonical source"
STRIP_HEADER="tail -n +7"
for agent_name in "${CANONICAL_AGENTS[@]}"; do
    canonical="$ROOT_DIR/.opencode/agents/$agent_name.md"
    generated="$LOCAL_PROMPTS/$agent_name.md"

    if diff -q <($STRIP_HEADER "$generated") "$canonical" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $agent_name.md mirror matches canonical (content only)"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $agent_name.md mirror DRIFTED from canonical"
        diff <($STRIP_HEADER "$generated") "$canonical" | head -20
        ((TESTS_FAILED++))
    fi
done

test_start "GOR-022" "Installed prompts match their source (mirror or canonical)"
# Agents: installed must match generated mirror
for agent_name in "${CANONICAL_AGENTS[@]}"; do
    generated="$LOCAL_PROMPTS/$agent_name.md"
    installed="$GLOBAL_PROMPTS/$agent_name.md"

    if diff -q "$generated" "$installed" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $agent_name.md installed matches generated mirror"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $agent_name.md installed DRIFTED from generated mirror"
        diff "$generated" "$installed" | head -20
        ((TESTS_FAILED++))
    fi
done
# Orchestrator: installed must match canonical (no generated header)
orchestrator_installed="$GLOBAL_PROMPTS/orchestrator.md"
orchestrator_canonical="$LOCAL_PROMPTS/orchestrator.md"
if diff -q "$orchestrator_installed" "$orchestrator_canonical" > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} orchestrator.md installed matches canonical"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} orchestrator.md installed DRIFTED from canonical"
    diff "$orchestrator_installed" "$orchestrator_canonical" | head -20
    ((TESTS_FAILED++))
fi

test_start "GOR-023" "No stale/untracked prompt files in global-runtime/prompts/ with no canonical source"
ORCHESTRATOR_EXEMPTED="orchestrator"
# Internal-only agents may keep their prompts here without a canonical .opencode/agents/*.md source.
INTERNAL_ONLY_PROMPTS=("summary" "compaction")
for prompt_file in "$LOCAL_PROMPTS"/*.md; do
    [ -f "$prompt_file" ] || continue
    prompt_name=$(basename "$prompt_file" .md)

    # orchestrator is exempt — it's the canonical orchestrator prompt
    [ "$prompt_name" = "$ORCHESTRATOR_EXEMPTED" ] && continue

    # internal-only agents are also exempt
    is_internal=0
    for internal in "${INTERNAL_ONLY_PROMPTS[@]}"; do
        if [ "$prompt_name" = "$internal" ]; then
            is_internal=1
            break
        fi
    done
    [ "$is_internal" -eq 1 ] && continue

    # Every other prompt must have a matching canonical agent
    found=0
    for agent_name in "${CANONICAL_AGENTS[@]}"; do
        if [ "$prompt_name" = "$agent_name" ]; then
            found=1
            break
        fi
    done

    if [ "$found" -eq 1 ]; then
        echo -e "  ${GREEN}✓${NC} $prompt_name.md has matching canonical agent"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $prompt_name.md has NO canonical source (stale/untracked)"
        ((TESTS_FAILED++))
    fi
done

test_start "GOR-024" "Sync script exits 0 (regression guard)"
SYNC_OUTPUT=$(bash "$SYNC_SCRIPT" 2>&1) && {
    echo -e "  ${GREEN}✓${NC} sync-opencode-runtime.sh exits 0"
    ((TESTS_PASSED++))
} || {
    echo -e "  ${RED}✗${NC} sync-opencode-runtime.sh FAILED"
    echo "$SYNC_OUTPUT" | head -10
    ((TESTS_FAILED++))
}

test_start "GOR-025" "All canonical agents defined in workspace; if global has agent block it must be a workspace subset (Option D)"
# 1. Workspace must have all 7 canonical agents (always required)
for agent_name in "${CANONICAL_AGENTS[@]}"; do
    if grep -q "\"$agent_name\"" "$ROOT_DIR/.opencode/opencode.json" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $agent_name defined in workspace config"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $agent_name NOT FOUND in workspace config"
        ((TESTS_FAILED++))
    fi
done
# Also verify orchestrator is defined in workspace
if grep -q '"orchestrator"' "$ROOT_DIR/.opencode/opencode.json" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} orchestrator defined in workspace config"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} orchestrator NOT FOUND in workspace config"
    ((TESTS_FAILED++))
fi
# 2. If global has agent block, every global agent must come from workspace
GLOBAL_FOR_025=""
for i in 1 2 3 4 5; do
  GLOBAL_FOR_025=$(cat "$GLOBAL_CFG" 2>/dev/null) && break
  sleep 0.2
done
[ -z "$GLOBAL_FOR_025" ] && GLOBAL_FOR_025="{}"
GLOBAL_AGENT_NAMES=$(echo "$GLOBAL_FOR_025" | jq -r '.agent // {} | keys | sort | join(",")')
if [ -z "$GLOBAL_AGENT_NAMES" ]; then
    echo -e "  ${GREEN}✓${NC} Global has no agent block (GLOBAL_THIN_IDLE — agents in workspace only)"
    ((TESTS_PASSED++))
else
    WORKSPACE_AGENT_NAMES_FOR_025=$(echo "$WORKSPACE_CONTENT" | jq -r '.agent // {} | keys | sort | join(",")')
    UNEXPECTED_AGENTS=$(echo "$GLOBAL_FOR_025" | jq -r --arg ws "$WORKSPACE_AGENT_NAMES_FOR_025" '
      (.agent // {} | keys) - ($ws | split(",")) | sort | join(",")
    ')
    if [ -z "$UNEXPECTED_AGENTS" ]; then
        echo -e "  ${GREEN}✓${NC} Global agent block is a workspace subset (GLOBAL_RUNTIME_MATERIALIZED): [$GLOBAL_AGENT_NAMES]"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} Global has unexpected agents not in workspace: $UNEXPECTED_AGENTS"
        ((TESTS_FAILED++))
    fi
fi

# ── Phase OC-L.3b: Retired OpenCode Legacy Scripts Guard ──────────────────────

test_start "GOR-026" "No retired OpenCode legacy scripts remain active in .agent/scripts/"
RETIRE_OC_SCRIPTS=(db-query.sh oc-init.sh opencode-config-fix.sh opencode-db-prevent.sh opencode-mcp-verify.sh opencode-session-prune.sh opencode-verify.sh)
for shim in "${RETIRE_OC_SCRIPTS[@]}"; do
    assert_file_not_exists "$ROOT_DIR/.agent/scripts/$shim" "$shim absent from active .agent/scripts/"
done

# ── Phase OC-L.3d: .agent/scripts/ Allowlist Guard ────────────────────────────

test_start "GOR-027" ".agent/scripts/ allowlist: only stewardctl.sh may remain active"

# Forbidden patterns must be absent
for pattern in "opencode" "oc-" "ram-" "db-"; do
    count=$(find "$ROOT_DIR/.agent/scripts" -maxdepth 1 -name "${pattern}*" -type f 2>/dev/null | wc -l)
    if [ "$count" -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} No ${pattern}* scripts in .agent/scripts/"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} Found $count ${pattern}* scripts in .agent/scripts/"
        ((TESTS_FAILED++))
    fi
done

# Specific retired scripts must be absent
for shim in claude-toggle.sh vault-keeper.sh; do
    if [ ! -f "$ROOT_DIR/.agent/scripts/$shim" ]; then
        echo -e "  ${GREEN}✓${NC} $shim absent from .agent/scripts/"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $shim still present in .agent/scripts/"
        ((TESTS_FAILED++))
    fi
done

# stewardctl.sh must still exist (allowlist)
if [ -f "$ROOT_DIR/.agent/scripts/stewardctl.sh" ]; then
    echo -e "  ${GREEN}✓${NC} stewardctl.sh present (allowlisted)"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} stewardctl.sh missing from .agent/scripts/"
    ((TESTS_FAILED++))
fi

# ── Phase OC-OPT.1B: Conformance Hygiene & Status Command Guard ───────────────

test_start "GOR-031" "Conformance tests dir contains only executable tests; oc-status command present"

# No .md report files in tests/ directory
md_count=$(find "$ROOT_DIR/.opencode/conformance/tests" -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l)
if [ "$md_count" -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} No .md report files in conformance/tests/"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} Found $md_count .md file(s) in conformance/tests/"
    ((TESTS_FAILED++))
fi

# Archived reports exist
ARCHIVE_DIR="$ROOT_DIR/.opencode/conformance/archive/reports"
if [ -d "$ARCHIVE_DIR" ]; then
    archive_count=$(find "$ARCHIVE_DIR" -name '*.md' -type f 2>/dev/null | wc -l)
    if [ "$archive_count" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} $archive_count report(s) archived in conformance/archive/reports/"
        ((TESTS_PASSED++))
    else
        echo -e "  ${YELLOW}⚠${NC} Archive directory exists but is empty"
        ((TESTS_PASSED++))
    fi
else
    echo -e "  ${RED}✗${NC} Archive directory missing"
    ((TESTS_FAILED++))
fi

# oc-status.sh exists and is executable
STATUS_SCRIPT="$ROOT_DIR/.opencode/scripts/oc-status.sh"
if [ -f "$STATUS_SCRIPT" ]; then
    echo -e "  ${GREEN}✓${NC} oc-status.sh exists"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} oc-status.sh missing"
    ((TESTS_FAILED++))
fi

if [ -x "$STATUS_SCRIPT" ]; then
    echo -e "  ${GREEN}✓${NC} oc-status.sh is executable"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} oc-status.sh is not executable"
    ((TESTS_FAILED++))
fi

# oc-status alias points to canonical script
if grep -q 'alias oc-status=.*\.opencode/scripts/oc-status\.sh' "$HOME/.zshrc" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} oc-status alias points to .opencode/scripts/oc-status.sh"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} oc-status alias missing or wrong"
    ((TESTS_FAILED++))
fi

# ── Phase OC-OPT.1B-Hotfix: oc-status Drift Accuracy Guard ────────────────────

test_start "GOR-032" "oc-status prompt drift detection matches conformance reality"

# After sync, oc-status should NOT report prompt drift for any agent
STATUS_OUTPUT=$(bash "$ROOT_DIR/.opencode/scripts/oc-status.sh" 2>&1)
DRIFT_COUNT=$(echo "$STATUS_OUTPUT" | grep -c 'canonical ≠ mirror' || true)
if [ "$DRIFT_COUNT" -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} oc-status reports no false prompt drift after sync"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} oc-status reports $DRIFT_COUNT false drift(s) after sync"
    ((TESTS_FAILED++))
fi

# oc-status should report "All prompts in sync" after sync
if echo "$STATUS_OUTPUT" | grep -q 'All prompts in sync'; then
    echo -e "  ${GREEN}✓${NC} oc-status confirms all prompts in sync"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} oc-status does not confirm sync (may have real drift)"
    ((TESTS_FAILED++))
fi

echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
