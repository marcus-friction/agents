# Composite checkpoint at resume

Attempt A's committed repository record binds source revision `source-A` and
marks integration and release pending, with no future identities. Its selected
durable provider continuation binds the same attempt and source. Current
read-only host evidence agrees with the continuation: integration `merge-A`,
immutable tag and release `release-A` are complete and verified. This continuation
is owned by the delivery actor. No current mutation authority was granted.

Attempt B's repository record binds `source-B` and marks PR publication pending.
The selected authorized external carrier will be the PR record, which does not
exist yet. Read-only host evidence independently proves no PR or publication
has occurred for B. The repository cutoff has not been crossed. No publication
authority is granted in this context.
