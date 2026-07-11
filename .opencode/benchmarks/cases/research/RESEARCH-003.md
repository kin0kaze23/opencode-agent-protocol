# RESEARCH-003 - Internal pattern scan

- Task type: RESEARCH
- Repo: target app repo
- Lane expectation: FAST
- Initial state: question is answerable from local repo evidence

## Prompt
Map the existing local patterns for a feature class and recommend the narrowest consistent next step.

## Expected outputs
- repo evidence
- recommendation with alternatives when warranted
- no code changes

## Expected files touched
- none

## Forbidden actions
- implementation without approval
- unsupported ecosystem claims without explicit external-scan path

## Pass conditions
- recommendation is evidence-backed
- no fake implementation claims

## Metrics captured
- rubric dimensions
