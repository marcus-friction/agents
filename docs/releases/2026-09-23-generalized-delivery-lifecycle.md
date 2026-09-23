# v1.9.0 — Generalized delivery lifecycle

Release date: 2026-09-24. Use the full commit SHA from the
[release record](https://github.com/marcus-friction/agents/releases/tag/v1.9.0)
with installer `--ref` for stable installation. `master` remains mutable.

Delivery is now an explicit provider-neutral lifecycle rather than an implied
commit-and-push finish. A generic `wrap` prepares the complete read-only path
through atomic commits, change-request integration, applicable release,
deployment triggers, and safe cleanup while preserving a separate authority
gate for every external or destructive effect.

The new `release` skill owns complete-unreleased-set discovery, SemVer and
artifact preparation, immutable publication, partial-state recovery, and
post-publication verification. GitHub mechanics remain optional adapters, and
repository release never silently authorizes application deployment.

Projects define their delivery variables in active `CONTRIBUTING.md`, including
the default branch and merge method, exact checks, release relevance, version
artifacts, deployment coupling, durable checkpoint, terminal-evidence cutoff,
and cleanup proof. The canonical candidate documents carry the same structure
without mechanically replacing project-owned policy.

Durable checkpoints are secret-free, bind every effect to exact repository and
provider identities, and never carry authority into a fresh context. Target
drift causes full recomputation; timeouts and partial publication require
read-only reconciliation before any retry. Cleanup remains blocked until
integration is proven and release reaches a terminal state.

The offline deterministic suite registers 66 live-agent cases and adds direct
coverage for preview-only authority, exact commit and integration routing,
automatic releases and branch deletion, stale targets, hostile checkpoints,
provider timeouts, secret non-disclosure, partial publication, terminal release
states, and merge-method-aware cleanup. Focused live evaluation also verified
the final authority and recovery boundaries against the v1.8.0 comparison.

Existing installations are not changed automatically. Edge installations can
update from `master`; stable installations should adopt the full immutable SHA
published in the v1.9.0 release record.
