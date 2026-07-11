#!/bin/bash
# Phase B1 Command-Quality Uplift Tests
# Tests the new quality patterns added to debug, advise, plan-feature, implement

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/b1-command-quality-${TIMESTAMP}.md"

source "$SCRIPT_DIR/../assert.sh"

echo "=========================================="
echo "Protocol Conformance Suite - Phase B1 Command-Quality Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo ""

reset_counters

# ============================================================
# B1-DEBUG-001: Hypothesis discipline (2-4 ranked hypotheses)
# ============================================================
test_start "B1-DEBUG-001" "Hypothesis discipline present"
assert_file_contains "$ROOT_DIR/.opencode/commands/debug.md" "2-4.*falsifiable hypotheses" "2-4 hypotheses required"
assert_file_contains "$ROOT_DIR/.opencode/commands/debug.md" "H1:" "H1 hypothesis format"
assert_file_contains "$ROOT_DIR/.opencode/commands/debug.md" "H2:" "H2 hypothesis format"

# ============================================================
# B1-DEBUG-002: Causal-confidence rule
# ============================================================
test_start "B1-DEBUG-002" "Causal-confidence rule present"
assert_file_contains "$ROOT_DIR/.opencode/commands/debug.md" "causal-confidence" "Causal-confidence rule"
assert_file_contains "$ROOT_DIR/.opencode/commands/debug.md" "If.*is true, then.*will fail" "Causal-confidence format"

# ============================================================
# B1-DEBUG-003: Failure-surface mapping (conditional)
# ============================================================
test_start "B1-DEBUG-003" "Failure-surface mapping for shared logic"
assert_file_contains "$ROOT_DIR/.opencode/commands/debug.md" "failure surface" "Failure-surface mapping"
assert_file_contains "$ROOT_DIR/.opencode/commands/debug.md" "shared logic, state, auth, schema, or cross-module" "Conditional trigger"

# ============================================================
# B1-ADVISE-001: Recommendation rule
# ============================================================
test_start "B1-ADVISE-001" "Recommendation rule present"
assert_file_contains "$ROOT_DIR/.opencode/commands/advise.md" "Recommend.*when" "Recommend when condition"
assert_file_contains "$ROOT_DIR/.opencode/commands/advise.md" "Defer.*when" "Defer when condition"

# ============================================================
# B1-ADVISE-002: Alternative-choice conditions
# ============================================================
test_start "B1-ADVISE-002" "Alternative-choice conditions"
assert_file_contains "$ROOT_DIR/.opencode/commands/advise.md" "Choose.*when" "Choose when format"

# ============================================================
# B1-ADVISE-003: Re-evaluation triggers (non-trivial)
# ============================================================
test_start "B1-ADVISE-003" "Re-evaluation triggers for non-trivial"
assert_file_contains "$ROOT_DIR/.opencode/commands/advise.md" "Revisit.*if" "Re-evaluation trigger format"
assert_file_contains "$ROOT_DIR/.opencode/commands/advise.md" "non-trivial" "Non-trivial condition"

# ============================================================
# B1-PLAN-001: Vague-scope clarification
# ============================================================
test_start "B1-PLAN-001" "Vague-scope clarification patterns"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Vague-Scope" "Vague-scope section"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Unclear.*done" "Unclear done pattern"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Hidden stakeholders" "Hidden stakeholders pattern"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Unbounded scope" "Unbounded scope pattern"

# ============================================================
# B1-PLAN-002: Decide-now-vs-defer framework
# ============================================================
test_start "B1-PLAN-002" "Decide-now-vs-defer framework"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Decide now" "Decide now option"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Defer" "Defer option"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Blocks all downstream" "Decide-now criteria"

# ============================================================
# B1-PLAN-003: Narrow-first slicing (soft rule)
# ============================================================
test_start "B1-PLAN-003" "Narrow-first slicing criteria"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Narrow-First" "Narrow-first section"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Testable in isolation" "Testable criterion"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "Reversible" "Reversible criterion"
assert_file_contains "$ROOT_DIR/.opencode/commands/plan-feature.md" "User-visible" "User-visible criterion"

# ============================================================
# B1-IMPL-001: Contract-first synthesis
# ============================================================
test_start "B1-IMPL-001" "Contract-first synthesis"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Contract-First" "Contract-first section"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Re-state the contract" "Re-state requirement"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Verify contract coherence" "Coherence check"

# ============================================================
# B1-IMPL-002: Sensitive-path security check
# ============================================================
test_start "B1-IMPL-002" "Sensitive-path security check"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Sensitive-Path Security" "Security check section"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "user input" "User input question"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "sensitive data" "Sensitive data question"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "trust boundaries" "Trust boundaries question"

# ============================================================
# B1-IMPL-003: Security summary in Completion Summary
# ============================================================
test_start "B1-IMPL-003" "Security summary output"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Security check:" "Security check output"
assert_file_contains "$ROOT_DIR/.opencode/commands/implement.md" "Sensitive data handling" "Sensitive data output"

# ============================================================
# Results
# ============================================================
echo ""
report_results "$RESULT_FILE"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
