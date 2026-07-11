# Quickstart

> **5-minute guide to get the OpenCode Agent Protocol running.**

## What You Need

- macOS or Linux
- [OpenCode](https://github.com/opencode-ai/opencode) CLI installed
- Git
- Python 3 (for conformance tests)
- A shell (bash or zsh)

## Step 1: Clone

```bash
git clone https://github.com/kin0kaze23/opencode-agent-protocol.git
cd opencode-agent-protocol
git submodule update --init --recursive
```

## Step 2: Add Shell Aliases

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Replace /path/to with your actual clone location
alias oc='bash /path/to/opencode-agent-protocol/.opencode/bin/autopilot'
alias oc-fresh='bash /path/to/opencode-agent-protocol/.opencode/bin/autopilot --fresh'
alias oc-manual='bash /path/to/opencode-agent-protocol/.opencode/scripts/opencode-safe-launch.sh'
```

Then: `source ~/.zshrc`

## Step 3: Verify Installation

```bash
bash scripts/verify-install.sh
```

This runs a 10-suite install verification.

## Step 4: Run Validation

```bash
bash .opencode/scripts/validate-protocol-atlas.sh
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh
```

All tests should pass.

## Step 5: Start OpenCode

```bash
# Autopilot mode (auto-approves safe operations, denies dangerous ones)
oc

# Fresh session (clears stale serve artifacts)
oc-fresh

# Manual mode (all permissions require approval)
oc-manual
```

## What's Safe

- **Autopilot (`oc`)**: Auto-approves file edits, lint, test, build. Denies secrets, packages, schema, CI, deploy, raw git mutations.
- **Manual (`oc-manual`)**: All permissions require your approval. Use for push, deploy, schema, CI, protocol, or secrets changes.

## What's Advisory

- Model routing recommendations are advisory only (`auto_applied: false`)
- Reviewer policy recommendations are advisory only (`auto_applied: false`)
- You must manually review and apply routing changes

## Next Steps

- Read [INSTALLATION.md](INSTALLATION.md) for detailed setup
- Read [OPERATING_GUIDE.md](OPERATING_GUIDE.md) for daily usage
- Read the [Protocol Atlas](docs/protocol/PROTOCOL_ATLAS.md) for system overview
- Read [VERSIONING.md](VERSIONING.md) for version policy
