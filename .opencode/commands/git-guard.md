---
description: "Block dangerous git operations at the command-contract level"
---

# GitGuard — Git Safety Enforcement

**Purpose:** Block dangerous git operations at the command-contract level.
**Authority:** `.opencode/commands/git-guard.md` + `.opencode/rules.md`
**Model:** qwen3.7-plus (v1.1-production, Action 4D) (Executor mode when invoked)

---

## Behaviour

GitGuard is a mandatory pre-flight check before ANY git write operation
(commit, push, branch creation, reset, rebase) executed by the Owner Agent.

It is NOT a shell hook. It is a protocol contract that the Owner Agent
MUST invoke and satisfy before executing any git write command.

---

## When GitGuard Activates

GitGuard MUST run before any of these operations:

| Operation | Risk Level | GitGuard Required |
|---|---|---|
| `git commit` | Medium | ✅ Yes |
| `git push` | High | ✅ Yes |
| `git branch -b` / `git checkout -b` | Low | ✅ Yes |
| `git reset` | High | ✅ Yes |
| `git rebase` | High | ✅ Yes |
| `git merge` | Medium | ✅ Yes |
| `git tag` | Low | ✅ Yes |
| `git status` / `git log` / `git diff` | None | ❌ No (read-only) |

---

## Blocked Operations (Hard Deny)

These operations are BLOCKED. The Owner Agent MUST refuse them and output
the denial message with the safer alternative.

### 1. Force Push

**Blocked pattern:** `git push --force`, `git push -f`, `git push --force-with-lease` (without explicit user approval)

**Denial message:**
```
BLOCKED: Force push detected.

Command: <exact command>
Reason: Force push rewrites remote history and can destroy others' work.

Safer alternatives:
  - git push --force-with-lease  (only if you verified no one else pushed)
  - git revert <commit>          (safe history-preserving undo)
  - Create a new commit that undoes the change

Override: Requires explicit user approval with stated reason.
```

### 2. Direct Push to Protected Branches

**Blocked pattern:** `git push origin main`, `git push origin master`, `git push origin main --force`

**Denial message:**
```
BLOCKED: Direct push to protected branch detected.

Command: <exact command>
Branch: <main|master>
Reason: Protected branches must receive changes through pull requests only.

Safer alternatives:
  - git push origin feat/<repo>/<task-slug>  (push to feature branch)
  - gh pr create                              (create PR from feature branch)

Override: Hotfix branches (hotfix/<repo>/<task-slug>) may push directly
with explicit user approval and a rollback note.
```

### 3. Commit with --no-verify

**Blocked pattern:** `git commit --no-verify`, `git commit -n`

**Denial message:**
```
BLOCKED: Pre-commit hook bypass detected.

Command: <exact command>
Reason: --no-verify skips pre-commit hooks (linting, secret scanning, formatting).
        This allows broken or insecure code to enter the repository.

Safer alternatives:
  - Fix the underlying lint/test failure and commit normally
  - git commit --amend (if fixing the last commit)
  - Run the failing hook manually to see the exact error

Override: Requires explicit user approval with stated reason.
          Document why the hook must be bypassed in the commit message.
```

---

## Pre-Commit Checklist (Before git commit)

Before any `git commit`, the Owner Agent MUST verify:

- [ ] Working tree is from the correct repo directory (not workspace root)
- [ ] No secrets, credentials, or API keys in staged files
- [ ] No `.env` files with real values staged (templates OK)
- [ ] Commit message follows convention (imperative, descriptive)
- [ ] If lane is STANDARD or HIGH-RISK: commit is on an isolated branch
- [ ] NOW.md is updated if this commit completes a phase

---

## Pre-Push Checklist (Before git push)

Before any `git push`, the Owner Agent MUST verify:

- [ ] GitGuard blocked-operations check passed
- [ ] Current branch is NOT main or master
- [ ] All quality gates passed (lint, typecheck, test, build)
- [ ] If lane is STANDARD or HIGH-RISK: Reviewer output reviewed
- [ ] Rollback note is present in the completion summary
- [ ] PR target branch is correct (usually main/master)

---

## Integration with Commands

### /implement
GitGuard runs implicitly at Step 10 (before commit). The Owner Agent MUST use
the execution wrapper (`.opencode/git-guard/git-guard.sh`) for all mutating git
operations. If any blocked pattern is detected, the wrapper denies the command
and outputs the denial message. The implement step stops and surfaces the denial.

### /ship
GitGuard runs at Step 7 (before PR creation). The Owner Agent MUST use the
execution wrapper for all mutating git operations. Force push, direct-main push,
and --no-verify commits are blocked at the wrapper level. The ship summary must
include a GitGuard confirmation line.

### /checkpoint
GitGuard runs when archiving PLAN.md or committing vault changes. The Owner Agent
MUST use the execution wrapper for all mutating git operations. Vault commits use
`git -C vault` — the repo directory check ensures the correct git context.

---

## Execution Wrapper (Third Layer)

The execution wrapper (`.opencode/git-guard/git-guard.sh`) provides a third
enforcement layer between the protocol contract and the pre-push hook:

| Layer | What It Does | When It Fires |
|---|---|---|
| **Protocol** (git-guard.md) | Agent must refuse blocked operations | Before any git command |
| **Wrapper** (git-guard.sh) | Script intercepts unsafe patterns before git executes | When agent uses wrapper |
| **Hook** (pre-push-hook.sh) | Git-level blocking at push time | During `git push` |

**Usage:**
```bash
# Instead of: git commit --no-verify -m "fix"
# Use:        bash .opencode/git-guard/git-guard.sh commit --no-verify -m "fix"
# Result:     DENIED with safer alternatives

# Instead of: git push --force origin main
# Use:        bash .opencode/git-guard/git-guard.sh push --force origin main
# Result:     DENIED with safer alternatives

# Safe commands pass through:
bash .opencode/git-guard/git-guard.sh status
bash .opencode/git-guard/git-guard.sh commit -m "safe commit"
bash .opencode/git-guard/git-guard.sh push origin feat/my-branch
```

**Blocked patterns:**
- `git commit --no-verify` / `git commit -n`
- `git push --force` / `git push -f`
- `git push origin main` / `git push origin master`
- `git push origin HEAD:main` / `git push origin HEAD:master`
- `git reset --hard`
- `git clean -fd`

**Override mechanism:**
Create a `.gitguard-override` file in the working directory with a stated reason.
The wrapper consumes the file after one use (one-time override) and logs it to
`.opencode/git-guard/override-log.jsonl`.

```bash
echo "Emergency: production hotfix" > .gitguard-override
bash .opencode/git-guard/git-guard.sh commit --no-verify -m "hotfix"
# Override applied, logged, and .gitguard-override removed
```

---

## Override Protocol

If a blocked operation is genuinely required:

1. User must explicitly approve with a stated reason
2. Owner Agent outputs an `OVERRIDE RECORD` block:
   ```
   OVERRIDE RECORD
   Operation: <blocked operation>
   Reason: <user-stated reason>
   Approved by: <user>
   Timestamp: <ISO date>
   Risk acknowledgment: <user confirms understanding>
   ```
3. The operation may then proceed
4. The override record is appended to the session's completion summary

Self-approval is NEVER permitted. The Owner Agent may not override
GitGuard on its own authority.

---

## Pre-Push Hook (Second Layer)

A git pre-push hook provides a second enforcement layer at the git level.
Install in each project repo:

```bash
#!/bin/bash
# .git/hooks/pre-push
# GitGuard pre-push hook — blocks force push and direct main/master push

protected_branches="main master"
current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")

# Read stdin for push info
while read local_ref local_sha remote_ref remote_sha; do
    remote_branch=$(echo "$remote_ref" | sed 's|refs/heads/||')

    # Block direct push to protected branches
    for branch in $protected_branches; do
        if [ "$remote_branch" = "$branch" ]; then
            echo "BLOCKED: Direct push to '$branch' is not allowed." >&2
            echo "Use a feature branch and pull request instead." >&2
            exit 1
        fi
    done
done

exit 0
```

Install command (run per repo):
```bash
cp .opencode/git-guard/pre-push-hook.sh .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

**Note:** The pre-push hook is a safety net. The primary enforcement is
the GitGuard command contract in this file.

---

## Do Not

- Execute any blocked git operation without going through the override protocol
- Self-approve a GitGuard override
- Skip the pre-commit or pre-push checklist
- Commit from the workspace root directory (must be inside the project repo)
- Push without verifying gates passed first
