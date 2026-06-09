<!-- Ebook addendum for Chapter 2. Appended after the lesson body at build time. -->

## Key Takeaways {#key-takeaways}

- **VS Code** is your editor; **Laragon** bundles a web server, MySQL, PHP, Node.js, and Composer in one installer.
- Laravel 13 requires **PHP 8.3 or higher**. Upgrade PHP in Laragon and confirm with `php -v` before creating the project.
- `composer create-project --prefer-dist laravel/laravel catatku` scaffolds the whole project. Fresh Laravel 13 may set up SQLite by default; Catatku will switch to MySQL in Chapter 5.
- `php artisan serve` starts the dev server. The folder structure is consistent: `Controllers/` for logic, `Models/` for data, `migrations/` for schema, `views/` for templates, `web.php` for routes.
- The `.env` file holds secrets and is never committed to Git.

## Checkpoint {#checkpoint}

Before moving on, confirm:

- `php -v` reports PHP 8.3 or higher.
- `composer` runs and shows its help output.
- A `catatku` project exists and opens in VS Code.
- `php artisan serve` runs and the Laravel welcome page loads at `http://127.0.0.1:8000`.

## Exercises {#exercises}

1. Run `php artisan --version` and write down the exact Laravel version your project installed.
2. Stop the server, then start it again on port 8080 instead of the default. (Hint: there is a flag for this.) Confirm the app loads at the new address.
3. Run `php artisan route:list` on the fresh project and count how many routes Laravel created before you wrote any code.

Solutions are in the **Exercise Solutions** section at the back.
