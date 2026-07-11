---
name: plan-correction-discipline
description: Corrects plans after prior drift — replan, fix implementation mismatch — identifies root cause of plan/implementation mismatch and produces a corrected, implementation-ready plan.
---

# Plan Correction Discipline

Use this skill when a plan has drifted, overclaimed readiness, or mixed unrelated concerns.

## Goal

Correct the minimum necessary parts of the plan without resetting the whole project or introducing new scope.

## Procedure

Before correcting the plan, read the following:

1. Read the current `<repo>/PLAN.md` to understand the existing objective and scope
2. Read any referenced design docs or architecture notes to understand what was intended
3. Read recent git log or chat history to identify where the drift originated
4. Read the repo's `AGENTS.md` for repo-specific completion rules

Then execute the correction:

1. Identify the exact unresolved blocker — be specific about what is missing or wrong
2. Classify the blocker into one of these categories:
   - **Runtime authority** — no active entrypoint/mount path identified
   - **State model** — multi-step flow has no explicit state management strategy
   - **Contract touch list** — shape change lacks constructors, defaults, migrations, or consumers
   - **Success criteria** — outcomes are vague or untestable
   - **Summary overclaim** — plan claims more than the evidence proves
   - **Scope creep** — unrelated concerns mixed into the same phase
3. Request a narrow correction pass that closes that blocker — the smallest change that resolves the specific gap without redesigning the whole plan
4. Keep all unrelated approved scope untouched
5. Re-check implementation readiness after the correction using the Implementation Readiness Gate

## Output format

Produce a correction request in this exact format:

```
## Plan Correction

**Unresolved blocker:** <name the blocker precisely>

**Blocker category:** <runtime authority / state model / contract touch list / success criteria / summary overclaim / scope creep>

**Required correction:** <describe the narrow fix needed>

**Unchanged scope:** <confirm what stays approved and untouched>

**Next step:** <specific action to close the blocker>
```

## Out of Scope

This skill does NOT:
- Redesign the entire plan unless the baseline itself is fundamentally wrong
- Add new features or scope beyond what was originally approved
- Fix implementation bugs (that is /debug)
- Replace a /plan-feature when the objective itself needs to change
