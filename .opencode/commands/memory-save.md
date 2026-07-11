---
description: "Save a durable, source-backed Owner memory fact"
---

# /memory-save

**Purpose:** Save a durable, source-backed Owner memory fact  
**Mode:** Executor  
**Model:** qwen3.7-plus (v1.1-production, Action 4D)  
**Tool access:** Layer A file ops  
**Success output:** Memory page updated, index/log updated, guard-compatible structure preserved

## Behaviour

When invoked, the Owner agent:

1. Confirms the fact is durable and worth saving.
2. Refuses to save secrets, raw resolved config output, unreviewed transcripts, temporary logs, or facts contradicted by repo truth.
3. Classifies the memory type:
   - `preference`
   - `convention`
   - `hazard`
   - `project-summary`
   - `lesson`
   - `decision`
4. Reads `vault/owner-memory/index.md` and relevant existing page(s) to avoid duplicates.
5. Updates an existing page when possible; creates a new page only when needed.
6. Ensures required frontmatter includes `authority: advisory` and `sources:`.
7. Updates `vault/owner-memory/index.md` if a page is created or summary/date changes.
8. Appends one entry to `vault/owner-memory/log.md` with reason and source.
9. Runs `/memory-audit` or the owner-memory conformance check when the change is structural.

## Output format

```markdown
## Memory Saved

Fact: <one sentence>
Type: <memory type>
Files updated:
  - <path>
  - vault/owner-memory/index.md (if changed)
  - vault/owner-memory/log.md
Authority: advisory only
Source: <user statement / repo file / verification artifact>
Verification: <audit result or not required — content-only update>
```

## Do not

- Save facts without provenance.
- Save secrets or raw config output.
- Use memory to bypass repo `AGENTS.md`, `NOW.md`, or active `PLAN.md`.
- Create duplicate pages when an existing page can be updated.
