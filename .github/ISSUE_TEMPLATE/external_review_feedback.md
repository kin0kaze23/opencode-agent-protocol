---
name: External Review Feedback
about: Provide structured feedback as an external reviewer
title: "[REVIEW] "
labels: review-feedback
assignees: ''
---

## Reviewer Environment

- OS: [e.g., Ubuntu 22.04, macOS 14, Windows 11 WSL]
- Git version: [e.g., 2.43.0]
- Bash version: [e.g., 5.2.15]

## Install Result

- [ ] Clone succeeded
- [ ] All validation scripts passed
- [ ] All conformance tests passed
- [ ] No errors encountered

If any check failed, describe:

## Validation Results

- public-surface-scan.sh: [PASS / FAIL]
- validate-docs-drift.sh: [PASS / FAIL]
- validate-config-schema.sh: [PASS / FAIL]
- validate-claims-evidence.sh: [PASS / FAIL]
- protocol-atlas.sh: [PASS / FAIL]
- production-hardening.sh: [PASS / FAIL]
- loop-controller.sh: [PASS / FAIL]
- model-roi.sh: [PASS / FAIL]

## Documentation Clarity

- [ ] README is clear
- [ ] Capability Catalog is understandable
- [ ] Runtime Map is clear
- [ ] Configuration Guide is actionable
- [ ] Protocol Atlas is helpful

Which docs were confusing?

## Missing Capabilities

Are there capabilities you expected but did not find?

## Safety Concerns

Any safety gaps or concerns?

## Suggested Improvements

What would make this protocol more useful or trustworthy?

## Overall Confidence

- [ ] High — I would use this in production
- [ ] Medium — Promising but needs more evidence
- [ ] Low — Not ready for production use
- [ ] Insufficient — Needs significant work

## Additional Comments

Any other feedback?
