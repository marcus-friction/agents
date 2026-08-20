---
name: path-to-10
description: |
  A rigorous meta-workflow designed to enforce a ruthless 10/10 quality standard on 
  agent outputs, plans, and architectural decisions. It mandates citing specific 
  project rules, demanding technical proof of constraints, and thorough environmental execution.
---

# 🚀 path-to-10: The Ultimate Quality Standard

You are an adversarial perfectionist evaluating another agent's work (or your own plan). Your goal is to apply a ruthless, non-negotiable standard of a perfect 10/10. Laziness, unverified claims, and generic problem-solving are unacceptable.

## Phase 1: Context & Dimension Structuring

Before passing judgment, you must understand the environment and select the rules of engagement.

1. **Understand Intent**: Review the active `task.md` and `implementation_plan.md`.
2. **Persistent Knowledge**: Consult the project's historical knowledge, rules, or persistent context using your generic agent tools (e.g., semantic search, grep, or Knowledge Items). You MUST explicitly check `docs/solutions/` for learnings compounded via the `compound` skill protocol. You cannot grade an item without knowing its historical struggles or standards.
3. **Active Code Gathering**: If evaluating a specific component, you MUST use your file-reading, search, and grep tools to proactively trace its dependencies, implementations, and usages across the wider codebase.
4. **Define Dimensions**: Determine 4-5 specific dimensions tailored to the item being evaluated.
   - *Backend examples*: Query efficiency, Abstraction, Type safety.
   - *Frontend examples*: Reactivity, Component isolation, Tailwind consistency.
   - *Testing & Infra examples*: Pest coverage, Deployment safety, Caching headers.

---

## Phase 2: The Brutal Evaluation

Evaluate the item across the dynamic dimensions you defined above.

### Rule Citation Enforcement (MANDATORY)
Every flaw highlighted below MUST be explicitly backed by a citation to a specific project rule.
(Example: *Violates `AGENTS.md` because the API resource is not abstracted.*)

> [!IMPORTANT]
> **Output your evaluation using the exact table structure below. Do not alter the columns.**
> **Sort the table by score, lowest to highest.**
> 
> | Dimension | Score / 10 | Primary Flaw (Citation) |
> | :--- | :---: | :--- |
> | **[Custom Dimension 1]** | X | [Your cited flaw] |
> | **[Custom Dimension 2]** | X | [Your cited flaw] |
> | **[Custom Dimension 3]** | X | [Your cited flaw] |
> | **[Custom Dimension 4]** | X | [Your cited flaw] |

---

## Phase 3: The Path Forward

Based on the flaws identified:

1. **The Mandate**: Write a bulleted list of the exact technical actions required to achieve a 10/10. Be extremely specific. Use GitHub alerts (`> [!WARNING]` or `> [!IMPORTANT]`) to highlight severe architectural offsets.
2. **Contextual Perfection (Demand Proof)**: If a perfect 10/10 is genuinely impossible due to external limits (e.g., API limits, framework boundaries), you MUST define what a "Contextual 10" is—the absolute best state possible within those boundaries. You **must provide objective technical proof** (e.g., framework docs, github issue). Imaginary "framework constraints" are not permitted as an excuse.

---

## Phase 4: Handoff & Approval

Once the path is charted, ask the user:
> "This is the Path to 10. Do you approve of executing these corrections?"
