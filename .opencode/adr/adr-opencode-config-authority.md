# ADR: OpenCode Configuration Authority Model

**Status:** Updated (Phase 1.7 — v2.0.0 — 2026-06-28)
**Previous:** Sealed (Phase C5 — v1.0.0 — 2026-05-24)
**Date:** 2026-06-28
**Context:** Dual-config model — global config serves as behavioral baseline for repos outside PersonalProjects workspace

## Problem

The OpenCode configuration is spread across three layers. The original C5 seal attempted to strip global config to provider/auth only, but this proved impractical because repos outside the PersonalProjects workspace (e.g., antigravity repos) have no `.opencode/` directory and depend entirely on the global config for behavioral routing.

## Decision

### Authority Model (v2.0.0 — Dual-Config)

| Layer | File(s) | Responsibility | Authority Level |
|---|---|---|---|
| **Global** | `~/.config/opencode/opencode.json` | **Behavioral baseline** — same agent definitions, MCP config, model routing as workspace. Serves repos outside PersonalProjects. | Behavioral baseline for repos outside workspace |
| **Workspace** | `.opencode/opencode.json` | **Behavioral runtime authority** — agents, model routing, MCP policy, permissions, compaction, default agent, prompts, helper roster. Adds workspace-specific settings (compaction, default_agent, watcher, lsp). | **Behavioral runtime authority** for repos under PersonalProjects |
| **Workspace** | `.opencode/brain-config.json` | Orchestration/routing/eval policy, budgets, protocol intelligence, model comparison routing | **Orchestration policy authority** |
| **Repo-level** | `<repo>/.opencode/` | Repo-specific exceptions, hooks, local MCP overrides only | Exception-only |
| **Conformance** | `.opencode/conformance/` | Prove no drift across layers | Enforcement |

### Principles

1. **Dual-config sync**: The sync script writes the same agent definitions, MCP config, and model routing to BOTH global and workspace configs. This ensures consistent behavior across all repos.

2. **Workspace is primary authority**: For repos under PersonalProjects, the workspace config overrides global. It adds workspace-specific settings (compaction, default_agent, watcher, lsp, share, snapshot).

3. **Global is behavioral baseline**: For repos outside PersonalProjects (e.g., antigravity repos), the global config provides the full behavioral baseline. Both configs have 11 agents (including summary/compaction internal agents).

4. **brain-config is protocol intelligence**: `brain-config.json` is the canonical source for routing, budgets, and roster. The sync script generates both configs from it.

5. **Repo-level is exception-only**: Repos inherit workspace or global behavior by default. Repo `.opencode/` directories contain only MCP overrides, hooks, or explicit exceptions.

6. **No silent drift**: Conformance tests must run to prove both configs are synchronized and match the canonical protocol source.

### Target State (v2.0.0)

- **Global**: ~250 lines — full behavioral baseline (11 agents, MCP config, model routing, permissions)
- **Workspace**: ~350 lines — behavioral authority (same 11 agents + compaction settings, default_agent, watcher, lsp, instructions)
- **brain-config.json**: unchanged — orchestration policy authority
- **Sync script**: writes to BOTH configs from canonical source
- **Conformance**: guards updated to accept dual-config model

### What Changed from v1.0.0

| Aspect | v1.0.0 (C5) | v2.0.0 (Phase 1.7) |
|---|---|---|
| Global config | Provider/auth only (~50 lines) | Behavioral baseline (~250 lines) |
| Agent definitions | Workspace only | Both global and workspace |
| Summary/compaction | Workspace only | Both global and workspace |
| Sync script target | Global only | Both global and workspace |
| Conformance guards | Fail if global has behavioral keys | Accept global behavioral keys under dual-config model |

### Non-Decisions (Deferred)

- This ADR does **not** authorize migration. Migration requires Phase C0-C5 execution.
- This ADR does **not** change secret management (Doppler remains canonical).
- This ADR does **not** change model routing or MCP enabled/disabled status.
- This ADR does **not** modify prompts or agent behavior.

## Consequences

### Positive
- Workspace is self-describing and portable (16 keys)
- Global config is machine-level plumbing only (3 keys)
- Clear authority boundaries eliminate governance smell
- Conformance tests prevent silent drift (7 guards, enforcement mode)
- MCP profiles runtime-effective (ui_ux, automation, baseline, apa_product_factory)
- Repo exceptions narrow and approved (MCP overlays, APA agents)

### Negative
- Migration completed successfully with 0 runtime behavior changes
- No temporary duplication (global minimized, workspace self-contained)

### Risks (Mitigated)
- **MCP mismatch**: Resolved via profile-based policy and repo-local overlays
- **Compaction drift**: Normalized to schema-valid `reserved` key (previously `reservedTokens`) with conservative auto/prune settings
- **Agent governance**: Resolved via workspace agent declarations and conformance guards
- **brain-config alignment**: 1,329-line orchestration policy must be proven aligned with OpenCode runtime config.

## Conformance Requirements (SEALED — Enforcement Mode)

All 7 guards run in enforcement mode. Any config change must pass:

1. `effective-runtime-diff.sh` — Prove workspace is self-contained behavioral authority
2. `mcp-policy-guard.sh` — Prove MCP state matches profile policy
3. `brain-routing-alignment.sh` — Prove brain-config.json defaults match opencode.json
4. `agent-roster-guard.sh` — Prove all 7 agents resolvable with correct model assignments
5. `prompt-mirror-drift.sh` — Prove prompt checksums match across global/workspace
6. `repo-exception-guard.sh` — Prove repo-level .opencode/ contains only allowed exceptions
7. `config-authority-guard.sh` — Prove each layer contains only allowed keys

**Current result:** 0 FAIL, 0 WARN, 320 PASS (v1.0.0 sealed)

## References

- `.opencode/opencode.json` (workspace — behavioral authority)
- `~/.config/opencode/opencode.json` (global — provider/auth only)
- `.opencode/brain-config.json` (orchestration policy)
- `.opencode/protocol/phase-c5-seal-report.md` (final seal report)
- `.opencode/policies/` (all policy manifests)
- Phase C0-C5 migration plan (separate document)
