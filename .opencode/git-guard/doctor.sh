#!/usr/bin/env bash
# GitGuard Doctor — Repo Protection Health Check
# Checks repo-level GitGuard configuration and reports PASS/WARN/FAIL.
#
# Usage:
#   bash .opencode/git-guard/doctor.sh              (all repos)
#   bash .opencode/git-guard/doctor.sh sample-service (specific repo)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CANONICAL_HOOK="$SCRIPT_DIR/pre-push-hook.sh"
WRAPPER="$SCRIPT_DIR/git-guard.sh"
OVERRIDE_LOG="$SCRIPT_DIR/override-log.jsonl"

# Repo list (synced with .opencode/registry.yaml on 2026-04-04)
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
    # Missing from disk — kept for reference, doctor will SKIP
    ClearPathOS
    ImagineHub
    example-cli
    example-toolchain
    AgentMonitor
    CryptoDerivative
)

if [ $# -gt 0 ]; then
    REPOS=("$@")
else
    REPOS=("${ALL_REPOS[@]}")
fi

echo "=========================================="
echo "GitGuard Doctor — Repo Protection Health"
echo "=========================================="
echo "Date: $(date -Iseconds)"
echo ""

# ============================================================
# Global checks (workspace-level)
# ============================================================
echo "── Global Checks ──────────────────────────"

# G-001: Wrapper exists and is executable
if [ -f "$WRAPPER" ] && [ -x "$WRAPPER" ]; then
    echo "  PASS  Wrapper script exists and is executable"
else
    echo "  FAIL  Wrapper script missing or not executable: $WRAPPER"
fi

# G-002: Canonical hook exists
if [ -f "$CANONICAL_HOOK" ]; then
    echo "  PASS  Canonical pre-push hook exists"
else
    echo "  FAIL  Canonical pre-push hook missing: $CANONICAL_HOOK"
fi

# G-003: Command docs reference wrapper
if grep -q "git-guard.sh" "$WORKSPACE_ROOT/.opencode/commands/implement.md" 2>/dev/null && \
   grep -q "git-guard.sh" "$WORKSPACE_ROOT/.opencode/commands/ship.md" 2>/dev/null; then
    echo "  PASS  Command docs reference wrapper (/implement, /ship)"
else
    echo "  FAIL  Command docs missing wrapper references"
fi

# G-004: AGENTS.md references wrapper
if grep -q "git-guard.sh" "$WORKSPACE_ROOT/.opencode/AGENTS.md" 2>/dev/null; then
    echo "  PASS  AGENTS.md references wrapper"
else
    echo "  WARN  AGENTS.md missing wrapper reference"
fi

# G-005: Override log status
if [ -f "$OVERRIDE_LOG" ]; then
    override_count=$(wc -l < "$OVERRIDE_LOG")
    if [ "$override_count" -eq 0 ]; then
        echo "  PASS  Override log exists (empty — no overrides used)"
    else
        echo "  WARN  Override log has $override_count entries (review recommended)"
    fi
else
    echo "  PASS  No override log (no overrides have been used)"
fi

echo ""

# ============================================================
# Per-repo checks
# ============================================================
echo "── Per-Repo Checks ────────────────────────"
printf "  %-30s %-8s %-8s %-8s %-8s %s\n" "REPO" ".git" "HOOK" "NOW.md" "PLAN" "NOTES"
printf "  %-30s %-8s %-8s %-8s %-8s %s\n" "----" "----" "----" "----" "----" "-----"

for repo in "${REPOS[@]}"; do
    REPO_PATH="$WORKSPACE_ROOT/$repo"
    GIT_DIR="$REPO_PATH/.git"
    HOOK_TARGET="$GIT_DIR/hooks/pre-push"
    NOW_MD="$REPO_PATH/NOW.md"
    PLAN_MD="$REPO_PATH/PLAN.md"

    notes=""

    # Check .git
    if [ -d "$GIT_DIR" ]; then
        git_status="PASS"
    else
        git_status="SKIP"
        notes="No .git directory"
    fi

    # Check hook
    if [ -d "$GIT_DIR" ]; then
        if [ -f "$HOOK_TARGET" ]; then
            if diff -q "$CANONICAL_HOOK" "$HOOK_TARGET" >/dev/null 2>&1; then
                hook_status="PASS"
            else
                hook_status="WARN"
                notes="${notes:+$notes; }Hook differs from canonical"
            fi
        else
            hook_status="FAIL"
            notes="${notes:+$notes; }Hook missing"
        fi
    else
        hook_status="SKIP"
    fi

    # Check NOW.md
    if [ -f "$NOW_MD" ]; then
        now_status="PASS"
        # Check for active/blocked state
        if grep -q "status:.*active\|status:.*blocked" "$NOW_MD" 2>/dev/null; then
            notes="${notes:+$notes; }NOW.md shows active/blocked work"
        fi
    else
        now_status="WARN"
        notes="${notes:+$notes; }NOW.md missing"
    fi

    # Check PLAN.md
    if [ -f "$PLAN_MD" ]; then
        plan_status="PASS"
        if grep -q "PENDING USER REVIEW" "$PLAN_MD" 2>/dev/null; then
            notes="${notes:+$notes; }PLAN.md pending review"
        fi
    else
        plan_status="—"
    fi

    printf "  %-30s %-8s %-8s %-8s %-8s %s\n" "$repo" "$git_status" "$hook_status" "$now_status" "$plan_status" "$notes"
done

echo ""

# ============================================================
# Summary
# ============================================================
echo "=========================================="
echo "Doctor Summary"
echo "=========================================="

# Count repo-level issues
hook_pass=0
hook_warn=0
hook_fail=0
now_pass=0
now_warn=0

for repo in "${REPOS[@]}"; do
    REPO_PATH="$WORKSPACE_ROOT/$repo"
    GIT_DIR="$REPO_PATH/.git"
    HOOK_TARGET="$GIT_DIR/hooks/pre-push"
    NOW_MD="$REPO_PATH/NOW.md"

    if [ -d "$GIT_DIR" ]; then
        if [ -f "$HOOK_TARGET" ]; then
            if diff -q "$CANONICAL_HOOK" "$HOOK_TARGET" >/dev/null 2>&1; then
                hook_pass=$((hook_pass + 1))
            else
                hook_warn=$((hook_warn + 1))
            fi
        else
            hook_fail=$((hook_fail + 1))
        fi
    fi

    if [ -f "$NOW_MD" ]; then
        now_pass=$((now_pass + 1))
    else
        now_warn=$((now_warn + 1))
    fi
done

echo "Hooks: $hook_pass PASS, $hook_warn WARN, $hook_fail FAIL"
echo "NOW.md: $now_pass present, $now_warn missing"

if [ "$hook_fail" -gt 0 ]; then
    echo ""
    echo "⚠ REMEDIATION: Run repair to fix missing hooks"
    echo "  bash .opencode/git-guard/repair-hooks.sh"
elif [ "$hook_warn" -gt 0 ]; then
    echo ""
    echo "⚠ REMEDIATION: Run repair to update stale hooks"
    echo "  bash .opencode/git-guard/repair-hooks.sh"
else
    echo ""
    echo "✓ All repos with .git directories have current GitGuard hooks."
fi
