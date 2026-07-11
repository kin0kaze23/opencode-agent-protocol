# REFACTOR-004 - Multi-file contract-preserving cleanup

- Task type: REFACTOR
- Repo: target app repo
- Lane expectation: STANDARD
- Initial state: approved cleanup slice with explicit out-of-scope

## Prompt
Perform a modest multi-file cleanup that preserves behavior and improves readability or structure.

## Expected outputs
- contract-first implementation
- gate pass
- review if risk requires it
- checkpoint

## Expected files touched
- two to four related files

## Forbidden actions
- hidden interface changes
- undocumented touch-list expansion

## Pass conditions
- cleanup remains reversible
- change stays behavior-preserving

## Metrics captured
- rubric dimensions
