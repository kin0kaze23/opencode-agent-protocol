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

The following checks from `.github/workflows/validation.yml` must pass before merge. CI runs on both Ubuntu and macOS (matrix strategy), so each check has two variants:

| Check name (Ubuntu) | Check name (macOS) |
|---------------------|---------------------|
| `Privacy Scan (ubuntu-latest)` | `Privacy Scan (macos-latest)` |
| `Docs Drift (ubuntu-latest)` | `Docs Drift (macos-latest)` |
| `Config Schema (ubuntu-latest)` | `Config Schema (macos-latest)` |
| `Claims & Evidence (ubuntu-latest)` | `Claims & Evidence (macos-latest)` |
| `Public Sync (ubuntu-latest)` | `Public Sync (macos-latest)` |
| `Protocol Conformance (ubuntu-latest)` | `Protocol Conformance (macos-latest)` |

All 12 checks are required by branch protection. A PR cannot merge until all 12 pass.

### How to Configure

1. Go to **Settings → Branches** on GitHub
2. Click **Add branch protection rule** (or edit existing)
3. Branch name pattern: `main`
4. Check the boxes per the table above
5. In "Require status checks to pass before merging", select all 12:
   - `Privacy Scan (ubuntu-latest)` / `Privacy Scan (macos-latest)`
   - `Docs Drift (ubuntu-latest)` / `Docs Drift (macos-latest)`
   - `Config Schema (ubuntu-latest)` / `Config Schema (macos-latest)`
   - `Claims & Evidence (ubuntu-latest)` / `Claims & Evidence (macos-latest)`
   - `Public Sync (ubuntu-latest)` / `Public Sync (macos-latest)`
   - `Protocol Conformance (ubuntu-latest)` / `Protocol Conformance (macos-latest)`
6. Click **Create** or **Save changes**

Alternatively, use GitHub Rulesets (Settings → Rules → Rulesets) for the same configuration with more flexibility.

### v5.5.4 Branch Protection Update

v5.5.4 added the `Public Sync` CI job. Maintainers must update branch protection to require the two new checks:

- `Public Sync (ubuntu-latest)`
- `Public Sync (macos-latest)`

Without this update, the drift detector can fail without blocking merges, defeating the purpose of v5.5.4.

## Merge Policy

- Squash merges preferred for clean history
- PR title should follow conventional commits format
- All CI checks must pass (12/12)
- No secrets or personal data in diffs (enforced by privacy scan)
- No author-specific content in control files (enforced by public sync validation)

## Release Process

See [docs/RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) for the full release checklist.
