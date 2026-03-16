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
