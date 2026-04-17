---
name: architecture-review
description: Architecture compliance checklist for code review
---

# Architecture Review Skill

Verify changes comply with the project's architectural patterns. Use during the architecture pass of `/review`.

## Checklist

### Layer Separation

- [ ] **Controllers are thin**: No business logic — delegate to Actions
- [ ] **Actions are single-purpose**: One public `__invoke()` method per Action class
- [ ] **Models are clean**: No business logic in models — only relationships, scopes, casts, accessors
- [ ] **Services wrap externals**: Third-party SDKs wrapped in Service classes, never called directly from controllers/actions
- [ ] **No cross-layer leaking**: Controllers don't import Models directly (use Actions); Actions don't import Request objects

### API Design

- [ ] **Versioned routes**: New endpoints in `routes/api/v1.php`
- [ ] **API Resources**: All responses go through Resource classes — no raw model serialization
- [ ] **Consistent naming**: RESTful resource naming (`/api/v1/orders`, not `/api/v1/getOrders`)
- [ ] **Form Requests**: Validation in dedicated Request classes, not inline in controllers
- [ ] **No breaking changes**: Existing API contracts preserved — additive changes only

### Frontend Architecture

- [ ] **Components follow hierarchy**: `base/` for primitives, feature components grouped by domain
- [ ] **Composables for shared logic**: Reusable logic in `composables/`, not duplicated across components
- [ ] **Stores for global state**: Pinia stores for cross-component state, `useState` for SSR-safe reactive state
- [ ] **Server proxy**: API calls go through `server/api/` routes — no direct backend URLs in client code
- [ ] **Types in `shared/`**: Shared types live in `shared/types/` — accessible to both client and server

### Design System

- [ ] **Tokens used**: Colors, spacing, typography from design tokens — no hardcoded values
- [ ] **Base components**: `BaseButton`, `BaseInput`, etc. used — no raw HTML for common patterns
- [ ] **Responsive**: Layouts use Tailwind responsive utilities — no fixed widths

### Dependency Direction

```
Controllers → Actions → Models
     ↓            ↓
  Requests    Services (external)
     ↓
  Resources (output)
```

- [ ] Dependencies flow downward — never upward or circular
- [ ] No new dependency added without explicit approval
- [ ] Package usage aligns with stack choices in `20_stack.md`

### File Organization

- [ ] New files follow existing directory structure (see `20_stack.md` layouts)
- [ ] Test files mirror source structure in `tests/Feature/` and `tests/Unit/`
- [ ] No orphan files — everything belongs to a clear module or domain area
