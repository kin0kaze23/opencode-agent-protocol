# Testing Rules — Auto-Activated

**Trigger:** Editing files matching `**/*.test.*`, `**/*.spec.*`, `**/tests/**`, `**/e2e/**`, `**/__tests__/**`, `**/test/**`

**Source:** Adapted from `.claude/rules/testing.md` + `.opencode/skills/testing/SKILL.md` + `.opencode/skills/testing-validation/SKILL.md`

---

## Temperature

Testing: **0.1** — test assertions must be deterministic and precise. No creative variance.

---

## Test Writing Rules

- One assertion per test (where practical) — tests should have a single failure reason
- Test names must describe the behaviour, not the implementation:
  - GOOD: `"returns 404 when user not found"`
  - BAD: `"test findUser with bad id"`
- Prefer real integrations over mocks for database tests where the test suite supports it
- Mock only: external APIs, time (use vi.useFakeTimers), random values (use seed)
- Never hard-code credentials or env vars in test files — use `.env.test` or test fixtures

## After Changes — Always Run Regression Check

After any code change, run the test suite for the changed module (not just the file you edited).
The `/gates` command runs the correct gate set for the active verification profile.

## Quality Gates for Test Work

```bash
# Run tests for a specific file
pnpm vitest run src/path/to/file.test.ts

# Run full suite
pnpm test

# Run with coverage (when checking coverage gaps)
pnpm test --coverage
```

## Project Test Stacks

| Project | Test runner | E2E |
|---------|-------------|-----|
| ClearPathOS | Vitest | Playwright |
| example-analyzer | Vitest | - |
| areté-life-os | - | Playwright |
| example-toolchain | - | Playwright |
| example-cli | `cargo test` | - |
| sample-service | - | - |

## Coverage Requirements

| Repo | Minimum | Target |
|------|---------|--------|
| sample-service | 40% unit + E2E critical | 60% |
| ClearPathOS | 60% unit + E2E core | 80% |
| areté-life-os | 50% unit + E2E | 70% |
| stillness | 30% unit | 50% |
| example-cli | 60% unit | 80% |

**No feature ships without tests.**

## Deterministic Verification

- Tests must NOT accept multiple status codes (e.g., `[200, 403]`) unless explicitly testing error handling
- Tests must NOT contain "may fail" or "expected (but might not work)" comments
- Tests must NOT use placeholder route parameters (e.g., literal `:id` strings instead of variables)
- Each test assertion must have ONE expected outcome
