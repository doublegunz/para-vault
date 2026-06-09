<!-- Ebook addendum for Chapter 3. Appended after the lesson body at build time. -->

## Key Takeaways {#key-takeaways}

- A **route** maps a URL to the code that runs for it. All web routes live in `routes/web.php`.
- `Route::get('/path', function () { ... })` responds to GET requests at that path.
- A **view** is a Blade file in `resources/views/` that turns data into HTML. Dot notation maps names to folders: `'entries.index'` is `resources/views/entries/index.blade.php`.
- `compact('entries')` passes data from a route to a view; `{{ $variable }}` displays it with automatic XSS protection; `@foreach` loops; `{{-- --}}` comments are stripped from output.
- The data-flow pattern (route prepares data, view renders it) stays the same all book long. Only the data source changes.

## Checkpoint {#checkpoint}

Before moving on, confirm:

- `http://127.0.0.1:8000` shows your custom Catatku home page, not Laravel's welcome page.
- `http://127.0.0.1:8000/entries` lists three dummy entries with titles, dates, and snippets.
- You can explain what `compact('entries')` does and why `{{ }}` is safer than raw `echo`.

## Exercises {#exercises}

1. Add a new route `/about` that returns a new `about.blade.php` view containing a short paragraph about Catatku.
2. Add a fourth entry to the dummy `$entries` array and confirm it appears in the browser.
3. Above the list, display the total number of entries (for example, "You have 4 entries") using the `$entries` array.

Solutions are in the **Exercise Solutions** section at the back.
