# Laravel 13 Cache Tags: Invalidate a Single Article's Cache Without Flushing Your Entire Application

You cache your article pages because the database queries behind them are expensive, and for a while everything is fast and happy. Then an editor fixes a typo in article number five and asks why the old version is still showing. You reach for the only invalidation tool you know, `Cache::flush()`, and the typo disappears. Problem solved, or so it seems.

What you actually did was throw away every cached value in the application. All ten thousand article caches, the category navigation, the homepage statistics, the expensive report you cache for an hour: gone, all to fix one typo. The next wave of traffic now stampedes straight through to your database to rebuild a cache that was almost entirely still valid, and your response times spike at the worst possible moment. Worse still, `Cache::flush()` does not respect your cache prefix, so if another application shares the same Redis server, you just cleared its cache too.

The right tool for this is cache tagging. Tags let you label related cache entries and then invalidate them by label, so when article five changes you clear exactly the entries tied to article five and leave everything else warm. In this tutorial we build a small article site that caches each article under its own tag, then wire up surgical invalidation so a single update busts a single cache. By the end you will be able to expire one item, or one logical group of items, without ever touching the rest of your cache.

## Overview {#overview}

The core idea is to attach two tags to every cached article: a shared `articles` tag that lets us clear all articles at once when we ever need to, and a unique `article:{id}` tag that lets us clear exactly one. Because flushing any single tag invalidates every entry carrying that tag, the per-id tag becomes a precise scalpel. To prove the rest of the cache is untouched, we also store one deliberately untagged value and watch it survive every invalidation. We will drive cache busting manually first, then move it into a model observer so it happens automatically whenever an article changes.

### What You'll Build

- A Laravel 13 article site that caches each article on read, tagged by both a global `articles` tag and a unique `article:{id}` tag
- An update path that invalidates only the changed article's cache
- A model observer that busts the right cache automatically on every update and delete
- A separate, untagged cache entry that proves your other caches stay warm through every invalidation
- A Pest test suite that verifies tagging, single-item invalidation, and group invalidation using the `array` store

### What You'll Learn

- Which cache drivers support tagging and why `file` and `database` do not
- How to store and read tagged items with `Cache::tags([...])->remember()`
- How to design per-id tags so you can expire one item without flushing the rest
- The difference between flushing one tag and flushing a group of tags
- How to automate invalidation with a model observer and the `#[ObservedBy]` attribute
- How to test tag behavior in CI without a running Redis server

### What You'll Need

- PHP 8.3 or newer
- Composer and the Laravel installer
- A running Redis server on your machine; cache tags require a taggable store, and Redis is the easiest one to reach for
- Basic familiarity with Eloquent models, routes, and Artisan Tinker

## Step 1: Create the Project and Switch to a Taggable Cache Store {#step-1-create-the-project-and-switch-to-a-taggable-cache-store}

Create a fresh Laravel 13 application configured for SQLite and Pest, then move into it.

```bash
laravel new cache-tags-demo --no-interaction --database=sqlite --pest --no-boost
cd cache-tags-demo
```

Before writing any feature code, we have to confront the one fact that shapes this entire tutorial: tags do not work on every cache driver. A brand new Laravel 13 app defaults to the `database` cache store, and that store cannot tag. You can prove it to yourself right now with Tinker.

```bash
php artisan tinker --execute="Cache::tags(['demo'])->put('k', 'v', 60);"
```

The call fails immediately with a clear exception.

```
   BadMethodCallException 

  This cache store does not support tagging.

  at vendor/laravel/framework/src/Illuminate/Cache/Repository.php
```

Tagging is only supported by the `redis`, `memcached`, and `array` drivers. The `file`, `database`, and `dynamodb` drivers have no way to track which keys belong to which tag, so they refuse the operation outright. We will use Redis, which is the most common production choice. Install the pure-PHP Redis client so you do not need to compile a PECL extension.

```bash
composer require predis/predis
```

Now point the application's cache at Redis. Open `.env` and set the cache store and the Redis client.

```dotenv
CACHE_STORE=redis
REDIS_CLIENT=predis
```

`CACHE_STORE=redis` makes Redis the default cache backend, which is what gives us tagging. `REDIS_CLIENT=predis` tells Laravel to talk to Redis through the Composer package we just installed rather than the PhpRedis extension. Run the default migrations so the rest of the app has its tables.

```bash
php artisan migrate
```

With Redis selected, repeat the tagging experiment. This time it works.

```bash
php artisan tinker --execute="Cache::tags(['demo'])->put('k', 'v', 60); echo Cache::tags(['demo'])->get('k');"
```

```
v
```

The value went into a tagged cache and came back out, which confirms Redis is reachable and tagging is live. Now we can build something worth caching.

## Step 2: Build the Article Model and Seed Data {#step-2-build-the-article-model-and-seed-data}

Generate an `Article` model along with its migration and factory in one command.

```bash
php artisan make:model Article -mf
```

Open the generated migration in `database/migrations` and define a simple article table.

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
            $table->string('title');
            $table->text('body');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('articles');
    }
};
```

A title and a body are all we need to represent an article. The `timestamps()` column gives us an `updated_at` value we can display, which makes it obvious when a cached version is stale.

Open `app/Models/Article.php` and mark the writable attributes with the `#[Fillable]` attribute.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['title', 'body'])]
class Article extends Model
{
    use HasFactory;
}
```

The `#[Fillable(['title', 'body'])]` attribute keeps mass assignment protection on while declaring that `title` and `body` are safe to set through `create()` and `update()`. We will return to this file in Step 5 to attach an observer.

Open the factory at `database/factories/ArticleFactory.php` and describe a fake article.

```php
<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

class ArticleFactory extends Factory
{
    public function definition(): array
    {
        return [
            'title' => fake()->sentence(6),
            'body' => fake()->paragraphs(3, true),
        ];
    }
}
```

Passing `true` to `fake()->paragraphs(3, true)` returns the three paragraphs as a single string instead of an array, which matches our `text` column. Seed a handful of articles by editing `database/seeders/DatabaseSeeder.php`.

```php
<?php

namespace Database\Seeders;

use App\Models\Article;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        Article::factory()->count(10)->create();
    }
}
```

Ten articles is plenty to show that invalidating one leaves the other nine alone. Run the seeder.

```bash
php artisan db:seed
```

```
   INFO  Seeding database.
```

Confirm the rows landed.

```bash
php artisan tinker --execute="echo App\Models\Article::count();"
```

```
10
```

We now have ten articles. Next we cache them.

## Step 3: Cache Each Article With Tags {#step-3-cache-each-article-with-tags}

We will serve articles through a controller that caches each one under two tags. Generate the controller.

```bash
php artisan make:controller ArticleController
```

Open `app/Http/Controllers/ArticleController.php` and write the `show` method.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Article;
use Illuminate\Support\Facades\Cache;

class ArticleController extends Controller
{
    public function show(int $id)
    {
        // Cache the article under a global "articles" tag and a unique
        // "article:{id}" tag so we can later clear one without the rest.
        $article = Cache::tags(['articles', "article:{$id}"])
            ->remember("article:{$id}", now()->addHour(), function () use ($id) {
                logger("CACHE MISS: loading article {$id} from the database");

                return Article::findOrFail($id);
            });

        // A deliberately untagged cache entry that should survive every
        // tag flush, proving we only clear what we mean to clear.
        $stats = Cache::remember('homepage:stats', now()->addHour(), function () {
            return ['total_articles' => Article::count()];
        });

        return view('articles.show', [
            'article' => $article,
            'stats' => $stats,
        ]);
    }
}
```

The important line is `Cache::tags(['articles', "article:{$id}"])->remember(...)`. The `remember` method returns the cached value if it exists and otherwise runs the closure, stores its result under both tags, and returns it. The `logger()` call inside the closure only fires on a cache miss, so it is our proof of whether a request hit the database or the cache. The `$stats` entry is stored with a plain `Cache::remember()` and no tags at all; it is the control that must survive when we start flushing tags later.

Register the route in `routes/web.php`.

```php
<?php

use App\Http\Controllers\ArticleController;
use Illuminate\Support\Facades\Route;

Route::get('/articles/{id}', [ArticleController::class, 'show']);
Route::put('/articles/{id}', [ArticleController::class, 'update']);
```

The `GET` route renders an article and the `PUT` route will update it; we build the `update` action in the next step. Now create the view at `resources/views/articles/show.blade.php` following the standalone HTML and Tailwind convention.

```blade
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $article->title }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <p class="text-sm text-gray-500">Total articles: {{ $stats['total_articles'] }}</p>
        <h1 class="text-2xl font-bold mt-2">{{ $article->title }}</h1>
        <p class="text-xs text-gray-400 mt-1">Last updated {{ $article->updated_at->diffForHumans() }}</p>
        <div class="mt-4 leading-relaxed whitespace-pre-line">{{ $article->body }}</div>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Cache Tags at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

Because the cached `$article` is a full Eloquent model, `$article->updated_at->diffForHumans()` works just as it would on a fresh model; the cache serializes and restores it transparently. Start the development server and load an article in your browser to confirm the page renders.

```bash
php artisan serve
```

Visit `http://127.0.0.1:8000/articles/1` and you should see the article title, body, and total count. The article is now cached. Time to invalidate it precisely.

## Step 4: Invalidate a Single Article on Update {#step-4-invalidate-a-single-article-on-update}

When an article changes, we want to clear only that article's cache. Add an `update` method to `app/Http/Controllers/ArticleController.php`.

```php
public function update(int $id)
{
    $article = Article::findOrFail($id);

    $article->update(request()->only(['title', 'body']));

    // Flush only the entries tagged with this article's unique tag.
    Cache::tags("article:{$id}")->flush();

    return response()->json([
        'message' => "Cache cleared for article {$id}",
        'article' => $article,
    ]);
}
```

The line `Cache::tags("article:{$id}")->flush()` is the whole point of the tutorial. It removes every cache entry carrying the `article:{id}` tag, which is exactly one entry: the article we just changed. Because that entry was also tagged `articles`, you might expect flushing one of its tags to be insufficient, but flushing any single tag an entry carries is enough to invalidate it. Everything tagged with a different `article:{id}`, and the untagged `homepage:stats`, is left completely alone.

You can see this behavior directly in Tinker without even going through the controller, because `flush()` on a tag is the same call wherever you make it. First warm two articles and the stats, then flush just one.

```bash
php artisan tinker
```

```php
> Cache::tags(['articles', 'article:3'])->put('article:3', App\Models\Article::find(3), now()->addHour());
> Cache::tags(['articles', 'article:7'])->put('article:7', App\Models\Article::find(7), now()->addHour());
> Cache::put('homepage:stats', ['total_articles' => 10], now()->addHour());

> Cache::tags('article:3')->flush();
= true

> Cache::tags(['articles', 'article:3'])->get('article:3');
= null

> Cache::tags(['articles', 'article:7'])->get('article:7')?->title;
= "Quia voluptatem quas et molestiae."

> Cache::get('homepage:stats');
= [
    "total_articles" => 10,
  ]
```

Flushing `article:3` cleared article three, while article seven and the untagged stats survived untouched. That is the surgical invalidation a blanket `Cache::flush()` can never give you. The one weakness here is that this only works if every developer remembers to call `flush()` after every change. Let us remove that risk.

## Step 5: Automate Invalidation With a Model Observer {#step-5-automate-invalidation-with-a-model-observer}

Manual cache busting is fragile because it lives in the controller, and articles can change from many places: a console command, a queued job, a bulk import. A model observer fixes this by reacting to the model's own lifecycle events, so the cache is cleared no matter where the change came from. Generate the observer.

```bash
php artisan make:observer ArticleObserver --model=Article
```

Open `app/Observers/ArticleObserver.php` and clear the article's tag on both update and delete.

```php
<?php

namespace App\Observers;

use App\Models\Article;
use Illuminate\Support\Facades\Cache;

class ArticleObserver
{
    public function updated(Article $article): void
    {
        // Any save that changes the article clears just its cache.
        Cache::tags("article:{$article->id}")->flush();
    }

    public function deleted(Article $article): void
    {
        // A removed article should not linger in the cache either.
        Cache::tags("article:{$article->id}")->flush();
    }
}
```

The `updated` method runs after any persisted change to an existing article, and `deleted` runs after it is removed; both flush the article's unique tag so the stale value cannot survive. Register the observer on the model with the `#[ObservedBy]` attribute. Reopen `app/Models/Article.php` and add it.

The current model header looks like this.

```php
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['title', 'body'])]
class Article extends Model
{
    use HasFactory;
}
```

Update it to import the observer and the `#[ObservedBy]` attribute.

```php
use App\Observers\ArticleObserver;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\ObservedBy;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['title', 'body'])]
#[ObservedBy(ArticleObserver::class)]
class Article extends Model
{
    use HasFactory;
}
```

Now that the observer owns invalidation, the manual flush in the controller is redundant. Simplify the `update` method so the controller no longer has to remember anything about caching. The old version flushed the cache itself.

```php
public function update(int $id)
{
    $article = Article::findOrFail($id);

    $article->update(request()->only(['title', 'body']));

    // Flush only the entries tagged with this article's unique tag.
    Cache::tags("article:{$id}")->flush();

    return response()->json([
        'message' => "Cache cleared for article {$id}",
        'article' => $article,
    ]);
}
```

The new version just updates the model and trusts the observer to clear the cache.

```php
public function update(int $id)
{
    $article = Article::findOrFail($id);

    // The ArticleObserver clears this article's cache automatically.
    $article->update(request()->only(['title', 'body']));

    return response()->json([
        'message' => "Article {$id} updated",
        'article' => $article,
    ]);
}
```

With the manual flush gone you can remove the now-unused `Cache` import from the controller if your editor flags it. The behavior is identical, but invalidation now happens for every update from every code path, not just this one endpoint. Let us watch the whole thing work.

## Step 6: Try It Out {#step-6-try-it-out}

We will exercise the feature from three angles in Tinker, which lets us inspect the cache state directly after each action. Make sure your `php artisan serve` process from Step 3 is still running if you want to load pages in the browser as well.

### Scenario 1: Warm the Cache and Confirm Hits

Load article one twice through the running server, then look at the log.

```bash
curl -s http://127.0.0.1:8000/articles/1 > /dev/null
curl -s http://127.0.0.1:8000/articles/1 > /dev/null
```

Open `storage/logs/laravel.log` and you will see the cache miss logged exactly once, on the first request.

```
[2026-05-29 09:14:02] local.DEBUG: CACHE MISS: loading article 1 from the database
```

The second request never logged a miss because it was served straight from Redis. That is the performance win we are protecting.

### Scenario 2: Update One Article and Prove Only It Rebuilt

Now use Tinker to update article one through normal Eloquent and confirm the observer cleared only its cache.

```bash
php artisan tinker
```

```php
> Cache::tags(['articles', 'article:1'])->put('article:1', App\Models\Article::find(1), now()->addHour());
> Cache::tags(['articles', 'article:2'])->put('article:2', App\Models\Article::find(2), now()->addHour());
> Cache::put('homepage:stats', ['total_articles' => 10], now()->addHour());

> App\Models\Article::find(1)->update(['title' => 'A corrected title']);
= true

> Cache::tags(['articles', 'article:1'])->get('article:1');
= null

> Cache::tags(['articles', 'article:2'])->get('article:2')?->title;
= "Aperiam quos qui est velit voluptas."

> Cache::get('homepage:stats');
= [
    "total_articles" => 10,
  ]
```

The plain `update()` call triggered the observer, which flushed `article:1`. Article two and the untagged stats stayed cached, so the next visitor to article two still gets a fast response while article one rebuilds from fresh data.

### Scenario 3: Flush the Whole Group at Once

Sometimes you genuinely want to clear all articles, for example after a layout change to the shared template. The global `articles` tag does that in one call, and the untagged stats still survive.

```php
> Cache::tags(['articles', 'article:5'])->put('article:5', App\Models\Article::find(5), now()->addHour());
> Cache::tags(['articles', 'article:9'])->put('article:9', App\Models\Article::find(9), now()->addHour());

> Cache::tags('articles')->flush();
= true

> Cache::tags(['articles', 'article:5'])->get('article:5');
= null

> Cache::tags(['articles', 'article:9'])->get('article:9');
= null

> Cache::get('homepage:stats');
= [
    "total_articles" => 10,
  ]
```

Flushing the `articles` tag cleared every article in one move, yet `homepage:stats` is still there because it was never tagged. You now have two levels of control: one article, or all articles, and never the whole cache. Let us lock this behavior down with tests.

## Step 7: Write the Tests {#step-7-write-the-tests}

Cache tags need a taggable store, but we do not want CI to depend on a running Redis server. The `array` store also supports tagging and lives entirely in memory for the duration of a test, so we point the default cache at `array` in a `beforeEach` hook. Create the test file.

```bash
php artisan make:test ArticleCacheTest --pest
```

Open `tests/Feature/ArticleCacheTest.php` and write the suite.

```php
<?php

use App\Models\Article;
use Illuminate\Support\Facades\Cache;

beforeEach(function () {
    // The array store supports tagging, so tests need no Redis server.
    config()->set('cache.default', 'array');
});

it('caches an article after it is shown', function () {
    $article = Article::factory()->create();

    $this->get("/articles/{$article->id}")->assertOk();

    $cached = Cache::tags(['articles', "article:{$article->id}"])->get("article:{$article->id}");

    expect($cached)->not->toBeNull()
        ->and($cached->id)->toBe($article->id);
});

it('clears only the updated article from the cache', function () {
    $a = Article::factory()->create();
    $b = Article::factory()->create();

    $this->get("/articles/{$a->id}")->assertOk();
    $this->get("/articles/{$b->id}")->assertOk();

    $this->put("/articles/{$a->id}", ['title' => 'Fixed', 'body' => 'New body'])->assertOk();

    expect(Cache::tags(['articles', "article:{$a->id}"])->get("article:{$a->id}"))->toBeNull()
        ->and(Cache::tags(['articles', "article:{$b->id}"])->get("article:{$b->id}"))->not->toBeNull();
});

it('keeps untagged cache when a single article tag is flushed', function () {
    $article = Article::factory()->create();

    Cache::put('homepage:stats', ['total_articles' => 1], now()->addHour());
    Cache::tags(['articles', "article:{$article->id}"])
        ->put("article:{$article->id}", $article, now()->addHour());

    Cache::tags("article:{$article->id}")->flush();

    expect(Cache::tags(['articles', "article:{$article->id}"])->get("article:{$article->id}"))->toBeNull()
        ->and(Cache::get('homepage:stats'))->not->toBeNull();
});

it('flushing the articles tag clears every article but not untagged cache', function () {
    $a = Article::factory()->create();
    $b = Article::factory()->create();

    Cache::put('homepage:stats', ['total_articles' => 2], now()->addHour());
    Cache::tags(['articles', "article:{$a->id}"])->put("article:{$a->id}", $a, now()->addHour());
    Cache::tags(['articles', "article:{$b->id}"])->put("article:{$b->id}", $b, now()->addHour());

    Cache::tags('articles')->flush();

    expect(Cache::tags(['articles', "article:{$a->id}"])->get("article:{$a->id}"))->toBeNull()
        ->and(Cache::tags(['articles', "article:{$b->id}"])->get("article:{$b->id}"))->toBeNull()
        ->and(Cache::get('homepage:stats'))->not->toBeNull();
});

it('flushes the cache when an article is updated via the observer', function () {
    $article = Article::factory()->create();

    Cache::tags(['articles', "article:{$article->id}"])
        ->put("article:{$article->id}", $article, now()->addHour());

    $article->update(['title' => 'Changed by Eloquent']);

    expect(Cache::tags(['articles', "article:{$article->id}"])->get("article:{$article->id}"))->toBeNull();
});

it('flushes the cache when an article is deleted via the observer', function () {
    $article = Article::factory()->create();

    Cache::tags(['articles', "article:{$article->id}"])
        ->put("article:{$article->id}", $article, now()->addHour());

    $article->delete();

    expect(Cache::tags(['articles', "article:{$article->id}"])->get("article:{$article->id}"))->toBeNull();
});
```

Each test nails down one promise. The first confirms a shown article lands in the tagged cache. The second hits the update route and proves only the changed article is cleared while its neighbor stays cached. The third and fourth verify the two levels of invalidation, single-tag and group-tag, and that the untagged `homepage:stats` survives both. The last two bypass the controller entirely and prove the observer fires on a raw Eloquent `update()` and `delete()`, which is the guarantee that invalidation works from any code path. Run the suite.

```bash
php artisan test
```

```
   PASS  Tests\Feature\ArticleCacheTest
  ✓ it caches an article after it is shown                                   0.21s
  ✓ it clears only the updated article from the cache                        0.04s
  ✓ it keeps untagged cache when a single article tag is flushed             0.02s
  ✓ it flushing the articles tag clears every article but not untagged cache 0.03s
  ✓ it flushes the cache when an article is updated via the observer         0.02s
  ✓ it flushes the cache when an article is deleted via the observer         0.02s

  Tests:    6 passed (14 assertions)
  Duration: 0.43s
```

Six green tests confirm tagging, single-item invalidation, group invalidation, and observer-driven busting, all without a Redis server in the loop. With the behavior verified, here is what is happening underneath.

## How Cache Tags Work Under the Hood {#how-cache-tags-work-under-the-hood}

Tags can feel like magic, but the mechanism is simple once you see it. When you write to a tagged cache, Laravel does not store your value under the key you gave it. Instead it generates a hidden namespace from the tags, derived from a version identifier stored for each tag, and prefixes your real key with that namespace. The value lives at something closer to `tag-version-hash:article:5` than at `article:5`. This is exactly why you cannot read a tagged value back without supplying the same tags: without them, Laravel cannot reconstruct the namespace and so cannot find the key.

Flushing a tag, then, is not a search-and-delete across thousands of keys. Laravel simply changes the version identifier for that tag. Every key that was namespaced under the old version instantly becomes unreachable, because new reads compute the new namespace and find nothing there. The old entries are orphaned and eventually reclaimed by the store's own expiration and memory management. This is what makes a tag flush fast and constant-time regardless of how many entries carried the tag, and it is also why memcached, which automatically purges stale records, is sometimes recommended for heavily tagged caches.

This design also explains the driver restriction. The `file` and `database` drivers have no efficient way to maintain these tag version identifiers and namespaced lookups, so Laravel does not pretend to support tagging on them and throws the `BadMethodCallException` you saw in Step 1. Redis and memcached have the data structures and atomic operations to do it properly, which is why tags are exclusive to them and to the in-memory `array` store used for testing.

## Cache Tags vs Forgetting by Key {#cache-tags-vs-forgetting-by-key}

Tags are powerful, but they are not always the right tool, and reaching for them when a plain key would do adds overhead you do not need. If a cached value has exactly one natural identity and you always know its key, `Cache::forget('article:5')` on the default store is simpler, works on every driver including `file` and `database`, and avoids the extra namespace bookkeeping. A single user's profile cache or a single config blob fits this pattern perfectly.

Tags earn their place when one of two things is true. First, when a single entry logically belongs to several groups at once, such as a product cached under both its category and its brand, so that clearing either group should invalidate it. Second, when you need to invalidate a whole group in one operation without enumerating its members, such as clearing every article after a template change. A plain key approach would force you to track and loop over every key yourself, which is exactly the bookkeeping tags do for you. The article cache in this tutorial uses both ideas: the per-id tag gives you precise single-item control, and the shared `articles` tag gives you group control, neither of which requires you to maintain a list of keys by hand.

## Conclusion {#conclusion}

Reaching for `Cache::flush()` to fix one stale value is like demolishing a building to repaint one room. Cache tags give you the precision to invalidate exactly what changed, keep the rest of your cache warm, and protect your database from needless stampedes. Here are the ideas worth keeping.

- **Tags need a taggable store.** Cache tagging works only on the `redis`, `memcached`, and `array` drivers; the default `database` store and the `file` store will throw `This cache store does not support tagging`.
- **Use a global tag plus a per-id tag.** Storing each item under both `['articles', "article:{id}"]` gives you two levels of control, clearing one item or the whole group, from the same simple API.
- **Flushing any one of an entry's tags invalidates it.** That is why `Cache::tags("article:5")->flush()` clears article five even though it also carries the `articles` tag, and why an untagged entry survives every tag flush.
- **Let an observer own invalidation.** Moving the flush into an `ArticleObserver` with `#[ObservedBy]` means the cache is cleared on every update and delete from any code path, not just the one controller that happened to remember.
- **Test with the array store.** Because the `array` driver supports tagging and runs in memory, your tests verify real tag behavior without depending on a Redis server in CI.
- **Prefer a plain key when one is enough.** If a value has a single known key and one identity, `Cache::forget()` is simpler and works everywhere; save tags for entries that belong to multiple groups or need group-wide invalidation.
