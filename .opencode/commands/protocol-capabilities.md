---
description: "Print the current verified OpenCode protocol capability surface"
---

# /protocol-capabilities

**Mode:** Read-only
**Purpose:** Summarize the current verified protocol capability surface from CAPABILITIES.md
**Does not:** Update any files, modify state, or trigger implementation

---

## Behaviour

1. Read `vault/protocols/opencode/CAPABILITIES.md`
2. Group capabilities by status:
   - **production-core** — officially approved for default use
   - **verified** — works and validated, available for use
   - **safe canary** — works, safe, but under soak period
   - **deferred** — planned but not implemented
   - **blocked** — not usable due to known issue
3. Print a structured summary grouped by status
4. Include last verified version and commit for each capability
5. Show total counts by status
6. Print the active protocol version from brain-config.json

---

## Output Format

```
## Protocol Capabilities — v<version>

### Production-Core
- <name> — <description> (last verified: <version>)

### Verified
- <name> — <description> (last verified: <version>)

### Safe Canary
- <name> — <description> (last verified: <version>)

### Deferred
- <name> — <description>

### Blocked
- <name> — <description> (reason: <reason>)

---
Total: <N> production-core, <N> verified, <N> canary, <N> deferred, <N> blocked
```

---

## Constraints

- Read-only: never modifies CAPABILITIES.md or any other file
- Does not promote/demote capabilities (that requires explicit owner approval)
- Does not auto-update version or status fields
- Uses vault truth, not cached data
