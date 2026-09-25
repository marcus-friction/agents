---
name: release
description: Prepare, publish, verify, and recover source or package releases when the user explicitly requests a release or wrap routes an adopted release disposition. Use for release relevance, version/artifact preparation, immutable publication, partial-state resume, and release verification. Invocation alone does not authorize publication or deployment.
---

# Release

Own release mechanics without assuming a provider, version scheme, registry, or
deployment platform. Repository integration and application deployment are
separate boundaries coordinated by `wrap`.

## Establish the release contract

Read active project instructions, `CONTRIBUTING.md`, version/manifests, prior
release identities, provider/registry evidence, and the intended integration
revision. Discover:

- release relevance and permitted batching or deferral;
- the last applicable release boundary and complete unreleased change set;
- versioning, preparation artifacts, publication mechanism, immutable target
  identity, verification, recovery, and owner;
- integration/tag/release triggers that automatically publish or deploy.

When integration, tagging, or publication can cause an automatic deployment,
load the provider-neutral [deployment
intervention](../wrap/references/deployment-interventions.md) contract. Resolve
its intervention state before the triggering effect; release state and release
authority do not resolve deployment prerequisites.

Do not hardcode SemVer, tags, hosted releases, GitHub, package registries, or a
default branch. Missing material policy is `unresolved`. When preparation may
alter reviewed content, integration is blocked until the decision and artifacts
are resolved.

## Classify the disposition

Use exactly one current lifecycle disposition:

- `required`;
- `deferred by adopted policy`, with the policy and boundary;
- `not applicable`, with an evidence-backed reason;
- `complete`, with verified immutable identity;
- `partial`, with completed/unknown/failed steps and recovery state;
- `blocked`, when a non-authority conflict or failed prerequisite prevents
  progression;
- `unresolved`, when project policy cannot decide safely.

When structured output requests the lifecycle disposition, emit exactly one of
those canonical tokens; do not substitute status synonyms such as `released`,
`success`, or `ready`.

Authority readiness is separate from lifecycle disposition: report it as
`authorized` or `not authorized` for the next exact effect. Missing authority
does not change `required` to `blocked`; it prevents progression while the
release remains `required`. A collision, failed prerequisite, or contradictory
identity may make the lifecycle disposition `blocked` even when authority was
granted.

Classify the complete unreleased change set, not only the latest commit or
current workspace. Include earlier integrated but unreleased work. If the target
or release boundary drifts, recompute relevance, version, artifacts, checks,
trigger coupling, and affected authority.

## Prepare before integration

When the adopted contract requires preparation, update only authorized version
files, manifests, lockfiles, notes, or generated artifacts and run their checks.
Keep preparation in the reviewed content. Do not invent a changelog, version,
registry, signing method, or release note format. Preparation never authorizes
commit, push, integration, publication, or deployment.

Before the prepared payload can cross a commit, registry, or release boundary,
require wrap's redaction-safe credential and sensitive-artifact gate. Block on
unresolved material without reading secret values into chat or logs.

## Publish after integration

Publish or trigger only after integration is verified, and bind every immutable
identity to the actual integrated revision. Immediately before the effect,
revalidate repository/provider/account, release name/version, target revision,
existing tags/releases/artifacts, credentials, exposure, automatic triggers,
recovery, and exact current authority.

When the effect triggers deployment, also re-resolve every intervention action
against the exact current target, configuration, scripts, trigger, and safe
verification evidence. Relevant drift invalidates stale `none` or `completed`
evidence. Rediscover actions and recompute the state; a verified empty inventory
returns `none`, while an incomplete assessment pauses the effect without
inventing a user action.

If integration itself automatically creates the release, observe and verify the
result rather than triggering it twice. If any step triggers production or
shared-state deployment, require separate exact deployment authority before the
triggering effect. Repository release authority is not deployment authority.
An automatic deployment with intervention state `required` or `unverified`
blocks the integration, tag, or release that would trigger it, even when release
publication itself is authorized. Surface the exact `USER ACTION REQUIRED`
handoff and resume only after safe verification reaches `completed` or evidence
supports `none`.

Use an adopted provider adapter where available; load
[GitHub publication](references/github.md) only for confirmed GitHub releases.
Otherwise give a precise manual handoff. Never install a provider or registry
tool without authority.

## Verify and recover

Verify the immutable identity, integrated revision, expected artifacts and
provider/registry status. Record exact IDs and terminal state in the project's
secret-free checkpoint. After a timeout or interrupted multi-step publication,
the overall release disposition is `partial`; mark the ambiguous individual
effect `unknown`. Never repeat it blindly. Inspect current state first and
continue only with fresh authority for the remaining exact effects.

Never move or overwrite an existing tag/release with a different identity,
reuse a version ambiguously, expose credentials, or discard recovery evidence.
Report the release disposition, boundary and full change set, preparation,
publication identities, verification, automatic triggers, partial checkpoints,
and next safe recovery action.
