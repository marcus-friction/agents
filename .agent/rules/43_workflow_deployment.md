---
trigger: model_decision
description: Apply when merging branches, promoting code between environments, or performing release/deployment tasks.
---

# Deployment Workflow

## Environments

| Environment | Branch | Trigger | URL Pattern |
|---|---|---|---|
| **Staging** | `staging` | Auto-deploy on merge | `staging.{project}.com` |
| **Production** | `master` | Auto-deploy on merge | `{project}.com` |

Both environments are managed by **Laravel Forge** with auto-deploy enabled.

## Process

### Feature → Staging

1. Complete feature on branch, all CI checks pass.
2. Open PR → `staging`. Human review required.
3. Squash merge into `staging`.
4. Forge auto-deploys to staging.
5. Verify the feature works on staging.

### Staging → Production

1. Open PR from `staging` → `master`.
2. Human review required.
3. Squash merge into `master`.
4. Forge auto-deploys to production.
5. Verify on production.

### Hotfixes

1. Create `hotfix/` branch from `master`.
2. Fix and PR directly to `master` (bypass staging for critical issues).
3. After merge, back-merge `master` into `staging` to keep branches in sync.

## Pre-Merge Checklist

- [ ] All CI checks pass (Larastan, Pint, Pest, ESLint, typecheck, Vitest).
- [ ] Migrations reviewed — `down()` method included.
- [ ] `.env.example` updated if new environment variables were added.
- [ ] No `dd()`, `dump()`, or `console.log()` left in code.
- [ ] Production database backed up before deploying migrations (see `44_workflow_database.md`).

## Rollback Strategy

- **Code rollback:** revert the squash-merge commit on the target branch. Forge auto-deploys the reverted state.
- **Migrations:** never roll back in production. Write a corrective migration instead (see `44_workflow_database.md`).
- **Data issues:** restore from backup using the emergency recovery procedure in `44_workflow_database.md`.
