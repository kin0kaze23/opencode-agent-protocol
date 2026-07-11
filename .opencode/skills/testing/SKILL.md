---
name: testing
description: Testing best practices for React, Node.js, Rust projects — unit tests, integration tests, TDD
---

# Testing Skill

Comprehensive testing guide for all portfolio projects.

## Procedure

Before writing tests, read the following:

1. Read the target module to understand function signatures, types, and logic
2. Read the repo's `package.json` to confirm the testing framework and scripts
3. Read 1-2 existing test files to match the project's conventions (import style, assertions, fixtures)
4. Read the test directory structure to understand where tests should live

Then write tests using the AAA pattern (Arrange, Act, Assert) and follow the conventions below.
Run tests after writing them. Fix failures before finishing.

---

## Prerequisites

```bash
# Install testing tools based on project
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom
# For E2E
npm install -D @playwright/test
```

## Testing Strategy by Project

### React/Vite Projects (Areté, demo-project, StableVault)
- **Unit**: Vitest + React Testing Library
- **E2E**: Playwright
- **Coverage**: 80% minimum

### Next.js Projects (ClearPathOS)
- **Unit**: Vitest + React Testing Library
- **E2E**: Playwright
- **Component**: Storybook with controls

### Express Backends (sample-service, example-analyzer, example-dashboard)
- **Unit**: Vitest
- **Integration**: Supertest
- **DB**: Test containers or mocks

### Rust Projects (example-cli)
- **Unit**: `cargo test`
- **Integration**: Integration tests in `tests/` dir

## Test File Convention

```
src/
├── components/
│   └── Button.test.tsx
├── hooks/
│   └── useAuth.test.ts
├── utils/
│   └── format.test.ts
__tests__/
├── api/
│   └── user.test.ts
e2e/
└── login.spec.ts
```

## Running Tests

```bash
# Unit tests
npm run test

# Watch mode
npm run test:watch

# Coverage
npm run test:coverage

# E2E
npx playwright test

# All projects
npm run test:all
```

## Quality Gates

| Project | Min Coverage | Required |
|---------|-------------|----------|
| React/Vite | 70% | ✅ |
| Next.js | 75% | ✅ |
| Express | 80% | ✅ |
| Rust | 80% | ✅ |

## Key Patterns

### Test AAA Pattern
```typescript
test('should login user', () => {
  // Arrange
  const user = { email: 'test@example.com', password: 'password' }

  // Act
  const result = login(user)

  // Assert
  expect(result.token).toBeDefined()
})
```

### Mocking Fetch/API
```typescript
vi.mock('@/lib/api', () => ({
  fetchUser: vi.fn().mockResolvedValue({ id: '1', name: 'Test' })
}))
```

### Testing Hooks
```typescript
const { result } = renderHook(() => useAuth())
act(() => { result.current.login('test', 'pass') })
expect(result.current.user).toBeDefined()
```

## CI Integration

```yaml
# GitHub Actions
- run: npm run test:coverage
  with:
    coverage_threshold: 70
```

## When to Write Tests

- ✅ New feature implementation
- ✅ Bug fix (regression prevention)
- ✅ Refactoring (ensure behavior preserved)
- ❌ UI tweaks without logic change
- ❌ Documentation only

## Output format

Produce a testing report in this exact format:

```
## Testing Report — <module/feature name>

**Framework:** <Vitest / Jest / Playwright / cargo test>
**Test file:** <path to new or modified test file>

### Tests written
- <test name> — <what it verifies>
- <test name> — <what it verifies>

### Test results
- Total: <count>
- Passed: <count>
- Failed: <count>
- Coverage: <percentage>

### Gate result
- test: <PASS/FAIL>
```

## Out of Scope

This skill does NOT:
- Write production code (that is /implement)
- Fix failing tests caused by broken production code (that is /debug)
- Replace browser verification for UI changes (that is webapp-testing/SKILL.md)
- Run accessibility audits (that is accessibility-audit/SKILL.md)
- Replace E2E test suites in CI/CD (that is /gates)
- Audit test coverage without running the test suite