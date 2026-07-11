---
description: "Promote a confirmed mistake into durable repo/protocol prevention"
---

# /promote-lesson

**Mode:** Mentor or Reviewer
**Purpose:** Convert a confirmed orchestrator mistake into durable repo-local, protocol-wide, or both forms of prevention
**Tool access:** Layer A (read-only by default; write only to approved protocol or vault lesson files)
**Success output:** Confirmed lesson persisted to the correct durable location with duplication control and file-growth guardrails

## Behaviour

When invoked, the Owner agent:

1. Identifies the confirmed mistake pattern
2. Classifies scope:
   - `repo-local` when the lesson depends on one repo's canon, state, architecture, or workflow
   - `protocol-wide` when the same prevention rule should apply across repos
   - `both` when the repo needs a local reminder and the workspace protocol also needs a general rule or test
3. Searches for duplicate or near-duplicate lessons first
4. Decides whether to append, update, or promote the existing lesson entry rather than creating another duplicate
5. Writes the durable lesson shape:
   - Mistake pattern
   - Evidence
   - Fix pattern
   - Prevention rule
6. Uses the most generic rule that is still accurate
7. Applies file-growth guardrails:
   - avoid duplicate append-only entries
   - prefer updating an existing lesson when it clearly covers the same mistake pattern
   - keep protocol-wide lessons concise and reusable
8. Returns a short summary of:
   - scope chosen
   - files updated
   - why that scope was correct

## Decision rules

- Prefer `protocol-wide` when the same mistake could recur in another repo
- Prefer `repo-local` when the prevention depends on product canon or repo-specific architecture
- Use `both` when the lesson needs a repo reminder plus a shared prevention rule
- Default to the most generic rule that is still accurate, not the most local or most global by habit

## Output format

```
## Lesson Promotion

Scope: repo-local / protocol-wide / both
Mistake pattern: <one sentence>
Evidence: <what proved the mistake>
Fix pattern: <what changed>
Prevention rule: <durable rule>
Files updated:
  - <path>
```

## Do not

- Leave a confirmed repeatable mistake as chat-only feedback
- Create duplicate append-only entries when an existing lesson should be updated
- Promote a repo-specific detail into a protocol-wide rule without evidence
- Skip file-growth guardrails when lesson files are already covering the same class of mistake
