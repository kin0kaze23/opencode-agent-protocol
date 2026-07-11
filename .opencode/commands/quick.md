---
description: "Execute quick edits (≤3 files, no sensitive paths) with lint gate only"
---

# /quick

**Mode:** Executor
**Model:** qwen3-coder-plus
**Tool access:** Layer A
**Success output:** Edit applied + committed, zero ceremony

## Behaviour

When invoked, the Owner agent:

1. Validates the request is safe to execute without planning:
   - ≤3 files to modify or create
   - No sensitive paths (auth/payment/schema/crypto/user-data)
   - Scope is crystal clear (no ambiguity about what "done" looks like)
   - No cross-repo dependencies
   - If any of these fail: redirect to `/plan-feature` instead
2. Output 6-field quick preflight:
   - Repo, Mode: QUICK, Risk score, Files, Success criteria, No plan/approval needed
3. Edit files directly
4. Run lint gate only (typecheck, test, build skipped)
5. Commit with conventional message — current branch only
6. Done — no review, no checkpoint, no approval

## When to use /quick

- You know exactly what file to change and what the change should be
- The scope is obvious (e.g., "add console.log to processUser", "update version to 1.0.1", "fix this typo")
- You don't need a plan, approval, or review
- It's too trivial for `/plan-feature` but too complex for DIRECT lane

## When NOT to use /quick

- Multiple files with unclear relationships → use `/plan-feature`
- Sensitive paths → use `/plan-feature`
- Cross-repo changes → use `/plan-feature`
- You're unsure what "done" looks like → use `/advise` first
- More than 3 files → use `/plan-feature`

## Output format

```
## Quick Edit
Repo:     <repo>
Mode:     QUICK
Risk:     <score 0-2>
Files:    <list of ≤3 files>
Success:  <one-line criteria>
Plan:     Skipped — scope is obvious

<edits applied>

lint: PASS / FAIL (exit <code>)
Commit: <hash> "<message>"
```

## Do not
- Use for changes to auth, payment, schema, or security paths
- Use when scope is ambiguous
- Use for cross-repo changes
- Skip lint gate
- Commit without verifying the edit is correct
