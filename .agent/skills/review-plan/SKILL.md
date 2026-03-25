---
name: review-plan
description: Meta-level guidance for reviewing and challenging implementation plans
---

# Review Plan Skill

Use this skill during the `/plan` workflow to brutally evaluate your drafted implementation plan before finalizing it. The goal is to catch architectural flaws, scope gaps, and edge cases early.

## Evaluation Perspectives

Put on different hats to evaluate the plan. If the draft fails under any lens, it must be revised.

### 1. Vision & Goals Perspective
- **Alignment:** How does this implementation specifically advance the project's core vision and goals? 
- **Critical Challenge:** Is this feature actually necessary right now? Does it solve a real problem or is it a distraction?
- **References:** `10_project.md` rule.

### 2. Architecture Perspective
- **Simplicity:** Is there a simpler way to achieve the exact same business goal? Are we over-engineering?
- **Impact Radius:** What existing systems will this break? Are interconnected components updated?
- **Data Integrity:** Are migrations, rollbacks, and large-scale data cleanup steps explicitly planned?
- **References:** `architecture-review` skill.

### 3. Engineering & Scope Perspective
- **No Deferrals:** Does the plan tackle the project **as a whole**? Projects must be phased, not deferred (no "we will do this later").
- **Knowledge Re-use:** Does the implementation leverage established patterns from the codebase and compounded learnings in Knowledge Items (KIs)?
- **References:** `21_standards_laravel.md`, `22_standards_nuxt.md`.

### 4. Performance Perspective
- **Scalability:** Will this survive a traffic spike? Are there N+1 query risks or large payload hazards?
- **Caching:** Are caching layers (Redis/CDN) considered where appropriate?
- **References:** `25_caching_performance.md` rule, `performance-review` skill.

### 5. Security Perspective
- **Protection:** Are authorization (Policies), authentication, and strict input validation meticulously mapped out?
- **References:** `50_security.md` rule, `security-review` skill.

### 6. Design & UI Perspective (If Frontend)
- **Aesthetics:** Does the plan leverage the existing design system tokens rather than ad-hoc framing?
- **Accessibility:** Are loading, error, and empty states defined?
- **References:** `23_design_system.md`, `24_accessibility.md`, `ui-accessibility-review` skill.

### 7. QA & Verification Perspective
- **Edge Cases:** Does the plan account for sad paths, race conditions, and bizarre inputs?
- **Concrete Verification:** Are the testing and manual verification steps specific and actionable? (e.g., write "Add `it('handles X')` to `OrderTest`" instead of "Test the feature").
- **References:** `41_workflow_testing.md` rule, `test-driven-development` skill.

## Action
For each evaluation iteration, execute the following:

1. **Individual Ratings:** Rate the current draft brutally and honestly from **1 to 10** for *each individual perspective* (Vision, Architecture, Engineering, Performance, Security, Design, QA).
2. **Path to 10:** For any perspective rated below a 10, explicitly state exactly what must be changed, added, or removed to get that specific dimension to a perfect 10.
3. **Revise:** Go back and heavily revise the implementation plan to execute the "Path to 10" recommendations. Do not be gentle with your own draft.
