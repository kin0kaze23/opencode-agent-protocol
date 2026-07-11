#!/usr/bin/env bash
# GitGuard Execution Wrapper
# Intercepts unsafe git commands and denies them with clear messages.
#
# This is a PROTOCOL-ENFORCED wrapper. The OpenCode Owner Agent is bound by
# protocol (.opencode/commands/git-guard.md) to use this wrapper for all
# mutating git operations. It provides defense-in-depth alongside the
# pre-push hook (.opencode/git-guard/pre-push-hook.sh).
#
# Usage:
#   bash .opencode/git-guard/git-guard.sh <git-command> [args...]
#   bash .opencode/git-guard/git-guard.sh commit -m "fix bug"
#   bash .opencode/git-guard/git-guard.sh push origin feat/my-branch
#
# Exit codes:
#   0 — Command allowed and executed successfully
#   1 — Command denied (unsafe pattern detected)
#   2 — Command allowed but execution failed (git error, not a guard issue)
#   3 — Override applied (unsafe command executed with explicit override)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
OVERRIDE_LOG="$SCRIPT_DIR/override-log.jsonl"

# Protected branches
PROTECTED_BRANCHES="main master"

# ============================================================
# Override mechanism
# ============================================================
check_override() {
    # Look for override file in current working directory (where the command runs)
    local override_file="./.gitguard-override"

    if [ -f "$override_file" ]; then
        local reason
        reason=$(cat "$override_file")
        if [ -n "$reason" ]; then
            # Log the override
            local timestamp
            timestamp=$(date -Iseconds)
            local cmd="$*"
            echo "{\"timestamp\":\"$timestamp\",\"command\":\"$cmd\",\"reason\":\"$reason\"}" >> "$OVERRIDE_LOG"
            echo "⚠ OVERRIDE APPLIED"
            echo "Reason: $reason"
            echo "Logged to: $OVERRIDE_LOG"
            echo ""
            # Remove the override file after use (one-time use)
            rm -f "$override_file"
            return 0
        fi
    fi
    return 1
}

# ============================================================
# Pattern detection
# ============================================================
detect_unsafe_patterns() {
    local cmd="$1"
    shift
    local args=("$@")
    local full_cmd="git $cmd ${args[*]:-}"

    # If no args, nothing to check
    if [ ${#args[@]} -eq 0 ]; then
        return 0
    fi

    # Check for --no-verify / -n on commit
    if [ "$cmd" = "commit" ]; then
        for arg in "${args[@]}"; do
            if [ "$arg" = "--no-verify" ] || [ "$arg" = "-n" ]; then
                echo "DENIED: Pre-commit hook bypass detected."
                echo ""
                echo "Command: $full_cmd"
                echo "Reason: --no-verify skips pre-commit hooks (linting, secret scanning, formatting)."
                echo "        This allows broken or insecure code to enter the repository."
                echo ""
                echo "Safer alternatives:"
                echo "  git commit -m \"message\"              (fix the lint error first)"
                echo "  git commit --amend                     (fix the last commit)"
                echo ""
                echo "Override: Create .gitguard-override with a stated reason, then retry."
                echo "  echo \"Emergency: production hotfix\" > .gitguard-override"
                echo "  bash .opencode/git-guard/git-guard.sh $cmd ${args[*]}"
                return 1
            fi
        done
    fi

    # Check for --force / -f on push
    if [ "$cmd" = "push" ]; then
        local has_force=false
        local target_branch=""

        for arg in "${args[@]}"; do
            if [ "$arg" = "--force" ] || [ "$arg" = "-f" ]; then
                has_force=true
            fi
            # Detect refspec patterns like HEAD:main or HEAD:master
            if [[ "$arg" == *":main" ]] || [[ "$arg" == *":master" ]]; then
                target_branch="${arg##*:}"
            fi
        done

        # Check for direct push to protected branches
        for arg in "${args[@]}"; do
            if [ "$arg" = "origin" ] || [ "$arg" = "upstream" ]; then
                continue
            fi
            # Skip flags
            if [[ "$arg" == -* ]]; then
                continue
            fi
            # Check if this is a branch name (not a refspec)
            if [[ "$arg" != *":"* ]]; then
                for branch in $PROTECTED_BRANCHES; do
                    if [ "$arg" = "$branch" ]; then
                        echo "DENIED: Direct push to protected branch detected."
                        echo ""
                        echo "Command: $full_cmd"
                        echo "Branch: $arg"
                        echo "Reason: Protected branches must receive changes through pull requests only."
                        echo ""
                        echo "Safer alternatives:"
                        echo "  git push origin feat/<repo>/<task-slug>  (push to feature branch)"
                        echo "  gh pr create                              (create PR)"
                        echo ""
                        echo "Override: Create .gitguard-override with a stated reason, then retry."
                        return 1
                    fi
                done
            fi
        done

        # Check for force push
        if [ "$has_force" = true ]; then
            echo "DENIED: Force push detected."
            echo ""
            echo "Command: $full_cmd"
            echo "Reason: Force push rewrites remote history and can destroy others' work."
            echo ""
            echo "Safer alternatives:"
            echo "  git push --force-with-lease  (only if you verified no one else pushed)"
            echo "  git revert <commit>          (safe history-preserving undo)"
            echo ""
            echo "Override: Create .gitguard-override with a stated reason, then retry."
            return 1
        fi

        # Check for refspec pushing to protected branches (HEAD:main, HEAD:master)
        if [ -n "$target_branch" ]; then
            echo "DENIED: Push to protected branch via refspec detected."
            echo ""
            echo "Command: $full_cmd"
            echo "Target: $target_branch"
            echo "Reason: Protected branches must receive changes through pull requests only."
            echo ""
            echo "Safer alternatives:"
            echo "  git push origin feat/<repo>/<task-slug>"
            echo "  gh pr create"
            echo ""
            echo "Override: Create .gitguard-override with a stated reason, then retry."
            return 1
        fi
    fi

    # Check for reset --hard (destructive)
    if [ "$cmd" = "reset" ]; then
        for arg in "${args[@]}"; do
            if [ "$arg" = "--hard" ]; then
                echo "DENIED: Destructive reset detected."
                echo ""
                echo "Command: $full_cmd"
                echo "Reason: git reset --hard discards all uncommitted changes permanently."
                echo ""
                echo "Safer alternatives:"
                echo "  git stash                    (save changes for later)"
                echo "  git reset --soft <commit>    (keep changes in working tree)"
                echo "  git reset --mixed <commit>   (keep changes, unstage them)"
                echo ""
                echo "Override: Create .gitguard-override with a stated reason, then retry."
                return 1
            fi
        done
    fi

    # Check for clean -fd (destructive)
    if [ "$cmd" = "clean" ]; then
        local has_force=false
        local has_dirs=false
        for arg in "${args[@]}"; do
            if [ "$arg" = "-f" ] || [ "$arg" = "--force" ]; then
                has_force=true
            fi
            if [ "$arg" = "-d" ]; then
                has_dirs=true
            fi
            # Handle combined flags like -fd or -df
            if [[ "$arg" == -* ]] && [[ "$arg" != --* ]]; then
                if [[ "$arg" == *f* ]]; then
                    has_force=true
                fi
                if [[ "$arg" == *d* ]]; then
                    has_dirs=true
                fi
            fi
        done
        if [ "$has_force" = true ] && [ "$has_dirs" = true ]; then
            echo "DENIED: Destructive clean detected."
            echo ""
            echo "Command: $full_cmd"
            echo "Reason: git clean -fd permanently removes untracked files and directories."
            echo ""
            echo "Safer alternatives:"
            echo "  git clean -n              (dry run — see what would be deleted)"
            echo "  git clean -fd --dry-run   (dry run with directories)"
            echo ""
            echo "Override: Create .gitguard-override with a stated reason, then retry."
            return 1
        fi
    fi

    return 0
}

# ============================================================
# Main execution
# ============================================================
if [ $# -lt 1 ]; then
    echo "Usage: $0 <git-command> [args...]"
    echo ""
    echo "Examples:"
    echo "  $0 commit -m \"fix bug\""
    echo "  $0 push origin feat/my-branch"
    echo "  $0 status"
    exit 0
fi

GIT_CMD="$1"
shift
GIT_ARGS=("$@")

# Read-only commands pass through without checking
case "$GIT_CMD" in
    status|log|diff|show|branch|tag|remote|fetch|clone|init|describe|rev-parse|rev-list|ls-remote|shortlog|blame|grep|reflog)
        if [ ${#GIT_ARGS[@]} -gt 0 ]; then
            git "$GIT_CMD" "${GIT_ARGS[@]}"
        else
            git "$GIT_CMD"
        fi
        exit $?
        ;;
esac

# Check for unsafe patterns
if [ ${#GIT_ARGS[@]} -gt 0 ]; then
    if ! detect_unsafe_patterns "$GIT_CMD" "${GIT_ARGS[@]}"; then
        # Check for override
        if check_override "$GIT_CMD" "${GIT_ARGS[@]}"; then
            echo "Executing with override..."
            git "$GIT_CMD" "${GIT_ARGS[@]}"
            exit 3
        fi
        exit 1
    fi
fi

# Command is safe — execute it
if [ ${#GIT_ARGS[@]} -gt 0 ]; then
    git "$GIT_CMD" "${GIT_ARGS[@]}"
else
    git "$GIT_CMD"
fi
exit $?
