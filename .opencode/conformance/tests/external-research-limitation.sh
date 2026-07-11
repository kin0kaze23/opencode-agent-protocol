#!/bin/bash
# External Research Limitation Test
# Verifies that social/news/recency requests do NOT trigger WebFetch or fabricate sentiment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/external-research-limitation-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - External Research Limitation Test"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

# ============================================================
# EXTERNAL-001: AGENTS.md has external research limitation rule
# ============================================================
test_start "EXTERNAL-001" "AGENTS.md has external research limitation"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "External Research Limitation" "Rule exists in AGENTS.md"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "Do NOT simulate external research via WebFetch" "WebFetch explicitly blocked"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" "Do NOT use curl/shell to scrape" "Shell scraping blocked"

# ============================================================
# EXTERNAL-002: advise.md has external research limitation
# ============================================================
test_start "EXTERNAL-002" "advise.md has external research limitation"
assert_file_contains "$ROOT_DIR/.opencode/commands/advise.md" "External Research Limitation" "Rule exists in advise.md"
assert_file_contains "$ROOT_DIR/.opencode/commands/advise.md" "Do NOT use WebFetch, curl, or shell" "WebFetch blocked at command level"

# ============================================================
# EXTERNAL-003: ecosystem-scan skill forbids WebFetch
# ============================================================
test_start "EXTERNAL-003" "ecosystem-scan skill forbids WebFetch"
assert_file_contains "$ROOT_DIR/.opencode/skills/ecosystem-scan/SKILL.md" "Do NOT use WebFetch" "WebFetch explicitly forbidden"
assert_file_contains "$ROOT_DIR/.opencode/skills/ecosystem-scan/SKILL.md" "reddit" "Reddit in trigger keywords"
assert_file_contains "$ROOT_DIR/.opencode/skills/ecosystem-scan/SKILL.md" "last 30 days" "Recency in trigger keywords"

# ============================================================
# EXTERNAL-004: brain-config.json has out-of-scope triggers
# ============================================================
test_start "EXTERNAL-004" "brain-config.json has out-of-scope triggers"
assert_file_contains "$ROOT_DIR/.opencode/brain-config.json" "what are people saying" "Social sentiment trigger"
assert_file_contains "$ROOT_DIR/.opencode/brain-config.json" "reddit" "Reddit trigger"
assert_file_contains "$ROOT_DIR/.opencode/brain-config.json" "last 30 days" "Recency trigger"
assert_file_contains "$ROOT_DIR/.opencode/brain-config.json" "market research" "Market research trigger"

# ============================================================
# EXTERNAL-005: rules.md has external research limitation
# ============================================================
test_start "EXTERNAL-005" "rules.md has external research limitation"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "External Research Limitation" "Rule exists in rules.md"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" "Do NOT simulate external research" "Simulation blocked"

# ============================================================
# EXTERNAL-006: runtime workspace config denies webfetch
# ============================================================
test_start "EXTERNAL-006" "workspace opencode.json denies webfetch"
assert_file_contains "$ROOT_DIR/.opencode/opencode.json" "\"webfetch\": \"deny\"" "webfetch denied in runtime config"
assert_file_contains "$ROOT_DIR/.opencode/opencode.json" ".opencode/AGENTS.md" "AGENTS.md injected into runtime config"
assert_file_not_contains "$ROOT_DIR/.opencode/opencode.json" ".opencode/skills/ecosystem-scan/SKILL.md" "ecosystem-scan not bootstrapped into runtime config"
assert_file_contains "$ROOT_DIR/.opencode/brain-config.json" "ecosystem-scan/SKILL.md" "ecosystem-scan available through selective skill loading"

# ============================================================
# EXTERNAL-007: approved research MCP path is explicit
# ============================================================
test_start "EXTERNAL-007" "approved research MCP path is explicit"
assert_file_contains "$ROOT_DIR/.opencode/AGENTS.md" 'Current approved search MCP: `Exa`' "AGENTS.md names Exa as approved search MCP"
assert_file_contains "$ROOT_DIR/.opencode/rules.md" 'Current approved search MCP: `Exa`' "rules.md names Exa as approved search MCP"
assert_file_contains "$ROOT_DIR/.opencode/commands/advise.md" "approved search MCPs" "advise.md allows only approved search MCPs"
assert_file_contains "$ROOT_DIR/.opencode/brain-config.json" "\"exa\"" "brain-config declares Exa metadata"
assert_file_contains "$ROOT_DIR/.opencode/brain-config.json" "\"blocked_for\"" "brain-config documents blocked search cases"

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"

# ============================================================
# MANUAL TEST REQUIRED
# ============================================================
echo ""
echo "=========================================="
echo "MANUAL RUNTIME TEST REQUIRED"
echo "=========================================="
echo ""
echo "Run this prompt in OpenCode CLI:"
echo ""
echo "  What are people saying about Hono on Reddit in the last 30 days?"
echo ""
echo "Expected behavior:"
echo "  ✓ ecosystem-scan skill activates"
echo "  ✓ OUT-OF-SCOPE section returned for social-sentiment request"
echo "  ✓ NO WebFetch against Reddit"
echo "  ✓ NO fabricated sentiment claims"
echo "  ✓ Safe alternative suggested"
echo ""
echo "Failure behavior:"
echo "  ✗ WebFetch used against Reddit URLs"
echo "  ✗ Sentiment synthesis returned"
echo "  ✗ No OUT-OF-SCOPE section"
echo ""
echo "Approved-search example prompt:"
echo ""
echo "  Use Exa to find 2 direct Hono documentation or GitHub examples for WebSocket handling. Cite the exact URLs and summarize the pattern."
echo ""
echo "Expected behavior:"
echo "  ✓ Approved Exa path used when available"
echo "  ✓ Exact source URLs cited"
echo "  ✓ VERIFIED vs INFERRED discipline preserved"
echo ""
