<!-- Ebook addendum for Chapter 4. Appended after the lesson body at build time. -->

## Key Takeaways {#key-takeaways}

- **MVC** splits an app into Model (data), View (presentation), and Controller (flow control). Each part has one responsibility.
- `php artisan make:controller EntryController` generates a controller in `app/Http/Controllers/`.
- Controller methods like `index()` hold the logic that used to live in route closures. `index` is the Laravel convention for "list resources."
- Routes point to controllers with `[ControllerClass::class, 'methodName']`, keeping `routes/web.php` a clean map.
- `php artisan route:list` verifies that routes are wired correctly. The refactor changes nothing the user sees; the gain is entirely in organization.

## Checkpoint {#checkpoint}

Before moving on, confirm:

- `routes/web.php` contains only URL mappings, with no business logic.
- `php artisan route:list` shows the `/entries` route handled by `EntryController@index`.
- `/entries` looks exactly the same in the browser as it did before the refactor.

## Exercises {#exercises}

1. Generate a new `PageController` and move the `/about` route from the previous chapter's exercise to point at a `PageController@about` method.
2. Run `php artisan route:list` and confirm `/about` is now bound to your controller, not a closure.
3. In one or two sentences, explain why the view did not need to change when you moved the logic into a controller.

Solutions are in the **Exercise Solutions** section at the back.
