# Building a Health Check Endpoint for Laravel 13 and Monitoring It with Uptime Robot

Your application "looks up" because the web server still answers requests, but the database behind it is refusing connections and every checkout silently returns a 500. Meanwhile your uptime monitor is glowing green, because all it ever checks is whether the homepage returns a 200. You find out about the outage from an angry customer email, not from your monitoring. That gap between "the process is running" and "the application can actually serve users" is exactly where real incidents hide. Laravel 13 ships with a built-in `/up` route, but it only confirms the framework booted; it never touches your database or cache. In this tutorial you will build a dependency aware JSON health endpoint that probes the database and cache on every request, returns the right HTTP status codes, and then wire it to Uptime Robot so you get an alert the moment a real dependency goes down.

## Overview {#overview}

There are two very different questions a monitor can ask. The first is liveness: is the application process alive and responding at all? The second is readiness: can the application actually do its job right now, including reaching the services it depends on? Laravel's built-in `/up` route answers the first question well, but production incidents usually live in the second. A health endpoint that runs a quick database query and a cache roundtrip gives you a single URL that tells the truth about readiness, and an external service like Uptime Robot can poll that URL every minute and alert you the instant the answer changes.

### What You'll Build

- An invokable `HealthCheckController` that exposes `GET /health`.
- A JSON response containing an overall `status`, a timestamp, and a per dependency breakdown for the database and cache.
- Correct status codes: `200 OK` when everything is healthy and `503 Service Unavailable` when any dependency fails.
- A Pest test suite that proves both the healthy path and simulated failures behave correctly.
- An Uptime Robot keyword monitor that watches the endpoint and alerts you when it stops reporting `healthy`.

### What You'll Learn

- The difference between liveness and readiness, and why the built-in `/up` route is not enough on its own.
- How to build an invokable controller and register a route outside the web middleware group so it stays lean.
- How to probe the database connection and a cache roundtrip safely, capturing failures instead of crashing.
- Why returning a `503` status from a health endpoint matters to monitors and load balancers.
- How to test multiple health states, including simulated dependency failures, with Pest.
- How to configure an Uptime Robot keyword monitor and alert contacts to turn the endpoint into proactive alerting.

### What You'll Need

- PHP 8.3 or higher, which is the minimum version for Laravel 13.
- Composer and the Laravel installer available on your machine.
- SQLite, which ships ready to use with a fresh Laravel 13 project.
- Basic familiarity with Eloquent, routing, and the terminal.
- A free Uptime Robot account for the monitoring section.
- A publicly reachable URL for the final step, since Uptime Robot cannot reach `localhost`. A deployed app or a tunneling tool such as ngrok works fine.

## Step 1: Create the Project {#step-1-create-the-project}

Start by scaffolding a fresh Laravel 13 application with Pest already wired in. Pest is the testing framework you will use later to verify the healthy and failure paths, so installing it now saves a round trip.

Run the following commands. The first creates a new project configured for SQLite and Pest, and the second moves you into the project directory.

```bash
laravel new health-check-demo --no-interaction --database=sqlite --pest --no-boost
cd health-check-demo
```

The `--database=sqlite` flag creates a local `database/database.sqlite` file and points your `.env` at it, so you do not need a separate database server to follow along. The `--pest` flag installs Pest and replaces the default PHPUnit stubs with Pest equivalents.

Confirm the application boots by starting the development server.

```bash
php artisan serve
```

You should see the server come up and report the address it is listening on.

```
   INFO  Server running on [http://127.0.0.1:8000].

  Press Ctrl+C to stop the server
```

While the server is running, open `http://127.0.0.1:8000/up` in your browser. This is Laravel's built-in health route, and you will see an animated "Application up" page. That route is a pure liveness check: it confirms the framework booted, but it never queries your database or cache. That is the limitation you are about to fix. Stop the server with Ctrl+C so your terminal is free for the next steps.

## Step 2: Create the Health Check Controller {#step-2-create-the-controller}

The endpoint has exactly one job: respond to a health probe. That makes it a perfect fit for an invokable controller, a controller with a single `__invoke` method and no other actions. It keeps the responsibility obvious and the routing clean.

Generate the controller with the `--invokable` flag.

```bash
php artisan make:controller HealthCheckController --invokable
```

You should see confirmation that the file was created.

```
   INFO  Controller [app/Http/Controllers/HealthCheckController.php] created successfully.
```

Open `app/Http/Controllers/HealthCheckController.php` and replace its contents with a minimal first version that returns a static healthy response. Starting small gives you something you can run and verify before adding the real probes.

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;

class HealthCheckController extends Controller
{
    /**
     * Return the readiness state of the application.
     */
    public function __invoke(): JsonResponse
    {
        return response()->json([
            'status' => 'healthy',
        ]);
    }
}
```

The `response()->json()` helper sets the `Content-Type` header to `application/json` and serializes the array for you. Right now it always reports `healthy`, which is obviously a lie, but it gives you a working endpoint to register and hit before you add the actual checks.

## Step 3: Register the Health Route {#step-3-register-the-route}

A health endpoint should be as lean as possible. It will be hit constantly by your monitor, and it must keep working even when parts of the application are degraded. The routes in `routes/web.php` automatically run through the entire web middleware group: cookie encryption, session startup, CSRF protection, and more. Those middleware are useful for normal pages, but they are dead weight for a machine readable health probe, and some of them can even depend on the database. If your session driver is the database and the database is down, the session middleware would throw before your controller ever runs, turning a clean `503` into an opaque `500`.

To avoid that, register the route outside the web group. Laravel 13 exposes a `then` callback in `bootstrap/app.php` for registering routes that do not belong to any group, which means no session and no CSRF middleware are applied.

Open `bootstrap/app.php` and update the `withRouting` call.

```php
<?php

use App\Http\Controllers\HealthCheckController;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
        then: function (): void {
            // Register /health outside the web group so it carries no session
            // or CSRF middleware. A health check must stay lean and must not
            // depend on the very services it is meant to diagnose.
            Route::get('/health', HealthCheckController::class);
        },
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*'),
        );
    })->create();
```

Because the controller is invokable, you pass the class name directly to `Route::get` with no method to specify. Confirm the route was registered by listing your routes.

```bash
php artisan route:list
```

You should see the `health` route alongside the built-in `up` route.

```
  GET|HEAD   health .................................... HealthCheckController
  GET|HEAD   up .............................................................
```

Start the server again and hit the endpoint with `curl` to verify the static response.

```bash
php artisan serve
```

In a second terminal, run the following command.

```bash
curl http://127.0.0.1:8000/health
```

You should get the placeholder JSON back.

```json
{"status":"healthy"}
```

That confirms the route, controller, and JSON response are wired together. Now you can make the response tell the truth.

## Step 4: Add the Database and Cache Checks {#step-4-add-checks}

A health check is only useful if its dependencies are independent enough to give you separate signals. By default a fresh Laravel project uses the database as its cache store, which means a cache probe would just be a second database probe in disguise. To get a genuinely separate signal, switch the cache store to the file driver, which needs no extra services.

Open your `.env` file and set the cache store.

```ini
CACHE_STORE=file
```

With that in place, a database outage and a cache outage become two distinct failures the endpoint can report on independently.

Now open `app/Http/Controllers/HealthCheckController.php` again and replace it with the full version that probes both dependencies.

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Throwable;

class HealthCheckController extends Controller
{
    /**
     * Return the readiness state of the application and its dependencies.
     */
    public function __invoke(): JsonResponse
    {
        // Run each dependency probe and collect its result.
        $checks = [
            'database' => $this->checkDatabase(),
            'cache' => $this->checkCache(),
        ];

        // The application is only healthy when every single check passed.
        $healthy = collect($checks)->every(fn (array $check) => $check['ok'] === true);

        return response()->json([
            'status' => $healthy ? 'healthy' : 'unhealthy',
            'timestamp' => now()->toIso8601String(),
            'checks' => $checks,
        ], $healthy ? 200 : 503);
    }

    /**
     * Confirm the database accepts a connection and answers a trivial query.
     */
    private function checkDatabase(): array
    {
        $start = microtime(true);

        try {
            // getPdo() forces a real connection instead of a lazy one.
            DB::connection()->getPdo();

            // A "select 1" proves the connection can actually run queries.
            DB::select('select 1');

            return $this->ok($start);
        } catch (Throwable $e) {
            return $this->failed($start, $e->getMessage());
        }
    }

    /**
     * Confirm the cache store can write and read back the same value.
     */
    private function checkCache(): array
    {
        $start = microtime(true);

        try {
            // Use a random sentinel so we verify a true write-then-read roundtrip.
            $key = 'health:cache:'.Str::random(8);
            $value = Str::uuid()->toString();

            Cache::put($key, $value, 10);
            $readBack = Cache::get($key);
            Cache::forget($key);

            if ($readBack !== $value) {
                return $this->failed($start, 'Cache read value did not match what was written.');
            }

            return $this->ok($start);
        } catch (Throwable $e) {
            return $this->failed($start, $e->getMessage());
        }
    }

    /**
     * Shape a passing check result, including how long it took in milliseconds.
     */
    private function ok(float $start): array
    {
        return [
            'ok' => true,
            'duration_ms' => $this->elapsed($start),
        ];
    }

    /**
     * Shape a failing check result with the captured error message.
     */
    private function failed(float $start, string $message): array
    {
        return [
            'ok' => false,
            'duration_ms' => $this->elapsed($start),
            'error' => $message,
        ];
    }

    /**
     * Milliseconds elapsed since the given start time, rounded for readability.
     */
    private function elapsed(float $start): float
    {
        return round((microtime(true) - $start) * 1000, 2);
    }
}
```

There is a deliberate pattern here worth calling out. Each probe is wrapped in its own `try/catch` that catches `Throwable`, so a failing dependency is recorded as a failed check rather than bubbling up as an uncaught exception. That is what lets the endpoint stay alive long enough to report the problem honestly. The database probe calls `getPdo()` to force a real connection, then runs `select 1` to prove the connection can actually execute queries, not just open a socket. The cache probe writes a random value and reads it straight back, which catches a cache layer that is silently dropping writes, a failure a simple "is the service reachable" ping would miss.

The aggregation logic is intentionally strict. The overall `status` is `healthy` only when every check passed, and the response code follows the same rule: `200` when healthy and `503 Service Unavailable` when anything fails. That status code matters, because monitors and load balancers key off it. A `503` is the standard signal that says "this instance is temporarily unable to serve, route traffic elsewhere," and you will rely on exactly that behavior when you configure Uptime Robot. Notice also that every check records a `duration_ms`. A health endpoint should stay fast, ideally under a second, so these timings give you an early warning when a dependency is getting slow before it fails outright.

## Step 5: Try It Out {#step-5-try-it-out}

With the server still running, hit the endpoint again and include the `-i` flag so `curl` prints the response headers along with the body.

```bash
curl -i http://127.0.0.1:8000/health
```

You should see a `200 OK` status, a JSON content type, and both checks reporting `ok`.

```json
{
    "status": "healthy",
    "timestamp": "2026-06-08T13:07:12+00:00",
    "checks": {
        "database": {
            "ok": true,
            "duration_ms": 0.44
        },
        "cache": {
            "ok": true,
            "duration_ms": 1.04
        }
    }
}
```

Now prove the failure path works. The simplest way to take the database offline without touching code is to temporarily rename the SQLite file so Laravel cannot find it. Stop nothing, just run this in your second terminal.

```bash
mv database/database.sqlite database/database.sqlite.bak
```

Hit the endpoint again.

```bash
curl -i http://127.0.0.1:8000/health
```

This time the response status line reads `HTTP/1.1 503 Service Unavailable`, the overall `status` flips to `unhealthy`, and the database check reports the failure with the underlying error message. The cache check still passes, which confirms the two probes are genuinely independent.

```json
{
    "status": "unhealthy",
    "timestamp": "2026-06-08T13:07:22+00:00",
    "checks": {
        "database": {
            "ok": false,
            "duration_ms": 0.48,
            "error": "Database file at path [/path/to/health-check-demo/database/database.sqlite] does not exist. Ensure this is an absolute path to the database."
        },
        "cache": {
            "ok": true,
            "duration_ms": 1.81
        }
    }
}
```

The path in the error message will reflect your own project location. Restore the database file so the application is healthy again before moving on.

```bash
mv database/database.sqlite.bak database/database.sqlite
```

A final `curl http://127.0.0.1:8000/health` should report `healthy` once more. Manual checks like this are great for a quick confidence pass, but you do not want to rename files every time you change the controller. That is what the test suite is for.

## Step 6: Test the Endpoint with Pest {#step-6-test-with-pest}

Automated tests let you verify both the healthy path and the failure paths without ever touching real services. The trick for the failure cases is to mock the `DB` and `Cache` facades so they behave the way they would during an outage, which keeps the tests fast and deterministic.

Generate a feature test.

```bash
php artisan make:test HealthCheckTest --pest
```

Open `tests/Feature/HealthCheckTest.php` and replace its contents with the following suite.

```php
<?php

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

test('health endpoint returns 200 when everything is healthy', function () {
    $response = $this->get('/health');

    $response->assertStatus(200);
});

test('health endpoint returns json with a healthy status', function () {
    $response = $this->get('/health');

    $response->assertHeader('content-type', 'application/json')
        ->assertJsonPath('status', 'healthy');
});

test('health endpoint reports database and cache checks as ok', function () {
    $response = $this->get('/health');

    $response->assertJsonPath('checks.database.ok', true)
        ->assertJsonPath('checks.cache.ok', true);
});

test('health endpoint returns 503 when the database is down', function () {
    // Force the database probe to throw the way a real outage would.
    DB::shouldReceive('connection')->andThrow(new RuntimeException('SQLSTATE[HY000] Connection refused'));

    $response = $this->get('/health');

    $response->assertStatus(503)
        ->assertJsonPath('status', 'unhealthy')
        ->assertJsonPath('checks.database.ok', false);
});

test('health endpoint returns 503 when the cache is broken', function () {
    // Simulate a cache store that accepts writes but returns the wrong value back.
    Cache::shouldReceive('put')->andReturnTrue();
    Cache::shouldReceive('get')->andReturn('stale-or-missing');
    Cache::shouldReceive('forget')->andReturnTrue();

    $response = $this->get('/health');

    $response->assertStatus(503)
        ->assertJsonPath('status', 'unhealthy')
        ->assertJsonPath('checks.cache.ok', false);
});

test('health endpoint keeps healthy checks ok while another dependency fails', function () {
    // Only the cache is broken here, so the database check should still pass.
    Cache::shouldReceive('put')->andReturnTrue();
    Cache::shouldReceive('get')->andReturn('stale-or-missing');
    Cache::shouldReceive('forget')->andReturnTrue();

    $response = $this->get('/health');

    $response->assertStatus(503)
        ->assertJsonPath('checks.database.ok', true)
        ->assertJsonPath('checks.cache.ok', false);
});
```

The first three tests cover the happy path: a `200` status, a JSON content type with a `healthy` status, and both checks reporting `ok`. The fourth test uses `DB::shouldReceive('connection')->andThrow(...)` to make the database probe throw exactly as it would during a connection failure, then asserts the endpoint returns `503` with the database check marked as failed. The fifth test mocks the cache facade so that `get` returns a value that does not match what was written, which trips the roundtrip mismatch branch in the controller. The last test is the important one for confidence: it breaks only the cache and asserts the database check still reports `ok`, proving the checks fail independently rather than all collapsing together.

Run the suite, filtering to just this test file.

```bash
php artisan test --filter=HealthCheckTest
```

All six tests should pass.

```
   PASS  Tests\Feature\HealthCheckTest
  ✓ health endpoint returns 200 when everything is healthy               0.11s  
  ✓ health endpoint returns json with a healthy status                   0.02s  
  ✓ health endpoint reports database and cache checks as ok              0.02s  
  ✓ health endpoint returns 503 when the database is down                0.02s  
  ✓ health endpoint returns 503 when the cache is broken                 0.02s  
  ✓ health endpoint keeps healthy checks ok while another dependency fa… 0.02s  

  Tests:    6 passed (15 assertions)
  Duration: 0.28s
```

With the endpoint proven by tests, the last piece is to put a real monitor in front of it.

## Step 7: Connect Uptime Robot to Your Health Endpoint {#step-7-uptime-robot}

A health endpoint only helps if something is actually watching it. Uptime Robot polls a URL on a schedule and notifies you when it stops responding the way you expect. The one hard requirement is that your endpoint must be reachable from the public internet, because Uptime Robot's servers cannot see `localhost`. In practice this means you point the monitor at your deployed application, for example `https://yourdomain.com/health`. The rest of this section assumes you have such a public URL; the endpoint you built works the same way no matter where it is hosted.

If you have not deployed yet and only want to try the monitor against your local machine, you can optionally expose your dev server with a tunneling tool such as ngrok. This step is not required to use the endpoint, it is just a convenience for local experimentation.

```bash
# Optional: only needed if you want to monitor a local server
ngrok http 8000
```

ngrok prints a public HTTPS URL that forwards to your local server, so your endpoint becomes reachable at something like `https://your-subdomain.ngrok-free.app/health`. Keep the tunnel running while the monitor is active. For a real setup, prefer your deployed URL instead.

Now create the monitor. Log in to Uptime Robot and add a new monitor with these settings.

- Set the monitor type to **Keyword**. A plain HTTP monitor only checks whether the server responds, but a keyword monitor inspects the response body, which is what makes it a perfect match for a JSON health endpoint.
- Set the URL to your public health endpoint, for example `https://yourdomain.com/health`.
- Set the keyword to `healthy`.
- Set the alert condition to trigger when the keyword **does not exist** in the response. When everything is fine the body contains `"status":"healthy"`, so the keyword is present and the monitor stays up. The moment the endpoint reports `"status":"unhealthy"`, the word `healthy` still technically appears, so pair this with the status code behavior described below.
- Set the monitoring interval to one minute so you find out quickly.
- Attach your alert contacts, such as your email address, so a notification actually reaches you.

There is a subtle point about the keyword choice worth understanding. Because the unhealthy response also contains the substring `healthy` inside the word `unhealthy`, you want a keyword that only appears in the good state. A reliable approach is to match the exact JSON fragment `"status":"healthy"` as the keyword, so the match disappears the instant the status flips to `unhealthy`. On top of that, Uptime Robot treats the `503` status code your endpoint returns during an outage as a down signal on its own, so you get two independent triggers: the missing keyword and the failing status code. That redundancy is exactly why a keyword monitor on a structured health endpoint beats a bare ping.

If you want to confirm the alert actually fires, you can optionally repeat the failure simulation from Step 5 by renaming the SQLite file while the monitor is pointed at a reachable instance. Within a poll cycle or two, Uptime Robot flips the monitor to Down and sends your alert, then recovers to Up once you restore the file. This live test is useful for peace of mind, but it is not required: you already proved the endpoint returns the correct status and body for every state in the Pest suite from Step 6, which needs no third party setup at all.

## Liveness vs Readiness, and the Built-in /up Route {#liveness-vs-readiness}

Now that you have a working readiness endpoint, it is worth stepping back to see where it fits alongside Laravel's built-in tooling. Liveness and readiness answer different questions, and mature systems usually expose both rather than choosing one.

A liveness check answers "is this process running and able to respond?" It should be extremely cheap and should not touch external dependencies, because its job is to detect a hung or crashed process so an orchestrator can restart it. Laravel's built-in `/up` route, configured in `bootstrap/app.php` through the `health: '/up'` argument, is exactly this kind of check. When it is hit, the framework dispatches a `DiagnosingHealth` event and renders a simple status page, confirming the application booted and the HTTP stack is alive. You can hook into that `DiagnosingHealth` event to throw an exception when something is wrong, but the route's natural role is liveness.

A readiness check answers "can this instance actually serve traffic right now?" That is the question your `/health` endpoint answers, because it verifies the database and cache the application truly depends on. The two work together: an orchestrator or load balancer uses liveness to decide whether to restart an instance, and readiness to decide whether to send it traffic. Keep readiness checks fast, return as little internal detail as the consumer needs, and never run migrations, queue jobs, or other heavy work inside them, since the endpoint may be hit every few seconds.

If your needs grow beyond a couple of checks, the `spatie/laravel-health` package offers a larger framework with ready made checks for queues, scheduled tasks, disk space, and more, plus a dashboard. The hand rolled endpoint you built here is a great default for most applications and a clear foundation to understand what any such package is doing under the hood.

## Conclusion {#conclusion}

A green dot on a status page means very little if it only proves the web server answered the door. By building a readiness endpoint that probes the database and cache, returning honest status codes, and putting an external monitor in front of it, you close the gap between "the process is up" and "the application works." Here are the key takeaways.

- **Liveness is not readiness.** The built-in `/up` route confirms the framework booted, but a readiness endpoint that checks real dependencies is what tells you the application can actually serve users.
- **An invokable controller plus a group free route is enough.** Registering `/health` through the `then` callback in `bootstrap/app.php` keeps it free of session and CSRF middleware, so it stays lean and does not depend on the services it diagnoses.
- **Probe dependencies for real.** Forcing a database connection with a `select 1` and doing a write then read cache roundtrip catches silent failures that a simple reachability ping would miss.
- **Status codes are the contract.** Returning `200` when healthy and `503` when degraded is what lets monitors and load balancers act on the result automatically.
- **Test the failures, not just the success.** Mocking the `DB` and `Cache` facades lets you prove the endpoint reports each outage correctly and that the checks fail independently, all without touching real services.
- **Uptime Robot turns the endpoint into alerting.** A keyword monitor that watches for the healthy status, polling every minute, is what actually wakes you up before your users do.
