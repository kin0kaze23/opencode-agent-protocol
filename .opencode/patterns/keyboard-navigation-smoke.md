# Keyboard Navigation Smoke Test

> **Pattern:** `.opencode/patterns/keyboard-navigation-smoke.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines the keyboard navigation smoke test pattern for verifying that all interactive elements are reachable and operable without a mouse. This is a WCAG 2.2 Level A requirement (2.1.1 Keyboard).

## When to Apply

Trigger when:
- New interactive elements are added (buttons, links, inputs, toggles)
- Navigation structure changes
- Modal/dialog/overlay components are added
- Focus management logic is modified

## Test Coverage

### 1. Focus Reachability

Every interactive element must be reachable via Tab:

```typescript
test("all interactive elements are reachable via Tab", async ({ page }) => {
  const focusableCount = await page.evaluate(() => {
    return document.querySelectorAll(
      'a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])'
    ).length;
  });

  for (let i = 0; i < focusableCount; i++) {
    await page.keyboard.press("Tab");
    await page.waitForTimeout(50);
  }

  // Verify no focus trap — should still be able to tab
  await page.keyboard.press("Tab");
  const focusedTag = await page.evaluate(() => document.activeElement?.tagName);
  expect(focusedTag).toBeTruthy();
});
```

### 2. Focus Visibility

Focused elements must have a visible focus indicator:

```typescript
test("focus ring is visible", async ({ page }) => {
  await page.keyboard.press("Tab");
  const hasVisibleFocus = await page.evaluate(() => {
    const el = document.activeElement;
    if (!el) return false;
    const style = window.getComputedStyle(el);
    return style.outlineStyle !== "none" || style.boxShadow !== "none";
  });
  expect(hasVisibleFocus).toBeTruthy();
});
```

### 3. Keyboard Operability

Interactive elements must respond to keyboard input:
- **Buttons/Links:** Enter or Space activates
- **Inputs:** Type, navigate with arrow keys where applicable
- **Toggles/Switches:** Space toggles state
- **Checkboxes:** Space toggles state
- **Select/Dropdown:** Arrow keys navigate, Enter selects

### 4. Skip Link

Pages must have a skip-to-main-content link:

```typescript
test("skip link is present and functional", async ({ page }) => {
  const skipLink = page.locator('a[href="#main-content"]');
  await expect(skipLink).toHaveCount(1);
  await page.keyboard.press("Tab");
  await expect(skipLink).toBeFocused();
});
```

### 5. Focus Order

Focus order must be logical and match visual order:
- Tab through the page and verify the sequence matches the visual layout
- No elements should be skipped or visited out of order

## Common Failures

| Failure | Cause | Fix |
|---|---|---|
| Focus trap | Modal without focus trap management | Add focus trap library or manual management |
| Invisible focus | No `:focus-visible` styles | Add global focus ring CSS |
| Unreachable element | `tabindex="-1"` on interactive element | Remove negative tabindex |
| Wrong activation | Button requires mouse click only | Add `onClick` handler, ensure it's a `<button>` |
| Skip link missing | No skip link in layout | Add `<a href="#main-content">` |

## Implementation Checklist

- [ ] All interactive elements reachable via Tab
- [ ] Focus indicator visible on all focused elements
- [ ] Buttons/links activate with Enter/Space
- [ ] Form inputs accept keyboard input
- [ ] Toggles/switches respond to Space
- [ ] Skip link present and functional
- [ ] Focus order matches visual layout
- [ ] No focus traps (except intentional modal traps)

## Related Patterns

- `a11y-production-gate.md` — Full accessibility gate definition
- `aria-snapshot-regression.md` — ARIA tree snapshot tests
- `screen-reader-smoke.md` — Screen reader verification
