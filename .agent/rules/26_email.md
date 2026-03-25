---
trigger: model_decision
description: Apply when writing, reviewing, or modifying email templates, notifications, or transactional email code.
---

# Email Standards

## Template Engine
- **MJML only.** All email templates use MJML compiled via `spatie/mjml-php`. No raw HTML email templates.
- **File extension:** `.mjml.blade.php` — Blade handles dynamic content, MJML handles responsive structure.
- **Location:** `resources/views/emails/`.

## Architecture (Two-Layer)

### Base Layout (`emails/base.mjml.blade.php`)
Single shared layout that owns all brand chrome. Every email `@extends('emails.base')`.
- **Header:** Project logo as a hosted PNG (not inline SVG — email client support is unreliable). Fixed width (e.g. 150px), retina-ready (`@2x`), with `alt` text set to the project name. Link to project homepage.
- **Typography:** Map fonts from `23_design_system.md`. Use web-safe fallback stack (MJML `mj-attributes`).
- **Colors:** Pull brand palette from `23_design_system.md`. Define once in `mj-attributes`, never inline per-notification.
- **Footer:** Company name, address, unsubscribe link (`{{ $unsubscribeUrl }}`), and legal line. Always present.
- **No notification builds its own shell.** If a new notification doesn't fit the base layout, extend the base — don't bypass it.

### Content Partials (`emails/_*.mjml.blade.php`)
Reusable MJML sections for common patterns. Use `@include` — never copy-paste structure.

| Partial | Purpose |
|---|---|
| `_action` | CTA button (accepts `$url`, `$label`, optional `$variant`) |
| `_heading` | Section heading (accepts `$text`) |
| `_info-row` | Key-value data row (accepts `$label`, `$value`) |
| `_divider` | Branded horizontal rule |

Add new partials when a pattern repeats across 2+ notifications.

### Notification Templates (`emails/{domain}/{name}.mjml.blade.php`)
- Grouped by domain (`auth/`, `billing/`, `account/`).
- Only define the unique `@section('content')` body — all chrome comes from base + partials.

## Logo Usage
- **Format:** PNG with transparent background. Never SVG (inconsistent email client rendering). Never JPEG (no transparency).
- **Hosting:** Serve from the app's public URL or CDN — never Base64-embed (bloats payload, triggers spam filters).
- **Sizing:** Set explicit `width` on `<mj-image>` (e.g. `width="150px"`). Let height auto-scale. Provide `@2x` source for retina.
- **Alt text:** Always set to the project name. This is the fallback when images are blocked (most Outlook configs).
- **Dark mode:** If the logo is dark-on-transparent, provide a light variant or add a white background container.
- **One logo per email.** Header only. No repeated logos in footer or body.

## Sending Pattern
- **Notifications only.** Use `app/Notifications/` implementing `ShouldQueue`. No raw Mailables (see `21_standards_laravel.md`).
- **Compile at queue time.** MJML → HTML conversion happens before the job hits the queue, not inside the queue worker. This keeps the worker free of Node.js dependency.

## Testing
- **Pest:** Fake notifications (`Notification::fake()`) to assert delivery + recipients. Don't test rendered HTML in unit tests.
- **Visual QA:** Use Mailpit (Sail default) to preview compiled emails. Check mobile rendering manually.
- **Spam score:** Run final templates through a spam checker (e.g. mail-tester.com) before production launch.

## Accessibility
- **Alt text:** Every `<mj-image>` must have descriptive `alt`. Decorative images use `alt=""`.
- **Contrast:** Text/background pairings must meet WCAG AA (4.5:1 for body text, 3:1 for large text). Inherit from `23_design_system.md` palette.
- **Link clarity:** CTA buttons must have descriptive labels ("Sign In", "View Order") — never "Click here".
- **Preheader:** Set a meaningful preheader (`mj-preview`) for every transactional email — it's the second line recipients see in their inbox.
