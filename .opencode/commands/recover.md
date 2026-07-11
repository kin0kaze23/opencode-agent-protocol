---
description: "Re-anchor a drifted session on original goals and current reality"
---

# /recover

**Purpose:** Re-anchor a drifted session on original goals and current reality
**Mode:** Mentor
**Model:** qwen3.7-plus (v1.1-production, Action 4D)
**Tool access:** Layer A (read-only)
**Success output:** Recovery plan with clear next action

## Behaviour

When invoked, the Owner agent:

1. Recovers session context:
   - Original goal (from PLAN.md, NOW.md, or chat history)
   - Current state (git status, recent changes, chat summary)
   - What has actually been completed (evidence, not assertions)
   - What remains (gap between current and complete)
2. Identifies contradictions:
   - Plan vs implementation mismatches
   - Scope changes not documented
   - Decisions made that changed direction
3. Determines whether original plan is still valid:
   - Yes: Continue with original plan
   - No: Document what changed and why
4. Recommends best next move:
   - Continue (original plan still valid)
   - Pivot (new direction needed)
   - Stop (goal achieved or no longer valuable)

## Output format

```
## Session Recovery — <repo> — <date>

Original goal: <from PLAN.md/NOW.md/chat>

Current state:
- Git status: <clean/dirty/branch>
- Recent changes: <summary>
- Last completed: <evidence>

Completed (verified):
- <item> (evidence: test/gate/commit)
- <item> (evidence: test/gate/commit)

Remaining:
- <item> (gap from original goal)
- <item> (gap from original goal)

Contradictions found:
- <plan vs implementation mismatch>
- <scope change not documented>
- <decision that changed direction>

Plan validity:
- Original plan still valid: yes/no
- What changed: <if no>
- Why it changed: <if no>

Recommended next action: Continue / Pivot / Stop
Reasoning: <why this action>
```

## When to use

- Session context feels lost or confused
- After long break (days/weeks)
- When plan diverged from implementation
- When user asks "where were we?" or "what's left?"
- Before continuing a blocked task

## When NOT to use

- Fresh session with clear context — use `/init` or start directly
- Mid-task with clear next step — just continue
- When NOW.md and PLAN.md are current and coherent — use `/status`

## Protocol alignment

- Reads canonical NOW.md and PLAN.md per ADR-001
- Supports compaction continuity from `/checkpoint`
- Feeds into `/plan-feature` if pivot needed
- Complements `/status` (state reading) with recovery logic
