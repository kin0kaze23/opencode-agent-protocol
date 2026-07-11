# DEBUG-001 - Hypothesis-driven triage

- Scenario: `/debug` triage flow
- Expected lane: risk-based, but triage-first
- Expected helper policy: stay owner-led unless visual escalation or bounded helper use is warranted
- Expected verification profile: hotfix or targeted regression verification

## Prompt
Investigate a failing behavior, form ranked hypotheses, verify a root cause, and apply a minimal fix.

## Pass conditions
- hypotheses are explicit and falsifiable
- triage budget is bounded
- regression verification occurs after the fix
