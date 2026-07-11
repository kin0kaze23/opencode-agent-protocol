# ADR: APA Repo-Level Agent Exception

**Status:** Approved (Phase C1.5)
**Date:** 2026-05-23
**Context:** APA Digital Asset Product requires repo-specific agents that differ from workspace-level OpenCode agents.

## Problem

The repo-exception-guard (Guard 6) enforces that repo-level `.opencode/` directories contain only `hooks/` unless an approved exception ADR exists.

`apa-digital-asset-product/.opencode/` contains:
- `agents/` — 16 APA-specific agent definitions
- `commands/` — 6 APA factory commands
- `node_modules/`, `package.json`, `package-lock.json` — OpenCode plugin dependencies
- `.gitignore`

This violates the "hooks only" rule but is a legitimate exception.

## Decision

APA is approved as a repo-level agent exception under the following conditions:

### Allowed Contents

| Path | Purpose | Justification |
|---|---|---|
| `.opencode/agents/` | 16 APA-specific agents | APA requires domain-specific agents (blockchain/stablecoin, compliance/AML, treasury ops, etc.) that are fundamentally different from workspace-level agents |
| `.opencode/commands/` | 6 APA factory commands | APA has a custom "AI Product Factory" workflow with plan/gate/build/review/release commands |
| `.opencode/opencode.jsonc` | Repo-level OpenCode config | APA uses `bailian-coding-plan` provider directly with repo-specific agent definitions |
| `.opencode/node_modules/` | OpenCode plugin dependencies | Required for plugin auth |
| `.opencode/package.json` | Plugin dependency manifest | Required for plugin auth |
| `.opencode/package-lock.json` | Lockfile | Required for plugin auth |
| `.opencode/.gitignore` | Git ignore | Standard |

### Why Workspace Agents Are Insufficient

Workspace-level agents (orchestrator, explorer, planner, implementer, reviewer, architect, budget) are general-purpose coding agents. APA requires:

1. **Domain-specific expertise**: blockchain/stablecoin engineering, compliance/AML review, treasury operations, regulatory risk assessment
2. **Different permission model**: APA agents have `git_push: deny` and `deploy: deny` by default (sandbox-only, no real custody/wallet access)
3. **Custom workflow**: APA "AI Product Factory" lifecycle with plan → gate → build → review → release stages
4. **Provider isolation**: APA uses `bailian-coding-plan` provider directly, not the workspace's `opencode-go` routing

### Expiry/Review Condition

This exception expires when:
- APA migrates to the workspace-level agent model (if APA agents become generic enough), OR
- Phase C4 migration completes and the workspace authority model is re-evaluated

Review at next conformance suite run or when APA agent definitions change materially.

### Guard Update

The `repo-exception-guard.sh` must recognize `apa-digital-asset-product` as an approved exception. The guard should:
- PASS for all allowed contents listed above
- FAIL for any content NOT in the allowed list
- Continue to FAIL for any other repo with non-hook content (unless another ADR is created)

## Consequences

### Positive
- APA can maintain its domain-specific agent ecosystem without workspace-level interference
- Conformance suite recognizes the exception explicitly
- Exception is documented, time-bound, and reviewable

### Negative
- Sets precedent for repo-level agent exceptions
- Risk of other repos requesting similar exceptions
- APA agents may drift from workspace protocol standards over time

### Mitigation
- Exception is narrow (APA only, specific paths)
- Guard continues to enforce for all other repos
- Review condition ensures periodic re-evaluation

## References

- `.opencode/conformance/tests/repo-exception-guard.sh`
- `.opencode/policies/known-c0-drift.json`
- `apa-digital-asset-product/opencode.jsonc`
- `apa-digital-asset-product/.opencode/agents/` (16 files)
