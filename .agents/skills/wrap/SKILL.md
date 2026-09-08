---
name: wrap
description: Prepare bounded commits or pushes only when the user explicitly asks to commit, "wrap", or push. Keep commit and push authority separate; a status or completion request alone does not trigger this skill.
---

# Wrap

Prepare a precise, reviewable Git handoff without expanding the user's authority.

## When to Use

Use only for an explicit commit, wrap, or push request. Finishing implementation,
asking for status, or switching context does not trigger this skill. Route a
valid request directly; do not ask whether to use the skill. An explicit denial
such as "do not commit or push" is not a request and does not trigger wrap.

## Resolve the requested effects

- A commit request authorizes only the named local commit scope. It does not
  authorize a push or other publication.
- A push request authorizes only the named push scope. It does not authorize
  creating or amending commits.
- A generic "wrap it up" request authorizes a read-only survey and an exact
  effect-batch preview, not immediate mutation. Show the proposed commit groups,
  exact files, commit messages, and any remote and branch that would be pushed;
  ask once which effects to execute.
- If an explicit request already identifies an exact commit-only batch, proceed
  through revalidation and execute the authorized commit without a redundant
  kickoff. Before an authorized push, follow the canonical just-in-time external
  effect decision using its exact remote, ref, exposure, credentials, and recovery
  facts; reuse an unchanged exact approval rather than asking twice.

## Inspect and preview

1. Read applicable repository instructions, then inspect status, relevant diffs,
   branch, and remotes without exposing secret values. Preserve unrelated work.
2. Confirm relevant verification results. Offer needed tests or linting rather
   than silently widening the request.
3. Group only the accepted changes into atomic commits that each leave the
   repository coherent. Stage exact physical files or reviewed patch hunks; never
   use `git add .` or `git add -A`.
4. When a non-trivial solved problem would benefit future work, offer `compound`.
   Do not invoke it or persist a solution unless the user accepts that separate
   artifact.
5. Surface possible scratch cleanup, README changes, or release notes as separate
   follow-ups. Do not delete files, edit README, or create a release document as
   part of wrap unless each action was separately requested and scoped.

## Execute the authorized batch

1. Immediately before mutation, revalidate the exact files or hunks, branch,
   remote, and relevant worktree state. Stop on a relevant change; preserve and
   ignore unrelated dirty work.
2. Create only authorized commits, in dependency order, using concise
   Conventional Commit messages. Report their hashes and subjects.
3. Push only after push authority and the exact external-effect decision are both
   established. Use the approved remote and ref without force.
4. If a push is rejected, report the rejection and options. Do not automatically
   pull, rebase, merge, amend, force-push, or retry.
5. Report the effects actually completed and anything deliberately left
   unchanged.

## Boundaries

- Wrap never automatically rebases, merges, deletes files or branches, publishes a
  pull request or release, creates a release document, or edits README.
- Destructive cleanup, force-push, history rewriting, branch deletion, tags,
  releases, and other publication remain separate exact R3 effects.
- A commit and a push are two independent effects even when both appear in one
  preview. Approval for one never implies the other.
