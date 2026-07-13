# OpenCode Agent Protocol

> **A safety-first OpenCode agent protocol for governed AI-assisted software development.**
> Classify risk, route to the right model, run bounded implementation loops, gate releases through CI and reviewer evidence, score outcomes, and improve routing over time.

> **Disclaimer:** This project is not affiliated with or endorsed by OpenCode unless otherwise stated. It is an independent protocol built on top of the OpenCode CLI.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Status

Actively maintained. The protocol is production-oriented and versioned through tagged releases. Breaking changes are documented in the [changelog](CHANGELOG.md) and release notes.

## What This Is

This repository contains the **OpenCode agent protocol** — a protocol layer and AI engineering harness specification for governing AI-assisted software development with OpenCode.

**Important:** This is a **protocol specification**, not a bundled runtime. To use it as a working harness, you need:

- **OpenCode** installed as the runtime
- **Model API access** configured by you (OpenAI, Anthropic, or other providers)
- **Your own project repos** to apply the protocol to

Fresh-clone validation proves **protocol integrity** (files are valid, tests pass, no personal data). It does not prove that your models or providers are configured.

### Prerequisites

| Requirement | Purpose |
|-------------|---------|
| [OpenCode](https://github.com/opencode-ai/opencode) | Runtime that executes the protocol |
| git | Version control |
| bash 4+ | Script execution (validation, scanning, conformance tests) |
| Python 3 | Conformance tests |
| Node.js 18+ | MCP servers, sync scripts |
| jq | JSON processing in scripts |
| GitHub account | CI, branch protection, PR workflow |
| Model provider access | API keys for your chosen AI models (configured by you, not included) |

### What's Included

- **OpenCode protocol** (`.opencode/`) — behavioral rules, model routing, commands, scripts, conformance tests
- **Protocol Atlas** (`docs/protocol/PROTOCOL_ATLAS.md`) — visual system map with 11 Mermaid diagrams
- **Conformance suite** — 297+ tests across multiple suites, 0 failures
- **First-run setup script** (`scripts/setup.sh`) — detects OS, checks prerequisites, generates aliases

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

# 2. Run setup (checks prerequisites, generates aliases)
bash scripts/setup.sh

# 3. Verify
bash scripts/verify-install.sh

# 4. Run conformance tests
bash .opencode/conformance/tests/protocol-atlas.sh
bash .opencode/conformance/tests/production-hardening.sh

# 5. Run public-surface scan (privacy regression)
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

## How the Orchestrator and Sub-Agents Cooperate

The protocol defines a multi-agent topology where the orchestrator delegates to specialized helpers:

| Role | When used | What it does |
|------|-----------|-------------|
| **Orchestrator** | Always | Routes tasks, owns strategy, makes final decisions |
| **Planner** | Ambiguous, multi-step, high-risk work | Creates plans, validates readiness |
| **Implementer** | After approved touch list | Bounded code changes only |
| **Reviewer** | Risk 4+, sensitive paths, release gates | Independent quality check |
| **Architect** | Architecture, auth, schema, cross-surface design | Resolves high-ambiguity decisions |
| **Explorer** | Read-only discovery, cost/quota checks | Cheap routing classification |

**Model routing** assigns the right model to each role based on eval evidence. **CI** enforces privacy scan and protocol conformance on every PR. **Branch protection** prevents direct pushes to main.

See [docs/CAPABILITY_CATALOG.md](docs/CAPABILITY_CATALOG.md) for the full capability map and [docs/RUNTIME_MAP.md](docs/RUNTIME_MAP.md) for the runtime source-of-truth map.

## Evidence and Limitations

This protocol is **safety-first** but not **guaranteed safe**. It provides guardrails, not guarantees.

### What the protocol does

- CI-enforced privacy scanning on every PR
- Protocol conformance tests (297+ tests)
- Branch protection (PR required, no force push)
- Documented agent topology and model routing
- Repeatable release process with fresh-clone validation
- Cross-platform launcher (macOS + Linux)

### What the protocol does not do

- Guarantee code correctness (CI checks protocol, not product logic)
- Guarantee model quality (routing is advisory)
- Replace human review for HIGH-RISK changes
- Catch unknown personal data patterns (only known patterns are scanned)
- Prevent all security threats (see threat model for scope)

### Evidence

| Document | Purpose |
|----------|---------|
| [docs/CASE_STUDIES.md](docs/CASE_STUDIES.md) | 3 public-safe case studies |
| [docs/EVIDENCE.md](docs/EVIDENCE.md) | Measured and illustrative workflow evidence |
| [docs/FAILURE_MODES.md](docs/FAILURE_MODES.md) | 8 known failure modes with mitigations |
| [docs/THREAT_MODEL.md](docs/THREAT_MODEL.md) | Security threat model with 9 threat categories |
| [docs/CLAIMS.md](docs/CLAIMS.md) | Allowed and disallowed public claims |

## External Review and First Run

New to the protocol? Start here:

| Document | Purpose |
|----------|---------|
| [docs/FIRST_RUN_CHECKLIST.md](docs/FIRST_RUN_CHECKLIST.md) | 15-minute clone-to-validated guide |
| [docs/EXTERNAL_REVIEW_GUIDE.md](docs/EXTERNAL_REVIEW_GUIDE.md) | What to inspect and evaluate as a reviewer |
| [docs/DEMO_WALKTHROUGH.md](docs/DEMO_WALKTHROUGH.md) | Walk through 5 example workflows |

## Harness and Loop

The protocol has two layers:

```
HARNESS: rules + agents + skills + policies + validators + CI
LOOP:    goal → plan → act → verify → repair → review → merge
```

The **harness** is the set of stable files that define what each iteration is allowed to do. It changes slowly and is validated by CI.

The **loop** is the repeated process that runs inside the harness. It runs per task and is governed by the harness rules.

See [docs/HARNESS_AND_LOOP.md](docs/HARNESS_AND_LOOP.md) for the full two-layer architecture.

## Getting Started With Your Own Models

This protocol ships with **placeholder model IDs** (`YOUR_PROVIDER/YOUR_MODEL_ID`) in `opencode.json`. You must replace these with your own provider's model IDs before the harness can run.

To adapt it to your own setup:

1. Run `bash scripts/setup.sh` — checks prerequisites and detects placeholder config
2. Read [docs/OWN_MODEL_SETUP.md](docs/OWN_MODEL_SETUP.md) — how to configure your providers
3. Update `.opencode/opencode.json` — replace `YOUR_PROVIDER/YOUR_*_MODEL` with your actual model IDs
4. Copy templates from [examples/config/](examples/config/) — reference configs for OpenAI, Anthropic, or custom providers
5. Set your API key environment variable (e.g. `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`)
6. Run `bash scripts/validate-config-schema.sh` to verify

See [docs/PUBLIC_SYNC_POLICY.md](docs/PUBLIC_SYNC_POLICY.md) for how the public repo relates to the internal development repo.

## MCP Servers

The protocol configures several MCP servers (context7, exa, sequential-thinking, github). On first run, `npx` downloads these packages automatically (30-60 seconds, network required). To disable MCP servers you don't need, set `"enabled": false` in `.opencode/opencode.json`.

## External Reviewers Welcome

We welcome external review. If you are a technical reviewer:

1. Follow the [First Run Checklist](docs/FIRST_RUN_CHECKLIST.md) (15 minutes)
2. Read the [External Review Guide](docs/EXTERNAL_REVIEW_GUIDE.md)
3. Review the [External Review Pilot](docs/EXTERNAL_REVIEW_PILOT.md) plan
4. File feedback using the "External Review Feedback" issue template

See [Feedback Triage Policy](docs/FEEDBACK_TRIAGE.md) for how feedback is handled.

## Documentation

| Document | Purpose |
|---|---|
| [docs/QUICKSTART.md](docs/QUICKSTART.md) | 5-minute quickstart |
| [docs/INSTALLATION.md](docs/INSTALLATION.md) | Detailed installation |
| [docs/OPERATING_GUIDE.md](docs/OPERATING_GUIDE.md) | Daily operating guide |
| [docs/VERSIONING.md](docs/VERSIONING.md) | Versioning policy |
| [docs/protocol/PROTOCOL_ATLAS.md](docs/protocol/PROTOCOL_ATLAS.md) | Visual system map |
| [docs/PUBLICATION_POLICY.md](docs/PUBLICATION_POLICY.md) | Publication policy |
| [docs/CAPABILITY_CATALOG.md](docs/CAPABILITY_CATALOG.md) | Capability catalog — every public capability mapped |
| [docs/RUNTIME_MAP.md](docs/RUNTIME_MAP.md) | Runtime source-of-truth map |
| [docs/CONFIGURATION_GUIDE.md](docs/CONFIGURATION_GUIDE.md) | How to customize the protocol |
| [docs/CLAIMS.md](docs/CLAIMS.md) | Allowed and disallowed public claims |
| [docs/VALIDATION.md](docs/VALIDATION.md) | Validation scripts, test tiers, and CI enforcement |
| [docs/HARNESS_AND_LOOP.md](docs/HARNESS_AND_LOOP.md) | Two-layer architecture (harness vs loop) |
| [docs/PROGRESSIVE_ONBOARDING.md](docs/PROGRESSIVE_ONBOARDING.md) | 10-stage path from clone to first workflow |
| [docs/OWN_MODEL_SETUP.md](docs/OWN_MODEL_SETUP.md) | How to adapt the protocol to your own model providers |
| [docs/PUBLIC_SYNC_POLICY.md](docs/PUBLIC_SYNC_POLICY.md) | How the public repo relates to the internal development repo |
| [docs/DOGFOODING_LOG_TEMPLATE.md](docs/DOGFOODING_LOG_TEMPLATE.md) | Template for recording daily-use evidence |
| [docs/MAINTAINERS.md](docs/MAINTAINERS.md) | Maintainer guide and branch protection |
| [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) | Release checklist |
| [CHANGELOG.md](CHANGELOG.md) | Public release summary |
| [RELEASES.md](RELEASES.md) | Release index and checklist |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |
| [SECURITY.md](SECURITY.md) | Security policy |

## Verification

```bash
# First-run setup (checks prerequisites, generates aliases)
bash scripts/setup.sh

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

**Current:** v5.5.3 — Fresh-Clone Runtime Install Hardening

See [CHANGELOG.md](CHANGELOG.md) for release history.

## License

[MIT](LICENSE) — Copyright (c) 2026 OpenCode Agent Protocol contributors
