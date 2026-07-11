# Component Decision Rule

> **Protocol:** OpenCode v4.9.2+
> **Authority:** `.opencode/patterns/component-decision-rule.md`
> **Type:** Mandatory decision flow for all UI implementation

## Purpose

Prevents agents from creating "beautiful but fragile" UI by enforcing a structured decision flow before generating any new component.

---

## Decision Flow

When implementing UI, follow this order:

### Step 1: Use Existing Repo Components First

Check the repo's component registry (`docs/design-system/COMPONENT_REGISTRY.md`) for existing components that match the need.

- If a suitable component exists → **use it**
- If a suitable component exists but needs minor customization → **extend it**
- If no suitable component exists → proceed to Step 2

### Step 2: Use shadcn/ui for Standard Primitives

If the repo uses Tailwind CSS and has shadcn/ui configured:

- For standard accessible primitives (Dialog, Select, DropdownMenu, Tooltip, Popover, Tabs, Accordion, Switch, Checkbox, RadioGroup, Slider, Toast, Alert, Progress, Separator, Avatar, Badge, Skeleton) → **add from shadcn/ui**
- If the repo does NOT use Tailwind → **skip to Step 3**

### Step 3: Compose Custom Product Components

Build custom components on top of existing primitives when:

- The product needs a unique branded pattern (e.g., demo-project WaxSeal, protected-repo ProgressRing)
- The interaction is domain-specific (e.g., devotional content display, baby growth tracking)
- shadcn/ui does not cover the use case

### Step 4: Do Not Hand-Roll Accessible Primitives

**Never** hand-roll these unless explicitly justified with a product requirement:

- Dialogs / Modals
- Dropdowns / Selects
- Tabs
- Tooltips
- Popovers
- Complex form controls (checkboxes, radio groups, switches, sliders)

Use Radix UI primitives or shadcn/ui instead. These require careful ARIA, keyboard, and focus management that is error-prone when built from scratch.

### Step 5: Include All Required States

Every new component must include these states where applicable:

| State | When Required |
|---|---|
| Responsive | Always — mobile, tablet, desktop |
| Loading | When fetching or processing data |
| Empty | When no data exists to display |
| Error | When an operation fails |
| Disabled | When interaction is temporarily unavailable |
| Keyboard | Always — Tab, Enter, Escape, Arrow navigation |
| Reduced motion | Always — respect `prefers-reduced-motion` |
| Offline | When network is unavailable (progressive enhancement) |
| Long content | When content exceeds viewport or container |

---

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Correct Approach |
|---|---|---|
| Hand-rolling a dialog with `position: fixed` and manual focus trap | Misses edge cases, breaks screen readers | Use shadcn/ui Dialog or Radix DialogPrimitive |
| Creating a custom dropdown with `div` elements | Not keyboard accessible, no ARIA | Use shadcn/ui Select or Radix Select |
| Adding Tailwind to a repo that uses custom CSS design system | Breaks visual consistency, adds bundle weight | Respect existing styling approach |
| Installing Motion for React when CSS transitions suffice | Unnecessary dependency, bundle bloat | Use CSS `transition` and `@keyframes` |
| Building a card component without loading/empty/error states | Fragile — breaks on real data | Include all applicable states |
| Using purple gradients and `#3B82F6` as primary accent | Generic AI aesthetic | Use repo-specific design tokens |

---

## Repo-Specific Rules

### demo-project

- **Do not** add Tailwind CSS
- **Do not** add shadcn/ui (requires Tailwind)
- **Do not** add Motion for React unless a specific interaction cannot be handled cleanly with CSS
- **Preserve** WaxSeal, InkText, ScrollUnfurl, demo-projectLogo as identity components
- **Use** existing CSS design tokens from `design-system.css`
- **Prefer** CSS-only motion for all interactions

### protected-repo

- **Do** use existing Tailwind v4 setup
- **Do** use existing Framer Motion / Motion for React setup
- **Do** use existing component library (28 components in `src/components/ui/`)
- **Preserve** BabyAvatar, Illustration, ProgressRing, QuickLogButton as identity components
- **Consider** shadcn/ui for future complex primitives (Dialog, Select, etc.) when needed
- **Use** existing motion presets from `lib/motion/presets.ts`
