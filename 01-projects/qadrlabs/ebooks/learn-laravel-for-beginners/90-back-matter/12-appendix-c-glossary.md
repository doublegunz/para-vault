# Appendix C: Glossary

This glossary defines the key terms used throughout the book in plain language. The definitions are written for someone meeting these words for the first time, in the context of how Catatku uses them. They are listed alphabetically.

**Artisan.** Laravel's command-line tool. You use it to create files, run migrations, start the development server, and inspect your application. Every command starts with `php artisan`.

**Authentication.** The process of proving who a user is, usually with an email and password. In Catatku, this covers registration, login, and logout.

**Authorization.** Deciding what an authenticated user is allowed to do. Catatku uses ownership-based authorization: a user may only read, edit, or delete their own entries, enforced with an `abort(403)` check.

**Blade.** Laravel's template engine. Blade files end in `.blade.php` and let you write HTML mixed with clean directives like `{{ }}`, `@foreach`, and `@if`.

**Blade component.** A reusable piece of UI stored in `resources/views/components/`. The file `layout.blade.php` becomes the `<x-layout>` tag. Components receive data through slots and props.

**Carbon.** The date and time library bundled with Laravel. Timestamp columns become Carbon objects, giving you methods like `format()`, `diffForHumans()`, and `isoFormat()`.

**Closure.** An anonymous function, written inline. Early routes used a closure to hold their logic before that logic moved into a controller.

**Composer.** The package manager for PHP. You used it to create the Laravel project and to install its dependencies.

**Controller.** The class that holds your application logic. It receives a request, prepares or fetches data, and returns a view or redirect. Catatku has `EntryController` and `AuthController`.

**CRUD.** Create, Read, Update, Delete: the four basic operations on data. Building full CRUD for entries was the heart of Part IV.

**CSRF (Cross-Site Request Forgery).** An attack where a malicious site tries to submit a form to your app on a user's behalf. The `@csrf` directive adds a hidden token that blocks this. A missing token causes a 419 error.

**Eager loading.** Fetching related records in advance to avoid extra queries. `Entry::with('user')` eager loads each entry's user, preventing the N+1 problem.

**Eloquent.** Laravel's ORM. It maps database tables to PHP model classes, rows to objects, and columns to properties, so you write expressive PHP instead of raw SQL.

**Environment file (`.env`).** A file holding environment-specific settings like database credentials. It is never committed to Git because it contains secrets.

**Fillable.** The list of columns allowed to be set through mass assignment. Laravel 13 declares it with the `#[Fillable([...])]` attribute. It is the front line of mass assignment protection.

**Flash message.** A one-time message stored in the session and shown on the next page, then cleared. Catatku uses `redirect()->with('success', '...')` for these.

**Foreign key.** A column that links one table to another. The `user_id` column on `entries` is a foreign key pointing to `users.id`.

**Hashing.** A one-way transformation applied to passwords before storage with `Hash::make()`. The original cannot be recovered, but `Hash::check()` can still verify it.

**HTTP method.** The verb of a request: GET (read), POST (create), PUT (update), DELETE (remove). Browsers only support GET and POST in forms, so the others use method spoofing.

**Mass assignment.** Creating or updating a record by passing a whole array of data at once, as in `Entry::create($validated)`. It is convenient but must be guarded by `#[Fillable]`.

**Method spoofing.** Adding `@method('PUT')` or `@method('DELETE')` to a POST form so Laravel treats it as that verb. It works around the HTML limitation of only supporting GET and POST.

**Middleware.** A filter that runs before a request reaches your controller. `auth` requires a logged-in user; `guest` requires the opposite.

**Migration.** A PHP file that defines a database structure change. Migrations are tracked in Git, run with `php artisan migrate`, and undone with `php artisan migrate:rollback`.

**Model.** A class representing a database table, such as `Entry` or `User`. Models carry relationships, fillable rules, and query methods through Eloquent.

**MVC (Model-View-Controller).** The pattern that splits an app into data (Model), presentation (View), and flow control (Controller). It keeps each concern in its own place.

**N+1 problem.** A performance trap where accessing a relationship inside a loop fires one extra query per item. Eager loading with `with()` fixes it.

**ORM (Object-Relational Mapping).** A technique for working with database rows as objects. Eloquent is Laravel's ORM.

**Prop.** A named value passed into a Blade component, declared with `@props([...])` and passed with attributes like `:entry="$entry"`.

**Relationship.** A defined link between models. `belongsTo` says an entry belongs to a user; `hasMany` says a user has many entries.

**Route.** A mapping between a URL and the code that runs for it, defined in `routes/web.php`.

**Route Model Binding.** Laravel automatically turning a URL parameter into a model. A method `show(Entry $entry)` receives the entry whose id is in the URL, or a 404 if none exists.

**Seed data.** Sample records inserted for testing, which you added through Tinker in Chapter 6.

**Session.** Server-side storage that remembers a user across requests, identified by a cookie in the browser. It is how a user stays logged in.

**Session fixation.** An attack defeated by regenerating the session id after login with `session()->regenerate()`.

**Slot.** The content placed between a component's opening and closing tags, available inside as `{{ $slot }}`.

**Tinker.** Laravel's interactive REPL, opened with `php artisan tinker`, for running model queries and inserting data by hand.

**Validation.** Checking incoming input against rules like `required`, `email`, `unique`, `min`, `max`, and `confirmed` before using it. `$request->validate([...])` does this and redirects back with errors on failure.

**View.** A Blade template that turns data into HTML. Views live in `resources/views/`.

**XSS (Cross-Site Scripting).** An attack where malicious markup is injected into a page. Blade's `{{ }}` escapes output automatically, which is why you always prefer it over raw echo.
