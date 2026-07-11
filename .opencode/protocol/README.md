# OpenCode Protocol Documentation Index

**Last Updated:** 2026-05-27
**Current State:** SEALED (Configuration Authority v1.0.0, Model Routing v1.1.0)

---

## Quick Start for New Sessions

1. Read `.opencode/AGENTS.md` — Workspace behavioral authority
2. Read `<repo>/AGENTS.md` — Repo-specific truth
3. Read `<repo>/NOW.md` — Current status and active focus
4. Run conformance: `bash .opencode/scripts/workspace-protocol-guard.sh`

---

## Sealed Documents (Current Authority)

| Document | Phase | Status | Purpose |
|---|---|---|---|
| [Configuration Authority ADR](.opencode/adr/adr-opencode-config-authority.md) | C5 | ✅ SEALED v1.0.0 | Four-layer authority model (Global → Workspace → brain-config → Repo) |
| [C5 Seal Report](.opencode/protocol/phase-c5-seal-report.md) | C5 | ✅ SEALED | Final seal report: 0 FAIL, 0 WARN, 320 PASS |
| [C5.1 Release Verification](.opencode/protocol/phase-c5.1-release-verification.md) | C5.1 | ✅ SEALED | Git tag, fresh session simulation, conformance proof |
| [M2E Routing Seal](.opencode/protocol/phase-m2e-routing-seal.md) | M2E | ✅ SEALED v1.0.0 | Model routing configuration: 7 agents, 3 canary phases validated |
| [Runtime Fix Report](.opencode/protocol/opencode-runtime-fix-report.md) | M2E | ✅ FIXED | Doppler secrets + prompts symlink auto-loading |

---

## Phase C: Configuration Authority (Completed)

| Document | Phase | Status | Purpose |
|---|---|---|---|
| [C0: Effective Runtime Proof](.opencode/protocol/phase-c0-effective-runtime-proof.md) | C0 | ✅ Complete | Initial drift discovery: 50 WARN, 229 PASS |
| [C1: Conformance Guards](.opencode/protocol/phase-c1-conformance-guards.md) | C1 | ✅ Complete | 7 guard scripts built |
| [C1.5: Repo Exception Resolution](.opencode/protocol/phase-c1.5-repo-exception-resolution.md) | C1.5 | ✅ Complete | APA exception approved, stale artifacts cleaned |
| [C2: MCP Profile Policy](.opencode/protocol/phase-c2-mcp-profile-policy.md) | C2 | ✅ Complete | 5 MCP profiles defined, repo mapping created |
| [C2.5: MCP Runtime Effectiveness](.opencode/protocol/phase-c2.5-mcp-runtime-effectiveness.md) | C2.5 | ✅ Complete | MCP overlays runtime-effective |
| [C2.5 Seal + C3A Report](.opencode/protocol/phase-c2.5-seal-c3a-report.md) | C2.5/C3A | ✅ Complete | Workspace self-contained, global unchanged |
| [C3B: Effective Runtime Diff](.opencode/protocol/phase-c3b-effective-runtime-diff.md) | C3B | ✅ Complete | No unintended behavior changes |
| [C5: Seal Report](.opencode/protocol/phase-c5-seal-report.md) | C5 | ✅ SEALED | Final seal: 0 FAIL, 0 WARN, 320 PASS |
| [C5.1: Release Verification](.opencode/protocol/phase-c5.1-release-verification.md) | C5.1 | ✅ SEALED | Git tag, fresh session proof |

---

## Phase M: Model Routing (Completed)

| Document | Phase | Status | Purpose |
|---|---|---|---|
| [M2A: Routing Evidence](.opencode/protocol/phase-m2a-routing-evidence.md) | M2A | ✅ Complete | Task taxonomy, model matrix, shadow router spec |
| [M2B: Explorer Canary](.opencode/protocol/phase-m2b-explorer-canary.md) | M2B | ✅ PASS | deepseek-v4-flash validated for read-only exploration |
| [M2C: Reviewer Canary](.opencode/protocol/phase-m2c-reviewer-canary.md) | M2C | ✅ PASS | glm-5.1 validated for review/risk tasks |
| [M2D: Implementer Canary](.opencode/protocol/phase-m2d-implementer-canary.md) | M2D | ✅ PASS | qwen3.5-plus validated for bounded implementation |
| [M2E: Routing Seal](.opencode/protocol/phase-m2e-routing-seal.md) | M2E | ✅ SEALED v1.0.0 | Routing sealed: 319 PASS, 0 FAIL, 0 WARN |
| [M3A: Dependency Inventory](.opencode/protocol/phase-m3a-dependency-inventory.md) | M3A | ✅ Complete | All Alibaba/Bailian references classified |
| [M3B: Health Verification](.opencode/protocol/phase-m3b-health-verification.md) | M3B | ✅ Complete | 6/7 models healthy, implementer broken (429) |
| [M3C: Cleanup + Hotfix](.opencode/protocol/phase-m3c-cleanup-report.md) | M3C | ✅ Complete | Implementer hotfix, Bailian decommissioned |
| [M3D: Challenger Canary](.opencode/protocol/phase-m3d-challenger-canary.md) | M3D | ✅ Complete | 3 challengers tested, no promotion |
| [M3E: Final Seal](.opencode/protocol/phase-m3e-final-seal.md) | M3E | ✅ SEALED v1.1.0 | Final seal: 319 PASS, 0 FAIL, 0 WARN, tag created |

---

## Phase P: Optimization (In Progress)

| Document | Phase | Status | Purpose |
|---|---|---|---|
| [P0.5: Evidence Reconciliation](.opencode/protocol/phase-p0.5-evidence-reconciliation.md) | P0.5 | ✅ Complete | Verified routing seal, reconciled conformance count |
| [P1A: Git Hygiene Cleanup](.opencode/protocol/phase-p0.5-p1-report.md) | P1A | ✅ Complete | OpenCode files committed, legacy files cleaned |
| [P1B: Protocol Documentation Index](.opencode/protocol/README.md) | P1B | ✅ Complete | This file |
| [P1C: Helper Prompt Audit](.opencode/protocol/phase-p1c-helper-prompt-audit.md) | P1C | ✅ Complete | MCP profile awareness gap identified |
| [P1.5: Prompt Eval Fixtures](.opencode/protocol/phase-p1.5-prompt-eval-fixtures.md) | P1.5 | ✅ Complete | 31 fixtures created across 6 helpers |
| [P1.6: Prompt Updates](.opencode/protocol/phase-p1.6-prompt-updates.md) | P1.6 | ✅ Complete | MCP awareness + escalation rules added |
| [P1.7: Prompt Eval Execution](.opencode/protocol/phase-p1.7-prompt-eval-results.md) | P1.7 | ✅ Complete | 29 PASS, 2 WARN (accepted), 0 FAIL |
| [P1.8: Helper Prompts Seal](.opencode/protocol/phase-p1.8-helper-prompts-seal.md) | P1.8 | ✅ SEALED v1.0.0 | Helper prompts sealed, tag created |
| [P2A: CI Design](.opencode/protocol/phase-p2a-ci-design.md) | P2A | ✅ Complete | Guard tiering designed (Tier 1/2/3) |
| [P2: CI Conformance Integration](.opencode/protocol/phase-p2-ci-conformance.md) | P2 | ✅ Complete | Local pre-commit hook + GitHub Actions workflow |
| [P2.5: CI Hardening](.opencode/protocol/phase-p2.5-ci-hardening.md) | P2.5 | ✅ Complete | Hook activated, CI hardened, non-mutating, deterministic |
| [P3A: Metrics Schema](.opencode/protocol/phase-p3a-metrics-schema.md) | P3A | ✅ Complete | Privacy-safe schema defined, retention policy documented |
| [P3B: Local Metrics Capture](.opencode/protocol/phase-p3b-local-metrics.md) | P3B | ✅ Complete | Lightweight capture script integrated, non-blocking |
| [P3C: Cost/Token Estimation](.opencode/protocol/phase-p3c-cost-token-estimation.md) | P3C | ✅ Complete | Source/confidence fields, local rate card, no fake precision |
| [P3D: Performance Baselines](.opencode/protocol/phase-p3d-performance-baselines.md) | P3D | ✅ Complete | Baseline reporting, sample-size rules, non-blocking thresholds |
| [O1: Workspace Topology](.opencode/protocol/phase-o1-workspace-topology.md) | O1 | ✅ Complete | Folder map, orchestrator documentation, future-agent-safe |
| [O2: Multi-Agent Coordination](.opencode/protocol/phase-o2-multi-agent-coordination.md) | O2 | ✅ Complete | Branch rules, protected files, readiness gate, conflict prevention |

---

## Superseded Documents

| Document | Superseded By | Reason |
|---|---|---|
| `CAPABILITY_CERTIFICATION.md` | M2E Routing Seal | Routing now sealed with canary evidence |
| `CAPABILITY_DRIFT_LOG.md` | P0.5 Evidence Reconciliation | Drift now tracked via conformance guards |
| `DAILY_USE_CERTIFICATION.md` | C5.1 Release Verification | Daily use now covered by runtime fix |
| `M9_FRESH_SESSION_SMOKE_TEST.md` | C5.1 Release Verification | Fresh session proof now part of C5.1 |
| `M10_VAULT_PROMOTION.md` | N/A | Vault promotion separate track |
| `UI_UX_FE_PROTOCOL_CLOSURE.md` | N/A | UI/UX protocol separate track |

---

## Key Policy Files

| File | Purpose |
|---|---|
| `.opencode/policies/authority-model.json` | Four-layer authority model definition |
| `.opencode/policies/mcp-profiles.json` | 5 MCP profiles (baseline, ui_ux, research, automation, apa_product_factory) |
| `.opencode/policies/repo-mcp-profiles.json` | Repo-to-profile mapping (14 repos) |
| `.opencode/policies/repo-exceptions.json` | Approved repo exceptions (5 repos) |
| `.opencode/policies/known-c0-drift.json` | 20 known drift items (all classified) |
| `.opencode/policies/model-routing-shadow.json` | Shadow router spec (M2A) |
| `.opencode/policies/agent-roster.json` | 7 agent definitions with models, prompts, permissions |
| `.opencode/policies/prompt-baseline.json` | Prompt checksum baseline |

---

## Conformance Guards

| Guard | Checks | Purpose |
|---|---|---|
| `effective-runtime-diff.sh` | 29 | Workspace self-contained behavioral authority |
| `mcp-policy-guard.sh` | 37 | MCP state matches profile policy |
| `brain-routing-alignment.sh` | 13 | brain-config defaults match opencode.json |
| `agent-roster-guard.sh` | 54 | 7 agents resolvable with correct models/prompts/permissions |
| `prompt-mirror-drift.sh` | 41 | Prompt checksums match across global/workspace |
| `repo-exception-guard.sh` | 93 | Repo .opencode/ contains only allowed content |
| `config-authority-guard.sh` | 59 | Each layer contains only allowed keys |

**Run all guards:** `bash .opencode/scripts/workspace-protocol-guard.sh`

---

## Git Tags

| Tag | Commit | Purpose |
|---|---|---|
| `opencode-config-authority-v1.0.0` | 78eb3a5 | Configuration authority model sealed |
| `opencode-routing-v1.0.0` | 79565e3 | Model routing configuration sealed (v1.0.0) |
| `opencode-routing-v1.1.0` | 42c6bcd | Implementer hotfix + Bailian decommission (v1.1.0) |
| `opencode-helper-prompts-v1.0.0` | *(latest)* | Helper prompts sealed after P1.7 fixture execution |

---

## Next Steps (Planned)

| Phase | Scope | Status |
|---|---|---|
| P1A | Git hygiene cleanup | ✅ Complete |
| P1B | Protocol documentation index | ✅ Complete (this file) |
| P1C | Helper prompt audit only | ⏳ Pending |
| P1.5 | Helper prompt eval fixtures | ⏳ Planned |
| P1.6 | Safe helper prompt update | ⏳ Planned |
| P2 | CI conformance integration | ⏳ Planned |
| P3 | Performance tracking | ⏳ Planned |
| P4 | Observability | ⏳ Planned |
| P5 | Automated recovery | ⏳ Planned |
