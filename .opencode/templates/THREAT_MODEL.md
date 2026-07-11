# Threat Model

Status: `<draft | approved | N/A>`
Mode: `<compact | full>`
Date: `<YYYY-MM-DD>`

## Use

- Purpose: identify trust boundaries, abuse paths, mitigations, and residual risk before sensitive work ships.
- Required when: auth, payments, crypto, secrets, permissions, user data, external callbacks, or trust boundaries are touched.
- Mode guidance: compact mode covers only touched flows; full mode maps all relevant flows and STRIDE categories.
- Required evidence: scoped flows, boundary list, mitigations, residual-risk owner acceptance where needed.

## N/A rule

Use `N/A` only when the work does not touch auth, payments, crypto, secrets, permissions, user data, external callbacks, or trust boundaries. Reason: `<specific reason>`. Risk if skipped: `<risk or none>`

## Scope

- System/change: `<scope>`
- In scope: `<assets, flows, boundaries>`
- Out of scope: `<explicit exclusions>`

## Assets and actors

- Assets: `<data, credentials, funds, permissions, availability>`
- Actors: `<user, admin, service, attacker, third party>`

## Trust boundaries and data flows

| Flow | Source | Boundary crossed | Destination | Sensitive data? |
|---|---|---|---|---|
| `<flow>` | `<source>` | `<boundary>` | `<destination>` | `<yes/no>` |

## STRIDE risks

| Category | Risk | Mitigation | Residual risk |
|---|---|---|---|
| Spoofing | `<risk or N/A>` | `<mitigation>` | `<risk>` |
| Tampering | `<risk or N/A>` | `<mitigation>` | `<risk>` |
| Repudiation | `<risk or N/A>` | `<mitigation>` | `<risk>` |
| Information disclosure | `<risk or N/A>` | `<mitigation>` | `<risk>` |
| Denial of service | `<risk or N/A>` | `<mitigation>` | `<risk>` |
| Elevation of privilege | `<risk or N/A>` | `<mitigation>` | `<risk>` |

## Owner acceptance

- Residual risks requiring owner acceptance:
  - `<risk or none>`
- Owner approval: `<pending | approved | not required — reason>`
