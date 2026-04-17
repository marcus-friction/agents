---
trigger: model_decision
description: Apply when running migrations, writing seeders, performing database backups, or any destructive database operation.
---

# Database Operations

## Mandatory Backups
**Every destructive or structural DB operation requires a verified backup.** (Includes `migrate`, `fresh`, `rollback`, `db:seed`, manual schema/data changes). Read-only queries do not.

1. **Dump:** Create a timestamped `pg_dump` backup to `database/backups/`. Example: `sail exec pgsql pg_dump -U sail {database} > database/backups/backup_$(date +%Y%m%d_%H%M%S).sql`
2. **Verify:** Check file size is non-zero.
3. **Commit Rule:** Never commit backups (`database/backups/*.sql` must be in `.gitignore`).

## Migrations & Eloquent Sync
- **Writing:** Keep atomic. Always provide a `down()`. Use explicit `->references()->on()` for foreign keys on non-standard table names. Migrations only add schema, they do not backfill data.
- **Running:** Backup first. In Production, append `--force`. **Never roll back production; write a corrective migration instead.**
- **Sync:** If a column changes, update the Model's `$fillable`, `$casts`, and `@property` annotations immediately.

## Seeders
- **Idempotency:** Seeders must be safe to run multiple times without duplicating data. Use `firstOrCreate()` or `updateOrCreate()`.

## Test Database Isolation
- See `.agents/rules/41_workflow_testing.md` for `RefreshDatabase` isolation, `phpunit.xml` configuration, and safe test execution patterns.

## Emergency Recovery
If the development DB is wiped:
1. Find latest backup in `database/backups/`.
2. Clear: `sail exec pgsql psql -U sail -d {db} -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"`
3. Restore: `sail exec -T pgsql psql -U sail -d {db} < database/backups/{file}.sql`
4. Run `sail artisan migrate` and re-seed structural data.
