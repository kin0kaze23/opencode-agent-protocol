---
name: runtime-wiring-audit
description: Verifies the active runtime entrypoint, mount path, or router that actually wires a module into the app — prevents planning against dead code.
---

# Runtime Wiring Audit

Use this skill before planning or reviewing when multiple files could plausibly be the active implementation.

## Goal

Verify which module is actually live at runtime. Do not trust filenames, richer implementations, or newer-looking files without mount-path evidence.

## Procedure

Before auditing, read the following:

1. Identify the real entrypoint or mount path for the relevant part of the app:
   - `app/App.tsx`, router entry, layout shell, server bootstrap, or exported registration point
2. Read the entrypoint file to trace the import chain
3. Read candidate implementation files that could be the active module
4. Read any routing configuration (React Router, Next.js routes, Express routes, etc.)

Then execute the audit:

1. Start at the real entrypoint or mount path and trace the import/render/route chain to the live implementation
2. For each candidate implementation, determine:
   - **Mounted and live** — actively imported, rendered, or routed
   - **Orphaned / unused** — exists in the codebase but no import chain reaches it
   - **Legacy but still mounted** — older code that is still the active implementation
3. Record exact evidence for each candidate:
   - Entrypoint file where the chain starts
   - Full import path from entrypoint to candidate
   - Exact render/mount/route line that activates it
4. If ambiguity remains after tracing, the phase is not implementation-ready — request clarification

## Output format

Produce an audit report in this exact format:

```
## Runtime Wiring Audit — <module/feature name>

**Runtime authority:** VERIFIED / AMBIGUOUS / NOT FOUND

### Live implementation
- File: <exact file path>
- Import chain: <entrypoint> → <intermediate> → <target>
- Mount line: <file>:<line> — <code snippet>

### Orphaned implementations (if any)
- <file path> — <why it is not live: no import / commented out / unused export>

### Legacy but mounted (if any)
- <file path> — <evidence it is still the active implementation>
```

- If authority is `VERIFIED`, the plan can proceed with the confirmed file as the implementation target.
- If authority is `AMBIGUOUS`, the phase is not implementation-ready — the plan must resolve the ambiguity first.
- If authority is `NOT FOUND`, the feature does not exist at runtime — the plan must create it.

## Out of Scope

This skill does NOT:
- Modify or refactor the implementation (that is /implement)
- Audit code quality or correctness of the live module (that is /review)
- Trace transitive dependencies beyond the direct mount path
- Replace architectural analysis when the routing system itself is the subject of change
