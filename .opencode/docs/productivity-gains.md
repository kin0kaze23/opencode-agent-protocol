# Productivity Gains Registry

> **Purpose:** Searchable catalog of reusable OpenCode productivity gains — workflows, capabilities, guardrails, and references the orchestrator can recommend.
> **Version:** v0.2
> **Created:** 2026-06-12
> **Status:** Advisory only (no runtime integration)
> **Owner Approval Required:** Yes — low-risk approval (documentation + YAML only, no runtime integration)
> **Last Updated:** 2026-06-13

---

## Authority Model

| Layer | Location | Authority | Purpose |
|-------|----------|-----------|---------|
| Runtime Implementation | `.opencode/scripts/`, `.opencode/commands/`, `.opencode/conformance/` | runtime_authoritative | Active code the orchestrator can invoke |
| Human-Readable Docs | `.opencode/docs/` | semi_authoritative | Current protocol documentation for humans |
| Machine-Readable Index | `.opencode/registry/` | advisory (semi_authoritative when integrated) | Structified indexes for AI consumption |
| Vault Archive | `vault/` | advisory | Historical reference, lessons, knowledge, archive |

**Key rule:** `.opencode/` is the single canonical source for active protocol state. `vault/` is documentation and history. Never mirror full content between them.

---

## How to Browse

### For Humans

1. Start here (`.opencode/docs/productivity-gains.md`)
2. Browse by category using the table of contents below
3. Each gain includes: name, scenario, trigger phrases, files, maturity, risks
4. Supporting references are listed separately at the bottom
5. Deprecated items are listed in a collapsed section

### For AI Agents

1. Match trigger phrases from user intent against the YAML registry (`.opencode/registry/productivity-gains.yaml`)
2. Filter by type: prefer `active_workflow` > `maintenance_capability` > `knowledge_reference`
3. Filter by category: match task domain
4. Filter by maturity: prefer `production` > `canary` > `experimental`
5. Check `use_when` / `do_not_use_when` conditions
6. Cite the gain with id, name, and files

### Stale/Duplicate Prevention

- Each gain has a unique `id` (PGR-XXX format)
- Each gain has `last_verified` date
- Gains older than 90 days without verification get flagged
- New gains must not duplicate existing gains (check by name and scenario)
- Deprecated gains are marked with `status: deprecated` and not recommended

---

## Core Active Productivity Gains (20 items)

These are workflows the orchestrator can recommend when matching conditions are detected.

### Runtime Maintenance

| ID | Name | Scenario | Trigger | Maturity |
|----|------|----------|---------|----------|
| PGR-001 | Protocol Doctor Health Check | Quick health check of workspace protocol state | "check protocol health", "protocol status" | production |
| PGR-016 | Global Runtime Sync | After any agent spec or orchestrator prompt change | "sync runtime", "update prompts" | production |

### Model Lifecycle

| ID | Name | Scenario | Trigger | Maturity |
|----|------|----------|---------|----------|
| PGR-017 | Model Upgrade Evaluation | Evaluating a new model for production use | "evaluate new model", "model canary" | production |

### Project Bootstrap

| ID | Name | Scenario | Trigger | Maturity |
|----|------|----------|---------|----------|
| PGR-003 | Bootstrap New Repo | After cloning or initializing a new repo | "new repo", "bootstrap" | production |

### Implementation Workflow

| ID | Name | Scenario | Trigger | Maturity |
|----|------|----------|---------|----------|
| PGR-007 | Scoped Implementation | Executing an approved plan with touch list | "implement", "execute plan" | production |

### Development Workflow

| ID | Name | Scenario | Trigger | Maturity |
|----|------|----------|---------|----------|
| PGR-009 | Structured Debugging | Bug triage with root-cause analysis | "debug", "fix bug" | production |
| PGR-010 | Feature Planning | Creating a feature plan with risk assessment | "plan feature", "create plan" | production |

### Release Deployment

| ID | Name | Scenario | Trigger | Maturity |
|----|------|----------|---------|----------|
| PGR-004 | Safe Deployment Rollback | Production incident or failed deploy | "rollback", "deploy failed" | production |
| PGR-005 | Release Ship Workflow | Ready to create PR and prepare release | "ship", "create PR" | production |

### Safety Guardrails

| ID | Name | Scenario | Trigger | Maturity |
|----|------|----------|---------|----------|
| PGR-013 | GitGuard Safety System | Any git operation (commit, push) | Automatic (wrapper enforcement) | production |
| PGR-014 | Empty Response Guardrail | Model returns empty/whitespace-only response | Automatic detection | production (sealed) |
| PGR-015 | Phase M1 Pre-Edit Safety Classifier | Before any file edit in /implement | Automatic (part of /implement) | active |

### Validation Quality

| ID | Name | Scenario | Trigger | Maturity |
|----|------|----------|---------|----------|
| PGR-002 | Workspace Protocol Guard | Before/after workspace-level agent/runtime edits | "protocol guard", "validate workspace" | production |
| PGR-011 | Quality Gate Sequence | Running validation gates before commit or ship | "run gates", "quality gates" | production |
| PGR-018 | Pre-Commit Failure Triage | When a pre-commit hook fails | "pre-commit failure", "hook failed" | production |
| PGR-020 | Daily UI Agent Workflow | Starting any UI/visual/component task | "UI task", "visual work" | production |

### Session Continuity

| ID | Name | Scenario | Trigger | Maturity |
|----|------|----------|---------|----------|
| PGR-006 | Session Checkpoint | End of session, phase completion, or interruption | "checkpoint", "save progress" | production |
| PGR-008 | Session Recovery | Drifted session or "where were we?" | "recover", "where were we" | production |
| PGR-012 | Compaction Safeguard | High token usage triggers compaction | Automatic (token threshold) | production |

### Runtime Maintenance (Vault Reference)

| ID | Name | Scenario | Trigger | Maturity |
|----|------|----------|---------|----------|
| PGR-019 | Prompt Change Acceptance | Making prompt changes with proper evidence | "prompt change", "baseline refresh" | production |

---

## Maintenance Capabilities (1 item)

These are maintenance tools the orchestrator can recommend when conditions are detected.

| ID | Name | Scenario | Trigger | Maturity |
|----|------|----------|---------|----------|
| PGR-M01 | Vault Keeper Maintenance Agent | Proactive vault maintenance (daily/weekly) | "vault maintenance", "vault health" | production |

---

## Supporting References (8 items)

These are documentation the orchestrator can cite for context but should not recommend as active workflows.

### Knowledge References

| ID | Name | Type | Purpose |
|----|------|------|---------|
| PGR-R01 | Protocol Changelog | historical_reference | Understanding protocol evolution and version decisions |
| PGR-R02 | Model Routing Documentation | knowledge_reference | Understanding current routing, blocked models, efficiency rules |
| PGR-R03 | Conformance Guards Documentation | knowledge_reference | Understanding the 7 conformance guards, 320 assertions, failure triage |
| PGR-R04 | Consolidated Lessons | knowledge_reference | Learning from past mistakes across 15+ repos |
| PGR-R05 | Daily Workflow Runbook (Vault) | knowledge_reference | Daily startup sequence, model selection, common commands |

### Setup References

| ID | Name | Type | Purpose |
|----|------|------|---------|
| PGR-021 | Protocol Replication Guide | supporting_reference (setup reference) | Replicating the v4.12.0 protocol to a new workspace |
| PGR-022 | New Device Setup | supporting_reference (setup reference) | Setting up the workspace on a new device |

### Operations References

| ID | Name | Type | Purpose |
|----|------|------|---------|
| PGR-M02 | Automation Jobs Registry | operations reference | Understanding all active automation jobs and their health |

---

## Planned / Experimental Active Gains (2 items)

These gains are planned but not yet runtime-implemented. They should not be recommended as executable workflows until their scripts exist and pass validation.

| ID | Name | Scenario | Trigger | Maturity | Status |
|----|------|----------|---------|----------|--------|
| PGR-023 | Provider Availability / Quota Preflight | Before model evals, routing changes, or long agent tasks | "check quota", "provider available", "API reachability" | canary | canary |
| PGR-024 | Scoped Commit-Readiness Check | Before committing in dirty workspaces, verify only intended files staged | "commit readiness", "scoped commit", "dirty workspace commit" | canary | canary |

> **Note:** PGR-023 v0.1 script (`.opencode/scripts/provider-preflight.sh`) exists and supports OpenCode Go reachability-only mode. Smoke completion is deferred. Advisory/canary — not wired into orchestrator or commands yet. Motivated by MiMo-V2.5 eval blocked by OpenCode Go HTTP 429 quota exhaustion (2026-06-13).

> **Note:** PGR-024 is a workflow pattern (no dedicated script) — uses standard git commands for scoped commit-readiness verification. First governed candidate proposal, added via PGR Maintenance Workflow v0.1 (2026-06-13).

---

## Deprecated / Roadmap (2 items)

These should not be included in the active registry.

| ID | Name | Type | Purpose |
|----|------|------|---------|
| PGR-D01 | Legacy Capability Registry | deprecated_reference | Historical reference for pre-v4.7.0 skill organization |
| PGR-D02 | Development Lifecycle Gap Analysis | roadmap_input | Understanding missing capabilities in the development lifecycle |

---

## Rules for Maintenance

1. **New gains must be evidence-backed** — include file existence, maturity, and last_verified date
2. **No duplicate entries** — check by name and scenario before adding
3. **Stale detection** — gains older than 90 days without verification get flagged
4. **Deprecation lifecycle** — deprecated entries stay for 30 days, then move to archive
5. **YAML size growth** — Phase 2.5 should not grow YAML by more than 15–20%; use defaults instead of repeated fields; do not add Phase 2.5 fields to references/deprecated entries unless needed
6. **Authority preserved** — this registry is advisory; runtime behavior is defined elsewhere

---

## Operating Contract (v0.3)

> Tells agents when to consult the registry, how much context to load, when to update, and how to avoid bloat/token waste.

### When to Consult

- User request matches a known scenario (implement, debug, ship, UI task, model eval, new repo, session recovery, provider issue)
- Agent is unsure which workflow applies — search registry before guessing
- Provider/model-dependent task starting — check PGR-023 (provider preflight) first

### When NOT to Consult

- Task is already covered by an approved PLAN.md — follow the plan
- Task is DIRECT lane (1 file, risk 0) — registry adds overhead for trivial work
- Agent already knows the correct workflow — don't search for the sake of searching

### Lookup Flow

```
User request → extract key phrases → match PGR trigger_phrases in YAML
→ filter by status (active > canary > reference_only)
→ filter by maturity (production > canary > deprecated)
→ check use_when / do_not_use_when
→ select best match (highest selection_priority if tied)
→ if multiple: select primary + cite secondary; load only primary context
```

### Minimal Context Rule

- Load YAML entry first (~20 lines) before reading linked docs
- Max 3 files from one PGR entry before acting
- Max 8 files total context for any single task
- Do NOT load vault/ references unless entry says `source_role: vault_reference` AND task requires history
- Do NOT load `.opencode/archive/`, `vault/archive/`, or deprecated gain files
- Use `Grep` to find sections in large files before `Read`

### Update vs Create

- **Update existing gain** when: new evidence improves it, files changed, status should change, or Phase 2.5 overrides need adjustment
- **Create new gain** only when: workflow executed 2+ times independently, has distinct trigger/files/use_when from all existing gains, and evidence artifact exists
- **Stay in vault only** when: lesson is repo-specific, one-time debugging, model-specific behavior, or protocol evolution
- **Go to model-registry** when: finding is about a specific model's reliability, routing, promotion_status, or token behavior

### Evidence Requirements

| Status | Required |
|---|---|
| canary | Script exists + syntax valid + 1 successful run |
| active | Script exists + passes validation + 2+ uses in different scenarios |
| reference_only | Documentation exists + accurately describes current state |
| deprecated | Superseded by another gain/tool + reason documented |

### Anti-Bloat Rules

- Max 25 active gains, 5 canary, 12 reference, 5 deprecated
- Gains with `last_verified` > 90 days → flag for review
- Prefer updating existing gains over creating new ones
- Do not duplicate model-registry, skills registry, or vault protocol content — cite and link instead
- YAML target: < 1500 lines; docs target: < 300 lines

### Token-Efficiency Rules

- Search YAML by trigger phrase before reading full docs
- Do NOT load vault unless task explicitly requires historical context
- Use provider-preflight (PGR-023) before any model-dependent eval
- For DIRECT lane tasks, skip registry entirely
- Load only the primary matching gain's files, not all related_gains

### PGR Maintenance Workflow (v0.1)

> Procedural governance for how agents should detect, propose, and request approval for PGR updates.
> This section defines the procedure. The rules above define the constraints.

#### When to Consider Proposing a PGR Update

After meaningful tasks, ask whether a repeatable productivity gain was discovered:

- After STANDARD or HIGH-RISK lane tasks that revealed a new workflow pattern
- After FAST lane tasks with 3+ files where a repeatable pattern emerged
- When an existing PGR entry proved incomplete, outdated, or inaccurate during use
- When a new tool, script, or command workflow emerged that deserves cataloging
- When a model reliability finding belongs in model-registry instead of PGR

If none of these apply, no proposal is needed. Most tasks do not generate new PGR entries.

#### Deduplication Procedure

Before proposing any change, systematically check for existing coverage:

1. **Search by trigger phrase** — does any existing entry match the key phrases from this task?
2. **Search by scenario** — does any existing entry describe the same situation?
3. **Search by workflow/use_when** — does any existing entry cover the same steps?
4. **Decision:**
   - If an existing entry covers 80%+ of the pattern → propose an **update** to that entry
   - If no existing entry covers the pattern → propose a **new candidate**
   - If the finding is repo-specific, one-time, or model-specific → **skip** (stay in vault or model-registry)

#### Candidate Proposal Format

Candidate proposals are session-output only. They are not registry entries until approved and committed.

Output the proposal in the session using this structure:

```
PGR Proposal: [create new / update existing]
Proposed ID: PGR-XXX (or existing ID for updates)
Name: [short descriptive name]
Scenario: [one-line description]
Trigger phrases: [3-5 phrases]
use_when: [3-5 conditions]
do_not_use_when: [2-3 conditions]
Minimal files: [list of files this gain references]
Validation gates: [what gates should run when this gain is used]
Evidence: [what proves this works — script exists, 2+ uses, test results]
Risks: [known limitations or failure modes]
Related gains: [PGR-IDs this connects to]
Deduplication check: [which existing entries were checked and why they don't cover this]
Recommendation: [create / update / skip]
```

#### Owner Approval Workflow

1. Output the candidate proposal in the session
2. Ask: "Propose PGR [create/update]: [name]. Approve, edit, or skip?"
3. Wait for explicit owner response
4. **Never edit the registry without explicit owner approval**
5. If owner says "edit" — incorporate feedback and re-propose
6. If owner says "skip" — do not edit, do not ask again this session

#### Validation Gates After Approval

After owner approval, before committing the registry edit:

1. **YAML syntax** — `ruby -e 'require "yaml"; YAML.load_file(".opencode/registry/productivity-gains.yaml")'`
2. **Unique IDs** — verify no duplicate PGR-XXX IDs
3. **Anti-bloat check** — verify entry counts within limits (25 active, 5 canary, 12 reference, 5 deprecated)
4. **Line count** — verify YAML < 1500 lines, docs < 300 lines
5. **Version consistency** — verify YAML version matches docs version
6. **Protocol-doctor** — `bash .opencode/scripts/protocol-doctor.sh` PGR section must pass
7. **Scoped diff review** — verify only PGR files changed, no forbidden files touched

#### Maturity for New Entries

Candidate proposals are not registry entries yet. They live in session output until owner approval. Once approved and evidence-backed, the first committed registry maturity should use an existing approved maturity level, usually `canary`, unless the Operating Contract defines another allowed level.

Promotion path: `canary` (1 successful run) → `active`/`production` (2+ successful uses in different scenarios)

#### Hard Rules

- **No duplicate entries** — check by name, scenario, and trigger phrases before adding
- **No registry edits without explicit owner approval** — proposals are session-output only
- **No new committed entry without evidence** — script exists, or 2+ successful uses documented
- **No runtime sync** unless the change affects orchestrator prompt behavior (rare for PGR-only changes)
- **No command or automation changes** in the same patch as a PGR registry edit
- **No exceeding anti-bloat limits** — if limits are reached, propose deprecation of a stale entry before adding a new one
- **No schema changes** without a separate approved governance patch

---

## Phase 2.5 — Schema Enhancements (v0.2)

Phase 2.5 adds agent-decision fields to the registry so the orchestrator can make smarter selections. These fields are optional and use header-level defaults — only overridden per-entry where they materially change agent behavior.

### Schema Defaults

| Field | Default | Description |
|-------|---------|-------------|
| `selection_priority` | 50 | Orchestrator ranking (0–100). 90–100 = always consider, 70–89 = strong candidate, 40–69 = reference, 0–39 = deprecated |
| `activation_confidence` | 0.7 | How confident we are this gain works (0.0–1.0) |
| `requires_owner_approval` | false | Whether human approval is needed |
| `risk_level` | low | Orchestrator caution level (low/medium/high/critical) |
| `budget_mode` | any | Whether gain can use premium models (any/cheap_only/premium_allowed) |
| `quota_or_availability_risk` | none | Provider quota risk (none/low/medium/high) |
| `provider_preflight_required` | false | Whether to check provider reachability first |

### Per-Entry Overrides (Phase 2.5A)

Only these gains have explicit Phase 2.5 field overrides:

- **PGR-007 Scoped Implementation** — priority 95, confidence 0.95, risk medium, with expected_gain and context_pack
- **PGR-017 Model Upgrade Evaluation** — priority 80, confidence 0.9, risk high, requires_owner_approval true, quota_risk high, with expected_gain
- **PGR-023 Provider Availability Preflight** (canary) — priority 85, confidence 0.5, with expected_gain. v0.1 supports OpenCode Go reachability only.

### Roadmap (Not Yet Added)

- **PGR-024 MCP / Tool Security Preflight** — planned future gain for verifying MCP server source, permissions, command execution surface, and tool poisoning risk before enabling tool/MCP infrastructure. OWASP now lists MCP tool poisoning as a top agent ecosystem risk.
