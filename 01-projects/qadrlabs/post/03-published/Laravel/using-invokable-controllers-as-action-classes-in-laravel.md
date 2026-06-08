---
title: "Using Invokable Controllers as Action Classes in Laravel"
slug: "using-invokable-controllers-as-action-classes-in-laravel"
category: "Laravel"
date: "2026-04-19"
status: "published"
---

Picture an `ArticleController` that started life as a clean resource controller: `index`, `create`, `store`, `show`, `edit`, `update`, and `destroy`. Seven methods, all of them standard CRUD operations, all of them belonging together in one class. That is the resource controller pattern working exactly as intended.

Then the feature requests arrive. The team needs a way to publish an article, so a `publish()` method is added to `ArticleController` because that is where articles live. Then a `feature()` method to mark an article as featured. Then an `archive()` method. None of these three are CRUD operations: each carries its own business logic, its own set of dependencies, and a responsibility that is conceptually separate from simply reading or writing a record. But without a clearly designated home for them, the path of least resistance is to keep adding methods to the class that already exists. The resource controller quietly grows into something it was never meant to be, and `ArticleController` ends up with ten methods that span two very different concerns.

The right fix is not to abandon the resource controller. The seven CRUD methods still belong together and should stay exactly where they are. The fix is to give `publish()`, `feature()`, and `archive()` their own dedicated home: one invokable controller class per action. `ArticleController` goes back to its seven clean methods; `PublishArticleController`, `FeatureArticleController`, and `ArchiveArticleController` each handle one specific operation with their own route, their own dependencies, and their own test file. This tutorial walks you through that refactoring so you can see firsthand how it keeps both your resource controllers and your non-CRUD actions clean and easy to maintain.

## Overview {#overview}

Before writing any code, here is a clear picture of what this tutorial covers. All examples were written and tested against Laravel 13.

### What You'll Build

You will start with a realistic `ArticleController` that has grown beyond its original scope, carrying ten methods across two different concerns. Step by step, you will extract the three non-CRUD operations (`publish`, `feature`, `archive`) into their own dedicated invokable controller classes inside an `Articles` subdirectory, leaving the resource controller with exactly the seven CRUD methods it was designed to hold.

### What You'll Learn

- How to identify which methods in a resource controller do not belong there
- How to generate an invokable controller with the `--invokable` Artisan flag and what the generated file contains
- How to register a single-action controller route without specifying a method name
- How to inject dependencies and use implicit route model binding in `__invoke()`
- How to organize invokable controllers into subdirectories with a consistent naming convention
- How to write focused, single-responsibility feature tests for each extracted action

### What You'll Need

- Laravel 13 or later
- PHP 8.3 or later
- A running local development environment (Laravel Herd, Sail, or Valet all work)
- Basic familiarity with Laravel resource controllers and Eloquent models

## Step 1: The Starting Point, a Bloated Resource Controller {#step-1}

Every refactoring starts with understanding the current state. Before extracting anything, you need to see the problem clearly: what does the controller look like now, and why does it need to change?

### Set Up the Article Model

Generate the `Article` model alongside its migration and factory:

```bash
php artisan make:model Article -mf
```

Open the migration file inside `database/migrations` and define the table columns. The three new columns, `published_at`, `featured`, and `archived_at`, represent the state that the three non-CRUD actions will manage:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('articles', function (Blueprint $table) {
            $table->id();
            // Each article belongs to the user who created it.
            // cascadeOnDelete ensures articles are removed when their owner is deleted.
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('body');
            // Nullable timestamps let us represent unpublished/unarchived state as null.
            // A non-null value means the action has been taken; null means it has not.
            $table->timestamp('published_at')->nullable();
            $table->boolean('featured')->default(false);
            $table->timestamp('archived_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('articles');
    }
};
```

Open `app/Models/Article.php` and declare the fillable fields along with the casts and the relationship back to `User`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Article extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'title', 'body', 'published_at', 'featured', 'archived_at'];

    // Casting published_at and archived_at to datetime ensures they come back
    // as Carbon instances rather than raw strings, which makes comparisons easier.
    protected $casts = [
        'published_at' => 'datetime',
        'featured'     => 'boolean',
        'archived_at'  => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

Run the migration to create the table:

```bash
php artisan migrate
```

### Generate the Bloated ArticleController

Generate the resource controller:

```bash
php artisan make:controller ArticleController --resource
```

Open `app/Http/Controllers/ArticleController.php` and fill in all ten methods. The seven CRUD methods are kept brief to stay focused on the structure; the three non-CRUD methods show the kind of logic that has accumulated over time:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Article;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Symfony\Component\HttpFoundation\Response as HttpResponse;

class ArticleController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(Article::latest()->get());
    }

    public function create(): JsonResponse
    {
        // Returns metadata needed to render a creation form.
        return response()->json(['message' => 'Return form data here.']);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'body'  => ['required', 'string'],
        ]);

        $article = Article::create([...$validated, 'user_id' => $request->user()->id]);

        return response()->json($article, HttpResponse::HTTP_CREATED);
    }

    public function show(Article $article): JsonResponse
    {
        return response()->json($article);
    }

    public function edit(Article $article): JsonResponse
    {
        return response()->json($article);
    }

    public function update(Request $request, Article $article): JsonResponse
    {
        abort_unless($request->user()->id === $article->user_id, 403);

        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'body'  => ['sometimes', 'string'],
        ]);

        $article->update($validated);

        return response()->json($article);
    }

    public function destroy(Request $request, Article $article): Response
    {
        abort_unless($request->user()->id === $article->user_id, 403);
        $article->delete();

        return response()->noContent();
    }

    // Everything below this line does not belong in a resource controller.
    // These three methods carry their own logic, their own dependencies,
    // and a concern that is entirely separate from CRUD. They accumulated
    // here because there was no clearly designated alternative home.

    public function publish(Request $request, Article $article): JsonResponse
    {
        abort_unless($request->user()->id === $article->user_id, 403);

        if ($article->published_at !== null) {
            return response()->json(['message' => 'Article is already published.'], 422);
        }

        $article->update(['published_at' => now()]);

        return response()->json($article);
    }

    public function feature(Request $request, Article $article): JsonResponse
    {
        abort_unless($request->user()->id === $article->user_id, 403);

        // Toggle: if featured is true, set it to false, and vice versa.
        $article->update(['featured' => ! $article->featured]);

        return response()->json($article);
    }

    public function archive(Request $request, Article $article): JsonResponse
    {
        abort_unless($request->user()->id === $article->user_id, 403);

        if ($article->archived_at !== null) {
            return response()->json(['message' => 'Article is already archived.'], 422);
        }

        $article->update(['archived_at' => now()]);

        return response()->json($article);
    }
}
```

### Register the Routes

Open `routes/web.php` and register the resource routes alongside the three additional routes. The non-CRUD routes currently use the array syntax because `ArticleController` has named methods for them:

```php
use App\Http\Controllers\ArticleController;

Route::middleware('auth')->group(function () {
    // The resource macro registers all seven standard CRUD routes at once.
    Route::resource('articles', ArticleController::class);

    // These three are registered separately because Route::resource()
    // does not know about non-standard actions like publish, feature, or archive.
    Route::patch('/articles/{article}/publish', [ArticleController::class, 'publish'])
        ->name('articles.publish');

    Route::patch('/articles/{article}/feature', [ArticleController::class, 'feature'])
        ->name('articles.feature');

    Route::patch('/articles/{article}/archive', [ArticleController::class, 'archive'])
        ->name('articles.archive');
});
```

### Verify the Baseline

Run `php artisan route:list --name=articles` to confirm all ten routes are registered before touching anything:

```bash
php artisan route:list --name=articles
```

```
  GET|HEAD   articles                       articles.index    App\Http\Controllers\ArticleController@index    web, auth
  POST       articles                       articles.store    App\Http\Controllers\ArticleController@store    web, auth
  GET|HEAD   articles/create                articles.create   App\Http\Controllers\ArticleController@create   web, auth
  GET|HEAD   articles/{article}             articles.show     App\Http\Controllers\ArticleController@show     web, auth
  PUT|PATCH  articles/{article}             articles.update   App\Http\Controllers\ArticleController@update   web, auth
  DELETE     articles/{article}             articles.destroy  App\Http\Controllers\ArticleController@destroy  web, auth
  GET|HEAD   articles/{article}/edit        articles.edit     App\Http\Controllers\ArticleController@edit     web, auth
  PATCH      articles/{article}/publish     articles.publish  App\Http\Controllers\ArticleController@publish  web, auth
  PATCH      articles/{article}/feature     articles.feature  App\Http\Controllers\ArticleController@feature  web, auth
  PATCH      articles/{article}/archive     articles.archive  App\Http\Controllers\ArticleController@archive  web, auth
```

Ten routes, all pointing to the same controller. The baseline is confirmed and the refactoring can begin.

## Step 2: Extract PublishArticleController {#step-2}

The `publish` operation is a one-way state change: it sets `published_at` to the current timestamp, checks that the article has not already been published, and verifies ownership. This is a complete, self-contained responsibility. It does not share logic with `index`, `store`, or any other CRUD method; it simply does not belong in `ArticleController`.

### Generate the Controller

The `make:controller` command accepts a path prefix. Passing `Articles/PublishArticleController` tells Artisan to create the file inside an `Articles` subdirectory and set the namespace accordingly. The `--invokable` flag scaffolds the class with a single `__invoke()` method already in place:

```bash
php artisan make:controller Articles/PublishArticleController --invokable
```

Open the generated file at `app/Http/Controllers/Articles/PublishArticleController.php`. You will find a class with the correct namespace and an empty `__invoke()` stub. Move the logic from `ArticleController@publish` into it:

```php
<?php

namespace App\Http\Controllers\Articles;

use App\Http\Controllers\Controller;
use App\Models\Article;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PublishArticleController extends Controller
{
    public function __invoke(Request $request, Article $article): JsonResponse
    {
        // Laravel performs implicit model binding here just as it does in any
        // named controller method. The {article} segment in the route is matched
        // to the Article model's primary key, and the resolved instance is injected
        // directly. A 404 is returned automatically if no record is found.
        abort_unless($request->user()->id === $article->user_id, 403);

        if ($article->published_at !== null) {
            return response()->json(['message' => 'Article is already published.'], 422);
        }

        $article->update(['published_at' => now()]);

        return response()->json($article);
    }
}
```

### Remove the Method from ArticleController

Open `app/Http/Controllers/ArticleController.php` and delete the `publish()` method entirely. The class now has nine methods. Save the file.

### Update the Route

Open `routes/web.php`. Change the import and the `publish` route definition to point to the new controller. The array syntax `[ArticleController::class, 'publish']` is replaced by the class name alone, because there is now only one public method to call:

```php
use App\Http\Controllers\ArticleController;
use App\Http\Controllers\Articles\PublishArticleController;

Route::middleware('auth')->group(function () {
    Route::resource('articles', ArticleController::class);

    // Before: [ArticleController::class, 'publish']
    // After:  PublishArticleController::class
    // Passing the class name alone is unambiguous because __invoke() is the
    // only public method. Laravel resolves it automatically during dispatch.
    Route::patch('/articles/{article}/publish', PublishArticleController::class)
        ->name('articles.publish');

    Route::patch('/articles/{article}/feature', [ArticleController::class, 'feature'])
        ->name('articles.feature');

    Route::patch('/articles/{article}/archive', [ArticleController::class, 'archive'])
        ->name('articles.archive');
});
```

### Verify

```bash
php artisan route:list --name=articles.publish
```

```
  PATCH  articles/{article}/publish  articles.publish  App\Http\Controllers\Articles\PublishArticleController  web, auth
```

The action column now shows `PublishArticleController` without any method suffix. Internally, Laravel appends `@__invoke` during resolution, but you never have to write it yourself.

## Step 3: Extract FeatureArticleController {#step-3}

The `feature` operation is a toggle: it flips the `featured` boolean from its current value to the opposite. Unlike `publish`, there is no "already featured" guard because toggling is always a valid operation regardless of the current state. The logic is simple, but it is still a distinct responsibility that has no business sitting inside a CRUD controller.

### Generate the Controller

```bash
php artisan make:controller Articles/FeatureArticleController --invokable
```

Open `app/Http/Controllers/Articles/FeatureArticleController.php` and fill in the implementation:

```php
<?php

namespace App\Http\Controllers\Articles;

use App\Http\Controllers\Controller;
use App\Models\Article;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FeatureArticleController extends Controller
{
    public function __invoke(Request $request, Article $article): JsonResponse
    {
        abort_unless($request->user()->id === $article->user_id, 403);

        // The boolean cast on the model ensures that $article->featured is always
        // a true PHP bool, so the negation operator works reliably here.
        $article->update(['featured' => ! $article->featured]);

        return response()->json($article);
    }
}
```

### Remove the Method from ArticleController

Delete the `feature()` method from `app/Http/Controllers/ArticleController.php`. The class is now down to eight methods.

### Update the Route

```php
use App\Http\Controllers\ArticleController;
use App\Http\Controllers\Articles\FeatureArticleController;
use App\Http\Controllers\Articles\PublishArticleController;

Route::middleware('auth')->group(function () {
    Route::resource('articles', ArticleController::class);

    Route::patch('/articles/{article}/publish', PublishArticleController::class)
        ->name('articles.publish');

    Route::patch('/articles/{article}/feature', FeatureArticleController::class)
        ->name('articles.feature');

    Route::patch('/articles/{article}/archive', [ArticleController::class, 'archive'])
        ->name('articles.archive');
});
```

### Verify

```bash
php artisan route:list --name=articles.feature
```

```
  PATCH  articles/{article}/feature  articles.feature  App\Http\Controllers\Articles\FeatureArticleController  web, auth
```

## Step 4: Extract ArchiveArticleController {#step-4}

The `archive` operation is structurally similar to `publish`: it is a one-way state change that sets `archived_at` to the current timestamp and guards against repeat calls. The key semantic difference is intent. Publishing makes an article visible to readers; archiving removes it from active circulation without deleting it from the database. That distinction belongs in its own class, not as an afterthought at the bottom of a CRUD controller.

### Generate the Controller

```bash
php artisan make:controller Articles/ArchiveArticleController --invokable
```

Open `app/Http/Controllers/Articles/ArchiveArticleController.php` and add the implementation:

```php
<?php

namespace App\Http\Controllers\Articles;

use App\Http\Controllers\Controller;
use App\Models\Article;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ArchiveArticleController extends Controller
{
    public function __invoke(Request $request, Article $article): JsonResponse
    {
        abort_unless($request->user()->id === $article->user_id, 403);

        if ($article->archived_at !== null) {
            return response()->json(['message' => 'Article is already archived.'], 422);
        }

        $article->update(['archived_at' => now()]);

        return response()->json($article);
    }
}
```

### Remove the Method from ArticleController

Delete the `archive()` method from `app/Http/Controllers/ArticleController.php`. The resource controller is now back to its original seven methods, which is exactly where it should have stayed:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Article;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Symfony\Component\HttpFoundation\Response as HttpResponse;

class ArticleController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(Article::latest()->get());
    }

    public function create(): JsonResponse
    {
        return response()->json(['message' => 'Return form data here.']);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'body'  => ['required', 'string'],
        ]);

        $article = Article::create([...$validated, 'user_id' => $request->user()->id]);

        return response()->json($article, HttpResponse::HTTP_CREATED);
    }

    public function show(Article $article): JsonResponse
    {
        return response()->json($article);
    }

    public function edit(Article $article): JsonResponse
    {
        return response()->json($article);
    }

    public function update(Request $request, Article $article): JsonResponse
    {
        abort_unless($request->user()->id === $article->user_id, 403);

        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'body'  => ['sometimes', 'string'],
        ]);

        $article->update($validated);

        return response()->json($article);
    }

    public function destroy(Request $request, Article $article): Response
    {
        abort_unless($request->user()->id === $article->user_id, 403);
        $article->delete();

        return response()->noContent();
    }
}
```

### Update the Route File

Here is the final state of `routes/web.php`. The three non-CRUD routes now each point to their own dedicated invokable controller:

```php
use App\Http\Controllers\ArticleController;
use App\Http\Controllers\Articles\ArchiveArticleController;
use App\Http\Controllers\Articles\FeatureArticleController;
use App\Http\Controllers\Articles\PublishArticleController;

Route::middleware('auth')->group(function () {
    // The resource controller stays exactly as it was, handling only CRUD.
    Route::resource('articles', ArticleController::class);

    // Each of these three routes now maps to its own dedicated class.
    // Reading this file, you can see immediately what each route does
    // without opening a single controller.
    Route::patch('/articles/{article}/publish', PublishArticleController::class)
        ->name('articles.publish');

    Route::patch('/articles/{article}/feature', FeatureArticleController::class)
        ->name('articles.feature');

    Route::patch('/articles/{article}/archive', ArchiveArticleController::class)
        ->name('articles.archive');
});
```

The controller directory now looks like this:

```
app/
  Http/
    Controllers/
      Articles/
        ArchiveArticleController.php
        FeatureArticleController.php
        PublishArticleController.php
      ArticleController.php
```

### Verify the Final Route List

```bash
php artisan route:list --name=articles
```

```
  GET|HEAD   articles                       articles.index    App\Http\Controllers\ArticleController@index                    web, auth
  POST       articles                       articles.store    App\Http\Controllers\ArticleController@store                    web, auth
  GET|HEAD   articles/create                articles.create   App\Http\Controllers\ArticleController@create                   web, auth
  GET|HEAD   articles/{article}             articles.show     App\Http\Controllers\ArticleController@show                     web, auth
  PUT|PATCH  articles/{article}             articles.update   App\Http\Controllers\ArticleController@update                   web, auth
  DELETE     articles/{article}             articles.destroy  App\Http\Controllers\ArticleController@destroy                  web, auth
  GET|HEAD   articles/{article}/edit        articles.edit     App\Http\Controllers\ArticleController@edit                     web, auth
  PATCH      articles/{article}/publish     articles.publish  App\Http\Controllers\Articles\PublishArticleController           web, auth
  PATCH      articles/{article}/feature     articles.feature  App\Http\Controllers\Articles\FeatureArticleController           web, auth
  PATCH      articles/{article}/archive     articles.archive  App\Http\Controllers\Articles\ArchiveArticleController           web, auth
```

Ten routes, the same as before. The CRUD routes all point to `ArticleController` with explicit method names. The three action routes point to their dedicated invokable controllers with no method suffix. The refactoring is structurally complete.

## Step 5: Write Feature Tests {#step-5}

With each action living in its own class, the testing story becomes straightforward. Every test file covers exactly one endpoint, and the file name maps directly to the controller it covers. There is no ambiguity about which method is under test, and coverage gaps are easy to spot because the one-to-one relationship is visible at a glance.

Before writing tests, open `database/factories/ArticleFactory.php` and fill in the factory definition along with a few named states that make test setup more expressive:

```php
<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class ArticleFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id'      => User::factory(),
            'title'        => fake()->sentence(),
            'body'         => fake()->paragraphs(3, true),
            // Default state represents a draft: not published, not featured, not archived.
            'published_at' => null,
            'featured'     => false,
            'archived_at'  => null,
        ];
    }

    // Named states let tests express intent clearly: Article::factory()->published()->create()
    // reads as a sentence and requires no inline attribute overrides.

    public function published(): static
    {
        return $this->state(['published_at' => now()]);
    }

    public function featured(): static
    {
        return $this->state(['featured' => true]);
    }

    public function archived(): static
    {
        return $this->state(['archived_at' => now()]);
    }
}
```

### Test PublishArticleController

```bash
php artisan make:test PublishArticleControllerTest
```

Open `tests/Feature/PublishArticleControllerTest.php` and write three scenarios: a successful publish, a duplicate publish attempt, and the two authorization failures:

```php
<?php

namespace Tests\Feature;

use App\Models\Article;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PublishArticleControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_owner_can_publish_their_article(): void
    {
        $user    = User::factory()->create();
        $article = Article::factory()->for($user)->create();

        $response = $this->actingAs($user)
            ->patchJson("/articles/{$article->id}/publish");

        $response->assertOk();

        // Confirm the published_at column was written to the database.
        $this->assertNotNull($article->fresh()->published_at);
    }

    public function test_already_published_article_returns_422(): void
    {
        $user    = User::factory()->create();
        // The published() state sets published_at to now() automatically.
        $article = Article::factory()->for($user)->published()->create();

        $response = $this->actingAs($user)
            ->patchJson("/articles/{$article->id}/publish");

        // Publishing an already-published article is a client error, not a server error.
        $response->assertUnprocessable();
    }

    public function test_non_owner_cannot_publish_article(): void
    {
        $owner   = User::factory()->create();
        $other   = User::factory()->create();
        $article = Article::factory()->for($owner)->create();

        $response = $this->actingAs($other)
            ->patchJson("/articles/{$article->id}/publish");

        // abort_unless() in the controller returns 403 when the IDs do not match.
        $response->assertForbidden();
        $this->assertNull($article->fresh()->published_at);
    }

    public function test_guest_cannot_publish_article(): void
    {
        $article = Article::factory()->create();

        $response = $this->patchJson("/articles/{$article->id}/publish");

        // The auth middleware blocks unauthenticated requests before the controller runs.
        $response->assertUnauthorized();
    }
}
```

### Test FeatureArticleController

```bash
php artisan make:test FeatureArticleControllerTest
```

```php
<?php

namespace Tests\Feature;

use App\Models\Article;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FeatureArticleControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_owner_can_feature_their_article(): void
    {
        $user    = User::factory()->create();
        // Default factory state: featured is false.
        $article = Article::factory()->for($user)->create();

        $response = $this->actingAs($user)
            ->patchJson("/articles/{$article->id}/feature");

        $response->assertOk();
        $this->assertTrue($article->fresh()->featured);
    }

    public function test_owner_can_unfeature_their_article(): void
    {
        $user    = User::factory()->create();
        // featured() state: featured is true.
        $article = Article::factory()->for($user)->featured()->create();

        $response = $this->actingAs($user)
            ->patchJson("/articles/{$article->id}/feature");

        $response->assertOk();
        // The toggle should have flipped featured from true to false.
        $this->assertFalse($article->fresh()->featured);
    }

    public function test_non_owner_cannot_feature_article(): void
    {
        $owner   = User::factory()->create();
        $other   = User::factory()->create();
        $article = Article::factory()->for($owner)->create();

        $response = $this->actingAs($other)
            ->patchJson("/articles/{$article->id}/feature");

        $response->assertForbidden();
        $this->assertFalse($article->fresh()->featured);
    }

    public function test_guest_cannot_feature_article(): void
    {
        $article = Article::factory()->create();

        $response = $this->patchJson("/articles/{$article->id}/feature");

        $response->assertUnauthorized();
    }
}
```

### Test ArchiveArticleController

```bash
php artisan make:test ArchiveArticleControllerTest
```

```php
<?php

namespace Tests\Feature;

use App\Models\Article;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ArchiveArticleControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_owner_can_archive_their_article(): void
    {
        $user    = User::factory()->create();
        $article = Article::factory()->for($user)->create();

        $response = $this->actingAs($user)
            ->patchJson("/articles/{$article->id}/archive");

        $response->assertOk();
        $this->assertNotNull($article->fresh()->archived_at);
    }

    public function test_already_archived_article_returns_422(): void
    {
        $user    = User::factory()->create();
        $article = Article::factory()->for($user)->archived()->create();

        $response = $this->actingAs($user)
            ->patchJson("/articles/{$article->id}/archive");

        $response->assertUnprocessable();
    }

    public function test_non_owner_cannot_archive_article(): void
    {
        $owner   = User::factory()->create();
        $other   = User::factory()->create();
        $article = Article::factory()->for($owner)->create();

        $response = $this->actingAs($other)
            ->patchJson("/articles/{$article->id}/archive");

        $response->assertForbidden();
        $this->assertNull($article->fresh()->archived_at);
    }

    public function test_guest_cannot_archive_article(): void
    {
        $article = Article::factory()->create();

        $response = $this->patchJson("/articles/{$article->id}/archive");

        $response->assertUnauthorized();
    }
}
```

### Run the Test Suite

```bash
php artisan test --filter=ArticleController
```

```
   PASS  Tests\Feature\PublishArticleControllerTest
  ✓ owner can publish their article                                                        0.19s
  ✓ already published article returns 422                                                  0.06s
  ✓ non owner cannot publish article                                                       0.06s
  ✓ guest cannot publish article                                                           0.05s

   PASS  Tests\Feature\FeatureArticleControllerTest
  ✓ owner can feature their article                                                        0.07s
  ✓ owner can unfeature their article                                                      0.06s
  ✓ non owner cannot feature article                                                       0.06s
  ✓ guest cannot feature article                                                           0.05s

   PASS  Tests\Feature\ArchiveArticleControllerTest
  ✓ owner can archive their article                                                        0.07s
  ✓ already archived article returns 422                                                   0.06s
  ✓ non owner cannot archive article                                                       0.06s
  ✓ guest cannot archive article                                                           0.05s

  Tests:    12 passed (24 assertions)
  Duration: 0.78s
```

Twelve tests, all passing. Each test class covers exactly one controller and one endpoint. The resource controller's own tests, which you would write separately in `ArticleControllerTest`, remain entirely unaffected by this refactoring.

## Understanding Invokable Controllers {#understanding}

Now that you have done the refactoring, it is worth understanding what is actually happening under the hood. Invokable controllers are not a special Laravel concept invented for routing; they are a standard PHP feature that Laravel detects and handles transparently during request dispatch.

### PHP's __invoke() Magic Method

PHP's `__invoke()` is a magic method that makes a class instance callable as if it were a function. When you call an object that implements `__invoke()`, PHP executes that method and returns its result:

```php
class Greeting
{
    public function __invoke(string $name): string
    {
        return "Hello, {$name}!";
    }
}

$greeting = new Greeting();

// The object is called like a function. PHP routes this to __invoke().
echo $greeting('World'); // Outputs: Hello, World!
```

Any class with `__invoke()` defined becomes callable. Laravel exploits this behavior during route resolution.

### How Laravel Resolves the Route

When you register a route like `Route::patch('/articles/{article}/publish', PublishArticleController::class)`, Laravel inspects the provided value and checks whether it is a string containing a class name with no method specified. If so, it uses PHP's reflection API to check whether that class implements `__invoke()`. If it does, Laravel internally rewrites the action to `PublishArticleController@__invoke` and processes it identically to any other controller method. There is no separate resolution path, no special middleware, and no magic beyond the reflection check. The service container, dependency injection, middleware stack, and model binding all work exactly the same way.

The cleaner route syntax is purely a surface-level convenience. Everything underneath is the same mechanism you already know.

### Route Registration Side by Side

Here is a direct comparison to make the difference concrete:

```php
// Traditional style: you must specify both the class and the method name.
// The array format exists because a controller can have many public methods.
Route::patch('/articles/{article}/publish', [ArticleController::class, 'publish']);

// Invokable style: the class name alone is sufficient.
// There is only one public method to call, so no disambiguation is needed.
Route::patch('/articles/{article}/publish', PublishArticleController::class);
```

The invokable syntax is shorter and reads more naturally in a route file, especially when each class name already describes the action being performed.

## When to Use Invokable Controllers (and When to Skip Them) {#when-to-use}

Invokable controllers are a deliberate architectural choice, not a universal replacement for resource controllers. Knowing when to reach for each pattern will save you from both under-organizing and over-engineering your codebase.

Invokable controllers are a good fit when the action is complex enough to justify its own class. If a controller method would grow beyond thirty to forty lines and pull in multiple dependencies, a dedicated class will be easier to read, test, and modify in isolation. They are the natural fit for actions that do not belong in a standard CRUD resource: operations like `PublishArticleController`, `ApproveCommentController`, or `ResendVerificationEmailController` have no natural home in a resource controller, and forcing them in creates the exact kind of mismatch this tutorial just resolved.

If your team values a strict one-test-file-per-endpoint policy, invokable controllers make that policy trivially enforceable. The mapping between controller, route, and test file is always one-to-one, and any deviation becomes immediately visible.

Resource controllers remain the better choice for standard CRUD operations where all seven methods share significant logic or the same core dependencies. When `index`, `store`, `show`, `update`, and `destroy` are tightly related and straightforward, grouping them together reduces the number of files and keeps the related behavior visible in one place.

The most practical answer is a hybrid. Many experienced Laravel teams use resource controllers for clean CRUD and reach for invokable controllers whenever an operation is complex, non-standard, or deserves its own test file. Neither approach is dogma; pick the one that makes the next developer to read your code grateful rather than confused.

## Conclusion {#conclusion}

Here are the key takeaways from this tutorial.

- **Resource controllers have a defined scope**: the seven CRUD methods (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`) belong together in a resource controller. Non-CRUD operations like `publish`, `feature`, and `archive` do not, even when they operate on the same model.
- **`--invokable` flag**: running `php artisan make:controller Articles/PublishArticleController --invokable` generates a controller with a single `__invoke()` stub and sets the namespace to reflect the subdirectory automatically.
- **Cleaner route registration**: invokable controllers are registered by passing the class name alone, without an array or method string. Laravel detects `__invoke()` through reflection and routes requests to it automatically.
- **Full dependency injection**: `__invoke()` accepts Form Requests, service classes, route parameters, and Eloquent model bindings just like any named controller method. All of Laravel's resolution mechanisms work identically here.
- **Implicit model binding**: type-hinting an Eloquent model in `__invoke()` triggers implicit model binding exactly as it does in a named controller method. A 404 is returned automatically if no matching record is found.
- **Subdirectory organization**: grouping non-CRUD controllers by resource into subdirectories (for example, `App\Http\Controllers\Articles`) keeps the file system readable as the application grows. The naming convention `{Action}{Resource}Controller` makes each file self-documenting.
- **One test file per action**: because each invokable controller handles exactly one operation, each test class covers exactly one endpoint. This eliminates ambiguity about what is being tested and makes coverage gaps easy to spot.
- **Not a universal replacement**: the goal of this pattern is not to eliminate resource controllers but to give non-CRUD actions a proper home. A well-organized Laravel application will typically contain both.