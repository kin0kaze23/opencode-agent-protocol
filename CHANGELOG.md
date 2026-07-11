# Changelog

All notable changes to the OpenCode Agent Protocol are documented here.

## Source-of-Truth Policy

| File | Purpose | Authority |
|------|---------|-----------|
| `CHANGELOG.md` (this file) | Public-facing release summary | Public |
| `RELEASES.md` | Release process, checklist, and release index | Process |

## Recent Releases

### v5.1.0 — 2026-07-11

Capability catalog + public example workflows. Added `docs/CAPABILITY_CATALOG.md` mapping 17 public capabilities with status, source files, validation tests, and CI coverage. Added `docs/RUNTIME_MAP.md` showing authoritative vs generated files. Added `docs/CONFIGURATION_GUIDE.md` with customization instructions. Added `examples/workflows/` with 5 sanitized example workflows (docs-only change, small bugfix, privacy scan failure, release checklist, model routing advisory). Added `docs/CLAIMS.md` defining allowed and disallowed public claims. Updated README with agent cooperation section. Fresh-clone validated.

### v5.0.3 — 2026-07-11

Branch protection verification. Confirmed branch protection ruleset is active on main (PR required, no force push, no deletion, conversation resolution). CI workflow verified to run automatically on PRs. Privacy scan and protocol conformance checks enforced. Feature development can safely resume.

### v5.0.2 — 2026-07-11

Public CI + branch protection gate. Added `.github/workflows/validation.yml` with privacy scan and protocol conformance jobs running on every PR and push to main. Added `docs/MAINTAINERS.md` with branch protection rules. Added `docs/RELEASE_CHECKLIST.md`. Verified GitHub owner spelling consistency. Fresh-clone validated.

### v5.0.1 — 2026-07-11

Public hardening + privacy scan regression. Added `scripts/public-surface-scan.sh` with variant-aware pattern matching (PascalCase, camelCase, space, kebab, snake, lowercase). Anonymized 149 remaining personal project name references missed in v5.0.0. Added publication exclusions to `.gitignore`. Added issue templates. Fixed README and CHANGELOG to remove vault references. Fresh-clone validated.

### v5.0.0 — 2026-07-11

First public baseline of OpenCode Agent Protocol. This release starts the public SemVer line. Earlier v4.x work was internal development history and is not part of the public repository history. Sanitized: no personal project names, identity, or vault. Validated: 297 conformance tests pass. Includes: protocol kernel, lite delegation, senior operator loop, autopilot permissions, model routing, token efficiency, compaction safeguard, loop controller, reviewer trust, Protocol Atlas.

---

For earlier internal history, see the private development repository.
