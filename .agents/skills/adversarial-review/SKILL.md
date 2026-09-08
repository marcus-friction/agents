---
name: adversarial-review
description: Independently challenge R3 or significant architecture, security, data, migration, permission, deployment, or production changes. Use after a deep review or when explicitly requested; routine changes do not require it.
---

# Adversarial Review

Try to falsify the approved design, implementation, and review conclusions.
Prefer a different model family or independent context when available, but do
not block evidence gathering merely because it is not.

This workflow is report-only: make zero repository or external writes.

## Preflight

- Read the accepted request, scope, comparison base, plan, and prior review.
- Identify the R3 or significant boundary that warrants an outside voice.
- Preserve unrelated dirty work and exclude it unless a dependency trace makes
  it relevant.
- Read relevant project rules and `references/what-if-matrix.md`.

## Challenge

Construct realistic failure scenarios only for applicable boundaries:

- concurrency, duplicate delivery, ordering, and partial writes;
- bypassed trust boundaries, confused deputies, privilege changes, and secret
  exposure;
- malformed, missing, stale, or adversarial input;
- database locks, resource exhaustion, timeouts, dependency outages, and
  degraded service;
- published-contract or migration compatibility during mixed-version rollout;
- destructive operations, recovery gaps, and irreversible external effects;
- UI state desynchronization, inaccessible recovery, and misleading feedback;
- scope omissions and assumptions unsupported by executable evidence.

Attempt to reproduce or prove each scenario with read-only inspection and safe
tests. Distinguish confirmed defects from hypotheses and unavailable evidence.
Do not manufacture a finding to justify the workflow.

## Report

For each scenario state category, affected boundary, evidence, exploit or failure
path, impact, likelihood, reversibility, existing controls, smallest mitigation,
and verification. Derive severity from the facts rather than a missing checklist
item.

Finish with blocking scenarios, non-blocking residual risks, pass applicability,
and an explicit GO or NO-GO recommendation. No autofix or task mutation occurs
in this skill; implementation requires a separate user request.
