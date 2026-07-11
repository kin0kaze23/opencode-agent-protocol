# OpenCode Skill Registry

> **Purpose:** Central index of all skills in `.opencode/skills/` with activation conditions, patterns status, and usage notes.
> **Last Updated:** 2026-07-03 (v4.27 audit)
> **Total Skills:** 67
> **All 4 Patterns:** Yes (v4.7.0 active baseline)

---

## Pattern Legend

| Pattern | Description |
|---------|-------------|
| **RF** | Read First — explicit instruction to read project files before acting |
| **OS** | Out of Scope — explicit list of what the skill does NOT do |
| **OF** | Output Format — structured template showing what the skill should produce |
| **DL** | Directive Language — numbered imperative steps, not passive description |

---

## Tier 1: Actively Referenced by Commands

These skills are activated by command skill activation tables. They wire directly into `/implement`, `/review`, `/plan-feature`, `/debug`, `/ship`, and `/analyze`.

| Skill | Activation | RF | OS | OF | DL | Lines | Notes |
|-------|-----------|----|----|----|----|-------|-------|
| ui-ux-pro-max | /implement, /review | ✅ | ✅ | ✅ | ✅ | 292 | UI/component/page work |
| frontend-design | /implement, /review | ✅ | ✅ | ✅ | ✅ | 170 | Visual direction, motion, landing pages |
| testing-validation | /implement, /review | ✅ | ✅ | ✅ | ✅ | 130 | Tests, specs, TDD |
| webapp-testing | /implement, /review | ✅ | ✅ | ✅ | ✅ | 125 | Browser verification, UI flows |
| database | /implement, /review | ✅ | ✅ | ✅ | ✅ | 245 | Schema, Prisma, Drizzle |
| dependency-hygiene | /implement, /review | ✅ | ✅ | ✅ | ✅ | 147 | Dependency changes |
| security | /implement, /review, /debug | ✅ | ✅ | ✅ | ✅ | 401 | Auth, crypto, sensitive paths |
| technical-debt-prevention | /implement, /review | ✅ | ✅ | ✅ | ✅ | 158 | Refactor, cleanup |
| systematic-debugging | /implement, /review, /debug | ✅ | ✅ | ✅ | ✅ | 112 | Root-cause analysis |
| rust | /implement, /review | ✅ | ✅ | ✅ | ✅ | 270 | Rust development (example-cli) |
| runtime-wiring-audit | /plan-feature | ✅ | ✅ | ✅ | ✅ | 68 | Verify active code paths |
| contract-touchlist-audit | /plan-feature | ✅ | ✅ | ✅ | ✅ | 63 | Type/interface/schema changes |
| plan-correction-discipline | /plan-feature | ✅ | ✅ | ✅ | ✅ | 61 | Drift correction, replan |
| implementation-readiness-gate | /plan-feature | ✅ | ✅ | ✅ | ✅ | 58 | Plan validation gate |
| sec-codeql | /gates (stateful-sensitive) | ✅ | ✅ | ✅ | ✅ | 67 | CodeQL security scanning |
| sec-solana | Solana projects | ✅ | ✅ | ✅ | ✅ | 69 | Solana vulnerability scanning |
| accessibility-audit | /implement, /review | ✅ | ✅ | ✅ | ✅ | 187 | WCAG 2.2 AA conformance |
| error-handling | /implement, /debug | ✅ | ✅ | ✅ | ✅ | 285 | Resilient patterns |
| nextjs | /implement | ✅ | ✅ | ✅ | ✅ | 305 | Next.js 14+ development |
| observability | /implement | ✅ | ✅ | ✅ | ✅ | 186 | Logging, metrics, tracing |
| testing | /implement | ✅ | ✅ | ✅ | ✅ | 160 | Unit, integration, TDD |
| refactor-clean | /implement | ✅ | ✅ | ✅ | ✅ | 120 | Safe refactoring |
| code-review-checklist | /review | ✅ | ✅ | ✅ | ✅ | 140 | Systematic review checklist |
| performance | /review | ✅ | ✅ | ✅ | ✅ | 240 | Frontend/backend optimization |
| technical-debt-assessment | /review | ✅ | ✅ | ✅ | ✅ | 205 | Complexity, coverage, debt |
| incident-response | /debug | ✅ | ✅ | ✅ | ✅ | 252 | Production incidents |
| deployment | /ship | ✅ | ✅ | ✅ | ✅ | 140 | Vercel, Railway, Docker |
| docker | /ship | ✅ | ✅ | ✅ | ✅ | 189 | Containerization |
| migration-patterns | /plan-feature | ✅ | ✅ | ✅ | ✅ | 124 | Zero-downtime deploys |
| api-design | /plan-feature, /analyze | ✅ | ✅ | ✅ | ✅ | 240 | REST/GraphQL patterns |
| interrogation | /analyze | ✅ | ✅ | ✅ | ✅ | 84 | Eliminate assumptions |
| brainstorming | /analyze | ✅ | ✅ | ✅ | ✅ | 116 | Design exploration |

---

## Tier 2: Available-on-Demand

These skills are present, documented, and available for manual activation when the task domain warrants it. The v4.7.0 specialist skills are also wired into command docs through trigger-based gates; they remain proportional to risk and do not make every task HIGH-RISK by default.

| Skill | Domain | RF | OS | OF | DL | Lines | Notes |
|-------|--------|----|----|----|----|-------|-------|
| agent-browser | Browser automation | ✅ | ✅ | ✅ | ✅ | 247 | AI-optimized browser CLI |
| ai-agent-evaluation | AI evals | ✅ | ✅ | ✅ | ✅ | 167 | LLM feature evaluations |
| api-contract-validation | API contracts | ✅ | ✅ | ✅ | ✅ | 98 | v4.7.0 active; boundary-triggered command wiring |
| ci-cd-pipeline | CI/CD | ✅ | ✅ | ✅ | ✅ | 310 | Deployment automation |
| cross-repo-dependencies | Multi-repo | ✅ | ✅ | ✅ | ✅ | 222 | Dependency graph |
| database-migration | DB migration | ✅ | ✅ | ✅ | ✅ | 208 | Safe migrations |
| design-system-governance | Design system | ✅ | ✅ | ✅ | ✅ | 97 | v4.7.0 active; UI/design-system trigger wiring |
| development | Coding standards | ✅ | ✅ | ✅ | ✅ | 130 | Clean code, immutability |
| docx | Word docs | ✅ | ✅ | ✅ | ✅ | 590 | .docx file operations |
| ecosystem-scan | Ecosystem | ✅ | ✅ | ✅ | ✅ | 256 | Library alternatives |
| github-pr-automation | GitHub | ✅ | ✅ | ✅ | ✅ | 150 | PR automation |
| infra-validation | Infrastructure | ✅ | ✅ | ✅ | ✅ | 95 | v4.7.0 active; deploy/runtime trigger wiring |
| pdf | PDF files | ✅ | ✅ | ✅ | ✅ | 340 | PDF processing |
| pencil-design | Pencil UI | ✅ | ✅ | ✅ | ✅ | 445 | Pencil.dev design workflow |
| pencil-pen-format | .pen format | ✅ | ✅ | ✅ | ✅ | 780 | .pen file format guide |
| performance-profiling | Profiling | ✅ | ✅ | ✅ | ✅ | 185 | Lighthouse, bundle, API |
| playbooks | Playbooks | ✅ | ✅ | ✅ | ✅ | 205 | Pre-built workflows |
| pptx | PowerPoint | ✅ | ✅ | ✅ | ✅ | 232 | .pptx file operations |
| runtime-optimization | Runtime | ✅ | ✅ | ✅ | ✅ | 220 | Parallelization, caching |
| slim | HTTPS tunneling | ✅ | ✅ | ✅ | ✅ | 225 | Local HTTPS tunneling |
| threat-modeling | Security design | ✅ | ✅ | ✅ | ✅ | 91 | v4.7.0 active; sensitive-boundary trigger wiring |
| token-optimization | Tokens | ✅ | ✅ | ✅ | ✅ | 190 | Context compression |
| verification-before-completion | Verification | ✅ | ✅ | ✅ | ✅ | 94 | Evidence-before-complete discipline |
| visual-regression | Visual QA | ✅ | ✅ | ✅ | ✅ | 100 | v4.7.0 active; risk-based visual trigger wiring |
| workflow-enforcement | Workflow | ✅ | ✅ | ✅ | ✅ | 162 | Development workflow |
| xlsx | Spreadsheets | ✅ | ✅ | ✅ | ✅ | 320 | .xlsx/.csv file operations |
| yt-search | YouTube search | ✅ | ✅ | ✅ | ✅ | 94 | Research pipeline v0.1; yt-dlp JSON wrapper |

---

## Tier 3: Sub-Skills (Referenced by Parent Skills)

| Skill | Parent | RF | OS | OF | DL | Lines | Notes |
|-------|--------|----|----|----|----|-------|-------|
| sec-codeql/codeql | sec-codeql | ✅ | ✅ | ✅ | ✅ | 281 | Full CodeQL analysis suite |
| sec-solana/solana-vulnerability-scanner | sec-solana | ✅ | ✅ | ✅ | ✅ | 389 | Solana 6-pattern scanner |

---

## Usage Notes

### How Skills Are Activated

Skills in this workspace are **not auto-loaded by description matching**. They are:
1. **Explicitly activated** by command skill activation tables (`/implement`, `/review`, `/plan-feature`, `/debug`, `/ship`, `/analyze`)
2. **Manually selected** by the agent based on task domain analysis
3. **Loaded via the `skill` tool** (or equivalent in the agent runtime)

### Runtime exposure status

This registry is the filesystem-maintained catalog, not proof that every entry is exposed by the current runtime's `skill` tool. v4.5 distinguishes:

- **Runtime-exposed** — available through the current `skill` tool.
- **Filesystem-maintained** — present under `.opencode/skills/` and governed by this registry, but not necessarily exposed by the active runtime adapter.

If a registry entry is needed but not runtime-exposed, either restore runtime exposure or document the skill as filesystem-maintained before relying on it in a command.

### Quality Assurance

All 60 skills meet all 4 authoring patterns (RF, OS, OF, DL) as of the v4.7.0 active baseline.
The original repair was documented in `vault/protocols/opencode/CHANGELOG.md` under v4.4.1; the five v4.7.0 specialist skills also follow RF/OS/OF/DL and are trigger-wired through commands.

### Adding New Skills

New skills must meet these requirements before being committed:
1. All 4 patterns present (RF, OS, OF, DL)
2. Under 400 lines (or uses progressive disclosure)
3. Referenced by at least one command's activation table (no orphans), except explicitly labelled prep skills whose command wiring is scheduled in a later approved phase
4. Added to this registry

---


## v4.9.0 UI/UX Quality Assurance Pack

| Skill | Path | Purpose | Activation |
|---|---|---|---|
| `ui-ux-quality-audit` | `.opencode/skills/ui-ux-quality-audit/SKILL.md` | Senior UI/UX quality audit — hierarchy, layout, typography, color, states, motion, microcopy, brand fit, delight, visual polish | On-demand, referenced by ui-work rules |
| `responsive-state-audit` | `.opencode/skills/responsive-state-audit/SKILL.md` | Viewport matrix + UX state coverage (loading, empty, error, success, disabled) | On-demand until command wiring |

## v4.9.1 UI/UX Expertise Enhancement

| Skill | Path | Purpose | Activation |
|---|---|---|---|
| `motion-design` | `.opencode/skills/motion-design/SKILL.md` | Senior motion design — timing, easing, micro-interactions, choreography, accessibility | On-demand, referenced by ui-work rules |
| `design-research` | `.opencode/skills/design-research/SKILL.md` | Design research methodology — competitor audit, mood board → tokens, aesthetic decisions | On-demand, referenced by ui-work rules |

> **Note:** v4.9.0/v4.9.1 skills are on-demand. They are referenced by `ui-work.md` but NOT command-wired into `/implement`, `/review`, `/gates`, or `/ship`.

## v4.9.2 Visual Craft + Platform Polish Pack

| Skill | Path | Purpose | Activation |
|---|---|---|---|
| `platform-guidelines-compliance` | `.opencode/skills/platform-guidelines-compliance/SKILL.md` | Platform guideline compliance — Apple HIG, Material 3, WCAG 2.2, safe areas, touch targets | On-demand, referenced by ui-work rules |
| `illustration-graphic-direction` | `.opencode/skills/illustration-graphic-direction/SKILL.md` | Custom illustration/graphic direction — visual metaphor, iconography, brand motif, empty-state graphics | On-demand, referenced by ui-work rules |
| `visual-iteration-loop` | `.opencode/skills/visual-iteration-loop/SKILL.md` | Visual iteration loop — screenshot critique, before/after comparison, max 2 iterations | On-demand, referenced by ui-work rules |

> **Note:** v4.9.0/v4.9.1/v4.9.2 skills are on-demand. They are referenced by `ui-work.md` but NOT command-wired into `/implement`, `/review`, `/gates`, or `/ship`.

## Statistics

| Metric | Count |
|--------|-------|
| Total skills | 67 |
| Actively referenced (Tier 1) | 32 |
| Available-on-demand (Tier 2) | 32 |
| Sub-skills (Tier 3) | 2 |
| Skills with all 4 patterns | 67 (100%) |
| Average skill size | 209 lines |
| Largest skill | pencil-pen-format (793 lines) |
| Smallest skill | implementation-readiness-gate (58 lines) |

---

## v4.27 Skill Audit (2026-07-03)

> Classification based on actual command references and runtime/test references.
> No skills archived. Archive candidates identified for future review.

### Classification Method

Each skill was checked for references in:
- `.opencode/commands/*.md` (command activation tables)
- `.opencode/AGENTS.md`, `.opencode/rules.md`, `.opencode/helper-roster.md`
- `.opencode/conformance/tests/*.sh`

### Active (referenced by 2+ commands)

32 skills — see Tier 1 table above.

### Reference (referenced by 1 command or protocol file)

| Skill | Referenced By | Notes |
|-------|--------------|-------|
| verification-before-completion | rules.md | Evidence-before-complete discipline |
| slim | rules.md | Local HTTPS tunneling |
| ecosystem-scan | rules.md | Library alternatives |
| yt-search | research-pipeline.md | YouTube search for research pipeline |
| workflow-enforcement | commands | Development workflow standards |
| technical-debt-assessment | /review | Complexity, coverage, debt |
| runtime-wiring-audit | /plan-feature | Verify active code paths |
| refactor-clean | /implement | Safe refactoring |
| plan-correction-discipline | /plan-feature | Drift correction |
| motion-design | ui-work rules | Motion design (on-demand) |
| design-research | ui-work rules | Design research (on-demand) |
| incident-response | /debug | Production incidents |
| implementation-readiness-gate | /plan-feature | Plan validation gate |
| development | /implement | Coding standards |
| contract-touchlist-audit | /plan-feature | Type/interface changes |
| code-review-checklist | /review | Systematic review |
| brainstorming | /analyze | Design exploration |
| interrogation | /analyze | Eliminate assumptions |

### Utility (not referenced by commands, manually invokable)

| Skill | Purpose | Notes |
|-------|---------|-------|
| xlsx | .xlsx/.csv file operations | Office document skill |
| pptx | .pptx file operations | Office document skill |
| pdf | PDF file operations | Office document skill |
| docx | .docx file operations | Office document skill |
| ai-agent-evaluation | LLM feature evaluations | Eval mode |
| github-pr-automation | PR automation | Manual use |

### Archive Candidates (0 references, potentially superseded)

> **No skills archived in v4.27.** These are identified for future review.
> Archive requires explicit owner approval per v4.27 rules.

| Skill | Superseded By | Reason | Recommendation |
|-------|--------------|--------|----------------|
| token-optimization | v4.17 token efficiency rules in rules.md | Rules.md now contains comprehensive token budget rules | Review for archive in v4.28 |
| runtime-optimization | performance skill | Overlaps with `performance` skill | Review for archive in v4.28 |
| performance-profiling | performance skill | Overlaps with `performance` skill | Review for archive in v4.28 |
| playbooks | unclear | No clear activation path | Review for archive in v4.28 |
| pencil-pen-format | unclear | Pencil.dev format, may be stale | Review for archive in v4.28 |
| pencil-design | unclear | Pencil.dev design, may be stale | Review for archive in v4.28 |
| database-migration | migration-patterns skill | Overlaps with `migration-patterns` | Review for archive in v4.28 |
| cross-repo-dependencies | unclear | No clear activation path | Review for archive in v4.28 |
| ci-cd-pipeline | unclear | No clear activation path | Review for archive in v4.28 |
