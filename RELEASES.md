# Release Process

> **How to tag and release protocol versions.**

## Current Stable Version

**v4.55** — 2026-07-11

> **Status:** Release/tag normalization. 16 backfilled tags (v4.20.1-v4.32), legacy tag policy, release history verifier. 60 v4.x tags total. 818 tests, 0 failures.

## Release Artifact Types

| Artifact | Location | Purpose |
|----------|----------|---------|
| **Protocol snapshot** | `vault/protocols/opencode/snapshots/<version>/protocol.md` | Complete protocol description for rollback — every version gets one |
| **Changelog entry** | `vault/protocols/opencode/CHANGELOG.md` | Human-readable history of what changed |
| **Version registry entry** | `vault/protocols/opencode/VERSIONS.md` | Single index of all versions with status and test results |
| **GitHub tag** | `git tag -a v<version>` | Immutable pointer to a specific commit |
| **GitHub Release** | GitHub Releases UI | Tagged release with notes, visible on repo page |

**Rule:** Every protocol version gets a snapshot and changelog entry. Only significant releases (new capabilities, security fixes, breaking changes) get GitHub tags and releases. Minor documentation/cleanup versions are docs-only.

## Release Procedure

### 1. Verify

Before tagging a release, ALL of these must pass:

```bash
# Full conformance suite
bash scripts/verify-install.sh

# Workspace protocol guard
bash .opencode/scripts/workspace-protocol-guard.sh

# Environment verification
bash .opencode/scripts/verify-environment.sh --mode workspace
```

**Requirement:** 0 FAIL across all internal protocol tests.

### 1.5. Protocol Atlas Version/Count Check (v4.51.1)

Before tagging, verify the Protocol Atlas is current:

```bash
# Atlas version must match NOW.md version
ATLAS_VERSION=$(grep -oP 'v4\.\d+(\.\d+)?' docs/protocol/PROTOCOL_ATLAS.md | head -1)
NOW_VERSION=$(grep -oP 'v4\.\d+(\.\d+)?' NOW.md | head -1)
[ "$ATLAS_VERSION" = "$NOW_VERSION" ] || echo "MISMATCH: Atlas=$ATLAS_VERSION NOW=$NOW_VERSION"

# Atlas test count must not be obviously stale (≥800)
grep -oP '\d+ targeted tests?' docs/protocol/PROTOCOL_ATLAS.md | head -1

# Run Atlas conformance tests
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/scripts/validate-protocol-atlas.sh
```

**Stop if:** Atlas version does not match NOW.md version, or test count is obviously stale.

### 2. Update Changelog

Add the new version to `CHANGELOG.md` with:
- Version number and date
- Added/Changed/Fixed/Removed sections
- Verification summary

### 3. Tag

```bash
git tag -a v4.28.1 -m "v4.28.1 — Portable OpenCode Agent Protocol"
git push origin v4.28.1
```

### 4. Update RELEASES.md

Record the release in this file.

### 5. Version Coherence Check (v4.51.1)

Before closing the release, verify all version-bearing files are coherent:

```bash
# All must show the same version
grep 'Version:' .opencode/AGENTS.md
grep 'Version:' .opencode/rules.md
grep '"version"' .opencode/brain-config.json
head -1 NOW.md
```

**Stop if:** Any file shows a different version than the release being tagged.

### 6. Vault Closure (v4.51.1)

Ensure vault artifacts exist for the release:

```bash
# Snapshot must exist
ls vault/protocols/opencode/snapshots/<version>/protocol.md

# CHANGELOG must have entry
grep '<version>' vault/protocols/opencode/CHANGELOG.md

# VERSIONS.md must mark as Current
grep '<version>' vault/protocols/opencode/VERSIONS.md
```

**Stop if:** Any vault artifact is missing.

## Rollback

To rollback to a previous version:

```bash
# Revert to a specific tag
git checkout v4.27.3

# Or revert a specific commit
git revert <commit-hash>

# Re-sync global prompts
bash .opencode/scripts/sync-opencode-runtime.sh

# Verify
bash scripts/verify-install.sh
```

## Release History

| Version | Date | Summary | GitHub Tag | GitHub Release |
|---|---|---|---|---|
| v4.55 | 2026-07-11 | Release/tag normalization (16 backfilled tags, legacy tag policy, release history verifier) | pending | pending |
| v4.54.1 | 2026-07-11 | Rename execution validation (GitHub repo renamed, remote updated, fresh clone verified) | ✅ `v4.54.1` | ✅ Published |
| v4.54 | 2026-07-11 | Repo rename + product identity update (opencode-agent-protocol, public docs, clone URLs, non-affiliation disclaimer) | ✅ `v4.54` | ✅ Published |
| v4.53.3 | 2026-07-11 | Fresh-clone empty-state test fix (model-roi bootstrap, skip not fail, assert.sh TESTS_SKIPPED) | ✅ `v4.53.3` | ✅ Published |
| v4.53.2 | 2026-07-11 | Local/GitHub sync + public fresh-clone install test + agent topology (diagram, Atlas section, claims discipline) | ✅ `v4.53.2` | ✅ Published |
| v4.53.1 | 2026-07-10 | Repo structure cleanup / public surface reduction (untracked unrelated projects, archive, generated artifacts, stale files; added hygiene policy) | ✅ `v4.53.1` | ✅ Published |
| v4.53 | 2026-07-10 | Open-source readiness pack (LICENSE, SECURITY.md, CONTRIBUTING.md, public docs, machine-local cleanup, loop-controller bootstrap fix) | ✅ `v4.53` | ✅ Published |
| v4.52.2 | 2026-07-10 | Fresh-clone portability validation (fresh clone works, plugin paths relative, generated files handled) | ✅ `v4.52.2` | ✅ Published |
| v4.52.1 | 2026-07-10 | Safe cleanup + portability blocker removal (parameterized paths, .gitignore cleanup, machine-local config untracking) | ✅ `v4.52.1` | ✅ Published |
| v4.52 | 2026-07-10 | Repository hygiene audit / open-source readiness audit (6-phase cleanup plan) | ✅ `v4.52` | ✅ Published |
| v4.51.1 | 2026-07-10 | Operational consistency + friction polish (release closure fixes, entrypoint canary, docs_only/test_improvement routing, Atlas version checks) | ✅ `v4.51.1` | ✅ Published |
| v4.51 | 2026-07-10 | Regular controlled use pilot (first live use of Core v1 on real low-risk tasks, 6 friction points identified) | ✅ `v4.51` | ✅ Published |
| v4.50 | 2026-07-10 | Core v1 hardening release (P0 sample-warning fix, core v1 manifest, hardening report, 815 targeted tests) | ✅ `v4.50` | ✅ Published |
| v4.49.1 | 2026-07-10 | Real reviewer calibration validation (seed vs real separation, evidence_source, confidence calibration) | ✅ `v4.49.1` | ✅ Published |
| v4.49 | 2026-07-10 | Reviewer calibration / disagreement tracking (findings schema, analyzer, disagreement tracker, policy recommendations) | ✅ `v4.49` | ✅ Published |
| v4.48.2 | 2026-07-10 | Protocol Atlas render validation (10 SVGs rendered, syntax checks, How to Use section) | ✅ `v4.48.2` | ✅ Published |
| v4.48.1 | 2026-07-10 | Protocol Atlas / Visual System Map (10 Mermaid diagrams, validation script, 38 conformance tests) | ✅ `v4.48.1` | ✅ Published |
| v4.48 | 2026-07-10 | Live non-production pilot (6 new tests for cross-model selective coverage and best_observed validation) | ✅ `v4.48` | ✅ Published |
| v4.47.1 | 2026-07-10 | First cross-model simulation validation (awk fix, model name fix, 19 runs, 3 success, 16 unavailable) | ✅ `v4.47.1` | ✅ Published |
| v4.47 | 2026-07-09 | Benchmark expansion + cross-model eval runs (confidence calibration, cross-model run plan, cross-model runner) | ✅ `v4.47` | ✅ Published |
| v4.46.1 | 2026-07-09 | First model ROI routing validation (end-to-end pipeline proven, 667 targeted, 0 failures) | ✅ `v4.46.1` | ✅ Published |
| v4.46 | 2026-07-09 | Model ROI / routing optimizer (normalizer, analyzer, recommendation generator, advisory policy) | ✅ `v4.46` | ✅ Published |
| v4.45.1 | 2026-07-09 | First loop controller validation (state machine, stop conditions, repair policy verified) | ✅ `v4.45.1` | ✅ Published |
| v4.45 | 2026-07-09 | Loop engineering controller (bounded loop, 10 stop conditions, 6 repair policies, lesson extraction) | ✅ `v4.45` | ✅ Published |
| v4.44.2 | 2026-07-09 | Installer comment script inclusion hotfix (post-release-gate-comment.sh in installer file list) | ✅ `v4.44.2` | ✅ Published |
| v4.44.1 | 2026-07-09 | First real task replay validation (3 tasks scored, awk fix, result writeback) | ✅ `v4.44.1` | ✅ Published |
| v4.44 | 2026-07-09 | Agent task replay eval suite (9 benchmark tasks, scoring engine, scorecard, 87 conformance tests) | ✅ `v4.44` | ✅ Published |
| v4.43.1 | 2026-07-09 | Freshness snapshot hotfix (freshness metrics in snapshots) | ✅ `v4.43.1` | ✅ Published |
| v4.43 | 2026-07-09 | Evidence freshness / expiry workflow (4-level classification, stale reverts, freshness report) | ✅ `v4.43` | ✅ Published |
| v4.42 | 2026-07-08 | Enhanced trend analytics (historical comparison, regression detection, lifecycle timeline) | ✅ `v4.42` | ✅ Published |
| v4.41 | 2026-07-08 | Manual branch protection evidence capture (evidence config, validator, dashboard integration) | ✅ `v4.41` | ✅ Published |
| v4.40.1 | 2026-07-08 | Dashboard hotfix (baseline failure name extraction, owner actions section tracking) | ✅ `v4.40.1` | ✅ Published |
| v4.40 | 2026-07-08 | Dashboard / trend reporting (fleet manifest, dashboard generator, snapshot recorder) | ✅ `v4.40` | ✅ Published |
| v4.39 | 2026-07-08 | PR comments / annotations (sticky comment, protection status, owner action) | ✅ `v4.39` | ✅ Published |
| v4.38 | 2026-07-08 | Branch protection verifier + CODEOWNERS + protection report + strict mode | ✅ `v4.38` | ✅ Published |
| v4.37.2 | 2026-07-08 | Rollout closure + status semantics (release_status normalization, installer NOW.md fix) | ✅ `v4.37.2` | ✅ Published |
| v4.37.1 | 2026-07-08 | Rollout kit hotfix (workflow path rewriting, validator in installer, docs paths, test framework fix) | ✅ `v4.37.1` | ✅ Published |
| v4.37.0 | 2026-07-07 | Multi-repo release gate rollout kit (install/validate scripts, label fix) | ✅ `v4.37.0` | ✅ Published |
| v4.36.0 | 2026-07-07 | Reviewer trust hardening + branch protection guidance | ✅ `v4.36.0` | ✅ Published |
| v4.35.0 | 2026-07-07 | Reviewer evidence enforcement | ✅ `v4.35.0` | ✅ Published |
| v4.34.2 | 2026-07-07 | Release gate hotfix | ✅ `v4.34.2` | — |
| v4.34.0 | 2026-07-07 | GitHub PR release gate integration (workflow, job summary, artifact, blocking) | ✅ `v4.34.0` | — |
| v4.33.0 | 2026-07-07 | Content-aware sensitive change classification (PR #22) | ✅ `v4.33.0` | ✅ Published |
| v4.32 | 2026-07-07 | Production hardening + security/release gates (included in v4.33.0) | — | — (docs-only, included in v4.33.0) |
| v4.31 | 2026-07-06 | Cross-repo telemetry expansion | — | — (docs-only) |
| v4.30 | 2026-07-05 | Evidence-based routing optimization | — | — (docs-only) |
| v4.29 | 2026-07-04 | Agent eval telemetry + reviewer calibration | — | — (docs-only) |
| v4.28.1 | 2026-07-04 | GitHub portability + installable protocol package (PR #12) | ✅ `v4.28.1` | ✅ Published |
| v4.27.4a | 2026-07-04 | Guardrail + backup hygiene | — | — (docs-only) |
| v4.27.4 | 2026-07-04 | brain-config documentation extraction | — | — (docs-only) |
| v4.27.3 | 2026-07-04 | Command + routing simplification | — | — (docs-only) |
| v4.27.2 | 2026-07-04 | Environment consistency + runtime contract | — | — (docs-only) |
| v4.27.1 | 2026-07-04 | Protocol coherence closure | — | — (docs-only) |
| v4.27 | 2026-07-03 | Information architecture cleanup | — | — (docs-only) |
| v4.26 | 2026-07-03 | Usage-aware autonomy + model ROI telemetry | — | — (docs-only) |
| v4.25 | 2026-07-03 | Proactive quality + auto-test guidance | — | — (docs-only) |
| v4.24 | 2026-07-03 | Senior memory + pattern reuse | — | — (docs-only) |
| v4.23 | 2026-07-03 | Test intelligence + evidence-based review | — | — (docs-only) |
| v4.22 | 2026-07-03 | Senior operator loop + CI-first workflow | — | — (docs-only) |
| v4.21 | 2026-07-03 | Code intelligence + lesson retrieval | — | — (docs-only) |
| v4.20.1 | 2026-07-03 | Mechanical risk classification | — | — (docs-only) |
| v4.20 | 2026-07-03 | Lite Delegation Mode | — | — (docs-only) |

### TODO: v4.54 Tag Backfill

The following versions are documented in RELEASES.md but do not have Git tags:
- v4.20 through v4.32 (17 versions, all docs-only)

These should be backfilled in v4.54 only if commit SHAs can be confidently identified via `git log --grep`.
Mark all backfilled releases as retrospective in release notes.
