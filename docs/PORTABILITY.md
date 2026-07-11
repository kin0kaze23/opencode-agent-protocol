# Portability Guide

> **What is portable vs what remains device-specific.**

## Portable (tracked in git, safe to clone)

| Category | Files | Notes |
|---|---|---|
| Protocol kernel | `.opencode/AGENTS.md`, `.opencode/rules.md` | Startup-loaded, canonical |
| Runtime config | `.opencode/opencode.json`, `.opencode/brain-config.json` | Behavioral authority |
| Commands | `.opencode/commands/*.md` | 40 slash commands |
| Scripts | `.opencode/scripts/*.sh` | 47 protocol scripts |
| Conformance tests | `.opencode/conformance/tests/*.sh` | 59 test files |
| Config | `.opencode/config/*.yaml` | Token budgets, gate matrix, repo profiles |
| Agent prompts | `.opencode/agents/*.md` | 8 helper agent sources |
| Skills | `.opencode/skills/*/SKILL.md` | 67 skills |
| Templates | `.opencode/templates/*.md` | Document templates |
| Policies | `.opencode/policies/*.json` | 10 policy files |
| Git guard | `.opencode/git-guard/` | Git mutation wrapper |
| Environment contract | `.opencode/docs/environment-contract.md` | Four-layer model |
| Runtime contract | `.opencode/docs/runtime-contract.md` | Required files per environment |
| Sync contract | `.opencode/docs/sync-contract.md` | Update procedures |
| Archive | `.opencode/archive/` | Historical files with MANIFEST.md |
| Workspace map | `WORKSPACE_MAP.md` | Repo registry |
| Project registry | `.opencode/registry.yaml` | Canonical repo metadata |
| Vault | `vault/` | Knowledge base (separate git repo) |

## Device-Specific (NOT tracked, must be configured locally)

| Category | Path | Notes |
|---|---|---|
| Global OpenCode config | `~/.config/opencode/opencode.json` | Provider auth only |
| Global prompts | `~/.config/opencode/prompts/*.md` | Generated from workspace |
| Secrets | Doppler (project: `nuggie-be`) | Never committed |
| Session cache | `.opencode/.session-cache/` | Ephemeral, gitignored |
| Pattern index | `.opencode/cache/` | Ephemeral, gitignored |
| Test results | `.opencode/conformance/results/` | Ephemeral, gitignored |
| Node modules | `.opencode/node_modules/` | Installed via `pnpm install` |

## What Must NOT Be Copied Between Devices

1. **Secrets** — Never copy `.env` files or API keys. Use Doppler.
2. **Session cache** — Ephemeral, device-specific.
3. **Global config** — Contains machine-local auth. Each device configures its own.
4. **Test results** — Ephemeral output, not portable.

## Portability Guarantees

1. **No hardcoded user paths** in scripts (except `opencode-safe-launch.sh` which uses `$HOME`)
2. **No secrets in tracked files** — verified by gitleaks pre-commit hook
3. **No machine-specific config in workspace** — global config is separate
4. **Cross-platform scripts** — bash scripts work on macOS and Linux (CI)
5. **Doppler for secrets** — secrets are sourced by name, never hardcoded

## Nested Git Repo Resolution (v4.28.2)

The control-plane previously tracked gitlinks (mode 160000) for three nested git repos that were not registered as submodules in `.gitmodules`. This caused persistent dirty `git status` output whenever the nested repos advanced locally.

### Decisions

| Repo | Classification | Decision | Rationale |
|---|---|---|---|
| `example-agent/example-agent` | Nested git repo (inside tracked `example-agent/` directory) | Untracked from control-plane index (`git rm --cached`). Already covered by `.gitignore` rule `example-agent/example-agent/`. | Independently managed repo. Control-plane should not track its commit state. |
| `example-platform` | Nested git repo (pure gitlink, no other tracked files) | Untracked from control-plane index (`git rm --cached`). Already covered by `.gitignore` rule `/example-platform/`. | No GitHub remote configured. Local-only repo. Control-plane should not track its commit state. |
| `example-toolchain-PROD` | Stale gitlink (empty directory, no `.git` on disk) | Untracked from control-plane index (`git rm --cached`). Added `/example-toolchain-PROD/` to `.gitignore`. | Stale gitlink with no actual repo on disk. Was causing workspace protocol guard failure. |
| `example-orchestrator-PROD` | Nested git repo (pure gitlink, no other tracked files) | Untracked from control-plane index (`git rm --cached`). Already covered by `.gitignore` rule `/example-orchestrator-PROD/`. | Independently managed repo. Control-plane should not track its commit state. |

### Proper Submodules (unchanged)

| Submodule | `.gitmodules` entry | Status |
|---|---|---|
| `vault` | `https://github.com/kin0kaze23/vault.git` | Active, properly registered |
| `career-ops` | `https://github.com/santifer/career-ops.git` | Active, properly registered |

### Known Legacy Tracking

The following directories were untracked from the control-plane index in v4.28.2a. Files remain on disk for historical reference but are no longer tracked by git.

| Directory | Previously Tracked | Classification | Decision | Date |
|---|---|---|---|---|
| `.agent/` | 166 files | Legacy (v2.0 AutonomousOrchestrator, 2026-03-25) | Untracked (`git rm -r --cached`). Added `/.agent/` to `.gitignore`. No active runtime references — all conformance tests are negative assertions verifying `.agent/` is NOT referenced. | v4.28.2a |
| `example-agent/` | 10 files | Legacy product-repo files (AGENTS.md, CLAUDE.md, NOW.md, etc.) | Untracked (`git rm --cached`). Already covered by `.gitignore` rule `/example-agent/`. No active protocol references. Files belong in the example-agent product repo, not the control-plane. | v4.28.2a |

### Local-Only Repos

| Repo | Status | Notes |
|---|---|---|
| `example-platform` | Local-only (no GitHub remote) | Not portable across devices. Has `AGENTS.md`, `NOW.md`, `PROJECT_MEMORY.md`. Owner decision: add remote or keep local-only. |
