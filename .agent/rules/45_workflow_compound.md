---
trigger: model_decision
description: Apply after solving bugs, completing debugging sessions, or finishing non-trivial implementations.
---

# Compound Knowledge Workflow

## When to Compound
Suggest the `/compound` workflow after solving **non-trivial** problems:
- Complex bug fixes requiring investigation.
- Successful resolution of deployment/performance issues.
- Implementations requiring research of an unfamiliar API/pattern.

*Do not suggest for trivial fixes, typos, or straightforward feature implementations.*

## Planning Check
Before starting new work:
1. Scan active conversation summaries.
2. Search prior solutions in `docs/solutions/` (Use `research-solutions` skill if available).

## Workflow to Rule Promotion
1. Run the `/compound` workflow to capture knowledge.
2. **Promotion:** If a pattern appears in 3+ solution documents, it must be consolidated into a permanent rule in the appropriate `.agent/rules/` file.
