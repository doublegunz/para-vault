<!-- Ebook addendum for Chapter 6. Appended after the lesson body at build time. -->

## Key Takeaways {#key-takeaways}

- **Eloquent** maps tables to model classes, rows to objects, and columns to properties, replacing raw SQL with expressive PHP.
- Laravel 13 declares mass-assignable columns with the `#[Fillable([...])]` attribute. **Mass assignment protection** stops users from setting columns like `user_id` they should not control.
- `belongsTo` on `Entry` and `hasMany` on `User` define the relationship in both directions. You set `user_id` safely through the relationship, never from form input.
- `Entry::with('user')->latest()->get()` fetches entries newest-first; `with('user')` eager loads to avoid the **N+1 problem**.
- Eloquent objects use arrow notation (`$entry->title`); timestamps become **Carbon** objects with helpers like `format('d F Y')`.
- `@forelse ... @empty ... @endforelse` handles empty collections cleanly. **Tinker** lets you query and seed data from the terminal.

## Checkpoint {#checkpoint}

Before moving on, confirm:

- `app/Models/Entry.php` has `#[Fillable(['title', 'content'])]` and a `user()` relationship; `User` has an `entries()` relationship.
- The controller's `index()` uses an Eloquent query, not a hardcoded array.
- After seeding data through Tinker, `/entries` shows real entries from the database, and an empty database shows the "No entries yet" state.

## Exercises {#exercises}

1. In Tinker, fetch the most recent entry and print its owner's name in a single expression.
2. Add `mood` to the `Entry` model's fillable list, then create one entry with a mood value through the user's relationship in Tinker.
3. Write the Eloquent expression that counts how many entries the user with id 1 has.

Solutions are in the **Exercise Solutions** section at the back.
