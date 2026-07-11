# Visual Asset Generation Pattern

> A safe, structured workflow for creating or specifying custom graphics, illustrations, motifs, and visual assets.
> Built on existing skills: `illustration-graphic-direction`, `design-research`, `visual-iteration-loop`, `ui-ux-quality-audit`.

## When to Use

| Surface | Examples |
|---------|----------|
| Empty states | No data, no search results, no notifications |
| Hero visuals | Welcome screens, landing pages, app store screenshots |
| Onboarding | Step illustrations, progress visuals, completion celebrations |
| Brand motifs | Logos, icons, decorative elements, loading animations |
| App store assets | Screenshots, preview videos, feature graphics |

## When Not to Use

| Context | Reason |
|---------|--------|
| Data-dense screens | Visuals distract from information; use clean typography and spacing |
| Forms and inputs | Visuals compete with user focus; keep it minimal |
| Sacred/sensitive content | Visuals may trivialize meaning (e.g., devotion, grief, health) |
| Error states | Users need clarity, not decoration; use clear messaging |
| When text alone suffices | Don't add visuals just to fill space |

## Art Direction Before Generation

**Never generate without direction.** Define these first:

| Element | Description |
|---------|-------------|
| **Metaphor** | What concept does the visual represent? (e.g., "growth" → sprouting plant) |
| **Tone** | Calm, energetic, playful, serious, warm, cool |
| **Visual language** | Line art, flat, gradient, isometric, hand-drawn, geometric |
| **Color palette** | Use design tokens (`--accent-primary`, `--color-text-primary`, etc.) |
| **Token fit** | Must match the project's design system, not generic stock aesthetics |
| **Constraints** | Size, format, aspect ratio, file size limits |

## Prompt Structure

When generating or specifying visuals, use this structure:

```
Subject: [what is depicted]
Metaphor: [what it represents conceptually]
Composition: [layout, framing, focal point]
Style: [line art, flat, gradient, etc.]
Color: [token references or specific palette]
Mood: [calm, energetic, etc.]
Format: [SVG, PNG, WebP, etc.]
Constraints: [size, aspect ratio, file size]
Negative: [what to avoid — generic AI, competitor copying, etc.]
```

### Example

```
Subject: Empty state illustration for "no devotions yet"
Metaphor: Quiet morning, anticipation, peaceful waiting
Composition: Centered, minimal, lots of negative space
Style: Line art with subtle gradient fills
Color: --accent-primary (#4A5D7C) at 20% opacity, --bg-primary (#FDFDFB)
Mood: Calm, inviting, not lonely
Format: SVG preferred, max 5KB
Constraints: 200×200px, scalable
Negative: No generic AI faces, no competitor copying, no busy backgrounds
```

## Brand Consistency

| Rule | Description |
|------|-------------|
| **Match design-research** | Visuals must align with the product's emotional goal and aesthetic direction |
| **Use design tokens** | Colors must reference `--accent-primary`, `--color-text-primary`, etc. |
| **Ownable motifs** | Create distinctive visual elements (e.g., demo-project "S" mark) |
| **No generic AI** | Avoid stock-looking, cliché, or obviously AI-generated aesthetics |
| **Consistent across surfaces** | Same visual language for empty states, loading, errors |

## Accessibility

| Requirement | Description |
|-------------|-------------|
| **Decorative vs meaningful** | Decorative images: `role="presentation"` or `aria-hidden="true"`. Meaningful images: `alt` text required |
| **Alt text** | Describe the concept, not the visual details (e.g., "No devotions yet — start your first one" not "Illustration of empty bookshelf") |
| **No image-only comprehension** | Critical information must never be conveyed only through images |
| **Color contrast** | Visual elements must meet WCAG AA contrast ratios |
| **Reduced motion** | Animated visuals must respect `prefers-reduced-motion` |

## SVG vs Raster Guidance

| Format | When to Use | When to Avoid |
|--------|-------------|---------------|
| **SVG** | Icons, logos, simple illustrations, motifs, loading spinners | Complex photos, detailed illustrations, gradients with many stops |
| **PNG** | Screenshots, app store assets, complex illustrations | Simple icons (use SVG), animated content |
| **WebP** | Photos, complex illustrations where file size matters | Simple icons (use SVG), when browser support is uncertain |

### Optimization

| Asset Type | Target Size | Technique |
|------------|-------------|-----------|
| SVG icons | < 2KB | Minify, remove metadata, use currentColor |
| SVG illustrations | < 5KB | Simplify paths, reduce points, remove unused defs |
| PNG screenshots | < 200KB | Compress, reduce colors, resize to target |
| WebP images | < 100KB | Quality 80-85, resize to target |

## Copyright and Safety

| Rule | Description |
|------|-------------|
| **No competitor copying** | Never replicate another product's visual identity, icons, or illustrations |
| **No copyrighted material** | Don't use stock images, fonts, or assets without proper licensing |
| **No auto-commit** | Generated assets must be reviewed before committing |
| **No auto-generate** | Don't generate images by default; require explicit direction |
| **Attribute sources** | If using external references, document them |

## Approval Rules

**Do not commit generated assets without explicit approval.**

| Asset Type | Approval Required |
|------------|-------------------|
| Icons | ✅ Yes — must match design system |
| Illustrations | ✅ Yes — must match brand direction |
| Logos/motifs | ✅ Yes — must be ownable and distinctive |
| App store assets | ✅ Yes — must meet platform guidelines |
| Loading animations | ✅ Yes — must respect reduced motion |

## Review Loop

1. **Generate** — Create asset based on art direction and prompt structure
2. **Inspect** — Review against acceptance criteria (see below)
3. **Reject/Keep** — Decide if asset meets standards
4. **Revise** — If rejected, refine direction and regenerate (max 2 iterations)
5. **Optimize** — Compress, minify, format for target use
6. **Verify in UI** — Place asset in actual UI context and verify visually

## Acceptance Criteria (CDO-Level)

| Criterion | Description |
|-----------|-------------|
| **Metaphor clarity** | Visual communicates the intended concept without explanation |
| **Brand fit** | Matches project's design-research and illustration direction |
| **Token consistency** | Uses design tokens, not hardcoded colors |
| **Accessibility** | Proper alt text, contrast, reduced-motion support |
| **Technical quality** | Optimized file size, correct format, scalable |
| **Originality** | Not generic, not competitor-copying, ownable |
| **Context fit** | Works in actual UI context (not just as standalone image) |
| **Emotional resonance** | Supports the product's emotional goal (calm, energetic, etc.) |

## Integration with Existing Skills

This pattern builds on:

| Skill | Role |
|-------|------|
| `illustration-graphic-direction` | Defines visual metaphor, iconography, brand motif |
| `design-research` | Provides product context, emotional goal, aesthetic direction |
| `visual-iteration-loop` | Structured before/after critique and revision |
| `ui-ux-quality-audit` | Final quality check against visual standards |

## Proven Example: demo-project "S" Mark

| Detail | Value |
|--------|-------|
| **Project** | demo-project (daily devotion app) |
| **Asset** | Typographic "S" mark in Instrument Serif |
| **Metaphor** | demo-project, simplicity, ownable brand identity |
| **Format** | SVG (inline in component) |
| **Color** | `--accent-primary` (#4A5D7C) |
| **Size** | 48×48px |
| **Commit** | `ce22245 feat(stillness): refine welcome screen visual identity` |
| **Verification** | 8 screenshots across viewports + dark mode |
