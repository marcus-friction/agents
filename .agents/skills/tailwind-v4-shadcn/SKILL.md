---
name: tailwind-v4-shadcn
description: Tailwind v4 + shadcn/ui setup (@theme inline + CSS variables). Fixes tw-animate-css, @apply, dark mode.
user-invocable: true
---

# Tailwind v4 + shadcn/ui

## 1. Quick Start
```bash
pnpm add tailwindcss @tailwindcss/vite; pnpm add -D @types/node tw-animate-css; pnpm dlx shadcn@latest init; rm tailwind.config.ts
```
**`vite.config.ts`**: `plugins: [react(), tailwindcss()]`
**`components.json`**: `"tailwind": { "config": "", "css": "src/index.css", "baseColor": "slate", "cssVariables": true }`

## 2. Architecture (MANDATORY)
**`src/index.css`**:
```css
@import "tailwindcss";
@import "tw-animate-css";
:root { --background: hsl(0 0% 100%); /* ... */ }
.dark { --background: hsl(222.2 84% 4.9%); /* ... */ }
@theme inline { --color-background: var(--background); /* map all */ }
@layer base { body { background-color: var(--background); color: var(--foreground); } } /* NO hsl() wrapper here! */
```
*Dark mode requires `ThemeProvider` wrapped around App and toggles `.dark` on `<html>`.*

## 3. Critical Rules
- **DO**: Wrap `:root` colors in `hsl()`. Map all via `@theme inline`. Use `@tailwindcss/vite`.
- **DON'T**: Put `:root` inside `@layer base`. Use `tailwind.config.ts`. Double-wrap `hsl(var(--bg))`. Use `@apply` with `@layer base/components` (use `@utility`). Use `dark:` variants for semantics.

## 4. Common Errors & Solutions
| Error | Fix |
|---|---|
| `tw-animate-css` missing | `pnpm add -D tw-animate-css`; `@import "tw-animate-css"` in CSS. Do NOT use `tailwindcss-animate`. |
| Colors not applying | Map variable in `@theme inline { --color-primary: var(--primary); }` |
| Dark mode static | Add `<ThemeProvider>` to `main.tsx`. |
| Dupe `@layer base` | Ensure only one `@layer base` exists in CSS. |
| Build fails on config | `rm tailwind.config.ts` |
| Multi-theme dark mode fails | Don't use `@theme inline` for multi-theme (data-theme="blue"). Use `@theme` + `@layer theme`. |
| `@apply` fails in v4 layer | Change `@layer components` to `@utility custom-class { @apply ... }`. |
| `@layer base` ignored | Don't wrap `:root` in `@layer base`. Define at document root. |

## 5. v4 Changes & Plugins
- **OKLCH**: Default color space. Use `oklch(0.7 0.15 250)` for modern colors. Fallbacks automatically generated.
- **Built-in**: Container Queries (`@container`, `@md:`), Line Clamp (`line-clamp-3`).
- **Plugins**: Use `@plugin "@tailwindcss/typography";` (not `@import`). Run `pnpm add -D @tailwindcss/typography` for prose.
- **Visuals**: `ring` is 1px now (was 3px).
- **Migration**: Automated `@tailwindcss/upgrade` often fails. Do manual migration. Default element styles (h1, ul) removed—use Typography plugin or custom base styles. Use Vite plugin, not PostCSS.
