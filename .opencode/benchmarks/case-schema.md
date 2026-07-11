# Benchmark Case Schema

Use this shape for each benchmark case:

```md
# <TASK-ID> - <short name>

- Task type:
- Repo:
- Lane expectation:
- Initial state:

## Prompt
<user request or fixture prompt>

## Expected outputs
- ...

## expected files touched
- ...

## Forbidden actions
- ...

## Pass conditions
- ...

## Metrics captured
- correctness
- safety
- completeness
- efficiency
- reversibility
- operator_burden
- evidence_quality
```
