---
description: "Snapshot OpenCode Go and Zen model lists, detect production drift + Zen Free fallback drift, generate canary and fallback suggestions"
---

# /model-snapshot

Detect available models from OpenCode Go and Zen endpoints, compare against the model registry and expected Zen Free roster, and generate dual-track drift reports with canary and fallback suggestions.

## What this does

**Track 1 — Go Production Model Drift:**
1. Fetches the current model list from `https://opencode.ai/zen/go/v1/models`
2. Compares against `expected_official_set` in `.opencode/model-registry.yaml`
3. Identifies new, removed, and deprecated Go models
4. Generates canary suggestions for any new models

**Track 2 — Zen Free Fallback Roster Drift:**
1. Fetches the current model list from `https://opencode.ai/zen/v1/models`
2. Extracts free models and compares against expected Zen Free roster
3. Identifies new, removed, and tracked free fallback models
4. Generates fallback suggestions with role classification and privacy warnings

## Safety

- **Read-only** — does NOT modify model-registry.yaml or any config file
- **No billing impact** — uses public /models endpoint, no model invocation
- **No API key required** — endpoint is public metadata
- **Output only** — writes to `.opencode/benchmarks/model-snapshots/`
- **Free models are NOT production routing** — all suggestions are advisory

## Usage

```bash
bash .opencode/scripts/model-snapshot.sh
```

## Output files

| File | Content |
|---|---|
| `YYYY-MM-DD-go.json` | Go endpoint model list snapshot |
| `YYYY-MM-DD-zen.json` | Zen endpoint model list snapshot |
| `YYYY-MM-DD-diff.md` | Dual-track drift report (Go production + Zen Free fallback) |
| `canary-suggestions.md` | New Go models flagged for paid-tier evaluation |
| `free-fallback-suggestions.md` | Zen Free fallback role classification + privacy warnings |

## After running

1. Review the diff report (both tracks)
2. Review canary suggestions for new Go production models
3. Review free fallback suggestions for quota-exhaustion planning
4. If new models warrant evaluation, manually edit `model-registry.yaml`
5. Commit the snapshot artifacts as baseline evidence

## Validation

For the **initial baseline run**, verify the current expected drift:
- Go drift is detected (new models not in registry expected_official_set)
- Zen Free fallback roster is detected (7 expected free models)
- Newly detected free models are flagged (if any)
- Removed free models are flagged (if any)
- Free fallback recommendations are advisory only
- No sensitive/private routing is recommended to free models
- No config or registry files were modified

For **future runs**, verify the script reports the actual diff against the current registry and expected Zen Free roster. Exact counts will vary as the registry is updated.

## Quota exhaustion context

OpenCode Go limits are dollar-value based ($12/5h, $30/week, $60/month).
When limits are reached, free models remain available but with reduced privacy.
The free fallback suggestions report helps plan for this scenario safely.
