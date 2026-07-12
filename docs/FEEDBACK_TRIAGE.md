# Feedback Triage Policy

> **Purpose:** Defines how external review feedback is classified, prioritized, and acted on.
> **Last Updated:** 2026-07-11

---

## Classification

Feedback is classified into one of these categories:

| Category | Description |
|----------|-------------|
| Install blocker | Prevents cloning, validation, or running scripts |
| Documentation confusion | Unclear, missing, or incorrect documentation |
| Validation failure | A validation script fails unexpectedly |
| Safety concern | Gap in guardrails, threat model, or privacy scanning |
| Capability gap | Expected capability that is missing |
| Feature request | Suggestion for new capability (deferred to future versions) |
| Claim/positioning concern | Public claims feel overstated or understated |
| Non-actionable | Feedback that cannot be acted on (out of scope, opinion without evidence) |

---

## Priority Levels

| Priority | Definition | Response time |
|----------|-----------|---------------|
| P0 | External install blocker — prevents any reviewer from cloning or validating | 24 hours |
| P1 | Trust/safety issue — gap in guardrails, privacy, or security | 48 hours |
| P2 | Onboarding clarity — documentation confusion that slows reviewers | 1 week |
| P3 | Feature improvement — useful but not blocking review | Next release cycle |

---

## Triage Process

1. **Receive** — Feedback arrives as a GitHub issue with the "review-feedback" label
2. **Classify** — Assign one category from the table above
3. **Prioritize** — Assign P0, P1, P2, or P3
4. **Respond** — Acknowledge receipt and classification within the response time
5. **Act** — Fix P0/P1 issues immediately; plan P2/P3 for next release
6. **Summarize** — Update [docs/REVIEW_FEEDBACK.md](REVIEW_FEEDBACK.md) with the feedback summary

---

## Decision Rules

| Priority | Action |
|----------|--------|
| P0 | Fix immediately, create a patch release if needed |
| P1 | Fix in the next release, document the mitigation |
| P2 | Plan for next release, acknowledge to reviewer |
| P3 | Add to backlog, acknowledge to reviewer |
| Non-actionable | Close with explanation, thank the reviewer |

---

## What We Will Not Do

- Dismiss feedback without classification
- Fix P2/P3 issues before P0/P1 issues
- Add new features during the review cycle
- Change public claims without evidence
- Remove safety guardrails to reduce friction
