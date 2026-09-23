---
title: Keep routing-critical skill behavior in primary instructions
category: agent-skills
date: 2026-09-23
components: [skills, agent evaluations]
tags: [progressive-disclosure, routing, handoff, regression-testing]
---

# Keep routing-critical skill behavior in primary instructions

## Symptom

An explicit generic wrap completed its local handoff but could omit the
required read-only commit preview. Exact commit requests still worked, and the
downstream Git-handoff reference still described the preview correctly.

## Root cause

The decision that a generic wrap requires a preview had moved out of the main
skill and into a conditionally loaded reference. The main skill said to load
that reference only when a request "includes or may lead to" a Git effect while
also emphasizing that wrap grants no commit or push authority. An agent could
therefore decide that the reference was inapplicable and never see the generic
preview requirement.

Progressive disclosure cannot recover a routing rule that is available only
after the model has already made the wrong routing decision.

## Solution

Keep the trigger and high-level behavior in the primary `SKILL.md`: a generic
wrap prepares the exact read-only preview unless both Git effects are excluded.
Keep the reference responsible for the detailed preview and execution workflow.
State separately that showing a preview needs no mutation authority while
executing commit or push does.

Protect both layers:

- a structural contract keeps the routing obligation in the main skill; and
- a consuming-agent case checks the resulting disposition, exact paths and
  message, one decision covering both effects, and absence of Git mutation.

Evaluation fields must encode the full decision semantics. A boolean such as
"message present" or a count such as `1` can pass while omitting required
content. Normalize whitespace when a static prompt assertion intentionally
matches prose across Markdown line wrapping.

## Prevention

Before moving instructions into a reference, ask whether the agent needs those
instructions to decide that the reference applies. If so, retain that decision
boundary in the main skill and move only downstream detail. Pair the main-skill
contract with a positive generic-route case and explicit negative authority
cases.

## Related

- [Wrap skill](../../.agents/skills/wrap/SKILL.md)
- [Git handoff reference](../../.agents/skills/wrap/references/git-handoff.md)
- [Routing contract](../../tests/skill-routing-contract-test.sh)
- [Generic-wrap evaluation registry](../../tests/agent-evals/cases.json)
- [Implementation plan](../plans/2026-09-23-wrap-commit-preview/implementation-plan.md)
