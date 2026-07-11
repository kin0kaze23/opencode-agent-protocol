---
name: frontend-design
description: Create distinctive, production-grade UI/UX that avoids generic "AI aesthetics." Bold aesthetic direction, exceptional typography, motion design, spatial composition.
---

# Frontend Design Skill

> Activate for: any UI component, page, screen, or interface work.
> HARD RULE: Never produce generic AI slop. Every design must be intentionally distinctive.

## Procedure

Before designing, read the following:

1. Read the target repo's `WORKSPACE_MAP.md` to confirm the dev port and stack
2. Read the existing design system tokens (CSS variables, Tailwind config, or theme file)
3. Read 1-2 existing pages or components to understand the current visual language
4. Read the Pencil style guide tags if using `pencil-design` for wireframing

Then answer these before touching a single line of code:

1. **Purpose** — What problem does this solve? Who uses it? What's their emotional state?
2. **Tone** — Pick ONE extreme and commit: brutally minimal | maximalist | retro-futuristic | organic/natural | luxury/refined | playful | editorial/magazine | brutalist | art deco | industrial | soft/pastel. Execute with precision.
3. **Differentiation** — What is the ONE thing a user will remember? Design backward from that.
4. **Constraints** — Framework? Performance budget? Accessibility level? Dark/light?

Write these answers as a short paragraph before any code. Then commit to the direction.

---

## Typography Rules

- NEVER: Inter, Roboto, Arial, system-ui, -apple-system
- ALWAYS: Distinctive font pairs from Google Fonts or variable fonts
- Display font + body font pairing — they must contrast meaningfully
- Examples of strong choices: Playfair Display + Lora, Space Mono + DM Sans, Instrument Serif + Instrument Sans, Syne + Manrope, Bricolage Grotesque + Instrument Sans

```css
/* Example: editorial direction */
@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;1,400&family=Lora:ital,wght@0,400;1,400&display=swap');

:root {
  --font-display: 'Playfair Display', serif;
  --font-body: 'Lora', serif;
}
```

---

## Color Rules

- NEVER: Purple gradient on white, blue gradient on dark, #3B82F6 as primary accent
- ALWAYS: Build a palette with one dominant color (not neutral) + one sharp accent + neutrals
- Use CSS variables for every color — no hardcoded hex in components
- Try: warm neutrals + deep emerald, off-white + deep navy + amber, slate + coral, near-black + lime

```css
:root {
  --color-bg: #0F0F0D;          /* near-black, warm */
  --color-surface: #1A1A17;     /* slightly lighter */
  --color-text: #F5F0E8;        /* warm white */
  --color-accent: #C8F04E;      /* electric lime */
  --color-muted: #6B6B5E;       /* warm gray */
}
```

---

## Motion Rules

- One well-orchestrated entrance beats ten scattered animations
- Staggered reveals with `animation-delay` create delight
- Hover states that surprise: scale on text, color shift on icon, underline that draws
- Use `@media (prefers-reduced-motion: reduce)` for accessibility

```css
/* Staggered card entrance */
.card { opacity: 0; transform: translateY(20px); animation: reveal 0.5s ease forwards; }
.card:nth-child(1) { animation-delay: 0ms; }
.card:nth-child(2) { animation-delay: 80ms; }
.card:nth-child(3) { animation-delay: 160ms; }

@keyframes reveal {
  to { opacity: 1; transform: translateY(0); }
}

@media (prefers-reduced-motion: reduce) {
  .card { animation: none; opacity: 1; transform: none; }
}
```

---

## Spatial Composition Rules

- Unexpected layouts > predictable grids
- Asymmetry, overlap, diagonal flow — use these intentionally
- Generous negative space OR controlled density — never accidental middle ground
- Break the grid at key moments (hero text over image edge, stat that bleeds into margin)

---

## Background & Depth

Create atmosphere, not flat surfaces:
- Gradient meshes (`conic-gradient`, `radial-gradient` layered)
- Grain/noise overlay (SVG filter or CSS pseudo-element)
- Dramatic shadows (not `box-shadow: 0 4px 6px rgba(0,0,0,0.1)` — go deeper)
- Geometric patterns or line art as background layer

```css
/* Noise grain overlay */
.bg-noise::after {
  content: '';
  position: fixed; inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.05'/%3E%3C/svg%3E");
  pointer-events: none; opacity: 0.4; mix-blend-mode: overlay; z-index: 1000;
}
```

---

## Output format

Produce a design deliverable in this exact format:

```
## Frontend Design — <component/page name>

**Tone:** <committed tone direction>
**Purpose:** <what problem this solves>
**Differentiator:** <the ONE memorable thing>

### Design decisions
- Typography: <font pair and why>
- Color palette: <dominant + accent + neutrals>
- Motion: <entrance strategy>
- Layout: <composition approach>

### Checklist
- [ ] Tone direction committed and visible in every element
- [ ] Custom font pair loaded (not system fonts)
- [ ] Color palette uses CSS variables throughout
- [ ] At least one entrance animation with stagger
- [ ] Hover states feel alive
- [ ] Background has atmosphere
- [ ] Mobile viewport tested
- [ ] prefers-reduced-motion handled
- [ ] No purple gradients, no Inter, no generic card shadows
```

---

## Using Pencil MCP for Design

When designing screens before coding, use the Pencil MCP tool:
- `mcp__pencil__get_guidelines(topic="web-app")` — get design system rules
- `mcp__pencil__get_style_guide_tags` — find matching style guides
- `mcp__pencil__get_style_guide(tags, name)` — load a style guide
- `mcp__pencil__batch_design(operations)` — create/update design nodes
- `mcp__pencil__get_screenshot` — validate design visually

Design in Pencil FIRST for any screen that's larger than a single component.

## Out of Scope

This skill does NOT:
- Write backend logic or API handlers (that is /implement)
- Fix performance issues (that is performance/SKILL.md)
- Audit accessibility compliance (that is accessibility-audit/SKILL.md)
- Replace the Pencil design tool for wireframing (use Pencil MCP first)
- Produce generic or template-based UI (always be intentionally distinctive)
