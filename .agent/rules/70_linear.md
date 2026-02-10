---
trigger: model_decision
description: Apply when handling tickets or interacting with Linear.
---

# Linear Project Management

Apply when working on tasks that correspond to Linear issues or when a new request comes in without an existing issue.

## Workspace

<!-- Fill per project -->
- **Organization:** …
- **Teams:** …

## Issue Lifecycle

**Backlog** → **Todo** → **In Progress** → **User Testing** → **Done** · (**Canceled**)

| State | Meaning |
|---|---|
| Backlog | Captured but not yet prioritized. |
| Todo | Prioritized and ready to pick up. |
| In Progress | Actively being worked on. |
| User Testing | Work completed by the Developer and to be verified by the user. |
| Done | Work complete and verified. |
| Canceled | Dropped — won't be done. |

### Agent behavior

1. **Before starting:** Move issue to **In Progress**, post comment: "Starting work".
2. **During work:** Post progress comments on significant milestones.
3. **On completion:** Post final comment with summary, move issue to **Done**.
4. **No issue exists:** Create one before starting work. All features, bugs, and improvements get an issue.

## Commit & PR References

- Reference issues in commits: `fix: resolve widget alignment (PROJ-42)`
- Link issues in PR descriptions.