# Maintainers Guide

> **Audience:** Repository maintainers and contributors with merge access.

## Branch Protection — Required GitHub Settings

After merging the CI workflow, configure branch protection rules on GitHub:

### Settings → Branches → Branch protection rules → main

| Rule | Required | Reason |
|------|----------|--------|
| Require a pull request before merging | Yes | Prevents direct pushes to main |
| Require approvals | Recommended (1+) | Ensures code review |
| Require status checks to pass | Yes | Blocks merges when CI fails |
| Require conversation resolution | Yes | Ensures all comments are resolved |
| Do not allow bypassing the above | Optional | Admins can override if needed |
| Allow force pushes | No | Protects history |
| Allow deletions | No | Protects branch |

### Required Status Checks

The following checks from `.github/workflows/validation.yml` must pass before merge:

- `Privacy Scan` — runs `scripts/public-surface-scan.sh`
- `Protocol Conformance` — runs install verification, Protocol Atlas, production hardening, loop controller, model ROI

### How to Configure

1. Go to **Settings → Branches** on GitHub
2. Click **Add branch protection rule**
3. Branch name pattern: `main`
4. Check the boxes per the table above
5. In "Require status checks to pass before merging", select:
   - `Privacy Scan`
   - `Protocol Conformance`
6. Click **Create**

Alternatively, use GitHub Rulesets (Settings → Rules → Rulesets) for the same configuration with more flexibility.

## Merge Policy

- Squash merges preferred for clean history
- PR title should follow conventional commits format
- All CI checks must pass
- No secrets or personal data in diffs (enforced by privacy scan)

## Release Process

See [docs/RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) for the full release checklist.
