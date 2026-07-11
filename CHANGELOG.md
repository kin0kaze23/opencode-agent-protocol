# Changelog

All notable changes to the OpenCode agent protocol are documented here.

> **Detailed protocol history:** `vault/protocols/opencode/CHANGELOG.md`
> **Release index and checklist:** `RELEASES.md`
> **Version registry:** `vault/protocols/opencode/VERSIONS.md`

## Source-of-Truth Policy

| File | Purpose | Authority |
|------|---------|-----------|
| `CHANGELOG.md` (this file) | Public-facing release summary | Public |
| `RELEASES.md` | Release process, checklist, and release index | Process |
| `vault/protocols/opencode/CHANGELOG.md` | Detailed protocol history with Added/Changed/Fixed/Removed | Canonical |
| `vault/protocols/opencode/VERSIONS.md` | Version registry with status and test results | Canonical |

## Recent Releases

### v4.52.1 — 2026-07-10

Safe cleanup + portability blocker removal. Parameterized all machine-specific paths in active `.opencode/` files. Cleaned generated artifacts from Git tracking. Removed machine-local configs from tracking.

### v4.52 — 2026-07-10

Repository hygiene audit / open-source readiness audit. Audit-first, no aggressive deletion. 6-phase cleanup plan defined.

### v4.51.1 — 2026-07-10

Operational consistency + friction polish. Release closure fixes, runtime entrypoint canary, docs_only/test_improvement routing, Protocol Atlas version checks.

### v4.51 — 2026-07-10

Regular controlled use pilot. First use of hardened Core v1 harness on real low-risk tasks. 6 friction points identified.

### v4.50 — 2026-07-10

Core v1 hardening release. P0 sample-warning fix, core v1 manifest, hardening report. 815 targeted tests, 0 failures. Core v1 hardened and ready for regular controlled use.

---

For the full detailed changelog with Added/Changed/Fixed/Removed sections for every version, see `vault/protocols/opencode/CHANGELOG.md`.
