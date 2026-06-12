## 1. Before You Begin

The API you built in Lesson 9 returns raw Eloquent models as JSON. This works for a quick prototype, but exposes every column in the database, including internal fields you might not want public. It also provides no consistent envelope or versioning strategy. API Resources solve this by giving you full control over the JSON structure. Laravel Sanctum provides lightweight token authentication so mobile apps and SPAs can identify themselves to your API without cookies or sessions.

This lesson transforms Catatku's API from a quick prototype into a production-grade interface. You will shape the JSON output with Resource classes, so the response contains exactly the fields you want in exactly the format you want. You will implement token-based login so external clients can authenticate, store tokens securely, and make authenticated requests. By the end, Catatku's API will be consistent, secure, and ready for a mobile app or SPA to consume.

### What You'll Build

You will wrap every entry response in an `EntryResource`, create a login endpoint that issues Sanctum tokens, and update the API routes to require authentication tokens.

### What You'll Learn

- ✅ API Resources with `make:resource`
- ✅ Resource collections with pagination
- ✅ Sanctum personal access tokens
- ✅ Creating tokens in a login endpoint
- ✅ Authenticating requests with `Bearer` tokens
- ✅ Revoking tokens on logout

### What You'll Need

- Lesson 9 completed
- Sanctum installed (the `install:api` command did this in Lesson 9)

---

## 2. Create an API Resource

An API Resource is a PHP class that transforms a model into an associative array. The `toArray` method defines the JSON shape. This separation lets you evolve the database schema without breaking the public API contract, because the Resource acts as a translation layer between the two.

### Step 1: Generate the Entry Resource

Run the following Artisan command to create the Resource class.

```bash
php artisan make:resource EntryResource
```

This creates `app/Http/Resources/EntryResource.php` with a skeleton `toArray` method. Resources live in their own namespace to keep them organized, and the generated file inherits from `JsonResource` which provides the serialization logic.

### Step 2: Define the Resource Shape

Open `app/Http/Resources/EntryResource.php` and replace its content with the following.

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EntryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'excerpt' => $this->excerpt,
            'content' => $this->content,
            'cover_image_url' => $this->cover_image
                ? asset('storage/' . $this->cover_image)
                : null,
            'reading_time' => $this->reading_time,
            'author' => [
                'id' => $this->user->id,
                'name' => $this->user->name,
            ],
            'tags' => $this->whenLoaded('tags', function () {
                return $this->tags->map(fn ($tag) => [
                    'id' => $tag->id,
                    'name' => $tag->name,
                    'slug' => $tag->slug,
                ]);
            }),
            'comments_count' => $this->whenCounted('comments'),
            'created_at' => $this->created_at->toIso8601String(),
            'updated_at' => $this->updated_at->toIso8601String(),
        ];
    }
}
```

Let us walk through this resource field by field. The `toArray()` method receives a `Request` object (useful when you want to return different fields for different clients) and returns an associative array that becomes the JSON response. The `id`, `title`, and `content` fields are direct mappings from the model. The `excerpt` and `reading_time` values come from the accessors you defined in Lesson 3, so computed values are included for free without any manual calculation in the Resource.

For `cover_image_url`, we transform the stored relative path into a full public URL when an image exists, or return null otherwise. This is far more useful for API clients than the raw storage path, because clients need the full URL to display the image. The `author` key flattens the user relationship into a simple object with only `id` and `name`, deliberately hiding sensitive fields like `email` and `password`.

The `tags` key uses `$this->whenLoaded('tags', ...)`, which is a conditional helper: it only includes this key if the tags relationship was explicitly eager loaded in the controller. If you forget to eager load, the key is simply absent from the response rather than triggering lazy-loading queries during serialization, which would recreate the N+1 problem. `whenCounted()` works the same way for the `comments_count` field: it only appears when `withCount('comments')` was called. The timestamps use `toIso8601String()`, which produces the universal ISO 8601 format like `2026-04-17T10:30:45+00:00`, compatible with every timezone and every API client.

### Step 3: Use the Resource in the Controller

Open `app/Http/Controllers/Api/EntryController.php` and add the `EntryResource` import to the top of the file alongside the existing `use` statements. Then update the `index`, `show`, and `store` methods to wrap their responses in the Resource as shown below.

```php
<?php
// ... others lines of code
use App\Http\Resources\EntryResource;

class EntryController extends Controller
{
    // ... other methods

    public function index(Request $request): JsonResponse
    {
        $entries = Entry::with('tags', 'user')
            ->withCount('comments')
            ->latest()
            ->paginate(15);

        return response()->json(EntryResource::collection($entries));
    }

    public function show(Entry $entry): JsonResponse
    {
        $entry->load('tags', 'user', 'comments.user');
        $entry->loadCount('comments');

        return response()->json(new EntryResource($entry));
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        $entry = $request->user()->entries()->create([
            'title' => $validated['title'],
            'content' => $validated['content'],
        ]);

        $entry->tags()->sync($validated['tags'] ?? []);
        $entry->load('tags', 'user');
        $entry->loadCount('comments');

        return response()->json(new EntryResource($entry), 201);
    }

    // ... other methods
}
```

Analyzing each change: the `use` statement imports the Resource class so it is available in every method. In `index()`, `EntryResource::collection($entries)` wraps every entry in the collection with the Resource transformation, and Laravel automatically preserves the pagination envelope in the output because it detects that `$entries` is a `LengthAwarePaginator`. In `show()` and `store()`, we wrap a single entry with `new EntryResource($entry)`. Notice that we call `loadCount('comments')` on single entries because `withCount('comments')` only works when building a query; `loadCount` is the equivalent method for loading counts on an already-retrieved model instance.

---

## 3. Set Up Sanctum Authentication

Laravel Sanctum was installed automatically when you ran `install:api` in Lesson 9. Now you need to prepare the User model and create a login endpoint that issues tokens. Sanctum provides personal access tokens that clients store and send with every subsequent request.

### Step 1: Add the HasApiTokens Trait

Open `app/Models/User.php` and add the `HasApiTokens` trait to the `use` statement and to the trait list at the top of the class.

```php
<?php
// ... others lines of code
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    // ... other methods and properties
}
```

The `HasApiTokens` trait adds three methods to the User model: `createToken()` to issue a new token, `tokens()` to access the user's existing tokens as a relationship, and `currentAccessToken()` to inspect the token used on the current request. Behind the scenes, tokens are stored in the `personal_access_tokens` table that Sanctum created during its install step, with fields for the token name, hashed value, ability scopes, and optional expiration. Hashing the token before storage means a database breach does not directly expose usable token strings.

### Step 2: Create the Auth Controller

Generate the authentication controller file.

```bash
php artisan make:controller Api/AuthController
```

Open `app/Http/Controllers/Api/AuthController.php` and replace its content with the following.

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
            'device_name' => 'required|string',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $token = $user->createToken($validated['device_name'])->plainTextToken;

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
            'token' => $token,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(null, 204);
    }
}
```

Breaking down this controller carefully: the `login` method validates three fields. The `email` and `password` are the standard credentials. The `device_name` is a label that identifies the calling client, such as "Alice's iPhone" or "Acme Dashboard", which is useful because users can later see and revoke tokens for individual devices.

After validation, we look up the user by email. If the user does not exist or the password hash does not match, we throw a `ValidationException` with a generic message. Using the same message for both failure cases prevents account enumeration: an attacker cannot determine whether a given email is registered based on the error message. The critical line is `$user->createToken($validated['device_name'])->plainTextToken`. The `createToken()` method inserts a new row in `personal_access_tokens` and returns an object with two properties: `accessToken` (the database record) and `plainTextToken` (the actual token string, shown only once because the database stores a hash). Clients must capture and store this string immediately; it cannot be retrieved again.

In `logout()`, `$request->user()->currentAccessToken()->delete()` deletes only the token used for the current request, not all of the user's tokens. This is the correct behavior: logging out on one device should not log the user out on their other devices.

### Step 3: Register the Auth Routes

Open `routes/api.php` and replace its content with the following, which adds the `AuthController` import, a public login route, and a logout route inside the authenticated group.

```php
<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\EntryController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/entries', [EntryController::class, 'index']);
Route::get('/entries/{entry}', [EntryController::class, 'show']);

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::post('/entries', [EntryController::class, 'store']);
    Route::put('/entries/{entry}', [EntryController::class, 'update']);
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']);
});
```

The `/login` endpoint is public so unauthenticated clients can obtain a token in the first place. All write endpoints, including logout, are protected by `auth:sanctum`. The logout route requires authentication because you need to prove your identity in order for the server to know which token to revoke.

---

## 4. Run and Test

Let us verify the full authentication and resource flow using curl commands.

### Step 1: Ensure a Test Account Exists

Before calling the login endpoint, you need a user account in the database. If you already registered through the Catatku web form in a previous lesson, you can use those credentials in the next step and skip this one.

If you are starting fresh or want a dedicated test account, create one using Tinker.

```bash
php artisan tinker
```

Run the following command, then type `exit` to leave Tinker.

```php
\App\Models\User::factory()->create([
    'name' => 'Admin',
    'email' => 'admin@example.com',
    'password' => bcrypt('password'),
]);
```

`User::factory()->create()` inserts a new user using the factory defaults, overriding only the fields you specify. `bcrypt('password')` hashes the plain-text string using the bcrypt algorithm, which is the same algorithm Laravel uses when users register through the web form. After running this, the user exists in the database and can authenticate via both the web form and the API login endpoint.

### Step 2: Login and Get a Token

Send a login request with the credentials from the previous step.

```bash
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "password",
    "device_name": "Test Device"
  }'
```

The response should be a JSON object with the user's info and a `token` field containing a long string like `1|aB3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7bC9dE1fG3hI`. Copy that token value; you will need it for subsequent requests. If you see a 422 validation error, verify that the email matches an existing user in the database and the password is correct.

### Step 3: Create an Entry with the Token

Replace `YOUR_TOKEN_HERE` with the token value from the previous step.

```bash
curl -X POST http://localhost:8000/api/entries \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"title":"From API","content":"Hello API"}'
```

The `Authorization: Bearer TOKEN` header identifies you to the API. Sanctum looks up the token in the database, finds the associated user, and makes that user available via `$request->user()` in the controller. The response should be the newly created entry wrapped in the `EntryResource` shape with a 201 status code.

### Step 4: Verify Token Persistence

Make another authenticated request, such as the list endpoint, using the same token to verify it remains valid across multiple requests.

```bash
curl -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  http://localhost:8000/api/entries
```

Tokens do not expire by default. You can configure expiration in minutes via the `expiration` key in `config/sanctum.php`, but the default is unlimited lifetime.

### Step 5: Logout and Verify Revocation

Send a logout request to delete the current token from the database.

```bash
curl -X POST http://localhost:8000/api/logout \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

After logout, try creating an entry using the same token. The request should now return 401 Unauthorized because the token record was deleted.

```bash
curl -X POST http://localhost:8000/api/entries \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"title":"After logout","content":"Should fail"}'
```

You should receive a 401 Unauthorized response, confirming that logout properly revokes the token.

### Step 6: Inspect Tokens in Tinker

Open Tinker to inspect the token records stored in the database.

```bash
php artisan tinker
```

Run the following commands to view the active tokens for the first user.

```php
$user = \App\Models\User::first();
$user->tokens->count();
$user->tokens->pluck('name');
```

`$user->tokens->count()` returns the number of active tokens linked to this user. `$user->tokens->pluck('name')` extracts just the name column, showing which devices the user has active sessions from. Type `exit` to leave Tinker.

---

## 5. Fix the Errors in Your Code

These are the most common mistakes when implementing API Resources and Sanctum authentication.

**Error 1: Trying to read the plain-text token after the request completes.**

This error occurs when a developer creates a token in one request and then tries to retrieve the plain-text value from the database in a later request. Sanctum hashes the token before storing it, so the plain-text value is only available immediately after calling `createToken()`.

```php
// Wrong: capturing the token object and trying to read plainTextToken later
$tokenObject = $user->createToken('api');
// ... other code ...
$plainText = $tokenObject->plainTextToken; // Still works in the same request

// Also wrong: trying to read from the database after the request
$storedPlainText = $user->fresh()->tokens->first()->plainTextToken; // null - only hash stored

// Correct: capture plainTextToken immediately and include it in the response
$token = $user->createToken('device_name')->plainTextToken;
return response()->json(['token' => $token]);
```

The wrong version delays reading `plainTextToken`, or tries to retrieve it from the database, where only the hashed value is stored. Clients that lose their token cannot recover it from the API; they must log in again to obtain a new one. The correct version captures `plainTextToken` immediately from the `createToken()` return value and includes it in the current response.

---

**Error 2: Sending the Authorization header without the `Bearer` prefix.**

This error occurs when a client sends the token value alone in the Authorization header, omitting the required `Bearer ` prefix. Sanctum expects the standard HTTP Bearer token format.

```bash
# Wrong: token sent without the Bearer prefix
Authorization: abc123def456

# Correct: token sent with the required Bearer prefix and a space
Authorization: Bearer abc123def456
```

Without the `Bearer` prefix, Sanctum does not recognize the header as a token and treats the request as unauthenticated, returning a 401 response even though a valid token was provided. The header format is `Authorization: Bearer <token>` with a capital B, the word Bearer, a single space, and then the token value.

---

**Error 3: Accessing a relationship in a Resource without `whenLoaded()`, causing lazy loading.**

This error occurs when a Resource directly accesses a relationship like `$this->tags->map(...)` without checking whether the relationship was eager loaded. If the relationship was not loaded, Eloquent fires a query for each item in the collection, recreating the N+1 problem inside serialization.

```php
// Wrong: direct relationship access triggers a query if not eager loaded
public function toArray(Request $request): array
{
    return [
        'tags' => $this->tags->map(fn ($tag) => ['name' => $tag->name]),
    ];
}

// Correct: whenLoaded() omits the key entirely if not eager loaded
public function toArray(Request $request): array
{
    return [
        'tags' => $this->whenLoaded('tags', fn () => $this->tags->map(
            fn ($tag) => ['name' => $tag->name]
        )),
    ];
}
```

The wrong version accesses `$this->tags` directly. If 50 entries are being serialized and tags were not eager loaded, Eloquent runs 50 individual `SELECT * FROM tags WHERE entry_id = ?` queries. The correct version uses `whenLoaded('tags', ...)`, which returns `MissingValue` (a sentinel that Laravel excludes from the JSON output) when the relationship was not loaded. Always eager load in the controller and use `whenLoaded` in the Resource.

---

## 6. Exercises

These exercises reinforce the two main skills from this lesson: shaping JSON output through Resources and controlling access through Sanctum token abilities. Exercise 1 should be completed before Exercise 2, since the `UserResource` created in Exercise 1 is used in the `/api/me` endpoint in Exercise 2.

**Exercise 1:** Create a `UserResource` that returns only `id`, `name`, and `created_at` (formatted as ISO 8601), deliberately omitting `email` and other private fields. Use it in `EntryResource` to replace the inline `author` array.

**Exercise 2:** Add a `/api/me` endpoint that returns the authenticated user's data wrapped in `UserResource`. Protect it with `auth:sanctum` middleware.

**Exercise 3:** Add abilities to tokens when created: `$user->createToken('api', ['entries:write'])`. Check abilities in the route with `middleware('abilities:entries:write')`.

---

## 7. Solutions

Each solution below builds on the one before it. Complete Exercise 1 first so the `UserResource` is available when implementing the `/api/me` endpoint in Exercise 2.

**Solution for Exercise 1:**

Generate the UserResource file.

```bash
php artisan make:resource UserResource
```

Open `app/Http/Resources/UserResource.php` and define the shape.

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'joined_at' => $this->created_at->toIso8601String(),
        ];
    }
}
```

This Resource exposes three fields: `id`, `name`, and `joined_at` (a renamed `created_at` with ISO 8601 formatting). The `email` and `password` fields are deliberately absent, ensuring they can never be accidentally leaked through this API surface. Update `EntryResource` to use it for the `author` field.

```php
use App\Http\Resources\UserResource;

'author' => new UserResource($this->whenLoaded('user')),
```

Passing `$this->whenLoaded('user')` rather than `$this->user` ensures the author field is only included when the user relationship was eager loaded in the controller, maintaining the same N+1 safety as `whenLoaded` on other relationships.

---

**Solution for Exercise 2:**

Open `app/Http/Controllers/Api/AuthController.php` and add the `UserResource` import to the top of the file alongside the existing `use` statements, then add the `me` method after the existing `logout` method.

```php
<?php
// ... others lines of code
use App\Http\Resources\UserResource;

class AuthController extends Controller
{
    // ... other methods

    public function me(Request $request): JsonResponse
    {
        return response()->json(new UserResource($request->user()));
    }
}
```

`$request->user()` returns the authenticated user resolved from the Sanctum token on the current request. Wrapping it in `new UserResource(...)` applies the same field shaping defined in Exercise 1, so the response exposes only `id`, `name`, and `joined_at` without leaking `email` or any other private attribute. Register the route in `routes/api.php` inside the `auth:sanctum` middleware group.

```php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // ... existing entry routes
});
```

Test the endpoint by sending a GET request with a valid bearer token.

```bash
curl -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  http://localhost:8000/api/me
```

The response should be the `UserResource` shape with only the three permitted fields. If you receive a 401, verify that the token is valid and that the `Authorization` header includes the `Bearer` prefix.

---

**Solution for Exercise 3:**

Open `app/Http/Controllers/Api/AuthController.php` and update the `login` method to pass abilities as the second argument to `createToken()`. The change is on the `createToken()` line; everything else in the method stays the same.

```php
<?php
// ... others lines of code

class AuthController extends Controller
{
    // ... other methods

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
            'device_name' => 'required|string',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $token = $user->createToken($validated['device_name'], ['entries:write'])->plainTextToken;

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
            'token' => $token,
        ]);
    }

    // ... other methods
}
```

The second argument to `createToken()` is an array of ability strings. A token that includes `entries:write` is permitted to perform write operations on entries. A token created without this ability, or with a different set of abilities, will be rejected when it hits a route guarded by the `abilities` middleware. Update `routes/api.php` to add the ability middleware to the write routes.

```php
Route::middleware(['auth:sanctum', 'abilities:entries:write'])->group(function () {
    Route::post('/entries', [EntryController::class, 'store']);
    Route::put('/entries/{entry}', [EntryController::class, 'update']);
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']);
});
```

`abilities:entries:write` is Sanctum's built-in middleware that checks whether the current token's ability list includes `entries:write`. If the token was created without that ability, the middleware rejects the request with a 403 Forbidden response before the controller method runs. This scoping pattern is useful when you want to issue read-only tokens to certain clients and write tokens to others, all from the same login endpoint by varying the abilities array.

---

## Next Up - Lesson 11

In this lesson you elevated Catatku's API from a raw Eloquent prototype to a properly shaped, authenticated interface. You created `EntryResource` with `whenLoaded()` and `whenCounted()` to produce consistent JSON that never triggers lazy-loading queries. You added the `HasApiTokens` trait to the User model and built an `AuthController` with login and logout methods. Login issues a Sanctum personal access token that clients store and send as a `Bearer` header on every authenticated request. Logout deletes only the current token, leaving other device sessions untouched.

In Lesson 11, you will learn feature testing with Pest: how to write browser-simulating tests that verify your application works end-to-end, using factories, database isolation, and authentication helpers to write fast and reliable test suites.