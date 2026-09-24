# Development Workflow

> [!WARNING]
> This inactive candidate becomes policy only through evidence-backed
> reconciliation. Replace every `Unresolved` with evidence, `Not applicable`
> plus a reason, or an owner decision in the active project document.

## Delivery Contract

| Field | Adopted value |
|---|---|
| Default branch and integration | Unresolved: record the branch, topic naming, change-request/direct route, and merge/squash/rebase method. Do not assume `staging` unless adopted. |
| Gates | Unresolved: name local checks, exact-head host checks, and review. Distinguish project policy from GitHub or other host enforcement, which exists only when confirmed by current evidence. |
| Release relevance | Unresolved: define consumer-visible changes, exclusions, batching, and deferral ownership. |
| Version and preparation | Unresolved: define the version scheme and reviewed files/artifacts that must change before integration. |
| Publication and verification | Unresolved: define the provider/registry mechanism, immutable integrated target, verification, and owner. |
| Deployment coupling | Unresolved: state every integration/tag/release trigger, or `Not applicable`; repository release does not authorize deployment. |
| Deployment prerequisites and intervention | Unresolved: authoritative routing point. For each prerequisite record environment/target; category/owner; variable or setting name only, sensitivity, and secure configuration location; manual action/reason; exact blocked effect, consequence, and required before timing; associated scripts (build/deploy/start/migration); safe verification/evidence owner; non-secret resume signal; recovery. Linked inventories must retain trigger/blocked effect, owner, verification, resume, and recovery routing here. With no target, record `Not applicable` plus reason. |
| Checkpoint and terminal evidence | Unresolved: before delivery select a secret-free checkpoint, its checkpoint owner, exact durable location, and whether creating/updating it is a separately authorized effect; also select either the content-bearing handoff or one evidence-only handoff as cutoff. Keep the tracker current through its preparation/publication; its later verified identity and cleanup stay external. |
| Recovery and cleanup | Unresolved: define partial-state recovery and merge-method-appropriate proof for owned remote branches, local branches, and worktrees. |

Preserve unrelated work. Use imperative commit subjects within 72 characters
and keep WIP commits off shared branches.

## Change Rigor

Use `.agents/skills/review/references/change-rigor.md`:

- **R0 — read-only:** inspect and report with no repository or external writes.
- **R1 — ordinary:** make reversible in-scope repository changes under an
  implementation request, preserving unrelated work and verifying outcomes.
- **R2 — elevated:** before destructive, privileged, auth/privacy/secret/
  permission, production/shared-state, publication, or irreversible effects,
  confirm the exact target, scope, exposure, credentials, and recovery.

The highest trigger wins. Skills change method, never authority. Approved scope
needs no second kickoff. Ask before unplanned packages, replacements, major
upgrades, licensing concerns, services, or expanded permissions.

## Tests, Review, and Data

Run real checks for adopted components: Larastan/Pint/Pest for Laravel,
ESLint/type-check/Vitest/build for Nuxt, and Playwright for changed critical
browser flows. Aim for full coverage of testable behavior and test changed
outcomes first. Do not invent tests for prose, generated artifacts, declarative
configuration, or trivial forwarding.

Use `review` normally; reserve deep independent review for R2, significant
architecture/security/data/production work, or explicit requests. Use additive
migrations, protect non-recreatable data, and document adopted environments,
triggers, rollback, and ownership from executable evidence.
