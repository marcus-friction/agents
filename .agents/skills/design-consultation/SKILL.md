---
name: design-consultation
description: Establish or amend a project's visual system with proportionate research, preview, and preservation. Use for DESIGN.md creation, focused design documentation, bounded visual changes, or a foundation/rebrand. Produces Google-format DESIGN.md decisions and a provider-neutral preview when visual scope requires it.
metadata:
  version: 3.0.0
---

# Design Consultation

Propose a coherent system from product and implementation evidence. Be
opinionated, explain tradeoffs, and invite correction without turning the
conversation into a form.

## Phase 0: Protect project-owned context before candidates

1. Inspect Git state and the existence, type, parent metadata, and hash of
   `DESIGN.md`. Treat symlinks, generated files, dirty targets, conflicts, and
   supersession as R3. Never write through a symlink.
2. Read applicable project-owned context first: `AGENTS.md`, `README.md`,
   `ARCHITECTURE.md`, the existing `DESIGN.md`, styling configuration,
   manifests, and representative UI. Read `CONTRIBUTING.md` when a change is
   planned.
3. Load `.agents/skills/review/references/change-rigor.md`. Reuse a handed-off
   component, boundary, and rigor classification only while scope and evidence
   hashes match.
4. After local context, inspect `.agents/templates/DESIGN.md` if it is a
   regular file. It is an inactive candidate, never an authority. Reject a
   symlink or special-file candidate.

The candidate follows the Google `DESIGN.md` contract: normative design tokens
live in YAML frontmatter and Markdown explains them in the standard section
order. Existing sound structures and meanings remain project-owned.

## Phase 1: Choose the smallest fitting mode

Classify the request and state the mode:

1. **Focused documentation:** wording, rationale, or recorded decisions only.
   No visual preview is required.
2. **Focused visual change:** bounded tokens, components, or states. Preview
   only the affected system and states.
3. **Foundation or rebrand:** a new visual system or broad replacement. Use a
   complete proposal and preview.

Escalate any R3 trigger regardless of mode. A clean R1/R2 focused visual change
may combine preview direction and the exact patch in one approval. R3 retains
separate semantic/preview and exact-patch gates.

If no user interface is adopted, stop and explain that `DESIGN.md` is not
applicable. If the product is unclear, recommend product discovery first.

## Phase 2: Build the preservation ledger

Inventory local and incoming meanings:

| ID | Source/hash | Meaning | Evidence | Applicability | Disposition | Target/conflict |
|---|---|---|---|---|---|---|

Use evidence states **observed**, **documented**, **inferred**, and **proposed**.
Applicability is applicable, not applicable with a reason, or
conflict/unresolved. Existing meaning defaults to retained or clarified;
movement, weakening, or supersession requires explicit approval.

Cover visual direction; color, typography, spacing, layout, shape, depth, and
motion; implementation architecture; component states; responsiveness;
accessibility; assets; and validation. Do not duplicate runtime architecture
that belongs in `ARCHITECTURE.md`.

## Phase 3: Resolve material design questions

Pre-fill answers from evidence. Ask only questions whose answers change the
accepted mode or proposal: product/audience, interface type, desired character,
brand constraints, and whether current landscape research would improve the
decision. Group related questions when helpful and do not repeat resolved facts.

Research only when requested or needed for an unstable market claim. Distinguish
observed conventions from recommendations and cite sources.

## Phase 4: Propose the system

Scale the proposal to the selected mode. Cover affected decisions with rationale:

- aesthetic and decoration;
- layout and responsive behavior;
- color roles and verified contrast;
- typography roles and fallbacks;
- spacing, shape, elevation, and motion;
- implementation architecture and token locations;
- component states: default, hover, active, focus, disabled, loading, empty,
  error, success, and loaded where applicable;
- accessibility: semantics, keyboard, focus, touch, contrast, text scaling, and
  reduced motion.

State safe conventions and deliberate risks. Check that each recommendation has
a ledger disposition and fits the observed implementation.

## Phase 5: Provider-neutral preview when visual

For focused visual and foundation/rebrand modes, build a self-contained HTML
preview in a temporary workspace outside active product source. Use embedded CSS
and local or system fallbacks; require no hosted preview service, package
installation, or network request.

A focused preview demonstrates only affected tokens, components, viewports, and
states. A foundation preview demonstrates the complete relevant system. Validate
rendering and assets, responsive behavior including the narrowest supported
viewport, WCAG AA contrast, keyboard order and visible focus, component states,
reduced-motion behavior, and agreement with the proposal and ledger. Label
unverified checks honestly.

Share the provider-neutral preview and validation result. For R3, obtain preview
approval before drafting the patch. For R1/R2, present the preview and exact
patch together for one combined approval.

## Phase 6: Patch DESIGN.md

Draft outside the active file. For a new or explicitly migrated document, follow
the Google Labs `DESIGN.md` format:

1. YAML frontmatter starts with `version: alpha`, a name, and approved
   `colors`, `typography`, `spacing`, `rounded`, and `components`
   groups. Use `omitted` with reasons only for deliberately undefined groups.
2. Markdown sections appear in order: `Overview`, `Colors`, `Typography`,
   `Layout`, `Elevation & Depth`, `Shapes`, `Components`, and
   `Do's and Don'ts`.
3. Place implementation, states, responsiveness, and accessibility in their
   applicable standard sections; append project-specific sections only when
   necessary.

Preserve an existing document's native structure unless format migration is an
explicitly approved part of the proposal. Show the exact unified diff and every
deletion, move, weakened constraint, or supersession.

R1/R2 use one combined semantic and exact-diff approval. R3 uses a semantic or
preview approval first and a separate exact-patch approval. Immediately before
writing, revalidate the target, parents, and direct evidence anchors; abort on a
relevant change and ignore unrelated work. Apply only approved hunks.

Validate the final Google structure, links, token/prose agreement, and applicable
UI checks. Use the official linter only when available and approved; otherwise
report its status as unverified. Show the resulting diff and never commit
automatically.
