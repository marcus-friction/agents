# JSON-LD Schema Templates

Ready-to-use JSON-LD templates for the most common entity types. Copy, adapt, and inject into `<script type="application/ld+json">` tags.

---

## Article

For blog posts, news articles, guides, and documentation pages.

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Your Article Title (max 110 chars)",
  "description": "A concise summary of the article content",
  "image": "https://example.com/images/article-hero.jpg",
  "author": {
    "@type": "Person",
    "name": "Author Name",
    "url": "https://example.com/about/author-name"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Company Name",
    "logo": {
      "@type": "ImageObject",
      "url": "https://example.com/logo.png"
    }
  },
  "datePublished": "2026-01-15T08:00:00+00:00",
  "dateModified": "2026-01-20T10:30:00+00:00",
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "https://example.com/blog/article-slug"
  }
}
```

**Required fields:** `headline`, `author`, `datePublished`, `image`
**Enables:** Article rich results, author knowledge panels

---

## Product

For e-commerce product pages, SaaS pricing, and product listings.

```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "Product Name",
  "description": "Brief product description",
  "image": [
    "https://example.com/images/product-1.jpg",
    "https://example.com/images/product-2.jpg"
  ],
  "brand": {
    "@type": "Brand",
    "name": "Brand Name"
  },
  "sku": "SKU-12345",
  "offers": {
    "@type": "Offer",
    "url": "https://example.com/products/product-slug",
    "priceCurrency": "EUR",
    "price": "49.99",
    "availability": "https://schema.org/InStock",
    "priceValidUntil": "2026-12-31"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.5",
    "reviewCount": "127"
  }
}
```

**Required fields:** `name`, `image`, `offers` (with `price` + `priceCurrency`)
**Enables:** Product rich results with pricing, availability, ratings

---

## Organization

For homepage and about pages. Establishes the business entity in Google's Knowledge Graph.

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Company Name",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png",
  "description": "Brief company description",
  "sameAs": [
    "https://twitter.com/company",
    "https://linkedin.com/company/company",
    "https://github.com/company"
  ],
  "contactPoint": {
    "@type": "ContactPoint",
    "email": "hello@example.com",
    "contactType": "customer service"
  }
}
```

**Required fields:** `name`, `url`
**Enables:** Knowledge panel, logo in search results, social profile links

---

## LocalBusiness

For businesses with a physical location. Extends Organization.

```json
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "Business Name",
  "url": "https://example.com",
  "image": "https://example.com/storefront.jpg",
  "telephone": "+31-20-1234567",
  "email": "info@example.com",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "123 Main Street",
    "addressLocality": "Amsterdam",
    "postalCode": "1012 AB",
    "addressCountry": "NL"
  },
  "geo": {
    "@type": "GeoCoordinates",
    "latitude": "52.3676",
    "longitude": "4.9041"
  },
  "openingHoursSpecification": [
    {
      "@type": "OpeningHoursSpecification",
      "dayOfWeek": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      "opens": "09:00",
      "closes": "17:00"
    }
  ]
}
```

**Required fields:** `name`, `address`
**Enables:** Local pack results, Google Maps integration, business info panel

---

## FAQPage

For FAQ sections, knowledge bases, and help pages. High-value for featured snippets.

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What is your return policy?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "We offer a 30-day no-questions-asked return policy on all products."
      }
    },
    {
      "@type": "Question",
      "name": "How long does shipping take?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Standard shipping takes 3-5 business days within the EU."
      }
    }
  ]
}
```

**Required fields:** `mainEntity` with at least one `Question`/`Answer` pair
**Enables:** FAQ rich results (expandable Q&A directly in search results)

---

## BreadcrumbList

For any page with breadcrumb navigation. Improves how URLs display in search results.

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    {
      "@type": "ListItem",
      "position": 1,
      "name": "Home",
      "item": "https://example.com"
    },
    {
      "@type": "ListItem",
      "position": 2,
      "name": "Category",
      "item": "https://example.com/category"
    },
    {
      "@type": "ListItem",
      "position": 3,
      "name": "Current Page"
    }
  ]
}
```

**Required fields:** `itemListElement` with `position` and `name`
**Enables:** Breadcrumb trail in search results instead of raw URL

---

## WebSite (with SearchAction)

For the homepage. Enables sitelinks searchbox in Google.

```json
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Site Name",
  "url": "https://example.com",
  "potentialAction": {
    "@type": "SearchAction",
    "target": {
      "@type": "EntryPoint",
      "urlTemplate": "https://example.com/search?q={search_term_string}"
    },
    "query-input": "required name=search_term_string"
  }
}
```

**Required fields:** `name`, `url`
**Enables:** Sitelinks searchbox (search directly from Google results)

---

## Implementation Notes

- **One script tag per schema type.** Don't nest multiple schemas in one tag.
- **Place in `<head>`.** JSON-LD can go anywhere in the HTML, but `<head>` is conventional and ensures early parsing.
- **Validate with Google's Rich Results Test:** https://search.google.com/test/rich-results
- **Nuxt:** Use `useHead()` with `script: [{ type: 'application/ld+json', innerHTML: JSON.stringify(schema) }]`
- **Laravel Blade:** Use `@push('schema')` / `@stack('schema')` pattern in layout.
