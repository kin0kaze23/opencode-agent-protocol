# Executive Product Review Rubric

> **Pattern:** `.opencode/patterns/executive-product-review-rubric.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines the executive product review rubric for evaluating UI quality at a CPO/CMO level. This rubric forces agents to evaluate their output against professional product design standards, not just technical correctness.

## When to Apply

Trigger when:
- A UI pilot or polish pass is completed
- Before shipping a new page or screen
- Before any production deploy of a user-facing surface
- When a stakeholder requests executive-level review

## Rubric Categories

Score each category 0-10. Total score out of 100.

### 1. First Impression (10 points)

| Score | Criteria |
|---|---|
| 9-10 | Immediately communicates purpose, feels premium and intentional |
| 7-8 | Clear purpose, minor visual noise or inconsistency |
| 5-6 | Purpose unclear at first glance, needs explanation |
| 0-4 | Confusing, cluttered, or unprofessional |

### 2. Visual Hierarchy (10 points)

| Score | Criteria |
|---|---|
| 9-10 | Clear primary/secondary/tertiary distinction, eye flows naturally |
| 7-8 | Good hierarchy, one or two elements compete for attention |
| 5-6 | Hierarchy exists but is inconsistent or unclear |
| 0-4 | No hierarchy, everything looks equally important |

### 3. Emotional Tone (10 points)

| Score | Criteria |
|---|---|
| 9-10 | Emotion matches product intent perfectly (calm, urgent, playful, etc.) |
| 7-8 | Tone is mostly right, minor mismatches in color or copy |
| 5-6 | Tone is neutral or inconsistent with product intent |
| 0-4 | Wrong emotional tone entirely |

### 4. Brand Consistency (10 points)

| Score | Criteria |
|---|---|
| 9-10 | All tokens, colors, typography, and spacing follow design system |
| 7-8 | Mostly consistent, 1-2 deviations with justification |
| 5-6 | Some inconsistency, design system not fully applied |
| 0-4 | No brand consistency, ad-hoc styling |

### 5. Whitespace and Rhythm (10 points)

| Score | Criteria |
|---|---|
| 9-10 | Generous, intentional whitespace, consistent spacing scale |
| 7-8 | Good spacing, minor crowding or inconsistency |
| 5-6 | Spacing is functional but not intentional |
| 0-4 | Cramped, inconsistent, or chaotic spacing |

### 6. Typography Quality (10 points)

| Score | Criteria |
|---|---|
| 9-10 | Clear type scale, readable at all sizes, proper line height |
| 7-8 | Good typography, minor scale or weight issues |
| 5-6 | Readable but type scale is inconsistent |
| 0-4 | Poor typography choices, hard to read |

### 7. Color Discipline (10 points)

| Score | Criteria |
|---|---|
| 9-10 | Limited palette, semantic color use, all contrast >= 4.5:1 |
| 7-8 | Good color use, 1-2 contrast or palette issues |
| 5-6 | Colors work but palette is too broad or inconsistent |
| 0-4 | Color chaos, poor contrast, inaccessible |

### 8. Motion Restraint (10 points)

| Score | Criteria |
|---|---|
| 9-10 | Motion is purposeful, subtle, respects reduced-motion preference |
| 7-8 | Good motion, slightly overused or missing reduced-motion |
| 5-6 | Motion exists but is distracting or inconsistent |
| 0-4 | No motion or excessive/chaotic animation |

### 9. Mobile Polish (10 points)

| Score | Criteria |
|---|---|
| 9-10 | Perfect on mobile, safe areas, touch targets, thumb zones |
| 7-8 | Good mobile experience, minor touch target or spacing issues |
| 5-6 | Functional on mobile but not optimized |
| 0-4 | Broken or unusable on mobile |

### 10. CTA Clarity (10 points)

| Score | Criteria |
|---|---|
| 9-10 | Primary action is obvious, secondary actions are clear, no ambiguity |
| 7-8 | Good CTA hierarchy, one action could be clearer |
| 5-6 | CTAs exist but hierarchy is unclear |
| 0-4 | No clear call to action, confusing navigation |

## Scoring Thresholds

| Score | Verdict | Action |
|---|---|---|
| 90-100 | **Excellent** | Ship immediately |
| 80-89 | **Good** | Ship with minor fixes |
| 70-79 | **Acceptable** | Fix before shipping |
| 60-69 | **Needs Work** | Significant revision required |
| 0-59 | **Not Ready** | Major redesign needed |

## Review Template

```markdown
# Executive Product Review — [Page/Component] — [Date]

## Scores
| Category | Score | Notes |
|---|---|---|
| First Impression | /10 | |
| Visual Hierarchy | /10 | |
| Emotional Tone | /10 | |
| Brand Consistency | /10 | |
| Whitespace and Rhythm | /10 | |
| Typography Quality | /10 | |
| Color Discipline | /10 | |
| Motion Restraint | /10 | |
| Mobile Polish | /10 | |
| CTA Clarity | /10 | |
| **Total** | **/100** | |

## Verdict
[Excellent / Good / Acceptable / Needs Work / Not Ready]

## Top 3 Fixes
1.
2.
3.

## Evidence
- Before/after screenshots: `artifacts/visual-review-v<N>/`
- Axe report: 0 violations
- Keyboard smoke: PASS
- Performance: Lighthouse >= 85
```

## Related Patterns

- `visual-quality-gate.md` — Visual quality gate definition
- `screenshot-evidence-pack.md` — Evidence pack structure
- `product-experience-review/SKILL.md` — Product experience review skill
