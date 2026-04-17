---
trigger: always_on
description: Tech stack boundaries, directory structure, dependency discipline, and quality tooling.
---

# Stack & Architecture

## Architecture

- **Monorepo**: Laravel at project root, Nuxt in `frontend/`.
- **API Pattern**: Decoupled — Laravel serves JSON API, Nuxt consumes via SSR proxy.
- **No Inertia**: Inertia is only used in Statamic projects (e.g., Coracle). New product projects use the decoupled API pattern.

### Monorepo Layout

- **Backend:** Default Laravel structure with `app/Actions/` for single-purpose domain logic, versioned API controllers in `app/Http/Controllers/Api/V1/`, Form Requests for validation, API Resources for responses, and versioned routes in `routes/api/v1.php`. Pest architectural tests live in `tests/Arch.php`.
- **Frontend (`frontend/`):** Nuxt 4 structure — `app/` (components, composables, layouts, pages, plugins), `server/` (API proxy routes, server middleware), `shared/` (types and utilities shared between client and server), `stores/` (Pinia stores). Tailwind `@theme` tokens in `assets/css/main.css`.

## Backend

- **PHP**: 8.4
- **Framework**: Laravel 13.x
- **Admin Panel**: Filament 4.x
- **Database**: PostgreSQL 17
- **Cache / Queues**: Redis
- **Queue Monitoring**: Laravel Horizon
- **Search**: Meilisearch via Laravel Scout
- **Auth**: Laravel Sanctum (API tokens + SPA cookie auth)
- **Feature Flags**: Laravel Pennant
- **Testing**: Pest 4.x
- **Dev Debugging**: Laravel Telescope (local only)
- **Production Monitoring**: Laravel Pulse

## Frontend

- **Node**: 22 LTS
- **Framework**: Nuxt 4.x (SSR)
- **Styling**: Tailwind CSS 4.x (CSS-first config — no `tailwind.config.js`)
- **State**: Pinia 3.x
- **Language**: TypeScript (strict)

## Infrastructure

- **Local Development**: Laravel Sail (`docker-compose.yml` orchestrates PHP, Postgres, Redis, Meilisearch, Node)
- **Deployment**: Laravel Forge
- **SSR Runtime**: PM2 (manages Nuxt SSR process in production)
- **CDN**: Cloudflare
- **Hosting**: GitHub (source), DigitalOcean (servers)

## Dependency Discipline

- **Never upgrade major versions, add new dependencies, or swap packages without explicit approval.**
- **Always verify package versions using CLI tools:** Execute explicit commands (e.g., `npm info <package> version`, `composer show <package>`) to retrieve the exact version number before modifying `package.json` or `composer.json`. Do not rely on internal knowledge to predict a version.
- Always check `composer.json` and `package.json` before installing to avoid duplicates or conflicts.
- Use semantic versioning constraints in `composer.json` (`"laravel/framework": "^12.0"`) — no wildcards.
- Run `composer outdated` / `npm outdated` to check before proposing upgrades.

## Quality Tooling

### Backend

| Tool | Purpose | Command |
|---|---|---|
| **Larastan** | Static analysis (PHPStan for Laravel). Target level 9. | `./vendor/bin/phpstan analyse` |
| **Laravel Pint** | Code formatting. Customize via `pint.json`. | `./vendor/bin/pint` |
| **Pest** | Testing framework. Use `it()` syntax. | `sail test` |

### Frontend

| Tool | Purpose | Command |
|---|---|---|
| **@nuxt/eslint** | Linting (flat config, `eslint.config.mjs`) | `npx eslint .` |
| **nuxi typecheck** | TypeScript verification | `npx nuxi typecheck` |
| **Vitest** | Component + unit testing | `npx vitest` |

### Excluded

- **Prettier** — Pint handles PHP; ESLint handles frontend. Prettier adds conflicts.
- **PHP_CodeSniffer** — Pint supersedes it.
