# A11y Production Gate

> **Pattern:** `.opencode/patterns/a11y-production-gate.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines the production accessibility gate that must pass before any UI-facing change ships to production. This gate ensures that accessibility is not an afterthought but a first-class quality requirement.

## When to Apply

Trigger this gate when:
- Any UI component, page, or screen is added or modified
- CSS tokens, colors, or typography are changed
- Navigation structure changes
- Form inputs or interactive elements are added/modified
- Before any production deploy of a user-facing surface

## Gate Definition

### Required Checks (ALL must pass)

| Check | Tool | Pass Criteria |
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

### axe-core Configuration

Run axe-core against **production build** (localhost serving built assets), not dev server:

```javascript
const results = await axe.run({
  runOnly: {
    type: 'tag',
    values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'best-practice']
  }
});

// Pass criteria
expect(results.violations).toHaveLength(0);
```

### Known Exceptions

If a violation cannot be fixed immediately:
1. Document the violation in the repo's `ACCESSIBILITY_CHECKLIST.md`
2. Add a `// a11y-exception: <reason>` comment in code
3. Get explicit owner approval before shipping
4. Set a deadline for remediation (max 2 sprints)

## Implementation Pattern

### Playwright Integration

```typescript
test("page passes axe-core with 0 violations", async ({ page }) => {
  const axeSource = await fetch("https://unpkg.com/axe-core@4.10.2/axe.min.js").then(r => r.text());
  await page.goto(`${BASE_URL}/target-page`, { waitUntil: "networkidle" });
  await page.waitForTimeout(2000); // Allow full hydration
  await page.addScriptTag({ content: axeSource });

  const results = await page.evaluate(async () => {
    return await window.axe.run();
  });

  expect(results.violations).toHaveLength(0);
  expect(results.passes.length).toBeGreaterThan(10);
});
```

### Dev Server Warning

**Always use production build for axe scans.** Dev servers may serve stale code or incomplete hydration, causing false positives/negatives. Clear `.next` (or equivalent) and restart before running axe scans.

## Related Patterns

- `keyboard-navigation-smoke.md` — Keyboard-only navigation tests
- `aria-snapshot-regression.md` — ARIA tree snapshot regression tests
- `screen-reader-smoke.md` — Screen reader verification tests

## History

| Date | Change |
|---|---|
| 2026-05-22 | Created from Phase M.2.4 work |
