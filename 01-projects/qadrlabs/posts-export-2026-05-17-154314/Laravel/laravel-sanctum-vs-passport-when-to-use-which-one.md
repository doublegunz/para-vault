---
title: "Laravel Sanctum vs Passport: When to Use Which One"
slug: "laravel-sanctum-vs-passport-when-to-use-which-one"
category: "Laravel"
date: "2026-04-20"
status: "published"
---

You start a new Laravel 13 project, run `php artisan install:api`, and Sanctum is already wired in. Then a colleague asks: "Wait, don't you need Passport for this?" Suddenly you are reading two sets of documentation that both claim to handle API authentication, and neither one makes it obvious when you would pick one over the other.

The wrong choice carries a real cost. Install Passport for a simple SPA and you inherit five extra database tables, RSA encryption keys, OAuth2 clients, and an authorization server to maintain. Skip Passport when you actually need it and you will hit a wall the moment a third-party developer asks for a "Connect with YourApp" button. Neither outcome is what you want.

This article gives you a clear, practical framework for making the right call. Instead of just listing features side by side, we will look at how each package works under the hood, walk through the scenarios where each one genuinely shines, and end with a decision guide you can bookmark for future projects.

## Overview {#overview}

This is a conceptual reference article for Laravel 13. There is no single application to build, but by the end you will have a solid mental model for when to reach for Sanctum and when Passport is the correct tool. The code examples throughout are runnable, so feel free to follow along in Tinker or a fresh Laravel 13 project.

### What You'll Learn

- How Sanctum's two authentication modes work: API token authentication and cookie-based SPA authentication
- What OAuth2 actually is and what Passport adds on top of it
- The key grant types Passport supports and when each one is relevant
- A practical decision framework for choosing the right package
- How to install each package correctly in Laravel 13

### What You'll Need

- PHP 8.3 or higher (required by Laravel 13)
- A Laravel 13 project: `composer create-project laravel/laravel myapp`
- Basic familiarity with REST APIs and HTTP headers
- No prior knowledge of OAuth2 is required, though it helps

## The Core Question: What Problem Are You Solving? {#the-core-question}

Before comparing features, it helps to frame the real question. Both Sanctum and Passport solve the same surface-level problem: they protect your API routes so that only authenticated requests get through. The difference lies in *who* is making those requests and *how much control* you need over what they can do.

Ask yourself two questions. First: do you own and control every client that will talk to your API? If your Laravel backend serves your own React SPA, your own mobile app, or your own admin dashboard, that is a first-party scenario. You are the one who built the client, and you trust it completely. Second: do third-party developers need to build applications that connect to your users' accounts? If external apps need to present a "Authorize with YourApp" screen, that is a third-party scenario requiring a full OAuth2 server.

Sanctum is designed for first-party scenarios. Passport is designed for the second. That single distinction resolves the confusion for most projects.

## How Laravel Sanctum Works {#how-sanctum-works}

Sanctum is described in the Laravel 13 documentation as a "featherweight authentication system." That word choice is intentional. Sanctum is lean by design because it solves two specific, focused problems without the overhead of a full OAuth2 implementation. Installing it in Laravel 13 requires just one command:

```bash
php artisan install:api
```

This command installs Sanctum, publishes and runs its migration (creating the `personal_access_tokens` table), and adds `routes/api.php` if it does not already exist. Sanctum is ready in under a minute.

### API Token Authentication

The first mode works exactly like GitHub's personal access tokens. A user visits their account settings, clicks "Generate API Key," and receives a plain-text token they copy and store. Every subsequent API request includes that token in the `Authorization` header as a `Bearer` value. Sanctum validates the request by comparing the incoming token against its hashed copy in the database.

To enable this, add the `HasApiTokens` trait to your `User` model:

```php
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;
}
```

Issuing a token is a single method call on the authenticated user. The plain-text value is only available at this moment. After the response is sent, Sanctum stores only a SHA-256 hash, so you cannot retrieve it again later:

```php
use Illuminate\Http\Request;

// POST /api/tokens/create
Route::post('/tokens/create', function (Request $request) {
    $token = $request->user()->createToken('mobile-app');

    return response()->json([
        'token' => $token->plainTextToken,
    ]);
})->middleware('auth:sanctum');
```

You can verify this interactively with Tinker on a fresh project:

```
$ php artisan tinker

> $user = App\Models\User::factory()->create();
> $token = $user->createToken('test-token');
> echo $token->plainTextToken;
1|abc123xyz...
```

Tokens can also carry "abilities," which are Sanctum's lightweight equivalent of OAuth scopes. An ability limits what a given token is permitted to do:

```php
// Issue a token that can only read posts, not create or delete them
$token = $user->createToken('read-only-client', ['posts:read']);

// In a controller or middleware, check for the required ability
if (! $request->user()->tokenCan('posts:read')) {
    abort(403);
}
```

Revoking a token is just as straightforward. You can revoke a specific token or all tokens belonging to a user:

```php
// Revoke the current token (logout from current device)
$request->user()->currentAccessToken()->delete();

// Revoke all tokens (logout from all devices)
$request->user()->tokens()->delete();
```

### SPA Cookie-Based Authentication

The second mode is for single-page applications hosted on the same domain or subdomain as your Laravel backend. Instead of tokens in request headers, Sanctum delegates entirely to Laravel's existing session and cookie system. Your Vue or React SPA sends a login request, Laravel creates a session and sets a cookie, and every subsequent request from the SPA includes that cookie automatically. No token management is required on the frontend side.

This approach has a meaningful security advantage. Authentication credentials never touch JavaScript. There is no token sitting in `localStorage` that an XSS attack could steal. The session cookie is `HttpOnly`, meaning JavaScript cannot read it at all.

To configure this mode, add your SPA's domain to the `stateful` key in `config/sanctum.php`:

```php
'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', sprintf(
    '%s%s',
    'localhost,localhost:3000,127.0.0.1,127.0.0.1:8000,::1',
    Sanctum::currentApplicationUrlWithPort()
))),
```

Your protected API routes use the same `auth:sanctum` middleware regardless of which mode is in use. Sanctum detects automatically whether the incoming request carries a session cookie or a Bearer token and authenticates accordingly:

```php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn (Request $request) => $request->user());
    Route::apiResource('posts', PostController::class);
});
```

One important note from the Laravel 13 docs: you should not use API tokens to authenticate your own first-party SPA. The cookie-based mode is the recommended and more secure approach for that scenario.

## How Laravel Passport Works {#how-passport-works}

Passport is a full OAuth2 server implementation built on top of the League OAuth2 Server library. Where Sanctum handles authentication with a handful of classes and one database table, Passport ships with five database tables, RSA key pair generation, and a complete authorization server that understands and enforces the OAuth2 specification.

Installing Passport in Laravel 13 uses the same `install:api` command but with an additional flag:

```bash
php artisan install:api --passport
```

This command runs the OAuth2 migrations (creating tables for clients, tokens, authorization codes, and more), generates the RSA encryption keys needed to sign access tokens, and registers Passport's routes under `/oauth/*`. After the command runs, update your `User` model to use Passport's trait and implement its contract:

```php
use Laravel\Passport\Contracts\OAuthenticatable;
use Laravel\Passport\HasApiTokens;

class User extends Authenticatable implements OAuthenticatable
{
    use HasApiTokens, HasFactory, Notifiable;
}
```

Then set the `api` guard driver to `passport` in `config/auth.php` so Laravel knows to use Passport's token guard for API requests:

```php
'guards' => [
    'web' => [
        'driver' => 'session',
        'provider' => 'users',
    ],
    'api' => [
        'driver' => 'passport',
        'provider' => 'users',
    ],
],
```

### The OAuth2 Grant Types Passport Supports

OAuth2 is an authorization *framework* rather than a single protocol. It defines several distinct flows, called grant types, each designed for a specific scenario. Understanding these three is sufficient for most decision-making.

The **Authorization Code Grant** is the flow you encounter when clicking "Log in with Google" on a third-party website. The user is redirected to your server, reviews the permissions being requested, and approves or denies the access. Your server then sends the user back to the third-party app with a short-lived authorization code. The third-party app exchanges that code for an access token by making a server-to-server request. The key security property: the third-party app never sees the user's password. This is the grant type that enables external developers to build integrations against your platform.

The **Client Credentials Grant** is for machine-to-machine communication where no user is involved at all. A background worker on a separate server needs to query your API. A microservice needs to call another microservice. This grant lets a server authenticate itself using a `client_id` and `client_secret` and receive an access token in exchange, without any user login step. An example request looks like this:

```php
use Illuminate\Support\Facades\Http;

$response = Http::post('https://your-app.com/oauth/token', [
    'grant_type'    => 'client_credentials',
    'client_id'     => env('PASSPORT_CLIENT_ID'),
    'client_secret' => env('PASSPORT_CLIENT_SECRET'),
    'scope'         => 'read:reports',
]);

$accessToken = $response->json()['access_token'];
```

You then protect a route to accept only tokens with the correct scope:

```php
Route::middleware(['auth:api', 'scope:read:reports'])
    ->get('/reports', ReportController::class);
```

The **Password Grant** allows a first-party client to exchange a username and password directly for an access token, skipping the redirect flow entirely. Passport includes it, but it is worth knowing that the OAuth 2.1 draft deprecates this grant because it requires the client to handle the user's raw credentials. For first-party mobile apps in Laravel 13, Sanctum's personal access tokens are the simpler and recommended alternative.

### Token Scopes in Passport

Scopes in Passport are more formal than Sanctum's abilities. You define them explicitly in your `AppServiceProvider` before they can be assigned to tokens:

```php
use Laravel\Passport\Passport;

public function boot(): void
{
    Passport::tokensCan([
        'posts:read'   => 'Read blog posts',
        'posts:write'  => 'Create and edit blog posts',
        'users:manage' => 'Manage user accounts',
    ]);
}
```

When a third-party client requests authorization, the user sees these scope descriptions on the approval screen, giving them explicit control over what the external application can access.

## Feature Comparison at a Glance {#feature-comparison}

The table below summarizes the practical differences for Laravel 13.

| Feature | Sanctum | Passport |
|---|---|---|
| Setup complexity | Low (one command) | Medium (keys, clients, five migrations) |
| OAuth2 server | No | Yes |
| SPA cookie-based auth | Yes | No (Passport recommends using Sanctum for SPAs) |
| Personal access tokens | Yes | Yes |
| Token abilities / scopes | Yes (abilities) | Yes (full OAuth2 scopes) |
| Refresh tokens | No | Yes |
| Third-party app authorization | No | Yes (Authorization Code Grant) |
| Machine-to-machine auth | No | Yes (Client Credentials Grant) |
| Default in `php artisan install:api` | Yes | No (requires `--passport` flag) |
| Performance overhead | Minimal | Higher (RSA signing, more DB queries) |

## When to Choose Sanctum {#when-to-choose-sanctum}

Sanctum is the right choice for the vast majority of Laravel projects. The framework team made it the default in `install:api` for a reason: most applications never need a full OAuth2 server, and shipping one adds complexity without benefit.

Reach for Sanctum in these situations:

- You are building a SPA (React, Vue, Angular, Next.js) that communicates with a Laravel backend you also control. The cookie-based authentication mode is secure, low-overhead, and integrates seamlessly with Laravel's existing session infrastructure.
- You are building a mobile application (iOS, Android, Flutter) that connects to your own API. Issue the user a personal access token after login, store it securely in the device keychain, and attach it to every request as a Bearer token.
- You need a "Developer Settings" page in your SaaS where users can generate API keys to call your API from their own scripts. This is the personal access token pattern, and it is what Sanctum was originally designed for.
- Your project is small to medium in scope with a single team owning both the backend and the frontend. There is no third-party ecosystem to manage.

If you are unsure whether you need OAuth2, you almost certainly do not. Start with Sanctum.

## When to Choose Passport {#when-to-choose-passport}

Passport becomes necessary when your application needs to act as an authorization server for parties outside your organization. The clearest signal is this: if you want other developers to build applications that present a "Connect with YourApp" screen and request scoped access to a user's account, you need the Authorization Code Grant. Only Passport provides it.

Think of platforms like Slack, Stripe, GitHub, or Shopify. Each of them exposes an OAuth2 flow so that external developers can request scoped access to a user's account without knowing the user's password. The user approves on the platform's own screen, and the external app receives a token limited to exactly the scopes it requested. If you are building a platform with an open developer ecosystem, Passport is not optional.

Reach for Passport in these situations:

- You need third-party developers to build applications that integrate with your users' accounts via an authorization flow.
- You are building a microservices architecture where services need to authenticate with each other via the Client Credentials Grant, without a user being involved.
- Your organization has a compliance requirement (such as in healthcare or financial services) that mandates the use of the OAuth2 standard.
- You need refresh tokens to issue short-lived access tokens that can be silently renewed without asking the user to log in again.

## The Gray Area: Can You Use Both? {#using-both}

Technically, both packages can operate on separate guards in the same application. The pattern is to assign Sanctum to one guard for first-party clients and Passport to a separate guard for third-party OAuth2 clients. A minimal `config/auth.php` setup for this looks like the following:

```php
'guards' => [
    'web' => [
        'driver'   => 'session',
        'provider' => 'users',
    ],
    // Sanctum guard for first-party API keys and SPA sessions
    'api-sanctum' => [
        'driver'   => 'sanctum',
        'provider' => 'users',
    ],
    // Passport guard for third-party OAuth2 tokens
    'api' => [
        'driver'   => 'passport',
        'provider' => 'users',
    ],
],
```

Routes can then specify which guard to use: `auth:api-sanctum` for first-party endpoints and `auth:api` for OAuth2-protected endpoints.

That said, this dual-guard approach adds meaningful configuration complexity and is rarely the right starting point. A more common path is to begin with Sanctum for your own frontend, then migrate to Passport when a genuine need for third-party OAuth2 arises. Migrating is manageable because both packages share the same `HasApiTokens` interface on the `User` model. The main caveat is that existing sessions cannot be transferred between authentication systems, so all users and any connected apps will need to re-authenticate after the switch.

## A Practical Decision Guide {#decision-guide}

Work through these questions in order and stop at the first "yes."

Do you need third-party developers to build integrations against your API using an approval-based authorization flow? If yes, use **Passport**.

Do you need server-to-server authentication where no user is involved? If yes, use **Passport**.

Do you have a compliance requirement mandating OAuth2? If yes, use **Passport**.

Are you building a SPA or mobile app that only talks to your own Laravel backend? If yes, use **Sanctum**.

Do you need users to generate personal access tokens via their account settings? If yes, use **Sanctum**.

Are you still unsure? Use **Sanctum** and revisit when requirements become clearer.

| Scenario | Choose |
|---|---|
| SPA on same domain as Laravel backend | Sanctum |
| Mobile app connecting to your own API | Sanctum |
| Personal access tokens / API key page | Sanctum |
| "Connect with YourApp" for third parties | Passport |
| Machine-to-machine / microservices | Passport |
| OAuth2 compliance requirement | Passport |
| Not sure yet | Sanctum |

## Conclusion {#conclusion}

Choosing between Sanctum and Passport comes down to one question: does your application need to act as an OAuth2 authorization server for external parties? For most Laravel projects, the answer is no, and Sanctum is the right tool from day one. Here are the key takeaways:

- **Sanctum is the right default.** Laravel 13 installs it with a single `php artisan install:api` command for good reason. It covers SPAs, mobile apps, and personal access tokens without the overhead of a full OAuth2 server.
- **Cookie-based auth is Sanctum's security advantage for SPAs.** Session cookies with `HttpOnly` flags protect credentials from XSS attacks in ways that `localStorage`-based token storage cannot match.
- **Passport exists for OAuth2 server scenarios.** If external developers need to build integrations against your users' accounts via an authorization flow, the Authorization Code Grant is non-negotiable. Passport provides it.
- **Start with Sanctum and migrate when needed.** Switching from Sanctum to Passport later is straightforward. Removing an OAuth2 server you never needed is far more painful.
- **The deciding question is: who controls the client?** If you control every client that talks to your API, Sanctum is your answer. If third-party developers will build their own clients against your API and your users, you need Passport.