# v1.10.0 — Deployment intervention handoffs

Release date: 2026-09-24. Use the full commit SHA from the
[release record](https://github.com/marcus-friction/agents/releases/tag/v1.10.0)
with installer `--ref` for stable installation. `master` remains mutable.

Deployment prerequisites now use one provider-neutral intervention contract
across `deploy`, `wrap`, and `release`. Every user-owned action has an explicit
state, and mixed actions aggregate deterministically: `required` takes
precedence over `unverified`, then verified `completed`; `none` applies only
when no user-owned action exists.

Required and unverified actions pause direct deployments and any integration,
tag, or release that would trigger deployment. The handoff identifies the exact
blocked effect, target, category, setting name, sensitivity, secure location,
owner, timing, scripts, consequence, safe verification, evidence owner,
recovery, and non-secret resume signal. Secret values are never requested or
recorded.

Active project `CONTRIBUTING.md` is the authoritative routing point for these
variables. The candidate template carries the complete schema while allowing a
larger linked inventory, and projects with no deployment target record an
evidence-backed `User intervention: none`.

Resolved state is re-evaluated immediately before every direct or automatic
trigger. Relevant target, configuration, script, or trigger drift invalidates
stale evidence. Intervention readiness remains separate from deployment and
release authority, so satisfying prerequisites never authorizes an external
effect.

The offline suite registers 75 live-agent cases. Nine deployment-intervention
scenarios cover missing secrets, automatic triggers, owner decisions,
repository adjustments, unavailable verification, drift, mixed action states,
verified completion, and evidence-backed absence of user work. Deterministic
probes reject empty, partial, collapsed, or secret-bearing handoffs.

This repository has no application-deployment trigger. Publishing v1.10.0 does
not deploy an application and requires no user-owned deployment prerequisite.
