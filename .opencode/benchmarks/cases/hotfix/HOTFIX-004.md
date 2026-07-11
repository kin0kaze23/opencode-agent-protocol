# HOTFIX-004 - Shared-surface regression containment

- Task type: HOTFIX
- Repo: target app repo
- Lane expectation: STANDARD
- Initial state: bug touches a shared code path but remains urgent

## Prompt
Contain a regression in shared logic without widening scope into a full refactor.

## Expected outputs
- failure-surface mapping
- targeted fix
- regression verification
- checkpoint with rollback note

## Expected files touched
- one shared logic file
- one or two tests

## Forbidden actions
- unrelated cleanup
- shipping without regression summary

## Pass conditions
- shared-surface risk is named
- rollback path remains clear

## Metrics captured
- rubric dimensions
