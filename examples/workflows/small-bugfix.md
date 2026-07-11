# Example: Small Bugfix Flow

> **Scenario:** A user wants to fix a bug in a conformance test script.

## User Task

Fix a bug in `.opencode/conformance/tests/protocol-atlas.sh` where a version check fails on v5.x versions.

## Expected Agent Flow

1. **Lane selection:** FAST (risk 1-2, ≤3 files, no sensitive paths)
2. **Short plan** (inline, not PLAN.md):
   - Read the failing test
   - Fix the regex pattern
   - Run the test to verify
   - Commit
3. Read relevant files (max 3)
4. Edit scoped files
5. Run relevant gates
6. Commit with conventional message

## Commands

```bash
# 1. Create a branch
git checkout -b fix/atlas-version-regex

# 2. Read the failing test
# (agent reads .opencode/conformance/tests/protocol-atlas.sh)

# 3. Fix the regex
# Change: grep -oE 'v4\.[0-9]+(\.[0-9]+)?'
# To:     grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?'

# 4. Run the test
bash .opencode/conformance/tests/protocol-atlas.sh

# 5. Commit
git add .opencode/conformance/tests/protocol-atlas.sh
git commit -m "fix: atlas version regex for v5.x

The version check only matched v4.x patterns. Updated to match
any vN.x.x pattern."

# 6. Push and create PR
git push origin fix/atlas-version-regex
gh pr create --title "fix: atlas version regex for v5.x" --body "..."
```

## What CI Enforces

| Check | What it does |
|-------|-------------|
| Privacy Scan | Ensures no personal data in the diff |
| Protocol Conformance | Ensures all protocol tests pass (including the fixed one) |

## Expected Output

```
What was changed: Fixed version regex in protocol-atlas.sh to match v5.x
Gate results: protocol-atlas 48/48 PASS
Files touched: .opencode/conformance/tests/protocol-atlas.sh
Next step: Merge PR after CI passes
Rollback note: Revert the regex change if test fails
```

## Safety Notes

- Bug fixes that touch logic require tests to pass
- CI validates the fix doesn't break other tests
- FAST lane allows inline plan (no PLAN.md needed)
