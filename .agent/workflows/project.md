---
description: Interactive onboarding — collects project context and writes 10_project.md
---

# Project Onboarding

Collect project context from the user and populate `.agent/rules/10_project.md`. This workflow functions as a strict product manager, interrogating the user's answers for depth to ensure the project foundation is solid before any code is written.

## Phase 1: Rigorous Interrogation (The YC Diagnostic)

Read `.agent/rules/10_project.md`. Identify which sections still only contain HTML comment placeholders (no real content). If all are filled, exist successfully unless the user overrides.

For each unfilled section, ask the user **exactly one question at a time** in the order below. **Do not batch questions.**

After each answer, you **must actively review the user's answer against the forcing functions below** before proceeding. If answers use buzzwords ("better UX"), lack measurable outcomes, or gloss over constraints, you must challenge the user and demand specificity.

| # | Section | What to ask | The Depth Check (Enforce Before Proceeding!) |
|---|---------|-------------|-----------------------------------------------|
| 1 | Name | What is the project called? | (Basic validation: is it a valid string?) |
| 2 | Vision | Describe in one paragraph: what does this project do, what problem does it solve, and why does it matter? | **Status Quo & Premise Challenge**: What are users doing *right now* to solve this problem badly, and what does that workaround cost them? Is there a simpler way to achieve the exact same business goal without this project? |
| 3 | Goals | What are the primary objectives? What does success look like? | **Demand Reality**: Reject "Growth rate is not a vision." What does success look like in measurable behavior? People liking the idea is not demand. |
| 4 | Users | Who uses this product? What are their key needs and pain points? | **Desperate Specificity**: Reject generic category filters ("SMBs", "Marketing teams"). Force the user to name the actual human role: What's their title? What gets them fired? |
| 5 | Problems & Pain Points | (Optional) What specific frustrations, time wastes, or financial costs is the user currently experiencing? Feel free to skip. | **Bleeding Neck Check**: If answered, does this articulate a real, acute problem rather than a mild inconvenience? |
| 6 | Competitive Landscape | (Optional) Who are the alternatives/competitors, and why is this solution uniquely better? Feel free to skip. | **True Moat Check**: If answered, is the differentiator a real advantage (e.g., proprietary data, radical simplicity, existing distribution) or just a feature claim? |
| 7 | Constraints | Are there non-negotiable limitations? (timeline, budget, regulatory, compatibility, business rules) | **Narrowest Wedge**: What is the absolute smallest version of this platform that delivers value against these constraints? Ensure the constraints don't represent a "Platform Vision" trap (e.g. "We need to build the full platform before anyone can really use it"). |

## Phase 2: Product Synthesis

Once all sections pass the depth checks, compile the collected information into the `10_project.md` format.

**Present this draft to the user for a final "CEO-style" review.** 
Do not write the file yet!

Ask: "Does this accurately reflect the product vision, or did I miss any crucial constraints? Please review this drafted context before I lock it in."

## Phase 3: File Output & Handoff

1. Once the user approves the synthesis, write the updated `10_project.md` preserving the YAML frontmatter (`trigger: always_on`) and section structure. Replace the HTML comment placeholders with the user's finalized answers.
2. Ask the user if they would like to establish the visual identity right now by running the `/design-system` workflow.
