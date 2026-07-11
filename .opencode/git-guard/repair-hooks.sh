#!/usr/bin/env bash
# GitGuard Hook Repair
# Installs or updates the pre-push hook in selected repos or all repos.
# Idempotent: skips repos that already have the up-to-date hook.
#
# Usage:
#   bash .opencode/git-guard/repair-hooks.sh              (all repos)
#   bash .opencode/git-guard/repair-hooks.sh sample-service (specific repo)
#   bash .opencode/git-guard/repair-hooks.sh sample-service StableVault (multiple repos)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
INSTALL_SCRIPT="$SCRIPT_DIR/install-hook.sh"

# Repo list from .opencode/registry.yaml (synced 2026-04-04)
ALL_REPOS=(
    sample-service
    example-app
    example-app-sandbox
    demo-project
    Pulse
    StableVault
    example-analyzer
    example-dashboard
    example-toolchainMissionControl
    example-orchestratorNuggie
    example-toolchain-DEV
    Openclaw-PROD
    Openclaw-STAGE
    ProjectTracker
    example-agent
    # Missing from disk — kept for reference
    ClearPathOS
    ImagineHub
    example-cli
    example-toolchain
    AgentMonitor
    CryptoDerivative
)

# If specific repos provided, use those instead
if [ $# -gt 0 ]; then
    REPOS=("$@")
else
    REPOS=("${ALL_REPOS[@]}")
fi

INSTALLED=0
UPDATED=0
SKIPPED=0
ERRORS=0

echo "=========================================="
echo "GitGuard Hook Repair"
echo "=========================================="
echo "Date: $(date -Iseconds)"
echo "Target repos: ${#REPOS[@]}"
echo ""

# Verify install script exists
if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "ERROR: Install script not found at $INSTALL_SCRIPT"
    exit 1
fi

for repo in "${REPOS[@]}"; do
    REPO_PATH="$WORKSPACE_ROOT/$repo"

    if [ ! -d "$REPO_PATH" ]; then
        echo "SKIP: $repo — directory not found"
        ((SKIPPED++))
        continue
    fi

    # Run the install script (idempotent)
    output=$(bash "$INSTALL_SCRIPT" "$repo" 2>&1) || {
        echo "ERROR: $repo — installation failed"
        echo "  $output"
        ((ERRORS++))
        continue
    }

    if echo "$output" | grep -q "^OK:"; then
        ((SKIPPED++))
    elif echo "$output" | grep -q "^UPDATE:"; then
        ((UPDATED++))
    elif echo "$output" | grep -q "^INSTALL:"; then
        ((INSTALLED++))
    elif echo "$output" | grep -q "^SKIP:"; then
        ((SKIPPED++))
    elif echo "$output" | grep -q "^DONE:"; then
        # Could be install or update — check which
        if echo "$output" | grep -q "no pre-push hook found"; then
            ((INSTALLED++))
        else
            ((UPDATED++))
        fi
    else
        echo "UNKNOWN: $repo — unexpected output: $output"
        ((ERRORS++))
    fi

    echo "  $output"
done

echo ""
echo "=========================================="
echo "Repair Summary"
echo "=========================================="
printf "Installed (new): %d\n" "$INSTALLED"
printf "Updated (legacy): %d\n" "$UPDATED"
printf "Skipped (current): %d\n" "$SKIPPED"
printf "Errors: %d\n" "$ERRORS"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    echo "Some repos had errors. Review output above."
    exit 1
else
    echo "Repair complete. All accessible repos have the GitGuard hook."
fi
