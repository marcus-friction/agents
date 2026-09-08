---
name: review-gstack
description: Run a rigorous pre-landing review for R3 or significant architecture, security, data, migration, permission, deployment, or production changes. Also use when explicitly requested; routine R1/R2 changes use the standard review.
metadata:
  version: "2.0.0"
---

# Mega Review

Use this as a deeper gate when the change risk justifies it. It does not replace
the normal scoped review or expand the approved work.

## Preflight

1. Read the approved request and, when present, `implementation_plan.md` and
   `task.md`.
2. Resolve the comparison base and reviewed paths.
3. Read the change-rigor reference; confirm the R3 or significant-boundary
   reason for this review.
4. Report and preserve unrelated dirty work. Include it only through an explicit
   dependency trace.

In report-only mode, make zero repository or external writes. Autofix is allowed
only when the user explicitly selects it.

## 1. Scope and intent

Map each accepted item as done, partial, missing, or equivalently changed.
Identify unauthorized additions, omissions, and behavior that differs from the
plan. Do not require plan artifacts for a routine task that did not need them.

## 2. Critical and architectural review

Read `checklist.md`. Trace every consumer of changed public signatures,
schemas, enums, states, permissions, and migrations. Review all in-scope files
and every affected boundary; do not include unrelated files merely because they
are dirty.

Declare standards, correctness, security, performance, architecture,
operations, testing, and compatibility applicable or not applicable with
reasons. Use the dedicated skills for applicable passes.

## 3. Conditional design review

For affected interfaces, read `design-checklist.md` and the active
`DESIGN.md`. Skip with a reason when no interface changes.

## 4. Test and failure-flow map

Use the smallest useful ASCII flow when three or more branches or state
transitions make coverage hard to see. Map changed observable behavior and
meaningful failures to real unit, integration, or end-to-end tests. Do not
create a diagram or test for ritual alone.

A bug fix needs a regression that fails without the fix. Preserve the 100% line
and branch target for testable production behavior and explain allowed
exclusions.

## 5. Findings and fixes

Use the standard review's severity, confidence, and action model. In explicitly
selected autofix mode, apply only deterministic, in-scope `safe_auto` changes
and verify them. Ask before behavior, contract, dependency, policy, permission,
data, or subjective design changes.

## 6. Independent challenge

Run or recommend `adversarial-review` for the R3/significant boundary that
triggered this workflow. Use an independent context when available. Do not make
the handoff a blocker when an independent executor is unavailable; record that
evidence honestly.

## Verdict

Report scope drift, pass applicability, findings, tests, autofixes, unavailable
evidence, and residual risk. Overall is GO only when every blocking accepted
item and R3 safeguard is verified.
