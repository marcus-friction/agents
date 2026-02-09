---
trigger: model_decision
description: Apply when writing, reviewing, or modifying Laravel backend code (PHP, Eloquent, controllers, actions, migrations, etc).
---

# Laravel Standards

## Structure

- **Default Laravel directory structure** — no domain-driven organization.
- **`declare(strict_types=1)`** in every PHP file. Enforce via Pint `declare_strict_types` rule.
- **No magic numbers** — timeouts, limits, IDs, and thresholds go in config files or class constants.
- **Comments explain "Why", not "How"** — DocBlocks document business intent and non-obvious decisions. Do not narrate implementation.

## Laravel-First Principle

**Before building anything, check if Laravel provides it.** The framework and its first-party packages (`20_stack.md`) cover most common needs. Writing custom implementations for solved problems is wasted effort and diverges from ecosystem conventions.

**Lookup order:**
1. Laravel core (Eloquent, Auth, Validation, Events, Mail, etc.)
2. First-party packages listed in `20_stack.md` (Horizon, Scout, Pennant, Pulse, etc.)
3. Established third-party packages already in the project (`composer.json`, `package.json`)
4. Custom implementation — only if none of the above apply

**Common anti-patterns — do not reinvent these:**

| Instead of... | Use... |
|---|---|
| Custom queue monitoring | Horizon |
| Config booleans / `.env` flags for feature gating | Pennant |
| Raw Meilisearch API calls | Scout |
| Custom notification job + Mailable | Notification class with `ShouldQueue` |
| Manual cron scripts | Scheduler (`routes/console.php`) |
| Custom search indexing logic | Scout's `Searchable` trait |
| Manual `dd()` / log debugging in production | Telescope (dev), Pulse (prod) |
| Inline permission checks in controllers | Policy classes |
| Raw DB queries for common patterns | Eloquent scopes, relationships |
| Custom validation logic in controllers | Form Request classes |

## Business Logic

- **Action classes** are the primary pattern for domain operations. One class, one job, single `__invoke()` method.
  - Location: `app/Actions/`
  - Naming: verb-first — `CreateOrder`, `SendInvoice`, `SyncInventory`.
- **Service classes** only for third-party SDK wrappers or cross-cutting infrastructure (e.g., `PaymentGatewayService`, `SearchService`).
- **Controllers are thin** — receive request, call action/service, return response. No business logic.

## Refactoring Triggers

- Controller method exceeds **15 lines** → extract logic to an Action class.
- Action class handles multiple unrelated concerns → split into focused Actions.

## API

- **Versioned routes**: `/api/v1/...`. Route files at `routes/api/v1.php`.
- **API Resources** for all JSON responses — never return raw models.
- **Form Request classes** for validation — no inline `$request->validate()`.
- **Resourceful controllers** using `Route::apiResource()` where applicable.
- **Consistent response structure** — use API Resources and proper HTTP status codes.

## Naming Conventions

| Item | Convention | Example |
|---|---|---|
| Models | Singular, PascalCase | `User`, `BikeModel` |
| Controllers | Singular, PascalCase, suffixed | `OrderController` |
| Actions | Verb-first, PascalCase | `CreateOrder` |
| Tables | Plural, snake_case | `users`, `bike_models` |
| Columns | snake_case | `first_name`, `created_at` |
| Pivot tables | Singular alphabetical, snake_case | `order_product` |
| Variables | camelCase | `$activeUsers` |
| Methods | camelCase | `calculateTotal()` |
| Routes | Plural, kebab-case | `/api/v1/bike-models` |
| Form Requests | PascalCase, suffixed | `StoreOrderRequest` |
| Migrations | Descriptive, snake_case | `create_orders_table` |

## Eloquent

- Always define `$fillable` on models (see `50_security.md` Mass Assignment).
- Use relationships and scopes — avoid raw DB queries unless performance demands it.
- Factories for every model.
- Use the `casts()` method for attribute casting (Laravel 12) — dates, booleans, enums, JSON. Follow existing model conventions if the project uses `$casts` property instead.

## Enums

- Use PHP 8.1+ backed enums for status fields, types, and roles — not string constants or config arrays.
- Location: `app/Enums/`
- Back with `string` or `int` to match database storage.
- Cast on models via `$casts`.

## Data Transfer Objects

- Use DTOs (or Spatie Laravel Data) for complex inputs/outputs between layers.
- Actions accept DTOs, not raw arrays or request objects.
- DTOs are immutable — set in constructor, no setters.

## Events & Listeners

- Use events for side effects that should not block the primary action (send email, sync search index, log activity).
- Actions fire events — listeners handle secondary concerns.
- Listeners are queueable by default.
- Location: `app/Events/`, `app/Listeners/`

## Jobs & Queues

- Anything slow, external, or non-critical goes on a queue.
- Jobs must be **idempotent** — safe to retry on failure.
- Implement `ShouldQueue` interface.
- Define `$tries`, `$backoff`, and `failed()` method for error handling.
- Location: `app/Jobs/`

## Policies

- Authorization logic lives in Policy classes — not controllers, not actions.
- Controllers authorize via `$this->authorize()` or `Gate::authorize()`.
- One Policy per model.
- Location: `app/Policies/`

## Error Handling

- Custom exception classes for domain errors (e.g., `InsufficientStockException`).
- Location: `app/Exceptions/`
- Consistent JSON error responses via the exception handler — never expose stack traces to clients.
- Use appropriate HTTP status codes: 422 for validation, 403 for authorization, 404 for not found, 500 for server errors.

## Config & Environment

- **Never use `env()` outside config files** — see `50_security.md`.
- Keep `.env.example` in sync with all required variables.
- Use config caching in production (`config:cache`).

## Migrations

See `44_workflow_database.md` for all migration writing, execution, and safety rules.

## Notifications

- Use Laravel's `Notification` classes for user-facing messages — not raw Mailables or ad-hoc jobs.
- Define delivery channels in `via()` — `mail`, `database`, `broadcast`, etc.
- `toMail()` for email, `toDatabase()` for in-app notification storage.
- Implement `ShouldQueue` on notifications — email delivery must never block the request.
- Location: `app/Notifications/`

## Scheduling

- Define scheduled tasks in `routes/console.php` (Laravel 11+).
- Server runs `schedule:run` via cron every minute — Forge manages this.
- Always set `->timezone()` explicitly on time-sensitive schedules.
- Use `->withoutOverlapping()` on long-running tasks to prevent pile-ups.
- Monitor via Pulse — failed schedules surface there automatically.

## Middleware

- Custom middleware in `app/Http/Middleware/`.
- Register in `bootstrap/app.php` middleware groups or individual routes — not globally unless it applies everywhere.
- **When to use middleware vs. Form Request authorization:**
  - Middleware: cross-cutting concerns (rate limiting, locale, CORS, feature flags).
  - Form Request `authorize()`: resource-specific permission checks tied to a specific request shape.
- Name middleware descriptively: `EnsureUserIsSubscribed`, not `CheckSub`.

## Service Providers

- `AppServiceProvider` for most bindings and configuration — avoid creating custom providers unless truly independent.
- `register()`: bind interfaces to implementations, register singletons. No other logic.
- `boot()`: event listeners, model observers, macro definitions, Blade directives.
- Never resolve dependencies in `register()` — other providers may not be loaded yet.

## Scout (Search)

- Use `Laravel\Scout\Searchable` trait on models that need full-text search.
- Define `toSearchableArray()` on each model — flatten relationship data (e.g., `category.name`, `brand.name`) into the array.
- Explicitly configure `filterableAttributes` and `sortableAttributes` per index — Meilisearch rejects filter/sort queries on unconfigured fields.
- Sync index settings via `sail artisan scout:sync-index-settings`.
- Always use `->searchable()` / `->unsearchable()` in model events to keep indexes in sync.
- Queue indexing operations in production (`SCOUT_QUEUE=true`).

## Pennant (Feature Flags)

- Use `Feature::active('feature-name')` to gate features — not config booleans or `.env` flags.
- Define features in a dedicated provider or `AppServiceProvider::boot()`.
- Scope features to users or teams via the `$scope` parameter.
- Clean up resolved flags with `sail artisan pennant:purge` after full rollout.