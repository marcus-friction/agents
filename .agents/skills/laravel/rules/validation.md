# Validation & Forms Best Practices

## Choose the Validation Boundary Proportionally

Use a dedicated Form Request when a meaningful or complex untrusted payload,
reused rules, request authorization, or the project's established convention
earns a named boundary. A small, one-off framework-supported input may be
validated inline when the transport remains clear and testable.

| Case | Evidence | Default boundary |
|---|---|---|
| `trivial-local` | One small input, no reused rules, no request authorization, and no established Form Request convention | Inline validation at the current Laravel transport boundary is acceptable. |
| `substantial-or-shared` | Meaningful or complex payload, reused rules, request authorization, or an established Form Request convention | Use a dedicated Form Request and consume its validated data. |

For a substantial payload, avoid leaving the full rule set in the controller:
```php
public function store(Request $request)
{
    $request->validate([
        'title' => 'required|max:255',
        'body' => 'required',
    ]);
}
```

Use a Form Request instead:
```php
public function store(StorePostRequest $request)
{
    Post::create($request->validated());
}
```

## Array vs. String Notation for Rules

Array syntax is more readable and composes cleanly with `Rule::` objects. Prefer it in new code, but check existing Form Requests first and match whatever notation the project already uses.

```php
// Preferred for new code
'email' => ['required', 'email', Rule::unique('users')],

// Follow existing convention if the project uses string notation
'email' => 'required|email|unique:users',
```

## Use Only Validated Data

Get only validated data. Never use `$request->all()` for mass operations. With
a Form Request, use `validated()` or `safe()`; inline validation should use the
array returned by `$request->validate()`.

Incorrect:
```php
Post::create($request->all());
```

Correct:
```php
Post::create($request->validated());
```

For a trivial local input:

```php
public function index(Request $request)
{
    $validated = $request->validate([
        'direction' => ['sometimes', Rule::in(['asc', 'desc'])],
    ]);

    return Post::query()
        ->orderBy('created_at', $validated['direction'] ?? 'desc')
        ->paginate();
}
```

## Use `Rule::when()` for Conditional Validation

```php
'company_name' => [
    Rule::when($this->account_type === 'business', ['required', 'string', 'max:255']),
],
```

## Use the `after()` Method for Custom Validation

Use `after()` instead of `withValidator()` for custom validation logic that depends on multiple fields.

```php
public function after(): array
{
    return [
        function (Validator $validator) {
            if ($this->quantity > Product::find($this->product_id)?->stock) {
                $validator->errors()->add('quantity', 'Not enough stock.');
            }
        },
    ];
}
```
