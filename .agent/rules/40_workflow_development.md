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
- **Cleanup:** Delete feature branch after merge. No WIP commits on `staging`/`master`. Write imperative commit messages ("Add feature").

## PRs & CI Requirements
- **Rules:** Human review is mandatory (no self-mergers). Squash merges only.
- **Backend CI:** `phpstan analyse` (Level 9), `pint --test`, `sail test`.
- **Frontend CI:** `eslint .`, `nuxi typecheck`, `vitest run`.
- All checks must pass before merging.

## Review Checklist
- Check naming conventions (`21_standards_laravel`, `22_standards_nuxt`).
- Ensure new code has test coverage.
- Verify security implications (`50_security`).
- Ensure accessibility basics are met (`24_accessibility`).
- Ensure implementation details do not leak into API contracts.

*Optional:* Use a pre-push hook for local checks (`pint --test && phpstan analyse`).