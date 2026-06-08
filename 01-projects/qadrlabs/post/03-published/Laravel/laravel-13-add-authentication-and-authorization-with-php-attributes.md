---
title: "Laravel 13: Add Authentication and Authorization with PHP Attributes"
slug: "laravel-13-add-authentication-and-authorization-with-php-attributes"
category: "Laravel"
date: "2026-03-25"
status: "published"
---

Our blog application works, has 19 passing tests, and a cleanly refactored controller with Form Request validation. But right now, anyone can create, edit, or delete posts without logging in. That is fine for a tutorial, but not for a real application.

In this tutorial, we will add authentication and authorization to the blog. We will build a login system without using any starter kit, create a policy to control who can edit and delete posts, and use Laravel 13's new PHP attributes (`#[Middleware]` and `#[Authorize]`) to apply these rules directly on the controller. And because we have a test suite, we will update our existing tests and write new ones to verify the security layer works correctly.

This is Part 4 of our Laravel 13 blog tutorial series, following the [CRUD tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step), the [testing tutorial](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application), and the [Form Request refactoring tutorial](https://qadrlabs.com/post/laravel-13-refactor-your-controller-with-form-request-validation).


## Overview {#overview}

We will add two layers of protection to the blog:

1. **Authentication**: Only logged-in users can access the post management pages.
2. **Authorization**: Only the user who created a post can edit or delete it.

### What You'll Build

- A login page and login/logout functionality (without starter kit).
- A `user_id` column on posts to track ownership.
- A `PostPolicy` to define who can perform which actions.
- PHP attributes on the controller for middleware and authorization.
- Updated and new Pest tests covering authentication and authorization scenarios.

### What You'll Learn

- How to build authentication manually without Laravel Breeze or Jetstream.
- How to use `#[Middleware('auth')]` to require authentication on a controller.
- How to use `#[Authorize]` to enforce policy checks on specific methods.
- How to access the route-bound model in `#[Authorize]` attributes.
- How to update existing tests with `actingAs()` for authenticated requests.
- How to write tests for unauthenticated access and unauthorized actions.

### What You'll Need

- The completed blog project with Form Request validation from the [previous tutorial](https://qadrlabs.com/post/laravel-13-refactor-your-controller-with-form-request-validation).
- PHP 8.3 or higher.
- Basic familiarity with Laravel middleware and policies.


## Step 1: Run the Tests Before Changes {#step-1-run-tests-before}

As always, start by running the existing test suite:

```
php artisan test
```

All 19 tests should pass. This is our baseline. Every change we make from here will be verified against these tests.


## Step 2: Build the Login System {#step-2-build-login-system}

We will build a simple login and logout system without using any starter kit like Breeze or Jetstream. This keeps the tutorial focused and gives you full control over the implementation.

### Create the LoginController

Generate a new controller:

```
php artisan make:controller Auth/LoginController
```

Open `app/Http/Controllers/Auth/LoginController.php` and add the login and logout logic:

```php
<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LoginController extends Controller
{
    /**
     * Show the login form.
     */
    public function showLoginForm()
    {
        return view('auth.login');
    }

    /**
     * Handle a login request.
     */
    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::attempt($credentials)) {
            $request->session()->regenerate();

            return redirect()->intended(route('posts.index'));
        }

        return back()->withErrors([
            'email' => 'The provided credentials do not match our records.',
        ])->onlyInput('email');
    }

    /**
     * Log the user out.
     */
    public function logout(Request $request)
    {
        Auth::logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login');
    }
}
```

Here is what each method does:

- `showLoginForm()` returns the login view. Nothing special here.
- `login()` first validates that both email and password are provided. Then `Auth::attempt($credentials)` checks the credentials against the `users` table. If the credentials match, `$request->session()->regenerate()` creates a new session ID to prevent session fixation attacks, and `redirect()->intended()` sends the user to the page they originally tried to access (or the posts index as a fallback). If the credentials are wrong, it redirects back with an error message while keeping the email input filled.
- `logout()` clears the authentication state, invalidates the session, and regenerates the CSRF token to prevent any session-based attacks after logout.

Save the file.

### Create the Login View

Create a new file at `resources/views/auth/login.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-md mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md mt-20">
        <h1 class="text-2xl font-bold text-gray-900 mb-6 text-center">Login</h1>

        @if($errors->any())
            <div class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded mb-6">
                <ul class="list-disc list-inside text-sm">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('login') }}" method="POST" class="space-y-6">
            @csrf
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input type="email" name="email" value="{{ old('email') }}" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                <input type="password" name="password" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
            </div>

            <div>
                <button type="submit" class="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm">
                    Login
                </button>
            </div>
        </form>
    </div>
</body>
</html>
```

Save the file.

### Register the Auth Routes

Open `routes/web.php` and add the authentication routes:

```php
<?php

use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\PostController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Authentication routes
Route::get('/login', [LoginController::class, 'showLoginForm'])->name('login');
Route::post('/login', [LoginController::class, 'login']);
Route::post('/logout', [LoginController::class, 'logout'])->name('logout');

Route::resource('posts', PostController::class);
```

The `login` route is named `login` because Laravel's `auth` middleware redirects unauthenticated users to the route named `login` by default. If you name it something else, you would need to configure the redirect path separately.

Save the file.

### Add a Logout Button

Update `resources/views/posts/index.blade.php` to include a logout button in the header. Find the existing header section:

```html
<div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold text-gray-900">Manage Posts</h1>
    <a href="{{ route('posts.create') }}" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm">
        Create New Post
    </a>
</div>
```

Replace it with:

```html
<div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold text-gray-900">Manage Posts</h1>
    <div class="flex items-center space-x-4">
        <a href="{{ route('posts.create') }}" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm">
            Create New Post
        </a>
        @auth
        <form action="{{ route('logout') }}" method="POST" class="inline">
            @csrf
            <button type="submit" class="text-gray-600 hover:text-gray-900 text-sm underline transition">
                Logout
            </button>
        </form>
        @endauth
    </div>
</div>
```

The `@auth` directive ensures the logout button only appears when the user is logged in.

Save the file.


## Step 3: Add Post Ownership {#step-3-add-post-ownership}

To authorize who can edit or delete a post, we need to know who created it. This means adding a `user_id` column to the `posts` table.

### Create the Migration

```
php artisan make:migration add_user_id_to_posts_table --table=posts
```

Open the generated migration file and add the `user_id` column:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->foreignId('user_id')->after('id')->constrained()->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->dropColumn('user_id');
        });
    }
};
```

`foreignId('user_id')->constrained()->onDelete('cascade')` creates a foreign key that references the `users` table. The `after('id')` places the column right after the `id` column for a clean table structure. When a user is deleted, all their posts are automatically removed.

Save the file and run the migration:

```
php artisan migrate
```

### Update the Post Model

Open `app/Models/Post.php` and add `user_id` to the `#[Fillable]` attribute and define the relationship:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['title', 'slug', 'content', 'status', 'user_id'])] // add user_id to fillable
class Post extends Model
{
    use HasFactory;

	// define relationship
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

The `user()` method defines a `BelongsTo` relationship, so you can access the post's author via `$post->user`.

Save the file.

### Update the Post Factory

Open `database/factories/PostFactory.php` and add the `user_id` field:

```php
<?php

namespace Database\Factories;

use App\Models\User; // add this line of code
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Post>
 */
class PostFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $title = $this->faker->sentence();

        return [
            'title' => $title,
            'slug' => Str::slug($title),
            'content' => $this->faker->paragraphs(3, true),
            'status' => $this->faker->randomElement(['draft', 'publish']),
            'user_id' => User::factory(), // add this line of code
        ];
    }
}
```

`User::factory()` automatically creates a user whenever a post is generated, establishing the ownership relationship in test data.

Save the file.

### Update the Store Logic

When creating a post, we need to assign the currently authenticated user as the owner. Open `app/Http/Controllers/PostController.php` and update the `store()` method:

```php
public function store(StorePostRequest $request)
{
    $request->user()->posts()->create($request->validated());

    return redirect()->route('posts.index')->with('success', 'Post created successfully.');
}
```

Instead of `Post::create($request->validated())`, we now use `$request->user()->posts()->create(...)`. This automatically sets the `user_id` to the authenticated user's ID without needing to include it in the form or the validated data.

For this to work, we need to add the `posts()` relationship to the `User` model. Open `app/Models/User.php` and add:

```php
use Illuminate\Database\Eloquent\Relations\HasMany;

// Inside the User class:
public function posts(): HasMany
{
    return $this->hasMany(Post::class);
}
```

The contents of the User Model class are as follows:
```php
<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }
}

```

Save both files.

### Update the StorePostRequest

Since `user_id` is no longer passed through the form, we should remove it from the fillable fields that the form touches. The `user_id` is set through the relationship, so the Form Request does not need to handle it. No changes are needed in `StorePostRequest` since it does not reference `user_id`.


## Step 4: Create a Post Policy {#step-4-create-post-policy}

Policies define which users are authorized to perform which actions on a model. Generate a policy for the `Post` model:

```
php artisan make:policy PostPolicy --model=Post
```

Open `app/Policies/PostPolicy.php` and define the authorization rules:

```php
<?php

namespace App\Policies;

use App\Models\Post;
use App\Models\User;

class PostPolicy
{
    /**
     * Determine whether the user can view any models.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can view the model.
     */
    public function view(User $user, Post $post): bool
    {
        return true;
    }

    /**
     * Determine whether the user can create models.
     */
    public function create(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can update the model.
     */
    public function update(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }

    /**
     * Determine whether the user can delete the model.
     */
    public function delete(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }
}
```

The logic is straightforward:

- `viewAny()`, `view()`, and `create()` return `true` because any authenticated user can list posts, view individual posts, and create new posts.
- `update()` and `delete()` compare the authenticated user's ID with the post's `user_id`. Only the user who created the post can edit or delete it. The `===` strict comparison ensures both the value and type match.

Save the file.


## Step 5: Apply PHP Attributes to the Controller {#step-5-apply-php-attributes}

This is where Laravel 13's new PHP attributes come into play. Instead of defining middleware in the constructor or the route file, you can declare them directly on the controller class and methods using `#[Middleware]` and `#[Authorize]`.

Open `app/Http/Controllers/PostController.php` and update it:

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Models\Post;
use Illuminate\Routing\Attributes\Controllers\Middleware;
use Illuminate\Routing\Attributes\Controllers\Authorize;

#[Middleware('auth')]
class PostController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $posts = Post::latest()->paginate(10);
        return view('posts.index', compact('posts'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return view('posts.create');
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StorePostRequest $request)
    {
        $request->user()->posts()->create($request->validated());

        return redirect()->route('posts.index')->with('success', 'Post created successfully.');
    }

    /**
     * Display the specified resource.
     */
    public function show(Post $post)
    {
        return view('posts.show', compact('post'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    #[Authorize('update', 'post')]
    public function edit(Post $post)
    {
        return view('posts.edit', compact('post'));
    }

    /**
     * Update the specified resource in storage.
     */
    #[Authorize('update', 'post')]
    public function update(UpdatePostRequest $request, Post $post)
    {
        $post->update($request->validated());

        return redirect()->route('posts.index')->with('success', 'Post updated successfully.');
    }

    /**
     * Remove the specified resource from storage.
     */
    #[Authorize('delete', 'post')]
    public function destroy(Post $post)
    {
        $post->delete();

        return redirect()->route('posts.index')->with('success', 'Post deleted successfully.');
    }
}
```

Let's break down the two attributes:

### `#[Middleware('auth')]` on the Class

Placing `#[Middleware('auth')]` on the class declaration applies the `auth` middleware to every method in the controller. This means all routes handled by `PostController` now require the user to be logged in. If an unauthenticated user tries to access any post route, they will be redirected to the login page.

In previous Laravel versions, you would achieve this with a constructor call:

```php
// Old approach
public function __construct()
{
    $this->middleware('auth');
}
```

The attribute approach is more declarative. You can see the middleware requirement at a glance without opening the constructor or the route file.

### `#[Authorize('update', 'post')]` on Methods

The `#[Authorize]` attribute is placed on individual methods that need authorization checks. It takes two arguments:

- The first argument (`'update'` or `'delete'`) is the policy method to call.
- The second argument (`'post'`) is the route parameter name that contains the model instance.

When a user accesses `edit()`, `update()`, or `destroy()`, Laravel automatically calls the corresponding policy method (e.g., `PostPolicy::update()`) with the authenticated user and the `Post` instance resolved from the route. If the policy returns `false`, Laravel throws an `AuthorizationException` and returns a 403 Forbidden response.

The `'post'` string must match the route parameter name. Since we used `Route::resource('posts', PostController::class)`, Laravel names the parameter `post` (singular of the resource name). This is the same parameter that route model binding uses to inject the `Post $post` instance.

Notice that `index()`, `create()`, `store()`, and `show()` do not have `#[Authorize]` attributes. This matches our policy: any authenticated user can list, view, and create posts. Only edit, update, and delete require ownership verification.

Save the file.


## Step 6: Seed Sample Data for Manual Testing {#step-6-seed-sample-data}

Before we update the automated tests, it is worth trying the application manually in the browser to see authentication and authorization working end to end. To do that, we need at least one user account to log in with. Rather than creating users manually through a database tool, we will use a seeder so the setup is repeatable.

To demonstrate authorization properly, we will seed two users. The first user will own several posts. The second user will own none. This lets you log in as each user and verify that the edit and delete buttons on posts you do not own return a 403 response.

### Create the UserSeeder

```
php artisan make:seeder UserSeeder
```

Open `database/seeders/UserSeeder.php` and replace its contents with:

```php
<?php

namespace Database\Seeders;

use App\Models\Post;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // First user: owns all seeded posts
        $alice = User::create([
            'name'     => 'Alice',
            'email'    => 'alice@example.com',
            'password' => Hash::make('password'),
        ]);

        // Create three posts owned by Alice
        $titles = [
            'Getting Started with Laravel 13',
            'Understanding PHP Attributes',
            'Writing Tests with Pest',
        ];

        foreach ($titles as $title) {
            Post::create([
                'title'   => $title,
                'slug'    => Str::slug($title),
                'content' => 'This is a sample post for manual testing purposes.',
                'status'  => 'publish',
                'user_id' => $alice->id, // Alice owns these posts
            ]);
        }

        // Second user: owns no posts, used to test unauthorized access
        User::create([
            'name'     => 'Bob',
            'email'    => 'bob@example.com',
            'password' => Hash::make('password'),
        ]);
    }
}
```

Both users share the same password (`password`) to keep manual testing simple.

### Register the Seeder

Open `database/seeders/DatabaseSeeder.php` and call `UserSeeder` from the `run()` method:

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            UserSeeder::class,
        ]);
    }
}
```

### Run the Seeder

```
php artisan db:seed
```

### Try It in the Browser

Start the development server if it is not already running:

```
php artisan serve
```

Open `http://127.0.0.1:8000/posts`. Because the `auth` middleware is now applied to the entire controller, you will be redirected to the login page immediately.

Log in with Alice's credentials (`alice@example.com` / `password`). You should be redirected to the post listing page, where Alice's three posts are visible. Click **Edit** on any of them. The form should load normally because Alice owns those posts.

Now log out and log back in as Bob (`bob@example.com` / `password`). Try clicking **Edit** on one of Alice's posts. You should receive a **403 Forbidden** response, which confirms that the policy and the `#[Authorize]` attribute are working correctly.


## Step 7: Update Existing Tests {#step-7-update-existing-tests}

Now that every route requires authentication, our existing tests will fail because they send requests without being logged in. We need to update them to use `actingAs()`, which simulates an authenticated user.

Open `tests/Feature/PostControllerTest.php` and update the file. First, add the `User` import at the top and create a helper that runs before each test:

```php
<?php

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

beforeEach(function () {
    $this->user = User::factory()->create();
});
```

`beforeEach()` runs before every test in the file. It creates a fresh user that we can use for authentication. The `$this->user` syntax stores it on the test instance so it is accessible in every test.

Now update each existing test to use `actingAs($this->user)`. Here is the complete updated file with both the existing tests modified and the new tests added:

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
// Index Tests
// ============================================================

test('index page displays a list of posts', function () {
    $posts = Post::factory()->count(3)->create();

    $response = $this->actingAs($this->user)->get(route('posts.index'));

    $response->assertStatus(200);
    $response->assertViewIs('posts.index');
    $response->assertViewHas('posts');

    foreach ($posts as $post) {
        $response->assertSee($post->title);
    }
});

test('index page shows empty state when no posts exist', function () {
    $response = $this->actingAs($this->user)->get(route('posts.index'));

    $response->assertStatus(200);
    $response->assertSee('No posts found.');
});

// ============================================================
// Create Tests
// ============================================================

test('create page displays the form', function () {
    $response = $this->actingAs($this->user)->get(route('posts.create'));

    $response->assertStatus(200);
    $response->assertViewIs('posts.create');
    $response->assertSee('Create Post');
});

test('a new post can be stored', function () {
    $response = $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => 'My First Blog Post',
        'content' => 'This is the content of my first blog post.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post created successfully.');

    $this->assertDatabaseHas('posts', [
        'title' => 'My First Blog Post',
        'slug' => 'my-first-blog-post',
        'content' => 'This is the content of my first blog post.',
        'status' => 'publish',
        'user_id' => $this->user->id,
    ]);
});

test('slug is automatically generated from the title', function () {
    $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => 'Laravel 13 Is Amazing',
        'content' => 'Some content here.',
        'status' => 'draft',
    ]);

    $this->assertDatabaseHas('posts', [
        'title' => 'Laravel 13 Is Amazing',
        'slug' => 'laravel-13-is-amazing',
    ]);
});

test('store validates required fields', function () {
    $response = $this->actingAs($this->user)->post(route('posts.store'), []);

    $response->assertSessionHasErrors(['title', 'content', 'status']);
});

test('store validates title max length', function () {
    $response = $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => str_repeat('a', 256),
        'content' => 'Some content.',
        'status' => 'publish',
    ]);

    $response->assertSessionHasErrors(['title']);
});

test('store validates status must be draft or publish', function () {
    $response = $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => 'Test Post',
        'content' => 'Some content.',
        'status' => 'archived',
    ]);

    $response->assertSessionHasErrors(['status']);
});

test('store validates slug uniqueness', function () {
    Post::factory()->create(['title' => 'Duplicate Title', 'slug' => 'duplicate-title']);

    $response = $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => 'Duplicate Title',
        'content' => 'Different content.',
        'status' => 'draft',
    ]);

    $response->assertSessionHasErrors(['slug']);
});

// ============================================================
// Show Tests
// ============================================================

test('show page displays a single post', function () {
    $post = Post::factory()->create();

    $response = $this->actingAs($this->user)->get(route('posts.show', $post));

    $response->assertStatus(200);
    $response->assertViewIs('posts.show');
    $response->assertSee($post->title);
    $response->assertSee($post->content);
});

test('show returns 404 for non-existent post', function () {
    $response = $this->actingAs($this->user)->get(route('posts.show', 9999));

    $response->assertStatus(404);
});

// ============================================================
// Edit and Update Tests
// ============================================================

test('edit page displays the form with existing data', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user)->get(route('posts.edit', $post));

    $response->assertStatus(200);
    $response->assertViewIs('posts.edit');
    $response->assertSee($post->title);
    $response->assertSee($post->content);
});

test('a post can be updated', function () {
    $post = Post::factory()->create([
        'title' => 'Original Title',
        'slug' => 'original-title',
        'content' => 'Original content.',
        'status' => 'draft',
        'user_id' => $this->user->id,
    ]);

    $response = $this->actingAs($this->user)->put(route('posts.update', $post), [
        'title' => 'Updated Title',
        'content' => 'Updated content.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post updated successfully.');

    $this->assertDatabaseHas('posts', [
        'id' => $post->id,
        'title' => 'Updated Title',
        'slug' => 'updated-title',
        'content' => 'Updated content.',
        'status' => 'publish',
    ]);
});

test('update validates required fields', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user)->put(route('posts.update', $post), []);

    $response->assertSessionHasErrors(['title', 'content', 'status']);
});

test('update allows same slug for the same post', function () {
    $post = Post::factory()->create([
        'title' => 'Keep This Title',
        'slug' => 'keep-this-title',
        'user_id' => $this->user->id,
    ]);

    $response = $this->actingAs($this->user)->put(route('posts.update', $post), [
        'title' => 'Keep This Title',
        'content' => 'Updated content only.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHasNoErrors();
});

// ============================================================
// Delete Tests
// ============================================================

test('a post can be deleted', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user)->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post deleted successfully.');

    $this->assertDatabaseMissing('posts', [
        'id' => $post->id,
    ]);
});

test('deleting a non-existent post returns 404', function () {
    $response = $this->actingAs($this->user)->delete(route('posts.destroy', 9999));

    $response->assertStatus(404);
});

// ============================================================
// Authentication Tests
// ============================================================

test('unauthenticated user is redirected to login from index', function () {
    $response = $this->get(route('posts.index'));

    $response->assertRedirect(route('login'));
});

test('unauthenticated user is redirected to login from create', function () {
    $response = $this->get(route('posts.create'));

    $response->assertRedirect(route('login'));
});

test('unauthenticated user is redirected to login from store', function () {
    $response = $this->post(route('posts.store'), [
        'title' => 'Test',
        'content' => 'Content',
        'status' => 'draft',
    ]);

    $response->assertRedirect(route('login'));
});

test('unauthenticated user is redirected to login from show', function () {
    $post = Post::factory()->create();

    $response = $this->get(route('posts.show', $post));

    $response->assertRedirect(route('login'));
});

test('unauthenticated user is redirected to login from edit', function () {
    $post = Post::factory()->create();

    $response = $this->get(route('posts.edit', $post));

    $response->assertRedirect(route('login'));
});

test('unauthenticated user is redirected to login from update', function () {
    $post = Post::factory()->create();

    $response = $this->put(route('posts.update', $post), [
        'title' => 'Updated',
        'content' => 'Content',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('login'));
});

test('unauthenticated user is redirected to login from destroy', function () {
    $post = Post::factory()->create();

    $response = $this->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('login'));
});

// ============================================================
// Authorization Tests
// ============================================================

test('user cannot edit a post they do not own', function () {
    $otherUser = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $otherUser->id]);

    $response = $this->actingAs($this->user)->get(route('posts.edit', $post));

    $response->assertStatus(403);
});

test('user cannot update a post they do not own', function () {
    $otherUser = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $otherUser->id]);

    $response = $this->actingAs($this->user)->put(route('posts.update', $post), [
        'title' => 'Hijacked Title',
        'content' => 'Hijacked content.',
        'status' => 'publish',
    ]);

    $response->assertStatus(403);
});

test('user cannot delete a post they do not own', function () {
    $otherUser = User::factory()->create();
    $post = Post::factory()->create(['user_id' => $otherUser->id]);

    $response = $this->actingAs($this->user)->delete(route('posts.destroy', $post));

    $response->assertStatus(403);

    $this->assertDatabaseHas('posts', ['id' => $post->id]);
});

test('post owner can edit their own post', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user)->get(route('posts.edit', $post));

    $response->assertStatus(200);
});

test('post owner can delete their own post', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user)->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('posts.index'));
    $this->assertDatabaseMissing('posts', ['id' => $post->id]);
});
```

Save the file.

### Key Changes in the Updated Tests

Here is a summary of what changed and why:

**Every request now uses `actingAs($this->user)`.** This simulates an authenticated user making the request. Without it, the `auth` middleware would redirect to the login page and the test would fail.

**The store test now asserts `user_id`.** The `assertDatabaseHas` check includes `'user_id' => $this->user->id` to verify that the post is correctly assigned to the authenticated user.

**Edit, update, and delete tests specify ownership.** Tests that need to pass authorization now create posts with `'user_id' => $this->user->id` so the authenticated user is the owner. Without this, the policy would block the request with a 403.

**Seven new authentication tests.** These verify that unauthenticated users are redirected to the login page for every route in the controller (index, create, store, show, edit, update, destroy).

**Five new authorization tests.** Three tests verify that a user cannot edit, update, or delete posts created by another user (expecting 403 status). Two tests explicitly confirm that the post owner can edit and delete their own posts (positive authorization tests).


## Step 8: Add Login Tests {#step-8-add-login-tests}

Let's also add tests for the login functionality itself. Create a new test file:

```
php artisan make:test Auth/LoginTest --pest
```

Open `tests/Feature/Auth/LoginTest.php` and add:

```php
<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

test('login page is displayed', function () {
    $response = $this->get(route('login'));

    $response->assertStatus(200);
    $response->assertSee('Login');
});

test('user can login with correct credentials', function () {
    $user = User::factory()->create([
        'password' => bcrypt('password123'),
    ]);

    $response = $this->post(route('login'), [
        'email' => $user->email,
        'password' => 'password123',
    ]);

    $response->assertRedirect(route('posts.index'));
    $this->assertAuthenticatedAs($user);
});

test('user cannot login with incorrect password', function () {
    $user = User::factory()->create([
        'password' => bcrypt('password123'),
    ]);

    $response = $this->post(route('login'), [
        'email' => $user->email,
        'password' => 'wrong-password',
    ]);

    $response->assertSessionHasErrors(['email']);
    $this->assertGuest();
});

test('user cannot login with non-existent email', function () {
    $response = $this->post(route('login'), [
        'email' => 'nobody@example.com',
        'password' => 'password123',
    ]);

    $response->assertSessionHasErrors(['email']);
    $this->assertGuest();
});

test('login validates required fields', function () {
    $response = $this->post(route('login'), []);

    $response->assertSessionHasErrors(['email', 'password']);
});

test('user can logout', function () {
    $user = User::factory()->create();

    $response = $this->actingAs($user)->post(route('logout'));

    $response->assertRedirect(route('login'));
    $this->assertGuest();
});
```

These tests cover:

- `assertAuthenticatedAs($user)` confirms the user is logged in after a successful login attempt.
- `assertGuest()` confirms the user is not logged in after a failed attempt or after logging out.
- The login form is tested for both valid and invalid credentials, missing fields, and non-existent emails.

Save the file.


## Step 9: Run All Tests {#step-9-run-all-tests}

Run the complete test suite:

```
php artisan test
```

You should see all tests passing:

```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\Auth\LoginTest
  ✓ login page is displayed                                              0.14s  
  ✓ user can login with correct credentials                              0.03s  
  ✓ user cannot login with incorrect password                            0.21s  
  ✓ user cannot login with non-existent email                            0.23s  
  ✓ login validates required fields                                      0.03s  
  ✓ user can logout                                                      0.01s  

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
  ✓ user cannot delete a post they do not own                            0.01s  
  ✓ post owner can edit their own post                                   0.01s  
  ✓ post owner can delete their own post                                 0.01s  

  Tests:    37 passed (94 assertions)
  Duration: 0.97s

```

We went from 19 tests to 37 tests. Here is the breakdown:

- **19 original CRUD tests** (updated with `actingAs` and ownership)
- **7 authentication tests** (redirect to login for every route)
- **5 authorization tests** (ownership enforcement for edit, update, delete)
- **6 login tests** (form display, valid/invalid login, logout)
- **+1 ExampleTest** (unit) + **+1 ExampleTest** (feature) = already counted in the total (original crud tests)


## Conclusion {#conclusion}

In this tutorial, we added authentication and authorization to our Laravel 13 blog application. We built a login system from scratch, tracked post ownership with a `user_id` column, created a policy to enforce ownership rules, and used Laravel 13's PHP attributes to apply everything cleanly on the controller.

Here are the key takeaways:

- **`#[Middleware('auth')]` on the class is cleaner than constructor calls.** You see the middleware requirement at a glance, right at the top of the class. No need to check the constructor or the route file.
- **`#[Authorize('update', 'post')]` ties policy checks to methods.** The second argument is the route parameter name, not the variable name. Laravel resolves the model instance from the route and passes it to the policy.
- **Policies keep authorization logic separate.** Instead of writing `if` statements in the controller, the policy encapsulates all ownership checks in one place. If the rules change, you update one file.
- **`actingAs()` makes authenticated testing simple.** One method call simulates a logged-in user for the entire request. Combined with `beforeEach()`, every test in the file can share the same user setup.
- **Test both authentication and authorization separately.** Authentication tests verify that unauthenticated users are redirected. Authorization tests verify that authenticated users can only access resources they own. These are different concerns and should be tested independently.
- **The test suite grew from 19 to 37 tests.** Each new security feature came with tests that verify it works. This gives you confidence that future changes will not accidentally remove a security check.

In the next tutorial, we will [Build a REST API for Your Blog with Sanctum Authentication](https://qadrlabs.com/post/laravel-13-build-a-rest-api-for-your-blog-with-sanctum-authentication).