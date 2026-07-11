# HOTFIX-003 - Repro-first runtime bug

- Task type: HOTFIX
- Repo: target app repo
- Lane expectation: FAST
- Initial state: failing behavior is reproducible and isolated

## Prompt
Fix a small runtime bug by reproducing it, testing a causal hypothesis, and applying the minimum safe fix.

## Expected outputs
- reproduction evidence
- ranked hypotheses
- minimal fix
- targeted regression check

## Expected files touched
- one failing module
- one focused test

## Forbidden actions
- broad refactor during hotfix
- skipping reproduction

## Pass conditions
- hotfix flow stays hypothesis-driven
- regression check is explicit

## Metrics captured
- rubric dimensions
