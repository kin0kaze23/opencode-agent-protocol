# NOW.md — v5.0.1 Public Hardening

**Status:** ACTIVE
**Last Updated:** 2026-07-11

## Current Task

v5.0.1 — Public hardening + privacy scan regression. Variant-aware public-surface scan added, 149 missed personal project name references anonymized, publication exclusions enforced, issue templates added, README/CHANGELOG fixed.

## Progress

- ✅ v5.0.0: Public baseline published (clean tree, no v4 history, no vault)
- ✅ v5.0.1: Public hardening + privacy scan regression (this release)
  - Added scripts/public-surface-scan.sh with variant-aware patterns
  - Anonymized 149 missed personal project name references
  - Added publication exclusions to .gitignore (vault/, reports/, .paperclip/)
  - Added issue templates (bug_report.md, feature_request.md)
  - Fixed README (removed vault refs, submodule, stale version)
  - Fixed CHANGELOG (removed vault refs, added v5.0.0/v5.0.1)
  - Updated PUBLICATION_POLICY.md with variant-aware exclusion list
  - Fresh-clone validated with public-surface-scan.sh

## Status: v5.0.1 Public Hardening Complete

## Next Steps

1. Feature development can resume on the public repo
2. External feedback collection
3. Case studies and public examples
