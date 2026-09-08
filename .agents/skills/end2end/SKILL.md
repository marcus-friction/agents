---
name: end2end
description: Plan and run browser-based end-to-end tests when the user asks to test an app, verify a UI, check a user flow, or interact with an application in a browser. Distinguishes test-only work from explicitly authorized test-and-fix work and reports evidence progressively.
---

# End-to-End Testing

Verify the application from a user's perspective while keeping browser and
state effects inside the user's intent.

## 1. Derive intent and scope

Use the scope already supplied. Ask only for a missing URL, persona, flow, or
expected result when it blocks safe execution; do not repeat questions the user
has answered.

Classify the request before opening the browser:

- **Test-only** is the default for requests to test, inspect, or report.
  Testing alone does not authorize production-code mutation.
- **Test-and-fix** applies only when the user also asks for fixes or an existing
  implementation request clearly includes them. It authorizes only bounded
  local edits in that supplied scope.

Classify fixture, browser, credential, cleanup, and shared-state effects
independently. Identify whether the target and test data are disposable local
state, a shared environment, or production. Do not use real credentials,
create shared records, alter production, or perform destructive cleanup unless
that exact effect has been approved. Never place credentials in plans, logs,
screenshots, traces, or reports.

Disposable local tests may use synthetic credentials created for that fixture
without a separate approval. Never substitute a live credential.

## 2. Plan proportionately

State the flows, expected outcomes, environment, and allowed effects concisely
in chat. A supplied, safe scope needs no redundant approval gate. Request one
precise decision only for an unresolved material effect such as real credential
use, shared-state mutation, or production interaction.

Chat is the default for the plan, progress, and result. Create a durable plan,
task list, trace, or report only when requested or when the user accepts it as a
useful handoff. Keep temporary test evidence in a verified test-owned location.

## 3. Execute progressively

Test one flow or page area at a time so failures remain attributable. Prefer
the host's browser capability and follow the `playwright` skill when Playwright
is used.

For each flow:

1. Record the expected outcome.
2. Perform only the classified interactions.
3. Verify the visible and stateful result.
4. Record pass, fail, or blocked with supporting evidence.

Seed and remove only proven disposable test-owned data. Preserve pre-existing
and shared data. If cleanup cannot be verified, retain the data and report its
exact location and recovery path.

## 4. Handle failures according to intent

- In **test-only** work, investigate read-only evidence as useful, report the
  failure and likely boundary, and do not edit production code.
- In **test-and-fix** work, use `systematic-debugging`, add a failing regression
  test when practical, make the smallest authorized local fix, and rerun the
  affected browser step.
- Stop when a fix expands beyond supplied scope or the same blocker survives
  three attempts. Do not revert user or pre-existing work; describe any local
  changes and unresolved recovery needs.

## 5. Report

Return a concise chat report with the tested scope and environment, per-flow
outcomes, evidence, changes made (if authorized), unresolved issues, and any
retained test data. A durable report uses the same fields only when requested
or accepted as a handoff.
