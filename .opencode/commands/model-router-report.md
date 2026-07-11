---
description: Generate advisory model router report with recommendations by task type
---

# Model Router Report

Generate an advisory report recommending models by task type, balancing capability, cost efficiency, quota endurance, privacy safety, and evidence confidence.

## Purpose

This command helps you decide which model to use for a given task by analyzing:

- **Capability scores** from evaluation evidence
- **Cost efficiency** from pricing and token patterns
- **Quota endurance** under Go subscription limits ($12/5h, $30/week, $60/month)
- **Privacy safety** for sensitive vs non-sensitive work
- **Evidence confidence** from benchmark and eval artifacts

## Usage

```bash
# Generate today's router report
/model-router-report

# Or run the script directly
bash .opencode/scripts/model-router-report.sh
```

## Output

The report is generated at:
```
.opencode/benchmarks/model-router-reports/YYYY-MM-DD-router-report.md
```

## What the Report Contains

### 1. Production Role Recommendations

Advisory recommendations for:
- **Orchestrator / Primary Planning** — High-risk architecture, complex planning
- **Implementer / Code Generation** — Production implementation, bounded coding
- **Reviewer / Code Review** — Code review, senior review, risk assessment
- **Explorer / Budget / Debug Loop** — High-volume, low-cost exploration
- **UI/Multimodal QA Helper** — Screenshot QA, accessibility audit, theme review
- **Non-Sensitive Free Fallback** — Free models for non-sensitive work only

### 2. Task-Type Recommendations

Task-specific guidance for:
- High-risk architecture / planning
- Production implementation
- Low-risk code exploration
- Repeated debugging loops
- Review / senior review
- UI/UX polish / multimodal QA
- Quota-low mode (when quota is running low)
- Go quota exhausted mode (when Go quota is fully consumed)
- Non-sensitive planning / helper tasks

### 3. Quota and Cost Efficiency

- Go subscription limits ($12/5h, $30/week, $60/month)
- Cost endurance comparison table
- Quota-low guidance (shift to cheap models)
- Go quota exhausted guidance (free models only, non-sensitive)

### 4. Model Eligibility Legend

Explains:
- **Router use modes:** scored, incumbent_baseline, canary_only, avoid
- **Pricing status:** known, inferred_from_zen, unknown
- **Privacy tiers:** go-subscription, zen-paid-*, free-*, etc.
- **Deprecation status:** active, deprecated, scheduled_deprecation

### 5. Warnings and Validation

Automated checks for:
- Free models incorrectly marked as sensitive-safe
- Unknown-pricing models (cannot calculate cost scores)
- Deprecated models (avoid unless approved)
- Scheduled deprecations (plan migration)
- Unevaluated models (detected but not production-ready)

## Model Use Modes

### Scored Models

Models with numeric evaluation evidence. Can receive composite scores based on capability, reliability, cost, privacy, and deprecation.

**Examples:**
- qwen3.7-plus (10.0/10 benchmark)
- qwen3.6-plus (9.9/10 benchmark)
- kimi-k2.6 (4.8/5.0 reviewer eval)
- minimax-m3 (4.6/5.0 UI eval)
- mimo-v2.5-free (4.7/5.0 free-tier eval)

### Incumbent Baseline Models

Production incumbents by protocol, but no standalone numeric eval artifact. Recommended with caution.

**Examples:**
- deepseek-v4-flash (explorer/budget/debug_loop incumbent)
- glm-5.1 (reviewer incumbent)

**Action:** Consider running numeric evals to validate these incumbents.

### Canary-Only Models

Detected in endpoint but not production-ready. Require canary evaluation before production use.

**Examples:**
- kimi-k2.7-code (newly detected)
- qwen3.6-plus-free (free fallback candidate)
- minimax-m3-free (free UI/QA candidate)

**Action:** Do not use for production. Run canary eval first.

### Avoid Models

Deprecated, unknown pricing, or privacy risk.

**Examples:**
- glm-5 (deprecated 2026-05-14)
- mimo-v2-pro (unknown pricing)
- mimo-v2-omni (unknown pricing)
- hy3-preview (unknown pricing)

**Action:** Avoid unless explicitly approved.

## Scoring Model

The report uses a weighted scoring model:

| Factor | Weight | Description |
|--------|--------|-------------|
| Capability | 35% | Average of orchestration, implementation, review, debugging, tool_calling, long_running scores |
| Reliability | 25% | Evidence confidence score |
| Cost Efficiency | 20% | Inverse of cost tier (ultra-cheap=10, cheap=8, balanced=6, expensive=4, premium=2) |
| Privacy Safety | 15% | Privacy tier score (go-subscription=10, zen-paid=8, free=5) |
| Deprecation Penalty | 5% | Penalty for deprecated (-10) or scheduled_deprecation (-5) models |

**Formula:**
```
composite_score = (capability × 0.35 + reliability × 0.25 + cost × 0.20 + privacy × 0.15 - deprecation × 0.05)
```

## Safety Rules

This command is **ADVISORY ONLY**:

- ✅ Reads model-registry.yaml
- ✅ Generates markdown report
- ✅ Performs validation checks
- ❌ Does NOT change routing
- ❌ Does NOT promote/demote models
- ❌ Does NOT invoke any models
- ❌ Does NOT use API keys
- ❌ Does NOT modify config files

## Privacy Warnings

### Free Models

Free models are **non-sensitive only**:

- ❌ Never send private repo code
- ❌ Never send secrets, credentials, API keys
- ❌ Never send auth, payment, customer data
- ❌ Never send proprietary planning or architecture
- ✅ Use for non-sensitive exploration, debug loops, helper tasks
- ✅ Use when Go quota is exhausted

**Privacy tiers:**
- `free-training-exception` — Data may be used for model improvement
- `free-nvidia-logged` — Sessions logged for NVIDIA improvement
- `free-stealth-training` — Stealth model, data may be used for training
- `free-unspecified` — No explicit privacy statement (assume unsafe)

### Go Subscription Models

Go subscription models are **safe for sensitive context**:

- ✅ Private repo code
- ✅ Secrets, credentials (with Doppler)
- ✅ Auth, payment, customer data
- ✅ Proprietary planning and architecture

## Quota Management

### Go Subscription Limits

- **5-hour limit:** $12 of usage
- **Weekly limit:** $30 of usage
- **Monthly limit:** $60 of usage

Limits are dollar-value based, not request-count based.

### Cost Endurance

| Model | Cost/Request | Requests per $12/5h |
|-------|-------------|---------------------|
| deepseek-v4-flash | $0.0003 | ~31,650 |
| mimo-v2.5 | $0.0004 | ~30,100 |
| qwen3.7-plus | $0.0028 | ~4,300 |
| qwen3.6-plus | $0.0037 | ~3,300 |
| kimi-k2.6 | $0.0096 | ~1,150 |
| glm-5.1 | $0.0137 | ~880 |

**Key insight:** deepseek-v4-flash allows 36× more requests than glm-5.1 under the same quota.

### Quota-Low Strategy

When quota is low:

1. Shift exploration/debug to deepseek-v4-flash (ultra-cheap)
2. Reserve qwen3.7-plus for final architecture/implementation
3. Reserve glm-5.1/kimi-k2.6 for high-risk reviews only
4. Avoid premium models unless critical

### Go Quota Exhausted Strategy

When Go quota is exhausted:

1. Free models remain available for non-sensitive tasks
2. Use mimo-v2.5-free (scored, non-sensitive only)
3. Never send sensitive data to free models
4. Avoid qwen3.6-plus-free and minimax-m3-free (privacy unspecified)

## Validation Checks

The script performs automated validation:

1. **Free model privacy check** — Warns if free model marked sensitive-safe
2. **Unknown pricing check** — Lists models without pricing data
3. **Deprecation check** — Warns about deprecated models
4. **Scheduled deprecation check** — Lists models with upcoming deprecation
5. **Unevaluated model check** — Lists detected but unevaluated models

Validation results are included in the report.

## Related Commands

- `/model-snapshot` — Detect model availability and drift
- `/model-economics` — (Phase 2) View model economics and pricing
- `/model-capability` — (Phase 3) View capability profiles

## Implementation Phases

This command is part of the Model Intelligence Registry implementation:

- **Phase 1:** Model snapshot and drift detection ✅
- **Phase 2:** Economics registry (pricing, cost tiers, privacy) ✅
- **Phase 2A:** Consistency audit and fixes ✅
- **Phase 3:** Capability profiles (evidence-only) ✅
- **Phase 3A:** Incumbent coverage gap closure ✅
- **Phase 4:** Advisory router report ✅ (this command)

## Examples

### Example 1: High-Risk Architecture Task

**Task:** Design auth system for payment processing

**Report recommendation:**
- Use qwen3.7-plus (scored, high capability)
- Cost: $0.0028/request
- Quota: ~4,300 requests per $12/5h
- Add reviewer gate (glm-5.1 or kimi-k2.6) for risk-score-4+ changes

### Example 2: Debug Loop

**Task:** Investigate why tests are failing

**Report recommendation:**
- Use deepseek-v4-flash (incumbent baseline, ultra-cheap)
- Cost: $0.0003/request
- Quota: ~31,650 requests per $12/5h
- High-volume, low-cost — ideal for repeated debugging

### Example 3: UI Review

**Task:** Review mobile responsive layout

**Report recommendation:**
- Use minimax-m3 (scored, UI/multimodal specialist)
- UI/Multimodal score: 9.2/10
- Cost: $0.0037/request
- Manual specialist only

### Example 4: Go Quota Exhausted

**Task:** Explore repo structure (Go quota exhausted)

**Report recommendation:**
- Use mimo-v2.5-free (scored, non-sensitive only)
- Cost: Free
- Privacy: Training exception (data may be used for improvement)
- **Never send sensitive data to free models**

## Troubleshooting

### Report not generated

Check that:
- `.opencode/model-registry.yaml` exists
- `.opencode/scripts/model-router-report.sh` is executable
- `.opencode/benchmarks/model-router-reports/` directory exists

### Validation errors

Review the warnings section in the report:
- Free models should not be marked sensitive-safe
- Deprecated models should be avoided
- Unknown-pricing models cannot receive cost scores

### Missing model recommendations

Check that:
- Model is in `.opencode/model-registry.yaml` economics section
- Model has `router_score_ready: true` or `router_use_mode: incumbent_baseline`
- Model is not marked as `deprecated` or `unevaluated_do_not_route`

## See Also

- [Model Registry](.opencode/model-registry.yaml) — Canonical source for model data
- [Helper Roster](.opencode/helper-roster.md) — Production routing table
- [Model Snapshot](.opencode/commands/model-snapshot.md) — Detect model availability
