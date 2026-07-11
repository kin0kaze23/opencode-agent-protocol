---
name: testing-validation
description: QA workflows, test coverage minimums, and Playwright E2E patterns for all portfolio projects.
---

# Testing & Validation Skill

> This checked-in OpenCode skill is the live version for OpenCode sessions.

## Procedure

Before writing tests, read the following:

1. Read the target module/file to understand function signatures, types, and logic
2. Read the existing test directory to find 1-2 representative tests
3. Identify the testing framework (Jest, Vitest, Pytest, etc.)
4. Note the import style, assertion patterns, and fixture conventions used

Then write tests covering:
- Happy path (valid input produces expected output)
- Edge cases (empty, null, zero, max values, boundary conditions)
- Error cases (invalid input, missing data, network failures)
- Async behavior (if applicable, including timeouts and race conditions)

Match the exact import style and patterns from existing tests.
Run tests after writing them. Fix failures before finishing.

---

## Coverage Requirements

| Repo | Minimum | Target |
|------|---------|--------|
| sample-service | 40% unit + E2E critical | 60% |
| ClearPathOS | 60% unit + E2E core | 80% |
| areté-life-os | 50% unit + E2E | 70% |
| demo-project | 30% unit | 50% |
| example-cli | 60% unit | 80% |

**No feature ships without tests.**

---

## Gate Execution Order

```bash
# Always run in this order:
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

If ANY gate fails, fix before proceeding. Max 3 auto-fix retries per gate.

---

## Unit Test Template (Vitest)

```typescript
import { describe, it, expect, vi } from 'vitest';
import { functionToTest } from '../module';

describe('functionToTest', () => {
  it('returns expected result for valid input', () => {
    const result = functionToTest({ id: '123', name: 'test' });
    expect(result).toEqual({ success: true, data: expect.any(Object) });
  });

  it('throws for invalid input', () => {
    expect(() => functionToTest(null)).toThrow('Input required');
  });
});
```

---

## E2E Test Template (Playwright)

```typescript
import { test, expect } from '@playwright/test';

test('critical user flow: create and view item', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();

  await page.getByRole('button', { name: 'Create' }).click();
  await page.getByLabel('Name').fill('Test Item');
  await page.getByRole('button', { name: 'Save' }).click();

  await expect(page.getByText('Test Item')).toBeVisible();
});
```

---

## Accessibility Gate

```typescript
import AxeBuilder from '@axe-core/playwright';

test('page has no accessibility violations', async ({ page }) => {
  await page.goto('/dashboard');
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations).toEqual([]);
});
```

---

## Pre-Ship QA Checklist

- [ ] All unit tests pass
- [ ] E2E critical flows pass
- [ ] Accessibility scan clean
- [ ] No console errors in browser
- [ ] Mobile viewport tested
- [ ] Error states tested (network failure, 404, 500)
- [ ] Feature status JSON updated

## Output format

Produce a testing report in this exact format:

```
## Testing Report — <module/feature name>

**Framework:** <Vitest / Jest / Pytest / Playwright / etc>
**Coverage:** <percentage or "not measured">

### Tests written
- <test file>: <test name> — <what it verifies>
- <test file>: <test name> — <what it verifies>

### Test results
- Unit tests: <pass/fail count>
- E2E tests: <pass/fail count>
- Coverage: <percentage>

### Gate results
- lint: <PASS/FAIL>
- typecheck: <PASS/FAIL>
- test: <PASS/FAIL>
- build: <PASS/FAIL>
```

## Out of Scope

This skill does NOT:
- Write production code (that is /implement)
- Fix failing tests caused by broken production code (that is /debug)
- Replace security testing for auth/payment paths (use security/SKILL.md)
- Generate test data or fixtures for external services (use mocks)
- Audit test coverage without running the test suite (that is /gates)
