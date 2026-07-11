# UI Pattern Library

> Proven, production-verified UI patterns extracted from real implementation work.
> Future agents can reuse these patterns across projects without needing new skills.

## How to Use

1. **Browse patterns** — Each `.md` file documents a single UI pattern.
2. **Check applicability** — Each pattern includes "When to use" and "When not to use" sections.
3. **Follow acceptance criteria** — Each pattern has a checklist for verification.
4. **Reference proven examples** — Patterns link to real commits where they were implemented and verified.

## Pattern Index

| Pattern | Status | Source |
|---------|--------|--------|
| [Premium Mobile Navigation](./premium-mobile-navigation.md) | ✅ Proven | demo-project `8c2ed9d` |
| [Visual Asset Generation](./visual-asset-generation.md) | ✅ Documented | Built on v4.9.2 skills |

## Candidate Patterns (Not Yet Documented)

These patterns are identified as high-value candidates for future documentation:

| Pattern | Priority | Notes |
|---------|----------|-------|
| Hero / Welcome Screen | Medium | First-impression screen with brand identity |
| Onboarding Stepper | Medium | Multi-step user profile collection |
| Empty State | Medium | Calm, encouraging zero-data screens |
| Card System | Medium | Consistent content containers |
| Bottom Sheet / Action Sheet | Medium | Contextual action overlays |
| Search / Command Bar | Low | Quick navigation and discovery |
| Form Flow | Low | Accessible, validated input sequences |
| Loading / Skeleton State | Low | Perceived performance during async ops |
| Error / Recovery State | Low | Graceful failure with clear recovery paths |
| AI Chat Panel | Low | Conversational interface with message threading |

## Adding New Patterns

When a pattern is proven through implementation and verification:

1. Create `<pattern-name>.md` in this directory.
2. Follow the template structure from existing patterns.
3. Link to the proving commit and verification results.
4. Update this index.
