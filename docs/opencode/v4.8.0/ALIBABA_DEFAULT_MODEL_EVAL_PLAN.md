# v4.8.0 — Alibaba-Default Model Reliability + GPT-5.5 Escalation Policy

Status: Phase 1 planning docs only
Active protocol: OpenCode v4.7.0 remains active
Routing impact: none

## Objective

v4.8.0 is an evaluation track for validating that Alibaba Cloud Model Studio Coding Plan models can remain the default daily OpenCode development workers under the active v4.7.0 protocol.

The goal is not to make GPT-5.5 the default worker or universal gold standard. GPT-5.5 is reserved for selective senior review, judging, hard-reasoning support, disagreement resolution, or owner-requested second opinion.

The evaluation should answer:

- Which Alibaba model is most reliable for each OpenCode lifecycle stage?
- Which current routing assumptions are supported by evidence?
- Where do Alibaba models need guardrails or reviewer escalation?
- When should GPT-5.5 be escalated instead of used routinely?

## Alibaba-first operating model

- Alibaba models are the default daily workers for planning, implementation, review, QA, and protocol operations.
- GPT-5.5 is not the default worker.
- GPT-5.5 is an external/manual reviewer path unless a later approved phase explicitly adds OpenCode provider routing.
- v4.8.0 setup must not change model routing, add agents, or alter active v4.7.0 behavior.

## Candidate model inventory

| Model | Status for v4.8.0 | Intended evaluation focus |
|---|---|---|
| `qwen3.6-plus` | primary candidate | long-context, protocol-heavy planning, complex analysis |
| `qwen3.5-plus` | primary candidate | FAST/STANDARD planning, routine protocol work |
| `qwen3-coder-plus` | primary candidate | coding/implementation discipline after validation |
| `qwen3-coder-next` | primary candidate | exploration and fast repo discovery, verify against prior weakness notes |
| `qwen3-max-2026-01-23` | runtime-verify-first | architecture, state-model, schema, security reasoning |
| `glm-5` | primary reviewer candidate | review, failure classification, budget second pass |
| `kimi-k2.5` | optional/specialized | visual/UI debugging and screenshot-driven review only |
| `MiniMax-M2.5` | version-reconcile-first | optional comparison after helper-roster/config mismatch is resolved |
| GPT-5.5 | external/manual reviewer path only | high-risk review, judge, tie-breaker, hard reasoning, owner-requested second opinion |

## Initial Alibaba routing hypothesis

This is a hypothesis to test, not active routing.

| Lifecycle / lane | Hypothesized Alibaba default |
|---|---|
| FAST / low-risk planning | `qwen3.5-plus` |
| STANDARD planning | `qwen3.5-plus` or `qwen3.6-plus` |
| Long-context / protocol-heavy work | `qwen3.6-plus` |
| Coding / implementation | `qwen3-coder-plus` after validation |
| Review / failure classification | `glm-5` |
| Architecture / state model | `qwen3-max-2026-01-23` if runtime verified; otherwise `qwen3.6-plus` |
| GPT-5.5 | high-risk second opinion only |

No routing recommendation should be made from one run only.

## Initial pilot shape

The first pilot should be small:

- 4 core fixtures.
- 3 Alibaba models maximum.
- 1 repeat initially.
- GPT-5.5 reviews selected outputs only.

Core fixtures:

1. PRD / planning.
2. UI/UX + frontend lifecycle.
3. Backend / API contract.
4. Security / infra / QA classification.

Expand only after the pilot demonstrates signal.

## v4.8.0 phases

1. Phase 1: planning docs only.
2. Phase 2: fixtures, rubric, and run schema.
3. Phase 3: small Alibaba-model pilot.
4. Phase 4: GPT-5.5 selective review.
5. Phase 5: Alibaba-first routing recommendation.
6. Phase 6: optional routing change only after explicit approval.

## Guardrails

- Keep active protocol at v4.7.0 during eval setup.
- Do not change model routing during eval setup.
- Do not add agents.
- Do not commit product-code changes.
- Do not print, log, paste, or store secrets.
- Do not stage `.env.doppler`.
- Do not use GPT-5.5 routinely for FAST tasks, simple edits, or default implementation.
- Classify model/provider/tool failures with v4.6.1 labels: `TARGETED_FAILURE`, `BROAD_BASELINE_FAILURE`, `FLAKY_OR_INFRA_FAILURE`, `NOT_RUN`, `ACCEPTED_NON_BLOCKING`, or `BLOCKING_UNKNOWN`.
- Treat GPT-5.5 as external/manual until OpenCode provider routing is explicitly approved later.

## Phase 1 success criteria

- Planning docs define Alibaba-first operating model.
- GPT-5.5 escalation policy is explicit and selective.
- Candidate model inventory marks verify-first and reconcile-first models.
- Routing hypothesis is labeled non-active.
- No routing, agent, product-code, or secret-bearing files are changed.
