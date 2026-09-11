Read the complete Nuxt, Vue, Pinia, Vite, Vitest, and Playwright skills under
`{context_root}`, then inspect `{fixture_root}/stack-state.md`. This is a
read-only decision exercise. Do not modify files.

In `decisions`, set:

- `d1` to whether initial-render catalog data should use `useFetch` or
  `useAsyncData` for SSR-aware loading;
- `d2` to whether Vue 3.5 reactive props destructuring keeps `pageSize`
  reactive in the component;
- `d3` to whether the form's component-local draft must move into Pinia;
- `d4` to whether the working JavaScript Vite configuration must be converted
  to TypeScript for this increment;
- `d5` to whether `fireEvent` is categorically invalid for the unsupported raw
  input event; and
- `d6` to whether the scoped structural locator is acceptable as a documented
  last resort for the third-party canvas.

Return the registry case ID, those decisions, and a concise evidence summary.
