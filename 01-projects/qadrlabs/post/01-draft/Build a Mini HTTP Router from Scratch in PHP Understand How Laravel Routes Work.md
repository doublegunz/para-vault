# Build a Mini HTTP Router from Scratch in PHP: Understand How Laravel Routes Work

You write `Route::get('/users/{id}', ...)` almost every day, yet routing still feels like a black box. When a route suddenly returns 404, or two routes collide and the wrong one wins, you are left guessing because the regex and the matching loop are hidden deep inside the framework. That guessing tax adds up: you copy snippets you do not fully understand, you cannot explain why `/users/new` matched `/users/{id}`, and debugging route order becomes trial and error. The fastest cure is to build the thing yourself. In this tutorial you will write a small HTTP router in plain PHP, around 100 lines, that supports exact routes, dynamic `{id}` parameters, route groups, and middleware. By the end, Laravel routing will stop being magic and start being a few lines of code you can reason about.

## Overview {#overview}

A router has one job: take an incoming request (an HTTP method plus a URI) and decide which piece of code should handle it. Everything else, dynamic parameters, groups, middleware, is built on top of that single idea. We will grow our router one capability at a time, running it after each step so you can see exactly what each addition buys you. We finish with a set of Pest tests and a section that maps every concept back to how Laravel does the same job at scale.

### What You'll Build

- A `Router` class that registers `GET` and `POST` routes
- Exact route matching with a clean 404 fallback
- Dynamic parameters like `/users/{id}` extracted with regex and passed to handlers
- Route groups that share a URI prefix and a middleware stack
- A small demo app served by PHP's built-in web server
- A Pest test suite that proves the router behaves correctly

### What You'll Learn

- How an HTTP request is reduced to a method plus a URI path
- How to register routes and store them in a simple table
- How to convert `{param}` placeholders into a regular expression and capture their values
- How middleware runs before a handler and can short-circuit a request
- How all of this maps to Laravel's `RouteCollection` and Symfony's compiled route regex

### What You'll Need

- PHP 8.3 or newer installed (this tutorial was written and tested on PHP 8.5)
- Composer for autoloading and for installing Pest
- A terminal and basic familiarity with PHP classes and closures
- No framework at all; this is pure PHP

## Step 1: Set Up the Project and a Front Controller {#step-1-set-up-the-project}

Every modern PHP application funnels all requests through a single entry point called a front controller. That one file boots the application and hands the request to the router. We will create a tiny project with Composer autoloading so our classes load automatically.

Create the project folder and the two directories we need, then add a `composer.json` file:

```json
{
    "name": "qadrlabs/mini-router",
    "description": "A mini HTTP router built from scratch in PHP",
    "type": "project",
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    },
    "require": {
        "php": ">=8.3"
    }
}
```

The important part is the `autoload` block. It tells Composer that any class in the `App\` namespace lives inside the `src/` folder, following the PSR-4 standard. With that in place, writing `App\Router` will load `src/Router.php` without a single manual `require`.

Generate the autoloader so Composer creates the `vendor/autoload.php` file:

```bash
composer dump-autoload
```

You should see output similar to this:

```
Generating autoload files
Generated autoload files
```

Now create the front controller at `public/index.php`. For now it only proves the wiring works:

```php
<?php

require __DIR__ . '/../vendor/autoload.php';

echo 'Router is alive';
```

The single `require` line loads Composer's autoloader, which is the only `require` you will ever write in this project. Everything after this point relies on autoloading.

Start PHP's built-in web server, pointing its document root at the `public/` folder so the outside world only ever sees `public/index.php`:

```bash
php -S localhost:8000 -t public
```

Visit `http://localhost:8000` in your browser or use `curl` in another terminal:

```bash
curl localhost:8000
```

You should get back:

```
Router is alive
```

Because the document root is `public/`, any URL you request (`/`, `/users/42`, `/anything`) is still served by `index.php`. That is exactly what we want: one entry point that we can route from. Stop the server with `Ctrl+C` when you are ready to move on.

## Step 2: Register Routes in a Router Class {#step-2-register-routes}

Before a router can match anything, it needs a list of routes to match against. In this step we build the registration side of the router: methods that record "when a GET request hits this path, run this handler." We will not match anything yet, just collect the routes into a table.

Create `src/Router.php` with the registration logic:

```php
<?php

namespace App;

class Router
{
    // Every registered route is stored here as an array of
    // [method, path, handler, middleware].
    private array $routes = [];

    // Register a route for a specific HTTP method.
    public function add(string $method, string $path, callable $handler): void
    {
        $this->routes[] = [
            'method' => strtoupper($method),
            'path' => $path,
            'handler' => $handler,
            'middleware' => [],
        ];
    }

    // Convenience helpers so callers write get()/post() instead of add().
    public function get(string $path, callable $handler): void
    {
        $this->add('GET', $path, $handler);
    }

    public function post(string $path, callable $handler): void
    {
        $this->add('POST', $path, $handler);
    }
}
```

The `$routes` array is the heart of the router. Each entry remembers four things: the HTTP method, the URI path, the handler to run, and a list of middleware (empty for now, we will use it in Step 5). The `add()` method normalizes the method to uppercase so `get` and `GET` behave the same, then appends the route to the table. The `get()` and `post()` helpers exist purely for readability; they call `add()` with the method filled in, which is the same ergonomic shortcut Laravel gives you with `Route::get()` and `Route::post()`.

Wire a couple of routes into `public/index.php` so we have something to match later:

```php
<?php

require __DIR__ . '/../vendor/autoload.php';

use App\Router;

$router = new Router();

// A plain exact route.
$router->get('/', function () {
    return 'Welcome to the mini router';
});

// A route that will become dynamic in Step 4.
$router->get('/users/{id}', function ($id) {
    return "Showing user #{$id}";
});

echo 'Routes registered';
```

At this point nothing dispatches yet, so visiting any URL still prints `Routes registered`. That is expected; we have only built the part that remembers routes. Next we teach the router to actually pick one.

## Step 3: Match Exact Routes and Dispatch {#step-3-match-and-dispatch}

This is the step where the router earns its name. Dispatching means looking at the current request, walking the route table, finding the first route whose method and path match, and running its handler. If nothing matches, we return a 404 just like any real framework.

Add a `dispatch()` method to `src/Router.php`, right after the `post()` method:

```php
    // Match a method and URI against the route table and run the handler.
    public function dispatch(?string $method = null, ?string $uri = null): mixed
    {
        // Default to the real request, but allow explicit args for testing.
        $method = strtoupper($method ?? $_SERVER['REQUEST_METHOD']);
        $uri = $uri ?? parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

        foreach ($this->routes as $route) {
            if ($route['method'] !== $method) {
                continue;
            }

            if ($route['path'] !== $uri) {
                continue;
            }

            return ($route['handler'])();
        }

        // No route matched, so send a 404 like any real framework would.
        http_response_code(404);

        return '404 Not Found';
    }
```

There are two design choices worth explaining here. First, `dispatch()` accepts an optional method and URI but defaults to the real request via `$_SERVER['REQUEST_METHOD']` and `$_SERVER['REQUEST_URI']`. Reading the request inside the router is convenient in production, while allowing explicit arguments makes the router trivially testable later without faking superglobals. Second, we run `parse_url($uri, PHP_URL_PATH)` to strip any query string, so `/users?page=2` matches the route `/users` rather than failing. The loop itself is deliberately boring: skip routes whose method differs, skip routes whose path differs, and run the first exact match. The `continue` statements make the "first match wins" behavior explicit, which is the same rule Laravel follows.

Update the bottom of `public/index.php` to dispatch and echo the result:

```php
<?php

require __DIR__ . '/../vendor/autoload.php';

use App\Router;

$router = new Router();

$router->get('/', function () {
    return 'Welcome to the mini router';
});

echo $router->dispatch();
```

Start the server again and test the home route and a missing route:

```bash
php -S localhost:8000 -t public
```

```bash
curl localhost:8000/
```

```
Welcome to the mini router
```

Now request something that does not exist and inspect the status line with `curl -i`:

```bash
curl -i localhost:8000/nope
```

```
HTTP/1.1 404 Not Found
```

The exact match works and the 404 path works. The obvious limitation is that `/users/42` would never match `/users/{id}`, because the strings differ. That is the problem we solve next.

## Step 4: Support Dynamic Parameters with Regex {#step-4-dynamic-parameters}

Real routes have variable segments: a user id, a slug, a post and comment pair. We cannot compare those with plain string equality, so we convert each route path into a regular expression where `{id}` becomes a capture group. When the request URI matches that regex, the captured values become the parameters we pass to the handler.

First, add a small `compile()` helper to `src/Router.php` that turns a path into a regex:

```php
    // Turn "/users/{id}" into a regex with a named capture group.
    private function compile(string $path): string
    {
        $pattern = preg_replace('#\{([a-zA-Z_]\w*)\}#', '(?<$1>[^/]+)', $path);

        return '#^' . $pattern . '$#';
    }
```

The `preg_replace` finds every `{name}` placeholder and rewrites it as `(?<name>[^/]+)`, a named capture group that matches one or more characters that are not a slash. The `[^/]+` part is what stops a single parameter from swallowing the rest of the URL. We then wrap the whole thing in `#^...$#` so the regex must match the entire path, not just a piece of it. For example, `/users/{id}` becomes `#^/users/(?<id>[^/]+)$#`, which matches `/users/42` and captures `42` under the name `id`.

Now replace the exact path comparison in `dispatch()` with a regex match. Change this block:

```php
            if ($route['path'] !== $uri) {
                continue;
            }

            return ($route['handler'])();
```

into this:

```php
            if (!preg_match($this->compile($route['path']), $uri, $matches)) {
                continue;
            }

            // Keep only named captures like "id", drop numeric indexes.
            $params = array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);

            // Pass captured params to the handler as ordered arguments.
            return call_user_func_array($route['handler'], array_values($params));
```

When `preg_match` succeeds, it fills `$matches` with both numeric and named keys. We only want the named ones, so `array_filter` with `ARRAY_FILTER_USE_KEY` and `is_string` keeps `id` and `commentId` while dropping the duplicate numeric indexes. Finally, `call_user_func_array` spreads those captured values into the handler as positional arguments, so a handler declared as `function ($id)` receives `42`. Note that an exact route like `/` still works, because a path with no placeholders compiles to a regex that only matches itself.

Update `public/index.php` to register a couple of dynamic routes and a POST route:

```php
<?php

require __DIR__ . '/../vendor/autoload.php';

use App\Router;

$router = new Router();

// A plain exact route.
$router->get('/', function () {
    return 'Welcome to the mini router';
});

// A dynamic route: {id} is captured and passed to the handler.
$router->get('/users/{id}', function ($id) {
    return "Showing user #{$id}";
});

// Two parameters in one path.
$router->get('/posts/{postId}/comments/{commentId}', function ($postId, $commentId) {
    return "Comment {$commentId} on post {$postId}";
});

// A POST route to prove method matching works.
$router->post('/users', function () {
    return 'User created';
});

echo $router->dispatch();
```

Restart the server and try the dynamic routes:

```bash
curl localhost:8000/users/42
```

```
Showing user #42
```

```bash
curl localhost:8000/posts/7/comments/99
```

```
Comment 99 on post 7
```

The router now extracts one or many parameters and feeds them to the handler in order. With dynamic matching in place, we can add the last big feature: grouping and middleware.

## Step 5: Add Route Groups and Simple Middleware {#step-5-groups-and-middleware}

Most apps have clusters of routes that share something: an `/admin` prefix, an authentication check, or both. Repeating that on every route is tedious and error prone. A route group lets you declare the shared prefix and middleware once, then register the inner routes against it. Middleware here is just a callable that runs before the handler and can stop the request by returning a value.

First, give the router the notion of a "current group" by adding two properties and a `group()` method. Add the properties near the top of the class, right after `$routes`:

```php
    // The current group prefix and middleware stack, applied while
    // routes are registered inside group().
    private string $groupPrefix = '';
    private array $groupMiddleware = [];
```

Then update `add()` so it folds the current group context into each route. Change the `add()` body to this:

```php
    public function add(string $method, string $path, callable $handler): void
    {
        $this->routes[] = [
            'method' => strtoupper($method),
            'path' => $this->groupPrefix . $path,
            'handler' => $handler,
            'middleware' => $this->groupMiddleware,
        ];
    }
```

Now `add()` prepends whatever prefix is active and attaches whatever middleware is active. Outside of a group both are empty, so ordinary routes are unaffected. Inside a group, every route automatically inherits the prefix and middleware.

Add the `group()` method itself, for example after `post()`:

```php
    // Register several routes under a shared prefix and middleware stack.
    public function group(string $prefix, array $middleware, callable $callback): void
    {
        // Remember the outer context so groups can nest safely.
        $previousPrefix = $this->groupPrefix;
        $previousMiddleware = $this->groupMiddleware;

        $this->groupPrefix = $previousPrefix . $prefix;
        $this->groupMiddleware = array_merge($previousMiddleware, $middleware);

        // Routes registered inside this callback inherit the prefix above.
        $callback($this);

        // Restore the outer context once the group is done.
        $this->groupPrefix = $previousPrefix;
        $this->groupMiddleware = $previousMiddleware;
    }
```

The save-and-restore pattern is what makes groups composable. We stash the previous prefix and middleware, set the new combined values, run the callback (which registers the inner routes), then put the old values back. Because we restore the context afterward, you can nest groups and routes declared after a group are not accidentally prefixed. This is the same mechanism Laravel uses when you write `Route::prefix('admin')->middleware('auth')->group(...)`.

Finally, teach `dispatch()` to run the middleware before the handler. Insert this block immediately after you build `$params` and before the `call_user_func_array` line:

```php
            // Run each middleware first; a non-null return short-circuits.
            foreach ($route['middleware'] as $middleware) {
                $result = $middleware($params);

                if ($result !== null) {
                    return $result;
                }
            }
```

The contract is simple and predictable: each middleware receives the captured route parameters and may return a value to stop the request immediately, or return `null` to let the request continue. A returned value short-circuits the whole dispatch, which is exactly how an auth middleware blocks an unauthenticated user before any controller logic runs.

Wire a protected group into `public/index.php`. Add a fake auth middleware and an admin group:

```php
// A simple "auth" middleware: block the request unless ?token=secret is set.
$auth = function (array $params) {
    if (($_GET['token'] ?? null) !== 'secret') {
        http_response_code(401);
        return '401 Unauthorized';
    }
    return null; // returning null lets the request continue
};

// Routes inside this group share the /admin prefix and the auth middleware.
$router->group('/admin', [$auth], function (Router $router) {
    $router->get('/dashboard', function () {
        return 'Admin dashboard';
    });
});

echo $router->dispatch();
```

Make sure that `echo $router->dispatch();` appears only once, at the very bottom of the file. Restart the server and request the dashboard without a token:

```bash
curl -i localhost:8000/admin/dashboard
```

```
HTTP/1.1 401 Unauthorized
```

Now request it with the token:

```bash
curl "localhost:8000/admin/dashboard?token=secret"
```

```
Admin dashboard
```

The middleware ran first, blocked the unauthorized request with a 401, and only let the authorized one through to the handler. The router is now feature complete. Let us exercise everything in one place.

## Step 6: Try It Out {#step-6-try-it-out}

With the server running on `localhost:8000`, walk through every capability in one sitting. Seeing all the scenarios back to back is the best way to confirm the router behaves the way you expect.

Start with the exact home route:

```bash
curl localhost:8000/
```

```
Welcome to the mini router
```

A single dynamic parameter:

```bash
curl localhost:8000/users/42
```

```
Showing user #42
```

Multiple parameters in one path:

```bash
curl localhost:8000/posts/7/comments/99
```

```
Comment 99 on post 7
```

Method matching, the POST route shares its path style with GET routes but only answers POST:

```bash
curl -X POST localhost:8000/users
```

```
User created
```

An unknown route, which falls through to the 404:

```bash
curl -i localhost:8000/nope
```

```
HTTP/1.1 404 Not Found
```

The grouped route blocked by middleware:

```bash
curl -i localhost:8000/admin/dashboard
```

```
HTTP/1.1 401 Unauthorized
```

And the same route allowed once the token is present:

```bash
curl "localhost:8000/admin/dashboard?token=secret"
```

```
Admin dashboard
```

Every feature behaves correctly. Manual testing with `curl` is fine for a walkthrough, but it does not protect you from regressions. For that we need automated tests.

## Step 7: Test the Router with Pest {#step-7-test-with-pest}

The reason we let `dispatch()` accept an explicit method and URI in Step 3 pays off now: we can test the router without spinning up a server or faking the `$_SERVER` superglobals. We will use Pest, a testing framework with a clean, expressive syntax, to lock in the router's behavior.

Install Pest as a development dependency:

```bash
composer require pestphp/pest --dev --with-all-dependencies
```

Pest ships a Composer plugin, so the first time you install it Composer asks for permission to run that plugin. Approve it when prompted, or allow it explicitly:

```bash
composer config allow-plugins.pestphp/pest-plugin true
```

Create a minimal `tests/Pest.php` file so Pest has an entry point. Since our router has no framework to bootstrap, the file can stay almost empty:

```php
<?php

// Pest's entry point. We keep it minimal since the router has no framework.
```

Add a `phpunit.xml` at the project root so Pest knows where the tests live:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         colors="true">
    <testsuites>
        <testsuite name="Feature">
            <directory>tests/Feature</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

Now write the tests in `tests/Feature/RouterTest.php`. We register a small set of routes once with a helper, then assert that each kind of request resolves correctly:

```php
<?php

use App\Router;

// A small helper to register the same routes in every test.
function makeRouter(): Router
{
    $router = new Router();

    $router->get('/', fn () => 'home');
    $router->get('/users/{id}', fn ($id) => "user {$id}");
    $router->get('/posts/{postId}/comments/{commentId}', fn ($postId, $commentId) => "{$postId}:{$commentId}");
    $router->post('/users', fn () => 'created');

    return $router;
}

it('matches an exact route', function () {
    expect(makeRouter()->dispatch('GET', '/'))->toBe('home');
});

it('extracts a single dynamic parameter', function () {
    expect(makeRouter()->dispatch('GET', '/users/42'))->toBe('user 42');
});

it('extracts multiple dynamic parameters in order', function () {
    expect(makeRouter()->dispatch('GET', '/posts/7/comments/99'))->toBe('7:99');
});

it('treats the HTTP method as part of the match', function () {
    expect(makeRouter()->dispatch('POST', '/users'))->toBe('created');
});

it('returns 404 for an unknown route', function () {
    expect(makeRouter()->dispatch('GET', '/missing'))->toBe('404 Not Found');
});

it('runs middleware before the handler', function () {
    $router = new Router();

    $blocker = fn (array $params) => 'blocked';

    $router->group('/admin', [$blocker], function (Router $router) {
        $router->get('/dashboard', fn () => 'dashboard');
    });

    expect($router->dispatch('GET', '/admin/dashboard'))->toBe('blocked');
});

it('lets the request continue when middleware returns null', function () {
    $router = new Router();

    $pass = fn (array $params) => null;

    $router->group('/admin', [$pass], function (Router $router) {
        $router->get('/dashboard', fn () => 'dashboard');
    });

    expect($router->dispatch('GET', '/admin/dashboard'))->toBe('dashboard');
});
```

Each test reads like a sentence describing one rule of the router. The first four cover exact matching, single and multiple parameter extraction, and method matching. The fifth pins down the 404 behavior. The last two prove the middleware contract from both sides: a middleware that returns a value short-circuits the request, while one that returns `null` lets the handler run. Because `dispatch()` takes the method and URI directly, no superglobals or HTTP server are involved, which keeps the tests fast and deterministic.

Run the suite:

```bash
./vendor/bin/pest
```

```
   PASS  Tests\Feature\RouterTest
  ✓ it matches an exact route                                            0.01s  
  ✓ it extracts a single dynamic parameter
  ✓ it extracts multiple dynamic parameters in order
  ✓ it treats the HTTP method as part of the match
  ✓ it returns 404 for an unknown route
  ✓ it runs middleware before the handler
  ✓ it lets the request continue when middleware returns null

  Tests:    7 passed (7 assertions)
  Duration: 0.06s
```

Seven passing tests confirm the router does everything we built it to do. Now that you understand every line, let us connect it back to Laravel.

## How Laravel Routes Work Under the Hood {#how-laravel-routes-work}

Our mini router is a scale model of Laravel's routing system. The shapes are the same; Laravel simply adds performance, flexibility, and a lot of edge case handling. Mapping our code to Laravel's makes the framework far less mysterious, and it explains behaviors that used to look like coincidences.

When you call `Route::get('/users/{id}', ...)`, Laravel does what our `add()` method does: it creates a route object and stores it in a collection. In our router that collection is the plain `$routes` array. In Laravel it is an `Illuminate\Routing\RouteCollection`, a richer object that indexes routes by method and name so lookups stay fast even with hundreds of routes registered.

The `{id}` placeholder is handled the same way conceptually, but Laravel hands the heavy lifting to Symfony. Each route is compiled into a `Symfony\Component\Routing\CompiledRoute` by the `RouteCompiler`, which generates a regular expression very similar to the one our `compile()` method builds. Our `(?<id>[^/]+)` named capture group is exactly the kind of pattern Symfony produces. When you add a constraint with `->where('id', '[0-9]+')`, you are swapping the default `[^/]+` for your own regex, which is the same edit you would make by hand in our `compile()` method. This is also why route order matters in both systems: matching walks the collection and the first route whose compiled regex matches wins, precisely the "first match wins" loop we wrote in `dispatch()`.

Middleware in Laravel is more powerful than our single before-handler callable, because Laravel runs middleware as an onion-shaped pipeline where each layer can act both before and after the handler. But the entry point is identical to ours: before your controller runs, the matched route's middleware stack executes, and any middleware can short-circuit the request by returning a response. Our `auth` closure that returns a `401` is a faithful miniature of a real Laravel `auth` middleware redirecting a guest to the login page. Even route groups line up one to one: `Route::prefix('admin')->middleware('auth')->group(...)` uses the same save-and-restore context trick our `group()` method uses to apply a shared prefix and middleware to everything inside.

If you want to see Laravel's compiled routing table, run `php artisan route:list` in any Laravel project. Every row is a route object like the ones in our `$routes` array, complete with method, URI, name, and middleware. The difference is scale and polish, not concept.

## Conclusion {#conclusion}

You just built a working HTTP router in about a hundred lines of plain PHP, and in doing so you turned one of the framework's biggest black boxes into something you can read top to bottom. Routing is no longer magic; it is a list, a loop, and a regex. Here are the ideas worth carrying with you:

- **Routing is method plus URI plus handler.** Every router, from our toy to Laravel's, reduces a request to an HTTP method and a URI path, then finds the first registered handler that matches both.
- **Regex powers dynamic parameters.** Converting `{id}` into a named capture group like `(?<id>[^/]+)` is the entire trick behind variable URL segments, and constraints such as `->where()` are just custom regex in that same slot.
- **First match wins, so order matters.** Both our `dispatch()` loop and Laravel's `RouteCollection` return the first route that matches, which is why a greedy route registered too early can shadow a more specific one.
- **Middleware is a callable that runs before the handler.** A middleware that returns a value short-circuits the request, and one that returns nothing lets it continue; Laravel wraps this in a richer pipeline but the contract is the same.
- **Laravel is this, at scale.** `RouteCollection`, Symfony's `CompiledRoute`, route groups, and middleware are production-grade versions of the exact pieces you wrote, which is why understanding the small version makes the big one easy to debug.
