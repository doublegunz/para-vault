# Laravel 13 DataTables Server-Side Processing: Display Posts with Yajra

Rendering a few database records in a Blade table is straightforward. The trouble starts when the table grows to hundreds or thousands of posts. Loading every row at once increases the response size, makes the browser do more work, and forces you to rebuild searching, sorting, and pagination yourself.

Our older tutorial, [Laravel 8 DataTables Server-Side Rendering](https://qadrlabs.com/post/belajar-laravel-8-integrasi-datatables-server-side-rendering), solved this problem with Laravel UI, Laravel Mix, and an earlier version of Yajra DataTables. Those tools and commands no longer represent a fresh Laravel application.

In this tutorial, we will rebuild the example with Laravel 13 and Yajra DataTables 13. Instead of users, our application will display blog posts. Eloquent will process pagination, searching, and ordering on the server, while DataTables.js renders only the current result page in the browser.

## Overview {#overview}

We will start with a clean Laravel 13 project, create realistic Post records, and connect an Eloquent query to a server-side DataTable. The finished application will use SQLite for a lightweight database, a standalone Blade view for the interface, and Pest tests for the DataTables response contract.

### What You'll Build

- A Laravel 13 application containing 100 sample blog posts.
- A server-side Posts DataTable with pagination, global searching, and column ordering.
- A `PostsDataTable` service that keeps query and table configuration outside the controller.
- A standalone Blade page styled with Tailwind CSS.
- A six-test Pest suite for the HTML page and AJAX behavior.

### What You'll Learn

- How to install Yajra DataTables 13 in Laravel 13.
- How to create a Post model with Laravel 13's `#[Fillable]` attribute.
- How to use an Eloquent query as a DataTables server-side source.
- How `minifiedAjax()` connects the generated table to its Laravel endpoint.
- How to verify total counts, pagination, searching, and ordering with Pest.

### What You'll Need

- PHP 8.3 or newer.
- Composer and the Laravel installer.
- Basic familiarity with Laravel routing, Eloquent, Blade, and factories.
- An internet connection for Composer and the frontend CDN assets.
- A terminal and a web browser.

You do not need to configure MySQL for this tutorial. The Laravel installer creates and configures an SQLite database for us.

## Step 1: Create the Laravel 13 Project {#step-1-create-the-laravel-13-project}

Create a fresh Laravel project named `laravel-datatables-posts`, select SQLite, and include Pest from the beginning:

```bash
laravel new laravel-datatables-posts --no-interaction --database=sqlite --pest --no-boost
cd laravel-datatables-posts
```

The `--no-interaction` option makes the command reproducible because the installer does not stop for prompts. The `--database=sqlite` option prepares a local SQLite database, while `--pest` installs Pest and its Laravel plugin. The `--no-boost` option keeps this focused tutorial free from the optional Laravel Boost setup.

Install the complete Yajra DataTables 13 package:

```bash
composer require yajra/laravel-datatables:"^13.0"
```

The complete package includes the Eloquent engine, HTML Builder, and the Artisan generator that we will use later. Version 13 requires PHP 8.3 or newer and targets Laravel 13.

You can compare the package choices in the [official Yajra DataTables 13 installation guide](https://yajrabox.com/docs/laravel-datatables/13.0/installation). This tutorial follows the service-class approach from the [official quick starter](https://yajrabox.com/docs/laravel-datatables/13.0/quick-starter), adapted to a Post model and a standalone Blade page.

Confirm the framework environment:

```bash
php artisan about --only=environment
```

A validated installation for this tutorial reported:

```text
 Environment ..
 Application Name .. Laravel
 Laravel Version .. 13.21.1
 PHP Version .. 8.5.6
 Composer Version .. 2.10.0
 Environment .. local
 Debug Mode .. ENABLED
 URL .. localhost:8000
 Maintenance Mode .. OFF
 Timezone .. UTC
 Locale .. en
```

Your Laravel 13 patch version and local PHP version may be newer. The important requirements are Laravel 13 and PHP 8.3 or above.

## Step 2: Build the Post Data Layer {#step-2-build-the-post-data-layer}

The DataTable needs enough records to make server-side pagination meaningful. Generate a Post model together with its migration and factory:

```bash
php artisan make:model Post -mf --no-interaction
```

The `-m` option creates a migration, and `-f` creates a model factory. We will use the factory to generate 100 realistic records without manually writing SQL.

Open the generated `database/migrations/*_create_posts_table.php` file and replace its contents with:

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
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('slug')->unique();
            $table->text('content');
            $table->string('status')->default('draft');
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('posts');
    }
};
```

The table stores the content fields needed by a small blog. The DataTable will display `title`, `status`, `published_at`, and `created_at`. The longer `content` field remains in the database but is deliberately excluded from the listing query.

Save the migration, then open `app/Models/Post.php` and replace its contents with:

```php
<?php

namespace App\Models;

use Database\Factories\PostFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['title', 'slug', 'content', 'status', 'published_at'])]
class Post extends Model
{
    /** @use HasFactory<PostFactory> */
    use HasFactory;

    /**
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

Laravel 13 can declare mass-assignable fields with the `#[Fillable]` attribute. This replaces the older `protected $fillable` property while preserving mass-assignment protection. The `casts()` method converts `published_at` into a Carbon date instance, which lets the DataTable format it later.

Save the model, then open `database/factories/PostFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\Post;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Post>
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
        $title = fake()->unique()->sentence(6);
        $isPublished = fake()->boolean();

        return [
            'title' => $title,
            'slug' => Str::slug($title).'-'.fake()->unique()->numberBetween(1000, 9999),
            'content' => fake()->paragraphs(4, true),
            'status' => $isPublished ? 'published' : 'draft',
            'published_at' => $isPublished
                ? fake()->dateTimeBetween('-1 year', 'now')
                : null,
        ];
    }

    public function draft(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'draft',
            'published_at' => null,
        ]);
    }

    public function published(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => 'published',
            'published_at' => fake()->dateTimeBetween('-1 year', 'now'),
        ]);
    }
}
```

The default factory randomly creates either a draft or a published post. Drafts always have a `null` publication date, while published posts receive a date from the previous year. The named `draft()` and `published()` states also give our tests an explicit way to create either condition.

Save the factory and update `database/seeders/DatabaseSeeder.php`:

```php
<?php

namespace Database\Seeders;

use App\Models\Post;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        Post::factory()->count(100)->create();
    }
}
```

This seeder creates enough records to exercise several DataTables pages. Save the file, rebuild the database, and run the seeder:

```bash
php artisan migrate:fresh --seed
```

The command drops existing tables, runs every migration, and then inserts the 100 Posts. Use `migrate:fresh` only on a local development database because it removes existing data.

Open Tinker to verify the number of rows:

```bash
php artisan tinker
```

Run the count query:

```php
App\Models\Post::count();
```

The verified result is:

```text
= 100
```

Type `exit` to leave Tinker. The database is now ready for server-side processing.

## Step 3: Create the Posts DataTable Service {#step-3-create-the-posts-datatable-service}

Generate a DataTable service class for the Post model:

```bash
php artisan datatables:make Posts
```

This command creates `app/DataTables/PostsDataTable.php`. The generated class contains more features than our read-only table needs, so replace it with:

```php
<?php

namespace App\DataTables;

use App\Models\Post;
use Illuminate\Database\Eloquent\Builder as QueryBuilder;
use Yajra\DataTables\EloquentDataTable;
use Yajra\DataTables\Html\Builder as HtmlBuilder;
use Yajra\DataTables\Html\Column;
use Yajra\DataTables\Services\DataTable;

class PostsDataTable extends DataTable
{
    /**
     * Build the DataTable class.
     *
     * @param  QueryBuilder<Post>  $query  Results from query() method.
     */
    public function dataTable(QueryBuilder $query): EloquentDataTable
    {
        return (new EloquentDataTable($query))
            ->editColumn(
                'published_at',
                fn (Post $post): string => $post->published_at?->format('M j, Y') ?? 'Not published'
            )
            ->editColumn(
                'created_at',
                fn (Post $post): string => $post->created_at->format('M j, Y')
            )
            ->setRowId('id');
    }

    /**
     * Get the query source of dataTable.
     *
     * @return QueryBuilder<Post>
     */
    public function query(Post $model): QueryBuilder
    {
        return $model->newQuery()->select([
            'id',
            'title',
            'status',
            'published_at',
            'created_at',
        ]);
    }

    /**
     * Optional method if you want to use the html builder.
     */
    public function html(): HtmlBuilder
    {
        return $this->builder()
            ->setTableId('posts-table')
            ->columns($this->getColumns())
            ->minifiedAjax()
            ->orderBy(4, 'desc')
            ->pageLength(10)
            ->searchDelay(350);
    }

    /**
     * Get the dataTable columns definition.
     */
    public function getColumns(): array
    {
        return [
            Column::make('id')->title('ID')->width(60),
            Column::make('title')->title('Title'),
            Column::make('status')->title('Status'),
            Column::make('published_at')->title('Published'),
            Column::make('created_at')->title('Created'),
        ];
    }

    /**
     * Get the filename for export.
     */
    protected function filename(): string
    {
        return 'Posts_'.date('YmdHis');
    }
}
```

There are four important parts in this class:

- `query()` starts an Eloquent query and selects only the five fields required by the listing.
- `dataTable()` converts the Eloquent builder into a DataTables response, formats the two dates, and uses the Post ID as the HTML row ID.
- `html()` creates the client configuration. It enables the AJAX endpoint, sorts by `created_at` descending, displays ten rows per page, and waits 350 milliseconds before submitting a search.
- `getColumns()` keeps the browser column order synchronized with the server query.

`minifiedAjax()` uses the current route for the background request. The first normal request receives the Blade page. Subsequent AJAX requests receive JSON because DataTables asks for a JSON response.

Save the service and check its PHP syntax:

```bash
php -l app/DataTables/PostsDataTable.php
```

The command should report `No syntax errors detected in app/DataTables/PostsDataTable.php`.

## Step 4: Connect the Controller, Route, and View {#step-4-connect-the-controller-route-and-view}

The service class is ready, but Laravel still needs a controller, route, and page. Generate the controller:

```bash
php artisan make:controller PostsController --no-interaction
```

Open `app/Http/Controllers/PostsController.php` and replace its contents with:

```php
<?php

namespace App\Http\Controllers;

use App\DataTables\PostsDataTable;

class PostsController extends Controller
{
    public function index(PostsDataTable $dataTable)
    {
        return $dataTable->render('posts.index');
    }
}
```

Laravel injects `PostsDataTable` into `index()`. Its `render()` method returns the Blade view for a normal browser request and produces the server-side JSON response when DataTables sends an AJAX request that accepts JSON.

Save the controller and open `routes/web.php`:

```php
<?php

use App\Http\Controllers\PostsController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/posts', [PostsController::class, 'index'])->name('posts.index');
```

The named `posts.index` route serves both parts of the integration. A normal `GET /posts` displays the page, while a DataTables AJAX request to the same URL receives the processed result set.

Save the route, create `resources/views/posts/index.blade.php`, and add:

```blade
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Posts DataTable</title>
    <script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>
    <link rel="stylesheet" href="https://cdn.datatables.net/2.3.8/css/dataTables.dataTables.min.css">
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="mb-2 text-3xl font-bold">Posts DataTable</h1>
        <p class="mb-6 text-gray-600">
            Browse posts with server-side pagination, searching, and ordering.
        </p>

        <div class="overflow-x-auto">
            {{ $dataTable->table([
                'class' => 'display w-full',
                'aria-describedby' => 'posts-table-description',
            ]) }}
        </div>

        <p id="posts-table-description" class="sr-only">
            A searchable and sortable list of blog posts.
        </p>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Laravel DataTables at qadrlabs.com</a>
        </div>
    </div>

    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script src="https://cdn.datatables.net/2.3.8/js/dataTables.min.js"></script>
    {{ $dataTable->scripts() }}
</body>
</html>
```

This is a standalone Blade document, so it does not depend on an application layout. Tailwind styles the page wrapper, while the official DataTables stylesheet handles its controls. The table is placed inside an overflow container so it remains usable on a narrow screen.

The example pins DataTables.js 2.3.8 from the [official DataTables CDN](https://cdn.datatables.net/). Pinning the version prevents a future major release from silently changing the table while you are following the tutorial.

The JavaScript order matters. jQuery loads first because Yajra's generated initialization uses the jQuery DataTables interface. DataTables.js loads second, and `$dataTable->scripts()` runs last to initialize `#posts-table` with the configuration from `PostsDataTable::html()`.

Save the view and verify the route:

```bash
php artisan route:list --name=posts
```

The validated route output is:

```text
 GET|HEAD posts .. posts.index › PostsController@index

 Showing [1] routes
```

At this point, the page and its server-side endpoint are connected.

## Step 5: Test the Server-Side DataTable {#step-5-test-the-server-side-datatable}

A browser check proves that the interface loads, but it does not protect the server-side contract from future changes. We will add focused tests for the HTML page, JSON structure, total count, pagination, searching, and ordering.

Create `tests/Feature/PostsDataTableTest.php`:

```php
<?php

use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;

uses(RefreshDatabase::class);

function dataTablesParameters(array $overrides = []): array
{
    $column = fn (string $name): array => [
        'data' => $name,
        'name' => $name,
        'searchable' => 'true',
        'orderable' => 'true',
        'search' => ['value' => '', 'regex' => 'false'],
    ];

    return array_replace_recursive([
        'draw' => 1,
        'start' => 0,
        'length' => 10,
        'search' => ['value' => '', 'regex' => 'false'],
        'columns' => [
            $column('id'),
            $column('title'),
            $column('status'),
            $column('published_at'),
            $column('created_at'),
        ],
        'order' => [
            ['column' => 4, 'dir' => 'desc'],
        ],
    ], $overrides);
}

function getPostsDataTable(array $parameters = []): TestResponse
{
    return test()
        ->withHeader('X-Requested-With', 'XMLHttpRequest')
        ->getJson(route('posts.index').'?'.http_build_query(dataTablesParameters($parameters)));
}

it('renders the posts datatable page', function () {
    $this->get('/posts')
        ->assertOk()
        ->assertSee('Posts DataTable');
});

it('returns the datatables json contract for ajax requests', function () {
    getPostsDataTable()
        ->assertOk()
        ->assertJsonStructure([
            'draw',
            'recordsTotal',
            'recordsFiltered',
            'data',
        ]);
});

it('reports the total number of posts', function () {
    Post::factory()->count(3)->create();

    getPostsDataTable()
        ->assertJsonPath('recordsTotal', 3)
        ->assertJsonPath('recordsFiltered', 3);
});

it('returns only the requested page length', function () {
    Post::factory()->count(25)->create();

    getPostsDataTable(['start' => 10, 'length' => 5])
        ->assertJsonCount(5, 'data');
});

it('filters posts by title with global search', function () {
    Post::factory()->create(['title' => 'Laravel DataTables Guide']);
    Post::factory()->create(['title' => 'Understanding Queue Workers']);

    getPostsDataTable([
        'search' => ['value' => 'Laravel DataTables', 'regex' => 'false'],
    ])
        ->assertJsonPath('recordsFiltered', 1)
        ->assertJsonPath('data.0.title', 'Laravel DataTables Guide');
});

it('orders posts by the requested column and direction', function () {
    Post::factory()->create(['title' => 'Zebra Post']);
    Post::factory()->create(['title' => 'Alpha Post']);
    Post::factory()->create(['title' => 'Middle Post']);

    getPostsDataTable([
        'order' => [
            ['column' => 1, 'dir' => 'asc'],
        ],
    ])->assertJsonPath('data.*.title', [
        'Alpha Post',
        'Middle Post',
        'Zebra Post',
    ]);
});
```

The `dataTablesParameters()` helper reproduces the important request values that DataTables.js sends. Each column includes its data key and whether it can be searched or ordered. Individual tests then override only the parameter relevant to their scenario.

`getPostsDataTable()` includes the `X-Requested-With` header and uses `getJson()`. Yajra 13 checks that the request is both AJAX and willing to accept JSON before returning the server-side response, so both conditions are intentional.

Save the test and run it:

```bash
php artisan test tests/Feature/PostsDataTableTest.php
```

The validated suite completes with six passing tests and thirteen assertions. If a test fails, read its individual failure before opening the browser. A failing count, search, or ordering assertion usually indicates that the browser and server column definitions no longer match.

## Step 6: Try It Out {#step-6-try-it-out}

The automated checks now protect the integration. Start Laravel's development server:

```bash
php artisan serve
```

Open [http://localhost:8000/posts](http://localhost:8000/posts) in your browser. The first page should display ten of the 100 seeded Posts.

Try the following interactions:

1. Enter part of a Post title in the search field. The table should update after a short delay and show only matching records.
2. Search for `draft` or `published`. The global search also checks the status column.
3. Click the Title header. The rows should switch between ascending and descending alphabetical order.
4. Change the page or page length. DataTables should request only the new result window.

Open your browser's Network panel and filter for `posts`. The normal document request returns HTML. The background request includes parameters such as `draw`, `start`, `length`, `search`, `columns`, and `order`, then receives JSON with this structure:

```json
{
    "draw": 1,
    "recordsTotal": 100,
    "recordsFiltered": 100,
    "data": [
        {
            "id": 1,
            "title": "Example Post Title",
            "status": "published",
            "published_at": "Jul 10, 2026",
            "created_at": "Jul 23, 2026",
            "DT_RowId": 1
        }
    ]
}
```

The values in your first record will differ because the factory generates random content. The stable parts are the response keys and the fact that `data` contains only the requested page.

## How Server-Side DataTables Works {#how-server-side-datatables-works}

The table may look like a normal JavaScript widget, but each interaction follows a request cycle between the browser, Laravel, and the database.

First, Laravel renders the standalone Blade page and the empty table header. `$dataTable->scripts()` then initializes DataTables.js with `serverSide` and `processing` enabled.

DataTables sends the current page offset, page size, global search value, column definitions, and requested ordering to `/posts`. `PostsDataTable` translates those values into an Eloquent query. SQLite executes the count and result queries, and Yajra returns a response that DataTables.js understands.

Four JSON fields coordinate the process:

- `draw` lets DataTables match the response with the request that initiated it.
- `recordsTotal` contains the number of rows before searching.
- `recordsFiltered` contains the number of rows after search conditions are applied.
- `data` contains only the records for the current page.

This is why the browser does not need all 100 records to render the first ten. The same principle remains useful when the table grows to hundreds of thousands of rows.

## Security and Performance Considerations {#security-and-performance-considerations}

Server-side processing reduces browser work, but query and output design still matter.

Yajra escapes column output by default. Keep that protection enabled for values such as Post titles. If you later add an HTML action column and mark it as raw, ensure that user-controlled values are escaped before they enter the generated HTML.

The example query selects only the fields needed by the table:

```php
return $model->newQuery()->select([
    'id',
    'title',
    'status',
    'published_at',
    'created_at',
]);
```

Avoid replacing this query with `Post::all()`. A collection loads every matching record into PHP before DataTables applies its response logic, which removes the main advantage of server-side processing.

Database indexes should reflect actual usage. The migration already gives `slug` a unique index. If users frequently filter by `status` or order a very large dataset by `created_at`, measure the query and add appropriate indexes. Do not add indexes to every column without checking the read and write tradeoffs.

Finally, disable application debug mode in production. Debug information is useful locally, but production DataTables responses should not expose query diagnostics or exception details.

## Conclusion {#conclusion}

You now have a Laravel 13 replacement for the older Laravel 8 DataTables tutorial. The application keeps its browser response small, delegates filtering and ordering to Eloquent, and verifies the integration through repeatable tests.

- **Server-side processing.** Pagination, searching, and ordering are translated into database queries instead of running against a full in-memory collection.
- **Service class separation.** `PostsDataTable` owns the Eloquent source, output formatting, HTML configuration, and column definitions.
- **Laravel 13 conventions.** The project uses PHP 8.3 or newer, SQLite, Pest, and the `#[Fillable]` model attribute.
- **Focused frontend setup.** A standalone Blade page combines Tailwind CSS with DataTables.js without requiring a shared layout.
- **Automated verification.** Six Pest tests protect the HTML page, JSON contract, total count, pagination, searching, and ordering.
