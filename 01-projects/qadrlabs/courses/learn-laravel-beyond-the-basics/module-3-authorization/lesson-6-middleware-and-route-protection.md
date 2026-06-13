## 1. Before You Begin

Middleware is code that runs before (or after) a request reaches your controller. You already use the `auth` middleware from the beginner course to ensure users are logged in. In this lesson, you will understand how the middleware pipeline works, create your own custom middleware, and organize routes into groups with shared middleware.

Middleware acts as a series of filters for HTTP requests. Each middleware can inspect the request, modify it, or reject it entirely before it reaches the controller. Laravel's built-in middleware handles authentication, CSRF protection, and rate limiting. You can create custom middleware for any application-specific logic. By the end of this lesson, Catatku will log every authenticated request, rate-limit comments to prevent spam, and organize its routes cleanly into groups.

### What You'll Build

You will create a custom middleware that logs request information, organize Catatku's routes into clean middleware groups, and apply rate limiting to the comment creation route.

### What You'll Learn

- ✅ How the middleware pipeline works
- ✅ Creating custom middleware with `make:middleware`
- ✅ Registering middleware aliases
- ✅ Applying middleware to routes and groups
- ✅ Built-in middleware: `auth`, `guest`, `throttle`
- ✅ Rate limiting specific routes

### What You'll Need

- Lesson 5 completed with authorization

---

## 2. Understanding the Middleware Pipeline

When a request arrives at your Laravel application, it passes through a series of middleware before reaching the controller. Each middleware can do one of three things: pass the request to the next middleware, modify the request before passing it, or reject the request entirely by returning a response or redirecting.

Think of it as a security checkpoint at a building. The first guard checks your ID (authentication middleware). The second checks your badge (authorization middleware). The third logs your entry time (logging middleware). If you fail any check, you are turned away before reaching your destination. If you pass all checks, you reach the controller. The same pattern protects your application: each middleware handles one concern, and together they form a pipeline that every request must traverse.

---

## 3. Create Custom Middleware

In this section you will generate a custom logging middleware and register it so you can apply it to routes by name.

### Step 1: Generate the Middleware

Run the following Artisan command to create the middleware file.

```bash
php artisan make:middleware LogRequest
```

This creates `app/Http/Middleware/LogRequest.php` with a skeleton `handle()` method that you will fill in next.

### Step 2: Write the Middleware Logic

Open `app/Http/Middleware/LogRequest.php` and replace its content with the following.

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class LogRequest
{
    public function handle(Request $request, Closure $next): Response
    {
        $start = microtime(true);

        $response = $next($request);

        $duration = round((microtime(true) - $start) * 1000, 2);

        Log::info('Request processed', [
            'method' => $request->method(),
            'url' => $request->fullUrl(),
            'user' => $request->user()?->id,
            'status' => $response->getStatusCode(),
            'duration_ms' => $duration,
        ]);

        return $response;
    }
}
```

Let us walk through the middleware step by step. The `use` statements import four classes: `Closure` for the `$next` callable, `Request` for the incoming HTTP request, `Log` for writing to Laravel's log files, and `Response` for the return type. The `handle()` method is the entry point every middleware must implement.

`$start = microtime(true)` captures the current time in seconds with microsecond precision before anything else runs. The line `$response = $next($request)` is the most important: it passes the request to the next middleware in the pipeline, and eventually to the controller. Whatever the controller returns comes back here as the response. Without calling `$next($request)`, the request would never reach the controller and the user would see a blank page.

After `$next($request)` returns, we are in "after" mode. `$duration = round((microtime(true) - $start) * 1000, 2)` calculates elapsed milliseconds by subtracting the start time from the current time, multiplying by 1000 to convert seconds to milliseconds, and rounding to 2 decimal places. `Log::info('Request processed', [...])` writes a structured log entry with five fields: the HTTP method, full URL, the authenticated user's ID (using the null-safe `?->` operator in case the user is not logged in), the HTTP response status code, and the duration. Finally, we return `$response` so it continues back up the pipeline to the browser. This single middleware demonstrates both "before" behavior (timing start) and "after" behavior (logging the completed result).

### Step 3: Register the Middleware

Open `bootstrap/app.php` and add the alias registration inside the **existing** `withMiddleware()` closure — do not add a second `withMiddleware()` call.

```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'log.request' => \App\Http\Middleware\LogRequest::class,
    ]);
})
```

This registration step is necessary because Laravel needs to know about your middleware before you can reference it by name in routes. The `withMiddleware()` closure already exists in `bootstrap/app.php` and is initially empty. The `alias()` call maps the short name `log.request` to the fully qualified class name. Without this alias, attempting to use `log.request` in a route definition would throw a "target class not found" error.

---

## 4. Organize Routes with Middleware Groups

Open `routes/web.php` and make two changes to the existing file: add `'log.request'` to the `auth` middleware group, and replace the seven individual entry routes with a single `Route::resource()` call. Replace the entire file content with the following.

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EntryController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\TagController;
use App\Http\Controllers\CommentController;

Route::get('/', function () {
    return view('home');
});

Route::middleware('guest')->group(function () {
    Route::get('/register', [AuthController::class, 'showRegister']);
    Route::post('/register', [AuthController::class, 'register']);

    Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthController::class, 'login']);
});

Route::middleware(['auth', 'log.request'])->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/entries/trash', [EntryController::class, 'trash'])->name('entries.trash');
    Route::resource('entries', EntryController::class);
    Route::patch('/entries/{entry}/restore', [EntryController::class, 'restore'])
        ->name('entries.restore')
        ->withTrashed();

    Route::post('/entries/{entry}/comments', [CommentController::class, 'store'])
        ->name('comments.store')
        ->middleware('throttle:10,1');
    Route::delete('/comments/{comment}', [CommentController::class, 'destroy'])->name('comments.destroy');

    Route::get('/tags', [TagController::class, 'index'])->name('tags.index');
    Route::get('/tags/{tag:slug}', [TagController::class, 'show'])->name('tags.show');
});
```

There are two meaningful changes from the previous lesson. First, the middleware group now reads `['auth', 'log.request']` — adding `log.request` alongside `auth` so every authenticated request is logged automatically. Second, the seven individual entry routes (index, create, store, show, edit, update, destroy) are replaced by `Route::resource('entries', EntryController::class)`, which generates all seven with identical route names in a single line. Everything else is carried over from earlier lessons and simply grouped here under the new middleware: the guest group and logout from the beginner course, the `comments.store`/`comments.destroy` routes and `CommentController` from Lesson 1, and the `tags.index`/`tags.show` routes and `TagController` from Lesson 2. Make sure those controllers exist (they were built in the bodies of Lessons 1 and 2) before reloading the app, or the route file will fail to resolve them.

Notice that `Route::get('/entries/trash', ...)` is placed **before** `Route::resource('entries', ...)`. The reason is that `Route::resource()` internally registers `GET /entries/{entry}` as the show route. Laravel matches routes in registration order, so if the trash route were placed after the resource, visiting `/entries/trash` would match `{entry}=trash` and call `show()` instead of `trash()`. Placing the literal route first ensures it wins before the wildcard is evaluated.

The comment store route receives additional inline middleware: `->middleware('throttle:10,1')` limits each user to a maximum of 10 comment submissions per minute. Stacking additional middleware on a specific route does not affect other routes in the group; the group-level `auth` and `log.request` still apply to all of them.

---

## 5. Run and Test

Let us verify all three aspects of this lesson - logging, rate limiting, and route protection - work correctly.

### Step 1: Test the Logging Middleware

Start the development server.

```bash
php artisan serve
```

Visit `http://localhost:8000/entries` in the browser while logged in. Then open `storage/logs/laravel.log` in your editor or terminal and look at the last line. You should see a log entry similar to the following.

```
[2026-04-17 10:30:45] local.INFO: Request processed {"method":"GET","url":"http://localhost:8000/entries","user":1,"status":200,"duration_ms":45.23}
```

This confirms the middleware is running on every request within the authenticated group. The fields include exactly what we logged: the HTTP method, full URL, user ID, response status code, and duration in milliseconds.

### Step 2: Test Rate Limiting

Navigate to an entry's detail page and submit more than 10 comments within one minute. After the tenth comment, you should see a 429 Too Many Requests error page. Wait one minute and try again; the submission should succeed. The `throttle` middleware tracks requests per user using Laravel's cache and automatically rejects requests once the limit is exceeded, returning a `Retry-After` header so the client knows when to try again.

### Step 3: Test Route Protection

Log out and try to access `/entries` directly by typing the URL into the browser. You should be redirected to the login page by the `auth` middleware. This confirms that unauthenticated users cannot bypass the login flow simply by knowing a URL.

### Step 4: Verify Middleware Order

Open `storage/logs/laravel.log` and confirm that requests from unauthenticated users do not produce `log.request` entries. This is because the `auth` middleware runs first in the group array and rejects the request before `log.request` ever runs. Middleware in a group array executes in order from left to right, and the first middleware to reject a request stops the pipeline entirely.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes when creating and applying middleware in Laravel.

**Error 1: Middleware creates an infinite redirect loop.**

This error occurs when a middleware redirects the user to a route that is also protected by the same middleware. The user is redirected, that route runs the middleware again, the middleware redirects again, and the cycle repeats until the browser reports "Too many redirects".

```php
// Wrong: ProfileSetup middleware redirects to /profile/setup,
// but that route also uses ProfileSetup middleware
public function handle(Request $request, Closure $next): Response
{
    if (!$request->user()->hasProfile()) {
        return redirect('/profile/setup');
    }
    return $next($request);
}

// Correct: exclude the destination route from the middleware check
public function handle(Request $request, Closure $next): Response
{
    if (!$request->user()->hasProfile() && $request->path() !== 'profile/setup') {
        return redirect('/profile/setup');
    }
    return $next($request);
}
```

The wrong version redirects unconditionally, so when the user lands on `/profile/setup`, the middleware runs again, redirects again, and the loop never ends. The correct version adds a path check with `$request->path() !== 'profile/setup'` to skip the redirect when the user is already on the destination route. Alternatively, you can exclude certain routes from the middleware using `$middleware->except(['profile.setup'])` in the registration.

---

**Error 2: Forgetting to return `$next($request)`.**

This is the most critical middleware mistake. If you forget to return the result of `$next($request)`, the request never reaches the controller and the browser receives an empty response.

```php
// Wrong: $next($request) is called but its result is not returned
public function handle(Request $request, Closure $next): Response
{
    Log::info('Request received');
    $next($request);
}

// Correct: always return the result of $next($request)
public function handle(Request $request, Closure $next): Response
{
    Log::info('Request received');
    return $next($request);
}
```

In the wrong version, `$next($request)` is called and the controller runs, but the response is discarded because the `handle` method never returns it. The browser receives a null or empty response. The correct version returns the result of `$next($request)`, which passes the response back up the chain to the browser. This is not optional: always return the result.

---

**Error 3: Using a middleware alias that was never registered.**

This error occurs when you reference a middleware by short name in a route definition but forget to register the alias. Laravel has no way to map the string to a class.

```php
// Wrong: log.request used in route but not registered as an alias
Route::middleware('log.request')->group(function () {
    Route::resource('entries', EntryController::class);
});

// Correct: register the alias first in bootstrap/app.php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'log.request' => \App\Http\Middleware\LogRequest::class,
    ]);
})
```

The wrong version uses `'log.request'` in the route, but without a registered alias, Laravel does not know what class to instantiate and throws "Target class [log.request] does not exist". The correct version registers the alias first in `bootstrap/app.php` so Laravel can resolve the string to the correct middleware class when processing the route.

---

## 7. Exercises

These exercises extend the middleware patterns from this lesson to other parts of Catatku. Each one requires creating or modifying middleware independently, giving you practice applying the pipeline concepts without step-by-step guidance.

**Exercise 1:** Create an `AdminOnly` middleware that checks if the user has `is_admin = true` and returns 403 if not. Apply it to an admin route group.

**Exercise 2:** Create a `TrackLastActivity` middleware that updates the user's `last_active_at` column on every request. Add the column migration first.

**Exercise 3:** Apply `throttle:5,1` to the entry `store` route to limit creating entries to 5 per minute. Test by rapidly submitting the create form.

---

## 8. Solutions

Each solution below is a complete implementation you can apply directly to Catatku. Pay attention to where the middleware is registered and how it is connected to routes, since those two steps are both required for middleware to take effect.

**Solution for Exercise 1:**

Generate the middleware file with Artisan.

```bash
php artisan make:middleware AdminOnly
```

Open `app/Http/Middleware/AdminOnly.php` and write the logic.

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AdminOnly
{
    public function handle(Request $request, Closure $next): Response
    {
        if (!$request->user()?->is_admin) {
            abort(403, 'Admin access required.');
        }
        return $next($request);
    }
}
```

In `bootstrap/app.php`, add the `admin.only` alias inside the existing `withMiddleware()` closure alongside `log.request`.

```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'log.request' => \App\Http\Middleware\LogRequest::class,
        'admin.only'  => \App\Http\Middleware\AdminOnly::class,
    ]);
})
```

Then apply the alias to an admin route group in `routes/web.php`.

```php
Route::middleware(['auth', 'admin.only'])->prefix('admin')->group(function () {
    Route::get('/dashboard', [AdminController::class, 'index'])->name('admin.dashboard');
});
```

The `abort(403)` function throws an HTTP exception that renders the 403 error page. The null-safe operator `?->` prevents a fatal error when the user is not authenticated; the expression short-circuits to `null`, which is falsy, causing the abort to run. The `$next($request)` call is only reached if the user passes the admin check.

---

**Solution for Exercise 2:**

Create and run the migration to add the `last_active_at` column.

```bash
php artisan make:migration add_last_active_at_to_users --table=users
```

In the migration file, add the column definition.

```php
public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->timestamp('last_active_at')->nullable();
    });
}

public function down(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn('last_active_at');
    });
}
```

`$table->timestamp('last_active_at')->nullable()` adds a TIMESTAMP column that accepts NULL as its default value. Nullable is necessary here because existing users already in the database have no activity timestamp yet, so the column must allow NULL until they make their first request after the migration runs. The `down()` method removes the column if you roll back. Run the migration with `php artisan migrate`, then generate the middleware file.

```bash
php artisan make:middleware TrackLastActivity
```

This creates `app/Http/Middleware/TrackLastActivity.php` with an empty `handle()` method. Open it and replace the file content with the following.

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class TrackLastActivity
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->user()) {
            $request->user()->update(['last_active_at' => now()]);
        }

        return $next($request);
    }
}
```

The `if ($request->user())` guard prevents the update from running for unauthenticated users. `$request->user()->update(['last_active_at' => now()])` writes the current timestamp to the database. Register the middleware alias and add it to the authenticated route group. For performance, you may want to add a cache check so the database is only updated once per minute rather than on every page view.

---

**Solution for Exercise 3:**

Open `routes/web.php` and separate the `store` route from the `Route::resource()` macro so you can attach throttle middleware to it independently. Keep `Route::get('/entries/trash', ...)` before the resource to preserve correct route ordering.

```php
Route::middleware(['auth', 'log.request'])->group(function () {
    Route::get('/entries/trash', [EntryController::class, 'trash'])->name('entries.trash');

    Route::resource('entries', EntryController::class)->except(['store']);

    Route::post('/entries', [EntryController::class, 'store'])
        ->name('entries.store')
        ->middleware('throttle:5,1');

    Route::patch('/entries/{entry}/restore', [EntryController::class, 'restore'])
        ->name('entries.restore')
        ->withTrashed();

    Route::post('/entries/{entry}/comments', [CommentController::class, 'store'])
        ->name('comments.store')
        ->middleware('throttle:10,1');
});
```

The `->except(['store'])` call removes the POST `/entries` route that `Route::resource()` would normally generate, freeing you to re-define it manually on the next line with the additional `throttle:5,1` middleware. Without `except(['store'])`, two routes would match the same URL and method, which causes unpredictable behavior. The named route `entries.store` must match what the resource macro would have generated so that existing form actions and `route()` calls in your views continue to work without changes. To test, submit the entry creation form six or more times within one minute and confirm the sixth attempt returns a 429 Too Many Requests response.

---

## Next Up - Lesson 7

In this lesson you learned how the middleware pipeline filters HTTP requests before they reach controllers. You created a custom `LogRequest` middleware that demonstrates both "before" and "after" behavior: capturing a timestamp before passing the request through and writing a structured log entry after the controller returns. You organized Catatku's routes into a clean authenticated group with shared middleware, and applied `throttle:10,1` to the comment creation route to prevent spam. You also learned the three most critical rules: always register middleware aliases before using them, always return `$next($request)`, and always exclude the redirect destination when rejecting requests.

In Lesson 7, you will learn file uploads and storage: how to add cover image uploads to Catatku entries using Laravel's Storage facade, validate file types and sizes, and display uploaded images in views.