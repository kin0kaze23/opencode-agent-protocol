# Visual Regression Maintenance

> **Runbook:** `.opencode/runbooks/visual-regression-maintenance.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Tells future agents how to maintain visual snapshot baselines, handle dynamic content, update screenshots intentionally, and avoid false positives in visual regression testing.

## Baseline Management

### When to Capture Baselines

1. **First run:** Baselines are captured automatically on first run with `--update-snapshots`
2. **After intentional visual change:** Update baselines with explicit rationale
3. **After adding new route:** Add snapshot tests and capture baselines
4. **Never:** Update baselines without reviewing the diff first

### How to Update Baselines

```bash
# Update baselines for specific pages
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --update-snapshots --grep "page-name"

# Verify updated baselines pass
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --grep "page-name"
```

### Baseline Review Checklist

Before updating baselines:
- [ ] Review the diff image (Playwright generates it in `test-results/`)
- [ ] Confirm changes are intentional
- [ ] Confirm no accessibility regressions
- [ ] Confirm no layout breakage
- [ ] Document rationale in commit message

## Handling Dynamic Content

### Problem

Some pages have dynamic content that changes between runs:
- Dates (e.g., "Week 3", "3 weeks old")
- User-specific data (e.g., baby name, log counts)
- Time-based content (e.g., "Last log at 2:30 PM")
- Random or seeded content

### Solutions

#### 1. Seed Data for Consistency

```typescript
async function seedProfile(page: Page) {
  await page.evaluate(() => {
    // Seed with fixed data
    indexedDB.open("protected-repo").then(db => {
      db.transaction("profile", "readwrite")
        .objectStore("profile")
        .put({
          id: "test-visual",
          localKey: "current",
          name: "Baby",  // Fixed name
          dateOfBirth: "2026-05-01",  // Fixed date
          // ... other fixed fields
        });
    });
  });
}
```

#### 2. Mask Dynamic Elements

```typescript
await expect(page).toHaveScreenshot("page.png", {
  mask: [page.locator(".dynamic-date")],  // Mask dynamic elements
  maxDiffPixels: 100,
  threshold: 0.1,
});
```

#### 3. Use `animations: "disabled"`

```typescript
await expect(page).toHaveScreenshot("page.png", {
  animations: "disabled",  // Disable animations for consistency
  caret: "hide",           // Hide text caret
});
```

#### 4. Wait for Hydration

```typescript
await page.waitForTimeout(1000);  // Allow hydration to complete
await expect(page).toHaveScreenshot("page.png");
```

## False Positive Prevention

### Common Causes

| Cause | Solution |
|---|---|
| Animations not settled | Add `waitForTimeout(1000)` before screenshot |
| Font loading | Wait for `document.fonts.ready` |
| Dynamic content | Seed data or mask elements |
| Viewport mismatch | Use fixed viewport sizes |
| Theme changes | Ensure consistent theme state |
| Network requests | Wait for `networkidle` |

### Snapshot Settings

```typescript
const SNAPSHOT_OPTIONS = {
  maxDiffPixels: 100,        // Allow minor pixel differences
  threshold: 0.1,            // 10% color difference threshold
  animations: "disabled",    // Disable animations
  caret: "hide",             // Hide text caret
  scale: "device",           // Use device pixel ratio
};
```

## Adding New Snapshot Tests

### Template

```typescript
test.describe("New Page", () => {
  test.beforeEach(async ({ page }) => {
    await seedProfile(page);  // If needed
  });

  for (const [viewport, size] of Object.entries(VIEWPORTS)) {
    test(`page-name — ${viewport}`, async ({ page }) => {
      await page.setViewportSize(size);
      await page.goto(`${BASE_URL}/page-name`, { waitUntil: "networkidle" });
      await page.waitForTimeout(1000);
      await expect(page).toHaveScreenshot(`page-name-${viewport}.png`, SNAPSHOT_OPTIONS);
    });
  }
});
```

### Viewport Matrix

| Viewport | Width | Height | Device Target |
|---|---|---|---|
| Mobile | 390px | 844px | iPhone 14 |
| Tablet | 768px | 1024px | iPad |
| Desktop | 1440px | 900px | Standard laptop |

**Minimum:** Mobile viewport required for all pages.
**Recommended:** All 3 viewports for core pages.

## CI/CD Integration

### Local Development

```bash
# Run visual snapshots
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts

# Update baselines (with review)
pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts --update-snapshots
```

### CI Pipeline (Future)

```yaml
# Example CI step
- name: Visual regression tests
  run: pnpm exec playwright test tests/e2e/visual-snapshots.spec.ts
  env:
    BASE_URL: http://localhost:3000
```

### Baseline Storage

- Baselines are stored in `tests/e2e/visual-snapshots.spec.ts-snapshots/`
- Committed to git alongside test code
- Review diffs in PR before merging

## Maintenance Schedule

| Frequency | Action |
|---|---|
| Per visual change | Review diff, update baselines if intentional |
| Weekly | Re-run full visual snapshot suite |
| Per release | Capture production baselines |
| Per new route | Add snapshot tests and capture baselines |

## Troubleshooting

### Snapshots Fail Unexpectedly

1. Check if dynamic content changed (dates, user data)
2. Check if animations didn't settle (increase `waitForTimeout`)
3. Check if viewport changed (verify config)
4. Check if theme changed (verify state)
5. Review diff image to identify the change

### Snapshots Always Fail

1. Verify dev server is running on correct port
2. Verify `BASE_URL` environment variable
3. Check for hydration errors in console
4. Verify page loads correctly in browser
5. Check if page requires authentication/seed data

### Baselines Out of Date

1. Review each failing snapshot diff
2. Update baselines for intentional changes
3. Fix code for unintentional changes
4. Re-run to verify all pass

## Related Documents

- `visual-quality-gate.md` — Visual quality gate definition
- `screenshot-evidence-pack.md` — Evidence pack structure
- `daily-agent-gate-tiers.md` — Gate tier definitions
- `daily-ui-agent-workflow.md` — Daily UI agent workflow
