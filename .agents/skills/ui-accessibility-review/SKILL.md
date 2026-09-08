---
name: ui-accessibility-review
description: Review adopted user interfaces for design-system fit, responsive behavior, and WCAG AA accessibility.
---

# UI and Accessibility Review

Use during a scoped UI review. Read the active `DESIGN.md` and representative
implementation first. If no interface is affected, mark the pass not applicable
with a reason.

## Design system

- Use approved color, typography, spacing, shape, and motion tokens through the
  project's Tailwind and CSS-variable conventions.
- Reuse established primitives when they preserve semantics and consistency;
  use established `Base*` components where they own the contract, while native
  semantic controls remain valid when the design system has no matching owner.
- Avoid unexplained one-off values. Judge exceptions by the active design
  language, not arbitrary class or pixel-count rules.
- Keep icons, feedback, empty/loading/error/success states, and density coherent.

## Responsive behavior

- Exercise the project's supported narrow, medium, and wide viewports,
  including the smallest documented width. When no project matrix exists, use
  representative 320px, 768px, 1024px, and 1440px checks.
- Prevent unintended horizontal scrolling, clipped content, and unusable
  controls.
- Preserve meaningful reading and focus order as layouts reflow.
- Make pointer targets usable for the product's devices and audience.
- Use responsive image sizing and `<NuxtImg>` when the adopted Nuxt image
  pipeline adds optimization without breaking the asset contract.

## Structure and interaction

- Use semantic landmarks, headings, lists, tables, buttons, links, and form
  controls for their intended behavior.
- Keep one meaningful `<h1>` per page and preserve a logical heading hierarchy.
- Keep every action and navigation path keyboard-operable with visible focus.
- Manage focus entry, containment, Escape behavior, and restoration for dialogs.
- Announce material dynamic updates when they are not otherwise perceivable.
- Associate visible labels, instructions, validation, and errors with controls;
  every input needs a visible label under the project accessibility contract.
- Use ARIA only where native semantics do not express the required state.

## Content and perception

- Give meaningful images useful alternatives and decorative images empty alt
  text.
- Meet WCAG AA contrast: at least 4.5:1 for normal text and 3:1 for large text
  and meaningful UI boundaries.
- Do not communicate status by color, motion, position, or icon alone.
- Respect reduced motion, zoom, text scaling, localization, and long content.
- Keep errors actionable and recovery paths perceivable.

## Findings

Classify issues by user impact and affected flow:

- **Must fix:** blocks access, understanding, input, navigation, or recovery.
- **Should fix:** materially weakens consistency or usability.
- **Consider:** bounded polish with no functional accessibility impact.

Cite the affected state and evidence. Do not auto-fix subjective design choices;
propose the smallest coherent correction and how to verify it.
