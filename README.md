# OpenCode Agent Protocol

> **A safety-first OpenCode agent protocol for governed AI-assisted software development.**
> Classify risk, route to the right model, run bounded implementation loops, gate releases through CI and reviewer evidence, score outcomes, and improve routing over time.

> **Disclaimer:** This project is not affiliated with or endorsed by OpenCode unless otherwise stated. It is an independent protocol built on top of the OpenCode CLI.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## What This Is

This repository contains the **OpenCode agent protocol** — behavioral rules, model routing, commands, scripts, conformance tests, and visual documentation for governing AI-assisted software development.

- **OpenCode protocol** (`.opencode/`) — behavioral rules, model routing, commands, scripts, conformance tests
- **Protocol Atlas** (`docs/protocol/PROTOCOL_ATLAS.md`) — visual system map with 11 Mermaid diagrams
- **Conformance suite** — 297+ tests across multiple suites, 0 failures

It does **not** contain product code. It is a protocol layer that sits on top of the OpenCode CLI.

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

# 2. Verify
bash scripts/verify-install.sh

# 3. Run conformance tests
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh

# 4. Run public-surface scan (privacy regression)
bash scripts/public-surface-scan.sh
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

See [SECURITY.md](SECURITY.md) for the full security policy.

## What Is Advisory vs Enforced

| Aspect | Advisory | Enforced |
|--------|----------|----------|
| Model routing | Recommendations only | — |
| Reviewer policy | Recommendations only | — |
| Risk classification | — | Lanes enforced |
| Pre-commit hooks | — | Secrets blocked |
| Release gates | — | CI + reviewer evidence |

## Documentation

| Document | Purpose |
|---|---|
| [docs/QUICKSTART.md](docs/QUICKSTART.md) | 5-minute quickstart |
| [docs/INSTALLATION.md](docs/INSTALLATION.md) | Detailed installation |
| [docs/OPERATING_GUIDE.md](docs/OPERATING_GUIDE.md) | Daily operating guide |
| [docs/VERSIONING.md](docs/VERSIONING.md) | Versioning policy |
| [docs/protocol/PROTOCOL_ATLAS.md](docs/protocol/PROTOCOL_ATLAS.md) | Visual system map |
| [docs/PUBLICATION_POLICY.md](docs/PUBLICATION_POLICY.md) | Publication policy |
| [docs/MAINTAINERS.md](docs/MAINTAINERS.md) | Maintainer guide and branch protection |
| [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) | Release checklist |
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

# Public-surface privacy scan
bash scripts/public-surface-scan.sh

# Conformance tests
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh
bash .opencode/conformance/tests/loop-controller.sh
bash .opencode/conformance/tests/model-roi.sh
```

## Protocol Version

**Current:** v5.0.2 — Public CI + Branch Protection Gate

See [CHANGELOG.md](CHANGELOG.md) for release history.

## License

[MIT](LICENSE) — Copyright (c) 2026 OpenCode Agent Protocol contributors
