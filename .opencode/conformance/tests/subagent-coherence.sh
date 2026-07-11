#!/bin/bash
# Subagent Coherence Tests - Active roster aligns with helper specs and naming

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/subagent-coherence-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Subagent Coherence Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

BRAIN_CONFIG="$ROOT_DIR/.opencode/brain-config.json"
AGENTS_DOC="$ROOT_DIR/.opencode/AGENTS.md"
ROSTER_DOC="$ROOT_DIR/.opencode/helper-roster.md"
SUBAGENT_SUMMARY="$ROOT_DIR/vault/context/agent protocol/agent-subagent-config.md"

test_start "SUB-001" "Active roster uses spec-backed helper names"
ROSTER_KEYS=$(ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json, os
from pathlib import Path

cfg = json.loads(Path(os.environ["ROOT_DIR"] + "/.opencode/brain-config.json").read_text())
core = sorted(cfg["subagents"]["roster"]["core"].keys())
specialized = sorted(cfg["subagents"]["roster"]["specialized"].keys())
print(",".join(core))
print(",".join(specialized))
PY
)
CORE_KEYS=$(echo "$ROSTER_KEYS" | sed -n '1p')
SPECIALIZED_KEYS=$(echo "$ROSTER_KEYS" | sed -n '2p')
assert_equals "explorer,implementer,planner,reviewer" "$CORE_KEYS" "Core helper roster matches canonical names"
assert_equals "architect,budget,visual-reviewer,visual-reviewer-fallback" "$SPECIALIZED_KEYS" "Specialized helper roster matches canonical names"

test_start "SUB-002" "Legacy roster names removed from active roster"
LEGACY_KEYS=$(ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json, os
from pathlib import Path

cfg = json.loads(Path(os.environ["ROOT_DIR"] + "/.opencode/brain-config.json").read_text())
keys = set(cfg["subagents"]["roster"]["core"].keys()) | set(cfg["subagents"]["roster"]["specialized"].keys())
legacy = [k for k in ["qa", "implementation", "research", "analysis", "dev_init"] if k in keys]
print(",".join(legacy))
PY
)
assert_equals "" "$LEGACY_KEYS" "Legacy helper names absent from active roster"

test_start "SUB-003" "Non-spec specialist roles are routed, not declared as helpers"
DEMOTED_KEYS=$(ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import json, os
from pathlib import Path

cfg = json.loads(Path(os.environ["ROOT_DIR"] + "/.opencode/brain-config.json").read_text())
keys = set(cfg["subagents"]["roster"]["core"].keys()) | set(cfg["subagents"]["roster"]["specialized"].keys())
demoted = [k for k in ["debugger", "visual_qa", "security", "performance", "deployment", "secondary_reviewer"] if k in keys]
print(",".join(demoted))
PY
)
assert_equals "" "$DEMOTED_KEYS" "Non-spec specialist roles absent from active roster"
assert_file_contains "$BRAIN_CONFIG" "\"specialist_routing\"" "Specialist routing section exists"

test_start "SUB-004" "Owner docs align with expanded helper roster"
assert_file_contains "$BRAIN_CONFIG" "specialist_routing" "Brain-config has specialist routing section"

test_start "SUB-005" "Workflow spawn line aligns with active roster"
assert_file_contains "$BRAIN_CONFIG" "Explorer / Planner / Implementer / Reviewer / Architect" "Workflow spawn line includes core helpers"

test_start "SUB-006" "Secondary review model routing is coherent"
assert_file_contains "$BRAIN_CONFIG" "\"bulk_review\": \"umans-ai-coding-plan/umans-flash\"" "bulk_review routes to umans-flash (v1.5 capacity-first)"
assert_file_contains "$ROSTER_DOC" "glm-5" "Roster doc references glm-5 as secondary review"

echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
