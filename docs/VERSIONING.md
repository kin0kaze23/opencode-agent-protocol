# Versioning Policy

> **How versions work in the OpenCode Agent Protocol.**

## Current Policy (v4.x — Transitional)

During v4.x development, versions follow an internal pattern:

| Component | Meaning | Example |
|-----------|---------|---------|
| Major (4) | Protocol generation | v4.x.x |
| Minor | New protocol capability | v4.50 = Core v1 Hardening |
| Patch | Bugfix, docs, validation, release closure | v4.52.1 = Safe Cleanup |

### v4.x Rules

- v4.x versions are pre-public-release
- No SemVer guarantee during v4.x
- v4.x tags are immutable historical markers
- Not all v4.x versions have Git tags (v4.20-v4.32 were docs-only)

## Future Policy (v5.0.0+ — Full SemVer)

Starting at v5.0.0, the protocol follows standard Semantic Versioning:

| Version Component | Meaning | Example |
|-------------------|---------|---------|
| **MAJOR** | Public baseline or breaking protocol change | v5.0.0 = first public-ready release |
| **MINOR** | New protocol capability | v5.1.0 = cross-model eval batch |
| **PATCH** | Bugfix, docs fix, validation fix, release closure | v5.0.1 = hotfix |

### v5.0.0 Transition Criteria

v5.0.0 is justified when the repo is:

- ✅ Clean (no machine-specific paths)
- ✅ Portable (fresh clone works)
- ✅ Documented (README, INSTALLATION, OPERATING_GUIDE, QUICKSTART)
- ✅ Licensed (LICENSE, SECURITY.md, CONTRIBUTING.md)
- ✅ Installable (bootstrap script, verify script)
- ✅ Tag-normalized (release history coherent)
- ✅ Safe to open-source (no secrets, no private paths)

### After v5.0.0

- MAJOR: breaking protocol changes, public baseline shifts
- MINOR: new capabilities (new eval types, new gate types, new routing dimensions)
- PATCH: bugfixes, documentation, validation fixes, release closure

## Retrospective Tag Policy

### Existing Tags

- Do not move or rename existing v4.x tags
- Tags v4.20.1 through v4.32 were backfilled in v4.55 as retrospective releases
- v4.20 and v4.31 are documented as docs-only releases without Git tags (no separate commit)
- Tags v4.28.1 through v4.54.1 have Git tags and GitHub Releases
- All v4.x tags are immutable historical markers

### Legacy Tags

The following legacy tags exist from early development and are preserved for history:

- `archive/*` — early experimental archives
- `oc-l.*` — early OpenCode launcher checkpoints
- `oc-opt.*` — early optimization checkpoints
- `opencode-config-authority-v1.0.0` — config authority seal
- `opencode-go-release1-*` — OpenCode Go release 1 markers
- `opencode-helper-prompts-v1.0.0` — helper prompts seal
- `opencode-routing-*` — early routing version markers (v4.9.2 through v4.19.1)
- `opencode-v4.9.2` — early protocol version
- `stew-l.*` — early steward checkpoints

These tags are **not** part of the v4.x SemVer lineage. They are preserved for historical reference only. Starting at v5.0.0, only clean `v*.*.*` SemVer tags will be used.
- Tags v4.20 through v4.32 are documented in RELEASES.md but may not have Git tags (docs-only releases)
- Tags v4.34.2 through v4.51.1 have Git tags and GitHub Releases

### Backfill Policy

- Backfill only if commit SHAs can be confidently identified via `git log --grep`
- Mark all backfilled releases as retrospective in release notes
- Prefer accurate history over perfect-looking history
- Do not fabricate tags where commit mapping is uncertain

## Release Artifacts

Every release gets:

| Artifact | Location | Purpose |
|----------|----------|---------|
| Git tag | `git tag -a v<version>` | Immutable pointer |
| GitHub Release | GitHub Releases UI | Tagged release with notes |
| Vault snapshot | `vault/protocols/opencode/snapshots/<version>/protocol.md` | Protocol description for rollback |
| Vault CHANGELOG | `vault/protocols/opencode/CHANGELOG.md` | Detailed history |
| Vault VERSIONS.md | `vault/protocols/opencode/VERSIONS.md` | Version registry |
| RELEASES.md | Root | Release index and checklist |

## Release Checklist

1. Verify (all conformance tests pass)
2. Protocol Atlas version/count check
3. Update CHANGELOG
4. Tag
5. Update RELEASES.md
6. Version coherence check (AGENTS.md, rules.md, brain-config.json, NOW.md)
7. Vault closure (snapshot, CHANGELOG, VERSIONS.md)
