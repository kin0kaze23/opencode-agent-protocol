# Claims Policy

> **Purpose:** Defines what claims are accurate and defensible about OpenCode Agent Protocol.
> **Last Updated:** 2026-07-11

---

## Allowed Claims

These claims are evidence-based and defensible:

| Claim | Evidence |
|-------|----------|
| Safety-first AI engineering harness | Protocol kernel with safety rules, lane selection, escalation triggers |
| Governed agentic development | Branch protection, CI enforcement, release gates, reviewer policy |
| CI-enforced privacy scanning | `scripts/public-surface-scan.sh` runs in CI on every PR |
| Conformance-tested public baseline | 297+ tests across multiple suites, 0 failures |
| Fresh-clone validated | Every release validated from a clean clone |
| Configurable protocol | Model routing, reviewer policy, gate matrix, token budgets all configurable |
| Portable public installation | No machine-specific paths, no vault dependency, no personal data |
| Branch protection enforced | GitHub ruleset active on main |
| Protocol Atlas documented | 11 Mermaid diagrams with rendered SVGs |
| Variant-aware privacy scanning | PascalCase, camelCase, space, kebab, snake, lowercase patterns |
| Documented agent topology | Orchestrator + 5 helper roles with routing guidance |
| Evidence-backed case studies | 3 case studies with measured/illustrative evidence |
| Documented failure modes | 8 known failure modes with mitigations and validation commands |
| Security threat model | 9 threat categories with mitigations and owner controls |

---

## Disallowed Claims

These claims are not supported by evidence and must not be made:

| Claim | Why not allowed |
|-------|----------------|
| Better than Anthropic/OpenAI internal harnesses | No comparative evidence |
| Approved by top AI researchers | No external review conducted |
| Fully autonomous production safety | Human review still required for HIGH-RISK |
| Guaranteed productivity improvement | No measured productivity evidence published |
| Zero privacy leaks guaranteed | Scanner catches known patterns, not all possible patterns |
| Production-tested at scale | No production usage evidence published |
| SOC 2 / ISO 27001 compliant | No compliance audit conducted |

---

## Recommended Public Description

> OpenCode Agent Protocol is a safety-first AI engineering harness for governed agentic development, with CI-enforced privacy scanning, protocol conformance, release discipline, agent topology documentation, and portable public installation.

---

## How to Substantiate Claims

| Claim type | Required evidence |
|-----------|-------------------|
| Performance | Measured benchmarks with methodology |
| Security | Security audit or penetration test |
| Productivity | Before/after time comparison with controlled variables |
| External review | Named reviewer with credentials |
| Compliance | Audit report from certified auditor |

Do not make claims without the corresponding evidence.
