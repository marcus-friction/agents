# Stack state

- The project has adopted Vite, React, Tailwind CSS 4, and shadcn/ui.
- The lockfile already contains compatible exact versions of
  `@tailwindcss/vite`, `tailwindcss`, and React.
- `vite.config.ts` already uses `@tailwindcss/vite`; no PostCSS path exists or
  is needed.
- `src/index.css` uses `@config "../tailwind.config.js"`.
- `tailwind.config.js` contains a used project-specific plugin and must remain.
- No selected stylesheet imports `tw-animate-css`.
- The requested change is to plan class-based dark-mode support without adding
  dependencies or running a generator.
