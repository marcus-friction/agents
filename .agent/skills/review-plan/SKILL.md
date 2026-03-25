---
name: review-plan
description: |
  Meta-level guidance for reviewing and challenging implementation plans using the
  Mega Plan Review pipeline. Use whenever you've drafted an implementation plan or
  design doc and need to evaluate it for completeness, scope gaps, and architectural
  flaws before proceeding to implementation. Proactively suggest this skill after
  any /plan workflow or when the user says "review my plan" or "is this plan solid".
---

# Review Plan Skill

Brutally evaluate your drafted implementation plan before finalizing it. The goal is to catch architectural flaws, scope gaps, and edge cases early using a structured pipeline.

## Preamble & Interaction Rules

During the review, you must follow the strict `AskUserQuestion` protocol:
- **Interactive Questioning:** Ask questions interactively, one by one. Do NOT batch all questions at the end of the review. Wait for the user's response before proceeding.
- **Format:** For every question, describe the problem, present 2-3 concrete options, and provide an opinionated recommendation based on engineering preferences.
- **Tradeoffs:** Explain the tradeoffs (Effort vs. Risk) for each option.

---

## Phase 1: CEO Review (Strategy & Scope)

### Step 0: Mode Selection
Explicitly declare the review mode based on the plan's intent:
1. **SCOPE EXPANSION:** Adding net-new capabilities. High risk.
2. **SELECTIVE EXPANSION:** Modifying existing flows to add edge-case value.
3. **HOLD SCOPE:** Refactoring or performance work. No new user-facing features.
4. **SCOPE REDUCTION:** Deleting features or ripping out legacy systems.

### Step 1: Premise Challenge
- Are we solving the right problem? Challenge the core premise of the implementation plan. Is there a simpler way to achieve the exact same business goal?

### Step 2: Dream State Mapping
- How does this implementation specifically advance the project's core vision (`10_project.md`) and get us closer to the ideal product state?

---

## Phase 2: Design Review (UI/UX)
*Trigger this phase ONLY if the plan includes UI/frontend scope.*

Enforce the following 7-Pass Structure:
1. **The Pruning Pass (Subtraction Default):** Does every UI element earn its pixels? Reduce cognitive load. "If it doesn't earn its pixels, cut it."
2. **The Slop Pass (AI Slop Avoidance):** Audit against the "AI Slop" blacklist. Remove generic 3-column feature grids, floating blobs, bubbly borders, and default font stacks. Demand specific, intentional UI decisions leveraging `23_design_system.md`.
3. **The State Matrix Pass:** Are loading, empty, error, success, and partial states explicitly defined? Empty states must have warmth, a primary action, and context.
4. **The Microcopy Pass:** Favor utility over aspiration. Remove generic hero copy.
5. **The Design System Alignment Pass:** Audit against existing components. Does the plan invent new UI paradigms unnecessarily?
6. **The Responsive & Accessibility Pass:** Enforce keyboard navigation, ARIA landmarks, contrast, and intentional mobile layouts instead of just "stacking on mobile."
7. **The Developer Handoff Pass:** Surface and resolve all unresolved design decisions via `AskUserQuestion` before engineering begins.

---

## Phase 3: Eng Review (Architecture & Completeness)

### Step 1: The Completeness Principle
- **"Boil the lake."** Does the plan tackle the project **as a whole**? Handle all documented edge cases. No deferred tasks (no "we will do this later" or "TODOs"). If an issue is within the blast radius and takes <1 day of effort, do it now.

### Checklist Anchors
Cross-reference these rule files during the review to catch domain-specific gaps:
- `10_project.md` — Does the plan align with project vision and goals?
- `23_design_system.md` — Does the plan reuse existing design tokens (if UI scope)?
- `24_accessibility.md` — Are accessibility requirements addressed (if UI scope)?

### Step 2: Data Flow & State Verification
- **ASCII Diagrams:** For any complex data transformations, database migrations, or state changes, mandate an ASCII diagram to visualize the data flow.
- **Explicit > Clever:** Does the plan favor explicit, readable code over clever, magical abstractions?

### Step 3: Performance, Security & QA
- **Scalability & Security:** Check for N+1 query risks, missing Policies (authorization), and strict input validation.
- **Test Coverage Map:** Map every new codepath to specific test types (unit, E2E). Concrete verification steps only (e.g., "Add `it('handles X')` to `OrderTest`").
- **Zero Silent Failures:** Ensure the system fails loudly and safely. Create a **Failure Modes Registry** table documenting how the implementation handles nil, empty, and timeout edge cases.

---

## Phase 4: Required Outputs

The finalized plan must explicitly include these two sections:
1. **NOT in scope:** Explicitly define what was considered but deferred or excluded, with a one-line rationale for each.
2. **What already exists:** List the existing patterns, KIs, and components that this plan will reuse to prevent duplication.

---

## Phase 5: Outside Voice (Adversarial Challenge)

Before finalizing, perform an adversarial check:
- Adopt an adversarial persona to find the blind spots in the plan.
- What happens if the database locks? What if the UI state desyncs? What if the third-party API is down?
- Force the plan to address these before developer execution begins.

---

## Review Verdict Output

After completing all phases, output a structured verdict:

```
REVIEW VERDICT
─────────────
Phase 1 (Strategy):      PASS | FAIL — [one-line summary]
Phase 2 (Design):        PASS | FAIL | SKIPPED — [one-line summary]
Phase 3 (Engineering):   PASS | FAIL — [one-line summary]
Phase 4 (Outputs):       PASS | FAIL — [one-line summary]
Phase 5 (Adversarial):   PASS | FAIL — [one-line summary]

Overall: GO | NO-GO
Blocking Issues: [numbered list, or "None"]
```
