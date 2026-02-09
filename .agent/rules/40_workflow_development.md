---
trigger: model_decision
description: Apply when creating branches, opening PRs, committing code, or discussing Git workflow.
---

# Development Workflow

## Branching

- **Model**: GitHub Flow with a `staging` branch.
- **Default branch**: `master` (production).
- **Staging branch**: `staging` (pre-production verification).

### Branch Naming

```
feature/short-description
fix/short-description
hotfix/short-description
```

### Flow

1. Create feature branch from `master`.
2. Develop and commit.
3. Open PR targeting `staging`.
4. CI checks must pass + human reviewer approves.
5. Squash merge into `staging` → auto-deploys to staging environment.
6. Verify on staging.
7. Open PR from `staging` → `master`.
8. Squash merge into `master` → auto-deploys to production.

## Pull Requests

- **Human review required** on every PR — no self-merges.
- **Squash merge only** — one clean commit per PR on the target branch.
- PR title becomes the squash commit message — make it descriptive.
- Delete feature branches after merge.

### Required CI Checks

**Backend:**
1. `./vendor/bin/phpstan analyse` (Larastan)
2. `./vendor/bin/pint --test` (formatting check)
3. `sail test` (Pest)

**Frontend (from `frontend/`):**
1. `npx eslint .`
2. `npx nuxi typecheck`
3. `npx vitest run`

All checks must pass before merge is allowed.

## Commits

- Write clear, imperative commit messages: "Add order export", not "Added order export".
- No WIP commits on `master` or `staging` — squash handles cleanup.
- Reference issue/ticket numbers where applicable.

### Review Checklist

Reviewers should verify beyond CI green:

- [ ] Naming follows conventions (`21_standards_laravel.md`, `22_standards_nuxt.md`).
- [ ] New code has test coverage — or a clear reason why not.
- [ ] Security-sensitive areas flagged (see `50_security.md` Code Review).
- [ ] No leaking of implementation details into the API contract.
- [ ] Accessibility basics met for UI changes (`24_accessibility.md`).

## Git Hooks (Recommended)

Use a pre-push hook to run local checks before code reaches CI:

```bash
# .git/hooks/pre-push
./vendor/bin/pint --test && ./vendor/bin/phpstan analyse
```

Optional but strongly recommended. Not enforced in CI — CI catches anything missed.