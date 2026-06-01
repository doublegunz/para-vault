---
title: "Generating API Documentation with Scramble in Laravel 13"
slug: "generating-api-documentation-with-scramble-in-laravel-13"
category: "Laravel"
date: "2026-04-02"
status: "published"
---

In the [previous tutorial](https://qadrlabs.com/post/build-an-api-using-jsonapi-specification-with-laravel-13), we built a JSON:API backend with articles, resources, and versioned routes. The API works, but how do your frontend developers or API consumers know which endpoints are available, what parameters to send, or what response to expect? Without proper documentation, teams waste time reading source code or asking on Slack.

You could write the documentation manually using tools like Swagger Editor or Postman, but that creates a maintenance problem. Every time you add a field, change a validation rule, or rename a route, you have to remember to update the docs. They inevitably drift out of sync.

Scramble solves this by automatically generating OpenAPI documentation from your existing Laravel code. It reads your routes, validation rules, type hints, and API Resources to produce an interactive Swagger UI, with zero manual annotations required.


## Overview {#overview}

In this tutorial, we will add automatic API documentation to the JSON:API project we built in the [previous tutorial](https://qadrlabs.com/post/build-an-api-using-jsonapi-specification-with-laravel-13). Scramble will scan our existing controller code and generate a fully interactive documentation page. We will also add PHPDoc blocks to improve the generated output with human-readable descriptions.

### What You'll Build

- A fully interactive Swagger UI page that documents every endpoint in your JSON:API.
- PHPDoc-enhanced controller methods with clear summaries and descriptions.
- A customized documentation configuration with your API title, version, and description.

### What You'll Learn

- How to install and configure Scramble for automatic API documentation.
- How to add PHPDoc blocks to your controllers for richer documentation.
- How to access and use the generated Swagger UI at `/docs/api`.
- How to publish and customize the Scramble configuration.
- How Scramble uses static analysis to keep documentation in sync with your code.

### What You'll Need

- The completed JSON:API project from the [previous tutorial](https://qadrlabs.com/post/build-an-api-using-jsonapi-specification-with-laravel-13).
- PHP 8.3 or higher.
- Composer installed globally.


## Step 1: Install Scramble {#step-1-install-scramble}

Scramble is a package by Dedoc that reads your Laravel routes, controller type hints, and validation rules to generate an OpenAPI 3.1 specification. Install it via Composer:

```bash
composer require dedoc/scramble
```

That is it. Scramble uses Laravel's auto-discovery feature, so the service provider is registered automatically. No need to add anything to `config/app.php` or `bootstrap/app.php`.


## Step 2: Add PHPDoc Blocks to Your Controller {#step-2-add-phpdoc-blocks}

Scramble can generate documentation from your code alone, but adding PHPDoc blocks gives you control over the summary and description text that appears in the documentation UI. Without PHPDoc blocks, Scramble will use the method name as the summary (e.g., "index", "store"), which is not very helpful for API consumers. With PHPDoc blocks, you can provide clear, descriptive titles and explanations.

Open `app/Http/Controllers/Api/ArticleController.php` and add PHPDoc blocks above each method:

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
    /**
     * Get a list of articles.
     *
     * Retrieves a paginated list of all articles along with their authors.
     *
     * @return \Illuminate\Http\Resources\Json\AnonymousResourceCollection
     */
    public function index()
    {
        $articles = Article::with('author')->paginate();

        return ArticleResource::collection($articles);
    }

    /**
     * Get a specific article.
     *
     * Retrieves the details of a single article by its ID, including the author information.
     *
     * @param \App\Models\Article $article
     * @return \App\Http\Resources\ArticleResource
     */
    public function show(Article $article)
    {
        $article->load('author');

        return new ArticleResource($article);
    }

    /**
     * Create a new article.
     *
     * Stores a newly created article in the database and returns the created resource.
     *
     * @param \Illuminate\Http\Request $request
     * @return \Illuminate\Http\JsonResponse
     */
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

    /**
     * Update an existing article.
     *
     * Updates the specified article in the database and returns the updated resource.
     *
     * @param \Illuminate\Http\Request $request
     * @param \App\Models\Article $article
     * @return \App\Http\Resources\ArticleResource
     */
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

    /**
     * Delete an article.
     *
     * Removes the specified article from the database.
     *
     * @param \App\Models\Article $article
     * @return \Illuminate\Http\Response
     */
    public function destroy(Article $article)
    {
        $article->delete();

        return response()->noContent();
    }
}
```

Each PHPDoc block has two parts that Scramble reads. The first line becomes the endpoint's **summary** (the short title displayed in the sidebar and endpoint list). The following lines become the endpoint's **description** (the longer explanation shown when you expand the endpoint). The `@param` and `@return` tags help Scramble infer the request and response types more accurately.

Save the file.


## Step 3: Seed a Test User {#step-3-seed-a-test-user}

Before testing the `POST /api/v1/articles` endpoint through the Swagger UI, you need at least one user in the database. The `store` method requires an `author_id` that must reference an existing user.

Open `database/seeders/DatabaseSeeder.php`. Laravel 13 already provides a default seeder that creates a test user:

```php
<?php

namespace Database\Seeders;

use App\Models\User;
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
        User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
        ]);
    }
}
```

This creates a single user with the name "Test User" and email "test@example.com". Run the seeder to populate your database:

```bash
php artisan migrate:fresh --seed
```

The `migrate:fresh --seed` command resets all tables and runs the seeder in one step. After this, you will have a user with `id = 1` that you can use as the `author_id` when creating articles through the documentation UI.


## Step 4: Try It Out {#step-4-try-it-out}

Start the Laravel development server if it is not already running:

```bash
php artisan serve
```

Then open your browser and navigate to:

```
http://127.0.0.1:8000/docs/api
```

You will see the Scramble Swagger UI with all five endpoints listed under the `Articles` group:

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/articles` | Get a list of articles |
| `POST` | `/api/v1/articles` | Create a new article |
| `GET` | `/api/v1/articles/{article}` | Get a specific article |
| `PUT/PATCH` | `/api/v1/articles/{article}` | Update an existing article |
| `DELETE` | `/api/v1/articles/{article}` | Delete an article |

Each endpoint shows the request body schema (derived from your validation rules), the response structure (derived from your API Resource), and the PHPDoc descriptions you added.

### Test Creating an Article

Click on the `POST /api/v1/articles` endpoint in the Swagger UI. Click the **Try it out** button. Fill in the request body with:

```json
{
    "title": "My First Article",
    "content": "This article was created from the Swagger UI.",
    "published_at": "2026-04-02",
    "author_id": 1
}
```

Click **Execute**. You should see a `201 Created` response with the article data formatted as a JSON:API resource.

### Test Listing Articles

Click on the `GET /api/v1/articles` endpoint and click **Execute**. You should see the article you just created in the paginated response.

### Test Updating an Article

Click on the `PUT /api/v1/articles/{article}` endpoint. Enter `1` for the article ID parameter. In the request body, change the title:

```json
{
    "title": "Updated Article Title"
}
```

Click **Execute**. You should see a `200 OK` response with the updated article data.

### Test Deleting an Article

Click on the `DELETE /api/v1/articles/{article}` endpoint. Enter `1` for the article ID. Click **Execute**. You should see a `204 No Content` response confirming the article was deleted.


## Step 5: Customize the Documentation {#step-5-customize-documentation}

If you want to customize the documentation title, description, or other OpenAPI metadata, publish the Scramble configuration file:

```bash
php artisan vendor:publish --provider="Dedoc\Scramble\ScrambleServiceProvider" --tag="scramble-config"
```

This creates a `config/scramble.php` file where you can adjust settings such as the API path prefix, the server URL displayed in the documentation, and the info block metadata.

For example, to change the API title and version:

```php
// config/scramble.php

return [
    'info' => [
        'title' => 'Articles JSON:API',
        'version' => '1.0.0',
        'description' => 'A RESTful JSON:API for managing articles.',
    ],
];
```

After saving the file, refresh the Swagger UI page. The header should now display your custom title, version, and description.

Save the file.


## How Scramble Works Under the Hood {#how-scramble-works}

Scramble does not rely on annotations or attributes you write manually. Instead, it uses static analysis to read your actual PHP code. Here is what it inspects:

**Routes**: Scramble scans `routes/api.php` to discover all API endpoints, their HTTP methods, and URI patterns.

**Validation rules**: When your controller calls `$request->validate([...])`, Scramble reads the rules to determine the request body schema. For example, `'title' => 'required|string|max:255'` becomes a required string field with a max length of 255 in the OpenAPI spec.

**Type hints and return types**: Scramble uses method signatures and `@return` PHPDoc tags to determine the response structure.

**API Resources**: If your controller returns an `ArticleResource`, Scramble inspects that class to build the response schema, including all the fields defined in the `toArray()` method.

**Route Model Binding**: When a method accepts `Article $article`, Scramble knows that `{article}` is a path parameter bound to the `Article` model.

This approach means your documentation always stays in sync with your actual code. When you add a new validation rule, change a return type, or add a new field to your API Resource, the documentation updates automatically the next time you refresh the Swagger UI.


## Conclusion {#conclusion}

In this tutorial, we added automatic API documentation to our existing JSON:API project using Scramble. With a single Composer install and some PHPDoc blocks, we generated a fully interactive Swagger UI that stays in sync with our code.

Here are the key takeaways:

- **Scramble generates documentation from your existing code.** It reads routes, validation rules, type hints, and API Resources to build an OpenAPI 3.1 specification. No manual annotations or separate documentation files required.
- **Installation is a single command.** `composer require dedoc/scramble` is all you need. Auto-discovery handles the service provider registration.
- **PHPDoc blocks improve the output.** The first line becomes the endpoint summary, the following lines become the description. Without them, Scramble falls back to method names, which are less informative.
- **The Swagger UI is interactive.** API consumers can explore endpoints, see request/response schemas, and test requests directly from `http://127.0.0.1:8000/docs/api` without needing Postman or cURL.
- **Documentation stays in sync automatically.** Because Scramble reads your actual code via static analysis, there is no risk of the docs drifting out of date. Change a validation rule, and the docs update on the next page load.
- **Configuration is optional but useful.** Publishing `config/scramble.php` lets you customize the API title, version, and description that appear in the Swagger UI header.