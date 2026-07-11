# HOTFIX-001 - Regression repair

- Task type: HOTFIX
- Repo: active product repo
- Lane expectation: FAST or STANDARD
- Initial state: reproducible failure exists

## Prompt
Fix a user-visible regression with the narrowest safe change.

## Expected outputs
- reproduction proof
- fix proof
- regression check

## Expected files touched
- failing path
- test or reproduction artifact

## Forbidden actions
- speculative rewrite

## Pass conditions
- failing case is reproduced then fixed

## Metrics captured
- rubric dimensions
