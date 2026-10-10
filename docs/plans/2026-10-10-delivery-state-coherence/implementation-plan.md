# Delivery state coherence — v1.13.1

## Accepted scope

Approved 2026-10-10: carry the two still-unmerged fixes from PR #9 into a
fresh PR against current `master`, prepare v1.13.1, and close #9 as superseded
once the replacement exists. This authorizes the scoped branch, commit, public
branch push and PR publication to `marcus-friction/agents`, and a supersession
comment and closure on #9 using the existing GitHub account. Merge, release
publication, checkpoint publication and branch deletion are later effects.

Base: `df1138a0b6efb57618b4828316dc84c1f42d9d67` (v1.13.0).
Source: `fix/delivery-state-coherence-v1.13.1`.

## Requirements and acceptance

1. Relevant deployment drift invalidates stale evidence and rediscoveries
   determine current actions. A verified empty inventory resolves to `none`;
   identified missing or unverified actions continue blocking triggering
   effects. Incomplete discovery pauses the effect without inventing an action.
2. Checkpoints can span a repository record and durable external continuation,
   bound to the same attempt/source. Future identities remain pending; resume
   reconciles carriers and host state before deciding whether an effect occurred.
   No recursive bookkeeping commit or inherited mutation authority.
3. Synchronize v1.13.1 metadata, stable documentation and release notes without
   carrying PR #9's obsolete v1.10.1 preparation.
4. Inventory affected evaluation cases, add meaningful boundary coverage, run
   the offline deterministic suite and independent review, then publish the
   replacement PR and close only #9. Preserve its branch as recovery evidence.

## Implementation and verification

Port the four delivery-guidance files from #9. Add evaluation cases for drift
with empty/unknown action inventories and pending checkpoint identities across
the cutoff. Existing missing-action, resume, hostile-checkpoint and terminal
cutoff cases remain valid; inspect their expectations. Deterministic checks
verify static contracts and evaluator grading, not live model behavior.
Use `bash tests/run.sh`, `git diff --check`, independent testing/contract review
and focused decision exercises where available. Report unexecuted live cases.

## Delivery and recovery

Publish one reviewed commit and replacement PR against exact current `master`
using existing HTTPS Git/GitHub CLI authentication. Public payload contains
skills, synthetic fixtures, tests, plan and release documentation only; check
for sensitive artifacts before commit/push. CI is PR-only and does not deploy.
After verifying replacement identities, post a supersession comment on #9 and
close it without deleting its branch. On ambiguous effects inspect provider
state before retrying. Human review and exact-head CI remain merge prerequisites.
v1.13.1 release publication remains pending until separately authorized.

## Scope clarification — 2026-10-10

The approved two fixes require aligning the direct shared-contract caller
`deploy/SKILL.md` and wrap/deploy final reporting with incomplete discovery.
Independent review traced the contradictory drift/reporting rules to those
callers (COH-C1, COH-C2). The three added cases also require updating both stale
registry counts in `tests/agent-eval-profile-test.sh` (TEST-001). These are
necessary corrections within the approved delivery-coherence scope; no new
service, permission, deployment or publication effect is added.
