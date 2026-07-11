# Example: Privacy Scan Failure Flow

> **Scenario:** A PR accidentally introduces a personal project name and the privacy scan fails.

## User Task

A contributor adds a new config file that references a personal project name.

## What Happens

1. Contributor creates a PR
2. CI runs automatically
3. **Privacy Scan job fails** — detects the blocked pattern
4. PR cannot merge (branch protection requires Privacy Scan to pass)

## Example Failure

```
=== Public Surface Scan ===
Scanning: /home/runner/work/opencode-agent-protocol

FAIL: Personal project names
  ./config/new-app.yaml

=== FAIL: 1 category(ies) with disallowed matches ===
```

## How to Fix

1. Check the CI output for which file and category failed
2. Edit the file to replace the personal project name with a generic name
3. Push the fix
4. CI re-runs automatically
5. Privacy Scan passes
6. PR can merge

## Local Verification

Before pushing, run locally:

```bash
bash scripts/public-surface-scan.sh
```

If it fails locally, fix before pushing.

## Safety Notes

- The privacy scan is enforced in CI — it cannot be bypassed
- Branch protection prevents merging with failed checks
- The scan checks all tracked files, not just the diff
- See `docs/PUBLICATION_POLICY.md` for the full list of blocked patterns
