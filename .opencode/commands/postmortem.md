---
description: "Capture a reusable lesson after a failure or misstep"
---

# /postmortem

**Purpose:** Capture a reusable lesson after a failure or misstep
**Mode:** Mentor
**Model:** qwen3.7-plus (v1.1-production, Action 4D)
**Tool access:** Layer A (file ops, git log)
**Success output:** Lesson doc written to vault + summary in chat

## Behaviour

When invoked, the Owner agent:

1. Asks: "What went wrong?" (if not stated)
2. Identifies: root cause, contributing factors, impact
3. Assigns a concise `Root-cause fingerprint` that can be reused if the same issue recurs
4. Writes a lesson with: cause, fix applied, prevention rule, fingerprint
5. Appends to `vault/projects/<repo>/lessons.md` if it exists
6. Outputs a summary to chat

## Output format (chat + appended to lessons.md)

```
## Postmortem - <repo> - <date>

What went wrong: <one sentence>

Root cause: <explanation>

Root-cause fingerprint: <stable short slug>

Fix applied: <what was done>

Prevention:
  - <rule or change to prevent recurrence>

Lesson category: <Architecture / Testing / Security / Deployment / Process>
```

## Do not
- Skip this after a significant failure
- Write lessons without a prevention rule
- Let lessons.md drift - keep it current
