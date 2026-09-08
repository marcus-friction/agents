---
name: ma-review
description: Run a scoped, report-only parallel code review using Laravel/Nuxt Architecture, Performance, and Security personas.
---

# Multi-Agent Code Review (MA-Review)

This skill orchestrates an R0, report-only multi-agent review. It never grants
autofix, artifact, task-list, repository, or external mutation authority.

## When to Use

Before opening a PR, or when the user asks for a multi-agent or parallel review
of recent changes. Routine work may use the standard `review` skill instead.

## Steps

### 1. Identify Scope
Read `.agents/skills/review/references/change-rigor.md`. Build the file set from
the accepted request, comparison base, explicit paths, and conversation context.
Report and preserve unrelated dirty work; include it only when an explicit
dependency or trust-boundary trace proves relevance. Record the R0–R3 rigor and
affected adopted components without turning the classification into mutation
authority.

### 2. Dispatch Review Personas
Instead of reviewing the code yourself sequentially, you must delegate to specialized personas. If your environment supports subagents (e.g., `invoke_subagent`), spawn them in parallel. If not, you must adopt each persona strictly and sequentially yourself.

Declare each pass applicable or not applicable with a reason. Dispatch the
applicable personas in parallel, providing each with the same reviewed file set,
accepted scope, base ref, project rules, and known boundary facts:
1. **Architecture Persona**: Instruct the subagent to strictly follow `.agents/skills/ma-architecture-review/SKILL.md`.
2. **Performance Persona**: Instruct the subagent to strictly follow `.agents/skills/ma-performance-review/SKILL.md`.
3. **Security Persona**: Instruct the subagent to strictly follow `.agents/skills/ma-security-review/SKILL.md`.

Wait for all dispatched personas to complete and return report-only findings.

### 3. Synthesis & Reporting
Once all personas have reported back, synthesize their findings:
- Deduplicate overlapping issues.
- Apply a confidence gate: Suppress findings below `0.60` confidence unless they are P0 (Critical).
- Preserve severity, confidence, evidence, consequence, smallest correction,
  and verification. Distinguish confirmed defects from hypotheses.
- Identify R3 concerns that require the standard or mega-review path and an
  independent challenge; do not mutate or silently hand them off as fixes.

Present findings in chat, ordered by severity, followed by pass applicability,
tests or evidence inspected, unavailable evidence, and residual risk. Create a
durable report or update `task.md` only under a separate explicit user request.
Do not autofix; a later fix request routes through the standard review action
model and applicable implementation skills.
