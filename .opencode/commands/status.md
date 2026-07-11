---
description: "Display repository and protocol status"
---

# /status

**Purpose:** Read current repo state without modifying it
**Mode:** Any
**Model:** qwen3.7-plus (v1.1-production, Action 4D)
**Tool access:** Layer A (reads NOW.md, legacy PHASE_STATE.md when needed, AGENTS.md, git log)
**Success output:** Structured current state block

## Behaviour

When invoked, the Owner agent:

1. Reads the active repo's `NOW.md` (canonical state)
   - If `NOW.md` is missing but `PHASE_STATE.md` exists: read `PHASE_STATE.md` as a legacy fallback and say so in the output
   - Vault `status.md` is NOT read — it is non-authoritative
2. Reads the active repo's `AGENTS.md` for repo-specific completion context
3. Reads `git log --oneline -10` for recent activity
4. Outputs a structured state block

## Difference from /checkpoint

/status = read current state (no writes)
/checkpoint = save current state to NOW.md (writes)

## Output format

```
## Status — <repo> — <date>

Protocol: OpenCode v4.3

State source: NOW.md / legacy PHASE_STATE.md

Task:     <current task or "No active task">
Status:   active / paused / blocked / complete
Blockers: <list or "None">

Derived State:
  - isBlocked: <true/false>
  - isReady: <true/false>
  - needsReview: <true/false>
  - canShip: <true/false or n/a>

Recent commits:
  <hash> <message>
  <hash> <message>

Next steps:
  1. <step>
  2. <step>
```

## Derived State Computation Rules

| Selector | Computation |
|----------|-------------|
| `isBlocked` | `true` if status === 'blocked' OR blockers.length > 0 |
| `isReady` | `true` if status === 'active' AND PLAN.md exists with status 'APPROVED' |
| `needsReview` | `true` if riskScore >= 4 OR touchList.length >= 4 (from PLAN.md) |
| `canShip` | `true` if gatesPassed AND reviewerVerdict !== 'Requires changes' AND no Critical findings |

### Computation Notes

- Derived state is **computed at read time**, not stored
- If PLAN.md is missing, `isReady` = false, `needsReview` = false, `canShip` = n/a
- If gates have not been run, `canShip` = n/a
- Deterministic: same inputs always produce same derived state
