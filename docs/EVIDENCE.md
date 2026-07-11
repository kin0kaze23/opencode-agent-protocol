# Evidence

> **Purpose:** Measured and illustrative workflow evidence for the OpenCode Agent Protocol.
> **Last Updated:** 2026-07-11

---

## Evidence Scope

This document provides evidence for the case studies in [docs/CASE_STUDIES.md](CASE_STUDIES.md). All evidence is from the actual v5.0.0–v5.1.0 release sequence.

**Important:** Time estimates are labeled as illustrative where not precisely measured. No guaranteed productivity gains are claimed.

---

## Case Study 1: Privacy Scan Regression

### Task Type
Privacy regression prevention — variant-aware scanning

### Baseline (Manual) Workflow
1. Manually search for personal project names using `grep`
2. Check PascalCase, space, kebab, snake, lowercase variants individually
3. Easy to miss variants
4. No automated enforcement

### Harness-Assisted Workflow
1. Run `bash scripts/public-surface-scan.sh`
2. Scanner checks all variant forms automatically
3. CI enforces the scan on every PR
4. Branch protection blocks merge if scan fails

### Checks Run
| Check | Command | Result |
|-------|---------|--------|
| Public surface scan | `bash scripts/public-surface-scan.sh` | PASS |
| Negative scan test | Add blocked pattern to temp file, run scan | FAIL (correct) |
| CI Privacy Scan | GitHub Actions | PASS |

### Tests
- 0 personal project name references in fresh clone (all variant forms)
- Scanner correctly fails when blocked pattern is present

### Failure Caught
149 personal project name references with variant naming (space-separated, kebab-case, snake_case, lowercase) that were missed by the v5.0.0 PascalCase-only scan.

### Time Estimate
- **Illustrative:** Manual variant search would take ~30-60 minutes per release. Automated scan takes <5 seconds.

### Limitations
- Only catches known patterns — new project names must be added manually
- Does not scan git history or untracked files
- Exclusions for policy docs must be narrow and documented

---

## Case Study 2: Repeatable Release Process

### Task Type
Release management — 5 sequential releases (v5.0.0–v5.1.0)

### Baseline (Manual) Workflow
1. Manually verify no personal data
2. Manually run all tests
3. Manually update version files
4. Push directly to main
5. No enforced checks
6. No fresh-clone validation

### Harness-Assisted Workflow
1. Follow `docs/RELEASE_CHECKLIST.md`
2. Run local validation (privacy scan + conformance tests)
3. Create PR
4. CI runs Privacy Scan + Protocol Conformance automatically
5. Branch protection blocks merge until checks pass
6. Squash merge
7. Tag and release
8. Fresh-clone validation

### Checks Run
| Check | v5.0.0 | v5.0.1 | v5.0.2 | v5.0.3 | v5.1.0 |
|-------|--------|--------|--------|--------|--------|
| Privacy Scan | N/A | PASS | PASS | PASS | PASS |
| Protocol Conformance | N/A | N/A | N/A | PASS | PASS |
| Fresh-clone validation | PASS | PASS | PASS | PASS | PASS |
| Conformance tests | 297/297 | 297/297 | 297/297 | 297/297 | 297/297 |

### Tests
- 297 conformance tests pass on every release
- 0 personal data leaks across 5 releases
- 0 failed releases

### Failure Caught
- v5.0.0 had 149 missed personal project name references (caught and fixed in v5.0.1)
- v5.0.3 CI initially failed because `verify-install.sh` was not suitable for CI (fixed by removing it from CI workflow)
- v5.0.3 old v4-era workflows caused CI failures (fixed by removing them)

### Time Estimate
- **Illustrative:** Each release took ~15-30 minutes including validation, PR, CI wait, tag, and fresh-clone validation. Without the checklist, releases would be ad-hoc and error-prone.

### Limitations
- Release process is still manual (human follows checklist)
- No automated release pipeline
- CI wait time depends on GitHub Actions runner availability

---

## Case Study 3: Agent Topology for Safe Task Delegation

### Task Type
Protocol design — agent topology, lane selection, model routing

### Baseline (Manual) Workflow
1. No risk classification — all tasks treated the same
2. No lane selection — no proportional controls
3. No model routing — single model for everything
4. No reviewer policy — no independent review
5. No git guard — direct push to main possible
6. No CI enforcement — no automated checks

### Harness-Assisted Workflow
1. Orchestrator classifies risk (0-10+) and selects lane (DIRECT/FAST/STANDARD/HIGH-RISK)
2. Each lane has proportional controls (plan required, gates required, reviewer required)
3. Model routing assigns appropriate model based on task type
4. Reviewer independently checks HIGH-RISK changes
5. Git guard blocks unsafe operations
6. CI enforces privacy scan + protocol conformance

### Checks Run
| Check | Command | Result |
|-------|---------|--------|
| Loop Controller | `bash .opencode/conformance/tests/loop-controller.sh` | 96/96 PASS |
| Production Hardening | `bash .opencode/conformance/tests/production-hardening.sh` | 53/53 PASS |
| Agent Roster Guard | `bash .opencode/conformance/tests/agent-roster-guard.sh` | PASS |
| Protocol Atlas | `bash .opencode/conformance/tests/protocol-atlas.sh` | 48/48 PASS |

### Tests
- 297 total conformance tests validate protocol consistency
- 11 Protocol Atlas diagrams document the system visually

### Failure Caught
- v5.0.3: Old v4-era CI workflows had environment dependencies that failed in CI — caught by PR-based CI, fixed by removing old workflows

### Time Estimate
- **Illustrative:** Protocol design and implementation spanned multiple sessions. The conformance test suite catches regressions in <5 seconds.

### Limitations
- Model routing is advisory — does not enforce which model is used
- Reviewer policy is advisory — human judgment still required
- Protocol does not guarantee code quality — it provides guardrails
- Agent behavior depends on AI model adherence to instructions
