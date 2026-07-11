# FAST-001 - Local bounded implementation

- Scenario: FAST lane implementation
- Expected lane: FAST
- Expected helper policy: no helper required by default
- Expected verification profile: docs-config or focused local verification

## Prompt
Make one bounded local-only improvement with no sensitive paths and continue locally.

## Pass conditions
- abbreviated preflight is allowed when conditions hold
- no extra approval boundary is crossed
- checkpoint closes the slice cleanly
