---
title: "Webhook Signature Verification in Laravel: Safely Receiving Data from Payment Gateways"
slug: "webhook-signature-verification-in-laravel-safely-receiving-data-from-payment-gateways"
category: "Laravel"
date: "2026-04-30"
status: "published"
---

Your webhook endpoint is a public URL, and anyone on the internet can POST to it. Without any protection, an attacker who discovers your endpoint address can craft a fake `payment.succeeded` payload and send it directly to your server. Your application would see a valid JSON body, assume a customer has paid, and ship the order, grant a subscription, or credit an account for a transaction that never actually happened. The URL alone is not a secret; it is a moving target that can be found through logs, error messages, or simple enumeration.

The industry-standard answer to this problem is HMAC-SHA256 signature verification. When a payment gateway sends you a webhook, it uses a shared secret key to compute a cryptographic signature of the request body and attaches that signature as a custom HTTP header. Your server then independently computes the same signature using the same secret. If the two values match, the payload is authentic. If they do not, you reject the request before your business logic ever runs.

In this tutorial, you will build a secure webhook receiver for a fictional payment gateway called **PaySwift**. You will implement signature verification in dedicated middleware, protect against replay attacks using a timestamp tolerance window, and add idempotency tracking to prevent the same event from being processed twice when PaySwift retries a failed delivery.

## Overview {#overview}

This article treats webhook security as a standalone subject. The implementation is intentionally scoped to one endpoint so that every layer of defence is visible and easy to reason about. Once you understand the pattern, you can adapt it to any real payment gateway by swapping out the header names and secret source.

### What You'll Build

- A Laravel 13 API endpoint at `POST /api/webhooks/payswift` that receives payment event notifications.
- A `VerifyPaySwiftSignature` middleware that validates the HMAC-SHA256 signature and rejects requests with expired timestamps.
- A `webhook_logs` database table with a unique constraint on the event ID to prevent duplicate processing.
- A suite of six Pest tests covering valid delivery and every rejection scenario.

### What You'll Learn

- How HMAC-SHA256 signature verification works and why it is the correct tool for webhook authentication.
- Why you must read the raw request body with `getContent()` before any JSON parsing when computing the signature.
- How to use `hash_equals()` for timing-safe comparison to close a subtle but real attack vector.
- How timestamp validation prevents replay attacks and how idempotency handles legitimate retries.

### What You'll Need

- PHP 8.3 or higher
- Composer
- Laravel 13 (fresh install)
- Basic familiarity with Laravel middleware, Eloquent models, and Pest
- `curl` installed on your machine for manual testing

## Step 1: Set Up the Project and Database {#step-1-setup}

Start by creating a fresh Laravel 13 project. Because webhook endpoints are API routes, you need to run `php artisan install:api` immediately after installation. Laravel 13 does not include `routes/api.php` by default; this command scaffolds it.

```bash
laravel new payswift-webhook-demo --database=sqlite --pest --no-boost
cd payswift-webhook-demo
php artisan install:api
```

The `--database=sqlite` flag configures the project to use SQLite out of the box, which means you do not need to set up a separate database server for this tutorial. The `--pest` flag scaffolds Pest as the default testing framework so you do not need to install it manually later. The `--no-boost` flag skips the optional starter kit prompt and creates a plain API-ready project. Once the installer finishes, run `php artisan install:api` to scaffold `routes/api.php` and install Laravel Sanctum. You will not use Sanctum token authentication here since webhooks come from external servers rather than authenticated browser sessions, but the command is still required to create the API routes file.

### Create the Webhook Logs Migration

The `webhook_logs` table records every event that your application successfully processes. Before processing any incoming event, the controller will check this table first. If the event ID is already present, the controller returns a 409 response without doing any work. This is your idempotency layer, and it is what protects you when PaySwift retries a delivery because your server returned a 500 error the first time.

```bash
php artisan make:migration create_webhook_logs_table
```

Open the generated file in `database/migrations/` and replace the body with the following:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('webhook_logs', function (Blueprint $table) {
            $table->id();

            // The unique event ID sent by PaySwift in the X-PaySwift-Event-ID header.
            // The unique constraint enforces idempotency at the database level,
            // acting as a safety net for race conditions where two requests with the
            // same event ID arrive at almost exactly the same moment.
            $table->string('event_id')->unique();

            // The event type, e.g. 'payment.succeeded' or 'payment.failed'.
            $table->string('event_type');

            // Store the full raw JSON payload for auditing and debugging.
            // Having the original payload is invaluable when you need to investigate
            // why a particular payment triggered unexpected behaviour.
            $table->json('payload');

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('webhook_logs');
    }
};
```

Run the migration:

```bash
php artisan migrate
```

Expected output:

```
   INFO  Running migrations.

  2025_01_15_000001_create_webhook_logs_table ............... 9ms DONE
```

## Step 2: Create the Webhook Route and Controller {#step-2-controller}

With the database ready, you can build the initial route and controller. At this stage the controller is intentionally simple: it reads the payload, dispatches to a handler, and returns 200. Signature verification and idempotency come in the next two steps so you can see each layer in isolation.

### Register the API Route

Open `routes/api.php` and add:

```php
<?php

use App\Http\Controllers\PaySwiftWebhookController;
use Illuminate\Support\Facades\Route;

Route::post('/webhooks/payswift', [PaySwiftWebhookController::class, 'handle']);
```

### Generate the Controller

```bash
php artisan make:controller PaySwiftWebhookController
```

Open `app/Http/Controllers/PaySwiftWebhookController.php` and write the following:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class PaySwiftWebhookController extends Controller
{
    public function handle(Request $request): \Illuminate\Http\Response
    {
        // getContent() returns the raw HTTP body as a string.
        // We use this instead of $request->all() or $request->json() because
        // we need the exact bytes that PaySwift sent. Parsing and re-encoding
        // the JSON can change byte ordering or whitespace and break the HMAC check
        // that we will add in the middleware later.
        $rawBody   = $request->getContent();
        $payload   = json_decode($rawBody, true);
        $eventType = $payload['event'] ?? 'unknown';

        match ($eventType) {
            'payment.succeeded' => $this->handlePaymentSucceeded($payload),
            'payment.failed'    => $this->handlePaymentFailed($payload),
            default             => Log::info("Unhandled PaySwift event: {$eventType}"),
        };

        return response('Webhook received.', Response::HTTP_OK);
    }

    private function handlePaymentSucceeded(array $payload): void
    {
        Log::info('PaySwift: payment succeeded', [
            'transaction_id' => $payload['data']['transaction_id'] ?? null,
            'amount'         => $payload['data']['amount'] ?? null,
            'currency'       => $payload['data']['currency'] ?? null,
        ]);
        // In a real application, you would update your Order model here:
        // Order::where('transaction_id', $payload['data']['transaction_id'])
        //     ->update(['status' => 'paid']);
    }

    private function handlePaymentFailed(array $payload): void
    {
        Log::warning('PaySwift: payment failed', [
            'transaction_id' => $payload['data']['transaction_id'] ?? null,
            'reason'         => $payload['data']['failure_reason'] ?? null,
        ]);
        // You might notify the customer or queue a follow-up action here.
    }
}
```

At this point the endpoint accepts any POST request, which is intentional. You are about to lock it down in the next step.

## Step 3: Build the Signature Verification Middleware {#step-3-middleware}

This is the core security layer. The middleware intercepts every incoming request before it reaches the controller and performs three checks in sequence: it verifies that the required headers are present, it confirms the timestamp is recent enough to rule out a replay attack, and it validates the HMAC-SHA256 signature. If any check fails, the request is rejected with a 401 response and the controller never runs.

### Store the Webhook Secret

PaySwift provides a webhook secret on your dashboard. Add it to `.env`:

```
PAYSWIFT_WEBHOOK_SECRET=super-secret-payswift-key
```

Then expose it through `config/services.php`. Reading configuration values through the `config()` helper is preferred over calling `env()` directly inside your classes, because it works correctly after the config is cached with `php artisan config:cache`.

```php
// config/services.php
'payswift' => [
    'webhook_secret' => env('PAYSWIFT_WEBHOOK_SECRET'),
],
```

### Write the Middleware

Generate the middleware class:

```bash
php artisan make:middleware VerifyPaySwiftSignature
```

Open `app/Http/Middleware/VerifyPaySwiftSignature.php` and replace its contents:

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class VerifyPaySwiftSignature
{
    // Accept webhooks timestamped within a 5-minute window.
    // This is the industry convention: generous enough to accommodate
    // legitimate delivery delays, tight enough to make captured-and-replayed
    // requests expire quickly.
    private const TIMESTAMP_TOLERANCE_SECONDS = 300;

    public function handle(Request $request, Closure $next): Response
    {
        $signatureHeader = $request->header('X-PaySwift-Signature');
        $timestampHeader = $request->header('X-PaySwift-Timestamp');

        // If either required header is absent, this is not a valid PaySwift request.
        // Reject it immediately without revealing which header is missing.
        if (! $signatureHeader || ! $timestampHeader) {
            return response()->json(
                ['error' => 'Missing webhook headers.'],
                Response::HTTP_UNAUTHORIZED
            );
        }

        // Cast to integer and check the age of the timestamp.
        // abs() handles the edge case where the receiving server's clock
        // is slightly ahead of PaySwift's clock.
        $timestamp = (int) $timestampHeader;

        if (abs(time() - $timestamp) > self::TIMESTAMP_TOLERANCE_SECONDS) {
            return response()->json(
                ['error' => 'Webhook timestamp expired.'],
                Response::HTTP_UNAUTHORIZED
            );
        }

        // Read the raw body before any JSON parsing occurs.
        // The HMAC must be computed over the exact bytes PaySwift signed.
        // Re-encoding a parsed array with json_encode() can produce different
        // key ordering, different whitespace, or different Unicode escaping,
        // any of which would produce a completely different hash.
        $rawBody = $request->getContent();
        $secret  = config('services.payswift.webhook_secret');

        // Compute the expected signature using the same algorithm and secret
        // that PaySwift used when it signed the outgoing payload.
        $computedSignature = 'sha256=' . hash_hmac('sha256', $rawBody, $secret);

        // hash_equals() performs a constant-time comparison.
        // The naive === operator short-circuits as soon as it finds a differing byte,
        // which leaks timing information. An attacker can measure those microsecond
        // differences over thousands of requests to reconstruct a valid signature
        // one byte at a time. hash_equals() always compares the full string length,
        // removing that timing signal entirely.
        if (! hash_equals($computedSignature, $signatureHeader)) {
            return response()->json(
                ['error' => 'Invalid webhook signature.'],
                Response::HTTP_UNAUTHORIZED
            );
        }

        return $next($request);
    }
}
```

### Register and Apply the Middleware

Open `bootstrap/app.php` and register a short alias inside the `withMiddleware` callback:

```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'verify.payswift' => \App\Http\Middleware\VerifyPaySwiftSignature::class,
    ]);
})
```

Then apply it to your route in `routes/api.php`:

```php
Route::post('/webhooks/payswift', [PaySwiftWebhookController::class, 'handle'])
    ->middleware('verify.payswift');
```

Every request to this endpoint now goes through the middleware first. Unauthenticated requests never reach the controller.

## Step 4: Add Idempotency to the Controller {#step-4-idempotency}

A valid signature proves the request came from PaySwift, but it does not prove you have never seen this particular event before. Payment gateways operate on an "at least once" delivery guarantee: if your server responds with a 5xx error or times out, PaySwift will retry the same event with a fresh timestamp and a freshly computed valid signature. Without idempotency, a network hiccup during your response could result in the same payment being recorded twice.

### Create the WebhookLog Model

```bash
php artisan make:model WebhookLog
```

Open `app/Models/WebhookLog.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

// The #[Fillable] attribute is the Laravel 13 way to declare mass-assignable fields.
// It replaces the protected $fillable array from older Laravel versions.
#[Fillable(['event_id', 'event_type', 'payload'])]
class WebhookLog extends Model
{
    //
}
```

### Update the Controller

Open `app/Http/Controllers/PaySwiftWebhookController.php` and update the `handle()` method to incorporate the idempotency check and the log write. The private handler methods stay the same:

```php
<?php

namespace App\Http\Controllers;

use App\Models\WebhookLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class PaySwiftWebhookController extends Controller
{
    public function handle(Request $request): \Illuminate\Http\Response
    {
        $rawBody   = $request->getContent();
        $payload   = json_decode($rawBody, true);
        $eventId   = $request->header('X-PaySwift-Event-ID');
        $eventType = $payload['event'] ?? 'unknown';

        // Check whether we have already processed this event.
        // Payment gateways retry failed deliveries; this guard ensures the
        // same event ID is never handled more than once, regardless of how
        // many times PaySwift delivers it.
        if (WebhookLog::where('event_id', $eventId)->exists()) {
            return response('Event already processed.', Response::HTTP_CONFLICT);
        }

        match ($eventType) {
            'payment.succeeded' => $this->handlePaymentSucceeded($payload),
            'payment.failed'    => $this->handlePaymentFailed($payload),
            default             => Log::info("Unhandled PaySwift event: {$eventType}"),
        };

        // Record the event after processing so that any retry arriving during
        // processing does not slip past the guard above.
        // The unique constraint on event_id in the database is a second line of
        // defence against the rare case where two requests arrive simultaneously.
        WebhookLog::create([
            'event_id'   => $eventId,
            'event_type' => $eventType,
            'payload'    => $rawBody,
        ]);

        return response('Webhook received.', Response::HTTP_OK);
    }

    private function handlePaymentSucceeded(array $payload): void
    {
        Log::info('PaySwift: payment succeeded', [
            'transaction_id' => $payload['data']['transaction_id'] ?? null,
            'amount'         => $payload['data']['amount'] ?? null,
            'currency'       => $payload['data']['currency'] ?? null,
        ]);
    }

    private function handlePaymentFailed(array $payload): void
    {
        Log::warning('PaySwift: payment failed', [
            'transaction_id' => $payload['data']['transaction_id'] ?? null,
            'reason'         => $payload['data']['failure_reason'] ?? null,
        ]);
    }
}
```

## Step 5: Try It Out {#step-5-try-it-out}

Start the development server:

```bash
php artisan serve
```

To send a realistic webhook, you need to compute a valid HMAC-SHA256 signature before making the request, which is exactly what PaySwift would do on its end. Create the following PHP script in your project root. It is a local testing tool only and should never be deployed or committed to version control.

```php
<?php
// generate-test-webhook.php
// Usage: php generate-test-webhook.php
// Simulates exactly what PaySwift does before sending a webhook to your server.

$secret    = 'super-secret-payswift-key'; // Must match PAYSWIFT_WEBHOOK_SECRET in .env
$eventId   = 'evt_' . bin2hex(random_bytes(8));
$timestamp = time();

$payload = json_encode([
    'event' => 'payment.succeeded',
    'data'  => [
        'transaction_id' => 'txn_abc123',
        'amount'         => 150000,   // In cents: IDR 1,500,000
        'currency'       => 'IDR',
        'customer_email' => 'budi@example.com',
    ],
]);

// PaySwift signs the raw JSON body with the shared secret.
// The 'sha256=' prefix makes the hashing algorithm explicit in the header value.
$signature = 'sha256=' . hash_hmac('sha256', $payload, $secret);

echo "Event ID : {$eventId}\n";
echo "Timestamp: {$timestamp}\n";
echo "Signature: {$signature}\n\n";
echo "Run this curl command:\n\n";
echo "curl -s -o /dev/null -w \"%{http_code}\" \\\n";
echo "  -X POST http://localhost:8000/api/webhooks/payswift \\\n";
echo "  -H 'Content-Type: application/json' \\\n";
echo "  -H \"X-PaySwift-Event-ID: {$eventId}\" \\\n";
echo "  -H \"X-PaySwift-Timestamp: {$timestamp}\" \\\n";
echo "  -H \"X-PaySwift-Signature: {$signature}\" \\\n";
echo "  -d '" . $payload . "'\n";
```

Run the script, then copy and execute the curl command it prints:

```bash
php generate-test-webhook.php
```

### Scenario 1: Valid Webhook

Running the generated curl command sends a request with a correct signature and a fresh timestamp. The middleware passes it through and the controller records it:

```
200
```

If you check `storage/logs/laravel.log`, you will see:

```
[2025-01-15 10:00:12] local.INFO: PaySwift: payment succeeded {"transaction_id":"txn_abc123","amount":150000,"currency":"IDR"}
```

Run the exact same curl command a second time. Because the event ID is already in `webhook_logs`, the controller's idempotency guard catches it:

```
409
```

### Scenario 2: Invalid Signature

Send a request with a deliberately wrong signature by changing the hex string:

```bash
curl -s -o /dev/null -w "%{http_code}" \
  -X POST http://localhost:8000/api/webhooks/payswift \
  -H 'Content-Type: application/json' \
  -H 'X-PaySwift-Event-ID: evt_tampered' \
  -H "X-PaySwift-Timestamp: $(date +%s)" \
  -H 'X-PaySwift-Signature: sha256=0000000000000000000000000000000000000000000000000000000000000000' \
  -d '{"event":"payment.succeeded","data":{"transaction_id":"txn_fake","amount":999999}}'
```

The `hash_equals()` check fails in the middleware and the controller is never reached:

```
401
```

### Scenario 3: Expired Timestamp

Send a request with a timestamp from the distant past:

```bash
curl -s -o /dev/null -w "%{http_code}" \
  -X POST http://localhost:8000/api/webhooks/payswift \
  -H 'Content-Type: application/json' \
  -H 'X-PaySwift-Event-ID: evt_old' \
  -H 'X-PaySwift-Timestamp: 1700000000' \
  -H 'X-PaySwift-Signature: sha256=anything' \
  -d '{"event":"payment.succeeded","data":{}}'
```

The timestamp check fires before the signature check and rejects the request immediately:

```
401
```

### Scenario 4: Missing Headers

Send a request with no webhook-specific headers at all:

```bash
curl -s -o /dev/null -w "%{http_code}" \
  -X POST http://localhost:8000/api/webhooks/payswift \
  -H 'Content-Type: application/json' \
  -d '{"event":"payment.succeeded","data":{}}'
```

```
401
```

## Step 6: Write the Tests {#step-6-tests}

Because you created the project with the `--pest` flag, Pest is already installed and configured. The only preparation needed before writing tests is adding the webhook secret to `phpunit.xml` so that every test run uses a known, predictable value instead of reading from your real `.env` file.

Add the webhook secret to `phpunit.xml` inside the `<php>` block so that tests use a known, predictable value:

```xml
<php>
    <env name="APP_ENV" value="testing"/>
    <env name="PAYSWIFT_WEBHOOK_SECRET" value="test-webhook-secret"/>
</php>
```

Create the test file:

```bash
touch tests/Feature/PaySwiftWebhookTest.php
```

Open it and write the following. There is one important implementation detail in the `sendWebhook` helper worth understanding before you read the code: Laravel's `call()` method accepts headers through a `$server` array that uses CGI variable naming (uppercase, hyphens replaced by underscores, prefixed with `HTTP_`). Passing headers through `withHeaders()` and then calling `call()` does not work because the two methods do not share state in the test kernel. The `sendWebhook` helper converts each header key to its CGI form internally, which is why all six tests behave correctly without requiring any changes to your application code.

```php
<?php

use App\Models\WebhookLog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Symfony\Component\HttpFoundation\Response;

uses(RefreshDatabase::class);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Builds headers that exactly replicate what PaySwift sends with each delivery.
// Any parameter can be overridden to simulate a specific failure condition.
function makeSignedHeaders(
    string $payload,
    ?string $secret = null,
    ?int $timestamp = null,
    ?string $eventId = null
): array {
    return [
        'Content-Type'         => 'application/json',
        'X-PaySwift-Event-ID'  => $eventId ?? 'evt_' . bin2hex(random_bytes(8)),
        'X-PaySwift-Timestamp' => (string) ($timestamp ?? time()),
        'X-PaySwift-Signature' => 'sha256=' . hash_hmac(
            'sha256',
            $payload,
            $secret ?? config('services.payswift.webhook_secret')
        ),
    ];
}

// Sends the raw JSON body directly over HTTP without re-encoding it.
// Using call() instead of postJson() is critical here: postJson() decodes the
// JSON into an array and re-encodes it, which could change the byte sequence
// and invalidate the HMAC we computed in makeSignedHeaders().
//
// All headers, including the custom X-PaySwift-* ones, are merged into the
// $server array as CGI-style keys (HTTP_* uppercase with hyphens as underscores).
// This is the only reliable way to ensure Laravel's test kernel sees them:
// withHeaders() and the $server parameter of call() do not share state,
// so headers passed via withHeaders() are silently lost when call() is used.
function sendWebhook(string $payload, array $headers): \Illuminate\Testing\TestResponse
{
    // Convert each header into its CGI equivalent so the test kernel treats them
    // exactly as it would a real incoming HTTP request.
    // e.g. 'X-PaySwift-Signature' becomes 'HTTP_X_PAYSWIFT_SIGNATURE'
    $server = ['CONTENT_TYPE' => 'application/json'];

    foreach ($headers as $name => $value) {
        if (strtolower($name) === 'content-type') {
            continue; // already set above
        }
        $key          = 'HTTP_' . strtoupper(str_replace('-', '_', $name));
        $server[$key] = $value;
    }

    return test()->call(
        'POST',
        '/api/webhooks/payswift',
        [],      // parameters (not used for raw body)
        [],      // cookies
        [],      // files
        $server,
        $payload
    );
}

// A realistic JSON payload used across multiple tests.
function samplePayload(string $event = 'payment.succeeded'): string
{
    return json_encode([
        'event' => $event,
        'data'  => [
            'transaction_id' => 'txn_test_001',
            'amount'         => 150000,
            'currency'       => 'IDR',
        ],
    ]);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

it('accepts a valid webhook with a correct signature', function () {
    $payload  = samplePayload();
    $headers  = makeSignedHeaders($payload);

    $response = sendWebhook($payload, $headers);

    $response->assertStatus(Response::HTTP_OK);
    expect(WebhookLog::count())->toBe(1);
});

it('rejects a webhook with an invalid signature', function () {
    $payload  = samplePayload();
    // Generating a signature with the wrong secret will produce a different
    // HMAC value that hash_equals() will reject.
    $headers  = makeSignedHeaders($payload, secret: 'wrong-secret');

    $response = sendWebhook($payload, $headers);

    $response->assertStatus(Response::HTTP_UNAUTHORIZED)
             ->assertJson(['error' => 'Invalid webhook signature.']);

    // The controller was never reached, so no log should have been written.
    expect(WebhookLog::count())->toBe(0);
});

it('rejects a webhook when the signature header is missing', function () {
    $payload = samplePayload();
    $headers = makeSignedHeaders($payload);
    unset($headers['X-PaySwift-Signature']);

    $response = sendWebhook($payload, $headers);

    $response->assertStatus(Response::HTTP_UNAUTHORIZED)
             ->assertJson(['error' => 'Missing webhook headers.']);
});

it('rejects a webhook when the timestamp header is missing', function () {
    $payload = samplePayload();
    $headers = makeSignedHeaders($payload);
    unset($headers['X-PaySwift-Timestamp']);

    $response = sendWebhook($payload, $headers);

    $response->assertStatus(Response::HTTP_UNAUTHORIZED)
             ->assertJson(['error' => 'Missing webhook headers.']);
});

it('rejects a webhook with an expired timestamp', function () {
    $payload      = samplePayload();
    // 400 seconds exceeds the 5-minute (300 second) tolerance window.
    $oldTimestamp = time() - 400;
    $headers      = makeSignedHeaders($payload, timestamp: $oldTimestamp);

    $response = sendWebhook($payload, $headers);

    $response->assertStatus(Response::HTTP_UNAUTHORIZED)
             ->assertJson(['error' => 'Webhook timestamp expired.']);

    expect(WebhookLog::count())->toBe(0);
});

it('rejects a duplicate event that has already been processed', function () {
    $payload = samplePayload();
    $eventId = 'evt_duplicate_001';

    // First delivery: signature is valid, event ID is new, should succeed.
    $headers = makeSignedHeaders($payload, eventId: $eventId);
    sendWebhook($payload, $headers)->assertStatus(Response::HTTP_OK);

    // Second delivery: same event ID but a fresh timestamp and valid signature,
    // exactly as a real payment gateway retry would look.
    // The idempotency guard in the controller should catch this and return 409.
    $headersRetry = makeSignedHeaders($payload, eventId: $eventId);
    sendWebhook($payload, $headersRetry)->assertStatus(Response::HTTP_CONFLICT);

    // Only one record in webhook_logs confirms processing happened exactly once.
    expect(WebhookLog::count())->toBe(1);
});
```

Run the tests:

```bash
./vendor/bin/pest
```

Expected output:

```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.10s

   PASS  Tests\Feature\PaySwiftWebhookTest
  ✓ it accepts a valid webhook with a correct signature                  0.06s
  ✓ it rejects a webhook with an invalid signature                       0.01s
  ✓ it rejects a webhook when the signature header is missing            0.01s
  ✓ it rejects a webhook when the timestamp header is missing            0.01s
  ✓ it rejects a webhook with an expired timestamp                       0.01s
  ✓ it rejects a duplicate event that has already been processed         0.01s

  Tests:  8 passed (14 assertions)
  Duration: 0.25s
```

All six PaySwift tests pass, and each one exercises a distinct security scenario.

## How Webhook Signature Verification Works Under the Hood {#how-it-works}

Now that the implementation is complete and tested, it is worth stepping back to understand why each decision in the code exists.

### The HMAC Primitive

HMAC stands for Hash-based Message Authentication Code. The key insight is that it is not simply a hash of the data. It is a hash of the data combined with a secret key using a mathematical construction that prevents someone from computing a valid HMAC without knowing the key. PHP exposes this as `hash_hmac(string $algo, string $data, string $key)`.

The flow works like this. PaySwift takes the raw JSON payload and computes `HMAC-SHA256(payload, sharedSecret)`. The result is a 64-character hex string that PaySwift attaches as the `X-PaySwift-Signature` header. When your server receives the request, it performs the identical computation on the payload it received. Because you both know the same secret, you can each independently arrive at the same value. An attacker who intercepts the request and changes even a single byte of the payload would need to recompute the signature, which requires knowledge of the secret. Without the secret, the forgery is computationally infeasible with SHA-256.

### Why `hash_equals()` and Not `===`

This is the most subtle security detail in the implementation. PHP's `===` operator is a short-circuit comparison: it stops and returns `false` the moment it finds a differing byte. This means a comparison that fails on the first byte returns in nanoseconds, while one that fails on the last byte takes slightly longer. An attacker making thousands of requests can measure these tiny timing differences to reconstruct a valid signature one character at a time. This technique is called a timing attack, and it is a documented real-world threat against naive hash comparisons.

`hash_equals()` always compares the complete length of both strings in constant time, regardless of where they differ. The timing signal disappears entirely. For any comparison that involves a secret or a signature, `hash_equals()` is the correct function to use.

### Why the Raw Body Matters

PHP's request helpers parse the JSON body into a PHP array when you call `$request->all()` or `$request->json()`. If you then call `json_encode()` on that array to recompute the HMAC, PHP's JSON encoder may produce different whitespace between keys, a different ordering of object keys, or different Unicode escape sequences than the original bytes PaySwift sent. Even a single extra space is enough to produce a completely different HMAC value. Using `$request->getContent()` gives you the exact byte sequence that crossed the wire and that PaySwift signed.

### Timestamp vs. Idempotency: Two Different Problems

These two mechanisms protect against different threats. The timestamp check prevents a classic replay attack, where an attacker captures a valid webhook in transit and re-sends it later. By rejecting any request timestamped more than five minutes ago, you ensure that a captured webhook has a very short useful lifetime for an attacker.

Idempotency handles a completely different scenario: legitimate duplicate deliveries. PaySwift retries the same event when your server fails to respond correctly. That retry will have a fresh timestamp and a valid signature, so it passes the middleware. The `webhook_logs` table is what catches it and prevents a duplicate payment record.

A useful mental model is that the timestamp check guards against malicious replay, while idempotency guards against operational retry. You need both because they solve different problems.

> **Production note:** Consider rotating your webhook secret periodically, every 90 days is a common interval. During the rotation window, accept signatures computed with either the old or the new secret before fully retiring the old one. This avoids a gap where legitimate webhooks arriving just after a deployment are incorrectly rejected.

## Conclusion {#conclusion}

You have built a production-ready webhook receiver that defends against forgery, replay attacks, and duplicate processing. Here are the key takeaways.

- **HMAC-SHA256 is the industry standard for webhook authentication.** Every major platform (Stripe, GitHub, Shopify, Slack) uses it to sign outgoing webhooks. Understanding the pattern lets you integrate with any provider by reading their documentation and adapting the header names and secret source.
- **Always read the raw body with `getContent()`.** Parsing the JSON first and re-encoding it can silently change the byte sequence and invalidate the signature. Your HMAC computation must happen over the exact bytes the sender signed.
- **Use `hash_equals()` for signature comparisons, never `===`.** It closes a real timing attack vector with no performance cost. It is a one-function change that makes a meaningful security difference.
- **Timestamp validation prevents replay attacks.** A five-minute window is the industry convention. It accommodates legitimate delivery delays while ensuring captured requests expire quickly.
- **Idempotency handles legitimate retries.** A unique constraint on `event_id` combined with an application-level guard ensures that payment gateway retries never cause duplicate side effects in your business logic.
- **Middleware is the correct place for signature verification.** Keeping the HMAC check in a dedicated middleware keeps your controller focused on business logic and makes it trivial to apply the same verification to future webhook routes.