---
title: "Passwordless Login with Magic Links in Laravel 13"
slug: "passwordless-login-with-magic-links-in-laravel-13"
category: "Laravel"
date: "2026-04-28"
status: "published"
---

Every Laravel application eventually faces the same authentication overhead: password reset flows, "forgot password" emails, bcrypt hashing, and the ever-present risk that your users are reusing `hunter2` across every site they visit. For internal tools and portals where accounts are provisioned by an admin rather than self-registered, the entire password layer becomes dead weight. The user never chose a password to begin with, so of course they forget it by next Tuesday. You end up maintaining a full password reset system just to work around a problem that should not exist.

Magic link authentication removes the problem entirely. Instead of asking for a password, the application sends a one-time link to the user's inbox. They click it, they are in. The link is cryptographically signed so it cannot be forged, it expires after fifteen minutes, and it self-destructs after the first use so replay attacks are not possible. The result is an authentication flow that is simultaneously more secure and easier to use.

This tutorial builds a complete magic link login system in Laravel 13 from scratch, without any third-party packages. We use two layers of protection: Laravel's built-in `URL::temporarySignedRoute()` to guarantee the link has not been tampered with, and a `login_tokens` database table to enforce one-time use. Understanding why both layers are necessary is half the lesson.

## Overview {#overview}

This tutorial uses a standalone approach. No Breeze, no Jetstream, no external auth packages. Every piece of the system is code we write ourselves, which means you will understand exactly how it works and can adapt it freely.

### What You'll Build

- A one-field login form that accepts an email address
- A magic link dispatch system that sends a signed, expiring URL to the user's inbox
- A verification endpoint that authenticates the user on the first click and rejects all subsequent attempts
- A protected dashboard page that confirms the login worked
- A logout action that properly clears the session
- Eleven Pest tests that cover the full flow including security edge cases

### What You'll Learn

- How `URL::temporarySignedRoute()` works and why it prevents link forgery
- How to combine signed URLs with a database token to achieve true one-time use
- How to hash tokens before storing them so a database breach cannot be used to replay links
- How to prevent user enumeration by returning identical responses for known and unknown emails
- How to rate-limit the link-send endpoint using Laravel's built-in throttle middleware
- How to write Pest tests that cover the full auth flow including edge cases

### What You'll Need

- PHP 8.3 or higher
- Laravel 13 (installed via `composer create-project laravel/laravel`)
- A mail driver configured in `.env` (Mailtrap or `MAIL_MAILER=log` both work for local development)
- Basic familiarity with Laravel routing, Eloquent models, and Notifications

## Step 1: Install Pest {#step-1-install-pest}

A fresh Laravel 13 project installed via `composer create-project` ships with PHPUnit, not Pest. Since this tutorial uses Pest, we need to swap them out before writing any tests.

First, remove PHPUnit:

```bash
composer remove phpunit/phpunit
```

Then install Pest along with its Laravel plugin:

```bash
composer require pestphp/pest --dev --with-all-dependencies
```

Finally, run the Pest initializer. This creates the `tests/Pest.php` configuration file and sets up the test environment:

```bash
./vendor/bin/pest --init
```

Pest is now ready. We will add the `RefreshDatabase` trait to `tests/Pest.php` in the testing step so that the in-memory SQLite database is migrated fresh before each test.

## Step 2: Create the LoginToken Model and Migration {#step-2-create-login-token-model}

We need a dedicated table to store magic link tokens. Rather than adding token columns to the `users` table, we create a separate `login_tokens` table. This design lets a user have multiple outstanding tokens at once, which matters when someone requests a new link before the previous one has expired.

Run the following command to generate the model and its migration together:

```bash
php artisan make:model LoginToken -m
```

Open the migration file inside `database/migrations/` and replace its contents with the schema below:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('login_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('token', 64)->unique();
            $table->timestamp('expires_at');
            $table->timestamp('consumed_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('login_tokens');
    }
};
```

Each column has a specific role. `user_id` links the token to its owner with a cascade delete so that tokens are cleaned up automatically when a user is removed. The `token` column stores a SHA-256 hash of the actual token value, never the raw string. `expires_at` is a hard timestamp after which the token is invalid regardless of anything else. `consumed_at` starts as `null` for every new token. When we set it to `now()` after a successful login, every subsequent attempt with the same token fails because we query with `whereNull('consumed_at')`.

Now open `app/Models/LoginToken.php` and replace its contents:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['token', 'expires_at', 'consumed_at'])]
class LoginToken extends Model
{
    protected function casts(): array
    {
        return [
            'expires_at' => 'datetime',
            'consumed_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isValid(): bool
    {
        return is_null($this->consumed_at) && $this->expires_at->isFuture();
    }
}
```

The `#[Fillable]` attribute is the Laravel 13 way to declare mass-assignable columns. We list only `token`, `expires_at`, and `consumed_at` because `user_id` is always set automatically by Eloquent when we create tokens through the relationship. The `casts()` method tells Eloquent to treat those two timestamp columns as `Carbon` instances, which allows us to call methods like `isFuture()` directly. The `isValid()` method combines both conditions into a single readable check that the controller can use.

Run the migration to create the table:

```bash
php artisan migrate
```

Expected output:

```
INFO  Running migrations.
  xxxx_xx_xx_create_login_tokens_table ......................................... 8ms DONE
```

Verify the table was created correctly by checking it in Tinker:

```bash
php artisan tinker
```

```php
>>> Schema::hasTable('login_tokens');
=> true
>>> Schema::getColumnListing('login_tokens');
=> [
     "id",
     "user_id",
     "token",
     "expires_at",
     "consumed_at",
     "created_at",
     "updated_at",
   ]
```

## Step 3: Add the Relationship and sendMagicLink to User {#step-3-update-user-model}

The `User` model needs two additions: a `loginTokens()` relationship so we can query and create tokens through the model, and a `sendMagicLink()` method that encapsulates the entire token-generation-and-dispatch workflow in one place. Keeping this logic on the model means we can call it from a controller, a console command, or a queued job without duplicating code.

Open `app/Models/User.php` and add the following imports at the top of the file, after the existing `use` statements:

```php
use App\Notifications\MagicLinkNotification;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;
```

Then add these two methods inside the `User` class, leaving everything else unchanged:

```php
public function loginTokens(): HasMany
{
    return $this->hasMany(LoginToken::class);
}

public function sendMagicLink(): void
{
    $this->loginTokens()->whereNull('consumed_at')->delete();

    $plainToken = Str::random(64);

    $this->loginTokens()->create([
        'token' => hash('sha256', $plainToken),
        'expires_at' => now()->addMinutes(15),
    ]);

    $this->notify(new MagicLinkNotification($plainToken));
}
```

`sendMagicLink()` does three things in sequence. First, it deletes any unconsumed tokens that already exist for this user. This ensures only the most recent link is ever valid. If someone requests three links in quick succession, only the third one will work. Second, it generates a 64-character cryptographically random plain token using `Str::random()`. This is what ends up in the email URL. Third, it stores a SHA-256 hash of that plain token in the database, not the token itself. SHA-256 is a one-way function, so someone with access to the `login_tokens` table cannot reverse the hashes back into URLs. The plain token is passed to the notification class, which uses it exactly once to build the signed URL.

## Step 4: Create the MagicLink Notification {#step-4-create-notification}

The notification class is responsible for building the signed URL and formatting the email. This is where `URL::temporarySignedRoute()` does its work.

Generate the notification class:

```bash
php artisan make:notification MagicLinkNotification
```

Open `app/Notifications/MagicLinkNotification.php` and replace its contents:

```php
<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\URL;

class MagicLinkNotification extends Notification
{
    use Queueable;

    public function __construct(private readonly string $plainToken) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $url = URL::temporarySignedRoute(
            'magic-link.verify',
            now()->addMinutes(15),
            ['token' => $this->plainToken]
        );

        return (new MailMessage)
            ->subject('Your login link for ' . config('app.name'))
            ->greeting('Hello, ' . $notifiable->name . '!')
            ->line('Click the button below to log in to your account. This link expires in 15 minutes and can only be used once.')
            ->action('Log In to ' . config('app.name'), $url)
            ->line('If you did not request this link, you can safely ignore this email. No account changes have been made.');
    }
}
```

`URL::temporarySignedRoute()` does two things simultaneously. It embeds an expiry timestamp directly into the URL, and it signs the entire URL including that expiry with an HMAC computed from your `APP_KEY`. When the user clicks the link and `$request->hasValidSignature()` is called in the controller, Laravel recomputes the HMAC and compares it to the signature in the URL. If anything has been modified, whether the token value, the expiry, or any other query parameter, the comparison fails and the request is rejected. The fifteen-minute window here matches the `expires_at` value we set in `sendMagicLink()` so that both checks expire at the same moment.

## Step 5: Build the MagicLinkController {#step-5-build-controller}

The controller handles three distinct concerns: displaying the login form, dispatching the magic link, and verifying the link when clicked. We will also add a logout action here to keep all auth-related logic in one place.

Generate the controller:

```bash
php artisan make:controller MagicLinkController
```

Open `app/Http/Controllers/MagicLinkController.php` and replace its contents:

```php
<?php

namespace App\Http\Controllers;

use App\Models\LoginToken;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class MagicLinkController extends Controller
{
    public function showForm(): View
    {
        return view('magic-link.form');
    }

    public function send(Request $request): RedirectResponse
    {
        $request->validate([
            'email' => ['required', 'email:rfc'],
        ]);

        $user = User::where('email', $request->email)->first();

        if ($user) {
            $user->sendMagicLink();
        }

        return redirect()->route('magic-link.sent');
    }

    public function verify(Request $request, string $token): RedirectResponse
    {
        if (! $request->hasValidSignature()) {
            abort(403, 'This magic link is invalid or has expired.');
        }

        $hashedToken = hash('sha256', $token);

        $loginToken = LoginToken::where('token', $hashedToken)
            ->whereNull('consumed_at')
            ->where('expires_at', '>', now())
            ->with('user')
            ->first();

        if (! $loginToken) {
            abort(403, 'This magic link has already been used or is no longer valid.');
        }

        $loginToken->update(['consumed_at' => now()]);

        Auth::login($loginToken->user);

        $request->session()->regenerate();

        return redirect()->intended(route('dashboard'));
    }

    public function logout(Request $request): RedirectResponse
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('magic-link.form');
    }
}
```

The `send()` method intentionally does not use the `exists:users,email` validation rule. If it did, Laravel's validation error would reveal whether a given email address is registered, which is a user enumeration vulnerability. Instead, we validate only that the email is syntactically valid, look the user up silently, send the notification only if they exist, and then always redirect to the same confirmation page regardless. An attacker cannot tell from the response whether an address is registered.

The `verify()` method runs two checks in a specific order. The signature check happens first, before any database query. This is intentional: malformed or expired URLs are rejected cheaply without touching the database. Only URLs that pass signature validation trigger a database lookup. When a valid token is found, we mark it as consumed before calling `Auth::login()`, not after. This ordering matters in the unlikely event of a race condition: consuming first means two simultaneous requests cannot both succeed. After login, `$request->session()->regenerate()` assigns a fresh session ID to prevent session fixation attacks.

## Step 6: Register the Routes {#step-6-register-routes}

Open `routes/web.php` and replace its contents with the following:

```php
<?php

use App\Http\Controllers\MagicLinkController;
use Illuminate\Support\Facades\Route;

Route::middleware('guest')->group(function () {
    Route::get('/magic-link', [MagicLinkController::class, 'showForm'])
        ->name('magic-link.form');

    Route::post('/magic-link', [MagicLinkController::class, 'send'])
        ->name('magic-link.send')
        ->middleware('throttle:5,1');
});

Route::get('/magic-link/sent', fn () => view('magic-link.sent'))
    ->name('magic-link.sent');

Route::get('/magic-link/verify/{token}', [MagicLinkController::class, 'verify'])
    ->name('magic-link.verify');

Route::middleware('auth')->group(function () {
    Route::get('/dashboard', fn () => view('dashboard'))->name('dashboard');
    Route::post('/logout', [MagicLinkController::class, 'logout'])->name('logout');
});
```

A few decisions are worth noting. The `guest` middleware wraps the form and send routes so that authenticated users cannot re-open the login form. The `throttle:5,1` middleware on the send route allows five requests per minute per IP address, which limits how quickly someone can trigger emails to valid accounts. The `magic-link.sent` confirmation page sits outside both middleware groups because it should be accessible regardless of auth state. The verify route is intentionally not behind the `guest` middleware. Using the middleware would cause an already-logged-in user who clicks an old link to be silently redirected; instead, they will receive a 403 message that makes the situation clear.

## Step 7: Build the Views {#step-7-build-views}

We need three views: the login form, the post-submit confirmation page, and the dashboard. Create the subdirectory for the magic link views first:

```bash
mkdir -p resources/views/magic-link
```

**The login form** is the entry point for the entire flow. It has a single email field and a submit button. Create `resources/views/magic-link/form.blade.php`:

```html
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Log In | {{ config('app.name') }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
<div class="max-w-md mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md mt-16">

    <h1 class="text-2xl font-bold mb-2">Log In</h1>
    <p class="text-gray-500 mb-6 text-sm">
        Enter your email address and we'll send you a one-click login link.
        No password required.
    </p>

    @if ($errors->any())
        <div class="bg-red-50 border border-red-200 text-red-700 rounded p-3 mb-4 text-sm">
            {{ $errors->first() }}
        </div>
    @endif

    <form method="POST" action="{{ route('magic-link.send') }}">
        @csrf
        <label class="block text-sm font-medium text-gray-700 mb-1" for="email">
            Email address
        </label>
        <input
            id="email"
            type="email"
            name="email"
            value="{{ old('email') }}"
            required
            autofocus
            placeholder="you@example.com"
            class="w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 mb-4"
        >
        <button
            type="submit"
            class="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded transition text-sm"
        >
            Send Login Link
        </button>
    </form>

    <div class="mt-8 mb-2 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com"
           class="text-blue-600 hover:text-blue-800 hover:underline transition"
           target="_blank">Tutorial: Magic Link Login at qadrlabs.com</a>
    </div>
</div>
</body>
</html>
```

**The confirmation page** is what the user sees after submitting the form. It does not reveal whether the email was found. Create `resources/views/magic-link/sent.blade.php`:

```html
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Check Your Inbox | {{ config('app.name') }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
<div class="max-w-md mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md mt-16 text-center">

    <div class="text-4xl mb-4">📬</div>
    <h1 class="text-xl font-bold mb-2">Check your inbox</h1>
    <p class="text-gray-500 text-sm mb-6">
        If that email address is registered, we've sent a login link.
        The link expires in 15 minutes and can only be used once.
    </p>

    <a href="{{ route('magic-link.form') }}"
       class="text-sm text-blue-600 hover:underline">
        Use a different email
    </a>

    <div class="mt-8 mb-2 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com"
           class="text-blue-600 hover:text-blue-800 hover:underline transition"
           target="_blank">Tutorial: Magic Link Login at qadrlabs.com</a>
    </div>
</div>
</body>
</html>
```

**The dashboard** is the protected page a user lands on after a successful login. It displays their email and provides a logout button. Create `resources/views/dashboard.blade.php` directly inside the `resources/views/` directory:

```html
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Dashboard | {{ config('app.name') }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
<div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md mt-16">

    <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold">Dashboard</h1>
        <form method="POST" action="{{ route('logout') }}">
            @csrf
            <button type="submit"
                    class="text-sm text-gray-500 hover:text-red-600 transition">
                Log Out
            </button>
        </form>
    </div>

    <div class="bg-green-50 border border-green-200 rounded p-4 text-sm text-green-800">
        You're logged in as <strong>{{ auth()->user()->email }}</strong>.
        No password required.
    </div>

    <div class="mt-8 mb-2 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com"
           class="text-blue-600 hover:text-blue-800 hover:underline transition"
           target="_blank">Tutorial: Magic Link Login at qadrlabs.com</a>
    </div>
</div>
</body>
</html>
```

## Step 8: Try It Out {#step-8-try-it-out}

Before opening a browser, configure the mail driver to write emails to the log file instead of sending them. Open `.env` and set:

```ini
MAIL_MAILER=log
```

You also need at least one user in the database. Create one in Tinker:

```bash
php artisan tinker
```

```php
>>> User::factory()->create(['email' => 'dev@example.com', 'name' => 'Dev User']);
```

Start the development server:

```bash
php artisan serve
```

**Scenario 1: Happy path**

Navigate to `http://localhost:8000/magic-link`. Enter `dev@example.com` and click "Send Login Link". You are redirected to the confirmation page immediately.

Open `storage/logs/laravel.log` and look for the magic link near the bottom. You will find a URL that looks like:

```
http://localhost:8000/magic-link/verify/xK9mQp...?expires=1747...&signature=a3b2c1...
```

Copy that full URL and paste it into your browser. You should land on the dashboard, logged in as Dev User.

**Scenario 2: Reusing the link**

Paste the same URL again. This time you should see a 403 page with the message "This magic link has already been used or is no longer valid." The `consumed_at` field is now set, so the database query in `verify()` returns nothing.

**Scenario 3: Unknown email**

Go back to the login form and enter an address that has no account, such as `ghost@example.com`. You are still redirected to the "Check your inbox" page. No notification is sent and no token is created. The response is identical to the happy path, which prevents an attacker from probing which emails are registered.

**Scenario 4: Tampered URL**

Take the URL from your log and append `&foo=bar` to the end. Paste it into a browser. The signature check fails immediately and you get a 403 error. Even changing a single character in the token segment produces the same result.

## Step 9: Write the Tests {#step-9-write-tests}

Before writing the test file, open `tests/Pest.php` and make sure it includes the `RefreshDatabase` trait for all Feature tests. This trait migrates the in-memory SQLite database fresh before each test so that every test starts with a clean state.

Open `tests/Pest.php` and confirm it contains the following line (the `--init` command may have already added the first `uses()` call; add `RefreshDatabase::class` to it):

```php
<?php

use Illuminate\Foundation\Testing\RefreshDatabase;

uses(Tests\TestCase::class, RefreshDatabase::class)->in('Feature');
```

Without `RefreshDatabase`, every test that tries to create a user will fail with `no such table: users` because the in-memory database is empty.

Now create the test file:

```bash
php artisan make:test MagicLinkTest --pest
```

Open `tests/Feature/MagicLinkTest.php` and replace its contents:

```php
<?php

use App\Models\LoginToken;
use App\Models\User;
use App\Notifications\MagicLinkNotification;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Str;

function makeToken(User $user, array $overrides = []): array
{
    $plain = Str::random(64);

    $user->loginTokens()->create(array_merge([
        'token' => hash('sha256', $plain),
        'expires_at' => now()->addMinutes(15),
        'consumed_at' => null,
    ], $overrides));

    return [$plain, URL::temporarySignedRoute(
        'magic-link.verify',
        now()->addMinutes(15),
        ['token' => $plain]
    )];
}

describe('Magic Link Form', function () {

    it('renders the login form for guests', function () {
        $this->get(route('magic-link.form'))
            ->assertOk()
            ->assertSee('Send Login Link');
    });

    it('redirects authenticated users to the dashboard', function () {
        $this->actingAs(User::factory()->create())
            ->get(route('magic-link.form'))
            ->assertRedirect(route('dashboard'));
    });

});

describe('Magic Link Send', function () {

    it('sends a notification and creates a token for a registered email', function () {
        Notification::fake();
        $user = User::factory()->create();

        $this->post(route('magic-link.send'), ['email' => $user->email])
            ->assertRedirect(route('magic-link.sent'));

        Notification::assertSentTo($user, MagicLinkNotification::class);
        $this->assertDatabaseHas('login_tokens', ['user_id' => $user->id]);
    });

    it('returns the same response for an unregistered email to prevent enumeration', function () {
        Notification::fake();

        $this->post(route('magic-link.send'), ['email' => 'ghost@example.com'])
            ->assertRedirect(route('magic-link.sent'));

        Notification::assertNothingSent();
        $this->assertDatabaseCount('login_tokens', 0);
    });

    it('rejects requests that exceed the rate limit', function () {
        $user = User::factory()->create();

        foreach (range(1, 5) as $i) {
            $this->post(route('magic-link.send'), ['email' => $user->email]);
        }

        $this->post(route('magic-link.send'), ['email' => $user->email])
            ->assertStatus(429);
    });

    it('invalidates old unused tokens when a new link is requested', function () {
        Notification::fake();
        $user = User::factory()->create();

        $this->post(route('magic-link.send'), ['email' => $user->email]);
        $this->post(route('magic-link.send'), ['email' => $user->email]);

        $this->assertDatabaseCount('login_tokens', 1);
    });

});

describe('Magic Link Verify', function () {

    it('authenticates the user and redirects to the dashboard with a valid link', function () {
        $user = User::factory()->create();
        [$plain, $url] = makeToken($user);

        $this->get($url)->assertRedirect(route('dashboard'));
        $this->assertAuthenticatedAs($user);
    });

    it('marks the token as consumed after a successful login', function () {
        $user = User::factory()->create();
        [$plain, $url] = makeToken($user);

        $this->get($url);

        $this->assertDatabaseMissing('login_tokens', [
            'user_id' => $user->id,
            'consumed_at' => null,
        ]);
    });

    it('rejects a link that has already been consumed', function () {
        $user = User::factory()->create();
        [$plain, $url] = makeToken($user, ['consumed_at' => now()]);

        $this->get($url)->assertStatus(403);
        $this->assertGuest();
    });

    it('rejects a link whose URL signature has been tampered with', function () {
        $tamperedUrl = route('magic-link.verify', ['token' => Str::random(64)]) . '&injected=1';

        $this->get($tamperedUrl)->assertStatus(403);
    });

    it('rejects a signed URL whose token does not exist in the database', function () {
        $plain = Str::random(64);

        $url = URL::temporarySignedRoute(
            'magic-link.verify',
            now()->addMinutes(15),
            ['token' => $plain]
        );

        $this->get($url)->assertStatus(403);
    });

});
```

The `makeToken()` helper creates a token record through the `$user->loginTokens()` relationship rather than calling `LoginToken::create()` directly. This is important because `user_id` is not in the model's `#[Fillable]` list; it is set automatically by Eloquent when creating through a relationship. Using `LoginToken::create(['user_id' => ...])` directly would fail with a mass assignment error.

Each `describe` block groups tests by the controller method under test. The `Magic Link Send` tests cover the enumeration prevention and rate limiting behaviours. The `Magic Link Verify` tests cover each rejection scenario individually, making it easy to identify exactly which check failed if a test breaks after a code change.

Run the tests against the specific file to avoid the default `ExampleTest` interfering:

```bash
./vendor/bin/pest tests/Feature/MagicLinkTest.php
```

Expected output:

```
   PASS  Tests\Feature\MagicLinkTest
  ✓ Magic Link Form → renders the login form for guests
  ✓ Magic Link Form → redirects authenticated users to the dashboard
  ✓ Magic Link Send → sends a notification and creates a token for a registered email
  ✓ Magic Link Send → returns the same response for an unregistered email to prevent enumeration
  ✓ Magic Link Send → rejects requests that exceed the rate limit
  ✓ Magic Link Send → invalidates old unused tokens when a new link is requested
  ✓ Magic Link Verify → authenticates the user and redirects to the dashboard with a valid link
  ✓ Magic Link Verify → marks the token as consumed after a successful login
  ✓ Magic Link Verify → rejects a link that has already been consumed
  ✓ Magic Link Verify → rejects a link whose URL signature has been tampered with
  ✓ Magic Link Verify → rejects a signed URL whose token does not exist in the database

  Tests:    11 passed (22 assertions)
  Duration: 0.42s
```

All eleven tests cover the full surface of the feature: the happy path, the security edge cases, and the enumeration prevention behaviour.

## How the Two-Layer Security Model Works {#how-two-layer-security-works}

Understanding why both security mechanisms are necessary makes it easier to reason about what could go wrong if either one were removed.

### The Signed URL Layer

`URL::temporarySignedRoute()` produces a URL with two additional query parameters: `expires` (a Unix timestamp) and `signature` (an HMAC computed over the full URL including the expiry). When `$request->hasValidSignature()` is called, Laravel recomputes the HMAC using your `APP_KEY` and compares it to the signature in the URL. If anything has changed, the comparison fails.

This layer prevents forgery. No one can construct a valid magic link without knowing your `APP_KEY`, and no one can extend the expiry of a link by editing the `expires` parameter, because doing so changes the URL and therefore invalidates the signature.

What signed URLs do not provide on their own is one-time use. A valid signed URL can be clicked multiple times within its expiry window and each click would pass the signature check. If someone intercepts the link via a forwarded email, a logged HTTP request, or a browser history search, they could use it again during the fifteen-minute window. That is the gap the database layer closes.

### The Database Token Layer

The `login_tokens` table tracks each token's lifecycle independently of the URL. When a user clicks the link, the controller queries for a token that is both unconsumed and not yet past `expires_at`. If such a token is found, the controller sets `consumed_at` to `now()` before calling `Auth::login()`. Every subsequent attempt to use the same URL finds a token with `consumed_at` already set and is rejected.

This layer prevents replay attacks within the expiry window. Even if an attacker intercepts the link and clicks it before the legitimate user does, the token is consumed on first use and the second click is rejected.

### Token Hashing

The plain token never enters the database. We store `hash('sha256', $plainToken)` instead. SHA-256 is a one-way function: knowing the hash gives you no practical path back to the plain token. If someone reads the `login_tokens` table through a SQL injection, a compromised backup, or a misconfigured query log, they cannot reverse the hashes into URLs that would pass the signature check. The plain token exists only in the notification email and the user's browser address bar.

### Why We Prevent User Enumeration

The `send()` method calls `$user->sendMagicLink()` only when a user is found, but it always redirects to the same confirmation page and always returns an HTTP redirect. An attacker probing the application cannot tell from the response whether a given email address is registered. If the application returned a different response for unknown emails, an attacker could build a list of registered accounts by submitting addresses in bulk and observing the responses.

## Conclusion {#conclusion}

Magic link authentication removes passwords from the equation entirely. For applications where accounts are admin-provisioned, or where simplicity of the login experience matters more than supporting offline access, it is a clean and defensible choice. Here is what we built and why each decision was made:

- **`URL::temporarySignedRoute()` as the tamper-proof layer.** The HMAC signature computed from your `APP_KEY` means no one can forge or modify a magic link. The embedded expiry timestamp means the link becomes invalid after fifteen minutes regardless of what the database says.
- **`login_tokens` table with `consumed_at` for one-time use.** The signed URL layer alone allows replay within the expiry window. Marking a token as consumed after the first successful login closes that gap completely.
- **SHA-256 hashing before storage.** Plain tokens never enter the database. A compromised `login_tokens` table cannot be used to construct working URLs because the hashes are not reversible.
- **User enumeration prevention.** The `send()` controller method returns an identical response for registered and unregistered emails. An attacker cannot determine which email addresses have accounts by observing response differences.
- **`throttle:5,1` on the send route.** Rate limiting prevents an attacker from triggering large volumes of emails to valid accounts, which would be both an abuse vector and a deliverability problem.
- **Session regeneration on login.** Calling `$request->session()->regenerate()` after `Auth::login()` prevents session fixation attacks, where an attacker pre-seeds a session ID and waits for a victim to authenticate into it.
- **Old token cleanup in `sendMagicLink()`.** Deleting unconsumed tokens before creating a new one means only the most recent link is valid. A user who requests multiple links in quick succession cannot accidentally log in with a stale one.
- **`RefreshDatabase` in `tests/Pest.php`.** Adding the trait at the suite level ensures every Feature test starts with a fully migrated in-memory database. Without it, tests fail with `no such table` errors even when all the application code is correct.