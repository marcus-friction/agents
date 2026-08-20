# Development Workflow

## Git & PRs
- **Flow:** GitHub Flow (`master`=prod, `staging`=pre-prod). Branches: `feature/*`, `fix/*`, `hotfix/*`.
- **Lifecycle:** Branch `master` → PR `staging` (Squash) → Verify → PR `master` (Squash).
- **Commits:** Imperative mood, ≤72 char subject. No WIP on `staging`/`master`. Delete branches after merge.
- **PR Rules:** Mandatory human review. CI must pass.

## Review Checklist
- Naming conventions, Test coverage, Security, Accessibility, Strict API contracts.

## Tooling & CI
- **Backend:** Larastan Level 9 (`./vendor/bin/phpstan analyse`), Pint (`./vendor/bin/pint`), Pest (`sail test`).
- **Frontend:** `@nuxt/eslint` (`npx eslint .`), TS Check (`npx nuxi typecheck`), Vitest (`npx vitest`).

## DB & Deployment
- **Migrations/Seeders:** Never modify published migrations; additive only. Seeders must be idempotent.
- **Deployment:** Forge handles deploy. No hardcoded ENV configs.
