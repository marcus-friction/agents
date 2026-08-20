---
name: compound
description: >
  Document a recently solved problem as structured, searchable knowledge so future work
  benefits from past solutions. Use this skill after solving non-trivial bugs, debugging
  sessions, or tricky implementations. Proactively suggest this skill when a session
  involved significant troubleshooting, dead-end investigation, or a fix that others
  would likely encounter again.
---

# Compound Knowledge

Capture a recently solved problem as structured documentation so future work benefits from past solutions.

## When to Use

After solving a non-trivial bug, debugging session, or tricky implementation. Trivial fixes (typos, obvious errors) don't need compounding.

## The 5-Step Extraction

Process the information through these 5 analytical steps before writing:

1. **Context Analyzer:** Identify the exact error messages, observable symptoms, and affected components.
2. **Solution Extractor:** Extract the precise technical solution, including working code snippets and configuration changes.
3. **Related Docs Finder:** Search `docs/solutions/` for related existing documentation.
4. **Prevention Strategist:** Determine how to prevent this issue in the future (e.g., tests, linting rules, architectural patterns).
5. **Category Classifier:** Choose the most appropriate category:
   - `build-errors/`
   - `runtime-errors/`
   - `performance/`
   - `database/`
   - `security/`
   - `deployment/`
   - `ui-bugs/`
   - `integration/`

## Writing the Document

Create `docs/solutions/[category]/[slug].md` using the template below.

## Auto-Triggered Post-Review

Immediately after generating the solution document, perform a targeted review based on the category. These categories get extra scrutiny because incomplete solutions in these areas tend to introduce silent regressions:
- **Performance:** Does the solution prevent N+1 queries or memory bloat?
- **Security:** Does the solution introduce any injection risks or bypass authorization?
- **Database:** Are any migrations or schema changes documented correctly?
If the review identifies gaps, update the solution document before concluding.

## Knowledge Tiers

Knowledge exists at multiple levels. Place learnings at the right tier:

| Tier | Location | Persistence | When to use |
|------|----------|-------------|-------------|
| **Conversation memory** | Agent brain / conversation logs | Automatic — summaries carry forward | Always happens — no action needed |
| **Solution docs** | `docs/solutions/[category]/` | Git-tracked, searchable | Default target for compound — specific problem/solution pairs |
| **Rules** | `AGENTS.md` | Always-on or model-decision | Recurring patterns seen in 3+ solutions — propose promotion |
| **Skills** | `.agents/skills/` | On-demand, loaded by name | Reusable expertise checklists (review, research) |

> Conversation summaries and walkthrough artifacts are automatically available at the start of each session. Solution docs require explicit search. Rules are always loaded. Use the right tier for the right type of knowledge.

## Solution Doc Template

Use the template in `references/solution-template.md` for all solution docs. The template includes YAML frontmatter for metadata and sections for Symptom, Root Cause, Solution, What Didn't Work, Prevention, and Related links.

## Rules

- Always create the category directory if it doesn't exist (`mkdir -p docs/solutions/[category]/`).
- Use kebab-case for filenames: `n-plus-one-brief-generation.md`.
- Include code examples — a solution without code is incomplete.
- Conversation walkthroughs already capture implementation context — solution docs should focus on the *reusable* problem/fix, not repeat the full narrative.
- Document dead ends — knowing what doesn't work is as valuable as what does.
- Never skip the Prevention section — that's where the compounding happens.
