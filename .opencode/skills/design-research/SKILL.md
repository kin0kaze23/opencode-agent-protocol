---
name: design-research
description: Design research methodology — product context, emotional analysis, competitor audit, mood board to token translation, aesthetic decision framework
version: v4.9.1
---

# Design Research Skill

> Activate for: net-new UI, major redesign, brand-sensitive surfaces, or when design direction is unclear
> HARD RULE: Every aesthetic choice must have a rationale — never use default or generic values.

---

## Purpose

Forces project-specific aesthetic decisions before design or implementation. Prevents generic defaults (random purple gradients, Inter everywhere, boilerplate card layouts) by requiring research, analysis, and documented rationale for every major visual choice.

---

## Phase 1: Product Context Analysis

Answer these before any design work:

1. **What is the product?** (one sentence: what it does, who it's for)
2. **What is the user's emotional state when they encounter this surface?** (rushed, anxious, bored, curious, stressed, calm?)
3. **What should the user feel after using it?** (confident, relieved, informed, inspired, grounded?)
4. **What is the product's core promise?** (speed, reliability, warmth, authority, simplicity, depth?)
5. **What would betray that promise visually?** (corporate coldness, playful frivolity, visual chaos, minimalism that feels empty?)

---

## Phase 2: Brand Adjective Extraction

Extract 3-5 adjectives that define the visual direction:

**Method:**
1. Read product docs (PRD, VISION.md, brand guidelines if available)
2. List adjectives users would use to describe the ideal experience
3. Eliminate contradictory adjectives (e.g., "playful" + "authoritative")
4. Keep 3-5 that are specific and mutually reinforcing

**Examples:**
- Meditation app: *calm, grounded, warm, unhurried*
- Fintech dashboard: *precise, trustworthy, efficient, modern*
- Creative portfolio: *bold, expressive, crafted, distinctive*
- Healthcare app: *caring, clear, reassuring, professional*

**Not adjectives:** "beautiful," "good," "modern" (too vague)

---

## Phase 3: Competitor / Adjacent-Product Audit

Analyze 3-5 products in the same category or adjacent space:

For each competitor:
| Aspect | What They Do Well | What Feels Generic | What to Avoid |
|---|---|---|---|
| Color palette | [specific observation] | [cliché or overused pattern] | [why it doesn't fit] |
| Typography | [specific observation] | [cliché or overused pattern] | [why it doesn't fit] |
| Layout | [specific observation] | [cliché or overused pattern] | [why it doesn't fit] |
| Motion | [specific observation] | [cliché or overused pattern] | [why it doesn't fit] |
| Copy/tone | [specific observation] | [cliché or overused pattern] | [why it doesn't fit] |

**Adjacent products** = not direct competitors but products with similar emotional goals (e.g., a meditation app might look to Calm, Headspace, but also to journaling apps, yoga studios, or nature photography sites).

---

## Phase 4: Anti-Pattern Audit

List patterns that are common in the category but should be avoided:

| Anti-Pattern | Why It's Overused | Why It Doesn't Fit This Product |
|---|---|---|
| Purple gradient on white | AI/tech cliché | Undermines warmth/trust |
| Inter/Roboto as display font | Default, no personality | Doesn't express brand character |
| Generic card grid with shadows | SaaS boilerplate | Feels corporate, not human |
| Hero section with stock photo | Placeholder thinking | Not specific to product |
| Animated particles in background | "Modern" cliché | Distracts from content |

---

## Phase 5: Mood Board → Token Translation

If mood board or inspiration references exist, translate them into design tokens:

| Inspiration Element | Translates To | Token |
|---|---|---|
| Warm, sunlit feeling | Color | `--color-bg: #FDFDFB` (warm cream) |
| Elegant book typography | Typography | `--font-display: Instrument Serif` |
| Soft shadows, layered paper | Shadow | `--shadow-md: 0 4px 12px rgba(0,0,0,0.06)` |
| Rounded, organic shapes | Border radius | `--radius-md: 20px` |
| Gentle breathing rhythm | Motion | `animation: breathe 5s ease-in-out infinite` |

**If no mood board exists:** extract mood from Phase 1 (product context) and Phase 2 (brand adjectives).

### Phase 5b: Mood Board → Graphic Language Translation

If mood board or inspiration references exist, translate them into graphic direction:

| Inspiration Element | Translates To | Graphic Decision |
|---|---|---|
| Warm, organic feeling | Illustration style | Textured, hand-drawn, earth tones |
| Clean, precise data | Iconography | Outlined, 2px stroke, geometric |
| Calm, meditative mood | Brand motif | Breathing circle, subtle gradients |
| Bold, energetic brand | Hero graphics | Large shapes, high contrast |

**Also define:**
- **Brand motif**: What recurring visual element anchors the brand? (pattern, shape, texture)
- **Competitor illustration/iconography audit**: What do competitors use? What feels generic? What should we avoid?
- **Platform-aware aesthetic notes**: How should graphics adapt for iOS vs Android vs web?

---

## Phase 6: Selected Design Direction

Synthesize research into a clear direction:

```markdown
## Selected Design Direction: [Name]

**Mood:** [1-3 adjectives]
**Color direction:** [primary palette + rationale]
**Typography direction:** [display + body + rationale]
**Spacing density:** [generous / balanced / compact + rationale]
**Border radius:** [sharp / rounded / organic + rationale]
**Elevation/shadow:** [flat / subtle / layered + rationale]
**Icon style:** [outlined / filled / illustrated + rationale]
**Illustration style:** [minimal / detailed / flat / textured + rationale]
**Brand motif:** [recurring element + usage rules]
**Motion personality:** [none / subtle / expressive + rationale]
```

---

## Phase 7: Rejected Design Directions

Document what was considered and why rejected:

```markdown
## Rejected Direction: [Name]

**What it looked like:** [brief description]
**Why rejected:** [specific reason — doesn't match emotional goal, too generic, conflicts with brand]
```

---

## Phase 8: Rationale for Every Major Aesthetic Choice

For each design token or pattern decision:

| Decision | Choice | Rationale | Source/Reference |
|---|---|---|---|
| Display font | Instrument Serif | Warm, literary, spiritual without ornate | Product adjective: "grounded" |
| Primary accent | Monastery Indigo (#4A5D7C) | Calm, deep, non-cliché | Rejected purple gradient |
| Border radius | 20px | Soft, organic, not corporate | Mood: "warm cream" |
| Motion | Subtle fade-in | Supports calm, not distracting | Brand adjective: "unhurried" |

---

## Final Output: Design Intelligence Brief

The research produces a Design Intelligence Brief with these sections:

1. Product context and user emotional state
2. Brand adjectives (3-5)
3. Competitor/adjacent-product audit findings
4. Anti-pattern audit
5. Mood board → token translation
6. Selected design direction with rationale
7. Rejected directions with rationale
8. Specific token recommendations (color, typography, spacing, radius, shadow, icon, motion)
9. Success criteria for visual quality

---

## Integration with Other Skills

- Output feeds into `ui-ux-quality-audit` as the design direction baseline
- Referenced by `plan-feature.md` when Design Intelligence Brief is created
- Called by `design-system-governance` to validate token choices against research rationale
- Referenced by `motion-design` for motion personality direction

---

## NOT_RUN Rules

Mark as NOT_RUN with reason when:
- Tiny change (bug fix, copy edit) — reason: "minor change, design research not needed"
- Following existing design system exactly — reason: "extending established patterns, research not needed"
- Non-visual change — reason: "no UI surface involved"

---

## When NOT to Use

- Bug fixes or minor polish
- Following established design system patterns
- Internal/admin surfaces with no brand impact
- Technical refactors with no visual change
