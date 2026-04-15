---
trigger: always_on
---

# Infrastructure
> **Per-project template.** Fill in actual values per repo.

## Environments
| Env        | URL                     | Branch      | Auto-deploy |
|------------|-------------------------|-------------|-------------|
| Dev        | `localhost:{APP_PORT}`  | `feature/*` | —           |
| Staging    | `staging.{project}.com` | `staging`   | Yes (Forge) |
| Production | `{project}.com`         | `master`    | Yes (Forge) |

## Dev Port Mapping & Services
- **Laravel (Sail)** / **Nuxt (SSR)** : `{port}` -> `APP_PORT`
- **PostgreSQL** : `{port}` -> `FORWARD_DB_PORT`
- **Redis** : `{port}` -> `FORWARD_REDIS_PORT` (Used for Cache, Queue)
- **Meilisearch** : `{port}` -> `FORWARD_MEILISEARCH_PORT` (Search)
- **Mailpit** : SMTP `{port}` -> `FORWARD_MAILPIT_PORT`, UI `{port}` -> `FORWARD_MAILPIT_DASHBOARD_PORT`

## Production Services
- **DB/Cache/Queue:** Managed by Forge (PostgreSQL / Redis / Horizon).
- **Search:** Systemd managed Meilisearch.
- **Storage:** DO Spaces (Local in Dev).
- **Mail:** Mailgun / SES.
- **Monitoring & CDN:** Sentry / Cloudflare.

## Network Binding Policy
- **Redis must bind to `127.0.0.1` only.** Never expose Redis on `0.0.0.0` or a public interface. Redis has no authentication by default and must only accept local connections.
- **Meilisearch must bind to `127.0.0.1` only.** Same rationale — master key auth exists but network exposure is unnecessary.
- **PostgreSQL:** Accept connections from `127.0.0.1` and private network IPs only. Never allow public access. Forge manages `pg_hba.conf` — do not override.
- **Verify after provisioning:** Run `ss -tlnp | grep -E '6379|7700|5432'` on any new server to confirm services listen on `127.0.0.1`, not `0.0.0.0`.

## Start Scripts
- All local dev startup scripts (`serve.sh`, `start.sh`, etc.) must follow the `start-scripts` skill. Consult it when creating or modifying startup scripts.
