---
name: contract-touchlist-audit
description: Audits type change, interface, schema, and profile contract changes for completeness — constructors, defaults, migrations, adapters, tests, and runtime consumers.
---

# Contract Touch-List Audit

Use this skill whenever a type, interface, schema, profile contract, or other shared shape changes.

## Goal

Prevent partial contract edits that update the type definition but miss constructors, defaults, migrations, adapters, tests, or runtime consumers.

## Procedure

Before auditing, read the following:

1. Read the changed type/interface/schema definition file to understand the new shape
2. Read the existing constructors or factory functions for the shape
3. Read any migration or normalization logic that consumes the shape
4. Read 1-2 representative runtime consumers (UI components, API handlers, test fixtures)
5. Note the import/export patterns used across the codebase for this shape

For each shape change, search for and classify every touch point:

1. **Type definitions** — the primary shape declaration
2. **Constructors / factory functions** — code that creates instances of the shape
3. **Default objects / initial state** — fallback or seed values matching the shape
4. **Migrations / normalization paths** — code that transforms old shapes to new
5. **Helper builders / adapters / transformers** — utilities that construct or convert the shape
6. **Route handlers / API payload builders** — endpoints that send or receive the shape
7. **Tests, fixtures, prompts, and seeded data** — test data matching the shape
8. **Runtime UI consumers / selectors / derived state** — components that read or render the shape

## Output format

Produce a structured audit report:

```
## Contract Touch-List Audit — <shape name>

**Verdict:** Touch list complete / Touch list incomplete

### Must edit now
- <file path> — <reason: constructor / default / migration / adapter / consumer>

### Audited, no change needed
- <file path> — <reason it is unaffected>

### Ambiguous, verify first
- <file path> — <what needs confirmation>
```

- If any real constructor, default, or consumer path is unaccounted for, the phase stays in `plan-correction`.
- If the touch list is complete, the plan is implementation-ready for this shape.

## Out of Scope

This skill does NOT:
- Implement the actual code changes (that is /implement)
- Run tests or verify correctness after changes (that is /gates)
- Audit unrelated files outside the shape's dependency graph
- Replace a full architectural review when the shape change is foundational
