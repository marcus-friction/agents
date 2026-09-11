---
name: migrate-project
description: Plan a legacy rewrite or migration into the project's adopted target components while preserving domain behavior and data. Use whenever the user asks to rewrite, port, or migrate an existing application, script, or service.
---

# Migrate Project

Recover behavior and data before choosing replacement technology. Produce an
actionable plan; do not scaffold or mutate the legacy system unless separately
asked.

## 1. Discover the legacy system

Use targeted search rather than reading whole trees. Inventory:

- manifests, runtime versions, entry points, routes, and public contracts;
- domain models, schemas, migrations, queries, and stored data;
- identity, sessions, authorization, secrets, and trust boundaries;
- UI flows, accessibility behavior, assets, and design rules;
- scheduled work, queues, caches, email, integrations, and failure handling;
- startup, deployment, monitoring, backup, and recovery evidence;
- tests and representative production behavior.

Distinguish observed behavior, declared intent, unresolved conflicts, and
obsolete implementation detail. Protect the legacy system as the behavioral
oracle; do not assume framework conventions express its real contract.

## 2. Select target components

Read project-owned `AGENTS.md`, `README.md`, `CONTRIBUTING.md`, and
`ARCHITECTURE.md`; load `DESIGN.md` only for UI scope. Classify every target
component Adopted, Optional, Not applicable, or Unresolved.

Laravel 13/PHP 8.4, Nuxt 4/Vue 3, PostgreSQL 17, Redis, Laravel Sail,
caching, background work, search, and email are preferred only when their
components are adopted. Preserve an established alternative unless replacement
is part of the approved migration. Filament, Meilisearch, Forge, PM2, and
Cloudflare remain optional until the accepted migration needs them.

Map identity establishment, browser-session ownership, token or claim exchange,
and authoritative resource authorization separately. Laravel Sanctum, Policies,
session cookies, and API tokens are options only when the relevant flow is
adopted; they are not a mandatory bundle.

Record boundary assurance for exposure, data impact, privilege, reversibility,
control owner, and evidence. Keep deployment unresolved unless migration
success requires it and the owner decides it.

## 3. Preserve behavior and data

Build a parity matrix from each legacy behavior and contract to its target,
verification, and disposition. Include edge cases, failure behavior, permissions,
background work, and operator workflows.

For material data, define schema mapping, repeatable extraction, validation,
transformation, loading, reconciliation, cutover, backup, and recovery. Use
versioned Laravel migrations when Laravel owns the adopted database schema. For
disposable data, prove the rebuild path instead of inventing backup ceremony.

Keep old and new schemas or contracts compatible across the actual rollout
window. Use dry runs and counts/checksums or domain invariants appropriate to the
data. Never claim rollback after an irreversible transformation.

## 4. Plan the accepted migration increment

Follow the `plan` workflow. Include:

- legacy inventory and parity matrix;
- adopted target map and dependency direction;
- data and trust-boundary flows;
- incremental slices with explicit entry/exit criteria;
- compatibility, coexistence, cutover, and recovery;
- tests that compare observable legacy and target behavior;
- Pest coverage for Laravel behavior and Vitest coverage for Nuxt/Vue logic
  when those components are adopted;
- performance and operational evidence;
- file-level scope, exclusions, risks, and verification commands.

Plan the complete accepted increment, which may be one vertical migration slice;
do not force a big-bang rewrite or absorb unrelated components.

Use `review-plan` to convergence. Apply security, architecture, accessibility,
and performance reviews only when their boundaries are relevant. Stop after
presenting the plan and tasks; execution needs the user's implementation request
or accepted plan.
