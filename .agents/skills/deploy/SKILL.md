---
name: deploy
description: Prepare, deploy, verify, and troubleshoot Laravel and Laravel + Nuxt applications on Laravel Cloud using the official Cloud CLI. Use for a first deployment, redeployment, Cloud readiness check, or failed Cloud release; also when deploy is explicitly requested. Preserve read-only requests and existing hosting choices; do not route unrelated providers into Laravel Cloud.
---

# Deploy

Take the application from its current repository state to a verified Laravel
Cloud release with as few user decisions as the evidence permits. Support
Laravel-only applications and Laravel + Nuxt in monorepos or separate repos.

## Establish the requested outcome

Distinguish checking readiness, preparing changes, deploying, and diagnosing a
failure. Read-only checks and diagnosis authorize inspection and a report, not
fixes or remote mutations. A preparation or deployment request authorizes
ordinary in-scope local work; invocation alone does not authorize paid resources,
publication, production changes, dependencies, or data migration.
Repository release does not authorize deployment. When an integration, tag, or
release automatically triggers Cloud, disclose and authorize the actual
production/shared-state effect before causing that trigger.

Read project instructions, adopted architecture, deployment docs, manifests,
lockfiles, Git state, and existing CI. Preserve documented hosting and unrelated
work. If Cloud has not been selected, recommend the appropriate path and resolve
that choice before preparing provider-specific changes. A migration from an
existing host needs an explicit migration scope; keep that host intact.

Load [Cloud operations](references/laravel-cloud.md) for CLI, configuration and
resources; [Laravel + Nuxt](references/laravel-nuxt.md) when Nuxt is present;
and [verification and recovery](references/verification-and-recovery.md) before
a release or when diagnosing one. Use current official docs and installed CLI
help for capabilities that change. Report unavailable evidence honestly.

## Inspect and recommend

Discover rather than ask the user to enumerate:

- Laravel/Nuxt roots, framework and runtime versions, package managers, build
  scripts, rendering mode, and shared build dependencies;
- database version/extensions, uploads, sessions/cache, authentication, queues,
  scheduler, mail, search and WebSockets actually used;
- Git remotes, deployable revisions, CI checks, Cloud organization, applications,
  environments, domains, resources and pending configuration when accessible.

Read environment variable names and configuration consumers without dumping
secret values. Do not upload a local `.env` wholesale. Never put credentials in
chat, command arguments, source, logs, or public frontend configuration.

Recommend the smallest complete setup. Retain the project's versions; our
default stack is Laravel 13/PHP 8.4, Nuxt 4 and PostgreSQL 17, not permission to
upgrade an existing project. Verify offered database versions/extensions instead
of silently substituting one. Include both apps and all required resources in
the cost estimate, with current pricing, region, usage assumptions and scaling
limits. Ask only for unresolved choices that affect the result, such as the
organization, region, budget or owned domain.

## Prepare a reviewable deployment

When local edits are in scope, prepare the needed settings and compatibility
fixes, then run the project's applicable checks. Preserve SSR, queue semantics,
authentication ownership and existing resource choices. If a new dependency,
service, major upgrade or architecture change becomes necessary, finish the
unaffected preparation and present that concrete decision before adopting it.

Prepare a compact deployment record in the project's existing location (or
`docs/deployment.md` when document writes are authorized). For read-only work,
keep it in the response. Record:

- each app/root, organization and environment ID, region and intended revision;
- build/start/deploy settings, variable names and their owners, resource links
  without credentials, domains and deployment trigger;
- checks, release order, expected costs and exposure, data impact, recovery
  target and owner; distinguish proposed settings from applied settings.

Before external effects, obtain or reuse the exact authorization covering
target, action, scope, exposure, credential class and recovery. Present missing
authorization as one concrete batch where possible. Account/billing setup and
Git-provider access may need a short user handoff. Do not repeat approval for
unchanged facts. Revalidate targets, staged settings and material evidence
immediately before acting; changed facts invalidate only affected authorization.

## Deploy and verify

Use an existing official Cloud CLI installation and explicit application and
environment targets. Inspect state before creating resources or repeating a
command. An ambiguous timeout may mean the remote operation succeeded.

For a first deployment, configure only approved resources/settings, deploy,
and record the resulting IDs. Use the guided `ship` command only when its full
set of effects is understood and authorized. For repeat deployments, compare
the recorded setup with remote state, review all staged settings, and release
the intended tested revision. Committing and pushing require their own existing
authorization; uncommitted work is not part of a Git-based Cloud deployment.

Monitor each deployment to a terminal state. For Laravel + Nuxt, track both
applications and verify their integration; they are independent deployments.
Use [verification and recovery](references/verification-and-recovery.md) for
health, authentication, resources and partial failures. A failed test authorizes
only fixes already within scope. Diagnose before retrying; stop and explain
when the same blocker survives three attempted resolutions.

Finish with URLs, deployed revisions and deployment IDs, checks actually run,
remaining failures or unverified behavior, and the next release/recovery method.
Update the deployment record when authorized. Report partial deployment as
partial; do not call an application verified solely because the build passed.
