# v1.7.0 (Unreleased) — Proportional Ecosystem Port

## Summary

The agent ecosystem now scales planning, approval, testing, and review to the
actual change while preserving its Laravel 13 and Nuxt 4 specialization. The
update also separates upstream-managed distribution assets from project-owned
documents so installation can refresh capabilities without silently changing a
project's policy.

## Changes

- Added the R0–R3 change-rigor model. Read-only work stays non-mutating, routine
  additive work remains direct, semantic changes receive proportionate review,
  and hazardous effects retain explicit decisions and revalidation.
- Separated component applicability, boundary assurance, and change rigor.
  Projects activate guidance only for adopted components and record evidence for
  security and operational controls.
- Added canonical candidates under `project-templates/base/`. Installation
  stages inactive copies under `.agents/templates/` and never creates, appends
  to, or replaces active root project documents.
- Removed the superseded root `README.template.md`; the canonical inactive
  README candidate now lives at `project-templates/base/README.md`.
- Defined managed-tree ownership for skills, tools, legal metadata, and provider
  adapters while preserving `.agents/project/` and local-only skill paths.
- Refined TDD around changed observable behavior and meaningful failure paths.
  The 100% line and branch coverage goal remains for testable production
  behavior without requiring ritual tests for prose or inert configuration.
- Added public-repository installation semantics, component-selective dependency
  planning, multi-tool skill discovery, immutable full-SHA support, concise
  document budgets, and an extended ecosystem reference.

## Preserved Specializations

Laravel 13, PHP 8.4, PostgreSQL 17, Redis, Filament 4, Sanctum, Scout,
Meilisearch, Horizon, Telescope, Pulse, Pest 4, Larastan, and Pint remain the
backend baseline. Nuxt 4, Vue 3 Composition API, Nitro, Pinia, Vite, Vitest,
VueUse, TypeScript, Tailwind CSS 4, and Playwright remain the frontend baseline.
Sail, Forge, PM2, and Cloudflare remain the preferred adopted delivery path.

The port excludes source-specific framework skills, cloud assumptions,
private-source authentication, branding, and captured evaluation evidence.
Existing multi-agent review skills remain and align with the new report-only
and proportional-review semantics.

## Release Boundary

Version 1.7.0 names the integration but remains unreleased. This change does not
publish an immutable stable release, and `master` remains a mutable edge channel.
Audited installations may pin a reviewed full 40-character commit SHA; a future
stable release must identify its exact commit separately.

## Verification Contract

The integrated change should pass the offline repository suite, shell syntax and
portability checks, skill validation, document-budget checks, JSON validation,
and `git diff --check`. Consuming projects must still run their own Laravel,
Nuxt, and browser checks for adopted components.
