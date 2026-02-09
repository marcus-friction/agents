---
trigger: model_decision
description: Apply when writing, reviewing, or running tests (Pest, Vitest), or when discussing test strategy and coverage.
---

# Testing Standards

## Coverage Philosophy

- Aim for high coverage across all layers — actions, controllers, models, composables, components.
- No hard coverage gate in CI, but every new feature and bugfix should ship with tests.
- Untested code is a liability. If you touch it, test it.
- For test-first workflow, read the `test-driven-development` skill if available.

---

## Backend — Pest + Larastan

### Execution Order

1. `./vendor/bin/phpstan analyse` — static analysis catches bugs before tests run.
2. `./vendor/bin/pint --test` — formatting check.
3. `sail test` — Pest test suite.

### Test Organization

- Mirror the app structure in `tests/Feature/` and `tests/Unit/`:
  - `tests/Feature/Api/V1/OrderControllerTest.php`
  - `tests/Unit/Actions/CreateOrderTest.php`
- **Feature tests** for HTTP endpoints and full request lifecycle.
- **Unit tests** for isolated logic — actions, value objects, services.
- **Architectural tests** using Pest's `arch()` plugin to enforce structural rules:
  ```php
  arch('controllers are thin')
      ->expect('App\Http\Controllers')
      ->not->toUse(['App\Models']);

  arch('actions are invokable')
      ->expect('App\Actions')
      ->toHaveMethod('__invoke');

  arch('strict types everywhere')
      ->expect('App')
      ->toUseStrictTypes();
  ```
  These prevent architectural drift over time — add new rules as patterns emerge.

### Naming & Structure

- Use `it()` syntax with descriptive sentences:
  ```php
  it('creates an order with valid data')
  it('rejects orders without a shipping address')
  it('fires OrderCreated event after successful creation')
  ```
- Group related tests with `describe()`:
  ```php
  describe('order creation', function () {
      it('creates an order with valid data')
      it('rejects orders without a shipping address')
  });
  ```
- Follow **Arrange → Act → Assert** in every test.

### Pest Features

- **Datasets** for testing same logic with varying inputs:
  ```php
  it('validates required fields', function (string $field) {
      // ...
  })->with(['name', 'email', 'address']);
  ```
- **`beforeEach()`** for shared setup within a file.
- **Global hooks** in `Pest.php` for cross-file setup (e.g., `RefreshDatabase`).
- **Higher-order tests** where they improve readability.

### What to Test

- **Actions**: test directly via invocation, not only through HTTP.
- **Controllers**: feature tests covering success, validation errors, authorization.
- **Models**: relationships, scopes, casts, accessors.
- **Events & Listeners**: assert events are dispatched; test listeners in isolation.
- **Jobs**: test `handle()` directly; assert jobs are dispatched from actions.
- **Policies**: test each gate/ability returns correct allow/deny.
- **Form Requests**: test validation rules via controller feature tests.

### Isolation

- `RefreshDatabase` trait for database isolation.
- Mock external services (payment gateways, third-party APIs) — never hit external services in tests.
- Factories for all models — no manual data setup in tests.

---

## Frontend — Vitest + @nuxt/test-utils

### Test Organization

- `tests/unit/` — fast tests running in Node (composables, utilities, stores).
- `tests/components/` — Nuxt-aware component tests using `mountSuspended`.
- Use `defineVitestConfig` from `@nuxt/test-utils/config` for Nuxt environment setup.

### Component Testing

- Mount components with `mountSuspended` from `@nuxt/test-utils/runtime`.
- Test **outputs and behavior**, not implementation details.
- Use `happy-dom` as the test environment.

### Pinia Store Testing

- Always call `setActivePinia(createPinia())` in `beforeEach()` — fresh state per test.
- Use `createTestingPinia()` when mounting components that depend on stores.
- Test store actions, getters, and state mutations independently.

### Composable Testing

- Use `mockNuxtImport` from `@nuxt/test-utils/runtime` for auto-imported composables.
- Centralize mock setup in `tests/setup/nuxt.mocks.ts`.
- Reset mocks in `beforeEach()` for test isolation.
- Composables without Nuxt runtime dependencies → test as plain unit tests in `tests/unit/`.

### What to Test

- **Components**: rendering, user interactions, emitted events, slot content.
- **Composables**: returned reactive state, function behavior, error handling.
- **Stores**: actions, getters, state transitions.
- **Type checking**: `npx nuxi typecheck` on every CI run.

### ESLint

- ESLint flat config only — no legacy `.eslintrc`.
- Run `npx eslint .` in CI.