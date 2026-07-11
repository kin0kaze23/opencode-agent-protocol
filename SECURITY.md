# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this repository, please report it responsibly:

1. **Do not** open a public GitHub issue
2. Email: security@[repo-owner-domain] (replace with your contact)
3. Include a description of the vulnerability and steps to reproduce
4. We will acknowledge receipt within 48 hours and provide a fix timeline

## Secrets Policy

- **Never commit secrets, API keys, tokens, or credentials to Git**
- All API keys must be managed through environment variables or a secrets manager (e.g., Doppler)
- The `.gitignore` is configured to block `.env` files and common secret patterns
- Pre-commit hooks scan for secrets using `gitleaks`
- Refer to secret names only (e.g., `OPENCODE_GO_API_KEY`), never values

## Permission Guardrails

This protocol enforces safety through explicit `deny` rules in `opencode.json`:

- Secrets (`.env`) — denied for read, edit, bash read, git show
- Package/lockfiles — denied for edit across all languages
- Schema/migrations — denied for edit
- Auth/payment/billing — denied for edit
- CI (`.github/`) — denied for edit
- Protocol (`.opencode/`, `AGENTS.md`) — denied for edit
- Deploy configs — denied for edit
- Raw git mutations — denied for bash
- Destructive commands — denied for bash

## Autonomous Use Disclaimer

- This protocol provides guardrails for AI-assisted engineering, not autonomous production safety
- HIGH-RISK tasks always require human reviewer evidence and owner approval
- No auto-push to main, no auto-merge of PRs, no self-approval of HIGH-RISK changes
- The owner is responsible for all changes made under this protocol
- This software is provided "as is" without warranty of any kind

## Safety Invariants

1. protected-repo is always excluded from all components
2. HIGH-RISK always requires reviewer evidence
3. Routing policy is advisory only (never auto-applied)
4. Reviewer policy is advisory only (never auto-applied)
5. No production mutation without explicit `--apply` approval
6. No auto-push to main
7. No self-approval of HIGH-RISK changes
8. Secrets are never committed
9. Pre-commit hooks cannot be skipped
10. Stale evidence triggers warnings
