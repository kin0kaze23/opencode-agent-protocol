# Core v1 Manifest — OpenCode Agent Protocol

> **Version:** v4.55
> **Date:** 2026-07-10
> **Status:** Core v1 Hardened

## What Is Included in Core v1

### Governance and Safety Layer (v4.20-v4.32)
- Lite delegation mode (DIRECT/FAST/STANDARD/HIGH-RISK)
- Risk classifier and lane selection
- Session cache and token efficiency
- Production hardening and security/release gates
- Content-aware sensitive change classification

### Release Gate Integration (v4.34-v4.36)
- GitHub PR release gate
- Reviewer evidence enforcement
- Reviewer trust hardening

### Multi-Repo Rollout (v4.37-v4.38)
- Multi-repo installer
- Branch protection verifier
- CODEOWNERS verifier

### PR Comments and Fleet Visibility (v4.39-v4.42)
- Sticky PR comments with gate results
- Fleet dashboard and trend analytics
- Manual branch protection evidence

### Evidence Freshness (v4.43-v4.43.1)
- Evidence freshness/expiry workflow
- Freshness metrics in fleet snapshots

### Task Replay Evals (v4.44-v4.44.2)
- 9 historical benchmark tasks
- Replay runner with dry-run/score-only/record-result modes
- Scoring engine: 7 dimensions + 2 penalties, max 35, pass 24
- Aggregate scorecard
- Installer comment script inclusion hotfix

### Loop Engineering Controller (v4.45-v4.45.1)
- Bounded loop controller with state machine
- 10 stop conditions, 6 repair policies
- Lesson extraction to JSONL
- Telemetry integration

### Model ROI / Routing Optimizer (v4.46-v4.47.1)
- Model performance normalizer with result_type tracking
- ROI analyzer with confidence calibration
- Routing recommendations (advisory only)
- Cross-model run plan and runner
- Confidence based on unique tasks, not raw records

### Live Non-Production Pilot (v4.48)
- Validated on real, low-risk test-only tasks
- 6 new conformance tests for cross-model selective coverage

### Protocol Atlas (v4.48.1-v4.48.2)
- Comprehensive visual documentation
- 10 Mermaid diagrams (all render to SVG)
- Validation script and 45 conformance tests
- 5-minute, 15-minute, and non-technical guides

### Reviewer Calibration (v4.49-v4.49.1)
- Reviewer findings schema with evidence_source tracking
- Calibration analyzer with seed vs real data separation
- Disagreement tracker
- Advisory policy recommendations
- Confidence calibration with minimum sample warnings

## What Is Explicitly Out of Scope

- Unbounded autonomous production editing
- Auto-pushing to real repos
- Auto-merging PRs
- Self-approving HIGH-RISK changes
- Silent production mutation
- protected-repo (always excluded)
- Auto-applying routing or reviewer policy changes

## Source-of-Truth Files

| File | Authority |
|------|-----------|
| `AGENTS.md` | Workspace router |
| `.opencode/rules.md` | OpenCode guardrails |
| `.opencode/brain-config.json` | Orchestration policy |
| `NOW.md` | Current state |
| `docs/protocol/PROTOCOL_ATLAS.md` | Visual system map |
| `.opencode/evals/task-replay/tasks.yaml` | Benchmark tasks |
| `.opencode/evals/loop-runs/LOOP_RUN_CONTRACT.md` | Loop contract |
| `.opencode/config/model-routing-policy.recommended.yaml` | Advisory routing |
| `.opencode/config/reviewer-policy.recommended.yaml` | Advisory reviewer policy |

## Required Validation Commands

```bash
# Core validation suite (16 suites, 815 tests)
bash .opencode/conformance/tests/reviewer-calibration.sh
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/scripts/validate-protocol-atlas.sh
bash .opencode/conformance/tests/model-roi.sh
bash .opencode/conformance/tests/loop-controller.sh
bash .opencode/conformance/tests/task-replay.sh
bash .opencode/conformance/tests/evidence-freshness.sh
bash .opencode/conformance/tests/manual-evidence.sh
bash .opencode/conformance/tests/fleet-dashboard.sh
bash .opencode/conformance/tests/fleet-trends.sh
bash .opencode/conformance/tests/pr-comment.sh
bash .opencode/conformance/tests/pr-release-gate.sh
bash .opencode/conformance/tests/branch-protection.sh
bash .opencode/conformance/tests/production-hardening.sh
bash .opencode/conformance/tests/telemetry-hardening.sh
bash .opencode/conformance/tests/evidence-based-routing.sh
```

## Safety Invariants

1. protected-repo is always excluded
2. HIGH-RISK always requires reviewer evidence
3. Routing policy is advisory only (auto_applied: false)
4. Reviewer policy is advisory only (auto_applied: false)
5. No production mutation without explicit --apply approval
6. No auto-push to main
7. No self-approval of HIGH-RISK changes
8. Secrets are never committed
9. Pre-commit hooks cannot be skipped
10. Stale evidence triggers warnings

## Known Limitations

1. Cross-model comparison is limited (only umans-glm-5.2 has successful simulation data)
2. Reviewer calibration sample size is small (6 real PR findings)
3. Live --apply mode is tightly gated and scaffolded
4. Routing and reviewer policy remain advisory
5. HIGH-RISK remains conservative
6. Most eval data is from control-plane repo
7. No `live_task_result` recording path for DIRECT lane regular-use tasks (design needed — target v4.52/v4.53)
8. Routing policy lacks eval data for `docs_only` and `test_improvement` task types (added v4.51.1 as advisory with `insufficient` confidence)

## Design Notes

### live_task_result Recording Path (TODO — v4.52/v4.53)

**Problem:** The performance records pipeline (`normalize-model-performance.sh`) expects `replay_result` or `loop_result` types. There is no `live_task_result` recording path for ad-hoc DIRECT/FAST lane tasks. This means regular-use evidence cannot feed into ROI/routing.

**Impact:** The feedback loop from regular controlled use to routing improvement is broken for low-risk live tasks. Only eval replays and loop controller runs generate performance records.

**Proposed design (not yet implemented):**
- Add `live_task_result` as a valid `result_type` in the normalizer
- Create a lightweight `record-live-task.sh` script that accepts task_id, task_type, risk_lane, model, score, and writes a normalized record
- Feed into existing `analyze-model-roi.sh` pipeline
- Gate behind explicit `--record` flag (not automatic)

**Priority:** Medium — needed to close the regular-use feedback loop, but not blocking for v4.52 cross-model evals.
