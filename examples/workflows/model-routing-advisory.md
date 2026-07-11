# Example: Model Routing Advisory Flow

> **Scenario:** A user wants to understand how model routing recommendations work.

## User Task

The user wants to know which model the protocol recommends for a STANDARD lane implementation task, and why.

## How Model Routing Works

Model routing is **advisory** — it provides recommendations, not enforcement. The routing policy considers:

1. **Task type** — implementation, review, architecture, exploration
2. **Risk level** — DIRECT, FAST, STANDARD, HIGH-RISK
3. **Provider availability** — primary, fallback, premium reserve
4. **Eval evidence** — model ROI scorecard, task replay results

## Checking the Current Routing

```bash
# View the model registry
cat .opencode/model-registry.yaml

# View the recommended routing policy
cat .opencode/config/model-routing-policy.recommended.yaml

# View the helper roster
cat .opencode/helper-roster.md
```

## Example Routing Decision

For a STANDARD lane implementation task:

1. **Primary:** `umans-coder` (capacity lane, implementation-focused)
2. **Fallback:** `qwen3.7-plus` (premium reserve, high-quality)
3. **Reviewer:** `umans-glm-5.1` (review/judge role)

The routing is based on:
- Eval evidence showing `umans-coder` performs well on implementation tasks
- Cost efficiency (capacity lane is cheaper than premium)
- Fallback chain ensures resilience

## What the Protocol Guarantees

- Routing recommendations are backed by eval evidence
- Fallback chains are defined for every role
- Models with empty-response history are blocked

## What the Protocol Does Not Guarantee

- Model availability (provider may be down)
- Latency (depends on provider load)
- Quality (evals are point-in-time, not continuous)

## How to Customize

See [docs/CONFIGURATION_GUIDE.md](CONFIGURATION_GUIDE.md) → "How to Customize Model Routing"
