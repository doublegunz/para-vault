# Configure CORS Safely in Laravel 13 with an Explicit Origin Allowlist

You are building a Laravel API and the frontend team reports a CORS error. Changing `allowed_origins` to `['*']` makes the error disappear, so the wildcard often survives into production without anyone reviewing which browser origins actually need access.

A wildcard CORS policy does not bypass authentication, steal Bearer tokens, or make private cookies readable by itself. It does, however, tell browsers that every origin may read eligible API responses. That is broader trust than most authenticated APIs need, and it can become dangerous when combined with exposed tokens, public endpoints that return sensitive data, or later authentication changes.

This tutorial builds a Laravel 13 API, observes the real wildcard behavior, and replaces it with a tested explicit allowlist. You will also create a browser client on a different port so the demonstration is genuinely cross-origin.

## Overview {#overview}

The finished project uses Sanctum Bearer token authentication and a CORS policy that allows only the browser frontend at `http://localhost:3000`.

### What You'll Build

- A Laravel 13 project named `cors-demo`
- A Sanctum-protected `/api/profile` endpoint
- A dashboard served from port `3000` that calls the API on port `8000`
- An environment-aware CORS allowlist
- Seven Pest tests that verify authentication and CORS behavior

### What You'll Learn

- How CORS and authentication solve different problems
- How to publish Laravel 13's CORS configuration
- How wildcard and explicit-origin responses differ
- Why an untrusted origin must not receive its own value in `Access-Control-Allow-Origin`
- How to test actual requests and preflight requests

### What You'll Need

- PHP 8.3 or higher
- Composer
- Laravel installer
- `curl`
- Basic familiarity with Laravel routes and Pest

## Step 1: Set Up the Project {#step-1-set-up-the-project}

Create a fresh Laravel 13 project, install the API scaffold, publish the CORS configuration, and run the migrations:

```bash
laravel new cors-demo --no-interaction --database=sqlite --pest --no-boost
cd cors-demo
php artisan install:api --no-interaction
php artisan config:publish cors --no-interaction
php artisan migrate
```

Laravel includes CORS middleware by default, but a fresh project does not contain `config/cors.php` until you publish it. The `install:api` command installs Sanctum and creates `routes/api.php`.

The command also instructs you to add Sanctum's `HasApiTokens` trait manually. Open `app/Models/User.php` and add the import and trait:

```php
<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
}
```

Laravel 13 uses the `#[Fillable]` attribute in the default model. The `HasApiTokens` trait adds the `tokens()` relationship and `createToken()` method used by Sanctum.

Create a demo-user seeder:

```bash
php artisan make:seeder UserSeeder --no-interaction
```

Replace `database/seeders/UserSeeder.php` with:

```php
<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::firstOrCreate(
            ['email' => 'demo@example.com'],
            ['name' => 'Demo User', 'password' => 'password'],
        );

        $user->tokens()->delete();
        $token = $user->createToken('demo-token')->plainTextToken;

        $this->command->newLine();
        $this->command->info('Demo user ready: demo@example.com');
        $this->command->info('Bearer token (copy this now):');
        $this->command->line($token);
        $this->command->newLine();
    }
}
```

Run the seeder and save the generated token:

```bash
php artisan db:seed --class=UserSeeder --no-interaction
```

The command prints the demo email and a generated Bearer token. Save that token before continuing because Sanctum stores only its hashed value.

## Step 2: Build the Protected API Endpoint {#step-2-build-the-protected-api-endpoint}

Create an invokable profile controller:

```bash
php artisan make:controller Api/ProfileController --invokable --no-interaction
```

Replace `app/Http/Controllers/Api/ProfileController.php` with:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'name' => $user->name,
            'email' => $user->email,
            'member_since' => $user->created_at->toDateString(),
        ]);
    }
}
```

Replace `routes/api.php` with:

```php
<?php

use App\Http\Controllers\Api\ProfileController;
use Illuminate\Support\Facades\Route;

Route::get('/profile', ProfileController::class)
    ->middleware('auth:sanctum')
    ->name('api.profile');
```

Start the API server:

```bash
php artisan serve --host=127.0.0.1 --port=8000
```

In another terminal, replace `YOUR_TOKEN` and verify the endpoint:

```bash
curl -s \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  http://127.0.0.1:8000/api/profile
```

The endpoint returns the authenticated user's profile. Calling it without the `Authorization` header returns a `401 Unauthenticated` response. CORS never replaces this authentication check.

## Step 3: Create a Cross-Origin Browser Client {#step-3-create-a-cross-origin-browser-client}

A page and API on the same scheme, host, and port have the same origin, so they do not demonstrate CORS. This step serves the dashboard on port `3000` and calls the API explicitly on port `8000`.

Create the dashboard controller:

```bash
php artisan make:controller DashboardController --invokable --no-interaction
```

Replace `app/Http/Controllers/DashboardController.php` with:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __invoke(): View
    {
        return view('dashboard');
    }
}
```

Add the route to `routes/web.php`:

```php
use App\Http\Controllers\DashboardController;

Route::get('/dashboard', DashboardController::class)->name('dashboard');
```

Create `resources/views/dashboard.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CORS Demo Dashboard</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold text-gray-900 mb-2">Profile Dashboard</h1>
        <p class="text-gray-500 text-sm mb-6">
            This page calls the API on port 8000 from a page on port 3000.
        </p>

        <label for="token" class="block text-sm font-medium text-gray-700 mb-1">
            Bearer Token
        </label>
        <input id="token" type="text"
            class="w-full border border-gray-300 rounded px-3 py-2 text-sm font-mono">

        <button id="fetchBtn"
            class="mt-4 bg-blue-600 text-white px-4 py-2 rounded text-sm hover:bg-blue-700 transition">
            Fetch Profile
        </button>

        <pre id="result" class="mt-6 bg-gray-50 border border-gray-200 rounded p-4 text-sm"></pre>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial CORS Configuration at qadrlabs.com</a>
        </div>
    </div>

    <script>
        document.getElementById('fetchBtn').addEventListener('click', async () => {
            const token = document.getElementById('token').value.trim();
            const result = document.getElementById('result');

            try {
                const response = await fetch('http://127.0.0.1:8000/api/profile', {
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Accept': 'application/json',
                    },
                });

                result.textContent = JSON.stringify(await response.json(), null, 2);
            } catch (error) {
                result.textContent = `Browser blocked the response: ${error.message}`;
            }
        });
    </script>
</body>
</html>
```

Keep the API server running on port `8000`. Start a second Laravel server:

```bash
php artisan serve --host=localhost --port=3000
```

Open `http://localhost:3000/dashboard`, paste the token, and click **Fetch Profile**. With Laravel's published wildcard configuration, the browser permits the cross-origin response.

## Step 4: Observe the Wildcard Policy {#step-4-observe-the-wildcard-policy}

The published `config/cors.php` contains permissive defaults:

```php
'paths' => ['api/*', 'sanctum/csrf-cookie'],
'allowed_methods' => ['*'],
'allowed_origins' => ['*'],
'allowed_headers' => ['*'],
'supports_credentials' => false,
```

Clear cached configuration:

```bash
php artisan config:clear
```

Use `curl` to inspect a request that claims to come from an unrelated origin:

```bash
curl -s -D - -o /dev/null \
  -H "Origin: https://evil-site.example" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  http://127.0.0.1:8000/api/profile
```

The response includes:

```text
Access-Control-Allow-Origin: *
```

This header permits any browser origin to read the response if that origin can make an otherwise valid request. It does not give the unrelated origin your Bearer token. An attacker who already possesses the token can call the API without relying on a browser or CORS, which is why token protection remains the primary security control.

Inspect the preflight request that a browser sends before a request containing the non-safelisted `Authorization` header:

```bash
curl -s -D - -o /dev/null \
  -X OPTIONS \
  -H "Origin: https://evil-site.example" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Authorization" \
  http://127.0.0.1:8000/api/profile
```

The wildcard policy permits that origin during preflight too. Next, replace this broad browser policy with the one origin the demo actually needs.

## Step 5: Configure an Explicit Allowlist {#step-5-configure-an-explicit-allowlist}

Replace `config/cors.php` with:

```php
<?php

return [
    'paths' => ['api/*'],

    'allowed_methods' => ['GET'],

    'allowed_origins' => array_filter([
        env('CORS_FRONTEND_URL'),
    ]),

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['Accept', 'Authorization'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,
];
```

Add the trusted browser origin to `.env` and `.env.example`:

```dotenv
CORS_FRONTEND_URL=http://localhost:3000
```

The dashboard uses a Bearer `Authorization` header, not cookie-based Fetch credentials, so `supports_credentials` remains `false`. Applications that use cross-origin cookies have additional Sanctum and CORS requirements and should enable credentials only with a specific origin allowlist.

Apply the configuration:

```bash
php artisan config:clear
```

The trusted-origin request now receives the exact configured value:

```text
Access-Control-Allow-Origin: http://localhost:3000
```

Repeat the request with `Origin: https://evil-site.example`. In Laravel 13.15, when the allowlist contains exactly one origin, the response may still contain:

```text
Access-Control-Allow-Origin: http://localhost:3000
```

That response is blocked by the browser because the header does not match the requesting origin. Therefore, robust tests verify that an untrusted origin never receives its own origin value. They should not assume the header is always absent.

## Step 6: Write the Feature Tests {#step-6-write-the-feature-tests}

Create the Pest test:

```bash
php artisan make:test CorsConfigurationTest --pest --no-interaction
```

Replace `tests/Feature/CorsConfigurationTest.php` with:

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

beforeEach(function () {
    config([
        'cors.allowed_origins' => ['http://localhost:3000'],
        'cors.allowed_methods' => ['GET'],
        'cors.allowed_headers' => ['Accept', 'Authorization'],
        'cors.paths' => ['api/*'],
        'cors.supports_credentials' => false,
    ]);
});

test('trusted origin receives its exact allow origin header', function () {
    Sanctum::actingAs(User::factory()->create());

    $response = $this->getJson('/api/profile', [
        'Origin' => 'http://localhost:3000',
    ]);

    $response->assertOk();
    $response->assertHeader('Access-Control-Allow-Origin', 'http://localhost:3000');
});

test('untrusted origin does not receive its own origin in the allow origin header', function () {
    Sanctum::actingAs(User::factory()->create());

    $response = $this->getJson('/api/profile', [
        'Origin' => 'https://evil-site.example',
    ]);

    $response->assertOk();
    expect($response->headers->get('Access-Control-Allow-Origin'))
        ->not->toBe('https://evil-site.example');
});

test('authenticated API never returns a wildcard origin', function () {
    Sanctum::actingAs(User::factory()->create());

    $response = $this->getJson('/api/profile', [
        'Origin' => 'http://localhost:3000',
    ]);

    expect($response->headers->get('Access-Control-Allow-Origin'))->not->toBe('*');
});

test('trusted preflight receives the configured CORS headers', function () {
    $response = $this
        ->withHeaders([
            'Origin' => 'http://localhost:3000',
            'Access-Control-Request-Method' => 'GET',
            'Access-Control-Request-Headers' => 'Authorization',
        ])
        ->options('/api/profile');

    $response->assertNoContent();
    $response->assertHeader('Access-Control-Allow-Origin', 'http://localhost:3000');
    $response->assertHeader('Access-Control-Allow-Methods', 'GET');
    $response->assertHeader('Access-Control-Allow-Headers', 'accept, authorization');
    $response->assertHeaderMissing('Access-Control-Allow-Credentials');
});

test('untrusted preflight does not receive its own origin in the allow origin header', function () {
    $response = $this
        ->withHeaders([
            'Origin' => 'https://evil-site.example',
            'Access-Control-Request-Method' => 'GET',
            'Access-Control-Request-Headers' => 'Authorization',
        ])
        ->options('/api/profile');

    expect($response->headers->get('Access-Control-Allow-Origin'))
        ->not->toBe('https://evil-site.example');
});

test('trusted origin still requires authentication', function () {
    $response = $this->getJson('/api/profile', [
        'Origin' => 'http://localhost:3000',
    ]);

    $response->assertUnauthorized();
});

test('trusted authenticated request returns profile data', function () {
    $user = User::factory()->create();
    Sanctum::actingAs($user);

    $response = $this->getJson('/api/profile', [
        'Origin' => 'http://localhost:3000',
    ]);

    $response->assertOk();
    $response->assertHeader('Access-Control-Allow-Origin', 'http://localhost:3000');
    $response->assertJson([
        'name' => $user->name,
        'email' => $user->email,
        'member_since' => $user->created_at->toDateString(),
    ]);
});
```

`RefreshDatabase` is required because the tests create users while the test environment uses an in-memory SQLite database. The preflight assertions also use Laravel's actual normalized header value, `accept, authorization`.

## Step 7: Try It Out {#step-7-try-it-out}

Format the project and run the focused test suite:

```bash
vendor/bin/pint --dirty
php artisan test --filter=CorsConfigurationTest
```

The tested project passes all seven CORS tests with 21 assertions:

```text
{"tool":"pest","result":"passed","tests":7,"passed":7,"assertions":21,"duration_ms":337}
```

Run the complete project suite too:

```bash
php artisan test
```

The complete tested project passes nine tests with 23 assertions:

```text
{"tool":"pest","result":"passed","tests":9,"passed":9,"assertions":23,"duration_ms":418}
```

With both local servers running, reload `http://localhost:3000/dashboard`. The trusted dashboard can read the profile response. A page served from another origin cannot read it because the response does not authorize that requesting origin.

## How CORS and Authentication Work Together {#how-cors-and-authentication-work-together}

CORS is a browser response-sharing policy. The server processes requests from `curl`, backend services, and other non-browser clients regardless of CORS headers. The browser compares the page's origin with `Access-Control-Allow-Origin` and decides whether JavaScript may read the response.

Authentication answers a different question: whether the request is authorized to access the endpoint. Sanctum rejects a missing or invalid Bearer token before the profile controller returns private data. A correct CORS policy does not compensate for weak authentication, and strong authentication does not justify trusting every browser origin.

The `Authorization` header triggers a preflight because it is not a CORS-safelisted request header. It does not require `supports_credentials => true`. Fetch credentials mode concerns cookies, TLS client certificates, and HTTP authentication credentials. Keep `supports_credentials` disabled unless the frontend architecture genuinely needs credentialed cross-origin requests.

## Avoid Origin Reflection {#avoid-origin-reflection}

Never copy an incoming `Origin` header directly into the response:

```php
// Do not do this.
$response->headers->set(
    'Access-Control-Allow-Origin',
    $request->header('Origin'),
);
```

That code authorizes every requesting origin by reflecting its own value. Use Laravel's `allowed_origins` list or carefully anchored `allowed_origins_patterns` instead.

When using a regular expression, escape literal dots and anchor the complete origin. For example, an unsafe pattern such as `^https://.*yourproject.com` can match attacker-controlled hostnames that merely contain that text. Prefer explicit origins whenever possible.

## Conclusion {#conclusion}

An explicit allowlist makes browser trust intentional and testable without confusing CORS with authentication.

- **Publish the configuration.** Laravel 13 handles CORS automatically, but `config/cors.php` must be published before you can customize it.
- **Keep authentication primary.** CORS does not bypass or replace Sanctum. Protected endpoints must still reject missing and invalid tokens.
- **Use a real cross-origin client.** Different ports are different origins. A relative request from a page served by the API does not test CORS.
- **Assert origin mismatch.** An untrusted origin must never receive its own value in `Access-Control-Allow-Origin`; the header is not guaranteed to be absent when only one origin is configured.
- **Test preflight behavior.** Requests containing `Authorization` trigger preflight, so the test suite should verify both actual requests and `OPTIONS` responses.
