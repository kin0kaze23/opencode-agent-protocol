# OpenCode Performance Metrics

**Version:** 1.0.0
**Date:** 2026-05-26
**Phase:** P3A (Passive Metrics Schema)

---

## Purpose

Passive, privacy-safe performance tracking for OpenCode agent/model routes. Enables optimization of model routing, cost, latency, and agent quality without logging sensitive data.

---

## Schema

See `schema.json` for the full JSON Schema definition.

### Allowed Fields
- `timestamp`
- `workspace`
- `git_sha`
- `agent`
- `task_type`
- `model_route`
- `fallback_escalation`
- `latency_ms`
- `status`
- `tokens_in` / `tokens_out`
- `estimated_cost`
- `error_category`
- `conformance_status`

### Forbidden Fields (Privacy Rules)
- `prompt`
- `response`
- `secrets`
- `file_contents`
- `api_keys`
- `user_data`
- `customer_data`
- `raw_command_output`

---

## Storage Strategy

### Raw Logs
- Location: `.opencode/metrics/raw/`
- Format: JSON lines (`.jsonl`)
- Git status: **Gitignored** (never committed)
- Rotation: Deleted after 30 days or when size exceeds 100MB

### Sanitized Summaries
- Location: `.opencode/metrics/summaries/`
- Format: JSON
- Git status: **May be committed** if sanitized (no sensitive data, aggregated only)
- Frequency: Daily or weekly

---

## Retention Policy

| Data Type | Retention | Deletion Method |
|---|---|---|
| Raw logs | 30 days | Automatic rotation script |
| Sanitized summaries | 90 days | Manual review and cleanup |
| Aggregated reports | 1 year | Archive to long-term storage |

---

## Future Capture Plan (P3B)

### Mechanism
- Lightweight wrapper script or logger
- No behavior changes to agents or routing
- Best-effort metrics only (non-blocking)

### Integration Points
- Pre-commit hook (Tier 1 checks)
- GitHub Actions workflow
- Manual conformance runs
- Agent task execution (future)

---

## Cost/Token Estimation (P3C)

### Approach
- Use provider usage data when available
- If token usage is unavailable, record `tokens: unknown`, `cost: unknown`
- **No fake precision**
- Local optional rate card (`rate-card.local.json`) for estimation
- Rate card is gitignored to prevent accidental commits of sensitive pricing

### Fields Added
- `tokens_source`: `provider_usage` | `cli_output` | `estimate` | `unknown`
- `cost_source`: `provider_usage` | `configured_rate_card` | `estimate` | `unknown`
- `cost_confidence`: `exact` | `estimated` | `unknown`
- `currency`: `USD` | `unknown`
- `rate_card_version`: Version string or null

### Rate Card Usage
1. Copy `.opencode/metrics/rate-card.example.json` to `.opencode/metrics/rate-card.local.json`
2. Update with your actual provider pricing
3. The capture script will automatically use it if present
4. **Never commit `rate-card.local.json`** (gitignored)

### Limitations
- Does not call provider billing APIs
- Does not require provider secrets
- Does not hardcode current prices as permanent truth
- Does not estimate costs from prompts/responses
- Does not log prompts or responses to count tokens
- Does not block commits if cost data is unavailable
- Does not treat estimated cost as exact

---

## Baselines & Thresholds (P3D)

### Approach
1. Collect baseline data for 2-4 weeks
2. Analyze distributions for latency, cost, token usage
3. Define thresholds based on percentiles (e.g., p95 latency)
4. **No hard blocking** until proven stable

### Initial Thresholds (After Baseline)
- Latency: p95 < X ms
- Cost: p95 < $Y per task
- Token usage: p95 < Z tokens
- Conformance: 0 FAIL, 0 WARN

---

## Privacy & Security

### What We Log
- Metadata only (timestamps, models, latency, status)
- Aggregated summaries (no individual task details)
- Sanitized error categories (no stack traces or secrets)

### What We Never Log
- Full prompts or responses
- Secrets, API keys, or tokens
- File contents or private repo data
- User/customer data
- Raw command output

### Compliance
- GDPR/CCPA compliant (no personal data logged)
- SOC 2 Type II aligned (metadata only, encrypted at rest)
- Internal audit ready (clear retention and deletion policies)

---

**Status:** Schema defined. Ready for P3B (local metrics capture).
