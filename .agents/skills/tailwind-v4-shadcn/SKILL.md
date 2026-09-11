---
name: tailwind-v4-shadcn
description: Tailwind v4 + shadcn/ui setup (@theme inline + CSS variables). Fixes tw-animate-css, @apply, dark mode.
---

# Tailwind v4 + shadcn/ui

## 1. Inspect and plan

Apply this guidance only to an adopted Vite + React + Tailwind v4 stack. Use
the scope already supplied, then inspect the package manifest, lockfile, package
manager, existing Tailwind/shadcn configuration, CSS entry point, aliases, and
working-tree state before proposing changes.

Use installed and locked dependency evidence first. When a dependency is
missing, resolve project-compatible exact versions and state the purpose of
each package. Do not use floating ranges, implicit tags, or an unpinned
generator. A new dependency still needs the project's normal dependency
decision unless the exact package and purpose were already approved.

Clean, additive file changes already inside a supplied implementation scope
need no second approval; share their preview as progress and proceed. Ask only
for an unresolved dependency, destructive removal or migration, dirty/special
target, or other material effect.

Prepare one effect preview covering the exact dependency commands and file
diffs, generator output, and any removal or migration. Preserve compatible
existing config and user changes; migrate or remove it only after an exact usage
check, verified replacement or proof that it is unused, and approved preview.
If a generator has no trustworthy preview, run the exact resolved CLI against a
disposable copy and present its diff; do not experiment on the project. Execute
only the approved unchanged batch after revalidating its files and dependency
facts; the supplied implementation request approves ordinary in-scope edits.

For a CSS-first setup, the planned result normally includes
**`vite.config.ts`** with `plugins: [react(), tailwindcss()]` and
**`components.json`** with
`"tailwind": { "config": "", "css": "src/index.css", "baseColor": "slate", "cssVariables": true }`.

## 2. CSS-first baseline
**`src/index.css`**:
```css
@import "tailwindcss";
:root { --background: hsl(0 0% 100%); /* ... */ }
.dark { --background: hsl(222.2 84% 4.9%); /* ... */ }
@theme inline { --color-background: var(--background); /* map all */ }
@layer base { body { background-color: var(--background); color: var(--foreground); } } /* NO hsl() wrapper here! */
```
Add the import and an exact compatible package only when selected output
requires it. If selected output does not import `tw-animate-css`, do not add its
import or package.
*Dark mode requires `ThemeProvider` wrapped around App and toggles `.dark` on `<html>`.*

## 3. Critical Rules
- **DO**: Wrap this baseline's `:root` colors in `hsl()`. Map semantic tokens via `@theme inline`. Use `@tailwindcss/vite` for this Vite integration. Preserve compatible JavaScript configuration explicitly loaded with `@config`. Use ordinary custom CSS or supported `@apply` where either is clearer than markup utilities.
- **DON'T**: Replace or ignore compatible existing Tailwind configuration merely because it uses `tailwind.config.*`. Double-wrap `hsl(var(--bg))`. Add both Vite and PostCSS processing paths without a project-specific reason. Use `dark:` variants for semantic colors already driven by variables.

## 4. Common Errors & Solutions
| Error | Fix |
|---|---|
| `tw-animate-css` missing | Confirm the import is required, then add a project-compatible exact version to the dependency preview. Do not substitute `tailwindcss-animate`. |
| Colors not applying | Map variable in `@theme inline { --color-primary: var(--primary); }` |
| Dark mode static | Add `<ThemeProvider>` to `main.tsx`. |
| Conflicting base rules | Multiple `@layer base` blocks are valid; reconcile duplicate selectors or contradictory declarations while preserving cascade order. |
| Build fails on config | Inspect how the config is consumed; migrate or remove it only in the approved file preview. |
| Multi-theme dark mode fails | Don't use `@theme inline` for multi-theme (data-theme="blue"). Use `@theme` + `@layer theme`. |
| `@apply` reports an unknown utility | Verify the utility exists and its theme is in scope; use `@reference` in separately processed CSS modules or component styles. |
| Theme variables have unexpected precedence | Inspect the project's cascade and layer order; keep this baseline's `:root` tokens at document root. |

## 5. v4 Changes & Plugins
- **OKLCH**: Default color space. Use `oklch(0.7 0.15 250)` for modern colors. Fallbacks automatically generated.
- **Built-in**: Container Queries (`@container`, `@md:`), Line Clamp (`line-clamp-3`).
- **Plugins**: Use `@plugin "@tailwindcss/typography";` (not `@import`). If prose support is required, plan an exact compatible `@tailwindcss/typography` version and purpose.
- **Visuals**: `ring` is 1px now (was 3px).
- **Migration**: Inspect automated `@tailwindcss/upgrade` output before applying it. Default element styles (h1, ul) are not supplied by Preflight—use the Typography plugin or ordinary custom base styles when required. For this Vite workflow, prefer the Vite plugin; PostCSS remains a supported integration for projects that adopt it.
