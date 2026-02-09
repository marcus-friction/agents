---
trigger: model_decision
description: Apply when running migrations, writing seeders, performing database backups, or any destructive database operation.
---

# Database Operations

## Mandatory Backup Before Major Operations

**Every destructive or structural database operation must be preceded by a verified backup.** No exceptions.

### What Requires a Backup

| Operation | Requires Backup |
|---|---|
| `migrate` (new migrations) | ✅ Yes |
| `migrate:fresh` / `migrate:rollback` | ✅ Yes |
| `db:seed` (structural seeders) | ✅ Yes |
| Manual schema changes | ✅ Yes |
| Data manipulation scripts | ✅ Yes |
| Read-only queries | ❌ No |

### Backup Procedure

1. **Dump the database:**
   ```bash
   # Sail (PostgreSQL)
   docker exec {container-name} pg_dump -U sail {database} > database/backups/backup_$(date +%Y%m%d_%H%M%S).sql

   # Forge / Production
   pg_dump -U {user} {database} > database/backups/backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Verify the backup:**
   ```bash
   ls -lh database/backups/backup_*.sql | tail -1
   ```
   Confirm non-zero file size before proceeding.

3. **Only then** proceed with the operation.

### `.gitignore`

Add `database/backups/*.sql` to `.gitignore` — backups must never be committed.

---

## Migration Safety

### Writing Migrations

- Keep migrations atomic — one concern per file.
- Group related columns in a single migration using `->after()` for readability.
- Always provide a `down()` method for reversibility.
- **Foreign keys:** explicit `->references()->on()` for complex pluralization (e.g., tables ending in `-ia`, `-us`, `-um`). Don't rely on `->constrained()` for non-standard table names.
- **Calculated columns:** use a post-migration seeder or command to populate values for existing rows. Migrations only add schema — they don't backfill.

### Running Migrations

- **Development:** always backup first (see above), then `sail artisan migrate`.
- **Production:** always use `--force` flag in deployment scripts to bypass the interactive prompt:
  ```bash
  $FORGE_PHP artisan migrate --force
  ```
- **Rollback:** never roll back in production. Write a corrective migration instead.

### Model-Migration Sync

Keep Eloquent models and migrations in sync. If a column is removed from a migration or the schema, also remove it from:
- `$fillable`
- `$casts`
- PHPDoc `@property` annotations
- API Resources and frontend types

Verify with:
```bash
sail artisan tinker --execute="print_r(\Schema::getColumnListing('table_name'));"
```

---

## Test Database Isolation

**The test database must be completely isolated from the development database.** `RefreshDatabase` will wipe the target database — if isolation fails, development data is destroyed.

### Required Configuration

In `phpunit.xml`, use `force="true"` to prevent `.env` leakage:

```xml
<php>
    <env name="APP_ENV" value="testing" force="true"/>
    <env name="DB_DATABASE" value="testing" force="true"/>
</php>
```

### Rules

- **Always use Sail for tests:** `./vendor/bin/sail test` — ensures the containerized environment is used.
- **Never run tests directly on the host** (`vendor/bin/pest` or `php artisan test`) without verifying the target database first.
- **Clear config cache** before running tests if you suspect isolation issues:
  ```bash
  sail artisan config:clear
  ```
- **Verify isolation** before running a large suite:
  ```bash
  sail artisan tinker --env=testing --execute="echo config('database.connections.pgsql.database');"
  ```

### Infrastructure Tables

The test database needs all framework tables. If a test fails with `relation does not exist`, generate the missing migration:

- **Notifications:** `sail artisan make:notifications-table`
- **Failed jobs:** `sail artisan queue:failed-table`
- **Job batches:** `sail artisan queue:batches-table`

Run `sail artisan migrate:fresh --env=testing` after adding infrastructure migrations.

---

## Emergency Recovery

If the development database is accidentally wiped:

1. **Locate the most recent backup** in `database/backups/`.
2. **Reset the schema:**
   ```bash
   sail exec pgsql psql -U sail -d {database} -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
   ```
3. **Restore from backup:**
   ```bash
   sail exec -T pgsql psql -U sail -d {database} < database/backups/{backup_file}.sql
   ```
4. **Run catch-up migrations** (any migrations created after the backup):
   ```bash
   sail artisan migrate
   ```
5. **Re-run structural seeders** to sync derived data.
6. **Verify** record counts and UI functionality.
