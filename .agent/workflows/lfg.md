---
description: Full engineering workflow — plan, execute, verify, compound
---

# Full Engineering Loop

Run all phases of the compound engineering workflow for a feature or bug fix.

## Steps

1. **Plan.** Enter PLANNING mode. Research the codebase, read relevant rules, and check `docs/solutions/` for prior art on similar problems. Create `implementation_plan.md` and request user review. Do not proceed until approved.

2. **Deepen the plan.** After approval, do a second pass:
   - Read framework docs (via web search) for any APIs you're unsure about.
   - Check git history for related past changes.
   - Verify the plan aligns with existing rules (especially `20_stack.md`, `21_standards_laravel.md`, `22_standards_nuxt.md`).
   - Update the plan if the research reveals gaps.

3. **Execute.** Enter EXECUTION mode. Implement the changes per the plan. Commit logical units of work.

4. **Verify.** Enter VERIFICATION mode. Run the full test/lint suite:
   - Backend: `./vendor/bin/phpstan analyse`, `./vendor/bin/pint --test`, `sail test`
   - Frontend: `npx eslint .`, `npx nuxi typecheck`, `npx vitest run`
   - Browser-test affected pages if UI changes are involved.
   - Fix any issues found — stay in VERIFICATION until clean.

5. **Resolve TODOs.** Search the changed files for any `TODO`, `FIXME`, or `HACK` comments introduced during execution. Resolve or explicitly flag them for the user.

6. **Compound.** Run `/compound` to document any non-trivial learnings from this work. If nothing was learned (straightforward implementation), skip.

7. **Summary.** Create `walkthrough.md` documenting what was built, what was tested, and validation results.

## Rules

- Never skip step 1 — even for "quick" fixes.
- The user must approve the plan before execution begins.
- Run the full verification suite, not just the tests you think are relevant.
- The compound step is not optional for debugging or tricky implementations.
