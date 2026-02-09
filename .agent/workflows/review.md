---
description: Multi-angle code review before merging
---

# Comprehensive Review

Perform a thorough code review from multiple perspectives, sequentially.

If the `code-review-excellence` skill exists, read it first for meta-level guidance on how to review well.

## When to Use

Before opening a PR, or when the user asks for a review of recent changes.

## Steps

1. **Identify scope.** Determine which files changed. Use `git diff` against the base branch.

2. **Standards pass.** Check all changes against the relevant coding standards:
   - PHP changes → `21_standards_laravel.md`
   - Vue/Nuxt changes → `22_standards_nuxt.md`
   - Styling changes → `23_design_system.md`
   - Flag any deviations.

3. **Security pass.** Review changes through the lens of `50_security.md`:
   - User input handling — is everything validated?
   - Authorization — are policies enforced?
   - Secrets — any hardcoded values or exposed keys?
   - SQL injection, XSS, CSRF — applicable?
   If the `security-review` skill exists, read it for deeper guidance.

4. **Performance pass.** Look for:
   - N+1 queries (missing eager loading)
   - Unnecessary database calls in loops
   - Missing indexes for new query patterns
   - Large payloads without pagination
   - Frontend: unnecessary re-renders, missing `lazy` loading
   If the `performance-review` skill exists, read it for deeper guidance.

5. **Architecture pass.** Verify:
   - Business logic in Actions, not controllers
   - Thin controllers pattern maintained
   - API versioning respected
   - No circular dependencies introduced
   - Design system tokens used (not hardcoded values)
   If the `architecture-review` skill exists, read it for deeper guidance.

6. **Accessibility & UI pass.** For changes touching frontend code:
   - Design system tokens used (no hardcoded colors, spacing)
   - Responsive at all breakpoints (320px → 1440px)
   - Semantic HTML, keyboard accessible, WCAG AA contrast
   - Loading, empty, and error states handled
   If the `ui-accessibility-review` skill exists, read it for the full checklist.

7. **Test coverage pass.** Check:
   - New code has test coverage
   - Edge cases are tested
   - Test naming follows conventions
   - No tests were removed or skipped without justification

8. **Report.** Present findings organized by severity:
   - 🔴 **Must fix** — security issues, broken tests, data integrity risks
   - 🟡 **Should fix** — standards violations, missing tests, performance concerns
   - 🟢 **Consider** — style suggestions, minor improvements
   Include specific file/line references and suggested fixes.

## Rules

- Run all passes even if early ones find issues — give the complete picture.
- Be specific — "this might have performance issues" is not useful. "Line 42: `User::all()` inside a loop will cause N+1" is.
- Don't nitpick formatting if Pint/ESLint will handle it.
- If no issues found in a pass, say so explicitly — confirmation is valuable.
