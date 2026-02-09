---
trigger: model_decision
description: Apply when diagnosing errors, fixing bugs, or troubleshooting failing tests. Strictly enforced.
---

# Debugging Workflow — Three Tries Rule

**This rule is strict. No exceptions.**

If the `systematic-debugging` skill exists, read it for methodology on how to approach each attempt.

When encountering a bug, error, or failing test, follow this exact protocol:

## Try 1 — Targeted Fix

1. Read the error message, stack trace, and relevant code.
2. Identify the most likely root cause.
3. Apply a single, focused fix.
4. Run the failing test or reproduce the issue to verify.

If fixed → done. If not → proceed to Try 2.

## Try 2 — Re-evaluate

1. **Do not** repeat the same approach. Step back.
2. Re-read logs, check related code, question your assumptions.
3. Try a fundamentally different approach.
4. Run the failing test or reproduce the issue to verify.

If fixed → done. If not → proceed to Try 3.

## Try 3 — Final Attempt

1. Broaden investigation — check dependencies, config, environment.
2. Apply the fix.
3. Run the failing test or reproduce the issue to verify.

If fixed → done. If not → **stop immediately and escalate.**

## Escalation

After three failed attempts, you **must**:

1. **Stop making changes.** Do not attempt a fourth fix.
2. **Report to the user** with:
   - What the original error was.
   - What you tried at each step and why it failed.
   - What you think the root cause might be.
   - Suggested next steps or areas to investigate.

## Anti-Patterns

- **No fix-loops.** Three tries, then escalate. Period.
- **No cascading changes.** If a fix requires touching unrelated code, stop and reassess.
- **No guessing.** Each attempt must have a clear hypothesis — not random changes.
- **No silent failures.** Always verify the fix actually resolves the issue before marking it done.