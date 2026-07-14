# Portability Guide

> **What is portable vs what remains device-specific.**
> **Last Updated:** 2026-07-14

## brain-config.json Status

The `.opencode/brain-config.json` file is an **internal reference config** that ships with the public repo for structural completeness. It is NOT the runtime config that OpenCode reads.

| File | Role | What OpenCode reads | User action |
|------|------|---------------------|-------------|
| `.opencode/opencode.json` | **Runtime config** — the file OpenCode actually loads | ✅ Yes | Replace `YOUR_PROVIDER/YOUR_*_MODEL` with your model IDs |
| `.opencode/brain-config.json` | **Internal reference** — used by `sync-opencode-runtime.sh` as a source for agent definitions | ❌ No (sync writes to opencode.json) | Do not edit unless you understand the sync flow |

### Sync Safety (v5.5.3)

`sync-opencode-runtime.sh` includes a **public-mode guard** that prevents overwriting placeholder model IDs in `opencode.json` with author-specific values from `brain-config.json`:

- If `opencode.json` contains `YOUR_PROVIDER` placeholders
- And `brain-config.json` contains non-placeholder model IDs
- Sync is **refused** with a clear message
- Override with `--allow-local-sync` flag (not recommended for public repo users)

### Recommended Setup Path

1. Edit `.opencode/opencode.json` directly — replace `YOUR_PROVIDER/YOUR_*_MODEL` with your model IDs
2. Set your API key environment variable
3. Do NOT run `sync-opencode-runtime.sh` unless you have also updated `brain-config.json`

See [docs/OWN_MODEL_SETUP.md](OWN_MODEL_SETUP.md) for detailed provider configuration.

## Portable (tracked in git, safe to clone)

| Category | Files | Notes |
|---|---|---|
| Protocol kernel | `.opencode/AGENTS.md`, `.opencode/rules.md` | Startup-loaded, canonical |
| Runtime config | `.opencode/opencode.json` | Behavioral authority — has placeholder model IDs |
| Internal reference | `.opencode/brain-config.json` | Used by sync script — not read by OpenCode directly |
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
| Setup script | `scripts/setup.sh` | First-run setup (OS detection, prerequisites, aliases) |
| Package metadata | `.opencode/package.json` | Plugin dependencies |

## Device-Specific (NOT tracked, must be configured locally)

| Category | Path | Notes |
|---|---|---|
| Global OpenCode config | `~/.config/opencode/opencode.json` | Provider auth only |
| Global prompts | `~/.config/opencode/prompts/*.md` | Generated from workspace via sync |
| Secrets | Your secrets manager (e.g. Doppler, .env) | Never committed |
| Session cache | `.opencode/.session-cache/` | Ephemeral, gitignored |
| Pattern index | `.opencode/cache/` | Ephemeral, gitignored |
| Test results | `.opencode/conformance/results/` | Ephemeral, gitignored |
| Node modules | `.opencode/node_modules/` | Installed via `npm install` |

## What Must NOT Be Copied Between Devices

1. **Secrets** — Never copy `.env` files or API keys. Use a secrets manager.
2. **Session cache** — Ephemeral, device-specific.
3. **Global config** — Contains machine-local auth. Each device configures its own.
4. **Test results** — Ephemeral output, not portable.

## Portability Guarantees

1. **No hardcoded user paths** in scripts (all use `$HOME` or relative paths)
2. **No secrets in tracked files** — verified by gitleaks pre-commit hook
3. **No machine-specific config in workspace** — global config is separate
4. **Cross-platform scripts** — bash scripts work on macOS and Linux
5. **Placeholder model IDs** — `opencode.json` ships with `YOUR_PROVIDER/YOUR_*_MODEL` placeholders
6. **Sync safety guard** — `sync-opencode-runtime.sh` refuses to overwrite placeholders with author-specific values
7. **First-run setup** — `scripts/setup.sh` detects OS, checks prerequisites, generates aliases

## Cross-Platform Compatibility (v5.5.3)

The launcher (`opencode-safe-launch.sh`) supports both macOS and Linux:

| Function | macOS | Linux |
|---|---|---|
| Memory check | `memory_pressure` / `vm_stat` | `/proc/meminfo` / `free -m` |
| File mtime | `stat -f %m` | `stat -c %Y` |
| Date parsing | `date -j -f` | `date -d` |
| OS detection | `uname -s` → `Darwin` | `uname -s` → `Linux` |

If the OS is unknown, the launcher skips the memory check with a warning.
