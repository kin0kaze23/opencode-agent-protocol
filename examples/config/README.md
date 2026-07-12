# Config Templates

> **Purpose:** Placeholder configs for adapting the protocol to your own providers.

## Files

| Template | Purpose |
|----------|---------|
| `brain-config.template.json` | Brain config with placeholder providers |
| `model-routing-policy.template.yaml` | Routing policy with placeholder models |
| `opencode.template.json` | OpenCode runtime config template |

See [docs/OWN_MODEL_SETUP.md](../../docs/OWN_MODEL_SETUP.md) for setup instructions.

---

## Example Setups

### 1. Minimal Docs-Only Setup

For a user who only wants to use the protocol for documentation work:

```json
// brain-config.json (minimal)
{
  "version": "5.5.2",
  "name": "Docs Protocol",
  "description": "Minimal setup for docs-only tasks",
  "default_model_role": "YOUR_PRIMARY_MODEL",
  "routing": {
    "implementation": { "primary": "YOUR_PRIMARY_MODEL" },
    "review": { "primary": "YOUR_PRIMARY_MODEL" }
  }
}
```

- Only one model needed
- No fallback chain (acceptable for low-risk docs work)
- No separate reviewer model (same model reviews its own work — acceptable for DIRECT lane)

### 2. Small App Bugfix Setup

For a user working on a small application with bug fixes and small features:

```yaml
# model-routing-policy.yaml (small app)
routing:
  implementation:
    primary: YOUR_PRIMARY_MODEL
    fallback: YOUR_FALLBACK_MODEL
  review:
    primary: YOUR_REVIEWER_MODEL
  architecture:
    primary: YOUR_PRIMARY_MODEL
  exploration:
    primary: YOUR_FALLBACK_MODEL

fallback_chains:
  implementation:
    - YOUR_PRIMARY_MODEL
    - YOUR_FALLBACK_MODEL
  review:
    - YOUR_REVIEWER_MODEL
```

- Two models: primary (stronger) and fallback (cheaper)
- Separate reviewer model for independent quality checks
- Fallback chain for resilience

### 3. Stricter High-Risk Setup

For a user working on security-sensitive or production-critical code:

```yaml
# model-routing-policy.yaml (high-risk)
routing:
  implementation:
    primary: YOUR_PRIMARY_MODEL
    fallback: YOUR_FALLBACK_MODEL
  review:
    primary: YOUR_REVIEWER_MODEL
  architecture:
    primary: YOUR_ARCHITECTURE_MODEL
  exploration:
    primary: YOUR_EXPLORER_MODEL

fallback_chains:
  implementation:
    - YOUR_PRIMARY_MODEL
    - YOUR_FALLBACK_MODEL
  review:
    - YOUR_REVIEWER_MODEL
    - YOUR_PRIMARY_MODEL
  architecture:
    - YOUR_ARCHITECTURE_MODEL
    - YOUR_PRIMARY_MODEL
  exploration:
    - YOUR_EXPLORER_MODEL
    - YOUR_FALLBACK_MODEL
```

- Four models: primary, fallback, reviewer, architecture, explorer
- Reviewer model differs from implementation model
- Architecture model for high-risk decisions
- Explorer model for cheap read-only work
- Full fallback chains for every role

---

## What Not to Do

- **Never** hardcode API keys in config files — use environment variables
- **Never** remove the fallback chain for implementation tasks
- **Never** use the same model for both implementation and review on HIGH-RISK tasks
- **Never** put personal project names or paths in config files
