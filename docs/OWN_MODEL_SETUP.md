# Own Model Setup Guide

> **Purpose:** How to adapt the OpenCode Agent Protocol to your own model providers.
> **Last Updated:** 2026-07-11

---

## Overview

The protocol ships with model routing configured for the original author's providers. This guide shows you how to adapt it to your own setup — whether you use OpenAI, Anthropic, a local model, or a custom provider.

**What you need before starting:**
- OpenCode installed
- API keys for your chosen provider(s)
- Basic familiarity with YAML and JSON

---

## Step 1: Choose Your Providers

The protocol supports multiple providers with fallback chains. You need at least:

| Role | Purpose | Minimum |
|------|---------|---------|
| Primary | Routine tasks | 1 provider |
| Fallback | When primary fails | 1 provider (can be same as primary) |
| Reviewer | Independent review | 1 provider (can be same as primary) |

### Common Provider Options

| Provider | API Key Env Var | Notes |
|----------|----------------|-------|
| OpenAI | `OPENAI_API_KEY` | GPT-4, GPT-4o, etc. |
| Anthropic | `ANTHROPIC_API_KEY` | Claude 3.5 Sonnet, Opus, etc. |
| OpenRouter | `OPENROUTER_API_KEY` | Multi-model access |
| Local (Ollama) | N/A | No API key needed |
| Custom | Your env var | Any OpenAI-compatible endpoint |

---

## Step 2: Update the Model Registry

Edit `.opencode/model-registry.yaml`. Replace the existing model entries with your own:

```yaml
# Example: OpenAI provider
your_primary_model:
  provider: openai
  model: gpt-4o
  context_window: 128000
  role: implementation
  api_key_env: OPENAI_API_KEY

# Example: Anthropic provider
your_reviewer_model:
  provider: anthropic
  model: claude-3-5-sonnet-20241022
  context_window: 200000
  role: review
  api_key_env: ANTHROPIC_API_KEY

# Example: Local model (no API key)
your_fallback_model:
  provider: ollama
  model: llama3
  context_window: 8000
  role: fallback
```

### What Not to Hardcode

- **Never** put API key values directly in the config — use `api_key_env` to reference environment variables
- **Never** put personal paths, project names, or identity in the config
- **Never** remove the fallback chain — always have a backup model

---

## Step 3: Update brain-config.json

Edit `.opencode/brain-config.json`. Update the routing to reference your models:

```json
{
  "version": "5.5.1",
  "name": "Your Protocol Name",
  "description": "Your description",
  "default_model_role": "YOUR_PRIMARY_MODEL",
  "routing": {
    "implementation": ["your_primary_model", "your_fallback_model"],
    "review": ["your_reviewer_model"],
    "architecture": ["your_primary_model"],
    "exploration": ["your_fallback_model"]
  }
}
```

Or use the template: `examples/config/brain-config.template.json`

---

## Step 4: Update the Routing Policy

Edit `.opencode/config/model-routing-policy.recommended.yaml`:

```yaml
# Your routing policy
routing:
  implementation:
    primary: your_primary_model
    fallback: your_fallback_model
  review:
    primary: your_reviewer_model
  architecture:
    primary: your_primary_model
  exploration:
    primary: your_fallback_model
```

Or use the template: `examples/config/model-routing-policy.template.yaml`

---

## Step 5: Validate

```bash
# Verify config is valid
bash scripts/validate-config-schema.sh

# Verify docs haven't drifted
bash scripts/validate-docs-drift.sh

# Run protocol conformance
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh
```

---

## What Should Remain Advisory

- **Model routing** — recommendations only, not enforced at runtime
- **Reviewer policy** — recommendations for when to require independent review
- **Risk classification** — advisory lane selection, not hard enforcement
- **Token budgets** — soft warnings, not hard caps

## What Should Not Be Changed Casually

- **Safety rules** in `.opencode/AGENTS.md` — these are the core guardrails
- **Privacy scan patterns** in `scripts/public-surface-scan.sh` — these protect against data leaks
- **CI workflow** in `.github/workflows/validation.yml` — this enforces the protocol
- **Branch protection** — this prevents unsafe merges

---

## Template Configs

See [examples/config/](../examples/config/) for placeholder templates:
- `brain-config.template.json` — brain config with placeholder providers
- `model-routing-policy.template.yaml` — routing policy with placeholder models
- `opencode.template.json` — OpenCode runtime config template

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `validate-config-schema.sh` fails | Check that model-registry.yaml has valid YAML and at least 3 model entries |
| Model not found at runtime | Check that `api_key_env` matches your environment variable name |
| Routing not working | Check that brain-config.json routing keys match model-registry.yaml model IDs |
| Privacy scan fails | Check that no personal data was added to config files |
