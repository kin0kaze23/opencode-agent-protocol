---
name: responsive-state-audit
description: Viewport matrix testing and UX state coverage — loading, empty, error, success, disabled states
version: v4.9.0
---

# Responsive/State Audit Skill

> Activate for: any new or changed component, layout, or user-facing flow
> HARD RULE: Test every viewport. Design every state.
> This skill combines responsive integrity and UX state coverage.

---

## Purpose

Ensures UI works correctly across all relevant viewport sizes AND that every interactive flow has designed states (loading, empty, error, success, disabled).

---

## Triggers

Auto-activate when:
- New components are created
- Layouts are modified
- User-facing flows are changed
- `/implement` scope includes UI files

Do NOT activate for:
- Backend-only changes
- Text-only changes with no layout impact

---

## Audit Procedure

### Part A: Responsive Integrity

#### Viewport Matrix

Test at these breakpoints:

| Breakpoint | Dimensions | Device Class | Check |
|---|---|---|---|
| Mobile S | 375×667 | Small phone (iPhone SE) | Layout, touch targets, readability |
| Mobile L | 414×896 | Large phone (iPhone 11+) | Layout, touch targets, readability |
| Tablet | 768×1024 | iPad | Layout adaptation, navigation |
| Desktop S | 1024×768 | Small laptop | Layout, spacing |
| Desktop L | 1440×900 | Standard desktop | Full layout, spacing |
| Desktop XL | 1920×1080 | Large monitor | Max-width, centering |

#### Responsive Checks at Each Breakpoint

- [ ] Layout integrity — no broken grid, overlapping elements
- [ ] No horizontal scroll — `overflow-x` clean at all widths
- [ ] Content not clipped — nothing hidden or cut off
- [ ] Touch targets ≥ 44×44px on mobile viewports
- [ ] Typography readable — minimum 14px body text
- [ ] Navigation adapts — hamburger menu, collapse, or reflow
- [ ] Images/media scale correctly — no overflow
- [ ] Spacing adjusts — appropriate density at each size
- [ ] Buttons remain usable — not too small, not overlapping
- [ ] Forms remain usable — inputs not too narrow

#### Critical Responsive Failures

| Issue | Severity |
|---|---|
| Horizontal scroll at any breakpoint | Critical |
| Content clipped/hidden | Critical |
| Touch targets < 24px on mobile | High |
| Unreadable text (< 12px) | High |
| Navigation broken on mobile | High |
| Image overflow | Medium |
| Spacing inconsistent between breakpoints | Medium |
| Minor alignment shift | Low |

---

### Part B: UX State Coverage

For every interactive component/flow, verify these states exist:

#### 1. Loading State
- Is there a visual indicator that something is happening?
- Is it more than just a basic spinner?
- Are skeleton screens used where appropriate?
- Does it communicate what is loading?
- Is there a timeout/error state if loading fails?

#### 2. Empty State
- Is there a designed empty state (not just blank space)?
- Does it explain WHY the area is empty?
- Does it guide the user to take action?
- Is there a clear CTA to create/add/import content?
- Is the tone appropriate (helpful, not apologetic)?

#### 3. Error State
- Is the error state designed (not raw error dump)?
- Is the error message human-readable?
- Does it explain WHAT went wrong?
- Does it suggest HOW to fix it?
- Is there a retry/recovery mechanism?
- Does it preserve user input where possible?

#### 4. Success State
- Is there confirmation that the action completed?
- Is it clear WHAT was accomplished?
- Does it guide to the next step?
- Is the confirmation dismissible?

#### 5. Disabled State
- Is it visually clear when a component is disabled?
- Is the disabled state accessible (not just greyed out)?
- Does it communicate WHY it is disabled?
- Is it still keyboard-navigable (focusable with explanation)?

#### 6. Skeleton/Shimmer
Where appropriate (data loading):
- Are skeleton screens used instead of spinners?
- Do skeletons match the shape of the content?
- Is the shimmer animation subtle?
- Does it respect `prefers-reduced-motion`?

---

## Evidence Format

```markdown
## Responsive/State Audit — [Feature/Screen]

### Responsive Integrity

Viewport matrix:
| Breakpoint | Dimensions | Status | Issues |
|---|---|---|---|
| Mobile S | 375×667 | ✅ Pass / ❌ Fail | <issues or "none"> |
| Mobile L | 414×896 | ✅ Pass / ❌ Fail | <issues or "none"> |
| Tablet | 768×1024 | ✅ Pass / ❌ Fail | <issues or "none"> |
| Desktop S | 1024×768 | ✅ Pass / ❌ Fail | <issues or "none"> |
| Desktop L | 1440×900 | ✅ Pass / ❌ Fail | <issues or "none"> |
| Desktop XL | 1920×1080 | ✅ Pass / ❌ Fail | <issues or "none"> |

No horizontal scroll: ✅ / ❌
No content clipping: ✅ / ❌
Touch targets adequate: ✅ / ❌
Typography readable: ✅ / ❌
Navigation adapts: ✅ / ❌

### UX State Coverage

| State | Present? | Quality | Notes |
|---|---|---|---|
| Loading | ✅ / ❌ | Good / Adequate / Missing | <notes> |
| Empty | ✅ / ❌ | Good / Adequate / Missing | <notes> |
| Error | ✅ / ❌ | Good / Adequate / Missing | <notes> |
| Success | ✅ / ❌ | Good / Adequate / Missing | <notes> |
| Disabled | ✅ / ❌ | Good / Adequate / Missing | <notes> |
| Skeleton | ✅ / ❌ / N/A | Good / Adequate / Missing | <notes> |

Overall verdict: PASS / FAIL

Findings:
- [Critical/High/Medium/Low] [specific issue]
```

---

## Severity Levels

| Level | Meaning |
|---|---|
| Critical | Horizontal scroll, clipped content, broken layout at a breakpoint |
| High | Touch targets too small, unreadable text, navigation broken |
| Medium | Missing UX state (no loading, no empty state), spacing inconsistent |
| Low | Minor responsive polish needed, state present but could be better |
| Info | Observation |

---

## Failure Conditions

Audit fails (blocks ship) if ANY of:
- Critical responsive failure at any breakpoint
- Missing error state for interactive flow
- Missing loading state for async operation
- Touch targets below 24px on mobile

---

## NOT_RUN Rules

Mark as NOT_RUN with reason when:
- No UI files in scope — reason: "no UI changes in this scope"
- No browser access — reason: "dev server not available for viewport testing"
- Component is internal/utility only — reason: "no user-facing UI to test"
