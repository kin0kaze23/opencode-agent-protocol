# Changelog

All notable changes to the OpenCode Agent Protocol are documented here.

## Source-of-Truth Policy

| File | Purpose | Authority |
|------|---------|-----------|
| `CHANGELOG.md` (this file) | Public-facing release summary | Public |
| `RELEASES.md` | Release process, checklist, and release index | Process |

## Recent Releases

### v5.3.0 — 2026-07-11

Config schema validation + docs drift checks. Added `scripts/validate-docs-drift.sh` (117 checks: file references, version consistency, diagram integrity, doc links). Added `scripts/validate-config-schema.sh` (40 checks: required files, JSON/YAML validity, agent roles, CI jobs). Added `scripts/validate-claims-evidence.sh` (17 checks: disallowed claim patterns, evidence docs, case studies). Expanded CI from 2 to 5 required jobs. Added `docs/VALIDATION.md`. Fixed 1 real docs drift issue caught by the new validator. Fresh-clone validated.

### v5.2.0 — 2026-07-11

Evidence pack + failure modes + threat model. Added `docs/CASE_STUDIES.md` with 3 public-safe case studies (privacy scan regression, repeatable release process, agent topology). Added `docs/EVIDENCE.md` with measured/illustrative workflow evidence. Added `docs/FAILURE_MODES.md` documenting 8 known failure modes with symptoms, risks, mitigations, and validation commands. Added `docs/THREAT_MODEL.md` covering 9 threat categories (secrets leakage, personal data leakage, prompt injection, unsafe automation, destructive commands, supply chain, malicious PRs, model hallucination, over-permissive actions). Updated README with evidence/limitations section. Updated CLAIMS.md with new allowed claims. Fresh-clone validated.

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
