---
trigger: model_decision
description: Apply when writing, reviewing, or running tests (Pest, Vitest), or when discussing test strategy and coverage.
---

# Testing Standards

## Core Philosophy
- **Rule:** If you touch it, test it. Every feature and bugfix must include tests. Arrange → Act → Assert.

## Backend (Pest + Larastan)
- **Execution Order:** 1. `phpstan analyse` 2. `pint --test` 3. `sail test`.
- **Structure:** Mirror `app/` in `tests/Feature/` (HTTP/Integration) and `tests/Unit/` (Isolated logic).
- **Architecture Tests:** Use Pest's `arch()` to enforce rules (e.g., "controllers are thin", strict types).
- **Syntax:** Use descriptive `it()` blocks and group with `describe()`. Use Datasets (`->with()`) for variations.
- **Isolation:** Use `RefreshDatabase`. Mock external services (never hit real APIs in tests). Use Model Factories exclusively.
- **Coverage:** Test Actions (direct invocation), Controllers (HTTP/Validation/Auth), Events, Job `handle()` methods, and Policy gates.
- **Extraction = Tests:** When extracting logic into a new Service, Action, or DTO, write tests covering the extracted surface. Tests belong to the new class, not the old caller.

## Hard Gate
- **PR Blocker:** Any PR introducing new components, composables, Actions, Controllers, Jobs, or Services without corresponding test files is **blocked**. Flag missing coverage in review.
- **Review Checklist:** During `/review`, verify that every new file in `app/components/`, `app/composables/`, `app/Actions/`, `app/Http/Controllers/` has a corresponding `.spec.ts` or Pest test.

## Frontend (Vitest + @nuxt/test-utils)
- **Structure:** `tests/composables/` for composable specs, `tests/components/` (Nuxt-aware via `mountSuspended`) mirroring `app/components/` structure, `tests/utils/` for utility specs.
- **Components:** Test outputs and user interactions, not internal implementation details. Use `mountSuspended` from `@nuxt/test-utils/runtime`, never plain `mount()`.
- **Pinia:** Isolate state using `setActivePinia(createPinia())` resetting in `beforeEach()`.
- **Composables:** Use `mockNuxtImport` for auto-imported dependencies. Test independent composables in `tests/composables/`.
- **Teleports:** Components using `<Teleport>` — assert on `document.body`, not the wrapper.
- **Verification:** Always run `nuxi typecheck` and `eslint .` to guarantee type safety and formatting.

## E2E (Playwright)
- **Scope:** Cover all page templates (home, listing, detail, search, compare, CMS, error).
- **Nuxt SSR Hazards:** Use `.first()` on ambiguous selectors. Query the backend API directly (port 8500) for data discovery, not the Nuxt proxy. Use UI-based assertions, not `waitForResponse` (SSR `$fetch` is invisible to Playwright).
- **Data Independence:** Use `test.skip()` guards when dynamic data isn't available. Never hard-code database slugs.