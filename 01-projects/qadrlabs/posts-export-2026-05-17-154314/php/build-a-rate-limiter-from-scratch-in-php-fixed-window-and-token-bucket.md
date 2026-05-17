---
title: "Build a Rate Limiter from Scratch in PHP: Fixed Window and Token Bucket"
slug: "build-a-rate-limiter-from-scratch-in-php-fixed-window-and-token-bucket"
category: "php"
date: "2026-04-29"
status: "published"
---

Your login form accepts 1,000 password attempts per minute and PHP will process every single one without complaint. Your public API endpoint has no ceiling on how many times a single IP can call it in a second. Your password reset flow can be triggered in a loop indefinitely. This is not a hypothetical; it is the default state of every web application that has not explicitly added rate limiting. Left unaddressed, brute-force attacks, credential stuffing, and API scraping are not a matter of if but when. The usual answer is to reach for a framework's built-in throttle middleware, which works fine until you need to debug it, configure it precisely, or understand why a client is hitting a 429 that you did not expect. The better answer, at least once, is to build it yourself.

In this tutorial, you will implement two of the most widely used rate limiting algorithms from scratch in plain PHP: the Fixed Window counter and the Token Bucket. You will abstract the storage layer behind an interface so the same algorithms work against an in-memory array, a file, or eventually Redis without changing a line of algorithm code. By the end, you will also understand the boundary problem that makes Fixed Window exploitable in certain scenarios, and why Token Bucket was designed to solve exactly that.

## Overview {#overview}

This tutorial runs entirely as a plain PHP project. No framework is required. The goal is to keep the algorithm mechanics visible and unobscured by framework abstractions.

### What You'll Build

- A `StorageInterface` with two implementations: `InMemoryStorage` and `FileStorage`
- A `FixedWindowLimiter` that enforces a strict request count per time window
- A `TokenBucketLimiter` that enforces a long-term average rate while allowing controlled bursts
- A `QuoteApi` simulation that exercises both limiters with two types of clients
- A boundary attack demo that shows exactly how Fixed Window can be exploited and why Token Bucket cannot

### What You'll Learn

- How Fixed Window counting works at the code level, including the reset logic
- How Token Bucket calculates token refills lazily using elapsed time
- How HTTP headers `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`, and `Retry-After` are constructed and why they matter
- How to apply the Open/Closed Principle to storage so algorithms never need to change when the backend does
- When to choose Fixed Window versus Token Bucket based on your use case

### What You'll Need

- PHP 8.1 or higher
- Composer (for PSR-4 autoloading only; no third-party packages required)
- Comfortable with PHP interfaces, type hints, and basic OOP

## Step 1: Project Setup {#step-1-project-setup}

Create the project directory and move into it:

```bash
mkdir rate-limiter && cd rate-limiter
```

Create `composer.json` for PSR-4 autoloading:

```json
{
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    }
}
```

Generate the autoloader:

```bash
composer dump-autoload
```

Create the full directory and file structure:

```bash
mkdir -p src/Storage src/Limiters
touch src/Storage/StorageInterface.php
touch src/Storage/InMemoryStorage.php
touch src/Storage/FileStorage.php
touch src/Limiters/FixedWindowLimiter.php
touch src/Limiters/TokenBucketLimiter.php
touch src/QuoteApi.php
touch simulate.php
```

Your final structure will look like this:

```
rate-limiter/
├── composer.json
├── simulate.php
└── src/
    ├── QuoteApi.php
    ├── Storage/
    │   ├── StorageInterface.php
    │   ├── InMemoryStorage.php
    │   └── FileStorage.php
    └── Limiters/
        ├── FixedWindowLimiter.php
        └── TokenBucketLimiter.php
```

## Step 2: Define the Storage Interface and In-Memory Implementation {#step-2-storage-interface}

Before writing a single line of algorithm code, define where state will be stored. A rate limiter is stateful by nature: it must remember how many requests a given identity has made, and when. The algorithm logic should not care whether that memory lives in a PHP array, a JSON file, or Redis. The `StorageInterface` is the contract that makes this separation possible.

Open `src/Storage/StorageInterface.php`:

```php
<?php

namespace App\Storage;

interface StorageInterface
{
    /**
     * Retrieve a stored value by key.
     * Returns null if the key does not exist.
     */
    public function get(string $key): mixed;

    /**
     * Store a value under a key.
     * If $ttl is provided (in seconds), the value should expire after that duration.
     * Not all storage backends enforce TTL natively; implementations may handle it
     * manually or ignore it for simplicity.
     */
    public function set(string $key, mixed $value, int $ttl = 0): void;

    /**
     * Remove a key from storage entirely.
     */
    public function delete(string $key): void;
}
```

Three methods. That is the entire surface area the algorithms need. Any backend that can read, write, and delete a keyed value can implement this contract.

Now create the simplest possible implementation. Open `src/Storage/InMemoryStorage.php`:

```php
<?php

namespace App\Storage;

class InMemoryStorage implements StorageInterface
{
    // All data lives in a plain PHP array for the lifetime of the script
    private array $data = [];

    // Tracks per-key expiration timestamps (Unix timestamps)
    private array $expiry = [];

    public function get(string $key): mixed
    {
        // If this key has an expiry time set and that time has passed, treat it as gone
        if (isset($this->expiry[$key]) && time() > $this->expiry[$key]) {
            $this->delete($key);
            return null;
        }

        return $this->data[$key] ?? null;
    }

    public function set(string $key, mixed $value, int $ttl = 0): void
    {
        $this->data[$key] = $value;

        if ($ttl > 0) {
            // Store the Unix timestamp at which this key should be considered expired
            $this->expiry[$key] = time() + $ttl;
        }
    }

    public function delete(string $key): void
    {
        unset($this->data[$key], $this->expiry[$key]);
    }
}
```

`InMemoryStorage` is ideal for simulations, unit tests, or any scenario where persistence across script runs is not needed. All data vanishes when the PHP process ends.

## Step 3: Build the Fixed Window Rate Limiter {#step-3-fixed-window}

The Fixed Window algorithm divides time into discrete, equal-length intervals called windows. Each identity (an IP address, a user ID, an API key) gets a counter that starts at zero when the window opens. Every request increments the counter. Once the counter reaches the configured limit, every subsequent request in that window is rejected. When the window closes and a new one opens, the counter resets to zero.

The mental model is a turnstile at a museum that resets every hour. The first 100 visitors get through. The next person to arrive before the hour is up is told to come back.

Open `src/Limiters/FixedWindowLimiter.php`:

```php
<?php

namespace App\Limiters;

use App\Storage\StorageInterface;

class FixedWindowLimiter
{
    public function __construct(
        private StorageInterface $storage,
        private int $limit,         // Maximum requests allowed per window
        private int $windowSeconds  // Window duration in seconds
    ) {}

    /**
     * Attempt to consume one request slot for the given identity key.
     * Returns true if the request is allowed, false if the limit is exceeded.
     */
    public function attempt(string $key): bool
    {
        $now        = time();
        $storageKey = 'fw:' . $key;

        // Load the current window record, or start fresh
        $record = $this->storage->get($storageKey);

        if ($record === null) {
            // First request ever from this identity: open a new window right now
            $record = [
                'count'      => 0,
                'window_start' => $now,
            ];
        }

        // Check if the current window has expired
        $windowAge = $now - $record['window_start'];

        if ($windowAge >= $this->windowSeconds) {
            // This window is over; open a fresh one starting from now
            $record = [
                'count'        => 0,
                'window_start' => $now,
            ];
        }

        // Check if the limit has already been reached in this window
        if ($record['count'] >= $this->limit) {
            // Save the unchanged record (we still need the window_start for headers)
            $this->storage->set($storageKey, $record, $this->windowSeconds);
            return false;
        }

        // Increment the counter and persist the updated record
        $record['count']++;
        $this->storage->set($storageKey, $record, $this->windowSeconds);

        return true;
    }

    /**
     * Return the standard X-RateLimit-* headers for this identity.
     * These inform the client of its current standing without requiring it to guess.
     */
    public function getHeaders(string $key): array
    {
        $storageKey = 'fw:' . $key;
        $record     = $this->storage->get($storageKey);
        $now        = time();

        $count       = $record['count'] ?? 0;
        $windowStart = $record['window_start'] ?? $now;
        $resetAt     = $windowStart + $this->windowSeconds;
        $remaining   = max(0, $this->limit - $count);

        return [
            'X-RateLimit-Limit'     => $this->limit,
            'X-RateLimit-Remaining' => $remaining,
            'X-RateLimit-Reset'     => $resetAt,   // Unix timestamp when the window resets
        ];
    }
}
```

Two things are worth noting here. First, the window is anchored to the timestamp of the *first request in that window*, not to a calendar boundary like the top of the minute. This means if Alice's first request arrives at 10:14:37, her window runs until 10:15:37, not 10:15:00. Second, `getHeaders()` is separate from `attempt()` so you can always read headers regardless of whether the last attempt was allowed or rejected.

Test this in isolation by temporarily adding the following to `simulate.php` and running it:

```php
<?php

require 'vendor/autoload.php';

use App\Storage\InMemoryStorage;
use App\Limiters\FixedWindowLimiter;

$storage = new InMemoryStorage();
$limiter = new FixedWindowLimiter($storage, limit: 5, windowSeconds: 60);

echo "=== Fixed Window: 5 req / 60s ===" . PHP_EOL . PHP_EOL;

for ($i = 1; $i <= 7; $i++) {
    $allowed = $limiter->attempt('user-alice');
    $headers = $limiter->getHeaders('user-alice');
    $status  = $allowed ? 'ALLOWED' : 'REJECTED (429)';

    echo "Request #{$i}: {$status}" . PHP_EOL;
    echo "  Remaining : " . $headers['X-RateLimit-Remaining'] . PHP_EOL;
    echo "  Reset at  : " . date('H:i:s', $headers['X-RateLimit-Reset']) . PHP_EOL . PHP_EOL;
}
```

```bash
php simulate.php
```

Expected output:

```
=== Fixed Window: 5 req / 60s ===

Request #1: ALLOWED
  Remaining : 4
  Reset at  : 10:16:37

Request #2: ALLOWED
  Remaining : 3
  Reset at  : 10:16:37

Request #3: ALLOWED
  Remaining : 2
  Reset at  : 10:16:37

Request #4: ALLOWED
  Remaining : 1
  Reset at  : 10:16:37

Request #5: ALLOWED
  Remaining : 0
  Reset at  : 10:16:37

Request #6: REJECTED (429)
  Remaining : 0
  Reset at  : 10:16:37

Request #7: REJECTED (429)
  Remaining : 0
  Reset at  : 10:16:37
```

Requests 1 through 5 pass. Requests 6 and 7 are blocked. The reset timestamp is the same for all seven because the window was opened on request 1 and has not expired. Clear `simulate.php` before proceeding.

## Step 4: Build the Token Bucket Rate Limiter {#step-4-token-bucket}

The Token Bucket algorithm models capacity as an accumulation of tokens over time. Imagine a bucket with a maximum capacity of, say, 10 tokens. Tokens are added to the bucket at a fixed rate: for example, 2 tokens every 10 seconds. When a request arrives, it must consume one token from the bucket to proceed. If the bucket is empty, the request is rejected. If the client stops sending requests for a while, tokens accumulate up to the bucket's maximum, allowing a burst of up to 10 requests in a short time.

The key difference from Fixed Window: there is no hard boundary reset. The bucket drains and refills continuously. A client that spaces out their requests naturally will always have tokens available. A client that hammers the endpoint will drain the bucket and be throttled proportionally to how hard they pushed.

One important implementation detail: the refill is calculated *lazily*. Rather than running a background timer that adds tokens every N seconds, you compute how many tokens should have been added since the last recorded timestamp every time `attempt()` is called. This avoids any background process and works correctly in stateless PHP request/response cycles.

Open `src/Limiters/TokenBucketLimiter.php`:

```php
<?php

namespace App\Limiters;

use App\Storage\StorageInterface;

class TokenBucketLimiter
{
    public function __construct(
        private StorageInterface $storage,
        private int $capacity,      // Maximum tokens the bucket can hold
        private int $refillRate,    // How many tokens to add per refill period
        private int $refillPeriod   // Refill period in seconds
    ) {}

    /**
     * Attempt to consume one token from the bucket for the given identity.
     * Returns true if a token was available, false if the bucket is empty.
     */
    public function attempt(string $key): bool
    {
        $now        = microtime(true); // Use float for sub-second precision
        $storageKey = 'tb:' . $key;

        $record = $this->storage->get($storageKey);

        if ($record === null) {
            // First request: start with a full bucket
            $record = [
                'tokens'      => $this->capacity,
                'last_refill' => $now,
            ];
        }

        // Calculate how much time has passed since the last refill timestamp
        $elapsed = $now - $record['last_refill'];

        // How many complete refill periods have elapsed?
        // For example: 25 seconds elapsed at a rate of 2 tokens per 10 seconds = 4 new tokens
        $periodsElapsed = floor($elapsed / $this->refillPeriod);
        $newTokens      = $periodsElapsed * $this->refillRate;

        if ($newTokens > 0) {
            // Add the earned tokens, but never exceed the bucket's capacity
            $record['tokens']      = min($this->capacity, $record['tokens'] + $newTokens);

            // Advance the last_refill timestamp by the number of complete periods that elapsed.
            // This preserves any partial period for the next calculation rather than discarding it.
            $record['last_refill'] += $periodsElapsed * $this->refillPeriod;
        }

        // Check if there is at least one token available
        if ($record['tokens'] < 1) {
            $this->storage->set($storageKey, $record);
            return false;
        }

        // Consume one token and save the updated state
        $record['tokens']--;
        $this->storage->set($storageKey, $record);

        return true;
    }

    /**
     * Return rate limit headers for this identity.
     * For Token Bucket, the most useful header on rejection is Retry-After,
     * which tells the client how many seconds to wait before a token is available.
     */
    public function getHeaders(string $key): array
    {
        $storageKey = 'tb:' . $key;
        $record     = $this->storage->get($storageKey);

        $tokens = $record ? (int) $record['tokens'] : $this->capacity;

        // Estimate seconds until the next token arrives
        $retryAfter = $tokens < 1
            ? ceil($this->refillPeriod / $this->refillRate)
            : 0;

        return [
            'X-RateLimit-Limit'     => $this->capacity,
            'X-RateLimit-Remaining' => max(0, $tokens),
            'Retry-After'           => $retryAfter, // 0 means no wait needed
        ];
    }
}
```

The key logic lives in the refill block. Notice that `last_refill` is advanced by `$periodsElapsed * $this->refillPeriod` rather than set directly to `$now`. This is intentional: it preserves the fractional time that did not complete a full period. If the refill period is 10 seconds and 17 seconds have elapsed, one full period earns tokens (10 seconds worth), and 7 seconds of credit carries forward to the next calculation. Setting `last_refill = $now` directly would discard that 7-second credit every time.

Test the Token Bucket in isolation with a burst scenario. Add the following to `simulate.php`:

```php
<?php

require 'vendor/autoload.php';

use App\Storage\InMemoryStorage;
use App\Limiters\TokenBucketLimiter;

$storage = new InMemoryStorage();

// Bucket holds 5 tokens, refills 1 token every 5 seconds
$limiter = new TokenBucketLimiter($storage, capacity: 5, refillRate: 1, refillPeriod: 5);

echo "=== Token Bucket: capacity=5, refill=1 per 5s ===" . PHP_EOL . PHP_EOL;

// Simulate a burst: 8 requests sent immediately with no pause
for ($i = 1; $i <= 8; $i++) {
    $allowed = $limiter->attempt('user-bob');
    $headers = $limiter->getHeaders('user-bob');
    $status  = $allowed ? 'ALLOWED' : 'REJECTED';

    echo "Request #{$i}: {$status}";
    echo " | Tokens left: " . $headers['X-RateLimit-Remaining'];

    if (! $allowed) {
        echo " | Retry-After: " . $headers['Retry-After'] . "s";
    }

    echo PHP_EOL;
}
```

```bash
php simulate.php
```

Expected output:

```
=== Token Bucket: capacity=5, refill=1 per 5s ===

Request #1: ALLOWED | Tokens left: 4
Request #2: ALLOWED | Tokens left: 3
Request #3: ALLOWED | Tokens left: 2
Request #4: ALLOWED | Tokens left: 1
Request #5: ALLOWED | Tokens left: 0
Request #6: REJECTED | Tokens left: 0 | Retry-After: 5s
Request #7: REJECTED | Tokens left: 0 | Retry-After: 5s
Request #8: REJECTED | Tokens left: 0 | Retry-After: 5s
```

The bucket started full (5 tokens). Five requests were served, then the bucket was empty. Requests 6 through 8 were rejected with a `Retry-After` of 5 seconds, telling the client exactly how long to wait before trying again. Clear `simulate.php` before continuing.

## Step 5: Add File-Based Storage {#step-5-file-storage}

`InMemoryStorage` works perfectly for a single script run, but its data disappears when the process ends. For a real web application where each HTTP request is a new PHP process, state must persist somewhere. `FileStorage` is the simplest persistent option: each key is stored as a JSON file on disk.

Open `src/Storage/FileStorage.php`:

```php
<?php

namespace App\Storage;

class FileStorage implements StorageInterface
{
    public function __construct(private string $directory)
    {
        // Create the storage directory if it does not already exist
        if (! is_dir($this->directory)) {
            mkdir($this->directory, 0755, true);
        }
    }

    public function get(string $key): mixed
    {
        $path = $this->path($key);

        if (! file_exists($path)) {
            return null;
        }

        $payload = json_decode(file_get_contents($path), associative: true);

        // Respect TTL: if the expiry time has passed, treat the key as non-existent
        if (isset($payload['expires_at']) && time() > $payload['expires_at']) {
            $this->delete($key);
            return null;
        }

        return $payload['value'];
    }

    public function set(string $key, mixed $value, int $ttl = 0): void
    {
        $payload = ['value' => $value];

        if ($ttl > 0) {
            $payload['expires_at'] = time() + $ttl;
        }

        file_put_contents($this->path($key), json_encode($payload));
    }

    public function delete(string $key): void
    {
        $path = $this->path($key);

        if (file_exists($path)) {
            unlink($path);
        }
    }

    /**
     * Derive a safe filesystem path from an arbitrary key string.
     * md5() is used here for brevity; in production you would want a more
     * collision-resistant approach for keys that come from user input.
     */
    private function path(string $key): string
    {
        return $this->directory . '/' . md5($key) . '.json';
    }
}
```

To swap from in-memory to file-based storage, change exactly one line at the call site. The limiter classes never change. Verify this by updating the constructor call in `simulate.php`:

```php
// Before (in-memory, data lost after script ends)
$storage = new InMemoryStorage();

// After (file-based, data persists between script runs)
$storage = new FileStorage(__DIR__ . '/storage');
```

Run the fixed window test twice in a row using `FileStorage`. The second run will pick up the counter from where the first run left off, which is the expected behavior for a persistent rate limiter. This is what `InMemoryStorage` cannot do and what `FileStorage` was built for.

## Step 6: Build the Quote API Simulation {#step-6-quote-api}

Now put both limiters to work in a realistic scenario. The `QuoteApi` class represents a fictional API endpoint that returns a random quote. It applies two different limiting strategies to two different types of client.

Open `src/QuoteApi.php`:

```php
<?php

namespace App;

use App\Limiters\FixedWindowLimiter;
use App\Limiters\TokenBucketLimiter;

class QuoteApi
{
    private array $quotes = [
        'The only way to do great work is to love what you do.',
        'In the middle of every difficulty lies opportunity.',
        'It does not matter how slowly you go as long as you do not stop.',
        'Everything you have ever wanted is on the other side of fear.',
        'Success is not final, failure is not fatal.',
    ];

    public function __construct(
        private FixedWindowLimiter  $anonymousLimiter,
        private TokenBucketLimiter  $apiKeyLimiter
    ) {}

    /**
     * Handle an anonymous request identified by IP address.
     * Returns an array representing an HTTP-like response.
     */
    public function handleAnonymous(string $ip): array
    {
        $allowed = $this->anonymousLimiter->attempt($ip);
        $headers = $this->anonymousLimiter->getHeaders($ip);

        if (! $allowed) {
            return [
                'status'  => 429,
                'body'    => 'Too Many Requests',
                'headers' => $headers,
            ];
        }

        return [
            'status'  => 200,
            'body'    => $this->randomQuote(),
            'headers' => $headers,
        ];
    }

    /**
     * Handle a request from an authenticated client identified by API key.
     */
    public function handleApiKey(string $apiKey): array
    {
        $allowed = $this->apiKeyLimiter->attempt($apiKey);
        $headers = $this->apiKeyLimiter->getHeaders($apiKey);

        if (! $allowed) {
            return [
                'status'  => 429,
                'body'    => 'Too Many Requests',
                'headers' => $headers,
            ];
        }

        return [
            'status'  => 200,
            'body'    => $this->randomQuote(),
            'headers' => $headers,
        ];
    }

    private function randomQuote(): string
    {
        return $this->quotes[array_rand($this->quotes)];
    }
}
```

## Step 7: Try It Out {#step-7-try-it-out}

Now write the full simulation. This `simulate.php` exercises three scenarios: an anonymous client hitting the Fixed Window limit, an API-key client bursting through a Token Bucket, and the boundary attack demonstration that reveals Fixed Window's structural weakness.

```php
<?php

require 'vendor/autoload.php';

use App\Storage\InMemoryStorage;
use App\Limiters\FixedWindowLimiter;
use App\Limiters\TokenBucketLimiter;
use App\QuoteApi;

// Helper: pretty-print a response from QuoteApi
function printResponse(int $requestNum, array $response): void
{
    $icon   = $response['status'] === 200 ? 'OK  ' : '429 ';
    $body   = $response['status'] === 200
        ? substr($response['body'], 0, 45) . '...'
        : $response['body'];

    echo "  [{$icon}] Request #{$requestNum}: {$body}" . PHP_EOL;

    foreach ($response['headers'] as $name => $value) {
        echo "         {$name}: {$value}" . PHP_EOL;
    }

    echo PHP_EOL;
}

// --- Setup ---
$storage = new InMemoryStorage();

// Anonymous clients: 5 requests per 60-second window
$anonymousLimiter = new FixedWindowLimiter($storage, limit: 5, windowSeconds: 60);

// API-key clients: bucket of 10 tokens, refills 2 tokens every 10 seconds
$apiKeyLimiter = new TokenBucketLimiter($storage, capacity: 10, refillRate: 2, refillPeriod: 10);

$api = new QuoteApi($anonymousLimiter, $apiKeyLimiter);

// =============================================================
// Scenario 1: Anonymous client (IP-based, Fixed Window)
// =============================================================
echo "============================================" . PHP_EOL;
echo " Scenario 1: Anonymous Client (Fixed Window)" . PHP_EOL;
echo " Limit: 5 requests per 60 seconds           " . PHP_EOL;
echo "============================================" . PHP_EOL . PHP_EOL;

for ($i = 1; $i <= 7; $i++) {
    $response = $api->handleAnonymous('203.0.113.42');
    printResponse($i, $response);
}

// =============================================================
// Scenario 2: API-key client (Token Bucket)
// =============================================================
echo "============================================" . PHP_EOL;
echo " Scenario 2: API-Key Client (Token Bucket)  " . PHP_EOL;
echo " Capacity: 10 tokens, refill 2 per 10s      " . PHP_EOL;
echo "============================================" . PHP_EOL . PHP_EOL;

for ($i = 1; $i <= 13; $i++) {
    $response = $api->handleApiKey('api-key-xyz-001');
    printResponse($i, $response);
}

// =============================================================
// Scenario 3: The Boundary Attack on Fixed Window
// =============================================================
echo "============================================" . PHP_EOL;
echo " Scenario 3: Boundary Attack Demonstration  " . PHP_EOL;
echo " Attacker sends 5 requests at window end,   " . PHP_EOL;
echo " then 5 more at window start (2s later).    " . PHP_EOL;
echo "============================================" . PHP_EOL . PHP_EOL;

// New storage and limiter so the attacker starts fresh
$attackStorage = new InMemoryStorage();
$attackLimiter = new FixedWindowLimiter($attackStorage, limit: 5, windowSeconds: 5);
$attackApi     = new QuoteApi($attackLimiter, $apiKeyLimiter);

echo "  [Window 1: first 5 requests use up the limit]" . PHP_EOL . PHP_EOL;

for ($i = 1; $i <= 5; $i++) {
    $response = $attackApi->handleAnonymous('attacker-ip');
    printResponse($i, $response);
}

echo "  [Sleeping 5 seconds for window to reset...]" . PHP_EOL . PHP_EOL;
sleep(5);

echo "  [Window 2: new window opens, attacker gets 5 more immediately]" . PHP_EOL . PHP_EOL;

for ($i = 6; $i <= 10; $i++) {
    $response = $attackApi->handleAnonymous('attacker-ip');
    printResponse($i, $response);
}

echo "  Result: 10 requests served in ~5 seconds against a '5 per 5s' limit." . PHP_EOL;
echo "  This is the boundary problem. Token Bucket does not have this weakness." . PHP_EOL;
```

Run the full simulation:

```bash
php simulate.php
```

Expected output:

```
============================================
 Scenario 1: Anonymous Client (Fixed Window)
 Limit: 5 requests per 60 seconds
============================================

  [OK  ] Request #1: The only way to do great work is to lo...
         X-RateLimit-Limit: 5
         X-RateLimit-Remaining: 4
         X-RateLimit-Reset: 1719820597

  [OK  ] Request #2: In the middle of every difficulty lies...
         X-RateLimit-Limit: 5
         X-RateLimit-Remaining: 3
         X-RateLimit-Reset: 1719820597

  [OK  ] Request #3: Success is not final, failure is not f...
         X-RateLimit-Limit: 5
         X-RateLimit-Remaining: 2
         X-RateLimit-Reset: 1719820597

  [OK  ] Request #4: Everything you have ever wanted is on ...
         X-RateLimit-Limit: 5
         X-RateLimit-Remaining: 1
         X-RateLimit-Reset: 1719820597

  [OK  ] Request #5: It does not matter how slowly you go a...
         X-RateLimit-Limit: 5
         X-RateLimit-Remaining: 0
         X-RateLimit-Reset: 1719820597

  [429 ] Request #6: Too Many Requests
         X-RateLimit-Limit: 5
         X-RateLimit-Remaining: 0
         X-RateLimit-Reset: 1719820597

  [429 ] Request #7: Too Many Requests
         X-RateLimit-Limit: 5
         X-RateLimit-Remaining: 0
         X-RateLimit-Reset: 1719820597

============================================
 Scenario 2: API-Key Client (Token Bucket)
 Capacity: 10 tokens, refill 2 per 10s
============================================

  [OK  ] Request #1: The only way to do great work is to lo...
         X-RateLimit-Limit: 10
         X-RateLimit-Remaining: 9
         Retry-After: 0

  [OK  ] Request #2: In the middle of every difficulty lies...
         X-RateLimit-Limit: 10
         X-RateLimit-Remaining: 8
         Retry-After: 0

  [... requests #3 through #10: ALLOWED, tokens draining ...]

  [OK  ] Request #10: Success is not final, failure is not f...
         X-RateLimit-Limit: 10
         X-RateLimit-Remaining: 0
         Retry-After: 0

  [429 ] Request #11: Too Many Requests
         X-RateLimit-Limit: 10
         X-RateLimit-Remaining: 0
         Retry-After: 5

  [429 ] Request #12: Too Many Requests
         X-RateLimit-Limit: 10
         X-RateLimit-Remaining: 0
         Retry-After: 5

  [429 ] Request #13: Too Many Requests
         X-RateLimit-Limit: 10
         X-RateLimit-Remaining: 0
         Retry-After: 5

============================================
 Scenario 3: Boundary Attack Demonstration
 Attacker sends 5 requests at window end,
 then 5 more at window start (2s later).
============================================

  [Window 1: first 5 requests use up the limit]

  [OK  ] Request #1: ...
  [OK  ] Request #2: ...
  [OK  ] Request #3: ...
  [OK  ] Request #4: ...
  [OK  ] Request #5: ...

  [Sleeping 5 seconds for window to reset...]

  [Window 2: new window opens, attacker gets 5 more immediately]

  [OK  ] Request #6: ...
  [OK  ] Request #7: ...
  [OK  ] Request #8: ...
  [OK  ] Request #9: ...
  [OK  ] Request #10: ...

  Result: 10 requests served in ~5 seconds against a '5 per 5s' limit.
  This is the boundary problem. Token Bucket does not have this weakness.
```

All three scenarios behave as expected. Scenario 3 confirms the boundary attack in practice.

## Understanding the Boundary Problem {#understanding-boundary-problem}

The Fixed Window boundary problem is not a bug in your implementation. It is a structural property of the algorithm. To understand why, consider a limit of 5 requests per 60 seconds.

With Fixed Window, time looks like a series of discrete boxes. Each box is 60 seconds wide. A client that exhausts their 5 requests in the last second of one box and immediately sends 5 more in the first second of the next box has sent 10 requests in roughly 2 seconds, yet both batches were individually within the limit.

```
Timeline:   |--- Window 1 (60s) ---|--- Window 2 (60s) ---|
Attacker:                     [5 OK]|[5 OK]
                                    ^
                              Window boundary
                       10 requests pass in ~2 seconds
```

The algorithm sees only within its own window. It has no memory of what happened in the previous one. This is why the attack works.

Token Bucket does not have this property because there is no boundary to exploit. The bucket's capacity is a continuous ceiling, not a periodic reset. An attacker who drains all 10 tokens in window one will not have 10 tokens available at the start of "window two" because there is no window two. There is only a bucket that refills at 2 tokens per 10 seconds from the moment it was drained. Even if the attacker waits precisely the right amount of time, they will receive exactly 2 tokens, not 10.

```
Token Bucket (capacity=10, refill=2 per 10s):

t=0s:  [10 tokens] --- burst of 10 requests ---> [0 tokens]
t=10s: [2 tokens]  --- burst of 2 requests  ---> [0 tokens]
t=20s: [2 tokens]  --- burst of 2 requests  ---> [0 tokens]
```

No matter how precisely the attacker times their requests, they cannot accumulate more tokens than the refill rate allows. This makes Token Bucket well-suited for endpoints where a boundary burst would be dangerous, such as login forms, payment initiation, or SMS verification.

## Choosing the Right Algorithm {#choosing-the-right-algorithm}

Neither algorithm is universally superior. The right choice depends on what you are protecting and what kind of traffic pattern is acceptable.

**Fixed Window** is the right choice when the use case involves clearly bounded accounting periods. Content management systems that limit edits per hour, free-tier APIs with a daily request quota, or admin actions limited to N per day all fit this model naturally. The limit is easy to explain to users ("you get 100 API calls per hour") and easy to implement. The boundary problem matters less when the window is long (hours or days) because the attacker's window of exploitation is proportionally large and therefore less useful for burst attacks.

**Token Bucket** is the right choice when the concern is burst protection rather than accounting. Login endpoints, password reset flows, payment API calls, and SMS-sending routes are all situations where you want to allow a small burst of legitimate retries while making brute-force attacks impractical. The continuous refill model means there is no "reset moment" that an attacker can time their requests around. It is also more forgiving for legitimate users with irregular but reasonable usage patterns.

For most public API endpoints that are developer-facing, Token Bucket is the stronger default. It enforces a steady average rate while allowing short bursts that match real-world usage patterns. For internal admin tools, dashboards, and any UI where the user understands the concept of an hourly or daily limit, Fixed Window is simpler to reason about and explain.

One final practical note: the `StorageInterface` you built means you can swap either algorithm from `InMemoryStorage` to `FileStorage` to a Redis-backed implementation without touching a single line in `FixedWindowLimiter` or `TokenBucketLimiter`. When you are ready to scale beyond a single server, that swap is a one-line change at the call site.

## Conclusion {#conclusion}

Building a rate limiter from scratch makes the tradeoffs between algorithms concrete rather than abstract. The two implementations in this tutorial cover the most common real-world cases, and the storage abstraction makes them practical for production use.

- **Fixed Window is simple but has a structural weakness at window boundaries.** A client can send twice the allowed requests in a very short time by splitting a burst across two consecutive windows. This matters more at short window durations (seconds, minutes) than long ones (hours, days).
- **Token Bucket eliminates the boundary problem through continuous refill.** There is no reset moment to exploit. Tokens accumulate gradually and cap at capacity, so a burst is only possible if the client has been patient enough to let the bucket refill.
- **Lazy refill calculation is what makes Token Bucket viable in stateless PHP.** Rather than running a background timer, the bucket computes how many tokens it has earned based on elapsed time every time `attempt()` is called. The trick of advancing `last_refill` by whole periods rather than setting it to `now` preserves fractional credit accurately.
- **Storage abstraction is not premature optimization; it is essential design.** The `StorageInterface` contract means both algorithms are completely indifferent to whether state lives in memory, on disk, or in Redis. Switching backends is a one-line change with zero risk to the algorithm logic.
- **HTTP headers are a first-class part of rate limiting.** `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`, and `Retry-After` are not optional polish. They are what allows a well-behaved client to adapt its behavior rather than blindly retrying and making the situation worse.