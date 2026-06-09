<!-- Ebook addendum for Chapter 9. Appended after the lesson body at build time. -->

## Key Takeaways {#key-takeaways}

- HTML forms support only GET and POST. **Method spoofing** with `@method('PUT')` and `@method('DELETE')` lets a POST act as PUT or DELETE to match RESTful conventions.
- The **edit form** mirrors the create form, plus `@method('PUT')` and `old('field', $entry->field)` to pre-fill current values while still preserving input after a failed validation.
- `$entry->update($validated)` updates a record (and `updated_at`); `$entry->delete()` removes it permanently.
- Every method that touches a specific entry needs an **`abort(403)` ownership check**.
- The full resource is seven routes and seven methods (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`), verifiable with `php artisan route:list`.

## Checkpoint {#checkpoint}

Before moving on, confirm:

- `edit()`, `update()`, and `destroy()` methods exist, each with an ownership check.
- `php artisan route:list` shows all seven entry routes.
- You can edit an entry (redirects to its detail with a success message) and delete one (redirects to the listing), and a second user gets a 403 on another user's entry.

## Exercises {#exercises}

1. Change the `update()` method so it redirects to the entries listing instead of the entry's detail page, and confirm the success message still shows.
2. On the detail page, show an "edited" note only when an entry's `updated_at` differs from its `created_at`.
3. Without writing code, fill in the RESTful table from memory: for "show edit form" and "save changes", what are the HTTP method, URL, and controller method for each?

Solutions are in the **Exercise Solutions** section at the back.
