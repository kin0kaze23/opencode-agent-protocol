# Release Checklist

> **Use this checklist for every public release.**

## Pre-Release

- [ ] Run `bash scripts/public-surface-scan.sh` — must PASS
- [ ] Run `bash scripts/verify-install.sh` — must PASS
- [ ] Run `bash .opencode/scripts/validate-protocol-atlas.sh` — must PASS
- [ ] Run `bash .opencode/conformance/tests/protocol-atlas.sh` — must PASS
- [ ] Run `bash .opencode/conformance/tests/production-hardening.sh` — must PASS
- [ ] Run `bash .opencode/conformance/tests/loop-controller.sh` — must PASS
- [ ] Run `bash .opencode/conformance/tests/model-roi.sh` — must PASS
- [ ] Verify no `vault/` directory present
- [ ] Verify no `reports/` directory present
- [ ] Verify no `.paperclip/` directory present
- [ ] Verify no personal project names in any file (run privacy scan)
- [ ] Verify no personal identity strings in any file
- [ ] Verify no secrets patterns in any file
- [ ] Verify no v4 history dependency (no v4.x tags in the public repo)

## Version Updates

- [ ] Update `NOW.md` with new version and status
- [ ] Update `CHANGELOG.md` with new release entry
- [ ] Update `docs/protocol/PROTOCOL_ATLAS.md` version
- [ ] Update `README.md` protocol version
- [ ] Verify version consistency across all version-bearing files

## Tag and Release

- [ ] Commit with conventional message: `release: vX.Y.Z <description>`
- [ ] Push to main (via PR merge, not direct push)
- [ ] Create annotated tag: `git tag -a vX.Y.Z -m "vX.Y.Z — <description>"`
- [ ] Push tag: `git push origin vX.Y.Z`
- [ ] Create GitHub Release with release notes
- [ ] Confirm release URL is accessible

## Post-Release Validation

- [ ] Fresh clone: `git clone https://github.com/kin0kaze23/opencode-agent-protocol.git`
- [ ] Run `bash scripts/public-surface-scan.sh` from fresh clone — must PASS
- [ ] Run `bash scripts/verify-install.sh` from fresh clone — must PASS
- [ ] Run full conformance suite from fresh clone — must PASS
- [ ] Verify `git tag -l` shows the new tag
- [ ] Verify GitHub Release page shows the new release
- [ ] Verify public clone instructions in README work correctly
