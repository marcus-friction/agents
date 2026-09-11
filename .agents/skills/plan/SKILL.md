---
name: plan
description: Create evidence-backed implementation plans. Use when the user asks for a plan, implementation plan, or execution strategy, or when multi-step, cross-boundary, or high-risk work must be scoped before implementation.
---

# Plan Workflow

Produce an evidence-backed plan for the complete accepted increment. Do not
inflate the increment to include adjacent product work. Every completed planning
workflow leaves a durable implementation plan and live task tracker.

## 1. Frame discovery

- Extract a provisional outcome, stated constraints, likely affected areas, and
  useful repository search terms from the request.
- Identify what evidence would establish acceptance criteria, exclusions,
  ownership, and external, destructive, privileged, production, data,
  architecture, or compatibility effects.
- Treat this as a discovery frame, not a plan. Do not draft ordered
  implementation steps or commit to files, components, or dependencies yet.

An explicit request for a plan authorizes only the ordinary repository writes
needed for the canonical plan pair. An implementation request that requires
this workflow supplies the same authority. Neither case authorizes production
changes, dependencies, implementation, or external effects. If the user
explicitly prohibits repository writes, surface the conflict and ask whether
to allow the required planning artifacts rather than silently switching to a
chat-only plan.

Store every new plan as:

```text
docs/plans/<YYYY-MM-DD>-<slug>/
├── implementation-plan.md
└── tasks.md
```

Use the current local date and a concise kebab-case increment slug. If the
folder already exists, choose the next available numeric suffix (`-2`, `-3`, and
so on); never overwrite or merge into it. If the user explicitly asks to revise
an existing plan, update its two files in place without creating a duplicate.
Before writing, verify that the selected directory, parents, and any existing
targets are physical directories or regular files rather than symlinks or
special files.

## 2. Build the relevant project picture

Read project evidence before asking planning questions. Use progressive
disclosure to get the full relevant picture rather than reading the repository
indiscriminately:

- locate and read every `AGENTS.md` that governs the repository and likely
  affected paths;
- read the accepted request or specification, product intent in `README.md`,
  and active project context under `.agents/project/` when present;
- read `CONTRIBUTING.md` when planning changes;
- read active architecture decisions, `ARCHITECTURE.md`, schemas, and contracts
  when components, data, trust, public interfaces, or runtime boundaries matter;
- read the active `DESIGN.md` and existing interface patterns only for
  user-interface scope;
- inspect the affected implementation, tests, executable configuration,
  dependency manifests, and relevant repository state or history;
- load only skills relevant to the accepted increment;
- read `.agents/skills/review/references/change-rigor.md`, classify the work R0,
  R1, or R2, and keep component applicability separate from boundary assurance.

Search `docs/solutions/` by filename and content using terms from the request,
affected components, contracts, dependencies, and symptoms. Read every match
that could materially inform or constrain the work, following relevant links to
related decisions or code. Record whether the directory is absent, no relevant
match exists, or specific solution documents apply. Treat compounded knowledge
as evidence, not automatically current policy: validate it against the current
implementation and active project documents, and call out stale or conflicting
guidance.

Reuse a current hash-bound context summary from an upstream workflow; re-read
changed or newly relevant anchors. Discovery is complete when the outcome and
acceptance boundary are supported, affected ownership and interfaces are known,
applicable rules and prior solutions have been assessed, and every remaining
material unknown is explicit.

When a relevant source is missing or unreadable, or the affected area cannot be
identified, record the evidence gap. Treat it as a material open question only
when it prevents a safe or accurate plan; never fabricate the missing context.

## 3. Resolve open questions

Separate the evidence into confirmed facts, reasonable non-blocking assumptions,
conflicts, and material open questions. An open question is material when its
answer can change scope, acceptance criteria, ownership, architecture, public
contracts, data handling or migration, trust boundaries, compatibility,
dependencies, rollout, recovery, or an elevated effect.

- Resolve questions from the request and repository evidence first. Do not ask
  the user for facts the project already answers.
- Surface conflicts between the request, current code, active decisions, and
  compounded knowledge instead of silently choosing one.
- Ask the user only the remaining material questions. Group related decisions,
  explain why each answer changes the plan, and provide concrete options with a
  recommendation when evidence supports one.
- Do not draft, persist, or present the plan artifacts while material
  questions remain. Wait for answers. If the user explicitly delegates a
  decision or requests a best-effort plan under uncertainty, state the chosen
  assumption and its consequence before drafting.
- Carry non-blocking uncertainty into the plan as a visible assumption or
  verification step. If no material question remains, proceed without an
  unnecessary confirmation gate.

## 4. Draft and persist the plan pair

Include:

- the accepted outcome, acceptance criteria, and explicit exclusions;
- a concise evidence ledger naming the project sources and compounded knowledge
  that materially shaped the plan;
- resolved decisions, constraints, and remaining non-blocking assumptions;
- component applicability and affected boundary-assurance facts;
- design and dependency decisions, including exact package purpose;
- file-level scope and ownership grounded in the inspected repository;
- ordered implementation steps;
- tests mapped to observable behavior and failure paths;
- data, compatibility, migration, recovery, and rollout handling when applicable;
- a failure-modes registry;
- existing code, patterns, and knowledge to reuse;
- verification commands and completion criteria.

Plan the complete accepted increment: every path needed to make that increment
usable, safe, and verifiable. Do not pull in an adjacent issue merely because it
looks small. Keep deployment unresolved unless it is required by the accepted
outcome and separately decided.

Write the result to `implementation-plan.md`. Create its sibling `tasks.md` as
a checkbox-based execution tracker derived from the ordered plan. Include
implementation, failure-path testing, verification, documentation, and required
review work. Keep task wording observable and small enough to update accurately.
Do not add lifecycle metadata merely to distinguish historical plans.

Treat `tasks.md` as live project state. During authorized implementation, read
the plan before changing code, follow its accepted scope and sequence, and
update the tracker as work progresses. Mark a task complete only when its
observable result is finished and applicable verification has passed. When an
accepted change alters the plan, update both files in the same folder. If the
plan conflicts with current evidence or the requested work, resolve that
material conflict instead of silently departing from it.

## 5. Review to convergence

Read and apply `review-plan` to every plan. Revise `implementation-plan.md` and
`tasks.md` for each material issue, then repeat only while a newly found
material issue is being resolved. Mark the plan-review task complete after all
retained findings are incorporated or explicitly left for owner decision. Stop
for owner input when the same blocker survives the third attempted resolution.
Record unresolved non-blocking decisions rather than inventing them.

## 6. Present

Link both artifacts and summarize scope, key decisions, risks, exclusions, and
verification. Ask the user to approve or revise the plan. If the original
request includes implementation, plan approval authorizes ordinary in-scope
edits; elevated effects still require an exact decision immediately before
execution.
