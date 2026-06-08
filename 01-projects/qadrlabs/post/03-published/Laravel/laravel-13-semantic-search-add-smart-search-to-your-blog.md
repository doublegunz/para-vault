---
title: "Laravel 13 Semantic Search: Add Smart Search to Your Blog"
slug: "laravel-13-semantic-search-add-smart-search-to-your-blog"
category: "Laravel"
date: "2026-03-26"
status: "published"
---

Traditional search finds posts by matching keywords. Type "cooking tips" and you get results that contain those exact words. But what about a post titled "How to Make the Perfect Pasta at Home"? It is clearly related to cooking, but a keyword search would miss it entirely.

Semantic search solves this by understanding the meaning behind your query, not just the words. Laravel 13 makes this possible with native vector query support and tight integration with PostgreSQL's `pgvector` extension.

This is Part 5 of our Laravel 13 blog tutorial series, following the [CRUD tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step), the [testing tutorial](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application), the [Form Request refactoring tutorial](https://qadrlabs.com/post/laravel-13-refactor-your-controller-with-form-request-validation), and the [authentication and authorization tutorial](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes). We will add semantic search to the existing blog so users can find posts by meaning, not just by exact keyword matches.

> **Note:** This tutorial has not been fully tested end-to-end due to limited access to an AI embedding provider. The code and concepts are based on the official Laravel 13 documentation and the pgvector extension documentation. If you encounter issues during implementation, please refer to the [Laravel 13 docs](https://laravel.com/docs/13.x) and the [pgvector GitHub repository](https://github.com/pgvector/pgvector).


## How Semantic Search Works {#how-semantic-search-works}

Before jumping into code, let's understand the concept. Semantic search works in three steps:

1. **Convert text to embeddings.** An embedding is a numerical vector (an array of numbers) that represents the meaning of a piece of text. Texts with similar meanings have vectors that are close together in mathematical space. For example, the embeddings for "cooking tips" and "pasta recipe" would be close to each other, while "car repair" would be far away.

2. **Store embeddings in the database.** Each post gets an embedding column that stores the vector representation of its content.

3. **Search by similarity.** When a user searches, their query is also converted into an embedding. The database then finds posts whose embeddings are closest to the query embedding, returning the most semantically relevant results.

Laravel 13 provides the pieces to make this work: the AI SDK can generate embeddings, PostgreSQL with `pgvector` stores and indexes them, and the query builder offers both `whereVectorSimilarTo()` (with AI SDK) and raw distance operators (without AI SDK) for similarity search.


## Overview {#overview}

We will add a semantic search feature to the blog application. This tutorial demonstrates two approaches: one that uses the AI SDK for automatic embedding generation and search, and one that works with manually inserted vectors using pgvector's raw distance operators.

### What You'll Build

- A vector column on the posts table for storing embeddings.
- A seeder that inserts sample posts with pre-defined embedding vectors.
- A search endpoint with two approaches: raw cosine similarity (no AI SDK needed) and `whereVectorSimilarTo()` (requires AI SDK).
- A search bar on the posts index page.
- An Artisan command to generate embeddings using the AI SDK (requires API key).
- A model observer to automate embedding generation (requires API key).

### What You'll Learn

- How to set up PostgreSQL with the `pgvector` extension in a Laravel project.
- How to store and query vector data manually (without an AI provider).
- How to use raw distance operators (`<=>`) for similarity search.
- How to use `whereVectorSimilarTo()` with the AI SDK.
- How to configure Pest tests to use PostgreSQL instead of SQLite.

### What You'll Need

- The completed blog project from the previous tutorials.
- PostgreSQL 15+ with the `pgvector` extension installed. If you need help setting this up, see our [pgvector setup tutorial](https://qadrlabs.com/post/getting-started-with-pgvector-set-up-vector-search-in-postgresql-on-ubuntu-2504).
- PHP 8.3 or higher with the `pdo_pgsql` extension.
- An AI provider API key (OpenAI, etc.) is **optional**. You can follow most of this tutorial without one.


## Step 1: Switch to PostgreSQL {#step-1-switch-to-postgresql}

The blog series so far has been using MySQL. Since vector search requires PostgreSQL with the `pgvector` extension, we need to switch the database.

### Install pgvector

If you have not installed PostgreSQL and pgvector yet, follow the instructions in our [pgvector setup tutorial](https://qadrlabs.com/post/getting-started-with-pgvector-set-up-vector-search-in-postgresql-on-ubuntu-2504). On Ubuntu, the quick version is:

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib -y
sudo apt install postgresql-17-pgvector -y
```

Replace `17` with your PostgreSQL version if different.

### Update the Database Configuration

Open `.env` and update the database settings:

```
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=db_belajar_laravel
DB_USERNAME=postgres
DB_PASSWORD=password
```

**Note:** Adjust the credentials to match your local PostgreSQL setup.

Make sure the `pdo_pgsql` PHP extension is installed. You can verify with:

```
php -m | grep pgsql
```

If it is not listed, install it for your PHP version (e.g., `sudo apt install php8.4-pgsql` on Ubuntu).

### Run the Migrations

Since we are using a new database, run all migrations from scratch:

```
php artisan migrate
```

This creates the `users`, `posts`, and all other tables in PostgreSQL.


## Step 2: Set Up pgvector and Add the Embedding Column {#step-2-add-embedding-column}

### Enable the pgvector Extension

Installing pgvector on your system is not enough; it needs to be activated per database. The cleanest way to handle this in Laravel is with a migration:

```
php artisan make:migration enable_pgvector_extension
```

Open the generated migration file and add:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::statement('CREATE EXTENSION IF NOT EXISTS vector');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement('DROP EXTENSION IF EXISTS vector');
    }
};
```

`CREATE EXTENSION IF NOT EXISTS vector` tells PostgreSQL to load the `pgvector` extension, which registers the `vector` data type and the similarity operators we will use later.

Run this migration:

```
php artisan migrate
```

**Important:** This migration must run before the embedding column migration. Since Laravel runs migrations in chronological order based on the filename timestamp, make sure the extension migration has an earlier timestamp.

### Add the Embedding Column

Create a migration to add the vector column to the posts table:

```
php artisan make:migration add_embedding_to_posts_table --table=posts
```

Open the generated migration file and add:

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
        Schema::table('posts', function (Blueprint $table) {
            $table->vector('embedding', dimensions: 5)->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->dropColumn('embedding');
        });
    }
};
```

We use `dimensions: 5` intentionally. In a production application with a real embedding model, you would use higher dimensions (768 for `nomic-embed-text`, 1536 for OpenAI's `text-embedding-3-small`, etc.). We use 5 dimensions here so we can insert sample data manually and keep the examples readable. When you integrate a real AI provider later, create a new migration to change the dimension count.

The column is `nullable()` because existing posts will not have embeddings until we generate or insert them.

Run the migration:

```
php artisan migrate
```

### Update the Post Model

Open `app/Models/Post.php` and add `embedding` to the `#[Fillable]` attribute:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['title', 'slug', 'content', 'status', 'user_id', 'embedding'])]
class Post extends Model
{
    use HasFactory;

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

Save the file.


## Step 3: Seed Sample Data with Manual Embeddings {#step-3-seed-sample-data}

Before building the search feature, we need posts with embedding data. Since we are using 5-dimensional vectors, we can insert them manually, just like we did in the [pgvector tutorial](https://qadrlabs.com/post/getting-started-with-pgvector-set-up-vector-search-in-postgresql-on-ubuntu-2504).

The key idea: posts about similar topics get similar vectors, and posts about different topics get different vectors. This simulates what a real embedding model would produce.

Create a seeder:

```
php artisan make:seeder PostSeeder
```

Open `database/seeders/PostSeeder.php` and add:

```php
<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PostSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $user = User::factory()->create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
        ]);

        $posts = [
            // Cooking / Food posts (similar vectors: high first two dimensions)
            [
                'title' => 'How to Make the Perfect Pasta at Home',
                'slug' => 'how-to-make-the-perfect-pasta-at-home',
                'content' => 'Making pasta from scratch is easier than you think. Start with flour, eggs, and a pinch of salt. Knead the dough until smooth, then roll it out and cut into your desired shape.',
                'status' => 'publish',
                'embedding' => '[0.9, 0.85, 0.1, 0.15, 0.2]',
            ],
            [
                'title' => '10 Quick and Healthy Breakfast Ideas',
                'slug' => '10-quick-and-healthy-breakfast-ideas',
                'content' => 'Start your morning right with these nutritious breakfast options. From overnight oats to smoothie bowls, these recipes take less than 15 minutes to prepare.',
                'status' => 'publish',
                'embedding' => '[0.85, 0.8, 0.15, 0.2, 0.25]',
            ],
            [
                'title' => 'Essential Kitchen Tools Every Home Cook Needs',
                'slug' => 'essential-kitchen-tools-every-home-cook-needs',
                'content' => 'A well-equipped kitchen makes cooking enjoyable. Here are the must-have tools: a sharp chef knife, cutting board, cast iron skillet, and a good set of measuring cups.',
                'status' => 'publish',
                'embedding' => '[0.8, 0.75, 0.2, 0.1, 0.15]',
            ],

            // Technology posts (similar vectors: high middle dimensions)
            [
                'title' => 'Getting Started with Machine Learning in Python',
                'slug' => 'getting-started-with-machine-learning-in-python',
                'content' => 'Machine learning allows computers to learn from data. This guide covers setting up your Python environment, understanding basic algorithms, and building your first model.',
                'status' => 'publish',
                'embedding' => '[0.1, 0.15, 0.9, 0.85, 0.2]',
            ],
            [
                'title' => 'Understanding Cloud Computing for Beginners',
                'slug' => 'understanding-cloud-computing-for-beginners',
                'content' => 'Cloud computing delivers computing services over the internet. Learn about IaaS, PaaS, and SaaS, and understand when to use each type for your projects.',
                'status' => 'publish',
                'embedding' => '[0.15, 0.2, 0.85, 0.8, 0.25]',
            ],
            [
                'title' => 'Web Security Best Practices for Developers',
                'slug' => 'web-security-best-practices-for-developers',
                'content' => 'Protect your web applications from common vulnerabilities. This article covers CSRF protection, SQL injection prevention, XSS mitigation, and secure authentication practices.',
                'status' => 'publish',
                'embedding' => '[0.2, 0.15, 0.8, 0.9, 0.3]',
            ],

            // Travel / Lifestyle posts (similar vectors: high last dimensions)
            [
                'title' => 'A Complete Guide to Backpacking in Southeast Asia',
                'slug' => 'a-complete-guide-to-backpacking-in-southeast-asia',
                'content' => 'Southeast Asia is a paradise for budget travelers. This guide covers the best routes, affordable accommodations, must-try street food, and cultural tips for first-time backpackers.',
                'status' => 'publish',
                'embedding' => '[0.2, 0.1, 0.15, 0.25, 0.9]',
            ],
            [
                'title' => 'How to Plan a Road Trip on a Budget',
                'slug' => 'how-to-plan-a-road-trip-on-a-budget',
                'content' => 'Road trips do not have to be expensive. Learn how to save on fuel, find free camping spots, pack smart, and use travel apps to plan the most scenic routes.',
                'status' => 'publish',
                'embedding' => '[0.15, 0.2, 0.1, 0.3, 0.85]',
            ],
            [
                'title' => 'Building Healthy Habits for a Better Life',
                'slug' => 'building-healthy-habits-for-a-better-life',
                'content' => 'Small daily habits compound into big results. This post explores morning routines, exercise consistency, mindful eating, and the science behind habit formation.',
                'status' => 'publish',
                'embedding' => '[0.5, 0.6, 0.3, 0.2, 0.7]',
            ],
            [
                'title' => 'The Art of Minimalist Living',
                'slug' => 'the-art-of-minimalist-living',
                'content' => 'Minimalism is about intentionally living with only the things you truly need. Declutter your space, simplify your schedule, and focus on what brings you genuine joy.',
                'status' => 'draft',
                'embedding' => '[0.4, 0.5, 0.25, 0.15, 0.75]',
            ],
        ];

        foreach ($posts as $post) {
            DB::table('posts')->insert(array_merge($post, [
                'user_id' => $user->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]));
        }
    }
}
```

Notice how the embeddings are grouped by topic:

- **Cooking posts** have high values in the first two dimensions: `[0.9, 0.85, 0.1, ...]`, `[0.85, 0.8, 0.15, ...]`
- **Technology posts** have high values in the middle dimensions: `[0.1, 0.15, 0.9, 0.85, ...]`
- **Travel/Lifestyle posts** have high values in the last dimensions: `[0.2, 0.1, 0.15, 0.25, 0.9]`

This pattern simulates how a real embedding model clusters similar content together in vector space. Posts about cooking will be close to each other and far from posts about technology.

We use `DB::table('posts')->insert()` instead of `Post::create()` to insert the embedding as a raw string value, which pgvector parses directly. This is the same format we used in the [pgvector tutorial](https://qadrlabs.com/post/getting-started-with-pgvector-set-up-vector-search-in-postgresql-on-ubuntu-2504).

Run the seeder:

```
php artisan db:seed --class=PostSeeder
```

You can verify the data in the terminal by connecting to PostgreSQL:

```
sudo -i -u postgres
psql -d db_belajar_laravel -c "SELECT id, title, embedding FROM posts;"
```


## Step 4: Build the Search Feature (Without AI SDK) {#step-4-build-search-without-ai}

Let's start with the approach that does not require an AI provider. We will use pgvector's cosine distance operator (`<=>`) directly in the query builder.

### Add a Search Method to the Controller

Open `app/Http/Controllers/PostController.php` and add the `search()` method. You will also need to add the `Request` and `DB` imports:

```php
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

// Inside PostController class:

/**
 * Search posts by vector similarity.
 */
public function search(Request $request)
{
    $request->validate([
        'q' => 'required|string|max:500',
    ]);

    $query = $request->input('q');
    $posts = collect();

    // Approach 1: Raw cosine similarity (no AI SDK needed)
    // Uses a pre-defined query vector based on topic keywords
    $queryVector = $this->getQueryVector($query);

    if ($queryVector) {
        $posts = DB::table('posts')
            ->selectRaw("*, embedding <=> ? AS distance", [$queryVector])
            ->whereNotNull('embedding')
            ->orderByRaw("embedding <=> ?", [$queryVector])
            ->limit(10)
            ->get();
    }

    return view('posts.search', compact('posts', 'query'));
}

/**
 * Map search keywords to pre-defined query vectors.
 *
 * In production, this would be replaced by an AI embedding model
 * that converts any text into a vector automatically.
 */
protected function getQueryVector(string $query): ?string
{
    $query = strtolower($query);

    // Pre-defined vectors for common search topics
    // These match the patterns used in our seeded data
    $topicVectors = [
        'cooking'    => '[0.9, 0.85, 0.1, 0.15, 0.2]',
        'food'       => '[0.85, 0.8, 0.15, 0.2, 0.25]',
        'recipe'     => '[0.88, 0.82, 0.12, 0.18, 0.22]',
        'kitchen'    => '[0.8, 0.75, 0.2, 0.1, 0.15]',
        'pasta'      => '[0.9, 0.85, 0.1, 0.15, 0.2]',
        'breakfast'  => '[0.85, 0.8, 0.15, 0.2, 0.25]',
        'technology' => '[0.1, 0.15, 0.9, 0.85, 0.2]',
        'programming'=> '[0.15, 0.2, 0.85, 0.8, 0.25]',
        'python'     => '[0.1, 0.15, 0.9, 0.85, 0.2]',
        'security'   => '[0.2, 0.15, 0.8, 0.9, 0.3]',
        'cloud'      => '[0.15, 0.2, 0.85, 0.8, 0.25]',
        'machine learning' => '[0.1, 0.15, 0.9, 0.85, 0.2]',
        'travel'     => '[0.2, 0.1, 0.15, 0.25, 0.9]',
        'backpacking'=> '[0.2, 0.1, 0.15, 0.25, 0.9]',
        'road trip'  => '[0.15, 0.2, 0.1, 0.3, 0.85]',
        'lifestyle'  => '[0.4, 0.5, 0.25, 0.15, 0.75]',
        'minimalism' => '[0.4, 0.5, 0.25, 0.15, 0.75]',
        'habits'     => '[0.5, 0.6, 0.3, 0.2, 0.7]',
        'health'     => '[0.5, 0.6, 0.3, 0.2, 0.7]',
    ];

    // Check if the query matches any known topic
    foreach ($topicVectors as $topic => $vector) {
        if (str_contains($query, $topic)) {
            return $vector;
        }
    }

    // Default: return a neutral vector
    return '[0.5, 0.5, 0.5, 0.5, 0.5]';
}
```

Here is how this works:

- `embedding <=> ?` is pgvector's cosine distance operator. It calculates how different two vectors are, with 0 meaning identical and 2 meaning opposite.
- `selectRaw()` adds the distance as a column so you can display it in the view.
- `orderByRaw()` sorts results by cosine distance (smallest first = most similar).
- `whereNotNull('embedding')` skips posts that do not have an embedding yet.
- `getQueryVector()` maps search keywords to pre-defined vectors that match the patterns in our seeded data.

**This is the key limitation of the manual approach.** Without an AI embedding model, you can only search for topics you have pre-defined vectors for. A real embedding model would convert any arbitrary text into a meaningful vector.

Save the file.


## Step 5: Add the Search Route and Views {#step-5-search-route-and-views}

### Add the Search Route

Open `routes/web.php` and add the search route **before** the resource route:

```php
<?php

use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\PostController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Authentication routes
Route::get('/login', [LoginController::class, 'showLoginForm'])->name('login');
Route::post('/login', [LoginController::class, 'login']);
Route::post('/logout', [LoginController::class, 'logout'])->name('logout');

Route::get('/posts/search', [PostController::class, 'search'])->name('posts.search');
Route::resource('posts', PostController::class);
```

The search route must come before `Route::resource()`. Otherwise, Laravel would interpret `/posts/search` as `/posts/{post}` and try to find a post with the ID "search", resulting in a 404.

Save the file.

### Create the Search Results View

Create a new file at `resources/views/posts/search.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Search Results</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-4xl mx-auto">
        <div class="bg-white p-6 md:p-8 rounded-lg shadow-md mb-6">
            <div class="flex justify-between items-center mb-6">
                <h1 class="text-2xl font-bold text-gray-900">Search Posts</h1>
                <a href="{{ route('posts.index') }}" class="text-gray-600 hover:text-gray-900 underline text-sm transition">Back to Manage Posts</a>
            </div>

            <form action="{{ route('posts.search') }}" method="GET">
                <div class="flex gap-3">
                    <input type="text" name="q" value="{{ $query ?? '' }}" placeholder="Try: cooking, technology, travel..."
                        class="flex-1 px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
                    <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-6 rounded-md transition duration-200 shadow-sm">
                        Search
                    </button>
                </div>
            </form>
        </div>

        @if(isset($posts))
            @if($posts->count() > 0)
                <p class="text-sm text-gray-500 mb-4">Found {{ $posts->count() }} results for "{{ $query }}"</p>
                <div class="space-y-4">
                    @foreach($posts as $post)
                    <div class="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition duration-200">
                        <h2 class="text-xl font-bold text-gray-900 mb-2">
                            <a href="{{ route('posts.show', $post->id) }}" class="hover:text-blue-600 transition">{{ $post->title }}</a>
                        </h2>
                        <p class="text-gray-600 text-sm mb-3">{{ Str::limit($post->content, 200) }}</p>
                        <div class="flex items-center space-x-4 text-xs text-gray-500">
                            <span class="px-2 py-0.5 rounded-full {{ $post->status === 'publish' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800' }}">
                                {{ ucfirst($post->status) }}
                            </span>
                            <span>{{ \Carbon\Carbon::parse($post->created_at)->format('M d, Y') }}</span>
                            @if(isset($post->distance))
                                <span class="text-blue-600">Similarity: {{ number_format(1 - $post->distance, 4) }}</span>
                            @endif
                        </div>
                    </div>
                    @endforeach
                </div>
            @else
                <div class="bg-white p-6 rounded-lg shadow-md text-center text-gray-500">
                    No posts found matching your search.
                </div>
            @endif
        @endif
    </div>

    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial Semantic Search Laravel 13 at qadrlabs.com</a>
    </div>
</body>
</html>
```

The view includes a similarity score calculated as `1 - distance`. Since cosine distance ranges from 0 (identical) to 2 (opposite), subtracting from 1 gives an intuitive score where higher means more similar.

Save the file.

### Add a Search Bar to the Index Page

Open `resources/views/posts/index.blade.php` and add a search form below the header section (after the closing `</div>` of the header and before the `@if(session('success'))` block):

```html
<div class="mb-6">
    <form action="{{ route('posts.search') }}" method="GET" class="flex gap-3">
        <input type="text" name="q" placeholder="Search posts by meaning (try: cooking, technology, travel)..."
            class="flex-1 px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition text-sm">
        <button type="submit" class="bg-gray-800 hover:bg-gray-900 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm text-sm">
            Search
        </button>
    </form>
</div>
```

Save the file.


## Step 6: Upgrade to AI-Powered Search (Optional) {#step-6-ai-powered-search}

The manual approach in Step 4 works for demonstration purposes, but it is limited to pre-defined keywords. To search with any arbitrary text, you need an AI embedding model. This step requires an API key from an AI provider (such as OpenAI).

> **Note:** If you do not have access to an AI provider, you can skip this step. The manual approach from Step 4 is sufficient for understanding how vector search works in Laravel.

### Install the AI SDK

```
composer require laravel/ai
```

Publish the configuration file:

```
php artisan vendor:publish --tag=ai-config
```

Add your AI provider credentials to `.env`:

```
AI_PROVIDER=openai
OPENAI_API_KEY=sk-your-api-key-here
```

### Update the Vector Dimensions

AI models produce higher-dimensional vectors. If you are using OpenAI's `text-embedding-3-small`, create a new migration to change the dimension count:

```
php artisan make:migration update_embedding_dimensions --table=posts
```

```php
public function up(): void
{
    Schema::table('posts', function (Blueprint $table) {
        $table->dropColumn('embedding');
    });

    Schema::table('posts', function (Blueprint $table) {
        $table->vector('embedding', dimensions: 1536)->nullable();
    });
}
```

Run the migration. This will drop existing manual embeddings, which you will regenerate using the AI SDK.

### Update the Search Method

With the AI SDK installed, you can replace the manual search approach with `whereVectorSimilarTo()`. Update the `search()` method in `PostController`:

```php
/**
 * Search posts by semantic similarity using AI SDK.
 */
public function search(Request $request)
{
    $request->validate([
        'q' => 'required|string|max:500',
    ]);

    $query = $request->input('q');

    $posts = DB::table('posts')
        ->whereVectorSimilarTo('embedding', $query)
        ->limit(10)
        ->get();

    return view('posts.search', compact('posts', 'query'));
}
```

`whereVectorSimilarTo('embedding', $query)` handles the entire flow automatically: it converts the `$query` string into an embedding using the AI SDK, performs a cosine similarity search against the `embedding` column, and orders results by relevance. You no longer need the `getQueryVector()` helper method.

### Build an Artisan Command for Batch Embedding Generation

Create a command to generate embeddings for existing posts:

```
php artisan make:command GeneratePostEmbeddings
```

Open `app/Console/Commands/GeneratePostEmbeddings.php`:

```php
<?php

namespace App\Console\Commands;

use App\Models\Post;
use Illuminate\Console\Command;
use Illuminate\Support\Str;

class GeneratePostEmbeddings extends Command
{
    protected $signature = 'posts:generate-embeddings
                            {--force : Regenerate embeddings for all posts}';

    protected $description = 'Generate embeddings for posts using the AI SDK';

    public function handle(): int
    {
        $query = Post::query();

        if (! $this->option('force')) {
            $query->whereNull('embedding');
        }

        $posts = $query->get();

        if ($posts->isEmpty()) {
            $this->info('No posts need embedding generation.');
            return self::SUCCESS;
        }

        $this->info("Generating embeddings for {$posts->count()} posts...");

        $bar = $this->output->createProgressBar($posts->count());
        $bar->start();

        foreach ($posts as $post) {
            $text = $post->title . ' ' . $post->content;
            $embedding = Str::of($text)->toEmbeddings();
            $post->update(['embedding' => $embedding]);
            $bar->advance();
        }

        $bar->finish();
        $this->newLine();
        $this->info('Done! All embeddings generated successfully.');

        return self::SUCCESS;
    }
}
```

`Str::of($text)->toEmbeddings()` is a Laravel 13 convenience method that calls the configured AI provider to generate an embedding vector. It combines the title and content for richer context.

Run it with:

```
php artisan posts:generate-embeddings
```

### Automate with a Model Observer

To generate embeddings automatically when posts are created or updated, create an observer:

```
php artisan make:observer PostObserver --model=Post
```

Open `app/Observers/PostObserver.php`:

```php
<?php

namespace App\Observers;

use App\Models\Post;
use Illuminate\Support\Str;

class PostObserver
{
    public function created(Post $post): void
    {
        $this->generateEmbedding($post);
    }

    public function updated(Post $post): void
    {
        if ($post->wasChanged(['title', 'content'])) {
            $this->generateEmbedding($post);
        }
    }

    protected function generateEmbedding(Post $post): void
    {
        $text = $post->title . ' ' . $post->content;
        $embedding = Str::of($text)->toEmbeddings();

        $post->withoutEvents(function () use ($post, $embedding) {
            $post->update(['embedding' => $embedding]);
        });
    }
}
```

Key details:

- `wasChanged(['title', 'content'])` prevents unnecessary API calls when only the status or other fields change.
- `withoutEvents()` prevents an infinite loop. Without it, `$post->update()` inside the `updated` event would trigger `updated` again.

Register the observer in `app/Providers/AppServiceProvider.php`:

```php
use App\Models\Post;
use App\Observers\PostObserver;

public function boot(): void
{
    Post::observe(PostObserver::class);
}
```


## Step 7: Configure Tests for PostgreSQL {#step-7-configure-tests}

The existing test suite uses SQLite in-memory, but SQLite does not support the `vector` data type. We need to switch tests to use PostgreSQL.

### Create a Test Database

Create a separate PostgreSQL database for testing and enable the pgvector extension:

```bash
sudo -i -u postgres
psql -c "CREATE DATABASE db_belajar_laravel_test;"
psql -d db_belajar_laravel_test -c "CREATE EXTENSION IF NOT EXISTS vector;"
exit
```

### Update phpunit.xml

Open `phpunit.xml` and update the database environment variables:

```xml
    <php>
        <env name="APP_ENV" value="testing"/>
        <env name="APP_MAINTENANCE_DRIVER" value="file"/>
        <env name="BCRYPT_ROUNDS" value="4"/>
        <env name="BROADCAST_CONNECTION" value="null"/>
        <env name="CACHE_STORE" value="array"/>
        <env name="DB_CONNECTION" value="pgsql"/>
        <env name="DB_DATABASE" value="db_belajar_laravel_test"/>
        <env name="MAIL_MAILER" value="array"/>
        <env name="QUEUE_CONNECTION" value="sync"/>
        <env name="SESSION_DRIVER" value="array"/>
        <env name="PULSE_ENABLED" value="false"/>
        <env name="TELESCOPE_ENABLED" value="false"/>
        <env name="NIGHTWATCH_ENABLED" value="false"/>
    </php>
```

The key changes: `DB_CONNECTION` is now `pgsql` and `DB_DATABASE` points to `db_belajar_laravel_test`.

### Add Search Tests

Open `tests/Feature/PostControllerTest.php` and add the `DB` import at the top of the file:

```php
use Illuminate\Support\Facades\DB;
```

Then add the following tests at the end of the file:

```php
// ============================================================
// Search Tests
// ============================================================

test('search page returns results for a valid query', function () {
    // Insert a post with a manual embedding via DB
    DB::table('posts')->insert([
        'title' => 'Cooking with Passion',
        'slug' => 'cooking-with-passion',
        'content' => 'A guide to becoming a better home cook.',
        'status' => 'publish',
        'user_id' => $this->user->id,
        'embedding' => '[0.9, 0.85, 0.1, 0.15, 0.2]',
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    $response = $this->actingAs($this->user)
        ->get(route('posts.search', ['q' => 'cooking']));

    $response->assertStatus(200);
    $response->assertViewIs('posts.search');
    $response->assertSee('Cooking with Passion');
});

test('search requires a query parameter', function () {
    $response = $this->actingAs($this->user)->get(route('posts.search'));

    $response->assertSessionHasErrors(['q']);
});

test('search query cannot exceed 500 characters', function () {
    $response = $this->actingAs($this->user)->get(route('posts.search', [
        'q' => str_repeat('a', 501),
    ]));

    $response->assertSessionHasErrors(['q']);
});

test('unauthenticated user is redirected to login from search', function () {
    $response = $this->get(route('posts.search', ['q' => 'test']));

    $response->assertRedirect(route('login'));
});

test('search returns empty state when no posts have embeddings', function () {
    $response = $this->actingAs($this->user)
        ->get(route('posts.search', ['q' => 'cooking']));

    $response->assertStatus(200);
    $response->assertSee('No posts found matching your search.');
});
```

The first test inserts a post with a manual embedding using `DB::table()`, then searches for "cooking" and verifies the post appears in the results. This works because the `getQueryVector()` method maps "cooking" to a vector that is close to the post's embedding.

Save the file and run:

```
php artisan test
```

> **Note:** Since the test database now uses PostgreSQL instead of SQLite, make sure PostgreSQL is running and the test database exists before running tests. Some of the existing tests that do not involve vector columns will also work with PostgreSQL. However, if you encounter issues, check that the `RefreshDatabase` trait is properly migrating the test database.


## Step 8: Try It Out {#step-8-try-it-out}

Start the development server:

```
php artisan serve
```

Open `http://127.0.0.1:8000/posts` and use the search bar. Try these queries with the seeded data:

- **"cooking"** should return the pasta, breakfast, and kitchen posts first.
- **"technology"** should return the machine learning, cloud computing, and security posts first.
- **"travel"** should return the backpacking and road trip posts first.
- **"health"** should return the healthy habits post and lifestyle-related posts.

The results are ordered by cosine similarity. Posts with embeddings closest to the query vector appear first, even if the exact keyword does not appear in the title or content.

### Understanding the Results

When you search for "cooking", the query vector `[0.9, 0.85, 0.1, 0.15, 0.2]` is compared against every post's embedding. The pasta post (`[0.9, 0.85, 0.1, 0.15, 0.2]`) has a distance of nearly 0, making it the top result. Technology posts like machine learning (`[0.1, 0.15, 0.9, 0.85, 0.2]`) have a large distance and appear at the bottom.

This is the core principle of semantic search: similar content clusters together in vector space.


## Summary: Two Approaches Compared {#two-approaches-compared}

| Aspect | Manual Vectors (Step 4) | AI SDK (Step 6) |
|--------|------------------------|-----------------|
| API key required | No | Yes |
| Search any text | No (pre-defined topics only) | Yes (any arbitrary text) |
| Embedding generation | Manual insertion | Automatic via `Str::of()->toEmbeddings()` |
| Search method | `orderByRaw('embedding <=> ?')` | `whereVectorSimilarTo()` |
| Vector dimensions | Any (we used 5) | Depends on model (768, 1536, etc.) |
| Production ready | No | Yes |

The manual approach is useful for learning and prototyping. The AI SDK approach is what you would use in a real application.


## Conclusion {#conclusion}

In this tutorial, we added semantic search to our Laravel 13 blog application. We switched to PostgreSQL with pgvector, seeded posts with manual embeddings, built a search feature using raw cosine distance operators, and covered how to upgrade to AI-powered search with the Laravel AI SDK.

Here are the key takeaways:

- **pgvector brings vector search to PostgreSQL.** You do not need a separate vector database. The `vector` column type and distance operators (`<=>`, `<->`, `<#>`) work alongside your existing tables, joins, and SQL.
- **You can start without an AI provider.** By inserting embeddings manually and using raw distance operators (`orderByRaw('embedding <=> ?')`), you can build and test the entire search pipeline without an API key.
- **`whereVectorSimilarTo()` automates the full pipeline.** When you have an AI provider configured, this Laravel 13 query builder method converts the search text to an embedding and performs similarity search in one call.
- **Tests need PostgreSQL, not SQLite.** The `vector` data type is pgvector-specific. Configure a separate PostgreSQL test database in `phpunit.xml` to run tests that involve vector columns.
- **Enable the pgvector extension via migration.** Using `DB::statement('CREATE EXTENSION IF NOT EXISTS vector')` in a migration keeps your database setup reproducible and version-controlled.
- **Cosine distance (`<=>`) is the recommended default.** It measures the angle between vectors regardless of magnitude, making it reliable for most embedding models.

> **Reminder:** This tutorial has not been fully tested end-to-end due to limited access to an AI embedding provider. The manual vector approach (Steps 1-5) works independently, while the AI SDK approach (Step 6) requires a configured provider. Please refer to the official documentation if you encounter issues.

From here, you could integrate a real embedding model (OpenAI, Ollama, or another provider), add search result pagination, combine vector search with keyword search for hybrid results, or build an HNSW index for better performance on large datasets.