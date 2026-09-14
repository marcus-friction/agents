# Agent Instructions & Pragmatic Guidelines

> [!WARNING]
> This inactive candidate becomes project policy only through evidence-backed
> reconciliation.

## Conduct

- Use the supplied scope, preserve unrelated work, inspect before assuming, and
  define observable acceptance criteria. Finish with applicable tests, review,
  and documentation.
- Skills change method, never authority. Read-only requests stay read-only. A
  bounded implementation request authorizes scoped edits without another
  kickoff; testing alone never authorizes production mutation.
- Use `.agents/skills/review/references/change-rigor.md`: R0 is read-only, R1
  ordinary repository work, and R2 an elevated external or irreversible effect.
- Store plans at `docs/plans/<YYYY-MM-DD>-<slug>/implementation-plan.md` with a
  sibling `tasks.md`. During authorized work, update both files as work changes,
  before reporting progress or handing off.
- Append dated plan amendments for scope extensions and their rationale; obtain
  required approval. Add new tasks promptly, track actual status, and check off
  only verified completion. Tie progress reports to task items, blockers, and
  next steps.
- Review may update only an already-authorized matching tracker with actionable
  findings, never fixes. An explicit no-write instruction still controls.
- Stop and explain cascading work or a blocker that survives three attempted
  resolutions. Ask before unplanned dependencies, major upgrades, architecture
  changes, external services, or expanded permissions.
- Follow more specific nested `AGENTS.md` files within their scope.

## Sources of Truth

Read `README.md` for intent and `CONTRIBUTING.md` for delivery policy. Load
`ARCHITECTURE.md` when components or boundaries matter and `DESIGN.md` only for
interface work. Treat executable configuration as evidence of current behavior;
label intended and unresolved decisions.

Apply component rules only when `ARCHITECTURE.md` marks that component
**Adopted**. Optional and unresolved components are not implementation approval.
Preserve an established alternative unless its replacement is approved.

## Laravel 13 and Data, When Adopted

- Use PHP 8.4 with strict types and prefer constructor injection with thin
  controllers. Use Form Requests for meaningful or reused input contracts,
  Policies when Laravel owns the protected resource, Actions for substantial
  use cases, and DTOs or API resources at public boundaries.
- Keep `$fillable` explicit. Prefer relationships and scopes, group `orWhere`
  clauses, prevent N+1 queries, and use bulk insert or `upsert()` for imports.
- Use PostgreSQL 17 with additive Laravel migrations. Separate Redis databases
  for application, cache, session, and queue workloads.
- Use Filament, Sanctum, Scout, Horizon, Pulse, caching, queues, and email only
  when their capability is adopted and its ownership is recorded.

## Nuxt 4 and Design, When Adopted

- Use Vue 3 Composition API with `<script setup lang="ts">`, typed props and
  emits, `ref` for primitives, `reactive` for objects, and VueUse where useful.
- Use `useFetch` or `useAsyncData` for initial SSR data. Keep Pinia stores,
  composables, and Nitro handlers focused and independently testable.
- Follow `DESIGN.md` and established components. Preserve semantic controls,
  labels, keyboard operation, focus, reduced motion, responsive behavior, and
  WCAG AA contrast.

## Security, Operations, and Quality

Validate untrusted data at each trust boundary and authorize protected resources
where policy is owned. Keep credentials out of source, logs, examples, and
client bundles; use ignored local environment files. Deployed secrets use the
approved platform/runtime secret boundary. Require approval before destructive,
privileged, production, or irreversible operations.

External adapters need an owner, timeout, failure behavior, and data contract.
Material data needs recovery evidence; disposable data needs a verified rebuild
path. Use Sail, Forge, PM2, and Cloudflare only when adopted and evidenced.

Aim for 100% line and branch coverage of testable production behavior. Test
changed outcomes and meaningful failures, test-first by default. Characterize
valid existing behavior rather than deleting it because tests were absent. Use
Pest for Laravel, Vitest for Nuxt logic, and Playwright for critical browser
flows. Do not invent tests for prose or behavior-free configuration.
