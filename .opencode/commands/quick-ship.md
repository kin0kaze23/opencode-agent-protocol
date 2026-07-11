---
description: "Fast PR workflow for low-risk changes — edit, lint, commit, push, PR"
---

# /quick-ship

**Mode:** Executor
**Purpose:** Fast path from edit to PR for low-risk changes. Runs Lite Mode classifier, commits, pushes, creates PR, and reports CI status.

## When to Use

- Lane is DIRECT or FAST
- Lite Mode classifier returns `allowed: yes`
- No sensitive paths touched
- No production deploy
- Owner has approved the change

## When NOT to Use

- auth, payment, schema, migration, crypto, secrets, user-data paths
- Protocol/registry/config file changes
- Production deploy config changes
- Package/lockfile changes
- HIGH-RISK lane tasks
- Multi-repo changes

## Behaviour

When invoked, the Owner agent:

1. **Verify Lite Mode eligibility:**
   ```bash
   bash .opencode/scripts/lite-mode-eligibility.sh <changed-files>
   ```
   - If `allowed: no`: stop and tell the user why. Recommend `/implement` with full controls.
   - If `allowed: yes`: continue.

2. **Run smallest relevant local gate:**
   - DIRECT: lint only
   - FAST: lint + typecheck (or per verification profile)
   - If gate fails: fix the issue, re-run. Do not skip.

2b. **Test awareness (v4.23 + v4.25):**
   - If change is copy/style-only: keep quick path, include no-test justification in PR body
   - If bug/logic behavior changes: run `bash .opencode/scripts/find-tests.sh <repo> <files>` and `bash .opencode/scripts/detect-untested.sh <repo> <files>`
   - If nearby tests found: run them, verify they pass, update if behavior changed
   - If no tests found and change is bug/logic: add focused regression test if practical
   - If no tests added: include concise no-test justification in PR body
   - Format: `Tests: not added — <specific reason>`

3. **Senior self-review (FAST only, optional for DIRECT):**
   ```bash
   bash .opencode/scripts/senior-self-review.sh
   ```
   - Read the checklist and answer honestly.
   - If any answer reveals a problem: fix before proceeding.
   - If all clear: continue.

4. **Commit with conventional message:**
   - Use GitGuard: `bash .opencode/git-guard/git-guard.sh commit -m "<message>"`
   - Current branch only.

5. **Push to remote:**
   ```bash
   bash .opencode/git-guard/git-guard.sh push origin <branch>
   ```

6. **Create PR:**
   ```bash
   gh pr create --title "<conventional title>" --body "<description>" --base main
   ```
   - PR body should be concise: what changed, why, how to verify.
   - For DIRECT: 2-3 sentences.
   - For FAST: 5-field summary (what, gates, files, next, rollback).

7. **Report PR URL and CI status:**
   ```
   PR created: <url>
   CI status: pending / running / not configured
   ```

8. **CI Repair Loop (if CI is configured and fails):**
   - Read the failing check name and logs
   - Classify failure type:
     | Failure Type | Root Cause Pattern | Fix Approach |
     |---|---|---|
     | lint | Style/formatting/import errors | Fix lint errors, run `pnpm lint` locally |
     | typecheck | Type errors, missing imports | Fix type errors, run `tsc --noEmit` locally |
     | unit test | Test assertion failure, missing mock | Fix code or update test, run targeted test locally |
     | build | Bundle error, missing dependency | Fix build config, run `pnpm build` locally |
     | dependency/install | Lockfile mismatch, missing package | Update lockfile, run `pnpm install` |
     | flaky/infra | Network timeout, service unavailable | Retry once — if same failure, escalate |
   - Identify root cause from logs
   - Make the smallest fix that resolves the failure
   - Run the failing command locally if possible to verify the fix
   - Commit and push the fix
   - Wait for CI to re-run
   - If CI fails again with the same root cause: stop and escalate to user
   - If CI fails with a different root cause: fix and retry (max 2 repair cycles)
   - Summarize: what failed, what was the fix, is it resolved

9. **Update NOW.md only if project state meaningfully changed.**

## CI Repair Loop Rules

- Maximum 2 repair cycles per PR
- Each cycle: read logs → diagnose → fix → push → wait
- If the same root cause recurs after a fix: stop, escalate to user
- If a new root cause appears: fix and retry
- Never disable tests or linting to make CI pass
- Never commit with `--no-verify`
- Document each failure and fix in the PR description or a comment

## Output Format

```
Quick-ship: <repo>
Lite Mode: allowed / blocked (<reason>)
Gate: lint PASS / FAIL
PR: <url>
CI: pending / passing / failed (<check name>)
Repair cycles: 0 / 1 / 2
Summary: <one paragraph>
```

## Do Not

- Use quick-ship for sensitive path changes
- Skip the Lite Mode classifier
- Create PRs with failing local gates
- Disable CI checks to make PRs pass
- Exceed 2 CI repair cycles without escalating
- Use `--force` or `--no-verify`
