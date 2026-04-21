---
name: brainstorm
description: Structured brainstorming for exploring new features or solving complex problems
---

# Brainstorming Workflow

Run a structured divergent-to-convergent thinking process before diving into planning or implementation. Useful when exploring a new feature space or tackling a thorny architectural problem.

## Steps

### 1. Frame & Pressure Test
Define the problem space, constraints, and desired outcomes, then rigorously challenge the premise:
- **Problem:** What are we trying to solve?
- **Constraints:** What technical, business, or timeline constraints exist?
- **Success:** What does a successful outcome look like?
- **The Pressure Test:** 
  - Is this solving the real user problem, or a proxy for a more important one? 
  - Are we duplicating something that already covers this?
  - What happens if we do nothing?
  - Is there a nearby framing that creates more user value without more carrying cost?

### 2. Diverge (Exploration)
Explore multiple, distinctly different approaches to solving the problem. Do not commit to one yet. Consider:
- **The Idealist approach:** If we had no constraints, how would we build this?
- **The Pragmatist approach:** What is the simplest, fastest way to get 80% of the value?
- **The Pattern approach:** How do the existing frameworks (`Laravel`, `Nuxt`) handle this natively?
- **The 'Do Nothing' approach:** Can we solve this without writing new code?

*Note: The agent should list the pros/cons, feasibility, and risk for each approach.*

### 3. Converge (Synthesis)
Evaluate the explored options against the constraints from Step 1.
- Identify patterns or hybrid approaches.
- Rank the options based on viability.
- Select a recommended approach.

### 4. Output
Generate a structured brief.

Write the output to `docs/brainstorms/YYYY-MM-DD-[topic]-brainstorm.md`.

## Output Format
```markdown
# Brainstorm: [Topic]

**Date:** YYYY-MM-DD
**Status:** Completed

## 1. Framing
- **Goal:** [brief]
- **Constraints:** [brief]

## 2. Exploration
[Summary of the 3-4 distinct approaches considered, with pros/cons]

## 3. Recommendation
**Chosen Approach:** [Name]
**Rationale:** [Why this won out]
**Rejected Alternatives:** [Why the others were dropped]

## 4. Open Questions
- [Any unknowns that need to be resolved during the Planning phase]
```

## Rules
- Brainstorming MUST output a file to `docs/brainstorms/`. Do not just output text to the chat.
- The output file should be used as the `origin:` reference when subsequently running `/lfg` (Planning phase).
