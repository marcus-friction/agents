# v1.10.1 — Delivery state coherence

Prepared 2026-09-25. Publish only after the reviewed change is integrated and
the immutable `v1.10.1` tag and GitHub release bind its exact `master` commit.

Relevant target, configuration, script, or trigger drift now invalidates
intervention evidence and triggers fresh action discovery. An evidence-backed
empty action inventory resolves to `none`; missing assessment evidence pauses
the dependent effect without inventing a user-owned action. Existing required
or unverified actions still block their dependent effects.

Delivery checkpoints may span the repository cutoff: the committed part records
only identities known then, and a durable provider or release record continues
the same attempt afterward. Future identities remain pending until observed,
with no recursive bookkeeping commit. An effect without a durable external
record waits for an authorized carrier.

This release changes agent guidance only. It does not deploy an application,
change project-owned delivery policy, or grant publication authority.
