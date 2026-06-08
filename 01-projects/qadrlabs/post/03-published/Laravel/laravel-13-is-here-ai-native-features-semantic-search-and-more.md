---
title: "Laravel 13 Is Here: AI-Native Features, Semantic Search, and More"
slug: "laravel-13-is-here-ai-native-features-semantic-search-and-more"
category: "Laravel"
date: "2026-03-21"
status: "published"
---

Laravel 13 officially dropped on **March 17, 2026**, keeping up with the framework's predictable yearly release schedule. This version puts a strong emphasis on AI-native development workflows, tighter defaults, and more expressive APIs, all while keeping breaking changes to a minimum.

Let's walk through what's new and how to get started.

## Support Policy {#support-policy}

Laravel maintains a consistent support window across all major releases: 18 months of bug fixes and 2 years of security patches. Only the latest major version of additional first-party libraries receives active bug fix support.

Here's how Laravel 13 fits into the current support timeline:

| Version | PHP        | Release             | Bug Fixes Until     | Security Fixes Until |
|---------|------------|---------------------|---------------------|----------------------|
| 10      | 8.1 - 8.3 | February 14, 2023   | August 6, 2024      | February 4, 2025     |
| 11      | 8.2 - 8.4 | March 12, 2024      | September 3, 2025   | March 12, 2026       |
| 12      | 8.2 - 8.5 | February 24, 2025   | August 13, 2026     | February 24, 2027    |
| 13      | 8.3 - 8.5 | March 17, 2026      | Q3 2027             | March 17, 2028       |

With Laravel 11 reaching the end of its security fix window this month, now is a good time to start planning your upgrade path.


## Minimal Breaking Changes {#minimal-breaking-changes}

One of the defining goals of this release cycle was to keep breaking changes as few as possible. The Laravel team focused on shipping continuous quality-of-life improvements throughout the year, improvements that don't disrupt existing applications.

As a result, upgrading to Laravel 13 should be a relatively lightweight process for most projects. You get a substantial batch of new capabilities without needing to rewrite large portions of your application code.


## PHP 8.3 {#minimum-php-version}

Laravel 13 raises the minimum PHP requirement to **8.3**. If you're still running an older version, you'll need to update your PHP installation before making the jump. The supported range extends up to PHP 8.5.


## Laravel AI SDK {#laravel-ai-sdk}

Perhaps the most exciting addition in this release is the first-party **Laravel AI SDK**. It provides a unified, provider-agnostic API for common AI tasks including text generation, tool-calling agents, embeddings, image creation, audio synthesis, and vector-store integrations. Everything is wrapped in a familiar, Laravel-native developer experience.

### Building an AI Agent

Creating an AI-powered agent is as simple as calling a single method. Here, a `SalesCoach` agent class processes a prompt and returns a response:

```php
use App\Ai\Agents\SalesCoach;

$response = SalesCoach::make()->prompt('Analyze this sales transcript...');

return (string) $response;
```

The `SalesCoach::make()` factory instantiates the agent, and `prompt()` sends the input text. The response can be cast to a string for direct output. You define each agent as its own class, so your AI logic stays organized and testable.

### Generating Images

The SDK includes a clean API for creating images from natural-language descriptions:

```php
use Laravel\Ai\Image;

$image = Image::of('A donut sitting on the kitchen counter')->generate();

$rawContent = (string) $image;
```

`Image::of()` accepts a plain-text prompt describing what you want, and `generate()` calls the configured image provider behind the scenes. The result can be cast to a string to get the raw image content (bytes), which you can then store, serve, or manipulate as needed.

### Synthesizing Audio

For voice-driven features like virtual assistants, narration, or accessibility enhancements, the SDK lets you convert text to natural-sounding speech:

```php
use Laravel\Ai\Audio;

$audio = Audio::of('I love coding with Laravel.')->generate();

$rawContent = (string) $audio;
```

The pattern mirrors the image API: provide the text, call `generate()`, and you receive audio content ready to be streamed or saved.

### Creating Embeddings

Embeddings are the backbone of semantic search and retrieval systems. Laravel 13 makes generating them effortless by extending the `Str` helper:

```php
use Illuminate\Support\Str;

$embeddings = Str::of('Napa Valley has great wine.')->toEmbeddings();
```

This converts a piece of text into a numerical vector representation, which can be stored alongside your data for similarity-based lookups. We'll see how this connects to the new vector search features below.


## JSON:API Resources {#json-api-resources}

Laravel 13 ships with built-in support for **JSON:API resources**, so you can return API responses that fully comply with the JSON:API specification without reaching for third-party packages.

These resources handle the heavy lifting: proper resource object serialization, relationship inclusion, sparse fieldsets, `links` objects, and the correct `Content-Type` headers. If you're building an API that needs to follow this widely-adopted standard, the framework now has you covered out of the box.


## Request Forgery Protection {#request-forgery-protection}

On the security front, Laravel's CSRF protection middleware has been upgraded and formally renamed to `PreventRequestForgery`. This enhanced middleware adds **origin-aware request verification**, meaning it can validate requests based on the `Origin` header, while still maintaining full backward compatibility with traditional token-based CSRF protection.

It's a subtle but important improvement for applications that need layered request validation.


## Queue Routing {#queue-routing}

Managing which queue or connection a job should be dispatched to can become scattered across multiple job classes. Laravel 13 introduces **centralized queue routing** via `Queue::route(...)`, letting you define default routing rules in one place:

```php
Queue::route(ProcessPodcast::class, connection: 'redis', queue: 'podcasts');
```

This single line tells Laravel: "Whenever a `ProcessPodcast` job is dispatched, send it to the `podcasts` queue on the `redis` connection." No need to set `$connection` or `$queue` properties inside the job class itself. This approach keeps your routing configuration centralized and easier to manage as your application grows.


## Expanded PHP Attributes {#expanded-php-attributes}

Laravel has been gradually embracing PHP 8's native attributes, and version 13 takes this further across the entire framework. The idea is to make common configuration more **declarative**. Instead of defining middleware or policies in separate files, you can declare them directly on your classes and methods.

Here's a practical example using the new `#[Middleware]` and `#[Authorize]` attributes on a controller:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Comment;
use App\Models\Post;
use Illuminate\Routing\Attributes\Controllers\Authorize;
use Illuminate\Routing\Attributes\Controllers\Middleware;

#[Middleware('auth')]
class CommentController
{
    #[Middleware('subscribed')]
    #[Authorize('create', [Comment::class, 'post'])]
    public function store(Post $post)
    {
        // ...
    }
}
```

The `#[Middleware('auth')]` attribute on the class applies the `auth` middleware to every method in the controller. On the `store` method specifically, `#[Middleware('subscribed')]` adds an additional check, and `#[Authorize('create', [Comment::class, 'post'])]` enforces a policy gate, all without touching a constructor or route definition.

Queue-related attributes like `#[Tries]`, `#[Backoff]`, `#[Timeout]`, and `#[FailOnTimeout]` follow the same pattern for job classes, and similar attributes have been introduced across Eloquent, events, notifications, validation, and testing.


## Cache TTL Extension {#cache-ttl-extension}

A small but handy addition: `Cache::touch()` lets you extend the time-to-live (TTL) of an existing cache entry **without** retrieving and re-storing its value:

```php
Cache::touch('user:session:123', now()->addMinutes(30));
```

This is particularly useful for session-like caching patterns where you want to keep an item alive as long as it's being accessed, without the overhead of fetching and putting it back.


## Semantic / Vector Search {#semantic-vector-search}

Laravel 13 brings **native vector query support** to the framework, tightly integrated with the AI SDK's embedding capabilities and PostgreSQL's `pgvector` extension.

This means you can build AI-powered search experiences, such as finding semantically similar documents, recommendations, or contextual matches, using tools you already know. Here's an example using the query builder:

```php
$documents = DB::table('documents')
    ->whereVectorSimilarTo('embedding', 'Best wineries in Napa Valley')
    ->limit(10)
    ->get();
```

`whereVectorSimilarTo()` is a new query builder clause that compares the `embedding` column against a vector representation of the search string. Under the hood, Laravel converts your search text into an embedding (using the AI SDK) and performs a similarity query against the stored vectors. The result is a collection of the 10 most semantically relevant documents, not just keyword matches, but actual meaning-based results.

This feature is documented across the search, query builder, and AI SDK sections of the docs, giving you a complete pipeline from text → embedding → similarity search.


## Trying It Out: Installation {#installation}

Let's verify that Laravel 13 is installable and working.

### Checking PHP Version

First, make sure your PHP version meets the minimum requirement (8.3):

```
$ php -v
PHP 8.4.5 (cli) (built: Jan  7 2026 08:43:36) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.4.5, Copyright (c) Zend Technologies
    with Zend OPcache v8.4.5, Copyright (c), by Zend Technologies
```

PHP 8.4 is well within the supported range (8.3 - 8.5), so we're good to go.

### Installing via Composer

You can scaffold a fresh Laravel 13 project using Composer's `create-project` command:

```
$ composer create-project --prefer-dist laravel/laravel test-laravel-app
Creating a "laravel/laravel" project at "./test-laravel-app"
Installing laravel/laravel (v13.1.0)
  - Downloading laravel/laravel (v13.1.0)
  - Installing laravel/laravel (v13.1.0): Extracting archive
Created project in /home/gun-gun-priatna/learning-lab/laravel/test-laravel-app
```

The output confirms that **v13.1.0** is being pulled down. Once inside the project directory, the `composer.json` confirms the dependency:

```json
"require": {
    "php": "^8.3",
    "laravel/framework": "^13.0",
    "laravel/tinker": "^3.0"
},
```

Running `php artisan serve` and visiting `http://127.0.0.1:8000/` displays the default Laravel 13 welcome page. Everything is working as expected.

![Laravel 13 default page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/tampilan-default-laravel-13.webp)


## Update Laravel Installer {#update-laravel-installer}

If you prefer using the standalone Laravel installer, make sure to update it first:

```
composer global update laravel/installer
```

Then create a new project with:

```
$ laravel new laravel-13-app
```

The installer now includes an option to install **Laravel Boost** for AI-assisted coding, a sign of how deeply AI integration is woven into this release:

```
 ┌ Do you want to install Laravel Boost to improve AI assisted coding? ┐
 │ Yes                                                                 │
 └─────────────────────────────────────────────────────────────────────┘
```

After installation completes, verifying `composer.json` confirms the same `"laravel/framework": "^13.0"` dependency. You're ready to start building.


## Conclusion {#conclusion}

Laravel 13 is a well-balanced release that delivers meaningful new capabilities without imposing a heavy upgrade burden. Here are the key takeaways:

- **AI is now a first-class citizen.** The Laravel AI SDK gives you a unified, provider-agnostic interface for text generation, image creation, audio synthesis, and embeddings, all with the clean API patterns Laravel developers expect.
- **Semantic search is built in.** With native vector queries, `pgvector` support, and the embedding pipeline from the AI SDK, building meaning-based search is no longer a "bring your own stack" exercise.
- **JSON:API support out of the box.** No more third-party packages for standard-compliant API responses.
- **PHP attributes everywhere.** Middleware, authorization, queue settings, and more can now be declared directly on your classes, resulting in less boilerplate and more clarity.
- **Minimal breaking changes.** The Laravel team intentionally kept this upgrade lightweight, so most applications can move to v13 with very little code modification.
- **PHP 8.3+ required.** Make sure your environment is up to date before upgrading.

Whether you're building AI-powered features from scratch or simply want a smoother developer experience, Laravel 13 has something worth exploring.