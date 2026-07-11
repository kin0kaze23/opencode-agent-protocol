AGENT_QUALITY_SCORECARD:
  period: last_30_days
  data_source: real
  tasks_count: 13
  eval_fixtures_excluded: 0
  source_type: live=7, retrospective=6, eval_fixture=0
  collection_mode: live=13, retrospective=0, synthetic=0
  evidence_level: full=10, partial=3
  confidence_weight: 76% full-evidence (10 full, 3 partial)
  success_rate: 100%
  ci_first_pass_rate: 80% (all evidence)
  ci_first_pass_rate_confidence: 80% (full evidence only)
  avg_repair_cycles: 0
  reviewer_value: 0 tasks with reviewer, 0 found issues
  model_roi: 2 models used, 0 premium tasks
  test_quality_signal: 2 with tests, 11 without
  memory_reuse: pattern=0, project=0
  recurring_failure_patterns: 0 types with failures
  human_acceptance: accepted=13, revised=0, rejected=0, unknown=0
  distributions:
    repos: control-plane=7, protected-repo-prod=3, example-app=1, sample-service=1, demo-project=1
    lanes: STANDARD=8, FAST=3, DIRECT=1, HIGH_RISK=1
    types: feature=4, protocol=4, infra=3, bugfix=2
  thresholds:
    total: 13/10 ✓
    reviewer: 0/5 ✗
    non_perfect: 2/3 ✗
    per_type_max: 4/5 ✗
  recommendations: exploratory_only — total threshold met but reviewer/failure/per-type thresholds not yet satisfied
  trend: (not yet available — requires multiple reporting periods)
  routing_optimization: partially_blocked — reviewer coverage insufficient (0/5)
  recommendation_status: exploratory_only
