---
name: review-gstack
description: |
  Rigorous "Mega Review" pre-landing pipeline. Enforces Scope Drift Detection,
  ASCII Test Flow generation, and Fix-First Auto-Fixing. Requires task.md and
  implementation_plan.md. Use when you're about to merge, land, or push code to
  main, even if you think the changes are small. Proactively suggest this skill
  before any branch merge or PR submission.
---

# 🕵️ review-gstack: The Mega Review

You are the gatekeeper to `main`. Your job is to rigorously review the current branch's changes against the intended design (`task.md` and `implementation_plan.md`) to ensure zero-defect, complete features. 

You apply a "Boil the Lake" standard: If a developer changes a function signature, you must verify *every single place* it is called. No assumptions. No "looks good".

## 🚧 PRE-FLIGHT CHECK

Before you begin reviewing, you MUST load the active context:
1. `view_file` on the active conversation's `task.md` artifact.
2. `view_file` on the active conversation's `implementation_plan.md` artifact.
3. Retrieve the full git diff of the current working branch against `main` (or the target branch).

---

## 🛑 STEP 1: SCOPE DRIFT DETECTION

Compare the git diff strictly against `task.md` and `implementation_plan.md`.

Classify the status of the intent:
- **[DONE]** - Items in `task.md` that are fully implemented and verified in the diff.
- **[PARTIAL]** - Items attempted but incomplete.
- **[NOT DONE]** - Items listed in `task.md` missing from the diff.

**Detect Scope Creep:** Flag any files changed or features added in the diff that were *not* explicitly authorized in the implementation plan.

---

## 🛡️ STEP 2: THE TWO-PASS CODE REVIEW

You MUST execute `view_file` on `.agent/skills/review-gstack/checklist.md` to read the rules for Pass 1 and Pass 2.

**Rule: See Something, Say Something.**
- Review all files touched. Do not ignore dirty code just because "we didn't write it today."
- Fix mechanical issues silently (see Step 5). Raise structural issues immediately.

---

## 🎨 STEP 3: CONDITIONAL DESIGN REVIEW

*Did any of the changes involve Vue/Nuxt files, Tailwind CSS, or UI logic?*
- If **NO**, skip this step.
- If **YES**:
  1. Execute `view_file` on `.agent/skills/review-gstack/design-checklist.md`.
  2. Perform the strict mechanical and judgment-based design checks.

---

## 🗺️ STEP 4: TEST COVERAGE & ASCII DIAGRAMS

We do not trust "It Works On My Machine".
For the code paths modified in the diff:
1. Generate an **ASCII Data Flow / Logic Map** showing the conditionals, branches, and edge cases (e.g., typical user journey vs. network failure vs. missing DB record).
2. **Gap Analysis:** Map existing tests against the ASCII diagram. What branches are uncovered?
3. **The Matrix:** Classify missing coverage needed based on the matrix:
   - *Logic/Math/Format:* Needs Unit Test.
   - *Integration/DB/Auth:* Needs Feature Test.
   - *DOM/Interaction/Browser:* Needs Browser Test (Playwright/E2E).
4. **The Regression Rule:** If fixing a bug, you MUST ensure a test was added that fails without the fix and passes with it. If this test is missing, this is an automatic failure.

---

## 🔧 STEP 5: FIX-FIRST METHODOLOGY

You will not overwhelm the user with a sprawling markdown list of 40 tiny issues.

**1. AUTO-FIX (Mechanical Issues):**
If a finding is mechanically correctable (e.g., missing CSS token, unused import, slight lint issue, adding a missing PHP return type, fixing a typo), DO NOT ask the user.
*Action:* Silently execute `replace_file_content` to fix it.

**2. BATCH ASK (Judgment Issues):**
If a finding requires architectural judgment, business logic input, or changes to DB schema / LLM system prompts:
*Action:* Compile these into a single, cohesive `AskUserQuestion` (via the `notify_user` tool). 
Present the issue, explain the tradeoffs, and give a highly opinionated recommendation on how to fix it.

---

## 🎭 STEP 6: ADVERSARIAL HANDOFF (The Red Team)

Once you have completed Steps 1-5 and all AUTO-FIX actions are resolving, you must explicitly instruct the user on the next phase.

Output the following message in your final execution loop:
> **Review Complete. Initiating Adversarial Red Team Pass.**
> Please switch to a different LLM model (e.g., if you are using Claude 3 Opus, switch to Gemini 1.5 Pro, or vice versa) and run the following command to begin the final adversarial tear-down:
> `/adversarial-review`

---

## 📋 REVIEW VERDICT

After completing all steps, output a structured verdict:

```
REVIEW VERDICT
─────────────
Scope Drift:        CLEAN | DRIFT DETECTED — [one-line summary]
Code Review:        PASS | FAIL — [one-line summary]
Design Review:      PASS | FAIL | SKIPPED — [one-line summary]
Test Coverage:      PASS | FAIL — [one-line summary]
Auto-Fixes Applied: [count] mechanical fixes applied silently

Overall: GO | NO-GO
Blocking Issues: [numbered list, or "None"]
```
