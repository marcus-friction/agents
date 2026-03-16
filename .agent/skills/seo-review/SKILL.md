---
name: seo-review
description: Comprehensive SEO, Core Web Vitals, and Semantic HTML review.
argument-hint: "[URL or files to review]"
disable-model-invocation: true
---

# SEO & UI Quality Review

Perform a deep technical SEO, Core Web Vitals, and structural review of the provided files or codebase.

## The Checklist

### 1. Technical SEO & Indexability
- **Nuxt Metadata:** Are `useHead` or `useSeoMeta` correctly implemented? Are properties like `title`, `description`, `og:image`, and `og:title` present and dynamic?
- **Canonicals:** Does the page output a `<link rel="canonical" href="...">` to prevent duplicate content indexing?
- **Robots Directives:** Are pagination, internal dashboards, or low-value routes correctly marked with `<meta name="robots" content="noindex, follow">`?
- **Sitemap:** If a new dynamic route was added, was the `@nuxtjs/sitemap` configuration updated to crawl it?

### 2. Core Web Vitals & Performance
- **Image Optimization:** Are images using `NuxtImg` (or equivalent) for WebP/AVIF formatting?
- **Lazy Loading:** Are below-the-fold images using `loading="lazy"`?
- **Layout Shift (CLS):** Do dynamic images or client-fetched UI components have explicit `width` and `height` reserves?
- **Render Blocking:** Are large payloads or heavy scripts blocking the LCP (Largest Contentful Paint)?

### 3. Semantic Structure
- **Heading Hierarchy:** Is there exactly one `<h1>` per page? Do subsequent headings follow a strict sequence (`<h2>` -> `<h3>` without skipping)?
- **Semantic Tags:** Does the HTML use semantic elements (`<article>`, `<nav>`, `<aside>`, `<main>`) instead of pure `<div>` soup?
- **Alt Text:** Do all user-facing `<img>` tags have descriptive `alt` attributes?

### 4. GEO (Generative Engine Optimization) Readiness
- **AI Crawler Access:** Are `robots.txt` rules blocking helpful AI crawlers unnecessarily?
- **LLMs.txt:** Is there an `llms.txt` file or easily parsable markdown variant available for the page?
- **Answer Engine Optimization (AEO):** Does high-value content answer specific questions clearly and concisely to target Featured Snippets or People Also Ask?

### 5. Schema Markup (JSON-LD)
- **Presence:** Is JSON-LD implemented for key entities (e.g., `Article`, `Product`, `Organization`, `LocalBusiness`, `FAQPage`)?
- **Validity:** Are there missing required fields in the Schema markup? Avoid deprecated types.

## Output Contract

Report your findings using the standard `todos/` file generation method (if part of the `/review` workflow) or list them clearly.

Categorize findings strictly by impact:
- 🔴 **P1 (Critical):** Missing canonicals, broken robots.txt, missing `useSeoMeta` on core pages.
- 🟡 **P2 (Important):** Missing `alt` tags, broken heading hierarchy, layout shift risks.
- 🟢 **P3 (Consideration):** Missing advanced schema, AEO tuning opportunities.
