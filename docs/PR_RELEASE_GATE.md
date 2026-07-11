# PR Release Gate

> **How to read the PR release gate summary in your pull requests.**
> **Version:** v4.35

## Overview

The PR release gate runs automatically on pull requests that touch protocol, source, or configuration files. It uses the v4.33 content-aware sensitive change classifier, the v4.32 release decision report, and the v4.35 reviewer evidence detector to provide a structured summary of risk, release readiness, and enforcement status.

The gate appears as a GitHub Actions check called **Release Gate** on your PR. It also writes a **Release Gate Summary** to the PR's Job Summary section, visible in the PR Checks UI.

## v4.35 Reviewer Evidence Enforcement

Starting with v4.35, the release gate enforces reviewer evidence for high-risk sensitive PRs:

- **High-risk + no trusted reviewer evidence → BLOCK** (exit 1, PR cannot merge)
- **High-risk + trusted reviewer evidence → advisory** (exit 0, summary recommends full tests)
- **Medium-risk → advisory** (exit 0, reviewer recommended)
- **Low-risk → pass** (exit 0, no action needed)

### Trusted Reviewer Evidence Sources

The gate accepts the following as trusted reviewer evidence:

1. **GitHub PR review approval** — An `APPROVED` review state from any reviewer
2. **Maintainer-applied label** — The `reviewer-approved` label applied to the PR

### Not Trusted

The following are NOT accepted as reviewer evidence:

- PR body text claiming reviewer was used
- Changed telemetry files in the PR diff
- Any file modified by the PR author claiming approval
- Comments or suggestions (only `APPROVED` review state counts)

### How to Provide Reviewer Evidence

**Option 1: Submit a GitHub approving review**
```bash
gh pr review <PR_NUMBER> --approve --body "Reviewed and approved"
```

**Option 2: Apply the reviewer-approved label**
```bash
gh pr edit <PR_NUMBER> --add-label reviewer-approved
```

Once evidence is provided, re-run the Release Gate workflow (or push a new commit) to re-check.

## When It Runs

The release gate triggers on pull requests that change files in:
- `.opencode/**` — protocol scripts, configs, tests
- `.github/workflows/**` — CI/CD workflows
- `scripts/**` — utility scripts
- `docs/**` — documentation
- `src/**`, `app/**`, `lib/**` — source code
- `NOW.md`, `AGENTS.md`, `RELEASES.md` — root protocol files

PRs that only change unrelated files (e.g., `README.md` at root) will not trigger the gate.

## How to Read the Summary

The job summary contains a structured table and sections:

### Summary Table

| Field | Meaning |
|-------|---------|
| **Release Status** | `✅ pass` — safe to merge. `⚠️ advisory` — sensitive changes detected, review before merge. `🚫 block` — blocking policy violation, cannot merge. |
| **Risk Level** | `🟢 none` — no sensitive changes. `🟡 medium` — medium-risk paths/content. `🔴 high` — high-risk paths/content (auth, secrets, payments). |
| **Detection Type** | `path` — sensitive path detected. `content` — sensitive content detected in diff. `path+content` — both. `none` — no detection. `manual` — manual override applied. |
| **Classifier Detected Sensitive** | `true` if the classifier found any sensitive patterns. |
| **Reviewer Required** | `Yes` if the classifier requires a reviewer (high or medium risk). `No` for low-risk PRs. |
| **Tests Required** | `Yes` if full test suite is required (high risk). `No` for low/medium risk. |

### Sensitive Areas

Lists the sensitive areas detected: `auth`, `security`, `secrets`, `payments`, `schema`, `deployment`, `pii`, `storage`.

### Matched Sensitive Patterns

Lists the specific content patterns that triggered detection: `VITE_E2E`, `SignedIn`, `ClerkProvider`, `API_KEY`, etc.

### Classifier Reason

Human-readable explanation of why the classifier made its determination.

### Allowed Failures

Lists any allowed failures configured in the repo. Allowed failures must have explicit signature, owner, reason, expiry, and follow-up.

### Expiry Warnings

Warns if an allowed failure has expired or will expire within 7 days. **Expired failures block the PR.**

### Owner Next Action

Clear guidance on what the PR author or reviewer should do next:
- `✅ No action required — safe to merge.`
- `⚠️ Sensitive changes detected. Ensure reviewer approval and full tests pass before merge.`
- `🚫 BLOCKED: Resolve expired allowed failure or policy violation before merge.`

## Blocking vs Advisory

### Blocking (PR cannot merge)

- **Expired allowed failures** — `release_status: block`
- **High-risk sensitive change without trusted reviewer evidence** — enforcement status: block
- The workflow exits with code 1, failing the required check

### Advisory (PR can merge, but review recommended)

- **High-risk sensitive change with trusted reviewer evidence** — enforcement status: advisory
- **Medium-risk sensitive changes** — `risk_level: medium`
- The workflow exits with code 0, but the summary recommends reviewer approval

### Pass (PR can merge, no action needed)

- **No sensitive changes** — `risk_level: none`
- The workflow exits with code 0

## Artifact

The full release decision report is uploaded as a workflow artifact named `release-decision-report`. It is retained for 30 days and can be downloaded from the workflow run page.

## Manual Override

If the classifier produces a false negative (misses a sensitive change), a manual override can be applied locally:

```bash
bash .opencode/scripts/sensitive-change-classifier.sh --files <file> --manual-override --manual-override-reason "description of false negative"
```

This sets `detection_type: manual` and forces high-risk classification. The override reason is visible in the release decision report.

## Local Testing

To test the release gate locally before pushing:

```bash
# Test against specific files
bash .opencode/scripts/sensitive-change-classifier.sh --files <file1> <file2>

# Test against a diff
bash .opencode/scripts/sensitive-change-classifier.sh --diff origin/main...HEAD

# Generate a full release decision report
bash .opencode/scripts/release-decision-report.sh --diff origin/main...HEAD --repo .
```

## Related

| Resource | Location |
|----------|----------|
| Classifier script | `.opencode/scripts/sensitive-change-classifier.sh` |
| Release report script | `.opencode/scripts/release-decision-report.sh` |
| Gate action script | `.opencode/scripts/pr-release-gate-action.sh` |
| Workflow | `.github/workflows/pr-release-gate.yml` |
| Conformance test | `.opencode/conformance/tests/pr-release-gate.sh` |
| Protocol snapshot | `vault/protocols/opencode/snapshots/v4.34/protocol.md` |
