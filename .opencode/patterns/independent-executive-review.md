# Independent Executive Review Workflow

> **Pattern:** `.opencode/patterns/independent-executive-review.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines the independent executive review workflow that prevents "agent grades its own homework." An implementer agent produces the UI change and self-scores, then a reviewer agent independently scores using the executive rubric with evidence-backed rationale.

## When to Apply

Trigger when:
- Completing a UI pilot or polish pass
- Before shipping a new page or screen
- When executive rubric score is >= 80 but needs independent verification
- Before any production deploy claiming "premium quality"

## Workflow

### Phase 1: Implementer Self-Assessment

The implementer agent:
1. Makes the UI changes following the touch list
2. Runs all Tier 2 gates (lint, typecheck, test, keyboard, ARIA, visual, axe)
3. Produces before/after screenshots
4. Self-scores using the executive rubric (10 categories, 100 points)
5. Documents rationale for each score
6. Produces evidence pack

**Output:** `artifacts/visual-review-v<N>/implementer-review.md`

### Phase 2: Independent Review

A different agent (Reviewer role) independently:
1. Reads the implementer's review and evidence pack
2. Reviews before/after screenshots without seeing the implementer's scores
3. Scores using the same executive rubric
4. Cites specific screenshot evidence for each score
5. Identifies discrepancies with implementer's scores
6. Provides user-impact rationale for each score

**Output:** `artifacts/visual-review-v<N>/reviewer-review.md`

### Phase 3: Score Reconciliation

Compare implementer and reviewer scores:

| Discrepancy | Action |
|---|---|
| Scores within 5 points | Accept average score |
| Scores 6-10 points apart | Discuss and reconcile |
| Scores > 10 points apart | Escalate to owner for tie-break |

**Final score:** Reconciled score (average or owner-decided)

## Reviewer Score Categories

The reviewer scores the same 10 categories but with additional evidence requirements:

| Category | Evidence Required |
|---|---|
| First Impression | Screenshot of initial load state |
| Visual Hierarchy | Annotated screenshot showing primary/secondary/tertiary elements |
| Emotional Tone | Comparison to product intent statement |
| Brand Consistency | Token usage audit (no hardcoded colors) |
| Whitespace and Rhythm | Spacing scale compliance check |
| Typography Quality | Type scale audit |
| Color Discipline | Contrast ratio report + palette audit |
| Motion Restraint | Animation count + reduced-motion check |
| Mobile Polish | Mobile viewport screenshot + touch target audit |
| CTA Clarity | User flow diagram showing primary action |

## Reviewer Template

```markdown
# Independent Executive Review — [Page/Component] — [Date]

## Reviewer: [Agent Name/Role]
## Implementer: [Agent Name/Role]

## Scores
| Category | Implementer | Reviewer | Discrepancy | Reviewer Evidence |
|---|---|---|---|---|
| First Impression | /10 | /10 | +/-N | [screenshot reference] |
| Visual Hierarchy | /10 | /10 | +/-N | [screenshot reference] |
| Emotional Tone | /10 | /10 | +/-N | [product intent reference] |
| Brand Consistency | /10 | /10 | +/-N | [token audit result] |
| Whitespace and Rhythm | /10 | /10 | +/-N | [spacing audit] |
| Typography Quality | /10 | /10 | +/-N | [type scale audit] |
| Color Discipline | /10 | /10 | +/-N | [contrast report] |
| Motion Restraint | /10 | /10 | +/-N | [animation count] |
| Mobile Polish | /10 | /10 | +/-N | [mobile screenshot] |
| CTA Clarity | /10 | /10 | +/-N | [user flow reference] |
| **Total** | **/100** | **/100** | **±N** | |

## Discrepancy Analysis
[Explain any scores that differ by > 5 points]

## User Impact Assessment
[How do the visual changes affect real users?]

## Verdict
[Excellent / Good / Acceptable / Needs Work / Not Ready]

## Top 3 Fixes (if score < 90)
1.
2.
3.
```

## Escalation Rules

| Condition | Action |
|---|---|
| Reviewer score < 70 | Block ship. Major revision required. |
| Discrepancy > 10 points | Escalate to owner for tie-break |
| Reviewer identifies a11y regression | Block ship. Fix before re-review. |
| Reviewer identifies performance regression | Block ship. Optimize before re-review. |
| Implementer disagrees with reviewer | Owner decides final score |

## Related Documents

- `executive-product-review-rubric.md` — Executive review scoring rubric
- `screenshot-evidence-pack.md` — Evidence pack structure
- `daily-agent-gate-tiers.md` — Gate tier definitions
- `golden-ui-scenarios.md` — Golden scenario tests
