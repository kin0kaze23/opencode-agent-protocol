# Changelog

All notable changes to the OpenCode Agent Protocol are documented here.

## Source-of-Truth Policy

| File | Purpose | Authority |
|------|---------|-----------|
| `CHANGELOG.md` (this file) | Public-facing release summary | Public |
| `RELEASES.md` | Release process, checklist, and release index | Process |

## Recent Releases

### v5.5.3 — 2026-07-14

Fresh-clone runtime install hardening. Fixed cross-platform launcher compatibility in `opencode-safe-launch.sh` — added OS detection (Darwin/Linux), cross-platform memory check (`/proc/meminfo` on Linux, `memory_pressure`/`vm_stat` on macOS), cross-platform `stat` command (`stat -c %Y` on Linux, `stat -f %m` on macOS), and cross-platform date parsing (`date -d` on Linux, `date -j -f` on macOS). Added `.opencode/package.json` to match existing `package-lock.json` (fixes broken `npm install`). Removed stale `git submodule update --init --recursive` and vault submodule references from QUICKSTART.md and INSTALLATION.md (public repo has no submodules). Replaced all author-specific model IDs in `opencode.json` with `YOUR_PROVIDER/YOUR_*_MODEL` placeholders. Added `scripts/setup.sh` — first-run setup script that detects OS, checks prerequisites (git, python3, node, jq, OpenCode CLI, lsof), generates shell alias snippets, checks provider env vars, and prints next steps. Supports `--check` flag for prerequisite-only validation. Updated README with setup.sh in Quick Start, Node.js/jq in prerequisites, placeholder model ID documentation, and MCP server first-run note. Updated FIRST_RUN_CHECKLIST with setup.sh step and provider configuration guidance. Updated CLAIMS.md with cross-platform launcher, setup script, and placeholder model claims. Fresh-clone validated.

### v5.5.2 — 2026-07-12

Harness/loop onboarding pack. Added `docs/HARNESS_AND_LOOP.md` with two-layer architecture (harness = stable files/rules/validators/CI, loop = goal → plan → act → verify → repair → review → merge). Added `examples/loop-runner/minimal-loop.sh` — illustrative loop runner showing Plan → Act → Verify → Review pattern. Added `docs/PROGRESSIVE_ONBOARDING.md` — 10-stage path from clone to first useful workflow. Added Failure Mode #9: State-Drift Repair Loop (same iteration repeats because state on disk did not capture progress). Added concrete config examples (minimal docs-only, small app bugfix, stricter high-risk) to `examples/config/README.md`. Updated README with harness/loop section. Updated CLAIMS.md. Fresh-clone validated.

### v5.5.1 — 2026-07-11

Public runtime onboarding + portability clarification. Updated README with prerequisites section clarifying that this is a protocol layer requiring OpenCode as runtime. Added `docs/OWN_MODEL_SETUP.md` with provider-agnostic setup guide for OpenAI, Anthropic, and custom providers. Added `examples/config/` with template configs (brain-config, model-routing-policy, opencode.json). Cleaned `.opencode/AGENTS.md` and `.opencode/rules.md` of internal-only references (vault, owner-memory, WORKSPACE_MAP) — replaced with generic equivalents. Updated `docs/VALIDATION.md` with test tier classification (Tier 1: public self-contained, Tier 2: CI-required, Tier 3: optional workspace). Added `docs/PUBLIC_SYNC_POLICY.md` documenting internal/public repo relationship. Added `docs/DOGFOODING_LOG_TEMPLATE.md` for recording daily-use evidence. Updated `docs/CLAIMS.md` with new allowed claims (OpenCode protocol layer, provider-adaptable, daily-use ready) and disallowed claims (turnkey any-model support, works without OpenCode, no setup required). Fresh-clone validated.

### v5.5.0 — 2026-07-11

External review pilot + feedback triage. Added `docs/EXTERNAL_REVIEW_PILOT.md` with reviewer profile, goals, timeline, and first-run steps. Added `docs/REVIEWER_INVITE_TEMPLATE.md` for inviting reviewers. Added `docs/FEEDBACK_TRIAGE.md` with classification categories and priority levels (P0–P3). Added `docs/REVIEW_FEEDBACK.md` (ready for first cycle). Configured branch protection to require all 10 matrix CI checks (5 jobs × 2 environments). Updated `docs/MAINTAINERS.md` with exact matrix check names. Updated README with external reviewers section. Fresh-clone validated.

### v5.4.0 — 2026-07-11

External review readiness + multi-environment validation. Expanded CI to run on both Ubuntu and macOS (5 jobs × 2 environments = 10 CI checks per PR). Added `docs/EXTERNAL_REVIEW_GUIDE.md` with reviewer onboarding instructions. Added `docs/FIRST_RUN_CHECKLIST.md` for 15-minute clone-to-validated flow. Added `docs/DEMO_WALKTHROUGH.md` linking to 5 example workflows. Added `.github/ISSUE_TEMPLATE/external_review_feedback.md` with structured feedback fields. Updated README with external review section. Fresh-clone validated.

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
