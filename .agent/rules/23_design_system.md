---
trigger: model_decision
description: Apply when building UI components, defining styles, choosing colors/typography/spacing, or establishing visual patterns.
---

# Design System

## Core Principles
- **Aesthetic:** Structure over decoration. Consistent geometry (border-radius). Grid spacing (4px base). Desktop-primary design with **mobile-first CSS** (`sm:`, `lg:`). No `max-*:` variants.
- **Feedback Lifecycle:** **NO TOASTS.** Use inline feedback contexts. 
  - **Buttons:** State machine (idle -> loading spinner -> success checkmark -> error/idle).
  - **Forms:** Inline field errors (on blur) via `aria-describedby`. Error summary for 5+ fields.
- **Component States:** Always implement Loading (skeleton `surface-2 animate-pulse`, no spinners for structural layouts), Empty (icon + description), Error (retry CTA), and Loaded states.
- **Modals:** Use as a last resort (destructive confirmations). Prefer inline expansion or slide-overs.

## UI Architecture
- **Tokens (Layer 1):** `tokens.css` with RGB custom properties (`--bg`, `--surface-1`). Map via semantic aliases (`primary`, `danger`). Implement dark mode via `@media (prefers-color-scheme: dark)`.
- **Bridge (Layer 2):** `main.css` maps tokens to Tailwind via `@theme`.
- **Z-Index Scale:** Prevent stacking conflicts: `z-0` (Base) -> `z-10` (Cards) -> `z-20` (Sticky Tabs) -> `z-30` (Nav) -> `z-40` (Header) -> `z-50` (Modals) -> `z-60` (Tooltips). Use `isolate` on scroll contexts.

## Standard Component API
- **Props:** `variant`, `size`, `disabled`, `loading`, `compact`. Use slots for structural variations. Emit events rather than mutating props.
- **Shapes:** Buttons and Inputs share fixed height. Cards use `surface-2` with 1px border. Hover states affect borders/shadows, not vertical translation.
- **Icons:** Use `<BaseIcon>` component. Avoid scattered inline SVGs.
- **Typography:** Two fonts: UI (sans), Data (mono). Use `rem` strictly for user-scaling. 
  - `text-xs` (0.75rem) to `text-2xl` (1.5rem). `h1`/`h2`=900 wight, `h3`=700 weight. Sentence case headings.

## Colors & Motion
- **Palette:** `primary-500` -> `600` (hover) -> `700` (active). WCAG AA contrast for text/background pairings.
- **Transitions:** 120-200ms duration.
- **Easing:** Elements entering (`cubic-bezier(0,0,0.2,1)`), elements exiting (`cubic-bezier(0.4,0,1,1)`), default micro-interactions (`ease-out`).