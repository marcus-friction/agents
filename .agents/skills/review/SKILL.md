---
name: review
description: Multi-angle code review before merging
---

# Comprehensive Review

Perform a thorough code review from multiple perspectives, sequentially.

If the `code-review-excellence` skill exists, read it first for meta-level guidance on how to review well.

## When to Use

Before opening a PR, or when the user asks for a review of recent changes.

## Argument Parsing / Modes
You can invoke this skill conditionally via argument hints:
- `mode:autofix`: Automatically apply `safe_auto` fixes without asking.
- `mode:report-only`: Strictly read-only output without modifying files.
- `base:<sha-or-ref>`: Provide a precise Git base for diffing.

## Steps

### 1. Identify Scope
Review all files changed **in this conversation thread**. Use `git diff` and your conversation context to build the file list. If the branch contains changes from a previous conversation, exclude those — focus only on what was created or modified during this complete thread.

### 2. Deep Dive & Action Routing
Before listing any findings, perform stress testing and Stakeholder Perspective Analysis:

**A. Stakeholder Perspective Analysis**
Examine the changes from these angles:
- **Developer:** Is the code maintainable, readable, and well-tested?
- **Ops:** Are there missing logs, bad error handling, or deployment risks?
- **End User:** Is the UI/UX negatively impacted? Is accessibility compromised?
- **Security:** Are we introducing vulnerabilities?
- **Business:** Does this align with the project goals?

**B. Action Routing & Fix Triggers**
Map every finding you discover into one of these actions:
| `autofix_class` | Meaning | Agent Action |
|---|---|---|
| `safe_auto` | Local, deterministic fix suitable for immediate autofix. | Fix silently in interactive/autofix mode. |
| `gated_auto` | Concrete fix, but alters behavior, contracts, or permissions. | Requires user approval before fixing. |
| `manual` | Actionable work that should be handed off. | Add to `task.md` residual work. |
| `advisory` | Report-only output (residual risks, rollout notes). | Keep in review report only. |

**C. Confidence Gating**
- Suppress findings below `0.60` confidence. 
- Exception: **P0 (Critical)** findings at `0.50+` confidence survive the gate — critical-but-uncertain issues must not be silently dropped.

### 3. Review Passes
Execute the following passes against the codebase, keeping the findings structured logically:

**Standards** — Check all changes against the relevant coding standards:
   - PHP changes → `21_standards_laravel.md`
   - Vue/Nuxt changes → `22_standards_nuxt.md`
   - Styling changes → `23_design_system.md`
   - **Knowledge Re-use:** Did the implementation re-invent the wheel or correctly leverage compounded learnings from existing Knowledge Items (KIs)?
   - Flag any deviations.

**Security** — Review changes through the lens of `50_security.md`:
   - User input handling — is everything validated?
   - Authorization — are policies enforced?
   - Secrets — any hardcoded values or exposed keys?
   - SQL injection, XSS, CSRF — applicable?
   If the `security-review` skill exists, read it for deeper guidance.

**Performance** — Review changes through the lens of `25_caching_performance.md`. Look for:
   - N+1 queries (missing eager loading)
   - Unnecessary database calls in loops
   - Missing indexes for new query patterns
   - Large payloads without pagination
   - Frontend: unnecessary re-renders, missing `lazy` loading
   If the `performance-review` skill exists, read it for deeper guidance.

**Architecture** — Verify:
   - Business logic in Actions, not controllers
   - Thin controllers pattern maintained
   - API versioning respected
   - No circular dependencies introduced
   - Design system tokens used (not hardcoded values)
   If the `architecture-review` skill exists, read it for deeper guidance.

**SEO & UI** — Check:
   - Semantic HTML and heading hierarchy
   - Core Web Vitals impact (LCP, CLS, INP)
   - Structured data / Schema.org where applicable
   If the `seo-review` skill exists, read it for deeper guidance.

**Accessibility** — Review changes through the lens of `24_accessibility.md`. For frontend code:
   - Design system tokens used (no hardcoded colors, spacing)
   - Responsive at all breakpoints (320px → 1440px)
   - Semantic HTML, keyboard accessible, WCAG AA contrast
   - Loading, empty, and error states handled
   If the `ui-accessibility-review` skill exists, read it for the full checklist.

**Testing** — Check:
   - New code has test coverage
   - Edge cases are tested
   - Test naming follows conventions
   - No tests were removed or skipped without justification

### 4. Reporting
When the review is complete, you must present the findings in three ways:

1. **Detailed Report Artifact:** Create a **conversation artifact** containing the full review details.
2. **Task Artifact:** Add `manual` and unapproved `gated_auto` findings as executable items to the Task artifact (`task.md`).
3. **Chat Summary:** Communicate the report and the updated task list to the user in the chat using a **pipe-delimited Markdown table** for the findings.

**Detailed Report Artifact Format:**

Group findings by severity, with a detailed block for each item:

```markdown
# Review: [Short Scope Description]
**Date:** YYYY-MM-DD
**Files reviewed:** [count]

---

## 🚨 Critical (P0)
> Must fix before merge. Exploitable vulnerability, data loss/corruption, hard breakage.

## 🔴 High (P1)
> Should fix. High-impact defect likely hit in normal usage, breaking contract.

## 🟡 Moderate (P2)
> Fix if straightforward. Meaningful downside but narrower scope (edge case, perf regression).

## 🟢 Low (P3) / Advisory
> User's discretion. Formatting, style recommendations, or advisory notes.
```

Each finding within a group follows this structure:

```markdown
### [Short Description]
**File(s):** `path/to/file.ext`
**Class:** `safe_auto` | `gated_auto` | `manual` | `advisory`

**Issue:** [Detailed description of what is wrong]

**Recommended Fix:** [Specific instructions or code snippet to resolve]
```

If a severity group has no findings, include the heading with "No findings." beneath it — confirmation is valuable.


## Rules

- Run all passes even if early ones find issues — give the complete picture.
- Be specific — "this might have performance issues" is not useful. "Line 42: `User::all()` inside a loop will cause N+1" is.
- Don't nitpick formatting if Pint/ESLint will handle it.
- If no issues found in a pass, say so explicitly — confirmation is valuable.