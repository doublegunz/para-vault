---
title: "Implementing the Repository Pattern Without Over-Engineering in Laravel"
slug: "implementing-the-repository-pattern-without-over-engineering-in-laravel"
category: "Laravel"
date: "2026-05-02"
status: "published"
---

If you have ever opened a controller in a growing Laravel project and found Eloquent queries scattered across its methods, you already know the problem. The logic that retrieves published posts, filters drafts, or loads related authors ends up duplicated across controllers, jobs, and Livewire components. The obvious fix seems to be the Repository Pattern: create a dedicated class, move all the queries there, and inject it where needed. So you do exactly that, and then you end up with a class that is barely more than a thin wrapper around Eloquent, with methods like `find($id)` that just call `Post::find($id)`. You have added a whole new layer to your codebase without solving the original problem.

This is the most common way the Repository Pattern gets implemented in Laravel, and it is also the reason so many developers either abandon it entirely or get lost in a forest of interfaces, service providers, and abstract base classes that serve no real purpose. The pattern itself is not the problem. The implementation is.

In this tutorial, you will learn how to implement the Repository Pattern correctly: building repositories that express the actual data-access needs of your feature, adding an interface to create a proper contract, and writing tests that verify the behavior you care about.

## Overview {#overview}

This tutorial builds a working post-management feature from scratch, using the Repository Pattern as the primary architectural tool for organizing data access. The angle here is practical; you will see the wrong approach first, understand exactly why it fails, and then build the correct version step by step.

Before diving into code, it helps to have a mental model of the layers involved. A correct repository implementation introduces a clear separation between three responsibilities:

```
┌─────────────────────────────────────────────────┐
│  Controller                                     │
│  "What does the user want?"                     │
│  Knows nothing about SQL, Eloquent, or queries  │
└────────────────────┬────────────────────────────┘
                     │ type-hints PostRepositoryInterface
                     ▼
┌─────────────────────────────────────────────────┐
│  Repository (the boundary)                      │
│  "What data does the application need?"         │
│  Owns all query logic; expresses domain intent  │
└────────────────────┬────────────────────────────┘
                     │ uses Eloquent internally
                     ▼
┌─────────────────────────────────────────────────┐
│  Eloquent / Database                            │
│  "How is the data stored and retrieved?"        │
│  An implementation detail the controller        │
│  should never need to know about               │
└─────────────────────────────────────────────────┘
```

The controller is not allowed to know about Eloquent. The database is not allowed to know about business rules. The repository is the boundary that keeps these two concerns from bleeding into each other. This separation is the entire value of the pattern.

### What You'll Build

- A `Post` model with published and draft states, tied to a `User` author.
- A `PostRepository` class with feature-oriented methods: `getPublished()`, `getDrafts()`, `getByUser()`, `findWithAuthor()`, `publish()`, and `storeDraft()`.
- A `PostRepositoryInterface` contract bound in the service container, so the controller depends on an abstraction rather than a concrete class.
- A `PostController` and a Blade view that displays published posts.
- Seven Pest tests that verify the repository's behavior against a real SQLite database.

### What You'll Learn

- Why the "Eloquent wrapper" approach adds indirection without adding value.
- How to design repository methods that are meaningful and specific to a feature.
- How to create an interface, bind it in `AppServiceProvider`, and inject it via the service container.
- How to test a repository class directly using Pest and `RefreshDatabase`.
- When a repository genuinely improves a codebase and when it is unnecessary overhead.

### What You'll Need

- PHP 8.3 or higher.
- Laravel 13.
- Composer installed globally.
- Basic familiarity with Eloquent models, migrations, and controllers.
- Pest (setup is included in Step 1).

## Step 1: Set Up the Project {#step-1-set-up-the-project}

If you already have a fresh Laravel 13 project ready, skip straight to the migration. Otherwise, create the project and install Pest in one sequence:

```bash
laravel new repo-demo --no-interaction --database=sqlite --pest --no-boost
cd repo-demo
```

Confirm the expectation API prompt with yes. The `phpunit.xml` in Laravel 13 already has the SQLite in-memory database uncommented, so tests will run against an in-memory database with no extra configuration needed.

Create the `Post` model together with its migration and factory:

```bash
php artisan make:model Post -mf
```

Open `database/migrations/xxxx_xx_xx_create_posts_table.php` and define the columns:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            // Each post belongs to a user; deleting a user removes their posts too
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('body');
            // null means the post is a draft; a past timestamp means it is published
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};
```

Open `app/Models/Post.php`. In Laravel 13, use the `#[Fillable]` PHP attribute instead of `protected $fillable`, and define the relationship to the author:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['title', 'body', 'published_at', 'user_id'])]
class Post extends Model
{
    use HasFactory;

    // The relationship is named "author" rather than "user" to be expressive
    // about the role this user plays in the context of a post
    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    protected function casts(): array
    {
        return [
            'published_at' => 'datetime',
        ];
    }
}
```

Open `database/factories/PostFactory.php` and add a `published()` state for use in tests:

```php
<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class PostFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id'      => User::factory(),
            'title'        => $this->faker->sentence(),
            'body'         => $this->faker->paragraphs(3, true),
            // Factories create drafts by default; use published() to override
            'published_at' => null,
        ];
    }

    // Calling ->published() on the factory produces a post with a past timestamp
    public function published(): static
    {
        return $this->state(fn (array $attributes) => [
            'published_at' => now()->subDays(rand(1, 30)),
        ]);
    }
}
```

Run the migration:

```bash
php artisan migrate
```

The `posts` table is now ready. Move on to Step 2.

## Step 2: See the Wrong Way First {#step-2-wrong-way}

Before writing the correct implementation, it is worth looking carefully at the pattern that appears in most tutorials and Stack Overflow answers. Understanding why this approach fails makes the correct version far more intuitive.

The class below is real, copyable PHP. It has no syntax errors. It would technically work in a Laravel project. Read through it and ask yourself: what does this class actually do that Eloquent does not already do on its own?

> **Do not add this file to your project.** This is a demonstration of the anti-pattern you want to avoid. You will build the correct version starting in Step 3.

```php
<?php

// ❌ ANTI-PATTERN: The "Eloquent Wrapper" repository.
// This approach adds an extra class without adding any abstraction.

namespace App\Repositories;

use App\Models\Post;
use Illuminate\Database\Eloquent\Collection;

class PostRepository
{
    // Just calls Post::find(). Your controller could do this directly.
    public function find(int $id): ?Post
    {
        return Post::find($id);
    }

    // Just calls Post::all(). There is no added value here.
    public function all(): Collection
    {
        return Post::all();
    }

    // Just calls Post::create(). The controller already knew how to do this.
    public function create(array $data): Post
    {
        return Post::create($data);
    }

    // A wrapper around update() with one extra line.
    public function update(int $id, array $data): Post
    {
        $post = Post::findOrFail($id);
        $post->update($data);

        return $post;
    }

    // Just destroys a record. No domain logic, no context, no intent.
    public function delete(int $id): bool
    {
        return (bool) Post::destroy($id);
    }
}
```

Every method here is a one-to-one translation of an Eloquent operation with a new name layered on top. If you inject this into a controller, the controller now depends on an extra class, but that class has provided zero new abstraction. Calling `$this->postRepository->create($data)` is identical in behavior to calling `Post::create($data)` directly.

Worse, when you add an interface to this pattern (as most tutorials recommend), you end up forcing every data-access operation in your application through five generic verbs: find, all, create, update, delete. When a controller calls `$this->postRepository->update($id, ['published_at' => now()])`, the reader has to mentally decode what that `update` call means in the context of the feature. The repository should be the place where that context lives, not the place where it gets erased.

The repository's job is not to wrap Eloquent. Its job is to give the application a clear, named way to express what data it needs.

Before building the correct version, there are two more anti-patterns worth naming, because they appear almost as frequently and cause similar problems in different ways.

**The God Repository.** Some teams take a step further and create a single, shared repository for multiple models, or even for the entire application. This looks like `AppRepository` or `DataRepository` with methods like `getAllPosts()`, `getAllUsers()`, `getSettings()`, all in one class. The god repository violates the Single Responsibility Principle and grows without bound. Every new feature adds more methods to the same class, turning it into a dumping ground for queries. There is no organizing principle, and the class becomes harder to navigate with every sprint.

> **Do not add this file to your project.** This is a second demonstration of the anti-pattern.

```php
<?php

// ❌ ANTI-PATTERN: The "God Repository".
// One class trying to own all data access for all models.

namespace App\Repositories;

use App\Models\Post;
use App\Models\User;

class AppRepository
{
    // Posts
    public function getAllPosts() { return Post::all(); }
    public function findPost(int $id) { return Post::find($id); }

    // Users
    public function getAllUsers() { return User::all(); }
    public function findUser(int $id) { return User::find($id); }

    // As the app grows, this class grows forever.
    // It becomes impossible to reason about at a glance.
}
```

**The Generic BaseRepository.** The other common pattern is an abstract `BaseRepository` class that provides `find()`, `all()`, `create()`, `update()`, and `delete()`, which all concrete repositories inherit. The appeal is obvious: write the CRUD logic once, reuse it everywhere. The problem is that it forces every repository into the same shape. When `PostRepository` needs `getPublished()` and `UserRepository` needs `getActiveSubscribers()`, those custom methods sit awkwardly alongside the five inherited generic ones. The base class also makes it tempting to call `$postRepository->all()` from a controller instead of defining a named, meaningful method, which is exactly the behavior the pattern is supposed to prevent.

```php
<?php

// ❌ ANTI-PATTERN: The "Generic BaseRepository".
// Inheriting generic CRUD from a base class discourages named, meaningful methods.

namespace App\Repositories;

use Illuminate\Database\Eloquent\Model;

abstract class BaseRepository
{
    public function __construct(protected Model $model) {}

    // These five methods are available to every repository that extends this class,
    // which makes it very tempting to use them directly from controllers.
    // That temptation is exactly the problem: all domain meaning gets lost.
    public function all()              { return $this->model->all(); }
    public function find(int $id)      { return $this->model->find($id); }
    public function create(array $data){ return $this->model->create($data); }
    public function update(int $id, array $data)
    {
        $record = $this->model->findOrFail($id);
        $record->update($data);
        return $record;
    }
    public function delete(int $id)    { return $this->model->destroy($id); }
}

// PostRepository now "has" all five generic methods for free,
// but "for free" here means: at the cost of domain expressiveness.
class PostRepository extends BaseRepository
{
    public function __construct(Post $model)
    {
        parent::__construct($model);
    }

    // The feature-specific method sits awkwardly alongside five generic ones.
    // Nothing prevents a controller from calling $this->postRepository->all()
    // instead of $this->postRepository->getPublished().
    public function getPublished() { /* ... */ }
}
```

All three anti-patterns share the same root cause: they define repositories in terms of database operations rather than in terms of what the application actually needs to express. Keep this in mind as you build the correct version.

## Step 3: Create the Feature-Oriented Repository {#step-3-feature-oriented-repository}

Now build the real repository. Start by creating the directory structure:

```bash
mkdir -p app/Repositories/Contracts
```

Create the file `app/Repositories/PostRepository.php`:

```php
<?php

namespace App\Repositories;

use App\Models\Post;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class PostRepository
{
    public function __construct(
        // Injecting the model makes the dependency explicit and allows
        // the service container to manage instantiation
        private readonly Post $model
    ) {}

    /**
     * Get paginated published posts, sorted by most recent publication date.
     *
     * "Published" means: has a published_at timestamp that is not in the future.
     * Future-dated posts are excluded deliberately, to support scheduled publishing.
     */
    public function getPublished(int $perPage = 15): LengthAwarePaginator
    {
        return $this->model
            ->whereNotNull('published_at')
            ->where('published_at', '<=', now())
            ->with('author')          // Eager-load to prevent N+1 queries in the view
            ->latest('published_at')
            ->paginate($perPage);
    }

    /**
     * Get all drafts (posts that have no published_at value).
     *
     * Sorted by creation date so the most recently created drafts appear first.
     */
    public function getDrafts(int $perPage = 15): LengthAwarePaginator
    {
        return $this->model
            ->whereNull('published_at')
            ->with('author')
            ->latest()
            ->paginate($perPage);
    }

    /**
     * Get all posts belonging to a specific user, regardless of publish status.
     *
     * Useful for "My Posts" views or admin dashboards where you need
     * to see both published and draft posts for a single author.
     */
    public function getByUser(User $user, int $perPage = 10): LengthAwarePaginator
    {
        return $this->model
            ->where('user_id', $user->id)
            ->latest()
            ->paginate($perPage);
    }

    /**
     * Retrieve a single post and load its author relationship in the same query.
     *
     * Throws ModelNotFoundException if the post does not exist, which Laravel
     * automatically converts to a 404 response in controllers.
     */
    public function findWithAuthor(int $id): Post
    {
        return $this->model
            ->with('author')
            ->findOrFail($id);
    }

    /**
     * Publish a post by recording the current time as its publication timestamp.
     *
     * Returns the refreshed model so the caller always gets up-to-date attributes,
     * including the newly set published_at value.
     */
    public function publish(Post $post): Post
    {
        $post->update(['published_at' => now()]);

        // fresh() re-fetches the record from the database to reflect
        // any changes made by database triggers or other processes
        return $post->fresh();
    }

    /**
     * Save a new post as a draft.
     *
     * The published_at override ensures that even if the caller accidentally
     * passes a timestamp in $data, this method always stores a draft.
     * The intent is enforced at the repository level, not at the call site.
     */
    public function storeDraft(array $data): Post
    {
        return $this->model->create(
            array_merge($data, ['published_at' => null])
        );
    }
}
```

Notice what is different compared to the anti-pattern. Every method has a name that describes a business concept rather than a database operation. The controller will never need to know that "get published posts" requires checking `published_at` against `now()`, or that "store as draft" means forcing `published_at` to null. Those details belong here, in the repository, and nowhere else. This is the abstraction the pattern is supposed to provide.

## Step 4: Add an Interface and Bind It {#step-4-add-interface}

A repository without an interface already cleans up your code significantly. But the interface is what elevates the repository from a "query helper class" to a genuine architectural boundary.

Here is the core idea. An interface separates *what the application needs* from *how that need is fulfilled*. When `PostController` type-hints `PostRepositoryInterface`, it is declaring a dependency on a contract, not on Eloquent, not on MySQL, and not on any specific query strategy. The controller is operating in the domain layer: it knows about `Post` objects and business concepts like "published" or "draft". The `PostRepository` is operating in the persistence layer: it knows how to talk to the database and translate those business concepts into SQL. The interface is the line between them.

This boundary has two concrete consequences beyond the conceptual. First, the service container can resolve the correct implementation automatically based on the type hint, meaning you can swap implementations (for example, a version with Redis caching) without touching a single controller. Second, in tests you can replace the real repository with a mock by rebinding the interface, which lets you test controller logic fast and without hitting the database at all.

Create the interface at `app/Repositories/Contracts/PostRepositoryInterface.php`:

```php
<?php

namespace App\Repositories\Contracts;

use App\Models\Post;
use App\Models\User;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface PostRepositoryInterface
{
    // Each signature here is a promise: any class implementing this interface
    // must provide exactly these methods with exactly these type signatures.
    // This contract is what the controller and tests will depend on.

    public function getPublished(int $perPage = 15): LengthAwarePaginator;

    public function getDrafts(int $perPage = 15): LengthAwarePaginator;

    public function getByUser(User $user, int $perPage = 10): LengthAwarePaginator;

    public function findWithAuthor(int $id): Post;

    public function publish(Post $post): Post;

    public function storeDraft(array $data): Post;
}
```

Now update `PostRepository` to declare that it fulfills this contract. Open `app/Repositories/PostRepository.php` and modify the namespace imports and class declaration:

```php
<?php

namespace App\Repositories;

use App\Models\Post;
use App\Models\User;
use App\Repositories\Contracts\PostRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

// Declaring the interface here tells PHP to enforce the contract at compile time.
// If you add a method to the interface and forget to add it here, PHP throws a fatal error.
class PostRepository implements PostRepositoryInterface
{
    // The rest of the class body is unchanged from Step 3.
    // Only the class declaration line and imports change here.

    public function __construct(
        private readonly Post $model
    ) {}

    public function getPublished(int $perPage = 15): LengthAwarePaginator
    {
        return $this->model
            ->whereNotNull('published_at')
            ->where('published_at', '<=', now())
            ->with('author')
            ->latest('published_at')
            ->paginate($perPage);
    }

    public function getDrafts(int $perPage = 15): LengthAwarePaginator
    {
        return $this->model
            ->whereNull('published_at')
            ->with('author')
            ->latest()
            ->paginate($perPage);
    }

    public function getByUser(User $user, int $perPage = 10): LengthAwarePaginator
    {
        return $this->model
            ->where('user_id', $user->id)
            ->latest()
            ->paginate($perPage);
    }

    public function findWithAuthor(int $id): Post
    {
        return $this->model
            ->with('author')
            ->findOrFail($id);
    }

    public function publish(Post $post): Post
    {
        $post->update(['published_at' => now()]);

        return $post->fresh();
    }

    public function storeDraft(array $data): Post
    {
        return $this->model->create(
            array_merge($data, ['published_at' => null])
        );
    }
}
```

Open `app/Providers/AppServiceProvider.php` and register the binding in the `register()` method. This tells Laravel's service container which concrete class to instantiate whenever any class asks for `PostRepositoryInterface`:

```php
<?php

namespace App\Providers;

use App\Repositories\Contracts\PostRepositoryInterface;
use App\Repositories\PostRepository;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Binding the interface to the concrete implementation.
        // To swap implementations later (e.g., a cached version), you only
        // change this one line. No controller or test needs to be updated.
        $this->app->bind(PostRepositoryInterface::class, PostRepository::class);
    }

    public function boot(): void
    {
        //
    }
}
```

With this binding in place, any controller or class that type-hints `PostRepositoryInterface` will automatically receive a `PostRepository` instance. You never call `new PostRepository()` anywhere in application code.

**Preview: swapping the implementation.** To make this concrete, consider what it looks like to add a caching layer later. You create a new class that implements the same interface, wraps the original repository, and adds caching around each method call. Then you change exactly one line in `AppServiceProvider`. The controller never changes, because it only knows about the interface, not the implementation behind it.

```php
<?php

// This is a preview of how the interface pays off as your app scales.
// A full walkthrough of caching repositories is covered in a separate tutorial.

namespace App\Repositories;

use App\Models\Post;
use App\Models\User;
use App\Repositories\Contracts\PostRepositoryInterface;
use Illuminate\Contracts\Cache\Repository as Cache;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class CachedPostRepository implements PostRepositoryInterface
{
    public function __construct(
        // The real repository does the actual database work
        private readonly PostRepository $inner,
        // The cache stores the result so the database is not hit every time
        private readonly Cache $cache,
    ) {}

    public function getPublished(int $perPage = 15): LengthAwarePaginator
    {
        // Cache the published list for 5 minutes; bypass the database on repeat requests
        return $this->cache->remember(
            key: "posts.published.page-{$perPage}",
            ttl: now()->addMinutes(5),
            callback: fn () => $this->inner->getPublished($perPage),
        );
    }

    // All other interface methods delegate to $this->inner as-is,
    // adding caching only where it provides measurable benefit.
    public function getDrafts(int $perPage = 15): LengthAwarePaginator
    {
        return $this->inner->getDrafts($perPage);
    }

    public function getByUser(User $user, int $perPage = 10): LengthAwarePaginator
    {
        return $this->inner->getByUser($user, $perPage);
    }

    public function findWithAuthor(int $id): Post
    {
        return $this->inner->findWithAuthor($id);
    }

    public function publish(Post $post): Post
    {
        return $this->inner->publish($post);
    }

    public function storeDraft(array $data): Post
    {
        return $this->inner->storeDraft($data);
    }
}
```

To activate the caching version, open `AppServiceProvider` and change the binding from `PostRepository::class` to `CachedPostRepository::class`. That single edit is the only change required across the entire application. The controller, the tests, and every other consumer keep working exactly as before.

## Step 5: Wire the Repository into the Controller {#step-5-wire-controller}

Create the controller:

```bash
php artisan make:controller PostController
```

Open `app/Http/Controllers/PostController.php` and implement the three actions:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use App\Repositories\Contracts\PostRepositoryInterface;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class PostController extends Controller
{
    public function __construct(
        // Type-hinting the interface, not the concrete class.
        // Laravel resolves the correct implementation from the service container
        // automatically based on the binding registered in AppServiceProvider.
        private readonly PostRepositoryInterface $posts
    ) {}

    // Display all published posts, paginated
    public function index(): View
    {
        $posts = $this->posts->getPublished();

        return view('posts.index', compact('posts'));
    }

    // Save a new post as a draft
    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'body'  => ['required', 'string'],
        ]);

        $this->posts->storeDraft(array_merge($validated, [
            'user_id' => $request->user()->id,
        ]));

        return redirect()->route('posts.index')->with('message', 'Draft saved.');
    }

    // Publish a specific post
    public function publish(Post $post): RedirectResponse
    {
        $this->posts->publish($post);

        return redirect()->route('posts.index')->with('message', 'Post published successfully.');
    }
}
```

Register the routes in `routes/web.php`:

```php
use App\Http\Controllers\PostController;

Route::get('/posts', [PostController::class, 'index'])->name('posts.index');
Route::post('/posts', [PostController::class, 'store'])->name('posts.store');
Route::patch('/posts/{post}/publish', [PostController::class, 'publish'])->name('posts.publish');
```

Create the views directory and the index view:

```bash
mkdir -p resources/views/posts
```

Create `resources/views/posts/index.blade.php` as a standalone Tailwind layout:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Published Posts</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-4xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">

        <h1 class="text-2xl font-bold text-gray-900 mb-6">Published Posts</h1>

        @if(session('message'))
            <div class="mb-4 p-3 bg-green-50 border border-green-200 text-green-700 rounded">
                {{ session('message') }}
            </div>
        @endif

        @forelse($posts as $post)
            <div class="border-b border-gray-200 py-5 last:border-0">
                <h2 class="text-lg font-semibold text-gray-900">{{ $post->title }}</h2>
                <p class="text-sm text-gray-400 mt-1">
                    By {{ $post->author->name }}
                    &middot;
                    {{ $post->published_at->diffForHumans() }}
                </p>
                <p class="text-gray-600 mt-2 leading-relaxed">
                    {{ Str::limit($post->body, 160) }}
                </p>
            </div>
        @empty
            <p class="text-gray-500 py-4">No published posts yet.</p>
        @endforelse

        <div class="mt-6">
            {{ $posts->links() }}
        </div>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com"
               class="text-blue-600 hover:text-blue-800 hover:underline transition"
               target="_blank">Tutorial Repository Pattern at qadrlabs.com</a>
        </div>

    </div>
</body>
</html>
```

## Step 6: Try It Out {#step-6-try-it-out}

Start the development server:

```bash
php artisan serve
```

The posts list will be empty because there is no data yet. Use Artisan Tinker in a second terminal to seed some posts and verify that the repository methods behave correctly before writing formal tests:

```bash
php artisan tinker
```

Run these commands inside Tinker in order:

```php
// Create a user to own the posts
$user = \App\Models\User::factory()->create(['name' => 'Alice', 'email' => 'alice@example.com']);

// Create three published posts for Alice
\App\Models\Post::factory(3)->published()->create(['user_id' => $user->id]);

// Create two draft posts for Alice
\App\Models\Post::factory(2)->create(['user_id' => $user->id]);

// Resolve the repository through the container to test the binding
$repo = app(\App\Repositories\Contracts\PostRepositoryInterface::class);

// Should return 3 (only the published posts)
$repo->getPublished()->total();

// Should return 2 (only the drafts)
$repo->getDrafts()->total();

// Should return 5 (all of Alice's posts, published and drafts combined)
$repo->getByUser($user)->total();

// Should return a Post instance with the author relationship loaded
$post = $repo->findWithAuthor(1);
$post->author->name;

// Publish one of the drafts and inspect the result
$draft = \App\Models\Post::whereNull('published_at')->first();
$published = $repo->publish($draft);
$published->published_at;
```

After running those commands, visit `http://localhost:8000/posts` in the browser. You should see Alice's three published posts rendered in the list, each showing the author name and relative publication time. The paginator appears at the bottom once the post count exceeds the default page size.

## Step 7: Write the Tests {#step-7-write-tests}

Testing the repository directly is the right call here. You want to verify the data-access behavior in isolation: that the query filters are correct, that relationships load, and that business rules like "storeDraft always creates a draft" are enforced. Create the test file:

```bash
php artisan make:test Repositories/PostRepositoryTest --pest
```

Open `tests/Feature/Repositories/PostRepositoryTest.php` and replace its contents with the following:

```php
<?php

use App\Models\Post;
use App\Models\User;
use App\Repositories\Contracts\PostRepositoryInterface;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

// Resolving through the interface also tests that the AppServiceProvider binding
// is registered correctly. If the binding is missing, every test below will fail.
function repo(): PostRepositoryInterface
{
    return app(PostRepositoryInterface::class);
}

it('returns only published posts', function () {
    // Create three published and two draft posts
    Post::factory(3)->published()->create();
    Post::factory(2)->create(); // drafts by default

    $results = repo()->getPublished();

    // Only the three published posts should appear in the results
    expect($results->total())->toBe(3);
});

it('does not return a future-scheduled post as published', function () {
    // A post with a future published_at should not be visible yet
    Post::factory()->create(['published_at' => now()->addDay()]);

    $results = repo()->getPublished();

    expect($results->total())->toBe(0);
});

it('returns only draft posts', function () {
    Post::factory(2)->published()->create();
    Post::factory(4)->create(); // four drafts

    $results = repo()->getDrafts();

    expect($results->total())->toBe(4);
});

it('returns only posts belonging to the specified user', function () {
    $alice = User::factory()->create();
    $bob   = User::factory()->create();

    Post::factory(3)->create(['user_id' => $alice->id]);
    Post::factory(2)->create(['user_id' => $bob->id]);

    $results = repo()->getByUser($alice);

    // Alice's three posts only; Bob's two should not be included
    expect($results->total())->toBe(3);
});

it('loads the author relationship when finding a post by id', function () {
    $user = User::factory()->create(['name' => 'Alice']);
    $post = Post::factory()->create(['user_id' => $user->id]);

    $result = repo()->findWithAuthor($post->id);

    expect($result->relationLoaded('author'))->toBeTrue()
        ->and($result->author->name)->toBe('Alice');
});

it('sets published_at when publishing a draft post', function () {
    $post = Post::factory()->create(['published_at' => null]);

    expect($post->published_at)->toBeNull();

    $published = repo()->publish($post);

    expect($published->published_at)->not->toBeNull()
        ->and($published->published_at->isPast())->toBeTrue();
});

it('stores a new post as a draft regardless of what is passed in the data array', function () {
    $user = User::factory()->create();

    // Even if the caller passes a published_at value, storeDraft() must ignore it
    $post = repo()->storeDraft([
        'title'        => 'A new draft',
        'body'         => 'Some body content.',
        'user_id'      => $user->id,
        'published_at' => now(), // this should be overridden to null
    ]);

    expect($post->published_at)->toBeNull();
});
```

Save the file, then run the test suite:

```bash
php artisan test
```

You should see this output:

```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.09s  

   PASS  Tests\Feature\Repositories\PostRepositoryTest
  ✓ it returns only published posts                                      0.06s  
  ✓ it does not return a future-scheduled post as published              0.01s  
  ✓ it returns only draft posts                                          0.01s  
  ✓ it returns only posts belonging to the specified user                0.01s  
  ✓ it loads the author relationship when finding a post by id           0.01s  
  ✓ it sets published_at when publishing a draft post                    0.01s  
  ✓ it stores a new post as a draft regardless of what is passed in the… 0.01s  

  Tests:    9 passed (12 assertions)
  Duration: 0.25s
```

All seven tests pass. The last test is particularly worth noting: it verifies that the business rule "a draft is always a draft until explicitly published" is enforced inside the repository itself, not in any specific controller. Any future call site that uses `storeDraft()` gets this protection automatically, without needing to remember to pass `published_at: null` at the call site.

## Repository vs. Laravel-Native Alternatives {#repository-vs-alternatives}

Now that the implementation is complete, it is worth being direct about something the tutorial has implicitly touched on: a repository is not the only way to organize data access in Laravel, and it is not always the right tool. The framework gives you several lighter-weight options, each with their own trade-offs.

| Approach                            | Best for                                                        | Trade-off                                                |
| ----------------------------------- | --------------------------------------------------------------- | -------------------------------------------------------- |
| **Eloquent directly in controller** | Small apps, simple CRUD, rapid prototyping                      | Query logic scatters quickly as features grow            |
| **Local scopes on the model**       | Reusable filter conditions on a single model                    | Cannot encapsulate multi-model queries or business rules |
| **Service class**                   | Business logic that crosses multiple models                     | Does not specifically address data-access organization   |
| **Repository (this tutorial)**      | Complex queries, reused across call sites, testable controllers | Extra file, interface, and service provider binding      |

**Eloquent directly in a controller** is completely reasonable for small or early-stage applications. If each controller action maps to one or two straightforward Eloquent calls, there is no problem worth solving. Adding a repository layer to a simple CRUD application is exactly the kind of over-engineering this tutorial warns against.

**Local scopes** are one of Eloquent's most underused features for this kind of problem. A scope on the `Post` model like `scopePublished()` lets you write `Post::published()->with('author')->paginate()` anywhere in the codebase. This is clean, readable, and requires zero extra infrastructure. The limitation is that scopes live on the model, so they only address filtering conditions for that model. They cannot encapsulate business rules (like "storeDraft must force published_at to null"), they cannot eager-load relationships in a centralized, tested way, and they cannot be mocked in controller tests. If your data-access complexity is mostly about filtering, scopes are the better choice.

**Service classes** are often recommended as the layer between the controller and Eloquent. A service class handles business logic: sending emails, coordinating multiple models, dispatching events. The distinction worth preserving is that a service class answers "what should happen" while a repository answers "how do I get or store this data." Mixing the two leads to services that are doing too much. In applications that use both patterns, services call repositories rather than calling Eloquent directly.

A practical rule for choosing: start with Eloquent directly in your controllers. When the same query logic appears in more than one place, extract it into a local scope. When a scope cannot capture the full intent of the operation, or when the logic involves business rules rather than just filters, introduce a repository.

## When Does a Repository Actually Add Value? {#when-repository-adds-value}

Now that you have a working implementation, it is worth being direct about the trade-offs. A repository is not free. It adds a file, a class, a constructor injection, and (with an interface) a service provider binding. For a small application with simple CRUD, that cost is rarely justified.

The pattern genuinely earns its place when one or more of the following conditions is true. The first is when the same data-access logic needs to run from multiple places, for example a console command, a controller, and a queued job all needing the same "get published posts" behavior. Without a repository, you either copy-paste the Eloquent query (violating DRY) or scatter the filtering logic across multiple classes. The second is when a query is complex enough that its intent is not obvious from reading the raw Eloquent chain. A method named `getEligibleForPromotion()` communicates something that `->where('score', '>=', 80)->whereNull('promoted_at')->with('tier')->get()` does not. The third is when you want controller tests to be fast and free of database operations: binding a mock to `PostRepositoryInterface` in a test makes it trivial to test controller logic without touching the database at all.

Where the pattern does not pay off is in simple applications where each controller action maps to one straightforward Eloquent call, or in small teams where coupling the controller to the model directly is a conscious and acceptable trade-off. Eloquent is expressive by design. Using `Post::published()->with('author')->paginate()` alongside a well-named local scope on the model is a perfectly respectable architecture for many projects.

A useful rule of thumb: if a repository method would just be a renamed version of an Eloquent method, skip the repository for that case. If the repository method captures a named concept from your domain, add it.

## Conclusion {#conclusion}

The Repository Pattern is one of the most commonly misimplemented patterns in Laravel, largely because most examples teach it as a generic CRUD wrapper rather than a domain-specific abstraction. Here is what this tutorial covered:

- **The repository as an architectural boundary.** A repository is not a query helper. It is the line between the domain layer (what the application needs) and the persistence layer (how that data is stored). Controllers operate above this boundary; Eloquent and SQL operate below it. The interface is what makes the line explicit.
- **Three anti-patterns to avoid.** The Eloquent wrapper (methods that rename Eloquent calls), the God Repository (one class owning all models), and the Generic BaseRepository (inherited CRUD methods that discourage meaningful naming) all share the same failure: they define repositories in terms of database operations rather than domain intent.
- **Feature-oriented method design.** Methods like `getPublished()`, `getDrafts()`, and `publish()` express business concepts. They own the query details internally, keeping controllers free of "how" and focused on "what."
- **Interfaces and service container binding.** Binding `PostRepositoryInterface` to `PostRepository` in `AppServiceProvider` means controllers depend on a contract. Swapping the concrete implementation later (for example, to `CachedPostRepository`) requires changing only that one binding, with no changes to any consumer.
- **Business rules enforced at the repository level.** The `storeDraft()` method forces `published_at` to null regardless of what the caller passes. That rule lives in the repository and applies everywhere the method is called, automatically.
- **Direct repository testing with Pest.** Testing the repository against a real SQLite database verifies its query behavior in isolation. Resolving through the interface in tests also confirms that the service container binding is registered correctly.
- **Repositories vs. local scopes and service classes.** Local scopes handle reusable filter conditions and are often enough for simple applications. Service classes handle business logic that spans multiple models. Repositories address data-access organization when queries are complex, reused across call sites, or when mockable controllers matter. Start with Eloquent directly, reach for scopes when duplication appears, and introduce repositories when scopes are no longer enough.