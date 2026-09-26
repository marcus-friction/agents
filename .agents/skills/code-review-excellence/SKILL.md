---
name: code-review-excellence
description: Guide specific, actionable, evidence-backed code review feedback without style noise. Use as the method layer inside a multi-angle review or when improving review quality.
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
| Logic errors | Formatting (Spotless/ESLint handles this) |
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
| "Performance concern here" | "This `userRepository.findAll()` loads ~5K records into memory. Use `PageRequest.of(0, 50)` or a scoped query" |
| "Needs tests" | "Add a test for the case where `discount > subtotal` — currently returns a negative total" |

### Use the Parent Severity Contract

- **P0:** catastrophic and immediate.
- **P1:** concrete merge blocker.
- **P2:** bounded defect or material gap.
- **P3:** concrete low-impact issue, never a taste preference.
- A genuine question is not a finding until the answer establishes a defect.

### Keep Positive Notes Proportionate

- A brief positive note can identify a pattern worth preserving, but it must not
  displace findings, applicability, evidence gaps, or the verdict.

## Review Order

For the `review` workflow, follow this sequence:

1. **Understand** — read the context, trace the flow
2. **Correctness** — does the code do what it claims?
3. **Standards** — does it follow project conventions?
4. **Security** — any vulnerabilities introduced?
5. **Performance** — any scalability concerns?
6. **Architecture** — does it respect layer boundaries?
7. **Accessibility** — UI changes meet WCAG AA?
8. **Tests** — trace affected tests and confirm each is updated or still valid;
   map changed outcomes and meaningful failures to executed tests and coverage
   evidence. A passing suite alone does not establish coverage. For
   behavior-free edits, explain why tests are not applicable.
9. **Report** — organized by severity, with specific fixes

## Anti-Patterns

- **Rubber stamping** — "LGTM" without reading the code is worse than no review.
- **Gatekeeping** — blocking on personal preference, not project standards.
- **Scope creep** — requesting unrelated improvements ("while you're here, could you also...").
- **The rewrite request** — "I would have done this differently" isn't a review comment unless the current approach has concrete problems.
- **Bikeshedding** — spending 10 comments on naming while missing a SQL injection.
