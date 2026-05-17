---
title: "Laravel Throttle Middleware and the RateLimiter Facade: A Practical Guide"
slug: "laravel-throttle-middleware-and-the-ratelimiter-facade-a-practical-guide"
category: "Laravel"
date: "2026-05-01"
status: "published"
---

A while back, we published a tutorial on [building a rate limiter from scratch in plain PHP](https://qadrlabs.com/post/build-a-rate-limiter-from-scratch-in-php-fixed-window-and-token-bucket), walking through Fixed Window and Token Bucket algorithms line by line. Someone in the comments made a point that stuck with us: *"Or just use throttle middleware in Laravel."* That observation is completely valid, and it is actually the right call for production applications. It also inspired a natural follow-up question: what does that throttle middleware actually do, and how do you use it properly across different scenarios?

This tutorial answers both. We will build a Quote API in Laravel 13 that demonstrates three distinct approaches to rate limiting, from the simplest one-liner on a route all the way to fine-grained manual control inside a controller. By the end, you will know not just how to apply `throttle:60,1`, but when to use each tool in Laravel's rate limiting system and what is happening underneath when you do.

## Overview {#overview}

This is a standalone Laravel 13 project. No prior tutorials in this series are required, though reading the [plain PHP rate limiter article](https://qadrlabs.com/post/build-a-rate-limiter-from-scratch-in-php-fixed-window-and-token-bucket) will give you a useful mental model for what Laravel is doing under the hood.

### What You'll Build

- A Quote API with three rate limiting layers: a simple route-level throttle for anonymous users, a named limiter with dynamic per-tier limits for authenticated users, and a manual `RateLimiter::attempt()` call inside a controller for write actions
- Pest tests covering anonymous limits, per-tier authenticated limits, per-user write limits, 429 headers, and counter reset behavior
- A custom 429 response so clients receive a useful message instead of a bare HTTP error

### What You'll Learn

- The difference between `throttle:x,y`, named limiters, and manual `RateLimiter` facade usage, and when each is the right tool
- How to define dynamic rate limits based on user attributes such as subscription tier
- How to use `RateLimiter::attempt()`, `availableIn()`, and `clear()` directly inside controller logic
- How to write Pest tests that verify rate limiting behavior without depending on real time passing
- How Laravel's throttle system maps to the Token Bucket concept from the plain PHP implementation

### What You'll Need

- PHP 8.3 or higher
- Laravel 13
- Pest (installed automatically via the `--pest` flag during project creation)
- Comfortable with Laravel routing, middleware, and service providers

## Step 1: Project Setup {#step-1-project-setup}

Create a fresh Laravel 13 application. The `--database=sqlite` flag configures SQLite as the default database so you do not need a running MySQL or PostgreSQL instance for this tutorial. The `--pest` flag installs Pest as the test runner automatically during project creation, so no separate installation step is needed. The `--no-boost` flag skips optional performance packages that are not relevant here:

```bash
laravel new quote-api --database=sqlite --pest --no-boost
cd quote-api
```

Install the API scaffold, which creates `routes/api.php` and configures Sanctum for token-based authentication:

```bash
php artisan install:api
```

The `User` model needs a `plan` column so we can differentiate between free and premium users. Create the migration:

```bash
php artisan make:migration add_plan_to_users_table --table=users
```

Open the generated migration file and add the column:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // 'free' and 'premium' are the two tiers we will rate limit differently
            $table->string('plan')->default('free')->after('email');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('plan');
        });
    }
};
```

Add the `plan` field to the `User` model. Open `app/Models/User.php` and update the fillable attribute:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'plan'])]
class User extends Authenticatable
{
    use HasApiTokens;

    // ... rest of the model
}
```

Create a seeder with two test users, one free and one premium:

```bash
php artisan make:seeder UserSeeder
```

Open `database/seeders/UserSeeder.php`:

```php
<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        User::create([
            'name'     => 'Free User',
            'email'    => 'free@example.com',
            'password' => Hash::make('password'),
            'plan'     => 'free',
        ]);

        User::create([
            'name'     => 'Premium User',
            'email'    => 'premium@example.com',
            'password' => Hash::make('password'),
            'plan'     => 'premium',
        ]);
    }
}
```

Run the migrations and seed:

```bash
php artisan migrate --seed --seeder=UserSeeder
```

## Step 2: Create the Quote Controller and Routes {#step-2-controller-routes}

The Quote API has two endpoints: a read endpoint that lists quotes and a write endpoint that allows authenticated users to add a quote. At this step, we build them without any rate limiting so we can verify they work before layering on the limits.

Create the controller:

```bash
php artisan make:controller QuoteController
```

Open `app/Http/Controllers/QuoteController.php`:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;

class QuoteController extends Controller
{
    // A static list standing in for a database table
    private array $quotes = [
        ['id' => 1, 'text' => 'The only way to do great work is to love what you do.'],
        ['id' => 2, 'text' => 'In the middle of every difficulty lies opportunity.'],
        ['id' => 3, 'text' => 'It does not matter how slowly you go as long as you do not stop.'],
        ['id' => 4, 'text' => 'Everything you have ever wanted is on the other side of fear.'],
        ['id' => 5, 'text' => 'Success is not final, failure is not fatal.'],
    ];

    /**
     * Return the list of quotes.
     * Available to both anonymous and authenticated users.
     * Rate limiting is applied at the route level via middleware.
     */
    public function index(): JsonResponse
    {
        return response()->json([
            'data' => $this->quotes,
        ]);
    }

    /**
     * Add a new quote (authenticated users only).
     * Rate limiting here is applied manually inside the method
     * using the RateLimiter facade, which gives us access to
     * business logic context that middleware cannot reach.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate(['text' => 'required|string|max:500']);

        // Build a key that is unique per user, not per IP.
        // This means the limit applies to the user's account,
        // not to the device or network they are connecting from.
        $key = 'quote-store:' . $request->user()->id;

        // Allow 5 write actions per day (86400 seconds).
        // The closure runs only when an attempt slot is available.
        $executed = RateLimiter::attempt(
            key: $key,
            maxAttempts: 5,
            callback: function () {},
            decaySeconds: 86400
        );

        if (! $executed) {
            $availableIn = RateLimiter::availableIn($key);

            return response()->json([
                'message'     => 'You have reached your daily quote submission limit.',
                'retry_after' => $availableIn . ' seconds',
            ], 429);
        }

        // In a real application this would persist to a database
        return response()->json([
            'message' => 'Quote submitted successfully.',
            'data'    => ['text' => $request->input('text')],
        ], 201);
    }
}
```

Open `routes/api.php` and define the routes. We set up three groups deliberately, one per limiting strategy:

```php
<?php

use App\Http\Controllers\QuoteController;
use Illuminate\Support\Facades\Route;

// Group 1: Anonymous access with a simple route-level throttle.
// throttle:10,1 means 10 requests per 1 minute, keyed by IP.
Route::middleware('throttle:10,1')
    ->get('/quotes', [QuoteController::class, 'index'])
    ->name('quotes.index.anonymous');

// Group 2: Authenticated access with a named limiter.
// The 'quotes' limiter is defined in AppServiceProvider and
// returns different limits based on the user's plan.
Route::middleware(['auth:sanctum', 'throttle:quotes'])
    ->get('/quotes/me', [QuoteController::class, 'index'])
    ->name('quotes.index.authenticated');

// Group 3: Authenticated write action.
// Rate limiting is handled manually inside the controller method
// using RateLimiter::attempt(), so no throttle middleware here.
Route::middleware('auth:sanctum')
    ->post('/quotes', [QuoteController::class, 'store'])
    ->name('quotes.store');
```

Start the development server and confirm both endpoints return a 200:

```bash
php artisan serve
```

```bash
curl http://localhost:8000/api/quotes
```

```json
{
    "data": [
        {"id": 1, "text": "The only way to do great work is to love what you do."},
        ...
    ]
}
```

The routes are working. Now we add the rate limiting layers one by one.

## Step 3: Apply Route-Level Throttle for Anonymous Users {#step-3-route-level-throttle}

The `throttle:10,1` middleware we already added to the anonymous route is the simplest form of rate limiting Laravel offers. The format is `throttle:maxAttempts,decayMinutes`. It reads the client's IP address as the identifier and stores the counter in the default cache driver. There is no additional code to write for this step: the middleware string on the route in Step 2 is all that is needed.

To verify the headers Laravel attaches to every response, make sure the development server is running and send a single request with the `-i` flag to include response headers in the output:

```bash
curl -i http://localhost:8000/api/quotes
```

Expected output (trimmed to the relevant headers):

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 9
X-RateLimit-Reset: 1746088597
Content-Type: application/json
```

Send the request nine more times and the eleventh call will return a 429:

```
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1746088597
Retry-After: 47
```

These are the same headers we built by hand in the plain PHP article. Laravel constructs them from the same information: the configured limit, the current counter, the window reset timestamp, and the seconds until the next slot is available.

The `throttle:10,1` shorthand works well for public-facing read endpoints where the limit is the same for everyone and you do not need per-user awareness. As soon as the limit should vary by who is making the request, a named limiter is the right tool.

## Step 4: Define a Named Rate Limiter in AppServiceProvider {#step-4-named-limiter}

A named limiter is a rate limit configuration registered under a string identifier. The throttle middleware references that name, and when a request comes in, Laravel evaluates the closure to determine the actual limit for that specific request. This is where dynamic, context-aware limiting becomes possible.

Open `app/Providers/AppServiceProvider.php` and add the named limiter to the `boot()` method:

```php
<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void {}

    public function boot(): void
    {
        $this->configureRateLimiters();
    }

    private function configureRateLimiters(): void
    {
        RateLimiter::for('quotes', function (Request $request) {
            $user = $request->user();

            // Anonymous users fall through to the simple throttle on the other route,
            // but if somehow they reach this named limiter, apply a strict limit.
            if (! $user) {
                return Limit::perMinute(10)->by($request->ip());
            }

            // Premium users get a generous limit keyed by their user ID,
            // so their limit is per-account rather than per-IP.
            if ($user->plan === 'premium') {
                return Limit::perMinute(200)->by($user->id);
            }

            // Free authenticated users get 30 requests per minute.
            return Limit::perMinute(30)->by($user->id);
        });
    }
}
```

Three important things to notice here. First, the closure receives the full `Request` object, which means you can access the authenticated user, query parameters, request body, or any other context to determine the limit. Second, the `by()` method sets the cache key suffix. Using `$user->id` instead of `$request->ip()` means the limit follows the account, not the network. Third, returning a different `Limit` object from the same closure is all it takes to produce three completely different behaviors from a single `throttle:quotes` middleware string.

The route in `routes/api.php` already has `throttle:quotes` applied to the authenticated read endpoint from Step 2, so no route changes are needed. To verify the named limiter is working correctly, you need a Sanctum token for each test user. Open Tinker to generate one:

```bash
php artisan tinker
```

Tinker is an interactive PHP shell. Run each line separately so you can see the output before proceeding to the next. First, load the premium user:

```
> $user = \App\Models\User::where('email', 'premium@example.com')->first();

= App\Models\User {#8127
    id: 2,
    name: "Premium User",
    email: "premium@example.com",
    plan: "premium",
    ...
  }
```

Then create a token:

```
> $token = $user->createToken('test')->plainTextToken;

= "2|NzAJqh2Yvq3g0ZWM8469kIQplmIpQF7vvm2i9eiMb222150f"
```

Then print it so you can copy it:

```
> echo $token;

2|NzAJqh2Yvq3g0ZWM8469kIQplmIpQF7vvm2i9eiMb222150f
```

Exit Tinker with `Ctrl+D` or by typing `exit`, then use the token in the curl request. Replace the value after `Bearer` with the token you just copied:

```bash
curl -i -H "Authorization: Bearer 2|NzAJqh2Yvq3g0ZWM8469kIQplmIpQF7vvm2i9eiMb222150f" \
  http://localhost:8000/api/quotes/me
```

The response headers should now show `X-RateLimit-Limit: 200` for the premium user. Repeat the process for `free@example.com` and you will see `X-RateLimit-Limit: 30`, confirming the named limiter is reading the `plan` attribute and returning a different limit per user.

## Step 5: Use the RateLimiter Facade Manually in the Controller {#step-5-manual-facade}

The `store()` method in `QuoteController` already contains the manual `RateLimiter::attempt()` call from Step 2. There is no new code to write here. This step explains in detail what that code is doing and why the facade is the right tool for write actions specifically, so the reasoning is clear before you reach the tests in Step 7.

The reason `throttle` middleware is not appropriate here is subtle but real. Middleware runs before the controller, which means it cannot see the result of validation or any business logic inside the method. If you want to limit based on information that only exists after the request has been processed, or if the "what counts as an attempt" is business-specific (like "5 write operations per day per account"), the facade gives you that control.

The key methods available directly on the `RateLimiter` facade cover every interaction pattern you might need:

```php
// Check if the key is over its limit without consuming an attempt
RateLimiter::tooManyAttempts('quote-store:' . $user->id, $maxAttempts = 5);

// Manually increment the counter by one (or more via the amount parameter)
RateLimiter::increment('quote-store:' . $user->id);
RateLimiter::increment('quote-store:' . $user->id, amount: 2);

// Check how many attempts remain before the limit is hit
RateLimiter::remaining('quote-store:' . $user->id, $maxAttempts = 5);

// Get seconds until the rate limit resets for a given key
RateLimiter::availableIn('quote-store:' . $user->id);

// Reset the counter for a key entirely, useful after a successful operation
// clears a transient lockout (for example, after a successful login)
RateLimiter::clear('quote-store:' . $user->id);
```

In the `store()` method, `attempt()` combines the increment and the callback into a single call. If an attempt slot is available, it increments the counter and calls the closure. If no slots remain, it returns `false` without calling the closure, and `availableIn()` tells us exactly how many seconds until the window resets so we can include that in the response body.

## Step 6: Customize the 429 Response {#step-6-custom-429}

By default, when the throttle middleware blocks a request it returns a plain 429 with the standard rate limit headers but no JSON body. For an API, it is better to return a structured JSON body alongside those headers so clients can parse the error programmatically without inspecting the status code alone.

The cleanest place to do this is inside the named limiter definition using the `->response()` callback. This approach lets you customize the response per limiter, which means the message can be context-specific. Update `configureRateLimiters()` in `AppServiceProvider` to add the callback. The `$headers` array passed to the closure already contains the standard `X-RateLimit-*` and `Retry-After` headers, so you pass them through to the response to make sure clients still receive them:

```php
private function configureRateLimiters(): void
{
    RateLimiter::for('quotes', function (Request $request) {
        $user = $request->user();

        $limit = match(true) {
            $user?->plan === 'premium' => Limit::perMinute(200)->by($user->id),
            $user !== null             => Limit::perMinute(30)->by($user->id),
            default                    => Limit::perMinute(10)->by($request->ip()),
        };

        // Attach a JSON response that will be returned when this limiter blocks a request.
        // The $headers array contains the standard X-RateLimit-* and Retry-After headers,
        // which we merge into the response so clients still receive them.
        return $limit->response(function (Request $request, array $headers) {
            return response()->json([
                'message'     => 'Too many requests. Please slow down.',
                'retry_after' => $headers['Retry-After'] ?? null,
            ], 429, $headers);
        });
    });
}
```

If you need a uniform 429 format across every route in the application rather than per limiter, an alternative is to register a global exception handler in `bootstrap/app.php` that catches `ThrottleRequestsException`. That approach is useful when you have many named limiters and do not want to attach a `->response()` callback to each one individually. For this tutorial, the per-limiter callback is sufficient and more explicit about which limiter produced the response.

## Step 7: Write Pest Tests {#step-7-pest-tests}

Rate limiting tests have one challenge: they depend on cache state. A counter left over from one test will cause the next test to see a different starting point, leading to false failures. The cleanest fix is to call `Cache::flush()` in `beforeEach`, which clears the entire cache before each test runs. This is safe in a test environment because the test database is also reset by `RefreshDatabase`, so there is no risk of clearing data you want to keep. Clearing only specific keys with `RateLimiter::clear()` is insufficient here because the throttle middleware stores its keys under an internal naming convention that differs from the keys used by the manual facade calls.

Create the test file:

```bash
php artisan make:test QuoteRateLimitTest --pest
```

Open `tests/Feature/QuoteRateLimitTest.php`:

```php
<?php

use App\Models\User;
use Illuminate\Support\Facades\Cache;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

beforeEach(function () {
    // Flush the entire cache before each test.
    // This resets both throttle middleware counters (keyed internally by Laravel)
    // and manual RateLimiter facade counters (keyed by our own strings).
    // Partial clears with RateLimiter::clear() are not sufficient because
    // the throttle middleware uses its own key format under the hood.
    Cache::flush();
});

it('allows anonymous users up to the route-level limit', function () {
    // The route-level throttle allows 10 requests per minute for anonymous users.
    // We send 10 requests and confirm all succeed.
    foreach (range(1, 10) as $i) {
        $response = $this->getJson('/api/quotes');
        $response->assertStatus(200);
    }

    // The 11th request should be blocked
    $this->getJson('/api/quotes')->assertStatus(429);
});

it('applies different limits to free and premium users', function () {
    $freeUser    = User::factory()->create(['plan' => 'free']);
    $premiumUser = User::factory()->create(['plan' => 'premium']);

    $freeToken    = $freeUser->createToken('test')->plainTextToken;
    $premiumToken = $premiumUser->createToken('test')->plainTextToken;

    // Exhaust the free user's 30-per-minute limit
    foreach (range(1, 30) as $i) {
        $this->withToken($freeToken)->getJson('/api/quotes/me')->assertStatus(200);
    }
    $this->withToken($freeToken)->getJson('/api/quotes/me')->assertStatus(429);

    // Clear the auth guard's cached user so the next request authenticates properly as the premium user
    app('auth')->forgetGuards();

    // The premium user's 200-per-minute limit should still have headroom.
    // We verify the next request succeeds rather than exhausting all 200.
    $this->withToken($premiumToken)->getJson('/api/quotes/me')->assertStatus(200);
});

it('blocks write actions after 5 submissions per day per user', function () {
    $user  = User::factory()->create(['plan' => 'free']);
    $token = $user->createToken('test')->plainTextToken;

    // 5 submissions should succeed
    foreach (range(1, 5) as $i) {
        $this->withToken($token)
            ->postJson('/api/quotes', ['text' => 'Quote number ' . $i])
            ->assertStatus(201);
    }

    // The 6th should be blocked with a 429
    $this->withToken($token)
        ->postJson('/api/quotes', ['text' => 'One too many'])
        ->assertStatus(429)
        ->assertJsonFragment(['message' => 'You have reached your daily quote submission limit.']);
});

it('includes a Retry-After value in the 429 response body for write actions', function () {
    $user  = User::factory()->create();
    $token = $user->createToken('test')->plainTextToken;

    // Exhaust the limit
    foreach (range(1, 5) as $i) {
        $this->withToken($token)->postJson('/api/quotes', ['text' => 'Quote ' . $i]);
    }

    $response = $this->withToken($token)
        ->postJson('/api/quotes', ['text' => 'Over limit'])
        ->assertStatus(429);

    // The response body should include a retry_after field with a non-zero value
    expect($response->json('retry_after'))->not->toBeNull();
});

it('resets the write counter after RateLimiter::clear is called', function () {
    $user  = User::factory()->create();
    $token = $user->createToken('test')->plainTextToken;

    // Exhaust the limit
    foreach (range(1, 5) as $i) {
        $this->withToken($token)->postJson('/api/quotes', ['text' => 'Quote ' . $i]);
    }

    // Confirm the limit is hit
    $this->withToken($token)
        ->postJson('/api/quotes', ['text' => 'Should fail'])
        ->assertStatus(429);

    // Reset the counter for this user
    RateLimiter::clear('quote-store:' . $user->id);

    // The next submission should succeed again
    $this->withToken($token)
        ->postJson('/api/quotes', ['text' => 'Should pass now'])
        ->assertStatus(201);
});
```

## Step 8: Try It Out {#step-8-try-it-out}

Run the full test suite:

```bash
php artisan test --filter=QuoteRateLimitTest
```

Expected output:

```
$ php artisan test --filter=QuoteRateLimitTest

   PASS  Tests\Feature\QuoteRateLimitTest
  ✓ it allows anonymous users up to the route-level limit                0.14s  
  ✓ it applies different limits to free and premium users                0.04s  
  ✓ it blocks write actions after 5 submissions per day per user         0.02s  
  ✓ it includes a Retry-After value in the 429 response body for write…  0.01s  
  ✓ it resets the write counter after RateLimiter::clear is called       0.01s  

  Tests:    5 passed (54 assertions)
  Duration: 0.27s

```

All five tests pass. To see the behavior live, generate tokens for both test users in Tinker and alternate requests between them against the authenticated endpoint. The headers will show `X-RateLimit-Limit: 30` for the free user and `X-RateLimit-Limit: 200` for the premium user, confirming the named limiter is reading the `plan` attribute and returning the correct limit per request.

## How Laravel's Throttle Works Under the Hood {#how-laravel-throttle-works}

If you read the [plain PHP rate limiter article](https://qadrlabs.com/post/build-a-rate-limiter-from-scratch-in-php-fixed-window-and-token-bucket), the mechanics of what Laravel is doing are already familiar. Laravel uses a Token Bucket approach internally. Each identity key maps to a bucket that holds a number of available attempts. When `ThrottleRequests` middleware runs, it calls the `RateLimiter` facade, which reads the current count from the cache, compares it against the limit, and either allows the request through or returns a 429.

The cache driver used is whatever your application's default cache is configured to use, typically the `file` driver in local development and `redis` in production. You can tell Laravel to use a specific driver for rate limiting without changing the global default by adding a `limiter` key to `config/cache.php`:

```php
'limiter' => env('RATE_LIMITER_CACHE', 'redis'),
```

The mapping between the facade methods and the plain PHP concepts is direct. `RateLimiter::attempt()` is consume-a-token. `RateLimiter::tooManyAttempts()` is bucket-is-empty check. `RateLimiter::remaining()` is current-token-count. `RateLimiter::availableIn()` is the Retry-After calculation. `RateLimiter::clear()` is a full bucket reset. Laravel wraps all of this in a cache-backed implementation so it works across multiple server processes and survives PHP process restarts, which is exactly what the `FileStorage` class in the plain PHP tutorial was designed to provide at a smaller scale.

## When to Use Each Approach {#when-to-use-each-approach}

Choosing between the three approaches in this tutorial comes down to where the limiting logic belongs and how much context it needs.

**`throttle:x,y` on a route** is the right starting point for any public-facing endpoint where the limit is flat and the same for all clients. It requires no configuration beyond the route definition, it applies before any controller code runs, and it handles headers and 429 responses automatically. Use it as the first line of defense on read endpoints and any endpoint where per-user awareness is not needed.

**Named limiters via `RateLimiter::for()`** are the right tool when the limit should vary based on who is making the request. The closure receives the full request object, which means you can inspect the authenticated user, a query parameter, a request header, or any other context to decide which `Limit` to return. Define named limiters in `AppServiceProvider` and apply them with `throttle:limiter-name`. This keeps the dynamic logic in a single, testable place rather than scattered across route files.

**Manual `RateLimiter::attempt()` in a controller** is the right tool when the rate limiting decision is part of the business logic rather than the routing layer. If you need to limit based on something that only exists after validation, or if the "attempt" represents a business action (a message sent, a report generated, a payment initiated) rather than an HTTP request, then the facade call belongs in the controller or a dedicated service class. It also gives you full control over what to include in the 429 response body, without needing to configure a custom response callback on the limiter.

## Conclusion {#conclusion}

Laravel's throttle system is a well-designed layer on top of the same fundamental concepts as any other rate limiter. Once you understand the three tools it provides and when each applies, building precise and maintainable rate limiting into any API becomes straightforward.

- **`throttle:x,y` is the simplest and most appropriate starting point.** For public read endpoints and any route where the limit is flat, this one-line middleware handles everything including headers, 429 responses, and cache management automatically.
- **Named limiters make dynamic per-user limiting clean and maintainable.** By defining the logic once in `AppServiceProvider` and referencing it by name on routes, you avoid duplicating conditional logic across route files and keep all limiting rules in a single reviewable location.
- **Manual `RateLimiter::attempt()` belongs to business logic, not routing.** When the decision of what counts as an attempt is specific to a business action rather than an HTTP request, the facade gives you the control that middleware cannot. Use `availableIn()` to include retry information in the response body and `clear()` to reset counters when a lockout condition is resolved.
- **The cache driver is what makes throttle work across processes.** In local development, the file driver is sufficient. In production on multiple servers, switch the `limiter` cache key to `redis` so all processes share the same counters. The rest of the code does not change.
- **Testing rate limiting requires flushing the full cache in `beforeEach`.** Throttle middleware stores its counters under an internal key format that differs from keys used by the manual `RateLimiter` facade, so clearing only specific keys is not sufficient. A `Cache::flush()` call in `beforeEach` guarantees every test starts from a clean state.