# Development Workflow

## Delivery Contract

These values govern `wrap` and `release`; skills never expand authority.

| Field | Adopted value |
|---|---|
| Default branch and integration | `master`; `feature/*`, `fix/*`, or `hotfix/*` branches integrate through a GitHub pull request using a merge commit. Do not use `staging` unless later adopted. |
| Gates | Run `bash tests/run.sh`, require the pull-request **Offline deterministic** check on the exact head, and obtain human review. This is project policy; GitHub host enforcement exists only when confirmed by current branch-protection or required-check evidence. |
| Release relevance | Consumer-visible managed skills, installers, candidate templates, plugin behavior, or stable install/update contracts require a release. Tests, plans, evidence, and internal bookkeeping alone are not release-relevant. Batching or deferral requires an explicit decision. |
| Version and preparation | SemVer. Synchronize `VERSION`, plugin/marketplace metadata, stable documentation, and release notes in the reviewed change. |
| Publication and verification | After integration, publish an immutable Git tag and GitHub release bound to the verified `master` merge SHA; verify the peeled remote tag and release metadata. |
| Deployment coupling | Not applicable: repository release has no adopted application-deployment trigger and does not authorize deployment. |
| Checkpoint and terminal evidence | The delivery actor owns a dedicated secret-free GitHub PR comment as checkpoint; create/update is a distinct provider effect needing exact authority. Release record proves completion, not partial state. Select one terminal cutoff: evidence PR merge if used, otherwise the verified content-bearing PR merge. Keep the tracker current through handoff publication; later identity/cleanup stay external. Reconcile refs and task context before publication. |
| Recovery and cleanup | Never repeat an ambiguous effect before inspecting remote state. Retain recovery state after partial publication. Delete owned local/remote branches and worktrees only after verified integration and terminal release, with merge-method-appropriate proof and no unique work or unrelated dirt. |

Use imperative commit subjects within 72 characters; keep WIP off shared
branches and preserve unrelated work.

## Change Rigor

Use `.agents/skills/review/references/change-rigor.md`:

- **R0 — read-only:** inspect and report with no repository or external writes.
- **R1 — ordinary:** make reversible in-scope repository changes under an
  implementation request, preserving unrelated work and verifying outcomes.
- **R2 — elevated:** before destructive, privileged, secret/permission,
  production/shared-state, publication, or irreversible effects, confirm the
  exact target, scope, exposure, credentials, and recovery.

The highest trigger wins. Skills change method, never authority. Approved
implementation needs no second kickoff. Ask before unplanned packages,
replacements, major upgrades, licensing concerns, services, or permissions.

## Verification

Run the real checks for adopted components. Aim for full line and branch
coverage of testable behavior; test changed outcomes and meaningful failures
first. Do not invent tests for prose, generated artifacts, declarative
configuration, or trivial forwarding.

Use `review` normally. Reserve deep and independent review for R2, significant
architecture/security/data/production work, or explicit requests.

Use additive migrations. Back up non-recreatable data before approved
destructive work and prove rebuilds for disposable data. When adopted, document
Forge, PM2, and Cloudflare environments, triggers, rollback, and ownership from
executable evidence.
