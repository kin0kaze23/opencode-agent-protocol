---
name: illustration-graphic-direction
description: Custom illustration / graphic direction — visual metaphor, iconography, brand motif, empty-state graphics, avoiding generic AI aesthetics
version: v4.9.2
---

# Illustration / Graphic Direction Skill

> Activate for: net-new UI with empty states, hero sections, onboarding, or brand-sensitive surfaces
> HARD RULE: Do not generate or commit image assets by default. Prefer simple SVG/icon direction.

---

## Purpose

Defines project-specific visual asset system to prevent generic AI graphics and ensure brand-consistent illustration, iconography, and graphic language throughout the product.

---

## Phase 1: Visual Metaphor Selection

What visual language fits the product?

**Method:**
1. Read product context and brand adjectives from Design Intelligence Brief
2. Extract a visual metaphor that embodies the product's emotional goal
3. Avoid clichés specific to the product category

**Examples:**
- demo-project (devotion app): *monastic, quiet, breath-like, textural, light-based* — NOT: lotus, purple gradient
- Fintech dashboard: *precise, structured, flowing data* — NOT: piggy bank, money bag
- Healthcare app: *caring, organic, warm* — NOT: red cross, stethoscope

**Questions to answer:**
- What feeling should the graphics evoke?
- What visual metaphor embodies the product's core promise?
- What would betray the brand visually?

---

## Phase 2: Iconography Style

| Decision | Options | Selection Criteria |
|---|---|---|
| Style | Outlined vs filled vs duotone vs hand-drawn | Match brand personality (outlined = modern, filled = bold, hand-drawn = warm) |
| Stroke width | 1.5px, 2px, 2.5px | Consistent across all icons; match typography weight |
| Corner radius | Sharp, rounded, organic | Match border radius tokens |
| Scale | 16px, 20px, 24px | Consistent sizing system; match touch target minimums |
| Library | Lucide, Heroicons, custom | Prefer established library; custom only if brand-defining |

---

## Phase 3: Illustration Style

| Decision | Options | Selection Criteria |
|---|---|---|
| Detail level | Minimal / abstract / detailed | Minimal for data screens, detailed for emotional moments |
| Flat vs textured | Flat / gradient / textured / photographic | Match design tokens (warm = textured, precise = flat) |
| Color palette | Monochrome / duotone / brand colors / full spectrum | Limit to 2-3 colors; use design system colors only |
| Line work | No lines / thin / bold | Match icon stroke width |
| Realism | Abstract / stylized / realistic | Abstract for concepts, stylized for objects, rarely realistic |

---

## Phase 4: Texture / Material Language

What materials/textures does the brand use?

| Material | When to Use | Example |
|---|---|---|
| Paper-like | Warm, literary, grounded brands | demo-project, journaling apps |
| Glass-like | Modern, premium, clean brands | Fintech, productivity |
| Organic/natural | Wellness, health, nature brands | Meditation, fitness, food |
| Geometric | Tech, precision, data brands | Analytics, engineering tools |
| Grainy/noisy | Editorial, artistic brands | Creative portfolios, magazines |

---

## Phase 5: Empty-State Graphics

Every empty state needs a designed graphic:

| Empty State | Graphic Guidance |
|---|---|
| No data yet | Illustration showing the action the user should take |
| No search results | Subtle, empathetic illustration (not a sad face) |
| No notifications | Calming illustration that doesn't create FOMO |
| No favorites | Icon that suggests the "save" action |
| Error/offline | Reassuring illustration with clear recovery path |

**Rules:**
- Maximum 1 illustration per empty state
- Keep it simple — the message is more important than the graphic
- Use SVG, not raster images (scalable, themeable, small file size)
- Match the visual metaphor from Phase 1

---

## Phase 6: Hero / Brand Graphics

For landing pages, welcome screens, and brand-defining moments:

| Element | Guidance |
|---|---|
| Hero illustration | 1-2 colors max; brand colors only; SVG preferred |
| Background pattern | Subtle, repeatable, themeable (CSS or SVG) |
| Brand motif | Recurring visual element that appears throughout the product |
| Loading graphic | Minimal, calm, matches motion design principles |

**Never:**
- Stock photography (generic, not brand-specific)
- AI-generated images without art direction (random, inconsistent)
- Competitor visuals (copyright, brand confusion)

---

## Phase 7: When Illustration Helps vs Clutters

| Use Illustration When | Avoid Illustration When |
|---|---|
| Explaining complex concepts | Displaying data (charts, tables) |
| Creating emotional connection | Forms, input fields, settings |
| Filling empty states meaningfully | Navigation, menus, headers |
| Anchoring brand identity | Dense dashboards, admin panels |
| Onboarding / welcome screens | Error messages (use text, not graphics) |

---

## Phase 8: SVG / Asset Rules

| Rule | Detail |
|---|---|
| Prefer SVG | For icons, illustrations, brand graphics — scalable, themeable, small |
| Limit illustrations per screen | Maximum 2-3 — more creates clutter |
| Use design token colors | Graphics must use CSS variables, not hardcoded colors |
| Dark mode support | All graphics must work in dark mode (avoid dark-on-dark) |
| File size limit | SVG icons < 5KB, illustrations < 15KB |
| No raster unless necessary | Photos require raster; everything else should be SVG |

---

## Phase 9: AI Image-Generation Prompt Structure

If AI image generation is needed (with explicit approval):

```
[Subject] in [style] style, [color palette], [mood], [composition], no text, no logos, clean background, suitable for [platform/context]
```

**Example:** "Abstract breathing circle in minimal geometric style, muted teal on warm cream, calm mood, centered composition, no text, no logos, clean background, suitable for meditation app welcome screen"

**Safety rules:**
- Do not generate images by default — require explicit approval
- Do not use copyrighted competitor visuals
- Use references as principles only
- Verify generated images match brand direction before use

---

## Evidence Format

```markdown
## Graphic Direction Review

Visual metaphor: [description + rationale]
Iconography style: [style, stroke width, corner radius, scale, library]
Illustration style: [detail level, flat/textured, color palette, line work]
Texture/material: [paper/glass/organic/geometric/grainy + rationale]
Empty-state graphics: [defined/not defined + description per state]
Brand motif: [recurring element + usage rules]
When to use illustration: [criteria defined]
When to avoid illustration: [criteria defined]
SVG/asset rules followed: PASS / FAIL
Generic AI graphics avoided: PASS / FAIL
Consistency with design tokens: PASS / FAIL
Dark mode compatibility: PASS / FAIL

Findings:
- [Critical/High/Medium/Low] [specific issue]
```

---

## Failure Conditions

Graphic direction review fails (blocks completion) if ANY of:
- Generic AI graphics detected (lotus, gradient blobs, stock photos, cliché icons)
- Graphics contradict brand direction from Design Intelligence Brief
- Illustration creates visual clutter in data-dense areas
- Graphics don't match design token colors/radius
- Competitor visuals used (copyright risk)

---

## NOT_RUN Rules

Mark as NOT_RUN with reason when:
- Data-only UI (tables, forms, dashboards) — reason: "no graphics needed"
- Following existing design system with established graphic language — reason: "extending established patterns"
- Text-only change — reason: "no visual assets involved"

---

## Integration with Other Skills

- Referenced by `ui-ux-quality-audit` for graphic direction check
- Referenced by `design-research` for brand motif and illustration style definition
- Referenced by `visual-iteration-loop` when graphics need critique and revision
- Feeds into `design-system-governance` for asset consistency checks
