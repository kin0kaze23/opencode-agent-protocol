---
name: systematic-debugging
description: Rigorous hypothesis-driven debugging. Reproduce → isolate → hypothesize → test → verify → prevent. Never guess. Never "try things."
---

# Systematic Debugging Skill

> Activate for: any bug, crash, test failure, unexpected behavior, or "it's not working."
> HARD RULE: No fix until root cause is confirmed. Treating symptoms causes recurring bugs.

---

## The Protocol

### Phase 1: Reproduce (confirm the bug is real and consistent)

1. **Get exact reproduction steps** — not "it crashes sometimes." Exact inputs, exact conditions.
2. **Reproduce it yourself** — run the failing test, trigger the error, see the stack trace
3. **Capture the full error**: stack trace, error message, line numbers, request/response data
4. **Note environment**: OS, node version, env vars, dependencies, branch

If you cannot reproduce it → ask for exact reproduction steps before hypothesizing anything.

### Phase 2: Isolate (narrow the search space)

Ask these in order:
- When did this start? (last working commit vs. current)
- What changed recently? (`git log --oneline -20`, `git diff HEAD~5`)
- Is it in ALL environments or just one? (local vs. CI vs. prod)
- Is it always or only sometimes? (deterministic vs. race condition)
- Is it in one specific input or any input? (data-specific vs. code logic)

Use binary search on the codebase — git bisect if needed:
```bash
git bisect start
git bisect bad HEAD
git bisect good <last-known-good-commit>
# Test each commit until git identifies the culprit
```

### Phase 3: Hypothesize (minimum 2, maximum 3 hypotheses)

Form hypotheses BEFORE reading any code. Hypotheses force you to think before pattern-matching.

Format:
```
H1: <what you think is happening> — Evidence: <what would confirm this>
H2: <alternative explanation> — Evidence: <what would confirm this>
H3: <edge case / environment issue> — Evidence: <what would confirm this>
```

Rank by probability. Test H1 first.

### Phase 4: Test Each Hypothesis

Test hypotheses by READING and REASONING first. Only run code to confirm, not to explore.

For each hypothesis:
1. Read the relevant code section (targeted, not the whole file)
2. Trace the execution path manually
3. Identify the exact line where the hypothesis would fail
4. Add a log or assertion to confirm: `console.log('[DEBUG]', variable)` or write a minimal test

**Never add a fix before confirming the hypothesis.**

### Phase 5: Fix the Root Cause

Once root cause confirmed:
1. Write the fix as the minimal change that addresses the root cause
2. Write a test that would have caught this bug
3. Run all gates via the native OpenCode command surface: `/gates`
4. Verify the original reproduction steps no longer trigger the bug

### Phase 6: Prevent Recurrence

After fixing, promote a reusable lesson only through the native OpenCode workflow:

- Use `/promote-lesson` when the bug reveals a repeatable pattern worth retaining.

Ask: "Is there a similar bug elsewhere in the codebase?" — check related code with Grep.

---

## Common Bug Categories

| Type | First place to look |
|------|---------------------|
| Race condition | Async/await usage, Promise.all, event handlers |
| Type error | Input validation at system boundary, TypeScript `as` casts |
| Null/undefined | Optional chaining missing, missing default values |
| State mutation | Shared mutable state, missing spread operator |
| Import/module | Circular imports, missing exports, wrong paths |
| Environment | Missing env vars, different behavior in test vs prod |
| Cache | Stale data, missing cache invalidation |
| CORS/auth | Missing headers, expired tokens, wrong origin |

---

## RESULT Block Format

```
RESULT
status: COMPLETE | BLOCKED
agent: debug
root_cause: <one sentence — the actual cause, not the symptom>
fix_applied: <what was changed and where>
test_added: <file:line of new test>
gates: lint [pass/fail] typecheck [pass/fail] test [pass/fail] build [pass/fail]
lesson_logged: YES | NO
prevention: <how to avoid this class of bug in future>
blockers: <none | what the user needs to provide>
```
