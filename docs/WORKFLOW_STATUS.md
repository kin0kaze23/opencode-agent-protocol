# CI Workflow Status

> **Purpose map for all GitHub Actions workflows in the control-plane repo.**
> Last updated: v4.28.2

## Workflows

| Workflow | File | Trigger | Status | Purpose |
|---|---|---|---|---|
| Protocol Conformance | `.github/workflows/protocol-conformance.yml` | `pull_request` (paths: `.opencode/**`, `scripts/**`, `docs/**`) + `workflow_dispatch` | **Active** | Runs protocol conformance suite on PRs that touch protocol files. Required for merge. |
| OpenCode Conformance (Legacy) | `.github/workflows/opencode-conformance.yml` | `workflow_dispatch` + `schedule` (daily 2 AM UTC) | **Legacy** | Superseded by `protocol-conformance.yml` for PR checks. Retained for manual dispatch and scheduled runs. PR trigger disabled in v4.28.1c to avoid duplicate failures. |
| Reusable Gates | `.github/workflows/gates.yml` | `workflow_call` only | **Active (reusable)** | Reusable gate workflow for individual repo CI. Called by repo `.github/workflows/ci.yml` via `uses:`. No standalone trigger — correctly skips on push to control-plane. |

## Notes

- `gates.yml` appears as "failure" on push events in GitHub Actions UI. This is expected: the workflow has `workflow_call` as its only trigger, so GitHub reports "no jobs ran" which displays as failure. This is not a real failure.
- `opencode-conformance.yml` is legacy. Do not re-enable its PR trigger. It duplicates `protocol-conformance.yml` with an older, less maintained test set.
- `protocol-conformance.yml` is the canonical CI gate for protocol changes. It runs on Ubuntu with `submodules: false` (no submodule checkout needed for protocol tests).
