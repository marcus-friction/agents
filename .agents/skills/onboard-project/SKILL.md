---
name: onboard-project
description: Safely establish or refresh project context for an existing repository without losing documentation or local agent rules. Use when setting up a cloned or mature codebase, fixing agent blindness, reconciling new .agents/templates, establishing architecture baselines, or asking "what is this codebase".
---

# Safe Project Onboarding

Build an evidence-backed project baseline while treating every active project
document as project-owned. Incoming templates are candidates, not authorities.

The core invariant is:

> No existing meaning may be overwritten, appended around, relocated,
> superseded, or deleted until it has an explicit ledger disposition and the
> user has approved the exact patch.

## Ownership Boundaries

| Path | Owner | Onboarding behavior |
|---|---|---|
| Root or nested project documentation | Project | Preserve; reconcile semantically |
| `.agents/templates/` | Upstream | Read-only candidate material |
| `.agents/skills/<upstream-name>/` | Upstream | Inspect for applicability; do not customize here |
| `.agents/project/` | Project | Durable onboarding decisions and local extensions |
| `.agents/rules/` or `.agent/` | Legacy/unknown | Preserve until every meaning is accounted for |

Root project documentation includes at least `README.md`, `AGENTS.md`, nested
`AGENTS.md` files, `CONTRIBUTING.md`, `ARCHITECTURE.md`, and `DESIGN.md`. Provider
instruction files are also project-owned when present.

Never infer ownership from a familiar heading, marker, or apparent copy of an
upstream file. A project may have customized it after installation.

Read `.agents/skills/review/references/change-rigor.md` and classify the proposed
mutation as R0, R1, R2, or R3. Component applicability, boundary assurance, and
change rigor remain independent. The highest applicable trigger wins.
Reuse a handed-off classification only while its scope and evidence hashes
still match; otherwise reclassify changed facts.

## Non-negotiable Safety Rules

- Do not edit, create, rename, or delete an active project document during the
  inventory and drafting phases.
- Do not write through a symlink. Record its link target and ask for explicit
  direction if the underlying file needs a change.
- Read existing documents before reading incoming templates.
- Preserve frontmatter, badges, diagrams, comments, anchors, links, setup
  commands, licensing text, and custom structure unless an exact change is
  approved.
- Never silently choose between contradictory sources. Record the conflict and
  ask the user.
- Never delete an existing rule merely because it is absent from, or
  inapplicable to, an incoming template.
- Do not read secret values from `.env` or credential files. Inspect examples,
  schemas, and variable names instead.
- Do not commit or push onboarding changes unless separately requested.

## Route With the Smallest Sufficient Process

Start with one read-only metadata pass that resolves the repository root, records
Git status when available, and discovers active project documents, nested or
provider instructions, prior onboarding state, legacy rules, symlinks, and
likely direct evidence anchors. Classify potentially sensitive paths by name
before reading content. This pass chooses a route; it is not a reason to inventory
the whole repository twice.

### Clean-additive fast-path predicates

Use the fast path only when every common predicate and one allowed rigor branch
are proven.

Common predicates:

- the requested result is a bounded proposal for clean additive project
  documentation;
- Git and physical metadata establish that each proposed target, its existing
  parent components, and every direct evidence anchor are clean and unchanged.
  Unrelated staged, unstaged, or untracked paths do not disqualify the route;
  preserve them and do not read, rewrite, stash, or otherwise disturb them;
- relevant tracked targets, candidates, and direct anchors have neither
  `assume-unchanged` nor `skip-worktree` Git index flags;
- each proposed target is absent or a clean physical regular file, is not a
  symlink, hardlink, special entry, or generated output, has exactly one link
  when it exists, and has only physical existing parent components;
- no active root or nested project document, provider instruction, prior
  preservation ledger, or legacy rule contains meaning that the proposal would
  alter, displace, or need to reconcile;
- every applicable candidate and direct evidence anchor is a physical,
  non-sensitive regular file with exactly one link, and each read records the
  exact SHA-256 matching both the frozen state and current physical bytes;
- repository evidence and scope already supplied by the user resolve the
  proposal without a conflict, supersession, deletion, weakened
  constraint, new dependency, external effect, or follow-up question; and
- the proposal changes no trust, data, privilege, deployment, or other boundary.

The following block is the normative, machine-readable form of the narrow-R2
acceptance case and its shared fast-path safeguards. The surrounding prose
defines how to gather the evidence; this block does not expand authority.

<!-- BEGIN CLEAN-ADDITIVE FAST-PATH CONTRACT -->
```json
{
  "path": "clean-additive-fast-path",
  "risk_class": "R2",
  "sole_r2_trigger": "already-supplied-component-applicability",
  "r1_target_policy": "bounded-clean-additive-project-documents",
  "r2_target_policy": "exactly-two-absent-root-agents-and-architecture",
  "proposal_targets": [
    "AGENTS.md",
    "ARCHITECTURE.md"
  ],
  "git_cleanliness_scope": "exact-target-candidate-anchor-paths",
  "tracked_index_flag_policy": "reject-assume-unchanged-and-skip-worktree",
  "read_evidence_policy": "exact-sha256-matches-state-and-current-bytes",
  "unrelated_dirty_policy": "preserve-and-continue",
  "existing_file_link_count": 1,
  "approval_decisions": 1,
  "ledger_form": "concise-target-scoped-disposition",
  "preapproval_writes": 0,
  "durable_artifacts_without_audit_need": 0,
  "preapproval_revalidation_batches": 0,
  "unchanged_application_commands": 0,
  "detailed_reference_loads": 0,
  "repeat_direct_anchor_reads": 0,
  "predicate_failure_path": "detailed-reconciliation",
  "predicate_failure_reference": "references/document-reconciliation.md",
  "performance_measurements": [
    "command_batches",
    "elapsed_seconds",
    "total_tokens"
  ]
}
```
<!-- END CLEAN-ADDITIVE FAST-PATH CONTRACT -->

Rigor branches:

- **General R1:** the canonical classifier returns R1. Any bounded project-
  document target set may use this branch when every target and change satisfies
  the common predicates. It does not require the two-file pair or a component-
  applicability fact.
- **Narrow R2:** the canonical classifier returns R2 solely because the proposal
  records component applicability already supplied in the accepted scope. Its
  only targets are exactly the two absent root files `AGENTS.md` and
  `ARCHITECTURE.md`. Direct repository evidence may corroborate the supplied
  applicability; it must not create a new decision.

This R2 exception does not cover a new component decision, clean existing
meaning, a public contract, a planned dependency, user-visible behavior, or any
other R2 trigger. A component-applicability fact cannot be relabeled R1 to enter
the general branch. Merely naming this route never downgrades an R2 or R3 fact.

A staged candidate outside the proposed R1 targets or narrow R2 pair may remain
inactive and unread when it is outside the accepted scope. Mention it as left
unchanged; do not turn it into a ledger item or broaden the proposal.

If any predicate is false or unresolved, stop the fast-path assessment. Read
[document-reconciliation.md](references/document-reconciliation.md) completely
and follow its detailed workflow. Reuse still-current discovery and hashes rather
than repeating work. Use that route for every other R2 case and every R3 case;
never improvise a partial fast path.

### Clean-additive proposal

Before approval:

1. In the initial metadata pass, combine root/status inspection and document,
   legacy, symlink, and anchor discovery. Do not read secret values or content
   diffs from unvetted paths.
2. In one direct evidence pass, read each necessary project anchor once, then
   each physical candidate applicable to the proposed targets. Record target,
   parent, candidate, and direct-anchor type, Git state, and hashes once.
3. Draft only the eligible target set. In chat, provide:
   - the explicit R1 classification, or R2 classification and its sole permitted
     component-applicability trigger;
   - observed facts and their direct repository paths;
   - a concise target-scoped disposition for the applicable incoming meaning,
     not a row-level preservation ledger;
   - the relevant component applicability and boundary facts;
   - the exact unified diff; and
   - other staged candidates deliberately left inactive and why.
4. Request one combined semantic-and-exact-patch approval, then stop.

The proposal turn makes no write, task update, or other artifact. Do not propose
or create a durable ledger unless repository evidence establishes a concrete
audit need; if it does, include its exact path and content in the combined patch.
Do not load the detailed reference while all predicates remain true. Do not
repeat unchanged direct-anchor reads, perform pre-approval revalidation, run a
second reconciliation pass, or execute an application's tests, build, startup,
health check, or source merely to validate an unapplied documentation proposal.

Command batches, elapsed time, and tokens are telemetry, not gates. Consolidate
related inspection when it remains readable and safe; do not combine commands
only to manipulate a count.

### Apply an approved clean-additive patch

On a later turn, approval is reusable only while its exact diff and captured
facts remain unchanged. Immediately before writing:

1. Revalidate the approved targets, their existing parents, candidate hashes, the
   direct evidence anchors supporting changed claims, relevant Git state, and
   the single-link status of every existing target, candidate, and direct anchor.
2. Abort the fast path if a target appeared, a hash or relevant state changed, a
   path became non-regular or hardlinked, or another predicate no longer holds.
   Preserve unrelated dirty paths. Load the detailed reference when
   reconciliation is now required.
3. Apply only the approved hunks. Do not create a preservation ledger solely for
   this route; write one only when the approved patch records a concrete audit
   need.
4. Validate the resulting documents, links, diff, and Git state. Run application
   behavior only when the approved documentation change also changed an
   executable contract.
5. Report the changed documents, validation performed, facts that remain
   unresolved, and staged candidates left inactive. Invite review; never commit
   or push unless separately requested.
