# ARIA Snapshot Regression

> **Pattern:** `.opencode/patterns/aria-snapshot-regression.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines the ARIA snapshot regression test pattern for catching semantic accessibility tree regressions over time. ARIA snapshots store a YAML representation of the accessibility tree and compare it against a baseline on each test run.

## When to Apply

Trigger when:
- Page structure changes (adding/removing landmarks, headings, regions)
- Component semantics change (role, aria-label, aria-describedby)
- Navigation structure is modified
- Form field labels or error associations change

## How ARIA Snapshots Work

Playwright's `toHaveAccessibleName()` and `expect().toMatchSnapshot()` can capture the accessibility tree:

```typescript
test("page accessibility tree matches snapshot", async ({ page }) => {
  await page.goto(`${BASE_URL}/target-page`, { waitUntil: "networkidle" });

  // Capture the accessibility tree
  const accessibilityTree = await page.accessibility.snapshot({
    interestingOnly: true,
    root: await page.locator('main').elementHandle()
  });

  expect(accessibilityTree).toMatchSnapshot('a11y-tree.json');
});
```

## Snapshot Coverage

### Required Snapshots Per Page

| Page | Snapshot Target | What It Verifies |
|---|---|---|
| Onboarding | `<main>` element | h1, form controls, toggles, progress indicator |
| Today/Dashboard | `<main>` element | h1, care dock, bottom nav, content sections |
| Settings | `<main>` element | h1, form fields, navigation links |
| Welcome/Landing | `<main>` element | h1, skip link, main content, navigation |

### Snapshot Update Workflow

1. Run tests with `--update-snapshots` flag when intentional changes are made
2. Review the diff in the snapshot file
3. Verify the change is intentional and correct
4. Commit the updated snapshot with the code change

```bash
pnpm exec playwright test --update-snapshots
```

## Implementation Pattern

### Basic Snapshot Test

```typescript
test("onboarding accessibility tree snapshot", async ({ page }) => {
  await page.goto(`${BASE_URL}/onboarding`, { waitUntil: "networkidle" });
  await page.waitForTimeout(1000); // Allow hydration

  const snapshot = await page.accessibility.snapshot({
    interestingOnly: true,
  });

  expect(snapshot).toMatchSnapshot('onboarding-a11y-tree.json');
});
```

### Targeted Snapshot Test

```typescript
test("care dock has correct accessible names", async ({ page }) => {
  await page.goto(`${BASE_URL}/today`, { waitUntil: "networkidle" });

  const careDock = page.locator('[aria-label="Log feed"]').locator('..');
  const snapshot = await careDock.accessibility.snapshot();

  expect(snapshot).toMatchSnapshot('care-dock-a11y-tree.json');
});
```

## Common Regressions Caught

| Regression | How Snapshot Catches It |
|---|---|
| Missing heading | Snapshot shows no heading role |
| Changed aria-label | Snapshot shows different name |
| Removed landmark | Snapshot missing main/nav region |
| Broken form association | Snapshot shows unlabeled input |
| Duplicate IDs | Snapshot shows merged/confused tree |

## Best Practices

1. **Use `interestingOnly: true`** — Filters out presentational elements
2. **Snapshot specific regions** — Don't snapshot the entire page; focus on meaningful sections
3. **Review diffs carefully** — ARIA snapshot changes should be intentional
4. **Keep snapshots small** — Large snapshots are hard to review and maintain
5. **Combine with axe-core** — Snapshots catch structural regressions; axe catches violations

## Related Patterns

- `a11y-production-gate.md` — Full accessibility gate definition
- `keyboard-navigation-smoke.md` — Keyboard-only navigation tests
- `screen-reader-smoke.md` — Screen reader verification
