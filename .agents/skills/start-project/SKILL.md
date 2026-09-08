---
name: start-project
description: Start a new project by clarifying the smallest valuable product, reconciling project-owned documentation safely, selecting applicable architecture components, and producing an executable plan. Use for new products, empty repositories, or an explicit start-project request.
---

# Start Project

Turn an idea into an evidence-backed project baseline and an executable first
increment. Be opinionated about specificity, but ask only unresolved material
questions.

## 1. Inspect before interviewing

- Confirm `.agents/skills` is the canonical skill source; tool registration
  belongs to installation, not onboarding.
- Read an existing `README.md` before asking questions. Record whether it is
  absent, regular, generated, dirty, or a symlink. Preserve its badges, links,
  commands, license, decisions, frontmatter, and structure.
- Treat every active document as project-owned, even when it looks like a
  placeholder or upstream copy.
- Read `AGENTS.md` for governing rules and enough repository evidence to
  distinguish an empty project from an existing implementation.
- If a current hash-bound project summary is handed in by another workflow,
  reuse its classification and evidence while scope and hashes still match.
  Reclassify only changed or newly relevant facts.

If context exists, ask whether the user wants to update/pivot it, explore a
start-fresh proposal, or brainstorm. “Start fresh” authorizes a proposal, never
an overwrite.

## 2. Define the smallest valuable product

First ask for the idea in the user's own words. Fill known answers from existing
context, then resolve only material gaps:

- the specific user and painful current workaround;
- the valuable outcome and measurable first success;
- the narrowest complete wedge and explicit non-goals;
- material timing, budget, legal, compatibility, or operational constraints;
- why the proposed advantage is meaningful rather than a feature list.

Group related questions when that is clearer. Do not force one-question ceremony
or repeat an answered question. Challenge vague claims once or twice with
concrete evidence, then record the owner's decision and proceed.

Read the staged `ARCHITECTURE.md` candidate when present. Classify each
component **Adopted**, **Optional**, **Not applicable**, or **Unresolved**, citing
the product need, repository evidence, or owner decision. Record affected
boundary assurance facts: exposure, data impact, privilege, reversibility,
control owner, and evidence. Deployment starts **Unresolved / TBD** and does not
block a local first increment.

## 3. Confirm the product synthesis

Present a concise synthesis covering users, problem, outcome, first increment,
success measures, constraints, non-goals, component applicability, boundary
facts, and unresolved material decisions. Ask for one decision on this
synthesis. Keep it outside active files.

Approval confirms product intent; it is not file-write approval.

## 4. Delegate documentation to onboarding

Run the `onboard-project` skill with the approved synthesis, component matrix,
boundary facts, change-rigor classification, and their scope/evidence hashes.
Do not duplicate its inventory, ledger, approval, revalidation, or patch logic.

Onboarding must reconcile an existing `README.md` and the applicable staged
candidates for `AGENTS.md`, `ARCHITECTURE.md`, and `CONTRIBUTING.md`. Existing
meanings receive explicit dispositions. R1/R2 changes use one combined semantic
and exact-patch approval; R3 retains separate gates, its
durable ledger, and strict revalidation. A missing template-backed baseline
candidate, blocking conflict, or declined required patch stops planning until
the owner decides how to proceed.

`README.md` is required product context when present, but it is not one of the
three template-backed baseline documents below. When it is absent, record that
fact and use the approved product synthesis if a README proposal is needed; its
absence alone does not block local planning.

The baseline candidate mapping is:

- `.agents/templates/AGENTS.md` → `AGENTS.md`
- `.agents/templates/ARCHITECTURE.md` → `ARCHITECTURE.md`
- `.agents/templates/CONTRIBUTING.md` → `CONTRIBUTING.md`

Only adopted component rules become active. Optional and unresolved components
are not implementation authorization.

## 5. Handle design only when applicable

If no user interface is adopted, skip design consultation and record why.

If an interface is adopted and design decisions are unresolved, recommend the
`design-consultation` skill with the appropriate mode:

- focused documentation for wording or rationale;
- focused visual for bounded token/component/state changes;
- foundation or rebrand for a new or replaced visual system.

Reuse the onboarding snapshot and classification while its scope and hashes
match. Do not ask design questions already resolved by project evidence.

## 6. Produce the implementation plan

Load `CONTRIBUTING.md` for change policy, `ARCHITECTURE.md` for adopted
boundaries, and `DESIGN.md` only for adopted UI scope. Search
`docs/solutions/` when it exists and use applicable project skills.

Plan the complete accepted first increment, not the whole imagined product.
State exclusions and why they do not leave that increment unusable. Use only
adopted components. Verify unstable versions and scaffolding commands before
including them. If the accepted increment requires deployment, stop for the
missing deployment decision.

Follow the `plan` and `review-plan` workflows. Create
`implementation_plan.md` and `task.md` only when the work is genuinely
multi-step, cross-boundary, or high-risk.

If the original request included implementation, acceptance of the final plan
also authorizes ordinary in-scope implementation. Do not ask a redundant
execution-kickoff question. Destructive, privileged, or external R3 effects
still require approval immediately before execution.
