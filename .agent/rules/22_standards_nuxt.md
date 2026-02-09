---
trigger: model_decision
description: Apply when writing, reviewing, or modifying Nuxt/Vue frontend code (components, composables, pages, Pinia stores, Tailwind styling).
---

# Nuxt Standards

## Structure

- **`app/`** directory for all UI code (pages, components, composables, layouts).
- **`server/`** for API routes and server-only logic.
- **`shared/`** for types and utilities used in both client and server.
- **`<script setup lang="ts">`** exclusively — no Options API.
- **No magic numbers** — thresholds, limits, and config values go in `useRuntimeConfig()` or named constants.
- **Comments explain "Why", not "How"** — document business intent and non-obvious decisions. Do not narrate implementation.

## Refactoring Triggers

- Vue component exceeds **300 lines** → extract logical sections into sub-components.
- Tailwind class string exceeds **80 characters** → extract to a component or use a binding variable.
- Use `tailwind-merge` for dynamic class binding to avoid conflicting utilities.

## Nuxt-First Principle

**Before building anything, check if Nuxt or Vue provides it.** Nuxt auto-imports composables, components, and utilities — writing custom versions of built-in features is wasted effort and breaks framework conventions.

**Lookup order:**
1. Nuxt built-ins (composables, components, utilities, auto-imports)
2. Vue core (`ref`, `computed`, `watch`, `provide`/`inject`, etc.)
3. Stack packages in `20_stack.md` (Pinia, Tailwind, `@nuxt/image`, etc.)
4. Existing project composables / components
5. Custom implementation — only if none of the above apply

**Common anti-patterns — do not reinvent these:**

| Instead of... | Use... |
|---|---|
| Custom fetch wrapper | `useFetch` / `useAsyncData` |
| Custom reactive state for SSR | `useState` |
| `<a>` tags for internal navigation | `<NuxtLink>` |
| `<img>` tags | `<NuxtImage>` |
| Manual `if (process.client)` guards everywhere | `<ClientOnly>` component |
| Custom error catch-all | `<NuxtErrorBoundary>` |
| `window.location.href = ...` | `navigateTo()` |
| Manual component/composable imports | Nuxt auto-imports |
| Custom global state management | Pinia stores |
| Custom CSS for spacing/colors/breakpoints | Tailwind utilities + `@theme` tokens |
| Custom media queries | Tailwind responsive prefixes (`sm:`, `md:`, etc.) |
| Custom ID generation for SSR | `useId()` |

## State Management

- **Pinia** for cross-cutting state (auth, cart, notifications, UI state).
- **`useState()`** acceptable for page-scoped ephemeral state.
- Pinia stores use the setup syntax (Composition API style).

## Naming Conventions

| Item | Convention | Example |
|---|---|---|
| Components | PascalCase files and usage | `UserCard.vue`, `<UserCard />` |
| Composables | camelCase, `use` prefix | `useAuth.ts`, `useCart.ts` |
| Stores (Pinia) | camelCase, `use` prefix, `Store` suffix | `useAuthStore.ts` |
| Pages | kebab-case | `user-profile.vue` |
| Types / Interfaces | PascalCase | `User`, `OrderItem` |
| Variables | camelCase | `const isLoading = ref(false)` |

## Component Layers

- **Base components** (`BaseButton`, `BaseInput`, `BaseCard`, etc.) are reusable design system primitives. They wrap HTML elements with consistent styling and props.
  - Location: `app/components/base/`
  - Prefix: always `Base`.
  - These are the only components that should contain raw Tailwind styling decisions (colors, spacing, typography).
- **Feature components** compose Base components and add domain logic.
- **Before creating a new component**, check if an existing Base component or composition already covers the need. Do not duplicate.

## Component Rules

- Props: use TypeScript generics with `defineProps<{}>()` and `withDefaults()`.
- Events: use `defineEmits<{}>()`.
- Never mutate props — emit events to parent.
- Use slots for content injection.
- Keep components focused — split when a component handles multiple concerns.

## Composables

- Prefix with `use` — always.
- Return refs, not raw values.
- Accept `ref` or `getter` arguments where appropriate.
- Clean up side effects (event listeners, intervals) on unmount.
- 4+ parameters → use an options object.

## Data Fetching

- Use `useFetch()` and `useAsyncData()` for SSR-compatible data loading.
- API calls go through a server proxy — never call the Laravel API directly from the client.

## Error Handling

- Use `useError()` composable and `createError()` for HTTP-level errors.
- Create `error.vue` at the app root for a global error page (404, 500).
- Use `<NuxtErrorBoundary>` to isolate component-level failures without crashing the page.
- Composables that call APIs: always handle the `error` ref from `useFetch` — never let it silently fail.
- Show inline error feedback per `23_design_system.md` Feedback Patterns — no toasts.

## SSR Gotchas

- **Browser APIs** (`window`, `document`, `localStorage`): wrap in `onMounted()` or use `<ClientOnly>`.
- **Hydration mismatches**: never generate random IDs or dates at render time — use `useId()` or seed from server state.
- **`onMounted` vs `onBeforeMount`**: `onMounted` runs client-only. Use `onBeforeMount` or `useAsyncData` for SSR logic.
- **Module-level state**: never use mutable module-level variables — they leak between SSR requests. Use `useState()` instead.

## Images

- Use `<NuxtImage>` for optimized loading (lazy, responsive sizes, format negotiation).
- Always set explicit `width` and `height` attributes to prevent layout shift.
- Use WebP with fallbacks where supported.

## TypeScript

- Generate API response types from the Laravel backend (API Resources define the contract).
- Keep types in `shared/types/` so both client and server routes can use them.
- Use `satisfies` over `as` for type assertions — it preserves inference.
- Import types with `import type { ... }` — never import runtime values for type-only usage.

## Styling

- **Design tokens** defined once via Tailwind v4's `@theme` in the main CSS file. This is the single source of truth for colors, spacing, and typography.
- **`@apply` sparingly** — only in Base component `<style>` blocks when wrapping raw HTML. Repeated utility patterns → extract a component, not a CSS class.
- **`<style scoped>`** on all components. No unscoped styles except the global design token layer.
- **Tailwind classes live in templates**, not extracted into CSS unless inside a Base component.