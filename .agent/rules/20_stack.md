---
trigger: always_on
---

# Stack & Architecture

## Architecture

- **Monorepo**: Laravel at project root, Nuxt in `frontend/`.
- **API Pattern**: Decoupled — Laravel serves JSON API, Nuxt consumes via SSR proxy.
- **No Inertia**: Inertia is only used in Statamic projects (e.g., Coracle). New product projects use the decoupled API pattern.

### Monorepo Layout

```
project-root/
├── app/
│   ├── Actions/           # Single-purpose domain operations
│   ├── Console/
│   ├── Enums/             # PHP 8.1+ backed enums
│   ├── Events/
│   ├── Exceptions/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   └── Api/
│   │   │       └── V1/    # Versioned API controllers
│   │   ├── Middleware/
│   │   ├── Requests/      # Form Request classes
│   │   └── Resources/     # API Resources
│   ├── Jobs/
│   ├── Listeners/
│   ├── Models/
│   ├── Policies/
│   ├── Providers/
│   └── Services/          # Third-party SDK wrappers
├── config/
├── database/
│   ├── factories/
│   ├── migrations/
│   └── seeders/
├── routes/
│   ├── api/
│   │   └── v1.php         # Versioned API routes
│   ├── console.php
│   └── web.php
├── tests/
│   ├── Feature/
│   ├── Unit/
│   └── Arch.php           # Pest architectural tests
├── frontend/              # ← Nuxt application
├── docker-compose.yml     # Laravel Sail
├── phpstan.neon           # Larastan config
├── pint.json              # Pint config
└── .env.example
```

### Frontend Layout (`frontend/`)

```
frontend/
├── app/
│   ├── components/
│   │   ├── base/          # BaseButton, BaseInput, BaseCard...
│   │   └── ...            # Feature components
│   ├── composables/       # useAuth, useCart...
│   ├── layouts/
│   ├── pages/
│   └── plugins/
├── server/                # API proxy routes, server middleware
├── shared/                # Types and utilities (client + server)
│   └── types/
├── stores/                # Pinia stores (useAuthStore, etc.)
├── assets/
│   └── css/
│       └── main.css       # Tailwind @theme tokens
├── nuxt.config.ts
├── eslint.config.mjs
├── vitest.config.ts
└── tsconfig.json
```

## Backend

- **PHP**: 8.4
- **Framework**: Laravel 12.x
- **Admin Panel**: Filament 4.x
- **Database**: PostgreSQL 17
- **Cache / Queues**: Redis
- **Queue Monitoring**: Laravel Horizon
- **Search**: Meilisearch via Laravel Scout
- **Auth**: Laravel Sanctum (API tokens + SPA cookie auth)
- **Feature Flags**: Laravel Pennant
- **Testing**: Pest 3.x
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
  - Alias recommended: `alias sail='./vendor/bin/sail'` — all rules use the short form (`sail test`, `sail artisan ...`).
- **Deployment**: Laravel Forge
- **SSR Runtime**: PM2 (manages Nuxt SSR process in production)
- **CDN**: Cloudflare
- **Hosting**: GitHub (source), DigitalOcean (servers)

## Dependency Discipline

- **Never upgrade major versions, add new dependencies, or swap packages without explicit approval.**
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
- **Cypress / Playwright** — Antigravity browser covers E2E verification.
