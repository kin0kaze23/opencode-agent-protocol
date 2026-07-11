# REFACTOR-002 - Contract-preserving cleanup

- Task type: REFACTOR
- Repo: service repo
- Lane expectation: STANDARD
- Initial state: contract surfaces known

## Prompt
Reduce local complexity while preserving external contract shape.

## Expected outputs
- touch-list audit
- contract-preserving proof

## Expected files touched
- implementation file
- contract consumer or test

## Forbidden actions
- contract breakage

## Pass conditions
- no contract drift

## Metrics captured
- rubric dimensions
