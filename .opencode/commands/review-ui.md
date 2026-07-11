---
description: "Independent executive UI review with executive rubric scoring"
---

# /review-ui

**Mode:** Reviewer
**Model:** glm-5
**Tool access:** Layer A + browser
**Success output:** Independent executive review score with evidence-backed rationale

## Behaviour

When invoked, the Owner agent:
1. Reads `<repo>/AGENTS.md` and `<repo>/NOW.md` for context
2. Determines the target repo and page/component to review
3. Reads the implementer's review (if exists) from `artifacts/visual-review-v<N>/implementer-review.md`
4. Independently scores using the executive rubric (10 categories, 100 points):
   - First Impression
   - Visual Hierarchy
   - Emotional Tone
   - Brand Consistency
   - Whitespace and Rhythm
   - Typography Quality
   - Color Discipline
   - Motion Restraint
   - Mobile Polish
   - CTA Clarity
5. Cites specific screenshot evidence for each score
6. Identifies discrepancies with implementer's scores (if any)
7. Provides user-impact rationale for each score
8. Produces reviewer review document at `artifacts/visual-review-v<N>/reviewer-review.md`

## When to use /review-ui

- After completing a UI pilot or polish pass
- Before shipping a new page or screen
- When executive rubric score is >= 80 but needs independent verification
- Before any production deploy claiming "premium quality"
- When implementer has self-scored and needs independent review

## When NOT to use /review-ui

- For routine non-UI changes → use `/gate-fast`
- For accessibility-only verification → use `/gate-ui`
- When no visual changes were made → skip review

## Output format

```
## Independent Executive Review
Repo:         <repo>
Page:         <page/component>
Reviewer:     glm-5 (Reviewer role)
Implementer:  <implementer agent>

| Category | Implementer | Reviewer | Discrepancy | Evidence |
|---|---|---|---|---|
| First Impression | /10 | /10 | +/-N | <screenshot ref> |
| Visual Hierarchy | /10 | /10 | +/-N | <screenshot ref> |
| Emotional Tone | /10 | /10 | +/-N | <product intent ref> |
| Brand Consistency | /10 | /10 | +/-N | <token audit> |
| Whitespace/Rhythm | /10 | /10 | +/-N | <spacing audit> |
| Typography | /10 | /10 | +/-N | <type scale audit> |
| Color Discipline | /10 | /10 | +/-N | <contrast report> |
| Motion Restraint | /10 | /10 | +/-N | <animation count> |
| Mobile Polish | /10 | /10 | +/-N | <mobile screenshot> |
| CTA Clarity | /10 | /10 | +/-N | <user flow ref> |
| **Total** | **/100** | **/100** | **±N** | |

Discrepancy analysis: <explain scores differing by > 5 points>
User impact: <how changes affect real users>
Verdict: Excellent / Good / Acceptable / Needs Work / Not Ready
Top 3 fixes: <if score < 90>
```

## Do not
- Simply accept the implementer's self-score
- Score without citing specific evidence
- Skip any rubric category
- Claim "Excellent" without before/after evidence
- Review without running accessibility gates first
