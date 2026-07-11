# FEATURE-002 - Bounded backend capability

- Task type: FEATURE
- Repo: service repo
- Lane expectation: STANDARD
- Initial state: known runtime path

## Prompt
Add one narrow backend capability without changing external contracts unnecessarily.

## Expected outputs
- contract touch list
- targeted tests

## Expected files touched
- handler
- test

## Forbidden actions
- hidden broad refactor

## Pass conditions
- handler and tests agree
- rollback recipe exists

## Metrics captured
- rubric dimensions
