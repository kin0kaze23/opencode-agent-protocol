---
description: "Auto-test generation — detect missing coverage, add focused tests, justify if skipped"
---

# /auto-test-generation

**Mode:** Executor
**Purpose:** Detect untested code in changed files, generate focused tests where practical, and justify when tests are skipped.

## When to Use

- After implementation is complete but before PR creation
- For FAST, STANDARD, and HIGH-RISK lanes
- DIRECT Lite: skip entirely

## Behaviour

When invoked, the Owner agent:

1. **Detect untested code:**
   ```bash
   bash .opencode/scripts/detect-untested.sh <repo> <changed-files>
   ```
   - Review: exported symbols, nearby tests, missing coverage, suggested test files
   - Classify change type: bug-fix / logic-change / refactor / ui-only / config

2. **Apply test generation rules based on change type:**

   | Change Type | Test Requirement | Action |
   |---|---|---|
   | Bug fix | Regression test required | Write a test that reproduces the bug, then verifies the fix |
   | Logic change | Unit or integration test required | Write a test that covers the new behavior |
   | Refactor | Existing tests or characterization tests | Run existing tests; if none exist, add characterization tests |
   | UI visual-only/style/copy | No test burden | No-test justification accepted |
   | Config tweak (non-runtime) | No test burden | No-test justification accepted |
   | HIGH-RISK | Full suite + reviewer | All tests must pass; reviewer verifies coverage |

3. **Generate focused tests (when required):**
   - Write tests that cover the specific changed behavior, not broad brittle tests
   - Test the public API, not implementation details
   - Include edge cases: empty input, null/undefined, boundary values
   - Keep tests small and readable
   - Place tests in the suggested test file path from detect-untested.sh
   - Use the project's test framework (vitest, jest, playwright, pytest, cargo test)

4. **Run targeted tests:**
   ```bash
   # If vitest/jest:
   pnpm test -- --grep <component-name>
   # If playwright:
   pnpm exec playwright test <test-file>
   # If pytest:
   pytest <test-file> -v
   ```
   - If tests pass: proceed to PR
   - If tests fail: fix the code or the test, re-run

5. **No-test justification (when tests are not practical):**
   ```
   Tests: not added — <specific reason>
   ```
   
   **Accepted justifications:**
   - `Tests: not added — visual-only CSS spacing change in single component. Existing visual harness not run locally.`
   - `Tests: not added — config value update with no logic impact. Build passes.`
   - `Tests: not added — typo fix in string literal. No behavior change.`
   - `Tests: not added — environment variable rename with no logic change. Build and lint pass.`
   
   **Rejected justifications:**
   - `Tests: not added — no tests needed` (too vague)
   - `Tests: not added — skip` (no reason)
   - `Tests: not added — not practical` (no specific reason)

6. **Report test generation summary:**
   ```
   Auto-Test Generation:
   Change type: <bug-fix / logic-change / refactor / ui-only / config>
   Symbols detected: <N>
   Symbols with coverage: <N>
   Symbols missing coverage: <N>
   Tests added: <yes — <file list> / no — <justification>>
   Test result: <pass / fail / not-run>
   ```

## DIRECT Lite Exception

DIRECT Lite tasks (risk 0, 1 file, no sensitive paths) skip auto-test generation entirely.
No test detection, no test generation, no justification needed.
This keeps trivial changes fast.

## HIGH-RISK Additional Rules

- Full test suite must pass before PR
- Reviewer must verify test coverage
- New tests must be reviewed for correctness
- No-test justification is NOT accepted for HIGH-RISK logic changes
- All exported symbols in changed files should have test coverage

## Do Not

- Write broad brittle tests that test everything
- Test implementation details instead of public API
- Skip test detection for STANDARD/HIGH-RISK
- Accept vague no-test justifications
- Disable tests to make CI pass
- Force test generation for DIRECT Lite trivial changes
- Generate tests for UI-only/style/copy changes
