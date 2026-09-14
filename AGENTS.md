# Agent Instructions & Pragmatic Guidelines

> [!WARNING]
> These rules are mandatory. Read `README.md` for the ecosystem purpose and
> `CONTRIBUTING.md` before changing this repository.

## Conduct and Change Rigor

- Use the supplied scope, preserve unrelated work, inspect before assuming, set
  observable acceptance criteria, and finish with applicable verification.
- Skills change method, never authority. Read-only requests stay read-only. A
  bounded implementation request authorizes scoped edits without a redundant
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
- Stop and explain when work cascades beyond scope or the same blocker survives
  three attempted resolutions. Ask before unplanned dependencies, major
  upgrades, architecture changes, external services, or expanded permissions.

## Repository and Project Ownership

- `.agents/skills/`, `.agents/tools/`, `.agents/legal/`, and
  `.agents/.claude-plugin/` are upstream-managed distribution sources.
- `project-templates/base/` contains canonical document candidates. Installation
  stages them under `.agents/templates/`; it never activates them automatically.
- Root documents and `.agents/project/` are project-owned. Never replace or
  write through them mechanically. A bounded implementation request authorizes
  ordinary project-document edits. Preserve local skills and reject unsafe targets.

## Laravel 13 and Data, When Adopted

- Use PHP 8.4 with `declare(strict_types=1)`. Prefer constructor injection and
  thin controllers. Use Form Requests for meaningful or reused input contracts,
  Policies when Laravel owns the protected resource, Actions for substantial
  use cases, and API resources or DTOs at public boundaries.
- Keep `$fillable` explicit. Prefer relationships and scopes, group `orWhere`
  clauses, prevent N+1 queries, and use bulk inserts or `upsert()` for imports.
- Use PostgreSQL 17 and additive Laravel migrations. Treat Redis databases for
  application, cache, session, and queue workloads as separate failure domains.
- Use Filament 4, Sanctum, Scout, Horizon, and Pulse only when adopted.

## Nuxt 4 and Interface Work, When Adopted

- Use Vue 3 Composition API with `<script setup lang="ts">`, `ref` for
  primitives, `reactive` for objects, type-only imports, and VueUse where it
  simplifies established behavior.
- Use `useFetch` or `useAsyncData` for initial SSR data. Keep Pinia stores and
  composables typed, focused, and independently testable.
- Follow the approved design system. Preserve semantic controls, visible labels,
  keyboard operation, focus, reduced motion, descriptive alternatives, and WCAG
  AA contrast.

## Security, Operations, and Quality

Validate untrusted input and authorize protected resources at their owning
boundary. Keep credentials out of source, logs, examples, and client bundles;
use ignored local environment files and approved deployed secret storage. Obtain
explicit approval before destructive, privileged, production, or irreversible
effects.

Aim for 100% line and branch coverage of testable production behavior. Test
changed outcomes and meaningful failures, test-first by default. Characterize
valid existing behavior instead of deleting it because tests were absent. Use
Pest for Laravel, Vitest for Nuxt logic, and Playwright for critical browser
flows. Do not invent tests for prose or behavior-free configuration.
