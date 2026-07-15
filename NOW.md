# NOW.md — v5.5.4 Public Drift Hardening + Sync Guardrails

**Status:** ACTIVE
**Last Updated:** 2026-07-15

## Current Task

v5.5.4 — Public drift hardening + sync guardrails. Sanitized public-facing control files of author-specific content, synced Visual QA protocol from internal repo, added automated drift detection script.

## Progress

- ✅ v5.0.0–v5.5.3: Public baseline through fresh-clone runtime install hardening
- ✅ v5.5.4: Public Drift Hardening + Sync Guardrails (this release)
  - P1: Synced Visual QA protocol to visual-reviewer agent definitions and prompt mirrors
  - P2: Added scripts/validate-public-sync.sh — drift detection script
  - P3: Sanitized AGENTS.md, rules.md, helper-roster.md of all author-specific content
  - P4: Added public-sync-validation job to CI
  - P5: Created docs/PUBLIC_SYNC_MANIFEST.md
  - P6: Updated version files to v5.5.4

## Status: v5.5.4 Complete — Ready for External Review

## Next Steps

1. Merge PR to main
2. Tag v5.5.4 and create GitHub Release
3. Launch external review pilot (invite 3–5 reviewers)
4. Start daily dogfooding with measurement log
5. v5.6.0 after real feedback arrives
