# Protocol Conformance Suite

**Purpose:** Mechanically verify protocol compliance for observable contract behavior.

**Scope:** Local-safe tests only. No remote side effects, no PR creation, no deploy execution.

---

## Test Categories

| Category | Tests | What It Verifies |
|----------|-------|------------------|
| `smoke.sh` | 6 tests | Basic protocol sanity (startup, preflight, plan stop) |
| `guarded-local.sh` | 14 tests | Full local command behavior (implement, gates, review, checkpoint, verification-before-recommendation) |
| `failure-recovery.sh` | 7 tests | Edge cases (dirty state, gate failure, approval boundaries) |
| `external-research-limitation.sh` | 7 tests | External research guardrails, approved-search routing, webfetch deny, and honest OUT-OF-SCOPE behavior |
| `implementation-readiness.sh` | 7 tests | Runtime-authority, touch-list, and readiness-gating safeguards |
| `elite-ops.sh` | 8 tests | Lanes, risk scoring, budgets, touch-list expansion, branch isolation, adaptive verification, and multi-repo planning |
| `environment-coherence.sh` | 8 tests | Registry authority, bootstrap parity, skill-loading coherence, writer/security runtime policy, and approved research MCP metadata |
| `subagent-coherence.sh` | 6 tests | Active helper roster, naming consistency, spec-backed delegation, specialist demotion routing |
| `global-opencode-runtime.sh` | 7 tests | Launcher-visible global OpenCode agent roster, helper models, prompt files, restart staleness detection, and approved research MCP sync |
| `benchmarking-ops.sh` | 7 tests | Benchmark rubric/schema, expanded gold corpus, adversarial fixtures, helper ROI probes, simulations, checkpoint telemetry, scoped SAST |
| `adversarial-ops.sh` | 3 tests | Executable adversarial harness for refusal, conflict, and SAST-sensitive fixtures |
| `runtime-simulations.sh` | 3 tests | FAST, STANDARD, HIGH-RISK, and `/debug` protocol scenario validation |
| `benchmark-aggregation.sh` | 3 tests | Telemetry aggregation and protocol health snapshot generation |
| `guardrail-enforcement.sh` | 6 tests | Prompt-injection refusal, fail-safe conflicts, root-cause circuit breaker, freshness review, narrow decision logging, telemetry-first policy |
| `discipline-ops.sh` | 6 tests | Structured rollback recipes, compaction anchors, continuity confidence, abbreviated FAST preflight, approval batching, lifecycle cleanup, phase-based progress signals |
| `behavior-parity.sh` | 25 tests | GitGuard enforcement, path-based auto-activation, session-end checkpoint (Phase 1 Claude Code parity) |
| `git-guard-enforcement.sh` | 7 tests | Mechanical pre-push hook enforcement: blocks main/master push, allows feature branches, idempotent install, audit detection |
| `git-guard-wrapper.sh` | 16 tests | Execution wrapper enforcement: blocks --no-verify, --force, -f, HEAD:main, HEAD:master, reset --hard, clean -fd; allows safe commands; override mechanism |
| `git-guard-compliance.sh` | 25 tests | Wrapper-usage compliance: /implement, /ship, /checkpoint flows reference wrapper; infrastructure checks; cross-flow consistency |
| **Config Authority Guards (Phase C1)** | | |
| `effective-runtime-diff.sh` | 29 checks | Effective OpenCode behavior across launch contexts (model, agents, MCP, compaction, runtime settings) |
| `mcp-policy-guard.sh` | 37 checks | MCP server state matches assigned repo profile; no orphan servers; global/workspace drift is intentional |
| `brain-routing-alignment.sh` | 13 checks | brain-config.json defaults match opencode.json (model, helpers, orchestrator, budgets, eval, fallback) |
| `agent-roster-guard.sh` | 54 checks | All 7 agents resolvable, correct models, prompts, permissions, helper roster |
| `prompt-mirror-drift.sh` | 36 checks | Prompt checksums match across global, workspace, and baseline |
| `repo-exception-guard.sh` | 95 checks | Repo .opencode/ folders contain only allowed content (hooks) |
| `config-authority-guard.sh` | 51 checks | Each config layer contains only what it is allowed to contain |

---

## Running Tests

```bash
# Smoke tests (fast sanity check)
bash .opencode/conformance/tests/smoke.sh

# Full local suite (guarded pilot)
bash .opencode/conformance/tests/guarded-local.sh

# Edge cases and failure recovery
bash .opencode/conformance/tests/failure-recovery.sh

# External research limitation safeguards
bash .opencode/conformance/tests/external-research-limitation.sh

# All tests
bash .opencode/conformance/tests/run-all.sh

# Implementation-readiness safeguards only
bash .opencode/conformance/tests/implementation-readiness.sh

# Elite operating-model safeguards
bash .opencode/conformance/tests/elite-ops.sh

# Environment coherence safeguards
bash .opencode/conformance/tests/environment-coherence.sh

# Subagent coherence safeguards
bash .opencode/conformance/tests/subagent-coherence.sh

# Launcher runtime coherence safeguards
bash .opencode/conformance/tests/global-opencode-runtime.sh

# Benchmarking and adversarial safeguards
bash .opencode/conformance/tests/benchmarking-ops.sh

# Executable adversarial harness
bash .opencode/conformance/tests/adversarial-ops.sh

# Runtime simulation safeguards
bash .opencode/conformance/tests/runtime-simulations.sh

# Benchmark aggregation and protocol health reporting
bash .opencode/conformance/tests/benchmark-aggregation.sh

# Guardrail enforcement safeguards
bash .opencode/conformance/tests/guardrail-enforcement.sh

# Discipline-layer safeguards
bash .opencode/conformance/tests/discipline-ops.sh

# Behavior parity (Phase 1 Claude Code parity)
bash .opencode/conformance/tests/behavior-parity.sh

# GitGuard mechanical enforcement (sandbox test)
bash .opencode/conformance/tests/git-guard-enforcement.sh

# GitGuard execution wrapper (adversarial tests)
bash .opencode/conformance/tests/git-guard-wrapper.sh

# Config Authority Guards (Phase C1)
# Run all guards in audit mode
bash .opencode/conformance/tests/effective-runtime-diff.sh --mode audit
bash .opencode/conformance/tests/mcp-policy-guard.sh --mode audit
bash .opencode/conformance/tests/brain-routing-alignment.sh --mode audit
bash .opencode/conformance/tests/agent-roster-guard.sh --mode audit
bash .opencode/conformance/tests/prompt-mirror-drift.sh --mode audit
bash .opencode/conformance/tests/repo-exception-guard.sh --mode audit
bash .opencode/conformance/tests/config-authority-guard.sh --mode audit

# Run all guards in enforce mode (post-C5)
bash .opencode/conformance/tests/effective-runtime-diff.sh --mode enforce
# ... etc
```

---

## Test Output

Results are written to `.opencode/conformance/results/`:

```
results/
├── smoke-<timestamp>.md
├── guarded-local-<timestamp>.md
├── failure-recovery-<timestamp>.md
├── external-research-limitation-<timestamp>.md
├── implementation-readiness-<timestamp>.md
├── elite-ops-<timestamp>.md
├── environment-coherence-<timestamp>.md
├── subagent-coherence-<timestamp>.md
├── global-opencode-runtime-<timestamp>.md
├── benchmarking-ops-<timestamp>.md
├── adversarial-ops-<timestamp>.md
├── runtime-simulations-<timestamp>.md
├── benchmark-aggregation-<timestamp>.md
├── guardrail-enforcement-<timestamp>.md
└── discipline-ops-<timestamp>.md
```

Each result file contains:
- Test ID and name
- Expected vs observed behavior
- PASS/FAIL verdict
- Evidence (output snippets, file paths, git hashes)

---

## What These Tests Verify

### Observable Contracts (YES)

- Preflight block presence and completeness (full 13 fields, with bounded FAST-lane abbreviation metadata)
- File creation/modification (PLAN.md, NOW.md, etc.)
- Git effects (commits, vault persistence)
- Output format (severity tags, evidence classification)
- Stop behavior (plan waits for approval, ship waits for approval)
- ADR compliance (canonical state reads)
- Runtime-authority verification rules
- Contract touch-list completeness rules
- `implementation-ready` gating rules
- Lane, risk-score, and autonomy-budget requirements
- Touch-list expansion disclosure rules
- Branch/worktree isolation and rollback-note requirements
- Verification-profile routing
- Registry authority and deprecated-path cleanup
- Bootstrap/skill-loading coherence
- Single-writer runtime enforcement metadata
- Lane-based security enforcement metadata
- Active helper roster coherence and naming alignment
- Spec-backed helper enforcement
- Launcher-visible OpenCode agent roster and helper model alignment
- Global prompt-file presence for active agents
- Benchmark rubric, schema, seed corpus, and adversarial fixtures
- Executable adversarial refusal/conflict harness
- Runtime simulation coverage for FAST, STANDARD, HIGH-RISK, and `/debug`
- Benchmark telemetry aggregation and protocol health snapshot generation
- Checkpoint benchmark telemetry and helper ROI metadata
- External research limitation and webfetch-deny enforcement
- Approved-search MCP routing for grounded external research
- Prompt-injection and jailbreak refusal policy
- Runtime-vs-policy fail-safe handling
- Repeated-root-cause circuit-breaker metadata
- Relevance-driven lesson freshness review
- Narrow durable-decision persistence
- Telemetry-first, warning-only token/cost policy
- Structured rollback recipe requirements
- Compaction continuity anchors
- Approval batching and phase-based progress metadata

### Internal Behavior (NO - Phase 3b+)

- Exact file-read order inside model
- True "preflight before internal exploration"
- Full browser automation
- Helper model orchestration
- Real PR creation
- Deploy command execution

---

## Test Design Principles

1. **Observable only** — Test what can be verified from output/files/git
2. **Local-safe** — No remote side effects
3. **Fast feedback** — Each test < 30 seconds
4. **Clear verdicts** — PASS/FAIL with evidence
5. **Reproducible** — Fixture-based, deterministic

---

## Status

| Milestone | Status |
|-----------|--------|
| ADR-001 (Canonical State) | ✅ Implemented |
| ADR-002 (Vault Persistence) | ✅ Runtime validated |
| Command-quality uplift | ✅ Implemented |
| Implementation-readiness safeguards | ✅ Implemented |
| Environment coherence safeguards | ✅ Implemented |
| Phase 3a (Local conformance) | ✅ Expanded |
| Phase 3b (Rich runtime tests) | ⏳ Deferred |
| Phase 4 (CI integration) | ⏳ Deferred |

---

**Version:** 3a-local-elite-env-v3-runtime-plus-proof  
**Last updated:** 2026-03-28
