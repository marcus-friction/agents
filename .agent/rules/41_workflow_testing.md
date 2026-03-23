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

## Frontend (Vitest + @nuxt/test-utils)
- **Structure:** `tests/unit/` (Node environment) vs `tests/components/` (Nuxt-aware via `mountSuspended` + `happy-dom`).
- **Components:** Test outputs and user interactions, not internal implementation details.
- **Pinia:** Isolate state using `setActivePinia(createPinia())` resetting in `beforeEach()`.
- **Composables:** Use `mockNuxtImport` for auto-imported dependencies. Test independent composables in `tests/unit/`.
- **Verification:** Always run `nuxi typecheck` and `eslint .` to guarantee type safety and formatting.