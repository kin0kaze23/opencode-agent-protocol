# Capability Catalog

> **Purpose:** Maps every public capability to its source files, configuration, validation tests, and CI coverage.
> **Last Updated:** 2026-07-11

---

## How to Read This Catalog

Each capability entry documents:

- **Status:** `stable` (production-ready), `advisory` (recommendations only), `experimental` (early-stage)
- **Source files:** Where the capability is defined
- **Configuration:** How to customize it
- **Validation:** Which test verifies it
- **CI coverage:** Whether CI enforces it on every PR
- **How to run:** The command to invoke it
- **Guarantees:** What it ensures
- **Does not guarantee:** What it does not ensure

---

## 1. Public Surface Scan

| Field | Value |
|-------|-------|
| **Status** | Stable |
| **Source** | `scripts/public-surface-scan.sh` |
| **Configuration** | Pattern list in the script; exclusions in `EXCLUDE_PATTERN` variable |
| **Validation** | Self-validating (exit 0 = clean, exit 1 = dirty) |
| **CI coverage** | Yes — `Privacy Scan` job in `.github/workflows/validation.yml` |
| **How to run** | `bash scripts/public-surface-scan.sh` |
| **Guarantees** | No personal project names, identity, secrets, or forbidden directories in tracked files |
| **Does not guarantee** | Protection against future patterns not yet in the scan list; does not scan untracked files |

---

## 2. Protocol Conformance

| Field | Value |
|-------|-------|
| **Status** | Stable |
| **Source** | `.opencode/conformance/tests/*.sh` (80+ test files) |
| **Configuration** | `.opencode/AGENTS.md`, `.opencode/rules.md`, `.opencode/brain-config.json` |
| **Validation** | Self-validating; `run-all.sh` aggregates all suites |
| **CI coverage** | Yes — `Protocol Conformance` job in `.github/workflows/validation.yml` |
| **How to run** | `bash .opencode/conformance/tests/protocol-atlas.sh` (or any individual test) |
| **Guarantees** | Protocol Atlas, production hardening, loop controller, and model ROI tests pass |
| **Does not guarantee** | Full runtime behavior in all environments; CI runs a subset of self-contained tests |

---

## 3. Protocol Atlas

| Field | Value |
|-------|-------|
| **Status** | Stable |
| **Source** | `docs/protocol/PROTOCOL_ATLAS.md`, `docs/protocol/diagrams/*.mmd`, `docs/protocol/diagrams/rendered/*.svg` |
| **Configuration** | N/A (documentation) |
| **Validation** | `.opencode/scripts/validate-protocol-atlas.sh`, `.opencode/conformance/tests/protocol-atlas.sh` |
| **CI coverage** | Yes — part of `Protocol Conformance` job |
| **How to run** | `bash .opencode/scripts/validate-protocol-atlas.sh` |
| **Guarantees** | 11 Mermaid diagrams exist, are non-empty, have valid syntax, and have rendered SVGs |
| **Does not guarantee** | Diagram accuracy against runtime behavior (manual review needed) |

---

## 4. Agent Topology

| Field | Value |
|-------|-------|
| **Status** | Stable |
| **Source** | `.opencode/AGENTS.md` (Protocol Kernel, Lane Selection, Senior Operator Loop), `.opencode/helper-roster.md` (helper roster) |
| **Configuration** | `.opencode/brain-config.json` (routing policy), `.opencode/model-registry.yaml` (model definitions) |
| **Validation** | `.opencode/conformance/tests/agent-roster-guard.sh`, `.opencode/conformance/tests/subagent-coherence.sh` |
| **CI coverage** | No (not in CI subset — requires local workspace context) |
| **How to run** | `bash .opencode/conformance/tests/agent-roster-guard.sh` |
| **Guarantees** | Helper roster is consistent with config; sub-agent definitions are coherent |
| **Does not guarantee** | Runtime agent behavior in production |

---

## 5. Model Routing Policy

| Field | Value |
|-------|-------|
| **Status** | Advisory |
| **Source** | `.opencode/model-registry.yaml`, `.opencode/config/model-routing-policy.recommended.yaml` |
| **Configuration** | Edit `model-registry.yaml` to add/change models; edit routing policy YAML for routing rules |
| **Validation** | `.opencode/conformance/tests/model-routing-coherence.sh`, `.opencode/conformance/tests/brain-routing-alignment.sh` |
| **CI coverage** | No (requires local model registry context) |
| **How to run** | `bash .opencode/conformance/tests/model-routing-coherence.sh` |
| **Guarantees** | Routing policy is internally consistent and matches brain-config |
| **Does not guarantee** | Model availability, latency, or quality in production |

---

## 6. Reviewer Calibration

| Field | Value |
|-------|-------|
| **Status** | Advisory |
| **Source** | `.opencode/config/reviewer-policy.recommended.yaml`, `.opencode/config/reviewer-trust-policy.yaml` |
| **Configuration** | Edit reviewer policy YAML files |
| **Validation** | `.opencode/conformance/tests/reviewer-calibration.sh`, `.opencode/conformance/tests/reviewer-calibration-scorecard.sh` |
| **CI coverage** | No (requires local eval context) |
| **How to run** | `bash .opencode/conformance/tests/reviewer-calibration.sh` |
| **Guarantees** | Reviewer policy is internally consistent |
| **Does not guarantee** | Review quality in production; human review still required for HIGH-RISK |

---

## 7. Loop Controller

| Field | Value |
|-------|-------|
| **Status** | Stable |
| **Source** | `.opencode/AGENTS.md` (Loop Controller section), `.opencode/conformance/tests/loop-controller.sh` |
| **Configuration** | Loop Run Contract template in `.opencode/templates/LOOP_RUN_CONTRACT.md` |
| **Validation** | `.opencode/conformance/tests/loop-controller.sh` |
| **CI coverage** | Yes — part of `Protocol Conformance` job |
| **How to run** | `bash .opencode/conformance/tests/loop-controller.sh` |
| **Guarantees** | Loop state machine, stop conditions, repair policy, and lesson extraction are defined and consistent |
| **Does not guarantee** | Loop execution quality in production |

---

## 8. Task Replay

| Field | Value |
|-------|-------| 
| **Status** | Stable |
| **Source** | `.opencode/evals/task-replay/` (task definitions, scoring, results) |
| **Configuration** | `.opencode/evals/task-replay/tasks.yaml` |
| **Validation** | `.opencode/conformance/tests/task-replay.sh` |
| **CI coverage** | No (requires local eval context) |
| **How to run** | `bash .opencode/conformance/tests/task-replay.sh` |
| **Guarantees** | Task replay scoring is consistent; no personal project names in task fixtures |
| **Does not guarantee** | Model performance on new tasks |

---

## 9. Production Hardening

| Field | Value |
|-------|-------|
| **Status** | Stable |
| **Source** | `.opencode/AGENTS.md` (Safety Rules, Lane Selection, Verification Expectations) |
| **Configuration** | `.opencode/config/gate-matrix.yaml`, `.opencode/config/token-budget.yaml` |
| **Validation** | `.opencode/conformance/tests/production-hardening.sh` |
| **CI coverage** | Yes — part of `Protocol Conformance` job |
| **How to run** | `bash .opencode/conformance/tests/production-hardening.sh` |
| **Guarantees** | Safety rules, lane selection, escalation triggers, and verification expectations are defined and consistent |
| **Does not guarantee** | Runtime enforcement (policies are advisory unless enforced by CI/hooks) |

---

## 10. Evidence-Based Routing

| Field | Value |
|-------|-------|
| **Status** | Advisory |
| **Source** | `.opencode/AGENTS.md` (Model Routing section), `.opencode/config/model-routing-policy.recommended.yaml` |
| **Configuration** | Edit routing policy YAML |
| **Validation** | `.opencode/conformance/tests/evidence-based-routing.sh` |
| **CI coverage** | No (requires local eval context) |
| **How to run** | `bash .opencode/conformance/tests/evidence-based-routing.sh` |
| **Guarantees** | Routing recommendations are backed by evidence |
| **Does not guarantee** | Evidence is current or applicable to all environments |

---

## 11. Release Checklist

| Field | Value |
|-------|-------|
| **Status** | Stable |
| **Source** | `docs/RELEASE_CHECKLIST.md` |
| **Configuration** | N/A (process documentation) |
| **Validation** | Manual (follow the checklist) |
| **CI coverage** | No (manual process) |
| **How to run** | Follow `docs/RELEASE_CHECKLIST.md` before each release |
| **Guarantees** | Pre-release, version update, tag, and post-release steps are documented |
| **Does not guarantee** | Human adherence to the checklist |

---

## 12. Branch Protection Policy

| Field | Value |
|-------|-------|
| **Status** | Stable |
| **Source** | `docs/MAINTAINERS.md` |
| **Configuration** | GitHub ruleset (configured via GitHub Settings or API) |
| **Validation** | `gh api repos/{owner}/{repo}/rulesets` |
| **CI coverage** | N/A (GitHub-enforced, not CI) |
| **How to run** | Verify via `gh api repos/kin0kaze23/opencode-agent-protocol/rulesets` |
| **Guarantees** | PR required before merge, no force push, no deletion, conversation resolution required |
| **Does not guarantee** | Code quality (that's what CI checks are for) |

---

## 13. Lite Delegation Mode

| Field | Value |
|-------|-------|
| **Status** | Stable |
| **Source** | `.opencode/AGENTS.md` (Lite Delegation Mode section), `.opencode/rules.md` |
| **Configuration** | Lane selection is automatic based on risk score and file count |
| **Validation** | `.opencode/conformance/tests/lite-delegation-mode.sh` |
| **CI coverage** | No (requires local context) |
| **How to run** | `bash .opencode/conformance/tests/lite-delegation-mode.sh` |
| **Guarantees** | DIRECT/FAST/STANDARD/HIGH-RISK lanes are defined with proportional controls |
| **Does not guarantee** | Correct lane selection in practice (advisory) |

---

## 14. Senior Operator Loop

| Field | Value |
|-------|-------|
| **Status** | Stable |
| **Source** | `.opencode/AGENTS.md` (Senior Operator Loop section) |
| **Configuration** | N/A (behavioral protocol) |
| **Validation** | `.opencode/conformance/tests/senior-operator-loop.sh` |
| **CI coverage** | No (requires local context) |
| **How to run** | `bash .opencode/conformance/tests/senior-operator-loop.sh` |
| **Guarantees** | Judgment cycle (Objective → Context → Risk → Plan → Implement → Test → Self-review → PR → CI → Memory) is documented |
| **Does not guarantee** | Adherence in practice (advisory) |

---

## 15. Git Guard

| Field | Value |
|-------|-------|
| **Status** | Stable |
| **Source** | `.opencode/git-guard/git-guard.sh` |
| **Configuration** | `.opencode/git-guard/` directory |
| **Validation** | `.opencode/conformance/tests/git-guard-compliance.sh`, `.opencode/conformance/tests/git-guard-enforcement.sh`, `.opencode/conformance/tests/git-guard-wrapper.sh` |
| **CI coverage** | No (requires local git context) |
| **How to run** | `bash .opencode/git-guard/git-guard.sh commit -m "message"` |
| **Guarantees** | Blocks `--no-verify`, `--force`, direct-main push |
| **Does not guarantee** | Protection if bypassed with raw git commands |

---

## 16. Empty Response Guardrail

| Field | Value |
|-------|-------|
| **Status** | Stable |
| **Source** | `.opencode/scripts/empty-response-guard.sh`, `.opencode/AGENTS.md` (Empty Response Guardrail section) |
| **Configuration** | Model blocklist in the script |
| **Validation** | `.opencode/conformance/tests/empty-response-guardrail.sh` |
| **CI coverage** | No (requires local context) |
| **How to run** | `bash .opencode/conformance/tests/empty-response-guardrail.sh` |
| **Guarantees** | Models with empty-response history are blocked from automatic routing |
| **Does not guarantee** | All empty responses are caught (runtime enforcement needed) |

---

## 17. Compaction Safeguard

| Field | Value |
|-------|-------|
| **Status** | Stable |
| **Source** | `.opencode/rules.md` (Compaction Continuity section), `.opencode/COMPACTION-SAFEGUARD.md` |
| **Configuration** | Model-specific token budgets in the rules |
| **Validation** | `.opencode/conformance/tests/compaction-safety.sh` |
| **CI coverage** | No (requires local context) |
| **How to run** | `bash .opencode/conformance/tests/compaction-safety.sh` |
| **Guarantees** | Token budgets and proactive checkpointing rules are documented |
| **Does not guarantee** | Runtime compaction behavior |

---

## Summary Table

| # | Capability | Status | CI Enforced |
|---|-----------|--------|-------------|
| 1 | Public Surface Scan | Stable | Yes |
| 2 | Protocol Conformance | Stable | Yes (subset) |
| 3 | Protocol Atlas | Stable | Yes |
| 4 | Agent Topology | Stable | No |
| 5 | Model Routing Policy | Advisory | No |
| 6 | Reviewer Calibration | Advisory | No |
| 7 | Loop Controller | Stable | Yes |
| 8 | Task Replay | Stable | No |
| 9 | Production Hardening | Stable | Yes |
| 10 | Evidence-Based Routing | Advisory | No |
| 11 | Release Checklist | Stable | No (manual) |
| 12 | Branch Protection | Stable | GitHub-enforced |
| 13 | Lite Delegation Mode | Stable | No |
| 14 | Senior Operator Loop | Stable | No |
| 15 | Git Guard | Stable | No |
| 16 | Empty Response Guardrail | Stable | No |
| 17 | Compaction Safeguard | Stable | No |
