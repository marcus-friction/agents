---
name: test-driven-development
description: TDD workflow — write failing tests first, then implement, then refactor
---

# Test-Driven Development Skill

Red → Green → Refactor workflow for writing tests before implementation. Use when building new features, fixing bugs, or when the user explicitly requests TDD. Complements `41_workflow_testing.md` which covers test *standards*; this skill covers the *process*.

## When to Use

- Building a new feature with clear acceptance criteria
- Fixing a bug (write a test that reproduces it first)
- Refactoring code that lacks tests (add characterization tests first)
- When the user says "TDD", "test first", or "write tests before code"

## The Cycle

### 🔴 Red — Write a Failing Test

1. **Start from the requirement**, not the implementation. What should the code *do*?
2. **Write the simplest test** that captures one aspect of the requirement:
   ```php
   it('calculates order total including tax', function () {
       $order = Order::factory()->create(['subtotal' => 10000]);
       $total = (new CalculateOrderTotal)($order);
       expect($total)->toBe(10800); // 8% tax
   });
   ```
3. **Run it.** It must fail. If it passes, either the test is wrong or the feature already exists.
4. **Verify it fails for the right reason** — a missing class/method, not a syntax error.

### 🟢 Green — Make It Pass

1. **Write the minimum code** to make the test pass. No more.
2. **Don't optimize.** Don't handle edge cases yet. Just pass the test.
3. **Run all tests** — the new one should pass, existing ones should still pass.

### 🔵 Refactor — Clean Up

1. **Improve the implementation** — remove duplication, clarify naming, extract methods.
2. **Don't change behavior** — tests must still pass after refactoring.
3. **Improve the test** — is it readable? Does the name describe the behavior?
4. **Run all tests again.**

Then start the next cycle with the next requirement slice.

## Practical Guidelines

### Slice Requirements Thin

Break features into the smallest testable behaviors:

| ❌ Too broad | ✅ Thin slices |
|---|---|
| "Order processing works" | "Calculates subtotal from line items" |
| | "Applies percentage discount" |
| | "Adds tax to discounted total" |
| | "Rejects orders with zero items" |

### Test Naming

Tests should read as specifications:

```php
// Backend (Pest)
it('rejects orders without a shipping address')
it('applies the highest applicable discount')
it('sends confirmation email after payment succeeds')

// Frontend (Vitest)
it('disables submit button while form is submitting')
it('shows validation errors below each invalid field')
it('redirects to dashboard after successful login')
```

### Bug Fix TDD

For bugs, the cycle is slightly different:

1. **Write a test that reproduces the bug** — it should fail (proving the bug exists).
2. **Fix the bug** — the test should now pass.
3. **Keep the test** — it's now a regression guard.

### When to Skip TDD

TDD isn't always the best approach:

- **Exploratory/prototype work** — when you're still figuring out the design
- **UI layout** — visual changes are better verified visually
- **One-off scripts** — throwaway code that won't be maintained
- **External API integration** — mock-heavy tests often provide false confidence

In these cases, write tests *after* but still write them.

## Rules

- Never skip 🔴 Red — if you write implementation before the test, you're not doing TDD.
- Each cycle should be **minutes**, not hours. If it's taking too long, the slice is too big.
- Commit after each Green → Refactor cycle — small, well-tested commits.
- Follow the test naming and structure conventions in `41_workflow_testing.md`.
