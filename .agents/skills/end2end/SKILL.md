---
name: end2end
description: Full end-to-end (E2E) testing skill utilizing the browser. Make sure to use this skill whenever the user asks to "test the app", "run end to end tests", "verify the UI", "check if the app works", or wants you to use the browser to interact with and test the application flow. This skill orchestrates creating a test plan, getting user approval, navigating the application using the browser, independently fixing obstacles, and generating a progressive test report.
---

# End-to-End Testing (E2E) Workflow

You are executing an end-to-end browser test for the application. Your goal is to systematically verify functionality from a user's perspective, document failures, and independently fix issues as you encounter them.

Follow these steps precisely:

## 1. Scoping (Ask the User)
Before doing anything, ask the user what they want to test. Specifically, ask:
*   Do they want to test the full application or just a specific subset of functionality (e.g., recently worked on features)?
*   Are there any specific URLs, user personas, or paths that should be the focus?

## 2. Test Planning
Once the user provides the scope, create a detailed testing plan.
*   **Artifact Strategy**: Use your artifact tools to create a `test_plan.md` artifact outlining exactly which pages, interactions, and expected outcomes you will test.
*   **Task List**: Make sure you have a `task.md` created with a structured checklist (using `[ ]`, `[/]`, `[x]`) corresponding to the steps in your test plan. 

## 3. Approval
Wait for the user's explicit approval on the test plan and task list. Do NOT proceed to execution until the user explicitly approves the plan.

## 4. Execution & Independent Debugging
After user approval, systematically execute your test plan using the `browser_subagent`.

*   **Test Progressively**: Test one flow or page area at a time *so that you can isolate failures immediately before compounding errors*.
*   **Track Progress**: Update your `task.md` checklist markings continuously as you move through each step (e.g., `[/]` when starting, `[x]` when verified) *so the user has real-time observability into what is actively being tested*.
*   **Independent Fixes (Bounded)**: If you encounter a bug, obstacle, or unexpected behavior during your browser session, STOP and attempt to fix it locally if you have the codebase access and context.
    *   Investigate logs, code, and errors.
    *   Apply the fix locally so the next browser test step passes.
    *   **Do NOT commit to git**: Leave the changes uncommitted for the user to review. 
    *   **Fix-Loop Warning**: If a fix requires complex architectural changes, touches multiple unrelated files, or you enter a repetitive fix-loop, STOP attempting to fix it. Revert your changes and simply log it as an Unresolved Issue in the report. Do not compound errors.
    *   Re-run the step using the browser to verify the fix only if you successfully applied a bounded local fix.
*   **Keep Reporting**: Maintain a `progressive_testing_report.md` artifact as you go *so the final state of the test doesn't lose the granular details discovered along the way*.

## 5. Report Formatting
ALWAYS use this exact template for the `progressive_testing_report.md` artifact:

```markdown
# Progressive Testing Report: [Target Scope]

## Executive Summary
[High-level overview of test stability and overall outcome]

## Testing Milestones
### [Milestone Name]
- **Status**: [Pass/Fail/Fixed]
- **Outcome**: [What worked or failed]
- **Applied Fixes**: [Detailed summary of what was fixed, if anything. Leave blank if none]

## Unresolved Issues
- [List any issues that you could not fix independently]
```

## 6. Final Report
When all tasks in your plan are checked off, finalize the `progressive_testing_report.md` utilizing the template above. Let the user know the testing is complete.
