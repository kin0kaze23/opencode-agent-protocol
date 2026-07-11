---
name: ui-ux-quality-audit
description: Senior UI/UX quality audit — visual hierarchy, layout, typography, color, states, accessibility, motion, microcopy, brand fit, delight, and production readiness
version: v4.9.0
---

# UI/UX Quality Audit Skill

> Activate before: `/review` on UI surfaces, `/ship` with UI changes, any "is the UI good enough?" question
> HARD RULE: "It looks fine" is not an audit. Show evidence.

---

## Purpose

This is the main "senior UI/UX reviewer" skill. It evaluates implemented UI against quality benchmarks for visual design, usability, accessibility, responsiveness, state coverage, and brand consistency. It does NOT generate designs — it audits them.

---

## Triggers

Auto-activate when:
- `/review` scope includes UI files (`**/*.tsx`, `**/*.css`, `**/*.html`, `**/components/**`, `**/pages/**`, `**/views/**`, `**/screens/**`, `**/app/**`)
- `/ship` scope includes UI surfaces
- User asks "is the UI good enough?", "review the design", "audit the visual quality"

Do NOT activate for:
- Backend-only changes
- Text-only / copy changes (use content microcopy section only)
- Infrastructure changes with no UI impact

---

## When Not to Use

- Trivial changes (≤2 files, no visible UI change) — skip to `/review`
- Early design ideation — use `frontend-design` or `ui-ux-pro-max` instead
- Backend API review — not relevant

---

## Compact Mode

For FAST lane tasks or minor UI tweaks, run only the **Critical Checks** section (items marked 🔴). Skip detailed audit sections.

---

## Required Inputs

Before starting the audit, gather:
- The UI files changed (from git diff or touch list)
- Browser screenshot(s) — at minimum desktop (1440px)
- Dev URL where the UI is running
- Design Intelligence Brief (if one exists for this feature)
- Existing design system documentation (if available)

---

## Audit Procedure

### Step 1: Visual Hierarchy 🔴
- Does the eye flow naturally from most important to least important content?
- Is the primary action/CTA visually dominant?
- Are secondary actions visually subordinate?
- Is information priority clear at a glance?
- Do affordances (buttons, links, inputs) look interactive?

**Severity scale:**
- Critical: No visual hierarchy — everything competes for attention
- High: Primary action is not visually prominent
- Medium: Secondary elements compete with primary
- Low: Minor hierarchy improvements possible

### Step 2: Layout / Grid / Alignment 🔴
- Is content aligned to a consistent grid or spacing system?
- Are margins and padding consistent and intentional?
- Is there a clear visual rhythm (consistent spacing multiples)?
- Do elements align properly (left edges, baselines, centers)?
- Is density appropriate (not too cramped, not too sparse)?

**Severity scale:**
- Critical: Elements misaligned, layout broken, overlapping content
- High: Inconsistent spacing rhythm, no alignment system
- Medium: Minor alignment issues visible
- Low: Pixel-level alignment could be tighter

### Step 3: Spacing Rhythm
- Are spacing values consistent (e.g., multiples of 4 or 8)?
- Is whitespace intentional or accidental?
- Does spacing create visual breathing room between sections?
- Are margins between related vs. unrelated elements differentiated?

### Step 4: Typography Scale 🔴
- Do headings follow a consistent type scale?
- Is there clear typographic hierarchy (H1 > H2 > H3 > body > caption)?
- Is body text readable (minimum 14px, appropriate line-height)?
- Are font weights used consistently (not too many weights)?
- Is the font pairing intentional and distinctive (not system fonts)?

**Severity scale:**
- Critical: Unreadable text, broken typography, wrong font loaded
- High: No typographic hierarchy, system fonts used for display
- Medium: Inconsistent heading sizes, too many font weights
- Low: Minor scale adjustments needed

### Step 5: Color and Semantic Usage 🔴
- Are colors coming from design tokens vs. hardcoded hex values?
- Is the primary color used consistently for primary actions?
- Are semantic colors used correctly (error = red, warning = amber, success = green, info = blue)?
- Do dark and light modes both have sufficient contrast?
- Is the color palette restrained (not too many colors)?

**Severity scale:**
- Critical: Semantic colors inverted (error shown as green), unreadable contrast
- High: Hardcoded colors everywhere, no token usage
- Medium: Color inconsistencies between components
- Low: Minor color refinement needed

### Step 6: Component Consistency
- Do similar UI elements look and behave the same way?
- Are button styles consistent (border radius, padding, hover states)?
- Are form inputs styled consistently?
- Do cards, lists, and tables follow a consistent pattern?
- Are icons from a consistent set (not mixed icon libraries)?

### Step 7: UX States 🔴
For every interactive component/flow:
- [ ] Loading state — is it designed (not just a spinner)?
- [ ] Empty state — is it helpful (not just "No data")?
- [ ] Error state — is it actionable (not just "Error occurred")?
- [ ] Success state — is it clear what happened?
- [ ] Disabled state — is it visually clear and accessible?
- [ ] Skeleton/shimmer patterns where appropriate?

**Severity scale:**
- Critical: No error state — user sees raw error or blank screen
- High: Missing loading state — user doesn't know something is happening
- Medium: Empty state is unhelpful or generic
- Low: States present but could be more polished

### Step 8: Responsiveness
- Does the layout adapt gracefully at different breakpoints?
- Is there no horizontal scroll at mobile width (375px)?
- Do touch targets remain 44×44px minimum on mobile?
- Does navigation adapt appropriately?
- Is typography readable at all breakpoints?

### Step 9: Accessibility Summary
Delegate to `accessibility-audit` skill for full audit. Quick checks:
- Keyboard navigation works?
- Focus visible?
- Contrast sufficient?
- Labels present?

If `accessibility-audit` is available, run it and reference its findings here.

### Step 10: Motion / Reduced Motion
- Do animations have a purpose (not decorative noise)?
- Are entrance animations subtle and well-timed (150-300ms)?
- Is `prefers-reduced-motion` respected?
- No flashing or strobing content?
- Hover transitions smooth (not instant, not sluggish)?

### Step 11: Microcopy
- Error messages are actionable and human-readable?
- Empty states have helpful copy?
- Button labels are action-oriented ("Save Changes" not "Submit")?
- No jargon or technical terms in user-facing copy?
- Tone matches brand direction?

### Step 12: Design-System-Governance Sub-Check
Delegate to `design-system-governance` skill. Quick checks:
- Token usage (colors, spacing, typography)
- Component consistency with existing patterns
- Spacing scale compliance
- Typography scale compliance
- Semantic color usage
- No hardcoded design values

If `design-system-governance` is available, run it and reference its findings here.

### Step 13: Brand Fit
- Does the UI match the design direction (from Design Intelligence Brief if available)?
- Is the tone consistent with the product brand?
- Does it feel like it belongs to this product?

### Step 14: Anti-Generic Quality
- Does it feel distinctive or like generic AI-generated UI?
- Are there intentional design decisions visible?
- Is there at least one memorable visual element?
- Does it avoid the common AI UI tropes:
  - Purple gradients on white
  - Blue gradient on dark
  - #3B82F6 as primary accent
  - Inter / Roboto as display font
  - Generic card shadows
  - Boilerplate hero layouts

### Step 15: Tasteful Delight
- Are there moments of polish that surprise and delight?
- Subtle animations that feel alive?
- Thoughtful micro-interactions?
- Attention to detail in small things (hover states, transitions, empty states)?

**Not gimmicks:** Avoid gratuitous animations, unnecessary visual noise, or features that distract from the primary task.

### Step 16: Production Readiness 🔴
- No broken layouts
- No horizontal scroll at any breakpoint
- No overflow or clipped content (unless intentional)
- No console errors on the page
- No broken images or missing assets
- All interactive elements are functional

---

## Severity Levels

| Level | Meaning | Action |
|---|---|---|
| Critical | Blocks user task, broken layout, accessibility failure | Must fix before ship |
| High | Visible quality issue, confusing UX, missing states | Should fix before ship |
| Medium | Polish issue, minor inconsistency | Fix if time permits |
| Low | Nice-to-have improvement | Document for later |
| Info | Observation, no action needed | Note only |

---

## Evidence Format

```markdown
## UI/UX Quality Audit — [Feature/Screen]

Overall verdict: Approve / Approve with fixes / Requires changes

Visual hierarchy: [Critical/High/Medium/Low] — [one sentence]
Layout/alignment: [Critical/High/Medium/Low] — [one sentence]
Spacing rhythm: [Critical/High/Medium/Low] — [one sentence]
Typography: [Critical/High/Medium/Low] — [one sentence]
Color usage: [Critical/High/Medium/Low] — [one sentence]
Component consistency: [Critical/High/Medium/Low] — [one sentence]
UX states: [Critical/High/Medium/Low] — [one sentence]
Responsiveness: [Critical/High/Medium/Low] — [one sentence]
Accessibility: [Critical/High/Medium/Low] — [summary, delegate to a11y audit]
Motion: [Critical/High/Medium/Low] — [one sentence]
Microcopy: [Critical/High/Medium/Low] — [one sentence]
Design system governance: [Critical/High/Medium/Low] — [summary, delegate to governance]
Brand fit: [Critical/High/Medium/Low] — [one sentence]
Anti-generic: [Critical/High/Medium/Low] — [one sentence]
Delight: [Critical/High/Medium/Low] — [one sentence]
Production readiness: [Critical/High/Medium/Low] — [one sentence]
Visual polish: [Critical/High/Medium/Low] — [one sentence]
Platform fit: [Critical/High/Medium/Low / N/A] — [one sentence]
Graphic language: [Critical/High/Medium/Low / N/A] — [one sentence]
Before/after iteration: [PASS / FAIL / N/A] — [one sentence]

Screenshots:
- Desktop (1440px): [path or note]
- Mobile (375px): [path or note]

Critical findings: [list or "none"]
High findings: [list or "none"]
Medium findings: [list or "none"]

Summary: [one paragraph]
```

---

## Failure Conditions

Audit fails (blocks ship) if ANY of:
- Critical finding in any category
- 3+ High findings
- Production readiness check fails (broken layout, horizontal scroll, console errors)
- Accessibility audit returns Critical or High findings (delegate to accessibility-audit)

---

### Step 17: Visual Polish / Pixel-Perfect QA 🔴

For material visual surfaces, check these before claiming production readiness:

- **Optical balance**: Do visual elements feel weighted correctly? (not left-heavy, not top-heavy)
- **Visual rhythm**: Is there a consistent spacing pattern? (not random gaps, not uneven padding)
- **CTA prominence**: Is the primary action clearly the most important thing on screen?
- **Awkward whitespace**: Is there unintended empty space? (trapped whitespace, orphans, widows)
- **Crop/overflow**: Is anything clipped or cropped unintentionally? (text cut off, images cropped wrong)
- **Icon/text alignment**: Do icons and text align on the same baseline? (not floating above or below)
- **Mobile density**: Does the mobile view feel appropriately spaced? (not cramped, not wasteful)
- **Empty visual noise**: Are there unnecessary decorative elements? (random lines, gradients, dots)
- **Dark mode harmony**: Do colors translate correctly in dark mode? (not washed out, not too bright)
- **Before/after screenshot critique**: Does the change improve the visual quality? (not just "different")

If motion or micro-interactions are involved:
- Delegate to `motion-design` skill for timing, easing, choreography review
- Check: purpose, continuity, feedback, hierarchy, restraint
- Verify: `prefers-reduced-motion` respected, no flashing, timing within spec

If this is net-new UI, major redesign, onboarding, landing page, dashboard, or brand-sensitive surface:
- Delegate to `design-research` skill for design direction review
- Check: selected/rejected directions, competitor audit rationale, anti-pattern avoidance
- Verify: every major aesthetic choice has documented rationale

If the UI targets a specific platform (iOS, Android, Capacitor, cross-platform web):
- Delegate to `platform-guidelines-compliance` skill for platform convention checks
- Check: safe areas, touch targets, navigation patterns, native-feeling motion
- Verify: platform vs custom brand decisions are documented

If the UI includes graphics, illustrations, empty states, or brand icons:
- Delegate to `illustration-graphic-direction` skill for graphic language review
- Check: visual metaphor, iconography style, brand motif, empty-state graphics
- Verify: no generic AI graphics, graphics match design tokens, dark mode compatible

If this is a material visual change (landing page, onboarding, dashboard, hero section):
- Activate `visual-iteration-loop` skill for before/after comparison
- Require: screenshot-first critique, top 5 weaknesses identified, top 3 revised
- Verify: before/after evidence provided, usability not compromised by aesthetic changes
- Warning: NN/g aesthetic-usability effect — visual polish must not mask usability issues

### Step 18: Platform Fit

- Does the UI feel appropriate for its target platform? (iOS vs Android vs web)
- Are platform conventions followed where appropriate?
- Is custom brand expression intentional, not accidental?
- Are safe areas respected (notch, home indicator, status bar)?

### Step 19: Graphic Language Fit

- Do illustrations/graphics match the brand direction?
- Is the iconography style consistent across the product?
- Are empty states designed, not just blank space?
- Are graphics free of generic AI aesthetics (lotus, gradient blobs, stock photos)?

### Step 20: Before/After Iteration Evidence (for material visual changes)

- Has the visual iteration loop been run?
- Are before/after screenshots provided?
- Did the change improve visual quality (not just "different")?
- Was usability preserved or improved (not compromised by aesthetic changes)?

---

## NOT_RUN Rules

Mark audit as NOT_RUN with reason when:
- No UI files in scope — reason: "no UI changes in this scope"
- UI is backend-rendered HTML only — reason: "server-rendered HTML, separate audit needed"
- No browser access — reason: "dev server not available for visual inspection"
- Design Intelligence Brief requested but not available — reason: "Design Intelligence Brief not found, audit based on general principles"

---

## Relation to Design Intelligence Brief

If a Design Intelligence Brief exists for this feature:
1. Read the brief before starting the audit
2. Use the brief's design direction, color direction, typography direction as the audit baseline
3. Evaluate whether the implementation matches the brief
4. Flag any deviations from the brief as findings

If no Design Intelligence Brief exists:
- Audit using general UI quality principles
- Note that no design brief was available for direction-specific evaluation
- Suggest creating a Design Intelligence Brief for this feature
