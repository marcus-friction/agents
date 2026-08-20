---
name: seo-review
description: |
  Comprehensive SEO, Core Web Vitals, and Semantic HTML review. Use when building
  any user-facing page, deploying new routes, or auditing search performance.
  Proactively suggest when new pages or dynamic routes are added to the project.
argument-hint: "[URL or files to review]"
disable-model-invocation: true
---

# SEO & UI Quality Review

Perform a deep technical SEO, Core Web Vitals, and structural review of the provided files or codebase.

## The Checklist

### 1. Technical SEO & Indexability
- **Metadata:** Are meta tags (`title`, `description`, `og:image`, `og:title`) correctly implemented and dynamic? _Why: Missing or duplicate metadata causes search engines to generate poor snippets, reducing click-through rates._
  - **Nuxt:** `useHead` or `useSeoMeta`
  - **Laravel Blade:** `@section('meta')` or equivalent
  - **Generic:** `<meta>` tags in `<head>`
- **Canonicals:** Does every indexable page output a `<link rel="canonical" href="...">` tag? _Why: Without canonicals, duplicate URLs (query params, trailing slashes, pagination) split ranking signals._
- **Robots Directives:** Are pagination, internal dashboards, or low-value routes correctly marked with `<meta name="robots" content="noindex, follow">`? _Why: Indexing internal pages wastes crawl budget and can expose sensitive URLs._
- **Sitemap:** If a new dynamic route was added, was the sitemap configuration updated? _Why: New pages won't be discovered by crawlers without sitemap inclusion._

### 2. Core Web Vitals & Performance
- **Image Optimization:** Are images served in modern formats (WebP/AVIF) with responsive `srcset`? _Why: Unoptimized images are the #1 cause of slow LCP (Largest Contentful Paint)._
- **Lazy Loading:** Are below-the-fold images using `loading="lazy"`? _Why: Eager-loading all images blocks initial render and wastes bandwidth._
- **Layout Shift (CLS):** Do dynamic images or client-fetched UI components have explicit `width` and `height` reserves? _Why: Missing dimensions cause layout shifts that degrade user experience and CLS score._
- **Render Blocking:** Are large payloads or heavy scripts blocking the LCP? _Why: Render-blocking resources delay the first meaningful paint, increasing bounce rates._

### 3. Semantic Structure
- **Heading Hierarchy:** Is there exactly one `<h1>` per page? Do subsequent headings follow a strict sequence (`<h2>` -> `<h3>` without skipping)? _Why: Broken hierarchy confuses screen readers and reduces content comprehension by search engines._
- **Semantic Tags:** Does the HTML use semantic elements (`<article>`, `<nav>`, `<aside>`, `<main>`) instead of pure `<div>` soup? _Why: Semantic HTML enables accessibility tools, improves machine readability, and can trigger rich results._
- **Alt Text:** Do all user-facing `<img>` tags have descriptive `alt` attributes? _Why: Missing alt text fails WCAG compliance and removes images from image search results._

### 4. GEO (Generative Engine Optimization) Readiness
- **AI Crawler Access:** Are `robots.txt` rules blocking helpful AI crawlers unnecessarily? _Why: Blocking AI crawlers prevents your content from appearing in AI-generated answers and summaries._
- **LLMs.txt:** Is there an `llms.txt` file or easily parsable markdown variant available? _Why: Structured machine-readable content improves discoverability in AI-powered search._
- **Answer Engine Optimization (AEO):** Does high-value content answer specific questions clearly and concisely to target Featured Snippets or People Also Ask? _Why: Direct answers in structured format are what search engines extract for position-zero results._

### 5. Schema Markup (JSON-LD)
- **Presence:** Is JSON-LD implemented for key entities (e.g., `Article`, `Product`, `Organization`, `LocalBusiness`, `FAQPage`)? Refer to `references/schema-templates.md` for ready-to-use templates. _Why: Schema markup enables rich results (stars, pricing, FAQs) that dramatically improve CTR._
- **Validity:** Are there missing required fields in the Schema markup? Avoid deprecated types. _Why: Invalid schema is silently ignored by search engines — you get zero benefit from broken markup._

### 6. On-Page SEO & Content Strategy
- **Keyword Targeting:** Does the page have a clear primary keyword target aligned with the Title, H1, and URL? _Why: Keyword misalignment splits ranking signals across topics._
- **Search Intent & Depth:** Does the content satisfy the user's search intent with sufficient depth? _Why: Thin content that doesn't match intent gets demoted in rankings._
- **Thin Content & Cannibalization:** Is the page competing with other pages for the same keyword? Does it provide unique value over category/tag pages? _Why: Internal cannibalization means your own pages fight each other for rankings._
- **Internal Linking:** Are there descriptive anchor texts linking to important internal pages? Are there any orphan pages? _Why: Internal links distribute PageRank and help crawlers discover deep content._

### 7. Content Quality (E-E-A-T)
- **Experience & Expertise:** Does the content demonstrate first-hand experience, original insights, or accurate/detailed information? _Why: Google's Helpful Content system favors experience-backed content over generic rewrites._
- **Authoritativeness & Trustworthiness:** Are author credentials or industry credentials visible? Is there transparent business contact info, privacy policies, etc.? _Why: Trust signals directly affect ranking for YMYL (Your Money Your Life) content._

## Output Contract

Report your findings categorized strictly by impact:
- 🔴 **P1 (Critical):** Missing canonicals, broken robots.txt, missing metadata on core pages.
- 🟡 **P2 (Important):** Missing `alt` tags, broken heading hierarchy, layout shift risks.
- 🟢 **P3 (Consideration):** Missing advanced schema, AEO tuning opportunities.

```
SEO REVIEW SUMMARY
──────────────────
Technical SEO:      PASS | FAIL — [one-line summary]
Core Web Vitals:    PASS | FAIL — [one-line summary]
Semantic Structure: PASS | FAIL — [one-line summary]
GEO/AEO:           PASS | FAIL | N/A — [one-line summary]
Schema Markup:      PASS | FAIL | MISSING — [one-line summary]
On-Page SEO:        PASS | FAIL — [one-line summary]
E-E-A-T:            PASS | FAIL — [one-line summary]

P1 Findings: [count]
P2 Findings: [count]
P3 Findings: [count]
```

## References
- [Schema Templates](references/schema-templates.md): Ready-to-use JSON-LD boilerplate for Article, Product, Organization, LocalBusiness, FAQPage, BreadcrumbList, and WebSite
- [Core Web Vitals Thresholds](references/cwv-thresholds.md): Target thresholds, metric definitions (LCP, INP, CLS, TTFB), and optimization triggers
- [E-E-A-T Quality Framework](references/eeat-framework.md): Experience, Expertise, Authoritativeness, and Trustworthiness evaluation rubrics
