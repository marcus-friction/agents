---
name: wrap
description: Complete and report an accepted increment, and when the user explicitly asks to wrap, commit, push, integrate, or finish delivery, prepare a provider-neutral lifecycle preview through release and safe cleanup. A generic wrap is read-only for Git and external effects; every mutation requires separate exact authority.
---

# Wrap

Close the accepted increment and coordinate its delivery. A wrap is ready only
when the workspace, knowledge, documentation, and quality gates are resolved and
the project's active delivery contract has been applied.

## Trigger and authority

Use for an explicit wrap, commit, push, integration, or delivery-completion
request. A status request, implementation completion, context switch, or bare
"do not commit or push" does not trigger it. "Wrap this up, but do not commit or
push" does trigger local completion while excluding those effects.

Skills change method, never authority. Invocation alone grants no Git, hosting,
release, deployment, or cleanup authority. Repository initialization is also a
Git effect. A generic wrap may finish bounded local cleanup, knowledge, and
documentation created in the accepted task, then prepare a complete read-only
lifecycle preview. Exact initialization, commit, push, integration, release,
deployment, and deletion requests authorize only the named effects and scope.
One exact batch decision may cover fully disclosed future effects while
their target, scope, exposure, credentials, recovery, reviewed identities, and
trigger coupling remain unchanged.

Treat unknown pre-existing work as read-only. If scope, destination, release
policy, or cleanup ownership is unresolved, inspect and preview rather than
guessing.

## Workflow

### 1. Establish readiness and inventory

Use Git for repository operations. Read [Git setup](references/git-setup.md)
when Git, a repository, remote capability, or authentication is missing. A
provider adapter is optional; never substitute an unadopted host.

Read repository instructions and inspect status, relevant diffs, branch,
worktrees, remotes, and active `CONTRIBUTING.md` without exposing secrets.
Classify every changed path as accepted work, intentional retained artifact,
unrelated preserved work, or cleanup candidate. A generic wrap may remove only
disposable artifacts created in this task; other uncommitted deletion needs
exact authority.

Before any commit or publication preview, inspect every accepted path with a
redaction-safe credential and sensitive-artifact check, including tracked and
untracked environment files, tokens, signing material, and hook URLs. Check
presence and classification without printing values. Block the affected commit,
push, integration, and release while sensitive content or ownership is
unresolved; never include it merely because the path was accepted.

When accepted uncommitted work starts on the adopted default branch but policy
requires reviewed topic-branch integration, preview exact topic-branch creation
before commit. Do not commit directly to the default branch or move unrelated
work implicitly; block when worktree state prevents a safe branch operation.

### 2. Resolve completion and delivery contracts

`required`, `update required`, and `unresolved` are pending states.

| Gate | Resolved dispositions | Pending when |
|---|---|---|
| Workspace | Every path is accepted, retained, preserved, or approved cleanup is complete | A path or cleanup owner is unexplained |
| Knowledge | `already captured`, `not applicable`, or `declined by user` with reason | A High-rated learning is uncaptured and not declined |
| Documentation | `current` or `no impact` with reason | An affected source of truth needs an update |
| Quality | Applicable verification and review are known | A required check or finding is unresolved |
| Delivery | Integration, release, deployment coupling, checkpoint/evidence, and cleanup values are explicit | A material field is missing or contradictory |

`compound` owns the knowledge rating; do not duplicate its eligibility rule.
During an explicit wrap, capture an
authorized High-rated learning or record an explicit decline. Medium and Low
resolve as `not applicable` with rationale. Check affected documentation and run
normal in-scope verification; never claim evidence that did not run.

Discover the delivery contract from active project evidence. It must identify
the default branch, integration route and method, required checks/review,
release relevance and preparation/publication policy, deployment trigger
coupling, durable checkpoint and terminal-evidence cutoff, and safe cleanup
rules. `Unresolved` is a result, not permission to invent a default.

### 3. Assess release and prepare the preview

Route release relevance and mechanics to the `release` skill. It owns the
complete unreleased change set from the last applicable release boundary,
pre-integration artifacts, post-integration publication, verification, and
partial-state recovery. If unresolved release preparation could change reviewed
content, block integration.

Route detailed references by requested work, including exact-effect requests:

- For every commit or push preview or execution, read Git handoff completely:
  [reference](references/git-handoff.md).
- For any change-request, integration, drift, or cleanup work, read integration
  and cleanup completely: [reference](references/integration-and-cleanup.md).
- Before any external effect or when resuming from recorded state, read delivery
  checkpoints completely: [reference](references/delivery-checkpoints.md).
- For a confirmed provider, read its provider adapter before provider inspection
  or mutation. GitHub uses the [GitHub adapter](references/github.md).

For every generic wrap where the user did not explicitly exclude both commit
and push, read [Git handoff](references/git-handoff.md) completely after every
completion gate is resolved. Also read
[integration and cleanup](references/integration-and-cleanup.md) and
[delivery checkpoints](references/delivery-checkpoints.md). Prepare its exact
read-only preview of atomic commit groups, proposed Conventional Commit
messages, reviewed paths or hunks, and the complete lifecycle:

- topic-branch creation when required, kept distinct from branch publication;
- branch publication and change-request destination;
- integration target, method, review, and checks;
- release disposition, artifacts, immutable identity, and verification;
- any release, deployment, or provider-managed destructive cleanup trigger
  caused by integration, tagging, or release;
- recovery checkpoints and exact cleanup candidates with proof.

Then ask once which Git effects to execute and which later delivery effects the
same exact batch should cover. A project may use an exact batch decision, but
materially changed facts require a new decision.
Explicitly disclose automatic production/shared-state effects before their
trigger; release authority never implies deployment authority.

### 4. Execute only authorized effects

Immediately before each effect, revalidate its exact repository, account,
source and target refs, reviewed head/base, checks, credentials, exposure,
trigger coupling, and recovery. Record completed or ambiguous effects in the
adopted secret-free checkpoint. Stored authority is historical evidence only.

After any target/base drift, recompute the complete unreleased set, release
artifacts, checks, automatic triggers, cleanup proof, and affected authority.
Stop on stale checks, ref mismatch, rejected publication, identity collision,
ambiguous timeout, or partial release; inspect state before retrying. Never
force, rewrite published history, move an existing release tag, or repeat an
effect whose outcome is unknown.

Cleanup starts only after verified integration and a terminal release state:
`complete`, `deferred by adopted policy`, or `not applicable` with reason. Use
merge-method-appropriate proof and preserve unique unintegrated content,
unrelated dirt, unowned worktrees, and partial recovery state.

### 5. Report

Use these stable fields:

```text
Workspace: <accounted paths and local cleanup>
Knowledge: <disposition and artifact, if any>
Documentation: <disposition and changed sources>
Quality: <tests, review, checks, and unavailable evidence>
Commits: <hashes/subjects or preview/not done>
Integration: <source/target, request, method, checks, revision, or disposition>
Release: <disposition, version/tag/release identity, verification, or recovery>
Cleanup: <completed, retained, blocked, and proof>
Preserved: <unrelated work and recovery state>
```

Facts created after the selected terminal repository handoff live in the
adopted external evidence and final report. Do not create recursive bookkeeping
commits; a remediation after the cutoff is a new tracked increment.
