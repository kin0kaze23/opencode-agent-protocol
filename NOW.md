# NOW.md — v4.55.1 Public Surface Privacy Scrub

**Status:** ACTIVE
**Last Updated:** 2026-07-11

## Current Task

v4.55.1 — Public surface privacy scrub. Identity scrubbed, publication policy created, history risk assessed.

## Progress

- ✅ v4.50-v4.55: Core v1 hardened through tag normalization
- ✅ v4.55.1: Public Surface Privacy Scrub (this task)
  - P0: Personal identity scrubbed (LICENSE, README, gates.yml, evidence.yaml, reports)
  - P1: 100 .opencode/ files reference personal project names (needs anonymization for v5)
  - P2: Vault has 1,032 files with personal project names (must exclude from public)
  - P3: 14 report files reference personal project names
  - P4: No actual secrets found
  - P5: All v4.x tags contain personal content — NOT safe to publish full history
  - P6: docs/PUBLICATION_POLICY.md created
  - Recommendation: Create clean public v5 repo from sanitized HEAD

## Status: Privacy Scrub Complete — v5.0.0 Requires Clean Public Baseline

## Next Steps

1. v5.0.0 — Create clean public baseline from sanitized HEAD (no v4 history, no vault, anonymized project names)
