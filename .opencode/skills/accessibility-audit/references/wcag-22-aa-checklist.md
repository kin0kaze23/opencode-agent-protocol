# WCAG 2.2 AA Conformance Checklist

Pragmatic checklist organized by frequency in real audits. Tick each item against the page/flow under review. WCAG criterion ID in parentheses.

---

## Perceivable

- [ ] All non-decorative images have meaningful `alt` text (1.1.1)
- [ ] Decorative images have `alt=""` (not omitted) (1.1.1)
- [ ] Video has captions; audio has transcript (1.2.2, 1.2.3)
- [ ] Information is not conveyed by color alone — also use icon, text label, or pattern (1.4.1)
- [ ] Body text contrast ≥ 4.5:1; large text ≥ 3:1 (1.4.3)
- [ ] Page is usable when zoomed to 200% — no clipping, no horizontal scroll (1.4.4, 1.4.10)
- [ ] UI component and graphical contrast ≥ 3:1 (borders, icons, focus rings) (1.4.11)
- [ ] Text spacing can be increased without loss of functionality (1.4.12)
- [ ] Hover/focus content is dismissible, hoverable, and persistent (1.4.13)

## Operable

- [ ] All interactive elements reachable by keyboard (2.1.1)
- [ ] No keyboard trap — Esc / Tab can always exit (2.1.2)
- [ ] No content flashes more than 3 times per second (2.3.1)
- [ ] Skip-to-content link present (2.4.1)
- [ ] Page has descriptive `<title>` (2.4.2)
- [ ] Focus order matches visual/logical order (2.4.3)
- [ ] Link text describes destination (no bare "click here") (2.4.4)
- [ ] Visible focus indicator on every focusable element (2.4.7, 2.4.11 — new in 2.2)
- [ ] Heading hierarchy is logical (h1 → h2 → h3, no skipping) (2.4.6)
- [ ] Drag operations have a single-pointer alternative (2.5.7 — new in 2.2)
- [ ] Touch targets ≥ 24×24 CSS pixels (2.5.8 — new in 2.2)

## Understandable

- [ ] Page declares language (`<html lang="en">`) (3.1.1)
- [ ] Form inputs have visible labels (3.3.2)
- [ ] Error messages are clear and associated with their input (`aria-describedby`) (3.3.1, 3.3.3)
- [ ] Required fields indicated in label, not just by color (3.3.2)
- [ ] No automatic redirects on input/focus changes that surprise the user (3.2.1, 3.2.2)
- [ ] Help is consistent across pages — same icon means same thing (3.2.4, 3.2.6 — new in 2.2)
- [ ] Auth flow does not require remembering, transcribing, or solving a puzzle that is not also offered an alternative (3.3.8 — new in 2.2)
- [ ] Information user already entered is not re-requested unnecessarily (3.3.7 — new in 2.2)

## Robust

- [ ] Valid HTML — no duplicate IDs, properly nested elements (4.1.1)
- [ ] All custom widgets have correct ARIA role, name, value (4.1.2)
- [ ] Status messages (toasts, errors appearing dynamically) are announced via `aria-live` or role="status"/"alert" (4.1.3)

---

## What's New in WCAG 2.2 (Often Missed)

These were added Oct 2023 and often missed in audits done with older tooling:

- **2.4.11 Focus Not Obscured (AA)** — Focused element must not be hidden behind sticky headers/footers
- **2.5.7 Dragging Movements (AA)** — Any drag interaction needs single-pointer alternative (e.g., kanban boards need keyboard-accessible move buttons)
- **2.5.8 Target Size (AA)** — Touch targets ≥ 24×24 CSS px (some exceptions for inline links in text)
- **3.2.6 Consistent Help (A)** — Help mechanism appears in same relative location across pages
- **3.3.7 Redundant Entry (A)** — Don't make users re-enter info they already provided in the same session
- **3.3.8 Accessible Authentication (AA)** — Don't require cognitive function tests for login (no "type the third character of your password" puzzles unless alternative offered)

---

## Tooling Coverage Map

| Issue type | axe-core | Lighthouse | Pa11y | Manual required |
|---|---|---|---|---|
| Missing alt text | ✓ | ✓ | ✓ | — |
| Color contrast | ✓ | ✓ | ✓ | — |
| Missing form labels | ✓ | ✓ | ✓ | — |
| Heading order | ✓ | ✓ | ✓ | — |
| Keyboard reachability | partial | ✗ | partial | ✓ |
| Focus visibility on interaction | ✗ | ✗ | ✗ | ✓ |
| Focus trap in modals | ✗ | ✗ | ✗ | ✓ |
| Screen reader announcements | ✗ | ✗ | ✗ | ✓ |
| Logical reading order | ✗ | ✗ | ✗ | ✓ |
| Meaningful link text | partial | ✗ | partial | ✓ |
| Information conveyed by color alone | partial | partial | partial | ✓ |

The ✓-only items are fixable in CI. The ✗ items require human judgment — budget time for them.
