# brain-config Reference — Descriptive Documentation

> **Purpose:** Reference documentation extracted from `brain-config.json`.
> **Status:** Reference-only. Not loaded at startup. Not read by runtime or conformance tests.
> **Parent config:** `.opencode/brain-config.json`

This file contains descriptive, historical, and explanatory content that was previously
inline in `brain-config.json` but was not read by the runtime, scripts, or conformance tests.

## workflow

Session startup and runtime ordering guidance. The actual startup sequence is defined in `.opencode/AGENTS.md` and `.opencode/rules.md`.

```json
{
  "session_start": [
    "read <repo>/AGENTS.md (mandatory)",
    "read <repo>/NOW.md (mandatory)",
    "if NOW.md status is active or blocked: apply Session Resume Rule before preflight",
    "if NOW.md is missing but PHASE_STATE.md exists: read PHASE_STATE.md as legacy fallback, report the exception, and normalize to NOW.md on the next /checkpoint",
    "progressive context expansion: read additional files ONLY when uncertainty triggers on_demand_triggers (see context_loading section)",
    "if vault/projects/<repo>/lessons.md exists AND current task overlaps lesson keywords: read it",
    "check repo dirty state: run git status --short for the target repo; if dirty, include dirty-state summary in preflight under Major risks",
    "output mandatory preflight block — see .opencode/AGENTS.md"
  ],
  "on_server_start": [
    "owner startup handled by .opencode/AGENTS.md and .opencode/rules.md"
  ],
  "on_complexity_high": [
    "escalate model — see orchestrator_mode.escalation in brain-config.json"
  ],
  "before_code": [
    "output preflight block with touch list and success criteria"
  ],
  "runtime_order": [
    "preflight",
    "plan",
    "implement",
    "gates",
    "review",
    "checkpoint",
    "ship"
  ],
  "after_plan": [
    "stop and wait for user approval; do not run /checkpoint after /plan-feature"
  ],
  "after_execute": [
    "run /gates first using the declared verification profile; only checkpoint after verification and review obligations are satisfied"
  ],
  "after_qa": [
    "deliver a verdict and, when the task is complete, run /checkpoint to update <repo>/NOW.md"
  ],
  "after_ship": [
    "run /ship only for release readiness, handoff, or deploy-adjacent work; never treat /ship as implicit approval"
  ]
}
```

## benchmarking

Benchmark configuration and telemetry settings. The actual benchmark cases live in `.opencode/benchmarks/`.

```json
{
  "enabled": true,
  "rubric_path": ".opencode/benchmarks/README.md",
  "case_schema_path": ".opencode/benchmarks/case-schema.md",
  "seed_corpus_policy": "Small gold corpus first. Expand only after the rubric and telemetry stabilize.",
  "gold_corpus_target": {
    "current_cases_per_task_type": 4,
    "growth_policy": "Expand incrementally from the gold set rather than jumping to a large corpus."
  },
  "checkpoint_telemetry": {
    "persist_to": "vault/projects/<repo>/benchmark-log.md",
    "fields": [
      "task_type",
      "lane",
      "verification_profile",
      "outcome",
      "gate_summary",
      "retries",
      "rollback_used",
      "files_changed_when_known",
      "helpers_used",
      "helper_models",
      "helper_durations_when_known",
      "reviewer_findings_when_present",
      "duration_minutes_when_known"
    ],
    "fabrication_forbidden": true
  },
  "aggregation": {
    "summary_script": ".opencode/scripts/aggregate-benchmark-telemetry.sh",
    "report_path": "vault/protocols/opencode/evals/benchmark-reports/"
  },
  "runtime_simulations": {
    "enabled": true,
    "script": ".opencode/scripts/run-runtime-simulations.sh",
    "cases": [
      "DEBUG-001",
      "FAST-001",
      "STANDARD-001",
      "HIGH-RISK-001"
    ]
  },
  "adversarial_harness": {
    "enabled": true,
    "script": ".opencode/scripts/run-adversarial-harness.sh",
    "cases": [
      "APPROVAL-BYPASS-001",
      "CAPABILITY-ESCALATION-001",
      "EVIDENCE-BYPASS-001",
      "PROMPT-INJECTION-001",
      "RUNTIME-CONFLICT-001",
      "SENSITIVE-SAST-001"
    ]
  }
}
```

## quality_gates

Gate ordering, verdicts, and additional gate definitions. The actual gate enforcement is in `.opencode/commands/gates.md` and `.opencode/config/gate-matrix.yaml`.

```json
{
  "order": ["lint", "typecheck", "test", "build"],
  "order_note": "Core gates enforced by /gates command. Optional/future gates (sast, performance, lighthouse) defined in additional_gates but not enforced by default.",
  "max_retries": 3,
  "verdicts": ["APPROVED", "SOFT_ISSUES", "HARD_BLOCKER"],
  "feedback_loop_limit": 2,
  "script_validation": {
    "enabled": true,
    "echo_only_detection": true,
    "echo_only_verdict": "PLACEHOLDER",
    "real_tooling_verdict": "VERIFIED",
    "missing_script_verdict": "SKIPPED",
    "warning_rule": "If a gate script starts with 'echo' or is a no-op: warn 'Gate [name] uses echo-only script — no real verification'. Report verification quality in gate output."
  },
  "additional_gates": {
    "sast": {
      "enabled": true,
      "enforced": true,
      "note": "Scoped security gate — enforced by /gates for stateful-sensitive work when sensitive paths, dependency manifests, or exposed API surfaces changed.",
      "tool": "semgrep",
      "command": "semgrep --config auto --error",
      "scope": "sensitive_paths_only"
    },
    "performance": {
      "enabled": false,
      "enforced": false,
      "note": "Performance gate — advisory only in v4.9.0. Not enforced by default."
    },
    "lighthouse": {
      "enabled": false,
      "enforced": false,
      "note": "Lighthouse gate — advisory only. Not enforced by default."
    }
  }
}
```

## context_loading

Progressive context loading triggers. The actual loading behavior is defined in `.opencode/AGENTS.md` startup sequence.

```json
{
  "policy": "progressive",
  "on_demand_triggers": {
    "repo_selection_ambiguous": "read WORKSPACE_MAP.md",
    "repo_structure_unclear": "spawn Explorer or read file tree",
    "task_overlaps_lesson_keywords": "read vault/projects/<repo>/lessons.md",
    "cross_repo_work": "read dependent repo AGENTS.md before switching",
    "roadmapping_relevant": "read ROADMAP.md",
    "durable_memory_relevant": "read vault/owner-memory/index.md and vault/owner-memory/log.md, then only relevant pages"
  },
  "max_files_before_first_edit": 3,
  "max_lines_per_read": 300
}
```

## orchestrator_intelligence

Orchestrator intelligence classification. The actual routing is in `orchestrator_mode` in brain-config.json.

```json
{
  "classification": ["HOTFIX", "FEATURE", "REFACTOR", "RESEARCH", "DEPLOY", "DESIGN"],
  "complexity_scoring": "1-10+ scale",
  "claim_verification": ["VERIFIED", "INFERRED", "OUT-OF-SCOPE"],
  "separation_principle": "Separate contract blockers from deployment gaps and polish"
}
```

## automation

Automation configuration. Currently minimal.

```json
{
  "enabled": false,
  "note": "Automation features are deferred to v5.0. No automated PR creation, merge, or deploy without explicit owner approval."
}
```
