---
version: alpha
name: Project Design System
description: Replace with the approved product and brand direction.
omitted:
  - section: colors
    reason: Define approved color tokens.
  - section: typography
    reason: Define approved typography tokens.
  - section: spacing
    reason: Define approved spacing and layout tokens.
  - section: rounded
    reason: Define approved shape tokens.
  - section: components
    reason: Define approved component tokens.
---

<!-- Modified by TomFit AG; further adapted by Agents Ecosystem contributors. -->

# [Project Name] Design System

> [!WARNING]
> This inactive candidate requires approved decisions and an exact patch. Remove
> `omitted` entries as tokens are defined. YAML is normative.

## Overview

- **Audience:** `[Who uses the interface and in what context?]`
- **Product:** `[What should users accomplish or understand?]`
- **Brand:** `[What should the interface feel like, and why?]`
- **Evidence:** `[Implementation, brand material, research, or owner decision.]`
- **Direction:** `[Focused documentation, visual change, foundation, or rebrand.]`

Follow Nuxt 4, Vue 3, Tailwind CSS 4, and component conventions when adopted.
Preserve valid tokens and interactions unless their exact replacement is
approved. When Laravel owns an adopted API resource, align interface states
with its validation and error contract rather than inventing a second domain
model in the client.

## Colors

- **Roles:** `[Primary, secondary, neutral, surface, text, and semantic roles.]`
- **Usage:** `[Where each role applies and prohibited pairings.]`
- **Contrast:** `[Verified WCAG AA text and control pairings.]`
- **Themes:** `[Light, dark, high-contrast, or other supported behavior.]`

## Typography

- **Families:** `[Approved families, loading strategy, and fallbacks.]`
- **Scale:** `[Display, heading, body, label, and caption roles.]`
- **Usage:** `[Hierarchy, weight limits, line length, and responsive behavior.]`

## Layout

- **Model:** `[Grid, containers, columns, and maximum widths.]`
- **Scale:** `[Base unit, named spacing scale, gutters, and margins.]`
- **Responsive:** `[Narrow, medium, and wide behavior, including 320px.]`

## Elevation & Depth

- **Depth:** `[Borders, tonal layers, shadows, overlays, and stacking rules.]`
- **Overlays:** `[Navigation, sticky controls, modals, popovers, and tooltips.]`
- **Motion:** `[Durations, easing, purpose, interruption, and reduced-motion behavior.]`

## Shapes

- **Language:** `[Approved geometry and where it reinforces meaning.]`
- **Radii:** `[Named radius scale and the role of each level.]`
- **Borders:** `[Widths, styles, and their semantic use.]`

## Components

- **Architecture:** `[Token, primitive, shared-component, and feature locations.]`
- **Contract:** `[Variants, sizes, slots, disabled, and pending behavior.]`
- **States:** Define relevant default, hover, active, focus, disabled, loading,
  empty, error, success, and loaded behavior.
- **Accessibility:** Preserve semantics, labels, keyboard operation, focus,
  zoom, text scaling, and reduced motion.
- **Validation:** `[Preview, visual regression, accessibility, and viewport checks.]`

Use established Tailwind tokens and Vue primitives first. Nuxt components own
presentation and interaction when adopted. The resource-owning server owns
domain validation and authorization; use Laravel Policies or Gates only for a
Laravel-owned resource. Keep feedback contextual and actionable.

## Do's and Don'ts

### Do

- Use normative tokens and established primitives before adding values.
- When that integration is adopted, keep Laravel validation feedback
  perceivable, contextual, and recoverable in the Nuxt interface.
- Meet WCAG AA contrast and preserve meaning under zoom, text scaling, keyboard
  navigation, and reduced motion.

### Don't

- Don't embed unrelated color, spacing, typography, or shape literals in
  feature components.
- Don't communicate state through color, motion, or transient feedback alone.
- Don't mix conflicting shape or elevation languages without approval.

## Decisions & Open Questions

| Decision or question | Status | Evidence or rationale |
|---|---|---|
| `[item]` | `[observed / intended / unresolved]` | `[path or owner confirmation]` |
