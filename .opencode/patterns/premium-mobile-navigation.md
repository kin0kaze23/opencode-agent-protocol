# Premium Mobile Navigation / TabDock

> A production-verified pattern for calm, premium mobile bottom navigation.
> Proven in demo-project (commit `8c2ed9d`), verified across 8 screens, 2 themes, 4 breakpoints.

## When to Use

- **Mobile-first apps** where thumb-reachable navigation is critical.
- **Apps with 3–5 primary destinations** — the cognitive sweet spot for bottom nav.
- **Products needing high perceived quality** — glass, pill indicators, and calm motion signal polish.
- **Calm/premium coer experiences** — meditation, wellness, journaling, faith, finance, or lifestyle apps.
- **Replacing underline/indicator-based docks** with a more premium, accessible alternative.

## When Not to Use

- **Dense enterprise desktop apps** — use sidebar or top navigation instead.
- **Apps with more than 5 primary destinations** — cognitive overload; consider overflow menus or hierarchical nav.
- **Flows where bottom nav would block critical content** — full-screen media, reading, or creation flows.
- **Products needing sidebar-first navigation** — desktop-heavy or admin tools.
- **Highly contextual navigation** — where available actions change per screen (use contextual toolbars instead).

## Visual Principles

| Principle | Description |
|-----------|-------------|
| **Floating capsule** | The dock floats above content with rounded corners, not flush to the screen edge. |
| **Tokenized glass surface** | `backdrop-filter: blur()` with semi-transparent background using design tokens, not hardcoded colors. |
| **Subtle border/shadow** | Thin border (`1px`) and soft shadow create depth without heaviness. |
| **Active pill state** | A rounded pill slides behind the active tab — more premium than underlines or color-only states. |
| **Icon + label pairing** | 18px icons with 10px labels, centered vertically in 64px touch targets. |
| **Safe-area-aware bottom spacing** | Uses `env(safe-area-inset-bottom)` to respect device notches and home indicators. |
| **Dark/light mode support** | Semantic tokens adapt to theme; no hardcoded colors except in token definitions. |
| **Calm, brand-appropriate motion** | 300ms ease-out-expo transition — smooth but not playful. Adjust duration per product personality. |

## Accessibility Requirements

| Requirement | Implementation |
|-------------|----------------|
| **Nav landmark** | `<nav role="navigation">` wraps the entire dock. |
| **aria-label** | `aria-label="Primary navigation"` on the `<nav>` element. |
| **aria-current="page"** | Applied to the active tab button; removed from inactive tabs. |
| **Accessible tab labels** | Each button has `aria-label` matching the visible label. |
| **44×44+ touch targets** | 64px height exceeds WCAG minimum; full button width clickable. |
| **Keyboard accessible** | Native `<button>` elements support Tab/Enter/Space navigation. |
| **Active state not color-only** | Pill background + text color change provides dual indication. |
| **Reduced motion support** | `@media (prefers-reduced-motion: reduce)` disables pill transition. |

## Motion Requirements

| Requirement | Implementation |
|-------------|----------------|
| **Transform-based movement** | Uses `transform: translateX()` with CSS custom property `--pill-index` — GPU-accelerated, no layout recalculation. |
| **Reduced-motion support** | Transition disabled via `@media (prefers-reduced-motion: reduce)`. |
| **No aggressive bounce** | Uses `ease-out-expo` — decelerating, not springy. Avoid bounce unless brand-appropriate. |
| **Transition duration supports personality** | 300ms default; adjust `--duration-normal` token per product (calm: 300–500ms, energetic: 150–250ms). |

## FE Implementation Notes

| Aspect | Guidance |
|--------|----------|
| **Same API if replacing existing dock** | Keep `activeTab` and `onTabChange` props; internal implementation can change freely. |
| **Token-based styling** | All colors, spacing, and motion use CSS custom properties. No hardcoded values in component JSX. |
| **No hardcoded colors except token definitions** | `#7A8FA8` is acceptable only inside a `[data-theme="vespers"]` token block, never directly in component CSS. |
| **No content overlap** | Add `pb-36` (144px) bottom padding to all tab screens to clear the dock. |
| **Safe-area support** | Use `env(safe-area-inset-bottom)` in CSS; test on devices with home indicators. |
| **Responsive verification** | Verify at 320px, 375px, 414px, and 768px breakpoints. No horizontal scroll. |
| **Dark-mode verification** | Verify all tokens resolve correctly in dark mode; check contrast ratios. |
| **Pill alignment** | Calculate `translateX` as `index * (tabWidth + gap)`. Verify for each tab index. |

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|--------------|-----|
| **Copying fintech/neon visuals blindly** | Clashes with calm product identity; feels gamified. | Adapt principles to brand — warm glass, muted tones. |
| **Tiny touch targets** | Fails WCAG; frustrating on mobile. | Minimum 44×44px; aim for 64px height. |
| **Active state only by color** | Invisible to color-blind users. | Add pill background, icon weight change, or shape indicator. |
| **Ignoring safe areas** | Dock overlaps home indicator on modern devices. | Use `env(safe-area-inset-bottom)`. |
| **Hardcoded colors in component** | Breaks theme switching; violates token discipline. | Use CSS custom properties; define theme variants in CSS. |
| **Too many tabs (6+)** | Cognitive overload; cramped layout. | Limit to 3–5; use overflow menu or hierarchical nav for more. |
| **Overly energetic motion** | Feels playful, not calm; distracting. | Use ease-out curves, 300ms+ duration; avoid spring/bounce. |
| **Using `left` property for animation** | Triggers layout recalculation; janky on low-end devices. | Use `transform: translateX()` for GPU acceleration. |

## Acceptance Criteria

- [ ] Premium but project-native (not a copy-paste from another app)
- [ ] Clear active tab indication (pill + color + aria-current)
- [ ] Safe-area aware (respects device insets)
- [ ] Accessible (nav landmark, aria labels, keyboard, 44px+ targets)
- [ ] Token-driven (no hardcoded colors in component JSX)
- [ ] Responsive (no horizontal scroll, works at 320px+)
- [ ] No content overlap (sufficient bottom padding on tab screens)
- [ ] Dark mode works (tokens resolve, contrast acceptable)
- [ ] Tests/typecheck/build pass (no regressions)
- [ ] Reduced motion respected (transition disabled for prefers-reduced-motion)

## Proven Example: demo-project

| Detail | Value |
|--------|-------|
| **Project** | demo-project (daily devotion app) |
| **Commit** | `8c2ed9d feat(demo-project): add premium mobile tab dock` |
| **Files** | `src/components/TabDock.tsx`, `src/styles/design-system.css` |
| **Tabs** | Today (Sun), Explore (Compass), Vault (Heart), Settings (SlidersHorizontal) |
| **Post-commit verification** | ✅ Passed — 8 screens, 2 themes, 4 breakpoints |
| **Tests** | ✅ 120/120 PASS |
| **Conformance** | ✅ 234/234 PASS (includes runtime styling integrity guardrail) |
| **Typecheck/Build** | ✅ PASS |
| **Browser verification** | ✅ 14/14 checks passed (light/dark, breakpoints, interactions, console, touch targets) |

### Key Implementation Details

- **Pill positioning**: `transform: translateX(calc(var(--pill-index, 0) * (100% + var(--space-2) * 2)))`
- **Touch targets**: 64px height (exceeds 44px minimum)
- **Glass effect**: `backdrop-filter: blur(24px)` with `rgba(255, 255, 255, 0.85)` background
- **Dark mode**: Warm glass `rgba(36, 42, 59, 0.9)` with accent pill `#7A8FA8` via `--color-accent` token
- **Motion**: 300ms ease-out-expo, GPU-accelerated via `transform`
- **Accessibility**: `<nav role="navigation">`, `aria-current="page"`, `aria-label` on each tab

### Token Structure

```css
/* Light mode */
--tab-dock-bg: rgba(255, 255, 255, 0.85);
--tab-dock-border: rgba(0, 0, 0, 0.06);
--tab-dock-pill-bg: var(--color-text-primary);
--tab-dock-icon-inactive: var(--color-text-tertiary);
--tab-dock-text-inactive: var(--color-text-secondary);

/* Dark mode (vespers) */
[data-theme="vespers"] {
  --color-accent: #7A8FA8;
  --tab-dock-bg: rgba(36, 42, 59, 0.9);
  --tab-dock-border: rgba(255, 255, 255, 0.08);
  --tab-dock-pill-bg: var(--color-accent);
  --tab-dock-icon-inactive: rgba(196, 194, 189, 0.5);
}
```
