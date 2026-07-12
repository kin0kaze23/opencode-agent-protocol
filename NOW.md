# NOW.md — v5.5.1 Public Runtime Onboarding + Portability Clarification

**Status:** ACTIVE
**Last Updated:** 2026-07-11

## Current Task

v5.5.1 — Public runtime onboarding + portability clarification. Clarified that the public repo is a protocol layer requiring OpenCode. Added own-model setup guide, config templates, validation tiers, sync policy, and dogfooding log template. Cleaned internal-only references from AGENTS.md and rules.md.

## Progress

- ✅ v5.0.0–v5.5.0: Public baseline through external review pilot
- ✅ v5.5.1: Public runtime onboarding + portability clarification (this release)
  - Updated README with prerequisites and positioning clarification
  - Added docs/OWN_MODEL_SETUP.md (provider-agnostic setup guide)
  - Added examples/config/ templates (brain-config, model-routing, opencode.json)
  - Cleaned AGENTS.md and rules.md of internal-only references (vault, owner-memory, WORKSPACE_MAP)
  - Updated docs/VALIDATION.md with test tier classification (Tier 1/2/3)
  - Added docs/PUBLIC_SYNC_POLICY.md
  - Added docs/DOGFOODING_LOG_TEMPLATE.md
  - Updated docs/CLAIMS.md with new allowed/disallowed claims
  - Fresh-clone validated

## Status: v5.5.1 Complete — External Review Can Begin With Less Onboarding Risk

## Next Steps

1. Launch external review pilot (invite 3–5 reviewers)
2. Start daily dogfooding with measurement log
3. v5.6.0 after real feedback arrives
