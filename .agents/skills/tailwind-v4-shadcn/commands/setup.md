# Setup Tailwind v4 + shadcn/ui

Add Tailwind CSS v4 and shadcn/ui to an existing React/Vite project.

---

## Your Task

Follow these steps to configure Tailwind v4 and shadcn/ui.

### 1. Inspect prerequisites and current state

Verify the project has adopted:
- Vite + React configured
- TypeScript (recommended)

Read the package manifest, lockfile, package-manager metadata, existing Vite and
Tailwind configuration, `components.json`, CSS entry, aliases, and working-tree
diff. If this is not the adopted stack, report the mismatch and stop.

### 2. Prepare the exact effect plan

Reuse compatible locked packages. For each missing dependency, resolve an exact
project-compatible version and explain its purpose. Preview the package-manager
command and lockfile change together with every file to create, edit, migrate,
or remove. Include generator output; when the generator has no reliable preview,
run the exact resolved CLI in a disposable copy and show that diff.

Obtain the project's normal decision for an unresolved new dependency,
destructive removal or migration, or dirty/special target unless that exact
effect was already supplied. Ordinary clean, additive configuration inside an
implementation request needs no redundant gate. Revalidate and execute only the
approved unchanged batch. Never substitute a floating tag or silently overwrite
configuration.

### 3. Configure Vite

Reconcile the approved change into `vite.config.ts`, preserving other plugins:

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

This Vite-specific setup uses `@tailwindcss/vite`. Tailwind v4 also supports
`@tailwindcss/postcss`; preserve an existing project-selected PostCSS path
unless an approved migration replaces it, and do not configure both by habit.

### 4. Create CSS Entry

Reconcile the approved change into `src/index.css`:

```css
@import "tailwindcss";
```

### 5. Initialize shadcn/ui

Use only the exact shadcn CLI version recorded in the approved plan. Prefer its
non-interactive, preview, or dry-run mode. Otherwise generate in the disposable
copy described above, review the resulting paths and diffs, then reproduce only
the approved output in the project.

When prompted:
- Style: Default
- Base color: Neutral (or user preference)
- CSS variables: Yes
- Tailwind config: Leave empty for this CSS-first shadcn/ui v4 setup
- Components path: `src/components`
- Utils path: `src/lib/utils`

### 6. Configure components.json

Ensure `components.json` has:

```json
{
  "tailwind": {
    "config": ""
  }
}
```

Use the empty `components.json` config field for this CSS-first shadcn/ui v4
setup. A compatible JavaScript configuration may still be loaded explicitly in
CSS through `@config`; inspect that path before migration or removal.

### 7. Add or reconcile the Theme Provider

If the project does not already provide compatible theme state, reconcile the
previewed `src/components/theme-provider.tsx` change:

```typescript
import { createContext, useContext, useEffect, useState } from 'react';

type Theme = 'dark' | 'light' | 'system';

type ThemeProviderProps = {
  children: React.ReactNode;
  defaultTheme?: Theme;
  storageKey?: string;
};

type ThemeProviderState = {
  theme: Theme;
  setTheme: (theme: Theme) => void;
};

const ThemeProviderContext = createContext<ThemeProviderState | undefined>(undefined);

export function ThemeProvider({
  children,
  defaultTheme = 'system',
  storageKey = 'ui-theme',
}: ThemeProviderProps) {
  const [theme, setTheme] = useState<Theme>(
    () => (localStorage.getItem(storageKey) as Theme) || defaultTheme
  );

  useEffect(() => {
    const root = window.document.documentElement;
    root.classList.remove('light', 'dark');

    if (theme === 'system') {
      const systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches
        ? 'dark'
        : 'light';
      root.classList.add(systemTheme);
    } else {
      root.classList.add(theme);
    }
  }, [theme]);

  return (
    <ThemeProviderContext.Provider
      value={{
        theme,
        setTheme: (theme: Theme) => {
          localStorage.setItem(storageKey, theme);
          setTheme(theme);
        },
      }}
    >
      {children}
    </ThemeProviderContext.Provider>
  );
}

export const useTheme = () => {
  const context = useContext(ThemeProviderContext);
  if (!context) throw new Error('useTheme must be used within ThemeProvider');
  return context;
};
```

### 8. Wrap App with Theme Provider

Reconcile the previewed main-entry change (for example `src/main.tsx`):

```typescript
import { ThemeProvider } from '@/components/theme-provider';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ThemeProvider defaultTheme="system">
      <App />
    </ThemeProvider>
  </React.StrictMode>
);
```

### 9. Add First Components

Generate only components in the approved preview, using the same exact CLI
version. Do not overwrite locally modified components. Additional components
are a later exact generator/file batch, not implicit permission from setup.

### 10. Provide Next Steps

```
✅ Tailwind v4 + shadcn/ui configured!

📁 Added:
   - @tailwindcss/vite plugin
   - src/components/ui/     (shadcn components)
   - src/lib/utils.ts       (cn utility)
   - Theme provider         (dark/light/system)

🎨 To add components later:
   - resolve the same project-compatible exact CLI version
   - preview the named component output
   - preserve existing component changes

⚠️ Critical Rules:
   - Use semantic colors: bg-primary, text-foreground
   - Never use raw Tailwind colors: bg-blue-500

📚 Skill loaded: tailwind-v4-shadcn
   - v3→v4 syntax corrections
   - Semantic color system
   - Theme provider included
```

---

## Tailwind v4 Key Differences

| v3 Pattern | v4 Pattern |
|------------|------------|
| existing JavaScript config | Preserve via `@config`, or migrate verified values into `@theme` |
| PostCSS integration | Supported; this Vite workflow selects `@tailwindcss/vite` |
| repeated declarations | Prefer utility classes; supported `@apply` or ordinary CSS remain available |
