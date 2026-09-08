# Third-Party Notices

Agents Ecosystem contains adapted and unmodified material from the projects
below. Revisions are full Git commit identifiers audited for release 1.7.0.
“Adapted” means the local maintainers changed upstream material; “retained”
means the relevant local files were byte-identical when audited.
`.agents/legal/retained-provenance.json` records the audited upstream path,
Git blob, local path, and SHA-256 digest for every retained file.

Material not identified below is maintained by Agents Ecosystem contributors
under the repository [MIT license](LICENSE). Attribution of imported TomFit AG
material does not claim that TomFit AG authored the entire repository.

## Distributed material

### TomFit Agent Ecosystem

- Source: <https://github.com/TomFitAG/tomfit-agents>
- Revision: `00c3885b4a456fb1317e6ec2faf5f73d0d0ddf77`
- License: MIT; Copyright (c) 2026 TomFit AG
- Scope: adapted installer hardening, managed-tree and template-staging
  architecture, provider adapters, deterministic tests, release channel
  contracts, provenance documentation, and proportional workflow/skill work
  incorporated into release 1.7.0. The skill scope includes the Playwright and
  migration workflows plus adapted onboarding, planning, review, debugging,
  and TDD contracts. Project-specific TomFit branding, private-repository
  authentication, and the Java/Gradle dependency baseline were not retained.

### gstack

- Source: <https://github.com/garrytan/gstack>
- Revision: `1211b6b40becb684eaf29b0f30a650a8a9b222a5`
- License: MIT; Copyright (c) 2026 Garry Tan
- Scope: adapted material in `review-gstack`, `review-plan`,
  `adversarial-review`, `plan`, `office-hours`, and `design-consultation`.

### Compound Engineering

- Source: <https://github.com/EveryInc/compound-engineering-plugin>
- Revision: `59dbaef37607354d103113f05c13b731eecbb690`
- License: MIT; Copyright (c) 2025 Every and Copyright (c) 2025 Kieran
  Klaassen
- Scope: adapted material in `architecture-review`, `performance-review`,
  `security-review`, `changelog`, `compound`, `review`, and `brainstorm`.

### Superpowers

- Source: <https://github.com/obra/superpowers>
- Revision: `b36e0829c6d0140e93cfef2ca599b1b07d4a7797`
- License: MIT; Copyright (c) 2025 Jesse Vincent
- Scope: adapted `systematic-debugging` and `test-driven-development` skills;
  four referenced technique files are retained from upstream.

### Jezweb Claude Skills

- Source: <https://github.com/jezweb/claude-skills>
- Revision: `bf917575ed6b65eb98307ced903f469020d8cd0a`
- License: MIT; Copyright (c) 2025 Jeremy Dawes (Jezweb)
- Scope: adapted `tailwind-v4-shadcn` skill with seven retained template and
  reference files.

### shadcn/ui

- Source: <https://github.com/shadcn-ui/ui>
- Revision: `7c9eaba1c0a6404c990c144a654792e3313c650d`
- License: MIT; Copyright (c) 2023 shadcn
- Scope: patterns and template portions used by `tailwind-v4-shadcn`; this
  notice is retained conservatively where Jezweb and shadcn sources overlap.

### Anthropic Skills

- Source: <https://github.com/anthropics/skills>
- Revision: `b9e19e6f44773509fbdd7001d77ff41a49a486c1`
- License: Apache-2.0; Copyright 2026 Anthropic, PBC.
- Scope: `skill-creator`; thirteen files are retained and four files are
  adapted with prominent modification notices.
- License copy: `.agents/skills/skill-creator/LICENSE.txt`.

### Agentic SEO Skill

- Source: <https://github.com/Bhanunamikaze/Agentic-SEO-Skill>
- Revision: `337069435d16c68071523f488841b882e35d9767`
- License: MIT; Copyright (c) 2026 Bhanu Namikaze and Copyright (c) 2026
  agricidaniel
- Scope: adapted `seo-review`; `references/cwv-thresholds.md` is retained.

### Marketing Skills

- Source: <https://github.com/coreyhaines31/marketingskills>
- Revision: `0d586e4952494d58ed5c60926aa5982311e41044`
- License: MIT; Copyright (c) 2025 Corey Haines
- Scope: adapted `copywriting`, `copy-editing`, and portions of `seo-review`;
  `copy-editing/references/content-refresh.md` is retained.

### Google Labs DESIGN.md

- Source: <https://github.com/google-labs-code/design.md>
- Revision: `89012cc4d140530d60742f76be04768585c1aa3a`
- License: Apache-2.0; Copyright 2026 Google LLC
- Scope: `project-templates/base/DESIGN.md` is an adapted format/template with
  a prominent modification notice.
- License copy: `.agents/skills/skill-creator/LICENSE.txt` contains the complete
  Apache License 2.0 terms used by both Apache-licensed sources.

### Vue.js AI Skills

- Source: `vendor/vuejs-ai` distribution recorded by each skill's `SYNC.md`
- Revision: `f3dd1bf4d3ac78331bdc903e4519d561c538ca6a`
- License: MIT; Copyright (c) 2025 hyf0, SerKo
- Scope: retained and adapted Vue best-practice, router, and testing skills;
  license copies are distributed with those skills.

### VueUse Skills

- Source: `vendor/vueuse` distribution recorded by the skill's `SYNC.md`
- Revision: `b6bb79b99fb1f1dba1f907829676a651735bbc10`
- License: MIT; Copyright (c) 2026 SerKo
- Scope: retained and adapted `vueuse-functions`; its license copy is
  distributed with the skill.

## Optional runtime downloads

The `skill-creator` HTML viewers reference SheetJS 0.20.3 from
`cdn.sheetjs.com` and Poppins and Lora from Google Fonts. These are runtime
downloads, not vendored files. SheetJS Community Edition 0.20.3 is
Apache-2.0; Poppins and Lora are SIL Open Font License 1.1. Opening those
viewers may therefore contact external hosts and is not part of the
repository's offline deterministic test guarantee.

## MIT permission notice

The MIT-licensed portions retain these notices:

- Copyright (c) 2026 Garry Tan
- Copyright (c) 2025 Every
- Copyright (c) 2025 Kieran Klaassen
- Copyright (c) 2025 Jesse Vincent
- Copyright (c) 2025 Jeremy Dawes (Jezweb)
- Copyright (c) 2023 shadcn
- Copyright (c) 2026 Bhanu Namikaze
- Copyright (c) 2026 agricidaniel
- Copyright (c) 2025 Corey Haines
- Copyright (c) 2026 TomFit AG
- Copyright (c) 2025 hyf0, SerKo
- Copyright (c) 2026 SerKo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
