---
name: incident-response
description: >
  Production incident lifecycle: detect, triage, mitigate, communicate, resolve,
  blameless postmortem, action items. Trigger when the user reports a production
  outage, error spike, broken deploy, "site is down", "users can't X", a paging
  alert fires, error rate jumps, latency regresses, a deploy needs rollback,
  data corruption is suspected, a security alert fires, or any phrase like
  "incident", "outage", "broken in prod", "P0", "P1", "stop ship", "rollback".
  Wraps and orchestrates existing /postmortem, /recover, /stop-ship, and
  /deploy-rollback commands into one coherent discipline. Required workflow
  for any production-impacting event in this workspace (Vercel, Cloudflare
  Workers, self-hosted Docker, iOS apps).
---

# Incident Response

> Activate for: any production-impacting event — outage, error spike, broken deploy, data issue, security alert, user-reported breakage at scale.
> HARD RULE: Mitigate first, understand later. Restoring service is more urgent than diagnosing root cause. Do not debug a fire while it is burning — put it out, then investigate the ashes.

---

## The Five Phases

```
DETECT → TRIAGE → MITIGATE → COMMUNICATE → POSTMORTEM
  (instant)   (≤5 min)    (≤15 min)    (continuous)   (≤48 hr)
```

Each phase has a clear exit criterion. Do not skip phases under time pressure — skipping is what causes 2-day incidents.

---

## Phase 1: Detect (instant)

You have an incident if **any** of these are true:
- A page/alert fired (PagerDuty, Sentry, Doppler alert, custom monitor)
- Error rate exceeded baseline by >3× in any 5-minute window
- p95 latency exceeded baseline by >2× sustained for >5 minutes
- A user reports something broken AND you can reproduce
- A deploy is in progress and CI/health checks are failing
- You smell smoke ("something feels wrong") — trust this; investigate

If you are unsure whether it is an incident, **declare it an incident**. False alarms cost minutes; missed incidents cost reputation.

---

## Phase 2: Triage (≤5 minutes)

### Step 2.1: Assign severity

| Sev | Definition | Examples | Response |
|---|---|---|---|
| **SEV-1** | Total outage or data loss / corruption affecting all users | Site down, DB unreachable, auth broken, secrets leaked | Drop everything. Get help. Wake people up. |
| **SEV-2** | Major feature broken for many users, or degraded performance affecting all | Core flow broken (checkout, login), error rate >10%, latency >5× | Drop current work. Single-thread on this. |
| **SEV-3** | Minor feature broken, or major feature broken for small user segment | Edge case, one integration failing, mild error rate elevation | Acknowledge, fix in current sprint, no after-hours work |
| **SEV-4** | Cosmetic, low-impact, or proactive cleanup | Typo, slow query that's still acceptable | Ticket, normal queue |

When in doubt, escalate one level. It is easier to de-escalate later than to apologize for under-reacting.

### Step 2.2: Capture the basics in 60 seconds

Open an incident notes file: `<repo>/docs/incidents/<YYYY-MM-DD>-<short-name>.md`

```markdown
# Incident: <short name>
- Detected: <UTC timestamp> by <person/alert>
- Severity: SEV-N
- Affected: <which users / what % / what feature>
- Symptoms: <one sentence>
- Suspected cause: <best guess so far, with confidence level>
- Status: INVESTIGATING

## Timeline (UTC)
- HH:MM — alert fired
- HH:MM — declared incident
```

Append to the timeline as the incident progresses. This is the postmortem source — write it as it happens, not from memory after.

### Step 2.3: Form a hypothesis (NOT a diagnosis)

In ≤2 minutes of investigation, what is the most likely cause? Common patterns, in rough probability order:

1. **Recent deploy** — `git log --oneline -10`, check if symptoms started after a specific commit. **THIS IS THE #1 CAUSE.**
2. **Config / environment change** — Doppler change, env var update, infra scaling event
3. **Upstream dependency** — Vercel status, Cloudflare status, Supabase, OpenAI/Anthropic API
4. **Data shape change** — new user input pattern, schema migration, large import job
5. **Capacity** — traffic spike, exhausted DB connections, rate limit hit
6. **Time-based** — cron job, midnight UTC quirk, certificate expiry

Pick one to act on. You can be wrong — that's fine — you'll cycle back if mitigation doesn't work.

---

## Phase 3: Mitigate (≤15 minutes)

**Goal: restore service, even if the underlying cause is not yet understood.**

### Decision tree

```
Was this caused by a recent deploy?
├── YES → ROLLBACK (use /deploy-rollback skill or platform-native rollback)
│         Vercel: vercel rollback
│         Cloudflare Workers: wrangler rollback
│         Docker: docker compose pull <prev-tag> && restart
│         iOS: pull from App Store Connect (cannot truly rollback)
└── NO  → Is there a feature flag for the broken capability?
         ├── YES → Disable the flag (instant mitigation)
         └── NO  → Is the broken thing recoverable by restart?
                  ├── YES → Restart the service (Vercel: redeploy; Workers: re-publish; Docker: restart)
                  └── NO  → Escalate, get help, isolate the broken capability
```

### Mitigation rules

- **Mitigation does NOT require root cause.** A rollback that restores service buys you time to investigate calmly. Take it.
- **Do not deploy fixes during the incident** unless the fix is a one-line revert. Forward-fixes during incidents cause secondary outages.
- **Communicate before you act on irreversible operations** (e.g., dropping data, force-pushing to fix infra). Announce intent in #incidents (or wherever your team is) before the action.
- **If three mitigation attempts fail, escalate.** You are too close to it.

### Workspace-specific shortcuts

- For Vercel projects (example-app, demo-project web): `vercel ls` → `vercel rollback <deployment-id>`
- For Cloudflare Workers: `wrangler deployments list` → `wrangler rollback <deployment-id>`
- For Docker (example-agent, sample-service, example-platform): check `docker compose ps`, roll back image tag, `docker compose up -d`
- Run `/deploy-rollback` command if available; run `/stop-ship` to block further deploys while incident is open

---

## Phase 4: Communicate (continuous)

Two audiences:

### Internal (team, stakeholders)

Updates every **15 min for SEV-1**, **30 min for SEV-2**, **at major status changes for SEV-3+**.

Format:
```
[SEV-N | INCIDENT-<slug> | <HH:MM UTC>]
Status: INVESTIGATING | MITIGATING | MONITORING | RESOLVED
Impact: <who/what is affected, % of users>
Action: <what you are doing right now>
Next update: <HH:MM>
```

Even "no new info, still investigating" is a valuable update. Silence is the worst signal.

### External (users)

For SEV-1/SEV-2 affecting customers:
- Post a status page update (or in-app banner if you have one) within 15 minutes
- Acknowledge: "We are aware of [symptom] and investigating."
- Do not estimate ETAs you can't keep — say "next update in 30 min" instead
- After resolution: "Service restored at HH:MM. Postmortem to follow."

---

## Phase 5: Resolve & Postmortem (≤48 hours after resolution)

### Step 5.1: Confirm resolution

- Service metrics back to baseline for ≥30 minutes
- No new related alerts
- Spot-check the previously-broken flow as a real user
- Mark incident as RESOLVED in the timeline with UTC timestamp

### Step 5.2: Write the postmortem (within 48 hours)

Use the `/postmortem` command if available — it scaffolds the doc. Otherwise create `<repo>/docs/postmortems/<YYYY-MM-DD>-<slug>.md`:

```markdown
# Postmortem: <Incident Name>
**Date:** YYYY-MM-DD | **Severity:** SEV-N | **Duration:** <minutes> | **Author:** <you>

## Summary (3 sentences max)
What happened, who was affected, how it was resolved.

## Impact
- Users affected: <number / percent>
- Duration of impact: <start UTC> to <end UTC>
- Revenue / SLA implications: <if relevant>

## Root Cause
<Technical explanation. Be specific. Include code snippets / config diffs / queries.>

## Timeline (UTC)
- HH:MM — <event>  (lift verbatim from incident notes)

## What Went Well
- <Specific things — fast detection, clean rollback, good comms>

## What Went Wrong
- <Specific things — alert delay, missing runbook, deploy without canary>
(Blameless: describe systems and decisions, not people. "We deployed without staging validation" not "Alice deployed without staging validation.")

## Action Items
| # | Action | Owner | Due | Severity |
|---|---|---|---|---|
| 1 | <Specific, tracked> | @owner | YYYY-MM-DD | P0/P1/P2 |

Each action item must be: specific (not "improve monitoring"), assigned (a name), and dated. Vague action items never happen.

## Detection Improvement
What signal could have caught this earlier? Add the alert as an action item.

## Prevention
What change makes this category of incident impossible / harder?
```

### Step 5.3: File and track action items

- Each action item becomes a ticket / GitHub issue with a P-label
- P0 actions block work until done
- P1 actions land within 2 weeks
- P2 actions tracked but not blocking
- Schedule a 30-day check-in to verify completion — half the value of postmortems is lost when actions don't ship

### Step 5.4: Promote lessons

If this incident reveals a workspace-wide gap (a recurring root cause, a missing skill, a runbook needed), use `/promote-lesson` to surface it as a workspace-level rule or skill update. Pattern repetition across postmortems is a signal you're under-investing in prevention.

---

## Anti-Patterns to Catch

| Anti-pattern | Why it's wrong | Fix |
|---|---|---|
| Skipping triage to "just look at it" | You burn time without understanding scope | 60-second triage even for "obvious" incidents |
| Forward-fixing instead of rolling back | Your fix can compound the outage | Rollback first, fix forward in calm |
| No timeline kept during incident | Postmortem becomes guesswork | Append to timeline as you act |
| Postmortem blames a person | Destroys trust, hides systemic causes | Blameless framing — describe systems |
| Action items are vague ("improve testing") | Never get done | Specific, assigned, dated |
| No follow-up on action items | Same incident recurs | 30-day check-in scheduled when postmortem published |
| "We won't do a postmortem, it was small" | Small-recurring is what eats teams | Postmortem ALL SEV-1 and SEV-2; SEV-3 if it recurs |
| Communication only after resolution | Users panic; team loses trust | Update every 15-30 min during the incident |
| Investigating in production console with no log | Can't reproduce findings later | Screen-record or copy/paste into incident notes |

---

## Pre-Incident Preparation (Do This Before You Need It)

- Each repo has a `<repo>/docs/RUNBOOK.md` with: how to deploy, how to rollback, where logs live, who to page
- Health check endpoint exists and is monitored (`/health` returning 200 + dependency checks)
- Rollback procedure has been tested in the last 90 days (untested rollbacks fail when you need them)
- Critical deploys go through a canary or staging gate
- Feature flags exist for risky new capabilities so you can mitigate without a deploy
- On-call expectations are documented (even if "on-call = whoever is awake")

See `references/runbook-template.md` for a starter runbook.
