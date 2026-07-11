---
name: sec-solana
description: >-
  Scans Solana programs for 6 critical vulnerabilities including arbitrary CPI, improper PDA validation,
  missing signer check, missing ownership checks, and sysvar spoofing. Activated when auditing
  Solana/Anchor programs or when a plan touches Solana smart contract code.
---

# Solana Vulnerability Scanner

This skill wraps the Solana-specific security scanner. The detailed skill content lives at `solana-vulnerability-scanner/SKILL.md`.

## Procedure

Before running a scan, read the following:

1. Read the repo's `Cargo.toml` or `Anchor.toml` to confirm Solana/Anchor dependency
2. Read the program source files (`programs/*/src/lib.rs`) to identify the program structure
3. Read any existing test files (`tests/`) to understand the current test coverage
4. Read the `solana-vulnerability-scanner/SKILL.md` sub-skill to load the full 6-pattern detection logic

Then execute the scan:

1. Detect the platform: native Rust Solana program vs Anchor framework
2. For each of the 6 vulnerability patterns, search the program source using grep/rg:
   - **Arbitrary CPI** — unchecked program IDs in `invoke()` / `invoke_signed()` calls
   - **Improper PDA Validation** — `create_program_address` without canonical bump
   - **Missing Ownership Check** — deserializing accounts without owner validation
   - **Missing Signer Check** — authority operations without `is_signer` check
   - **Sysvar Account Check** — spoofed sysvar accounts (pre-Solana 1.8.1)
   - **Improper Instruction Introspection** — absolute indexes allowing reuse
3. For each finding, record the file, line, pattern, and recommended fix
4. Run the reporting workflow from `solana-vulnerability-scanner/SKILL.md`

## Output format

Produce a scan report in this exact format:

```
## Solana Vulnerability Scan — <program name>

**Platform:** Native Rust / Anchor
**Source:** <program source path>
**Solana version:** <detected or unknown>

### Findings
- [<severity>] <file>:<line> — <pattern name> — <brief description>

### Pattern Coverage
- Arbitrary CPI: <checked / no CPI calls found / VULNERABLE>
- PDA Validation: <checked / no PDA usage found / VULNERABLE>
- Ownership Check: <checked / no deserialization found / VULNERABLE>
- Signer Check: <checked / no authority ops found / VULNERABLE>
- Sysvar Account: <checked / no sysvar usage found / VULNERABLE>
- Instruction Introspection: <checked / no introspection found / VULNERABLE>

### Gate verdict: PASS / FAIL
```

- If any Critical or High findings exist, the gate verdict is `FAIL` and the fix must be applied before proceeding.

## Out of Scope

This skill does NOT:
- Fix vulnerabilities in the Solana program (that is /implement or /debug)
- Write or run Solana program tests (that is /gates with the repo's test suite)
- Audit non-Solana code (use sec-codeql for general security scanning)
- Replace a full security audit for production mainnet launches
- Validate economic security or MEV vulnerability (those require specialized analysis)
