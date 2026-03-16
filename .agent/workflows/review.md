---
description: Multi-angle code review before merging
---

# Comprehensive Review

Perform a thorough code review from multiple perspectives, sequentially.

If the `code-review-excellence` skill exists, read it first for meta-level guidance on how to review well.

## When to Use

Before opening a PR, or when the user asks for a review of recent changes.

## Steps

### 1. Identify Scope
Determine which files changed. Use `git diff` against the base branch.

### 2. The Ultra-Thinking Phase
Before listing any findings, perform two deep-dive analyses:

**A. Stakeholder Perspective Analysis**
Examine the changes from these angles:
- **Developer:** Is the code maintainable, readable, and well-tested?
- **Ops:** Are there missing logs, bad error handling, or deployment risks?
- **End User:** Is the UI/UX negatively impacted? Is accessibility compromised?
- **Security:** Are we introducing vulnerabilities?
- **Business:** Does this align with the project goals?

**B. Scenario Exploration**
Imagine how the code behaves under stress:
- **Happy Path:** Does it work when everything is perfect?
- **Boundary Conditions:** What happens with empty inputs, massive inputs, or malformed data?
- **State Changes:** What if a database transaction fails halfway through?
- **Concurrent Access:** What if two users do this at exactly the same time?

### 3. Review Passes
Execute the following passes against the codebase, keeping the Ultra-Thinking insights in mind:
- **Standards:** Check `21_standards_laravel.md`, `22_standards_nuxt.md`, `23_design_system.md`.
- **Security:** Check `50_security.md` (injection, auth, secrets).
- **Performance:** Look for N+1 queries, missing indexes, large payloads.
- **Architecture:** Check Component boundaries, Action usage, API versioning.
- **SEO & UI:** Check semantic HTML, Core Web Vitals, Schema, and GEO readiness.
- **Accessibility:** Check WCAG contrast, keyboard navigation, responsive design.
- **Testing:** Verify test coverage and edge cases.

### 4. Findings & File-Todos Generation
Do NOT just list the findings lazily in chat. For EVERY finding, you MUST create a structured markdown file in the `todos/` directory.

File naming format: `todos/YYYYMMDD-pending-[P1/P2/P3]-[short-description].md`

Inside each todo file, include:
```markdown
# [Short Description]
**Severity:** [P1 (Critical) / P2 (Important) / P3 (Minor)]
**File(s):** [path/to/file.ext]

## Issue
[Detailed description of what is wrong]

## Recommended Fix
[Specific instructions or code snippet to resolve]
```

### 5. Report & Blocking
Summarize the created `todos/` files for the user.

**GATE: STOP.** If ANY `P1` (Critical) findings exist (e.g., security flaws, broken tests, severe data integrity risks), you MUST explicitly state that the workflow is BLOCKED. Require the user to fix the P1 findings (or authorize you to fix them) before the review can be considered "passed".

## Rules

- Run all passes even if early ones find issues — give the complete picture.
- Be specific — "this might have performance issues" is not useful. "Line 42: `User::all()` inside a loop will cause N+1" is.
- Don't nitpick formatting if Pint/ESLint will handle it.
- If no issues found in a pass, say so explicitly — confirmation is valuable.
