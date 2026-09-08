---
name: code-review-excellence
description: Meta-level code review guidance — how to review well, not just what to check
---

# Code Review Excellence Skill

How to conduct a high-quality code review. This skill provides meta-level
guidance for the `review` workflow — the domain-specific checklists (security,
performance, architecture, accessibility) tell you *what* to check; this skill
tells you *how* to review well.

## Principles

### Read for Intent First

1. **Understand the goal** before reading the code. What problem does this change solve?
2. **Read the PR description / commit messages** first — context shapes your review.
3. **Trace the flow** — follow the request from entry point to storage and back. Don't review files in isolation.

### Separate Substance from Style

| Substance (flag) | Style (skip) |
|---|---|
| Logic errors | Formatting (Pint/ESLint handles this) |
| Missing edge cases | Variable naming preferences |
| Security gaps | Blank line placement |
| Architectural violations | Import ordering |
| Missing tests | Comment phrasing |

If a linter or formatter can catch it, don't spend review time on it.

### One Concern Per Comment

- Each comment should address exactly one issue with a clear ask.
- Bad: "This function is too long and also the variable naming is confusing and there might be a race condition."
- Good: Three separate comments, each with one specific issue and suggestion.

## Writing Effective Feedback

### Be Specific and Actionable

| ❌ Vague | ✅ Actionable |
|---|---|
| "This could be better" | "Extract lines 42-58 into a `calculateDiscount()` method — it's reused in OrderAction too" |
| "Performance concern here" | "This `User::all()` loads ~5K records into memory. Use `paginate(50)` or a scoped query" |
| "Needs tests" | "Add a test for the case where `discount > subtotal` — currently returns a negative total" |

### Use Prefixes for Severity

- **`🔴 Must:`** — blocks merging. Security, correctness, data integrity.
- **`🟡 Should:`** — strong recommendation. Missing tests, standards violations.
- **`🟢 Nit:`** — optional improvement. Take it or leave it.
- **`❓ Question:`** — genuine question, not a disguised demand your way.

### Acknowledge Good Work

- Call out clever solutions, good test coverage, or clean abstractions.
- "Nice use of `cursorPaginate()` here — much better than offset pagination for this dataset."
- A review that's only criticism is demoralizing and incomplete.

## Review Order

For the `review` workflow, follow this sequence:

1. **Understand** — read the context, trace the flow
2. **Correctness** — does the code do what it claims?
3. **Standards** — does it follow project conventions?
4. **Security** — any vulnerabilities introduced?
5. **Performance** — any scalability concerns?
6. **Architecture** — does it respect layer boundaries?
7. **Accessibility** — UI changes meet WCAG AA?
8. **Tests** — adequate coverage for new/changed code?
9. **Report** — organized by severity, with specific fixes

## Anti-Patterns

- **Rubber stamping** — "LGTM" without reading the code is worse than no review.
- **Gatekeeping** — blocking on personal preference, not project standards.
- **Scope creep** — requesting unrelated improvements ("while you're here, could you also...").
- **The rewrite request** — "I would have done this differently" isn't a review comment unless the current approach has concrete problems.
- **Bikeshedding** — spending 10 comments on naming while missing a SQL injection.
