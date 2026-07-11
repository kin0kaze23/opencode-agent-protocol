---
name: platform-guidelines-compliance
description: Platform guideline compliance — Apple HIG, Material 3, WCAG 2.2, safe areas, touch targets, native motion, when to follow convention vs custom brand
version: v4.9.2
---

# Platform Guidelines Compliance Skill

> Activate for: any UI targeting specific platforms (iOS, Android, cross-platform web, Capacitor)
> HARD RULE: Never claim platform compliance without real evidence. Use PASS / FAIL / NOT_RUN with reason.

---

## Purpose

Ensures UI respects platform conventions where appropriate while allowing intentional brand expression. Apple's HIG and Material 3 are official guidance documents with specific conventions for navigation, motion, safe areas, and interaction. Agents need to know when to follow platform conventions vs when to express custom brand identity.

---

## Phase 1: Identify Target Platform

| Target | Platform Check Applies |
|---|---|
| iOS / iPadOS (Capacitor, React Native, SwiftUI) | Apple HIG + WCAG 2.2 |
| Android (Capacitor, Jetpack Compose) | Material 3 + WCAG 2.2 |
| Cross-platform web (React, Vue, Svelte targeting mobile Safari/Chrome) | Both HIG + Material 3 principles + WCAG 2.2 |
| Desktop web only | WCAG 2.2 only; mobile platform checks NOT_RUN |
| Internal admin tool | WCAG 2.2 only; platform conventions advisory |

---

## Phase 2: Apple HIG Compliance (where applicable)

Reference Apple HIG principles for designing high-quality Apple-platform experiences:

| Area | Check | Pass Criteria |
|---|---|---|
| Navigation | Follows iOS navigation patterns | Tab bar, navigation stack, modal presentation as appropriate |
| Safe areas | Content respects notch, home indicator, status bar | Uses safe-area-inset-* CSS env variables |
| Touch targets | Minimum 44×44pt (Apple recommendation) | All interactive elements meet minimum |
| Motion | Spring-based, physics-driven feel | Uses spring-like easing, not linear or generic ease |
| Typography | Dynamic Type support, system font hierarchy | Respects user text size preferences |
| Dark mode | System-wide dark mode support | Uses prefers-color-scheme, not app-specific toggle |
| Layout | Full-width content, generous whitespace | Content fills width appropriately, margins respect safe areas |
| Feedback | Haptic feedback where appropriate | Visual confirmation for all interactions |

---

## Phase 3: Material 3 Compliance (where applicable)

Reference Material 3 foundations for design tokens and motion guidance:

| Area | Check | Pass Criteria |
|---|---|---|
| Navigation | Follows Android navigation patterns | Bottom nav, drawer, FAB as appropriate |
| Touch targets | Minimum 48×48dp (Material recommendation) | All interactive elements meet minimum |
| Motion | Curve-based easing, shared element transitions | Uses Material easing curves, not generic |
| Elevation | Uses Material shadow system | Consistent elevation levels |
| Color | Dynamic color, tonal palettes | Uses tonal color system, not arbitrary colors |
| Layout | Grid system, consistent spacing | Follows 8dp grid system |
| Typography | Material type scale | Uses Material typography scale |

---

## Phase 4: WCAG 2.2 AA Baseline

Delegate to `accessibility-audit` for full WCAG 2.2 AA check. Key platform-relevant items:

| WCAG 2.2 Item | Platform Relevance |
|---|---|
| 2.5.8 Target Size (Minimum) | 24×24 CSS px minimum — all platforms |
| 1.4.10 Reflow | Mobile viewport must support zoom/reflow |
| 1.4.4 Resize Text | Must support 200% text zoom without breaking |
| 2.4.7 Focus Visible | Focus indicators must meet platform contrast expectations |

---

## Phase 5: Platform Conventions vs Custom Brand

| Follow Platform Convention When | Use Custom Brand Expression When |
|---|---|
| Navigation patterns (tab bar, back gesture) | Hero sections, landing pages |
| System UI patterns (status bar, notch handling) | Color accents (if brand-defining) |
| Accessibility patterns (VoiceOver, TalkBack) | Typography (if brand-defining display font) |
| Gesture expectations (swipe to delete, pull to refresh) | Illustrations, brand graphics |
| Touch target minimums | Micro-interactions (if brand-personality-defining) |

---

## Phase 6: Safe Area / Notch / Home Indicator

For iOS/Capacitor/web apps targeting mobile Safari:

```css
/* Required safe area handling */
padding-top: env(safe-area-inset-top);
padding-bottom: env(safe-area-inset-bottom);
padding-left: env(safe-area-inset-left);
padding-right: env(safe-area-inset-right);
```

**Check:**
- Content is not obscured by notch or Dynamic Island
- Bottom navigation/bar is not hidden by home indicator
- Status bar area is respected (no interactive elements in status bar zone)

---

## Evidence Format

```markdown
## Platform Compliance Review

Target platform: [iOS / Android / Cross-platform web / Desktop web only]

Apple HIG: PASS / FAIL / N/A (<reason>)
  Navigation: PASS / FAIL / N/A
  Safe areas: PASS / FAIL / N/A
  Touch targets (44×44pt): PASS / FAIL / N/A
  Motion: PASS / FAIL / N/A
  Dark mode: PASS / FAIL / N/A

Material 3: PASS / FAIL / N/A (<reason>)
  Navigation: PASS / FAIL / N/A
  Touch targets (48×48dp): PASS / FAIL / N/A
  Motion: PASS / FAIL / N/A
  Elevation: PASS / FAIL / N/A
  Color: PASS / FAIL / N/A

WCAG 2.2 AA: PASS / FAIL / N/A (<reason>) (delegate to accessibility-audit)
  Target size (24×24 CSS px): PASS / FAIL / N/A

Platform vs custom decisions documented: PASS / FAIL

Findings:
- [Critical/High/Medium/Low] [specific issue]
```

---

## Failure Conditions

Platform compliance review fails (blocks completion) if ANY of:
- Safe area violations (content obscured by notch/home indicator)
- Touch targets below platform minimum (24×24 CSS px WCAG 2.2 minimum)
- Navigation pattern contradicts platform expectation without documented justification
- Claimed platform compliance without evidence

---

## NOT_RUN Rules

Mark as NOT_RUN with reason when:
- Desktop-only web app — reason: "no mobile platform target"
- Internal admin tool — reason: "no user-facing platform compliance needed"
- No platform-specific targeting declared — reason: "platform not specified, web-only assumed"
- Static content only — reason: "no interactive elements to check"

---

## Integration with Other Skills

- Referenced by `ui-ux-quality-audit` for platform compliance check
- Referenced by `design-research` for platform-aware aesthetic notes
- Referenced by `motion-design` for platform-specific motion patterns (spring vs curve)
- Delegates to `accessibility-audit` for WCAG 2.2 baseline
