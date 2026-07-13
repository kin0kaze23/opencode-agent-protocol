# Contributing

Thank you for your interest in contributing to the OpenCode Agent Protocol!

## How to Contribute

### Issues

- Search existing issues before opening a new one
- Provide a clear title and description
- Include reproduction steps for bugs
- Tag with appropriate labels

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Make your changes
4. Run validation (see below)
5. Commit with conventional messages: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`
6. Open a PR against `kin0kaze23/opencode-agent-protocol`

### Repository Workflow

All changes follow this operating model:

1. **Branch** — create a feature branch from `main`
2. **Pull request** — open a PR with a clear description and validation evidence
3. **Validation** — all ten required CI checks must pass (Privacy Scan, Docs Drift, Config Schema, Claims & Evidence, Protocol Conformance — each on Ubuntu and macOS)
4. **Squash merge** — only squash merges are allowed; merge commits and rebase merges are disabled
5. **Branch deletion** — the feature branch is automatically deleted after merge

Direct pushes to `main` are blocked. Force pushes and branch deletion are also blocked.

### Tests Required

All PRs must pass the conformance suite:

```bash
# Run the full validation suite
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh
bash .opencode/conformance/tests/model-roi.sh
bash .opencode/conformance/tests/loop-controller.sh
bash .opencode/conformance/tests/task-replay.sh
```

### Release Gate

- All changes go through PR review
- Pre-commit hooks scan for secrets and block internal working files
- No PR is auto-merged
- HIGH-RISK changes require reviewer evidence

### Rules

- **No secrets** — never commit API keys, tokens, or credentials
- **No generated artifacts** — eval results, fleet snapshots, and conformance results are `.gitignored`
- **No machine-specific paths** — use `$HOME`, `$WORKSPACE_ROOT`, or relative paths
- **Update Protocol Atlas** when flows, diagrams, or components change
- **Run `validate-protocol-atlas.sh`** after Atlas changes
- **Keep policies advisory** — routing and reviewer policies must remain `auto_applied: false`

### Code Style

- Shell scripts: `set -euo pipefail`, use `$ROOT_DIR` for path resolution
- Python heredocs: pass `$ROOT_DIR` as environment variable, use `os.environ`
- Config files: use `${HOME}` for home directory references
- Documentation: use `$WORKSPACE_ROOT` in examples

### protected-repo

protected-repo is an archived repository that is always excluded from this protocol. Do not touch protected-repo in any contribution.
