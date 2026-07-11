#!/bin/bash
# Environment Coherence Tests - Bootstrap, registry, and runtime-policy alignment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/environment-coherence-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Environment Coherence Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

OPENCODE_JSON="$ROOT_DIR/.opencode/opencode.json"
BRAIN_CONFIG="$ROOT_DIR/.opencode/brain-config.json"
WORKSPACE_MAP="$ROOT_DIR/WORKSPACE_MAP.md"
REGISTRY="$ROOT_DIR/.opencode/registry.yaml"
WORKSPACE_GUARD="$ROOT_DIR/.opencode/scripts/workspace-protocol-guard.sh"

test_start "ENV-001" "Canonical registry path and deprecated-path cleanup"
assert_file_exists "$REGISTRY" "Canonical registry exists"
assert_file_contains "$BRAIN_CONFIG" "\"path\": \".opencode/registry.yaml\"" "brain-config uses canonical registry"
assert_file_not_contains "$WORKSPACE_MAP" ".agent/PROTOCOLS/REPO_REGISTRY.yaml" "workspace map no longer points at deprecated registry"
assert_file_contains "$WORKSPACE_MAP" ".opencode/registry.yaml" "workspace map points at canonical registry"

test_start "ENV-002" "Bootstrap loads policy only and relies on native command discovery"
assert_file_not_contains "$OPENCODE_JSON" ".opencode/skills/" "No skill files bootstrapped"
assert_file_not_contains "$OPENCODE_JSON" ".opencode/commands/" "Command bodies are not injected through instructions"
COMMAND_COUNT=$(ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import os
from pathlib import Path
root = Path(os.environ["ROOT_DIR"])
print(len(list((root / ".opencode/commands").glob("*.md"))))
PY
)
if [ "$COMMAND_COUNT" -ge 20 ]; then
    echo "  ${GREEN}✓${NC} Native command directory populated: $COMMAND_COUNT command files"
    ((TESTS_PASSED++))
else
    echo "  ${RED}✗${NC} Native command directory unexpectedly sparse: $COMMAND_COUNT command files"
    ((TESTS_FAILED++))
fi

test_start "ENV-003" "Skill loading policy matches bootstrap"
assert_file_contains "$BRAIN_CONFIG" "Startup loads policy files only" "Skill policy says startup is policy-only"
assert_file_contains "$BRAIN_CONFIG" "must not be bootstrapped through opencode.json" "Skill policy forbids bootstrap loading"

test_start "ENV-004" "Registry and workspace map repo counts match"
COUNTS=$(ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import os
from pathlib import Path

root = Path(os.environ["ROOT_DIR"])
registry = root / ".opencode/registry.yaml"
workspace = root / "WORKSPACE_MAP.md"

count = 0
in_repos = False
for line in registry.read_text().splitlines():
    if line.strip() == "repositories:":
        in_repos = True
        continue
    if in_repos:
        if line and not line.startswith("  "):
            break
        if line.startswith("  ") and not line.startswith("    ") and line.rstrip().endswith(":"):
            count += 1

map_count = 0
for line in workspace.read_text().splitlines():
    if line.startswith("| **") or line.startswith("| ~~"):
        map_count += 1

print(count)
print(map_count)
PY
)
REGISTRY_COUNT=$(echo "$COUNTS" | sed -n '1p')
MAP_COUNT=$(echo "$COUNTS" | sed -n '2p')
assert_equals "$REGISTRY_COUNT" "$MAP_COUNT" "Registry repo count matches workspace map"

test_start "ENV-005" "Parallel execution restricts writers"
assert_file_contains "$BRAIN_CONFIG" "\"max_parallel_writers\": 1" "Single writer limit"
assert_file_contains "$BRAIN_CONFIG" "\"writer_isolation_required\": true" "Writer isolation required"
assert_file_contains "$BRAIN_CONFIG" "\"shared_branch_writers_forbidden\": true" "Shared writer branch forbidden"

test_start "ENV-006" "High-risk lane security is operationalized"
assert_file_contains "$BRAIN_CONFIG" "\"lane_enforcement\"" "Security lane enforcement exists"
assert_file_contains "$BRAIN_CONFIG" "\"HIGH-RISK\"" "High-risk lane present"
assert_file_contains "$BRAIN_CONFIG" "\"sast\"" "High-risk SAST enforcement documented"
assert_file_contains "$BRAIN_CONFIG" "reviewer mandatory" "High-risk reviewer requirement"
assert_file_contains "$BRAIN_CONFIG" "rollback note mandatory" "High-risk rollback requirement"

test_start "ENV-007" "Second-brain writes are checkpoint and confirmation driven"
assert_file_contains "$BRAIN_CONFIG" "\"checkpoint\"" "Checkpoint-driven progress writes"
assert_file_contains "$BRAIN_CONFIG" "\"confirmed_lesson\"" "Confirmed lesson persistence only"
assert_file_not_contains "$BRAIN_CONFIG" "\"after_failure\"" "No automatic failure lesson writes"
assert_file_not_contains "$BRAIN_CONFIG" "\"post_execution\"" "No broad post-execution auto-write"

test_start "ENV-008" "Approved research MCPs are declared coherently"
assert_file_contains "$BRAIN_CONFIG" "\"exa\"" "Exa MCP metadata exists"
assert_file_contains "$BRAIN_CONFIG" "exa-mcp-server" "Exa local MCP package documented from checked-in runtime"
assert_file_contains "$BRAIN_CONFIG" "\"manual_per_query_only\"" "Approved search stays per-query"
# web-tools was deprecated and removed (2026-07-01) — no longer expected in brain-config

test_start "ENV-009" "Workspace protocol guard stays wired into runtime contracts"
assert_file_exists "$WORKSPACE_GUARD" "Workspace protocol guard exists"
assert_file_contains "$WORKSPACE_GUARD" "workspace-hygiene-audit.sh" "Guard runs workspace hygiene audit"
assert_file_contains "$WORKSPACE_GUARD" "environment-coherence.sh" "Guard runs environment coherence suite"
assert_file_contains "$WORKSPACE_GUARD" "global-opencode-runtime.sh" "Guard runs launcher runtime suite"
assert_file_contains "$ROOT_DIR/AGENTS.md" "workspace-protocol-guard.sh" "Root AGENTS references protocol guard"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "workspace-protocol-guard.sh" "OpenCode AGENTS references protocol guard"
assert_file_contains "$ROOT_DIR/CLAUDE.md" "workspace-protocol-guard.sh" "Claude adapter references protocol guard"
assert_file_contains "$ROOT_DIR/GEMINI.md" "workspace-protocol-guard.sh" "Gemini adapter references protocol guard"

echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
