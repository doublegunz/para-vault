---
title: "Speed Up Your Laravel App with Http::pool(): Run Multiple HTTP Requests Concurrently"
slug: "speed-up-your-laravel-app-with-httppool-run-multiple-http-requests-concurrently"
category: "Laravel"
date: "2026-05-16"
status: "published"
---

Every modern web application eventually reaches the same inflection point: a page that needs data from more than one source. A dashboard that pulls users from one service, products from another, and posts from a third. A checkout page that verifies inventory, fetches shipping rates, and checks a fraud score simultaneously. The naive implementation calls each source one by one, waits for the first to respond before asking the second, and waits for the second before asking the third.

If each of those requests takes 300ms, that is 900ms of wall-clock time spent waiting. Not processing. Not rendering. Just waiting. The frustrating part is that none of those requests actually depend on each other. The products endpoint does not need the users response to do its job. They could all start at the exact same moment.

`Http::pool()` is Laravel's built-in answer to this problem. It dispatches every request simultaneously, waits for all of them to finish, and returns the responses together. Three 300ms requests become roughly 300ms total, not 900ms. This tutorial proves that difference in Tinker with real numbers, then builds a controller and view that puts it to practical use.

## Overview {#overview}

This article uses three public testing APIs throughout: `dummyjson.com` for user and product data, and `jsonplaceholder.typicode.com` for posts. Each service runs on a different server, which means concurrent requests to them genuinely execute in parallel and produce a measurable timing difference.

### What You'll Build

- A Tinker session that proves the sequential-versus-concurrent timing difference with real measured numbers against three different public APIs.
- A `DashboardController` that uses `Http::pool()` to fetch users, products, and posts simultaneously, with named responses, error handling, and per-request options.
- A standalone Tailwind CSS dashboard view that displays the fetched data alongside an elapsed time badge.

### What You'll Learn

- How to use `Http::pool()` to dispatch multiple HTTP requests concurrently.
- How to name pooled responses with `->as()` for readable key-based access.
- How to apply per-request options like timeouts, headers, and tokens inside a pool.
- How to handle failures within a pool correctly, including the `ConnectionException` case that catches many developers off guard.

### What You'll Need

- PHP 8.3 or higher.
- Laravel 13 with Composer installed globally.
- An internet connection (required for the public API requests).
- Basic familiarity with Laravel routing and controllers.

## Step 1: Create a New Laravel Project {#step-1-create-project}

Start by creating a fresh Laravel 13 project. The `--no-interaction` flag skips the setup wizard and accepts all defaults, while `--pest` installs Pest as the testing framework and `--no-boost` skips Laravel Cloud Boost, which is not needed here:

```bash
laravel new pool-demo --no-interaction --database=sqlite --pest --no-boost
cd pool-demo
```

Unlike the typical API tutorial, you do not need to run `php artisan install:api` here because you are not building your own API routes. All HTTP requests in this tutorial go outbound to public testing services, so the default `routes/web.php` is all you need.

Confirm the project boots cleanly by starting the development server:

```bash
php artisan serve
```

Visit `http://127.0.0.1:8000` and confirm the default Laravel welcome page loads. Leave the server running in this terminal tab for later steps.

## Step 2: Prove the Difference in Tinker {#step-2-tinker-proof}

Before writing any controller code, it is worth proving the timing difference directly in Artisan Tinker. Seeing real numbers from your own machine is more convincing than any benchmark screenshot, and it gives you an intuition for the magnitude of the improvement before you build on top of it.

Open a new terminal tab in the same project directory and launch Tinker:

```bash
php artisan tinker
```

### The Sequential Baseline

Run this code first. It calls three different public APIs one after the other, waiting for each to respond before starting the next:

```php
use Illuminate\Support\Facades\Http;

$start = microtime(true);

Http::get('https://dummyjson.com/users?limit=6');
Http::get('https://dummyjson.com/products?limit=5');
Http::get('https://jsonplaceholder.typicode.com/posts?_limit=5');

$elapsed = (int) round((microtime(true) - $start) * 1000);
"Sequential: {$elapsed}ms"
```

`microtime(true)` returns the current Unix timestamp as a float with microsecond precision. Subtracting the start time from the end time gives elapsed seconds as a decimal, and multiplying by 1000 converts that to milliseconds. Rather than using `echo`, evaluating the string directly lets PsySH pretty-print the result for you. You should see output close to this:

```
= "Sequential: 1247ms"
```

Three API calls to three different servers, each taking roughly 300 to 500ms, executed one after another. The total time is the sum of all three waits.

### The Pooled Version

Now run the `Http::pool()` version. The structure looks different, but the intent is the same: fetch from the same three endpoints:

```php
use Illuminate\Http\Client\Pool;

$start = microtime(true);

Http::pool(fn (Pool $pool) => [
    $pool->get('https://dummyjson.com/users?limit=6'),
    $pool->get('https://dummyjson.com/products?limit=5'),
    $pool->get('https://jsonplaceholder.typicode.com/posts?_limit=5'),
]);

$elapsed = (int) round((microtime(true) - $start) * 1000);
"Pooled: {$elapsed}ms"
```

```
= "Pooled: 489ms"
```

Three requests sent simultaneously, and the total time is close to the slowest single response rather than the sum of all three. The three requests ran concurrently, and PHP waited for all of them to finish at once rather than waiting for each one in turn.

Notice also that if you look at the array Tinker prints from `Http::pool()`, the keys are not always in the order `0, 1, 2`. They arrive in the order the servers responded, which is direct evidence that the requests were genuinely in flight at the same time rather than queued one after another.

This is the core insight to carry into the rest of the tutorial: `Http::pool()` does not make individual requests faster. Each external server still took the same amount of time to respond. What changed is that all three waits happened simultaneously rather than one after another.

## Step 3: Build a Real Controller with Http::pool() {#step-3-controller}

With the timing proof in hand, it is time to build something more realistic. You will create a `DashboardController` that fetches from three different public APIs, each of which returns a different shape of data, simulating what a real dashboard does when it aggregates from multiple services.

The three services you will use are: `https://dummyjson.com/users?limit=6` simulates a user management service and returns six users with names, emails, and avatar URLs; `https://dummyjson.com/products?limit=5` simulates a product catalog service and returns five products with titles, prices, and stock levels; `https://jsonplaceholder.typicode.com/posts?_limit=5` simulates a content or blog service and returns five posts with titles and body text.

Create the controller:

```bash
php artisan make:controller DashboardController
```

Open `app/Http/Controllers/DashboardController.php` and replace its contents with the following:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\Pool;
use Illuminate\Support\Facades\Http;

class DashboardController extends Controller
{
    public function index(): \Illuminate\View\View
    {
        // Record the start time before any HTTP work begins.
        $start = microtime(true);

        // Http::pool() accepts a closure that receives a Pool instance.
        // The closure must return an array of request definitions.
        // Laravel collects every item in that array, hands them all to
        // Guzzle's cURL multi handler at once, and waits for every
        // request to complete before returning the $responses array.
        $responses = Http::pool(fn (Pool $pool) => [

            // ->as('key') gives each response a name so you can access
            // it by key instead of by numeric index ($responses[0], etc.).
            // Named access is far easier to read when the pool grows larger.
            $pool->as('users')
                 ->timeout(5)                               // abandon this request if it takes longer than 5s
                 ->withHeaders(['X-Client' => 'pool-demo']) // per-request header, applied individually per request
                 ->get('https://dummyjson.com/users?limit=6'),

            $pool->as('products')
                 ->timeout(5)
                 ->get('https://dummyjson.com/products?limit=5'),

            $pool->as('posts')
                 ->timeout(5)
                 ->get('https://jsonplaceholder.typicode.com/posts?_limit=5'),
        ]);

        // Calculate elapsed time before doing anything else.
        $elapsed = (int) round((microtime(true) - $start) * 1000);

        // Each response must be checked before accessing its data.
        // When a request inside a pool fails or times out, its slot in
        // $responses holds a ConnectionException instance, not a Response
        // object. Calling ->successful() on a ConnectionException causes
        // a fatal error, so you must check instanceof first.
        $users    = $this->resolveResponse($responses['users']);
        $products = $this->resolveResponse($responses['products']);
        $posts    = $this->resolveResponse($responses['posts']);

        return view('dashboard', compact('users', 'products', 'posts', 'elapsed'));
    }

    // A small private helper that handles both the ConnectionException case
    // and the unsuccessful HTTP status case in one place, keeping index() clean.
    private function resolveResponse(mixed $response): array|null
    {
        // If the connection failed entirely (timeout, DNS failure, etc.),
        // the response slot holds a ConnectionException. Return null so
        // the view can display a graceful "unavailable" message.
        if ($response instanceof ConnectionException) {
            return null;
        }

        // ->successful() returns true for any 2xx status code.
        // For non-2xx responses (404, 500, etc.), return null as well.
        return $response->successful() ? $response->json() : null;
    }
}
```

There is one constraint about `Http::pool()` that is worth understanding before moving on. You cannot chain global options directly onto the `Http::pool()` call itself. Code like this does not work:

```php
// This will NOT work. pool() cannot be pre-configured with withToken() or withHeaders().
Http::withToken($token)->pool(fn (Pool $pool) => [
    $pool->as('users')->get('...'),
]);
```

The reason is architectural. `Http::withToken()` returns a `PendingRequest` instance configured with those options. But `pool()` needs to build multiple independent requests, and a single `PendingRequest` cannot branch into several different outbound connections. The solution is to apply options to each request individually inside the closure, as shown above with `->timeout(5)` and `->withHeaders()`. This is actually more flexible in practice, because it means different requests in the same pool can carry different credentials, different timeouts, or different headers.

Now register the route. Open `routes/web.php` and add:

```php
<?php

use App\Http\Controllers\DashboardController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/dashboard', [DashboardController::class, 'index']);
```

## Step 4: Create the Dashboard View {#step-4-view}

Create the view at `resources/views/dashboard.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard — Http::pool() Demo</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-7xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">

        {{-- Header --}}
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-8 gap-4">
            <div>
                <h1 class="text-2xl font-bold text-gray-900">Http::pool() Dashboard</h1>
                <p class="text-gray-500 mt-1 text-sm">
                    Three concurrent requests to three different APIs via Http::pool()
                </p>
            </div>

            {{-- Elapsed time badge --}}
            <div class="flex items-center gap-2 bg-green-100 text-green-800 px-4 py-2 rounded-full text-sm font-bold self-start sm:self-auto">
                <span>⏱</span>
                <span>{{ $elapsed }}ms total</span>
            </div>
        </div>

        {{-- Explanation bar --}}
        <div class="bg-blue-50 border border-blue-200 rounded-lg px-4 py-3 mb-8 text-sm text-blue-800">
            Three requests to three different servers dispatched simultaneously.
            Total time equals the slowest response, not the sum of all three.
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

            {{-- Users card (dummyjson.com) --}}
            <div class="bg-gray-50 rounded-xl p-5">
                <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
                    Users
                    <span class="text-xs font-normal normal-case text-gray-400">(dummyjson.com)</span>
                </h2>

                @if($users && isset($users['users']))
                    <div class="space-y-2">
                        @foreach($users['users'] as $user)
                            <div class="flex items-center gap-3 bg-white rounded-lg px-3 py-2 border border-gray-200">
                                <img src="{{ $user['image'] }}" alt="{{ $user['firstName'] }}"
                                     class="w-8 h-8 rounded-full object-cover flex-shrink-0">
                                <div class="min-w-0">
                                    <p class="text-sm font-medium text-gray-800 truncate">
                                        {{ $user['firstName'] }} {{ $user['lastName'] }}
                                    </p>
                                    <p class="text-xs text-gray-400 truncate">{{ $user['email'] }}</p>
                                </div>
                            </div>
                        @endforeach
                    </div>
                    <p class="text-xs text-gray-400 mt-3">
                        Total: {{ $users['total'] }} users
                    </p>
                @else
                    <p class="text-sm text-red-500">Service unavailable.</p>
                @endif
            </div>

            {{-- Products card (dummyjson.com) --}}
            <div class="bg-gray-50 rounded-xl p-5">
                <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
                    Products
                    <span class="text-xs font-normal normal-case text-gray-400">(dummyjson.com)</span>
                </h2>

                @if($products && isset($products['products']))
                    <div class="space-y-2">
                        @foreach($products['products'] as $product)
                            <div class="flex items-center justify-between bg-white rounded-lg px-3 py-2 border border-gray-200">
                                <div class="min-w-0 pr-3">
                                    <p class="text-sm font-medium text-gray-800 truncate">{{ $product['title'] }}</p>
                                    <p class="text-xs text-gray-400 mt-0.5">Stock: {{ $product['stock'] }}</p>
                                </div>
                                <span class="text-sm font-bold text-gray-700 flex-shrink-0">
                                    ${{ number_format($product['price'], 2) }}
                                </span>
                            </div>
                        @endforeach
                    </div>
                    <p class="text-xs text-gray-400 mt-3">
                        Showing 5 of {{ $products['total'] }} total products
                    </p>
                @else
                    <p class="text-sm text-red-500">Service unavailable.</p>
                @endif
            </div>

            {{-- Posts card (jsonplaceholder.typicode.com) --}}
            <div class="bg-gray-50 rounded-xl p-5">
                <h2 class="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-3">
                    Posts
                    <span class="text-xs font-normal normal-case text-gray-400">(jsonplaceholder.typicode.com)</span>
                </h2>

                @if($posts)
                    <div class="space-y-2">
                        @foreach($posts as $post)
                            <div class="bg-white rounded-lg px-3 py-2 border border-gray-200">
                                <p class="text-sm font-medium text-gray-800 leading-snug">
                                    {{ \Str::title($post['title']) }}
                                </p>
                                <p class="text-xs text-gray-400 mt-1 leading-relaxed">
                                    {{ \Str::limit($post['body'], 60) }}
                                </p>
                            </div>
                        @endforeach
                    </div>
                @else
                    <p class="text-sm text-red-500">Service unavailable.</p>
                @endif
            </div>

        </div>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Http::pool() at qadrlabs.com</a>
        </div>

    </div>
</body>
</html>
```

The three columns each display a different data shape: users with avatars and emails from dummyjson.com, products with prices and stock levels also from dummyjson.com, and post titles with truncated body text from jsonplaceholder. Using two endpoints from the same provider for users and products is fine here because they are separate endpoints on separate paths, and the pool dispatches them concurrently just like it would to entirely different domains.

## Step 5: Handle Errors and Per-Request Options {#step-5-errors-options}

The `resolveResponse()` helper in the controller already handles the two most common failure modes. It is worth examining both in detail so you understand when each one occurs and why the order of checks matters.

### The ConnectionException Case

When a request inside a pool fails at the network level, whether due to a timeout, a DNS failure, or a refused connection, its slot in the `$responses` array is populated with a `ConnectionException` instance rather than a `Response` object. This is the behavior that surprises most developers the first time they encounter it, because synchronous `Http::get()` calls throw `ConnectionException` as an exception that propagates up the call stack. Inside a pool, the exception is caught internally and stored as the "response" for that slot so the other requests are not interrupted.

The consequence is that you cannot safely call `->successful()` on every item in `$responses` without checking first. `ConnectionException` does not have a `->successful()` method, and calling it will cause a fatal error. The correct pattern is always to check `instanceof ConnectionException` before anything else:

```php
// Always check for ConnectionException before calling any Response methods.
if ($response instanceof ConnectionException) {
    // Log the error, return a fallback, or surface a user-facing message.
    logger()->error('Pool request failed: ' . $response->getMessage());
    return null;
}
```

### The Failed HTTP Status Case

The second failure mode is a successful connection that returns a non-2xx status code: a 404, a 429 rate limit response, or a 503 from an overloaded service. In this case, the slot holds a normal `Response` object, but `->successful()` returns `false`. The `resolveResponse()` helper handles this with the `$response->successful() ? $response->json() : null` check after the `instanceof` guard.

### Per-Request Timeout

The `->timeout(5)` call on each request in the pool sets an upper bound on how long that specific request is allowed to wait. Without a timeout, a single slow or hung endpoint can hold the entire pool indefinitely, because `Http::pool()` waits for every request to finish before returning. A per-request timeout means the pool gives up on that request after the threshold and populates its slot with a `ConnectionException`, so the rest of the responses are still returned.

This also illustrates the key architectural difference between `Http::pool()` and a sequential approach when it comes to failures. In sequential code, if the first request hangs for 30 seconds, the user waits 30 seconds before the second request even starts. In a pool, if one request hangs, only that slot's timeout determines how long everyone waits. The other requests may have finished in 200ms and their responses are ready to use.

## Step 6: Try It Out {#step-6-try-it-out}

Make sure `php artisan serve` is still running in your first terminal tab, then open your browser and visit:

```
http://127.0.0.1:8000/dashboard
```

You should see the dashboard render with all three columns populated and a green timing badge in the top right. The elapsed time will typically land between 400ms and 800ms depending on your connection and the current load on each public API. Reload the page a few times and you will notice the badge fluctuates slightly, which reflects natural variance in network latency to three different servers.

To make the comparison concrete, recall the Tinker numbers from Step 2. Sequential execution of the same three requests took roughly 1247ms on the same network. The pooled dashboard renders in roughly 489ms. The gap is not as dramatic as with artificial one-second delays, but it is consistent and significant, and it scales with the number of requests you add to the pool.

If one of the three services is temporarily unreachable when you load the page, you will see "Service unavailable." in that card while the other two render normally. This is the `resolveResponse()` helper at work, making the dashboard resilient to partial failures rather than crashing the entire page.

## How Http::pool() Works Under the Hood {#how-it-works}

Understanding the mechanism behind `Http::pool()` helps you use it correctly and recognize the situations where it is and is not the right tool.

### Guzzle Promises and the cURL Multi Handler

Laravel's HTTP client is a fluent wrapper around Guzzle, and Guzzle in turn is built on PHP's cURL extension. When you call `Http::get()` in the normal synchronous way, PHP opens a single cURL handle, sends the request, and blocks the current process until the response arrives. Nothing else can happen in that process during the wait.

`Http::pool()` uses a different mode called `curl_multi`. Instead of blocking on one request, `curl_multi` registers all requests with the operating system as concurrent network operations. The OS manages the actual I/O, sending all requests onto the wire simultaneously, and PHP polls for completed responses in a tight loop. As soon as all responses are ready, `Http::pool()` collects them and returns the array.

Guzzle exposes this mechanism through its Promise system. Each request in the pool is represented internally as a Promise object, which is a lightweight placeholder for a future value. The Promises are all handed to `curl_multi` together, and when a response arrives, its Promise is resolved with the response data. `Http::pool()` waits for every Promise to resolve before assembling and returning the `$responses` array you work with in your controller.

### Why Total Time Equals the Slowest Request

Because all requests start at the same moment, the elapsed time is determined entirely by whichever request finishes last. If your pool contains three requests that take 200ms, 400ms, and 800ms respectively, the pool returns after roughly 800ms. The 200ms and 400ms responses have been sitting in memory since long before that, waiting for the 800ms one to arrive.

This is both the power of the approach and its one important caveat. A single slow or unresponsive endpoint in your pool acts as a bottleneck for all the responses. Per-request timeouts are your primary defense: by setting `->timeout(5)`, you ensure that no single request can hold the pool for more than five seconds, and a failed connection becomes a `ConnectionException` in that slot rather than an indefinite hang.

### When Not to Use Http::pool()

`Http::pool()` is designed for requests that are independent of each other. If request B needs data from the response of request A, they cannot be pooled, because you do not have A's response yet when you need to construct B. In that case, run A synchronously first, use its data to build B, and then optionally pool B alongside other unrelated requests.

The same logic applies to requests where the order of side effects matters. Creating a resource in one API and then immediately referencing its generated ID in a second API call requires sequential execution. Pooling them would mean both requests fire before either response is available, which means the second request cannot include data that only exists in the first response.

A useful mental test before reaching for `Http::pool()`: ask whether you could shuffle the requests into any order, or even run them on different machines, and still get the same result. If the answer is yes, they are good candidates for a pool. If the answer is no, sequential execution is the correct and safe choice.

## Conclusion {#conclusion}

You have proven the timing difference in Tinker, built a controller that uses `Http::pool()` against real public APIs, and learned the error-handling patterns that make pooled requests safe in production. Here are the key things to carry forward.

- **`Http::pool()` dispatches all requests simultaneously.** The total elapsed time equals the slowest request in the group, not the sum of all of them, because all requests are in flight at the same time rather than waiting for each other.
- **Name your responses with `->as()`.** Accessing pooled results by key (`$responses['users']`) is far more readable and resilient to reordering than accessing by numeric index (`$responses[0]`).
- **`Http::pool()` cannot be globally pre-configured.** You cannot chain `withToken()` or `withHeaders()` onto the `Http::pool()` call itself. Apply those options to each individual request inside the closure, which is actually more flexible since different requests can carry different credentials.
- **Always check `instanceof ConnectionException` before calling `->successful()`.** When a request inside a pool fails at the network level, its slot holds a `ConnectionException` instance, not a `Response` object. Calling `->successful()` on it causes a fatal error. The `instanceof` check must come first.
- **Set per-request timeouts with `->timeout()`.** Without timeouts, a single hung endpoint holds the entire pool indefinitely. A timeout converts the hang into a `ConnectionException` after the threshold, so the rest of your responses are still returned.
- **Only pool independent requests.** If one request depends on the output of another, those two must remain sequential. Pool them only alongside other requests that are genuinely unrelated to each other.
- **`php artisan serve` is single-threaded.** Calling your own app's endpoints from inside a pool during local development will not show the timing benefit because the server handles requests one at a time. The improvement is fully realized when calling external services or when running under Nginx with PHP-FPM in production.