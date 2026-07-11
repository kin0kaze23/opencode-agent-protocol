# Visual Quality Gate

> **Pattern:** `.opencode/patterns/visual-quality-gate.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines the visual quality gate that must pass before any UI change ships. This gate ensures that visual changes are intentional, evidence-backed, and do not regress the user experience.

## When to Apply

Trigger when:
- Any visual change is made (colors, spacing, typography, layout)
- New UI components or pages are added
- Responsive breakpoints are modified
- Animation or motion is added/changed
- Before any production deploy of a user-facing surface

## Gate Definition

### Required Checks (ALL must pass)

| Check | Tool | Pass Criteria |
|---|---|---|
| Visual snapshots | Playwright `toHaveScreenshot()` | All snapshots match or intentional diff approved |
| Multi-viewport | Playwright mobile/tablet/desktop | No layout breakage at any viewport |
| State coverage | Playwright | Loading, empty, error states verified |
| Accessibility preserved | axe-core | 0 new violations introduced |
| Performance budget | Lighthouse | Performance >= 85, no major regression |
| Executive rubric | Manual review | Score >= 80/100 |

### Visual Snapshot Rules

1. **Baseline first:** Before any visual change, capture baseline screenshots
2. **Intentional diffs only:** When snapshots fail, review the diff — accept only intentional changes
3. **Multi-viewport:** Capture at minimum 3 viewports:
   - Mobile: 390x844 (iPhone 14)
   - Tablet: 768x1024 (iPad)
   - Desktop: 1440x900
4. **State coverage:** Each page should have snapshots for:
   - Default/loaded state
   - Empty state (if applicable)
   - Loading state (if applicable)
   - Error state (if applicable)

### Implementation Pattern

```typescript
test("page visual snapshot — mobile", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto(`${BASE_URL}/target-page`, { waitUntil: "networkidle" });
  await page.waitForTimeout(1000); // Allow animations to settle
  await expect(page).toHaveScreenshot("target-page-mobile.png", {
    maxDiffPixels: 100,
    threshold: 0.1,
  });
});

test("page visual snapshot — tablet", async ({ page }) => {
  await page.setViewportSize({ width: 768, height: 1024 });
  await page.goto(`${BASE_URL}/target-page`, { waitUntil: "networkidle" });
  await page.waitForTimeout(1000);
  await expect(page).toHaveScreenshot("target-page-tablet.png", {
    maxDiffPixels: 100,
    threshold: 0.1,
  });
});

test("page visual snapshot — desktop", async ({ page }) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto(`${BASE_URL}/target-page`, { waitUntil: "networkidle" });
  await page.waitForTimeout(1000);
  await expect(page).toHaveScreenshot("target-page-desktop.png", {
    maxDiffPixels: 100,
    threshold: 0.1,
  });
});
```

### Screenshot Evidence Pack

For each visual change, produce an evidence pack:

```
artifacts/visual-review-v<N>/
├── before/
│   ├── onboarding-mobile.png
│   ├── today-mobile.png
│   └── today-seeded-mobile.png
├── after/
│   ├── onboarding-mobile.png
│   ├── today-mobile.png
│   └── today-seeded-mobile.png
└── diff/
    ├── onboarding-mobile-diff.png
    └── today-mobile-diff.png
```

## Related Patterns

- `screenshot-evidence-pack.md` — Evidence pack structure and workflow
- `executive-product-review-rubric.md` — Executive review scoring
- `a11y-production-gate.md` — Accessibility gate (must pass alongside visual gate)
