# Frontend UI Implementation Defaults

> **Protocol:** OpenCode v4.9.2+
> **Authority:** `.opencode/patterns/frontend-ui-defaults.md`
> **Type:** Default guidance — not mandatory global dependency

## Purpose

When an agent generates UI code, it should follow these defaults unless the target repo has an established alternative. This prevents every session from inventing its own styling approach, accessibility pattern, or animation library.

---

## Default Stack by Framework

### React / Next.js

| Layer | Default | Notes |
|---|---|---|
| Styling | Tailwind CSS v4 (utility-first) | Use `@import "tailwindcss"` in PostCSS. Prefer utility composition over custom CSS. |
| Component primitives | shadcn/ui (via Radix UI) | Copy-paste components into project. Agents own the code. Use for standard primitives only. |
| Animation | Motion for React (formerly Framer Motion) | Default for React micro-interactions. Adoption is repo-specific and non-mandatory. |
| Icons | Lucide React | Unless the repo has an established icon standard. |
| Design tokens | CSS custom properties or Tailwind config | Define color, spacing, radius, typography, elevation, and motion as tokens. |

### Vite + React (no Tailwind)

| Layer | Default | Notes |
|---|---|---|
| Styling | CSS custom properties + utility classes | If the repo already uses a custom CSS design system (e.g., demo-project), preserve it. Do not add Tailwind unless explicitly requested. |
| Component primitives | Custom components | Build accessible primitives in-repo. shadcn/ui requires Tailwind — do not force Tailwind adoption. |
| Animation | CSS transitions + `@keyframes` | Prefer CSS-only motion. Motion for React is optional for complex interactions. |
| Icons | Lucide React | Unless the repo has an established icon standard. |
| Design tokens | CSS custom properties in a single design-system file | Maintain one source of truth for all tokens. |

### React Native / Expo

| Layer | Default | Notes |
|---|---|---|
| Styling | StyleSheet + Tailwind (NativeWind) if available | Prefer built-in StyleSheet for simple apps. |
| Component primitives | React Native Paper or custom | Choose based on product identity needs. |
| Animation | React Native Reanimated | For gesture-driven and physics-based motion. |
| Icons | Lucide React Native | Consistent with web where possible. |

---

## Design Token Categories

Every app should define tokens for these categories:

| Category | Purpose | Example |
|---|---|---|
| Color | Backgrounds, surfaces, text, accents, functional states | `--color-bg`, `--color-accent`, `--color-error` |
| Spacing | Consistent rhythm for padding, margin, gap | `--space-1` through `--space-16` |
| Radius | Corner rounding for cards, buttons, inputs | `--radius-sm`, `--radius-md`, `--radius-lg` |
| Typography | Font families, sizes, weights, line heights | `--font-body`, `--text-base`, `--font-weight-semibold` |
| Elevation | Shadows, z-index layers, glass effects | `--shadow-sm`, `--shadow-lg`, `--glass-bg` |
| Motion | Durations, easing curves, spring configs | `--duration-fast`, `--ease-out-expo` |

---

## Custom vs. Library Components

- **Use shadcn/ui** for standard accessible primitives: Dialog, Select, DropdownMenu, Tooltip, Popover, Tabs, Accordion, Switch, Checkbox, RadioGroup, Slider, Toast, Alert, Progress, Separator, Avatar, Badge, Skeleton.
- **Build custom components** when the product needs unique branded patterns, domain-specific visualizations, or interactions that shadcn/ui does not cover.
- **Never hand-roll** accessible dialogs, dropdowns, selects, tooltips, or popovers unless justified by a specific product requirement. Use Radix primitives or shadcn/ui instead.

---

## Motion Guidelines

- Motion must serve clarity, feedback, hierarchy, or transition — never decoration alone.
- Always respect `prefers-reduced-motion`.
- Prefer subtle opacity, transform, scale, and layout transitions.
- Avoid decorative motion that slows task completion.
- See `motion-design` skill for detailed implementation guidance.

---

## Accessibility Baseline

Every new component must include:

- Keyboard navigation (Tab, Enter, Escape, Arrow keys where applicable)
- ARIA labels and roles
- Focus-visible states
- Color contrast meeting WCAG 2.2 AA (4.5:1 for text, 3:1 for large text/UI)
- `prefers-reduced-motion` support
- Loading, empty, error, disabled, and success states where applicable

---

## Repo-Specific Overrides

These defaults are overridden when a repo has established patterns:

| Repo | Override |
|---|---|
| demo-project | Uses custom CSS design system (no Tailwind). Preserve WaxSeal, InkText, ScrollUnfurl, demo-projectLogo as identity components. CSS-only motion preferred. |
| protected-repo | Uses Tailwind v4 + Framer Motion. Has established component library (28 components). Preserve BabyAvatar, Illustration, ProgressRing, QuickLogButton as identity components. |
