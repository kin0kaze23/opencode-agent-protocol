# Helper Agent Roster

> **v1.1 Production (Action 4D, 2026-06-05)** — qwen3.7-plus production primary for orchestrator/FAST-DIRECT/implementer/planner/architect. qwen3.6-plus retained as fallback/hard-solver/rollback baseline. v0.4 baseline: 9.9/10. Action 4B: 10.0/10. 3/3 canary tasks clean.
>
> **v4.27.1** — Protocol Coherence Closure + Information Architecture Cleanup.
>
> **v4.10.0 / M3C** — OpenCode Go routing + implementer hotfix.
> Routing guidance for helper delegation; Claude/Hermes/direct API remain deferred.
>
> **Migration note (2026-05-27):** OpenCode runtime agents use OpenCode Go routing.
> Alibaba/Bailian decommissioned from workspace routing (quota exhausted, 429 insufficient_quota).
> Canonical candidate registry: `.opencode/model-registry.yaml`. Secrets are sourced from
> Doppler project `nuggie-be`, config `dev_backend`, by variable name only.

Use this roster when the Owner decides to delegate or switch reasoning depth.

## Routing source of truth

- `.opencode/opencode.json` sets the **Owner session default** model: `umans-ai-coding-plan/umans-coder` (v1.5 capacity-first).
- Direct bounded implementation helper: `umans-ai-coding-plan/umans-coder` (v1.5 capacity-first).
- Fallback/hard-solver/rollback: `opencode-go/qwen3.7-plus` (premium reserve).
- This helper roster sets **delegated helper defaults**: `umans-ai-coding-plan/umans-coder` for Orchestrator/Planner/Implementer (capacity-first), `opencode-go/glm-5.1` for Reviewer (premium reserve), `opencode-go/qwen3.7-plus` for Architect (premium reserve), and `opencode-go/deepseek-v4-flash` for Explorer/Budget.
- `.opencode/model-registry.yaml` tracks Umans as primary capacity provider, OpenCode Go as premium reserve, plus deferred Claude/Hermes/direct API blockers.
- Orchestrator prompt source is intentionally manual-canonical at `.opencode/global-runtime/prompts/orchestrator.md`: the Owner prompt is workspace-specific policy, not a reusable helper spec. Helper prompts are generated from `.opencode/agents/*.md` and mirrored into global runtime; orchestrator is copied as-is by `.opencode/scripts/sync-opencode-runtime.sh`.
- GPT-5.5 is external/manual escalation only — NOT wired into OpenCode config.
- Do not treat helper defaults as a contradiction of the Owner session default; they apply only after the Owner delegates a bounded stage.

## Phase M1 OpenCode Go caveats

- OpenCode Go routing is promoted for OpenCode runtime agents only. Do not remove Alibaba/Bailian fallback, migrate Hermes/direct API, or migrate Claude wrappers as part of Phase M1.3.
- `umans-ai-coding-plan/umans-coder` is the v1.5 capacity-first Owner/Planner/Implementer route; `opencode-go/qwen3.7-plus` is the premium reserve for Architect and high-risk tasks; ambiguous performance requests remain plan-first under protocol guardrails.
- `opencode-go/qwen3.6-plus` is the fallback/hard-solver/rollback baseline.
- Ambiguous implementation and vague performance tasks must be plan-first: baseline measurement, target metric, suspected bottleneck, touch list, verification command, and rollback path are required before edits.
- Unsafe security/auth/rate-limit/CORS requests should refuse early and offer defensive alternatives rather than exploring unsafe implementation.
- Keep targeted Phase M1 re-eval focused on C-TEST-004, C-TEST-006, and C-TEST-002 before any broader 12-model matrix.
- **v0.2 eval (2026-06-05):** `opencode-go/qwen3.6-plus` confirmed as production baseline — only model with 0 empty responses across all roles.
- **Action 4B (2026-06-05):** `opencode-go/qwen3.7-plus` scored 10.0/10, 100% pass, 0 empty — approved for canary (Action 4C).
- **Action 4D (2026-06-05):** `opencode-go/qwen3.7-plus` promoted to production v1.1 after 3 clean canary tasks.
- **v0.2 eval (2026-06-05):** `opencode-go/mimo-v2.5-pro` blocked from automatic routing — produced 2 empty responses on debugging and feature implementation tasks.
- **v0.2 eval (2026-06-05):** `opencode-go/deepseek-v4-pro` blocked from hard-solver/debugging — produced 2 empty responses on debugging and build recovery tasks.
- **v0.2 eval (2026-06-05):** `opencode-go/minimax-m2.7` blocked from implementation — implementer score 2.59/10, too weak for production.

## Default routing
<!-- v1.5 capacity-first: Umans primary for routine, OpenCode Go premium reserve -->

| Role | Model | Status | Use for | Do not use for |
|---|---|---|---|---|
| Orchestrator | `umans-ai-coding-plan/umans-glm-5.2` | ✅ production_active_for_orchestrator_routine_medium | Routine/medium-risk orchestration, task coordination. Fallback: umans-coder → opencode-go/qwen3.7-plus (premium reserve). | High-risk architecture, difficult debugging (use OpenCode Go) |
| Planner | `umans-ai-coding-plan/umans-coder` | ✅ production_active_soak_monitoring | Feature plans, plan correction, implementation-readiness checks | Writing production code |
| Implementer | `umans-ai-coding-plan/umans-coder` | ✅ production_active_soak_monitoring | Approved code changes on explicit coding specs with reviewer gate. Fallback: qwen3.7-plus. | Ambiguous tasks, autonomous execution, guardrail decisions |
| Reviewer | `umans-ai-coding-plan/umans-glm-5.1` | ✅ production_active_for_reviewer_judge | Repo-grounded review, safety second-pass, risk verdicts. Fallback: opencode-go/glm-5.1 (premium reserve). | Default executor, autonomous planning, bulk use |
| Explorer | `umans-ai-coding-plan/umans-flash` | ✅ production_active_for_explorer_budget | Fast repo mapping and runtime-path discovery. Fallback: opencode-go/deepseek-v4-flash. | Final correctness verdicts |
| Architect | `opencode-go/qwen3.7-plus` | ✅ v1.1-production | High-risk auth, schema, state-model decisions (premium reserve) | Routine implementation or bulk review |
| Budget | `umans-ai-coding-plan/umans-flash` | ✅ production_active_for_explorer_budget | Read-only cost/routing summaries, cheap classification. Fallback: opencode-go/deepseek-v4-flash. | Editing files |
| Judge (eval) | `umans-ai-coding-plan/umans-glm-5.1` | ✅ production_active_for_reviewer_judge | Sparse high-value review/judge checks. Fallback: opencode-go/glm-5.1. | Broad repeat matrices |

## Routing logic (v4.8.0 — historical reference)

v4.8.0 introduced **Alibaba-first model routing** based on 6 evidence phases (Phase 3–6B). This section is historical reference only and has been superseded by v1.5 capacity-first routing.

| Change | Evidence | Confidence |
|---|---|---|
| Explorer: qwen3-coder-next → qwen3.6-plus | qwen3-coder-next has severe guardrail weakness (43.3 score, 6 blockers). qwen3.6-plus validated for repo discovery. | ✅ Eval-validated |
| Implementer: qwen3.5-plus → qwen3-coder-plus | qwen3-coder-plus scored 3.73 avg in coding pilot (Phase 6A), 4.0 for backend/API. Stronger than qwen3.5-plus for bounded patches. 1 hard-fail on frontend UI fixture — requires reviewer gate. | ✅ Eval-validated with guardrails |
| Reviewer: glm-5 confirmed | glm-5 scored 4.67 avg in Phase 6B reviewer pilot (0 hard-fails). Strong failure classification, secret-handling review, blocker/advisory separation. Slight over-hardline tendency documented. | ✅ Eval-validated with caveat |
| qwen3.5-plus for FAST planning | Phase 3: 4.29 avg, 0 hard-fails. Phase 4 GPT-5.5 review confirmed strong routine planning. Cost-efficient. | ✅ Eval-validated |
| qwen3.6-plus for complex work | Phase 3: 4.30 avg, 0 hard-fails. Phase 4 GPT-5.5 review confirmed excellent high-risk classification. Nearly tied with qwen3.5-plus. | ✅ Eval-validated |
| GPT-5.5: external/manual only | Phase 4 and 6A.2 selective reviews confirmed strong calibration value. Not wired into config. Owner escalation only. | ✅ Eval-validated as manual |

> **Note (v1.1-production, 2026-06-12):** All routes in the v4.8.0 table above have been superseded by `qwen3.7-plus` (production primary) and `qwen3.6-plus` (fallback). The following models are historical/eval-only references and are NOT in active production routing: `qwen3.5-plus` (decommissioned — Alibaba quota exhausted), `qwen3-coder-plus` (rejected — 3.73 avg, 1 hard-fail), `qwen3-coder-next` (rejected — 43.3 guardrail score, 6 blockers), `qwen3-max-2026-01-23` (not available on OpenCode Go). The ModelEval helper rows below are for evaluation mode only and must not be confused with production routing.

## Recommended switch guidance

- Start on `umans-ai-coding-plan/umans-coder` for Owner, planning, and implementation (v1.5 capacity-first).
- Switch to `opencode-go/qwen3.7-plus` for high-risk architecture, difficult debugging, final review, or when Umans fails quality/tool-use checks.
- Use `opencode-go/qwen3.6-plus` for hard-solver/fallback/rollback tasks. Switch when the plan is explicit and rollback is needed.
- Use `opencode-go/glm-5.1` for sparse `/review` and judge work only; avoid bulk use.
- Use `opencode-go/deepseek-v4-flash` for Explorer/Budget cheap read-only work.
- Keep `opencode-go/kimi-k2.6` as manual high-risk senior reviewer (eval-passed Phase 3B), `opencode-go/deepseek-v4-pro` as hard deep-repo solver only, and `opencode-go/minimax-m3` as manual UI/multimodal QA specialist only when OpenCode Go quota is available (v4.15.2: automatic visual-reviewer routing moved to `umans-ai-coding-plan/umans-kimi-k2.7` because minimax-m3 returned Insufficient balance).

## Visual Reviewer Fallback Diversity Plan (v4.16)

As of v4.16, `visual-reviewer-fallback` routes to `opencode-go/kimi-k2.6` (OpenCode Go premium reserve), providing true provider+model diversity from the primary `umans-ai-coding-plan/umans-kimi-k2.7` (Umans).

**v4.16 canary routing:**
- Primary: `umans-ai-coding-plan/umans-kimi-k2.7` (Umans) — routine visual QA
- Fallback: `opencode-go/kimi-k2.6` (OpenCode Go) — second opinion, primary failure, or high-risk visual QA

**Diversity achieved:**
- Provider diversity: OpenCode Go vs Umans (different failure domains)
- Model diversity: Kimi K2.6 vs Kimi K2.7 (different model versions)
- Quota pools: Separate — OpenCode Go premium reserve vs Umans capacity

**Candidate targets considered:**
1. ✅ **OpenCode Go `kimi-k2.6`** — eval-passed Phase 3B (6/6 PASS, 4.8/5.0), vision-capable, available quota. Selected for v4.16 canary.
2. ⏸️ OpenCode Go `minimax-m3` — eval-passed Phase 3C (5/5 PASS, 4.6/5.0) but returned Insufficient balance during v4.15.2. Restore as tertiary fallback once quota is verified.
3. ❌ Another Umans vision model — no verified candidate available.

**Canary status:**
- Non-empty output canary: pending
- Authenticated screenshot review: pending
- Unauthenticated screenshot review: pending
- All guards: pending
- Seal: blocked until canary evidence clean + explicit owner approval

## Provider Fallback Routing (v1.5 — 2026-06-22)

Every agent has an ordered fallback chain. Too many equal choices creates routing randomness. Each role gets exactly one primary and one or more ordered fallbacks.

### v1.5 Capacity-First Provider Strategy

**Provider Roles:**
- **Umans AI** = primary capacity provider: routine orchestration, implementation, planning (reviewer/explorer/budget pending Umans verification)
- **OpenCode Go** = premium reserve provider: high-risk architecture, difficult debugging, final review, current reviewer/explorer/budget until Umans alternatives verified
- **ChatGPT/Codex** = manual senior escalation only

**Rationale:**
OpenCode Go monthly quota is materially consumed (~20% used). Umans AI has more usable recurring capacity and resets roughly every 5 hours. Umans is now the primary/default provider for routine development. OpenCode Go is the secondary/premium provider for high-risk reasoning, difficult debugging, final review, and emergency fallback.

**Routing Principles:**
1. If task is routine or medium risk, prefer Umans
2. If task is high-risk architecture, difficult debugging, production release review, or failed Umans output, escalate to OpenCode Go
3. If OpenCode quota/rate-limit occurs, return to Umans immediately
4. Do not spend OpenCode Go on routine implementation/planning unless Umans fails quality or tool-use checks
5. Compaction remains conservative: opencode-go/glm-5.2 primary (1M context, matches chat model), umans-kimi-k2.7 bounded fallback for sessions <=180K tokens only.
6. **Failure-type-aware routing:** different failure types trigger different fallback behavior (see table below)

### Routing Table (v1.5 — Capacity-First)

| Role | Primary | Quality Fallback (same provider) | Quota Fallback (cross-provider) | Notes |
|---|---|---|---|---|
| **Orchestrator** | `umans-ai-coding-plan/umans-glm-5.2` | `umans-ai-coding-plan/umans-coder` | `opencode-go/qwen3.7-plus` | v1.5.2: production_active_for_orchestrator_routine_medium |
| **Implementer** | `umans-ai-coding-plan/umans-coder` | `opencode-go/qwen3.7-plus` | `opencode-go/qwen3.6-plus` | Capacity lane |
| **Reviewer** | `umans-ai-coding-plan/umans-glm-5.1` | `opencode-go/glm-5.1` | — | Umans primary (v1.5.2). OpenCode Go premium reserve for high-risk. |
| **Planner** | `umans-ai-coding-plan/umans-coder` | `opencode-go/qwen3.7-plus` | `opencode-go/qwen3.6-plus` | Capacity lane |
| **Architect** | `opencode-go/qwen3.7-plus` | `opencode-go/qwen3.6-plus` | `umans-ai-coding-plan/umans-glm-5.2` | Premium reserve for high-risk architecture |
| **Explorer** | `umans-ai-coding-plan/umans-flash` | `opencode-go/deepseek-v4-flash` | — | v1.5.2: production_active_for_explorer_budget |
| **Budget** | `umans-ai-coding-plan/umans-flash` | `opencode-go/deepseek-v4-flash` | — | v1.5.2: production_active_for_explorer_budget |
| **Compaction** | `opencode-go/glm-5.2` | `umans-ai-coding-plan/umans-kimi-k2.7` (<=180K only) | `opencode-go/qwen3.7-plus` (<=100K only) | GLM-5.2 has ~1M context, matches chat model. Kimi bounded to <=180K. |
| **Summary** | `opencode-go/glm-5.2` | `umans-ai-coding-plan/umans-kimi-k2.7` (<=180K only) | `opencode-go/qwen3.7-plus` (<=100K only) | GLM-5.2 has ~1M context. Kimi bounded to <=180K. |

### Failure-Type-Aware Step-Down Rules

| Failure Type | Behavior | Rationale |
|---|---|---|
| **Quota/rate limit** (429, insufficient_balance) | **Switch provider immediately** | Same-provider fallback will also fail |
| **Auth failure** (401, 403) | **Switch provider immediately** | Provider credentials broken |
| **Empty response** (0 bytes after tokens) | **Mark degraded, switch provider** | Model runtime issues, try other provider |
| **Tool-use failure** | **Avoid model for agentic tasks** | Model unreliable for tool-augmented work |
| **Quality weakness** (weak patches, poor plans) | **Try stronger sibling same-provider first** | Quality issue may be model-specific |
| **Compaction failure** | **Use proven compaction-safe only** | Only `compaction_safe: true` models |
| **Provider timeout** | **Switch provider immediately** | Provider may be down |

On step-down:
1. Record failure reason without exposing secrets.
2. **For quota/auth/timeout/empty: switch provider immediately** — do not try same-provider siblings.
3. **For quality weakness: try stronger same-provider model first**, then switch provider if still weak.
4. Continue workflow if a verified fallback exists.
5. If no fallback exists, stop and report to owner.
6. Do not silently retry against a failing provider.

### Provider Policy

1. **Primary provider:** Umans (`umans-ai-coding-plan/*`) for routine coding work.
2. **Premium reserve provider:** OpenCode Go (`opencode-go/*`) for high-risk tasks.
3. **Default Umans coding model:** `umans-ai-coding-plan/umans-coder`.
4. **GLM-5.2:** Candidate orchestrator/reviewer — do NOT promote until verification passes. See `glm52_verification_gate` in model-registry.yaml.
5. **Kimi/other Umans models:** Secondary fallback only where already verified.
6. **ChatGPT Plus / Codex:** Manual external escalation only — not automatic runtime routing. Usage depends on plan limits and may require credits beyond included usage.

### Failure Step-Down Behavior

On any of these failure modes, step down to the next fallback in the chain:
- Rate limit (429)
- Auth failure (401/403)
- Empty response (0 bytes after consuming tokens)
- Tool-use failure (model cannot use required tools)
- Provider timeout
- Insufficient balance

On step-down:
1. Record failure reason without exposing secrets.
2. **Switch provider if same-provider fallback fails** — do not stay on a failing provider.
3. Continue workflow if a verified fallback exists.
4. If no fallback exists, stop and report to owner.
5. Do not silently retry against a failing provider.

### GLM-5.2 Candidate Status

GLM-5.2 is worth adding as a candidate orchestrator/reviewer. Z.ai positions it as a flagship long-horizon coding/agentic model with 1M-token context, and Cloudflare describes it as supporting function calling and reasoning for tool-augmented agents.

**Do NOT promote to default reviewer until verification passes:**
- Tool-use via OpenCode Go provider
- Repo-edit safety (safe read + edit on test repo)
- Protocol gate pass (workspace protocol guard)
- Empty-response safety (0 empty across 3+ tasks)
- Compaction safety (dedicated eval — not approved until then)

### Umans-Coder Canary Status

Umans-coder is now the primary implementer and planner (v1.3). Status: **production_active_soak_monitoring**. All canaries and soak tasks passed:
- Implementation canary: PASS (0 empty responses, 0 protocol violations)
- Planning canary: PASS (0 empty responses, 0 protocol violations)
- Implementation soak: PASS (real implementation task, 0 empty responses, 8 tool calls, 0 failures)
- Planning soak: PASS (real planning task, 0 empty responses, specific/actionable plan)

Monitoring requirements:
- Observe 24h of production use with 0 empty responses
- Track quota consumption and reset behavior
- Monitor tool-use reliability across diverse tasks
- No quality regressions observed

Promotion to production_core requires: 24h production observation complete, 0 empty responses, stable quota behavior documented, no quality regressions.

See `umans_coder_canary_gate` in model-registry.yaml.

### Compaction Fallback Note

Compaction is fragile. Only use models already proven safe for summary/compaction. Current active compaction model is `opencode-go/glm-5.2` (1M context, matches chat model, eval passed 2026-07-08). `umans-kimi-k2.7` (256K context) is retained as bounded fallback for sessions <=180K tokens only. `opencode-go/qwen3.7-plus` (128K context) is bounded fallback for sessions <=100K tokens only. If session exceeds fallback model budget, force GLM-5.2 compaction or write checkpoint and start fresh session. See COMPACTION-SAFEGUARD.md for the full session budget guard.

### Protocol Roles (v1.3)

**Provider Router:** Decides provider/model before task execution based on task type, quota, cost, and failure state. Prevents random model choice.

**Quota Steward:** Tracks provider usage, cooldowns, reset windows, and recent model failures. Monitors quota consumption, detects rate limits, triggers provider switch on failure.

### Secrets

All API keys are managed through Doppler (project: `nuggie-be`, config: `dev_backend`). Agent may verify secret names/existence only. Never print, log, commit, or document secret values.

## Token and model-efficiency rules (M1.7)

- **Cheap-first read-only work:** use Explorer or Budget on `opencode-go/deepseek-v4-flash` for routine repo lookup, quota/cost checks, and low-risk classification before spending umans-coder or qwen3.7-plus context.
- **umans-coder is capacity-first primary:** use for routine orchestration, planning, and implementation. Reserve `opencode-go/qwen3.7-plus` for high-risk architecture, difficult debugging, final review.
- **No duplicate planning:** the Owner owns high-level strategy. Spawn Planner only for ambiguous, multi-step, high-risk, formal-plan, plan-correction, or owner-requested planning work; do not ask Planner to restate a plan the Owner already made.
- **Implementer consumes plans:** Implementer on `umans-ai-coding-plan/umans-coder` executes the approved touch list and must not redo planning, expand scope, or make architecture decisions.
- **Reviewer cost guard:** use `umans-ai-coding-plan/umans-glm-5.1` for routine review. Escalate to `opencode-go/glm-5.1` (premium reserve) only for risk score 4+, sensitive paths, auth/security/payment/data/secrets changes, 4+ changed files, release/ship gates, unclear implementation quality, or explicit owner request. For low-risk DIRECT/FAST work, sample review instead of reviewing every change.
- **Handoff digest required:** helper outputs should be compact and include Objective, Files inspected/changed, Key findings, Decision/recommendation, Risks/blockers, and Next recommended agent/action. Avoid large context dumps unless explicitly required.
- **Quota-low behavior:** when OpenCode Go quota, latency, or cost pressure is high, prefer Budget/Explorer for read-only work, avoid GLM reviewer unless high-risk, defer challenger models.
- **Task summary telemetry:** meaningful task summaries should list models/helpers used, why each was used, token/cost/latency if exposed, and whether a cheaper route would have been sufficient in hindsight.

## GPT-5.5 manual escalation

GPT-5.5 is NOT configured as a provider in OpenCode config. It remains an external/manual escalation target only.

Use GPT-5.5 when:
- High-risk security, infra, architecture, auth, payment, schema, or state-model review is needed.
- Alibaba models disagree materially and a tie-breaker is required.
- A routing/config change is being considered and final calibration is needed.
- Owner explicitly requests a second opinion.
- Selected eval judging and rubric calibration.

Do not wire GPT-5.5 into `.opencode/opencode.json` or `.opencode/brain-config.json`. This requires explicit owner approval and a separate config change.

## Conditional specialist routing

Not every specialist capability should be a first-class helper.
Route these through commands, skills, or model escalation instead:

- Visual bug triage: `/debug` with kimi-k2.6 escalation (senior review) or minimax-m3 manual UI/multimodal QA escalation
- Security-sensitive review: security skill plus Reviewer; escalate to kimi-k2.6 for high-risk auth/RLS/schema review
- UI/multimodal QA: minimax-m3 manual escalation for screenshot QA, mobile responsive, accessibility audit, theme/design-system review
- Performance audit: performance skill or verification profile
- Deployment readiness: `/ship` and explicit deploy commands
- Cheap second-pass verdict: `glm-5` via `bulk_review` escalation, only when the Owner asks for it

## Manual specialists (eval-passed, not automatic)

These models passed eval and are approved for manual specialist use only. They do not change runtime routing and are not automatic delegation targets.

| Model | Role | Eval | Allowed | Blocked |
|---|---|---|---|---|
| `opencode-go/kimi-k2.6` | Senior reviewer | Phase 3B: 6/6 PASS, 4.8/5 | High-risk review, security/auth/schema, release readiness, protocol routing | Default reviewer, automatic delegation, implementation, protocol seal |
| `opencode-go/minimax-m3` | UI/multimodal QA | Phase 3C: 5/5 PASS, 4.6/5 | Screenshot QA, mobile responsive, accessibility audit, theme review, product handoff | Security review, implementation, protocol seal, production deploy, automatic routing |
| `opencode/mimo-v2.5-free` | Planning/audit helper | Phase 2C: 6/6 PASS, 4.7/5 | Read-only audit, planning, repo exploration, validation supervision, patch proposals | Runtime orchestrator, protocol seal, secrets, security review, production deploy, schema changes |

## Non-negotiable delegation rules

- Do not call a phase `implementation-ready` unless runtime authority, state model, full touch list, success criteria, and out-of-scope are explicit
- For any type/interface/schema/profile shape change, audit constructors, defaults, migrations, adapters, prompts/tests, and runtime consumers before handing work to the Implementer
- If a correction pass closes one blocker but leaves a dependent blocker open, keep the phase in `plan-correction`
- Summaries must not claim more than the underlying evidence proved

## Model Comparison Helpers (v4.3)

These helpers are for protocol model comparison evaluation only. They map all 9 Alibaba Model Studio coding plan models to standardized evaluation roles.

**Eval mode only:** ModelEval helpers must not be allowed in the default daily `.opencode/opencode.json` task permission surface. Enable them only in an explicit eval run/config so daily routing remains limited to Explorer, Planner, Implementer, Reviewer, and Architect.

| Helper Role | Model | Use for Comparison |
|---|---|---|
| ModelEval-Qwen36 | `qwen3.6-plus` | Premium/long-context model baseline |
| ModelEval-Qwen35 | `qwen3.5-plus` | Previous generation comparison |
| ModelEval-QwenMax | `qwen3-max-2026-01-23` | Premium model comparison |
| ModelEval-CoderNext | `qwen3-coder-next` | Explorer model comparison |
| ModelEval-CoderPlus | `qwen3-coder-plus` | Implementer model comparison |
| ModelEval-GLM5 | `glm-5` | Budget model comparison |
| ModelEval-GLM47 | `glm-4.7` | Mid-tier model comparison |
| ModelEval-Kimi | `kimi-k2.5` | Visual/UI model comparison |
| ModelEval-MiniMax | `MiniMax-M2.7` | Third-party model comparison (updated 2026-05) |
| ModelEval-Hy3 | `hy3-preview-free` | Hy3 Preview comparison (Tencent Hunyuan 3) |
| ModelEval-Hy3 | `hy3-preview-free` | Hy3 model comparison |

**Evaluation protocol:** Each model receives the same standardized task prompt. Outputs are scored against the shared eval rubric in `vault/evals/framework/SCORING_GUIDE.md` (v2.0, 8-category). Results are written to `vault/evals/models/results/`.

**Cleanup:** These helper roles are for evaluation only. Remove or archive after comparison is complete.
