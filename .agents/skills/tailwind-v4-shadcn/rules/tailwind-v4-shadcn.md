---
paths: "**/*.css", "**/*.tsx", "**/*.jsx", tailwind.config.*, components.json, postcss.config.*
---

# Tailwind v4 + shadcn/ui Corrections

General model knowledge may include Tailwind v3 patterns. This project uses
**Tailwind v4** with different syntax.

## Critical Differences from v3

### Configuration
- Prefer CSS-first `@theme` blocks for new v4 configuration. Preserve an
  existing compatible `tailwind.config.*`; migrate or remove it only after an
  exact usage check and approved preview.
- JavaScript configuration remains compatible through the explicit `@config`
  directive. Check whether an existing config is loaded before changing it.
- PostCSS integration is supported in v4. This Vite-specific workflow selects
  `@tailwindcss/vite`; do not add a second processing path without a project
  reason.
- For the CSS-first shadcn/ui v4 setup, use `"config": ""` in
  `components.json`. That field does not prove a separately loaded `@config`
  file is unused.

### CSS Syntax
```css
/* ❌ v3 (an agent may suggest this) */
@tailwind base;
@tailwind components;
@tailwind utilities;

/* ✅ v4 (use this) */
@import "tailwindcss";
```

### Theme Configuration
```javascript
// tailwind.config.js — compatible when loaded explicitly from CSS
export default { theme: { colors: { primary: '#3b82f6' } } }
```

```css
@config "../../tailwind.config.js";

/* Preferred for new CSS-first v4 theme tokens */
@theme inline {
  --color-primary: var(--primary);
  --color-background: var(--background);
}
```

### Animations Package
Do not add the v3-era `tailwindcss-animate` package. If generated CSS requires
`tw-animate-css`, resolve a project-compatible exact version and include its
purpose, command, and lockfile change in the approved dependency preview.
Install an animation package only when the selected output requires it; native
CSS animation remains a valid dependency-free option.

```css
/* Add the second import only when selected output requires it. */
@import "tailwindcss";
@import "tw-animate-css";
```

### Plugins
Plugins in a JavaScript config loaded through `@config` remain supported for
compatibility. Inspect and preserve an existing compatible plugin path. For a
new CSS-first setup, `@plugin` loads a JavaScript plugin directly; it is an
alternative, not a reason to rewrite working configuration. Configuration,
presets, plugins, and CSS-driven features are merged where possible, with CSS
taking precedence on conflicts.

```javascript
// Supported compatibility path when this config is loaded with @config.
export default {
  plugins: [require('@tailwindcss/typography')],
}
```

```css
/* CSS-first alternative for a new setup. */
@plugin "@tailwindcss/typography";
```

### @apply Directive
Tailwind v4 supports `@apply` for composing existing utilities into custom CSS.
Prefer utilities in markup or ordinary custom CSS when they are clearer; use
`@apply` when composition is the simpler project-consistent choice. In CSS
modules or separately processed component styles, expose the theme with
`@reference` before applying utilities.

```css
/* Supported when these utilities are in scope */
.btn { @apply px-4 py-2 bg-primary; }

/* Ordinary custom CSS is also supported */
.btn { padding: 0.5rem 1rem; background-color: var(--primary); }
```

## Variable Architecture

For this shadcn/ui semantic-token pattern, use this structure:

```css
/* 1. Define at root (NOT inside @layer base) */
:root {
  --background: hsl(0 0% 100%);  /* hsl() wrapper required */
  --primary: hsl(221.2 83.2% 53.3%);
}

.dark {
  --background: hsl(222.2 84% 4.9%);
  --primary: hsl(217.2 91.2% 59.8%);
}

/* 2. Map to Tailwind utilities */
@theme inline {
  --color-background: var(--background);
  --color-primary: var(--primary);
}

/* 3. Apply base styles (NO hsl wrapper here) */
@layer base {
  body {
    background-color: var(--background);
    color: var(--foreground);
  }
}
```

## Dark Mode

- No `dark:` variants needed for semantic colors - theme switches automatically
- Just use `bg-background`, `text-foreground`, etc.
- ThemeProvider toggles `.dark` class on `<html>` element

## Quick Fixes

| If older guidance suggests... | Use instead... |
|----------------------|----------------|
| `@tailwind base` | `@import "tailwindcss"` |
| existing JavaScript config | Preserve and load with `@config`, or migrate its verified values in the approved preview |
| generated animation dependency | Inspect selected output; use native CSS, or an exact compatible `tw-animate-css` only when required |
| repeated utility declarations | `@apply`, direct CSS, or utility classes—whichever is clearest in context |
| `hsl(var(--color))` | `var(--color)` (already has hsl) |
