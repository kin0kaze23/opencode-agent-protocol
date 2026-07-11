# OpenCode Agent Protocol

> **A safety-first OpenCode agent protocol for governed AI-assisted software development.**
> Classify risk, route to the right model, run bounded implementation loops, gate releases through CI and reviewer evidence, score outcomes, and improve routing over time.

> **Disclaimer:** This project is not affiliated with or endorsed by OpenCode unless otherwise stated. It is an independent protocol built on top of the OpenCode CLI.

[![Protocol Conformance](https://github.com/kin0kaze23/opencode-agent-protocol/actions/workflows/protocol-conformance.yml/badge.svg)](https://github.com/kin0kaze23/opencode-agent-protocol/actions/workflows/protocol-conformance.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## What This Is

This repository is the **control plane** for a multi-repo AI engineering workspace. It contains:

- **OpenCode protocol** (`.opencode/`) — behavioral rules, model routing, commands, scripts, conformance tests
- **Protocol Atlas** (`docs/protocol/PROTOCOL_ATLAS.md`) — visual system map with 10 Mermaid diagrams
- **Vault** (`vault/`) — knowledge base, lessons, decisions, protocol history
- **Conformance suite** — 818+ tests across 16 suites, 0 failures

It does **not** contain product code. Product code lives in individual repo directories.

## What Problem It Solves

AI coding agents are powerful but unsafe without guardrails. This protocol provides:

1. **Risk classification** — every task is classified by risk score (0-10+)
2. **Lane selection** — DIRECT, FAST, STANDARD, HIGH-RISK with different controls
3. **Model routing** — advisory recommendations based on eval evidence
4. **Bounded implementation** — touch lists, stop conditions, repair policies
5. **Release gates** — CI, sensitive change classifier, reviewer evidence
6. **Scoring** — 7 dimensions + 2 penalties, max 35, pass 24
7. **Learning** — lessons extracted to JSONL, model ROI tracked
8. **Routing improvement** — evidence-based recommendations feed back to routing

## Quick Start

```bash
# 1. Clone
git clone https://github.com/kin0kaze23/opencode-agent-protocol.git
cd opencode-agent-protocol
git submodule update --init --recursive

# 2. Add aliases (see docs/QUICKSTART.md)
# 3. Verify
bash scripts/verify-install.sh

# 4. Start
oc  # autopilot mode
```

See [docs/QUICKSTART.md](docs/QUICKSTART.md) for the 5-minute guide.

## Three Operating Modes

| Mode | Command | When to use |
|------|---------|-------------|
| Autopilot Daily | `oc` | Normal coding, UI, docs, tests, refactors |
| Manual Ship | `oc-manual` | Push, deploy, schema, CI, protocol, secrets |
| Fresh Start | `oc-fresh` | After protocol releases |

## Safety Posture

- **No auto-push** to main
- **No auto-merge** of PRs
- **No self-approval** of HIGH-RISK changes
- **No secrets** committed (gitleaks + .gitignore + pre-commit hooks)
- **All policies advisory** — routing and reviewer policies are never auto-applied
- **Protected repos excluded — always

See [SECURITY.md](SECURITY.md) for the full security policy.

## What Is Advisory vs Enforced

| Aspect | Advisory | Enforced |
|--------|----------|----------|
| Model routing | ✅ Recommendations only | — |
| Reviewer policy | ✅ Recommendations only | — |
| Risk classification | — | ✅ Lanes enforced |
| Pre-commit hooks | — | ✅ Secrets blocked |
| Release gates | — | ✅ CI + reviewer evidence |
| Protected repo exclusion — Always excluded |

## Documentation

| Document | Purpose |
|---|---|
| [docs/QUICKSTART.md](docs/QUICKSTART.md) | 5-minute quickstart |
| [docs/INSTALLATION.md](docs/INSTALLATION.md) | Detailed installation |
| [docs/OPERATING_GUIDE.md](docs/OPERATING_GUIDE.md) | Daily operating guide |
| [docs/VERSIONING.md](docs/VERSIONING.md) | Versioning policy |
| [docs/protocol/PROTOCOL_ATLAS.md](docs/protocol/PROTOCOL_ATLAS.md) | Visual system map |
| [CHANGELOG.md](CHANGELOG.md) | Public release summary |
| [RELEASES.md](RELEASES.md) | Release index and checklist |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |
| [SECURITY.md](SECURITY.md) | Security policy |

## Verification

```bash
# Install verification
bash scripts/verify-install.sh

# Protocol Atlas validation
bash .opencode/scripts/validate-protocol-atlas.sh

# Full conformance suite (16 suites, 818+ tests)
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh
bash .opencode/conformance/tests/model-roi.sh
```

## Protocol Version

**Current:** v4.54 — Repo Rename + Product Identity

See [CHANGELOG.md](CHANGELOG.md) for release summary and [vault/protocols/opencode/CHANGELOG.md](vault/protocols/opencode/CHANGELOG.md) for detailed history.

## License

[MIT](LICENSE) — Copyright (c) 2026 OpenCode Agent Protocol contributors
