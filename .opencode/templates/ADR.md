# Architecture Decision Record

Status: `<proposed | accepted | superseded | N/A>`
Mode: `<compact | full>`
Date: `<YYYY-MM-DD>`
Review date: `<YYYY-MM-DD or N/A>`

## Use

- Purpose: record decisions that shape architecture, runtime, schema, state, or cross-surface contracts.
- Required when: HIGH-RISK, hard-to-reverse, cross-surface, schema/state-model, runtime, or interface decisions are made.
- Mode guidance: compact mode records decision plus one alternative; full mode records alternatives, implications, and rollback path.
- Required evidence: current constraint, alternatives considered, reversibility, and review date.

## N/A rule

Use `N/A` only for local, reversible implementation details that do not affect architecture, schema, state model, runtime, or cross-surface contracts. Reason: `<specific reason>`. Risk if skipped: `<risk or none>`

## Context

`<problem, constraints, current behavior, and why a decision is needed>`

## Decision

`<chosen decision>`

## Alternatives considered

| Option | Pros | Cons | Why rejected/accepted |
|---|---|---|---|
| `<option>` | `<pros>` | `<cons>` | `<reason>` |

## Tradeoffs and consequences

- Tradeoffs: `<what improves and what gets harder>`
- Consequences: `<runtime, maintenance, migration, or user impact>`
- Observability implications: `<logs, metrics, traces, or N/A>`
- Cost implications: `<infra/vendor/dev cost or N/A>`
- Reliability implications: `<failure modes, fallback, durability or N/A>`

## Reversibility

- Reversibility: `<easy | moderate | hard>`
- Migration/rollback path:
  - Preconditions: `<what must be true>`
  - Action: `<how to reverse>`
  - Verify: `<how rollback success is confirmed>`
