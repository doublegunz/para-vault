# Appendix A: Artisan Command Cheat Sheet

Artisan is Laravel's command-line tool, and you used it in almost every chapter. This appendix collects every command that appears in the book in one place, so you can find the right one quickly without searching back through chapters. Each command is shown with a short description and the chapter where it was introduced.

## Project and Server {#project-and-server}

These are the commands for creating a project and running it locally.

| Command | What it does | Chapter |
|---------|--------------|---------|
| `composer create-project --prefer-dist laravel/laravel catatku` | Create a new Laravel project | 2 |
| `php artisan serve` | Start the local development server | 2 |
| `php artisan serve --port=8080` | Start the server on a custom port | 2 |
| `php artisan --version` | Show the installed Laravel version | 2 |
| `php -v` | Show the installed PHP version | 2 |

## Generating Files {#generating-files}

The `make:` commands generate boilerplate files with the correct structure and naming already in place.

| Command | What it does | Chapter |
|---------|--------------|---------|
| `php artisan make:controller EntryController` | Create a controller | 4 |
| `php artisan make:model Entry -m` | Create a model and a migration together | 5 |
| `php artisan make:migration create_entries_table` | Create a migration on its own | 5 |
| `php artisan make:controller AuthController` | Create the auth controller | 10 |

## Database and Migrations {#database-and-migrations}

These commands manage your database schema. Remember that rollback and fresh are safe in development but dangerous in production.

| Command | What it does | Chapter |
|---------|--------------|---------|
| `php artisan migrate` | Run all pending migrations | 5 |
| `php artisan migrate:rollback` | Undo the most recent batch of migrations | 5 |
| `php artisan migrate:fresh` | Drop all tables and re-run migrations (development only) | - |

## Inspecting and Debugging {#inspecting-and-debugging}

These commands help you see what Laravel knows about your application.

| Command | What it does | Chapter |
|---------|--------------|---------|
| `php artisan route:list` | List every registered route | 4 |
| `php artisan route:list --except-vendor` | List only your application's routes | 4 |
| `php artisan tinker` | Open the interactive REPL to query models | 5, 6 |

Inside Tinker, two snippets came up repeatedly:

```php
Schema::getColumnListing('entries');   // list a table's columns (Chapter 5)
$user = \App\Models\User::create([...]); // create a record (Chapter 6)
```

## Clearing Caches {#clearing-caches}

When a change does not seem to take effect, a stale cache is often the cause. These commands clear them.

| Command | What it does | Chapter |
|---------|--------------|---------|
| `php artisan config:clear` | Clear cached configuration after editing `.env` | 5 |
| `php artisan view:clear` | Clear compiled Blade views | 3 |

> Production-focused Artisan commands (such as `key:generate`, `config:cache`, and deploying with `migrate --force`) are covered in the follow-up course, **Learn Laravel: Beyond the Basics**. See the "Continue Learning" guide at the back of the book.

## A Note on Memorizing {#a-note-on-memorizing}

You do not need to memorize this table. The two commands you will type most often are `php artisan serve` and `php artisan route:list`. Everything else you can look up here when you need it. Over time, the ones you use will stick on their own.
