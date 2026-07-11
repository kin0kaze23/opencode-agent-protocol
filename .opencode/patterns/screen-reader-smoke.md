# Screen Reader Smoke Test

> **Pattern:** `.opencode/patterns/screen-reader-smoke.md`
> **Version:** 1.0.0
> **Created:** 2026-05-22
> **Status:** Active

## Purpose

Defines the screen reader smoke test pattern for verifying that core user flows are usable with assistive technology. This pattern covers both automated Guidepup integration and manual screen reader verification workflows.

## When to Apply

Trigger when:
- New UI components ship to production
- Navigation or information architecture changes
- Form flows are added or modified
- Before any major release of a user-facing product

## Guidepup Integration

### What is Guidepup?

[Guidepup](https://github.com/guidepup/guidepup) is a Playwright-compatible library for automating screen readers:
- **macOS:** VoiceOver automation via Accessibility API
- **Windows:** NVDA automation via RPC

### Feasibility Assessment (2026-05-22)

| Platform | Status | Notes |
|---|---|---|
| macOS VoiceOver | **Feasible** | Requires macOS, VoiceOver enabled, accessibility permissions |
| Windows NVDA | **Feasible** | Requires Windows, NVDA installed |
| CI/CD | **Not recommended** | Screen reader automation requires real OS with accessibility stack |
| Linux | **Not supported** | Orca support is experimental |

### Current Decision

**Guidepup is optional/manual-release evidence only.** Do not make it mandatory in CI.

### Optional Integration Pattern

```typescript
// tests/e2e/a11y-screen-reader.spec.ts
import { test, expect } from '@playwright/test';
import { voiceOver } from '@guidepup/voiceover';

test.describe('Screen Reader Smoke Tests (macOS only)', () => {
  test.skip(process.platform !== 'darwin', 'VoiceOver requires macOS');

  test('onboarding flow is screen-reader accessible', async ({ page }) => {
    const vo = new voiceOver();
    await vo.start();

    await page.goto(`${BASE_URL}/onboarding`, { waitUntil: 'networkidle' });

    // VoiceOver should announce the page heading
    await vo.next();
    const heading = await vo.itemText();
    expect(heading).toContain('Welcome');

    // VoiceOver should announce form labels
    await vo.next();
    await vo.next();
    const formLabel = await vo.itemText();
    expect(formLabel).toContain('name');

    await vo.stop();
  });
});
```

## Manual Screen Reader Verification

### Required Manual Checks

When Guidepup is not available, perform these manual checks:

#### macOS VoiceOver

1. Enable VoiceOver: `Cmd + F5`
2. Navigate to the page
3. Verify:
   - [ ] Page heading is announced correctly
   - [ ] Skip link is announced and functional
   - [ ] Form fields have correct labels announced
   - [ ] Navigation landmarks are announced
   - [ ] Interactive elements have correct roles announced
   - [ ] Error states are announced (aria-live)
   - [ ] Toggle states are announced (aria-checked)

#### Windows NVDA

1. Start NVDA
2. Navigate to the page
3. Verify the same checklist as VoiceOver

### Manual Verification Template

```markdown
## Screen Reader Verification — [Page Name]
**Date:** YYYY-MM-DD
**Screen Reader:** VoiceOver / NVDA
**Browser:** Chrome / Safari / Firefox

### Results
- [ ] Page heading announced correctly
- [ ] Skip link functional
- [ ] Form labels correct
- [ ] Navigation landmarks announced
- [ ] Interactive elements correct
- [ ] Error states announced
- [ ] Toggle states announced

### Notes
[Any issues or observations]
```

## Automated Alternatives

When screen reader automation is not available, these automated checks provide partial coverage:

| Check | Tool | Coverage |
|---|---|---|
| ARIA tree structure | Playwright accessibility.snapshot | ~60% |
| Semantic violations | axe-core | ~30% |
| Keyboard navigation | Playwright keyboard tests | ~40% |
| Color contrast | axe color-contrast | ~20% |

**Combined automated coverage: ~70% of screen reader experience.**
The remaining 30% requires manual verification.

## Related Patterns

- `a11y-production-gate.md` — Full accessibility gate definition
- `keyboard-navigation-smoke.md` — Keyboard-only navigation tests
- `aria-snapshot-regression.md` — ARIA tree snapshot tests
