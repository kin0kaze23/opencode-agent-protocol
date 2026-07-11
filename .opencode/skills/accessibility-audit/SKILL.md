---
name: accessibility-audit
description: >
  Audit and remediate frontend code for WCAG 2.2 AA accessibility conformance.
  Trigger when the user adds or modifies any UI component (forms, modals, dropdowns,
  navigation, tables, buttons, links, images, color tokens), when shipping a new
  page or screen, when reviewing a PR that changes JSX/TSX/HTML/SwiftUI views,
  before any production deploy of a customer-facing app, or when the user asks to
  "check accessibility", "a11y audit", "WCAG", "screen reader", "keyboard nav",
  "color contrast", or mentions any disability-affecting concern. Required by
  workspace standards before merging UI changes to example-app, demo-project,
  example-dashboard, example-toolchainMissionControl, or any user-facing surface. Covers
  automated scanning (axe, Lighthouse, Pa11y), manual keyboard testing, screen
  reader spot checks (VoiceOver/NVDA), and prioritized remediation.
---

# Accessibility Audit (WCAG 2.2 AA)

> Activate for: any frontend change, any new UI component, any production deploy of a user-facing app.
> HARD RULE: A change cannot ship to production if it introduces a NEW WCAG 2.2 Level A or AA failure. Existing failures may be tolerated with a written exception, new ones may not.

---

## Why This Matters Beyond Compliance

Accessibility bugs are usability bugs. Every fix you make for a screen-reader user also helps:
- Users on flaky mobile connections (alt text loads when images don't)
- Users in bright sunlight (high contrast)
- Users who prefer keyboards (power users, RSI sufferers)
- Future-you, debugging at 2am with one hand on a coffee mug

In the EU, US federal contracts, and increasingly state law (CA, NY), AA conformance is also a legal floor. Most lawsuits target the same handful of issues — and they are all on this checklist.

---

## The Protocol

### Phase 1: Automated scan (catches ~30-40% of issues, near-zero cost)

For web apps (React/Next.js/Vite):

```bash
# 1. Add axe DevTools to dev dependencies (one-time)
pnpm add -D @axe-core/cli @axe-core/react

# 2. Run against a running dev server
pnpm dlx @axe-core/cli http://localhost:3000 --tags wcag2a,wcag2aa,wcag22aa --save axe-report.json

# 3. Lighthouse CI for cross-cutting metrics
pnpm dlx @lhci/cli@0.13.x autorun --collect.url=http://localhost:3000 --assert.preset=lighthouse:recommended

# 4. Pa11y for spider-style multi-page scan
pnpm dlx pa11y-ci --sitemap http://localhost:3000/sitemap.xml
```

Triage the report:
- **Critical / Serious** → block ship, fix now
- **Moderate** → fix in this PR if cheap, file ticket if not
- **Minor** → file ticket, tag `a11y-debt`

### Phase 2: Manual keyboard pass (catches ~30% more — automated tools cannot test interaction)

Disconnect your mouse. Walk through the primary user flow with **only** the keyboard:

| Key | Expected behavior |
|---|---|
| `Tab` / `Shift+Tab` | Moves focus forward/back through every interactive element |
| `Enter` / `Space` | Activates the focused button/link |
| `Esc` | Closes modal, cancels dropdown, exits focus trap |
| `Arrow keys` | Navigates within composite widgets (menus, tabs, radio groups) |

**Failure conditions to flag:**
- A focusable element has no visible focus ring (look for `outline: none` without a replacement)
- Focus disappears (sent to `<body>` after a modal closes — should return to the trigger)
- Focus order doesn't match visual order
- A modal opens but you can `Tab` out of it into the underlying page (focus trap missing)
- An interactive element is reachable by mouse but not by keyboard (a `<div onClick>` without `role="button"`, `tabIndex={0}`, and key handlers — common React anti-pattern)
- A custom dropdown/combobox doesn't follow ARIA Authoring Practices for combobox

### Phase 3: Screen reader spot check (catches semantic/labeling issues)

You don't need to be a SR expert. 15 minutes per major flow.

**macOS (VoiceOver):**
- Toggle: `Cmd + F5`
- Read next: `Ctrl + Option + →`
- Interact with element: `Ctrl + Option + Space`
- Open Rotor (list of headings/links/landmarks): `Ctrl + Option + U`

**Windows (NVDA, free):**
- Read next: `↓`
- List headings: `Ins + F7`

**What to listen for:**
- Every form input announces a **label** (not just placeholder text)
- Buttons announce their **purpose**, not "button button button" (icon-only buttons need `aria-label`)
- Images that convey information have alt text; decorative images have `alt=""`
- Headings exist and are in order (h1 → h2 → h3, not h1 → h4)
- Errors are announced when they appear (`aria-live="polite"` on error containers)
- Dynamic content updates are announced (loading states, toast notifications)

**Quick win:** open the Rotor / heading list. If it's empty or chaotic, your page has no semantic structure — that is the highest-leverage fix.

### Phase 4: Color and contrast check

Tooling does most of this, but verify:

- Body text contrast ≥ 4.5:1 against background
- Large text (18pt+ or 14pt bold) ≥ 3:1
- UI component borders, focus rings, icons ≥ 3:1
- Information is never conveyed by color alone (red error text needs an icon or "Error:" prefix)
- Test in dark mode AND light mode if both are supported

Use the browser DevTools color picker (Chrome/Firefox both show contrast ratio inline) or **WebAIM Contrast Checker** for one-offs.

### Phase 5: The 12 high-frequency lawsuit triggers (always check these)

Order of remediation priority — fix top-down:

1. **Form inputs without labels** (`<input>` with placeholder only, no `<label htmlFor>`)
2. **Images without alt text** (`<img>` missing `alt` attribute entirely — `alt=""` for decorative is correct)
3. **Buttons with no accessible name** (icon-only buttons missing `aria-label`)
4. **Color-contrast failures on body text or primary buttons**
5. **Missing keyboard focus indicators** (`outline: none` without replacement)
6. **Modal/dialog without focus trap** (Tab leaks to background page)
7. **Missing or skipped heading levels** (jumping h1 → h3)
8. **Links with non-descriptive text** ("click here", "read more" — should describe destination)
9. **Form validation errors not associated with their input** (need `aria-describedby` pointing to error message)
10. **Custom dropdown/select without proper ARIA** (use native `<select>` unless you have a specific reason)
11. **Time-limited sessions without warning/extension** (auto-logout that fires silently)
12. **Video/audio without captions or transcript** (any media)

### Phase 6: Document the result

Create or update `<repo>/docs/accessibility/audit-<YYYY-MM-DD>.md`:

```markdown
# A11y Audit — <repo> — <date>
- Pages tested: /, /dashboard, /settings
- Scanner: axe-core 4.x, Lighthouse 11.x
- Manual: keyboard ✓, VoiceOver spot check ✓
- Findings: critical=0, serious=2, moderate=5, minor=8
- Fixed in this PR: serious=2, moderate=3
- Remaining (tracked as #1234, #1235): moderate=2, minor=8
- Known exceptions: <list with WCAG ref + business justification>
```

---

## Per-Stack Quick Reference

### React / Next.js
- Use `eslint-plugin-jsx-a11y` (most CRA/Next templates already include it)
- Wrap routes in landmarks (`<main>`, `<nav>`, `<header>`)
- For modals: use Radix UI / React Aria / Headless UI — they get focus trap + ARIA right
- For forms: use `react-hook-form` with `aria-invalid` and `aria-describedby` wired to errors

### Vite + Tailwind
- Tailwind has `focus-visible:` utilities — use them, don't `outline-none` without a replacement
- Add `@tailwindcss/forms` for sane default form styling that doesn't strip semantics

### SwiftUI (Pulse, demo-project iOS)
- Set `.accessibilityLabel("...")` on every custom view
- Use `.accessibilityHint(...)` for non-obvious actions
- Prefer system controls (`Button`, `Toggle`, `Stepper`) — they are accessible by default
- Test with VoiceOver on a real device: `Settings → Accessibility → VoiceOver`
- Dynamic Type: test with large accessibility text size (`Settings → Accessibility → Display & Text Size → Larger Text`)

### Capacitor (demo-project web → iOS)
- Same web rules apply, but VoiceOver may behave differently than browser screen readers
- Test on device, not just simulator — VoiceOver in simulator is unreliable

---

## Common Mistakes to Catch

| Mistake | Why it's wrong | Fix |
|---|---|---|
| `<div onClick={...}>` for buttons | Not focusable, not announced as button | Use `<button>`, or add `role="button"`, `tabIndex={0}`, and `onKeyDown` for Enter/Space |
| Placeholder used as label | Disappears when typing, low contrast, not announced as label | Add visible `<label>` |
| `aria-label="button"` | Tautological — screen reader already says "button" | Describe the action: `aria-label="Close dialog"` |
| `alt="image of cat"` | Screen reader already says "image" | Just `alt="cat"` (or `alt=""` if decorative) |
| Tooltip is the only place info appears | Not visible on touch devices, not always reachable by keyboard | Make critical info visible inline; tooltips supplement, never replace |
| Skip-to-content link missing | Keyboard users tab through nav on every page | Add `<a href="#main">Skip to content</a>` as first focusable element |
| `outline: none` "for design reasons" | Removes the only focus indicator | Replace with a designed focus ring (`focus-visible:ring-2`) — never just remove |

See `references/wcag-22-aa-checklist.md` for the full conformance checklist.

---

## Production Gate Definition (v4.9.2+)

Before any UI change ships to production, ALL of the following must pass:

| Gate | Tool | Pass Criteria |
|---|---|---|
| Typecheck | `tsc --noEmit` | 0 errors |
| Lint | `eslint` | 0 errors |
| Build | `next build` / `vite build` | 0 errors |
| Unit tests | `vitest run` / `jest` | 100% pass |
| Keyboard smoke | Playwright keyboard tests | All tests pass |
| Production axe | axe-core on localhost | 0 serious/critical/moderate violations |
| ARIA snapshot | Playwright ARIA snapshots | All snapshots match |
| Contrast | axe color-contrast rule | 0 violations |
| Reduced motion | `prefers-reduced-motion` check | No motion when preference set |
| Screen reader | Guidepup or manual smoke | PASS or explicitly marked manual-required |

**Run axe-core against production build (localhost serving built assets), not dev server.** Dev servers may serve stale code or incomplete hydration, causing false positives/negatives.

### Pattern References

- `.opencode/patterns/a11y-production-gate.md` — Full gate definition and axe configuration
- `.opencode/patterns/keyboard-navigation-smoke.md` — Keyboard-only navigation test patterns
- `.opencode/patterns/aria-snapshot-regression.md` — ARIA tree snapshot regression tests
- `.opencode/patterns/screen-reader-smoke.md` — Screen reader verification (Guidepup + manual)

### Guidepup Status

Guidepup (VoiceOver/NVDA automation) is **optional/manual-release evidence only**. Do not make it mandatory in CI. macOS VoiceOver and Windows NVDA are feasible locally; Linux is not supported. See `screen-reader-smoke.md` for feasibility details and manual verification templates.
