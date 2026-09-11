---
name: onboard-project
description: Safely establish or refresh project context for an existing repository without losing documentation or local agent rules. Use when setting up a cloned or mature codebase, fixing agent blindness, reconciling new .agents/templates, establishing architecture baselines, or asking "what is this codebase".
---

# Project Onboarding

Make the repository understandable without replacing project-owned meaning.
Files under `.agents/templates/` are candidates; active documents remain owned
by the project.

## 1. Discover once

- Read applicable `AGENTS.md`, the active `README.md`, and
  `CONTRIBUTING.md` when changes are requested.
- Inspect repository status, top-level structure, manifests, build entrypoints,
  representative implementation, tests, and existing architecture or design
  decisions. Avoid inventories that do not support a decision.
- Treat root and nested documentation, provider instructions,
  `.agents/project/`, and legacy rule directories as project-owned.
- Inspect sensitive paths by name, schema, or example; never read secret values.
- Record whether proposed targets and parents are missing, regular, symlinks, or
  special files. For regular targets, inspect link count and generated-file
  provenance. Never write through a symlink or non-regular target, edit generated
  output directly, or treat a multiply linked file as an isolated path.

Reuse current evidence supplied by another workflow. Re-read only anchors that
changed or became relevant.

## 2. Explain the project

Summarize, with file evidence:

- product purpose, users, and important workflows;
- languages, frameworks, entrypoints, and real verification commands;
- module and dependency boundaries;
- persistence, identity, external integrations, deployment, and other trust
  boundaries when present;
- established conventions, contradictions, and material unknowns.

Classify components as **Adopted**, **Optional**, **Not applicable**, or
**Unresolved**. A template or preference is not evidence of adoption. Keep
deployment unresolved unless the project already decided it.

## 3. Choose the smallest durable baseline

Respond in chat when the user only wants an explanation. For durable onboarding,
prefer an existing `README.md`; when none exists, propose a concise README with
purpose, setup, verification, and known boundaries.

Create or amend another document only when it owns information that the README
cannot express clearly:

- `AGENTS.md` for persistent agent rules;
- `ARCHITECTURE.md` for material component or runtime boundaries;
- `CONTRIBUTING.md` for repository-specific workflow;
- `DESIGN.md` for an adopted interface system;
- `.agents/project/` for project-specific agent context that should not live in
  a product document.

Do not manufacture a fixed document set, copy every template, or create a
preservation ledger without a concrete audit need.

## 4. Reconcile and write

Read `.agents/skills/review/references/change-rigor.md` and classify the effect:

- R0 explanations make no writes.
- An explicit bounded onboarding request authorizes ordinary R1 edits,
  including tracked document changes. Preserve existing meaning and show the
  resulting diff; no separate semantic, patch, or kickoff approval is needed.
- For an R2 effect, confirm the exact target, scope, exposure, credentials, and
  recovery path immediately before it occurs.

When active content and a candidate disagree, retain both meanings until the
conflict is resolved. Load
[`references/document-reconciliation.md`](references/document-reconciliation.md)
only for a real conflict, unknown ownership, non-regular target, supersession,
generated output, multiply linked target, or elevated effect.

Immediately before writing, verify the exact target and parent are still safe.
Apply only in-scope edits, then validate links, commands, internal consistency,
and the actual diff. Never commit or push unless separately requested.

## 5. Handoff

Report the project model, adopted and unresolved components, documents changed,
verification run, preserved conflicts, and the next decision only when one is
material. Do not automatically turn onboarding into an implementation plan.
