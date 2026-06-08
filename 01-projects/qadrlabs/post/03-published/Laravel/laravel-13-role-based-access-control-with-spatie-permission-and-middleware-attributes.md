---
title: "Laravel 13: Role-Based Access Control with Spatie Permission and Middleware Attributes"
slug: "laravel-13-role-based-access-control-with-spatie-permission-and-middleware-attributes"
category: "Laravel"
date: "2026-03-27"
status: "published"
---

In previous versions of Laravel, applying role and permission checks on controllers meant either cluttering the constructor with `$this->middleware()` calls, scattering middleware across route files, or implementing the `HasMiddleware` interface with a static method. None of these approaches were particularly readable.

Laravel 13's `#[Middleware]` attribute changes that. You can now declare Spatie Permission's `role`, `permission`, and `role_or_permission` middleware directly on controller classes and methods using clean, declarative PHP attributes. The security rules become visible at a glance, right where they matter.

In this tutorial, we will build a simple content management system with role-based access control using Spatie Laravel Permission and Laravel 13's middleware attributes.

> **Note:** This tutorial has not been fully tested end-to-end. The code is based on the official Laravel 13, Spatie Permission v6, and PHP attributes documentation. If you encounter issues, please refer to the [Spatie Permission docs](https://spatie.be/docs/laravel-permission) and the [Laravel 13 docs](https://laravel.com/docs/13.x).


## How It Works {#how-it-works}

Before diving into code, let's understand what connects the pieces.

Spatie Laravel Permission ships with three middleware classes:

- `RoleMiddleware` (alias: `role`) checks if the user has a specific role.
- `PermissionMiddleware` (alias: `permission`) checks if the user has a specific permission.
- `RoleOrPermissionMiddleware` (alias: `role_or_permission`) checks if the user has either a role or a permission.

Laravel 13's `#[Middleware]` attribute accepts any registered middleware alias as a string. Since Spatie's middleware are registered as aliases (`role`, `permission`, `role_or_permission`), you can use them directly in the attribute:

```php
#[Middleware('role:admin')]           // Spatie's RoleMiddleware
#[Middleware('permission:edit posts')] // Spatie's PermissionMiddleware
```

This is the same syntax you would use in a route file or constructor, just declared as a PHP attribute instead.


## Overview {#overview}

### What You'll Build

- A Laravel 13 application with three roles: `admin`, `editor`, and `viewer`.
- An `ArticleController` protected by `#[Middleware]` attributes with Spatie's permission middleware.
- A seeder that creates roles, permissions, and test users.
- Pest tests that verify role-based access works correctly.

### What You'll Learn

- How to install and configure Spatie Laravel Permission in Laravel 13.
- How to register Spatie's middleware aliases.
- How to use `#[Middleware('role:...')]` and `#[Middleware('permission:...')]` on controllers.
- How to combine `#[Middleware]` at class level with method-level permission checks.
- How to write tests for role-based access control.
- How the old approach compares to the new attribute approach.

### What You'll Need

- PHP 8.3 or higher.
- Composer installed globally.
- MySQL or another supported database.
- Basic familiarity with Laravel and middleware concepts.


## Step 1: Create a New Project {#step-1-create-project}

```
composer create-project laravel/laravel --prefer-dist permission-demo
cd permission-demo
```

Configure your database in `.env`:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_permission_demo
DB_USERNAME=root
DB_PASSWORD=password
```

Run the initial migrations:

```
php artisan migrate
```


## Step 2: Install Spatie Laravel Permission {#step-2-install-spatie}

Install the package via Composer:

```
composer require spatie/laravel-permission
```

Publish the migration and configuration files:

```
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
```

This creates `config/permission.php` and a migration file for the roles, permissions, and pivot tables.

Run the migration:

```
php artisan migrate
```

### Add the HasRoles Trait to the User Model

Open `app/Models/User.php`. In a fresh Laravel 13 project, the default model already uses the `#[Fillable]` and `#[Hidden]` attributes:

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
}
```

Add the `HasRoles` trait from Spatie:

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
use Spatie\Permission\Traits\HasRoles;

#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, HasRoles, Notifiable;

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
}
```

The only changes are the `use Spatie\Permission\Traits\HasRoles;` import and adding `HasRoles` to the trait list. This gives the User model methods like `assignRole()`, `hasRole()`, `hasPermissionTo()`, and `givePermissionTo()`.

Save the file.

### Register Middleware Aliases

Open `bootstrap/app.php` and register Spatie's middleware aliases:

```php
<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->alias([
            'role' => \Spatie\Permission\Middleware\RoleMiddleware::class,
            'permission' => \Spatie\Permission\Middleware\PermissionMiddleware::class,
            'role_or_permission' => \Spatie\Permission\Middleware\RoleOrPermissionMiddleware::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
```

The `alias()` method maps short names to the full middleware class paths. After this, you can use `'role:admin'`, `'permission:edit articles'`, or `'role_or_permission:admin|edit articles'` anywhere middleware is accepted, including `#[Middleware]` attributes.

Save the file.


## Step 3: Create the Article Model {#step-3-create-model}

```
php artisan make:model Article -m
```

Open the migration file and define the schema:

```php
public function up(): void
{
    Schema::create('articles', function (Blueprint $table) {
        $table->id();
        $table->string('title');
        $table->text('content');
        $table->enum('status', ['draft', 'published'])->default('draft');
        $table->foreignId('user_id')->constrained()->onDelete('cascade');
        $table->timestamps();
    });
}
```

Run the migration:

```
php artisan migrate
```

Configure the model (`app/Models/Article.php`):

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['title', 'content', 'status', 'user_id'])]
class Article extends Model
{
    use HasFactory;

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

Save the file.

### Add the Articles Relationship to the User Model

Since articles belong to users, we need the inverse relationship on the User model. Open `app/Models/User.php` and add the `articles()` method:

```php
use Illuminate\Database\Eloquent\Relations\HasMany;

// Inside the User class, after the casts() method:

public function articles(): HasMany
{
    return $this->hasMany(Article::class);
}
```

We add this now while we are working with models, so it is ready when the controller uses `$request->user()->articles()->create(...)` later.

Save the file.

### Create the Article Factory

We will need this for testing. Generate the factory now:

```
php artisan make:factory ArticleFactory --model=Article
```

Open `database/factories/ArticleFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Article>
 */
class ArticleFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'title' => $this->faker->sentence(),
            'content' => $this->faker->paragraphs(3, true),
            'status' => $this->faker->randomElement(['draft', 'published']),
            'user_id' => User::factory(),
        ];
    }
}
```

Save the file.


## Step 4: Seed Roles, Permissions, and Users {#step-4-seed-data}

```
php artisan make:seeder RolePermissionSeeder
```

Open `database/seeders/RolePermissionSeeder.php`:

```php
<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class RolePermissionSeeder extends Seeder
{
    public function run(): void
    {
        // Reset cached roles and permissions
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        // Create permissions
        $permissions = [
            'view articles',
            'create articles',
            'edit articles',
            'delete articles',
            'publish articles',
        ];

        foreach ($permissions as $permission) {
            Permission::create(['name' => $permission]);
        }

        // Admin: full access
        Role::create(['name' => 'admin'])
            ->givePermissionTo(Permission::all());

        // Editor: can view, create, edit, and publish
        Role::create(['name' => 'editor'])
            ->givePermissionTo([
                'view articles',
                'create articles',
                'edit articles',
                'publish articles',
            ]);

        // Viewer: can only view
        Role::create(['name' => 'viewer'])
            ->givePermissionTo(['view articles']);

        // Create test users
        User::create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
        ])->assignRole('admin');

        User::create([
            'name' => 'Editor User',
            'email' => 'editor@example.com',
            'password' => bcrypt('password'),
        ])->assignRole('editor');

        User::create([
            'name' => 'Viewer User',
            'email' => 'viewer@example.com',
            'password' => bcrypt('password'),
        ])->assignRole('viewer');
    }
}
```

Run the seeder:

```
php artisan db:seed --class=RolePermissionSeeder
```


## Step 5: Build the Controller with Middleware Attributes {#step-5-controller-with-attributes}

This is the core of the tutorial. We will build the `ArticleController` using `#[Middleware]` attributes with Spatie's permission middleware.

```
php artisan make:controller ArticleController --resource
```

Open `app/Http/Controllers/ArticleController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Article;
use Illuminate\Http\Request;
use Illuminate\Routing\Attributes\Controllers\Middleware;

#[Middleware('auth')]
#[Middleware('permission:view articles')]
class ArticleController extends Controller
{
    /**
     * Display a listing of articles.
     * Accessible by: admin, editor, viewer (all have 'view articles')
     */
    public function index()
    {
        $articles = Article::with('user')->latest()->paginate(10);

        return view('articles.index', compact('articles'));
    }

    /**
     * Show the form for creating a new article.
     * Accessible by: admin, editor (both have 'create articles')
     */
    #[Middleware('permission:create articles')]
    public function create()
    {
        return view('articles.create');
    }

    /**
     * Store a newly created article.
     * Accessible by: admin, editor
     */
    #[Middleware('permission:create articles')]
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|max:255',
            'content' => 'required',
            'status' => 'required|in:draft,published',
        ]);

        $request->user()->articles()->create($validated);

        return redirect()->route('articles.index')
            ->with('success', 'Article created successfully.');
    }

    /**
     * Display the specified article.
     * Accessible by: admin, editor, viewer (all have 'view articles')
     */
    public function show(Article $article)
    {
        return view('articles.show', compact('article'));
    }

    /**
     * Show the form for editing an article.
     * Accessible by: admin, editor (both have 'edit articles')
     */
    #[Middleware('permission:edit articles')]
    public function edit(Article $article)
    {
        return view('articles.edit', compact('article'));
    }

    /**
     * Update the specified article.
     * Accessible by: admin, editor
     */
    #[Middleware('permission:edit articles')]
    public function update(Request $request, Article $article)
    {
        $validated = $request->validate([
            'title' => 'required|max:255',
            'content' => 'required',
            'status' => 'required|in:draft,published',
        ]);

        $article->update($validated);

        return redirect()->route('articles.index')
            ->with('success', 'Article updated successfully.');
    }

    /**
     * Remove the specified article.
     * Accessible by: admin only (only admin has 'delete articles')
     */
    #[Middleware('permission:delete articles')]
    public function destroy(Article $article)
    {
        $article->delete();

        return redirect()->route('articles.index')
            ->with('success', 'Article deleted successfully.');
    }
}
```

Let's break down how the middleware attributes work:

**Class-level attributes:**

```php
#[Middleware('auth')]
#[Middleware('permission:view articles')]
class ArticleController extends Controller
```

Both apply to every method. All requests must be authenticated and have the `view articles` permission.

**Method-level attributes:**

```php
#[Middleware('permission:create articles')]
public function create()
```

This adds an additional check on top of the class-level middleware. The viewer role only has `view articles`, so viewers receive a 403 when trying to access `create()`, `store()`, `edit()`, `update()`, or `destroy()`.

**The resulting access matrix:**

| Method | admin | editor | viewer |
|--------|-------|--------|--------|
| `index()` | Yes | Yes | Yes |
| `show()` | Yes | Yes | Yes |
| `create()` | Yes | Yes | 403 |
| `store()` | Yes | Yes | 403 |
| `edit()` | Yes | Yes | 403 |
| `update()` | Yes | Yes | 403 |
| `destroy()` | Yes | 403 | 403 |

This matrix is immediately readable from the controller code. Each `#[Middleware]` attribute documents exactly who can access what.

Save the file.


## Step 6: Create the Article Views {#step-6-create-views}

With the controller in place, let's create the Blade views it references. Create the directory structure first:

```bash
mkdir -p resources/views/articles
```

**resources/views/articles/index.blade.php:**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Articles</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-7xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-3xl font-bold text-gray-900">Articles</h1>
            <div class="flex items-center space-x-4">
                @can('create articles')
                <a href="{{ route('articles.create') }}" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm">
                    Create Article
                </a>
                @endcan
                <form action="{{ route('logout') }}" method="POST" class="inline">
                    @csrf
                    <button type="submit" class="text-gray-600 hover:text-gray-900 text-sm underline transition">Logout ({{ auth()->user()->name }})</button>
                </form>
            </div>
        </div>

        @if(session('success'))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative mb-6">
                {{ session('success') }}
            </div>
        @endif

        <div class="overflow-x-auto">
            <table class="min-w-full bg-white border border-gray-200 shadow-sm rounded-lg overflow-hidden">
                <thead class="bg-gray-50 border-b border-gray-200">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-16">No</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Title</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Author</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                    @forelse($articles as $article)
                    <tr class="hover:bg-gray-50 transition duration-150">
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center">{{ $articles->firstItem() + $loop->index }}</td>
                        <td class="px-6 py-4 text-sm font-medium text-gray-900">{{ $article->title }}</td>
                        <td class="px-6 py-4 text-sm text-gray-500">{{ $article->user->name }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm">
                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full {{ $article->status === 'published' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800' }}">
                                {{ ucfirst($article->status) }}
                            </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                            <a href="{{ route('articles.show', $article) }}" class="inline-flex items-center px-3 py-1.5 bg-blue-600 rounded-md text-xs text-white uppercase hover:bg-blue-700 transition shadow-sm">View</a>
                            @can('edit articles')
                            <a href="{{ route('articles.edit', $article) }}" class="inline-flex items-center px-3 py-1.5 bg-amber-500 rounded-md text-xs text-white uppercase hover:bg-amber-600 transition shadow-sm">Edit</a>
                            @endcan
                            @can('delete articles')
                            <form action="{{ route('articles.destroy', $article) }}" method="POST" class="inline-block m-0">
                                @csrf
                                @method('DELETE')
                                <button type="submit" onclick="return confirm('Are you sure?')" class="inline-flex items-center px-3 py-1.5 bg-red-600 rounded-md text-xs text-white uppercase hover:bg-red-700 transition shadow-sm">Delete</button>
                            </form>
                            @endcan
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="px-6 py-4 text-center text-sm text-gray-500">No articles found.</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="mt-6">
            {{ $articles->links() }}
        </div>
    </div>
</body>
</html>
```

Notice the `@can('create articles')`, `@can('edit articles')`, and `@can('delete articles')` directives. These Blade directives check the user's permissions and hide buttons that the user is not allowed to use. This is a UI convenience on top of the middleware protection. The middleware provides the real security; the Blade directives prevent showing buttons that would lead to a 403.

**resources/views/articles/create.blade.php:**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Article</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-gray-900">Create Article</h1>
            <a href="{{ route('articles.index') }}" class="text-gray-600 hover:text-gray-900 underline text-sm transition">Back</a>
        </div>

        @if($errors->any())
            <div class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded mb-6">
                <ul class="list-disc list-inside text-sm">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('articles.store') }}" method="POST" class="space-y-6">
            @csrf
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input type="text" name="title" value="{{ old('title') }}" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Content</label>
                <textarea name="content" rows="8" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition resize-y">{{ old('content') }}</textarea>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select name="status" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition">
                    <option value="draft" {{ old('status') == 'draft' ? 'selected' : '' }}>Draft</option>
                    <option value="published" {{ old('status') == 'published' ? 'selected' : '' }}>Published</option>
                </select>
            </div>
            <div class="pt-2 flex justify-end">
                <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-6 rounded-md transition duration-200 shadow-sm">
                    Submit Article
                </button>
            </div>
        </form>
    </div>
</body>
</html>
```

**resources/views/articles/show.blade.php:**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $article->title }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-3xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-start mb-6 pb-6 border-b border-gray-200">
            <div>
                <h1 class="text-3xl font-bold text-gray-900 mb-2">{{ $article->title }}</h1>
                <p class="text-sm text-gray-500">By {{ $article->user->name }} &middot; {{ $article->created_at->format('M d, Y') }}</p>
            </div>
            <div class="flex space-x-3">
                <a href="{{ route('articles.index') }}" class="text-sm font-medium text-gray-600 hover:text-gray-900 bg-gray-100 hover:bg-gray-200 px-4 py-2 rounded-md transition shadow-sm border border-gray-200">Back</a>
                @can('edit articles')
                <a href="{{ route('articles.edit', $article) }}" class="text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 px-4 py-2 rounded-md shadow-sm transition">Edit</a>
                @endcan
            </div>
        </div>
        <div class="prose max-w-none text-gray-800 leading-relaxed whitespace-pre-wrap">{{ $article->content }}</div>
    </div>
</body>
</html>
```

**resources/views/articles/edit.blade.php:**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Article</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-gray-900">Edit Article</h1>
            <a href="{{ route('articles.index') }}" class="text-gray-600 hover:text-gray-900 underline text-sm transition">Back</a>
        </div>

        @if($errors->any())
            <div class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded mb-6">
                <ul class="list-disc list-inside text-sm">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('articles.update', $article) }}" method="POST" class="space-y-6">
            @csrf
            @method('PUT')
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input type="text" name="title" value="{{ old('title', $article->title) }}" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Content</label>
                <textarea name="content" rows="8" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition resize-y">{{ old('content', $article->content) }}</textarea>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select name="status" required
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition">
                    <option value="draft" {{ old('status', $article->status) == 'draft' ? 'selected' : '' }}>Draft</option>
                    <option value="published" {{ old('status', $article->status) == 'published' ? 'selected' : '' }}>Published</option>
                </select>
            </div>
            <div class="pt-2 flex justify-end">
                <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-6 rounded-md transition duration-200 shadow-sm">
                    Update Article
                </button>
            </div>
        </form>
    </div>
</body>
</html>
```

Save all view files.


## Step 7: Set Up Authentication {#step-7-setup-auth}

The controller requires the `auth` middleware, so we need a login system. Create a minimal login controller and view.

### Create the Login Controller

```
php artisan make:controller Auth/LoginController
```

Open `app/Http/Controllers/Auth/LoginController.php`:

```php
<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LoginController extends Controller
{
    public function showLoginForm()
    {
        return view('auth.login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::attempt($credentials)) {
            $request->session()->regenerate();
            return redirect()->intended(route('articles.index'));
        }

        return back()->withErrors([
            'email' => 'The provided credentials do not match our records.',
        ])->onlyInput('email');
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('login');
    }
}
```

Save the file.

### Create the Login View

Create `resources/views/auth/login.blade.php`:

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


## Step 8: Register Routes {#step-8-register-routes}

Open `routes/web.php`:

```php
<?php

use App\Http\Controllers\ArticleController;
use App\Http\Controllers\Auth\LoginController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('articles.index');
});

Route::get('/login', [LoginController::class, 'showLoginForm'])->name('login');
Route::post('/login', [LoginController::class, 'login']);
Route::post('/logout', [LoginController::class, 'logout'])->name('logout');

Route::resource('articles', ArticleController::class);
```

No middleware definitions in the route file. The `#[Middleware]` attributes on the controller handle everything.

Save the file.


## Step 9: Install Pest {#step-9-install-pest}

A fresh Laravel 13 project ships with PHPUnit, not Pest. Replace it:

```
composer remove phpunit/phpunit
composer require pestphp/pest --dev --with-all-dependencies
```

Initialize Pest:

```
./vendor/bin/pest --init
```

Verify Pest is working:

```
./vendor/bin/pest
```

You should see the default example tests passing.


## Step 10: Write Tests {#step-10-write-tests}

Create a test file:

```
php artisan make:test ArticlePermissionTest --pest
```

Open `tests/Feature/ArticlePermissionTest.php`:

```php
<?php

use App\Models\Article;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

uses(RefreshDatabase::class);

beforeEach(function () {
    // Reset permission cache
    app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

    // Create permissions
    $permissions = [
        'view articles',
        'create articles',
        'edit articles',
        'delete articles',
        'publish articles',
    ];

    foreach ($permissions as $perm) {
        Permission::create(['name' => $perm]);
    }

    // Create roles
    Role::create(['name' => 'admin'])->givePermissionTo(Permission::all());
    Role::create(['name' => 'editor'])->givePermissionTo([
        'view articles', 'create articles', 'edit articles', 'publish articles',
    ]);
    Role::create(['name' => 'viewer'])->givePermissionTo(['view articles']);

    // Create users
    $this->admin = User::factory()->create()->assignRole('admin');
    $this->editor = User::factory()->create()->assignRole('editor');
    $this->viewer = User::factory()->create()->assignRole('viewer');
});

// ============================================================
// Index (requires: view articles)
// ============================================================

test('admin can view article list', function () {
    $response = $this->actingAs($this->admin)->get(route('articles.index'));
    $response->assertStatus(200);
});

test('editor can view article list', function () {
    $response = $this->actingAs($this->editor)->get(route('articles.index'));
    $response->assertStatus(200);
});

test('viewer can view article list', function () {
    $response = $this->actingAs($this->viewer)->get(route('articles.index'));
    $response->assertStatus(200);
});

test('unauthenticated user is redirected to login', function () {
    $response = $this->get(route('articles.index'));
    $response->assertRedirect(route('login'));
});

// ============================================================
// Create (requires: create articles)
// ============================================================

test('admin can access create form', function () {
    $response = $this->actingAs($this->admin)->get(route('articles.create'));
    $response->assertStatus(200);
});

test('editor can access create form', function () {
    $response = $this->actingAs($this->editor)->get(route('articles.create'));
    $response->assertStatus(200);
});

test('viewer cannot access create form', function () {
    $response = $this->actingAs($this->viewer)->get(route('articles.create'));
    $response->assertStatus(403);
});

test('admin can store an article', function () {
    $response = $this->actingAs($this->admin)->post(route('articles.store'), [
        'title' => 'Admin Article',
        'content' => 'Content by admin.',
        'status' => 'published',
    ]);

    $response->assertRedirect(route('articles.index'));
    $this->assertDatabaseHas('articles', ['title' => 'Admin Article']);
});

test('viewer cannot store an article', function () {
    $response = $this->actingAs($this->viewer)->post(route('articles.store'), [
        'title' => 'Viewer Article',
        'content' => 'This should fail.',
        'status' => 'draft',
    ]);

    $response->assertStatus(403);
    $this->assertDatabaseMissing('articles', ['title' => 'Viewer Article']);
});

// ============================================================
// Edit (requires: edit articles)
// ============================================================

test('admin can edit an article', function () {
    $article = Article::factory()->create(['user_id' => $this->admin->id]);

    $response = $this->actingAs($this->admin)->get(route('articles.edit', $article));
    $response->assertStatus(200);
});

test('editor can edit an article', function () {
    $article = Article::factory()->create(['user_id' => $this->editor->id]);

    $response = $this->actingAs($this->editor)->get(route('articles.edit', $article));
    $response->assertStatus(200);
});

test('viewer cannot edit an article', function () {
    $article = Article::factory()->create(['user_id' => $this->admin->id]);

    $response = $this->actingAs($this->viewer)->get(route('articles.edit', $article));
    $response->assertStatus(403);
});

// ============================================================
// Delete (requires: delete articles)
// ============================================================

test('admin can delete an article', function () {
    $article = Article::factory()->create(['user_id' => $this->admin->id]);

    $response = $this->actingAs($this->admin)->delete(route('articles.destroy', $article));

    $response->assertRedirect(route('articles.index'));
    $this->assertDatabaseMissing('articles', ['id' => $article->id]);
});

test('editor cannot delete an article', function () {
    $article = Article::factory()->create(['user_id' => $this->editor->id]);

    $response = $this->actingAs($this->editor)->delete(route('articles.destroy', $article));
    $response->assertStatus(403);

    $this->assertDatabaseHas('articles', ['id' => $article->id]);
});

test('viewer cannot delete an article', function () {
    $article = Article::factory()->create(['user_id' => $this->admin->id]);

    $response = $this->actingAs($this->viewer)->delete(route('articles.destroy', $article));
    $response->assertStatus(403);
});
```

The `beforeEach()` block creates fresh roles, permissions, and users before every test. `forgetCachedPermissions()` clears Spatie's cache to ensure clean state.

Save the file.


## Step 11: Run the Tests {#step-11-run-tests}

```
php artisan test --filter=ArticlePermissionTest
```

All 15 tests should pass, confirming the access matrix works correctly.


## Step 12: Try It Out {#step-12-try-it-out}

```
php artisan serve
```

Test with different users:

- **Admin** (`admin@example.com` / `password`): Can see all buttons, create/edit/delete articles.
- **Editor** (`editor@example.com` / `password`): Can see Create and Edit buttons, but no Delete button. Trying to access `/articles/{id}/edit` works, but manually visiting a delete URL returns 403.
- **Viewer** (`viewer@example.com` / `password`): Can only see View buttons. Create, Edit, and Delete buttons are hidden. Direct URL access to those routes returns 403.


## The Old Way vs The New Way {#old-vs-new}

To appreciate the attribute approach, let's compare it with the older patterns.

### Constructor Approach (Laravel 10 and earlier)

```php
class ArticleController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
        $this->middleware('permission:view articles');
        $this->middleware('permission:create articles')->only(['create', 'store']);
        $this->middleware('permission:edit articles')->only(['edit', 'update']);
        $this->middleware('permission:delete articles')->only(['destroy']);
    }

    public function index() { /* ... */ }
    public function create() { /* ... */ }
    // ...
}
```

The middleware is separated from the methods it protects. You have to read the constructor to understand what `create()` requires, then scroll down to find the actual method.

### HasMiddleware Interface (Laravel 11)

```php
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

class ArticleController extends Controller implements HasMiddleware
{
    public static function middleware(): array
    {
        return [
            'auth',
            'permission:view articles',
            new Middleware('permission:create articles', only: ['create', 'store']),
            new Middleware('permission:edit articles', only: ['edit', 'update']),
            new Middleware('permission:delete articles', only: ['destroy']),
        ];
    }

    public function index() { /* ... */ }
    public function create() { /* ... */ }
    // ...
}
```

Better than the constructor, but the middleware is still in a separate static method.

### PHP Attributes (Laravel 13)

```php
use Illuminate\Routing\Attributes\Controllers\Middleware;

#[Middleware('auth')]
#[Middleware('permission:view articles')]
class ArticleController extends Controller
{
    #[Middleware('permission:create articles')]
    public function create() { /* ... */ }

    #[Middleware('permission:edit articles')]
    public function edit(Article $article) { /* ... */ }

    #[Middleware('permission:delete articles')]
    public function destroy(Article $article) { /* ... */ }
}
```

The middleware is colocated with the class and methods it protects. No cross-referencing needed.


## Using Role Middleware and Pipe Syntax {#role-middleware-and-pipe-syntax}

The examples above use `permission:` middleware. You can also use `role:` and `role_or_permission:` with the same attribute syntax.

### Role-Based Access

```php
#[Middleware('auth')]
#[Middleware('role:admin')]
class AdminController extends Controller
{
    // Only users with the 'admin' role can access any method
}
```

### Multiple Roles with Pipe Syntax

The `|` (pipe) character acts as OR:

```php
#[Middleware('role:admin|editor')]
class ContentController extends Controller
{
    // Accessible by admin OR editor
}
```

### Role or Permission

```php
#[Middleware('role_or_permission:admin|edit articles')]
public function edit(Article $article)
{
    // Accessible by anyone with the 'admin' role
    // OR anyone with the 'edit articles' permission
}
```

### Using `only` and `except`

```php
#[Middleware('auth')]
#[Middleware('role:admin', only: ['destroy'])]
#[Middleware('permission:edit articles', except: ['index', 'show'])]
class ArticleController extends Controller
{
    // index, show: auth only
    // create, store, edit, update: auth + edit articles permission
    // destroy: auth + admin role
}
```

### Specifying a Guard

For API routes using a different guard:

```php
#[Middleware('role:admin,api')]
class ApiAdminController extends Controller
{
    // Checks the 'admin' role on the 'api' guard
}
```


## Quick Reference {#quick-reference}

| Use Case | Attribute |
|----------|-----------|
| Require a role | `#[Middleware('role:admin')]` |
| Require one of multiple roles | `#[Middleware('role:admin\|editor')]` |
| Require a permission | `#[Middleware('permission:edit articles')]` |
| Require one of multiple permissions | `#[Middleware('permission:edit articles\|publish articles')]` |
| Require a role or permission | `#[Middleware('role_or_permission:admin\|edit articles')]` |
| Restrict to specific methods | `#[Middleware('role:admin', only: ['destroy'])]` |
| Exclude specific methods | `#[Middleware('permission:edit articles', except: ['index', 'show'])]` |
| Specify a guard | `#[Middleware('role:admin,api')]` |


## Conclusion {#conclusion}

In this tutorial, we implemented role-based access control using Spatie Laravel Permission with Laravel 13's `#[Middleware]` attribute. We set up roles and permissions, applied them declaratively on a controller, created complete Blade views with `@can` directives, and wrote 15 Pest tests to verify the access matrix.

Here are the key takeaways:

- **Spatie's middleware aliases work directly in `#[Middleware]` attributes.** Once you register `role`, `permission`, and `role_or_permission` as aliases in `bootstrap/app.php`, you can use them as `#[Middleware('role:admin')]` on any controller class or method.
- **Class-level attributes apply to all methods.** Putting `#[Middleware('auth')]` and `#[Middleware('permission:view articles')]` on the class means every method requires authentication and the `view articles` permission.
- **Method-level attributes add additional checks.** `#[Middleware('permission:delete articles')]` on `destroy()` is an additional requirement on top of the class-level middleware. The user must pass all checks.
- **Use `@can` in Blade to hide UI elements.** The middleware provides the real security (403 on direct access). The `@can` directives provide a better user experience by hiding buttons the user cannot use.
- **Always reset the permission cache in tests.** Call `forgetCachedPermissions()` in `beforeEach()` to prevent stale permission data from leaking between tests.
- **Both approaches are valid.** If your team prefers the `HasMiddleware` interface or constructor-based middleware, those still work in Laravel 13. Attributes are an alternative, not a requirement.