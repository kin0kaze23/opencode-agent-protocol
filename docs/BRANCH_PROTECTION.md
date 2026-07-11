# Branch Protection Guidance

> **How to configure GitHub branch protection to make the Release Gate merge-protective.**
> **Version:** v4.36

## Overview

The Release Gate workflow can block high-risk PRs, but GitHub only prevents merging if the repository's branch protection rules require the Release Gate check. This document explains how to configure branch protection to make the harness fully merge-protective.

## Required Branch Protection Rules

For the `main` branch (or any protected branch):

### 1. Require the Release Gate check

**Settings → Branches → Branch protection rules → Edit → Require status checks to pass before merging**

Add these required checks:
- `Release Gate` — The PR release gate with reviewer evidence enforcement
- `build` — Build and doctor checks
- `ui_smoke` — UI smoke tests (if applicable)

### 2. Require approving reviews

- **Require approvals:** At least 1 approval before merging
- This works alongside the Release Gate's reviewer evidence enforcement

### 3. Dismiss stale approvals

- **Dismiss stale pull request approvals when new commits are pushed:** Enable
- This ensures approvals on older commits don't count after new changes
- The v4.36 detector also checks approval freshness as defense-in-depth

### 4. Restrict who can push to main

- **Restrict who can push to matching branches:** Only admins and maintainers
- No direct pushes to main — all changes through PRs

### 5. Restrict label management (recommended)

- The `reviewer-approved` label is only trusted if only maintainers/admins can apply it
- If any contributor can add labels, the label evidence is weak
- Consider restricting label creation and management to maintainers

## Fork PR Considerations

For PRs from forks:
- The `GITHUB_TOKEN` in GitHub Actions has read access to PR reviews and labels for fork PRs
- If the token lacks permissions, the detector fails safely (reports "no evidence found")
- High-risk fork PRs will be blocked until a maintainer provides reviewer evidence

## Verification

After configuring branch protection:

1. Create a high-risk PR without reviewer evidence → should be blocked
2. Add reviewer evidence (approving review or `reviewer-approved` label) → should pass
3. Push a new commit after approval → stale approval should be dismissed
4. Try to merge without the Release Gate passing → should be prevented by GitHub

## Related

| Resource | Location |
|----------|----------|
| PR Release Gate docs | `docs/PR_RELEASE_GATE.md` |
| Reviewer trust policy | `.opencode/config/reviewer-trust-policy.yaml` |
| Release gate workflow | `.github/workflows/pr-release-gate.yml` |
| Protocol snapshot | `vault/protocols/opencode/snapshots/v4.36/protocol.md` |
