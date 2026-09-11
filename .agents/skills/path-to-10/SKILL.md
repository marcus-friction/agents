---
name: path-to-10
description: Evaluate an output, plan, architecture decision, or implementation against its accepted intent and project evidence. Use when the user asks for a path to 10, quality score, gap-to-excellent analysis, or rigorous quality assessment.
---

# Path to 10

Identify the smallest evidence-backed changes that would make the evaluated
work excellent for its accepted purpose. A 10 is not abstract perfection; it is
the best supported result within the real scope and constraints.

## Authority and target

Resolve what is being evaluated and the accepted intent from the request and
conversation. Use a task file or implementation plan when one exists and is
relevant; neither file is a prerequisite.

An evaluation-only request is report-only: make zero repository or external
writes. If the user also asks to improve the work, implement only the supplied
scope and re-evaluate it. Do not add a generic approval gate; stop only for a
material choice or elevated effect that lacks authority.

## Establish evidence

Use the strongest relevant evidence available:

- accepted requirements, constraints, and owner decisions;
- applicable project rules, architecture or design decisions, and established
  patterns;
- observed behavior, executable tests, measurements, and the artifact itself;
- relevant project knowledge when it exists and plausibly matches the topic;
- current primary documentation for external limits when proof is required.

For implementation work, trace the affected behavior, dependencies, callers,
tests, and boundaries far enough to support the assessment. Do not review the
whole repository by default.

Label the basis of each material claim as an accepted requirement, project
rule, observed behavior, external constraint, or reviewer judgment. A project
rule is strong evidence but is not required for every valid flaw: a result can
contradict its accepted intent or demonstrably fail without violating a written
rule. Missing evidence stays unresolved rather than becoming a low score.

## Choose dimensions

Choose the smallest set of non-overlapping relevant dimensions that covers the
accepted outcome. Omit categories that cannot affect success. Useful dimensions
may include requirements completeness, correctness, usability, architecture,
security, performance, maintainability, reversibility, or verification.

For each dimension, state what a 10 means before scoring it. Use integer scores
with these anchors:

- **10:** accepted intent is met, relevant verification passes, and no material
  supported gap remains.
- **8-9:** intent is met with a small evidenced improvement remaining.
- **6-7:** a material but bounded gap remains.
- **3-5:** several material gaps or one severe gap undermine the outcome.
- **0-2:** the work is unusable, unsafe, or fundamentally misses its intent.

Do not average scores into false precision. The overall assessment is governed
by the most important unresolved dimension. Do not invent a gap merely to avoid
awarding 10.

## Build the path forward

For every supported gap, provide the smallest concrete correction and an
observable check that would prove it closed. Order actions by outcome and risk,
not by ease or file order. Separate required corrections from optional polish.

Define a **Contextual 10** only when a hard external constraint prevents the
ideal result. Prove that constraint with current primary documentation,
executable evidence, or an explicit owner-controlled boundary. If proof is
unavailable, mark the constraint unresolved and preserve the scores that are
otherwise supported.

## Report

Lead with the current quality judgment and the strongest reason. A compact
dimension table normally uses `Dimension | Score | Evidence | Gap to 10`, but
use a clearer shape when the artifact calls for it. Then give the prioritized
path forward, verification for each action, and unresolved evidence.

If the work already earns 10 for its accepted intent, say so and identify the
evidence; do not manufacture work. When implementation was requested, finish
with the checks run and the re-evaluated result.
