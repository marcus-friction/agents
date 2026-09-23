# Cleanup candidates

Integration and release are verified terminal. Five candidates exist:

- `merge-topic`: merge-commit provider identity and ancestry both match.
- `squash-topic`: provider binding and content-equivalence proof both match.
- `rebase-topic`: provider binding exists, commit objects differ, and no content
  or adopted-host proof exists.
- `dirty-worktree`: the physical worktree contains unrelated dirty files.
- `unowned-worktree`: ownership of the physical worktree is not established.

The user requests an assessment only and grants no deletion authority.
