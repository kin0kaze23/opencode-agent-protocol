#!/bin/bash
# Owner memory runtime checks.
# Focus: advisory authority, command wiring, index completeness, and baseline schema.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/owner-memory-runtime-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

PROTOCOL_DIR="$ROOT_DIR/vault/protocols/owner-memory"
MEMORY_DIR="$ROOT_DIR/vault/owner-memory"
RULES="$ROOT_DIR/.opencode/rules.md"
AGENTS="$ROOT_DIR/.opencode/AGENTS.md"

echo "=========================================="
echo "Protocol Conformance Suite - Owner Memory Runtime"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

test_start "MEM-001" "Owner memory protocol docs exist"
assert_file_exists "$PROTOCOL_DIR/README.md" "Owner memory README exists"
assert_file_exists "$PROTOCOL_DIR/SCHEMA.md" "Owner memory schema exists"
assert_file_exists "$PROTOCOL_DIR/runtime-flow.md" "Owner memory runtime flow exists"

test_start "MEM-002" "Owner memory store baseline exists"
assert_file_exists "$MEMORY_DIR/README.md" "Owner memory store README exists"
assert_file_exists "$MEMORY_DIR/index.md" "Owner memory index exists"
assert_file_exists "$MEMORY_DIR/log.md" "Owner memory log exists"

test_start "MEM-003" "Owner memory command contracts exist"
assert_file_exists "$ROOT_DIR/.opencode/commands/memory-status.md" "/memory-status command exists"
assert_file_exists "$ROOT_DIR/.opencode/commands/memory-save.md" "/memory-save command exists"
assert_file_exists "$ROOT_DIR/.opencode/commands/memory-audit.md" "/memory-audit command exists"

test_start "MEM-004" "Runtime rules wire Owner memory as advisory"
assert_file_contains "$RULES" "Owner Memory Runtime Rules" "Rules include Owner memory runtime section"
assert_file_contains "$RULES" "advisory only" "Rules declare Owner memory advisory"
assert_file_contains "$RULES" "never overrides" "Rules prevent memory from overriding repo truth"
assert_file_contains "$AGENTS" "vault/owner-memory/index.md" "Startup expansion mentions Owner memory index"

test_start "MEM-005" "Indexed memory pages exist and are advisory"
ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
from pathlib import Path
import os, re
root = Path(os.environ['ROOT_DIR'])
idx = root / 'vault/owner-memory/index.md'
text = idx.read_text()
paths = re.findall(r'`([^`]+\.md)`', text)
missing = []
bad = []
for rel in paths:
    p = root / 'vault/owner-memory' / rel
    if not p.exists():
        missing.append(rel)
        continue
    body = p.read_text()
    if 'authority: advisory' not in body:
        bad.append(rel + ' missing authority: advisory')
    if 'sources:' not in body:
        bad.append(rel + ' missing sources')
if missing or bad:
    print('Missing:', missing)
    print('Bad:', bad)
    raise SystemExit(1)
print(f'Indexed pages verified: {len(paths)}')
PY
echo -e "  ${GREEN}✓${NC} Indexed memory pages exist with advisory authority and sources"
((TESTS_PASSED++))

test_start "MEM-006" "Owner memory blocks secret-prone content"
assert_file_not_contains "$MEMORY_DIR/index.md" "sk-" "Index has no obvious API key literal"
assert_file_not_contains "$MEMORY_DIR/log.md" "sk-" "Log has no obvious API key literal"
assert_file_contains "$PROTOCOL_DIR/SCHEMA.md" "Skip when" "Schema documents skip criteria"
assert_file_contains "$PROTOCOL_DIR/SCHEMA.md" "secret" "Schema blocks secrets"

echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
