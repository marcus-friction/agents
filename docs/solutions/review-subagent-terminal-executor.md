---
title: Mark delegated review passes as terminal executors
category: agent-skills
date: 2026-10-10
components: [review skills, subagent dispatch]
tags: [review, subagents, delegation, recursion, skill-routing]
---

# Mark delegated review passes as terminal executors

## Symptom

A direct specialty review and a plan review can both send a pass to a fresh
subagent. Their earlier no-redelegation clause named only a parent `review`.
A child sent by another reviewer could read its task as another direct review
and start a second child for the same pass.

## Root cause

The child packet did not explicitly identify the recipient as the executor,
and the guard described one parent skill instead of the delegated role. The
same gap appeared in several specialty skills and stack personas. A smoke pass
found the stack persona variant after the first four specialty clauses were
corrected.

## Solution

For a standalone review, dispatch an applicable pass with a bounded packet
that says the recipient is the executor and must complete the pass without
delegating it again. In the receiving skill, stop redelegation whenever the
pass arrived by delegation, regardless of the parent reviewer. The invoking
reviewer still validates evidence and synthesizes the result.

Keep a same-context fallback labeled as such. It does not become independent
corroboration, and it does not satisfy the adversarial independence gate.

## Prevention

Check both ends of every new dispatch route: the parent packet names the
terminal executor, and the receiving skill covers delegation from any parent.
Exercise direct specialty, plan-to-specialty, and persona routes with a fresh
subagent. A source-text check alone cannot prove that a child stops.

## Related

- [Review orchestration](../../.agents/skills/review/references/scope-and-orchestration.md)
- [Review plan skill](../../.agents/skills/review-plan/SKILL.md)
- [Tracked increment](../plans/2026-10-10-review-skill-independent-dispatch/implementation-plan.md)
