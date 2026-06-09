<!-- Ebook addendum for Chapter 5. Appended after the lesson body at build time. -->

## Key Takeaways {#key-takeaways}

- The `.env` file holds your database connection details. Update it to point Catatku at MySQL.
- **Migrations** are PHP files that define schema changes. They are tracked in Git, run with `php artisan migrate`, and undone with `php artisan migrate:rollback`.
- `php artisan make:model Entry -m` creates a model and a migration together. Laravel maps the singular model `Entry` to the plural table `entries`.
- `up()` defines what the migration creates; `down()` undoes it.
- `foreignId('user_id')->constrained()->cascadeOnDelete()` creates a foreign key to `users` and deletes a user's entries when the user is deleted. `string()` is short text, `text()` is long text, `timestamps()` adds `created_at` and `updated_at`.
- Rolling back is safe in development but dangerous in production.

## Checkpoint {#checkpoint}

Before moving on, confirm:

- `.env` is configured for MySQL and `php artisan config:clear` has been run if you edited it.
- `php artisan migrate` completed and created the database when prompted.
- In Tinker, `Schema::getColumnListing('entries')` returns `id`, `user_id`, `title`, `content`, `created_at`, `updated_at`.

## Exercises {#exercises}

1. Add a nullable `mood` string column to the `entries` migration. Roll back, then migrate again, and confirm the column exists with `Schema::getColumnListing('entries')` in Tinker.
2. Without running it, write the single Artisan command that would undo the most recent migration.
3. Add a second nullable column, `published_at`, of a timestamp type to the same migration, then re-run the migration.

Solutions are in the **Exercise Solutions** section at the back.
