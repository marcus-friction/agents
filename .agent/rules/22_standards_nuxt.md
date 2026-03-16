---
trigger: model_decision
description: Apply when writing, reviewing, or modifying Nuxt/Vue frontend code (components, composables, pages, Pinia stores, Tailwind styling).
---

# Nuxt Standards

## Core Architecture
- **Structure:** `app/` (UI), `server/` (API/backend), `shared/` (types/utils).
- **Vue Syntax:** Use `<script setup lang="ts">` exclusively. No Options API.
- **Nuxt-First:** Always use built-ins (e.g. `<NuxtLink>`, `<NuxtImage>`, `useFetch`, `useState`) and auto-imports before custom wrappers or manual imports.
- **State:** Use Pinia for global state (setup syntax). Use `useState()` for ephemeral SSR-safe page state.

## Components
- **Base Components:** Reside in `app/components/base/`, prefixed `Base`. Only these contain raw Tailwind design tokens/colors. Use for UI primitives.
- **Feature Components:** Compose Base components and domain logic. Avoid duplicating Base component capabilities.
- **Rules:** Define props via generic `defineProps<{}>()` + `withDefaults()`. Define events via `defineEmits<{}>()`. Never mutate props. Use `<style scoped>` and place structural Tailwind classes inline.
- **Refactoring:** Extract component if >300 lines. Extract Tailwind class strings if >80 chars. Use `tailwind-merge` for dynamic classes.

## Composables & Logic
- **Composables:** Prefix with `use`. Return refs. Handle side-effect cleanup on unmount. Pass options object if 4+ parameters.
- **Data Fetching:** Use `useFetch` / `useAsyncData` against the server proxy. Never hit Laravel API directly from client.
- **Error Handling:** Use `useError()`/`createError()`. Wrap sections in `<NuxtErrorBoundary>`. Always handle the `error` ref from `useFetch`. Use inline feedback, **no toasts**.

## SSR Reliability
- **Browser APIs:** Wrap `window`, `document`, `localStorage` in `onMounted()` or `<ClientOnly>`.
- **Hydration:** Generate IDs with `useId()`. Do not generate random values at render time.
- **Lifecycle:** Use `onBeforeMount`/`useAsyncData` for SSR logic. `onMounted` is client-only.
- **State Leaks:** Never use module-level mutable variables. Always use `useState()`.

## Assets & Styling
- **Images:** `<NuxtImage>` strictly. Define explicit `width`/`height` to avoid CLS. 
- **Styling:** Design tokens defined once via Tailwind v4 `@theme` in main CSS. Use `@apply` very sparingly (only inside Base components).
- **TypeScript:** Generate response types from Laravel API Resources. Place in `shared/types/`. Import using `import type`. Use `satisfies` over `as`.

## Naming
- **PascalCase:** Components (`UserCard.vue`, `<UserCard />`), Types/Interfaces.
- **camelCase:** Composables (`useAuth`), Pinia Stores (`useAuthStore`), Variables.
- **kebab-case:** Pages (`user-profile.vue`).