---
description: "Bridge requirements to plan with structured analysis and skill activation"
---

# /analyze

**Mode:** Mentor / Planner  
**Model:** qwen3.7-plus (v1.1-production, Action 4D)  
**Tool access:** Layer A (read-only by default; write only to docs/ analysis artifacts)  
**Success output:** Structured analysis artifact that feeds /plan-feature with clear goals, constraints, and success criteria

## Purpose

`/analyze` bridges the gap between "I want X" and "here's the plan". It systematically gathers requirements, maps current vs. desired state, identifies constraints and risks, and produces a lightweight analysis artifact that makes /plan-feature significantly more effective.

## Skill Activation (run before analyzing)

| Task domain | Skill file |
|---|---|
| Eliminate assumptions / unclear requirements | `interrogation/SKILL.md` |
| Explore ideas and design approaches | `brainstorming/SKILL.md` |
| REST and GraphQL API design | `api-design/SKILL.md` |
| Product requirements / PRD-lite / task brief | `workflow-enforcement/SKILL.md` |
| Sensitive-path threat discovery | `threat-modeling/SKILL.md` |
| API/client/server contract discovery | `api-contract-validation/SKILL.md` |
| Deploy/runtime/environment/CI discovery | `infra-validation/SKILL.md` |

If no domain matches: proceed without skill activation.

## v4.7.0 Active Template Triggers

These templates are prep artifacts only; they do not promote the active protocol beyond v4.6.1.

| Trigger | Template / skill | Requirement |
|---|---|---|
| Net-new feature, product-facing change, or ambiguous request | `.opencode/templates/PRD.md` | Produce Product Brief / PRD-lite, or `N/A` with reason and risk for tiny DIRECT fixes |
| UI, frontend, page, component, CSS, view, screen, or product-copy work | `.opencode/templates/DESIGN_BRIEF.md` | Produce UI Design Brief, or `N/A` with reason and risk when no product UI changes |
| Auth, payment, schema, security, crypto, user-data, or other sensitive path | `.opencode/templates/THREAT_MODEL.md` + `threat-modeling/SKILL.md` | Identify assets, actors, trust boundaries, likely STRIDE risks, and whether HIGH-RISK planning is required |
| API handler, validator, SDK/client, request/response/error format, or compatibility surface | `api-contract-validation/SKILL.md` | Identify request, response, error, auth, compatibility, tests, docs, and client/server alignment questions |
| Deploy, runtime config, environment variables, secrets handling, CI, Docker, health, or rollback scope | `infra-validation/SKILL.md` | Identify runtime authority, health checks, secret-handling risks, deployment gates, and rollback questions |

## Behaviour

When invoked, the Owner agent:

1. Runs preflight — confirms target repo and analysis scope
2. Reads `<repo>/AGENTS.md` and `<repo>/NOW.md` for current state
3. Reads any relevant existing docs:
   - `<repo>/ROADMAP.md` if it exists
   - `<repo>/PLAN.md` if it exists (to check for existing plans)
   - `vault/projects/<repo>/lessons.md` if it exists
4. **Structured requirements elicitation:**
    - User goals: what does the user want to achieve?
    - User context: who uses this? what's their situation?
    - Success criteria: what does "done" look like?
    - Constraints: auth, existing patterns, performance, platform, timeline
    - Out of scope: what is explicitly NOT included?
    - MVP vs. production-quality: what is the minimum viable scope?
4b. **Product Brief / PRD-lite Gate:** For net-new features, product-facing changes, or ambiguous requests, produce a Product Brief before recommending implementation or planning. Tiny bug fixes may mark it `N/A` only with a specific reason.
   - Required fields: user problem, target user/persona, job-to-be-done, desired user outcome, product/business objective, success metric, non-goals, acceptance criteria, edge cases, kill criteria, analytics/observability requirement.
   - If any required field is unknown and affects scope or risk: ask one clarifying question or mark the field as `UNKNOWN — blocks planning`.
4c. **UI / sensitive / contract / infra trigger scan:** Before recommending planning, decide which v4.7.0 active templates or skills apply. Do not make every template mandatory for every task; mark non-applicable templates `N/A` with reason and risk.
5. **Current state analysis:**
   - What exists today? (read relevant code/docs)
   - What works well?
   - What is broken or missing?
   - What are the adjacent systems or dependencies?
6. **Desired state mapping:**
   - Target behavior from user perspective
   - Technical implications
   - Risks and failure modes
   - Migration considerations
7. **Option exploration (2-3 approaches):**
   - Each with trade-offs
   - Clear recommendation with reasoning
   - When to choose each option
8. **Gap identification:**
   - What must be planned?
   - What must be researched first?
   - What can be deferred?
9. **Writes analysis artifact** to `<repo>/docs/analysis/<ISO-date>-<topic>-analysis.md`:
    - Goals and success criteria
    - Product Brief / PRD-lite (or `N/A` with reason)
    - UI Design Brief trigger result (template required / N/A with reason and risk)
    - Threat Model trigger result (required / N/A with reason and risk)
    - API contract discovery result (required / N/A with reason and risk)
    - Infra/runtime discovery result (required / N/A with reason and risk)
    - Current state summary
    - Desired state summary
    - Constraints and risks
    - Recommended approach
    - Open questions for /plan-feature
10. **Outputs to chat:** "Analysis written to `<repo>/docs/analysis/...`. Reply 'approved' to start planning, 'adjust' to refine the analysis, or 'skip' to proceed directly to /plan-feature."
11. **Stops.** Does not proceed to /plan-feature without approval.

## Output format

Written to both chat AND the analysis artifact file:

```markdown
## Analysis: <topic>
Date: <ISO date>
Status: PENDING REVIEW

### Goals
- <goal 1>
- <goal 2>

### Success Criteria
- <observable outcome 1>
- <observable outcome 2>

### Product Brief / PRD-lite
- User problem: <problem or N/A with reason>
- Target user/persona: <user>
- Job-to-be-done: <job>
- Desired user outcome: <outcome>
- Product/business objective: <objective>
- Success metric: <metric>
- Non-goals: <explicit exclusions>
- Acceptance criteria: <criteria>
- Edge cases: <cases>
- Kill criteria: <when to stop/reject this direction>
- Analytics/observability requirement: <events/logs/metrics or N/A with reason>

### Specialist Prep Triggers
- UI Design Brief: <required / N/A with reason and risk>
- Threat Model: <required / N/A with reason and risk>
- API contract validation: <required / N/A with reason and risk>
- Infra validation: <required / N/A with reason and risk>

### Current State
<summary of what exists today>

### Desired State
<summary of what should exist>

### Constraints
- <constraint 1>
- <constraint 2>

### Risks
- <risk> -> <mitigation>

### Recommended Approach
<approach + reasoning>

### Alternatives Considered
- <option A> — <trade-off> — choose when: <condition>
- <option B> — <trade-off> — choose when: <condition>

### Open Questions for Planning
- <question 1>
- <question 2>

### Out of Scope
- <exclusion 1>
- <exclusion 2>
```

## Do not
- Write implementation code
- Create PLAN.md (that is /plan-feature's job)
- Skip reading current state before recommending approaches
- Invent requirements the user did not state or imply
- Proceed to planning without user approval of the analysis
- Over-analyze trivial changes — use judgement to scale depth to scope
- Reference retired orchestration commands or dead absolute paths

## When to use /analyze

- User goal is unclear or high-level ("make it better", "add admin features")
- Multiple valid approaches exist with significant trade-offs
- Task involves external integrations with unverified contracts
- User explicitly asks for analysis before planning
- The analysis will save more time than it costs to produce

## When NOT to use /analyze

- Trivial changes with clear specs (use /quick or /implement directly)
- User has already provided a detailed spec with clear requirements
- Bug fixes with clear root causes (use /debug)
- The user explicitly says "just do it" with a clear, scoped request
