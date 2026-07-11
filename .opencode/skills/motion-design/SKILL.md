---
name: motion-design
description: Senior motion design expertise — timing, easing, micro-interactions, choreography, physics principles, CSS/React implementation patterns
version: v4.9.2
---

# Motion Design Skill

> Activate for: any UI change that involves animation, transitions, or micro-interactions
> HARD RULE: Motion must serve clarity, feedback, or delight — never decoration alone.

---

## Purpose

Gives agents senior-level motion taste and implementation guidance. Motion is not decorative; it conveys status, provides feedback, guides attention, and enriches the experience. Poor motion feels gimmicky; great motion feels invisible but intentional.

---

## Motion Principles

| Principle | What It Means |
|---|---|
| **Purpose** | Every animation must communicate something: state change, spatial relationship, user action confirmation, or emotional tone |
| **Continuity** | Objects should maintain visual continuity when transitioning — users track what moves where |
| **Feedback** | User actions must receive immediate visual response (press, hover, swipe, drop) |
| **Hierarchy** | More important elements animate first or more prominently |
| **Restraint** | Less is more — the best motion is the user barely notices but would miss if removed |

---

## When NOT to Animate

- Content is already clear without motion
- The animation would delay or distract from the primary task
- The user is in a flow state and interruption would be jarring
- The animation serves only "visual interest" with no functional purpose
- The product is utilitarian (forms, tables, admin panels) where speed matters more than delight
- The user has `prefers-reduced-motion` enabled

---

## Micro-Interaction Catalog

### Button Press (100-150ms)
- Scale down to 0.97-0.98x on active/press
- Return to 1.0x on release
- Color transition optional (200ms)
- Purpose: confirms physical press

### Hover/Focus (150-250ms)
- Subtle color or shadow change
- Optional: slight scale (1.02x) for cards
- Optional: underline for links
- Purpose: indicates interactivity

### Card Reveal (250-400ms)
- Fade in from 0 opacity
- Optional: slide up 8-16px
- Stagger if multiple cards (50-100ms between each)
- Purpose: draws attention to new content

### Onboarding Entrance (250-500ms)
- Staggered: logo → headline → subtitle → CTA
- 150ms delay between each element
- Ease-out cubic-bezier(0.22, 1, 0.36, 1)
- Purpose: guides eye through hierarchy

### Success Confirmation (300-500ms)
- Checkmark draw animation or gentle scale bounce
- Optional: brief color pulse
- Purpose: confirms action completed

### Error Shake (300-400ms)
- Horizontal shake: -4px → +4px → -4px → +4px → 0
- Duration: 400ms total
- Optional: brief red flash
- Purpose: draws attention to error without being alarming

### Loading Skeleton (continuous)
- Shimmer: left-to-right gradient sweep, 1.5s cycle
- Opacity pulse: 0.3 → 0.6 → 0.3, 2s cycle
- Purpose: communicates loading without a spinner

### Page Transition (300-500ms)
- Fade + slight slide (8px) for most transitions
- Shared element transitions for continuity when applicable
- Purpose: maintains spatial awareness

### Gesture Feedback (100-200ms)
- Swipe: follow finger, spring back on release
- Pull-to-refresh: stretch with resistance, snap back
- Long press: slight scale down (0.95x) after 300ms hold
- Purpose: makes the interface feel physical

---

## Timing Specification

| Use Case | Duration | Rationale |
|---|---|---|
| Instant feedback (button press, toggle) | 100-150ms | Fast enough to feel immediate |
| Hover/focus state change | 150-250ms | Noticeable but not sluggish |
| Entrance/exit transitions | 250-400ms | Gives eye time to track |
| Page transitions | 300-500ms | Balances continuity with speed |
| Ambient/brand motion (breathing, floating) | 400-700ms | Relaxing, not distracting |
| Loading shimmer | 1.5s per cycle | Slow enough to not induce anxiety |
| Error shake | 300-400ms total | Quick but noticeable |

---

## Easing Rules

| Easing Type | CSS Value | When to Use |
|---|---|---|
| **Ease-out** | `cubic-bezier(0.22, 1, 0.36, 1)` | Entrances — starts fast, settles gently |
| **Ease-in** | `cubic-bezier(0.55, 0, 1, 0.45)` | Exits — starts slow, accelerates away |
| **Ease-in-out** | `cubic-bezier(0.65, 0, 0.35, 1)` | Smooth transitions in both directions |
| **Spring** | `cubic-bezier(0.34, 1.56, 0.64, 1)` | Physical feedback, gesture response |
| **Linear** | `linear` | ONLY for continuous progress (loading bars, spinners) |

**Never use:** `ease` (too generic), `ease-in-out` for entrances (too slow to start).

---

## Choreography Rules

### Parent Before Child
- Container animates before its contents
- Example: card fades in, then children stagger in

### Staggered Sequence
- Multiple similar elements: stagger by 50-150ms
- Maximum total sequence: 1000ms (otherwise feels slow)
- Example: list items fade in one by one, 80ms apart

### Focus-First Animation
- The most important element animates first and most prominently
- Secondary elements follow with subtler motion
- Example: headline → subtitle → CTA (not all at once)

### Avoid All-Elements-Moving-at-Once
- If everything moves, nothing draws attention
- Maximum 3-4 elements animating simultaneously
- Everything else should be static or transition silently

---

## Accessibility

- **`prefers-reduced-motion`**: disable all non-essential animations; replace with instant state changes
- **No flashing/strobing**: maximum 3 flashes per second; avoid red/green alternation
- **Motion must not be required to understand content**: all information must be available without animation
- **Motion duration limit**: animations should not exceed 5 seconds for essential content
- **Provide pause/stop**: for any animation longer than 5 seconds (WCAG 2.2 2.2.2)

---

## CSS/React Implementation Patterns

### CSS Transitions (simple state changes)
```css
.btn { transition: all 200ms cubic-bezier(0.22, 1, 0.36, 1); }
.btn:hover { transform: scale(1.02); }
```

### CSS Keyframes (one-off animations)
```css
@keyframes fade-in-up {
  from { opacity: 0; transform: translateY(16px); }
  to { opacity: 1; transform: translateY(0); }
}
.element { animation: fade-in-up 300ms cubic-bezier(0.22, 1, 0.36, 1) forwards; }
```

### CSS Staggered Children
```css
.item { animation: fade-in-up 300ms ease-out forwards; opacity: 0; }
.item:nth-child(1) { animation-delay: 0ms; }
.item:nth-child(2) { animation-delay: 80ms; }
.item:nth-child(3) { animation-delay: 160ms; }
```

### React Inline (for dynamic values)
```tsx
<div style={{
  animation: `fade-in-up 300ms ${easing} ${delay}ms forwards`,
  opacity: 0
}} />
```

### Reduced Motion Override
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## Motion for React Implementation Defaults

> **Library:** Motion for React (formerly Framer Motion)
> **Status:** Default React animation library — adoption is repo-specific and non-mandatory
> **Docs:** [motion.dev/react](https://motion.dev/react)

### When to Use Motion for React

- The repo already has it installed (e.g., protected-repo with Framer Motion 12.x)
- The interaction requires gesture handling (drag, swipe, pan)
- The interaction requires layout animations (shared element transitions, FLIP)
- The interaction requires spring physics with complex configs
- The interaction requires AnimatePresence for exit animations

### When NOT to Use Motion for React

- CSS `transition` or `@keyframes` can handle the interaction cleanly
- The repo does not use React (use CSS-only or framework-appropriate alternative)
- The repo has an established CSS-only motion system (e.g., demo-project)
- The animation is purely decorative
- Adding Motion would introduce a new dependency without clear benefit

### Motion Tokens

Define reusable motion tokens in your design system:

| Token | Duration | Use Case |
|---|---|---|
| `fast` | 120–180ms | Instant feedback (button press, toggle, tap) |
| `standard` | 180–260ms | Hover/focus, state changes, micro-interactions |
| `slow` | 300–420ms | Entrances, exits, page transitions, card reveals |
| `ambient` | 400–700ms | Background motion, breathing, floating elements |

### Easing Defaults

| Context | Easing | CSS Equivalent |
|---|---|---|
| Entrances | `easeOut` | `cubic-bezier(0.22, 1, 0.36, 1)` |
| Exits | `easeIn` | `cubic-bezier(0.55, 0, 1, 0.45)` |
| Bidirectional | `easeInOut` | `cubic-bezier(0.65, 0, 0.35, 1)` |
| Physical feedback | `spring` (stiffness: 300, damping: 20) | `cubic-bezier(0.34, 1.56, 0.64, 1)` |

### Reduced Motion Pattern

```tsx
import { useReducedMotion } from 'motion/react';

const reducedMotion = useReducedMotion();

<motion.div
  initial={reducedMotion ? false : { opacity: 0, y: 8 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: reducedMotion ? 0 : 0.2 }}
/>
```

### Repo-Specific Motion Defaults

| Repo | Default | Notes |
|---|---|---|
| protected-repo | Motion for React (Framer Motion 12.x) | Already installed. Use presets from `lib/motion/presets.ts`. |
| demo-project | CSS-only motion | No Motion for React. Use CSS transitions and `@keyframes` from `design-system.css`. |
| Other React repos | Motion for React (preferred) | Install only if a concrete interaction requires it. |

---

## Evidence Format

```markdown
## Motion Design Review

Overall: PASS / FAIL / NOT_RUN

Purpose: [each animation serves a clear purpose / decorative noise detected]
Timing: [within spec for use case / too slow or too fast]
Easing: [appropriate easing for direction / wrong easing used]
Choreography: [staggered and focused / all-at-once or chaotic]
Accessibility: [reduced-motion respected / flashing content / motion required for understanding]
Implementation: [CSS transitions or keyframes / JS-heavy or janky]

Findings:
- [Critical/High/Medium/Low] [specific issue with file:line]
```

---

## Failure Conditions

Motion review fails (blocks completion) if ANY of:
- Animation prevents task completion (too slow, too distracting)
- Flashing content (>3 flashes/second)
- Motion is required to understand content
- `prefers-reduced-motion` not respected

---

## NOT_RUN Rules

Mark as NOT_RUN with reason when:
- No animations in scope — reason: "no motion/animation in this change"
- Static content only — reason: "static screen, no micro-interactions involved"
- Framework handles motion (e.g., React Router transitions) — reason: "framework-managed transitions, review not applicable"

---

## Integration with Other Skills

- Referenced by `ui-ux-quality-audit` for motion quality review
- Referenced by `accessibility-audit` for prefers-reduced-motion implementation details
- Referenced by `design-research` for motion personality direction
- Called before implementing any animation, transition, or micro-interaction
