# Helper Agent Roster

> **Provider-agnostic reference** — Replace `YOUR_PROVIDER/YOUR_*_MODEL` placeholders with your actual provider and model IDs in `.opencode/opencode.json` and `.opencode/brain-config.json`.
>
> See `docs/OWN_MODEL_SETUP.md` for a provider-agnostic setup guide.

Use this roster when the Owner decides to delegate or switch reasoning depth.

## Routing source of truth

- `.opencode/opencode.json` sets the **Owner session default** model: `YOUR_PROVIDER/YOUR_IMPLEMENTER_MODEL`.
- Direct bounded implementation helper: `YOUR_PROVIDER/YOUR_IMPLEMENTER_MODEL`.
- Fallback/hard-solver/rollback: `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL` (premium reserve).
- This helper roster sets **delegated helper defaults**: `YOUR_PROVIDER/YOUR_IMPLEMENTER_MODEL` for Orchestrator/Planner/Implementer, `YOUR_PROVIDER/YOUR_REVIEWER_MODEL` for Reviewer, `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL` for Architect, and `YOUR_PROVIDER/YOUR_EXPLORER_MODEL` for Explorer/Budget.
- `.opencode/model-registry.yaml` tracks your primary capacity provider, premium reserve provider, plus any deferred providers.
- Orchestrator prompt source is intentionally manual-canonical at `.opencode/global-runtime/prompts/orchestrator.md`: the Owner prompt is workspace-specific policy, not a reusable helper spec. Helper prompts are generated from `.opencode/agents/*.md` and mirrored into global runtime; orchestrator is copied as-is by `.opencode/scripts/sync-opencode-runtime.sh`.
- External models (e.g., GPT) are external/manual escalation only — NOT wired into OpenCode config.
- Do not treat helper defaults as a contradiction of the Owner session default; they apply only after the Owner delegates a bounded stage.

## Default routing

| Role | Model | Status | Use for | Do not use for |
|---|---|---|---|---|
| Orchestrator | `YOUR_PROVIDER/YOUR_ORCHESTRATOR_MODEL` | ✅ production | Routine/medium-risk orchestration, task coordination. Fallback: `YOUR_PROVIDER/YOUR_IMPLEMENTER_MODEL` → `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL` (premium reserve). | High-risk architecture, difficult debugging (use premium reserve) |
| Planner | `YOUR_PROVIDER/YOUR_IMPLEMENTER_MODEL` | ✅ production | Feature plans, plan correction, implementation-readiness checks | Writing production code |
| Implementer | `YOUR_PROVIDER/YOUR_IMPLEMENTER_MODEL` | ✅ production | Approved code changes on explicit coding specs with reviewer gate. Fallback: `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL`. | Ambiguous tasks, autonomous execution, guardrail decisions |
| Reviewer | `YOUR_PROVIDER/YOUR_REVIEWER_MODEL` | ✅ production | Repo-grounded review, safety second-pass, risk verdicts. Fallback: `YOUR_PROVIDER/YOUR_REVIEWER_FALLBACK_MODEL` (premium reserve). | Default executor, autonomous planning, bulk use |
| Explorer | `YOUR_PROVIDER/YOUR_EXPLORER_MODEL` | ✅ production | Fast repo mapping and runtime-path discovery. Fallback: `YOUR_PROVIDER/YOUR_EXPLORER_FALLBACK_MODEL`. | Final correctness verdicts |
| Architect | `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL` | ✅ production | High-risk auth, schema, state-model decisions (premium reserve) | Routine implementation or bulk review |
| Budget | `YOUR_PROVIDER/YOUR_EXPLORER_MODEL` | ✅ production | Read-only cost/routing summaries, cheap classification. Fallback: `YOUR_PROVIDER/YOUR_EXPLORER_FALLBACK_MODEL`. | Editing files |
| Judge (eval) | `YOUR_PROVIDER/YOUR_REVIEWER_MODEL` | ✅ production | Sparse high-value review/judge checks. Fallback: `YOUR_PROVIDER/YOUR_REVIEWER_FALLBACK_MODEL`. | Broad repeat matrices |

## Recommended switch guidance

- Start on `YOUR_PROVIDER/YOUR_IMPLEMENTER_MODEL` for Owner, planning, and implementation.
- Switch to `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL` for high-risk architecture, difficult debugging, final review, or when primary fails quality/tool-use checks.
- Use `YOUR_PROVIDER/YOUR_FALLBACK_MODEL` for hard-solver/fallback/rollback tasks. Switch when the plan is explicit and rollback is needed.
- Use `YOUR_PROVIDER/YOUR_REVIEWER_FALLBACK_MODEL` for sparse `/review` and judge work only; avoid bulk use.
- Use `YOUR_PROVIDER/YOUR_EXPLORER_FALLBACK_MODEL` for Explorer/Budget cheap read-only work.
- Keep a vision-capable model as manual visual reviewer fallback when primary visual reviewer is unavailable.

## Visual Reviewer Fallback Diversity Plan

For visual QA, `visual-reviewer-fallback` should route to a different provider+model from the primary `visual-reviewer`, providing true provider+model diversity.

**Recommended routing:**
- Primary: `YOUR_PROVIDER/YOUR_VISUAL_REVIEWER_MODEL` — routine visual QA
- Fallback: `YOUR_PROVIDER/YOUR_VISUAL_REVIEWER_FALLBACK_MODEL` — second opinion, primary failure, or high-risk visual QA

**Diversity achieved:**
- Provider diversity: Different providers (different failure domains)
- Model diversity: Different model versions (different failure modes)
- Quota pools: Separate — premium reserve vs capacity

## Provider Fallback Routing (v1.5)

Every agent has an ordered fallback chain. Too many equal choices creates routing randomness. Each role gets exactly one primary and one or more ordered fallbacks.

### Capacity-First Provider Strategy

**Provider Roles:**
- **Primary capacity provider** = routine orchestration, implementation, planning
- **Premium reserve provider** = high-risk architecture, difficult debugging, final review
- **External (e.g., ChatGPT/Codex)** = manual senior escalation only

**Routing Principles:**
1. If task is routine or medium risk, prefer primary provider
2. If task is high-risk architecture, difficult debugging, production release review, or failed primary output, escalate to premium reserve
3. If premium reserve quota/rate-limit occurs, return to primary provider immediately
4. Do not spend premium reserve on routine implementation/planning unless primary fails quality or tool-use checks
5. Compaction remains conservative: use proven compaction-safe models only
6. **Failure-type-aware routing:** different failure types trigger different fallback behavior (see table below)

### Routing Table

| Role | Primary | Quality Fallback (same provider) | Quota Fallback (cross-provider) | Notes |
|---|---|---|---|---|
| **Orchestrator** | `YOUR_PROVIDER/YOUR_ORCHESTRATOR_MODEL` | `YOUR_PROVIDER/YOUR_IMPLEMENTER_MODEL` | `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL` | Primary for routine/medium-risk |
| **Implementer** | `YOUR_PROVIDER/YOUR_IMPLEMENTER_MODEL` | `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL` | `YOUR_PROVIDER/YOUR_FALLBACK_MODEL` | Capacity lane |
| **Reviewer** | `YOUR_PROVIDER/YOUR_REVIEWER_MODEL` | `YOUR_PROVIDER/YOUR_REVIEWER_FALLBACK_MODEL` | — | Premium reserve for high-risk |
| **Planner** | `YOUR_PROVIDER/YOUR_IMPLEMENTER_MODEL` | `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL` | `YOUR_PROVIDER/YOUR_FALLBACK_MODEL` | Capacity lane |
| **Architect** | `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL` | `YOUR_PROVIDER/YOUR_FALLBACK_MODEL` | `YOUR_PROVIDER/YOUR_ORCHESTRATOR_MODEL` | Premium reserve for high-risk architecture |
| **Explorer** | `YOUR_PROVIDER/YOUR_EXPLORER_MODEL` | `YOUR_PROVIDER/YOUR_EXPLORER_FALLBACK_MODEL` | — | Cheap read-only work |
| **Budget** | `YOUR_PROVIDER/YOUR_EXPLORER_MODEL` | `YOUR_PROVIDER/YOUR_EXPLORER_FALLBACK_MODEL` | — | Cheap read-only work |
| **Compaction** | `YOUR_PROVIDER/YOUR_COMPACTION_MODEL` | `YOUR_PROVIDER/YOUR_COMPACTION_FALLBACK_MODEL` (bounded) | `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL` (bounded) | Use proven compaction-safe models only |
| **Summary** | `YOUR_PROVIDER/YOUR_COMPACTION_MODEL` | `YOUR_PROVIDER/YOUR_COMPACTION_FALLBACK_MODEL` (bounded) | `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL` (bounded) | Use proven compaction-safe models only |

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

1. **Primary provider:** Your capacity provider for routine coding work.
2. **Premium reserve provider:** Your fallback provider for high-risk tasks.
3. **Default coding model:** `YOUR_PROVIDER/YOUR_IMPLEMENTER_MODEL`.
4. **Secrets:** All API keys managed through your secret manager. Agent may verify secret names/existence only. Never print, log, commit, or document secret values.

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

### Compaction Fallback Note

Compaction is fragile. Only use models already proven safe for summary/compaction. Use your large-context model for compaction. Use your medium-context model as bounded fallback for sessions within its token budget. If session exceeds fallback model budget, force large-context compaction or write checkpoint and start fresh session. See COMPACTION-SAFEGUARD.md for the full session budget guard.

### Protocol Roles

**Provider Router:** Decides provider/model before task execution based on task type, quota, cost, and failure state. Prevents random model choice.

**Quota Steward:** Tracks provider usage, cooldowns, reset windows, and recent model failures. Monitors quota consumption, detects rate limits, triggers provider switch on failure.

### Secrets

All API keys are managed through your secret manager. Agent may verify secret names/existence only. Never print, log, commit, or document secret values.

## Token and model-efficiency rules

- **Cheap-first read-only work:** use Explorer or Budget on `YOUR_PROVIDER/YOUR_EXPLORER_FALLBACK_MODEL` for routine repo lookup, quota/cost checks, and low-risk classification before spending premium model context.
- **Capacity-first primary:** use for routine orchestration, planning, and implementation. Reserve `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL` for high-risk architecture, difficult debugging, final review.
- **No duplicate planning:** the Owner owns high-level strategy. Spawn Planner only for ambiguous, multi-step, high-risk, formal-plan, plan-correction, or owner-requested planning work; do not ask Planner to restate a plan the Owner already made.
- **Implementer consumes plans:** Implementer on `YOUR_PROVIDER/YOUR_IMPLEMENTER_MODEL` executes the approved touch list and must not redo planning, expand scope, or make architecture decisions.
- **Reviewer cost guard:** use `YOUR_PROVIDER/YOUR_REVIEWER_MODEL` for routine review. Escalate to `YOUR_PROVIDER/YOUR_REVIEWER_FALLBACK_MODEL` (premium reserve) only for risk score 4+, sensitive paths, auth/security/payment/data/secrets changes, 4+ changed files, release/ship gates, unclear implementation quality, or explicit owner request. For low-risk DIRECT/FAST work, sample review instead of reviewing every change.
- **Handoff digest required:** helper outputs should be compact and include Objective, Files inspected/changed, Key findings, Decision/recommendation, Risks/blockers, and Next recommended agent/action. Avoid large context dumps unless explicitly required.
- **Quota-low behavior:** when premium reserve quota, latency, or cost pressure is high, prefer Budget/Explorer for read-only work, avoid premium reviewer unless high-risk, defer challenger models.
- **Task summary telemetry:** meaningful task summaries should list models/helpers used, why each was used, token/cost/latency if exposed, and whether a cheaper route would have been sufficient in hindsight.

## External manual escalation

External models (e.g., GPT) are NOT configured as a provider in OpenCode config. They remain an external/manual escalation target only.

Use external escalation when:
- High-risk security, infra, architecture, auth, payment, schema, or state-model review is needed.
- Provider models disagree materially and a tie-breaker is required.
- A routing/config change is being considered and final calibration is needed.
- Owner explicitly requests a second opinion.
- Selected eval judging and rubric calibration.

Do not wire external models into `.opencode/opencode.json` or `.opencode/brain-config.json`. This requires explicit owner approval and a separate config change.

## Conditional specialist routing

Not every specialist capability should be a first-class helper.
Route these through commands, skills, or model escalation instead:

- Visual bug triage: `/debug` with senior review escalation
- Security-sensitive review: security skill plus Reviewer; escalate for high-risk auth/RLS/schema review
- UI/multimodal QA: manual escalation for screenshot QA, mobile responsive, accessibility audit, theme/design-system review
- Performance audit: performance skill or verification profile
- Deployment readiness: `/ship` and explicit deploy commands
- Cheap second-pass verdict: budget model via `bulk_review` escalation, only when the Owner asks for it

## Manual specialists (eval-passed, not automatic)

These models passed eval and are approved for manual specialist use only. They do not change runtime routing and are not automatic delegation targets.

| Model Category | Role | Allowed | Blocked |
|---|---|---|---|
| `YOUR_PROVIDER/YOUR_SENIOR_REVIEWER_MODEL` | Senior reviewer | High-risk review, security/auth/schema, release readiness, protocol routing | Default reviewer, automatic delegation, implementation, protocol seal |
| `YOUR_PROVIDER/YOUR_MULTIMODAL_MODEL` | UI/multimodal QA | Screenshot QA, mobile responsive, accessibility audit, theme review, product handoff | Security review, implementation, protocol seal, production deploy, automatic routing |
| `YOUR_PROVIDER/YOUR_AUDIT_MODEL` | Planning/audit helper | Read-only audit, planning, repo exploration, validation supervision, patch proposals | Runtime orchestrator, protocol seal, secrets, security review, production deploy, schema changes |

## Non-negotiable delegation rules

- Do not call a phase `implementation-ready` unless runtime authority, state model, full touch list, success criteria, and out-of-scope are explicit
- For any type/interface/schema/profile shape change, audit constructors, defaults, migrations, adapters, prompts/tests, and runtime consumers before handing work to the Implementer
- If a correction pass closes one blocker but leaves a dependent blocker open, keep the phase in `plan-correction`
- Summaries must not claim more than the underlying evidence proved

## Model Comparison Helpers (v4.3)

These helpers are for protocol model comparison evaluation only. They map your models to standardized evaluation roles.

**Eval mode only:** ModelEval helpers must not be allowed in the default daily `.opencode/opencode.json` task permission surface. Enable them only in an explicit eval run/config so daily routing remains limited to Explorer, Planner, Implementer, Reviewer, and Architect.

| Helper Role | Model Category | Use for Comparison |
|---|---|---|
| ModelEval-Orchestrator | `YOUR_PROVIDER/YOUR_ORCHESTRATOR_MODEL` | Orchestrator model baseline |
| ModelEval-Implementer | `YOUR_PROVIDER/YOUR_IMPLEMENTER_MODEL` | Implementer model comparison |
| ModelEval-Reviewer | `YOUR_PROVIDER/YOUR_REVIEWER_MODEL` | Reviewer model comparison |
| ModelEval-Explorer | `YOUR_PROVIDER/YOUR_EXPLORER_MODEL` | Explorer model comparison |
| ModelEval-Architect | `YOUR_PROVIDER/YOUR_ARCHITECT_MODEL` | Architect model comparison |
| ModelEval-Compaction | `YOUR_PROVIDER/YOUR_COMPACTION_MODEL` | Compaction model comparison |

**Evaluation protocol:** Each model receives the same standardized task prompt. Outputs are scored against the shared eval rubric. Results are written to your eval results directory.

**Cleanup:** These helper roles are for evaluation only. Remove or archive after comparison is complete.
