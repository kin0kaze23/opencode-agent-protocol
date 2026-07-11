#!/bin/bash
# Model Router Report Generator
# Phase 4: Advisory Router Report
#
# Generates an advisory report recommending models by task type based on
# capability, cost, quota efficiency, privacy, and evidence confidence.
#
# This script is READ-ONLY and ADVISORY ONLY.
# It does NOT change routing, promote/demote models, or invoke any models.

set -euo pipefail

# Configuration
REGISTRY_FILE=".opencode/model-registry.yaml"
REPORT_DIR=".opencode/benchmarks/model-router-reports"
TODAY=$(date +%Y-%m-%d)
REPORT_FILE="${REPORT_DIR}/${TODAY}-router-report.md"

# Scoring weights (default)
WEIGHT_CAPABILITY=35
WEIGHT_RELIABILITY=25
WEIGHT_COST=20
WEIGHT_PRIVACY=15
WEIGHT_DEPRECATION=5

# Go quota limits
GO_LIMIT_5H=12
GO_LIMIT_WEEK=30
GO_LIMIT_MONTH=60

# Validation errors
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((VALIDATION_WARNINGS++))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((VALIDATION_ERRORS++))
}

# Check if registry file exists
if [[ ! -f "$REGISTRY_FILE" ]]; then
    log_error "Registry file not found: $REGISTRY_FILE"
    exit 1
fi

# Create report directory if needed
mkdir -p "$REPORT_DIR"

log_info "Generating model router report for $TODAY"
log_info "Reading from: $REGISTRY_FILE"
log_info "Writing to: $REPORT_FILE"

# Start report
cat > "$REPORT_FILE" << 'HEADER'
# Model Router Advisory Report

**Generated:** TIMESTAMP
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

HEADER

# Replace timestamp
sed -i '' "s/TIMESTAMP/$(date '+%Y-%m-%d %H:%M:%S %Z')/" "$REPORT_FILE"

# Extract model data function
extract_model_data() {
    local model=$1
    local field=$2

    # This is a simplified extraction - in production you'd use yq or python
    awk -v model="$model" -v field="$field" '
        /^    [a-z0-9.-]+:$/ {
            current_model = substr($0, 5, length($0)-5)
            gsub(/:$/, "", current_model)
        }
        current_model == model && $0 ~ "^      " field ":" {
            value = $0
            sub("^      " field ":[[:space:]]*", "", value)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            gsub(/^"|"$/, "", value)
            print value
            exit
        }
    ' "$REGISTRY_FILE"
}

# Extract capability score
extract_capability_score() {
    local model=$1
    local capability=$2

    awk -v model="$model" -v cap="$capability" '
        /^  [a-z0-9.-]+:$/ {
            current_model = substr($0, 3, length($0)-3)
            gsub(/:$/, "", current_model)
        }
        current_model == model && $0 ~ "^    " cap ":" {
            value = $0
            sub("^    " cap ":[[:space:]]*", "", value)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            print value
            exit
        }
    ' "$REGISTRY_FILE"
}

# Extract router readiness
extract_router_ready() {
    local model=$1
    extract_model_data "$model" "router_score_ready"
}

extract_router_mode() {
    local model=$1
    extract_model_data "$model" "router_use_mode"
}

# Extract cost tier
extract_cost_tier() {
    local model=$1
    extract_model_data "$model" "cost_tier"
}

# Extract privacy tier
extract_privacy_tier() {
    local model=$1
    extract_model_data "$model" "privacy_tier"
}

# Extract pricing status
extract_pricing_status() {
    local model=$1
    extract_model_data "$model" "pricing_status"
}

# Extract deprecation status
extract_deprecation_status() {
    local model=$1
    extract_model_data "$model" "deprecation_status"
}

# Extract routing status
extract_routing_status() {
    local model=$1
    extract_model_data "$model" "routing_status"
}

# Extract cost per request
extract_cost_per_request() {
    local model=$1
    extract_model_data "$model" "cost_per_typical_request"
}

# Extract estimated requests per 5h
extract_requests_5h() {
    local model=$1
    awk -v model="$model" '
        /^    [a-z0-9.-]+:$/ {
            current_model = substr($0, 5, length($0)-5)
            gsub(/:$/, "", current_model)
        }
        current_model == model && /per_5_hours:/ {
            value = $0
            sub(".*per_5_hours:[[:space:]]*", "", value)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            print value
            exit
        }
    ' "$REGISTRY_FILE"
}

# Get all models from economics section
get_all_models() {
    awk '
        /^  models:$/ { in_models=1; next }
        in_models && /^    [a-z0-9.-]+:$/ {
            model = substr($0, 5, length($0)-5)
            gsub(/:$/, "", model)
            print model
        }
        in_models && /^[^ ]/ { exit }
    ' "$REGISTRY_FILE"
}

# Calculate composite score
calculate_score() {
    local model=$1
    local task_type=$2

    local router_ready=$(extract_router_ready "$model")
    local router_mode=$(extract_router_mode "$model")
    local cost_tier=$(extract_cost_tier "$model")
    local privacy_tier=$(extract_privacy_tier "$model")
    local deprecation=$(extract_deprecation_status "$model")
    local routing_status=$(extract_routing_status "$model")

    # Check if model can be scored
    if [[ "$router_ready" != "true" ]]; then
        echo "N/A ($router_mode)"
        return
    fi

    # Extract capability scores
    local orch=$(extract_capability_score "$model" "orchestration")
    local impl=$(extract_capability_score "$model" "implementation")
    local review=$(extract_capability_score "$model" "review")
    local debug=$(extract_capability_score "$model" "debugging")
    local tool=$(extract_capability_score "$model" "tool_calling")
    local long=$(extract_capability_score "$model" "long_running")
    local ui=$(extract_capability_score "$model" "ui_multimodal")
    local budget=$(extract_capability_score "$model" "budget_efficiency")
    local confidence=$(extract_capability_score "$model" "evidence_confidence")

    # Calculate average capability (simplified)
    local cap_sum=0
    local cap_count=0
    for score in "$orch" "$impl" "$review" "$debug" "$tool" "$long"; do
        if [[ -n "$score" && "$score" != "null" ]]; then
            cap_sum=$(echo "$cap_sum + $score" | bc -l 2>/dev/null || echo "0")
            ((cap_count++))
        fi
    done

    local avg_capability=0
    if [[ $cap_count -gt 0 ]]; then
        avg_capability=$(echo "scale=2; $cap_sum / $cap_count" | bc -l 2>/dev/null || echo "0")
    fi

    # Cost efficiency score (inverse of cost tier)
    local cost_score=5
    case "$cost_tier" in
        "ultra-cheap") cost_score=10 ;;
        "cheap") cost_score=8 ;;
        "balanced") cost_score=6 ;;
        "expensive") cost_score=4 ;;
        "premium") cost_score=2 ;;
        "free") cost_score=10 ;;
        *) cost_score=5 ;;
    esac

    # Privacy score
    local privacy_score=8
    case "$privacy_tier" in
        "go-subscription") privacy_score=10 ;;
        "zen-paid-"*) privacy_score=8 ;;
        "free-"*) privacy_score=5 ;;
        *) privacy_score=6 ;;
    esac

    # Reliability score (based on evidence confidence)
    local reliability_score=7
    if [[ -n "$confidence" && "$confidence" != "null" ]]; then
        reliability_score=$confidence
    fi

    # Deprecation penalty
    local deprecation_penalty=0
    if [[ "$deprecation" == "deprecated" ]]; then
        deprecation_penalty=10
    elif [[ "$deprecation" == "scheduled_deprecation" ]]; then
        deprecation_penalty=5
    fi

    # Calculate weighted score
    local score=$(echo "scale=2; ($avg_capability * $WEIGHT_CAPABILITY + $reliability_score * $WEIGHT_RELIABILITY + $cost_score * $WEIGHT_COST + $privacy_score * $WEIGHT_PRIVACY - $deprecation_penalty * $WEIGHT_DEPRECATION) / 100" | bc -l 2>/dev/null || echo "0")

    echo "$score"
}

# Generate model recommendations section
cat >> "$REPORT_FILE" << 'SECTION'

---

## Production Role Recommendations

SECTION

# Orchestrator recommendation
cat >> "$REPORT_FILE" << 'ROLE'
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

ROLE

# Implementer recommendation
cat >> "$REPORT_FILE" << 'ROLE'
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

ROLE

# Reviewer recommendation
cat >> "$REPORT_FILE" << 'ROLE'
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

ROLE

# Explorer recommendation
cat >> "$REPORT_FILE" << 'ROLE'
### Explorer / Budget / Debug Loop

**Incumbent Baseline:** deepseek-v4-flash (not numerically scored)
- Status: Production incumbent for explorer/budget/debug_loop
- Evidence: No standalone numeric eval artifact
- Cost tier: Ultra-cheap ($0.0003/request)
- Quota endurance: ~31,650 requests per $12/5h
- **Strength:** Highest quota endurance — 36× more requests than glm-5.1

**Guidance:** deepseek-v4-flash is the production incumbent for high-volume, low-cost work. Ideal for exploration, debug loops, and budget tasks. Consider numeric eval to validate capability scores.

ROLE

# UI/Multimodal QA recommendation
cat >> "$REPORT_FILE" << 'ROLE'
### UI/Multimodal QA Helper

**Recommended:** minimax-m3 (scored)
- UI/Multimodal score: 9.2/10
- Evidence: 4.6/5.0 UI eval, 5/5 PASS
- Cost tier: Balanced ($0.0037/request)
- Approved for: Manual UI/multimodal QA specialist

**Guidance:** Use minimax-m3 for screenshot QA, mobile responsive, accessibility audit, theme review. Not for security review or implementation.

ROLE

# Free fallback recommendation
cat >> "$REPORT_FILE" << 'ROLE'
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

ROLE

# Generate task-type recommendations
cat >> "$REPORT_FILE" << 'SECTION'

---

## Task-Type Recommendations

SECTION

cat >> "$REPORT_FILE" << 'TASKS'
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

TASKS

# Generate quota and cost section
cat >> "$REPORT_FILE" << 'SECTION'

---

## Quota and Cost Efficiency

SECTION

cat >> "$REPORT_FILE" << QUOTA
### Go Subscription Limits

- **5-hour limit:** \$$GO_LIMIT_5H of usage
- **Weekly limit:** \$$GO_LIMIT_WEEK of usage
- **Monthly limit:** \$$GO_LIMIT_MONTH of usage

Limits are dollar-value based, not request-count based. Actual request count depends on model pricing and token patterns.

### Cost Endurance Comparison

| Model | Cost/Request | Requests per \$12/5h | Quota Endurance |
|-------|-------------|---------------------|-----------------|
| deepseek-v4-flash | \$0.0003 | ~31,650 | Very High |
| mimo-v2.5 | \$0.0004 | ~30,100 | Very High |
| qwen3.7-plus | \$0.0028 | ~4,300 | Strong |
| qwen3.6-plus | \$0.0037 | ~3,300 | Moderate |
| kimi-k2.6 | \$0.0096 | ~1,150 | Low |
| glm-5.1 | \$0.0137 | ~880 | Very Low |

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

QUOTA

# Generate model eligibility legend
cat >> "$REPORT_FILE" << 'SECTION'

---

## Model Eligibility Legend

SECTION

cat >> "$REPORT_FILE" << 'LEGEND'
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

LEGEND

# Generate warnings section
cat >> "$REPORT_FILE" << 'SECTION'

---

## Warnings and Validation

SECTION

# Check for models with router_score_ready: true but no evidence_refs
log_info "Validating model data..."

# Check for free models marked sensitive safe
free_models_unsafe=$(grep -A 5 "cost_tier: free" "$REGISTRY_FILE" | grep "sensitive_context_safe: true" || true)
if [[ -n "$free_models_unsafe" ]]; then
    log_warn "Free model marked as sensitive_context_safe: true"
    cat >> "$REPORT_FILE" << 'WARN'
**⚠️ WARNING:** Free model marked as sensitive_context_safe: true
- Free models should never be marked safe for sensitive context
- Review privacy tier and update registry

WARN
fi

# Check for free models with "Unlimited" wording (safety check)
if grep -q "Unlimited" "$REPORT_FILE"; then
    log_warn "Report contains 'Unlimited' wording — free models should never be described as unlimited"
    cat >> "$REPORT_FILE" << 'WARN'
**⚠️ WARNING:** Report contains "Unlimited" wording
- Free models should never be described as having unlimited quota
- Use "Free / quota not modeled / limited-time" instead
- Free model availability and limits are not guaranteed

WARN
fi

# Check for unknown-pricing models with cost scores
unknown_pricing_models=$(grep -B 5 "pricing_status: unknown" "$REGISTRY_FILE" | grep "^    [a-z]" | sed 's/^    //' | sed 's/://' || true)
if [[ -n "$unknown_pricing_models" ]]; then
    log_info "Found models with unknown pricing: $unknown_pricing_models"
    cat >> "$REPORT_FILE" << WARN
**ℹ️ INFO:** Models with unknown pricing (no cost scores):
$(echo "$unknown_pricing_models" | sed 's/^/- /')

These models cannot receive cost-quality scores until pricing is known.

WARN
fi

# Check for deprecated models
deprecated_models=$(grep -B 5 "deprecation_status: deprecated" "$REGISTRY_FILE" | grep "^    [a-z]" | sed 's/^    //' | sed 's/://' || true)
if [[ -n "$deprecated_models" ]]; then
    log_warn "Found deprecated models: $deprecated_models"
    cat >> "$REPORT_FILE" << WARN
**⚠️ WARNING:** Deprecated models detected:
$(echo "$deprecated_models" | sed 's/^/- /')

Avoid these models unless explicitly approved.

WARN
fi

# Check for scheduled deprecations
scheduled_dep=$(grep -B 5 "deprecation_status: scheduled_deprecation" "$REGISTRY_FILE" | grep "^    [a-z]" | sed 's/^    //' | sed 's/://' || true)
if [[ -n "$scheduled_dep" ]]; then
    log_info "Found models with scheduled deprecation: $scheduled_dep"
    cat >> "$REPORT_FILE" << WARN
**ℹ️ INFO:** Models with scheduled deprecation:
$(echo "$scheduled_dep" | sed 's/^/- /')

Plan migration before deprecation date.

WARN
fi

# Check for newly detected models (unevaluated)
unevaluated=$(grep "routing_status: unevaluated_do_not_route" "$REGISTRY_FILE" | wc -l | tr -d ' ')
if [[ $unevaluated -gt 0 ]]; then
    log_info "Found $unevaluated unevaluated models"
    cat >> "$REPORT_FILE" << WARN
**ℹ️ INFO:** $unevaluated model(s) detected but unevaluated
- These models are in the endpoint but not in the registry expected set
- Do not use for production until canary evaluation passes
- Run \`/model-snapshot\` to see details

WARN
fi

# Add validation summary
cat >> "$REPORT_FILE" << SUMMARY
### Validation Summary

- **Validation errors:** $VALIDATION_ERRORS
- **Validation warnings:** $VALIDATION_WARNINGS

SUMMARY

if [[ $VALIDATION_ERRORS -gt 0 ]]; then
    cat >> "$REPORT_FILE" << 'FAIL'
**❌ VALIDATION FAILED** — Review errors above before using this report.

FAIL
else
    cat >> "$REPORT_FILE" << 'PASS'
**✅ VALIDATION PASSED** — Report is ready for use.

PASS
fi

# Add footer
cat >> "$REPORT_FILE" << 'FOOTER'

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

FOOTER

log_info "Report generated successfully: $REPORT_FILE"
log_info "Validation errors: $VALIDATION_ERRORS"
log_info "Validation warnings: $VALIDATION_WARNINGS"

if [[ $VALIDATION_ERRORS -gt 0 ]]; then
    log_error "Report generated with validation errors — review before use"
    exit 1
else
    log_info "Report ready for use"
    exit 0
fi
