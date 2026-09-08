---
name: test-driven-development
description: Use when implementing testable feature or bug behavior. Write a failing test for the intended observable change before changing production behavior; characterize existing code instead of discarding it.
---

# Test-Driven Development

Use a short red–green–refactor loop for observable behavior. The test should
prove the requested change, not satisfy a ritual.

## Scope the behavior

Before writing a test, name:

- the user- or boundary-visible behavior that changes;
- the realistic production mistake the test should catch;
- the expected result derived independently of the implementation;
- the meaningful success and failure paths.

Do not invent tests for human prose, behavior-free configuration, trivial
forwarding, or generated artifacts without an executable contract. Record
legitimate coverage exclusions explicitly. Allowed exclusion categories are
generated, declarative, unreachable, and behavior-free.

Read [writing-good-tests.md](references/writing-good-tests.md) when writing or
changing tests, mocks, fixtures, or test helpers.

## Red

Write the smallest test that expresses one intended outcome. Exercise real code
and boundaries; mock only the slow or external layer after understanding its
side effects.

Run the narrow test and confirm it fails because the intended behavior is
missing or wrong. A syntax error, broken fixture, or unrelated failure is not a
valid red. If the test already passes, refine it to cover the actual delta or
confirm that no production change is needed.

## Existing implementation

Preserve valid existing code. When it predates tests:

1. Characterize current behavior where that knowledge protects the change.
2. Add a failing test for the intended delta.
3. Modify only the production behavior the failing test proves must change.

Do not delete and recreate implementation merely because it was written before
its tests. Exploration may inform the test, but keep only code supported by the
accepted behavior.

## Green

Make the smallest coherent production change that passes the new test. Avoid
unrequested options and abstractions. Run the narrow test, then the relevant
suite. Fix the implementation when a valid test fails; change a test only when
its expectation or setup is demonstrably wrong.

## Refactor

After green, improve names, cohesion, and duplication without changing behavior.
Keep the tests passing. Add another red case for any new behavior discovered
during refactoring.

## Coverage and completion

Aim for **100% line and branch coverage of testable production behavior**. Tests
are required for new or changed observable behavior, not for every method.
Coverage proves execution, not correctness; assertions must cover useful
outcomes, boundaries, and meaningful failure paths.
Record the project's actual coverage command and measured scope. Do not claim a
numeric result when no executable coverage tool ran.

Before completion confirm:

- each changed behavior had a test that failed for the expected reason;
- expectations are hand-derived rather than mirrored from production logic;
- mocks are narrow and assertions target real component behavior;
- error, empty, authorization, concurrency, or malformed-input cases are covered
  when applicable;
- the relevant suite passes without unexplained warnings;
- exclusions are explicit and belong to an allowed category.

For a regression, first reproduce the bug with a failing test, then fix it and
retain the test.
