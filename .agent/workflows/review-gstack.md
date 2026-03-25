---
description: Scope, verify, and auto-fix code changes using the rigorous `review-gstack` methodology based on your active `task.md` intent.
---

# `review-gstack`

This workflow triggers the "Mega Review" pipeline, designed to thoroughly vet pre-landing code changes against your stated intent (`task.md`), auto-fixing mechanical errors and batching architectural questions.

1. Ensure your active working directory is clean except for the files you intend to review and commit.
2. Read the instructions in `./.agent/skills/review-gstack/SKILL.md`.
3. Read the code review heuristics in `./.agent/skills/review-gstack/checklist.md`.
4. If frontend files were modified, read the design heuristics in `./.agent/skills/review-gstack/design-checklist.md`.
5. Read the active `task.md` and `implementation_plan.md` artifacts attached to this conversation.
6. Generate the Scope Drift and Test Coverage (ASCII map) analyses as described in the skill.
7. Execute the Fix-First methodology: silently correct mechanical `AUTO-FIX` issues, then use the `notify_user` tool to present all `ASK` issues in a single, batched interface.
8. Once the Fix-First decisions are resolved, automatically trigger the `adversarial-review` skill to complete the final Red Team pass.
