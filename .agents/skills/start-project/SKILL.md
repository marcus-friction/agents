---
name: start-project
description: Start a new project through a focused product interview, the adopted Laravel/Nuxt core stack, a complete project-document baseline, and a persisted executable first-increment plan. Use for new products, empty or scaffold-only repositories, or an explicit start-project request; use onboard-project once meaningful product behavior exists.
---

# Start Project

Turn an idea into the smallest valuable, testable first increment without
reopening the approved technical foundation or exhausting the owner with
low-value questions.

## 1. Qualify and inspect

Treat an empty repository or one containing only generated scaffolding and no
meaningful product behavior as a new project. If meaningful behavior already
exists, use `onboard-project` instead.

Read applicable `AGENTS.md`, active project documents, manifests, repository
status, and enough implementation evidence to make that distinction. Inspect
the five candidates under `.agents/templates/` by path and type without reading
secret values. Treat active documents as project-owned and surface conflicts
instead of overwriting them. Never write through a symlink or non-regular
target.

## 2. Run a focused product interview

Answer from supplied context first. Ask one question at a time and drive quickly
toward what to build and for whom. Target a 15–20 minute interview and normally
ask no more than eight questions. Exceed that cap only for a decision that
blocks a safe or accurate first increment.

Resolve only material gaps, in this order:

- the specific user and painful current workaround;
- the valuable outcome and observable first success;
- the narrowest complete wedge and explicit non-goals;
- material timing, budget, legal, compatibility, and operational constraints;
- why the proposed advantage matters to the user.

Do not over-index on naming, speculative scale, exhaustive personas, distant
features, or implementation detail that cannot change the first increment.
Challenge a vague material assumption concretely, then respect and record the
owner's decision. Keep success evidence lightweight and observable; do not
force a numeric target or fixed statement format.

## 3. Apply the adopted technical foundation

The default core stack is already approved and **Adopted**:

- Nuxt 4, Vue 3, TypeScript, and Tailwind CSS 4 for the web interface;
- Laravel 13 and PHP 8.4 for the application API;
- PostgreSQL 17 for primary data; and
- Redis for adopted cache, session, queue, and application workloads, kept as
  separate failure domains.

Build on this core without asking the owner to accept it, comparing alternatives,
or proposing replacements. A core component that is unnecessary for the first
increment remains **Adopted but deferred**; do not reclassify it or scaffold it
merely to prove adoption. Only an explicit owner decision may replace or remove
a core component, and that decision must be recorded in active project context
before planning.

Classify additional capabilities **Adopted**, **Optional**, **Not applicable**,
or **Unresolved** from product need and owner decisions. Record material
exposure, data, privilege, reversibility, and control ownership. Deployment
remains **Unresolved / TBD** until separately decided.

Present a concise synthesis of user, problem, first increment, success measure,
non-goals, constraints, adopted and deferred components, explicit stack
overrides, and material unknowns. Do not require a separate synthesis approval.
If a missing choice would substantially change the product or architecture,
ask the next focused question before continuing.

## 4. Establish the complete baseline

An explicit request to start the project authorizes ordinary creation or
reconciliation of all five active baseline documents:

- `.agents/templates/README.md` to `README.md`;
- `.agents/templates/AGENTS.md` to `AGENTS.md`;
- `.agents/templates/ARCHITECTURE.md` to `ARCHITECTURE.md`;
- `.agents/templates/CONTRIBUTING.md` to `CONTRIBUTING.md`; and
- `.agents/templates/DESIGN.md` to `DESIGN.md`.

Adapt every candidate to the accepted product; do not activate placeholder text
or copy the candidate mechanically. Record the core as Adopted and mark unused
core layers deferred in the active `ARCHITECTURE.md`. Use `onboard-project` to
reconcile any existing active document while preserving its meaning. Verify
that the complete active baseline exists and is internally consistent before
planning.

If any required candidate is missing, stop and report that the agent
distribution is incomplete. Do not invent or reconstruct the candidate. Ask
for authority to run `update-agents`, disclosing that it refreshes all managed
agent assets and adapters as well as templates. Resume only after that workflow
succeeds and all five candidates pass the path and type checks. A start-project
request alone does not authorize the broader distribution refresh.

An exploratory or explicitly no-write request remains read-only and receives
the product synthesis only; explain that creating the baseline requires an
explicit start-project request.

## 5. Plan the first increment

Use `plan` for every start-project result. It must persist and review these
paired artifacts:

```text
docs/plans/<YYYY-MM-DD>-<slug>/
├── implementation-plan.md
└── tasks.md
```

For a new increment, choose a concise kebab-case slug. If its folder exists,
select the next available numeric suffix such as `-2`; never overwrite it.
When the user explicitly asks to revise an existing plan, update that plan and
its sibling tracker in place without duplication.

Plan the complete first increment, not the imagined full product. Include file
scope, exact dependencies and purpose, observable tests, failure handling,
compatibility, and completion criteria. Keep deferred core components out of
the implementation sequence until needed. Keep optional components and
deployment out unless the increment requires and explicitly adopts or resolves
them.

Always apply `review-plan`, revise material issues to convergence, and keep
`tasks.md` synchronized with the reviewed plan. Present the plan paths and ask
the owner to approve or revise the plan. If the original request includes
implementation, plan approval authorizes ordinary in-scope work. Follow the
plan and update `tasks.md` throughout execution. Confirm elevated destructive,
privileged, production, publication, secret/permission, or irreversible effects
immediately before they occur.
