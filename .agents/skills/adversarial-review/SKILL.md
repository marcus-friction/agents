---
name: adversarial-review
description: |
  Perform a destructive "Red Team" review of the current changes to eliminate
  shared blind spots. Best used with a secondary model. Use after any code review
  or plan review, and before deploying to production. Proactively suggest when
  merging significant changes.
---

# 🛑 adversarial-review: The Red Team Pass

This skill enforces the **Red Team Pass**. You must actively attempt to break the assumptions, architecture, and code constructed by the primary developer or agent.

## When to Use
Triggered automatically or manually immediately after `review-gstack` or `plan` has been completed. For the highest rigor, the user should switch the active LLM model (e.g., from Claude to Gemini) before running this, ensuring a true "Outside Voice" without shared contextual blind spots.

## Rules of Engagement

1. **Verify Model Switch & Pause:** **Before doing anything**, explicitly use the `notify_user` asking the user: "To ensure a true adversarial review without shared context, please switch your active LLM model (e.g., from Claude to Gemini) and reply with 'continue'." You must receive a positive confirmation before proceeding with the review.
2. **Assume Failure:** You do not trust the diff. You do not trust the implementation plan. Look for catastrophic edge cases.
3. **The "What If" Matrix:** Apply each scenario from `references/what-if-matrix.md`. At minimum, consider:
   - **Concurrency:** What if two users execute this simultaneously? Race conditions cause silent data corruption.
   - **Trust Boundaries:** What if a malicious user bypasses frontend validation? Server-side must be the source of truth.
   - **Infrastructure Failures:** What if the database locks during this transaction? What if the third-party API times out or returns a 500?
   - **Deployment Race:** What if the data migration drops a table while code is mid-deployment? Zero-downtime requires backward compatibility.
4. **Report Format:** Do not present a standard review. Present your findings exclusively as independent "Vulnerability / Risk Scenarios" using the output template below.
5. **No Auto-Fixing:** You are the auditor, not the engineer. Bring the glaring issues to the user's attention using the interactive `AskUserQuestion` format. All issues should be batched together at the end.

## Output Template

For each finding, use:

```
SCENARIO: [Short descriptive name]
─────────────────────────────────
Category:   [Concurrency | Trust Boundary | Infrastructure | Deployment | Logic | Data Integrity]
Impact:     [Critical | High | Medium | Low]
Likelihood: [Certain | Likely | Possible | Unlikely]
Description: [What happens and why it's dangerous]
Mitigation: [Recommended fix or guard]
```

Batch all scenarios into a single `notify_user` call at the end.
