# Publication Policy

> **Purpose:** Defines what may be public, what must stay private, and how to create a safe public release.

## What May Be Public

| Category | Examples | Condition |
|----------|----------|-----------|
| Protocol source | `.opencode/AGENTS.md`, `rules.md`, `brain-config.json` | Sanitized of personal project names |
| Conformance tests | `.opencode/conformance/tests/*.sh` | Test fixtures anonymized |
| Scripts | `.opencode/scripts/*.sh` | No machine-specific paths |
| Skills | `.opencode/skills/*/SKILL.md` | Examples use generic names |
| Commands | `.opencode/commands/*.md` | No personal references |
| Public docs | `README.md`, `docs/*` | No personal identity |
| Examples | `examples/*` | Public-safe configs only |
| Protocol Atlas | `docs/protocol/*` | No personal project names |
| Legal/community | `LICENSE`, `SECURITY.md`, `CONTRIBUTING.md` | Copyright: "OpenCode Agent Protocol contributors" |

## What Must Stay Private

| Category | Reason |
|----------|--------|
| Vault submodule (3,293 files) | Personal workspace knowledge base with project names, lessons, decisions, Hermes evals |
| Fleet repo config | Lists personal project repos by name |
| Personal project folders | Unrelated to protocol |
| Machine-local configs | `.ai/`, `.launcher/`, `.claude/settings.json` |
| Generated eval results | May contain personal project references |
| Git history (v4.x) | Contains personal project files, local paths, personal identity |

## Personal Project Exclusion Policy

The following personal project names must NOT appear in public-facing content:

- protected-repo (always excluded)
- example-app
- sample-service
- demo-project
- example-platform
- example-agent
- example-dashboard
- example-analyzer
- Pulse
- example-cli
- example-toolchain
- example-orchestrator

In conformance tests, eval fixtures, and skills, these should be replaced with generic names:
- `sample-app`
- `example-repo`
- `demo-project`
- `protected-repo`

## Vault/Report Sanitization Policy

- The vault submodule is a personal knowledge base and must NOT be included in a public repo
- Reports may contain historical references to personal project names — sanitize or exclude from public repo
- Protocol snapshots in `vault/protocols/opencode/snapshots/` are the only vault content relevant to protocol history

## No Personal Identity Policy

- No personal legal names in public files
- Copyright holder: "OpenCode Agent Protocol contributors"
- GitHub handle: `kin0kaze23` (for repo URLs, clone commands)
- No personal email addresses, phone numbers, or local paths

## No Secrets Policy

- No API keys, tokens, or credentials in tracked files
- Pre-commit hooks scan for secrets using gitleaks
- `.env` files are `.gitignored`
- Secret names (e.g., `OPENCODE_GO_API_KEY`) may be referenced but never values

## Release History Publication Policy

### v4.x History (Private)

- v4.x Git history contains personal project files, local paths, and personal identity
- v4.x tags point to commits with personal content
- v4.x history must NOT be published

### v5.0.0 Public Baseline (Recommended)

**Recommendation: Create a clean public v5 repo from sanitized HEAD.**

1. Keep the current v4 repo as private/internal development history
2. Create a new public repo (or sanitize the current one) with:
   - Sanitized `.opencode/` (project names replaced with generic examples)
   - No vault submodule (or a sanitized public vault with only protocol snapshots)
   - Sanitized reports (or no reports)
   - Clean v5.0.0 initial commit
   - No v4.x history
3. v5.0.0 is the first public release
4. Historical note: "v5.0.0 is the first public baseline. Earlier v4.x work was internal development history."

### Why Not Publish Full History?

- 1,032 vault files contain personal project names
- 100 tracked files in the main repo reference personal project names
- All v4.x tags (61 tags) point to commits with personal project files
- Git history contains personal identity, local paths, and personal project content
- Rewriting history is risky and would break tags/releases

### Alternative: History Rewrite (Not Recommended)

If full history publication is required:
1. Use `git filter-repo` to remove personal content from all commits
2. Recreate all tags on rewritten commits
3. Force-push rewritten history
4. Recreate GitHub Releases
5. This is risky, time-consuming, and may miss edge cases
