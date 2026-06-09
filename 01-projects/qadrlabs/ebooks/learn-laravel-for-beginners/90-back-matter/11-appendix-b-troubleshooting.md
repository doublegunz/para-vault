# Appendix B: Troubleshooting Common Errors

Every programmer meets errors, and beginners meet them constantly. That is not a sign you are doing something wrong. It is the normal texture of building software. This appendix collects the problems that come up most often while building Catatku, with the cause and the fix for each. When something breaks, read the error message first, then find the matching entry here.

## Setup and Environment {#setup-and-environment}

These problems show up in Chapter 2 while getting the tools working.

**`php` is not recognized as a command.** Your terminal cannot find PHP because it is not on the system PATH. In Laragon, use Menu > Tools > Path > Add Laragon to Path, then open a fresh terminal. Outside Laragon, make sure PHP's folder is added to your operating system's PATH.

**Laravel says it requires PHP 8.3 but you have an older version.** Laravel 13 needs PHP 8.3 or higher. Follow the upgrade steps in Chapter 2 to download a PHP 8.3 build and select it in Laragon, then confirm with `php -v`.

**`composer create-project` fails partway through.** This is almost always a network interruption. Delete the half-created `catatku` folder and run the command again on a stable connection.

## Database and Migrations {#database-and-migrations}

These appear in Chapters 5 and 6 when connecting to the database.

**`SQLSTATE[HY000] [1045] Access denied for user`.** Your database username or password in `.env` is wrong. With Laragon's defaults, `DB_USERNAME=root` and `DB_PASSWORD=` is left blank. After editing `.env`, run `php artisan config:clear` so the new values are read.

**`SQLSTATE[HY000] [2002] Connection refused`.** MySQL is not running. In Laragon, click Start All and wait for the services to come up, then try the migration again.

**`The database 'db_catatku' does not exist`.** This is expected the first time. When you run `php artisan migrate`, Laravel asks whether to create the database. Choose Yes.

**You changed a migration but the columns did not update.** Editing a migration file does not change a table that already ran. In development, run `php artisan migrate:rollback` then `php artisan migrate` again, or `php artisan migrate:fresh` to rebuild everything from scratch. Never do this against production data.

**`Column not found` after adding a column.** You added a column to the migration but did not re-run it. Roll back and migrate again so the new column actually exists in the table.

## Routes and Views {#routes-and-views}

These appear from Chapter 3 onward.

**`404 Not Found` when the route clearly exists.** Two common causes. First, route order: a static route like `/entries/create` must be declared before the dynamic `/entries/{entry}`, or Laravel treats "create" as an entry id. Second, run `php artisan route:list` to confirm the route is registered the way you expect.

**`View [home] not found`.** Laravel cannot find the Blade file. Check the path and spelling: `view('home')` looks for `resources/views/home.blade.php`, and `view('entries.index')` looks for `resources/views/entries/index.blade.php`. The dot maps to a folder.

**Your Blade changes do not show up.** Compiled views can be stale. Run `php artisan view:clear` and reload.

## Forms, Validation, and CSRF {#forms-validation-csrf}

These appear in Chapters 8 through 11.

**`419 Page Expired` when submitting a form.** The form is missing its CSRF token. Add `@csrf` inside every POST form. If it is already there, your session may have expired; reload the page to get a fresh token.

**A PUT or DELETE form submits as if nothing happened, or hits the wrong method.** HTML forms only support GET and POST. For update and delete, the form must use `method="POST"` and include `@method('PUT')` or `@method('DELETE')` so Laravel spoofs the real method.

**Validation always fails or the error messages never appear.** Make sure the form field `name` attributes exactly match the keys in your validation rules. For the `confirmed` rule on `password`, the second field must be named exactly `password_confirmation`.

**Typed input disappears after a validation error.** Add `old('field')` to your inputs (in the `value` attribute for text inputs, between the tags for a textarea). For edit forms, use the two-argument form `old('field', $entry->field)`. Never use `old()` on password fields.

## Authentication and Authorization {#authentication-authorization}

These appear in Chapters 7 through 11.

**`403 Forbidden` when reading your own entry.** Before authentication exists (Chapters 7 to 9), `auth()->id()` is `null`, so the ownership check `if ($entry->user_id !== auth()->id())` blocks everyone. Use the temporary `/dev-login` route from Chapter 8 to log in as the test user while developing. Once real auth is in place (Chapter 11), this resolves on its own.

**Guests hitting a protected route get an error instead of the login page.** Laravel's `auth` middleware redirects unauthenticated users to a route named `login`. Make sure your login route has `->name('login')`, as shown in Chapter 11.

**`Call to a member function entries() on null`.** You called `auth()->user()->entries()` on a route where no one is logged in. Either the route is missing the `auth` middleware, or you are testing it as a guest. Confirm the route sits inside the `middleware('auth')` group.

**A logged-in user can still open the register or login page.** Wrap those routes in `middleware('guest')` so authenticated users are redirected away, as shown in Chapters 10 and 11.

## When None of These Match {#when-none-match}

If your error is not listed here, do not panic. Copy the exact error message and the first few lines of the stack trace, and search for them. Laravel's messages are specific, and someone has almost certainly hit the same thing before. **Appendix C: Glossary** can help if a term in the message is unfamiliar, and the official documentation at `laravel.com/docs` is now much easier to read because you have built a real app.
