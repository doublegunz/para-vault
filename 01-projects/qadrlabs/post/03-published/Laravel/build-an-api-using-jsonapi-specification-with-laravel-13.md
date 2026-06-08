---
title: "Build an API Using JSON:API Specification with Laravel 13"
slug: "build-an-api-using-jsonapi-specification-with-laravel-13"
category: "Laravel"
date: "2026-03-24"
status: "published"
---

When multiple teams work on API integrations, one of the biggest time sinks is agreeing on how JSON responses should be formatted. Without a shared standard, every developer structures their responses differently, leading to inconsistencies in data format, error handling, pagination, and relationship management. Clients end up writing custom parsing logic for every API they integrate with.

JSON:API Specification solves this problem by defining a clear, widely-adopted standard for how APIs should structure their requests and responses. And with Laravel 13, implementing this specification has become significantly easier. Laravel now ships with a built-in `JsonApiResource` class that produces JSON:API compliant responses out of the box, with automatic handling of resource objects, relationships, sparse fieldsets, includes, and the correct `Content-Type` header.

In this tutorial, we will build a complete API for managing articles using JSON:API Specification and Laravel 13's native `JsonApiResource`.


## What Is JSON:API Specification? {#what-is-json-api-specification}

[JSON:API Specification](https://jsonapi.org) defines how clients should request resources and how servers should respond to those requests. It is designed to minimize the number of requests and the amount of data transmitted between client and server, without sacrificing readability, flexibility, or discoverability. All data exchange uses the JSON:API media type (`application/vnd.api+json`).

### Core Components

A JSON:API response is built around several core components:

- **Resource Objects**: The primary data managed by the API (e.g., users, articles, products). Each resource object has a `type` and an `id`.
- **Attributes**: Properties of a resource object containing the actual data, such as title, content, and publication date.
- **Relationships**: Connections between resource objects. For example, an article has a relationship with the user who wrote it.
- **Links**: URLs that provide further information about a resource or the relationships between resources.
- **Meta**: Additional information that may be useful to the client but does not fit into attributes or relationships.
- **Errors**: A standardized format for returning error information when something goes wrong.

Here is an example of a JSON:API response for a blog article:

```json
{
  "data": {
    "type": "articles",
    "id": "1",
    "attributes": {
      "title": "JSON API Guide",
      "content": "This is a comprehensive guide to JSON API.",
      "published_at": "2023-06-01T12:00:00Z"
    },
    "relationships": {
      "author": {
        "data": { "type": "users", "id": "1" }
      }
    },
    "links": {
      "self": "http://example.com/articles/1"
    }
  }
}
```

### Why Use JSON:API Specification?

Adopting JSON:API Specification addresses several common pain points in API development:

- **Consistency**: It provides strict rules on data formatting, reducing ambiguity across different API endpoints and teams.
- **Efficiency**: Features like sparse fieldsets and the `include` parameter let clients request only the data they need, avoiding over-fetching and under-fetching.
- **Interoperability**: A widely-accepted standard makes integration easier across web apps, mobile apps, and third-party services.
- **Standardized error handling**: Error responses follow a predictable format, making client-side error handling straightforward.
- **Built-in pagination and filtering**: The specification defines standard approaches for pagination, sorting, and filtering, so you don't have to invent your own.

### HTTP Methods and Status Codes

JSON:API uses standard HTTP methods for CRUD operations:

- **GET**: Retrieve a resource or a collection of resources.
- **POST**: Create a new resource.
- **PATCH**: Update an existing resource.
- **DELETE**: Remove a resource.

Common status codes include: 200 OK for successful reads and updates, 201 Created for successful resource creation, 204 No Content for successful deletions, 400 Bad Request for invalid input, 404 Not Found when a resource does not exist, and 500 Internal Server Error for server-side failures.


## Overview {#overview}

In this tutorial, we will build an API for managing `articles` data. Each article has a `title`, `content`, `published_at` timestamp, and an `author_id` that references the `users` table. The API will return responses that include relationship data, so clients can see the author information alongside each article.

### What You'll Build

A REST API with the following endpoints:

- `GET /api/v1/articles` to list all articles with pagination.
- `GET /api/v1/articles/{id}` to view a single article with its author.
- `POST /api/v1/articles` to create a new article.
- `PATCH /api/v1/articles/{id}` to update an existing article.
- `DELETE /api/v1/articles/{id}` to delete an article.

All responses will comply with the JSON:API Specification, using Laravel 13's built-in `JsonApiResource`.

### What You'll Learn

- How to use Laravel 13's `JsonApiResource` to produce JSON:API compliant responses.
- How to define attributes and relationships on JSON:API resources.
- How to handle sparse fieldsets and relationship includes.
- How to write feature tests that verify JSON:API response structure.

### What You'll Need

- PHP 8.3 or higher
- Composer installed globally
- MySQL (or another supported database)
- A code editor
- Basic familiarity with Laravel and RESTful APIs


## Step 1: Create a New Project {#step-1-create-new-project}

Open your terminal and create a fresh Laravel project:

```
composer create-project --prefer-dist laravel/laravel json-api-project
```

Wait for the installation to finish, then navigate into the project directory:

```
cd json-api-project
```

Start the development server to verify everything works:

```
php artisan serve
```


## Step 2: Configure the Database {#step-2-configure-database}

Open the `.env` file and update the database settings:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=json_api_db
DB_USERNAME=root
DB_PASSWORD=password
```

**Note:** Adjust `DB_USERNAME` and `DB_PASSWORD` to match your local MySQL credentials.

Save the `.env` file, then run the migration command:

```
php artisan migrate
```

If the database does not exist yet, Laravel will ask if you want to create it:

```
   WARN  The database 'json_api_db' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘

```

Select **Yes** and press Enter. Laravel will create the database and run the default migrations:

```
   WARN  The database 'json_api_db' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ Yes                                                          │
 └──────────────────────────────────────────────────────────────┘

   INFO  Preparing database.  

  Creating migration table ...................................... 34.79ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table ......................... 161.42ms DONE
  0001_01_01_000001_create_cache_table .......................... 60.50ms DONE
  0001_01_01_000002_create_jobs_table .......................... 142.30ms DONE

```


## Step 3: Create Model and Migration {#step-3-create-model-and-migration}

As outlined in the overview, we need an `Article` model with a relationship to the `User` model. Generate both the model and migration:

```
php artisan make:model Article -m
```

```
   INFO  Model [app/Models/Article.php] created successfully.  

   INFO  Migration [database/migrations/2024_06_10_080838_create_articles_table.php] created successfully.
```

### Define the Database Schema

Open `database/migrations/xxxx_xx_xx_xxxxxx_create_articles_table.php` and define the columns:

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
        Schema::create('articles', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('content');
            $table->timestamp('published_at')->nullable();
            $table->foreignId('author_id')->constrained('users')->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('articles');
    }
};
```

The `foreignId('author_id')->constrained('users')->onDelete('cascade')` line creates a foreign key column that references the `users` table. The `onDelete('cascade')` ensures that when a user is deleted, all of their articles are automatically removed as well.

Save the migration file.

### Configure the Model

Open `app/Models/Article.php` and set up the fillable fields and the author relationship:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['title', 'content', 'published_at', 'author_id'])]
class Article extends Model
{
    use HasFactory;

    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    protected function casts(): array
    {
        return [
            'published_at' => 'datetime',
        ];
    }
}

```

The `#[Fillable]` attribute is new in Laravel 13 and replaces the traditional `$fillable` property with a cleaner, declarative syntax using PHP's native attributes. The `author()` method defines a `BelongsTo` relationship, telling Laravel that each article belongs to a single user via the `author_id` foreign key.

Save the model file, then run the migration:

```
php artisan migrate
```

```
   INFO  Running migrations.  

  2024_06_10_080838_create_articles_table ....................... 79.98ms DONE
```


## Step 4: Create JSON:API Resource Classes {#step-4-create-json-api-resources}

This is where Laravel 13 makes a significant difference compared to older versions. Previously, you had to manually format your resource responses to match the JSON:API structure, defining `type`, `id`, `attributes`, and `relationships` keys by hand. Laravel 13 introduces `JsonApiResource`, a dedicated resource class that handles all of this automatically.

### Generate the User Resource

```
php artisan make:resource UserResource --json-api
```

The `--json-api` flag generates a class that extends `JsonApiResource` instead of the standard `JsonResource`. Open `app/Http/Resources/UserResource.php` and define the attributes:

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\JsonApi\JsonApiResource;

class UserResource extends JsonApiResource
{
    /**
     * The resource's attributes.
     */
    public $attributes = [
        'name',
        'email',
        'created_at',
        'updated_at',
    ];

    /**
     * The resource's relationships.
     */
    public $relationships = [
        //
    ];
}
```

With `JsonApiResource`, you only need to list the attribute names in the `$attributes` property. Laravel reads their values directly from the underlying model. The `type` (e.g., `users`) and `id` are derived automatically from the resource class name and the model's primary key. There is no need to manually build the response array.

Save the file.

### Generate the Article Resource

```
php artisan make:resource ArticleResource --json-api
```

Open `app/Http/Resources/ArticleResource.php` and configure attributes and relationships:

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\JsonApi\JsonApiResource;

class ArticleResource extends JsonApiResource
{
    /**
     * The resource's attributes.
     */
    public $attributes = [
        'title',
        'content',
        'published_at',
        'created_at',
        'updated_at',
    ];

    /**
     * The resource's relationships.
     */
    public $relationships = [
        'author' => UserResource::class,
    ];

    /**
     * Get the resource's links.
     */
    public function toLinks(Request $request): array
    {
        return [
            'self' => url('/api/v1/articles/' . $this->id),
        ];
    }
}
```

Let's break down what each part does:

- `$attributes` lists which model fields should be included in the `attributes` section of the JSON:API response. You simply list the field names, and Laravel pulls the values from the model.
- `$relationships` defines the includable relationships. The `'author' => UserResource::class` entry tells Laravel that the `author` relationship should be serialized using the `UserResource` class. Relationships are only included in the response when the client explicitly requests them via the `include` query parameter (e.g., `?include=author`).
- `toLinks()` adds a `links` object to each resource in the response, which is part of the JSON:API specification for resource discoverability.

Compare this to the old approach where you had to manually build the entire response structure inside `toArray()`:

```php
// Old approach (before Laravel 13)
public function toArray(Request $request): array
{
    return [
        'type' => 'articles',
        'id' => (string) $this->id,
        'attributes' => [
            'title' => $this->title,
            'content' => $this->content,
            // ...
        ],
        'relationships' => [
            'author' => new UserResource($this->whenLoaded('author')),
        ],
        'links' => [
            'self' => url('/api/articles/' . $this->id)
        ]
    ];
}
```

With `JsonApiResource`, all of that boilerplate is handled for you. The `Content-Type` header is also automatically set to `application/vnd.api+json`.

Save the file.


## Step 5: Create the Controller {#step-5-create-controller}

Generate an API controller for articles:

```
php artisan make:controller Api/ArticleController
```

```
   INFO  Controller [app/Http/Controllers/Api/ArticleController.php] created successfully. 
```

Open `app/Http/Controllers/Api/ArticleController.php` and implement the CRUD methods:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ArticleResource;
use App\Models\Article;
use App\Models\User;
use Illuminate\Http\Request;

class ArticleController extends Controller
{
    public function index()
    {
        $articles = Article::with('author')->paginate();

        return ArticleResource::collection($articles);
    }

    public function show(Article $article)
    {
        $article->load('author');

        return new ArticleResource($article);
    }

    public function store(Request $request)
    {
        $validatedData = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'published_at' => 'nullable|date',
            'author_id' => 'required|exists:users,id',
        ]);

        $article = Article::create($validatedData);

        return (new ArticleResource($article))
            ->response()
            ->setStatusCode(201);
    }

    public function update(Request $request, Article $article)
    {
        $validatedData = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'content' => 'sometimes|required|string',
            'published_at' => 'nullable|date',
            'author_id' => 'sometimes|required|exists:users,id',
        ]);

        $article->update($validatedData);

        return new ArticleResource($article->fresh());
    }

    public function destroy(Article $article)
    {
        $article->delete();

        return response()->noContent();
    }
}
```

Notice how much cleaner this controller is compared to the old approach. Here is what changed:

**No manual `Content-Type` headers.** `JsonApiResource` automatically sets the `Content-Type` to `application/vnd.api+json` on every response. In the old approach, you had to manually chain `->header('Content-Type', 'application/vnd.api+json')` on every response.

**No manual 404 handling.** By using route model binding (`Article $article` in the method signature), Laravel automatically returns a 404 response if the article is not found. The old approach required manual `find()` calls and custom 404 error responses.

**Simpler collection responses.** `ArticleResource::collection($articles)` handles pagination metadata automatically. The old approach required wrapping the collection inside a manual `response()->json()` call.

**The `show` method uses eager loading.** `$article->load('author')` ensures the author relationship is loaded so clients can request it via `?include=author`. Without this, the relationship data would not be available for inclusion.

**The `update` method uses `sometimes` validation.** The `sometimes` rule means the field is only validated if it is present in the request. This allows clients to send partial updates (e.g., only updating the title without sending the content), which aligns with how PATCH requests work in the JSON:API specification.

Save the controller file.


## Step 6: Register the Routes {#step-6-register-routes}

By default, `routes/api.php` does not exist in recent Laravel versions. Generate it first:

```
php artisan install:api
```

Wait for the setup to complete. Then open `routes/api.php` and add the article routes:

```php
<?php

use App\Http\Controllers\Api\ArticleController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::apiResource('articles', ArticleController::class);
});
```

`Route::apiResource()` registers five routes for the controller: `index`, `store`, `show`, `update`, and `destroy`. These map to `GET /articles`, `POST /articles`, `GET /articles/{article}`, `PATCH /articles/{article}`, and `DELETE /articles/{article}` respectively. The `prefix('v1')` wraps all routes under `/api/v1/`, which is a common convention for API versioning.

Save the route file.


## Step 7: Testing {#step-7-testing}

With the API built, let's verify that every endpoint returns responses that comply with the JSON:API Specification.

### Step 7.1: Configure PHPUnit

Open `phpunit.xml` and and make sure the DB_CONNECTION and DB_DATABASE environment variables are not commented out.

```xml
        <env name="DB_CONNECTION" value="sqlite"/>
        <env name="DB_DATABASE" value=":memory:"/>
```

This tells PHPUnit to use an in-memory SQLite database for testing. Each test run starts with a completely fresh database, ensuring tests are isolated and repeatable.

Save the file.

### Step 7.2: Create a Factory Class

Tests need sample data. Generate a factory for the `Article` model:

```
php artisan make:factory ArticleFactory --model=Article
```

```
   INFO  Factory [database/factories/ArticleFactory.php] created successfully.
```

Open `database/factories/ArticleFactory.php` and define the default state:

```php
<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use App\Models\User;

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
            'title' => $this->faker->sentence,
            'content' => $this->faker->paragraph,
            'published_at' => $this->faker->optional()->dateTime,
            'author_id' => User::factory(),
        ];
    }
}
```

The `author_id` field uses `User::factory()`, which means every time an article is created via the factory, a corresponding user is automatically generated as well. The `optional()` method on `published_at` means some articles will have a publication date and some will not, simulating real-world data.

Save the file.

### Step 7.3: Write the Test Class

Generate a test file:

```
php artisan make:test ArticleApiTest
```

```
   INFO  Test [tests/Feature/ArticleApiTest.php] created successfully. 
```

Open `tests/Feature/ArticleApiTest.php` and write tests for each CRUD operation:

```php
<?php

namespace Tests\Feature;

use App\Models\Article;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ArticleApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_an_article()
    {
        $user = User::factory()->create();
        $data = [
            'title' => 'New Article',
            'content' => 'Article content',
            'published_at' => now(),
            'author_id' => $user->id,
        ];

        $response = $this->postJson('/api/v1/articles', $data);

        $response->assertStatus(201)
            ->assertJson([
                'data' => [
                    'type' => 'articles',
                    'attributes' => [
                        'title' => 'New Article',
                        'content' => 'Article content',
                    ],
                ],
            ]);

        $this->assertDatabaseHas('articles', [
            'title' => 'New Article',
            'content' => 'Article content',
            'author_id' => $user->id,
        ]);
    }

    public function test_user_can_get_article_list()
    {
        Article::factory()->count(3)->create();

        $response = $this->getJson('/api/v1/articles');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => [
                    '*' => ['type', 'id', 'attributes'],
                ],
            ]);
    }

    public function test_user_can_get_a_single_article()
    {
        $article = Article::factory()->create();

        $response = $this->getJson('/api/v1/articles/' . $article->id);

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'type' => 'articles',
                    'id' => (string) $article->id,
                    'attributes' => [
                        'title' => $article->title,
                        'content' => $article->content,
                    ],
                ],
            ]);
    }

    public function test_user_can_update_an_article()
    {
        $article = Article::factory()->create();
        $data = [
            'title' => 'Updated Article Title',
            'content' => 'Updated Article Content',
        ];

        $response = $this->patchJson('/api/v1/articles/' . $article->id, $data);

        $response->assertStatus(200)
            ->assertJson([
                'data' => [
                    'type' => 'articles',
                    'attributes' => [
                        'title' => 'Updated Article Title',
                        'content' => 'Updated Article Content',
                    ],
                ],
            ]);

        $this->assertDatabaseHas('articles', $data);
    }

    public function test_user_can_delete_an_article()
    {
        $article = Article::factory()->create();

        $response = $this->deleteJson('/api/v1/articles/' . $article->id);

        $response->assertStatus(204);
        $this->assertDatabaseMissing('articles', ['id' => $article->id]);
    }
}
```

Let's walk through what each test verifies:

- `test_user_can_create_an_article` sends a POST request with article data and checks that the response has a 201 status code, the correct JSON:API structure with `type` and `attributes`, and that the data is actually saved in the database.
- `test_user_can_get_article_list` creates three articles and verifies that the GET endpoint returns a 200 status with the expected JSON:API collection structure.
- `test_user_can_get_a_single_article` verifies that fetching a specific article returns the correct `type`, `id`, and `attributes` matching the created article.
- `test_user_can_update_an_article` sends a PATCH request with partial data and verifies both the response structure and that the database was updated.
- `test_user_can_delete_an_article` sends a DELETE request and verifies a 204 No Content response, then confirms the record no longer exists in the database.

The `RefreshDatabase` trait ensures the database is reset between each test, so tests do not interfere with each other.

Save the file.

### Step 7.4: Run the Tests

Execute the test suite:

```
php artisan test
```

```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ArticleApiTest
  ✓ user can create an article                                           0.13s  
  ✓ user can get article list                                            0.01s  
  ✓ user can get a single article                                        0.01s  
  ✓ user can update an article                                           0.01s  
  ✓ user can delete an article                                           0.01s  

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.01s  

  Tests:    7 passed (24 assertions)
  Duration: 0.21s

```

All five API tests pass. The responses from our endpoints match the JSON:API structure we defined in the assertions.


## Sparse Fieldsets and Includes {#sparse-fieldsets-and-includes}

One of the powerful features of JSON:API (and `JsonApiResource`) is the ability for clients to request only the data they need.

### Requesting Specific Fields

Clients can use the `fields` query parameter to request only specific attributes for each resource type:

```
GET /api/v1/articles/1?fields[articles]=title,created_at&fields[users]=name
```

This returns only the `title` and `created_at` for the article, and only the `name` for the related user. This is handled automatically by `JsonApiResource` with no additional code on your part.

### Including Relationships

By default, relationships are not included in the response. Clients can request them using the `include` parameter:

```
GET /api/v1/articles/1?include=author
```

This produces a response with resource identifier objects in the `relationships` key and full resource objects in the top-level `included` array:

```json
{
    "data": {
        "id": "1",
        "type": "articles",
        "attributes": {
            "title": "Hello World",
            "content": "This is my first article."
        },
        "relationships": {
            "author": {
                "data": {
                    "id": "1",
                    "type": "users"
                }
            }
        }
    },
    "included": [
        {
            "id": "1",
            "type": "users",
            "attributes": {
                "name": "John Doe",
                "email": "john@example.com"
            }
        }
    ]
}
```

All of this behavior comes for free with `JsonApiResource`. You defined the `$relationships` property on the resource, and Laravel handles the rest.


## Conclusion {#conclusion}

In this tutorial, we built a complete JSON:API compliant REST API using Laravel 13. Starting from a fresh project, we created models, migrations, JSON:API resources, a controller, and a full test suite to verify the response structure.

Here are the key takeaways:

- **Laravel 13's `JsonApiResource` eliminates boilerplate.** Instead of manually constructing `type`, `id`, `attributes`, and `relationships` in every resource, you declare them as properties and let the framework handle the serialization.
- **The `Content-Type` header is automatic.** `JsonApiResource` sets `application/vnd.api+json` on every response without you chaining it manually.
- **Relationships are opt-in by default.** Clients must use the `include` query parameter to request relationship data. This prevents over-fetching and keeps responses lean.
- **Sparse fieldsets work out of the box.** Clients can use the `fields` parameter to request only the attributes they need, with no additional controller logic required.
- **Route model binding simplifies error handling.** By type-hinting models in controller methods, Laravel returns proper 404 responses automatically, eliminating manual `find()` and error response code.
- **Feature tests verify compliance.** Writing tests that assert the JSON:API structure ensures your API stays compliant as the codebase evolves.

For a deeper dive into JSON:API Specification, visit the official site at [https://jsonapi.org](https://jsonapi.org). For more details on Laravel's `JsonApiResource`, refer to the [Eloquent API Resources documentation](https://laravel.com/docs/13.x/eloquent-resources#jsonapi-resources).