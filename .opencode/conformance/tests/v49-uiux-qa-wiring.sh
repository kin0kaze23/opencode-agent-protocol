#!/bin/bash
# v4.9.0 UI/UX QA Wiring Conformance Tests
# Verifies that v4.9 UI/UX QA skills are correctly wired into the OpenCode workflow
# Runs in < 60 seconds, checks command/rule file content for required references

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
RESULTS_DIR="$SCRIPT_DIR/../results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_FILE="$RESULTS_DIR/v49-uiux-qa-wiring-${TIMESTAMP}.md"

# Source assertion helpers
source "$SCRIPT_DIR/../assert.sh"

PLAN="$ROOT_DIR/.opencode/commands/plan-feature.md"
IMPLEMENT="$ROOT_DIR/.opencode/commands/implement.md"
REVIEW="$ROOT_DIR/.opencode/commands/review.md"
GATES="$ROOT_DIR/.opencode/commands/gates.md"
SHIP="$ROOT_DIR/.opencode/commands/ship.md"
UI_WORK="$ROOT_DIR/.opencode/rules/ui-work.md"

echo "=========================================="
echo "Protocol Conformance Suite - v4.9 UI/UX QA Wiring Tests"
echo "=========================================="
echo "Started: $(date -Iseconds)"
echo "Root: $ROOT_DIR"
echo ""

reset_counters

# ============================================================
# V49-001: Design Intelligence Brief trigger in plan-feature
# ============================================================
test_start "V49-001" "Design Intelligence Brief trigger in /plan-feature"
assert_file_contains "$PLAN" "Design Intelligence Brief" "Plan references Design Intelligence Brief"
assert_file_contains "$PLAN" "net-new UI" "Brief triggers for net-new UI"
assert_file_contains "$PLAN" "landing page" "Brief triggers for landing pages"
assert_file_contains "$PLAN" "dashboard" "Brief triggers for dashboards"
assert_file_contains "$PLAN" "onboarding" "Brief triggers for onboarding flows"
assert_file_contains "$PLAN" "principles.*not imitation\|not imitation" "References as principles, not imitation"
assert_file_contains "$PLAN" "Apple HIG" "Apple HIG reference guidance"
assert_file_contains "$PLAN" "Material 3" "Material 3 reference guidance"
assert_file_contains "$PLAN" "WCAG 2.2" "WCAG 2.2 reference guidance"
assert_file_contains "$PLAN" "NN/g" "NN/g reference guidance"
assert_file_contains "$PLAN" "Do not copy competitor UI\|competitor UI" "Do not copy competitor UI guardrail"
assert_file_contains "$PLAN" "clarity, hierarchy" "Extract principles: clarity, hierarchy"

# ============================================================
# V49-002: Implement UI/UX evidence flow
# ============================================================
test_start "V49-002" "Implement UI/UX evidence flow in /implement"
assert_file_contains "$IMPLEMENT" "ui-ux-quality-audit" "References ui-ux-quality-audit skill"
assert_file_contains "$IMPLEMENT" "accessibility-audit" "References accessibility-audit skill"
assert_file_contains "$IMPLEMENT" "responsive-state-audit" "References responsive-state-audit skill"
assert_file_contains "$IMPLEMENT" "visual-regression" "References visual-regression skill"
assert_file_contains "$IMPLEMENT" "Lighthouse.*advisory\|advisory.*v4.9" "Lighthouse is advisory"
assert_file_contains "$IMPLEMENT" "375×667" "Viewport 375×667"
assert_file_contains "$IMPLEMENT" "414×896" "Viewport 414×896"
assert_file_contains "$IMPLEMENT" "768×1024" "Viewport 768×1024"
assert_file_contains "$IMPLEMENT" "1024×768" "Viewport 1024×768"
assert_file_contains "$IMPLEMENT" "1440×900" "Viewport 1440×900"
assert_file_contains "$IMPLEMENT" "1920×1080" "Viewport 1920×1080"
assert_file_contains "$IMPLEMENT" "NOT_RUN" "NOT_RUN rules present"
assert_file_contains "$IMPLEMENT" "NOT_RUN with reason" "NOT_RUN with reason pattern"
assert_file_contains "$IMPLEMENT" "stop and return to plan correction\|Critical.*stop\|stop and return" "Critical findings stop completion"

# ============================================================
# V49-003: Review UI/UX track
# ============================================================
test_start "V49-003" "Review UI/UX review track in /review"
assert_file_contains "$REVIEW" "Design Intelligence Brief\|design-brief" "Review reads Design Intelligence Brief"
assert_file_contains "$REVIEW" "UI/UX Quality Audit" "Review reads UI/UX Quality Audit report"
assert_file_contains "$REVIEW" "Accessibility Audit" "Review reads Accessibility Audit report"
assert_file_contains "$REVIEW" "Responsive/State Audit\|Responsive.*Audit" "Review reads Responsive/State Audit"
assert_file_contains "$REVIEW" "Visual Regression" "Review reads Visual Regression evidence"
assert_file_contains "$REVIEW" "clarity" "Expert-grade UI: clarity"
assert_file_contains "$REVIEW" "hierarchy" "Expert-grade UI: hierarchy"
assert_file_contains "$REVIEW" "consistency" "Expert-grade UI: consistency"
assert_file_contains "$REVIEW" "accessibility" "Expert-grade UI: accessibility"
assert_file_contains "$REVIEW" "responsiveness" "Expert-grade UI: responsiveness"
assert_file_contains "$REVIEW" "brand fit" "Expert-grade UI: brand fit"
assert_file_contains "$REVIEW" "anti-generic" "Expert-grade UI: anti-generic quality"
assert_file_contains "$REVIEW" "delight" "Expert-grade UI: tasteful delight"
assert_file_contains "$REVIEW" "production readiness" "Expert-grade UI: production readiness"
assert_file_contains "$REVIEW" "usefulness.*beauty\|beauty alone\|not decorative" "Usefulness, not decorative beauty alone"
assert_file_contains "$REVIEW" "legibility.*reading\|clear communication\|visual polish.*mask" "Legibility and clear communication standard"

# ============================================================
# V49-004: Gates UI surface profile
# ============================================================
test_start "V49-004" "Gates UI surface profile extension in /gates"
assert_file_contains "$GATES" "UI/UX Quality Audit" "Gates include UI/UX Quality Audit"
assert_file_contains "$GATES" "Accessibility Audit" "Gates include Accessibility Audit"
assert_file_contains "$GATES" "Responsive/State Audit\|Responsive.*State" "Gates include Responsive/State Audit"
assert_file_contains "$GATES" "Visual Regression" "Gates include Visual Regression"
assert_file_contains "$GATES" "Lighthouse.*advisory\|advisory.*v4.9" "Lighthouse is advisory in gates"
assert_file_contains "$GATES" "browser verification" "Gates include browser verification"
assert_file_contains "$GATES" "targeted UI smoke" "Gates include targeted UI smoke"
assert_file_contains "$GATES" "Critical UI/UX.*BLOCK\|Critical.*BLOCK\|BLOCK" "Critical UI/UX findings block"
assert_file_contains "$GATES" "Critical/High accessibility.*BLOCK\|Critical/High.*BLOCK\|High.*BLOCK" "Critical/High accessibility findings block"
assert_file_contains "$GATES" "responsive breakage.*BLOCK\|Responsive breakage.*BLOCK\|breakage.*BLOCK" "Responsive breakage blocks"
assert_file_contains "$GATES" "NOT_RUN.*pass with warning\|pass with warning\|NOT_RUN rules" "NOT_RUN rules present"
assert_file_contains "$GATES" "advisory only in v4.9.0\|Lighthouse.*ADVISORY\|ADVISORY.*v4.9" "Lighthouse advisory confirmed"

# ============================================================
# V49-005: Ship UI/UX quality gate
# ============================================================
test_start "V49-005" "Ship UI/UX quality gate in /ship"
assert_file_contains "$SHIP" "UI/UX Quality Gate\|UI/UX quality gate" "Ship has UI/UX Quality Gate"
assert_file_contains "$SHIP" "Critical UI/UX Quality Audit" "Ship blocks Critical UI/UX findings"
assert_file_contains "$SHIP" "Critical/High Accessibility Audit\|Critical/High Accessibility\|Critical/High.*accessibility" "Ship blocks Critical/High accessibility findings"
assert_file_contains "$SHIP" "responsive breakage" "Ship blocks responsive breakage"
assert_file_contains "$SHIP" "visual regression" "Ship blocks visual regression issues"
assert_file_contains "$SHIP" "console errors on UI" "Ship blocks console errors on UI surfaces"
assert_file_contains "$SHIP" "block ship\|block.*report" "Ship blocks on critical findings"

# ============================================================
# V49-006: UI work rules reference v4.9 skills
# ============================================================
test_start "V49-006" "UI work rules reference v4.9 skills"
assert_file_contains "$UI_WORK" "ui-ux-quality-audit" "ui-work references ui-ux-quality-audit"
assert_file_contains "$UI_WORK" "accessibility-audit" "ui-work references accessibility-audit"
assert_file_contains "$UI_WORK" "responsive-state-audit" "ui-work references responsive-state-audit"
assert_file_contains "$UI_WORK" "visual-regression" "ui-work references visual-regression"
assert_file_contains "$UI_WORK" "Lighthouse.*advisory\|performance.*Lighthouse\|advisory" "ui-work references Lighthouse advisory"
assert_file_contains "$UI_WORK" "design-system-governance\|design-system" "ui-work references design-system-governance"

# ============================================================
# V49-007: Safety — no auto-install directives
# ============================================================
test_start "V49-007" "Safety — no auto-install directives"
assert_file_not_contains "$PLAN" "npm install.*axe\|npm install.*axe-core\|pnpm install.*axe\|install.*axe-core\|install.*lighthouse" "Plan does not auto-install axe-core or Lighthouse"
assert_file_not_contains "$IMPLEMENT" "npm install.*axe\|npm install.*axe-core\|pnpm install.*axe\|install.*axe-core\|install.*lighthouse" "Implement does not auto-install dependencies"
assert_file_not_contains "$GATES" "npm install.*axe\|npm install.*axe-core\|pnpm install.*axe\|install.*axe-core\|install.*lighthouse" "Gates does not auto-install dependencies"
assert_file_not_contains "$SHIP" "npm install.*axe\|npm install.*axe-core\|pnpm install.*axe\|install.*axe-core\|install.*lighthouse" "Ship does not auto-install dependencies"
assert_file_not_contains "$REVIEW" "npm install.*axe\|npm install.*axe-core\|pnpm install.*axe\|install.*axe-core\|install.*lighthouse" "Review does not auto-install dependencies"

# ============================================================
# V49-008: Safety — no automatic baseline commit directives
# ============================================================
test_start "V49-008" "Safety — no automatic baseline commit directives"
assert_file_not_contains "$IMPLEMENT" "commit baseline without\|automatically commit.*baseline\|auto-commit.*baseline" "Implement does not auto-commit baselines"
assert_file_not_contains "$GATES" "commit baseline\|auto-commit.*baseline" "Gates does not auto-commit baselines"
assert_file_not_contains "$REVIEW" "commit baseline\|auto-commit.*baseline" "Review does not auto-commit baselines"
assert_file_not_contains "$SHIP" "commit baseline\|auto-commit.*baseline" "Ship does not auto-commit baselines"

# ============================================================
# V49-009: Safety — GPT-5.5 remains manual/external only
# ============================================================
test_start "V49-009" "Safety — GPT-5.5 remains manual/external only"
assert_file_contains "$ROOT_DIR/.opencode/helper-roster.md" "GPT-5.5 is external/manual escalation only\|external/manual escalation only" "GPT-5.5 is external/manual only"
assert_file_not_contains "$PLAN" "GPT-5.5\|gpt-5.5" "Plan does not reference GPT-5.5 as auto-routed"
assert_file_not_contains "$IMPLEMENT" "GPT-5.5\|gpt-5.5" "Implement does not reference GPT-5.5 as auto-routed"

# ============================================================
# V49-010: Safety — qwen3-coder-plus remains reviewer-gated
# ============================================================
test_start "V49-010" "Safety — qwen3-coder-plus remains reviewer-gated"
assert_file_contains "$ROOT_DIR/.opencode/helper-roster.md" "reviewer-gated\|Reviewer-gated" "Helper roster confirms reviewer-gated"
assert_file_contains "$ROOT_DIR/.opencode/agents/implementer.md" "reviewer-gated\|Reviewer-gated" "Implementer agent confirms reviewer-gated"

# ============================================================
# V49-011: NOT_RUN terminology consistency
# ============================================================
test_start "V49-011" "NOT_RUN terminology consistency"
assert_file_not_contains "$PLAN" "NOT_RULES\|NOTRULES\|NOT RULES\|NOT_RUN_RULES" "Plan uses NOT_RUN consistently"
assert_file_not_contains "$IMPLEMENT" "NOT_RULES\|NOTRULES\|NOT RULES" "Implement uses NOT_RUN consistently"
assert_file_not_contains "$GATES" "NOT_RULES\|NOTRULES\|NOT RULES" "Gates uses NOT_RUN consistently"
assert_file_not_contains "$REVIEW" "NOT_RULES\|NOTRULES\|NOT RULES" "Review uses NOT_RUN consistently"
assert_file_not_contains "$SHIP" "NOT_RULES\|NOTRULES\|NOT RULES" "Ship uses NOT_RUN consistently"
assert_file_not_contains "$UI_WORK" "NOT_RULES\|NOTRULES\|NOT RULES" "ui-work uses NOT_RUN consistently"

# ============================================================
# V49.1-001: Design research wired into /plan-feature
# ============================================================
test_start "V49.1-001" "Design research wired into /plan-feature"
assert_file_contains "$PLAN" "design-research/SKILL.md" "Plan references design-research skill"
assert_file_contains "$PLAN" "Design Research.*v4.9.1\|v4.9.1.*Design Research\|Design Research.*v4" "Plan has v4.9.1 design research step"
assert_file_contains "$PLAN" "product context" "Design research requires product context"
assert_file_contains "$PLAN" "emotional state\|user emotional" "Design research requires user emotional state"
assert_file_contains "$PLAN" "brand adjectives\|brand adjective" "Design research requires brand adjectives"
assert_file_contains "$PLAN" "competitor.*audit\|adjacent.*audit" "Design research requires competitor audit"
assert_file_contains "$PLAN" "anti-pattern" "Design research requires anti-pattern audit"
assert_file_contains "$PLAN" "mood board.*token\|token translation" "Design research requires mood board to token translation"
assert_file_contains "$PLAN" "selected.*direction\|design direction" "Design research requires selected direction"
assert_file_contains "$PLAN" "rejected.*direction\|rejected direction" "Design research requires rejected directions"
assert_file_contains "$PLAN" "rationale.*aesthetic\|aesthetic.*rationale\|rationale" "Design research requires rationale for choices"
assert_file_contains "$PLAN" "principles.*not imitation\|not imitation" "Design research uses principles, not imitation"

# ============================================================
# V49.1-002: Motion design wired into /implement
# ============================================================
test_start "V49.1-002" "Motion design wired into /implement"
assert_file_contains "$IMPLEMENT" "motion-design/SKILL.md" "Implement references motion-design skill"
assert_file_contains "$IMPLEMENT" "Motion Design.*v4.9.1\|v4.9.1.*Motion Design\|Motion Design.*v4" "Implement has v4.9.1 motion design step"
assert_file_contains "$IMPLEMENT" "timing.*easing\|easing.*rationale\|timing/easing" "Motion design requires timing/easing rationale"
assert_file_contains "$IMPLEMENT" "reduced-motion\|prefers-reduced-motion" "Motion design requires reduced-motion handling"
assert_file_contains "$IMPLEMENT" "when not to animate\|clarity.*decoration\|support clarity" "Motion design checks when not to animate"
assert_file_contains "$IMPLEMENT" "choreography\|parent before child\|staggered\|focus-first" "Motion design checks choreography"

# ============================================================
# V49.1-003: v4.9.1 review checks in /review
# ============================================================
test_start "V49.1-003" "v4.9.1 review checks in /review"
assert_file_contains "$REVIEW" "design-research\|design research" "Review checks design-research methodology"
assert_file_contains "$REVIEW" "generic default\|project-specific\|aesthetic choices" "Review checks project-specific aesthetics"
assert_file_contains "$REVIEW" "motion.*purposeful\|purposeful.*motion\|purposeful" "Review checks motion purposefulness"
assert_file_contains "$REVIEW" "timing.*easing\|choreography" "Review checks timing/easing/choreography"
assert_file_contains "$REVIEW" "reduced.*motion\|prefers-reduced-motion" "Review checks reduced-motion"
assert_file_contains "$REVIEW" "pixel.*perfect\|optical balance\|visual polish\|rhythm" "Review checks pixel-perfect polish"

# ============================================================
# V49.1-004: Motion accessibility blockers in /gates and /ship
# ============================================================
test_start "V49.1-004" "Motion accessibility blockers in /gates and /ship"
assert_file_contains "$GATES" "motion.*harms accessibility\|harms accessibility\|motion.*accessibility" "Gates block accessibility-harming motion"
assert_file_contains "$GATES" "design.*direction mismatch\|contradicts approved\|contradicts.*brief" "Gates block design-research mismatch"
assert_file_contains "$GATES" "reduced-motion\|prefers-reduced-motion" "Gates check reduced-motion"
assert_file_contains "$GATES" "visual polish.*fail\|polish failure\|Major visual polish" "Gates block major visual polish failures"
assert_file_contains "$SHIP" "design direction mismatch\|contradicts.*brief\|design.*mismatch" "Ship blocks design direction mismatch"
assert_file_contains "$SHIP" "motion.*accessibility\|harming motion\|accessibility-harming\|harms accessibility" "Ship blocks accessibility-harming motion"
assert_file_contains "$SHIP" "motion.*comprehension\|only conveyed through motion\|motion-only" "Ship blocks motion-only comprehension"

# ============================================================
# V49.2-001: Platform guidelines in /plan-feature, /implement, /review, /gates, /ship
# ============================================================
test_start "V49.2-001" "Platform guidelines compliance wired into commands"
assert_file_contains "$PLAN" "platform-guidelines-compliance/SKILL.md" "Plan references platform-guidelines-compliance"
assert_file_contains "$PLAN" "safe area\|notch\|home indicator\|touch target" "Plan requires safe area / touch target checks"
assert_file_contains "$IMPLEMENT" "platform-guidelines-compliance/SKILL.md" "Implement references platform-guidelines-compliance"
assert_file_contains "$IMPLEMENT" "safe area\|safe-area\|safe_areas\|touch target\|Touch target" "Implement checks safe areas / touch targets"
assert_file_contains "$GATES" "safe-area.*violation.*BLOCK\|Safe-area violation.*BLOCK\|safe-area violation" "Gates block safe-area violations"
assert_file_contains "$GATES" "touch-target.*BLOCK\|touch-target violation" "Gates block touch-target violations"
assert_file_contains "$SHIP" "safe-area\|safe.area\|touch-target\|touch.*target\|platform compliance" "Ship blocks safe-area / touch-target violations"

# ============================================================
# V49.2-002: Illustration/graphic direction in /plan-feature, /implement, /review, /gates, /ship
# ============================================================
test_start "V49.2-002" "Illustration/graphic direction wired into commands"
assert_file_contains "$PLAN" "illustration-graphic-direction/SKILL.md" "Plan references illustration-graphic-direction"
assert_file_contains "$PLAN" "visual metaphor\|iconography\|brand motif\|empty-state" "Plan requires visual metaphor / iconography / motif"
assert_file_contains "$IMPLEMENT" "illustration-graphic-direction/SKILL.md" "Implement references illustration-graphic-direction"
assert_file_contains "$IMPLEMENT" "generic AI\|no.*commit.*image\|Do NOT generate" "Implement avoids generic AI graphics, no auto-commit images"
assert_file_contains "$GATES" "generic.*graphic\|cliché.*graphic\|graphic.*inconsisten\|illustration.*inconsisten" "Gates block generic/cliché graphics"
assert_file_contains "$SHIP" "graphic.*mismatch\|illustration.*mismatch\|graphic.*inconsisten" "Ship blocks graphic/illustration mismatch"

# ============================================================
# V49.2-003: Visual iteration loop in /implement, /review, /gates, /ship
# ============================================================
test_start "V49.2-003" "Visual iteration loop wired into commands"
assert_file_contains "$IMPLEMENT" "visual-iteration-loop/SKILL.md" "Implement references visual-iteration-loop"
assert_file_contains "$IMPLEMENT" "before.*after\|top 5.*top 3\|max 2\|2 iteration\|critique" "Implement requires before/after critique loop"
assert_file_contains "$REVIEW" "before.*after\|visual iteration\|iteration.*evidence\|aesthetic.*usability" "Review checks visual iteration evidence"
assert_file_contains "$GATES" "visual iteration.*BLOCK\|Missing visual iteration" "Gates block missing visual iteration evidence"
assert_file_contains "$GATES" "aesthetic.*harm\|harms usability\|polish.*harm\|harms.*usability" "Gates block aesthetic polish that harms usability"
assert_file_contains "$SHIP" "visual iteration.*evidence\|missing.*iteration\|iteration.*evidence" "Ship blocks missing visual iteration evidence"
assert_file_contains "$SHIP" "reduce.*usability\|usability.*reduce\|reduce usability\|harmed.*aesthetic" "Ship blocks visual changes that reduce usability"

# ============================================================
# V49.2-004: Safety — no auto-generate/commit images
# ============================================================
test_start "V49.2-004" "Safety — no auto-generate/commit images"
assert_file_not_contains "$IMPLEMENT" "generate.*image.*default\|auto.*generate.*image\|commit.*image.*default\|auto.*commit.*image" "Implement does not auto-generate or commit images"
assert_file_not_contains "$PLAN" "generate.*image.*default\|auto.*generate.*image" "Plan does not auto-generate images"

# ============================================================
# V49.2-005: Runtime Styling Integrity in verification-before-completion
# ============================================================
VERIFY_SKILL="$ROOT_DIR/.opencode/skills/verification-before-completion/SKILL.md"
test_start "V49.2-005" "Runtime Styling Integrity guardrail in verification skill"
assert_file_contains "$VERIFY_SKILL" "Runtime Styling Integrity" "Verification skill includes Runtime Styling Integrity section"
assert_file_contains "$VERIFY_SKILL" "all materially affected render states" "Requires all materially affected render states"
assert_file_contains "$VERIFY_SKILL" "Unauthenticated.*onboarding\|onboarding.*Unauthenticated" "Requires unauthenticated/onboarding state verification"
assert_file_contains "$VERIFY_SKILL" "Authenticated.*main app\|main app.*Authenticated" "Requires authenticated/main app state verification"
assert_file_contains "$VERIFY_SKILL" "CSS files are loaded\|CSS.*loaded" "Requires CSS files loaded check"
assert_file_contains "$VERIFY_SKILL" "computed styles\|non-default computed" "Requires computed styles check"
assert_file_contains "$VERIFY_SKILL" "browser-default HTML\|browser default" "Blocks browser-default HTML rendering"
assert_file_contains "$VERIFY_SKILL" "User screenshot contradiction\|user.*screenshot.*contradiction\|contradiction.*user" "User screenshot contradiction blocks completion"
assert_file_contains "$VERIFY_SKILL" "state seeding\|localStorage.*seeded\|seeded.*localStorage" "Requires reporting state seeding used"
assert_file_contains "$VERIFY_SKILL" "Runtime Styling Integrity" "Runtime Styling Integrity evidence table present"

# ============================================================
# Write results
# ============================================================
report_results "$RESULT_FILE" "v4.9.0 UI/UX QA Wiring Tests"

echo ""
echo "Results written to: $RESULT_FILE"
echo "Finished: $(date -Iseconds)"
