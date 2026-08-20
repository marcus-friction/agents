# Agent Instructions & Pragmatic Guidelines

> [!WARNING]
> This document contains pragmatic, non-project-specific rules that agents MUST follow across the ecosystem. Do not deviate from these patterns unless explicitly instructed. Project-specific stack and vision information is found in `README.md`. Design specifications are in `DESIGN.md`.

## Core Conduct & Quality
- **Scope Discipline:** Stay strictly within the requested scope. Never modify, refactor, or "improve" code outside the current task without explicit permission.
- **Anti-Loops:** Do not enter fix-loops where one change triggers cascading unrelated changes. Stop and ask if stuck.
- **Verification:** Proactively verify work. Suggest automated or manual verification steps.
- **Directness:** Lead with the answer, then provide context. No filler, no apologies. Correct mistakes and move on.

## AI Native Workflow & Compounding
- **"Do the Complete Thing":** Because AI makes the marginal cost of execution near zero, never skip the "last 10%". Every feature must include regression tests, a security review, and documentation updates before being considered complete.
- **Optimize for Judgment, Not Typing:** Code generation is cheap; architectural judgment is expensive. Pause to verify architectural fit and edge cases with the developer before generating large blocks of code.
- **The "Feature Bloat" Stop-Condition:** If you find yourself repeatedly fixing the same class of bug or using inconsistent patterns, immediately HALT execution and document the constraint in `AGENTS.md` before proceeding.

## Engineering Process
- **Testable Acceptance Criteria:** Every feature must be mapped to explicit, testable acceptance criteria (and edge cases) *before* implementation begins. This ensures clarity and prevents building the wrong thing.

## Backend Standards (Laravel)
- **Structure:** Use default Laravel directory structure. `declare(strict_types=1)` everywhere.
- **Dependency Injection:** Never call `app()`, `resolve()`, or `new` inside constructors. Use constructor injection exclusively.
- **Domain Logic:** Thin controllers (receive request, call action, return response). Controllers >15 lines trigger extracting an Action class in `app/Actions/`.
- **Data Layer (Eloquent):** Always define `$fillable`. Prefer relationships/scopes over raw queries. Wrap `orWhere` inside a `where(fn ($q) => ...)` group to prevent scope leaks.
- **Performance:** Avoid N+1 queries. Use `loadCount()` / `loadExists()` instead of loading full relations just to call `->count()`. For bulk imports, use `upsert()` / `insert()` in chunks instead of per-row `updateOrCreate()`.
- **100% Test Coverage (TDD):** All controllers, actions, and domain logic must be covered by Pest tests. Strict Test-Driven Development is required: no production code without a failing test first.

## Frontend Standards (Nuxt / Vue)
- **Composition API:** Use `<script setup>` and Vue 3 Composition API exclusively. Use `ref` for primitives, `reactive` for deep objects. Use VueUse composables where possible.
- **Data Fetching (Nuxt):** Use `useFetch` / `useAsyncData` for SSR data. Never use `$fetch` directly in components for initial loads (causes hydration mismatch).
- **TypeScript:** Generate response types from Laravel API Resources. Place in `shared/types/`. Import using `import type`. Use `satisfies` over `as`.
- **Naming:**
  - `PascalCase`: Components (`UserCard.vue`), Types/Interfaces.
  - `camelCase`: Composables (`useAuth`), Pinia Stores, Variables.
  - `kebab-case`: Pages (`user-profile.vue`).
- **Real-Browser Verification (E2E):** Do not rely solely on unit tests for the frontend. Any DOM or interaction changes must be verified using a real browser testing tool (e.g., Playwright) to prevent "it works in theory" hydration and interaction bugs.
- **100% Test Coverage (TDD):** All composables, Pinia stores, and complex UI logic must have 100% unit test coverage using Vitest. Strict Test-Driven Development is required: no production code without a failing test first.

## Security & Data
- **Never trust input.** Validate at the boundary via Form Requests, authorize at the resource via Policies, escape at the output.
- **Secrets:** Store in `.env` only (never commit). Use `config()` in Laravel, never `env()` in code. In Nuxt, use private `runtimeConfig` (public only for safe values).
- **XSS & SSRF:** Blade `{{ }}` and Vue `{{ }}` auto-escapes. Never use `{!! !!}` or `v-html` with user content unless strictly sanitized. For URL fetching, use `dns_get_record()` and bind IP to prevent DNS rebinding.
- **Mass Assignment:** Always define `$fillable`. Do not use `$guarded = []`.

## Caching & Performance
- **Application Cache:** Cache expensive/frequent queries. Use `Cache::remember()`. Note: `null` returns bypass `Cache::remember()`. Wrap in a DTO if `null` is a valid value. Use `Cache::lock()` for expensive computations to prevent cache stampede.
- **Redis Isolation:** Use separate DBs for `default`, `cache`, `session`, `queue` to prevent `FLUSHDB` collateral damage.
- **HTTP/CDN Caching:** Apply `Cache-Control` via middleware (`public, max-age=...` for open data, `private` for auth/mutations). Nuxt SSR should configure `routeRules` (`isr: 3600`, `swr: 600`, `ssr: true`).

## Accessibility (WCAG AA)
- **Semantic HTML:** Use correct native elements (`<button>`, `<a>`, `<nav>`). Never `<div>`/`<span>` for interactions. Ensure one sequential `<h1>` per page.
- **Focus & Keyboard:** All interactive elements must be keyboard-operable. Provide visible focus indicators. Modals must trap focus and close via `Escape`.
- **Contrast & Visuals:** Minimum 4.5:1 (normal text). Do not use color alone to convey meaning. Meaningful images require descriptive `alt`. Decorative require `alt=""`.
- **Forms:** Every input requires a visible `<label>` tied via `for`/`id`. Indicate required fields structurally.
