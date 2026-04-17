---
name: systematic-debugging
description: Structured debugging methodology — reproduce, isolate, hypothesize, verify, fix
---

# Systematic Debugging Skill

Methodical approach for each debugging attempt. Use alongside the Three Tries Rule (`42_workflow_debugging.md`) — this skill provides the *how* for each try.

## Methodology

### 1. Reproduce

Before anything else, create a reliable reproduction:

- **Exact steps** to trigger the bug — write them down.
- **Minimal reproduction** — strip away unrelated code/state until you have the smallest case that still fails.
- **Environment check** — is this environment-specific? Compare dev, staging, production.

If you can't reproduce it, you can't fix it. Say so and gather more information.

### 2. Isolate

Narrow the problem space:

- **Binary search the stack** — is the problem in the request, the controller, the action, the model, the database? Eliminate layers systematically.
- **Check boundaries** — where does correct data become incorrect? Log/inspect at each boundary.
- **Recent changes** — `git log --oneline -20` and `git diff` — did a recent commit introduce this?
- **Dependencies** — has a package updated? Check `composer.lock` / `package-lock.json` diffs.

### 3. Hypothesize

Form a specific, testable theory:

- **"The bug is caused by X because Y"** — write this down before touching code.
- **One hypothesis at a time** — don't fix two things simultaneously.
- **Predict the outcome** — "If my hypothesis is correct, then changing Z should produce result W."

Bad hypothesis: "Something is wrong with the query."
Good hypothesis: "The `whereHas` clause on line 42 doesn't account for soft-deleted records, causing the empty result set."

### 4. Verify

Test your hypothesis before applying the fix:

- **Read first** — re-read the relevant code carefully. Many bugs become obvious on a close read.
- **Add targeted logging** — `Log::debug()` / `console.log()` at the exact point your hypothesis predicts the failure.
- **Check the data** — query the database, inspect the request payload, examine the state.
- **Confirm the hypothesis** — does the evidence match your prediction?

If it doesn't match → return to step 3 with a new hypothesis. Don't force-fit.

### 5. Fix

Apply a single, focused change:

- **Minimal diff** — change only what's needed to fix the root cause.
- **No drive-by fixes** — don't refactor adjacent code while debugging.
- **Verify the fix** — run the reproduction steps again. Does it pass?
- **Check for regressions** — run the test suite. Did the fix break anything else?

## Anti-Patterns

| Pattern | Problem |
|---------|---------|
| Changing code without a hypothesis | Shotgun debugging — wastes attempts |
| Fixing symptoms instead of root cause | Bug will resurface in a different form |
| Multiple changes in one attempt | Can't tell which change fixed (or broke) things |
| Skipping reproduction | You might fix the wrong bug |
| "It works on my machine" | Not a diagnosis — check environment differences |

## When Multiple Issues Overlap

If debugging reveals multiple problems:

1. Fix the **root cause** first — downstream issues may resolve automatically.
2. If issues are independent, fix the most severe one and log the others.
3. Don't chase secondary issues mid-debug — finish one fix cycle before starting another.
