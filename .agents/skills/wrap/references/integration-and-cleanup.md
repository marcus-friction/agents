# Integration and Cleanup

Load this reference for change-request gates, integration, target drift, or
branch/worktree cleanup. Use the project's adopted provider adapter when one
exists; otherwise produce a bounded manual handoff.

## Integrate

Verify the exact source head, target/base, required local and host checks, human
review, merge method, repository/account, and automatic release, deployment, or
provider-managed branch deletion triggers. Treat automatic branch deletion as
an automatic destructive trigger, not as an incidental merge detail. Stale or
failed checks block integration. If release preparation may change reviewed
content, it must be complete before integration.

When integration would automatically delete the reviewed head branch before
delivery reaches its terminal release state, block the merge. Proceed after the
behavior is verified disabled under exact authority. If it must remain enabled,
require exact deletion authority, an independently verified recovery ref that
preserves the reviewed head, and an adopted lifecycle that permits the early
deletion. Authority to create the recovery ref alone is insufficient; neither
integration nor cleanup authority silently authorizes the provider effect.

Immediately before the effect, revalidate every material fact and current exact
authority. A target advance requires a full recompute of the complete unreleased
set, release relevance and artifacts, checks/review, trigger coupling, cleanup
proof, and affected authorization. Never silently merge, rebase, rewrite, or
force. After integration, record and verify the actual integrated revision; all
release publication binds to that revision, not merely the topic head.

## Reach a terminal delivery state

Cleanup remains pending until integration is verified and release is `complete`,
`deferred by adopted policy`, or `not applicable` with evidence-backed reason.
A failed or partial release preserves its source branch, worktree, checkpoint,
and recovery instructions.

## Prove cleanup safety

Confirm ownership of every exact local/remote branch and physical worktree.
Then apply proof appropriate to the integration method:

- **Merge commit:** provider merge identity plus ancestry of the reviewed head
  into the verified integrated revision.
- **Squash:** provider binding between reviewed head and integrated revision,
  plus content equivalence or the project's adopted host proof.
- **Rebase:** provider binding and content/adopted-host proof across rewritten
  commits; different commit identities alone do not mean content is unintegrated.

Retain any target with unique unintegrated content, unrelated dirty files,
missing/contradictory proof, an unowned worktree, partial publication, or needed
recovery state. Never force-delete to make cleanup appear complete. Preview
remote branch deletion and local branch/worktree removal separately, revalidate
their exact physical targets, execute only authorized deletions, and report each
as completed, retained, or blocked with the proof/reason.
