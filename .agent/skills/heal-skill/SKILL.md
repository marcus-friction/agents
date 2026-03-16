---
name: heal-skill
description: Self-repair skill for fixing malfunctioning skills or workflows
argument-hint: "[name of failing skill/workflow]"
disable-model-invocation: true
---

# Heal Skill

Use this skill when an existing skill or workflow is producing bad outputs, getting stuck in loops, or failing to adhere to instructions. This process analyzes the failure, patches the instruction file, and verifies the fix.

## Process

### 1. Identify the Failure
- Read the conversation history to understand how the target skill/workflow failed.
- Was it missing context? Was an instruction ambiguous? Did it use the wrong tool? 

### 2. Analyze the Skill File
- Load the corresponding `SKILL.md` or `.md` workflow file.
- Look for contradicting instructions, vague gates, or missing anti-patterns.

### 3. Propose the Patch
- Identify exactly what lines need to change.
- Formulate a precise instruction addition. Common fixes:
  - Adding explicit `GATE: STOP.` instructions.
  - Adding an `<anti_patterns>` section.
  - Clarifying a sub-agent's prompt or boundaries.

### 4. Apply & Test
- Use a file editing tool to update the skill/workflow file.
- Summarize the changes made for the user.

## Rules
- Focus on *behavioral* instructions, not just formatting.
- Be extremely specific. AI agents need sharp boundaries. Add `NEVER` and `ALWAYS` clauses if necessary.
- If fixing a workflow that skipped steps, introduce explicit gates requiring verification before proceeding.
