---
name: review-plan
description: Challenge an implementation plan for scope, architecture, design, security, and verification gaps. Use after drafting any implementation plan or when asked whether a plan is ready.
---

# Review Plan

Evaluate the plan against repository evidence and the complete accepted
increment. The goal is convergence, not ritual.

## Preflight

Declare scope mode: expansion, selective expansion, hold scope, or reduction.
Read the accepted request, plan, applicable `AGENTS.md`, `README.md`, and
`CONTRIBUTING.md`, plus the plan's sibling `tasks.md` when present. Load
`ARCHITECTURE.md` when runtime boundaries matter and `DESIGN.md` only for UI
scope. Identify R0, R1, or R2 change rigor and affected boundary-assurance
facts.

Ask only questions whose answers materially change the plan. Present concrete
options and a recommendation. Group related decisions when clearer.

## Review passes

Mark every pass **applicable** or **not applicable**, with a reason.

### Strategy and scope

- Does the plan solve the stated problem with the smallest complete increment?
- Are success measures observable?
- Are exclusions explicit and compatible with a usable result?
- Did adjacent nice-to-have work enter without evidence?
- Does it reuse existing code and applicable compounded knowledge?

### Architecture and data

- Do adopted components and dependency directions match repository evidence?
- Are identity, browser sessions, service claims, and resource authorization
  owned explicitly when relevant?
- Are public contracts, persistence ownership, migrations, concurrency,
  idempotence, recovery, and compatibility handled?
- Are dependencies exact and purpose-bound? Are unplanned services, major
  upgrades, licensing, or permission expansions surfaced for decision?
- Would a compact ASCII flow materially clarify a multi-step state or data
  transition? Require one only when it improves understanding.

### Design and accessibility

Apply only for interface scope. Check alignment with the active `DESIGN.md`,
existing components, responsive states, loading/empty/error/success behavior,
keyboard flow, semantics, focus, contrast, reduced motion, and developer
handoff. Reject generic design prescriptions that lack project evidence.

### Security and operations

Use the security review's applicability preflight. Derive controls from exposure,
data impact, privilege, reversibility, control ownership, and evidence. Ensure
adopted runtimes have enough diagnostic and health evidence for their materiality.
Do not require unrelated auth, database, observability, or edge controls.

### Testing and delivery

Map changed observable behavior and meaningful failure paths to real tests.
Preserve the 100% line and branch target for testable production behavior while
documenting legitimate generated, declarative, unreachable, or behavior-free
exclusions. Verify commands, fixtures, compatibility, and rollback or rebuild
paths. Do not claim unavailable tools as passed.

## Required plan content

A ready plan states:

- the accepted increment and explicit exclusions;
- evidence, assumptions, adopted components, and unresolved decisions;
- file ownership and implementation sequence;
- test coverage map and verification commands;
- failure modes and safe recovery;
- existing patterns and knowledge to reuse;
- completion criteria.

Its `tasks.md` maps the implementation, failure-path tests, verification,
documentation, and applicable review work without contradicting or expanding
the plan.

## Convergence and verdict

Perform one thorough pass. Repeat only to resolve a newly found material issue;
do not require a fixed pass count. If the same blocker survives three attempted
resolutions, stop for owner input.

Before finalizing, use an independent outside-voice challenge for elevated or
significant architecture, security, data, migration, permission, deployment, or
production scope. Routine plans do not require it.

Report:

```text
REVIEW VERDICT
Strategy:      PASS | FAIL
Architecture:  PASS | FAIL | N/A
Design:        PASS | FAIL | N/A
Security/Ops:  PASS | FAIL | N/A
Testing:       PASS | FAIL
Overall:       GO | NO-GO
Blocking issues: [list or None]
```
