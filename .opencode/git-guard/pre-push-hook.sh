#!/bin/bash
# GitGuard Pre-Push Hook
# Install: cp .opencode/git-guard/pre-push-hook.sh .git/hooks/pre-push && chmod +x .git/hooks/pre-push
#
# Blocks:
#   - Direct push to protected branches (main, master)
#   - Force push (detected via --force flag in git push command)
#
# This is a SECOND enforcement layer. Primary enforcement is the
# GitGuard command contract in .opencode/commands/git-guard.md

protected_branches="main master"

# Read stdin for push info (git passes this to pre-push hooks)
while read local_ref local_sha remote_ref remote_sha; do
    remote_branch=$(echo "$remote_ref" | sed 's|refs/heads/||')

    # Block direct push to protected branches
    for branch in $protected_branches; do
        if [ "$remote_branch" = "$branch" ]; then
            echo "" >&2
            echo "BLOCKED: Direct push to '$branch' is not allowed." >&2
            echo "Use a feature branch and pull request instead." >&2
            echo "" >&2
            echo "Safer alternatives:" >&2
            echo "  git push origin feat/<repo>/<task-slug>" >&2
            echo "  gh pr create" >&2
            exit 1
        fi
    done
done

exit 0
