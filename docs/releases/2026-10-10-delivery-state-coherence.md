# v1.13.1 — Delivery state coherence

Prepared 2026-10-10. For stable installation, use the full commit SHA in the
[v1.13.1 release record](https://github.com/marcus-friction/agents/releases/tag/v1.13.1)
once published. `master` remains mutable.

This patch carries forward the two unmerged delivery fixes from PR #9 against
v1.13.0, replacing its obsolete v1.10.1 release preparation.

Relevant target, configuration, script or trigger drift invalidates intervention
evidence and requires fresh action discovery. A verified empty inventory resolves
to `none`. Incomplete discovery pauses the dependent effect as an evidence gap
without inventing a user-owned action. Identified missing or unverified actions
still block their dependent effects.

Delivery checkpoints can span the repository cutoff. The committed part contains
facts known by that cutoff; a durable provider or release continuation binds the
same attempt and source revision and records later identities and verification.
Future effects remain pending without fabricated identities. Resume reconciles
all selected carriers and host state before deciding an outcome, without a
recursive bookkeeping commit or inherited mutation authority.

Verification covers static guidance contracts, evaluator grading sensitivity,
and existing delivery evaluations. Independent testing and delivery-contract
reviews found and verified corrections to the direct deploy caller, incomplete
discovery reporting, and stale registry counts. A fresh subagent passed the six
decisions in each of the three new scenarios. Formal live-agent threshold runs
are separate from the offline deterministic suite and remain unexecuted.
This release does not deploy an application.
