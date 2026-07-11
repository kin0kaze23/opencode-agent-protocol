---
description: "Triage a bug with focused diagnosis, reproduction, and targeted fixes"
---

# /debug

**Mode:** Executor
**Model:** qwen3.7-plus (escalate to kimi-k2.6 for UI regression, visual bugs, screenshots; escalate to visual-reviewer / umans-kimi-k2.7 for UI/multimodal QA; minimax-m3 is manual-only when OpenCode Go quota is available)
**Tool access:** Layer A
**Success output:** Root cause identified + fix applied + failing tests now pass

`/debug` is the protocol's triage posture. Use it when the fastest safe path is
to shrink uncertainty before planning a broader change.

## Skill Activation (run before debugging)

| Task domain | Skill file |
|---|---|
| Root-cause analysis / hypothesis testing | `systematic-debugging/SKILL.md` |
| Error handling / resilience patterns | `error-handling/SKILL.md` |
| Production incidents / outage response | `incident-response/SKILL.md` |
| Security / auth / crypto-sensitive bugs | `security/SKILL.md` |
| UI regression / visual bugs / screenshots | Escalate to `kimi-k2.6` (senior review) or visual-reviewer `umans-kimi-k2.7` (UI/multimodal QA) |

If no domain matches: proceed without skill activation.

## Behaviour

When invoked, the Owner agent:

1. Runs preflight - if visual/UI bug, states escalation to kimi-k2.6 or visual-reviewer (umans-kimi-k2.7) in preflight
2. **Root-cause filter** — separate symptoms from causes before hypothesizing:
   - Observable symptom: what users see
   - Intermediate causes: chain of events leading to symptom
   - Potential root causes: actual bugs/decisions/conditions
   - False leads: things that look related but aren't
3. Reproduces the failure (reads error, locates failing test or log)
4. Forms 2-4 ranked falsifiable hypotheses:
   - H1: <most likely cause> — Falsify by: <test/observation>
   - H2: <second likely> — Falsify by: <test/observation>
   - H3: <third likely> — Falsify by: <test/observation> (if applicable)
   - H4: <fourth likely> — Falsify by: <test/observation> (if applicable)
5. Tests H1 first. If falsified, moves to H2.
6. Applies causal-confidence rule before fix:
   - "If <root cause> is true, then <specific test> will fail. Test result: <pass/fail>."
7. Applies minimal fix
8. If fix touches shared logic, state, auth, schema, or cross-module paths: maps failure surface
   - Related code paths: <list>
   - Tests to verify: <list>
9. Runs the specific failing test(s) to verify pass
10. Runs full quality gates to check for regressions
11. Commits with a message describing root cause and fix

## Triage budget

Bound the investigation before it becomes drift:

- Max 4 ranked hypotheses
- Max 12 shell commands before a summary
- Max 20 minutes without causal confirmation

If the budget is exhausted:
- summarize the leading evidence
- state the next best probe
- decide whether to continue in `/debug`, return to `/plan-feature`, or escalate to the user

## Escalation trigger

Escalate to kimi-k2.6 when:
- Bug is visual or layout-related and needs senior review
- Screenshot or screenshot comparison is needed
- User describes "it looks wrong" rather than "it throws an error"

Escalate to visual-reviewer (umans-kimi-k2.7) when:
- UI/multimodal QA is needed (accessibility, mobile responsive, theme consistency)
- Visual hierarchy, spacing, or design-system review is required
- Product handoff QA with visual evidence

Note: `opencode-go/minimax-m3` is a manual UI/multimodal QA specialist option only when OpenCode Go quota is available (v4.15.2).

## Output format

```
Root cause: <one sentence>
Fix: <what was changed and why>
Hypothesis tested: H1 / H2 / H3 / H4
Causal confidence: <statement>
Test result: PASS / FAIL
Regression check: PASS / FAIL
Failure surface: <list or "Not required — isolated change">
```

## Hypothesis Discipline

Before applying any fix:

1. List 2-4 falsifiable hypotheses (ranked by likelihood). Each must be testable.
2. Test H1 first. If falsified, move to H2.
3. State causal confidence before fixing: "If X is true, then Y test fails."
4. Map failure surface only when fix touches shared logic, state, auth, schema, or cross-module paths.

## Do not
- Guess without reading the error
- Fix multiple bugs in one session
- Skip regression check after fix
- Keep investigating without a bounded summary once the triage budget is exhausted
