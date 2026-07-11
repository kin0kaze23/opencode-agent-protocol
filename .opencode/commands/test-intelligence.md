---
description: "Test intelligence — discover tests, apply test expectations, generate or justify"
---

# /test-intelligence

**Mode:** Executor
**Purpose:** Discover nearby tests for changed files, apply test expectation rules, and ensure tests are added or justified before PR.

## When to Use

- After candidate files are identified (post code-index search)
- Before implementation begins
- For FAST, STANDARD, and HIGH-RISK lanes
- DIRECT Lite: skip unless target file is unknown

## Behaviour

When invoked, the Owner agent:

1. **Run test discovery:**
   ```bash
   bash .opencode/scripts/find-tests.sh <repo> <changed-file-1> [changed-file-2...]
   ```
   - Review output: framework, test command, nearby tests, coverage status, missing tests

2. **Classify change type:**
   | Change Type | Test Requirement |
   |---|---|
   | Bug fix | Regression test required — reproduce the bug, then verify fix |
   | Logic change | Unit or integration test required — test the new behavior |
   | Refactor | Existing tests must pass — or add characterization tests |
   | UI visual-only/style/copy | No test burden — no-test justification accepted |
   | Config tweak (non-runtime) | No test burden — no-test justification accepted |
   | HIGH-RISK (auth/schema/migration) | Full test suite + reviewer required |

3. **Apply test expectation:**
   - If tests exist nearby: run them, verify they pass, update if behavior changed
   - If tests are missing and change type requires tests: add or update tests
   - If no tests are needed: provide specific no-test justification

4. **No-test justification format (when tests are not added):**
   ```
   Tests: not added — <specific reason>
   ```
   
   **Bad justification:**
   ```
   Tests: not added — no tests needed
   ```
   
   **Good justifications:**
   ```
   Tests: not added — visual-only CSS spacing change in single component. Existing visual harness not run locally.
   Tests: not added — config value update with no logic impact. Build passes.
   Tests: not added — typo fix in string literal. No behavior change.
   ```

5. **Run targeted tests when available:**
   ```bash
   # If vitest/jest:
   pnpm test -- --grep <component-name>
   # If playwright:
   pnpm exec playwright test <test-file>
   # If pytest:
   pytest <test-file> -v
   ```

6. **Report test intelligence summary:**
   ```
   Test Intelligence:
   Framework: <vitest/jest/playwright/pytest/cargo/unknown>
   Test command: <command>
   Nearby tests: <list or none>
   Coverage: <covered/uncovered> for <N> changed files
   Tests added: <yes — <file list> / no — <justification>>
   Test result: <pass/fail/not-run>
   ```

## DIRECT Lite Exception

DIRECT Lite tasks (risk 0, 1 file, no sensitive paths) skip test intelligence entirely.
No test discovery, no test expectation, no justification needed.
This keeps trivial changes fast.

## HIGH-RISK Additional Rules

- Full test suite must pass before PR
- Reviewer must verify test coverage
- New tests must be reviewed for correctness
- No-test justification is NOT accepted for HIGH-RISK logic changes

## Do Not

- Skip test discovery for STANDARD/HIGH-RISK
- Accept vague no-test justifications
- Disable tests to make CI pass
- Add tests that don't actually test the changed behavior
- Force test generation for DIRECT Lite trivial changes
