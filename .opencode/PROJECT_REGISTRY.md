# Project Registry — Canonical Repo Identity

> **Purpose:** Prevent wrong-repo and stale-repo work. Read this file at startup for any production/deploy task.
> **Authority:** This registry is the single source of truth for repo identity, production URLs, and allowed task types.
> **Last updated:** 2026-07-08

## Rules

1. **Pre-edit check:** For any production or deploy task, check this registry before editing files.
2. **Block on non-production status:** If the requested project maps to `archive-candidate`, `archived-reference-only`, `legacy-reference-only`, `local-first`, `pending-cleanup`, or `NOT_CLONED`, **stop before editing** and inform the owner.
3. **Wrong-repo blocks:** Record wrong-repo blocks in the loop ledger as `WRONG_REPO_BLOCKED`.
4. **No silent repo operations:** Do not clone, delete, or move repos without explicit owner approval.
5. **Cleanup gate:** Production repos under cleanup must be marked `canonical-pending-cleanup` until the owner confirms the cleanup baseline is sealed.

## Registry

| Project | GitHub | Local Path | Production URL | Status | Allowed Task Types |
|---|---|---|---|---|---|
| protected-repo production | `kin0kaze23/protected-repo` | `./protected-repo-prod` | `https://protected-repo-one.vercel.app` | `active` | production tasks after AGENTS.md + NOW/docs review; canonical local clone at v2.0 |
| protected-repo local-first v0.1 | `kin0kaze23/protected-repo-pwa` | `./protected-repo` | none / prototype only | `archived-reference-only` | reference only — no product work |
| protected-repo production legacy clone | `kin0kaze23/protected-repo` | `./archive/protected-repo-prod-legacy-2026-07-08` | none / archived copy | `archived-reference-only` | reference only — no product work |
| demo-project | `kin0kaze23/stillness-daily-devotion` | `./demo-project` | Vercel project present | `active` | production tasks |
| sample-service | `kin0kaze23/automation-hub` | `./sample-service` | Vercel project present | `active` | production tasks |
| example-app | `kin0kaze23/arete-life-os` | `./example-app` | Vercel project present | `active` | production tasks |

## Status Definitions

| Status | Meaning |
|---|---|
| `active` | Canonical production repo, cloned locally, safe for all task types |
| `canonical-pending-cleanup` | Canonical production repo on GitHub, but NOT cloned locally; cleanup in progress; do not edit until clone is complete and baseline is sealed |
| `archive-candidate` | Local-only prototype or stale fork; no production value; do not use for production tasks |
| `archived-reference-only` | Preserved archived/reference copy; do not use for production or roadmap work |
| `legacy-reference-only` | Preserved stale legacy copy; do not use for production or roadmap work |
| `NOT_CLONED` | Repo exists on GitHub but is not present locally; cannot be worked on until cloned |
| `sandbox` | Dirty/in-progress copy; not for production use |

## How to Use This Registry

### At session startup (for production/deploy tasks):

1. Read this file.
2. Find the target project in the table.
3. If status is `active` → proceed with normal workflow.
4. If status is `canonical-pending-cleanup` → **stop** and inform owner: "Production repo is pending cleanup. Clone and seal baseline first."
5. If status is `archive-candidate`, `archived-reference-only`, or `legacy-reference-only` → **stop** and inform owner: "This is a reference/archive copy. Use the canonical production repo instead."
6. If status is `NOT_CLONED` → **stop** and inform owner: "Repo not cloned locally. Clone from GitHub first."

### When recording ledger entries:

- If a task was blocked due to wrong-repo status, record as: `WRONG_REPO_BLOCKED`
- Include: project name, status that caused block, recommended action

### When updating this registry:

- Only the owner or owner-approved protocol changes may edit this file.
- Update after: repo clone, repo archive, production URL change, or status change.
- Keep the table in sync with `WORKSPACE_MAP.md`.
