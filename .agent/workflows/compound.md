---
description: Document a solved problem to compound team knowledge
---

# Compound Knowledge

Capture a recently solved problem as structured documentation so future work benefits from past solutions.

## When to Use

After solving a non-trivial bug, debugging session, or tricky implementation. Trivial fixes (typos, obvious errors) don't need compounding.

## Steps

1. **Identify the problem.** Determine what was solved from conversation context or user description. Ask the user if unclear.

2. **Extract context.** Gather:
   - Exact error messages or observable symptoms
   - Which component/layer was affected
   - Investigation steps tried (including dead ends)

3. **Analyze root cause.** Write a concise technical explanation of why the problem occurred.

4. **Extract the solution.** Document the working fix with code examples where applicable.

5. **Check for prior art.** Search `docs/solutions/` for related existing documentation. Cross-reference if found.

6. **Determine category.** Classify into one of:
   - `build-errors/`
   - `runtime-errors/`
   - `performance/`
   - `database/`
   - `security/`
   - `deployment/`
   - `ui-bugs/`
   - `integration/`

7. **Write the solution doc.** Create `docs/solutions/[category]/[slug].md` using the template below.

8. **Evaluate knowledge tier.** Decide where the learning belongs (see Knowledge Tiers below). Ask the user before modifying rules.

9. **Summarize.** Tell the user what was documented and where.

## Knowledge Tiers

Antigravity maintains knowledge at multiple levels. Place learnings at the right tier:

| Tier | Location | Persistence | When to use |
|------|----------|-------------|-------------|
| **Conversation memory** | Antigravity brain (`~/.gemini/antigravity/brain/`) | Automatic — conversation summaries carry forward | Always happens — no action needed |
| **Solution docs** | `docs/solutions/[category]/` | Git-tracked, searchable | Default target for `/compound` — specific problem/solution pairs |
| **Rules** | `.agent/rules/` | Always-on or model-decision | Recurring patterns seen in 3+ solutions — propose promotion |
| **Skills** | `.agent/skills/` | On-demand, loaded by name | Reusable expertise checklists (review, research) |

> Conversation summaries and walkthrough artifacts are automatically available at the start of each session. Solution docs require explicit search. Rules are always loaded. Use the right tier for the right type of knowledge.

## Solution Doc Template

```markdown
---
title: [Descriptive title]
category: [category]
date: [YYYY-MM-DD]
components: [affected components]
tags: [searchable keywords]
---

# [Title]

## Symptom

[Exact error messages, observable behavior]

## Root Cause

[Technical explanation of why this happened]

## Solution

[Step-by-step fix with code examples]

## What Didn't Work

[Investigation steps that were dead ends and why — saves future time]

## Prevention

[How to avoid this in the future — tests, linting rules, patterns]

## Related

- [Links to related solution docs, rules, or issues]
```

## Rules

- Always create the category directory if it doesn't exist (`mkdir -p docs/solutions/[category]/`).
- Use kebab-case for filenames: `n-plus-one-brief-generation.md`.
- Include code examples — a solution without code is incomplete.
- Conversation walkthroughs already capture implementation context — solution docs should focus on the *reusable* problem/fix, not repeat the full narrative.
- Document dead ends — knowing what doesn't work is as valuable as what does.
- Never skip the Prevention section — that's where the compounding happens.
