# Loop Run Contract — v4.45 Loop Engineering Controller

> **Purpose:** Defines the bounded execution contract for a single loop run.
> The loop controller reads this contract before execution and enforces all
> stop conditions, repair policies, and safety constraints.

## Contract Fields

```yaml
# ─── Identity ────────────────────────────────────────────────────────────
task_id: "TR-001"                    # Task from task replay registry
model: "umans-glm-5.2"               # Model to evaluate
agent: "owner"                       # Agent to evaluate

# ─── Lane and scope ──────────────────────────────────────────────────────
lane: "STANDARD"                     # Risk lane: FAST, STANDARD, HIGH-RISK
allowed_files:                       # Files the loop may touch
  - ".opencode/scripts/install-release-gate.sh"
forbidden_files:                     # Files the loop must never touch
  - "protected-repo/**"
  - ".env"
  - ".env.*"
  - "**/package.json"
  - "**/package-lock.json"

# ─── Cycle control ───────────────────────────────────────────────────────
max_cycles: 3                        # Maximum repair cycles (0 = single pass)
required_tests:                      # Tests that must pass for completion
  - "Installer rewrites .opencode/scripts/ to .github/scripts/"
  - "Installer does not modify source files"
reviewer_required: true              # Whether reviewer evidence is required
evidence_required: true              # Whether completion evidence is required

# ─── Stop conditions ─────────────────────────────────────────────────────
stop_conditions:
  max_cycles_reached: true           # Stop when max_cycles exhausted
  tests_pass_and_threshold_met: true # Stop when tests pass + score >= threshold
  forbidden_file_touched: true       # Stop immediately if forbidden file touched
  protected-repo_path_detected: true      # Stop immediately if protected-repo path detected
  same_failure_repeats_twice: true   # Stop if same failure reason repeats 2x
  no_score_improvement_after_repair: true  # Stop if repair didn't improve score
  required_evidence_missing: true    # Stop if evidence missing after final cycle
  high_risk_lacks_reviewer: true     # Stop if HIGH-RISK task lacks reviewer evidence
  cost_budget_exceeded: false        # Stop if cost budget exceeded (if available)
  time_budget_exceeded: false        # Stop if time budget exceeded (if available)
  malformed_result_detected: true    # Stop if result JSON is malformed

# ─── Repair policy ───────────────────────────────────────────────────────
repair_policy:
  test_quality_low: "add_or_improve_tests"        # If test_quality <= 2
  evidence_quality_low: "collect_better_evidence"  # If evidence_quality <= 2
  reviewer_issue_exists: "repair_reviewer_finding" # If reviewer_issue_count > 0
  minimal_diff_low: "reduce_scope"                 # If minimal_diff <= 2
  security_risk_low: "escalate_to_high_risk"        # If security_risk_handling <= 2
  root_cause_low: "replan_before_editing"           # If root_cause_correct <= 2

# ─── Scoring policy ──────────────────────────────────────────────────────
scoring_policy:
  pass_threshold: 24                 # Minimum score to pass (out of 35)
  max_possible_score: 35
  score_dimensions:                   # Dimensions scored (0-5 each)
    - root_cause_correct
    - minimal_diff
    - test_quality
    - ci_success
    - security_risk_handling
    - evidence_quality
    - lesson_reuse
  penalties:
    reviewer_issue_count:            # -2 per issue, max -10
      per_issue: 2
      max_penalty: 10
    repair_cycles:                   # -3 per cycle beyond first, max -9
      per_cycle: 3
      max_penalty: 9
  tracked:
    - time_cost_seconds              # Tracked but not penalized

# ─── Lesson extraction ───────────────────────────────────────────────────
lesson_extraction_policy:
  enabled: true
  output_file: ".opencode/evals/lessons/loop-lessons.jsonl"
  extract_on:                        # When to extract lessons
    - "completion"                   # After successful completion
    - "failure"                      # After failure/stop
    - "repair_cycle"                  # After each repair cycle
  fields:                            # Fields to record per lesson
    - task_id
    - failure_pattern
    - fix_pattern
    - evidence
    - recommended_future_action
    - applicable_task_types
```

## Contract Validation Rules

1. `task_id` must exist in the task replay registry
2. `model` and `agent` must be non-empty strings
3. `lane` must be one of: FAST, STANDARD, HIGH-RISK
4. `max_cycles` must be >= 0 and <= 5
5. `forbidden_files` must always include `protected-repo/**`
6. `allowed_files` must not overlap with `forbidden_files`
7. `pass_threshold` must be >= 0 and <= `max_possible_score`
8. If `lane` is HIGH-RISK, `reviewer_required` must be true
9. If `reviewer_required` is true, `evidence_required` must be true
10. `stop_conditions` must include at least `max_cycles_reached` and `forbidden_file_touched`

## Safety Constraints

- **Default mode is dry-run** — no production repo mutation
- **`--apply` requires explicit owner approval** — marked DANGEROUS
- **protected-repo is always excluded** — enforced by contract, controller, and tests
- **Forbidden files are enforced** — any touch triggers immediate stop
- **No secrets are recorded** — results contain no secret values
- **HIGH-RISK tasks require reviewer evidence** — enforced by stop condition
