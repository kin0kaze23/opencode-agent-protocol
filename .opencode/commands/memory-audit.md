---
description: "Audit memory files for consistency"
---

# /memory-audit

**Purpose:** Validate Owner-agent memory structure and authority boundaries  
**Mode:** Reviewer  
**Model:** qwen3.7-plus (v1.1-production, Action 4D)  
**Tool access:** Layer A read-only by default  
**Success output:** Pass/fail memory audit with exact files to fix

## Behaviour

When invoked, the Owner agent:

1. Reads `vault/protocols/owner-memory/SCHEMA.md`.
2. Reads `vault/owner-memory/index.md` and `log.md`.
3. Verifies every indexed memory page exists.
4. Verifies every memory page has required frontmatter:
   - `title`
   - `type`
   - `created`
   - `updated`
   - `status`
   - `authority: advisory`
   - `sources`
5. Verifies no obvious secret-like literals are present.
6. Flags pages not listed in the index.
7. Flags stale/superseded pages that conflict with active repo truth when a target repo is supplied.
8. Does not fix files unless the user explicitly asks.

## Output format

```markdown
## Memory Audit

Result: PASS / FAIL

Checks:
  - Protocol docs exist: PASS / FAIL
  - Index exists: PASS / FAIL
  - Log exists: PASS / FAIL
  - Indexed pages exist: PASS / FAIL
  - Required frontmatter: PASS / FAIL
  - Advisory authority: PASS / FAIL
  - Sources present: PASS / FAIL
  - Secret-like literals: PASS / FAIL

Findings:
  [High] <path> — <issue> -> <fix>
  [Medium] <path> — <issue> -> <fix>

Verdict: Ready / Needs fixes
```

## Do not

- Edit memory files during audit mode.
- Treat external recall provider output as proof without file-backed evidence.
- Promote Owner memory above repo truth.
