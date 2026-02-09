---
trigger: model_decision
description: Apply when building UI components, defining styles, choosing colors/typography/spacing, or establishing visual patterns.
---

# Design System

> **Template file.** Copy into each project's `.agent/rules/` and customize the marked sections. Architecture and component patterns are standard; token values, fonts, and tone are per-project.

## Design Tone

> *Customize per project.*

<!-- Example: "Kinetic Engineering — precise, technical, data-first." -->
<!-- Example: "Warm editorial — approachable, clean, content-focused." -->

**Tone:** {describe the aesthetic direction in 3–5 words}
**Audience:** {target users}

## Principles

- Structure over decoration, dense layouts preferred.
- Consistent geometry — define a project-wide border radius (e.g., `0` sharp, `0.5rem` soft).
- Shadows used sparingly — hover/overlays only.
- Consistent spacing grid (0.25rem / 4px base unit).
- **Desktop-primary, mobile-first CSS** — design for desktop as the primary experience, but write CSS mobile-first using Tailwind's `sm:`, `md:`, `lg:` breakpoints (ascending).

---

## Token Architecture — Two Layers

### Layer 1: `tokens.css` — Raw Palette + Semantic Aliases

CSS custom properties on `:root` using RGB triplets for alpha compositing support.

**Required token categories:**

| Category | Tokens |
|---|---|
| Surfaces | `bg`, `surface-1`, `surface-2` |
| Borders | `border`, `border-strong` |
| Text | `text`, `text-muted`, `text-faint` |
| Radius | `radius` (project-wide default) |
| Shadow | `shadow-1` |
| Focus | `focus` color, `focus-width`, `focus-offset` |
| Palette ramps | 50–900 scale per color |

**Semantic aliases** map raw ramps to roles:

| Role | Purpose |
|---|---|
| `primary` | Actions, links, active states |
| `accent` | Highlights, call-to-action |
| `success` | Positive status |
| `warning` | Caution status |
| `danger` | Error, destructive actions |

### Dark Mode Support

Include a dark mode override block in `tokens.css` alongside the light theme. Override the same token names — the `@theme` bridge and all components stay unchanged.

```css
@media (prefers-color-scheme: dark) {
  :root {
    --{prefix}-bg: {dark value};
    --{prefix}-surface-1: {dark value};
    --{prefix}-text: {dark value};
    /* ... override all surface, border, and text tokens ... */
    /* Palette ramps typically stay the same or shift slightly */
  }
}
```

- Even if v1 is light-only, include the block with placeholder values to avoid retrofitting.
- Use `prefers-color-scheme` for automatic switching, or `[data-theme="dark"]` for manual toggle.

### Layer 2: `main.css` — Tailwind `@theme` Bridge

Maps CSS custom properties to Tailwind utilities via `@theme`. Also contains `@font-face` declarations, base styles, prose, and animations.

---

## Typography

> *Customize fonts per project.*

- Self-host variable fonts via `@font-face` with `font-display: block`.
- Two font families: **UI font** (sans) and **data/spec font** (mono).
- **UI font:** {e.g., Satoshi, Inter, Outfit}
- **Mono font:** {e.g., Geist Mono, JetBrains Mono}
- **Use `rem` units** for all font sizes — enables user browser text scaling (WCAG AA requirement).

| Token | Size (rem) | Line Height | Usage |
|---|---|---|---|
| `text-xs` | 0.75rem | 1rem | Specs, labels, mono data |
| `text-sm` | 0.8125rem | 1.125rem | Dense UI, secondary text |
| `text-base` | 0.875rem | 1.25rem | Body text |
| `text-lg` | 1rem | 1.5rem | H3, section headings |
| `text-xl` | 1.125rem | 1.625rem | H2 |
| `text-2xl` | 1.5rem | 2rem | H1 |

- Heading weights: `h1`/`h2` = 900, `h3` = 700.
- Casing: headings in sentence case, labels in Title Case, specs/IDs in mono.

---

## Spacing Scale

Use Tailwind's default spacing scale (based on 0.25rem / 4px grid). Define any project-specific overrides in `@theme`.

---

## Breakpoints

Use Tailwind's default breakpoints (`sm` 640px, `md` 768px, `lg` 1024px, `xl` 1280px, `2xl` 1536px). Desktop-primary design, mobile-first CSS:

- Write base styles for mobile, layer with ascending breakpoints (`sm:`, `md:`, `lg:`).
- Never use `max-*:` variants.
- Content max-width: ~1440px (customizable per project).

---

## Z-Index Scale

Define a consistent z-index system to prevent stacking conflicts:

| Layer | Z-Index | Usage |
|---|---|---|
| Base content | `z-0` | Default document flow |
| Raised elements | `z-10` | Cards on hover, dropdowns triggers |
| Sticky elements | `z-20` | Sticky tabs, sub-navigation |
| Navigation | `z-30` | Breadcrumbs, secondary nav |
| Header | `z-40` | Top-level sticky header |
| Overlays | `z-50` | Modals, slide-overs, drawers |
| Tooltips | `z-[60]` | Hover hints, always-on-top |

- Sticky elements stack top-down: header (z-40) > breadcrumbs (z-30) > tabs (z-20).
- Apply `isolate` on scrollable containers to prevent z-index bleed.

---

## Color

> *Customize palette per project.*

- RGB triplets in `tokens.css` for alpha support: `rgb(var(--token) / 0.5)`.
- 5 semantic ramps, each 50–900.
- **Interaction states:** primary 500 → 600 (hover) → 700 (active).
- **Secondary interactions:** outline + tinted hover background.
- All color pairings must meet WCAG AA contrast (see `24_accessibility.md`).

### Standard Pairings

Define which text token goes on which surface:

| Surface | Text | Muted Text | Usage |
|---|---|---|---|
| `bg` | `text` | `text-muted` | App background |
| `surface-1` | `text` | `text-muted` | Primary surfaces |
| `surface-2` | `text` | `text-faint` | Cards, inputs, recessed areas |
| `primary-500+` | white | — | Primary buttons, active tabs |

---

## Layout

> *Customize navigation patterns per project.*

- Grid system with max content width.
- Top navigation with search.
- Sidebar filtering for list/browse pages where applicable.

---

## Standard Components

### Base Component API Conventions

All Base components follow consistent prop naming:

| Prop | Type | Purpose |
|---|---|---|
| `variant` | string | Visual style (e.g., `primary`, `secondary`, `ghost`) |
| `size` | string | Size tier (e.g., `sm`, `md`, `lg`) |
| `disabled` | boolean | Disabled state |
| `loading` | boolean | Loading state |
| `compact` | boolean | Reduced padding/density |

- Emit events for actions (`@click`, `@change`) — let parent handle logic.
- Use named slots for customizable sections; provide default slot content for the common case.
- Props for simple variations, slots for structural variations.

### Buttons

- Fixed height (e.g., 36px / 2.25rem).
- **Primary:** solid primary background, white text.
- **Secondary:** transparent background, primary border, primary text.
- Always add `cursor-pointer` to `<button>` elements.

### Inputs

- Surface-2 filled, 1px border. Focus via border color change only (no glow, no shadow).
- Match button height for visual alignment.

### Cards

- Surface-2 background, 1px border.
- Hover: shadow + stronger border. No vertical translate on hover.
- UI text in sans font, data in mono font where applicable.
- Support compact mode via `compact` prop with reduced padding.
- Use `overflow-hidden` when containing background elements.

### Tabs

- Sentence case text, not uppercase.
- Active: primary-colored text + sliding underline indicator.
- Inactive: muted text, primary on hover.
- Responsive gap between tabs.

### Badges / Count Boxes

- Inline count indicators using project geometry (e.g., square boxes if sharp radius).
- Surface-2 background, border, centered text.

### Icons

- Use a centralized `BaseIcon` component — no inline SVGs scattered across the codebase.
- Icon stroke style should match project geometry (e.g., square linecaps for sharp projects, round for soft).
- Centralize domain-specific icon mappings in a utility file.

### Clickability Indicators

- Right-aligned chevron to indicate navigable items.
- Muted by default, primary-colored on group hover.

### Navigation Pairs (Prev/Next)

- Previous: `[←] Label` — button left, label right.
- Next: `Label [→]` — label left, button right.
- Compact buttons with arrow icon only.

---

## Feedback & Dialogs

### No Toasts

**Never use toast notifications.** All user feedback is inline, in context where the action happened. Toasts are easily missed, inaccessible, and disconnect feedback from the user's focus.

### Feedback Patterns

#### 1. Button State Machine

The primary feedback mechanism. The button itself communicates progress:

| State | Visual | Duration |
|---|---|---|
| `idle` | Default label | — |
| `loading` | Spinner + disabled, label changes (e.g., "Saving...") | Until resolved |
| `success` | Checkmark icon or "Saved" label | ~2s, then back to idle |
| `error` | Button returns to idle, inline error message appears below | Until resolved |

- Covers ~80% of feedback needs (form submits, actions, toggles).
- The `loading` prop on Base button components drives this behavior.

#### 2. Form Validation

- **Field-level:** error messages appear directly below each invalid field, associated via `aria-describedby`.
- **Timing:** validate on **blur** (not on every keystroke). Re-validate all on submit.
- **Error summary:** for complex forms (5+ fields), show an error summary at the top linking to each invalid field.
- **Success:** on successful submit, use the button state machine. For multi-step forms, advance to the next step.

#### 3. Inline Message Bands

For non-field feedback within a section (e.g., "Settings saved", "Payment failed"):

- A styled message block using semantic colors (`success`, `danger`, `warning`).
- Appears **in the same visual context** as the action — not floating, not at the top of the page.
- **Errors persist** until the user takes corrective action.
- **Success messages** auto-fade after ~3s or persist as static text — never require dismissal.

#### 4. Optimistic UI

For fast-feeling interactions (toggles, likes, reordering, inline edits):

- Apply the change **immediately** in the UI.
- Send the request in the background.
- Roll back with an inline error if the server rejects it.
- Only use for low-risk, reversible actions.

### Modals — Last Resort Only

Modals interrupt user flow and should only be used when no inline or slide-over alternative works. **Before implementing a modal, confirm with the user that it is necessary.**

Acceptable uses:
- Destructive confirmations ("Delete this item permanently?").
- Flows that genuinely require isolated focus (e.g., multi-step wizard with no other placement).

Prefer instead:
- Inline expansion or disclosure for additional content.
- Slide-over panels for supplementary detail.
- Inline forms over modal forms.

---

## Component States

Every data-driven component must handle all states:

| State | Pattern |
|---|---|
| **Loading** | Skeleton placeholders matching the component's layout shape. Never use spinners in place of content. |
| **Empty** | Centered message with icon + description + optional action CTA. |
| **Error** | Inline error message with retry action. Use `danger` semantic color. |
| **Loaded** | Normal content rendering. |

- Loading skeletons use `surface-2` animated with a subtle pulse (`animate-pulse`).
- Empty states are a design opportunity — not just "No data found."
- Error states always offer a recovery path (retry button, link to help).

---

## Motion

- Transitions: 120–200ms for micro-interactions.
- Define shared keyframe animations in `main.css`.
- Respect `prefers-reduced-motion` — see `24_accessibility.md`.

### Easing Functions

| Name | Value | Usage |
|---|---|---|
| Default | `ease-out` | Most micro-interactions |
| Enter | `cubic-bezier(0, 0, 0.2, 1)` | Elements appearing (modals, dropdowns) |
| Exit | `cubic-bezier(0.4, 0, 1, 1)` | Elements disappearing |