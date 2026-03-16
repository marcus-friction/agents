---
description: Full engineering workflow — plan, execute, verify, compound
---

# Full Engineering Loop

Run all phases of the compound engineering workflow for a feature or bug fix.

CRITICAL: You MUST execute every step below IN ORDER. Do NOT skip any step. Do NOT jump ahead to coding or implementation. The plan phase (steps 1-2) MUST be completed and verified BEFORE any work begins.

## Steps

### 1. Plan
Enter PLANNING mode. Research the codebase, read relevant rules, and check `docs/solutions/` for prior art. 
**Brainstorm Link:** Check `docs/brainstorms/` for recent brainstorms related to this feature. If found, carry over key decisions and link back using `(see brainstorm: docs/brainstorms/...)`.

Create a structured plan file.
- Format: `docs/plans/YYYY-MM-DD-NNN-<type>-<desc>-plan.md`
- Detail Level: Choose MINIMAL, MORE, or A LOT based on complexity. Follow project templates.
- Request user review. Do not proceed until approved.

**GATE: STOP.** Verify that a plan file was created in `docs/plans/`. Do NOT proceed to step 2 until a written plan exists and is approved.

### 2. Deepen the Plan
After approval, do a second deeper research pass:
- Read framework docs (via web search) for any APIs you're unsure about.
- Check git history for related past changes.
- Read `SKILL.md` files for any skills referenced in the plan.
- Verify component boundaries align with existing architecture (`20_stack.md`).
- Update the plan file with the new findings.

**GATE: STOP.** Confirm the plan has been deepened and updated. Do NOT proceed to step 3 without a deepened plan.

### 3. Execute
Enter EXECUTION mode. Implement the changes strictly per the deepened plan. Commit logical units of work.

**GATE: STOP.** Verify that implementation work was performed (files were created or modified). Do NOT proceed to step 4 if no code changes were made.

### 4. Verify
Enter VERIFICATION mode. Run the full test/lint suite:
- Backend: `./vendor/bin/phpstan analyse`, `./vendor/bin/pint --test`, `sail test`
- Frontend: `npx eslint .`, `npx nuxi typecheck`, `npx vitest run`
- Browser-test affected pages if UI changes are involved.
- Fix any issues found — stay in VERIFICATION until clean.

### 5. Review (Self)
Run `/review` workflow to do a multi-angle pass over the changes (Standards, Security, Performance). Generate `todos/*.md` for findings and resolve any P1 blockers.

### 6. Resolve TODOs
Search the changed files for any `TODO`, `FIXME`, or `HACK` comments introduced during execution. Resolve or explicitly flag them for the user.

### 7. Compound
Run `/compound` to document any non-trivial learnings from this work. If nothing was learned (straightforward implementation), skip.

### 8. Summary
Create `walkthrough.md` documenting what was built, what was tested, and validation results.

## Rules
- Never skip step 1 or step 2 — even for "quick" fixes.
- The user must approve the plan before execution begins.
- Run the full verification suite, not just the tests you think are relevant.
- The compound step is not optional for debugging or tricky implementations.
