# Laravel Cloud operations

Sources checked 2026-09-11. Discover current pages through the
[official documentation index](https://laravel.com/cloud/docs/llms.txt).
This is original stack guidance informed by those docs. Laravel also maintains
an [official deployment skill](https://github.com/laravel/agent-skills); it is
not a required second installation or an additional source of authorization.

## CLI and target discovery

Reuse the project's `vendor/bin/cloud` if installed, otherwise an existing
global `cloud`. Resolve the actual executable and inspect its version and help.
If absent, propose the official `laravel/cloud-cli` Composer package and its
installation scope; do not install it as an incidental readiness step. A Nuxt
app can use a global CLI without adding PHP dependencies to its frontend.
Check package requirements against the local runtime; docs and installed
versions may differ. No custom API wrapper or agent-specific tool is required.

The following discovery examples use `cloud` as the resolved executable:

```sh
cloud --version -n
cloud --help -n
cloud application:list --help -n
cloud deploy --help -n
cloud ship --help -n
cloud deploy:monitor --help -n
```

Read help for each operation before assembling arguments. Use non-interactive
mode (`-n`) with all required values. Request JSON only where supported and
extract the minimum needed fields without exposing secrets. Do not suppress
errors or treat `--force` as user authorization. Do not assume mutation commands
support the same flags as reads or that examples from another CLI version work.

Resolve the organization, app, environment and resource IDs. Check existing
repo defaults against the selected targets; one repo default is not sufficient
to identify both apps in a monorepo. If credentials select another organization,
stop before mutation and resolve the mismatch. Inspect configuration through
the CLI without printing token files or sensitive variable values.

Use browser authentication when the user can complete it. For headless use,
the CLI supports `LARAVEL_CLOUD_TOKEN` supplied through approved secret storage
or the execution environment. Do not request tokens in chat. Prefer secure
stdin/file input supported by the installed command for secret mutation. Avoid
shell tracing, literal values in arguments and raw credential-bearing output.
If tooling cannot keep a value private, give the user a bounded dashboard step.

Sources: [CLI](https://laravel.com/cloud/docs/api/cli),
[CLI repository](https://github.com/laravel/cloud-cli),
[authentication](https://laravel.com/cloud/docs/api/authentication).

## First and subsequent releases

`ship` may create an application, deploy, provision resources, sync local
variables, and create/push a repository. Inspect its help and actual behavior;
do not use it when these effects exceed the approved batch. Explicit resource
operations are suitable when the guided path cannot express the approved setup.
If the installed CLI cannot configure a needed Nuxt/runtime setting, use a
precise dashboard handoff rather than inventing flags or installing an upgrade.

Cloud builds from a connected Git repository. Identify the branch and exact
commit(s); pushing can deploy immediately when push-to-deploy is enabled.
Choose one release trigger. For CI-gated releases, configure automatic pushes
accordingly so they cannot bypass the checks or race a second trigger. Deploy
hooks can target a commit belonging to the environment's branch. Treat hook
URLs as secrets and confirm the resulting deployed revision.

Compare existing settings before updates. Pending Cloud settings and linked
secrets can take effect with the next deployment; include them in the review.
Reuse existing resources rather than recreating them on every invocation.

Sources: [deployments](https://laravel.com/cloud/docs/deployments),
[environments](https://laravel.com/cloud/docs/environments),
[secrets](https://laravel.com/cloud/docs/secrets).

## Laravel settings and resources

Select the adopted PHP version explicitly; Cloud's new-environment default may
differ. Derive build steps from the repo's lockfiles/scripts, including assets
only where used. Install production Composer dependencies and build caches in
the build phase. Put reviewed additive database migrations in the deploy phase;
`php artisan migrate --force` is a production operation, not a readiness check.
Deploy-phase filesystem changes do not persist. Cloud manages worker restarts;
do not transfer a Forge/PM2 restart script into Cloud unchanged.

Use `APP_ENV=production` for production targets. For staging and other
environments, preserve the adopted `APP_ENV` value and inspect its consumers
before proposing a change; mail routing and scheduled tasks may depend on it.
Keep `APP_DEBUG=false`, the correct HTTPS application URL, and a stable
per-environment application key. Do not rotate an existing
`APP_KEY` during deployment. Resource attachment injects connection settings;
look for stale custom variables that override them. Avoid local filesystem
sessions/cache/uploads: replicas and deployments do not share durable disks.

| Need actually present | Decision to make |
|---|---|
| PostgreSQL | Verify offered major version, extensions, region, connection limits and recovery. Preserve PostgreSQL 17 where adopted; incompatible offerings need a decision. Attach to the backend that owns the data. |
| Cache/session/Redis workloads | Preserve distinct connections, database selection, prefixes and failure-domain needs. Valkey is a Redis-compatible option, not automatic approval to replace an adopted service. |
| Uploads/generated files | Use durable object storage. Verify the S3 adapter is already installed or propose it explicitly. Retain disk names and access semantics; public/private Cloud buckets have different visibility, not per-object ACLs. |
| Queues/Horizon | Check current managed-queue requirements and job semantics. Horizon needs a Redis-backed queue and a custom process; managed queues cannot replace it transparently. |
| Scheduler | Enable it deliberately on the intended Laravel cluster; verify duplicate execution protection when replicas exist. |
| Mail/search/WebSockets | Preserve adopted providers; identify missing credentials/services and costs rather than provisioning every optional component. |

Check scale-to-zero against job duration, scheduled work and latency needs.
Estimate app, frontend, database, workers, storage and traffic together from
current regional pricing. Distinguish estimates from caps; spending-limit
shutdown affects availability and may not eliminate every charge.

Sources: [runtimes](https://laravel.com/cloud/docs/runtimes),
[Postgres](https://laravel.com/cloud/docs/resources/databases/postgres),
[Valkey](https://laravel.com/cloud/docs/resources/caches/valkey),
[storage](https://laravel.com/cloud/docs/resources/object-storage),
[queues](https://laravel.com/cloud/docs/queues),
[scheduler](https://laravel.com/cloud/docs/scheduled-tasks),
[pricing](https://laravel.com/cloud/pricing),
[spending limits](https://laravel.com/cloud/docs/spending-limits).
