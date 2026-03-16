---
trigger: model_decision
description: Apply when handling tickets or interacting with Linear.
---

# Linear Project Management
Apply when working on tasks corresponding to Linear issues, or when starting undocumented work.

## Issue Lifecycle
`Backlog` → `Todo` → `In Progress` → `User Testing` → `Done` · (`Canceled`)

## Agent Behavior
1. **Pre-work:** If no issue exists, create one. Move the issue to **In Progress** and comment "Starting work".
2. **During work:** Post progress comments on significant milestones.
3. **On completion:** Summarize work in a final comment and move issue to **Done**.

## Git Integration
- Reference issue IDs in commits: `fix: resolve widget alignment (PROJ-42)`
- Link issues explicitly in PR descriptions.