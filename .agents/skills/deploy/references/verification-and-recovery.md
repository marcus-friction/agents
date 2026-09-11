# Verification and recovery

## Before releasing

Use the project's actual checks: Laravel static analysis, formatting and Pest;
Nuxt lint, typecheck, Vitest and production build when those components exist.
Exercise relevant changed flows with the adopted browser tests. Record skipped
or unavailable checks and their effect on readiness. Do not invent tests for
prose or run destructive migrations against a live database to validate config.

Compare the intended commit(s) with the remote branch and test evidence. Inspect
pending environment settings, attachments, secret changes and concurrent
deployments. Record the last working code/configuration and the compatible
database schema. Before a material data migration, establish the applicable
backup/restore or disposable-data rebuild path and authorization. A snapshot
without a usable restore path is incomplete recovery evidence.

## After each deployment

Follow the installed CLI's supported monitoring/status commands for the exact
deployment ID. Wait for terminal status; if monitoring disconnects, query that
deployment before trying again. A local timeout is not proof of remote failure.

Verify only the capabilities present in the application:

| Area | Observable evidence |
|---|---|
| Release | Correct app/environment, successful terminal status, expected revision and applied settings. |
| HTTP and frontend | HTTPS works, an expected page renders, assets and deep links load, Nuxt SSR works where adopted. |
| Laravel API | Health endpoint (often `/up`, if adopted) plus a representative API request; readiness includes required resource connectivity. |
| Authentication | Login, session continuity/SSR refresh, authorized action, access denial and logout with approved test data. |
| Persistence | Database access and upload/read behavior using an approved test record/file; no reliance on ephemeral files. |
| Background work | A safe representative job completes; scheduler/process status matches the intended configuration. |
| Operations | Relevant logs and resource status show no release errors; domain/TLS and configured scaling behave as expected. |

Prefer existing safe probes and designated test accounts. Obtain missing
authorization before tests send real mail, charge money, change production data
or trigger other external effects. Do not seed production or create privileged
users as a smoke-test shortcut. A backend 200 and a frontend 200 do not prove
the integrated user flow. No browser access means that flow remains unverified.

## Diagnose and recover

For a failed or ambiguous operation, inspect its remote status, deployment
phase, sanitized error and recent changes. Reconcile partially created resources
before retrying; duplicate provisioning creates cost and target ambiguity.
Diagnosis-only requests remain read-only. Implement a fix only when authorized,
verify it locally where possible, and revalidate the release scope before retry.
Stop and explain after the same blocker survives three attempted resolutions.

| Failure | Next decision |
|---|---|
| Build failure | Check runtime, lockfile, working directory, dependencies and generated output. Preserve the active release while preparing the fix. |
| Nuxt live but unreachable | Inspect start command, port, listen interface and Nitro preset/output; do not infer success from build status. |
| Migration failure | Determine what applied and whether the old code still works. A failed deploy may already have changed data/schema. |
| Frontend fails after backend release | Keep a backward-compatible backend with the previous frontend when verified safe; otherwise use the approved recovery pair or cutover decision. |
| Auth failure | Trace domains, credentials, CSRF and SSR forwarding; do not weaken authorization to get a green check. |
| Duplicate/uncertain deployment | Resolve deployment IDs and status before issuing a new release. |

Use the platform's currently supported method to redeploy a known compatible
revision when rollback is authorized. Verify its migrations/deploy commands
against the current schema first. Code rollback does not restore database data,
secrets or environment settings. Do not run `migrate:rollback`, restore a
database, rotate keys, delete resources or switch DNS without the exact separate
effect being covered. Keep the old host/resources until an approved migration
cutover and retention decision permit removal.

Return each application's deployed revision, URL and deployment ID, checks and
failures, any partial state, and a concrete recovery/next-release instruction.
When allowed, update the existing deployment record with applied facts, leaving
proposed or unverified settings visibly distinct.

Sources checked 2026-09-11:
[deployments](https://laravel.com/cloud/docs/deployments),
[logs](https://laravel.com/cloud/docs/logs),
[Cloud CLI](https://laravel.com/cloud/docs/api/cli).
