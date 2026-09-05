# Build an MCP Server in Laravel So AI Agents Can Query Your Content

You ask an AI assistant something about your own application and it has nothing to work with. So you paste. You copy a few article titles into the chat, add an excerpt or two, and hope you picked the right ones. The assistant answers confidently based on the slice you handed it, which is the only slice it will ever see.

That workaround falls apart quickly. The context goes stale the moment you paste it, because the assistant has no way to notice that you published three more articles yesterday. You become the search engine, which means the quality of every answer depends on how well you guessed which rows mattered. And nothing in that flow enforces a boundary, so the draft you were still editing is one careless copy away from being part of the conversation.

The Model Context Protocol fixes the shape of this problem. Instead of pasting data, you expose a small set of typed operations that an AI client can call on demand, and the client decides when to call them. Laravel now ships a first party package for this, `laravel/mcp`, so the server is just PHP classes in your application with your Eloquent models behind them. This tutorial builds the simplest useful version of that: a local, read only server that lets an agent search your articles, read one in full, and get a summary of the library, without ever seeing a draft.

## Overview {#overview}

The case study is a small Laravel application that stands in for a real content site. It has categories, articles, and a publication status, seeded with a dozen realistic entries so that searching actually returns something worth reading. On top of that sits an MCP server with three tools. You will run those tools by hand over the protocol first, so you can see exactly what an AI client sees, then connect Claude Code and watch a real agent chain the tools together to answer a question.

Everything here uses the local transport, which runs the server as a subprocess over standard input and output. That is the fastest way to get a working server and the right starting point. Putting the same server on an HTTP route behind Sanctum, and giving an agent tools that write rather than read, are natural follow ups once this one works.

### What You'll Build

- A Laravel 13 application with `categories` and `articles` tables, seeded with 10 published articles and 2 drafts across 4 categories.
- An MCP server class registered under the handle `qadrlabs`, exposing a name, a version, and instructions that tell the agent how to use it.
- Three read only tools: `search-articles`, `get-article`, and `content-stats`, each with a validated input schema.
- A Claude Code connection to that server, verified with a real conversation where the agent searches, picks a slug, and reads the article.
- A Pest suite of eight tests that lock in the tool names, the search behaviour, the validation caps, and the rule that drafts never leak.

### What You'll Learn

- How to install `laravel/mcp` and where the server registration lives.
- How a tool defines its input schema with the `JsonSchema` builder, and how that schema reaches the AI client.
- Why the tool name an agent sees is not always the one you expected, and how to pin it with attributes.
- How to talk to a local MCP server by hand with `printf` and `jq`, which is the fastest way to debug one.
- How `Response::text()` and `Response::error()` differ from the client's point of view.
- How to connect the server to Claude Code and confirm the agent is really calling your tools.
- How to test MCP tools with Pest without starting a server or a browser.

### What You'll Need

- PHP 8.3 or newer, the minimum for Laravel 13.
- Composer and the Laravel installer.
- `jq` for reading the protocol responses in the terminal. Any JSON formatter works, but the commands below use `jq`.
- Basic familiarity with Eloquent, migrations, and Pest. The [Pest tutorial](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application) covers the testing side if you need it.
- An MCP capable client for the last step. This article uses Claude Code, but any client that can launch a stdio server works.

Everything in this article was run against Laravel Framework 13.30.1 and `laravel/mcp` v0.9.4.

## Step 1: Create the Project and Install Laravel MCP {#step-1-create-the-project-and-install-laravel-mcp}

Start from a clean Laravel project on SQLite, so nothing here depends on a database server being installed. Pest comes along with the `--pest` flag and will be used in the last step.

```bash
laravel new mcp-demo --no-interaction --database=sqlite --pest --no-boost
cd mcp-demo
```

Confirm which framework version you landed on, since the MCP package tracks recent Laravel releases closely.

```bash
php artisan --version
```

```text
Laravel Framework 13.30.1
```

Now pull in the MCP package itself.

```bash
composer require laravel/mcp
```

`laravel/mcp` is the first party package maintained by the Laravel team. It handles the protocol layer, the transports, the artisan generators, and the test helpers, which leaves you writing nothing but the tool classes. Check what version Composer resolved.

```bash
composer show laravel/mcp
```

```text
name     : laravel/mcp
descrip. : Rapidly build MCP servers for your Laravel applications.
keywords : laravel, mcp
versions : * v0.9.4
```

The package registers its servers in a dedicated routes file that does not exist yet. Publish it.

```bash
php artisan vendor:publish --tag=ai-routes
```

```text
   INFO  Publishing [ai-routes] assets.  

  Copying file [vendor/laravel/mcp/routes/ai.php] to [routes/ai.php] .... DONE
```

That command creates `routes/ai.php`, which is where MCP servers get registered. It sits alongside `routes/web.php` and `routes/console.php` and follows the same idea: a small declarative file that maps an address to a handler. Open it and you will find a single commented line showing the web form of the registration, which we are not using yet.

```php
<?php

use Laravel\Mcp\Facades\Mcp;

// Mcp::web('/mcp/demo', \App\Mcp\Servers\PublicServer::class);
```

Leave it as it is for now. There is no server class to point it at until Step 3.

## Step 2: Model the Content the Agent Will Read {#step-2-model-the-content-the-agent-will-read}

An MCP server is only as interesting as the data behind it, so before writing any protocol code, build the content model. Two tables are enough: categories, and articles that belong to a category and carry a publication status. That status column is the entire security model of this tutorial, because it is what separates what the agent may see from what it may not.

Generate both models with their migrations and factories in one pass.

```bash
php artisan make:model Category -mf
php artisan make:model Article -mf
```

Open the categories migration and give it a name and a unique slug. The slug is what the agent will pass when it wants to filter a search, so it needs to be stable and predictable.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
```

The articles migration carries the fields a reader would expect plus the two that matter for access control, `status` and `published_at`.

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
            $table->foreignId('category_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->string('slug')->unique();
            $table->string('excerpt');
            $table->text('body');
            $table->string('status')->default('draft');
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('articles');
    }
};
```

Note that `status` defaults to `draft`. A new row is invisible to the agent until somebody deliberately publishes it, which is the safer default when an automated client is reading the table.

Now the models. `Category` needs the fillable attribute and the relationship back to its articles.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['name', 'slug'])]
class Category extends Model
{
    /** @use HasFactory<\Database\Factories\CategoryFactory> */
    use HasFactory;

    /**
     * The articles that belong to this category.
     *
     * @return \Illuminate\Database\Eloquent\Relations\HasMany<\App\Models\Article, $this>
     */
    public function articles(): HasMany
    {
        return $this->hasMany(Article::class);
    }
}
```

`Article` is where the important piece lives. The `published` scope is defined once here and every tool will go through it, so there is exactly one place in the codebase that decides what an AI client is allowed to read.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Scope;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['category_id', 'title', 'slug', 'excerpt', 'body', 'status', 'published_at'])]
class Article extends Model
{
    /** @use HasFactory<\Database\Factories\ArticleFactory> */
    use HasFactory;

    /**
     * The category this article belongs to.
     *
     * @return \Illuminate\Database\Eloquent\Relations\BelongsTo<\App\Models\Category, $this>
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * Limit the query to articles that are visible to the public.
     */
    #[Scope]
    protected function published(Builder $query): void
    {
        $query->where('status', 'published')->whereNotNull('published_at');
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'published_at' => 'datetime',
        ];
    }
}
```

The `#[Scope]` attribute is the Laravel 13 way of declaring a query scope. The method stays `protected` and Laravel exposes it as `Article::published()` on the query builder, which reads better than the old `scopePublished` naming convention and keeps the method out of the model's public surface.

Next, the factories. These are only used by the test suite in Step 8, but generating them now keeps the model work in one place.

```php
<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Category>
 */
class CategoryFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = $this->faker->unique()->word();

        return [
            'name' => Str::title($name),
            'slug' => Str::slug($name),
        ];
    }
}
```

```php
<?php

namespace Database\Factories;

use App\Models\Category;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

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
        $title = $this->faker->unique()->sentence(6);

        return [
            'category_id' => Category::factory(),
            'title' => $title,
            'slug' => Str::slug($title),
            'excerpt' => $this->faker->sentence(12),
            'body' => $this->faker->paragraphs(3, true),
            'status' => 'published',
            'published_at' => now()->subDays($this->faker->numberBetween(1, 365)),
        ];
    }

    /**
     * Indicate that the article is still a draft.
     */
    public function draft(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'draft',
            'published_at' => null,
        ]);
    }
}
```

Finally the seeder. Faker paragraphs would work, but search results built from lorem ipsum tell you nothing about whether the search tool is any good. Real sentences make every response in the rest of this article readable, so the seeder writes out twelve explicit articles across four categories, two of them left as drafts.

```php
<?php

namespace Database\Seeders;

use App\Models\Article;
use App\Models\Category;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the content the MCP server will expose.
     */
    public function run(): void
    {
        $categories = collect([
            'Laravel' => 'laravel',
            'PHP' => 'php',
            'DevOps' => 'devops',
            'Machine Learning' => 'machine-learning',
        ])->mapWithKeys(fn (string $slug, string $name) => [
            $slug => Category::create(['name' => $name, 'slug' => $slug]),
        ]);

        $articles = [
            ['laravel', 'Queue Batching in Laravel', 'queue-batching-in-laravel', 'Group jobs into a batch so you can track progress and react when every job finishes.', 'A batch wraps many jobs into one unit of work. Bus::batch() returns a Batch instance that reports pendingJobs, failedJobs, and a progress percentage, and the then, catch, and finally callbacks fire once for the whole batch instead of once per job.', 'published', '2026-03-11'],
            ['laravel', 'Testing Eloquent Relationships with Pest', 'testing-eloquent-relationships-with-pest', 'Write focused Pest tests that prove a relationship returns the rows you expect.', 'Relationship tests are cheap and they catch renamed foreign keys early. Build the parent with a factory, attach two children, and assert on the count and the returned ids rather than on the SQL.', 'published', '2026-04-02'],
            ['laravel', 'Cache Tags and When They Fail You', 'cache-tags-and-when-they-fail-you', 'Cache tags make group invalidation easy, until the driver you deploy on does not support them.', 'Tags work on Redis and Memcached and throw on the file and database drivers. If your local environment uses the file driver and production uses Redis, tagged cache calls pass every test and break on deploy.', 'published', '2026-05-20'],
            ['laravel', 'Form Requests Beyond Validation', 'form-requests-beyond-validation', 'A Form Request can authorize, prepare input, and shape error messages, not just validate it.', 'prepareForValidation lets you normalise input before the rules run, authorize keeps policy checks out of the controller, and passedValidation gives you a hook for derived values.', 'draft', null],
            ['php', 'Readonly Properties in PHP 8.2', 'readonly-properties-in-php-82', 'Readonly properties give you immutability without writing a getter for every field.', 'A readonly property can be written once from inside the declaring class scope and never again. It pairs well with constructor promotion, and it turns a whole class of accidental mutation bugs into a TypeError at the point of assignment.', 'published', '2026-01-15'],
            ['php', 'Enums as First Class Domain Types', 'enums-as-first-class-domain-types', 'Backed enums replace string constants and make invalid states unrepresentable.', 'A backed enum carries a scalar value, so it maps cleanly onto a database column while still giving you methods, interfaces, and exhaustive match arms.', 'published', '2026-02-08'],
            ['php', 'Composer Scripts Worth Adding', 'composer-scripts-worth-adding', 'A handful of composer scripts turn a long onboarding document into one command.', 'Scripts are the cheapest automation in a PHP project. A post-create-project-cmd that copies the env file and runs the migrations means a new developer types one command and gets a running app.', 'draft', null],
            ['devops', 'Zero Downtime Deploys with Symlinks', 'zero-downtime-deploys-with-symlinks', 'Build the new release beside the old one and flip a symlink when it is ready.', 'The trick is that a symlink swap is atomic. Requests in flight finish against the old release, and every request after the swap resolves the new one, so no user ever sees a half deployed directory.', 'published', '2026-03-28'],
            ['devops', 'Reading Nginx Access Logs Without Tears', 'reading-nginx-access-logs-without-tears', 'A few awk and sort pipelines answer most questions you would otherwise reach for a dashboard to answer.', 'Access logs are plain text, which means the standard Unix tools are already a query engine. Counting status codes per path takes one awk and one sort, and it runs in milliseconds on a log file.', 'published', '2026-06-14'],
            ['devops', 'Health Checks That Actually Check Health', 'health-checks-that-actually-check-health', 'An endpoint that returns 200 unconditionally is worse than no health check at all.', 'A useful health check touches the dependencies the request path touches: the database, the cache, and the queue connection. Anything less reports green while the app cannot serve a single real request.', 'published', '2026-07-01'],
            ['machine-learning', 'Train Test Split Without Leaking Data', 'train-test-split-without-leaking-data', 'Scaling before you split is the most common way to leak the test set into training.', 'Fit the scaler on the training fold only, then transform both folds with it. A Pipeline in scikit-learn enforces this ordering for you, which is why it belongs in every cross validation loop.', 'published', '2026-05-06'],
            ['machine-learning', 'Reading a Confusion Matrix', 'reading-a-confusion-matrix', 'Accuracy hides the errors that matter; the confusion matrix shows you which ones you are making.', 'On an imbalanced dataset a model that predicts the majority class every time can score 95 percent accuracy. The confusion matrix makes that failure obvious in one glance, and precision and recall put a number on it.', 'published', '2026-06-30'],
        ];

        foreach ($articles as [$category, $title, $slug, $excerpt, $body, $status, $publishedAt]) {
            Article::create([
                'category_id' => $categories[$category]->id,
                'title' => $title,
                'slug' => $slug,
                'excerpt' => $excerpt,
                'body' => $body,
                'status' => $status,
                'published_at' => $publishedAt,
            ]);
        }
    }
}
```

Run the migrations and the seeder together.

```bash
php artisan migrate:fresh --seed
```

```text
  Dropping all tables ............................................ 3.95ms DONE

   INFO  Preparing database.  

  Creating migration table ....................................... 5.73ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table .......................... 19.61ms DONE
  0001_01_01_000001_create_cache_table .......................... 12.26ms DONE
  0001_01_01_000002_create_jobs_table ........................... 20.59ms DONE
  2026_09_05_025640_create_categories_table ...................... 5.91ms DONE
  2026_09_05_025641_create_articles_table ....................... 11.12ms DONE


   INFO  Seeding database.
```

Confirm the split between published and draft rows with Tinker, since every tool you write from here depends on it.

```bash
echo 'App\Models\Article::published()->count() . " published of " . App\Models\Article::count() . " total in " . App\Models\Category::count() . " categories"' | php artisan tinker
```

```text
= "10 published of 12 total in 4 categories"
```

Ten of twelve articles are visible. Those two hidden drafts are the thing you will keep checking for the rest of the tutorial.

## Step 3: Generate the MCP Server and Register It {#step-3-generate-the-mcp-server-and-register-it}

A server in `laravel/mcp` is a class that describes itself and lists the tools it offers. It holds no logic of its own, which makes it a good place to start because you can register it, connect to it, and confirm the protocol handshake works before writing a single tool.

```bash
php artisan make:mcp-server ContentServer
```

```text
   INFO  Server [app/Mcp/Servers/ContentServer.php] created successfully.  
```

Open `app/Mcp/Servers/ContentServer.php` and fill in the three attributes. They are not decoration. The name and version go into the handshake response, and the instructions string is injected into the AI client's context as guidance about how to use this particular server.

```php
<?php

namespace App\Mcp\Servers;

use Laravel\Mcp\Server;
use Laravel\Mcp\Server\Attributes\Instructions;
use Laravel\Mcp\Server\Attributes\Name;
use Laravel\Mcp\Server\Attributes\Version;

#[Name('QadrLabs Content')]
#[Version('0.1.0')]
#[Instructions('Read-only access to the QadrLabs article library. Start with search-articles to find a slug, then call get-article with that slug to read the full text. Only published articles are visible; drafts are never returned. Use content-stats for an overview of the library.')]
class ContentServer extends Server
{
    protected array $tools = [
        //
    ];

    protected array $resources = [
        //
    ];

    protected array $prompts = [
        //
    ];
}
```

Write the instructions for a reader who has never seen your database. The one above tells the agent the intended order of operations, which stops it from guessing slugs, and it states the draft rule explicitly so the model does not waste turns asking for content it will never receive.

Now register the server. Replace the contents of `routes/ai.php`.

```php
<?php

use App\Mcp\Servers\ContentServer;
use Laravel\Mcp\Facades\Mcp;

Mcp::local('qadrlabs', ContentServer::class);
```

`Mcp::local()` registers the server under a handle rather than a URL. The handle is what you pass to the artisan commands, and it is what a client uses when it launches the server as a subprocess. The alternative, `Mcp::web()`, publishes the same server on an HTTP route instead, which is what you would reach for once the server needs to be available to something that is not on your machine.

Verify the registration by starting the server and speaking the protocol to it directly. An MCP client and server exchange newline delimited JSON-RPC messages, and for the local transport those messages travel over standard input and output, so `printf` and a pipe are a perfectly good client.

```bash
printf '%s\n' \
'{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"terminal","version":"1.0"}}}' \
| php artisan mcp:start qadrlabs
```

```text
{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2025-06-18","capabilities":{"tools":{"listChanged":false},"resources":{"listChanged":false},"prompts":{"listChanged":false}},"serverInfo":{"name":"QadrLabs Content","version":"0.1.0"},"instructions":"Read-only access to the QadrLabs article library. Start with search-articles to find a slug, then call get-article with that slug to read the full text. Only published articles are visible; drafts are never returned. Use content-stats for an overview of the library."}}
```

That single line is the entire handshake. The server reports which protocol version it speaks, which capabilities it has, the name and version from your attributes, and the instructions string. Every MCP client starts a session with exactly this exchange.

Asking for the tool list needs two more messages: the `notifications/initialized` acknowledgement that ends the handshake, and the `tools/list` request itself. Piping the response through `jq` keeps the output readable.

```bash
printf '%s\n' \
'{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"terminal","version":"1.0"}}}' \
'{"jsonrpc":"2.0","method":"notifications/initialized"}' \
'{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
| php artisan mcp:start qadrlabs \
| jq -r 'select(.id == 2) | .result.tools'
```

```text
[]
```

An empty array, which is correct: the server is registered and answering, and it has nothing to offer yet. That command is worth keeping in your shell history, because you will run it again after every tool you add.

## Step 4: Build the Search Articles Tool {#step-4-build-the-search-articles-tool}

The first tool is the entry point for everything else. An agent that wants to know something about your content has no slugs and no ids, only a question in natural language, so it needs a way to turn a keyword into a short list of candidates.

```bash
php artisan make:mcp-tool SearchArticlesTool
```

```text
   INFO  Tool [app/Mcp/Tools/SearchArticlesTool.php] created successfully.  
```

Open `app/Mcp/Tools/SearchArticlesTool.php` and write the whole thing.

```php
<?php

namespace App\Mcp\Tools;

use App\Models\Article;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\JsonSchema\Types\Type;
use Laravel\Mcp\Request;
use Laravel\Mcp\Response;
use Laravel\Mcp\Server\Attributes\Description;
use Laravel\Mcp\Server\Tool;

#[Description('Search published articles by keyword and return the matching titles, slugs, categories, and excerpts. Use the returned slug with the get-article tool to read the full body.')]
class SearchArticlesTool extends Tool
{
    /**
     * Handle the tool request.
     */
    public function handle(Request $request): Response
    {
        $validated = $request->validate([
            'query' => ['required', 'string', 'min:2', 'max:100'],
            'category' => ['nullable', 'string', 'max:50'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:20'],
        ]);

        $term = '%'.$validated['query'].'%';

        $articles = Article::query()
            ->published()
            ->with('category')
            ->when(
                $validated['category'] ?? null,
                fn (Builder $query, string $slug) => $query->whereHas(
                    'category',
                    fn (Builder $category) => $category->where('slug', $slug)
                )
            )
            ->where(fn (Builder $query) => $query
                ->where('title', 'like', $term)
                ->orWhere('excerpt', 'like', $term)
                ->orWhere('body', 'like', $term))
            ->orderByDesc('published_at')
            ->limit($validated['limit'] ?? 5)
            ->get();

        if ($articles->isEmpty()) {
            return Response::text("No published articles match \"{$validated['query']}\".");
        }

        $results = $articles->map(fn (Article $article) => implode("\n", [
            $article->title,
            "  slug: {$article->slug}",
            "  category: {$article->category->name}",
            "  published: {$article->published_at->toDateString()}",
            "  {$article->excerpt}",
        ]))->implode("\n\n");

        return Response::text(
            "Found {$articles->count()} published article(s) for \"{$validated['query']}\":\n\n".$results
        );
    }

    /**
     * Get the tool's input schema.
     *
     * @return array<string, Type>
     */
    public function schema(JsonSchema $schema): array
    {
        return [
            'query' => $schema->string()
                ->description('The keyword to look for in the title, excerpt, and body.')
                ->required(),
            'category' => $schema->string()
                ->description('Optional category slug to narrow the search: laravel, php, devops, or machine-learning.'),
            'limit' => $schema->integer()
                ->description('How many articles to return. Defaults to 5, never more than 20.')
                ->min(1)
                ->max(20)
                ->default(5),
        ];
    }
}
```

There are four things worth pausing on here.

The `schema()` method is the tool's public contract. Every `description()` you write ends up in the AI client's context, so it is prompt text, not a code comment. Telling the model which category slugs exist is what stops it from inventing `ml` or `dev-ops` and getting an empty result.

The `$request->validate()` call is ordinary Laravel validation, and it runs on data the model produced. The schema is advisory; a model can and will send a `limit` of 50 if it decides that is a good idea, so the cap has to be enforced in PHP, not just described in JSON.

The query goes through `->published()` before anything else, so the draft rule is applied first and every later clause can only narrow the result further. There is no code path in this tool that can reach an unpublished row.

The response is plain text rather than JSON. A model reads text perfectly well, and formatting each result with a labelled `slug:` line makes the next call obvious: the agent copies the slug straight into `get-article`.

Register the tool in the server's `$tools` array.

```php
    protected array $tools = [
        SearchArticlesTool::class,
    ];
```

Add the matching import at the top of `ContentServer.php`, then list the tools again.

```bash
printf '%s\n' \
'{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"terminal","version":"1.0"}}}' \
'{"jsonrpc":"2.0","method":"notifications/initialized"}' \
'{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
| php artisan mcp:start qadrlabs \
| jq -r 'select(.id == 2) | .result.tools[] | {name, title}'
```

```text
{
  "name": "search-articles-tool",
  "title": "Search Articles Tool"
}
```

The tool works, but the name is not the one the description promised. `laravel/mcp` v0.9.4 derives the name from the full class name, and it does not strip the `Tool` suffix, so `SearchArticlesTool` becomes `search-articles-tool`. That matters more than it looks: the name is the identifier the model types when it calls the tool, and it is the name you will write in your instructions, your tests, and your client configuration. Pin it explicitly rather than depending on a derivation rule.

Add two attributes above the class and the matching imports.

```php
use Laravel\Mcp\Server\Attributes\Description;
use Laravel\Mcp\Server\Attributes\Name;
use Laravel\Mcp\Server\Attributes\Title;
use Laravel\Mcp\Server\Tool;

#[Name('search-articles')]
#[Title('Search Articles')]
#[Description('Search published articles by keyword and return the matching titles, slugs, categories, and excerpts. Use the returned slug with the get-article tool to read the full body.')]
class SearchArticlesTool extends Tool
```

`#[Name]` sets the machine identifier and `#[Title]` sets the human readable label a client shows in its UI. Run the same listing command again.

```text
{
  "name": "search-articles",
  "title": "Search Articles"
}
```

Now call it. A `tools/call` request names the tool and passes its arguments, and the text the tool returned comes back inside `result.content[0].text`. Since you are about to make a lot of these calls, define a shell function that wraps the handshake and pulls that text out.

```bash
mcp() {
  printf '%s\n' \
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"terminal","version":"1.0"}}}' \
    '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
    "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"$1\",\"arguments\":$2}}" \
  | php artisan mcp:start qadrlabs \
  | jq -r 'select(.id == 2) | .result.content[0].text'
}
```

The function takes a tool name and a JSON arguments object, sends the same three message handshake you have been typing by hand, and prints only the text the tool produced. Paste it into your shell and try the search.

```bash
mcp search-articles '{"query":"cache"}'
```

```text
Found 2 published article(s) for "cache":

Health Checks That Actually Check Health
  slug: health-checks-that-actually-check-health
  category: DevOps
  published: 2026-07-01
  An endpoint that returns 200 unconditionally is worse than no health check at all.

Cache Tags and When They Fail You
  slug: cache-tags-and-when-they-fail-you
  category: Laravel
  published: 2026-05-20
  Cache tags make group invalidation easy, until the driver you deploy on does not support them.
```

Two hits, sorted newest first, each carrying the slug the agent will need next. The health checks article matched on the word cache in its body rather than its title, which is exactly what you want a keyword search to do.

Check the category filter and the limit by passing more arguments.

```bash
mcp search-articles '{"query":"the","category":"devops","limit":2}'
```

```text
Found 2 published article(s) for "the":

Health Checks That Actually Check Health
  slug: health-checks-that-actually-check-health
  category: DevOps
  published: 2026-07-01
  An endpoint that returns 200 unconditionally is worse than no health check at all.

Reading Nginx Access Logs Without Tears
  slug: reading-nginx-access-logs-without-tears
  category: DevOps
  published: 2026-06-14
  A few awk and sort pipelines answer most questions you would otherwise reach for a dashboard to answer.
```

Three DevOps articles contain the word "the", but the limit of 2 cut the list short. Now try the case this whole tutorial is built around, a search for a phrase that only appears in a draft.

```bash
mcp search-articles '{"query":"Form Requests"}'
```

```text
No published articles match "Form Requests".
```

"Form Requests Beyond Validation" is sitting in the database with that exact title, and the tool reports nothing. The scope did its job.

Finally, push past the cap to confirm validation is enforced rather than merely documented.

```bash
mcp search-articles '{"query":"cache","limit":50}'
```

```text
The limit field must not be greater than 20.
```

The validation exception is converted into a tool error automatically, and the model receives the message as text it can act on, usually by retrying with a smaller number.

## Step 5: Build the Get Article Tool {#step-5-build-the-get-article-tool}

Search deliberately returns excerpts rather than full bodies, because sending a dozen complete articles into a model's context to answer one question is wasteful. The second tool is the follow up: given a slug, return one article in full.

```bash
php artisan make:mcp-tool GetArticleTool
```

Write the class with the naming attributes in place from the start.

```php
<?php

namespace App\Mcp\Tools;

use App\Models\Article;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Illuminate\JsonSchema\Types\Type;
use Laravel\Mcp\Request;
use Laravel\Mcp\Response;
use Laravel\Mcp\Server\Attributes\Description;
use Laravel\Mcp\Server\Attributes\Name;
use Laravel\Mcp\Server\Attributes\Title;
use Laravel\Mcp\Server\Tool;

#[Name('get-article')]
#[Title('Get Article')]
#[Description('Read one published article in full by its slug. Returns the title, category, publication date, and the complete body.')]
class GetArticleTool extends Tool
{
    /**
     * Handle the tool request.
     */
    public function handle(Request $request): Response
    {
        $validated = $request->validate([
            'slug' => ['required', 'string', 'max:255'],
        ]);

        $article = Article::query()
            ->published()
            ->with('category')
            ->where('slug', $validated['slug'])
            ->first();

        if ($article === null) {
            return Response::error(
                "No published article exists with the slug \"{$validated['slug']}\". Use the search-articles tool to find a valid slug."
            );
        }

        return Response::text(implode("\n", [
            $article->title,
            "category: {$article->category->name}",
            "published: {$article->published_at->toDateString()}",
            '',
            $article->body,
        ]));
    }

    /**
     * Get the tool's input schema.
     *
     * @return array<string, Type>
     */
    public function schema(JsonSchema $schema): array
    {
        return [
            'slug' => $schema->string()
                ->description('The slug of the article to read, as returned by the search-articles tool.')
                ->required(),
        ];
    }
}
```

The interesting decision is `Response::error()` instead of `Response::text()` for the miss. Both send text back to the client, but an error response carries `isError: true`, which tells the model that the call did not succeed rather than that the answer is "nothing". Without that flag a model will sometimes report your error message to the user as if it were content.

The error message itself is written for the model, not for a log file. It names the tool to try next, which turns a dead end into a recoverable step.

Notice also that a draft slug and a slug that does not exist produce the same response. That is deliberate. Returning "this article exists but you may not read it" would tell an outside caller that a draft with that exact slug is sitting in your database, which is information you did not intend to publish.

Register the tool alongside the first one.

```php
    protected array $tools = [
        SearchArticlesTool::class,
        GetArticleTool::class,
    ];
```

Read one of the articles the search step turned up.

```bash
mcp get-article '{"slug":"zero-downtime-deploys-with-symlinks"}'
```

```text
Zero Downtime Deploys with Symlinks
category: DevOps
published: 2026-03-28

The trick is that a symlink swap is atomic. Requests in flight finish against the old release, and every request after the swap resolves the new one, so no user ever sees a half deployed directory.
```

Then ask for the draft by its real slug, taken straight from the seeder.

```bash
mcp get-article '{"slug":"form-requests-beyond-validation"}'
```

```text
No published article exists with the slug "form-requests-beyond-validation". Use the search-articles tool to find a valid slug.
```

Even with a perfectly valid slug in hand, the tool refuses. The boundary is in the query, not in the search index.

## Step 6: Build the Content Stats Tool {#step-6-build-the-content-stats-tool}

The last tool answers a different kind of question. Search and read are per article; sometimes an agent needs to know the shape of the whole library before deciding what to search for, and asking it to page through every row to count them would burn a lot of tokens for a number the database already knows.

```bash
php artisan make:mcp-tool ContentStatsTool
```

```php
<?php

namespace App\Mcp\Tools;

use App\Models\Article;
use App\Models\Category;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Illuminate\JsonSchema\Types\Type;
use Laravel\Mcp\Request;
use Laravel\Mcp\Response;
use Laravel\Mcp\Server\Attributes\Description;
use Laravel\Mcp\Server\Attributes\Name;
use Laravel\Mcp\Server\Attributes\Title;
use Laravel\Mcp\Server\Tool;

#[Name('content-stats')]
#[Title('Content Stats')]
#[Description('Summarise the content library: how many articles are published, how many are still drafts, and how the published ones are spread across categories.')]
class ContentStatsTool extends Tool
{
    /**
     * Handle the tool request.
     */
    public function handle(Request $request): Response
    {
        $published = Article::query()->published()->count();
        $drafts = Article::query()->count() - $published;

        $perCategory = Category::query()
            ->withCount(['articles as published_count' => fn ($query) => $query->published()])
            ->orderByDesc('published_count')
            ->get()
            ->map(fn (Category $category) => "  {$category->name}: {$category->published_count}")
            ->implode("\n");

        return Response::text(implode("\n", [
            "Published articles: {$published}",
            "Draft articles: {$drafts}",
            '',
            'Published per category:',
            $perCategory,
        ]));
    }

    /**
     * Get the tool's input schema.
     *
     * @return array<string, Type>
     */
    public function schema(JsonSchema $schema): array
    {
        return [];
    }
}
```

An empty `schema()` array is how you declare a tool that takes no arguments. The client still sends an `arguments` object, it is just empty, and there is nothing to validate.

This tool reports a draft count, which is a judgement call rather than a leak. A number tells the agent that unpublished work exists so it can say "you have two drafts" instead of pretending the library is complete, and a count reveals no titles, no slugs, and no text. If even that is more than you want to share, delete the line.

Add it to the server, which now holds all three tools.

```php
<?php

namespace App\Mcp\Servers;

use App\Mcp\Tools\ContentStatsTool;
use App\Mcp\Tools\GetArticleTool;
use App\Mcp\Tools\SearchArticlesTool;
use Laravel\Mcp\Server;
use Laravel\Mcp\Server\Attributes\Instructions;
use Laravel\Mcp\Server\Attributes\Name;
use Laravel\Mcp\Server\Attributes\Version;

#[Name('QadrLabs Content')]
#[Version('0.1.0')]
#[Instructions('Read-only access to the QadrLabs article library. Start with search-articles to find a slug, then call get-article with that slug to read the full text. Only published articles are visible; drafts are never returned. Use content-stats for an overview of the library.')]
class ContentServer extends Server
{
    protected array $tools = [
        SearchArticlesTool::class,
        GetArticleTool::class,
        ContentStatsTool::class,
    ];

    protected array $resources = [
        //
    ];

    protected array $prompts = [
        //
    ];
}
```

Call the new tool.

```bash
mcp content-stats '{}'
```

```text
Published articles: 10
Draft articles: 2

Published per category:
  Laravel: 3
  DevOps: 3
  PHP: 2
  Machine Learning: 2
```

Those are the same numbers Tinker reported back in Step 2, which means the tool and the seeder agree. List the tools one more time to see the finished surface.

```bash
printf '%s\n' \
'{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"terminal","version":"1.0"}}}' \
'{"jsonrpc":"2.0","method":"notifications/initialized"}' \
'{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
| php artisan mcp:start qadrlabs \
| jq -r 'select(.id == 2) | .result.tools[].name'
```

```text
search-articles
get-article
content-stats
```

It is also worth looking at one full tool definition, because this JSON is precisely what the model is given when it decides whether to call your tool. Run the same listing command again with the final `jq` filter changed to pick out the first tool in full.

```bash
jq -r 'select(.id == 2) | .result.tools[0]'
```

```text
{
  "name": "search-articles",
  "title": "Search Articles",
  "description": "Search published articles by keyword and return the matching titles, slugs, categories, and excerpts. Use the returned slug with the get-article tool to read the full body.",
  "inputSchema": {
    "properties": {
      "query": {
        "description": "The keyword to look for in the title, excerpt, and body.",
        "type": "string"
      },
      "category": {
        "description": "Optional category slug to narrow the search: laravel, php, devops, or machine-learning.",
        "type": "string"
      },
      "limit": {
        "description": "How many articles to return. Defaults to 5, never more than 20.",
        "default": 5,
        "minimum": 1,
        "maximum": 20,
        "type": "integer"
      }
    },
    "type": "object",
    "required": [
      "query"
    ]
  },
  "annotations": {}
}
```

Every `->description()` and `->min()` you wrote in PHP shows up here as JSON Schema. The Laravel builder is a typed front end for a document that gets handed to a language model.

## Step 7: Try It Out with Claude Code {#step-7-try-it-out-with-claude-code}

Piping JSON by hand proves the server works. Connecting a real client proves it is usable, which is a different question: it depends on whether the model can figure out your tools from their names and descriptions alone.

Register the server with Claude Code from inside the project directory.

```bash
claude mcp add qadrlabs -- php artisan mcp:start qadrlabs
```

```text
Added stdio MCP server qadrlabs with command: php artisan mcp:start qadrlabs to local config
```

Everything after `--` is the command Claude Code will run to launch the server, which is why it matches the artisan command you have been using all along. The client starts that process, performs the handshake over its standard input and output, and shuts it down when the session ends. There is no port, no URL, and no daemon to keep alive.

Confirm the connection.

```bash
claude mcp get qadrlabs
```

```text
qadrlabs:
  Scope: Local config (private to you in this project)
  Status: ✔ Connected
  Type: stdio
  Command: php8.5
  Args: artisan mcp:start qadrlabs
  Environment:

To remove this server, run: claude mcp remove qadrlabs -s local
```

The default local scope keeps the registration private to this project on this machine. Adding `--scope project` instead writes a `.mcp.json` file in the project root that you can commit, which is how you share a server with a team; each teammate is prompted to approve it the first time they run Claude Code there.

Now ask a question that cannot be answered without the tools.

```bash
claude -p "Use the qadrlabs MCP server. Which published articles mention deploys, and what is the main idea of the one about zero downtime? Answer in plain prose, no markdown formatting and no dashes."
```

```text
Two published articles mention deploys. One is "Zero Downtime Deploys with Symlinks" in the DevOps category, published 28 March 2026, and the other is "Cache Tags and When They Fail You" in the Laravel category, published 20 May 2026, where the mention is incidental since it talks about cache tags breaking when the driver you deploy on does not support them.

The main idea of the zero downtime article is that swapping a symlink is an atomic operation, so you build the new release in its own directory alongside the current one and only flip the symlink once it is fully ready. Requests already in flight keep finishing against the old release, every request arriving after the flip resolves to the new one, and no user ever hits a partially deployed directory.
```

Read that answer closely. It contains a publication date, a category name, and a distinction between an article that is about deploys and one that merely mentions the word, none of which was in the question. The model got all of it from your database.

To see the calls behind it rather than the prose, ask for the structured stream and filter it down to the tool invocations.

```bash
claude -p "Use the qadrlabs MCP server. Which published articles mention deploys, and what is the main idea of the one about zero downtime?" \
  --verbose --output-format stream-json \
  | jq -r 'select(.type == "assistant") | .message.content[] | select(.type == "tool_use") | "\(.name) \(.input)"'
```

```text
mcp__qadrlabs__search-articles {"query": "deploy", "limit": 20}
mcp__qadrlabs__get-article {"slug": "zero-downtime-deploys-with-symlinks"}
```

Two calls, in the order the server's instructions asked for. The agent searched for a keyword, read the slug out of the result, and passed it to the second tool without being told the slug existed. That handoff is the payoff for formatting the search output with a labelled `slug:` line and for describing each tool in terms of the other.

The `mcp__qadrlabs__` prefix is how Claude Code namespaces tools from an MCP server, combining the handle you registered with the tool's own name. That prefix is another reason the `#[Name]` attribute matters: `mcp__qadrlabs__search-articles` is what you will type when allowing or denying individual tools.

## Step 8: Cover the Tools with Pest {#step-8-cover-the-tools-with-pest}

The manual pipes and the Claude Code session are how you explore a server. They are not how you keep it correct. `laravel/mcp` ships test helpers that call a tool directly through the server, with no process, no transport, and no client, so a full tool test runs in milliseconds.

First, enable `RefreshDatabase` in `tests/Pest.php`, which is commented out in a fresh Laravel project.

```php
pest()->extend(TestCase::class)
    ->use(RefreshDatabase::class)
    ->in('Feature');
```

Now create `tests/Feature/ContentServerTest.php`. The `beforeEach` block builds a tiny, fully known dataset: two published articles in different categories and one draft. Small explicit fixtures beat factories here, because most of these assertions are about exact strings.

```php
<?php

use App\Mcp\Servers\ContentServer;
use App\Mcp\Tools\ContentStatsTool;
use App\Mcp\Tools\GetArticleTool;
use App\Mcp\Tools\SearchArticlesTool;
use App\Models\Article;
use App\Models\Category;

beforeEach(function () {
    $this->laravel = Category::create(['name' => 'Laravel', 'slug' => 'laravel']);
    $this->devops = Category::create(['name' => 'DevOps', 'slug' => 'devops']);

    Article::create([
        'category_id' => $this->laravel->id,
        'title' => 'Cache Tags and When They Fail You',
        'slug' => 'cache-tags-and-when-they-fail-you',
        'excerpt' => 'Cache tags make group invalidation easy.',
        'body' => 'Tags work on Redis and Memcached and throw on the file driver.',
        'status' => 'published',
        'published_at' => '2026-05-20',
    ]);

    Article::create([
        'category_id' => $this->devops->id,
        'title' => 'Zero Downtime Deploys with Symlinks',
        'slug' => 'zero-downtime-deploys-with-symlinks',
        'excerpt' => 'Build the new release beside the old one.',
        'body' => 'A symlink swap is atomic.',
        'status' => 'published',
        'published_at' => '2026-03-28',
    ]);

    Article::create([
        'category_id' => $this->laravel->id,
        'title' => 'Form Requests Beyond Validation',
        'slug' => 'form-requests-beyond-validation',
        'excerpt' => 'A Form Request can do more than validate.',
        'body' => 'prepareForValidation runs before the rules.',
        'status' => 'draft',
        'published_at' => null,
    ]);
});

it('exposes the search tool under a stable name', function () {
    ContentServer::tool(SearchArticlesTool::class, ['query' => 'cache'])
        ->assertOk()
        ->assertName('search-articles')
        ->assertTitle('Search Articles');
});

it('returns published articles that match the keyword', function () {
    ContentServer::tool(SearchArticlesTool::class, ['query' => 'symlink'])
        ->assertOk()
        ->assertSee('Zero Downtime Deploys with Symlinks')
        ->assertSee('slug: zero-downtime-deploys-with-symlinks');
});

it('never leaks a draft through the search tool', function () {
    ContentServer::tool(SearchArticlesTool::class, ['query' => 'Form Requests'])
        ->assertOk()
        ->assertDontSee('Form Requests Beyond Validation')
        ->assertSee('No published articles match');
});

it('narrows the search to a single category', function () {
    ContentServer::tool(SearchArticlesTool::class, [
        'query' => 'the',
        'category' => 'devops',
    ])
        ->assertOk()
        ->assertSee('Zero Downtime Deploys with Symlinks')
        ->assertDontSee('Cache Tags and When They Fail You');
});

it('rejects a limit above the cap', function () {
    ContentServer::tool(SearchArticlesTool::class, [
        'query' => 'cache',
        'limit' => 50,
    ])
        ->assertHasErrors()
        ->assertSee('The limit field must not be greater than 20.');
});

it('returns the full body for a published slug', function () {
    ContentServer::tool(GetArticleTool::class, [
        'slug' => 'cache-tags-and-when-they-fail-you',
    ])
        ->assertOk()
        ->assertSee('Tags work on Redis and Memcached');
});

it('errors when the slug belongs to a draft', function () {
    ContentServer::tool(GetArticleTool::class, [
        'slug' => 'form-requests-beyond-validation',
    ])
        ->assertHasErrors()
        ->assertSee('No published article exists with the slug');
});

it('counts published articles per category', function () {
    ContentServer::tool(ContentStatsTool::class)
        ->assertOk()
        ->assertSee('Published articles: 2')
        ->assertSee('Draft articles: 1')
        ->assertSee('Laravel: 1');
});
```

`ContentServer::tool()` takes the tool class and its arguments and returns a test response with assertions built for MCP. `assertOk()` checks that `isError` is false and `assertHasErrors()` checks the opposite, which is what makes the validation and missing slug tests meaningful. `assertName()` and `assertTitle()` pin the identifiers a client depends on, so the derived name problem from Step 4 cannot quietly come back through a class rename.

The two tests that matter most are the draft tests. `it('never leaks a draft through the search tool')` and `it('errors when the slug belongs to a draft')` are the executable form of the promise in the server instructions. If somebody later drops `->published()` from a query while refactoring, these fail.

Run the suite.

```bash
php artisan test
```

```text
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ContentServerTest
  ✓ it exposes the search tool under a stable name                       0.21s  
  ✓ it returns published articles that match the keyword                 0.02s  
  ✓ it never leaks a draft through the search tool                       0.02s  
  ✓ it narrows the search to a single category                           0.03s  
  ✓ it rejects a limit above the cap                                     0.02s  
  ✓ it returns the full body for a published slug                        0.02s  
  ✓ it errors when the slug belongs to a draft                           0.02s  
  ✓ it counts published articles per category                            0.02s  

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.04s  

  Tests:    10 passed (24 assertions)
  Duration: 0.49s
```

Ten tests in half a second, covering an integration that would otherwise need a running AI client to exercise.

## How the Local Transport Actually Works {#how-the-local-transport-actually-works}

The commands in this tutorial look unusual for a Laravel project because MCP has no HTTP layer in this mode. It is worth understanding what those pipes were doing.

MCP is JSON-RPC 2.0 with a fixed vocabulary of methods. Every message is a single line of JSON. A request carries an `id`, a `method`, and a `params` object; a response carries the same `id` and either a `result` or an `error`. A notification is a message with no `id`, which is why `notifications/initialized` never produces a reply.

The local transport, sometimes called stdio, carries those lines over a process pipe. The client launches your server as a child process, writes requests to its standard input, and reads responses from its standard output. That is the whole thing. `php artisan mcp:start qadrlabs` is just a program that reads lines and writes lines, which is why `printf ... | php artisan mcp:start qadrlabs` is a legitimate MCP client and not a trick.

One consequence is that standard output belongs to the protocol. A stray `dump()` or `echo` inside a tool writes a non-JSON line into the middle of the stream and the client will fail to parse it. When debugging a local server, send diagnostics to the log with `Log::info()` or to standard error, never to standard output.

A session always follows the same three beats. The client sends `initialize` and the server replies with its capabilities, name, version, and instructions. The client sends `notifications/initialized` to confirm it is ready. From there the client calls `tools/list` to discover what exists and `tools/call` to run something, as many times as the conversation needs.

The web transport swaps the pipe for an HTTP route and changes nothing else. The same server class, the same tools, and the same messages, delivered as POST bodies instead. That is the single line difference between `Mcp::local()` and `Mcp::web()`, and it is why starting locally costs you nothing later.

There is also a graphical debugger. Running `php artisan mcp:inspector qadrlabs` starts the official MCP Inspector against your server and opens a browser UI where you can click through the tool list and fill in arguments in a form.

```bash
php artisan mcp:inspector qadrlabs
```

```text
   INFO  Starting the MCP Inspector for server [qadrlabs].  

Transport Type => STDIO
Command => /usr/bin/php8.5
Arguments => /home/gun-gun-priatna/obsidian-vault/sandbox/mcp-demo/artisan mcp:start qadrlabs
```

The inspector is downloaded through `npx` on first run, so it needs Node installed and a moment of patience. It is the friendlier option for exploring a server you did not write; the `printf` pipeline stays faster for the server you are actively editing, and it works over SSH.

## Tools, Resources, and Prompts {#tools-resources-and-prompts}

The generated server class has three empty arrays, and this tutorial only filled one of them. The other two are worth knowing about even though they stay empty here.

A **tool** is something the model decides to call, on its own, in the middle of reasoning. Tools are for operations whose results depend on arguments the model chooses: a search with a query, a lookup by id, a calculation. All three tools in this article are tools precisely because the model has to pick the query and the slug.

A **resource** is a document the client can read, identified by a URI rather than called with arguments. Style guides, schemas, and reference material fit here. The distinction is who initiates: a resource is usually attached to the conversation by the user or the client, while a tool is invoked by the model.

A **prompt** is a reusable template the user triggers, with named arguments the client fills in. It is closer to a slash command than to a function call, and it is the right home for a "summarise this article in a formal tone" workflow that a person starts deliberately.

The rule of thumb is to ask who decides. If the model decides, build a tool. If the person decides, build a prompt. If it is a static document that just needs to be readable, build a resource.

## Keeping a Read-Only Server Read-Only {#keeping-a-read-only-server-read-only}

A read only server is not read only because you decided not to write any write tools. It is read only because of specific choices in the code, and those choices are worth naming so they survive the next feature.

The `published()` scope is the boundary, and it is a single scope on the model rather than a condition repeated in three tools. Every query in every tool starts with it. When a fourth tool arrives, the reviewable question is one line long: does this query go through `published()`.

Validation caps the blast radius of a bad argument. The schema says `limit` may not exceed 20 and the validator enforces it, which matters because a language model is an untrusted input source in the ordinary sense. It is not malicious, but it is capable of asking for 10,000 rows because that seemed like a thorough thing to do.

Result size is a cost, not just a performance concern. Everything a tool returns is pasted into the model's context window and billed as input tokens on the next turn. Returning excerpts from search and full text only from `get-article` is a deliberate split: the agent pays for one full article instead of ten.

The error message is part of the interface. Telling the model which tool to try next turns a failed call into a recovered one, and keeping the message identical for a missing slug and a draft slug avoids confirming that the draft exists.

Finally, the local transport is doing security work you should not mistake for your own. The server runs as a subprocess of a client already running on your machine, with your file permissions and your `.env`. There is no network listener and no authentication because there is no remote caller. The moment you switch to `Mcp::web()`, that changes completely: the route needs `->middleware('auth:sanctum')` or OAuth, the tools need to care about `$request->user()`, and the draft boundary stops being a nicety. If you are heading that way, the [Sanctum REST API tutorial](https://qadrlabs.com/post/laravel-13-build-a-rest-api-for-your-blog-with-sanctum-authentication) covers the token side of it.

## Conclusion {#conclusion}

The interesting thing about building this server is how little of it is about MCP. Two migrations, two models, one scope, and three classes that each run a query and format a string. The protocol work is entirely handled by `laravel/mcp`, which leaves the real design questions on your side of the line: what should the agent be able to see, what should each tool be called, and what does its output need to look like for the next call to be obvious.

- **The tool description is prompt text, not documentation.** Everything you pass to `#[Description]` and `->description()` is handed to the model as the basis for deciding whether and how to call your tool, so listing the valid category slugs there is what stops the model from inventing one.
- **Pin the tool name with `#[Name]`.** In `laravel/mcp` v0.9.4 the derived name keeps the class suffix, so `SearchArticlesTool` becomes `search-articles-tool`. The name is a public identifier that appears in instructions, client configuration, and tool permissions, so set it explicitly and assert on it in a test.
- **Enforce the schema in PHP anyway.** The JSON Schema tells the model what is allowed; `$request->validate()` is what actually stops a `limit` of 50, because a model is free to send arguments its schema said not to.
- **One scope is the entire access boundary.** Routing every query through `Article::published()` means the rule lives in one place, and reviewing a new tool for safety is a one line check rather than a reread of its whole query.
- **`Response::error()` and `Response::text()` say different things.** An error response carries `isError: true`, which tells the model the call failed instead of letting it report your error message to the user as content.
- **Design tool output for the next tool call.** Search returns excerpts with a labelled slug line and `get-article` takes exactly that slug, which is why the agent chained the two calls without being told the slug existed. It also keeps full article bodies out of the context window until one is actually needed.
- **The local transport is a pipe, so debugging is a pipe.** `printf` and `jq` against `php artisan mcp:start` is the fastest feedback loop you will get, and it works anywhere, but it also means standard output belongs to the protocol and your debug output belongs in the log.
- **Everything here ports to the web transport unchanged.** Swapping `Mcp::local()` for `Mcp::web()` moves the same server onto an HTTP route, at which point authentication with Sanctum, per user authorization inside the tools, and rate limiting all become part of the job.
