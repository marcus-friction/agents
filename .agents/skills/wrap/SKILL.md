---
name: wrap
description: Complete a clean, documented, knowledge-preserving handoff when the user explicitly asks to wrap, commit, or push. A wrap may finish accepted local work but never implies commit or push; those permissions remain separate.
---

# Wrap

Close the accepted increment before handing it off to Git. A handoff is ready
only when the workspace is accounted for, reusable knowledge and affected
documentation are resolved, and relevant quality evidence is known.

## Trigger

Use only for an explicit wrap, commit, or push request. A status request,
implementation completion, context switch, or bare "do not commit or push" does
not trigger this skill. "Wrap this up, but do not commit or push" does trigger
the completion workflow without authorizing either Git effect.

## Authority by request

| Request | Authorized | Still requires authority |
|---|---|---|
| Explicit wrap | Audit the handoff; finish bounded cleanup, knowledge, and documentation for accepted work completed in this task | Any commit or push |
| Exact commit | Audit, then commit only the named files or hunks once every gate is resolved | Push; missing cleanup, knowledge, or documentation outside the named scope |
| Exact push | Audit, then push only the named local ref to the named remote/ref | Creating or amending commits; missing local completion work |

Treat unknown pre-existing work as read-only. Preview any proposed mutation and
obtain approval before changing it. Skills change method, never authority.
If a commit or push request lacks exact scope or destination, inspect and
preview the missing facts instead of guessing them.

## Workflow

### 1. Inventory the handoff

Read repository instructions and inspect status, relevant diffs, branch, and
remotes without exposing secrets. Classify every changed or untracked path as:

- accepted work;
- an intentional retained artifact;
- unrelated work to preserve; or
- a cleanup candidate.

Scan accepted work for scratch scripts, debugging statements, temporary
fixtures, stale generated output, and undocumented environment variables. An
explicit wrap may remove an artifact created in this task and known to be
disposable. Deleting any other uncommitted data requires exact approval. A
worktree may remain intentionally dirty, but no path may remain unexplained.

### 2. Resolve the completion gates

`required` and `update required` are pending states, not final dispositions.
Resolve every applicable gate before previewing or executing a commit or push.

| Gate | Resolved dispositions | Pending when |
|---|---|---|
| Workspace | Every path is accepted, deliberately retained, preserved as unrelated, or approved cleanup is complete | A path is unexplained or cleanup has no owner decision |
| Knowledge | `already captured`, `not applicable`, or `declined by user` with a reason | A reusable lesson is `required` but not captured or declined |
| Documentation | `current` or `no impact` with a reason; list any updates separately | An affected source of truth is `update required` |
| Quality | Relevant verification and review are confirmed; unavailable evidence is explicit | A required check has not run or an applicable finding is unresolved |

For the knowledge gate, invoke `compound` to assess candidates from the accepted
work. `compound` owns the relevance rating; do not duplicate its eligibility
rule here. A High-rated learning is `required` until captured, found already
captured, or explicitly declined. Medium- and Low-rated candidates resolve as
`not applicable` with the rating rationale. During an explicit wrap, capture or
update an authorized High-rated learning and verify it. An explicit decline
resolves the gate as a waiver; never report the knowledge as captured.
After a successful capture or update, report the gate as `already captured` and
include the artifact path.

Report the final knowledge-gate disposition, not the operation that led to it:

- a successful `captured` or `updated` operation resolves to `already captured`;
- an explicit waiver resolves to `declined by user`, never `proposed`; and
- an uncaptured High learning outside an exact commit-only or push-only write
  scope is `required`, not `proposed`, because it still blocks that Git effect.

For the documentation gate, check every affected source of truth: README,
setup/configuration and environment examples, architecture or design decisions,
runbooks, public interfaces, and useful code comments. During an explicit wrap,
complete bounded updates for the accepted increment. Do not create a changelog
or release document unless separately requested.

Run missing tests or review when they are normal in-scope completion work. Do
not claim evidence that did not run. For commit-only, push-only, or unknown
pre-existing work, consolidate all missing-mutation decisions into one preview
with exact paths, effects, and reasons.

### 3. Prepare or execute Git effects when applicable

If the request includes or may lead to a commit or push, read
`references/git-handoff.md` completely and follow it after every completion gate
is resolved. If the user explicitly excluded both effects, skip that reference
and report the completed local handoff.

### 4. Report the handoff

Lead with completed effects and use this compact shape:

```text
Workspace: <accounted paths and cleanup>
Knowledge: <disposition and artifact, if any>
Documentation: <disposition and changed sources>
Quality: <tests, review, and unavailable evidence>
Git: <commit hashes/subjects and push destination, or explicitly not done>
Preserved: <unrelated or intentionally retained work>
```

If work remains blocked, replace the Git line with one consolidated decision
that names the exact unresolved effects. Never hide incomplete gates in a
generic follow-up list.
