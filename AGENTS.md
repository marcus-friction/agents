# Agent Instructions & Pragmatic Guidelines

> [!WARNING]
> Rules are mandatory. Refer to `README.md` for project stack/vision and `DESIGN.md` for UI specs.

## Conduct & Workflow
- **Scope Discipline:** No unprompted refactoring. Stick strictly to the requested task.
- **Anti-Loops:** Stop and ask if stuck in cascading fixes.
- **Directness & Verification:** Lead with answers, no filler. Proactively verify work.
- **"Do the Complete Thing":** Never skip the last 10% (regression tests, security reviews, docs).
- **Optimize for Judgment:** Pause for architectural/edge-case approval before massive code generation.
- **Feature Bloat:** If repeatedly fixing a pattern, HALT and document the constraint in `AGENTS.md`.
- **Testable Acceptance Criteria:** Define explicitly before implementation.

## Backend (Laravel 13)
- **Structure:** Default structure, `declare(strict_types=1)` everywhere.
- **DI:** Constructor injection exclusively; never `app()`, `resolve()`, or `new`.
- **Domain Logic:** Thin controllers (extract >15 lines to `app/Actions/`).
- **Data Layer:** `$fillable` mandatory (no `$guarded = []`). Wrap `orWhere` in closures. Prefer relationships/scopes over raw queries.
- **Performance:** No N+1 queries. Use `loadCount()`/`loadExists()`. Chunk bulk imports via `upsert()`/`insert()`.
- **100% TDD (Pest):** Total coverage for controllers, actions, domain logic. Write failing test first.

## Frontend (Nuxt 4 / Vue 3)
- **Composition API:** `<script setup>` exclusively. Use `ref` (primitives), `reactive` (objects), VueUse.
- **Data Fetching:** SSR via `useFetch`/`useAsyncData`. Never `$fetch` directly on initial load (hydration risk).
- **TypeScript:** Use `import type`. Generate types from Laravel API. Use `satisfies`, not `as`.
- **Naming:** PascalCase (Components/Types), camelCase (Composables/Stores/Vars), kebab-case (Pages).
- **100% TDD (Vitest):** Total coverage for composables/stores/logic. Write failing test first.
- **E2E (Playwright):** Verify DOM/interaction changes in a real browser.

## Security & Data
- **Defense:** Validate via Form Requests, authorize via Policies, escape output.
- **Secrets:** `.env` only. Use `config()` (Laravel) and private `runtimeConfig` (Nuxt).
- **XSS & SSRF:** Avoid `{!! !!}`/`v-html` with user content. Bind IP and use `dns_get_record()` for URL fetching.

## Caching & Performance
- **Cache:** `Cache::remember()` (wrap `null` in DTOs). Use `Cache::lock()` for heavy tasks.
- **Redis:** Separate DBs (`default`, `cache`, `session`, `queue`) to isolate `FLUSHDB`.
- **HTTP:** Middleware `Cache-Control` (`public` vs `private`). Nuxt `routeRules` (`isr/swr`).

## Accessibility (WCAG AA)
- **HTML & Forms:** Semantic tags (no `div` buttons). One `<h1>` per page. Visible `<label>` per input.
- **A11y:** Keyboard-operable, visible focus, trap modal focus (`Escape` to close). Contrast ≥4.5:1. Descriptive `alt` tags.
