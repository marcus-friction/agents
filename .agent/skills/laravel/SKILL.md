---
name: laravel
description: Laravel framework operational patterns for AI agents. Use when creating files, writing migrations, building controllers, working with Eloquent, or running Artisan commands. Derived from official Laravel Boost guidelines.
metadata:
  version: "2026.2.9"
  source: Synthesized from laravel/boost .ai/ guidelines, tinho1123/CarvaSys skills, and LeandroSoares/cacaloo agent definitions
---

Laravel operational skill for AI-assisted development. Complements the project's `21_standards_laravel.md` rule with agent-specific workflow patterns derived from the official Laravel Boost MCP server.

> **Rule vs Skill**: `21_standards_laravel.md` defines *what* to build (architecture, naming, patterns). This skill defines *how* the agent should work (file creation, Artisan usage, verification).

## File Creation

- **Always use `sail artisan make:*` commands** to create models, controllers, migrations, Form Requests, policies, jobs, notifications, and events. Never create these files manually.
- Use `sail artisan list` to discover available generators and their options.
- Pass `--no-interaction` to all Artisan commands.
- Pass relevant `--options` to generators (e.g., `make:model -mfsr` for model + migration + seeder + factory + resource).
- When creating a generic PHP class, use `sail artisan make:class`.

## Conventions

- **Follow existing conventions first.** Before creating or editing a file, check sibling files for structure, approach, and naming patterns.
- Check for existing components/classes to reuse before writing new ones.
- Stick to the existing directory structure — do not create new base folders without approval.
- Do not change dependencies without approval.

## Eloquent

- **`Model::query()` over `DB::`** — always prefer Eloquent. Use the query builder only for genuinely complex operations.
- Prevent N+1 problems with eager loading (`with()`, `load()`).
- Define return type hints on all relationship methods.
- Casts: use the `casts()` method on models (Laravel 12), not the `$casts` property. Follow whichever convention the project already uses.
- When modifying a column in a migration, include **all** previously defined attributes — omitted attributes will be dropped.
- Limit eager loads natively in Laravel 12: `$query->latest()->limit(10)`.

## Controllers & Validation

- Create Form Request classes for validation — never inline `$request->validate()`.
- Check sibling Form Requests to see if the project uses array or string-based rules.
- Controllers handle HTTP I/O only — delegate logic to Actions or Services.

## APIs

- Default to Eloquent API Resources with versioned routes (`/api/v1/...`).
- If existing API routes don't use versioning, follow the existing convention.

## Auth & Authorization

- Use Laravel's built-in auth features: gates, policies, Sanctum.
- Spatie Permission: use `.can()`, never `.hasRole()` for authorization checks.

## URL Generation

- Prefer named routes with the `route()` function — never hardcode URLs.

## Queues

- Use `ShouldQueue` for time-consuming operations.
- Jobs must be idempotent — safe to retry.

## Config & Environment

- **Never use `env()` outside config files.** Always use `config()`.

## Laravel 12 Structure

- Middleware configured in `bootstrap/app.php` via `Application::configure()->withMiddleware()`.
- `bootstrap/providers.php` contains service providers.
- Console commands in `app/Console/Commands/` are auto-discovered — no manual registration.
- Scheduled tasks defined in `routes/console.php`.

## Testing

- Every change must be tested. Write or update a test, then run it.
- Run minimum tests needed: `sail test --compact --filter=TestName`.
- Use model factories — check for existing factory states before manually constructing models.
- Most tests should be feature tests. Use `--unit` flag only for pure unit tests.
- Use Pest syntax (`it()`, `test()`) — not PHPUnit class syntax.
- Use `fake()->word()` or `$this->faker->method()` — follow whichever convention the project uses.
- Never delete tests without approval.

## Verification

- Do not create verification scripts or tinker when tests cover the functionality.
- Run affected tests after every change to confirm they pass.

## Frontend Bundling

- If a frontend change isn't reflected in the UI, the user may need to run `npm run build` or `npm run dev`. Ask them.
- Vite manifest errors (`ViteException`) — resolve by running `npm run build`.

## Common Modern PHP Patterns

Use PHP 8.4 features where appropriate:
- **Constructor promotion**: `public function __construct(private readonly string $name)`
- **Backed enums**: `enum Status: string { case Active = 'active'; }`
- **Match expressions** over switch statements
- **Readonly properties** for immutable data
- **Named arguments** for clarity: `User::create(name: $name, email: $email)`
