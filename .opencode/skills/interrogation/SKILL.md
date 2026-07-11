---
name: interrogation
description: Eliminate assumptions before implementation begins — structured questions, canonical docs. Ask 20 structured questions. Produce canonical docs. No coding until clarity achieved.
---

# Interrogation Skill

> Activate for: new feature, unclear request, ambiguous scope, unknown repo/user/constraints.
> This checked-in OpenCode skill is the live version for OpenCode sessions.

---

## The Non-Negotiable Rule

**Do not code in Interrogation Mode.** Output only: questions → answers → canonical docs.

---

## When to Interrogate

- Request is ambiguous or has multiple valid interpretations
- You don't know the target repo, user, or use case
- You're about to assume data shape, auth, or behavior
- Scope could be big or small
- Multiple technical approaches with meaningfully different trade-offs

---

## The 20-Question Stack

### Identity & Context
1. What repo/project is this for?
2. Who is the end user? (role, technical level)
3. What problem does this solve for them?

### Behavior & Scope
4. What is the core action? (verb + noun: "user submits form", "API returns list")
5. What happens on success? (exact outcome, redirect, message, state change)
6. What happens on error?
7. What data is saved/changed?
8. What data is displayed?

### Technical Constraints
9. Does it need authentication? What kind?
10. Does it need a database? Which one? New table or existing?
11. Are there existing components/patterns to reuse?
12. Any new dependencies required?
13. Mobile-first or desktop?

### Scope Boundaries
14. What is explicitly OUT OF SCOPE?
15. What's the MVP vs. future enhancement?
16. Any time/complexity constraints?

### Launch Readiness (new project / first feature)
17. Is error tracking set up? (Sentry)
18. Is analytics set up? (PostHog/Plausible)
19. Are preview deployments enabled? (Vercel PR previews)
20. Is there a README with local setup + env vars list?

---

## Output Format

After interrogation, produce:

```markdown
## Interrogation Summary: <Feature Name>

### Answers
| Question | Answer |
|----------|--------|
| Repo | sample-service |
| End user | Admin managing workflows |
...

### Canonical Requirements
- [x] Core behavior defined
- [x] Error cases defined
- [x] Scope boundaries set
- [x] MVP defined

### Ready to implement: YES / NO (reasons if NO)
```
