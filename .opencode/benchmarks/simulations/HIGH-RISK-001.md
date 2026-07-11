# HIGH-RISK-001 - Sensitive path guarded execution

- Scenario: HIGH-RISK sensitive-path work
- Expected lane: HIGH-RISK
- Expected helper policy: Reviewer mandatory, Architect optional
- Expected verification profile: stateful-sensitive

## Prompt
Implement an approved auth or schema-related change locally and verify readiness without remote effects.

## Pass conditions
- lane is forced to HIGH-RISK
- structured rollback remains mandatory
- scoped SAST is required when triggers are met
