---
name: skill-creator
description: Create or improve an agent skill and evaluate it proportionately. Use when a user asks to create, edit, optimize, validate, benchmark, or improve the triggering description of a skill.
---

<!-- Modified by TomFit AG in 2026 for provider-neutral, proportionate skill
creation and evaluation. -->

# Skill Creator

Create the smallest skill that reliably changes agent behavior in the intended
situations. Existing repository conventions and the user's requested scope take
precedence over this workflow.

## 1. Establish the contract

Use the conversation and existing skill before asking questions. Resolve only
material unknowns:

- what outcome the skill enables;
- when it should and should not trigger;
- expected artifacts or response shape;
- required tools, inputs, boundaries, and failure behavior;
- observable examples of success.

Keep authority separate from method: a skill may explain how to mutate or call a
service, but invocation alone never grants permission for that effect.

## 2. Design for progressive disclosure

A skill directory contains `SKILL.md` and only the support it needs:

```text
skill-name/
├── SKILL.md
├── references/  # detailed guidance loaded only when relevant
├── scripts/     # deterministic helpers
└── assets/      # output templates or media
```

In `SKILL.md`:

- include YAML `name` and `description`;
- make the description state capability and concrete trigger contexts;
- put the normal workflow and important boundaries in the body;
- route to support files precisely instead of repeating them;
- prefer reasons and observable decisions to ritual, fixed pass counts, or
  exhaustive checklists;
- do not add dependencies, network calls, persistence, publication, or
  destructive behavior that the description does not make unsurprising.

Keep provider-specific commands in optional adapters. The canonical workflow
must remain usable when a named model, subagent feature, viewer, or proprietary
tool is unavailable unless that capability is fundamental to the skill.

## 3. Evaluate in proportion to risk

Do not require a benchmark for every wording edit. Choose the lightest evidence
that can distinguish improvement:

- inspect and validate metadata, paths, and references for a small mechanical
  edit;
- use a few realistic positive, negative, and boundary prompts for routing or
  workflow changes;
- compare old and new behavior when the change is subtle or regressions matter;
- run repeated trials only when model variance could change the decision;
- use human review for subjective output instead of inventing numeric certainty.

Every automated assertion must inspect an observable result. Source-text checks
can verify static contracts but do not prove model behavior. Keep raw prompts,
transcripts, and outputs outside the repository by default.

The bundled scripts are optional helpers. Before using one, inspect its CLI and
dependencies and confirm that it fits the current host and evaluation contract:

- `scripts/quick_validate.py` for structural validation;
- `scripts/run_eval.py` or `scripts/run_loop.py` for compatible eval formats;
- `scripts/aggregate_benchmark.py` and `scripts/generate_report.py` for retained
  benchmark data;
- `eval-viewer/generate_review.py` for a local review artifact;
- `scripts/improve_description.py` for an explicitly requested description
  experiment;
- `scripts/package_skill.py` only when the user asks for packaging.

Do not install missing packages or force an incompatible harness merely because
one is bundled.

## 4. Iterate on evidence

Explain what each case tests, run the narrowest useful comparison, and inspect
failures before changing the skill. Revise the skill or test when evidence shows
the contract is wrong; do not tune instructions solely to literal fixture text.
Stop when the accepted behavior is clear and verified, not after an arbitrary
number of iterations.

Read `references/schemas.md` only when using the bundled evaluation format.

## 5. Deliver

Validate all changed paths and links, report tests and unavailable evidence, and
summarize the trigger boundary. Do not create an archive, publish, install, or
promote the skill into another repository unless the user requested that
separate effect.
