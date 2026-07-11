# Case Studies

> **Purpose:** Public-safe case studies showing how the OpenCode Agent Protocol improves governed AI-assisted development.
> **Last Updated:** 2026-07-11

---

## Case Study 1: Privacy Scan Regression Prevention

### Problem

During the v5.0.0 public baseline creation, a privacy scan checked for personal project names in PascalCase form (e.g., `PortfolioAnalyser`). However, the scan missed variant forms:
- Space-separated: `Portfolio Analyser`
- Kebab-case: `portfolio-analyser`
- Snake_case: `portfolio_analyser`
- Lowercase: `portfolioanalyser`

149 references with variant naming slipped through to the public repo.

### Harness Capability Used

| Capability | Role |
|-----------|------|
| Public Surface Scan | Variant-aware pattern matching |
| CI enforcement | Privacy Scan job blocks PRs with personal data |
| Branch protection | Prevents merging without passing privacy scan |

### Outcome

- v5.0.1 added variant-aware scanning (`scripts/public-surface-scan.sh`)
- All 149 missed references were anonymized
- A negative scan test confirmed the scanner catches blocked patterns
- CI now enforces the scan on every PR — future variant leaks are blocked before merge

### Evidence

- **Negative scan test:** Created a temp branch with `BabyGuide` in a file → scanner correctly failed → branch deleted without merging
- **CI result:** PR #1 (v5.0.3) — Privacy Scan: PASS
- **Fresh-clone validation:** 0 personal project name references in all variant forms

### Limitations

- The scanner only catches known patterns — new personal project names must be added manually
- Exclusions for policy docs that intentionally list blocked names must be narrow and path-specific
- The scanner does not scan untracked files or git history

---

## Case Study 2: Repeatable Release Process

### Problem

Publishing a public repo from internal development history requires a disciplined, repeatable release process. Without it, releases are ad-hoc, error-prone, and may accidentally include personal data or internal artifacts.

### Harness Capability Used

| Capability | Role |
|-----------|------|
| Release Checklist | Pre-release, version update, tag, and post-release validation steps |
| Protocol Conformance | CI validates protocol tests pass before merge |
| Branch Protection | PR required before merge to main |
| Public Surface Scan | Ensures no personal data in the release |
| Fresh-clone Validation | Post-release verification from a clean clone |

### Outcome

The v5.0.0 → v5.1.0 release sequence (5 releases) followed the same repeatable flow:

1. Create feature branch
2. Make changes
3. Run local validation
4. Create PR
5. CI runs Privacy Scan + Protocol Conformance
6. Both checks pass → merge state CLEAN
7. Squash merge
8. Tag release
9. Fresh-clone validation
10. Create GitHub Release

Every release was validated from a fresh clone with 0 failures.

### Evidence

| Release | Privacy Scan | Protocol Conformance | Fresh Clone |
|----------|--------------|----------------------|-------------|
| v5.0.0 | N/A (pre-CI) | N/A (pre-CI) | PASS |
| v5.0.1 | PASS | N/A (pre-CI) | PASS |
| v5.0.2 | PASS | N/A (pre-CI) | PASS |
| v5.0.3 | PASS | PASS | PASS |
| v5.1.0 | PASS | PASS | PASS |

### Limitations

- The release process is manual (human follows the checklist)
- No automated release pipeline yet
- Fresh-clone validation is manual

---

## Case Study 3: Agent Topology for Safe Task Delegation

### Problem

AI coding agents can make unsafe changes without guardrails: pushing directly to main, skipping tests, touching sensitive paths without review, or using inappropriate models for the task complexity.

### Harness Capability Used

| Capability | Role |
|-----------|------|
| Agent Topology | Orchestrator delegates to specialized helpers (Planner, Implementer, Reviewer, Architect, Explorer) |
| Lane Selection | DIRECT/FAST/STANDARD/HIGH-RISK with proportional controls |
| Model Routing | Advisory model assignment based on task type and risk |
| Reviewer Policy | Independent review required for HIGH-RISK and sensitive paths |
| Git Guard | Blocks `--no-verify`, `--force`, direct-main push |
| CI Enforcement | Privacy scan + protocol conformance on every PR |

### Outcome

A typical STANDARD lane task follows this flow:

1. **Orchestrator** classifies risk and selects lane
2. **Planner** creates a PLAN.md with touch list, success criteria, rollback path
3. **Implementer** makes bounded code changes on the approved touch list
4. **Reviewer** independently checks quality (required for HIGH-RISK)
5. PR is created — CI runs privacy scan + protocol conformance
6. Both checks must pass before merge (branch protection)
7. **Git Guard** prevents unsafe git operations throughout

### Evidence

- **Conformance tests:** 297 tests across multiple suites validate the protocol is internally consistent
- **Loop Controller test:** 96/96 PASS — validates state machine, stop conditions, repair policy
- **Production Hardening test:** 53/53 PASS — validates safety rules, lane selection, escalation triggers
- **Agent Roster Guard:** Validates helper roster consistency

### Limitations

- Model routing is advisory — it does not enforce which model is used
- Reviewer policy is advisory — human judgment is still required for HIGH-RISK
- The protocol does not guarantee code quality — it provides guardrails, not guarantees
- Agent behavior depends on the underlying AI model's adherence to instructions
