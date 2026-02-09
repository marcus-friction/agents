---
trigger: always_on
---

# Infrastructure

> **Per-project file.** Copy this template into each project's `.agent/rules/` and fill in the actual values.

## Environments

| Environment | URL | Branch | Auto-deploy |
|---|---|---|---|
| Dev | `localhost:{APP_PORT}` | feature/* | — |
| Staging | `staging.{project}.com` | `staging` | Yes (Forge) |
| Production | `{project}.com` | `master` | Yes (Forge) |

## Dev Port Mapping

| Service | Port | .env Variable |
|---|---|---|
| Laravel (Sail) | `{port}` | `APP_PORT` |
| Nuxt (SSR) | `{port}` | — |
| PostgreSQL | `{port}` | `FORWARD_DB_PORT` |
| Redis | `{port}` | `FORWARD_REDIS_PORT` |
| Meilisearch | `{port}` | `FORWARD_MEILISEARCH_PORT` |
| Mailpit SMTP | `{port}` | `FORWARD_MAILPIT_PORT` |
| Mailpit UI | `{port}` | `FORWARD_MAILPIT_DASHBOARD_PORT` |

## Services

| Service | Dev | Staging | Production |
|---|---|---|---|
| Database | PostgreSQL (Sail) | Forge managed | Forge managed |
| Cache | Redis (Sail) | Redis (Forge) | Redis (Forge) |
| Queue | Redis (Sail) | Redis (Forge) | Redis (Forge) |
| Queue Monitor | Horizon (Sail) | Horizon (Forge) | Horizon (Forge) |
| Search | Meilisearch (Sail) | Meilisearch (systemd) | Meilisearch (systemd) |
| Storage | Local disk | DO Spaces | DO Spaces |
| Mail | Mailpit | Mailgun / SES | Mailgun / SES |
| Monitoring | — | Sentry | Sentry |
| CDN | — | Cloudflare | Cloudflare |
