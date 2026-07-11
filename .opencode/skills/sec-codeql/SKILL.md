---
name: sec-codeql
description: >-
  Scans a codebase for security vulnerability detection using CodeQL interprocedural data flow and
  taint tracking. Triggers on "run codeql", "codeql scan", "codeql analysis", "build codeql database",
  or "find vulnerabilities with codeql". Activated by /gates when verification profile is
  stateful-sensitive and auth/payment/schema/security/crypto paths are touched.
---

# CodeQL Security Scanner

This skill wraps the full CodeQL analysis suite. The detailed skill content lives at `codeql/SKILL.md`.

## Procedure

Before running a scan, read the following:

1. Read the repo's `package.json` or equivalent to identify the primary language(s)
2. Read the verification profile from the active `PLAN.md` to confirm scoped SAST is mandatory
3. Read any existing CodeQL database directories (search for `codeql-database.yml`) to check for prior runs
4. Read the `.github/workflows/` or CI config if it exists to understand existing security gates

Then execute the scan:

1. Verify CodeQL is installed (`codeql --version`)
2. If no database exists, run the build-database workflow from `codeql/SKILL.md`
3. Run the appropriate analysis suite:
   - "run codeql" or "find vulnerabilities" → important-only suite (high-precision security findings)
   - "run all" → security-and-quality suite (comprehensive)
4. Process SARIF output and report findings with severity classification
5. If zero findings, investigate database quality before reporting clean (see Principle 4 in `codeql/SKILL.md`)

## Output format

Produce a scan report in this exact format:

```
## CodeQL Security Scan — <repo>

**Suite:** important-only / security-and-quality
**Database:** <path or "built fresh">
**Language:** <detected language>

### Findings
- [<severity>] <file>:<line> — <vulnerability type> — <brief description>

### Summary
- Total findings: <count>
- Critical: <count>
- High: <count>
- Medium: <count>
- Low: <count>

### Gate verdict: PASS / FAIL
```

- If any Critical or High findings exist, the gate verdict is `FAIL` and the fix must be applied before proceeding.
- If zero findings, include a database quality note confirming the scan was thorough.

## Out of Scope

This skill does NOT:
- Write custom CodeQL queries (that requires a dedicated query development skill)
- Fix vulnerabilities in the codebase (that is /implement or /debug)
- Replace CI/CD integration (use GitHub Actions documentation for that)
- Perform quick pattern searches (use Semgrep or grep for speed)
- Analyze a single file or lightweight changes (Semgrep is faster for simple matching)
