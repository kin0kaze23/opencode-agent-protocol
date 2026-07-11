---
name: implementation-readiness-gate
description: Validates that a plan or plan-correction artifact meets all readiness conditions before implementation — runtime authority, state model, touch list completeness, success criteria, and out-of-scope.
---

# Implementation Readiness Gate

Use this skill before calling any phase `implementation-ready`.

## Procedure

Before running the gate, read the following:

1. Read the active `<repo>/PLAN.md` to load the current objective, touch list, and success criteria
2. Read the repo's `AGENTS.md` for repo-specific completion rules
3. If a verification profile is declared, read the relevant gate commands from the repo's config
4. Read any referenced design docs or architecture notes linked in the plan

Verify all of these conditions are explicit in the plan:

1. **Active runtime authority** — the exact entrypoint, mount path, router, or lazy import that proves which implementation is live
2. **State model** — for stateful or multi-step flows: direct-to-model writes vs draft object vs reducer/state machine
3. **Full contract touch list** — for shape changes: constructors, defaults, migrations, helper builders/adapters, tests, and runtime consumers
4. **Observable success criteria** — testable outcomes with clear pass/fail conditions
5. **Clear out-of-scope list** — what is explicitly not part of this phase

## Output format

Return a gate verdict in this exact format:

```
## Implementation Readiness Gate

**Verdict:** Implementation-ready / Needs correction

### Gate checks
- Runtime authority: <explicit / missing — <details if missing>>
- State model: <explicit / N/A / missing — <details if missing>>
- Contract touch list: <complete / N/A / incomplete — <details if incomplete>>
- Success criteria: <testable / vague — <details if vague>>
- Out-of-scope: <defined / missing>

### Blockers (if any)
- <blocker 1>
- <blocker 2>
```

## Failure rule

If one blocker is fixed but a dependent blocker remains, do not promote the phase out of `plan-correction`.

## Out of Scope

This skill does NOT:
- Fix missing conditions (that is /plan-feature or plan-correction)
- Run quality gates (that is /gates)
- Implement the plan (that is /implement)
- Approve plans that look good but lack explicit runtime authority or state model
