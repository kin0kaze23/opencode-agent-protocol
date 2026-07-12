# Demo Walkthrough

> **Purpose:** Walk through the protocol's example workflows to understand how it works in practice.
> **Last Updated:** 2026-07-11

---

## Available Examples

All examples are in [examples/workflows/](../examples/workflows/) and use only generic, public-safe names.

### 1. Docs-Only Change Flow

**File:** [examples/workflows/docs-only-change.md](../examples/workflows/docs-only-change.md)

**Scenario:** Fix a typo in README.md.

**What it demonstrates:**
- DIRECT lane (risk 0, 1 file, no sensitive paths)
- No PLAN.md required
- Minimal gate (lint only)
- CI still runs privacy scan

**Key takeaway:** Even the simplest change goes through privacy scan in CI.

---

### 2. Small Bugfix Flow

**File:** [examples/workflows/small-bugfix.md](../examples/workflows/small-bugfix.md)

**Scenario:** Fix a version regex in a conformance test.

**What it demonstrates:**
- FAST lane (risk 1-2, ≤3 files)
- Inline plan (not PLAN.md)
- Tests required for logic changes
- CI runs both privacy scan and protocol conformance

**Key takeaway:** Logic changes require tests to pass in CI.

---

### 3. Privacy Scan Failure Flow

**File:** [examples/workflows/privacy-scan-failure.md](../examples/workflows/privacy-scan-failure.md)

**Scenario:** A PR accidentally introduces a personal project name.

**What it demonstrates:**
- CI catches personal data before merge
- Branch protection blocks merge when checks fail
- How to fix and re-push

**Key takeaway:** The privacy scan is enforced — it cannot be bypassed.

---

### 4. Release Checklist Flow

**File:** [examples/workflows/release-checklist.md](../examples/workflows/release-checklist.md)

**Scenario:** A maintainer cuts a new release.

**What it demonstrates:**
- Pre-release validation
- Version file updates
- PR → CI → merge → tag → release flow
- Fresh-clone validation

**Key takeaway:** Releases follow a repeatable, documented process.

---

### 5. Model Routing Advisory Flow

**File:** [examples/workflows/model-routing-advisory.md](../examples/workflows/model-routing-advisory.md)

**Scenario:** Understanding how model routing recommendations work.

**What it demonstrates:**
- Model routing is advisory (not enforced)
- Routing considers task type, risk, provider availability, and eval evidence
- Fallback chains ensure resilience

**Key takeaway:** Model routing provides recommendations, not guarantees.

---

## How to Use These Examples

1. Read through each example to understand the workflow
2. Try the commands locally on a clone of the repo
3. Create a test branch and practice the flow
4. Observe how CI enforces checks on PRs

## What CI Enforces on Every PR

| Check | What it catches |
|-------|----------------|
| Privacy Scan | Personal data, secrets, forbidden directories |
| Docs Drift | Stale file references, version mismatches, broken links |
| Config Schema | Missing files, invalid JSON/YAML, missing agent roles |
| Claims & Evidence | Disallowed claims, missing evidence docs |
| Protocol Conformance | Protocol regressions (297+ tests) |

All 5 checks must pass before a PR can merge (enforced by branch protection).
