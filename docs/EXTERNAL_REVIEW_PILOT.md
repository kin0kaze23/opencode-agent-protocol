# External Review Pilot

> **Purpose:** Defines the first structured external review cycle for OpenCode Agent Protocol.
> **Last Updated:** 2026-07-11

---

## Reviewer Profile

We are looking for 3–5 technical reviewers who:

- Are comfortable with bash, git, and GitHub
- Have experience with AI coding agents (OpenCode, Claude Code, Cursor, etc.)
- Can follow a structured checklist and provide honest feedback
- Are willing to spend 15–30 minutes reviewing the repo

No prior knowledge of this protocol is required.

---

## Review Goals

1. **Install validation** — Can a new user clone and validate the repo without issues?
2. **Documentation clarity** — Are the docs understandable without private context?
3. **Capability understanding** — Can a reviewer identify what the protocol does and does not do?
4. **Safety assessment** — Does the reviewer feel the guardrails are adequate?
5. **Feedback quality** — Does the feedback template capture useful, actionable feedback?

---

## Expected Time Commitment

| Step | Time |
|------|------|
| Clone and validate | 5 minutes |
| Read Capability Catalog and Runtime Map | 5 minutes |
| Inspect Protocol Atlas | 3 minutes |
| Review example workflows | 5 minutes |
| Review claims, failure modes, and threat model | 5 minutes |
| File feedback | 5 minutes |
| **Total** | **15–30 minutes** |

---

## Exact First-Run Steps

1. Clone: `git clone https://github.com/kin0kaze23/opencode-agent-protocol.git`
2. Follow: [docs/FIRST_RUN_CHECKLIST.md](FIRST_RUN_CHECKLIST.md)
3. Read: [docs/EXTERNAL_REVIEW_GUIDE.md](EXTERNAL_REVIEW_GUIDE.md)
4. File feedback: Use the "External Review Feedback" issue template

---

## What Feedback Is Most Useful

- **Install blockers** — anything that prevents cloning or validation
- **Documentation confusion** — unclear sections, missing context, broken links
- **Validation failures** — any script that fails unexpectedly
- **Safety concerns** — gaps in guardrails or threat model
- **Capability gaps** — expected capabilities that are missing
- **Positioning concerns** — claims that feel overstated or understated

---

## What Is Out of Scope

- Product code (this is a protocol layer, not a product)
- Internal development history (v4.x is private)
- Model performance benchmarks (not yet published)
- Comparative analysis with other harnesses
- Feature requests for new protocol capabilities

---

## How to File Feedback

1. Go to [Issues](https://github.com/kin0kaze23/opencode-agent-protocol/issues)
2. Click "New Issue"
3. Select "External Review Feedback"
4. Fill in the structured fields
5. Submit

---

## How Feedback Will Be Triaged

Feedback will be classified and prioritized per [docs/FEEDBACK_TRIAGE.md](FEEDBACK_TRIAGE.md).

Summary of all feedback will be published in [docs/REVIEW_FEEDBACK.md](REVIEW_FEEDBACK.md) after the review cycle closes.

---

## Review Cycle Timeline

| Phase | Duration |
|-------|----------|
| Invite reviewers | 1 day |
| Reviewers complete checklist | 3–5 days |
| Triage feedback | 1–2 days |
| Publish feedback summary | 1 day |
| Plan fixes | 1 day |
| **Total** | **~1 week** |
