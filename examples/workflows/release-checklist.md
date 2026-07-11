# Example: Release Checklist Flow

> **Scenario:** A maintainer wants to release v5.2.0.

## User Task

Cut a new release following the release checklist.

## Steps

### 1. Pre-Release Validation

```bash
# Run all checks locally
bash scripts/public-surface-scan.sh
bash .opencode/scripts/validate-protocol-atlas.sh
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh
bash .opencode/conformance/tests/loop-controller.sh
bash .opencode/conformance/tests/model-roi.sh
```

All must pass.

### 2. Verify No Forbidden Directories

```bash
ls vault reports .paperclip 2>/dev/null
# Expected: not found
```

### 3. Update Version Files

- `NOW.md` — new version and status
- `CHANGELOG.md` — new release entry
- `README.md` — protocol version
- `docs/protocol/PROTOCOL_ATLAS.md` — version

### 4. Create PR

```bash
git checkout -b release/v5.2.0
git add -A
git commit -m "release: v5.2.0 <description>"
git push origin release/v5.2.0
gh pr create --title "release: v5.2.0" --body "..."
```

### 5. Wait for CI

Both checks must pass:
- Privacy Scan
- Protocol Conformance

### 6. Merge and Tag

```bash
gh pr merge --squash --delete-branch
git checkout main && git pull
git tag -a v5.2.0 -m "v5.2.0 — <description>"
git push origin v5.2.0
```

### 7. Create GitHub Release

```bash
gh api repos/kin0kaze23/opencode-agent-protocol/releases -X POST \
  -f tag_name="v5.2.0" \
  -f name="v5.2.0 — <description>" \
  -f body="<release notes>" \
  -F draft=false -F prerelease=false
```

### 8. Fresh-Clone Validation

```bash
git clone https://github.com/kin0kaze23/opencode-agent-protocol.git /tmp/test
cd /tmp/test
bash scripts/public-surface-scan.sh
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh
bash .opencode/conformance/tests/loop-controller.sh
bash .opencode/conformance/tests/model-roi.sh
```

## What CI Enforces

| Check | What it does |
|-------|-------------|
| Privacy Scan | Ensures no personal data in the release |
| Protocol Conformance | Ensures all protocol tests pass |

## Safety Notes

- Never push directly to main — always use a PR
- Never skip the fresh-clone validation
- Follow `docs/RELEASE_CHECKLIST.md` for the full checklist
