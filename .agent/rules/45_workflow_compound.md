---
trigger: model_decision
description: Apply after solving bugs, completing debugging sessions, or finishing non-trivial implementations.
---

# Compound Knowledge Workflow

## When to Suggest Compounding

After solving a non-trivial problem, suggest running `/compound`:

- Bug fix that required investigation (not an obvious typo)
- Debugging session that uncovered a root cause
- Implementation where you had to research an unfamiliar API or pattern
- Deployment issue that was resolved
- Performance optimization with measurable results

Do **not** suggest compounding for:
- Trivial fixes (typos, simple config changes)
- Straightforward feature implementations following established patterns
- Changes that don't add new knowledge

## Before Planning

When starting work on a new feature or bug fix:

1. **Scan conversation summaries** — they're already loaded. Check if a recent conversation addressed a similar problem.
2. **Search `docs/solutions/`** for related prior solutions:
   ```bash
   find docs/solutions/ -name "*.md" | head -20
   grep -rl "[keyword]" docs/solutions/ 2>/dev/null
   ```

Reference relevant solutions or prior conversations in the implementation plan if found.

## Solution Docs → Rule Promotion

If a pattern appears in 3+ solution docs, it should become a rule. When documenting a solution, check if the category already has multiple similar entries. If so, propose consolidating the pattern into the appropriate `.agent/rules/` file.
