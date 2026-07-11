---
name: verification-before-completion
description: Prove work is actually done before claiming COMPLETE. Evidence before assertions. Run gates, verify behavior, test edge cases, check regressions.
---

# Verification Before Completion Skill

> Activate before: any COMPLETE verdict, any APPROVED status, any "it's done" claim.
> HARD RULE: "It should work" is not verification. Show evidence.

---

## The Problem This Solves

Agents (and engineers) declare work complete based on:
- "The code looks right"
- "Tests pass" (without checking if tests cover the actual behavior)
- "I implemented what was asked" (without verifying from the user's perspective)

This skill forces evidence-based completion.

---

## Verification Checklist (run ALL items, not just the easy ones)

### Gate 1: Quality Gates
Use the native OpenCode gate flow: `/gates`

All four must pass: lint ✓ typecheck ✓ test ✓ build ✓
If any fail → fix before proceeding. Never skip.

### Gate 2: Behavioral Verification
Answer each question with evidence (log output, screenshot, test result):

- [ ] Does the feature do what was requested? (not "I implemented X" — "when user does Y, Z happens")
- [ ] Are ALL success paths tested?
- [ ] Are the PRIMARY error paths tested? (invalid input, network failure, not authenticated)
- [ ] Does it behave correctly on mobile viewport? (if UI work)

### Gate 3: Regression Check
```bash
git diff HEAD~1 --stat  # what changed
git diff HEAD~1         # line-by-line changes
```

For each changed file, ask: "Could this change break something that was working?"
- Changed a utility function → did anything else that calls it break?
- Changed a database query → does it still return the right shape?
- Changed a component prop → did parent components break?

### Gate 4: Playwright Verification (UI changes only)
Use Playwright MCP to open the app and verify visually:
1. Navigate to the changed page/component
2. Take a screenshot
3. Verify the change is visible and correct
4. Test the interactive behavior (click, type, submit)
5. Check console for errors (`page.on('console', ...)`)

### Gate 5: Staff Engineer Bar
Ask yourself: "Would a senior engineer approve this in code review?"
- Is the solution simple? Or did I over-engineer?
- Is the root cause fixed, or is this a band-aid?
- Is there a simpler approach that I missed?
- Does the code match the patterns in the rest of the repo?

---

## Evidence Format

When reporting COMPLETE, provide evidence for each gate:

```
VERIFICATION EVIDENCE

Gates:     lint ✓ | typecheck ✓ | test ✓ (47 passing, 0 failing) | build ✓
Behavior:  Verified: user submits form → item appears in list within 200ms
           Verified: empty input → "Name required" error shown
           Verified: network error → retry button appears
Regression: Checked 3 callers of changed function — all pass tests
UI:        Screenshot taken at 375px and 1440px — layout correct at both
Staff bar: Solution uses existing pattern from UserCard component. No new abstractions.
```

---

## Red Flags That Mean "Not Done"

- "The tests should pass" (run them — do they?)
- "I think the UI looks right" (open it — does it?)
- "This shouldn't break anything" (check it — does anything break?)
- "The logic is correct" (test it with actual inputs — is it?)
- Only happy path tested
- No error handling for the obvious failure modes
- Feature works in isolation but breaks in the real app context

---

## Structured UI/UX Evidence (v4.9.0)

> When the scope includes UI changes, append this evidence section to the verification output.
> All UI evidence fields are required before claiming COMPLETE for UI work.

```markdown
## UI/UX Evidence Summary

### Screenshots
- Dev URL: <url>
- Desktop (1440px): <screenshot-path or "captured">
- Mobile (375px): <screenshot-path or "captured">

### Viewport Matrix
| Breakpoint | Status | Issues |
|---|---|---|
| 375×667 | ✅ Pass / ❌ Fail | <issues or "none"> |
| 768×1024 | ✅ Pass / ❌ Fail | <issues or "none"> |
| 1024×768 | ✅ Pass / ❌ Fail | <issues or "none"> |
| 1440×900 | ✅ Pass / ❌ Fail | <issues or "none"> |
| 1920×1080 | ✅ Pass / ❌ Fail | <issues or "none"> |

### Console Errors
- Count: <number>
- Errors: <list or "none">
- Warnings: <list or "none">

### Network Errors
- Count: <number>
- Failed requests: <list or "none">

### Accessibility Audit (WCAG 2.2)
- Result: PASS / FAIL / NOT_RUN (<reason>)
- Critical: <count>
- High: <count>
- Medium: <count>
- Low: <count>
- Focus order: ✅ / ❌
- Keyboard navigation: ✅ / ❌
- Contrast compliance: ✅ / ❌

### Visual Regression
- Baseline exists: ✅ / ❌
- Screenshots compared: <count>
- Pixel diff: <percentage>
- Result: ✅ Pass / ❌ Fail / NOT_RUN (<reason>) / MANUAL_REVIEW

### Responsive Integrity
- Layout breaks: <count>
- Horizontal scroll: ✅ / ❌
- Touch targets < 44px: <count>
- Overflow issues: <list or "none">

### State Coverage
| State | Present? | Notes |
|---|---|---|
| Loading | ✅ / ❌ | <notes> |
| Empty | ✅ / ❌ | <notes> |
| Error | ✅ / ❌ | <notes> |
| Success | ✅ / ❌ | <notes> |
| Disabled | ✅ / ❌ | <notes> |

### Performance (Lighthouse — Advisory)
- Result: PASS / FAIL / NOT_RUN (<reason>)
- Performance: <score>
- LCP: <value> / 2.5s target
- CLS: <value> / 0.1 target

### Known Visual Risks
- <risk or "none">

### Accepted Non-Blocking Issues
- <issue or "none">
```

### When UI Evidence Is Required

UI evidence fields are required when:
- Any `.tsx`, `.jsx`, `.vue`, `.svelte` file is changed
- Any `.css`, `.scss`, `.less` file is changed
- Any file under `components/`, `pages/`, `views/`, `screens/`, `app/` is changed
- Any layout, navigation, or visual pattern is modified

### When UI Evidence Can Be Skipped

Mark UI evidence as `NOT_RUN` with reason when:
- No UI files in scope — reason: "no UI changes in this scope"
- Text-only / copy change — reason: "text-only change, no visual layout impact"
- Backend-only change — reason: "backend change, no UI impact"
- Dev server not available — reason: "dev server not running, cannot capture screenshots"

---

## Runtime Styling Integrity Check (v4.9.2)

> **HARD RULE:** Browser verification must include ALL materially affected render states, not only the easiest seeded state.
> If the app renders as browser-default HTML (plain text, unstyled inputs, native buttons), verification is FAILED regardless of test results.

### The Problem This Solves

Prior verification missed unstyled onboarding screens because:
1. Tests seeded `localStorage` with user data, skipping onboarding entirely
2. Only the authenticated/main-app state was visually verified
3. The unauthenticated/onboarding state was never checked
4. CSS import breakage went undetected until a human opened localhost

### Required Checks for UI Work

**1. Verify all materially affected render states**

| State | When to verify | How |
|-------|---------------|-----|
| Unauthenticated / onboarding | If UI touches onboarding, global styles, or app entry | Clear `localStorage`, open app, verify styled render |
| Authenticated / main app | If UI touches main app surfaces | Seed user state, verify styled render |
| Dark mode | If UI touches theme tokens or dark mode styles | Toggle theme, verify both modes |
| Error / empty states | If UI touches error handling or empty states | Trigger error/empty condition, verify styled render |

**2. Confirm CSS files are loaded**

```python
# In Playwright verification:
css_loaded = []
page.on("response", lambda res: css_loaded.append(res.url) if "css" in res.url.lower() else None)
# After navigation, verify expected CSS files are in css_loaded
# Verify no 404s or MIME type errors for CSS assets
```

**3. Confirm key styled elements have non-default computed styles**

For at least 3 representative elements per screen, verify:
- `background` is not `rgba(0, 0, 0, 0)` or `transparent` (unless intentional)
- `border-radius` is not `0px` (unless intentional)
- `padding` is not `0px` (unless intentional)
- `font-family` matches the design system (not browser default)
- `color` is not `rgb(0, 0, 0)` on white background (unless intentional)

**4. Report state seeding used during verification**

Every verification report must include:
```
Verification state:
- localStorage: <cleared / seeded with user data / seeded with partial onboarding>
- Auth state: <unauthenticated / authenticated>
- Theme: <light / dark / both verified>
- Viewport: <mobile / desktop / both verified>
```

**5. User screenshot contradiction blocks completion**

If a user-provided manual screenshot shows unstyled content that contradicts agent verification:
- The user screenshot wins
- Block commit until the discrepancy is resolved
- Do not claim verification passed

**6. Browser-default HTML is an automatic FAIL**

Signs of browser-default rendering:
- Plain text with no typography hierarchy
- Inputs with native browser styling (no border-radius, no custom padding)
- Buttons with native appearance (no custom background, no hover states)
- No visible spacing system (elements touching each other)
- No visible color system (all black text on white)

If any of these are present → verification FAILED. Do not proceed to commit.

### Evidence Format Addition

Append this section to UI verification reports:

```markdown
### Runtime Styling Integrity

| Check | Status | Notes |
|-------|--------|-------|
| CSS files loaded | ✅ / ❌ | <list loaded CSS files> |
| No failed CSS requests | ✅ / ❌ | <list failures or "none"> |
| Unauthenticated state styled | ✅ /  / N/A | <notes> |
| Authenticated state styled | ✅ / ❌ / N/A | <notes> |
| Computed styles non-default | ✅ / ❌ | <sample elements checked> |
| State seeding reported | ✅ /  | <what was seeded> |
| User screenshot contradiction | ✅ None / ❌ Blocked | <details if blocked> |
```
