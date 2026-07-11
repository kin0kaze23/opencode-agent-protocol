# UI Work Rules — Auto-Activated

**Trigger:** Editing files matching `**/*.tsx`, `**/*.css`, `**/*.html`, `**/components/**`, `**/pages/**`, `**/views/**`, `**/screens/**`, `**/app/**`

**Source:** Adapted from `.claude/rules/ui-work.md` + `.opencode/skills/frontend-design/SKILL.md`

---

## Activation Sequence (Zoom-In Method)

For any UI task, activate in this order:

1. **Design research** (`design-research`) — for net-new UI, major redesign, onboarding, landing pages, dashboards, or brand-sensitive surfaces
2. **Platform guidelines compliance** (`platform-guidelines-compliance`) — for platform-sensitive UI (iOS, Android, Capacitor, cross-platform web)
3. **Illustration/graphic direction** (`illustration-graphic-direction`) — when graphics, icons, empty states, or hero surfaces are involved
4. Read the repo's design system docs — understand the design language
5. Invoke design brainstorming for layout / hierarchy / motion decisions before writing code
6. **Motion design** (`motion-design`) — before implementing any animation, transition, or micro-interaction
7. Follow the UI Non-Negotiables during implementation
8. After implementation: run UI/UX Quality Audit (`ui-ux-quality-audit`)
9. Run Accessibility Audit (`accessibility-audit`)
10. Run Responsive/State Audit (`responsive-state-audit`)
11. Run design-system governance check (`design-system-governance`)
12. If material visual changes: run Visual Iteration Loop (`visual-iteration-loop`) for before/after comparison
13. If material visual changes: run Visual Regression (`visual-regression`)
14. If performance-sensitive: run Lighthouse advisory (`performance`)
15. Verify WCAG compliance (contrast, keyboard support, ARIA) during and after coding
16. Spawn Reviewer before shipping — final QA pass

Do not skip steps. Design decisions (step 5) must be made before implementation (step 7).

---

## Temperature for UI Work

- Design ideation, layout decisions: **0.6** (creative latitude is valuable here)
- Implementation (TSX/CSS code): **0.1** (precise, follow established patterns)

---

## UI Non-Negotiables

- Check existing component library before creating new components
- Mobile-first: design and test at 375px before desktop breakpoints
- Every interactive element needs keyboard support and ARIA labels
- Colour contrast: minimum 4.5:1 for body text, 3:1 for large text (WCAG AA)
- No inline styles unless absolutely necessary — use Tailwind classes or CSS vars
- Use existing design tokens (colours, spacing, typography) from the repo's design system

## Project-Specific Notes

| Project | CSS approach | Component pattern |
|---------|-------------|-------------------|
| sample-service Console | Tailwind v4 + shadcn/ui | TanStack Router pages |
| demo-project | Tailwind CDN + custom CSS vars (`bg-cream`, `paper-surface`) | React functional + Context |
| areté-life-os | Tailwind | React functional + Vercel serverless |
| ClearPathOS | Tailwind + shadcn/ui | Next.js App Router |

## Design Quality (from frontend-design skill)

- NEVER: Inter, Roboto, Arial, system-ui as primary fonts — use distinctive font pairs
- NEVER: Purple gradient on white, blue gradient on dark, #3B82F6 as primary accent
- ALWAYS: Build a palette with one dominant color + one sharp accent + neutrals
- ALWAYS: Use CSS variables for every color — no hardcoded hex in components
- One well-orchestrated entrance beats ten scattered animations
- Unexpected layouts > predictable grids — use asymmetry intentionally

## Checklist Before Shipping UI

- [ ] Tone direction committed and visible in every element
- [ ] Custom font pair loaded (not system fonts)
- [ ] Color palette uses CSS variables throughout
- [ ] At least one entrance animation with stagger (if applicable)
- [ ] Hover states feel alive (not just opacity change)
- [ ] Mobile viewport tested — layout holds
- [ ] `prefers-reduced-motion` handled
- [ ] No purple gradients. No Inter. No generic card shadows.
