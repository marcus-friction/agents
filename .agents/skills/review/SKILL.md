---
name: review
description: Perform a scoped multi-angle review before merging or when the user asks to review changes. Supports read-only reporting and explicitly selected deterministic autofix.
---

# Comprehensive Review

Review the approved scope, not the entire dirty worktree. Read
`code-review-excellence` when available.

## Modes

- `mode:report-only` is strictly R0: make zero repository or external writes,
  including no task, report-file, formatting, or autofix changes.
- `mode:autofix` explicitly selects deterministic in-scope autofix.
- Without `mode:autofix`, report findings and wait for a fix request.
- `base:<ref>` supplies the comparison base.

Never auto-fix subjective design or policy decisions, behavior/contract changes,
permissions, dependencies, destructive work, or anything outside reviewed scope.

## Scope

Build the file set from the approved request, accepted plan, base ref, and
explicit paths. Use conversation context to distinguish this task's changes.
Report unrelated dirty work and preserve it; include it only when an explicit
dependency trace proves relevance.

Read `.agents/skills/review/references/change-rigor.md`. Record change rigor,
affected components, and boundary assurance. An R0 review never mutates.
R3 or significant architecture, security, data, or production work may require
`review-gstack` and an independent adversarial review; routine R1/R2 work does
not.

## Finding model

For each finding record severity, confidence, evidence, consequence,
verification, and one action:

| Action | Meaning |
|---|---|
| `safe_auto` | Local deterministic correction eligible only in explicit `mode:autofix`. |
| `gated_auto` | Concrete change needing owner approval because it affects behavior, contracts, policy, dependencies, or permissions. |
| `manual` | Actionable work requiring project judgment or external coordination. |
| `advisory` | Residual risk or observation; no repository action. |

Suppress findings below 0.60 confidence, except plausible P0 findings at 0.50 or
higher. Do not turn formatting covered by project automation into review noise.

## Passes

Declare every pass **applicable** or **not applicable**, with a reason.

- **Standards:** Check applicable `AGENTS.md`, `CONTRIBUTING.md`, established
  structure, and reusable project knowledge.
- **Correctness:** Trace changed behavior, error paths, boundaries, concurrency,
  compatibility, and user-visible outcomes.
- **Security:** Use the `security-review` applicability preflight. Do not apply
  controls for absent components.
- **Performance:** Use `performance-review` only where the change can affect
  runtime cost, capacity, or latency.
- **Architecture:** Use `architecture-review`; enforce adopted boundaries, not
  generic class, route, transaction, or directory shapes.
- **UI/accessibility/SEO:** Load `DESIGN.md` and the relevant review skills only
  for affected user interfaces or public pages.
- **Testing:** Confirm changed observable behavior and meaningful failures are
  protected. Coverage of lines without useful assertions is insufficient.
- **Operations:** Scale logging, health, recovery, migration, and rollout checks
  to real exposure, data materiality, and production impact.

Run all applicable passes even after finding an issue.

## Autofix

In explicit `mode:autofix`, apply only `safe_auto` changes whose expected
output is deterministic and inside scope. Re-run the narrowest affected check
after each group, then the relevant suite. Convert any uncertain fix to
`gated_auto` or `manual`; do not widen scope.

## Report

Lead with findings ordered P0–P3. Each item names files/lines, confidence,
action, evidence, impact, smallest correction, and verification. Then list
pass applicability, tests run, unavailable evidence, and residual risk.

In mutating review modes, add only unresolved `manual` and approved workflow
items to `task.md`. In report-only mode, keep everything in the response.
If there are no findings, say so directly rather than inventing work.
