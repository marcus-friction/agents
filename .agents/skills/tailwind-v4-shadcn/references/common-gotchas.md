# Common Gotchas & Solutions

## CSS and Theme Checks

### 1. Choosing a Cascade Location for `:root`

This skill's baseline keeps theme variables at the document root:
```css
:root {
  --background: hsl(0 0% 100%);
}
```

Ordinary custom CSS is supported in Tailwind v4, including selectors outside
Tailwind directives. A layered `:root` rule is also valid CSS:
```css
@layer base {
  :root {
    --background: hsl(0 0% 100%);
  }
}
```

Choose deliberately based on the project's cascade. Do not move an existing
rule merely because it is layered; check ordering and resulting styles first.

The baseline applies element defaults separately:
```css
@layer base {
  body {
    background-color: var(--background);
  }
}
```

---

### 2. Nested `@theme` Directive

❌ **WRONG:**
```css
@theme {
  --color-primary: hsl(0 0% 0%);
}

.dark {
  @theme {
    --color-primary: hsl(0 0% 100%);
  }
}
```

✅ **CORRECT:**
```css
:root {
  --primary: hsl(0 0% 0%);
}

.dark {
  --primary: hsl(0 0% 100%);
}

@theme inline {
  --color-primary: var(--primary);
}
```

**Why:** Tailwind v4 doesn't support `@theme` inside selectors.

---

### 3. Double `hsl()` Wrapping

❌ **WRONG:**
```css
@layer base {
  body {
    background-color: hsl(var(--background));
  }
}
```

✅ **CORRECT:**
```css
@layer base {
  body {
    background-color: var(--background);  /* Already has hsl() */
  }
}
```

**Why:** Variables already contain `hsl()`, double-wrapping creates `hsl(hsl(...))`.

---

### 4. Blindly retaining or deleting `tailwind.config.ts`

❌ **WRONG:** assuming a file can be deleted merely because the project uses
Tailwind v4, or leaving active v3-only color configuration without checking how
the build consumes it.

An example of v3-style configuration that needs investigation:
```typescript
// tailwind.config.ts
export default {
  theme: {
    extend: {
      colors: {
        primary: 'hsl(var(--primary))'
      }
    }
  }
}
```

✅ **CORRECT:** inspect imports, scripts, plugins, presets, and generated config
first. Tailwind v4 can load a compatible JavaScript config explicitly with
`@config`; preserve that path or move confirmed theme values into the previewed
CSS-first mapping when appropriate:
```css
@config "../../tailwind.config.js";
```

```typescript
// Keep a compatible file until its approved migration/removal is verified.
export default {}

// components.json
{
  "tailwind": {
    "config": ""  // ← Empty string
  }
}
```

**Why:** CSS-first theme values are clearer for this pattern, but deletion can
discard plugins, presets, or project-owned behavior. Preserve compatible config
and remove only the exact reviewed file in the approved migration.

---

### 5. Missing `@theme inline` Mapping

❌ **WRONG:**
```css
:root {
  --background: hsl(0 0% 100%);
}

/* No @theme inline block */
```

Result: `bg-background` class doesn't exist

✅ **CORRECT:**
```css
:root {
  --background: hsl(0 0% 100%);
}

@theme inline {
  --color-background: var(--background);
}
```

**Why:** `@theme inline` generates the utility classes.

---

## Configuration Gotchas

### 6. Wrong components.json Config

❌ **WRONG:**
```json
{
  "tailwind": {
    "config": "tailwind.config.ts"  // ← No!
  }
}
```

✅ **CORRECT:**
```json
{
  "tailwind": {
    "config": ""  // ← Empty for v4
  }
}
```

---

### 7. Mixing PostCSS and Vite Integration Without Intent

PostCSS integration through `@tailwindcss/postcss` is supported in Tailwind v4.
This skill targets an adopted Vite stack, where the direct Vite plugin is the
default integration:

```typescript
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()]
})
```

An existing working PostCSS path is not a v3 defect. Preserve it unless the
approved scope includes a migration. What to avoid is configuring both paths
without a project-specific reason, for example adding this on top of the Vite
plugin:
```typescript
// vite.config.ts
export default defineConfig({
  css: {
    postcss: './postcss.config.js'
  }
})
```

---

### 8. Missing Path Aliases

❌ **WRONG:**
```typescript
// tsconfig.json has no paths
import { Button } from '../../components/ui/button'
```

✅ **CORRECT:**
```json
// tsconfig.app.json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

```typescript
import { Button } from '@/components/ui/button'
```

---

## Color System Gotchas

### 9. Using `dark:` Variants for Semantic Colors

❌ **WRONG:**
```tsx
<div className="bg-primary dark:bg-primary-dark" />
```

✅ **CORRECT:**
```tsx
<div className="bg-primary" />
```

**Why:** With proper CSS variable setup, `bg-primary` automatically responds to theme.

---

### 10. Hardcoded Color Values

❌ **WRONG:**
```tsx
<div className="bg-blue-600 dark:bg-blue-400" />
```

✅ **CORRECT:**
```tsx
<div className="bg-primary" />  {/* Or bg-info, bg-success, etc. */}
```

**Why:** Semantic tokens enable theme switching and reduce repetition.

---

## Component Gotchas

### 11. Missing `cn()` Utility

❌ **WRONG:**
```tsx
<div className={`base ${isActive && 'active'}`} />
```

✅ **CORRECT:**
```tsx
import { cn } from '@/lib/utils'
<div className={cn("base", isActive && "active")} />
```

**Why:** `cn()` properly merges and deduplicates Tailwind classes.

---

### 12. Empty String in Radix Select

❌ **WRONG:**
```tsx
<SelectItem value="">Select an option</SelectItem>
```

✅ **CORRECT:**
```tsx
<SelectItem value="placeholder">Select an option</SelectItem>
```

**Why:** Radix UI Select doesn't allow empty string values.

---

## Installation Gotchas

### 13. Wrong Tailwind Package

❌ **WRONG:** carrying a Tailwind 3 range forward, or installing an unpinned
Tailwind version without checking the host project.

✅ **CORRECT:** inspect the manifest and lockfile, resolve mutually compatible
exact versions of `tailwindcss` and `@tailwindcss/vite`, and include both
purposes and the lockfile diff in the dependency preview.

---

### 14. Missing Dependencies

❌ **WRONG:**
```json
{
  "dependencies": {
    "tailwindcss": "^4.1.0"
    // Missing @tailwindcss/vite
  }
}
```

✅ **CORRECT:** derive the needed package set from the selected components and
existing application. Record exact, project-compatible versions—without range
operators—for each new package in the approved plan. Do not copy a stock
manifest over existing dependencies.

---

### 17. tw-animate-css Import Error (REAL-WORLD ISSUE)

❌ **WRONG:** adding `tailwindcss-animate` by habit without inspecting the
generated CSS and project dependencies.

```css
@import "tw-animate-css"; /* Fails when the package was not planned/installed. */
```

✅ **CORRECT:** use native CSS animation when sufficient. If selected shadcn
output imports `tw-animate-css`, resolve an exact compatible version and show
its purpose, install command, and lockfile change before applying it.

**Why:**
- `tailwindcss-animate` is a different, v3-era integration
- An import without its matching dependency causes a build error
- Generator output and installed packages must be reconciled as one batch

**Impact:** Build failure, requires manual CSS file cleanup

---

### 18. Conflicting Base Rules After shadcn init

Multiple `@layer base` blocks are valid and participate in cascade order. The
problem is conflicting declarations, not the number of blocks. After generator
output, compare the resulting selectors and values:

```css
@layer base {
  body {
    background-color: var(--background);
  }
}

@layer base {  /* ← Duplicate added by shadcn init */
  * {
    border-color: hsl(var(--border));
  }
}
```

Merge blocks only when doing so preserves ordering and makes the conflict
clearer:

```css
@layer base {
  * {
    border-color: var(--border);
  }

  body {
    background-color: var(--background);
    color: var(--foreground);
  }
}
```

**Prevention:**
- Compare `src/index.css` before and after generator output.
- Reconcile duplicate selectors or contradictory declarations.
- Preserve valid separate layer blocks when their order is intentional.

**Impact:** unresolved conflicting declarations can create unexpected styles.

---

## Testing Gotchas

### 15. Not Testing Both Themes

❌ **WRONG:**
Only testing in light mode

✅ **CORRECT:**
Test in:
- Light mode
- Dark mode
- System mode
- Both initial load and toggle

---

### 16. Not Checking Contrast

❌ **WRONG:**
Colors look good but fail WCAG

✅ **CORRECT:**
- Use browser DevTools Lighthouse
- Check contrast ratios (4.5:1 minimum)
- Test with actual users

---

## Quick Diagnosis

**Symptoms → Likely Cause:**

| Symptom | Likely Cause |
|---------|-------------|
| `bg-primary` doesn't work | Missing `@theme inline` mapping |
| Colors all black/white | Double `hsl()` wrapping |
| Dark mode not switching | Missing ThemeProvider |
| Build fails | Legacy config, plugins, and CSS entry disagree with the v4 setup |
| Text invisible | Wrong contrast colors |
| `@/` imports fail | Missing path aliases in tsconfig |

---

## Prevention Checklist

Before deploying:
- [ ] Existing `tailwind.config.*` was preserved, or its exact migration/removal was reviewed and approved
- [ ] CSS-first shadcn/ui v4 projects use `"config": ""` in `components.json`
- [ ] Semantic color variables contain valid complete color values and are not double-wrapped
- [ ] `@theme inline` maps the semantic variables that need generated utilities
- [ ] The intended cascade location and ordering of `:root` rules was verified
- [ ] Theme provider wraps app
- [ ] Tested in both light and dark modes
- [ ] All text has sufficient contrast
