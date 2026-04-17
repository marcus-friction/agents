---
trigger: model_decision
description: Apply when diagnosing errors, fixing bugs, or troubleshooting failing tests. Strictly enforced.
---

# Debugging Workflow — Three Tries Rule

**Strict Rule: Three tries, then escalate. No exceptions. No fix-loops.** Read the `systematic-debugging` skill for detailed methodology.

## Protocol
1. **Try 1 (Targeted Fix):** Read error > Identify root cause > Apply single focused fix > Verify.
2. **Try 2 (Re-evaluate):** If Try 1 fails, **do not repeat**. Re-read logs, question assumptions, try a fundamentally different approach > Verify.
3. **Try 3 (Final Attempt):** Broaden investigation (dependencies, env, config) > Apply fix > Verify.

## Escalation
If Try 3 fails, **Stop making changes.** Escalate to the user with:
- The original error.
- What was tried and why it failed.
- Hypothesis for the root cause.
- Suggested next steps.

## Anti-Patterns
- **No fix-loops:** Stop at 3 failed tries.
- **No cascading changes:** If a fix requires touching unrelated code, stop and reassess.
- **No guessing:** Base attempts on clear hypotheses.
- **No silent failures:** Always verify fix actually resolves the issue.