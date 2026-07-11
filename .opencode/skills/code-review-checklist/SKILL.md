---
name: code-review-checklist
description: Systematic code review checklist beyond security — naming, complexity, test coverage, documentation, architecture, and maintainability.
---

# Code Review Checklist

Systematic code review checklist for non-security aspects of code quality.

## When to Use

- User asks for "code review", "PR review", "review checklist"
- Reviewing a pull request before merge
- Self-reviewing code before committing
- Distinct from `/review` command (which is the protocol command) and security review (which uses the security skill)

## Review Workflow

### Step 1: Understand the Change
- Read the PR description or task brief
- Understand the objective and scope
- Identify the risk level (Low/Medium/High)
- Check if the change matches the planned scope

### Step 2: Review by Category
Work through each category below. Flag findings with severity.

### Step 3: Report
- Lead with Critical and High findings
- Group by category
- Provide specific file:line references
- Suggest concrete fixes

## Review Categories

### 1. Correctness
- [ ] Does the code do what it claims to do?
- [ ] Are edge cases handled? (empty input, null, boundary values)
- [ ] Are error paths tested, not just happy paths?
- [ ] Are there race conditions or concurrency issues?
- [ ] Does it handle the "nothing found" case?

### 2. Naming and Readability
- [ ] Variable names describe what they hold, not how they're computed
- [ ] Function names describe what they do (verb + noun)
- [ ] No abbreviations that aren't universally understood
- [ ] Boolean variables read as questions (`isValid`, `hasPermission`)
- [ ] Constants are uppercase with underscores (`MAX_RETRIES`)

### 3. Complexity
- [ ] Functions are under 30 lines (soft limit)
- [ ] No nested conditionals deeper than 3 levels
- [ ] Early returns used instead of deep nesting
- [ ] No god objects or god functions doing too many things
- [ ] Cyclomatic complexity is reasonable (under 10 per function)

### 4. Test Coverage
- [ ] New code has corresponding tests
- [ ] Tests verify behavior, not implementation details
- [ ] Tests have descriptive names (`should_return_404_when_user_not_found`)
- [ ] Edge cases are tested (empty, null, boundary, error)
- [ ] No flaky tests (no arbitrary timeouts, no order dependencies)
- [ ] Mock boundaries are clear (mock external calls, not internal logic)

### 5. Error Handling
- [ ] Errors are caught and handled, not swallowed
- [ ] Error messages are actionable (not just "something went wrong")
- [ ] No stack traces exposed to clients
- [ ] Graceful degradation for external service failures
- [ ] Retry logic has limits (no infinite retry loops)

### 6. API and Contract Changes
- [ ] Breaking changes are documented
- [ ] API versioning is considered for public APIs
- [ ] Request/response schemas are validated
- [ ] Backward compatibility is maintained where possible
- [ ] API documentation is updated (APP_FLOW.md or equivalent)

### 7. Performance
- [ ] No N+1 query patterns
- [ ] Database queries are indexed appropriately
- [ ] Large datasets are paginated
- [ ] No unnecessary re-renders (React)
- [ ] Expensive operations are memoized or cached
- [ ] Bundle size impact is considered for frontend changes

### 8. Architecture
- [ ] Change follows existing patterns and conventions
- [ ] No circular dependencies introduced
- [ ] Separation of concerns is maintained
- [ ] New dependencies are justified (not reinventing the wheel)
- [ ] No tight coupling between unrelated modules

### 9. Documentation
- [ ] Complex logic has inline comments explaining WHY, not WHAT
- [ ] Public APIs have JSDoc/TSDoc comments
- [ ] README updated if setup or usage changed
- [ ] `.env.example` updated if new environment variables added
- [ ] Migration notes included if schema changed

### 10. Git Hygiene
- [ ] Commit messages are descriptive and imperative
- [ ] No debug code or console.log left in
- [ ] No commented-out code blocks
- [ ] No merge commits in feature branches (rebase preferred)
- [ ] PR scope matches the PR title and description

## Severity Classification

| Severity | Meaning | Action |
|---|---|---|
| **Critical** | Bug, data loss, security issue | Must fix before merge |
| **High** | Significant design flaw, missing error handling | Should fix before merge |
| **Medium** | Readability issue, minor design concern | Fix in this PR or create follow-up |
| **Low** | Style nit, minor improvement | Optional, nice to have |

## Review Output Format

```
## Review: <PR title or scope>

Verdict: Approve / Approve with minor fixes / Requires changes

Findings:
  [Critical] <file>:<line> — <problem> -> <recommendation>
  [High]     <file>:<line> — <problem> -> <recommendation>
  [Medium]   <file>:<line> — <problem> -> <recommendation>
  [Low]      <file>:<line> — <problem> -> <recommendation>

Summary: <one paragraph>
```

## Anti-Patterns (Never Do)

- Approve without reading the diff
- Only review for style, ignore logic
- Nitpick on personal preferences without citing a standard
- Review without understanding the objective
- Leave vague feedback ("this looks wrong" without explaining why)
- Mix implementation planning into review output
