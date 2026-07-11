# Model Router Advisory Report

**Generated:** 2026-06-14 14:08:58 +08
**Registry:** .opencode/model-registry.yaml
**Status:** ADVISORY ONLY — No routing changes applied

---

## Executive Summary

This report provides advisory recommendations for model selection by task type,
balancing capability, cost efficiency, quota endurance, privacy safety, and
evidence confidence.

**Key Principles:**
- Production routing unchanged — this is advisory guidance only
- Scored models have numeric evaluation evidence
- Incumbent baseline models are production-proven but lack standalone numeric evals
- Canary-only models are detected but not production-ready
- Free models are non-sensitive only with privacy warnings


---

## Production Role Recommendations

### Orchestrator / Primary Planning

**Recommended:** qwen3.7-plus (scored)
- Composite score: High capability + strong cost efficiency
- Evidence: 10.0/10 benchmark, 100% pass rate
- Cost tier: Cheap ($0.0028/request)
- Quota endurance: ~4,300 requests per $12/5h

**Fallback:** qwen3.6-plus (scored)
- Composite score: Strong capability, slightly higher cost
- Evidence: 9.9/10 benchmark, 100% pass rate
- Cost tier: Balanced ($0.0037/request)
- Quota endurance: ~3,300 requests per $12/5h

**Guidance:** Use qwen3.7-plus for high-risk architecture, complex planning, and production implementation. Fall back to qwen3.6-plus for hard-solver tasks or when qwen3.7-plus is unavailable.

### Implementer / Code Generation

**Recommended:** qwen3.7-plus (scored)
- Implementation score: 10/10
- Evidence: 10.0/10 benchmark, 3/3 canary tasks clean
- Cost tier: Cheap
- Best for: Production implementation, bounded coding tasks

**Alternative:** qwen3.6-plus (scored)
- Implementation score: 9.9/10
- Evidence: 9.9/10 benchmark
- Cost tier: Balanced
- Best for: Fallback implementation, hard-solver tasks

**Guidance:** qwen3.7-plus is the production primary for implementation. Use reviewer gate (glm-5.1 or kimi-k2.6) for risk-score-4+ changes.

### Reviewer / Code Review

**Incumbent Baseline:** glm-5.1 (not numerically scored)
- Status: Production incumbent reviewer by protocol
- Evidence: No standalone numeric eval artifact
- Cost tier: Premium ($0.0137/request)
- Quota endurance: ~880 requests per $12/5h
- **Warning:** High quota cost — reserve for high-value reviews

**Scored Alternative:** kimi-k2.6 (scored)
- Review score: 9.6/10
- Evidence: 4.8/5.0 reviewer eval, 6/6 PASS
- Cost tier: Expensive ($0.0096/request)
- Quota endurance: ~1,150 requests per $12/5h
- Approved for: Manual/high-risk senior review

**Guidance:** glm-5.1 is the production incumbent but expensive. kimi-k2.6 is a scored alternative for senior review. Consider numeric eval for glm-5.1 to justify cost. For routine reviews, consider if reviewer is needed at all.

### Explorer / Budget / Debug Loop

**Incumbent Baseline:** deepseek-v4-flash (not numerically scored)
- Status: Production incumbent for explorer/budget/debug_loop
- Evidence: No standalone numeric eval artifact
- Cost tier: Ultra-cheap ($0.0003/request)
- Quota endurance: ~31,650 requests per $12/5h
- **Strength:** Highest quota endurance — 36× more requests than glm-5.1

**Guidance:** deepseek-v4-flash is the production incumbent for high-volume, low-cost work. Ideal for exploration, debug loops, and budget tasks. Consider numeric eval to validate capability scores.

### UI/Multimodal QA Helper

**Recommended:** minimax-m3 (scored)
- UI/Multimodal score: 9.2/10
- Evidence: 4.6/5.0 UI eval, 5/5 PASS
- Cost tier: Balanced ($0.0037/request)
- Approved for: Manual UI/multimodal QA specialist

**Guidance:** Use minimax-m3 for screenshot QA, mobile responsive, accessibility audit, theme review. Not for security review or implementation.

### Non-Sensitive Free Fallback

**Scored Option:** mimo-v2.5-free (scored)
- Evidence: 4.7/5.0 eval, 6/6 PASS
- Cost tier: Free / quota not modeled / limited-time
- Privacy tier: Free training exception
- **Warning:** Data may be used for model improvement
- **Privacy:** Non-sensitive only — no private repo code, secrets, auth, payments, customer data, or proprietary planning

**Canary-Only Options:**
- qwen3.6-plus-free — Not in Zen docs free text, privacy unspecified
- minimax-m3-free — Not in Zen docs free text, privacy unspecified

**Guidance:** Free models are for non-sensitive work only. Never send private repo code, secrets, auth, payments, customer data, or proprietary planning. Use only when Go quota is exhausted or for deliberately low-risk tasks. Free model availability and limits are not guaranteed — they may change without notice.


---

## Task-Type Recommendations

### High-Risk Architecture / Planning

**Use:** qwen3.7-plus
- Highest capability + strong evidence
- Cost: $0.0028/request
- Quota: ~4,300 requests per $12/5h

**Avoid:** Free models, unknown-pricing models, deprecated models

### Production Implementation

**Use:** qwen3.7-plus + reviewer gate
- Implementation score: 10/10
- Add reviewer (glm-5.1 or kimi-k2.6) for risk-score-4+ changes

### Low-Risk Code Exploration

**Use:** deepseek-v4-flash
- Ultra-cheap, highest quota endurance
- Cost: $0.0003/request
- Quota: ~31,650 requests per $12/5h

### Repeated Debugging Loops

**Use:** deepseek-v4-flash
- High-volume, low-cost
- 36× more requests than glm-5.1 under same quota

### Review / Senior Review

**Use:** glm-5.1 (incumbent) or kimi-k2.6 (scored)
- glm-5.1: Production incumbent, expensive (~880 req/$12)
- kimi-k2.6: Scored alternative, better quota (~1,150 req/$12)

### UI/UX Polish / Multimodal QA

**Use:** minimax-m3
- UI/Multimodal score: 9.2/10
- Manual specialist only

### Quota-Low Mode

**Strategy:**
1. Shift exploration/debug to deepseek-v4-flash (ultra-cheap)
2. Reserve qwen3.7-plus for final architecture/implementation
3. Reserve glm-5.1/kimi-k2.6 for high-risk reviews only
4. Avoid premium models (glm-5.1, qwen3.7-max) unless critical

### Go Quota Exhausted Mode

**Use:** Free models only (non-sensitive tasks)
- mimo-v2.5-free (scored, training exception)
- deepseek-v4-flash-free (canary-only)
- north-mini-code-free (canary-only)

**Free model limitations:**
- Quota not modeled — availability and limits are not guaranteed
- Limited-time availability — may change without notice
- Privacy risk — data may be used for training

**Never send to free models:**
- Private repo code
- Secrets, credentials, API keys
- Auth, payment, customer data
- Proprietary planning or architecture

### Non-Sensitive Planning / Helper Tasks

**Use:** Free models (if Go quota exhausted)
- mimo-v2.5-free: Scored, non-sensitive only
- Privacy warning: Data may be used for training
- Quota: Free / quota not modeled / limited-time availability


---

## Quota and Cost Efficiency

### Go Subscription Limits

- **5-hour limit:** $12 of usage
- **Weekly limit:** $30 of usage
- **Monthly limit:** $60 of usage

Limits are dollar-value based, not request-count based. Actual request count depends on model pricing and token patterns.

### Cost Endurance Comparison

| Model | Cost/Request | Requests per $12/5h | Quota Endurance |
|-------|-------------|---------------------|-----------------|
| deepseek-v4-flash | $0.0003 | ~31,650 | Very High |
| mimo-v2.5 | $0.0004 | ~30,100 | Very High |
| qwen3.7-plus | $0.0028 | ~4,300 | Strong |
| qwen3.6-plus | $0.0037 | ~3,300 | Moderate |
| kimi-k2.6 | $0.0096 | ~1,150 | Low |
| glm-5.1 | $0.0137 | ~880 | Very Low |

**Key Insight:** deepseek-v4-flash allows 36× more requests than glm-5.1 under the same quota. Use expensive models sparingly.

### Quota-Low Guidance

When quota is low:
1. **Shift exploration/debug** to deepseek-v4-flash (ultra-cheap)
2. **Reserve qwen3.7-plus** for final architecture/implementation decisions
3. **Reserve glm-5.1/kimi-k2.6** for high-risk changes only
4. **Avoid premium models** unless critical

### Go Quota Exhausted Guidance

When Go quota is exhausted:
1. **Free models remain available** for non-sensitive tasks
2. **Never send sensitive data** to free models (privacy risk)
3. **Use mimo-v2.5-free** for scored non-sensitive work
4. **Avoid qwen3.6-plus-free and minimax-m3-free** (privacy unspecified)


---

## Model Eligibility Legend

### Router Use Modes

- **scored** — Model has numeric evaluation evidence and can receive composite scores
- **incumbent_baseline** — Production incumbent by protocol, but no standalone numeric eval
- **canary_only** — Detected but not production-ready, requires canary evaluation
- **avoid** — Deprecated, unknown pricing, or privacy risk

### Pricing Status

- **known** — Full pricing data from Go docs
- **inferred_from_zen** — Pricing inferred from Zen docs (not Go-specific)
- **unknown** — No pricing data available, cannot calculate cost scores

### Privacy Tiers

- **go-subscription** — Go paid models, zero-retention (safe for sensitive context)
- **zen-paid-*** — Zen paid models, provider-specific retention policies
- **free-training-exception** — Free models, data may be used for training
- **free-nvidia-logged** — Nemotron free, sessions logged for NVIDIA improvement
- **free-stealth-training** — Big Pickle, stealth model, data may be used for training
- **free-unspecified** — Free models without explicit privacy statement (assume unsafe)

### Deprecation Status

- **active** — Model is active and supported
- **deprecated** — Model is deprecated, avoid unless explicitly approved
- **scheduled_deprecation** — Model will be deprecated on specified date, receive warning


---

## Warnings and Validation

**ℹ️ INFO:** Models with unknown pricing (no cost scores):
- mimo-v2-pro
- mimo-v2-omni
- hy3-preview

These models cannot receive cost-quality scores until pricing is known.

**ℹ️ INFO:** 4 model(s) detected but unevaluated
- These models are in the endpoint but not in the registry expected set
- Do not use for production until canary evaluation passes
- Run `/model-snapshot` to see details

### Validation Summary

- **Validation errors:** 0
- **Validation warnings:** 0

**✅ VALIDATION PASSED** — Report is ready for use.


---

## Next Steps

1. **Review recommendations** — Ensure they align with your task requirements
2. **Check quota status** — Adjust model selection based on current quota
3. **Run canary evals** — For models marked as canary_only or incumbent_baseline
4. **Update registry** — After evals, update capability_profiles with numeric scores

### Recommended Eval Priorities

Based on this report, the highest-value evals would be:

1. **deepseek-v4-flash** — Production incumbent for high-volume work, no numeric eval
2. **glm-5.1** — Production incumbent reviewer, expensive, should justify cost
3. **kimi-k2.7-code** — Newly detected, may challenge kimi-k2.6 reviewer role
4. **qwen3.6-plus-free** — Free fallback candidate, needs privacy confirmation
5. **minimax-m3-free** — Free UI/QA fallback candidate, needs privacy confirmation

---

**Report generated by:** .opencode/scripts/model-router-report.sh
**Advisory only:** This report does not change routing or invoke models
**Registry source:** .opencode/model-registry.yaml
