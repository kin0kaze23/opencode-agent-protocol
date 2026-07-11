#!/bin/bash
# OpenCode v4.5 native-alignment checks.
# Focus: context-minimal bootstrap, helper permission surface, safe config inspection, and protocol doc placement.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/opencode-v45-native-alignment-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

OPENCODE_JSON="$ROOT_DIR/.opencode/opencode.json"
RULES="$ROOT_DIR/.opencode/rules.md"
ROSTER="$ROOT_DIR/.opencode/helper-roster.md"
SKILL_REGISTRY="$ROOT_DIR/.opencode/skills/registry.md"
V45_DOC="$ROOT_DIR/vault/protocols/opencode/v4.5-opencode-native-alignment.md"

echo "=========================================="
echo "Protocol Conformance Suite - OpenCode v4.5 Native Alignment"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

test_start "V45-001" "Context-minimal OpenCode bootstrap"
assert_file_not_contains "$OPENCODE_JSON" ".opencode/commands/" "Command bodies are not always injected as instructions"
assert_file_contains "$OPENCODE_JSON" ".opencode/AGENTS.md" "Core OpenCode protocol remains bootstrapped"
assert_file_contains "$OPENCODE_JSON" ".opencode/rules.md" "Core OpenCode rules remain bootstrapped"
# v4.20: helper-roster.md moved from startup instructions to reference-only
assert_file_not_contains "$OPENCODE_JSON" ".opencode/helper-roster.md" "Helper roster is reference-only (v4.20: not in startup instructions)"
assert_file_exists "$ROSTER" "Helper roster doc exists as reference"

test_start "V45-002" "Daily helper permission surface excludes eval-only helpers"
PERMISSION_KEYS=$(ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json, os
from pathlib import Path
cfg = json.loads(Path(os.environ['ROOT_DIR'] + '/.opencode/opencode.json').read_text())
print(','.join(sorted(cfg.get('permission', {}).get('task', {}).keys())))
PY
)
assert_equals "architect,budget,explorer,implementer,planner,reviewer,visual-reviewer,visual-reviewer-fallback" "$PERMISSION_KEYS" "Allowed task helpers match daily roster"
assert_file_not_contains "$OPENCODE_JSON" "ModelEval-" "Eval helpers are not allowed by default"
assert_file_contains "$ROSTER" "Eval mode only" "Roster marks ModelEval helpers as eval-mode only"

test_start "V45-003" "Safe config inspection and protocol documentation"
assert_file_contains "$RULES" "raw oc debug config output" "Rules block raw resolved config sharing"
assert_file_contains "$RULES" "vault/protocols" "Rules prefer protocol docs under vault/protocols"
assert_file_exists "$V45_DOC" "v4.5 protocol doc exists under vault/protocols"
assert_file_not_contains "$V45_DOC" "sk-" "v4.5 doc does not contain obvious API key literal"

test_start "V45-004" "Skill registry runtime-exposure caveat is explicit"
assert_file_contains "$SKILL_REGISTRY" "Runtime exposure status" "Skill registry documents runtime exposure status"
assert_file_contains "$SKILL_REGISTRY" "Filesystem-maintained" "Skill registry distinguishes filesystem-maintained skills"

echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
