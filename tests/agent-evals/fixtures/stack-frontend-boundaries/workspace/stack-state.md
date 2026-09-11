# Frontend stack state

The project uses Nuxt 4, Vue 3.5, Pinia 3, Vite 8, Vitest 5 with Vue Test
Utils, and Playwright. Catalog data is needed in the server-rendered page and
should use Nuxt's SSR-aware data utilities rather than a mounted-only request.

The component destructures `pageSize` from `defineProps` under Vue 3.5 and uses
it in a computed value. A form draft is used by one component only and does not
need a global store. The project has a working `vite.config.js`; converting it
to TypeScript is outside the requested behavior.

One Vitest component test must dispatch a raw browser input event that the installed
`user-event` version cannot express. The test can use `fireEvent` for that
specific low-level contract and continue using `userEvent.setup()` for normal
typing and clicks.

One Playwright flow interacts with a third-party canvas. The widget exposes no
accessible node or supported test identifier and its vendor markup cannot be
changed. The proposed fallback is a locator scoped to the widget root and a
documented stable structural attribute, not a generated class or positional
index.
