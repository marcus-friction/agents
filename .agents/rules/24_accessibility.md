---
trigger: model_decision
description: Apply when building UI components, forms, navigation, modals, or any user-facing interface elements.
---

# Accessibility (WCAG AA)

## Semantic HTML & ARIA
- Use correct native elements (`<button>`, `<a>`, `<nav>`, `<main>`). Never `<div>`/`<span>` for interactions.
- Set `lang` attribute on `<html>`.
- Ensure one sequential `<h1>` per page. Use lists (`<ul>`/`<ol>`) and tables correctly.
- Include a skip-to-content link as the first focusable element.
- Prefer semantic HTML over ARIA. 
- Use ARIA only when necessary: `aria-label`/`aria-labelledby` (icon-only buttons), `aria-expanded` (toggles), `aria-hidden="true"` (decorative elements). `aria-live="polite"` for dynamic updates.
- Announce route changes in SPAs via `aria-live` region.

## Keyboard & Focus
- All interactive elements must be keyboard-operable with logical tab order.
- Provide visible focus indicators. Never use `outline: none` without a clear replacement.
- Modals/Overlays must trap focus and close via the `Escape` key.

## Visuals & Media
- **Contrast:** Minimum 4.5:1 (normal text) and 3:1 (large text/UI elements). Contrast values must align with the palette in `.agents/rules/11_design.md`.
- Do not use color alone to convey meaning (pair with icons/text).
- **Images:** Meaningful images require descriptive `alt`. Decorative images require `alt=""`.
- **Motion:** Respect `prefers-reduced-motion`. No un-pausable auto-play or flashing content (>3/sec).
- **Responsive:** Minimum 44x44px touch targets. Usable down to 320px width. Text resizable to 200%.

## Forms
- Every input requires a visible `<label>` tied via `for`/`id`.
- Associate errors via `aria-describedby` on the input.
- Indicate required fields visually and structurally. Group related fields with `<fieldset>`/`<legend>`.

## Verification
- Test via keyboard-only navigation.
- Audit with automated accessibility tools (e.g., Lighthouse, axe).
- Spot-check critical flows with a screen reader.
