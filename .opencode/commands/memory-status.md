---
description: "Display memory state and statistics"
---

# /memory-status

**Purpose:** Read Owner-agent memory state without modifying it  
**Mode:** Mentor / Reviewer  
**Model:** qwen3.7-plus (v1.1-production, Action 4D)  
**Tool access:** Layer A read-only  
**Success output:** Current Owner memory health, relevant pages, and conflict/staleness notes

## Behaviour

When invoked, the Owner agent:

1. Reads `vault/protocols/owner-memory/README.md` and `SCHEMA.md`.
2. Reads `vault/owner-memory/index.md`.
3. Reads the latest section of `vault/owner-memory/log.md`.
4. If a repo or topic is supplied, reads only the relevant memory page(s).
5. Reports whether memory is advisory, indexed, source-backed, and consistent with active repo truth.
6. Does not edit files.

## Output format

```markdown
## Memory Status

Store: vault/owner-memory
Authority: advisory only
Index: present / missing
Log: present / missing
Relevant pages:
  - <path> — <summary>

Health:
  - Indexed pages exist: pass/fail
  - Required frontmatter present: pass/fail
  - authority: advisory present: pass/fail
  - Sources present: pass/fail

Conflicts with repo truth: none / <list>
Recommended next action: <none / run /memory-audit / update stale page>
```

## Do not

- Modify memory files.
- Treat Owner memory as authoritative over repo truth.
- Load all project memory pages when only one topic is relevant.
