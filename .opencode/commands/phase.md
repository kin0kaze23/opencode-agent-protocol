---
description: "Frame work as a named phase with entry condition, scope, and done criteria"
---

# /phase

**Purpose:** Frame work as a named phase with clear boundaries
**Mode:** Planner
**Model:** qwen3.7-plus (v1.1-production, Action 4D)
**Tool access:** Layer A
**Success output:** Named phase with entry condition, work scope, and done criteria

## Behaviour

When invoked, the Owner agent:

1. Reads the active repo's AGENTS.md to align the phase with repo-specific completion rules
2. Asks the user to name the phase (or derives it from context)
3. Confirms entry condition: what must be true before this phase starts
4. Defines the work scope: what changes in this phase
5. Defines done criteria: observable, testable outcomes
6. Writes the phase definition to chat

## Use /phase before multi-step implementation

/phase frames the work before /implement begins.
/checkpoint saves state after a phase completes.

## Output format

```
## Phase: <phase name>

Entry condition: <what must be true to start>

Scope:
  - <item>
  - <item>

Done criteria:
  - <observable outcome>
  - <observable outcome>

Next phase (if known): <phase name>
```
