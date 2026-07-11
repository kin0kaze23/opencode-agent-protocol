#!/bin/bash
# Run All Conformance Tests (Phase 3a + 3b)
# Executes smoke, guarded-local, failure-recovery, browser-verification, and helper-runtime tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Protocol Conformance Suite - Full Run (Phase 3a + 3b)"
echo "=========================================="
echo ""

# Track overall results
TOTAL_PASSED=0
TOTAL_FAILED=0
FAILED_SUITES=()

# Run smoke tests
echo ">>> Running smoke tests..."
if bash "$SCRIPT_DIR/smoke.sh"; then
    echo "Smoke tests: PASSED"
else
    echo "Smoke tests: FAILED"
    FAILED_SUITES+=("smoke")
fi
echo ""

# Run debug-first compliance tests (documentation audit)
echo ">>> Running debug-first compliance tests (documentation)..."
if bash "$SCRIPT_DIR/debug-first-compliance.sh"; then
    echo "Debug-first compliance tests: PASSED"
else
    echo "Debug-first compliance tests: FAILED"
    FAILED_SUITES+=("debug-first-compliance")
fi
echo ""

# Run debug-first behavioral tests (fresh session proof)
echo ">>> Running debug-first behavioral tests (fresh session)..."
if bash "$SCRIPT_DIR/debug-first-behavioral.sh"; then
    echo "Debug-first behavioral tests: PASSED"
else
    echo "Debug-first behavioral tests: FAILED"
    FAILED_SUITES+=("debug-first-behavioral")
fi
echo ""

# Run debug-first behavioral edit tests (full edit cycle proof)
echo ">>> Running debug-first behavioral edit tests (edit cycle)..."
if bash "$SCRIPT_DIR/debug-first-behavioral-edit.sh"; then
    echo "Debug-first behavioral edit tests: PASSED"
else
    echo "Debug-first behavioral edit tests: FAILED"
    FAILED_SUITES+=("debug-first-behavioral-edit")
fi
echo ""

# Run guarded local tests
echo ">>> Running guarded local tests..."
if bash "$SCRIPT_DIR/guarded-local.sh"; then
    echo "Guarded local tests: PASSED"
else
    echo "Guarded local tests: FAILED"
    FAILED_SUITES+=("guarded-local")
fi
echo ""

# Run failure recovery tests
echo ">>> Running failure recovery tests..."
if bash "$SCRIPT_DIR/failure-recovery.sh"; then
    echo "Failure recovery tests: PASSED"
else
    echo "Failure recovery tests: FAILED"
    FAILED_SUITES+=("failure-recovery")
fi
echo ""

# Run browser verification tests (Phase 3b)
echo ">>> Running browser verification tests (Phase 3b)..."
if bash "$SCRIPT_DIR/browser-verification.sh"; then
    echo "Browser verification tests: PASSED"
else
    echo "Browser verification tests: FAILED"
    FAILED_SUITES+=("browser-verification")
fi
echo ""

# Run helper runtime tests (Phase 3b)
echo ">>> Running helper runtime tests (Phase 3b)..."
if bash "$SCRIPT_DIR/helper-runtime.sh"; then
    echo "Helper runtime tests: PASSED"
else
    echo "Helper runtime tests: FAILED"
    FAILED_SUITES+=("helper-runtime")
fi
echo ""

# Run external research limitation tests
echo ">>> Running external research limitation tests..."
if bash "$SCRIPT_DIR/external-research-limitation.sh"; then
    echo "External research limitation tests: PASSED"
else
    echo "External research limitation tests: FAILED"
    FAILED_SUITES+=("external-research-limitation")
fi
echo ""

# Run Phase B1 command-quality tests
echo ">>> Running Phase B1 command-quality tests..."
if bash "$SCRIPT_DIR/b1-command-quality.sh"; then
    echo "Phase B1 command-quality tests: PASSED"
else
    echo "Phase B1 command-quality tests: FAILED"
    FAILED_SUITES+=("b1-command-quality")
fi
echo ""

# Run lesson promotion tests
echo ">>> Running lesson promotion tests..."
if bash "$SCRIPT_DIR/lesson-promotion.sh"; then
    echo "Lesson promotion tests: PASSED"
else
    echo "Lesson promotion tests: FAILED"
    FAILED_SUITES+=("lesson-promotion")
fi
echo ""

# Run implementation-readiness protocol tests
echo ">>> Running implementation-readiness protocol tests..."
if bash "$SCRIPT_DIR/implementation-readiness.sh"; then
    echo "Implementation-readiness protocol tests: PASSED"
else
    echo "Implementation-readiness protocol tests: FAILED"
    FAILED_SUITES+=("implementation-readiness")
fi
echo ""

# Run elite operating-model tests
echo ">>> Running elite operating-model tests..."
if bash "$SCRIPT_DIR/elite-ops.sh"; then
    echo "Elite operating-model tests: PASSED"
else
    echo "Elite operating-model tests: FAILED"
    FAILED_SUITES+=("elite-ops")
fi
echo ""

# Run environment coherence tests
echo ">>> Running environment coherence tests..."
if bash "$SCRIPT_DIR/environment-coherence.sh"; then
    echo "Environment coherence tests: PASSED"
else
    echo "Environment coherence tests: FAILED"
    FAILED_SUITES+=("environment-coherence")
fi
echo ""

# Run subagent coherence tests
echo ">>> Running subagent coherence tests..."
if bash "$SCRIPT_DIR/subagent-coherence.sh"; then
    echo "Subagent coherence tests: PASSED"
else
    echo "Subagent coherence tests: FAILED"
    FAILED_SUITES+=("subagent-coherence")
fi
echo ""

# Run launcher runtime coherence tests
echo ">>> Running launcher runtime coherence tests..."
if bash "$SCRIPT_DIR/global-opencode-runtime.sh"; then
    echo "Launcher runtime coherence tests: PASSED"
else
    echo "Launcher runtime coherence tests: FAILED"
    FAILED_SUITES+=("global-opencode-runtime")
fi
echo ""

# Run benchmarking ops tests
echo ">>> Running benchmarking ops tests..."
if bash "$SCRIPT_DIR/benchmarking-ops.sh"; then
    echo "Benchmarking ops tests: PASSED"
else
    echo "Benchmarking ops tests: FAILED"
    FAILED_SUITES+=("benchmarking-ops")
fi
echo ""

# Run executable adversarial tests
echo ">>> Running adversarial ops tests..."
if bash "$SCRIPT_DIR/adversarial-ops.sh"; then
    echo "Adversarial ops tests: PASSED"
else
    echo "Adversarial ops tests: FAILED"
    FAILED_SUITES+=("adversarial-ops")
fi
echo ""

# Run runtime simulation tests
echo ">>> Running runtime simulation tests..."
if bash "$SCRIPT_DIR/runtime-simulations.sh"; then
    echo "Runtime simulation tests: PASSED"
else
    echo "Runtime simulation tests: FAILED"
    FAILED_SUITES+=("runtime-simulations")
fi
echo ""

# Run benchmark aggregation tests
echo ">>> Running benchmark aggregation tests..."
if bash "$SCRIPT_DIR/benchmark-aggregation.sh"; then
    echo "Benchmark aggregation tests: PASSED"
else
    echo "Benchmark aggregation tests: FAILED"
    FAILED_SUITES+=("benchmark-aggregation")
fi
echo ""

# Run guardrail enforcement tests
echo ">>> Running guardrail enforcement tests..."
if bash "$SCRIPT_DIR/guardrail-enforcement.sh"; then
    echo "Guardrail enforcement tests: PASSED"
else
    echo "Guardrail enforcement tests: FAILED"
    FAILED_SUITES+=("guardrail-enforcement")
fi
echo ""

# Run discipline ops tests
echo ">>> Running discipline ops tests..."
if bash "$SCRIPT_DIR/discipline-ops.sh"; then
    echo "Discipline ops tests: PASSED"
else
    echo "Discipline ops tests: FAILED"
    FAILED_SUITES+=("discipline-ops")
fi
echo ""

echo "=========================================="
echo "Full suite complete"
if [ ${#FAILED_SUITES[@]} -gt 0 ]; then
    echo -e "\033[0;31mFAILED SUITES: ${FAILED_SUITES[*]}\033[0m"
    exit 1
else
    echo -e "\033[0;32mALL SUITES PASSED\033[0m"
fi
echo "=========================================="
