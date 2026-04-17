---
description: Summarize the day's work and put it in context
---

# Stats

Summarize the day's engineering work and provide perspective on progress.

## When to Use

At the end of a work day, or when the user asks for a status check.

## Steps

1. **Gather raw data.** Collect from all relevant repos:
   - `git log --oneline --since="midnight" --author="$(git config user.name)"` — today's commits
   - `git diff --stat HEAD~<n>..HEAD` — scope of changes (files, insertions, deletions)
   - Review conversation history summaries from today's sessions for context on what was worked on

2. **Categorize the work.** Group today's contributions by type:
   - 🚀 **Features** — new functionality shipped
   - 🐛 **Fixes** — bugs resolved
   - 🔧 **Refactors** — code improved without behavior change
   - 📚 **Docs** — documentation, rules, workflows, solution docs
   - 🧪 **Tests** — test coverage added or improved
   - 🏗️ **Infra** — CI/CD, deployment, tooling, configuration

3. **Summarize achievements.** Write a concise narrative of what was accomplished, focusing on outcomes over activities. Lead with impact: what changed for the user, the product, or the codebase.

4. **Quantify the session.** Present key metrics:
   | Metric | Value |
   |--------|-------|
   | Commits | count |
   | Files changed | count |
   | Lines added / removed | +X / -Y |
   | Conversations | count |
   | Solutions documented | count (if any) |

5. **Contextualize.** Put today's work in broader perspective:
   - What progress was made toward active projects or milestones?
   - Are there open threads or unfinished work to carry forward?
   - Were any blockers identified that need attention?

6. **Carry-forward items.** List anything that should be picked up next:
   - Unfinished tasks or TODOs introduced today
   - Open questions or decisions pending
   - Follow-up items mentioned in conversations

7. **Present the summary.** Format as a clean, scannable report using the template below.

## Report Template

```markdown
# Daily Summary — [YYYY-MM-DD]

## What Got Done
[Concise narrative of accomplishments, 2-4 sentences]

## Breakdown
### 🚀 Features
- [item]

### 🐛 Fixes
- [item]

### 🔧 Refactors / Infra
- [item]

## By the Numbers
| Metric | Value |
|--------|-------|
| Commits | X |
| Files changed | X |
| Lines | +X / -Y |

## Carry Forward
- [ ] [item to pick up next]
```

## Rules

- Only include categories that have entries — don't show empty sections.
- Keep the narrative section outcome-focused, not a task list.
- When conversation history is available, use it — it's the richest source of "what actually happened."
- Don't invent metrics. If data isn't available (e.g., no git access), say so and work from conversation context.
- The report should be concise enough to read in 30 seconds.
