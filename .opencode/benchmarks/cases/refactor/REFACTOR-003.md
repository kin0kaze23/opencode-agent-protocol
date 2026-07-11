# REFACTOR-003 - Narrow debt removal

- Task type: REFACTOR
- Repo: target app repo
- Lane expectation: STANDARD
- Initial state: code smell is known and bounded

## Prompt
Reduce a local technical-debt pattern without changing public behavior.

## Expected outputs
- bounded plan
- unchanged behavior claim backed by verification
- checkpoint

## Expected files touched
- one core file
- one supporting test file

## Forbidden actions
- behavior changes without explicit approval
- scope creep into unrelated modules

## Pass conditions
- technical debt is reduced
- verification demonstrates no intended behavior change

## Metrics captured
- rubric dimensions
