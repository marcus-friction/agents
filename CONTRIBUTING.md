# Development & Contribution Workflow

This document outlines the operational workflows for contributing to projects in this ecosystem.

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
- **CI Checks:** All quality tooling (Larastan level 9, Pint, @nuxt/eslint, typecheck, Vitest, Pest) must pass before merging.

## Review Checklist
- Check naming conventions.
- Ensure new code has test coverage.
- Verify security implications.
- Ensure accessibility basics are met.
- Ensure implementation details do not leak into API contracts.

## Testing & Quality Tooling
- **Backend:** 
  - Larastan for static analysis (Target level 9). Run: `./vendor/bin/phpstan analyse`
  - Laravel Pint for formatting. Run: `./vendor/bin/pint`
  - Pest for testing (use `it()` syntax). Run: `sail test`
- **Frontend:**
  - `@nuxt/eslint` for linting. Run: `npx eslint .`
  - TypeScript verification. Run: `npx nuxi typecheck`
  - Vitest for component/unit tests. Run: `npx vitest`

## Deployment & Database Operations
- **Migrations:** Never modify published migrations. Create new migrations for additive changes. Write `down()` methods carefully.
- **Seeders:** Must be idempotent.
- **Deployment:** Handled via Laravel Forge on staging and production environments. Do not hardcode environment-specific configurations.
