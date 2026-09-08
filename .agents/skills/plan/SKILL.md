---
name: plan
description: Scope, architect, and verify implementation plans for multi-step, cross-boundary, or high-risk work.
---

# Plan Workflow

Produce an evidence-backed plan for the complete accepted increment. Do not
inflate the increment to include adjacent product work.

## 1. Establish scope

- Restate the outcome, explicit exclusions, and observable acceptance criteria.
- Fill answers from the request and repository before asking questions. Ask only
  unresolved material questions; group related questions when clearer.
- Identify external, destructive, privileged, production, data, architecture,
  and compatibility effects.
- Read `.agents/skills/review/references/change-rigor.md` and classify the work
  R0–R3. Keep component applicability and boundary assurance separate.

A report-only planning request is R0: make zero repository or external writes.
Present the plan in chat by default. Persist `implementation_plan.md`, `task.md`,
or another agreed path only when the user requests a file or accepts a proposed
durable handoff because it materially helps the accepted work. Complexity alone
does not authorize an artifact. Treat that request or acceptance as authority to
prepare the candidate, not to bypass project-document ownership: present its
semantic summary and exact document patch as one decision, then revalidate the
physical target and parent before writing. R3 document triggers retain their
separate semantic and exact-patch decisions.

## 2. Load relevant context

Use progressive disclosure:

- always read applicable `AGENTS.md` files and the product intent in
  `README.md`;
- read `CONTRIBUTING.md` when planning changes;
- read `ARCHITECTURE.md` when components, data, trust, or runtime boundaries
  matter;
- read `DESIGN.md` only for user-interface scope;
- load only skills relevant to the accepted increment;
- search `docs/solutions/` when it exists and note when it does not.

Inspect affected implementation and executable configuration. Reuse a current
hash-bound context summary from an upstream workflow; re-read only changed or
newly relevant anchors.

## 3. Draft the plan

Include:

- current evidence and constraints;
- component applicability and affected boundary-assurance facts;
- design and dependency decisions, including exact package purpose;
- file-level scope and ownership;
- ordered implementation steps;
- tests mapped to observable behavior and failure paths;
- data, compatibility, migration, recovery, and rollout handling when applicable;
- a failure-modes registry;
- explicit exclusions with rationale;
- existing code, patterns, and knowledge to reuse;
- verification commands and completion criteria.

Plan the complete accepted increment: every path needed to make that increment
usable, safe, and verifiable. Do not pull in an adjacent issue merely because it
looks small. Keep deployment unresolved unless it is required by the accepted
outcome and separately decided.

## 4. Review to convergence

Read and apply `review-plan`. Perform one self-review for a non-trivial plan.
Revise material issues and repeat only while a new material issue is being
resolved. Stop for owner input when the same blocker survives the third attempted
resolution. Record unresolved non-blocking decisions rather than inventing them.

## 5. Present

Summarize scope, key decisions, risks, exclusions, and verification. Ask the
user to approve or revise the plan. If the original request includes
implementation, plan approval authorizes ordinary in-scope edits; R3 destructive,
privileged, or external effects still require approval immediately before
execution.
