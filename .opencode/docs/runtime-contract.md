# Runtime Contract — Required Files Per Environment

> **Version:** v4.27.2
> **Status:** Active
> **Purpose:** Specify required files for each environment layer to ensure reproducible behavior.

## A. Global Install (`~/.config/opencode/`)

| File | Status | Purpose |
|---|---|---|
| `opencode.json` | REQUIRED | Provider config, auth references, plugin config |
| `prompts/orchestrator.md` | REQUIRED | Installed orchestrator prompt mirror |
| `prompts/architect.md` | REQUIRED | Installed architect prompt mirror |
| `prompts/budget.md` | REQUIRED | Installed budget prompt mirror |
| `prompts/explorer.md` | REQUIRED | Installed explorer prompt mirror |
| `prompts/implementer.md` | REQUIRED | Installed implementer prompt mirror |
| `prompts/planner.md` | REQUIRED | Installed planner prompt mirror |
| `prompts/reviewer.md` | REQUIRED | Installed reviewer prompt mirror |
| `prompts/visual-reviewer.md` | REQUIRED | Installed visual-reviewer prompt mirror |
| `prompts/visual-reviewer-fallback.md` | REQUIRED | Installed visual-reviewer-fallback prompt mirror |

**Must NOT contain:** Lanes, gates, token budgets, model routing, safety rules, commands, skills.
**Sync:** Generated from `.opencode/agents/*.md` and `.opencode/global-runtime/prompts/orchestrator.md` via `sync-opencode-runtime.sh`.

## B. Multi-Repo Workspace (`.opencode/`)

### Startup-Loaded (mandatory at session start)

| File | Status | Purpose |
|---|---|---|
| `.opencode/AGENTS.md` | REQUIRED | Protocol kernel |
| `.opencode/rules.md` | REQUIRED | OpenCode guardrails |
| `.opencode/opencode.json` | REQUIRED | Runtime config |
| `.opencode/brain-config.json` | REQUIRED | Orchestration policy |

### Runtime-Critical (loaded on demand)

| File | Status | Purpose |
|---|---|---|
| `.opencode/helper-roster.md` | REFERENCE | Helper agent routing (not startup-loaded) |
| `.opencode/model-registry.yaml` | REFERENCE | Model definitions and routing |
| `.opencode/COMPACTION-SAFEGUARD.md` | REFERENCE | Compaction safety guide |
| `.opencode/PROTOCOL_RUNBOOK.md` | REFERENCE | Protocol runbook |
| `.opencode/PROJECT_REGISTRY.md` | ADVISORY | Project registry |
| `.opencode/config/token-budget.yaml` | REQUIRED | Lane-level budgets |
| `.opencode/config/gate-matrix.yaml` | REQUIRED | Risk-based gate selection |
| `.opencode/config/repo-profiles.yaml` | REQUIRED | Repo type detection |
| `.opencode/agents/*.md` | REQUIRED | Helper agent prompt sources (8 files) |
| `.opencode/commands/*.md` | REQUIRED | Slash commands (40 files) |
| `.opencode/scripts/*.sh` | REQUIRED | Protocol scripts (46 files) |
| `.opencode/conformance/tests/*.sh` | REQUIRED | Conformance tests (59 files) |
| `.opencode/conformance/assert.sh` | REQUIRED | Test assertion library |
| `.opencode/conformance/guard-assert.sh` | REQUIRED | Guard assertion library |
| `.opencode/conformance/fixtures/` | REQUIRED | Test fixture repos |
| `.opencode/git-guard/` | REQUIRED | Git guard wrapper |
| `.opencode/plugins/brain-hooks.js` | REQUIRED | Runtime plugin |
| `.opencode/policies/*.json` | REQUIRED | Policy files (10 files) |
| `.opencode/templates/*.md` | REFERENCE | Document templates |
| `.opencode/skills/*/SKILL.md` | REFERENCE | Skill library |
| `.opencode/skills/registry.md` | REFERENCE | Skill classification |
| `.opencode/adr/*.md` | REFERENCE | Architecture Decision Records |
| `.opencode/role-profiles/*.md` | REFERENCE | Senior-specialist role profiles |
| `.opencode/README.md` | REFERENCE | Navigation guide |

### Generated/Cache (must NOT be committed)

| Path | Status | Purpose |
|---|---|---|
| `.opencode/cache/` | GENERATED | Pattern index, code index (ephemeral) |
| `.opencode/.session-cache/` | GENERATED | Session cache (ephemeral) |
| `.opencode/conformance/results/` | GENERATED | Test output (gitignored) |
| `.opencode/node_modules/` | GENERATED | Dependencies (gitignored) |
| `.opencode/brain-config.json.backup.*` | GENERATED | Backup files (should be cleaned up) |

### Archived (historical, not runtime authority)

| Path | Status | Purpose |
|---|---|---|
| `.opencode/archive/` | ARCHIVED | Historical files with MANIFEST.md |
| `.opencode/archive/protocol-phases/` | ARCHIVED | 45 historical protocol phase docs |
| `.opencode/archive/model-registry-historical.yaml` | ARCHIVED | Historical model registry sections |
| `.opencode/benchmarks/` | REFERENCE | Benchmark cases and simulations (non-authoritative) |
| `.opencode/evals/` | REFERENCE | Model evaluation data (non-authoritative) |

## C. Repo-Specific Project (`<repo>/`)

| File | Status | Purpose |
|---|---|---|
| `<repo>/AGENTS.md` | REQUIRED | Repo-specific product truth |
| `<repo>/NOW.md` | REQUIRED | Current task status |
| `<repo>/PLAN.md` | OPTIONAL | Active plan (required for STANDARD/HIGH-RISK) |
| `<repo>/CLAUDE.md` | OPTIONAL | Claude-specific overlay |
| `<repo>/.opencode/` | EXCEPTION | Repo-local hooks/tools only (ADR required) |
| `<repo>/PROJECT_MEMORY.md` | OPTIONAL | Project memory (recommended for active repos) |

## D. Fresh Clone / CI Environment

A fresh clone of the workspace must have:

1. **Global:** `~/.config/opencode/opencode.json` with provider auth (via Doppler).
2. **Workspace:** `.opencode/` directory with all REQUIRED files above.
3. **Repo:** `<repo>/AGENTS.md` and `<repo>/NOW.md` for the target repo.
4. **Secrets:** Doppler project `nuggie-be`, config `dev_backend` configured.
5. **Runtime:** `opencode` CLI installed and accessible.
6. **Node:** `.opencode/node_modules/` installed via `pnpm install` in `.opencode/`.

**Fresh clone verification:**
```bash
bash .opencode/scripts/verify-environment.sh --mode workspace
bash .opencode/scripts/verify-environment.sh --mode repo <repo-path>
```

## Portability Rules

1. **No hardcoded user paths:** Scripts must use `$ROOT_DIR` or `$HOME`, not hardcoded absolute paths.
2. **No machine-specific config in workspace:** Machine-specific config belongs in global.
3. **Secrets via Doppler only:** Never hardcode API keys, tokens, or credentials.
4. **Portable paths:** Use relative paths from workspace root or `$ROOT_DIR` in scripts.
5. **Cross-platform:** Scripts must work on macOS (darwin) and Linux (CI).
