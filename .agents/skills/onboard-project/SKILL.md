---
name: onboard-project
description: Make sure to use this skill whenever the user mentions setting up a fresh project, cloning a new repo, fixing agent blindness, establishing baselines, or asking 'what is this codebase'. It ensures the agent has the necessary architectural context and rules tailored to the tech stack.
---

# Project Onboarding Protocol

The `.agent` folder serves as the "brain" for future sessions. If the rules and architectural understanding established here are wrong or too generic, all future agent interactions in this repository will fail, be hallucinatory, or bloat the context window. Your goal here is to establish a rock-solid, concise baseline for this specific codebase.

Follow these steps exactly, completing them one by one.

## Step 1: Establish Context & Architecture Documentation
Do not guess. Ground your analysis in actual dependencies.
1. Run a deep analysis of the codebase by explicitly checking anchor files (e.g., `package.json`, `.env.example`, `composer.json`, `docker-compose.yml`, etc.).
2. Create an `ARCHITECTURE.md` file in the project root.
3. The `ARCHITECTURE.md` must be comprehensive and include:
   - **System Overview**: High-level map of the project.
   - **Data Flow & Storage**: Primary databases, APIs, and caching.
   - **Key Directories**: What lives where.
   - **Security/Auth boundaries**: How authentication is handled.

## Step 2: Adapt Project Context
You must adapt the new architecture context to the project's `README.md`. Keep your outputs concise and structured—use `README.template.md` as your structural reference template rather than writing sprawling paragraphs.
1. Rewrite `README.md` to capture the project's vision, goals, users, and constraints.
2. Rewrite the Stack section of `README.md` to document the precise technologies used (e.g., Vanilla JS vs Vue vs React, REST vs GraphQL, specific databases).
3. Rewrite the Infrastructure section of `README.md` to reflect deployment targets (e.g., Vercel, AWS, Forge) and CI/CD setups.

## Step 3: Design Rule Adaptation (If Frontend Exists)
If the project includes a frontend or user interface:
1. Examine the current design assets (CSS files, Tailwind config, font imports).
2. Update `DESIGN.md` to capture the project's design system, including:
   - Typography and font families.
   - Color palettes and themes.
   - Layout behaviors and specific styling paradigms (e.g., Swiss Brutalist, Utility-first Tailwind, Custom CSS variables).

## Step 4: Validate Workflows
Review the `.agents/skills/` directory. Ensure that none of the workflow scripts contain hardcoded references or assumptions that conflict with the new stack.
- For example: Check if an implementation workflow assumes `npm test` when the project actually uses `pnpm`, or if it attempts to compile frontend assets when it's a backend-only API.

## Step 5: Save State
1. If the user uses git, prompt them to review the changes and commit the onboarding setup.

## Completion
Once these 5 steps are complete, state that the project is successfully onboarded and ready for specialized workflows (like `/plan` or `/review-gstack`).
