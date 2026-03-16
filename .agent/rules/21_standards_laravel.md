---
trigger: model_decision
description: Apply when writing, reviewing, or modifying Laravel backend code (PHP, Eloquent, controllers, actions, migrations, etc).
---

# Laravel Standards

## Core Architecture
- **Structure:** Default Laravel directory structure. No domain-driven organization.
- **Principles:** `declare(strict_types=1)` everywhere (Pint). No magic numbers (use config/constants). Comments explain "Why", not "How".
- **Laravel-First:** Always use built-in features/packages before custom code (Horizon, Scout, Pennant, Pulse, Policies, Notification, Scheduler).

## Domain Logic & Routing
- **Controllers:** Thin logic. Receive request, call action, return response. >15 lines triggers extracting an Action.
- **Actions:** Primary domain logic pattern. `app/Actions/`, verb-first (`CreateOrder`), single `__invoke()` method. Split if handling multiple concerns. Accept DTOs, not raw arrays.
- **Services:** Only for third-party SDK wrappers.
- **API:** JSON responses via API Resources (never raw models). Route in `routes/api/v1.php`. Validate via Form Requests (no inline `$request->validate()`).

## Data Layer
- **Eloquent:** Always define `$fillable`. Prefer relationships/scopes over raw queries. Require factories. Use `casts()` method for types.
- **Enums:** PHP 8.1+ backed enums in `app/Enums/`. Use `$casts` on models.
- **Scout:** Use `Searchable` trait. Flatten data in `toSearchableArray()`. Set searchable/sortable attributes explicitly. Synchronize and use queuing in prod.

## Async & Background
- **Events/Listeners:** Side effects (stats, emails) via Events. Use queueable Listeners (`app/Listeners/`).
- **Jobs:** Slow/external operations. Must be **idempotent**, implement `ShouldQueue`, and define `$tries`, `$backoff`, and `failed()`.
- **Notifications:** `app/Notifications/` implementing `ShouldQueue`. Use `via()` for channels (mail, database). Do not use raw Mailables.
- **Scheduling:** `routes/console.php`. Always use `->timezone()` and `->withoutOverlapping()`.

## Security & Reliability
- **Policies:** One per model in `app/Policies/`. Controllers call `$this->authorize()`.
- **Middleware:** Use for cross-cutting checks (rate limits, features). Name descriptively (`EnsureUserIsSubscribed`).
- **Error Handling:** Custom domain exceptions (`app/Exceptions/`). Return consistent JSON with proper HTTP codes (422, 403, 404, 500). No stack traces.
- **Config:** Never use `env()` outside config files.
- **Pennant:** Feature flag via `Feature::active()`, not `.env` booleans.

## Naming
- **PascalCase:** Models (`User`), Controllers (`*Controller`), Actions (`Create*`), Form Requests, API Resources, Interfaces/DTOs.
- **camelCase:** Variables, Methods.
- **snake_case:** DB tables (plural), Columns, Migrations, Pivot tables (singular alphabetical `order_product`).
- **kebab-case:** Routes (`/api/v1/bike-models`).