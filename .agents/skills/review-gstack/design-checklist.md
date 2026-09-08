# Mega Design Review Checklist

Apply only to interfaces affected by the reviewed change. The active
`DESIGN.md`, product goal, and observed component system are authoritative.

## Product and visual coherence

- Identify the interface type and the user's primary task.
- Check that hierarchy, copy, layout, and actions make that task clear.
- Reuse approved tokens and primitives. A native semantic control is valid when
  the design system has no corresponding component.
- Flag generic patterns only when they conflict with the product identity,
  obscure hierarchy, or add cognitive load; do not enforce a universal style
  blacklist.
- Treat subjective visual changes as judgment decisions, never autofixes.

## States and interaction

- Verify applicable default, hover, active, focus, disabled, loading, empty,
  error, success, and loaded states.
- Keep feedback contextual, perceivable, and recoverable.
- Check keyboard order, visible focus, dialog focus management, semantics,
  labels, announcements, and reduced motion.
- Meet WCAG AA contrast and avoid communicating meaning by color or motion alone.

## Responsive behavior

- Exercise the project's supported narrow, medium, and wide viewports.
- Check reflow, reading order, touch usability, long content, localization,
  zoom, and text scaling.
- Prevent unintended clipping or horizontal overflow.
- Judge fixed dimensions by observed behavior; do not reject them categorically.

## Evidence

For each finding cite the affected state, viewport or input, violated project
decision, user impact, smallest coherent correction, and verification.
