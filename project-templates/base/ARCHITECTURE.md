# Architecture

> [!WARNING]
> This inactive candidate must be reconciled with repository evidence and
> approved intent. Do not replace an existing architecture or activate optional
> components mechanically.

## Decision Model

Classify every component independently:

| Status | Meaning |
|---|---|
| **Adopted** | Required by approved scope and the current or intended architecture. |
| **Optional** | Preferred if the capability becomes necessary; not active now. |
| **Not applicable** | Outside the accepted project scope. |
| **Unresolved** | A material decision is missing; do not invent or implement it. |

Cite executable repository evidence for current state and owner confirmation
for intent. An established alternative remains valid until its replacement is
approved.

For each affected trust or data boundary, record assurance separately from
component status:

| Exposure | Data impact | Privilege | Reversibility / availability | Control owner | Evidence |
|---|---|---|---|---|---|
| local, private/internal, public | disposable, internal, sensitive, regulated-confirmed | anonymous, authenticated, privileged, service identity | recreatable, recoverable, material, critical | application, edge, identity provider, external service, unresolved | path, configuration, or owner decision |

Keep materially different boundaries in separate rows. Missing facts remain
unresolved; they do not become a project-wide security label.

## Preferred Full-Stack Shape

For a project adopting the full ecosystem:

```text
Browser -> Cloudflare -> Nuxt 4 SSR (PM2) -> Laravel 13 -> Actions/Services
                                                       -> Eloquent -> PostgreSQL 17
Admin   ----------------------------------------------> Filament 4
                                      Redis <- cache / sessions / queues
```

Remove absent arrows and add verified integrations. Do not document a fictional
full stack.

| Capability | Preferred architecture | Boundary |
|---|---|---|
| Web interface | Nuxt 4, Vue 3, TypeScript, Tailwind CSS 4, Pinia | SSR by default; hydrate the smallest interactive boundary. |
| Server routes | Nitro when the web layer owns the endpoint | Keep presentation concerns separate from Laravel domain policy. |
| Application API | Laravel 13 on PHP 8.4 | Controllers translate transport; Actions or services own use cases and transactions. |
| Admin | FilamentPHP 4 | Reuse Laravel authorization and domain boundaries. |
| Primary data | PostgreSQL 17 with additive Laravel migrations | Eloquent models own persistence mapping; contracts do not expose accidental internals. |
| Search | Scout with Meilisearch after database search is insufficient | Treat indexes as derived and record rebuild behavior. |
| Identity | Sanctum or an approved alternative | Record where identity is established and sessions or tokens are owned. |
| Authorization | The resource-owning server; Laravel Policies and Gates when Laravel owns the resource | Keep one authoritative policy owner. |
| Caching | Laravel cache, then Redis and HTTP/edge caching as justified | Record source, key scope, invalidation, and privacy. |
| Background work | Laravel queues with Horizon when operationally useful | Enter through an approved use case and use an appropriate identity. |
| Email | Laravel Mail with approved transport and template strategy | Keep secrets server-side and make failure handling observable. |
| Local orchestration | Laravel Sail or Docker Compose | Bind private services to loopback or an approved private interface. |
| Observability | Telescope in development; Pulse and structured logs in production | Add metrics, traces, and alerts where exposure or availability justifies them. |
| Delivery | Forge for Laravel, PM2 for Nuxt SSR, Cloudflare at the edge | Record environment, trigger, rollback, and control ownership. |

Verify versions and scaffolding before adoption. Observed project versions stay
authoritative until an approved migration changes them.

## Boundaries and Dependency Direction

- Nuxt owns presentation, rendering, interaction, and browser-facing state.
  Each resource-owning server owns its domain use cases and durable
  authorization; Laravel owns those concerns only for Laravel-owned resources.
  Document any server-to-server trust handoff explicitly.
- When Nuxt consumes a Laravel API, keep one authoritative API contract.
  Generate or derive client TypeScript types and verify contract drift when
  that integration is adopted; do not maintain an independent handwritten
  model on each side.
- Controllers depend on application contracts. Domain and persistence code do
  not depend on UI or HTTP response types.
- Place transactions around atomic use cases. Do not make every service
  transactional or let external network calls extend database locks.
- Keep Eloquent relationships intentional, eager-load proven access paths, and
  paginate unbounded collections.
- Treat caches and search indexes as derived unless documented otherwise.
  Record their source, invalidation, isolation, and rebuild path.
- External adapters need an owner, timeout, retry or failure policy, and data
  contract. Record secret storage and access without storing secret values.

If Nuxt and Laravel share authentication, document one browser-to-service
handoff, cookie or token ownership, CSRF control, claim mapping, logout or
revocation behavior, and service identity. Avoid duplicate policy authorities.

| Authorization case | Authoritative boundary | Non-owner behavior |
|---|---|---|
| Nuxt/Nitro-owned resource | Authorize in the owning Nuxt/Nitro server handler or policy layer. | Laravel is not required. |
| Laravel-owned resource reached through Nuxt | Authorize with Laravel Policies or Gates before protected access. | Nuxt may establish or forward identity but does not duplicate domain policy. |

## Repository and Operations Evidence

| Path or component | Responsibility | Status | Evidence |
|---|---|---|---|
| `[path]` | `[verified responsibility]` | `[adopted / optional / not applicable / unresolved]` | `[manifest, source, or owner decision]` |

Record verified startup commands, listeners, dependencies, readiness, and owned
cleanup for local runtimes. Require enough logs and health evidence to diagnose
each adopted runtime. Back up material non-recreatable data before destructive
work; for disposable data, verify the rebuild path.

## Decisions and Open Questions

| Component or decision | Status | Evidence or rationale | Next decision |
|---|---|---|---|
| `[item]` | `[adopted / optional / not applicable / unresolved]` | `[path or owner confirmation]` | `[decision or none]` |
