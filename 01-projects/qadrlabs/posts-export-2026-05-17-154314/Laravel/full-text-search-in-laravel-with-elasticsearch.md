---
title: "Full-Text Search in Laravel with Elasticsearch"
slug: "full-text-search-in-laravel-with-elasticsearch"
category: "Laravel"
date: "2026-04-29"
status: "published"
---

Every Laravel application eventually runs into the same wall. Search starts as `Post::where('title', 'LIKE', "%{$query}%")`, and for a while it works. Then the dataset grows, and that query starts doing a full table scan. You add an index, the performance improves slightly, but now users complain that searching for "running" does not find posts about "run" or "runner". Someone types "elasticsaerch" in the search bar and gets zero results. And when you try to sort results by relevance rather than by date, you realize SQL has no concept of relevance at all.

These are not edge cases. They are the natural limits of using a relational database as a search engine. Elasticsearch was built specifically to solve them. It uses inverted indexes and a dedicated analysis pipeline to make full-text search fast, typo-tolerant, and relevance-aware by default. But most tutorials stop at "send a document, run a query, see results" without explaining how to integrate it correctly into a Laravel application: how to keep MySQL and Elasticsearch in sync automatically, how to design the integration so it is testable, and what trade-offs you are accepting when you introduce a second datastore.

This tutorial covers all of it, step by step, using the official Elasticsearch PHP client directly so you understand what is actually happening at each layer.

## Overview {#overview}

Before writing a single line of code, it is worth establishing the mental model that the entire integration is built on. Elasticsearch and MySQL are not alternatives in this setup. They serve completely different roles.

```
┌──────────────────────────────────────────────────────────┐
│  MySQL                                                   │
│  Source of truth: posts, users, relationships            │
│  Handles: create, update, delete, relational queries     │
└─────────────────────────┬────────────────────────────────┘
                          │ Observer fires on save / delete
                          ▼
┌──────────────────────────────────────────────────────────┐
│  Queued Job                                              │
│  Async bridge: serializes the document for indexing      │
└─────────────────────────┬────────────────────────────────┘
                          │ HTTP request to REST API
                          ▼
┌──────────────────────────────────────────────────────────┐
│  Elasticsearch                                           │
│  Search layer: full-text queries, fuzzy matching,        │
│  relevance scoring                                       │
│  Returns: document IDs                                   │
└─────────────────────────┬────────────────────────────────┘
                          │ IDs passed back to Laravel
                          ▼
┌──────────────────────────────────────────────────────────┐
│  MySQL (second read)                                     │
│  Fetch full Eloquent models by ID, with relationships    │
└──────────────────────────────────────────────────────────┘
```

MySQL stays the source of truth for all writes. Elasticsearch only ever receives data from MySQL, never the other way around. When a user runs a search, Elasticsearch returns a ranked list of document IDs, and Laravel fetches the full Eloquent models from MySQL using those IDs. This two-step read pattern keeps relationships, authorization, and data integrity entirely in MySQL's domain.

### What You'll Build

- A Docker-based Elasticsearch 9 instance running locally.
- An explicit index mapping for a `posts` index that separates full-text fields from filterable fields.
- An Artisan command that bulk-indexes all existing posts in batches.
- An Eloquent Observer that dispatches queued jobs to keep the Elasticsearch index in sync with MySQL on every create, update, and delete.
- A `PostSearch` class that encapsulates the query DSL: multi-field matching with boosting, fuzzy matching for typo tolerance, and a filter that excludes unpublished posts.
- A `SearchController` that calls `PostSearch`, fetches ordered Eloquent models from MySQL, and renders a Blade view with a search bar and results.
- Pest tests that verify the query structure `PostSearch` builds, using a mocked Elasticsearch client.

### What You'll Learn

- How to run Elasticsearch 9 locally with Docker and connect to it from Laravel.
- Why explicit index mappings matter and how field types like `text` vs `keyword` affect search behavior.
- How to auto-sync MySQL data to Elasticsearch via a queued Observer pattern without coupling the model directly to the search infrastructure.
- How to write a meaningful query using the Elasticsearch DSL: `bool`, `multi_match`, `fuzziness`, `filter`, and `range`.
- How to bind the Elasticsearch client in the service container so it can be mocked cleanly in tests.
- The trade-offs of dual-write consistency and what to do when the queue fails.

### What You'll Need

- PHP 8.3 or higher.
- Laravel 13.
- Docker and Docker Compose installed locally.
- Composer installed globally.
- Pest (setup included in Step 1).
- Basic familiarity with Eloquent models, migrations, Artisan commands, and queued jobs.

## Step 1: Set Up the Project and Run Elasticsearch {#step-1-setup}

If you already have a fresh Laravel 13 project, skip the first three commands and go straight to installing Pest and setting up Docker. Otherwise:

```bash
laravel new es-demo --no-interaction
cd es-demo
composer remove phpunit/phpunit
composer require pestphp/pest --dev --with-all-dependencies
./vendor/bin/pest --init
```

Confirm the expectation API prompt with yes. The `phpunit.xml` in Laravel 13 already has the SQLite in-memory connection uncommented, so tests will run against an in-memory database with no extra configuration.

Now create a `docker-compose.yml` file in the root of your project. A single-node Elasticsearch 9 instance is enough for local development:

```yaml
# docker-compose.yml

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:9.0.0
    container_name: es-demo
    environment:
      # Single-node mode skips the cluster formation ceremony
      - discovery.type=single-node
      # Disable TLS and authentication for local development only.
      # Never use this setting in production.
      - xpack.security.enabled=false
      # Cap heap at 512 MB so it does not consume your entire machine RAM
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    ports:
      - "9200:9200"
    volumes:
      # Named volume persists index data across container restarts
      - esdata:/usr/share/elasticsearch/data

volumes:
  esdata:
    driver: local
```

Start the container:

```bash
docker compose up -d
```

Give Elasticsearch about 20 to 30 seconds to finish its startup sequence, then verify it is running:

```bash
curl -s http://localhost:9200 | grep "tagline"
```

You should see:

```
"tagline" : "You Know, for Search"
```

If the curl returns nothing or a connection refused error, run `docker compose logs elasticsearch` and look for startup errors. The most common one on Linux is an `vm.max_map_count` kernel setting that is too low; fix it with `sudo sysctl -w vm.max_map_count=262144`.

Add the Elasticsearch host to your `.env` file:

```ini
ELASTICSEARCH_HOST=http://localhost:9200
```

Also configure the queue connection so your Observer jobs run asynchronously. For local development, the `database` driver is simplest because it requires no additional infrastructure:

```ini
QUEUE_CONNECTION=database
```

Laravel 13 ships with the `jobs` table migration included by default, so no extra setup is needed. The table will be created when you run `php artisan migrate` later in Step 3.

## Step 2: Install the PHP Client and Bind It in the Container {#step-2-client}

Install the official Elasticsearch PHP client, pinned to the v9 major:

```bash
composer require elasticsearch/elasticsearch:^9.0
```

Create a dedicated config file at `config/elasticsearch.php`. This keeps all Elasticsearch configuration in one place instead of scattering it across `config/services.php` or hardcoding it in classes:

```php
<?php

return [
    // The full URL to your Elasticsearch instance, including scheme and port
    'host' => env('ELASTICSEARCH_HOST', 'http://localhost:9200'),

    // Index names are defined here so they can be changed without touching class code.
    // This is particularly useful when running tests against a separate test index.
    'indices' => [
        'posts' => env('ELASTICSEARCH_POSTS_INDEX', 'posts'),
    ],
];
```

Open `app/Providers/AppServiceProvider.php` and bind the Elasticsearch client in the `register()` method. Binding through the service container is what makes the client injectable and mockable:

```php
<?php

namespace App\Providers;

use Elastic\Elasticsearch\Client;
use Elastic\Elasticsearch\ClientBuilder;
use Elastic\Elasticsearch\ClientInterface;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Bind the Elasticsearch client as a singleton.
        // A singleton means Laravel creates the client once and reuses it
        // for the lifetime of the request, avoiding repeated TCP handshakes.
        $this->app->singleton(Client::class, function () {
            return ClientBuilder::create()
                ->setHosts([config('elasticsearch.host')])
                ->build();
        });

        // Also bind the interface to the concrete class.
        // This allows classes and tests to type-hint ClientInterface,
        // which is not final and can be mocked freely.
        $this->app->bind(ClientInterface::class, Client::class);
    }

    public function boot(): void
    {
        //
    }
}
```

With this binding in place, any class that type-hints `ClientInterface` in its constructor will receive the configured singleton automatically. In tests, you can mock `ClientInterface` because it is a regular interface — unlike `Client`, which is marked `final` and cannot be extended or mocked by Mockery.

## Step 3: Create the Post Model and Migration {#step-3-model}

```bash
php artisan make:model Post -mf
```

Open the generated migration and define the columns for a blog post:

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
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('body');
            // null means draft; a past timestamp means published.
            // This field is also indexed in Elasticsearch for filter queries.
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

Open `app/Models/Post.php` and define the model with the Laravel 13 `#[Fillable]` attribute, a `casts()` method to ensure `published_at` is always a Carbon instance, and a named relationship to its author.

The cast is essential: without it, `published_at` comes out of the database as a plain string, and calling `->toIso8601String()` on it in the bulk-index command or the queued sync job throws a fatal error. The `casts()` method is the correct and reliable way to define casts alongside `#[Fillable]` in Laravel 13. Using a `#[Casts]` PHP attribute is not supported and will be silently ignored, leaving `published_at` as a string.

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

    /**
     * Defines how Eloquent transforms raw database values before they reach PHP.
     * Returning 'datetime' for published_at instructs Eloquent to wrap the raw
     * timestamp string in a Carbon instance automatically on every model load.
     * This is what makes ->toIso8601String() safe to call anywhere on the model.
     */
    protected function casts(): array
    {
        return [
            'published_at' => 'datetime',
        ];
    }

    // The relationship is named "author" to describe the user's role in this context
    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
```

Open `database/factories/PostFactory.php` and add a `published()` state for seeding:

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
            'body'         => $this->faker->paragraphs(5, true),
            // All factory posts are drafts by default
            'published_at' => null,
        ];
    }

    // State that sets a past publication timestamp
    public function published(): static
    {
        return $this->state(fn (array $attributes) => [
            'published_at' => now()->subDays(rand(1, 60)),
        ]);
    }
}
```

Run the migration:

```bash
php artisan migrate
```

## Step 4: Create the Index with an Explicit Mapping {#step-4-mapping}

This step is the one most tutorials skip entirely, and it is the most important one for getting good search results. Elasticsearch can infer field types from the data you send (dynamic mapping), but the inferred types are almost never what you actually want. By defining the mapping explicitly, you control exactly how each field is analyzed and stored.

Create the command:

```bash
php artisan make:command Elasticsearch/CreatePostsIndex
```

Open `app/Console/Commands/Elasticsearch/CreatePostsIndex.php` and define the mapping:

```php
<?php

namespace App\Console\Commands\Elasticsearch;

use Elastic\Elasticsearch\Client;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

// In Laravel 13, command signature and description are defined as PHP attributes
// instead of protected class properties. The generated file already uses this format.
#[Signature('es:create-posts-index {--fresh : Drop the existing index before creating a new one}')]
#[Description('Create the Elasticsearch index for posts with explicit field mappings')]
class CreatePostsIndex extends Command
{
    public function __construct(private readonly Client $client)
    {
        parent::__construct();
    }

    public function handle(): int
    {
        $index = config('elasticsearch.indices.posts');

        // If --fresh is passed, drop the existing index first.
        // This is useful when you change the mapping and need to reindex from scratch.
        if ($this->option('fresh') && $this->indexExists($index)) {
            $this->client->indices()->delete(['index' => $index]);
            $this->info("Deleted existing index [{$index}].");
        }

        if ($this->indexExists($index)) {
            $this->warn("Index [{$index}] already exists. Use --fresh to recreate it.");
            return self::SUCCESS;
        }

        $this->client->indices()->create([
            'index' => $index,
            'body'  => [
                'settings' => [
                    // number_of_shards: how many pieces the index is split into.
                    // 1 is correct for a single-node development environment.
                    'number_of_shards'   => 1,
                    // number_of_replicas: how many copies of each shard exist.
                    // 0 is correct for a single-node cluster; 1+ requires multiple nodes.
                    'number_of_replicas' => 0,
                ],
                'mappings' => [
                    'properties' => [

                        // "text" type: the field is analyzed (tokenized, lowercased, stemmed).
                        // Suitable for full-text search where you want "posts" to match "post".
                        // The nested "keyword" sub-field stores the raw, unanalyzed string,
                        // which is useful for sorting and exact-match aggregations.
                        'title' => [
                            'type'   => 'text',
                            'fields' => [
                                'keyword' => ['type' => 'keyword'],
                            ],
                        ],

                        // The "english" analyzer applies language-specific stemming.
                        // "running" becomes "run", so a search for "run" matches "running".
                        // This is the key difference between "standard" and "english" analyzer.
                        'body' => [
                            'type'     => 'text',
                            'analyzer' => 'english',
                        ],

                        // "keyword" type: stored and searched as an exact string, never analyzed.
                        // Correct for values you filter on but never do full-text search against.
                        'author_name' => [
                            'type' => 'keyword',
                        ],

                        // "date" type: stored in milliseconds since epoch internally.
                        // Elasticsearch auto-detects ISO 8601 strings during indexing.
                        'published_at' => [
                            'type' => 'date',
                        ],
                    ],
                ],
            ],
        ]);

        $this->info("Index [{$index}] created successfully.");
        return self::SUCCESS;
    }

    private function indexExists(string $index): bool
    {
        return $this->client->indices()->exists(['index' => $index])->asBool();
    }
}
```

Run the command:

```bash
php artisan es:create-posts-index
```

You should see:

```
Index [posts] created successfully.
```

Verify the mapping was applied correctly by inspecting the index directly:

```bash
curl -s http://localhost:9200/posts/_mapping | python3 -m json.tool
```

The output should show the four properties with their types matching exactly what you defined. If you see `text` where you expected `keyword` or vice versa, run `php artisan es:create-posts-index --fresh` to drop and recreate the index.

## Step 5: Bulk-Index Existing Data {#step-5-bulk-index}

The index is now empty. You need a way to push all existing MySQL records into it. For small datasets you could do this one document at a time, but Elasticsearch's bulk API lets you send hundreds of documents in a single HTTP request, which is significantly more efficient.

```bash
php artisan make:command Elasticsearch/IndexPosts
```

Open `app/Console/Commands/Elasticsearch/IndexPosts.php`:

```php
<?php

namespace App\Console\Commands\Elasticsearch;

use App\Models\Post;
use Elastic\Elasticsearch\Client;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('es:index-posts')]
#[Description('Bulk-index all published posts into Elasticsearch')]
class IndexPosts extends Command
{
    public function __construct(private readonly Client $client)
    {
        parent::__construct();
    }

    public function handle(): int
    {
        $index    = config('elasticsearch.indices.posts');
        $total    = Post::whereNotNull('published_at')->count();
        $bar      = $this->output->createProgressBar($total);
        $indexed  = 0;

        // chunk() loads 200 posts at a time to avoid exhausting PHP memory
        Post::with('author')
            ->whereNotNull('published_at')
            ->chunk(200, function ($posts) use ($index, $bar, &$indexed) {
                $params = ['body' => []];

                foreach ($posts as $post) {
                    // Every bulk operation requires two lines:
                    // the action descriptor (what to do and where)...
                    $params['body'][] = [
                        'index' => [
                            '_index' => $index,
                            '_id'    => $post->id,
                        ],
                    ];

                    // ...followed immediately by the document body.
                    // published_at is cast to a Carbon instance on the model (see Post model).
                    // The null-safe operator handles the unlikely edge case of a null slipping through
                    // despite the whereNotNull() scope above.
                    $params['body'][] = [
                        'title'        => $post->title,
                        'body'         => $post->body,
                        'author_name'  => $post->author?->name ?? '',
                        'published_at' => $post->published_at?->toIso8601String(),
                    ];
                }

                // Send the entire chunk in one HTTP request
                $this->client->bulk($params);

                $indexed += count($posts);
                $bar->advance(count($posts));
            });

        $bar->finish();
        $this->newLine();
        $this->info("Indexed {$indexed} posts successfully.");

        return self::SUCCESS;
    }
}
```

You cannot run this yet because you have no data. You will run it in Step 9 after seeding. In Laravel 13, all commands in the `app/Console/Commands` directory are auto-discovered, so no manual registration in `app/Console/Kernel.php` is required.

## Step 6: Keep the Index in Sync with an Observer and Queued Jobs {#step-6-observer}

The bulk-index command handles existing data. But from this point forward, every new post created, every post updated, and every post deleted needs to be reflected in Elasticsearch automatically. The standard Laravel mechanism for this is a model Observer.

The Observer will not call Elasticsearch directly. Instead, it dispatches a queued job. This separation has two important benefits. First, if Elasticsearch is temporarily unavailable, the job stays in the queue and will be retried automatically. Second, the HTTP request to Elasticsearch happens in the background, so the user's request is not blocked waiting for it.

You need two jobs because an index operation and a delete operation need different data. An index job needs the full post content, so it re-fetches the model from MySQL. A delete job only needs the document ID, because by the time the job runs, the MySQL record may already be gone.

```bash
php artisan make:job IndexPostJob
php artisan make:job DeletePostJob
```

Open `app/Jobs/IndexPostJob.php`:

```php
<?php

namespace App\Jobs;

use App\Models\Post;
use Elastic\Elasticsearch\Client;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class IndexPostJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    // SerializesModels stores only the model's primary key in the serialized payload.
    // When the job runs, Laravel re-fetches the full model from MySQL.
    // This means the job always indexes the most up-to-date version of the post.
    public function __construct(private readonly Post $post) {}

    public function handle(Client $client): void
    {
        $client->index([
            'index' => config('elasticsearch.indices.posts'),
            'id'    => $this->post->id,
            'body'  => [
                'title'        => $this->post->title,
                'body'         => $this->post->body,
                // Null-safe: if the author was deleted between job dispatch and execution,
                // fall back to an empty string rather than crashing the job.
                'author_name'  => $this->post->author?->name ?? '',
                'published_at' => $this->post->published_at?->toIso8601String(),
            ],
        ]);
    }
}
```

Open `app/Jobs/DeletePostJob.php`:

```php
<?php

namespace App\Jobs;

use Elastic\Elasticsearch\Client;
use Elastic\Elasticsearch\Exception\ClientResponseException;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class DeletePostJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    // The job receives the post's integer ID, not the model.
    // This is intentional: when the "deleted" event fires, the MySQL record is already gone.
    // If we passed the model with SerializesModels, Laravel would try to re-fetch it
    // from the database and get a ModelNotFoundException.
    public function __construct(private readonly int $postId) {}

    public function handle(Client $client): void
    {
        try {
            $client->delete([
                'index' => config('elasticsearch.indices.posts'),
                'id'    => $this->postId,
            ]);
        } catch (ClientResponseException $e) {
            // A 404 means the document was never indexed in the first place.
            // This can happen if a draft post (which we do not index) is deleted.
            // It is not an error condition, so we swallow it silently.
            if ($e->getCode() !== 404) {
                throw $e;
            }
        }
    }
}
```

Now create the Observer:

```bash
php artisan make:observer PostObserver --model=Post
```

Open `app/Observers/PostObserver.php`:

```php
<?php

namespace App\Observers;

use App\Jobs\DeletePostJob;
use App\Jobs\IndexPostJob;
use App\Models\Post;

class PostObserver
{
    // The "saved" event fires after both create and update operations.
    // We only index posts that are published. If a published post is reverted
    // to a draft, the old document stays in the index until the next indexing cycle.
    // For production use, you would also dispatch a delete here when published_at is null.
    public function saved(Post $post): void
    {
        if ($post->published_at !== null) {
            IndexPostJob::dispatch($post);
        }
    }

    // The "deleted" event fires after the record has been removed from MySQL.
    // We pass only the ID, not the model, for the reason documented in DeletePostJob.
    public function deleted(Post $post): void
    {
        DeletePostJob::dispatch($post->id);
    }
}
```

Register the observer in `AppServiceProvider`. The `boot()` method is the right place for this because observers depend on models that need the application to be fully bootstrapped:

```php
<?php

namespace App\Providers;

use App\Models\Post;
use App\Observers\PostObserver;
use Elastic\Elasticsearch\Client;
use Elastic\Elasticsearch\ClientBuilder;
use Elastic\Elasticsearch\ClientInterface;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(Client::class, function () {
            return ClientBuilder::create()
                ->setHosts([config('elasticsearch.host')])
                ->build();
        });

        $this->app->bind(ClientInterface::class, Client::class);
    }

    public function boot(): void
    {
        // Registers the observer. From this point on, saving or deleting a Post
        // automatically dispatches the corresponding Elasticsearch sync job.
        Post::observe(PostObserver::class);
    }
}
```

## Step 7: Build the PostSearch Class {#step-7-search}

With the infrastructure in place, you can now focus on the actual search query. Rather than writing the Elasticsearch DSL inside a controller, you isolate it in a dedicated class. This makes the query testable, reusable, and easy to extend without touching controller logic.

Create the directory and the class:

```bash
mkdir -p app/Search
```

Create `app/Search/PostSearch.php`:

```php
<?php

namespace App\Search;

use Elastic\Elasticsearch\ClientInterface;

class PostSearch
{
    public function __construct(private readonly ClientInterface $client)
    {
    }

    /**
     * Search published posts by keyword.
     *
     * Returns an array of document IDs in relevance order (highest score first).
     * The caller is responsible for fetching the full Eloquent models using these IDs.
     *
     * @return string[]
     */
    public function search(string $query, int $size = 15): array
    {
        $response = $this->client->search([
            'index' => config('elasticsearch.indices.posts'),
            'body'  => [
                // Limit results to the requested page size
                'size'  => $size,
                'query' => [
                    // bool query combines multiple conditions.
                    // Conditions in "must" affect the relevance score.
                    // Conditions in "filter" do not affect score but exclude non-matching docs.
                    'bool' => [
                        'must' => [
                            [
                                // multi_match searches across multiple fields in one expression.
                                'multi_match' => [
                                    'query'     => $query,
                                    // title^2 boosts title matches: a hit in the title is
                                    // worth twice as much as a hit in the body.
                                    'fields'    => ['title^2', 'body'],
                                    // fuzziness AUTO: Elasticsearch calculates the allowed edit
                                    // distance based on term length.
                                    // "laravel" (7 chars) allows 2 character edits,
                                    // so "laravle" still matches.
                                    'fuzziness' => 'AUTO',
                                    // At least one of the query terms must match
                                    'operator'  => 'or',
                                ],
                            ],
                        ],
                        'filter' => [
                            [
                                // range filter: only include documents where published_at
                                // is in the past. "now" is a special Elasticsearch date math
                                // expression that resolves to the current UTC timestamp.
                                'range' => [
                                    'published_at' => [
                                        'lte' => 'now',
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ]);

        // Each hit has a "_id" field containing the MySQL primary key we stored during indexing.
        // array_column extracts all "_id" values into a flat array.
        return array_column($response['hits']['hits'], '_id');
    }
}
```

A key concept here is the difference between the `must` clause and the `filter` clause inside a `bool` query. The `must` clause runs in "query context": Elasticsearch scores each document by how well it matches and returns a `_score` value. The `filter` clause runs in "filter context": documents either pass or they do not, and there is no scoring calculation. Filters are also cached by Elasticsearch, which makes them significantly faster than equivalent query context conditions. The `published_at <= now` check belongs in a filter because it is a binary condition with no relevance meaning.

## Step 8: Wire the Search Into a Controller and View {#step-8-controller}

```bash
php artisan make:controller SearchController
```

Open `app/Http/Controllers/SearchController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use App\Search\PostSearch;
use Illuminate\Http\Request;
use Illuminate\View\View;

class SearchController extends Controller
{
    public function __construct(private readonly PostSearch $postSearch) {}

    public function index(Request $request): View
    {
        $query = $request->input('q', '');
        $posts = collect();

        if (filled($query)) {
            // Step 1: ask Elasticsearch for the IDs of matching documents, in relevance order
            $ids = $this->postSearch->search($query);

            if (!empty($ids)) {
                // Step 2: fetch full Eloquent models from MySQL using those IDs.
                // We re-order in PHP to preserve the relevance order Elasticsearch gave us,
                // because SQL's whereIn() does not guarantee ordering.
                $modelsById = Post::with('author')
                    ->whereIn('id', $ids)
                    ->get()
                    ->keyBy('id');

                $posts = collect($ids)
                    ->map(fn ($id) => $modelsById->get((int) $id))
                    ->filter(); // remove nulls for documents that no longer exist in MySQL
            }
        }

        return view('search.index', compact('posts', 'query'));
    }
}
```

Register the route in `routes/web.php`:

```php
use App\Http\Controllers\SearchController;

Route::get('/search', [SearchController::class, 'index'])->name('search.index');
```

Create the view directory and the template:

```bash
mkdir -p resources/views/search
```

Create `resources/views/search/index.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Search Posts</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
<div class="max-w-3xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">

    <h1 class="text-2xl font-bold text-gray-900 mb-6">Search Posts</h1>

    <form action="{{ route('search.index') }}" method="GET" class="mb-8">
        <div class="flex gap-3">
            <input
                type="text"
                name="q"
                value="{{ $query }}"
                placeholder="Search by title or content..."
                class="flex-1 border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                autofocus
            >
            <button
                type="submit"
                class="bg-blue-600 text-white px-5 py-2 rounded-lg hover:bg-blue-700 transition"
            >
                Search
            </button>
        </div>
    </form>

    @if(filled($query))
        <p class="text-sm text-gray-500 mb-4">
            {{ $posts->count() }} result(s) for <span class="font-medium text-gray-700">"{{ $query }}"</span>
        </p>
    @endif

    @forelse($posts as $post)
        <div class="border-b border-gray-200 py-5 last:border-0">
            <h2 class="text-lg font-semibold text-gray-900">{{ $post->title }}</h2>
            <p class="text-sm text-gray-400 mt-1">
                By {{ $post->author->name }}
                &middot;
                {{ $post->published_at->diffForHumans() }}
            </p>
            <p class="mt-2 text-gray-600 leading-relaxed">
                {{ Str::limit($post->body, 200) }}
            </p>
        </div>
    @empty
        @if(filled($query))
            <p class="text-gray-500 py-4">No posts found for "{{ $query }}".</p>
        @else
            <p class="text-gray-500 py-4">Enter a keyword above to search published posts.</p>
        @endif
    @endforelse

    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com"
           class="text-blue-600 hover:text-blue-800 hover:underline transition"
           target="_blank">Tutorial Elasticsearch at qadrlabs.com</a>
    </div>

</div>
</body>
</html>
```

## Step 9: Try It Out {#step-9-try-it-out}

Start the development server and a queue worker in separate terminals:

```bash
# Terminal 1
php artisan serve

# Terminal 2: processes queued jobs (Observer sync jobs go here)
php artisan queue:work
```

Open `php artisan tinker` in a third terminal and seed some posts:

```php
// Create a user
$user = \App\Models\User::factory()->create(['name' => 'Alice', 'email' => 'alice@example.com']);

// Create 20 published posts with realistic content
\App\Models\Post::factory(20)->published()->create(['user_id' => $user->id]);

// Create 5 drafts that should NOT appear in search results
\App\Models\Post::factory(5)->create(['user_id' => $user->id]);
```

Now run the bulk-index command to push all published posts into Elasticsearch:

```bash
php artisan es:index-posts
```

You should see:

```
 20/20 [============================] 100%
Indexed 20 posts successfully.
```

Open `http://localhost:8000/search` in your browser. Try three search scenarios to verify the behavior.

For an exact keyword, enter a word that appears in one of the post titles. You should see that post at the top of the results.

For fuzzy matching, try a misspelled version of a word you know is in a post, for example "laravle" instead of "laravel". Elasticsearch should still find the relevant posts because `fuzziness: AUTO` tolerates up to two character edits for terms of that length.

For draft exclusion, verify that the five drafts you created never appear in any search results regardless of what you search.

Now test the Observer sync. In Tinker, create a new published post and watch the queue worker terminal:

```php
$user = \App\Models\User::where(["name" => "Alice", "email" => "alice@example.com"])->first();

$post = \App\Models\Post::factory()->published()->create([
    'user_id' => $user->id,
    'title'   => 'A brand new post about Elasticsearch indexing',
    'body'    => 'This post was just created and should appear in search immediately.',
]);
```

In the queue worker terminal, you should see:

```
[2025-04-23 07:00:00][1] Processing: App\Jobs\IndexPostJob
[2025-04-23 07:00:00][1] Processed:  App\Jobs\IndexPostJob
```

Go back to the browser and search for "brand new". Your post should appear in the results without needing to run `es:index-posts` again.

## Step 10: Write the Tests {#step-10-tests}

The value of the `PostSearch` class is that it encapsulates the query DSL in a testable unit. By mocking the Elasticsearch client, tests can verify the query structure without needing a running Elasticsearch instance.

```bash
php artisan make:test Search/PostSearchTest --pest
```

Open `tests/Feature/Search/PostSearchTest.php` and replace its contents:

```php
<?php

use App\Search\PostSearch;
use Elastic\Elasticsearch\ClientInterface as Client;

// A helper that returns a mock Elasticsearch response shaped like the real API response.
// The real response is an Elasticsearch object implementing ArrayAccess,
// but a plain PHP array works identically in tests because PHP arrays
// support the same bracket-access syntax.
function fakeEsResponse(array $ids = []): array
{
    return [
        'hits' => [
            'total' => ['value' => count($ids)],
            'hits'  => array_map(fn ($id) => ['_id' => (string) $id], $ids),
        ],
    ];
}

it('calls the search API on the configured posts index', function () {
    $client = mock(Client::class);

    $client->shouldReceive('search')
        ->once()
        ->withArgs(fn (array $params) => $params['index'] === config('elasticsearch.indices.posts'))
        ->andReturn(fakeEsResponse([1, 2]));

    $search = new PostSearch($client);
    $search->search('laravel');
});

it('includes a multi_match query across title and body fields', function () {
    $client = mock(Client::class);

    $client->shouldReceive('search')
        ->once()
        ->withArgs(function (array $params) {
            $mustClause = $params['body']['query']['bool']['must'][0]['multi_match'] ?? null;

            return $mustClause !== null
                && in_array('title^2', $mustClause['fields'])
                && in_array('body', $mustClause['fields']);
        })
        ->andReturn(fakeEsResponse());

    (new PostSearch($client))->search('elasticsearch');
});

it('sets fuzziness to AUTO for typo tolerance', function () {
    $client = mock(Client::class);

    $client->shouldReceive('search')
        ->once()
        ->withArgs(function (array $params) {
            $multiMatch = $params['body']['query']['bool']['must'][0]['multi_match'] ?? null;

            return $multiMatch !== null && $multiMatch['fuzziness'] === 'AUTO';
        })
        ->andReturn(fakeEsResponse());

    (new PostSearch($client))->search('qurey');
});

it('applies a filter that restricts results to published posts', function () {
    $client = mock(Client::class);

    $client->shouldReceive('search')
        ->once()
        ->withArgs(function (array $params) {
            $filters = $params['body']['query']['bool']['filter'] ?? [];

            // Verify the filter contains a range on published_at with lte: now
            foreach ($filters as $filter) {
                if (isset($filter['range']['published_at']['lte'])
                    && $filter['range']['published_at']['lte'] === 'now') {
                    return true;
                }
            }

            return false;
        })
        ->andReturn(fakeEsResponse());

    (new PostSearch($client))->search('search term');
});

it('returns document ids extracted from the Elasticsearch response', function () {
    $client = mock(Client::class);

    $client->shouldReceive('search')
        ->andReturn(fakeEsResponse([7, 42, 3]));

    $ids = (new PostSearch($client))->search('laravel tips');

    // IDs come back as strings (Elasticsearch document IDs are always strings)
    expect($ids)->toBe(['7', '42', '3']);
});

it('respects the size parameter', function () {
    $client = mock(Client::class);

    $client->shouldReceive('search')
        ->once()
        ->withArgs(fn (array $params) => $params['body']['size'] === 5)
        ->andReturn(fakeEsResponse());

    (new PostSearch($client))->search('keyword', size: 5);
});
```

Save the file and run the test suite:

```bash
php artisan test --filter PostSearch
```

You should see:

```
   PASS  Tests\Feature\Search\PostSearchTest
  ✓ it calls the search API on the configured posts index
  ✓ it includes a multi_match query across title and body fields
  ✓ it sets fuzziness to AUTO for typo tolerance
  ✓ it applies a filter that restricts results to published posts
  ✓ it returns document ids extracted from the Elasticsearch response
  ✓ it respects the size parameter

  Tests:  6 passed (6 assertions)
  Duration: 0.16s
```

Notice that none of these tests needed a database connection, a running Elasticsearch instance, or any HTTP requests. They run entirely in memory and complete in under a third of a second. This is the direct benefit of isolating the query logic in a dedicated class and binding the client through the service container.

## How Elasticsearch Indexes Data {#how-elasticsearch-indexes}

Understanding why certain search behaviors work the way they do requires a basic mental model of how Elasticsearch stores and processes text.

When you index a document with a `text` field like `title`, Elasticsearch does not store the raw string and search through it later. It runs the string through an analysis pipeline first. The pipeline has three stages: character filters clean up the raw input (stripping HTML tags, for example); the tokenizer splits the cleaned text into individual terms (splitting "Quick Brown Fox" into three tokens); and token filters transform each token (lowercasing, removing stop words like "the" and "a", applying stemming so "running" becomes "run").

The result is an inverted index: a data structure that maps each term to the list of document IDs that contain it. When a user searches for "run", Elasticsearch looks up "run" in the inverted index and instantly retrieves the document IDs without scanning any documents at all. This is why search in Elasticsearch is fast even across millions of documents: the work is done at index time, not at query time.

The distinction between `text` and `keyword` field types comes from this pipeline. A `text` field is analyzed before storage, which makes it good for full-text search but unsuitable for exact matching or sorting, because "Quick Brown Fox" becomes three lowercase tokens. A `keyword` field skips the analysis pipeline entirely and stores the value as-is. You cannot do full-text search on a `keyword` field, but you can sort by it, filter with exact equality, and use it in aggregations.

The `english` analyzer you applied to the `body` field adds language-specific stemming on top of the standard tokenizer. This is why a search for "running" matches documents that contain "runs", "runner", or "ran": they all reduce to the same stem "run" during both indexing and query time.

## The Data Consistency Challenge {#data-consistency}

The mental model diagram in the Overview showed a clean, sequential flow from MySQL to Elasticsearch via a queue. In practice, this flow can break at any point, and the consequences are worth understanding before you ship this to production.

The fundamental problem is called the dual-write problem. When a post is saved, you write to two separate data stores: MySQL and the Elasticsearch index (via the queue). If MySQL succeeds but the Elasticsearch job fails permanently (after all retries are exhausted), the two stores are out of sync. MySQL has the updated post; Elasticsearch has the stale version. Users searching for the new content will not find it.

The queued Observer pattern in this tutorial mitigates the problem rather than eliminating it. If Elasticsearch is temporarily unavailable, the jobs remain in the database queue and will be retried when it comes back online. Laravel's built-in retry logic with exponential backoff handles most transient failures. You configure the retry behavior in each job class with the `$tries` and `$backoff` properties.

For applications where stale search results are acceptable (a blog, a documentation site, a content platform), the queued Observer is the right trade-off. The search index converges toward consistency within seconds of any write operation. For applications where any inconsistency is unacceptable (financial records, legal documents, anything where the search results have binding meaning), Elasticsearch is likely the wrong tool; a transactional database with proper full-text indexing is more appropriate.

If you need stronger guarantees, the next step up from the queued Observer is a Change Data Capture (CDC) approach using tools like Debezium or AWS DMS. CDC reads directly from the MySQL binary log, which means it captures every change regardless of how it was made (including raw SQL, migrations, and bulk inserts that bypass Eloquent). This is a meaningful infrastructure addition, and it is the subject of a separate, more advanced tutorial.

## When Elasticsearch is Overkill {#when-overkill}

Elasticsearch solves real problems, but it introduces significant operational complexity: a second datastore, a queue worker, Docker or a managed service, index management, and the consistency trade-offs described above. For many applications, this overhead is not justified.

MySQL's built-in FULLTEXT index with `MATCH ... AGAINST` queries handles English full-text search reasonably well for datasets in the tens of thousands of records. It supports natural language mode, boolean operators, and expansion queries. It does not support fuzzy matching or cross-field boosting, but those features matter most for consumer-facing search boxes, not internal admin tools or simple filtered lists.

PostgreSQL's `tsvector` and `tsquery` types are even more capable and support language-specific stemming, ranking, and efficient GIN indexing. If your application already uses PostgreSQL, you can get very far with its native full-text capabilities before introducing Elasticsearch.

Elasticsearch becomes the clear choice when your dataset approaches hundreds of thousands of records and full-table scans are measurably impacting response times, when you need typo tolerance and relevance ranking for a consumer-facing search interface, when you need to search across many fields with different weights, or when you want autocomplete suggestions, faceted filtering, or geospatial search.

A practical approach is to start with MySQL `LIKE` or `MATCH ... AGAINST`, measure the performance at your actual data scale, and introduce Elasticsearch only when the measurements show that the native capabilities are no longer sufficient. Premature optimization of the search layer is a common source of accidental complexity in Laravel applications that would have been fine with a database index and a two-line WHERE clause.

## Conclusion {#conclusion}

Full-text search in Laravel is not just a matter of swapping `LIKE` for a different query. It requires thinking about how data flows between two separate stores and what guarantees you need from that flow. Here is what this tutorial covered:

- **Elasticsearch as a search layer, not a primary database.** MySQL remains the source of truth. Elasticsearch receives a projected copy of each document and returns IDs. The controller fetches full Eloquent models from MySQL using those IDs, preserving relationships and data integrity.
- **Explicit index mappings prevent bad defaults.** Dynamic mapping guesses field types from incoming data. `text` vs `keyword`, `standard` vs `english` analyzer: these choices directly determine what queries will work and how accurate the results will be. Defining the mapping before indexing any data is always the right call.
- **Bulk indexing for existing data, Observer for ongoing sync.** The `es:index-posts` command handles the initial load efficiently using Elasticsearch's bulk API. The `PostObserver` dispatches queued jobs for every subsequent change, so the index stays current without any manual intervention.
- **Queued jobs protect against transient failures.** By dispatching `IndexPostJob` and `DeletePostJob` to the queue rather than calling Elasticsearch synchronously in the Observer, the integration is resilient to Elasticsearch downtime. Failed jobs are retried automatically, and the index converges toward consistency.
- **`PostSearch` isolates the DSL for testing.** Putting the query logic in a dedicated class rather than a controller method makes it possible to write fast, focused tests that verify query structure using a mocked client. No running Elasticsearch needed.
- **`filter` context vs `query` context matters for performance.** The `published_at <= now` condition belongs in a `bool.filter` clause, not in `must`. Filter clauses do not affect relevance scoring and are cached by Elasticsearch, making them substantially faster for binary inclusion/exclusion conditions.
- **Start simple and introduce Elasticsearch when measurements justify it.** MySQL full-text search is capable enough for many applications. The consistency trade-offs and operational overhead of Elasticsearch are worth accepting only when your actual data scale and search requirements demand it.