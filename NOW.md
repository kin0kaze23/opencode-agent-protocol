# NOW.md — v5.3.0 Config Schema Validation + Docs Drift Checks

**Status:** ACTIVE
**Last Updated:** 2026-07-11

## Current Task

v5.3.0 — Config schema validation + docs drift checks. Added 3 new validation scripts, expanded CI to 5 jobs, created validation docs.

## Progress

- ✅ v5.0.0–v5.2.0: Public baseline through evidence pack
- ✅ v5.3.0: Config schema validation + docs drift checks (this release)
  - Added scripts/validate-docs-drift.sh (117 checks: file refs, version consistency, diagrams, links)
  - Added scripts/validate-config-schema.sh (40 checks: required files, JSON/YAML validity, agent roles, CI jobs)
  - Added scripts/validate-claims-evidence.sh (17 checks: disallowed patterns, evidence docs, case studies)
  - Expanded CI from 2 jobs to 5 jobs (Privacy Scan, Docs Drift, Config Schema, Claims & Evidence, Protocol Conformance)
  - Added docs/VALIDATION.md
  - Fixed 1 real docs drift issue (git-guard.md reference in Capability Catalog)
  - Fresh-clone validated

## Status: v5.3.0 Complete

## Next Steps

1. External review readiness (v5.4)
2. Multi-environment install tests
