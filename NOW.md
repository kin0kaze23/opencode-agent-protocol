# NOW.md — v5.5.3 Fresh-Clone Runtime Install Hardening

**Status:** ACTIVE
**Last Updated:** 2026-07-14

## Current Task

v5.5.3 — Fresh-clone runtime install hardening. Fixed cross-platform launcher, package metadata, stale submodule docs, provider/model placeholders, and first-run setup friction.

## Progress

- ✅ v5.0.0–v5.5.2: Public baseline through harness/loop onboarding
- ✅ v5.5.3: Fresh-Clone Runtime Install Hardening (this release)
  - P0: Fixed `opencode-safe-launch.sh` for Linux (OS detection, `/proc/meminfo`, `stat -c %Y`, `date -d`)
  - P1: Added `.opencode/package.json` matching existing `package-lock.json`
  - P2: Removed stale `git submodule update` and vault references from QUICKSTART and INSTALLATION
  - P3: Replaced author-specific model IDs with `YOUR_PROVIDER/YOUR_*_MODEL` placeholders in `opencode.json`
  - P4: Added `scripts/setup.sh` — first-run setup script (OS detection, prerequisites, aliases, provider check)
  - P5: Updated README, QUICKSTART, INSTALLATION, FIRST_RUN_CHECKLIST with setup.sh and cross-platform docs
  - P6: Added MCP first-run documentation to QUICKSTART, INSTALLATION, FIRST_RUN_CHECKLIST
  - P8: Updated CLAIMS.md with cross-platform, setup script, and placeholder model claims
  - Fresh-clone validated

## Status: v5.5.3 Complete — Ready for External Review

## Next Steps

1. Merge PR to main
2. Tag v5.5.3 and create GitHub Release
3. Launch external review pilot (invite 3–5 reviewers)
4. Start daily dogfooding with measurement log
5. v5.6.0 after real feedback arrives
