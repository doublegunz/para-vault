---
title: "CQRS in Laravel 13: Separate Your Read and Write Paths with Commands and Queries"
slug: "cqrs-in-laravel-13-separate-your-read-and-write-paths-with-commands-and-queries"
category: "Laravel"
date: "2026-06-17"
status: "draft"
---

A blog starts with one tidy `PostController`. It validates a request, updates a `Post`, and renders a list. Then the product grows. The listing page needs the author name, a short excerpt, and a comment count. The dashboard needs a different shape again. Before long, the same controller method and the same Eloquent model are bent in two directions at once: one set of changes is about writing data correctly, the other is about shaping data for the screen.

When reads and writes share a single path, every new display requirement leaks into your write logic, and every change to how you persist data risks breaking a report. A method that should express "publish this post" ends up tangled with `with()`, `withCount()`, and view-specific formatting. Tests touch everything, because everything touches everything. The code that changes state and the code that reads it have completely different reasons to change, yet they live in the same place.

CQRS, which stands for Command Query Responsibility Segregation, is the discipline of splitting those two responsibilities apart. Writes go through commands that express intent. Reads go through queries that return data already shaped for display. This article builds a small, pragmatic CQRS setup in Laravel 13 on a single database, with no event sourcing and no separate read store. It is the next step after our two earlier architecture articles: [Service Class, Action Class, and Use Case Class](https://qadrlabs.com/post/service-class-action-class-and-use-case-class-what-they-are-and-when-to-use-each-in-laravel) and [Implementing the Repository Pattern Without Over-Engineering](https://qadrlabs.com/post/implementing-the-repository-pattern-without-over-engineering-in-laravel). If those answered "where do I put my logic?", this one answers "should reading and writing even share the same path?".

## Overview {#overview}

Here is a clear picture of what you will build, learn, and need before starting. The demo is deliberately small so the pattern stays visible instead of being buried under feature code.

### What You'll Build

You will build a tiny blog where the write path and the read path never touch each other. Writes go through `CreatePostCommand` and `PublishPostCommand`, each handled by a dedicated handler. Reads go through `GetPublishedPostsQuery`, whose handler returns `PostListItem` read models that are shaped for a listing page. Both sides are dispatched through two small classes you will write yourself: a `CommandBus` and a `QueryBus` that resolve handlers from the container by naming convention.

### What You'll Learn

- What CQRS actually means, and why it does not require event sourcing or a second database
- How to model a write as a command object that carries intent, not just data
- How to write invokable handlers that hold the logic for one command or one query
- How to build a convention-based command bus and query bus on top of Laravel's service container
- How to design read models (DTOs) that are shaped for the screen instead of the table
- How to test the read and write paths in isolation, without booting the HTTP layer
- When CQRS earns its cost and when it is over-engineering

### What You'll Need

- Laravel 13 and PHP 8.3 or higher
- Composer and Artisan
- Pest for testing (installed with the project below)
- Comfort with Eloquent, controllers, and validation
- Ideally, the two prior articles in this series linked above

## Step 1: Create the Project {#step-1-create-the-project}

Every step in this build depends on the previous one, so the work is genuinely sequential. We start with a fresh project that already has SQLite and Pest wired up.

Create the project and move into it:

```bash
laravel new cqrs-demo --no-interaction --database=sqlite --pest --no-boost
cd cqrs-demo
```

The `--pest` flag installs Pest as the test runner, and `--database=sqlite` gives you a zero-config database file that Laravel migrates automatically on creation. There is nothing else to configure before you start writing code. With the project in place, we can model the domain it will operate on.

## Step 2: Create the Models and Migrations {#step-2-create-the-models-and-migrations}

The domain for this build is small: a `Post` that belongs to an author and can have many comments. We generate each model together with its migration and factory in one command, then fill in the details. The factories matter because the tests later lean on them to fabricate posts and comments.

Generate the `Post` and `Comment` models with their migrations and factories attached:

```bash
php artisan make:model Post -mf
php artisan make:model Comment -mf
```

Expected output:

```
   INFO  Model [app/Models/Post.php] created successfully.

   INFO  Factory [database/factories/PostFactory.php] created successfully.

   INFO  Migration [database/migrations/xxxx_xx_xx_xxxxxx_create_posts_table.php] created successfully.

   INFO  Model [app/Models/Comment.php] created successfully.

   INFO  Factory [database/factories/CommentFactory.php] created successfully.

   INFO  Migration [database/migrations/xxxx_xx_xx_xxxxxx_create_comments_table.php] created successfully.
```

The `-m` flag generates the matching migration and `-f` generates the factory, so a single command per model gives you the model class, an empty migration, and a stub factory ready to edit. Start with the `posts` migration. Open the generated file and describe the columns the write side needs: an author, a title, a body, and a nullable `published_at` timestamp that distinguishes a draft from a published post.

```php
<?php

// database/migrations/xxxx_xx_xx_xxxxxx_create_posts_table.php

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
            // A null published_at means the post is still a draft. Setting it
            // is the entire meaning of the "publish" intent later on.
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

Now open the `comments` migration so the read side has something to aggregate, and fill it in:

```php
<?php

// database/migrations/xxxx_xx_xx_xxxxxx_create_comments_table.php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('comments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('post_id')->constrained()->cascadeOnDelete();
            $table->string('body');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('comments');
    }
};
```

Now fill in the generated models. The `Post` model uses the Laravel 13 `#[Fillable]` attribute instead of the old `protected $fillable` property, and the `casts()` method to turn `published_at` into a `Carbon` instance:

```php
<?php

// app/Models/Post.php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['user_id', 'title', 'body', 'published_at'])]
class Post extends Model
{
    /** @use HasFactory<\Database\Factories\PostFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'published_at' => 'datetime',
        ];
    }

    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function comments(): HasMany
    {
        return $this->hasMany(Comment::class);
    }
}
```

The `Comment` model is intentionally minimal; it only needs to belong to a post:

```php
<?php

// app/Models/Comment.php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['post_id', 'body'])]
class Comment extends Model
{
    /** @use HasFactory<\Database\Factories\CommentFactory> */
    use HasFactory;

    public function post(): BelongsTo
    {
        return $this->belongsTo(Post::class);
    }
}
```

Fill in the generated factories next, because the tests in the final step build their data through them. The `PostFactory` produces a draft by default and exposes a `published()` state so a test can ask for a published post explicitly. Open `database/factories/PostFactory.php`:

```php
<?php

// database/factories/PostFactory.php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class PostFactory extends Factory
{
    public function definition(): array
    {
        return [
            // A fresh post belongs to a generated author and starts as a
            // draft. published_at stays null until the publish state is used.
            'user_id'      => User::factory(),
            'title'        => fake()->sentence(),
            'body'         => fake()->paragraphs(3, true),
            'published_at' => null,
        ];
    }

    // A named state for published posts. Calling Post::factory()->published()
    // stamps published_at, which is exactly what the read side filters on.
    public function published(): static
    {
        return $this->state(fn () => ['published_at' => now()]);
    }
}
```

The `definition()` method describes a sensible default row, and `published()` overrides only `published_at` when a test needs a live post. Now the `CommentFactory`, which just needs a body and a post to attach to. Open `database/factories/CommentFactory.php`:

```php
<?php

// database/factories/CommentFactory.php

namespace Database\Factories;

use App\Models\Post;
use Illuminate\Database\Eloquent\Factories\Factory;

class CommentFactory extends Factory
{
    public function definition(): array
    {
        return [
            // post_id defaults to a generated post, but tests usually pass an
            // explicit post_id to attach comments to a post they already made.
            'post_id' => Post::factory(),
            'body'    => fake()->sentence(),
        ];
    }
}
```

With the models, migrations, and factories in place, run the migration to create both tables:

```bash
php artisan migrate
```

Expected output:

```
   INFO  Running migrations.  

  2026_06_17_063754_create_posts_table .......................... 43.64ms DONE
  2026_06_17_063816_create_comments_table ....................... 19.29ms DONE
```

The domain now exists. Next we build the machinery that will carry commands and queries to their handlers.

## Step 3: Define the Command Bus and Query Bus {#step-3-define-the-command-bus-and-query-bus}

Before writing any commands, we need something to dispatch them. A bus is just a small object that takes a message (a command or a query), finds the right handler for it, and runs it. We will build both buses by hand so there is no magic to explain away later. The whole idea fits in a naming convention and one line of container resolution.

Start with two marker interfaces. They carry no methods; their only job is to let a bus type-hint against a single contract and to label a class as either a write instruction or a read request. Create `app/Cqrs/Command.php`:

```php
<?php

// app/Cqrs/Command.php

namespace App\Cqrs;

// Marker interface. Implementing it signals that a class is a write
// instruction meant to change state, and lets the CommandBus type-hint
// against a single contract instead of a loose object.
interface Command
{
}
```

And `app/Cqrs/Query.php`:

```php
<?php

// app/Cqrs/Query.php

namespace App\Cqrs;

// Marker interface for read requests. A Query never changes state; it
// only describes what the caller wants to read.
interface Query
{
}
```

Now the `CommandBus`. It receives a command, derives the handler class name from the command's class name, resolves that handler from Laravel's service container, and invokes it. Create `app/Cqrs/CommandBus.php`:

```php
<?php

// app/Cqrs/CommandBus.php

namespace App\Cqrs;

use Illuminate\Contracts\Container\Container;
use RuntimeException;

class CommandBus
{
    // The container is Laravel's service container. Resolving the handler
    // through it means the handler's own constructor dependencies (a
    // repository, a mailer, another action) are injected automatically.
    public function __construct(private readonly Container $container) {}

    public function dispatch(Command $command): mixed
    {
        $handlerClass = $this->handlerFor($command);

        if (! class_exists($handlerClass)) {
            throw new RuntimeException('No handler found for command: '.$command::class);
        }

        // make() builds the handler with its dependencies resolved.
        $handler = $this->container->make($handlerClass);

        // Every handler exposes a single __invoke() method, so the bus
        // does not need to know any method names.
        return $handler($command);
    }

    // Convention over configuration: CreatePostCommand is handled by
    // CreatePostHandler in the same namespace. No manual mapping to maintain.
    private function handlerFor(Command $command): string
    {
        return preg_replace('/Command$/', 'Handler', $command::class);
    }
}
```

The key line is `handlerFor()`. It takes the fully qualified class name, for example `App\Commands\CreatePostCommand`, and replaces the trailing `Command` with `Handler`, producing `App\Commands\CreatePostHandler`. The replacement is anchored to the end of the string with `$`, so the `Commands` namespace segment is left untouched. Because we resolve the handler through the container with `make()`, any dependency the handler type-hints in its constructor is injected for free. That is the entire reason to route through the container rather than calling `new` ourselves.

The `QueryBus` is the same idea with a different verb and a different suffix. Reads are not dispatched, they are asked. Create `app/Cqrs/QueryBus.php`:

```php
<?php

// app/Cqrs/QueryBus.php

namespace App\Cqrs;

use Illuminate\Contracts\Container\Container;
use RuntimeException;

class QueryBus
{
    public function __construct(private readonly Container $container) {}

    // ask() reads more naturally for queries than dispatch(). The mechanics
    // are identical to the CommandBus, but the intent at the call site is clear.
    public function ask(Query $query): mixed
    {
        $handlerClass = $this->handlerFor($query);

        if (! class_exists($handlerClass)) {
            throw new RuntimeException('No handler found for query: '.$query::class);
        }

        $handler = $this->container->make($handlerClass);

        return $handler($query);
    }

    // GetPublishedPostsQuery is handled by GetPublishedPostsHandler.
    private function handlerFor(Query $query): string
    {
        return preg_replace('/Query$/', 'Handler', $query::class);
    }
}
```

Both buses depend only on `Illuminate\Contracts\Container\Container`, which Laravel can resolve automatically, so there is no service provider binding to write. If you prefer not to maintain your own buses, Laravel ships a native command bus through the `Illuminate\Contracts\Bus\Dispatcher` contract and `Bus::dispatch()`, the same one queued jobs use. The hand-rolled version here keeps the mechanism in plain sight, which is the point of this article.

## Step 4: Build the Write Side with Commands and Handlers {#step-4-build-the-write-side}

With the bus in place, we can model the write path. A command is an immutable description of an intent to change state, and a handler is the one place that knows how to carry that intent out. Create the directory `app/Commands` and start with `CreatePostCommand`:

```php
<?php

// app/Commands/CreatePostCommand.php

namespace App\Commands;

use App\Cqrs\Command;

// A command is an immutable description of an intent to change state.
// readonly properties guarantee the data cannot be mutated between the
// moment the controller builds it and the moment the handler runs it.
final readonly class CreatePostCommand implements Command
{
    public function __construct(
        public int $authorId,
        public string $title,
        public string $body,
    ) {}
}
```

The command carries only the data needed to create a post, with named, typed properties. Because it is `readonly`, nothing can change its contents after the controller builds it, which makes it safe to pass around. Now the handler that acts on it:

```php
<?php

// app/Commands/CreatePostHandler.php

namespace App\Commands;

use App\Models\Post;

class CreatePostHandler
{
    // The handler holds the write logic. It receives the command, performs
    // the state change, and returns the new model. A freshly created post
    // is a draft, so published_at stays null.
    public function __invoke(CreatePostCommand $command): Post
    {
        return Post::create([
            'user_id'      => $command->authorId,
            'title'        => $command->title,
            'body'         => $command->body,
            'published_at' => null,
        ]);
    }
}
```

The handler is invokable, which is why the bus can call `$handler($command)` without knowing a method name. It does one thing: persist a draft post. Notice that "create" does not mean "publish"; a new post starts with `published_at` set to null.

Publishing is a separate intent, so it gets its own command. This is the heart of the write side in CQRS: instead of a generic `update` that could change anything, you name the operation after what the business actually does. Create `PublishPostCommand`:

```php
<?php

// app/Commands/PublishPostCommand.php

namespace App\Commands;

use App\Cqrs\Command;

// Publishing is a distinct business intent, not a generic "update". Naming
// the command after the intent keeps the write model expressive.
final readonly class PublishPostCommand implements Command
{
    public function __construct(
        public int $postId,
    ) {}
}
```

And its handler, which encapsulates exactly what "publish" means in this application: stamp the post with the current time once.

```php
<?php

// app/Commands/PublishPostHandler.php

namespace App\Commands;

use App\Models\Post;
use Illuminate\Support\Facades\Date;

class PublishPostHandler
{
    public function __invoke(PublishPostCommand $command): Post
    {
        $post = Post::findOrFail($command->postId);

        // The intent "publish" maps to setting the publish timestamp once.
        // The handler is the single place that knows what publishing means.
        $post->update([
            'published_at' => Date::now(),
        ]);

        return $post->refresh();
    }
}
```

If publishing later grows to dispatch a notification or clear a cache, that logic lives here, in the one handler responsible for the publish intent. Nothing on the read side has to know or change.

## Step 5: Build the Read Side with Queries and Read Models {#step-5-build-the-read-side}

The read side has a completely different job. It does not change anything; it produces data shaped for a screen. The most important idea in this step is that the read model is allowed to look nothing like the write model. The `posts` table stores a `user_id` and a full `body`; the listing page wants an author name and a short excerpt. CQRS lets you build exactly the shape the view needs without bending the `Post` model to serve it.

Start with the read model itself. Create `app/ReadModels/PostListItem.php`:

```php
<?php

// app/ReadModels/PostListItem.php

namespace App\ReadModels;

// A read model is shaped for the screen, not for the database table. It
// carries exactly the fields the listing needs: a short excerpt instead of
// the full body, the author's name instead of a foreign key, a formatted
// date, and a precomputed comment count. The write model never has to grow
// to serve these display concerns.
final readonly class PostListItem
{
    public function __construct(
        public int $id,
        public string $title,
        public string $excerpt,
        public string $authorName,
        public string $publishedAt,
        public int $commentCount,
    ) {}
}
```

This DTO is a plain, immutable value object. A Blade view or an API resource can read its properties directly, with no risk of triggering a lazy-loaded relationship or an unexpected query. Next, the query that asks for a list of published posts. It carries the parameters that define the read, which here is just a limit:

```php
<?php

// app/Queries/GetPublishedPostsQuery.php

namespace App\Queries;

use App\Cqrs\Query;

// A query carries the parameters that define what to read. Here it is just
// a page limit, but it could hold filters, sorting, or a search term.
final readonly class GetPublishedPostsQuery implements Query
{
    public function __construct(
        public int $limit = 10,
    ) {}
}
```

Now the handler that runs the read and maps the result into read models. Because this code is isolated on the read side, it is free to optimize for reading: it selects only the columns the screen needs, eager loads the author, and counts comments in a single aggregated query rather than triggering an N+1.

```php
<?php

// app/Queries/GetPublishedPostsHandler.php

namespace App\Queries;

use App\Models\Post;
use App\ReadModels\PostListItem;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class GetPublishedPostsHandler
{
    /**
     * @return Collection<int, PostListItem>
     */
    public function __invoke(GetPublishedPostsQuery $query): Collection
    {
        // The read query is free to be optimized independently of the write
        // model: it selects only the columns the screen needs, eager loads the
        // author, and counts comments in one aggregated query instead of N+1.
        return Post::query()
            ->whereNotNull('published_at')
            ->with('author:id,name')
            ->withCount('comments')
            ->latest('published_at')
            ->limit($query->limit)
            ->get(['id', 'user_id', 'title', 'body', 'published_at'])
            ->map(fn (Post $post) => new PostListItem(
                id:           $post->id,
                title:        $post->title,
                excerpt:      Str::limit($post->body, 80),
                authorName:   $post->author->name,
                publishedAt:  $post->published_at->format('M d, Y'),
                commentCount: $post->comments_count,
            ));
    }
}
```

The handler still uses Eloquent under the hood, which is exactly the pragmatic point: CQRS is about separating the read path from the write path, not about banning your ORM. The query returns a collection of `PostListItem` objects, so everything downstream works with a stable, display-ready shape instead of raw models.

## Step 6: Wire the Controller, Routes, and View {#step-6-wire-the-controller-routes-and-view}

Now we connect the buses to HTTP. The controller's only job is to translate between the outside world and the domain: turn a request into a command, or call a query and hand the result to a view. It never talks to Eloquent directly.

Because the write endpoints return JSON and should be stateless, expose them as API routes. Install API routing first:

```bash
php artisan install:api
```

Expected output:

```
   INFO  Running migrations.  

  2026_06_17_064202_create_personal_access_tokens_table ......... 14.69ms DONE


   INFO  API scaffolding installed. Please add the [Laravel\Sanctum\HasApiTokens] trait to your User model.
```

This creates `routes/api.php`. The Sanctum trait it mentions is only needed if you protect the endpoints with tokens; for this demo the write endpoints are open, so you can skip that note. Now create the controller:
```
php artisan make:controller PostController
```

Next, open the controller in the code editor and complete it so that it looks like the following lines of code.

```php
<?php

// app/Http/Controllers/PostController.php

namespace App\Http\Controllers;

use App\Commands\CreatePostCommand;
use App\Commands\PublishPostCommand;
use App\Cqrs\CommandBus;
use App\Cqrs\QueryBus;
use App\Queries\GetPublishedPostsQuery;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class PostController extends Controller
{
    // The buses are resolved from the container. The controller never talks
    // to Eloquent directly; it only translates HTTP into commands and queries.
    public function __construct(
        private readonly CommandBus $commands,
        private readonly QueryBus $queries,
    ) {}

    // The write path: build a command from the validated input and dispatch it.
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'author_id' => 'required|integer|exists:users,id',
            'title'     => 'required|string|max:255',
            'body'      => 'required|string',
        ]);

        $post = $this->commands->dispatch(new CreatePostCommand(
            authorId: $validated['author_id'],
            title:    $validated['title'],
            body:     $validated['body'],
        ));

        return response()->json(['id' => $post->id], 201);
    }

    // Another write path expressing a specific intent rather than a generic update.
    public function publish(int $post): JsonResponse
    {
        $this->commands->dispatch(new PublishPostCommand(postId: $post));

        return response()->json(['message' => 'Post published.']);
    }

    // The read path: ask a query and hand the read models straight to the view.
    public function index(): View
    {
        $posts = $this->queries->ask(new GetPublishedPostsQuery(limit: 10));

        return view('posts.index', ['posts' => $posts]);
    }
}
```

Notice how thin each method is. The controller validates, builds a command or query, and dispatches it. The decision of how to persist or how to read lives entirely in the handlers. Register the routes, with the read page on the web side and the write endpoints on the stateless API side:

```php
<?php

// routes/web.php

use App\Http\Controllers\PostController;
use Illuminate\Support\Facades\Route;

// The read side renders an HTML page from read models.
Route::get('/', [PostController::class, 'index']);
```

```php
<?php

// routes/api.php

use App\Http\Controllers\PostController;
use Illuminate\Support\Facades\Route;

// The write side is exposed as stateless API endpoints that dispatch commands.
Route::post('/posts', [PostController::class, 'store']);
Route::post('/posts/{post}/publish', [PostController::class, 'publish']);
```

Finally, the listing view. It iterates over `PostListItem` read models, reading their plain properties. There is no Eloquent in the template and no risk of an accidental query. Create `resources/views/posts/index.blade.php`:

```blade
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Published Posts</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold mb-6">Published Posts</h1>

        <div class="space-y-4">
            {{-- Each $post is a PostListItem read model, not an Eloquent
                 object. The view reads plain typed properties. --}}
            @forelse ($posts as $post)
                <article class="border border-gray-200 rounded-lg p-4">
                    <h2 class="text-lg font-semibold">{{ $post->title }}</h2>
                    <p class="text-gray-600 mt-1">{{ $post->excerpt }}</p>
                    <div class="text-sm text-gray-500 mt-3 flex justify-between">
                        <span>By {{ $post->authorName }} on {{ $post->publishedAt }}</span>
                        <span>{{ $post->commentCount }} comments</span>
                    </div>
                </article>
            @empty
                <p class="text-gray-500">No published posts yet.</p>
            @endforelse
        </div>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial CQRS in Laravel at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

The pieces are connected. The read page asks a query, the write endpoints dispatch commands, and neither knows anything about the other.

## Step 7: Try It Out {#step-7-try-it-out}

The cleanest way to see the two paths in action is to exercise the buses directly with Artisan Tinker. The same commands and queries run when you POST to the API endpoints or visit the page; Tinker just lets us watch the result without HTTP noise. Start a Tinker session for each snippet below with `php artisan tinker`.

First, create an author and dispatch `CreatePostCommand` through the `CommandBus`:

```php
use App\Models\User;
use App\Cqrs\CommandBus;
use App\Commands\CreatePostCommand;

$user = User::factory()->create(["name" => "Ada Lovelace"]);

$post = app(CommandBus::class)->dispatch(new CreatePostCommand(
    authorId: $user->id,
    title:    "Understanding CQRS in Laravel",
    body:     "CQRS separates the write path from the read path so each side can evolve on its own.",
));

echo "Created post #{$post->id}" . PHP_EOL;
echo "published_at: " . var_export($post->published_at, true) . PHP_EOL;
```

Output:

```
Created post #1
published_at: NULL
```

The post was created as a draft, exactly as the create handler intended. Now dispatch the publish intent through the same bus:

```php
use App\Cqrs\CommandBus;
use App\Commands\PublishPostCommand;

$post = app(CommandBus::class)->dispatch(new PublishPostCommand(postId: 1));

echo "Published post #{$post->id}" . PHP_EOL;
echo "published_at: " . $post->published_at->toDateTimeString() . PHP_EOL;
```

Output:

```
Published post #1
published_at: 2026-06-17 06:44:25
```

The bus found `PublishPostHandler` by convention and ran it; the post now has a publish timestamp. Add a couple of comments so the read model has something to count:

```php
App\Models\Comment::factory()->count(2)->create(["post_id" => 1]);
```

Now switch to the read side and ask `GetPublishedPostsQuery` through the `QueryBus`:

```php
use App\Cqrs\QueryBus;
use App\Queries\GetPublishedPostsQuery;

$items = app(QueryBus::class)->ask(new GetPublishedPostsQuery(limit: 10));

echo "Returned " . $items->count() . " item(s) of type " . $items->first()::class . PHP_EOL;
dump($items->first());
```

Output:

```
Returned 1 item(s) of type App\ReadModels\PostListItem
App\ReadModels\PostListItem {#7134
  +id: 1
  +title: "Understanding CQRS in Laravel"
  +excerpt: "CQRS separates the write path from the read path so each side can evolve on its..."
  +authorName: "Ada Lovelace"
  +publishedAt: "Jun 17, 2026"
  +commentCount: 2
}
```

This is the whole point in one screen of output. The write side accepted intents (`CreatePostCommand`, `PublishPostCommand`) and returned `Post` models. The read side returned a `PostListItem` with an excerpt, the author's name, a formatted date, and a comment count, none of which exist as columns on the `posts` table. Visit `/` in the browser and the listing page renders these same read models.

## Step 8: Test the Read and Write Paths {#step-8-test-the-read-and-write-paths}

Because both sides are plain PHP objects with no dependency on the HTTP layer, you can test them by instantiating handlers directly. That makes the tests fast and the failure messages precise. Create the test file `tests/Feature/CqrsTest.php`:

```php
<?php

use App\Commands\CreatePostCommand;
use App\Commands\CreatePostHandler;
use App\Commands\PublishPostCommand;
use App\Commands\PublishPostHandler;
use App\Cqrs\CommandBus;
use App\Cqrs\QueryBus;
use App\Models\Comment;
use App\Models\Post;
use App\Models\User;
use App\Queries\GetPublishedPostsHandler;
use App\Queries\GetPublishedPostsQuery;
use App\ReadModels\PostListItem;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('creates a draft post through the write handler', function () {
    $user = User::factory()->create();

    $post = (new CreatePostHandler())(new CreatePostCommand(
        authorId: $user->id,
        title: 'Hello CQRS',
        body: 'A first post.',
    ));

    expect($post)->toBeInstanceOf(Post::class)
        ->and($post->published_at)->toBeNull();

    $this->assertDatabaseHas('posts', ['title' => 'Hello CQRS']);
});

it('sets the publish timestamp through the publish handler', function () {
    $post = Post::factory()->create(['published_at' => null]);

    $published = (new PublishPostHandler())(new PublishPostCommand(postId: $post->id));

    expect($published->published_at)->not->toBeNull();
});

it('returns published posts as read models', function () {
    $post = Post::factory()->published()->create();
    Comment::factory()->count(2)->create(['post_id' => $post->id]);

    $items = (new GetPublishedPostsHandler())(new GetPublishedPostsQuery());

    expect($items)->toHaveCount(1)
        ->and($items->first())->toBeInstanceOf(PostListItem::class)
        ->and($items->first()->commentCount)->toBe(2);
});

it('excludes draft posts from the read side', function () {
    Post::factory()->published()->create();
    Post::factory()->create(['published_at' => null]);

    $items = (new GetPublishedPostsHandler())(new GetPublishedPostsQuery());

    expect($items)->toHaveCount(1);
});

it('resolves the command handler by convention through the command bus', function () {
    $user = User::factory()->create();

    $post = app(CommandBus::class)->dispatch(new CreatePostCommand(
        authorId: $user->id,
        title: 'Dispatched',
        body: 'Through the bus.',
    ));

    expect($post)->toBeInstanceOf(Post::class);
    $this->assertDatabaseHas('posts', ['title' => 'Dispatched']);
});

it('resolves the query handler by convention through the query bus', function () {
    Post::factory()->published()->create();

    $items = app(QueryBus::class)->ask(new GetPublishedPostsQuery());

    expect($items->first())->toBeInstanceOf(PostListItem::class);
});

it('lists only published posts on the home page', function () {
    Post::factory()->published()->create(['title' => 'Visible Post']);
    Post::factory()->create(['title' => 'Hidden Draft']);

    $this->get('/')
        ->assertOk()
        ->assertSee('Visible Post')
        ->assertDontSee('Hidden Draft');
});
```

These seven tests cover the full surface: the write handlers persist and publish correctly, the read handler returns read models and filters out drafts, both buses resolve the right handler by convention, and the home page renders only published posts. They rely on the `published()` state you already added to `PostFactory` back in Step 2, so there is nothing else to wire up.

Before running the suite, remove the two placeholder tests Laravel ships with a new project. The default `tests/Feature/ExampleTest.php` asserts that `/` returns `200`, but it does not refresh the database, so once the home page renders the listing it queries a `posts` table that does not exist in the test run and returns `500`. Deleting both example tests leaves only the suite you actually wrote:

```bash
rm tests/Feature/ExampleTest.php tests/Unit/ExampleTest.php
```

Now run the suite:

```bash
php artisan test
```

Expected output:

```
   PASS  Tests\Feature\CqrsTest
  ✓ it creates a draft post through the write handler                    0.18s  
  ✓ it sets the publish timestamp through the publish handler            0.02s  
  ✓ it returns published posts as read models                            0.03s  
  ✓ it excludes draft posts from the read side                           0.02s  
  ✓ it resolves the command handler by convention through the command b… 0.02s  
  ✓ it resolves the query handler by convention through the query bus    0.02s  
  ✓ it lists only published posts on the home page                       0.04s  

  Tests:    7 passed (14 assertions)
  Duration: 0.40s
```

Every path is verified without booting a controller in most of the tests, which is the practical payoff of moving logic out of the HTTP layer and into commands, queries, and handlers.

## Commands Express Intent, Queries Return Shape {#commands-vs-queries}

Now that the code is working, it is worth slowing down on the idea that makes CQRS more than just folder organization. A command and a query are asymmetric on purpose, and understanding that asymmetry is what stops you from rebuilding a fat controller with extra steps.

A command names an intent. `PublishPostCommand` is not "update the post and set a column"; it is "publish this post". The difference matters because the handler becomes the single, obvious home for everything publishing means. When the business later decides that publishing also notifies subscribers and clears a cache, you add that to `PublishPostHandler` and nothing else changes. A generic `update` method, by contrast, has no opinion about what it is doing, so that logic ends up scattered across controllers and observers. Commands also tend to return little: an id, the created model, or nothing at all. Their job is to change state, not to report on it.

A query returns shape. `GetPublishedPostsHandler` does not hand back `Post` models and hope the view figures out the rest; it returns `PostListItem` objects that already contain an excerpt, an author name, a formatted date, and a comment count. The read model is built for the screen that consumes it. This is why a single Eloquent model serving both reads and writes eventually feels stretched: the write side wants a faithful representation of the table, while the read side wants whatever the UI happens to need today. CQRS lets each side have what it wants. When a new dashboard needs a different shape, you add a new query and a new read model, and the write side never notices.

## How CQRS Relates to CRUD, Repositories, and Actions {#cqrs-vs-crud}

It helps to place CQRS next to patterns you already know, because it does not replace them so much as it splits them along a new axis. Plain CRUD treats create, read, update, and delete as four operations on one model through one path. That is perfectly fine for most screens, and you should not abandon it lightly. CQRS only changes one thing: it refuses to let reads and writes share that path once they start pulling in different directions.

The patterns from the earlier articles in this series still apply inside each side. A command handler can call an [Action class](https://qadrlabs.com/post/service-class-action-class-and-use-case-class-what-they-are-and-when-to-use-each-in-laravel) to do its work, or delegate persistence to a [repository](https://qadrlabs.com/post/implementing-the-repository-pattern-without-over-engineering-in-laravel) instead of touching Eloquent directly. A query handler can use a repository method tuned for reading. CQRS is the decision to draw a line down the middle between writing and reading; the Service, Action, Use Case, and Repository patterns are the tools you use on either side of that line. They compose rather than compete. You can adopt CQRS for one feature that genuinely has read and write asymmetry, and leave the rest of the application as ordinary controllers, exactly as you would adopt the repository pattern selectively.

## When CQRS Is Overkill {#when-overkill}

CQRS is a cost as much as a benefit, and pretending otherwise is how teams end up with a hundred tiny files for a CRUD app that never needed them. Every feature now means a command, a handler, possibly a query, a read model, and the buses to carry them. For a simple admin form where the read and the write are mirror images of each other, that ceremony buys you nothing. Reach for plain controllers and Eloquent there, and feel no guilt about it.

The pattern earns its keep when reads and writes genuinely diverge. Reporting and analytics screens that aggregate across tables, dashboards that need a dozen different shapes of the same data, or write operations that carry rich business rules and side effects are where the separation pays off. The clearer your write intents and the more varied your read shapes, the more a single shared model strains, and the more CQRS relieves that strain. It also opens a door you do not have to walk through today: once reads and writes are separated in code, scaling the read side onto a replica, a cache, or even a dedicated read store becomes a localized change rather than a rewrite. Event sourcing lives further down that same road, but it is a separate decision with its own heavy trade-offs, and you do not need it to get the value shown in this article.

## Conclusion {#conclusion}

CQRS is a small idea with a big payoff: stop forcing one model and one path to serve two jobs that change for different reasons. On a single database, with no event sourcing, you can separate the write path from the read path using nothing more than command objects, query objects, invokable handlers, and a thin bus built on Laravel's container.

- **CQRS means separating reads from writes, not adding infrastructure.** The valuable version runs on one database with plain Eloquent inside the handlers. Event sourcing and separate read stores are optional roads, not requirements.
- **Commands express intent.** `PublishPostCommand` says what the business does, which gives the matching handler a single, obvious home for everything that intent involves, now and later.
- **Queries return display-shaped read models.** `PostListItem` carries an excerpt, an author name, and a comment count that never exist as table columns, so the write model never has to grow to serve the screen.
- **The bus is just a naming convention plus the container.** Resolving `CreatePostCommand` to `CreatePostHandler` and building it with `make()` gives you automatic dependency injection and no mapping to maintain.
- **Test handlers directly, not controllers.** Because the logic lives in plain PHP objects, the suite instantiates handlers and asserts behavior without booting HTTP, which keeps tests fast and failures precise.
- **CQRS composes with the patterns you already use.** Repositories and Action classes live inside each side; CQRS only decides that reading and writing should not share a path once they diverge.
- **Reach for it only when asymmetry justifies the cost.** Simple CRUD does not need commands and queries. Reporting, aggregation, and rich write rules do, and that is exactly where the separation stops feeling like ceremony and starts saving you work.
