---
name: review
description: Perform a scoped multi-angle code review of local changes, an explicit path set, or a branch or pull-request diff before merging or when the user asks for review. Defaults to non-mutating review, records actionable work in an already-authorized plan tracker, and supports only explicitly selected deterministic autofix.
---

# Scoped Review

Review the accepted change and its intent, not the repository in general. Read
`code-review-excellence` when available; this skill's scope, severity, and
output contracts take precedence.

## Modes and authority

- Default and `mode:report-only` make no reviewed-code, configuration, report
  file, checkout, external, or autofix changes. They are R0 unless an accepted
  plan already authorizes the bounded `tasks.md` update described below; that
  tracker-only effect is R1 and does not authorize a fix.
- `mode:autofix` authorizes only deterministic `safe_auto` corrections inside
  the reviewed local scope. Without it, report findings and stop.
- `base:<ref>` supplies a comparison base. Never switch branches or check out a
  remote review target.

Never infer permission to commit, push, publish, file tickets, change policy or
contracts, add dependencies, or send code or review data to an external model,
provider, or service. Those actions need their own authority.

## 1. Establish scope and intent

Read these references completely:

- `.agents/skills/review/references/change-rigor.md`
- `.agents/skills/review/references/scope-and-orchestration.md`
- `.agents/skills/review/references/finding-contract.md`

Resolve the exact target, base and head, file inventory, accepted requirements,
governing project rules, and the matching accepted implementation plan when one
exists. Record change rigor, affected components, and material boundary facts.
Preserve unrelated dirty work. A tracker is eligible only when it is the regular
`tasks.md` sibling of that plan and its authority covers the reviewed increment;
never guess between plausible historical plans or create a missing tracker.

## 2. Select passes

Declare each pass applicable or not applicable with a reason. Correctness is
always selected. Select other passes only when evidence makes them relevant:

- **Standards:** applicable `AGENTS.md`, `CONTRIBUTING.md`, architecture or
  design decisions, established structure, and reusable project knowledge.
- **Testing:** changed behavior, failure handling, or an affected test harness.
- **Security:** use `security-review` for changed trust, data, identity,
  permission, dependency, or destructive-operation boundaries.
- **Performance:** use `performance-review` when runtime cost, capacity,
  latency, or resource use can materially change.
- **Architecture:** use `architecture-review` for boundaries, dependencies,
  contracts, ownership, persistence, or structural change.
- **UI/accessibility/SEO:** load `DESIGN.md` and the relevant skills only for an
  affected interface or public page.
- **Operations:** select for material migration, rollout, recovery, logging,
  health, or production behavior.

Framework-specific rules apply only to components the project marks Adopted.
All selected passes inspect the complete accepted scope; one finding does not
end the review.

## 3. Execute and synthesize

Give every delegated pass the same compact review packet: target and intent,
base/head, accepted file list and diff, explicit requirements, applicable
standards, boundary facts, and the finding contract. Follow the dispatch,
collection, independence, failure, evidence-search, and deduplication rules in
`scope-and-orchestration.md`.

Normalize every retained issue through `finding-contract.md`. Validate the
cited line and surrounding behavior before reporting it. Keep primary and
secondary findings verdict-relevant; list unrelated pre-existing findings
separately. Do not turn formatter or linter output into review noise.

Elevated or significant architecture, security, data, migration, permission,
deployment, or production work may also require `adversarial-review` after the
selected review passes. A routine ordinary change does not.

## 4. Autofix, when explicitly selected

Apply only `safe_auto` findings whose result is deterministic, reversible, and
inside the reviewed local scope. Re-run the narrowest affected check after each
group and then the relevant suite. Inspect the autofix-only diff before
finishing. Revert a failed or uncertain correction and report it as
`gated_auto` or `manual`; do not widen scope.

## 5. Update the accepted tracker

When the matching accepted plan already authorizes its live tracker, amend only
that `tasks.md` after synthesis:

- add every retained actionable P0–P3 finding as an unchecked task with its
  stable finding ID, narrow location, smallest correction, and verification;
- exclude advisory-only observations and avoid duplicating an existing finding
  task;
- keep secrets or sensitive evidence out of task text;
- mark the review task complete only after all retained findings have been
  recorded, including when the verdict is Not ready; and
- leave every finding task unchecked until its correction is implemented and
  verified.

If the tracker is absent, ambiguous, outside the accepted increment, explicitly
excluded from writes, or unsafe to edit, make no repository write and report the
tracking gap. Tracker authority never permits changing reviewed code or any
other file.

## 6. Report

Lead with stable-numbered findings ordered P0-P3. Each finding includes exact
location, confidence, action, evidence, consequence, smallest correction, and
verification. Then report:

- scope and intent;
- explicit requirements as complete, partial, missing, or equivalently met;
- every pass as completed, not applicable, or missing coverage;
- tests and inspections run, unavailable evidence, pre-existing issues, and
  residual risks;
- tracker tasks added, deduplicated, or unavailable; and
- one verdict last: **Ready**, **Not ready**, or **Withheld**.

Use **Not ready** for unresolved P0/P1 findings or an incomplete explicit
requirement. Use **Withheld** when missing required coverage or unavailable
material evidence prevents a defensible verdict. Otherwise use **Ready**. If
there are no findings, say so directly, but never call the change Ready when a
required pass did not complete.
