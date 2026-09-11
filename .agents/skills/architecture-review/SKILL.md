---
name: architecture-review
description: Review code or plans when a change affects component boundaries, dependencies, contracts, data ownership, layering, or adopted project architecture decisions.
---

# Architecture Review

Review the approved change against the project's own `AGENTS.md`,
`ARCHITECTURE.md`, manifests, and executable configuration. Mark this pass not
applicable with a reason when no architecture boundary changes.

## Preflight

- Identify the reviewed paths and accepted scope.
- List affected components and their **Adopted**, **Optional**, **Not
  applicable**, or **Unresolved** status.
- Apply framework-specific rules only to adopted components.
- Protect published or consumed contracts. A private or pre-release breaking
  change is acceptable only when explicitly approved.
- Treat dependencies named with an exact purpose in the approved plan or direct
  request as approved. Escalate unplanned packages, replacements, major
  upgrades, licensing concerns, external services, and permission expansion.

## Boundaries

### Laravel, when adopted

- Controllers translate HTTP and delegate business behavior. Extract controller
  logic beyond the project's small transport boundary into `app/Actions/`.
- Prefer constructor injection for lifetime dependencies; allow method injection
  for a single container-invoked action or handler. Do not hide dependencies behind
  `app()`, `resolve()`, or ad hoc construction.
- Actions own use cases and atomic mutation boundaries. Models own persistence
  relationships, scopes, casts, and accessors rather than domain orchestration.
- Use Form Requests for meaningful or complex untrusted payloads, reused rules,
  request authorization, or an established convention. A small, one-off input
  may remain inline when the boundary is clear and testable.
- When Laravel is the resource-owning server, authorize protected resources
  through its Policies or Gates. Do not make Laravel a policy dependency for a
  resource owned by another server.
- Keep Eloquent models out of public contracts. Use API Resources or the
  repository's established response types when they provide an explicit output
  contract.
- Use relationships and scopes before raw queries, define `$fillable`, group
  `orWhere` clauses, and preserve additive Laravel migration history.
- Wrap external services behind an owned adapter with explicit timeouts and
  failure behavior.
- Follow the project's compatibility strategy for routes. Do not add a version
  prefix automatically.

### Nuxt and Vue, when adopted

- Use Vue 3 Composition API with `<script setup>` and TypeScript. Follow local
  conventions for `ref`, `reactive`, `import type`, and `satisfies`.
- Fetch initial SSR data with `useFetch` or `useAsyncData`; avoid client-only
  lifecycle fetching that creates hydration or duplicate-request behavior.
- Keep shared reactive behavior in composables, cross-component state in Pinia,
  and SSR-safe request state in the project's established Nuxt boundary.
- Keep secrets in private `runtimeConfig` and domain authorization at the
  resource-owning server. A Nitro proxy is not a second policy owner for a
  Laravel-owned resource, while a Nuxt/Nitro-owned resource is authorized in
  that server boundary without requiring Laravel.
- Prefer composition and existing state conventions. Refactor when behavior,
  cohesion, readability, or reuse reveals a boundary—not at an arbitrary prop,
  line, or class count.
- Follow the active Tailwind and component system. Reuse established primitives
  where they improve consistency; semantic HTML remains valid.
- Verify responsive and hydration behavior rather than prohibiting fixed values
  universally.

### Shared boundaries

| Case | Authoritative owner | Required control | Non-owner behavior |
|---|---|---|---|
| `nuxt-owned` | Nuxt/Nitro resource-owning server | Enforce domain authorization in the owning server handler or policy boundary. | Laravel is not required. |
| `laravel-owned` | Laravel resource-owning server | Enforce Policies or Gates before protected access. | Nuxt may establish or forward identity but must not duplicate domain policy. |

- Dependencies flow inward from UI and transport to application contracts;
  application and persistence layers do not depend on UI or HTTP types.
- Background work enters through an approved use case with an appropriate user
  or service identity.
- External integrations have an owner, timeout, failure policy, and data
  contract.
- Caches and indexes have a source, invalidation rule, and rebuild path.
- Identity establishment, browser sessions, service claims, and authoritative
  resource authorization have explicit owners; do not introduce duplicate
  policy authorities.
- Deployment decisions remain unresolved unless the approved scope and
  executable evidence establish them.

## Repository fit

Place new files in the repository's established module and test layout. Every
file should have a clear owner, but a review must not invent directories or
renames solely to match another ecosystem's convention.

Report each issue with the violated project decision, evidence, consequence,
smallest correction, and a concrete verification step.

## Parent review handoff

When invoked by the parent review, use its supplied finding contract and review
packet. Do not widen the accepted file set. Return either an evidence-backed
not-applicable reason or normalized findings with classification, severity,
confidence, exact location, violated decision, consequence, smallest
correction, verification, and pre-existing status.
