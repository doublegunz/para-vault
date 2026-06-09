<!-- Ebook addendum for Chapter 8. Appended after the lesson body at build time. -->

## Key Takeaways {#key-takeaways}

- Forms use a **two-route pattern**: GET to show the form, POST to process it.
- `$request->validate([...])` checks input. On failure it redirects back with errors and old input; on success it returns a clean validated array. Common rules: `required`, `string`, `max:255`.
- `@csrf` is mandatory on every POST form; without it Laravel returns a 419. `old('field')` preserves typed input; `@error ... @enderror` shows field errors.
- `$request->user()->entries()->create($validated)` saves through the relationship, setting `user_id` from the session, never from input.
- `redirect()->with('success', '...')` sends a one-time flash message. `Route::middleware('auth')->group(...)` protects routes. **Route order matters**: `/entries/create` must come before `/entries/{entry}`.

## Checkpoint {#checkpoint}

Before moving on, confirm:

- `create()` and `store()` methods exist, and the create/store routes sit inside the `auth` group.
- After logging in via `/dev-login`, the create form at `/entries/create` works.
- Submitting empty fields shows validation errors with input preserved; submitting valid data saves the entry and shows a green success message on the listing.

## Exercises {#exercises}

1. Add a `min:3` rule to the `title` field and confirm the error message appears when you submit a two-character title.
2. Below the content textarea, show a small hint with a character or word count of the current `old('content')` value.
3. Give the `title` field a custom validation message (for example, "Please give your entry a title.") using the array form of validation rules.

Solutions are in the **Exercise Solutions** section at the back.
