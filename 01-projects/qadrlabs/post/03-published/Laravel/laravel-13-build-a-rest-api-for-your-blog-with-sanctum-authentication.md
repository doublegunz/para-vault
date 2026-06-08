---
title: "Laravel 13: Build a REST API for Your Blog with Sanctum Authentication"
slug: "laravel-13-build-a-rest-api-for-your-blog-with-sanctum-authentication"
category: "Laravel"
date: "2026-03-26"
status: "published"
---

Our blog application works great in the browser. But what if you want to build a mobile app, a Vue.js frontend, or let other services interact with your blog data? You need an API.

In this tutorial, we will add a REST API layer on top of the existing blog application. We will use Laravel Sanctum for token-based authentication, create dedicated API controllers and resource classes, and write Pest tests to verify every endpoint.

This is Part 6 of our Laravel 13 blog tutorial series, following the [CRUD tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step), the [testing tutorial](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application), the [Form Request refactoring tutorial](https://qadrlabs.com/post/laravel-13-refactor-your-controller-with-form-request-validation), and the [authentication and authorization tutorial](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes).


## Overview {#overview}

We will build a complete REST API that mirrors the web CRUD functionality, with a separate authentication system based on API tokens.

### What You'll Build

- Token-based authentication endpoints (register, login, logout).
- RESTful API endpoints for listing, creating, viewing, updating, and deleting posts.
- API resource classes for consistent JSON response formatting.
- Authorization checks so users can only modify their own posts.
- A full Pest test suite for every API endpoint.

### What You'll Learn

- How to install and configure Laravel Sanctum.
- How to build authentication endpoints that issue and revoke API tokens.
- How to create API-specific controllers separate from web controllers.
- How to use Eloquent API Resources to format JSON responses.
- How to protect API routes with Sanctum middleware.
- How to reuse existing Form Requests and Policies in the API layer.
- How to write API tests using `actingAs()` with Sanctum.

### What You'll Need

- The completed blog project with authentication and authorization from the [previous tutorial](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes).
- PHP 8.3 or higher.
- Basic familiarity with REST APIs and JSON.


## Step 1: Install Sanctum {#step-1-install-sanctum}

Laravel Sanctum provides a lightweight authentication system for SPAs (single page applications), mobile applications, and token-based APIs. It allows each user to generate multiple API tokens with specific abilities.

Install Sanctum and set up the API routes file:

```
php artisan install:api
```

This command does several things at once:

- Installs the `laravel/sanctum` package.
- Publishes Sanctum's migration files (creates a `personal_access_tokens` table).
- Creates the `routes/api.php` file.
- Registers the API routes in your application's route service provider.
- Runs the migration.

After the command completes, verify that the `HasApiTokens` trait is added to your `User` model. Open `app/Models/User.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    // ... existing code

    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }
}
```

The `HasApiTokens` trait adds the `createToken()` and `tokens()` methods to the User model, which we will use to issue and manage API tokens.

Save the file.


## Step 2: Create API Resource Classes {#step-2-create-api-resources}

API Resources transform your Eloquent models into structured JSON responses. They give you control over exactly which fields are included and how relationships are formatted.

### Create the PostResource

```
php artisan make:resource PostResource
```

Open `app/Http/Resources/PostResource.php`:

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PostResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'slug' => $this->slug,
            'content' => $this->content,
            'status' => $this->status,
            'author' => [
                'id' => $this->user->id,
                'name' => $this->user->name,
            ],
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
```

The `toArray()` method defines the JSON structure for each post. Instead of returning the raw model with all its columns (including `user_id`, `embedding`, or other internal fields), we explicitly list only the fields the API consumer needs. The `author` key nests the user's `id` and `name` for a cleaner response than exposing a raw `user_id` foreign key.

We access `$this->user` directly because the resource proxies property access to the underlying model. We will make sure to eager-load this relationship in the controller.

Save the file.


## Step 3: Create the API Authentication Controller {#step-3-auth-controller}

API authentication works differently from web authentication. Instead of sessions and cookies, we issue tokens that the client includes in every request.

Generate the controller:

```
php artisan make:controller Api/AuthController
```

Open `app/Http/Controllers/Api/AuthController.php`:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Register a new user and return a token.
     */
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'message' => 'Registration successful.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
            'token' => $token,
        ], 201);
    }

    /**
     * Login and return a token.
     */
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful.',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
            'token' => $token,
        ]);
    }

    /**
     * Logout and revoke the current token.
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully.',
        ]);
    }
}
```

Here is the flow for each endpoint:

**Register:** Validates the input (including `password_confirmation` via the `confirmed` rule), creates a new user with a hashed password, generates an API token using `createToken('api-token')`, and returns the token along with the user data. The `plainTextToken` property gives us the raw token string that the client needs to store. This is the only time the plain text token is available; Sanctum stores a hashed version in the database.

**Login:** Finds the user by email, checks the password with `Hash::check()`, and issues a new token if the credentials are valid. If the credentials are wrong, it throws a `ValidationException` which Laravel converts into a 422 JSON response with error messages. Each login creates a new token, so a user can be logged in from multiple devices simultaneously.

**Logout:** Deletes only the current token using `currentAccessToken()->delete()`. This revokes access for the device that made the logout request without affecting tokens on other devices. If you want to log out from all devices, you would use `$request->user()->tokens()->delete()` instead.

Save the file.


## Step 4: Create the API Post Controller {#step-4-api-post-controller}

We will create a separate controller for the API instead of reusing the web controller. This is a common practice because API responses (JSON) differ from web responses (views and redirects), and mixing them in one controller leads to messy conditional logic.

Generate the controller:

```
php artisan make:controller Api/PostController
```

Open `app/Http/Controllers/Api/PostController.php`:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Http\Resources\PostResource;
use App\Models\Post;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Http\Request;

class PostController extends Controller
{
    use AuthorizesRequests;

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $posts = Post::with('user')->latest()->paginate(10);

        return PostResource::collection($posts);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StorePostRequest $request)
    {
        $post = $request->user()->posts()->create($request->validated());

        return new PostResource($post->load('user'));
    }

    /**
     * Display the specified resource.
     */
    public function show(Post $post)
    {
        return new PostResource($post->load('user'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdatePostRequest $request, Post $post)
    {
        $this->authorize('update', $post);

        $post->update($request->validated());

        return new PostResource($post->load('user'));
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Post $post)
    {
        $this->authorize('delete', $post);

        $post->delete();

        return response()->json([
            'message' => 'Post deleted successfully.',
        ]);
    }
}
```

Let's walk through the key design decisions:

**Reusing Form Requests.** The `store()` and `update()` methods use the same `StorePostRequest` and `UpdatePostRequest` we created in the [Form Request tutorial](https://qadrlabs.com/post/laravel-13-refactor-your-controller-with-form-request-validation). The slug generation and validation rules are identical for both web and API. This is one of the big benefits of Form Requests: write once, use everywhere.

**Reusing the PostPolicy.** The `authorize('update', $post)` and `authorize('delete', $post)` calls use the same `PostPolicy` from the [auth tutorial](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes). We use the `AuthorizesRequests` trait and call `$this->authorize()` directly instead of the `#[Authorize]` attribute. Both approaches call the same policy methods. The attribute approach is cleaner for web controllers where every request is authenticated, while the explicit `$this->authorize()` call is more common in API controllers.

**Returning PostResource.** Every response goes through `PostResource` for consistent JSON formatting. `PostResource::collection($posts)` wraps a paginated collection and automatically includes pagination metadata (`links` and `meta` keys).

**Eager loading relationships.** `Post::with('user')` and `$post->load('user')` ensure the user relationship is loaded before passing the post to the resource. Without eager loading, accessing `$this->user` in the resource would trigger a separate query for each post (N+1 problem).

**No views or redirects.** Unlike the web controller, every method returns JSON. This keeps the API controller focused on data, not presentation.

Save the file.


## Step 5: Register the API Routes {#step-5-register-routes}

Open `routes/api.php` and register the authentication and post routes:

```php
<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PostController;
use Illuminate\Support\Facades\Route;

// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::apiResource('posts', PostController::class)->names([
        'index' => 'api.posts.index',
        'store' => 'api.posts.store',
        'show' => 'api.posts.show',
        'update' => 'api.posts.update',
        'destroy' => 'api.posts.destroy',
    ]);
});
```

All routes in `routes/api.php` are automatically prefixed with `/api`. So the full URLs become `/api/register`, `/api/login`, `/api/posts`, etc.

The structure separates public and protected routes:

- **Public routes** (`register` and `login`) do not require authentication. Anyone can create an account or log in to receive a token.
- **Protected routes** are wrapped in `middleware('auth:sanctum')`. The `auth:sanctum` middleware validates the token from the `Authorization: Bearer {token}` header. If the token is missing or invalid, Sanctum returns a 401 Unauthorized response.
- `Route::apiResource('posts', PostController::class)` registers five routes: `index`, `store`, `show`, `update`, and `destroy`. It is similar to `Route::resource()` but excludes `create` and `edit` since those are form pages that do not exist in an API.

**Important:** The `->names([...])` method assigns explicit route names with an `api.` prefix (e.g., `api.posts.index` instead of `posts.index`). Without this, the API route names would conflict with the web route names from `Route::resource('posts', ...)` in `routes/web.php`. Both would register `posts.index`, and the API version would overwrite the web version, breaking your web tests and named route references.

Save the file.


## Step 6: Handle Unauthenticated API Requests {#step-6-handle-unauthenticated}

By default, when an unauthenticated request hits a Sanctum-protected route, Laravel tries to redirect to the login page. This makes sense for web requests, but for API requests we want a JSON response instead.

Open `bootstrap/app.php` and add the following to ensure unauthenticated API requests receive a proper JSON response:

```php
<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Auth\AuthenticationException; // add this line of code
use Illuminate\Http\Request; // add this line of code

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        //
    })
    ->withExceptions(function (Exceptions $exceptions) {
		// [ ... Add this lines of code ... ]
        $exceptions->render(function (AuthenticationException $e, Request $request) {
            if ($request->is('api/*')) {
                return response()->json([
                    'message' => 'Unauthenticated.',
                ], 401);
            }
        });
    })->create();
```

The `render` callback checks if the request URL starts with `api/`. If so, it returns a 401 JSON response instead of redirecting to the login page. Web requests continue to redirect as before.

Save the file.


## Step 7: Write API Tests {#step-7-write-api-tests}

Now let's write comprehensive tests for the API. Create a new test file:

```
php artisan make:test Api/AuthApiTest --pest
```

### Authentication Tests

Open `tests/Feature/Api/AuthApiTest.php`:

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

test('a user can register via the api', function () {
    $response = $this->postJson('/api/register', [
        'name' => 'John Doe',
        'email' => 'john@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ]);

    $response->assertStatus(201)
        ->assertJsonStructure([
            'message',
            'user' => ['id', 'name', 'email'],
            'token',
        ]);

    $this->assertDatabaseHas('users', [
        'email' => 'john@example.com',
    ]);
});

test('register validates required fields', function () {
    $response = $this->postJson('/api/register', []);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['name', 'email', 'password']);
});

test('register validates unique email', function () {
    User::factory()->create(['email' => 'taken@example.com']);

    $response = $this->postJson('/api/register', [
        'name' => 'Jane Doe',
        'email' => 'taken@example.com',
        'password' => 'password123',
        'password_confirmation' => 'password123',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['email']);
});

test('register validates password confirmation', function () {
    $response = $this->postJson('/api/register', [
        'name' => 'John Doe',
        'email' => 'john@example.com',
        'password' => 'password123',
        'password_confirmation' => 'different',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['password']);
});

test('a user can login via the api', function () {
    $user = User::factory()->create([
        'password' => bcrypt('password123'),
    ]);

    $response = $this->postJson('/api/login', [
        'email' => $user->email,
        'password' => 'password123',
    ]);

    $response->assertStatus(200)
        ->assertJsonStructure([
            'message',
            'user' => ['id', 'name', 'email'],
            'token',
        ]);
});

test('login fails with incorrect credentials', function () {
    $user = User::factory()->create([
        'password' => bcrypt('password123'),
    ]);

    $response = $this->postJson('/api/login', [
        'email' => $user->email,
        'password' => 'wrong-password',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['email']);
});

test('login validates required fields', function () {
    $response = $this->postJson('/api/login', []);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['email', 'password']);
});

test('a user can logout via the api', function () {
    $user = User::factory()->create();
    $token = $user->createToken('test-token');

    $response = $this->withToken($token->plainTextToken)
        ->postJson('/api/logout');

    $response->assertStatus(200)
        ->assertJson([
            'message' => 'Logged out successfully.',
        ]);
});

test('logout requires authentication', function () {
    $response = $this->postJson('/api/logout');

    $response->assertStatus(401);
});
```

Notice the use of `postJson()` instead of `post()`. The `postJson()` method sends the request with the `Accept: application/json` and `Content-Type: application/json` headers, which is how API clients communicate. This ensures Laravel returns JSON validation errors instead of redirecting.

Also notice `actingAs($user, 'sanctum')` in most tests. The second argument specifies the guard. For Sanctum API routes, you must use `'sanctum'` as the guard name.

The **logout test** is different. It uses `createToken()` and `withToken()` instead of `actingAs()`. This is because `actingAs($user, 'sanctum')` creates a transient (in-memory) authentication that does not store a real token in the database. When the logout controller calls `currentAccessToken()->delete()`, it needs a real token to delete. By creating a token with `createToken('test-token')` and authenticating with `withToken($token->plainTextToken)`, the token exists in the database and can be properly revoked.

Save the file.

### Post API Tests

Create another test file:

```
php artisan make:test Api/PostApiTest --pest
```

Open `tests/Feature/Api/PostApiTest.php`:

```php
<?php

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->user = User::factory()->create();
});

// ============================================================
// Index
// ============================================================

test('authenticated user can list posts', function () {
    Post::factory()->count(3)->create();

    $response = $this->actingAs($this->user, 'sanctum')
        ->getJson('/api/posts');

    $response->assertStatus(200)
        ->assertJsonStructure([
            'data' => [
                '*' => ['id', 'title', 'slug', 'content', 'status', 'author', 'created_at', 'updated_at'],
            ],
            'links',
            'meta',
        ]);
});

test('post list is paginated', function () {
    Post::factory()->count(15)->create();

    $response = $this->actingAs($this->user, 'sanctum')
        ->getJson('/api/posts');

    $response->assertStatus(200)
        ->assertJsonCount(10, 'data');
});

test('unauthenticated user cannot list posts', function () {
    $response = $this->getJson('/api/posts');

    $response->assertStatus(401);
});

// ============================================================
// Store
// ============================================================

test('authenticated user can create a post', function () {
    $response = $this->actingAs($this->user, 'sanctum')
        ->postJson('/api/posts', [
            'title' => 'API Created Post',
            'content' => 'This post was created via the API.',
            'status' => 'publish',
        ]);

    $response->assertStatus(201)
        ->assertJson([
            'data' => [
                'title' => 'API Created Post',
                'slug' => 'api-created-post',
                'content' => 'This post was created via the API.',
                'status' => 'publish',
                'author' => [
                    'id' => $this->user->id,
                    'name' => $this->user->name,
                ],
            ],
        ]);

    $this->assertDatabaseHas('posts', [
        'title' => 'API Created Post',
        'user_id' => $this->user->id,
    ]);
});

test('store validates required fields via api', function () {
    $response = $this->actingAs($this->user, 'sanctum')
        ->postJson('/api/posts', []);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['title', 'content', 'status']);
});

test('store validates slug uniqueness via api', function () {
    Post::factory()->create(['slug' => 'duplicate-title']);

    $response = $this->actingAs($this->user, 'sanctum')
        ->postJson('/api/posts', [
            'title' => 'Duplicate Title',
            'content' => 'Some content.',
            'status' => 'draft',
        ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['slug']);
});

test('unauthenticated user cannot create a post', function () {
    $response = $this->postJson('/api/posts', [
        'title' => 'Unauthorized Post',
        'content' => 'This should fail.',
        'status' => 'draft',
    ]);

    $response->assertStatus(401);
});

// ============================================================
// Show
// ============================================================

test('authenticated user can view a single post', function () {
    $post = Post::factory()->create();

    $response = $this->actingAs($this->user, 'sanctum')
        ->getJson("/api/posts/{$post->id}");

    $response->assertStatus(200)
        ->assertJson([
            'data' => [
                'id' => $post->id,
                'title' => $post->title,
                'slug' => $post->slug,
            ],
        ]);
});

test('show returns 404 for non-existent post', function () {
    $response = $this->actingAs($this->user, 'sanctum')
        ->getJson('/api/posts/9999');

    $response->assertStatus(404);
});

test('unauthenticated user cannot view a post', function () {
    $post = Post::factory()->create();

    $response = $this->getJson("/api/posts/{$post->id}");

    $response->assertStatus(401);
});

// ============================================================
// Update
// ============================================================

test('post owner can update their post via api', function () {
    $post = Post::factory()->create([
        'title' => 'Original Title',
        'slug' => 'original-title',
        'user_id' => $this->user->id,
    ]);

    $response = $this->actingAs($this->user, 'sanctum')
        ->putJson("/api/posts/{$post->id}", [
            'title' => 'Updated Title',
            'content' => 'Updated content.',
            'status' => 'publish',
        ]);

    $response->assertStatus(200)
        ->assertJson([
            'data' => [
                'title' => 'Updated Title',
                'slug' => 'updated-title',
            ],
        ]);

    $this->assertDatabaseHas('posts', [
        'id' => $post->id,
        'title' => 'Updated Title',
    ]);
});

test('user cannot update a post they do not own via api', function () {
    $otherUser = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $otherUser->id]);

    $response = $this->actingAs($this->user, 'sanctum')
        ->putJson("/api/posts/{$post->id}", [
            'title' => 'Hijacked Title',
            'content' => 'Hijacked content.',
            'status' => 'publish',
        ]);

    $response->assertStatus(403);
});

test('update validates required fields via api', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user, 'sanctum')
        ->putJson("/api/posts/{$post->id}", []);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['title', 'content', 'status']);
});

test('unauthenticated user cannot update a post', function () {
    $post = Post::factory()->create();

    $response = $this->putJson("/api/posts/{$post->id}", [
        'title' => 'Unauthorized Update',
        'content' => 'This should fail.',
        'status' => 'draft',
    ]);

    $response->assertStatus(401);
});

// ============================================================
// Destroy
// ============================================================

test('post owner can delete their post via api', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user, 'sanctum')
        ->deleteJson("/api/posts/{$post->id}");

    $response->assertStatus(200)
        ->assertJson([
            'message' => 'Post deleted successfully.',
        ]);

    $this->assertDatabaseMissing('posts', ['id' => $post->id]);
});

test('user cannot delete a post they do not own via api', function () {
    $otherUser = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $otherUser->id]);

    $response = $this->actingAs($this->user, 'sanctum')
        ->deleteJson("/api/posts/{$post->id}");

    $response->assertStatus(403);

    $this->assertDatabaseHas('posts', ['id' => $post->id]);
});

test('unauthenticated user cannot delete a post', function () {
    $post = Post::factory()->create();

    $response = $this->deleteJson("/api/posts/{$post->id}");

    $response->assertStatus(401);
});
```

A few patterns to notice across these tests:

- **Every test uses `actingAs($this->user, 'sanctum')`.** The `'sanctum'` guard tells Laravel to authenticate the request as if a valid Sanctum token was provided. This is cleaner than generating an actual token in every test.
- **All requests use the `Json` suffix** (`getJson`, `postJson`, `putJson`, `deleteJson`). This ensures proper headers and JSON error responses.
- **Authentication tests check for 401.** Every endpoint has a corresponding test that verifies unauthenticated requests are rejected.
- **Authorization tests check for 403.** The update and delete endpoints verify that users cannot modify posts they do not own.
- **The store test verifies `user_id`.** After creating a post, the test checks that the `user_id` in the database matches the authenticated user, confirming the ownership assignment works through the API.
- **Pagination is tested separately.** The test creates 15 posts and verifies that only 10 are returned per page.

Save the file.


## Step 8: Run the Tests {#step-8-run-tests}

Run the complete test suite:

```
php artisan test
```

Output:
```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\Api\AuthApiTest
  ✓ a user can register via the api                                      0.15s  
  ✓ register validates required fields                                   0.01s  
  ✓ register validates unique email                                      0.01s  
  ✓ register validates password confirmation                             0.01s  
  ✓ a user can login via the api                                         0.01s  
  ✓ login fails with incorrect credentials                               0.01s  
  ✓ login validates required fields                                      0.01s  
  ✓ a user can logout via the api                                        0.01s  
  ✓ logout requires authentication                                       0.01s  

   PASS  Tests\Feature\Api\PostApiTest
  ✓ authenticated user can list posts                                    0.02s  
  ✓ post list is paginated                                               0.02s  
  ✓ unauthenticated user cannot list posts                               0.01s  
  ✓ authenticated user can create a post                                 0.01s  
  ✓ store validates required fields via api                              0.01s  
  ✓ store validates slug uniqueness via api                              0.01s  
  ✓ unauthenticated user cannot create a post                            0.01s  
  ✓ authenticated user can view a single post                            0.01s  
  ✓ show returns 404 for non-existent post                               0.01s  
  ✓ unauthenticated user cannot view a post                              0.01s  
  ✓ post owner can update their post via api                             0.01s  
  ✓ user cannot update a post they do not own via api                    0.01s  
  ✓ update validates required fields via api                             0.01s  
  ✓ unauthenticated user cannot update a post                            0.01s  
  ✓ post owner can delete their post via api                             0.01s  
  ✓ user cannot delete a post they do not own via api                    0.01s  
  ✓ unauthenticated user cannot delete a post                            0.01s  

   PASS  Tests\Feature\Auth\LoginTest
  ✓ login page is displayed                                              0.02s  
  ✓ user can login with correct credentials                              0.01s  
  ✓ user cannot login with incorrect password                            0.21s  
  ✓ user cannot login with non-existent email                            0.23s  
  ✓ login validates required fields                                      0.03s  
  ✓ user can logout                                                      0.02s  

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.01s  

   PASS  Tests\Feature\PostControllerTest
  ✓ index page displays a list of posts                                  0.01s  
  ✓ index page shows empty state when no posts exist                     0.01s  
  ✓ create page displays the form                                        0.01s  
  ✓ a new post can be stored                                             0.01s  
  ✓ slug is automatically generated from the title                       0.01s  
  ✓ store validates required fields                                      0.01s  
  ✓ store validates title max length                                     0.01s  
  ✓ store validates status must be draft or publish                      0.01s  
  ✓ store validates slug uniqueness                                      0.01s  
  ✓ show page displays a single post                                     0.01s  
  ✓ show returns 404 for non-existent post                               0.01s  
  ✓ edit page displays the form with existing data                       0.01s  
  ✓ a post can be updated                                                0.01s  
  ✓ update validates required fields                                     0.01s  
  ✓ update allows same slug for the same post                            0.01s  
  ✓ a post can be deleted                                                0.01s  
  ✓ deleting a non-existent post returns 404                             0.01s  
  ✓ unauthenticated user is redirected to login from index               0.01s  
  ✓ unauthenticated user is redirected to login from create              0.01s  
  ✓ unauthenticated user is redirected to login from store               0.01s  
  ✓ unauthenticated user is redirected to login from show                0.01s  
  ✓ unauthenticated user is redirected to login from edit                0.01s  
  ✓ unauthenticated user is redirected to login from update              0.01s  
  ✓ unauthenticated user is redirected to login from destroy             0.01s  
  ✓ user cannot edit a post they do not own                              0.01s  
  ✓ user cannot update a post they do not own                            0.01s  
  ✓ user cannot delete a post they do not own                            0.03s  
  ✓ post owner can edit their own post                                   0.01s  
  ✓ post owner can delete their own post                                 0.01s  

  Tests:    63 passed (194 assertions)
  Duration: 1.25s


```

You should see all tests passing, including the original web tests from previous tutorials and the new API tests. The API test suite adds:

- 9 authentication tests (register, login, logout with valid/invalid/missing data).
- 18 post API tests (CRUD operations with authentication, authorization, and validation checks).

Combined with the existing web tests, the total test count is 63 tests.


## Step 9: Try It Out {#step-9-try-it-out}

Start the development server:

```
php artisan serve
```

You can test the API using `curl` or any API client like Postman or Insomnia.

### Register a User

```bash
curl -X POST http://127.0.0.1:8000/api/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

The response includes a `token` field. Copy this token for the next requests.

### Login

```bash
curl -X POST http://127.0.0.1:8000/api/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

### Create a Post

Replace `YOUR_TOKEN` with the token from the register or login response:

```bash
curl -X POST http://127.0.0.1:8000/api/posts \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "title": "My First API Post",
    "content": "This post was created via the REST API.",
    "status": "publish"
  }'
```

### List All Posts

```bash
curl http://127.0.0.1:8000/api/posts \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### View a Single Post

```bash
curl http://127.0.0.1:8000/api/posts/1 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Update a Post

```bash
curl -X PUT http://127.0.0.1:8000/api/posts/1 \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "title": "Updated API Post",
    "content": "This post was updated via the REST API.",
    "status": "publish"
  }'
```

### Delete a Post

```bash
curl -X DELETE http://127.0.0.1:8000/api/posts/1 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Logout

```bash
curl -X POST http://127.0.0.1:8000/api/logout \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

After logout, the token is revoked and any subsequent request using the same token will receive a 401 response.


## Conclusion {#conclusion}

In this tutorial, we added a complete REST API layer to our Laravel 13 blog application. We installed Sanctum for token-based authentication, created dedicated API controllers and resource classes, reused existing Form Requests and Policies, and wrote a comprehensive Pest test suite.

Here are the key takeaways:

- **Sanctum makes token-based auth simple.** `createToken()` issues a token, `currentAccessToken()->delete()` revokes it. No OAuth complexity needed for most API use cases.
- **Separate API controllers from web controllers.** API endpoints return JSON, web endpoints return views and redirects. Keeping them in separate controllers avoids messy conditional logic and makes each controller easier to maintain.
- **Form Requests are reusable across layers.** The `StorePostRequest` and `UpdatePostRequest` we built in a previous tutorial work identically in the API controller. Write validation once, use it everywhere.
- **Policies work the same for web and API.** The `PostPolicy` enforces ownership checks regardless of whether the request comes from a browser or an API client. The only difference is how you call it: `#[Authorize]` attribute on web controllers vs `$this->authorize()` in API controllers.
- **API Resources give you control over JSON structure.** Instead of exposing raw model data, `PostResource` defines exactly which fields the API returns and how relationships are nested.
- **Always specify the `'sanctum'` guard in tests.** Using `actingAs($user, 'sanctum')` ensures the test authenticates through the Sanctum guard. Without the guard name, the test would use the default web guard, which could lead to unexpected behavior. The one exception is the logout test: use `createToken()` and `withToken()` instead, because `actingAs()` creates an in-memory token that cannot be deleted by `currentAccessToken()->delete()`.
- **Use `postJson()` instead of `post()` for API tests.** The `Json` suffix methods set the correct headers and ensure Laravel returns JSON validation errors instead of redirecting.
- **Give API routes explicit names to avoid conflicts.** When you have both `Route::resource('posts')` in web routes and `Route::apiResource('posts')` in API routes, they register the same route names (e.g., `posts.index`). The API routes will overwrite the web routes, breaking your web tests. Use `->names([...])` to prefix API route names with `api.` (e.g., `api.posts.index`).

From here, you could add token abilities (scopes) to restrict what each token can do, implement rate limiting on the API endpoints, add API versioning with route prefixes, or build a frontend that consumes this API using Vue.js, React, or a mobile framework.