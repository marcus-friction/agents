# 2026-03-25 — Skill Professionalization (v1.2.0)

## Summary
Audited and professionalized 9 agentic skills against the `skill-creator` quality framework. Introduced `references/` architecture for progressive disclosure, added structured output templates, and reduced total SKILL.md lines by 32%.

## Changes

### Skills — New (migrated from workflows)
- `adversarial-review` — Red Team review with structured output template and `references/what-if-matrix.md`
- `compound` — Solution documentation with extracted template in `references/solution-template.md`
- `copy-editing` — Seven Sweeps copy review with checklist, common problems, and output template
- `copywriting` — Marketing/UI copy principles with context-gathering fallback
- `design-consultation` — Design system builder with `references/font-pairings.md` and `references/color-theory.md`
- `office-hours` — YC Office Hours with `references/pushback-patterns.md` and `references/design-doc-templates.md`
- `review-gstack` — Pre-landing Mega Review with verdict output template
- `skill-creator` — Skill creation, testing, and description optimization

### Skills — Modified
- `review-plan` — Added pushy description, checklist anchors, Review Verdict output template
- `seo-review` — Framework-agnostic checks with *why* explanations, output summary, and `references/schema-templates.md`

### Skills — Removed
- `heal-skill` — Removed (redundant with `systematic-debugging`)
- `research-solutions` — Removed (superseded by `compound`)

### Workflows — Modified
- `wrap.md` — Added squash-merge step for feature branches
- `plan.md` — Updated skill references
- `project.md` — Streamlined interactive onboarding
- `design-system.md` — Updated to reference `design-consultation` skill

### Workflows — Removed
- `compound.md` — Migrated to skill
- `lfg.md` — Removed (unused)

### Other
- `README.md` — Updated skills table, added v1.2.0 release entry
- `10_project.md` — Minor project context updates
- `23_design_system.md` — Minor design system updates

## Notes
- All SKILL.md files now under 350 lines (target was <500)
- 10 `references/` files created across skills for progressive disclosure
- Average skill quality score: 9.2/10 against skill-creator dimensions
- Remaining path-to-10 items are micro-polish (tool name generalization, inline examples)
