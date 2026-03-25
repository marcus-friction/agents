---
description: Scope, architect, and plan new engineering tasks
---

# Plan Workflow

This workflow guides the agent through scoping, architecting, and planning a new feature or project. It results in a robust, peer-reviewed implementation plan and a comprehensive task list.

## When to Use

When the user asks to plan a new feature, project, or gives a high-level request, or explicitly uses `/plan`.

## Steps

### 1. Discovery & Interrogation
1. Acknowledge the user's request.
2. Ask **clarifying questions, ONE BY ONE**. Do not overwhelm the user with a wall of 5 questions. Wait for the answer to question 1 before asking question 2.
3. Keep asking questions until you have a complete picture of:
   - The exact business goal.
   - The edge cases.
   - The technical constraints.
   - The preferred approach (if any).

### 2. Context Gathering
Before writing the plan, you MUST read the following to inform your architecture:
1. The project rules (`.agent/rules/*.md`).
2. Any relevant `.agent/skills/*.md`.
3. The most relevant Knowledge Items (KIs) in the Antigravity Brain and documented under `/docs`.
4. Existing codebase files that will be impacted.

### 3. Draft the Plan
Draft an initial Implementation Plan based on the gathered context. Follow our architectural standards and compounded learnings.

### 4. The Review Loop
Do NOT present the first draft to the user immediately.
1. Load the `review-plan` skill (`.agent/skills/review-plan/SKILL.md`).
2. Self-review your drafted plan using the criteria in the `review-plan` skill.
3. Revise the plan to address any shortcomings found during the self-review.
4. Repeat this self-review and revision loop exactly **3 times** to ensure maximum robustness.

### 5. Final Output
After the 3rd iteration, finalize the output. You MUST generate:
1. **Implementation Plan Artifact:** Create a **conversation artifact** detailing the proposed architecture, file changes, and verification steps.
2. **Task Artifact:** A comprehensive `task.md` file containing every required step to complete the project, broken down into granular, actionable tasks. Ensure no parts of the project are missing.

Present a summary of the plan and the tasks to the user, and ask for their approval.

## Rules

- **Projects are ALWAYS tackled as a whole.** They can be broken down into phases and stages, but **NO parts** of the project can be deferred. Do not say "we will handle X later" or "Y is out of scope for now" if it was part of the original request or constitutes a complete project.
- **Interactive Questioning:** Ask questions along the way, interactively and **one by one**, to clarify where a user decision is needed. Every question MUST include a concrete recommendation and a clear explanation of the tradeoffs involved.