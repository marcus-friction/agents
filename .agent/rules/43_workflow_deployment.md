---
trigger: model_decision
description: Apply when merging branches, promoting code between environments, or performing release/deployment tasks.
---

# Deployment Workflow

## Environments (Auto-Deployed via Laravel Forge)
- **Staging:** `staging` branch. `staging.{project}.com`
- **Production:** `master` branch. `{project}.com`

## Process
1. **Feature → Staging:** PR to `staging` (Human Review) → Squash Merge → Auto-Deploy → Verify.
2. **Staging → Production:** PR `staging` to `master` (Human Review) → Squash Merge → Auto-Deploy → Verify.
3. **Hotfixes:** Branch from `master` → PR to `master` (bypass staging) → Squash Merge. *Must back-merge `master` into `staging` afterwards.*

## Pre-Merge Checklist
- All CI checks passing (Backend + Frontend).
- Migrations reviewed (ensure `down()` exists).
- `.env.example` updated with any new keys.
- No `dd()`, `dump()`, or `console.log()` leftovers.
- Production DB backed up before running migrations (see `44_workflow_database`).

## Rollback Strategy
- **Code:** Revert the squash-merge commit on target branch (Forge auto-deploys).
- **Migrations:** **Never roll back in production.** Write a new corrective migration instead.
- **Data Loss:** Restore from backup via emergency recovery procedures (`44_workflow_database`).
