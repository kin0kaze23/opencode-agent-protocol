#!/bin/bash
# OpenCode Conformance Pre-Commit Hook (Tier 1)
# Purpose: Block commits that introduce configuration authority drift
# Tier 1 guards: config-authority, prompt-mirror, repo-exception, mcp-policy
#
# Installation:
#   ln -s ../../.opencode/hooks/pre-commit-conformance.sh .git/hooks/pre-commit
#
# Emergency bypass (requires follow-up conformance):
#   git commit --no-verify
#
# This hook runs fast checks (~2.5s) that protect against the most dangerous drift:
# - Global/workspace authority changes
# - Prompt desync
# - Unapproved repo-level config
# - MCP policy drift

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GUARD_DIR="$WORKSPACE_ROOT/.opencode/conformance/tests"

START_TIME=$(date +%s%N)

echo "🔍 Running OpenCode conformance checks (Tier 1)..."

FAIL_COUNT=0
GUARDS_RUN=0

# Tier 1 guards
TIER1_GUARDS=(
    "config-authority-guard"
    "prompt-mirror-drift"
    "repo-exception-guard"
    "mcp-policy-guard"
)

for guard in "${TIER1_GUARDS[@]}"; do
    GUARDS_RUN=$((GUARDS_RUN + 1))
    echo "  Running $guard..."

    if ! bash "$GUARD_DIR/${guard}.sh" --mode audit > /tmp/opencode-${guard}.log 2>&1; then
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "  ❌ $guard FAILED"
        echo "  See /tmp/opencode-${guard}.log for details"
    else
        # Check for FAIL in output even if script exits 0
        if grep -q "FAIL: [1-9]" /tmp/opencode-${guard}.log 2>/dev/null; then
            FAIL_COUNT=$((FAIL_COUNT + 1))
            echo "  ❌ $guard FAILED (found FAIL in output)"
            echo "  See /tmp/opencode-${guard}.log for details"
        else
            echo "  ✅ $guard PASSED"
        fi
    fi
done

echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "🚫 COMMIT BLOCKED: $FAIL_COUNT/$GUARDS_RUN conformance checks failed"
    echo ""
    echo "To bypass (requires follow-up conformance):"
    echo "  git commit --no-verify -m \"your message\""
    echo ""
    echo "Then run full conformance manually:"
    echo "  bash .opencode/scripts/workspace-protocol-guard.sh"
    echo ""

    # Capture metrics (non-blocking)
    bash "$WORKSPACE_ROOT/.opencode/metrics/capture.sh" \
        --task_type conformance \
        --status fail \
        --latency_ms $(( ( $(date +%s%N) - START_TIME ) / 1000000 )) \
        --error_category conformance_failure \
        --conformance_status "$FAIL_COUNT/$GUARDS_RUN failed" 2>/dev/null || true

    exit 1
else
    echo "✅ All $GUARDS_RUN conformance checks passed"

    # Capture metrics (non-blocking)
    bash "$WORKSPACE_ROOT/.opencode/metrics/capture.sh" \
        --task_type conformance \
        --status success \
        --latency_ms $(( ( $(date +%s%N) - START_TIME ) / 1000000 )) \
        --conformance_status "0/$GUARDS_RUN failed" 2>/dev/null || true

    exit 0
fi
