---
trigger: model_decision
description: Apply when building UI components, forms, navigation, modals, or any user-facing interface elements.
---

# Accessibility — WCAG AA Baseline

## Semantic HTML

- Use the correct HTML element for the job: `<button>` for actions, `<a>` for navigation, `<nav>`, `<main>`, `<article>`, `<aside>`, `<header>`, `<footer>`.
- Never use `<div>` or `<span>` for interactive elements.
- One `<h1>` per page. Heading levels must be sequential (no skipping from h2 to h4).
- Use `<ul>` / `<ol>` for lists, `<table>` for tabular data.

## Keyboard Navigation

- All interactive elements must be reachable and operable via keyboard.
- Visible focus indicators on all focusable elements — never `outline: none` without a replacement.
- Logical tab order that follows visual reading order.
- Escape key closes modals, dropdowns, and overlays.
- Focus trapping inside modals — tab cycling stays within the modal while open.

## ARIA

- Prefer semantic HTML over ARIA — use ARIA only when no native element conveys the role.
- Common required attributes:
  - `aria-label` or `aria-labelledby` on icon-only buttons and custom controls.
  - `aria-expanded` on toggles and disclosure widgets.
  - `aria-hidden="true"` on decorative elements (icons paired with text).
  - `role` only when needed — don't add `role="button"` to a `<button>`.
- Live regions (`aria-live="polite"`) for dynamic content updates (inline status messages, async results).

## Color & Contrast

- Text contrast ratio: **4.5:1** minimum (normal text), **3:1** minimum (large text/UI components).
- Never use color alone to convey information — pair with icons, text, or patterns.
- Test color pairings from the design system tokens against AA contrast requirements.

## Forms

- Every input has a visible `<label>` associated via `for`/`id`.
- Error messages are associated with inputs via `aria-describedby`.
- Required fields use the `required` attribute and visual indicator.
- Group related fields with `<fieldset>` and `<legend>`.

## Images & Media

- All meaningful images have descriptive `alt` text.
- Decorative images use `alt=""` (empty alt) — not missing alt.
- Videos and audio provide captions or transcripts where applicable.

## Responsive & Touch

- Touch targets minimum **44×44px**.
- Content is usable from 320px viewport width up (no horizontal scrolling).
- Text can be resized to 200% without loss of content or functionality.

## Motion

- Respect `prefers-reduced-motion` — disable or simplify animations.
- No auto-playing content that can't be paused.
- No flashing content (3 flashes per second threshold).

## Verification Checklist

- Test with keyboard-only navigation regularly.
- Use browser dev tools accessibility audit (Lighthouse, axe).
- Spot-check with a screen reader (VoiceOver, NVDA) for critical flows.
