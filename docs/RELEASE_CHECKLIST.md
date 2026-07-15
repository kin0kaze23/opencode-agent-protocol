# Release Checklist

> **Use this checklist for every public release.**

## Pre-Release

### Privacy & Sanitization

- [ ] Run `bash scripts/public-surface-scan.sh` — must PASS
- [ ] Run `bash scripts/validate-public-sync.sh` — must PASS (v5.5.4+)
- [ ] Verify no `vault/` directory present
- [ ] Verify no `reports/` directory present
- [ ] Verify no `.paperclip/` directory present
- [ ] Verify no personal project names in any file (run privacy scan)
- [ ] Verify no personal identity strings in any file
- [ ] Verify no secrets patterns in any file
- [ ] Verify no author-specific model IDs in control files (run public sync validation)
- [ ] Verify no v4 history dependency (no v4.x tags in the public repo)

### Validation Scripts

- [ ] Run `bash scripts/verify-install.sh` — must PASS
- [ ] Run `bash scripts/validate-docs-drift.sh` — must PASS
- [ ] Run `bash scripts/validate-config-schema.sh` — must PASS
- [ ] Run `bash scripts/validate-claims-evidence.sh` — must PASS
- [ ] Run `bash .opencode/scripts/validate-protocol-atlas.sh` — must PASS

### Conformance Tests

- [ ] Run `bash .opencode/conformance/tests/protocol-atlas.sh` — must PASS
- [ ] Run `bash .opencode/conformance/tests/production-hardening.sh` — must PASS
- [ ] Run `bash .opencode/conformance/tests/loop-controller.sh` — must PASS
- [ ] Run `bash .opencode/conformance/tests/model-roi.sh` — must PASS

## Version Updates

- [ ] Update `NOW.md` with new version and status
- [ ] Update `CHANGELOG.md` with new release entry
- [ ] Update `docs/protocol/PROTOCOL_ATLAS.md` version
- [ ] Update `README.md` protocol version
- [ ] Verify version consistency across all version-bearing files (run `validate-public-sync.sh`)

## CI & Branch Protection

- [ ] Confirm all 12 CI checks pass on the PR (6 jobs × 2 environments)
- [ ] Confirm branch protection requires all 12 checks (including Public Sync)
- [ ] Confirm no stale or missing required checks

## Tag and Release

- [ ] Commit with conventional message: `release: vX.Y.Z <description>`
- [ ] Push to main (via PR merge, not direct push)
- [ ] Create annotated tag: `git tag -a vX.Y.Z -m "vX.Y.Z — <description>"`
- [ ] Push tag: `git push origin vX.Y.Z`
- [ ] Create GitHub Release with release notes
- [ ] Confirm release URL is accessible

## Post-Release Validation (Fresh Clone)

- [ ] Fresh clone: `git clone https://github.com/kin0kaze23/opencode-agent-protocol.git`
- [ ] Run `bash scripts/setup.sh --check` from fresh clone — must PASS
- [ ] Run `bash scripts/public-surface-scan.sh` from fresh clone — must PASS
- [ ] Run `bash scripts/validate-public-sync.sh` from fresh clone — must PASS
- [ ] Run `bash scripts/validate-docs-drift.sh` from fresh clone — must PASS
- [ ] Run `bash scripts/validate-config-schema.sh` from fresh clone — must PASS
- [ ] Run `bash scripts/validate-claims-evidence.sh` from fresh clone — must PASS
- [ ] Run `bash scripts/verify-install.sh` from fresh clone — must PASS
- [ ] Run full conformance suite from fresh clone — must PASS
- [ ] Verify `git tag -l` shows the new tag
- [ ] Verify GitHub Release page shows the new release
- [ ] Verify public clone instructions in README work correctly
