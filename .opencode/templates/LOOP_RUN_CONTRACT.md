# Loop Run Contract

> **Purpose:** Define a bounded, auditable, cost-controlled closed-loop execution contract.
> This template makes every agent loop explicit: what outcome proves success, what scope is allowed,
> how many retries are permitted, when to stop, who verifies, and where outcomes are preserved.

---

## 1. Loop Identity

| Field | Value |
|---|---|
| **Loop name** | `<short descriptive name>` |
| **Date** | `<ISO date>` |
| **Owner** | `<who owns this loop>` |
| **Repo** | `<target repo>` |
| **Lane** | `<DIRECT / FAST / STANDARD / HIGH-RISK>` |

---

## 2. Goal

### Verified Outcome
`<one sentence: what exact outcome proves success>`

### Success Criteria
- `<observable outcome 1>`
- `<observable outcome 2>`
- `<observable outcome 3>`

### Non-Goals
- `<what this loop explicitly does NOT do>`
- `<scope exclusions>`

---

## 3. Scope

### Allowed Files
- `<path or glob pattern>`
- `<path or glob pattern>`

### Forbidden Files
- `<path or glob pattern that must NOT be touched>`
- `<sensitive paths excluded>`

### Allowed Commands
- `<command or "read-only only">`
- `<command>`

### Forbidden Actions
- `<action that must NOT be performed>`
- `<e.g., no commits, no deploys, no provider changes>`

---

## 4. Context Sources

- `<AGENTS.md / NOW.md / PLAN.md / lessons / specific docs>`
- `<which files to read before starting>`

---

## 5. Verification Gates

| Gate | Required? | Failure mode caught | Notes |
|---|---|---|---|
| lint | `<yes/no>` | `<e.g., syntax/style violations>` | |
| typecheck | `<yes/no>` | `<e.g., type contract violations>` | |
| test | `<yes/no>` | `<e.g., behavioral regressions>` | |
| build | `<yes/no>` | `<e.g., packaging/import errors>` | |
| browser | `<yes/no>` | `<e.g., runtime/console errors>` | |
| review | `<yes/no>` | `<e.g., logic/design flaws>` | |
| security | `<yes/no>` | `<e.g., auth/secret vulnerabilities>` | |
| `<other>` | `<yes/no>` | `<specific failure mode>` | |

---

## 6. Retry Policy

### Max Attempts
`<number>`

### Per-Gate Retry Rule
`<e.g., "exactly one retry per gate, then stop">`

### Same-Failure Stop Rule
`<e.g., "if same gate fails twice with same root cause, stop and escalate">`

---

## 7. Budget Limits

| Limit | Value |
|---|---|
| **Max helper calls** | `<number>` |
| **Max files inspected** | `<number>` |
| **Max commands run** | `<number>` |
| **Max touch-list expansions** | `<number>` |
| **Max context expansion** | `<number of lines or "bounded">` |

---

## 8. Stop Conditions

Stop the loop when ANY of these are true:

- `<condition 1: e.g., "success criteria met">`
- `<condition 2: e.g., "retry budget exhausted">`
- `<condition 3: e.g., "same failure recurs twice">`
- `<condition 4: e.g., "touch-list expansion needed without approval">`
- `<condition 5: e.g., "verification cannot be run">`
- `<condition 6: e.g., "dirty workspace creates conflict risk">`

---

## 9. Escalation Boundary

Escalate to `<Owner / Reviewer / Architect / user>` when:

- `<trigger 1: e.g., "risk score 4+">`
- `<trigger 2: e.g., "sensitive paths touched">`
- `<trigger 3: e.g., "auth/security/payment/data/secrets changes">`
- `<trigger 4: e.g., "4+ changed files">`
- `<trigger 5: e.g., "release/ship gates in scope">`
- `<trigger 6: e.g., "implementation quality unclear after gates">`
- `<trigger 7: e.g., "explicit owner request">`

---

## 10. Rollback Path

| Field | Value |
|---|---|
| **Type** | `<revert-commit / discard-working-tree / drop-branch / disable-flag / restore-deployment / other>` |
| **Scope** | `<what is being reversed or disabled>` |
| **Preconditions** | `<what must be true first>` |
| **Action** | `<exact command or operator action>` |
| **Verify** | `<how rollback success is confirmed>` |

---

## 11. Loop Ledger

Record each attempt:

### Attempt `<N>`

| Field | Value |
|---|---|
| **Hypothesis** | `<what was expected>` |
| **Action** | `<what was done>` |
| **Result** | `<what happened>` |
| **Gate outcome** | `<PASS / FAIL / NOT_RUN>` |
| **Decision** | `<continue / stop / escalate>` |

---

## 12. Memory Update Target

After loop completion, update:

- `<NOW.md / PLAN.md / vault lessons / checkpoint only>`
- `<which files to preserve outcomes in>`

---

## 13. Final Evidence Requirement

Before claiming completion, provide:

- `<evidence 1: e.g., "gate results">`
- `<evidence 2: e.g., "browser screenshot">`
- `<evidence 3: e.g., "test output">`
- `<evidence 4: e.g., "traceability verification">`

---

## 14. Completion Checklist

- [ ] Goal achieved (verified outcome matches success criteria)
- [ ] All required gates passed
- [ ] Retry budget respected
- [ ] Budget limits respected
- [ ] Stop conditions evaluated
- [ ] Escalation boundary respected
- [ ] Rollback path documented
- [ ] Loop ledger complete
- [ ] Memory updated
- [ ] Final evidence provided
- [ ] No forbidden files touched
- [ ] No forbidden actions performed
- [ ] Completion summary written

---

## Usage Notes

- This template is **not wired into command behavior yet**.
- It is a standalone reference for future bounded closed-loop work.
- When used, copy this template and fill in all fields before starting the loop.
- The loop should stop if any stop condition is met, regardless of progress.
- The loop should escalate if any escalation boundary is crossed.
- The loop should preserve outcomes in the memory update target.

---

## Version

- **Template version:** 1.0.0
- **Created:** `<ISO date>`
- **Status:** Template-only, no enforcement
