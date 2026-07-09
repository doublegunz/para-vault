---
title: "HTTP QUERY Method Support in Laravel 13.19"
slug: "http-query-method-support-in-laravel-13-19"
category: "Laravel"
date: "2026-07-09"
status: "draft"
---

# HTTP QUERY Method Support in Laravel 13.19

Complex search endpoints often outgrow a clean `GET` URL. A few filters are fine, but nested filters, arrays, long search expressions, and privacy-sensitive inputs can turn the query string into a brittle transport detail. Many teams solve that by using `POST /search`, but then the request no longer communicates that the operation is meant to be safe and repeatable.

RFC 10008 gives HTTP a clearer option: the `QUERY` method. It carries query content in the request body while preserving safe and idempotent query semantics. Laravel 13.19 adds support on the pieces Laravel developers touch most often: the HTTP client and HTTP testing helpers.

The official framework changelog lists both additions in the same release: `Http::query()` in [PR #60663](https://github.com/laravel/framework/pull/60663) and the `query()` plus `queryJson()` testing helpers in [PR #60662](https://github.com/laravel/framework/pull/60662). This article turns that release note into a small runnable Laravel example.

## Overview {#overview}

We will build a tiny search endpoint that accepts an HTTP `QUERY` request, reads filters from the request body, and verifies the behavior with Pest. Then we will test the outgoing side with Laravel's HTTP client so you can see how `Http::query()` sends data.

### What You'll Build

- A fresh Laravel 13.19 demo application.
- An `/api/search` route that responds to the `QUERY` method.
- A search response that proves the filter came from the request body, not the URL query string.
- Pest tests that call the route with `queryJson()`.
- HTTP client tests that inspect outgoing `Http::query()` requests.

### What You'll Learn

- Why RFC 10008 introduces `QUERY` instead of overloading `GET` or `POST`.
- How `QUERY` differs from URL query parameters.
- How Laravel 13.19 sends a `QUERY` request with `Http::query()`.
- How to test incoming `QUERY` routes with `query()` and `queryJson()`.
- What production caveats to check before exposing `QUERY` publicly.

### What You'll Need

- PHP 8.3 or newer.
- Laravel 13.19 or newer.
- Composer and Artisan.
- Pest, installed by the Laravel installer command below.
- Basic familiarity with Laravel routes, feature tests, and the HTTP client.

## Step 1: Create a Laravel 13.19 Demo Project {#step-1-create-a-laravel-13-19-demo-project}

Start with a clean Laravel project so the route and tests are easy to follow. The `--database=sqlite` flag keeps the app lightweight, even though this demo uses an in-memory collection instead of a database table.

Create the project and move into it:

```bash
laravel new http-query-demo --no-interaction --database=sqlite --pest --no-boost
cd http-query-demo
```

The `--pest` flag installs Pest as the test runner. The `--no-boost` flag keeps the generated project minimal, which is useful for a focused HTTP feature demo.

Confirm the framework version:

```bash
php artisan --version
```

For this article, the demo was verified against Laravel 13.19.0:

```text
Laravel Framework 13.19.0
```

Laravel 13 does not create `routes/api.php` in a fresh app until you ask for API scaffolding. Create it now:

```bash
php artisan install:api
```

This command publishes the API routes file and registers it in `bootstrap/app.php`. It may also install Laravel Sanctum if your project does not already have it, but this article does not use authentication.

## Step 2: Add a QUERY Search Route {#step-2-add-a-query-search-route}

Now add a route that responds to the HTTP `QUERY` method. Laravel's routing layer can match custom HTTP methods with `Route::match()`, which makes it a good fit for a method that is newer than the common `get`, `post`, and `delete` helpers.

Open `routes/api.php` and add this route below the generated imports:

```php
<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::match(['QUERY'], '/search', function (Request $request) {
    $validated = $request->validate([
        'filter.status' => ['required', 'in:active,draft,archived'],
    ]);

    $articles = collect([
        ['title' => 'Laravel HTTP Client Guide', 'status' => 'active'],
        ['title' => 'Draft Release Notes', 'status' => 'draft'],
        ['title' => 'Archived Search Notes', 'status' => 'archived'],
    ]);

    return response()->json([
        'method' => $request->method(),
        'query_string_status' => $request->query('filter.status'),
        'body_status' => $validated['filter']['status'],
        'results' => $articles
            ->where('status', $validated['filter']['status'])
            ->values(),
    ]);
});
```

The route validates a nested body field named `filter.status`. It also returns both `query_string_status` and `body_status` on purpose. That makes the test easier to read because the response shows that `queryJson()` put the filter in the request body, not in the URL query string.

## Step 3: Test the Route with queryJson {#step-3-test-the-route-with-queryjson}

Laravel 13.19 adds `query()` and `queryJson()` to the same testing concern that already provides helpers such as `getJson()`, `postJson()`, and `deleteJson()`. Use `queryJson()` when the request body should be JSON and the response is expected to be JSON.

Create `tests/Feature/HttpQueryMethodTest.php`:

```php
<?php

use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;

test('queryJson sends search filters in the request body', function () {
    $response = $this->queryJson('/api/search', [
        'filter' => [
            'status' => 'active',
        ],
    ]);

    $response
        ->assertOk()
        ->assertJson([
            'method' => 'QUERY',
            'query_string_status' => null,
            'body_status' => 'active',
            'results' => [
                [
                    'title' => 'Laravel HTTP Client Guide',
                    'status' => 'active',
                ],
            ],
        ]);
});

test('queryJson validates the query content', function () {
    $response = $this->queryJson('/api/search', [
        'filter' => [
            'status' => 'deleted',
        ],
    ]);

    $response->assertUnprocessable();
});
```

The first test sends a JSON `QUERY` request to `/api/search`. The route returns the request method, the missing URL query string value, the body value, and the filtered result. The second test confirms that the route still treats the body as real request input, so normal Laravel validation applies.

Run the tests:

```bash
php artisan test
```

At this point, Pest should report the generated example tests plus the two new tests as passing. In a fresh project, that means 4 passing tests: the generated feature test, the generated unit test, and the two `QUERY` route tests you just added.

## Step 4: Send an Outgoing QUERY Request with Http::query {#step-4-send-an-outgoing-query-request-with-http-query}

Testing incoming routes is only one side of the release. Laravel 13.19 also adds `Http::query()` to the HTTP client, so your application can send `QUERY` requests to another service without dropping down to `Http::send('QUERY', ...)`.

Add these two tests to the same `tests/Feature/HttpQueryMethodTest.php` file:

```php
test('Http::query sends a QUERY request with a JSON body by default', function () {
    Http::fake([
        'api.example.test/search' => Http::response(['ok' => true]),
    ]);

    Http::query('https://api.example.test/search', [
        'filter' => [
            'status' => 'active',
        ],
    ]);

    Http::assertSent(function (Request $request) {
        return $request->method() === 'QUERY'
            && $request->url() === 'https://api.example.test/search'
            && $request->data()['filter']['status'] === 'active'
            && $request->hasHeader('Content-Type', 'application/json');
    });
});

test('Http::query can send form encoded query content', function () {
    Http::fake([
        'api.example.test/search' => Http::response(['ok' => true]),
    ]);

    Http::asForm()->query('https://api.example.test/search', [
        'status' => 'active',
    ]);

    Http::assertSent(function (Request $request) {
        return $request->method() === 'QUERY'
            && $request->data()['status'] === 'active'
            && $request->hasHeader('Content-Type', 'application/x-www-form-urlencoded');
    });
});
```

The first test proves the default behavior: Laravel sends the payload as JSON, just like `post()`, `put()`, and `patch()` do by default. The second test proves that `asForm()` still controls the body format, so you can send `application/x-www-form-urlencoded` query content when an API expects it.

Run the full test suite again:

```bash
php artisan test
```

The verified demo project for this article completed with 6 passing tests and 7 assertions. The important behavior is covered from both directions: your route can receive body-carried query content, and your application can send it through the HTTP client.

## Step 5: Try It Out with curl {#step-5-try-it-out-with-curl}

Feature tests are the cleanest way to verify the Laravel behavior, but you can also send a `QUERY` request manually if your local `curl` version supports custom methods.

Start the development server:

```bash
php artisan serve
```

In another terminal, send a `QUERY` request with a JSON body:

```bash
curl -X QUERY http://127.0.0.1:8000/api/search \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"filter":{"status":"active"}}'
```

The response should show the same distinction the test asserted:

```json
{
    "method": "QUERY",
    "query_string_status": null,
    "body_status": "active",
    "results": [
        {
            "title": "Laravel HTTP Client Guide",
            "status": "active"
        }
    ]
}
```

The key field is `query_string_status`. It is `null` because the filter did not come from `?filter[status]=active`. The route read it from the JSON body.

## Understanding the HTTP QUERY Method {#understanding-the-http-query-method}

RFC 10008 defines `QUERY` as a method for asking a target resource to process enclosed content in a safe and idempotent way. That short definition matters because it gives `QUERY` a different meaning from both `GET` and `POST`.

With `GET`, query inputs usually live in the URI:

```
GET /feed?q=laravel&limit=10&sort=-published HTTP/1.1
Host: example.test
```

That works well for small parameters. It becomes weaker when the query input is large, deeply nested, costly to encode into a URI, or not something you want to appear in common URL logs.

With `POST`, the same query input can move into the body:

```
POST /feed HTTP/1.1
Host: example.test
Content-Type: application/json

{"q":"laravel","limit":10,"sort":"-published"}
```

The body problem is solved, but the method now suggests a potentially unsafe operation. A human might know that `POST /feed` is just a search, but generic HTTP tooling cannot infer that from the method alone.

`QUERY` is designed to sit between those two patterns:

```
QUERY /feed HTTP/1.1
Host: example.test
Content-Type: application/json

{"q":"laravel","limit":10,"sort":"-published"}
```

The request target still identifies the resource that should perform the query. The body describes the query operation. According to RFC 10008, `QUERY` is safe and idempotent, which means clients can repeat it when needed without expecting target resource state to change.

## Laravel 13.19 API Surface {#laravel-13-19-api-surface}

Laravel 13.19 did not change how URL query strings work. Instead, it added explicit helpers for the HTTP `QUERY` method, which keeps the naming clear.

For outgoing requests, use `Http::query()`:

```php
use Illuminate\Support\Facades\Http;

$response = Http::query('https://api.example.test/search', [
    'filter' => [
        'status' => 'active',
    ],
]);
```

Laravel sends the second argument as request body data. JSON is the default body format. If the remote API expects form encoded content, keep using the existing fluent body format helpers:

```php
$response = Http::asForm()->query('https://api.example.test/search', [
    'status' => 'active',
]);
```

For incoming route tests, use `query()` or `queryJson()`:

```php
$this->query('/search', ['status' => 'active']);

$this->queryJson('/api/search', [
    'filter' => [
        'status' => 'active',
    ],
]);
```

Use `withQueryParameters()` or the `$query` argument to `get()` when you intentionally want URL query parameters. Use `Http::query()` when you want the HTTP method to be `QUERY` and the query content to live in the request body.

## Practical Caveats Before Using QUERY in Production {#practical-caveats-before-using-query-in-production}

Laravel can now send and test `QUERY`, but production readiness depends on the whole request path. Check every client, proxy, gateway, load balancer, CDN, and upstream service that will see the request.

Browsers also need special attention. RFC 10008 notes that `QUERY` is not a CORS safelisted method, so browser clients using it cross-origin will trigger a preflight request. Your CORS configuration must allow the `QUERY` method explicitly.

Servers should also validate `Content-Type`. RFC 10008 expects a `QUERY` request to have content and metadata that agree with each other. In Laravel, that usually means you should be explicit about accepting JSON or form data, validate the body as normal request input, and return a clear client error when the content is unsupported.

Finally, do not treat `QUERY` as a secrecy tool. Moving input out of the URI can reduce accidental exposure in URL logs, browser history, bookmarks, and analytics systems, but request bodies can still be logged by application code, API gateways, debugging middleware, or observability tools.

## Conclusion {#conclusion}

Laravel 13.19 makes RFC 10008 practical for Laravel applications by adding the missing framework-level convenience methods. You can now model body-carried, safe query operations more clearly in your client code and your tests.

- **HTTP QUERY.** `QUERY` carries query content in the request body while preserving safe and idempotent semantics.
- **Laravel 13.19.** The release adds `Http::query()` for outgoing requests and `query()` plus `queryJson()` for route tests.
- **Body-based filters.** The new helpers keep URL query strings separate from HTTP `QUERY` body content, which makes intent easier to read.
- **Testing support.** `queryJson()` lets you verify incoming `QUERY` routes with the same style you already use for JSON API tests.
- **Production checks.** Confirm support across clients, CORS rules, proxies, gateways, caches, and upstream services before relying on `QUERY` publicly.
