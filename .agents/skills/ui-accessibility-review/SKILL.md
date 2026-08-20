---
name: ui-accessibility-review
description: UI quality, responsiveness, and accessibility review checklist for Nuxt/Tailwind
---

# UI & Accessibility Review Skill

Review checklist for UI code quality, responsive design, and WCAG AA compliance. Use during the UI/accessibility pass of `/review` or when auditing frontend code. References `AGENTS.md` and `DESIGN.md` as source rules.

## Checklist

### Design System Compliance

- [ ] Colors use design tokens — no hardcoded hex/rgb values
- [ ] Typography uses defined scale — no arbitrary `text-[17px]`
- [ ] Spacing follows the spacing scale — no arbitrary `p-[13px]`
- [ ] Base components used (`BaseButton`, `BaseInput`, etc.) — no raw HTML for standard controls
- [ ] Icons are consistent in size and style throughout the view

### Layout & Responsiveness

- [ ] Layout works at 320px, 768px, 1024px, 1440px viewports
- [ ] No horizontal scrolling at any breakpoint
- [ ] Touch targets are at least 44×44px on mobile
- [ ] Stacking order makes sense on mobile (most important content first)
- [ ] Images use `<NuxtImg>` with appropriate `sizes` attribute
- [ ] No fixed widths that break on smaller viewports

### Visual Quality

- [ ] Consistent spacing rhythm — elements don't feel randomly placed
- [ ] Text is readable — sufficient line height, appropriate measure (45–75 chars per line)
- [ ] Empty states are handled — not just blank white space
- [ ] Loading states are present for async content
- [ ] Error states are visually clear and provide actionable guidance
- [ ] Transitions/animations use `prefers-reduced-motion` media query

### Accessibility — Structure

- [ ] Semantic HTML used — `<nav>`, `<main>`, `<article>`, `<button>`, `<a>`
- [ ] One `<h1>` per page, heading levels are sequential (no skipping)
- [ ] Interactive elements are `<button>` (actions) or `<a>` (navigation) — not `<div @click>`
- [ ] Lists use `<ul>`/`<ol>`, tabular data uses `<table>`

### Accessibility — Interaction

- [ ] All interactive elements keyboard-reachable and operable
- [ ] Visible focus indicators on all focusable elements
- [ ] Tab order follows visual reading order
- [ ] Modals trap focus and close with Escape key
- [ ] Dynamic content updates use `aria-live` regions

### Accessibility — Content

- [ ] Meaningful images have descriptive `alt` text
- [ ] Decorative images use `alt=""`
- [ ] Form inputs have visible `<label>` elements with `for`/`id` association
- [ ] Error messages linked to inputs via `aria-describedby`
- [ ] Required fields use `required` attribute and visual indicator
- [ ] Color contrast meets 4.5:1 (text) / 3:1 (large text, UI components)
- [ ] Information not conveyed by color alone

### Accessibility — ARIA

- [ ] `aria-label` or `aria-labelledby` on icon-only buttons
- [ ] `aria-expanded` on toggles and disclosure widgets
- [ ] `aria-hidden="true"` on decorative icons paired with text
- [ ] No redundant roles (`role="button"` on `<button>`)

## Severity Guide

- 🔴 **Must fix**: Missing keyboard access, broken semantics (`<div>` as button), contrast failures, no alt text on meaningful images
- 🟡 **Should fix**: Missing ARIA attributes, arbitrary spacing/colors bypassing tokens, no empty/loading states
- 🟢 **Consider**: Minor spacing inconsistencies, suboptimal line length, missing `prefers-reduced-motion`
