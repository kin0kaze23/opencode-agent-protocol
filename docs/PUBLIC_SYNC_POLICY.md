# Public Sync Policy

> **Purpose:** Defines how the public repo relates to the internal development repo and how to prevent drift.
> **Last Updated:** 2026-07-11

---

## Two Repositories

| Repo | Visibility | Purpose |
|------|-----------|---------|
| `kin0kaze23/opencode-agent-protocol` | Public | Clean protocol specification, CI-validated, no personal data |
| `kin0kaze23/opencode-agent-protocol-internal` | Private | Full development history with vault, real project configs, personal context |

The public repo was created from a sanitized staging tree with no v4 git history. The internal repo contains the full v4.x development history, vault submodule, real project names, and personal runtime state.

---

## What Stays Internal Only

| Category | Reason |
|----------|--------|
| v4.x git history | Contains personal project names, identity, and local paths |
| Vault submodule | Personal knowledge base with project names, lessons, decisions |
| Real project configs | Contains real provider names, API key references, project names |
| Internal reports | May contain historical personal project references |
| WORKSPACE_MAP.md | Internal workspace registry with real repo names |
| Owner memory | Personal durable memory with preferences and context |

---

## What Can Be Ported to Public

| Category | Condition |
|----------|-----------|
| Protocol improvements | Must pass privacy scan (no personal data) |
| New conformance tests | Must be self-contained (no workspace-specific state) |
| Documentation improvements | Must not reference internal-only files or concepts |
| Validation scripts | Must work on fresh clone without workspace setup |
| Bug fixes | Must not expose personal data in the diff |

---

## Sync Process

1. **Make changes in the internal repo** (daily use)
2. **Identify public-safe improvements** — anything that would benefit external users
3. **Port to public repo** via a new branch:
   - Clone the public repo
   - Create a feature branch
   - Apply the changes (manually or cherry-pick)
   - Run `bash scripts/public-surface-scan.sh` — must PASS
   - Run all Tier 1 validations — must PASS
   - Create PR
   - Wait for CI (10 matrix checks)
   - Merge
4. **Tag and release** the public repo

---

## Drift Prevention

| Check | How | Frequency |
|-------|-----|-----------|
| Privacy scan | `bash scripts/public-surface-scan.sh` | Every PR |
| Docs drift | `bash scripts/validate-docs-drift.sh` | Every PR |
| Config schema | `bash scripts/validate-config-schema.sh` | Every PR |
| Claims & evidence | `bash scripts/validate-claims-evidence.sh` | Every PR |
| Protocol conformance | 5 conformance test scripts | Every PR |
| Fresh-clone validation | Clone + run all Tier 1 tests | Every release |

---

## What Not to Do

- **Do not** push v4 history to the public repo
- **Do not** include vault, reports, or .paperclip in the public repo
- **Do not** use real project names in public docs or configs
- **Do not** hardcode API keys or provider-specific config in public files
- **Do not** assume internal-only features are available in the public repo
- **Do not** sync automatically — every public change must pass privacy scan and CI
