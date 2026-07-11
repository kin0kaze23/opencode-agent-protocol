# Runbook Template — `<repo-name>`

Copy this into `<repo>/docs/RUNBOOK.md` and fill it in. A runbook that doesn't exist is the #1 cause of long incidents.

---

## At-a-Glance

- **Service name:** <repo-name>
- **What it does:** <one sentence>
- **Stack:** <e.g., Next.js 14 + Postgres + Clerk>
- **Deploy target:** <Vercel / Cloudflare Workers / Docker host / App Store>
- **Repo:** <github URL>
- **Owner / on-call:** <person or rotation>
- **Status page:** <URL or "none">

---

## Health & Observability

- **Health check URL:** `https://<host>/health` — should return 200 with `{"status":"ok","db":"ok","dependencies":{...}}`
- **Logs:** <where? Vercel dashboard / Cloudflare dashboard / `docker logs` / Datadog / Sentry>
- **Error tracking:** <Sentry project URL or "none">
- **Metrics dashboard:** <URL or "none">
- **Alerts route to:** <PagerDuty / Slack channel / email>

---

## Deploy

```bash
# Standard deploy procedure
<exact command>

# Canary / preview deploy (if available)
<exact command>
```

---

## Rollback (TEST THIS QUARTERLY — UNTESTED ROLLBACKS DO NOT WORK)

```bash
# Most recent successful rollback procedure:
<exact command sequence>

# Last tested: YYYY-MM-DD by <person>
```

If rollback fails:
- Fallback 1: <e.g., redeploy previous git tag manually>
- Fallback 2: <e.g., disable feature flag X>
- Last resort: <e.g., put up maintenance page>

---

## Common Incidents & Mitigations

### Symptom: <e.g., 502 errors after deploy>
- Likely cause: <e.g., new env var missing in production>
- Mitigation: <exact steps>
- Where to look: <log query, dashboard panel>

### Symptom: <e.g., login broken>
- Likely cause: <e.g., Clerk API key rotated, JWT secret mismatch>
- Mitigation: <exact steps>
- Where to look: <log query>

### Symptom: <e.g., DB connection exhaustion>
- Likely cause: <e.g., long-running query, missed connection close>
- Mitigation: <`SELECT pg_terminate_backend(pid) ...` command>
- Where to look: <Supabase dashboard / pgAdmin>

(Add new entries after every incident — that's how a runbook grows useful.)

---

## Dependencies (Things That Can Break Us)

| Dependency | Status page | What breaks if it's down |
|---|---|---|
| Vercel | https://www.vercel-status.com | Whole site |
| Supabase | https://status.supabase.com | DB, auth |
| Clerk | https://status.clerk.com | Login |
| OpenAI/Anthropic | https://status.openai.com / https://status.anthropic.com | AI features |
| Cloudflare | https://www.cloudflarestatus.com | DNS, edge |

---

## Escalation

- **Tier 1:** <on-call person>
- **Tier 2 (if T1 unreachable for 15 min):** <backup person>
- **Subject matter experts by area:**
  - Auth: <person>
  - Payments: <person>
  - Infra: <person>

---

## Recent Postmortems

- YYYY-MM-DD — <link to postmortem> — <one-sentence lesson>
- YYYY-MM-DD — <link to postmortem> — <one-sentence lesson>

---

## Last Reviewed

- YYYY-MM-DD by <person>
- Quarterly review owner: <person>
