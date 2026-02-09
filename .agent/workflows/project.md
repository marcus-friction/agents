---
description: Interactive onboarding — collects project context and writes 10_project.md
---

# Project Onboarding

Collect project context from the user and populate `.agent/rules/10_project.md`.

## Steps

1. Read `.agent/rules/10_project.md`. Identify which sections still only contain HTML comment placeholders (no real content).

2. For each unfilled section, ask the user **one question at a time** in the order below. Do not batch questions.

3. After each answer, **evaluate its depth**. If the answer is too vague or surface-level, ask a targeted follow-up to get specifics before moving on. Examples:
   - "You mentioned 'better UX' — can you describe a specific pain point this solves?"
   - "What does success look like in measurable terms?"

4. Once satisfied with the depth, move to the next section.

5. **Status** is pre-filled as "Phase 1 — initial development". Do not ask about it.

6. After all answers are collected, write the updated `10_project.md` preserving the YAML frontmatter and section structure. Replace HTML comment placeholders with the user's answers.

7. Show the user a summary of what was written and ask them to review the file.

## Question Guide

| # | Section | What to ask |
|---|---------|-------------|
| 1 | Name | What is the project called? |
| 2 | Vision | Describe in one paragraph: what does this project do, what problem does it solve, and why does it matter? |
| 3 | Goals | What are the primary objectives? What does success look like? |
| 4 | Users | Who uses this product? What are their key needs and pain points? |
| 5 | Key Concepts | What domain-specific terms or concepts must the agent understand to work in this codebase? |
| 6 | Status | *(skip — pre-filled: "Phase 1 — initial development")* |
| 7 | Constraints | Are there non-negotiable limitations? (timeline, budget, regulatory, compatibility, business rules) |

## Rules

- Skip sections that already contain real content (not just HTML comments).
- Ask exactly one question at a time. Wait for the user's response before continuing.
- Probe for depth — do not accept one-word or vague answers without a follow-up.
- Preserve the existing YAML frontmatter (`trigger: always_on`) when writing the file.
