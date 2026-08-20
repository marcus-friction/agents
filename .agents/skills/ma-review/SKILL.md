---
name: ma-review
description: Multi-agent parallel code review orchestrator. Dispatches specialized personas for Architecture, Performance, and Security.
---

# Multi-Agent Code Review (MA-Review)

This skill acts as an orchestrator for a parallel, multi-agent code review process, adapting the latest Compound Engineering methodologies.

## When to Use

Before opening a PR, or when the user asks for a multi-agent or parallel review of recent changes.

## Steps

### 1. Identify Scope
Review all files changed **in this conversation thread**. Use `git diff` and your conversation context to build the file list. Focus only on what was created or modified during this complete thread.

### 2. Dispatch Review Personas
Instead of reviewing the code yourself sequentially, you must delegate to specialized personas. If your environment supports subagents (e.g., `invoke_subagent`), spawn them in parallel. If not, you must adopt each persona strictly and sequentially yourself.

Dispatch the following three personas, providing each with the list of files to review:
1. **Architecture Persona**: Instruct the subagent to strictly follow `.agents/skills/ma-architecture-review/SKILL.md`.
2. **Performance Persona**: Instruct the subagent to strictly follow `.agents/skills/ma-performance-review/SKILL.md`.
3. **Security Persona**: Instruct the subagent to strictly follow `.agents/skills/ma-security-review/SKILL.md`.

Wait for all dispatched personas to complete their reviews and return their findings.

### 3. Synthesis & Reporting
Once all personas have reported back, synthesize their findings:
- Deduplicate overlapping issues.
- Apply a confidence gate: Suppress findings below `0.60` confidence unless they are P0 (Critical).

When the synthesis is complete, present the findings in three ways:

1. **Detailed Report Artifact:** Create a **conversation artifact** containing the full aggregated review details, grouped by severity (Critical, High, Moderate, Low).
2. **Task Artifact:** Add actionable findings as executable items to the Task artifact (`task.md`).
3. **Chat Summary:** Communicate the report and the updated task list to the user in the chat using a pipe-delimited Markdown table.
