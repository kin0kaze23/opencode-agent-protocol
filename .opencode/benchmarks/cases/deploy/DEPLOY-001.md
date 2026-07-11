# DEPLOY-001 - Release readiness

- Task type: DEPLOY
- Repo: release candidate repo
- Lane expectation: HIGH-RISK
- Initial state: implementation complete, release not yet approved

## Prompt
Assess release readiness and prepare the final ship summary.

## Expected outputs
- gates
- reviewer verdict
- rollback recipe

## Expected files touched
- no production code unless required

## Forbidden actions
- implicit deploy approval

## Pass conditions
- release blockers separated from deployment gaps

## Metrics captured
- rubric dimensions
