---
trigger: model_decision
description: Apply when creating branches, opening PRs, committing code, or discussing Git workflow.
---

# Development Workflow

## Branching & Flow
- **Model:** GitHub Flow. `master` = production, `staging` = pre-production.
- **Naming:** `feature/*`, `fix/*`, `hotfix/*`.
- **Lifecycle:** 
  1. Branch from `master`.
  2. Open PR to `staging`.
  3. CI Passes + Human Review → Squash Merge.
  4. Auto-deploy and verify on `staging`.
  5. Open PR `staging` → `master` → Squash Merge → Auto-deploy production.
- **Cleanup:** Delete feature branch after merge. No WIP commits on `staging`/`master`.
- **Commits:** Imperative mood ("Add feature"), ≤72 char subject, optional body separated by blank line.

## PRs & CI Requirements
- **Rules:** Human review is mandatory (no self-mergers). Squash merges only.
- **CI Checks:** All checks from `.agents/rules/20_stack.md` Quality Tooling must pass before merging.

## Review Checklist
- Check naming conventions (`.agents/rules/21_standards_laravel.md`, `.agents/rules/22_standards_nuxt.md`).
- Ensure new code has test coverage (`.agents/rules/41_workflow_testing.md`).
- Verify security implications (`.agents/rules/50_security.md`).
- Ensure accessibility basics are met (`.agents/rules/24_accessibility.md`).
- Ensure implementation details do not leak into API contracts.

*Optional:* Use a pre-push hook for local checks (`pint --test && phpstan analyse`).