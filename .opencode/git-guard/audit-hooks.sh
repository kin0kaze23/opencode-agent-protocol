#!/usr/bin/env bash
# GitGuard Hook Auditor
# Reports hook installation status across all managed repos.
#
# Usage:
#   bash .opencode/git-guard/audit-hooks.sh
#   bash .opencode/git-guard/audit-hooks.sh sample-service StableVault  (specific repos)
#
# Output: PASS/WARN/FAIL per repo + summary

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CANONICAL_HOOK="$SCRIPT_DIR/pre-push-hook.sh"

# Repo list from WORKSPACE_MAP.md
ALL_REPOS=(
    sample-service
    ClearPathOS
    example-app
    demo-project
    Pulse
    StableVault
    example-analyzer
    example-dashboard
    ImagineHub
    example-cli
    example-toolchain
    example-toolchainMissionControl
    AgentMonitor
    CryptoDerivative
    example-orchestratorNuggie
)

# If specific repos provided, use those instead
if [ $# -gt 0 ]; then
    REPOS=("$@")
else
    REPOS=("${ALL_REPOS[@]}")
fi

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

echo "=========================================="
echo "GitGuard Hook Audit"
echo "=========================================="
echo "Date: $(date -Iseconds)"
echo "Canonical source: $CANONICAL_HOOK"
echo ""

# Verify canonical source exists
if [ ! -f "$CANONICAL_HOOK" ]; then
    echo "ERROR: Canonical hook not found at $CANONICAL_HOOK"
    exit 1
fi

printf "%-30s %-10s %s\n" "REPO" "STATUS" "DETAILS"
printf "%-30s %-10s %s\n" "----" "------" "-------"

for repo in "${REPOS[@]}"; do
    REPO_PATH="$WORKSPACE_ROOT/$repo"
    GIT_DIR="$REPO_PATH/.git"
    HOOK_TARGET="$GIT_DIR/hooks/pre-push"

    if [ ! -d "$GIT_DIR" ]; then
        printf "%-30s %-10s %s\n" "$repo" "SKIP" "No .git directory"
        ((SKIP_COUNT++))
        continue
    fi

    if [ ! -f "$HOOK_TARGET" ]; then
        printf "%-30s %-10s %s\n" "$repo" "FAIL" "Hook missing"
        ((FAIL_COUNT++))
        continue
    fi

    # Check if hook matches canonical source
    if diff -q "$CANONICAL_HOOK" "$HOOK_TARGET" >/dev/null 2>&1; then
        printf "%-30s %-10s %s\n" "$repo" "PASS" "Up to date"
        ((PASS_COUNT++))
    else
        # Check if it's a legacy hook (has the old signature)
        if grep -q "PROTECTED_BRANCHES" "$HOOK_TARGET" 2>/dev/null; then
            printf "%-30s %-10s %s\n" "$repo" "WARN" "Legacy hook (needs update)"
            ((WARN_COUNT++))
        else
            printf "%-30s %-10s %s\n" "$repo" "WARN" "Unknown hook content"
            ((WARN_COUNT++))
        fi
    fi
done

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
printf "PASS:  %d\n" "$PASS_COUNT"
printf "WARN:  %d\n" "$WARN_COUNT"
printf "FAIL:  %d\n" "$FAIL_COUNT"
printf "SKIP:  %d\n" "$SKIP_COUNT"
printf "TOTAL: %d\n" "${#REPOS[@]}"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "Action needed: Run repair to install missing hooks"
    echo "  bash .opencode/git-guard/repair-hooks.sh"
elif [ "$WARN_COUNT" -gt 0 ]; then
    echo "Action recommended: Run repair to update legacy hooks"
    echo "  bash .opencode/git-guard/repair-hooks.sh"
else
    echo "All repos with .git directories have the GitGuard hook installed."
fi
