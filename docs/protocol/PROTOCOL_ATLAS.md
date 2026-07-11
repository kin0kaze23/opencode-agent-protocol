# Protocol Atlas — OpenCode Agent Harness

> **Version:** v4.55.1
> **Last Updated:** 2026-07-10
> **Status:** Active
> **protected-repo:** EXCLUDED — do not touch

---

## One-Page Executive Overview

The OpenCode agent harness takes an engineering task, classifies its risk, routes it to the right model/agent, runs a bounded implementation loop, tests and reviews the result, gates release through CI and reviewer evidence, scores the outcome, extracts lessons, updates model ROI, and improves future routing.

**The full operating loop:**

```
User Task → Risk Classifier → Model/Agent Routing → Plan → Implement → Test → Review → Repair Loop → Release Gate → PR Comment → Score → Lesson Extraction → Model ROI Update → Future Routing Improvement
```

**Key safety properties:**
- protected-repo is always excluded
- Routing is advisory only — never auto-applied
- HIGH-RISK tasks require reviewer evidence and owner approval
- No production mutation without explicit `--apply` approval
- All changes gated by pre-commit hooks and conformance tests

**Current scale:** 815 targeted tests, 0 failures across 16 suites.

---

## Full Operating Loop

```mermaid
graph TB
    UT[User Task] --> RC[Risk Classifier]
    RC --> LR[Lane Selection]
    LR --> MR[Model/Agent Routing]
    MR --> PL[Plan]
    PL --> IM[Implement / Simulate]
    IM --> TS[Test]
    TS --> RV[Review]
    RV --> RP[Repair Loop]
    RP -->|repair| IM
    RV -->|pass| RG[Release Gate]
    RG --> PC[PR Comment]
    RG --> SC[Score]
    SC --> LE[Lesson Extraction]
    LE --> ROI[Model ROI Update]
    ROI --> FR[Future Routing Improvement]
    FR -.->|advisory| MR
```

**Diagram file:** `diagrams/system-overview.mmd`

### Loop stages

| Stage | What happens | Owner/Agent | Key artifact |
|-------|-------------|-------------|--------------|
| Intake | Task classified by risk score | Agent | Risk score, lane |
| Routing | Model/agent selected based on advisory recommendations | Agent (advisory) | Routing recommendation |
| Plan | Touch list, success criteria, rollback path | Agent + Owner approval | PLAN.md (STANDARD+) |
| Implement | Bounded code changes within touch list | Agent | Diff |
| Test | Lint, typecheck, unit tests, build | Agent | Gate results |
| Review | Reviewer evidence checked (HIGH-RISK required) | Agent + Reviewer | Reviewer findings |
| Repair | If tests/review fail, cycle back (max_cycles) | Agent | Repair cycle count |
| Release Gate | CI gates, sensitive change classifier, reviewer evidence | CI + Agent | Gate pass/block |
| PR Comment | Sticky PR comment with gate result | CI | PR comment |
| Score | 7 dimensions + 2 penalties, max 35, pass 24 | Agent | Score JSON/MD |
| Lesson Extraction | Failure pattern, fix pattern, recommended action | Agent | loop-lessons.jsonl |
| Model ROI Update | Normalize, analyze, generate recommendations | Agent | ROI scorecard |
| Future Routing | Advisory recommendations feed back to routing | Agent (advisory) | model-routing-policy.recommended.yaml |

---

## Agent Topology / Sub-Agent Responsibilities

The protocol uses a multi-agent architecture where the Orchestrator delegates to specialized sub-agents. All routing is advisory — the Orchestrator makes final decisions.

### Topology Diagram

```mermaid
graph TB
    subgraph "Orchestrator Layer"
        ORC[Orchestrator<br/>umans-glm-5.2<br/>Routes tasks, owns strategy]
    end

    subgraph "Planning Layer"
        PLN[Planner<br/>Creates plans, touch lists<br/>Ambiguous/high-risk work]
    end

    subgraph "Execution Layer"
        IMP[Implementer<br/>Bounded code changes<br/>Consumes approved plans]
        EXP[Explorer<br/>Read-only discovery<br/>Cheap-first routing]
    end

    subgraph "Review Layer"
        REV[Reviewer<br/>umans-glm-5.1<br/>Risk 4+, sensitive paths]
        ARCH[Architect<br/>qwen3.7-plus<br/>Auth/schema/state-model]
    end

    subgraph "Budget Layer"
        BUD[Budget<br/>deepseek-v4-flash<br/>Cheap summaries, routing]
    end

    subgraph "Compaction Layer"
        CMP[Compaction<br/>glm-5.2 / kimi-k2.7<br/>Context preservation]
    end

    subgraph "Eval & Routing Layer"
        ROI[Model ROI Analyzer]
        ROUTE[Routing Generator]
        CAL[Reviewer Calibration]
        LOOP[Loop Controller]
        SCORE[Task Scorer]
        LESSON[Lesson Extractor]
    end

    subgraph "Release Layer"
        GATE[Release Gate]
        PR[PR / Merge]
    end

    ORC -->|delegate| PLN
    ORC -->|discover| EXP
    ORC -->|implement| IMP
    ORC -->|review| REV
    ORC -->|architecture| ARCH
    ORC -->|budget| BUD
    ORC -->|compaction| CMP
    PLN -->|approved plan| IMP
    IMP -->|test results| SCORE
    SCORE -->|fail| LOOP
    LOOP -->|repair| IMP
    SCORE -->|pass| GATE
    REV -->|findings| CAL
    GATE -->|block| IMP
    GATE -->|pass| PR
    IMP -->|performance| ROI
    ROI -->|recommendations| ROUTE
    ROUTE -->|advisory| ORC
    LOOP -->|lessons| LESSON
    LESSON -->|future| ORC
```

**Diagram file:** `diagrams/agent-topology.mmd` | **Rendered:** `rendered/agent-topology.svg`

### Agent Roles

| Agent | Model | Role | When Used |
|-------|-------|------|-----------|
| **Orchestrator** | umans-glm-5.2 | Routes tasks, owns strategy, makes final decisions | Every session |
| **Planner** | umans-coder | Creates plans, touch lists, success criteria | Ambiguous, multi-step, high-risk work |
| **Implementer** | umans-coder | Bounded code changes within approved touch list | After plan approval |
| **Explorer** | umans-flash | Read-only codebase discovery, dependency mapping | Before planning, cheap-first routing |
| **Reviewer** | umans-glm-5.1 | Risk 4+, sensitive paths, release gates | HIGH-RISK, 4+ files, auth/security/payment |
| **Architect** | qwen3.7-plus | Auth/session semantics, schema, state-model | Architecture decisions, cross-surface design |
| **Budget** | deepseek-v4-flash | Cheap summaries, routing classification, cost summaries | Routine read-only work |
| **Compaction** | glm-5.2 / kimi-k2.7 | Context preservation during long sessions | Session compaction |

### How Agents Cooperate

1. **Orchestrator** receives the user task and classifies risk
2. **Explorer** may be called first for read-only discovery (cheap-first routing)
3. **Planner** creates the implementation plan for ambiguous/high-risk work
4. **Implementer** executes bounded code changes within the approved touch list
5. **Reviewer** checks the output for HIGH-RISK tasks or sensitive paths
6. **Architect** is consulted for auth/schema/state-model decisions
7. **Budget** handles cheap summaries and routing classification
8. **Compaction** preserves context during long sessions
9. **Loop Controller** manages repair cycles if tests fail
10. **Task Scorer** scores the outcome (7 dimensions, max 35, pass 24)
11. **Lesson Extractor** captures failure patterns for future use
12. **Model ROI Analyzer** normalizes performance data
13. **Routing Generator** produces advisory recommendations
14. **Release Gate** validates CI, sensitive changes, and reviewer evidence
15. **PR/Merge** requires human approval — no auto-merge

### Advisory-Only Principle

All routing and reviewer policies are advisory (`auto_applied: false`). The Orchestrator uses recommendations as guidance but makes final decisions. No policy is automatically applied without owner review.

---

## Task Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Intake
    Intake --> RiskClassification
    RiskClassification --> LaneSelection
    LaneSelection --> DIRECT: risk 0
    LaneSelection --> FAST: risk 1-2
    LaneSelection --> STANDARD: risk 3-5
    LaneSelection --> HIGHRISK: risk 6+
    DIRECT --> Implement
    FAST --> Plan
    STANDARD --> Plan
    HIGHRISK --> Plan
    Implement --> Test
    Test --> Review
    Review --> Pass: tests pass
    Review --> Repair: issues found
    Repair --> Implement: cycle < max
    Pass --> ReleaseGate
    ReleaseGate --> Merged: gate passes
    Merged --> Score
    Score --> [*]
```

**Diagram file:** `diagrams/task-lifecycle.mmd`

---

## Risk Routing Decision Tree

```mermaid
flowchart TD
    Start[Task arrives] --> Q1{Risk score?}
    Q1 -->|0| DIRECT[DIRECT: edit, lint, commit]
    Q1 -->|1-2| FAST[FAST: inline plan, ≤3 files]
    Q1 -->|3-5| STANDARD[STANDARD: PLAN.md, ≤6 files]
    Q1 -->|6+| HIGHRISK[FORCED HIGH-RISK: PLAN.md + ADR]
    HIGHRISK --> HR[Reviewer required, full suite + SAST]
    STANDARD --> SR[Full gate suite, reviewer recommended]
    FAST --> FR[Per verification profile, reviewer optional]
```

**Diagram file:** `diagrams/risk-routing-decision-tree.mmd`

### Lane summary

| Lane | Risk | Files | Plan | Gates | Reviewer | Checkpoint |
|------|------|-------|------|-------|----------|------------|
| DIRECT | 0 | 1 | None | Lint only | No | Lite |
| FAST | 1-2 | ≤3 | Inline bullets | Per profile | Optional | Lite |
| STANDARD | 3-5 | ≤6 | PLAN.md | Full suite | Recommended | Full |
| HIGH-RISK | 6+ | ≤10 | PLAN.md + ADR | Full + SAST | Required | Full |

Forced HIGH-RISK: auth, payment, schema, migration, cryptography, destructive action, user data, state model rewrite.

---

## Safety and Release Gate Flow

```mermaid
flowchart LR
    PR[PR Created] --> Lint --> TC[Typecheck] --> UT[Unit Tests] --> Build
    Build --> SC{Sensitive?}
    SC -->|No| Gate[Standard gate]
    SC -->|Yes| Classify[Content-aware classifier v4.33]
    Classify --> RG[Release gate]
    Gate --> RG
    RG --> REV{Reviewer evidence?}
    REV -->|Found| Pass[Gate PASS]
    REV -->|Missing, required| Block[Gate BLOCK]
    Pass --> Comment[PR Comment v4.39]
    Comment --> Merge[Ready to merge]
```

**Diagram file:** `diagrams/release-gate-flow.mmd`

### Release gate components

| Component | Version | Purpose |
|-----------|---------|---------|
| `validate-release-gate.sh` | v4.34 | Main gate validator |
| `sensitive-change-classifier.sh` | v4.33 | Content-aware sensitive change detection |
| `release-decision-report.sh` | v4.34 | Gate decision report |
| `reviewer-evidence-detector.sh` | v4.35 | Detects reviewer evidence in PR |
| `post-release-gate-comment.sh` | v4.39 | Sticky PR comment with gate result |
| `install-release-gate.sh` | v4.37 | Multi-repo installer |
| `reviewer-trust-policy.yaml` | v4.36 | Trust policy for reviewer evidence |

---

## Reviewer Evidence Flow

```mermaid
flowchart TD
    PR[PR opened] --> Detect[Reviewer Evidence Detector]
    Detect --> Q1{Evidence found?}
    Q1 -->|Yes| Q2{Type: comment/approval/review?}
    Q2 --> Policy[Trust Policy]
    Q1 -->|No| Q3{Required?}
    Q3 -->|HIGH-RISK| Block[BLOCKED]
    Q3 -->|STANDARD| Warn[Warning]
    Q3 -->|FAST/DIRECT| Skip[Skip]
    Policy --> Q4{Trusted?}
    Q4 -->|Yes| Pass[Pass]
    Q4 -->|No| Block
```

**Diagram file:** `diagrams/reviewer-evidence-flow.mmd`

---

## Eval / Replay / Loop Flow

```mermaid
flowchart TD
    TY[tasks.yaml<br/>9 benchmark tasks] --> RTR[run-task-replay-eval.sh]
    TY --> RLC[run-loop-controller.sh]
    TY --> RCM[run-cross-model-evals.sh]
    RTR --> SCT[score-task-replay.sh]
    RLC --> SCT
    SCT --> GEN[generate-task-replay-scorecard.sh]
    GEN --> NMP[normalize-model-performance.sh]
    NMP --> AMR[analyze-model-roi.sh]
    AMR --> GRR[generate-routing-recommendations.sh]
    GRR --> Policy[model-routing-policy.recommended.yaml<br/>advisory only]
    RLC --> Lessons[loop-lessons.jsonl]
```

**Diagram file:** `diagrams/eval-loop-flow.mmd`

### Eval components

| Component | File | Purpose |
|-----------|------|---------|
| Task registry | `.opencode/evals/task-replay/tasks.yaml` | 9 historical benchmark tasks |
| Replay runner | `run-task-replay-eval.sh` | --dry-run, --score-only, --record-result |
| Loop controller | `run-loop-controller.sh` | State machine, stop conditions, repair policy |
| Cross-model runner | `run-cross-model-evals.sh` | Multi-model eval runner |
| Scoring engine | `score-task-replay.sh` | 7 dimensions + 2 penalties, max 35 |
| Scorecard | `generate-task-replay-scorecard.sh` | Aggregate results |
| Normalizer | `normalize-model-performance.sh` | Unified JSONL with result_type |
| ROI analyzer | `analyze-model-roi.sh` | By-model, by-task-type, by-risk-lane |
| Routing generator | `generate-routing-recommendations.sh` | Advisory recommendations + YAML policy |
| Lessons | `loop-lessons.jsonl` | Failure patterns, fix patterns |

### Scoring dimensions

| Dimension | Max | Weight | Type |
|-----------|-----|--------|------|
| root_cause_correct | 5 | 5 | Scored |
| minimal_diff | 5 | 4 | Scored |
| test_quality | 5 | 4 | Scored |
| ci_success | 5 | 4 | Scored |
| security_risk_handling | 5 | 5 | Scored |
| evidence_quality | 5 | 3 | Scored |
| lesson_reuse | 5 | 3 | Scored |
| reviewer_issue_count | — | -2/issue | Penalty (max -10) |
| repair_cycles | — | -3/cycle | Penalty (max -9) |
| time_cost | — | tracked | Not penalized |

**Max score: 35 | Pass threshold: 24 (70%)**

---

## Model ROI / Routing Flow

```mermaid
flowchart TD
    Results[All results] --> Norm[normalize-model-performance.sh]
    Norm --> Records[performance-records.jsonl<br/>with result_type]
    Records --> ROI[analyze-model-roi.sh]
    ROI --> Scorecard[model-roi-scorecard.md/json]
    Scorecard --> Routing[generate-routing-recommendations.sh]
    Routing --> Recs{Confidence}
    Recs -->|3+ unique tasks| High[high]
    Recs -->|1-2 unique tasks| Low[low]
    Recs -->|0| Insufficient[insufficient]
    Routing --> YAML[model-routing-policy.recommended.yaml<br/>advisory: true]
```

**Diagram file:** `diagrams/model-roi-routing-flow.mmd`

### Confidence calibration

| Level | Requirement | Behavior |
|-------|-------------|----------|
| high | 3+ unique tasks | Full recommendation with rationale |
| low | 1-2 unique tasks | Recommendation marked "low confidence" |
| insufficient | 0 unique tasks | No recommendation, missing data flagged |

### Routing guardrails

- protected-repo excluded from all routing
- No self-attested score-only promotion without evidence
- No production route change without explicit owner approval
- No HIGH-RISK downgrade to low-cost model purely for cost
- Stale eval data (>30 days) triggers warning
- Recommended YAML policy is advisory only (`auto_applied: false`)

---

## Fleet Protection Flow

```mermaid
flowchart TD
    AH[sample-service<br/>manually_verified] --> BPV[Branch Protection Verifier]
    ST[demo-project<br/>manually_verified] --> BPV
    BG[protected-repo<br/>EXCLUDED] -.->|do not touch| BGX[Excluded]
    BPV --> FD[Fleet Dashboard]
    FD --> FT[Fleet Trends]
    FT --> EF[Evidence Freshness]
    EF --> FS[Fleet Snapshots]
```

**Diagram file:** `diagrams/fleet-protection-flow.mmd`

### Fleet status

| Repo | Status | Freshness |
|------|--------|-----------|
| sample-service | manually_verified | Fresh |
| demo-project | manually_verified | Fresh |
| protected-repo | EXCLUDED | Do not touch |

---

## Human Owner Responsibility Map

```mermaid
flowchart TD
    subgraph Owner_Approves
        OA1[Task scope and touch list]
        OA2[Plan before implementation]
        OA3[PR merge to main]
        OA4[Deploy / release]
        OA5[Secret handling]
        OA6[Schema / migration changes]
        OA7[Model routing changes]
        OA8[--apply mode]
    end
    subgraph Automated
        A1[Risk classification]
        A2[Lane selection]
        A3[Gate execution]
        A4[Test execution]
        A5[Score calculation]
        A6[Lesson extraction]
        A7[ROI analysis]
        A8[Routing recommendations]
    end
    subgraph Never_Automated
        NA1[Push to main]
        NA2[Force push]
        NA3[Skip hooks]
        NA4[Commit secrets]
        NA5[Disable rate limits]
        NA6[Touch protected-repo]
        NA7[Auto-apply routing]
        NA8[Self-approve HIGH-RISK]
    end
```

**Diagram file:** `diagrams/operator-responsibility-map.mmd`

---

## Artifact / Source-of-Truth Map

```mermaid
flowchart TD
    subgraph Protocol_Truth
        AGENTS[AGENTS.md]
        RULES[rules.md]
        BRAIN[brain-config.json]
        NOW[NOW.md]
    end
    subgraph Release_Governance
        RG[validate-release-gate.sh]
        SCC[sensitive-change-classifier.sh]
        RED[reviewer-evidence-detector.sh]
        PRC[post-release-gate-comment.sh]
        INST[install-release-gate.sh]
    end
    subgraph Eval
        TY[tasks.yaml]
        RTR[run-task-replay-eval.sh]
        SCT[score-task-replay.sh]
        RLC[run-loop-controller.sh]
        RCM[run-cross-model-evals.sh]
        NMP[normalize-model-performance.sh]
        AMR[analyze-model-roi.sh]
        GRR[generate-routing-recommendations.sh]
    end
    subgraph Reports
        R1[reports/task-replay/]
        R2[reports/model-roi-scorecard.*]
        R3[reports/routing-recommendations.*]
        R4[reports/fleet-dashboard.*]
        R5[reports/loop-controller/]
    end
```

**Diagram file:** `diagrams/artifact-map.mmd`

### Key artifacts

| Artifact | Location | Authority |
|----------|----------|-----------|
| AGENTS.md | workspace root | Workspace router |
| rules.md | `.opencode/rules.md` | OpenCode guardrails |
| brain-config.json | `.opencode/brain-config.json` | Orchestration policy |
| NOW.md | repo root | Current state |
| PLAN.md | repo root | Active plan |
| tasks.yaml | `.opencode/evals/task-replay/` | Benchmark tasks |
| performance-records.jsonl | `.opencode/metrics/model-performance/` | Normalized records |
| loop-lessons.jsonl | `.opencode/evals/lessons/` | Extracted lessons |
| model-routing-policy.recommended.yaml | `.opencode/config/` | Advisory routing policy |

---

## Glossary

| Term | Definition |
|------|------------|
| Lane | Risk classification: DIRECT, FAST, STANDARD, HIGH-RISK |
| Touch list | Approved list of files that may be modified |
| Gate | Quality check: lint, typecheck, test, build |
| Release gate | CI gate that validates PR before merge |
| Reviewer evidence | Proof that a reviewer examined the change |
| Trust policy | Rules for what reviewer evidence is trusted |
| Task replay | Replaying a historical task to evaluate agent performance |
| Loop controller | Bounded execution loop with stop conditions |
| Result type | replay_result, loop_result, or live_task_result |
| Confidence | high (3+ unique tasks), low (1-2), insufficient (0) |
| best_observed | Best model from available evidence (not globally proven) |
| best_overall | Best model from cross-model comparison (2+ models) |
| protected-repo | Excluded repo — never touched by any component |
| Advisory only | Routing recommendations are not auto-applied |
| Freshness | How recently evidence was verified (expires after 90 days) |

---

## How to Use This Atlas

### 5-Minute Explanation (for anyone)

1. **"The harness takes a task, classifies its risk, and routes it to the right model."**
   - Risk classifier → lane selection → advisory routing

2. **"It runs a bounded loop: plan, implement, test, review, repair."**
   - Max cycles, stop conditions, forbidden files, protected-repo excluded

3. **"Every change goes through a release gate with CI and reviewer evidence."**
   - Sensitive change classifier, reviewer evidence detector, trust policy

4. **"After completion, it scores the outcome and extracts lessons."**
   - 7 scoring dimensions, lesson extraction to JSONL

5. **"Scores feed into model ROI, which generates advisory routing recommendations."**
   - Confidence based on unique tasks, best_observed not best_overall, advisory only

### 15-Minute Deep Dive (for engineers)

1. **Start with the system overview diagram** (`diagrams/system-overview.mmd`) — shows the full operating loop
2. **Walk through the task lifecycle** (`diagrams/task-lifecycle.mmd`) — explains state machine and lane selection
3. **Review the release gate flow** (`diagrams/release-gate-flow.mmd`) — shows how CI gates and reviewer evidence work
4. **Examine the eval/loop flow** (`diagrams/eval-loop-flow.mmd`) — shows how tasks are replayed and scored
5. **Study the model ROI flow** (`diagrams/model-roi-routing-flow.mmd`) — shows how routing recommendations are generated
6. **Check the operator responsibility map** (`diagrams/operator-responsibility-map.mmd`) — shows what's automated vs owner-approved

### For Non-Technical Stakeholders

- **What it does**: Safely automates engineering tasks with quality gates
- **Why it's safe**: protected-repo excluded, routing advisory only, HIGH-RISK requires human approval
- **What it measures**: 7 quality dimensions per task, model ROI by task type
- **What it learns**: Lessons extracted to JSONL, routing improves over time
- **What it doesn't do**: No auto-push to main, no self-approval, no secret exposure

### Rendered Diagrams

SVG renders of all diagrams are available in `docs/protocol/rendered/`. To regenerate:

```bash
npx @mermaid-js/mermaid-cli -i docs/protocol/diagrams/<diagram>.mmd -o docs/protocol/rendered/<diagram>.svg -b transparent
```

Any new diagram must pass render validation via `validate-protocol-atlas.sh`.

---

## Maintenance Rules

### When must this atlas be updated?

Update this atlas when changes affect:

- **Routing** — model routing policy, confidence calibration, guardrails
- **Risk lanes** — lane definitions, thresholds, forced HIGH-RISK triggers
- **Reviewer behavior** — trust policy, evidence types, reviewer requirements
- **Release gates** — gate components, sensitive change classifier, PR comments
- **Eval scoring** — scoring dimensions, penalties, pass threshold
- **Loop controller** — state machine, stop conditions, repair policy
- **Model ROI** — normalizer, analyzer, recommendation generator
- **Fleet dashboard** — fleet repos, protection status, freshness
- **Manual evidence** — evidence types, freshness expiry, manual verification
- **Owner workflow** — approval boundaries, never-automated rules

### How to update

1. Update the relevant section in `PROTOCOL_ATLAS.md`
2. Update the corresponding Mermaid diagram in `diagrams/`
3. Run `bash .opencode/scripts/validate-protocol-atlas.sh`
4. Run `bash .opencode/conformance/tests/protocol-atlas.sh`
5. Commit with conventional message

---

*Generated as part of v4.48.1 — Protocol Atlas / Visual System Map. Updated v4.50 — Core v1 Hardening Release.*
