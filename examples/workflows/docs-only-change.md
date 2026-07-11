# Example: Docs-Only Change Flow

> **Scenario:** A user wants to fix a typo in the README.

## User Task

Fix a typo in `README.md` — change "recieve" to "receive".

## Expected Agent Flow

1. **Lane selection:** DIRECT (risk 0, 1 file, no sensitive paths)
2. **No PLAN.md required** — DIRECT lane
3. Read the target file
4. Edit the file
5. Run lint gate (smallest relevant gate)
6. Commit with conventional message

## Commands

```bash
# 1. Create a branch
git checkout -b docs/fix-typo

# 2. Make the change
# (edit README.md)

# 3. Commit
git add README.md
git commit -m "docs: fix typo in README"

# 4. Push and create PR
git push origin docs/fix-typo
gh pr create --title "docs: fix typo in README" --body "Fix recieve → receive"
```

## What CI Enforces

| Check | What it does |
|-------|-------------|
| Privacy Scan | Ensures no personal data in the diff |
| Protocol Conformance | Ensures protocol tests still pass |

## Expected Output

```
Edited README.md. lint: PASS. Committed <hash>.
```

## Safety Notes

- Docs-only changes are the safest class of change
- No test burden for DIRECT lane
- CI still runs privacy scan to catch accidental personal data
