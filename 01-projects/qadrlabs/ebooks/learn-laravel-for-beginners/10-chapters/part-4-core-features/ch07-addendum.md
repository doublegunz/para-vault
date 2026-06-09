<!-- Ebook addendum for Chapter 7. Appended after the lesson body at build time. -->

## Key Takeaways {#key-takeaways}

- **Blade components** extract reusable HTML. Any file in `resources/views/components/` becomes a component; `layout.blade.php` becomes `<x-layout>`.
- `{{ $slot }}` is the placeholder where a component's wrapped content is inserted. `@props(['entry'])` declares props, passed with `:entry="$entry"` (the colon means "evaluate as PHP").
- **Route Model Binding** turns `Entry $entry` into the model whose id is in the URL, returning a 404 automatically if it does not exist.
- `abort(403)` blocks access; the ownership check ensures only the owner can view an entry.
- `@method('DELETE')` lets a POST form act as DELETE. Carbon helpers (`isoFormat`, `diffForHumans`, `ne`) and `whitespace-pre-line` handle dates and line breaks.

## Checkpoint {#checkpoint}

Before moving on, confirm:

- A shared `<x-layout>` and an `<x-entry-card>` component exist and are used by the listing view.
- The listing page renders through the layout with a sticky nav and entry cards.
- A `show()` method and `/entries/{entry}` route exist; visiting an entry detail works once you are logged in (via `/dev-login` from the next chapter), and a 403 appears otherwise.

## Exercises {#exercises}

1. Add a simple footer to the layout component (for example, a copyright line) so it appears on every page automatically.
2. Extract the "No entries yet" empty state into its own `<x-empty-state>` component and use it in the listing view.
3. On the detail page, display an estimated reading time (assume 200 words per minute) using `str_word_count($entry->content)`.

Solutions are in the **Exercise Solutions** section at the back.
