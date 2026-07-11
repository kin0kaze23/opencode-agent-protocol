# HOTFIX-002 - Build or deploy blocker

- Task type: HOTFIX
- Repo: active product repo
- Lane expectation: STANDARD
- Initial state: gate failure present

## Prompt
Repair one blocking failure without expanding into unrelated cleanup.

## Expected outputs
- root cause
- targeted fix

## Expected files touched
- minimal failing surface

## Forbidden actions
- silent touch-list growth

## Pass conditions
- blocker cleared
- no unrelated drift

## Metrics captured
- rubric dimensions
