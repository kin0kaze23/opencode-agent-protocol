# Duplicate Command Strategy

> **Status:** Sealed documentation — no runtime changes authorized.
> **Created:** 2026-06-12
> **Author:** Owner Agent
> **Scope:** Read-only audit record and strategy document for duplicate commands across `.opencode/commands` and `.claude/commands`.

---

## 1. Current Sealed Baseline

| Category | Count | Status |
|----------|-------|--------|
| Commands (`.opencode/commands/*.md`) | 33/33 | YAML frontmatter sealed |
| Skills (`.opencode/skills/*/SKILL.md`) | 68/68 | YAML frontmatter sealed |
| Combined command/skill files | 101/101 | Standardized |

**Frontmatter objective:** Sealed — all command and skill files have consistent YAML frontmatter.

---

## 2. Duplicate Inventory

The following 8 command files exist in both `.opencode/commands/` and `.claude/commands/`:

| File | `.opencode/commands` | `.claude/commands` | Duplicate Risk |
|------|---------------------|-------------------|----------------|
| `checkpoint.md` | ✅ Canonical | ⚠️ Active | Medium |
| `debug.md` | ✅ Canonical | ⚠️ Active | Medium |
| `deploy-preview.md` | ✅ Canonical | ⚠️ Active | Medium |
| `deploy-rollback.md` | ✅ Canonical | ⚠️ Active | Medium |
| `deploy-vercel.md` | ✅ Canonical | ⚠️ Active | Medium |
| `deploy-workers.md` | ✅ Canonical | ⚠️ Active | Medium |
| `gates.md` | ✅ Canonical | ⚠️ Active | Medium |
| `implement.md` | ✅ Canonical | ⚠️ Active | Medium |

---

## 3. Canonicality Statement

- **`.opencode/commands`** is the **canonical** command surface for OpenCode.
- **`.claude/commands`** is an **active Claude Code compatibility surface** that is still consumed by Claude Code sessions.
- Do not assume `.claude/commands` can be deleted, stubbed, or deprecated until:
  - Claude Code consumption is retired, OR
  - Compatibility behavior is validated through testing.

---

## 4. Risk Statement

| Action | Risk Level | Rationale |
|--------|------------|-----------|
| Read-only duplicate audit | **Low** | No files modified; documentation only |
| Editing active `.claude/commands` files | **Medium–High** | Command markdown may affect Claude Code behavior, routing, or command quality |
| Deleting `.claude/commands` duplicates | **High** | Active consumption by Claude Code sessions; deletion may break workflows |
| Adding deprecation notices inside active command bodies | **Medium** | May change Claude Code behavior even if content is not functionally different |

---

## 5. Recommended Strategy

1. **Keep both command surfaces** for now.
2. **Treat `.opencode/commands` as OpenCode canonical** — all OpenCode work should reference these.
3. **Treat `.claude/commands` as Claude compatibility** — preserve until consumption is retired.
4. **Avoid behavior-changing edits to `.claude/commands`** — no deprecation notices, stubs, or content removal.
5. **Next step:** Conduct a consumption audit to identify exactly which scripts, hooks, settings, docs, and workflows still rely on `.claude/commands`.

---

## 6. Future Migration Options

| Option | Description | Preconditions |
|--------|-------------|---------------|
| **Keep both and document divergence** | Maintain separate command surfaces with documented differences | None |
| **Sync selected improvements** | Copy improvements from `.opencode` to `.claude` after compatibility review | Claude compatibility review complete |
| **Convert to compatibility stubs** | Replace `.claude` command bodies with stubs pointing to `.opencode` | Prove Claude no longer depends on full command content |
| **Remove duplicates** | Delete `.claude/commands` duplicates | All references migrated and validated |

---

## 7. Required Preconditions Before Modifying `.claude/commands`

Before any modification to `.claude/commands` files, ALL of the following must be true:

1. **All `.claude/commands` consumers identified** — scripts, hooks, settings, workflows, and docs that reference these files are documented.
2. **Claude Code command behavior understood** — how Claude Code parses, loads, and executes command markdown is validated.
3. **Compatibility test or manual validation path defined** — a repeatable test or validation workflow exists.
4. **Rollback plan defined** — clear steps to revert if issues arise.
5. **Human approval obtained** — explicit owner approval for the specific change.

---

## 8. References

- Workspace protocol: `.opencode/AGENTS.md`
- Command usage policy: `.opencode/docs/opencode-command-usage-policy.md`
- Commit scope guard: `.opencode/scripts/commit-scope-guard.sh`
- Workspace protocol guard: `.opencode/scripts/workspace-protocol-guard.sh`

---

*This document is a read-only audit record. No runtime changes are authorized by this document alone.*
