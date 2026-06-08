---
title: "Understanding with(), whereHas(), and withCount() in Laravel Eloquent"
slug: "understanding-with-wherehas-and-withcount-in-laravel-eloquent"
category: "Laravel"
date: "2026-04-20"
status: "published"
---

You write a simple foreach loop over a collection of posts, and inside that loop you access `$post->comments` to display how many comments each post has. The code works, the numbers are correct, and in development with five posts it feels instant. But in production, with 200 posts in the database, your page triggers 201 separate SQL queries. One to fetch the posts, then one more per post to fetch its comments. Your server slows to a crawl. Your users notice. This is the N+1 problem, and it is one of the most common and damaging performance issues in Laravel applications.

Laravel provides three Eloquent methods specifically designed to handle relationship queries efficiently: `with()`, `whereHas()`, and `withCount()`. Each one solves a different problem. `with()` loads relationship data alongside the parent query, eliminating per-row queries. `whereHas()` filters parent records based on a condition in a related table, but does not load that related data. `withCount()` appends an aggregate count of related records to each parent model without loading those records into memory. The confusion begins when developers treat these as interchangeable, reach for `with()` out of habit, or do not realize that some scenarios require combining multiple methods to get both correct filtering and correct data loading.

In this article, you will understand exactly what each method does at the SQL level, verify the queries they generate in Artisan Tinker, and learn the right patterns for combining them in real-world scenarios.

## Overview {#overview}

Rather than describing these methods in the abstract, this article grounds every concept in the actual SQL that Laravel generates. That way, you build an accurate mental model based on what your database actually receives, which is the most reliable way to reason about query performance.

### What You'll Build

You will run a series of Eloquent queries on a `Post` and `Comment` relationship using Artisan Tinker, inspecting the SQL produced by each method via `DB::enableQueryLog()`. By the end, you will have verified side-by-side how `with()`, `whereHas()`, and `withCount()` behave at the query level and how they complement each other in real-world patterns.

### What You'll Learn

- Why the N+1 problem occurs and how to detect it immediately with `DB::enableQueryLog()`.
- What SQL `with()` generates and why it solves N+1 but does not filter parent records.
- What SQL `whereHas()` generates, why it filters without loading relationship data, and why that distinction matters in practice.
- What SQL `withCount()` generates and when it is more memory-efficient than loading full relationship models.
- How to combine these methods for common real-world patterns: filtered list pages, stat dashboards, and mixed count-and-render scenarios.

### What You'll Need

- Laravel 13 with PHP 8.2 or higher.
- A `Post` model with a `hasMany` relationship to a `Comment` model. The `comments` table needs an `approved` boolean column, since several examples depend on it.
- Artisan Tinker (`php artisan tinker`) for running the examples interactively.
- Basic familiarity with Eloquent models and relationships.

## Setting Up the Example {#setting-up}

To follow along with every example in this article, you need two models connected by a `hasMany`/`belongsTo` relationship. If you already have a `Post` and `Comment` setup in your project, check that your `comments` table includes an `approved` boolean column before continuing.

Start by generating and running the migrations:

```bash
php artisan make:migration create_posts_table
php artisan make:migration create_comments_table
```

Open `database/migrations/xxxx_xx_xx_create_posts_table.php` and define the posts schema:

```php
public function up(): void
{
    Schema::create('posts', function (Blueprint $table) {
        $table->id();
        $table->string('title');
        $table->text('body');
        $table->timestamps();
    });
}
```

Then open `database/migrations/xxxx_xx_xx_create_comments_table.php`:

```php
public function up(): void
{
    Schema::create('comments', function (Blueprint $table) {
        $table->id();
        // Creates a post_id column with a foreign key constraint pointing to posts.id
        $table->foreignId('post_id')->constrained()->cascadeOnDelete();
        $table->text('body');
        // This column will be used in all conditional filtering examples
        $table->boolean('approved')->default(false);
        $table->timestamps();
    });
}
```

Run the migrations:

```bash
php artisan migrate
```

Now open `app/Models/Post.php` and define the `hasMany` relationship:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Post extends Model
{
    protected $fillable = ['title', 'body'];

    public function comments(): HasMany
    {
        // A post can have many comments
        return $this->hasMany(Comment::class);
    }
}
```

And in `app/Models/Comment.php`, define the inverse `belongsTo` relationship:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Comment extends Model
{
    protected $fillable = ['post_id', 'body', 'approved'];

    protected $casts = [
        // Cast to boolean so PHP sees true/false instead of the raw 1/0 from the database
        'approved' => 'boolean',
    ];

    public function post(): BelongsTo
    {
        return $this->belongsTo(Post::class);
    }
}
```

Before running any Tinker examples, populate your database with test data. Open Tinker and run the following:

```bash
php artisan tinker
```

```php
// Create 5 posts, each with 3 approved and 2 unapproved comments
for ($i = 1; $i <= 5; $i++) {
    $post = \App\Models\Post::create([
        'title' => "Post {$i}",
        'body'  => "Body content of post number {$i}.",
    ]);

    for ($j = 1; $j <= 3; $j++) {
        \App\Models\Comment::create([
            'post_id'  => $post->id,
            'body'     => "Approved comment {$j} on post {$i}",
            'approved' => true,
        ]);
    }

    for ($j = 1; $j <= 2; $j++) {
        \App\Models\Comment::create([
            'post_id'  => $post->id,
            'body'     => "Pending comment {$j} on post {$i}",
            'approved' => false,
        ]);
    }
}
```

After this, you have 5 posts, each with exactly 5 comments (3 approved, 2 pending), for a total of 25 comment rows. You are ready to explore each method.

## The N+1 Problem {#n-plus-1-problem}

Before looking at the solutions, it is worth understanding what the N+1 problem looks like in code and in the query log. The name describes the query count: 1 query to fetch the parent records, plus N additional queries for the related records (one per parent row). With 5 posts that becomes 6 queries; with 500 posts it becomes 501. The database does not complain. Your code returns correct results. The problem is invisible until your app reaches a scale where the latency accumulates.

### What Happens Without Eager Loading

Eloquent's default behavior is lazy loading. When you access a relationship property like `$post->comments` inside a loop, Eloquent fires a fresh SQL query for each iteration. Here is what that looks like in Tinker:

```php
DB::enableQueryLog(); // start recording every SQL query

$posts = Post::all(); // one query to fetch all posts

foreach ($posts as $post) {
    // Each access to ->comments fires a new SELECT query for that post only
    echo $post->title . ' has ' . $post->comments->count() . " comments\n";
}

$queries = DB::getQueryLog();
echo count($queries) . " queries were executed.\n";
```

```
Post 1 has 5 comments
Post 2 has 5 comments
Post 3 has 5 comments
Post 4 has 5 comments
Post 5 has 5 comments
6 queries were executed.
```

Print the log to see the exact SQL:

```php
foreach (DB::getQueryLog() as $i => $query) {
    echo ($i + 1) . ': ' . $query['query'] . "\n";
}
```

```
1: select * from `posts`
2: select * from `comments` where `comments`.`post_id` = 1
3: select * from `comments` where `comments`.`post_id` = 2
4: select * from `comments` where `comments`.`post_id` = 3
5: select * from `comments` where `comments`.`post_id` = 4
6: select * from `comments` where `comments`.`post_id` = 5
```

Notice the defining signature: the same query structure repeated once per post, each using a single exact `post_id` match. This is what N+1 looks like at the SQL level. The `with()` method exists specifically to eliminate this pattern.

## Understanding `with()`: Eager Loading Relationships {#understanding-with}

The `with()` method tells Eloquent to load a relationship's data alongside the main query, rather than waiting until you access the property inside a loop. The result is always exactly two queries regardless of how many parent records you have: one for the parents and one batched query for all the related records at once. Once those two queries complete, Eloquent maps each related record back to its parent in memory. Accessing `$post->comments` inside a loop no longer triggers any additional database round-trips, because the data is already there.

This approach is called eager loading because it loads the data upfront, "eagerly," before it is accessed. The contrast is lazy loading, where the query is deferred until the moment of access, which is what caused the N+1 problem above.

### How `with()` Works Under the Hood

```php
DB::enableQueryLog();

// Pass the relationship name to with() to eager-load it
$posts = Post::with('comments')->get();

foreach ($posts as $post) {
    // No additional query fires here; comments are already in memory
    echo $post->title . ' has ' . $post->comments->count() . " comments\n";
}

$queries = DB::getQueryLog();
echo count($queries) . " queries were executed.\n";
```

```
Post 1 has 5 comments
Post 2 has 5 comments
Post 3 has 5 comments
Post 4 has 5 comments
Post 5 has 5 comments
2 queries were executed.
```

Two queries instead of six. Print the log to see what Laravel sent to the database:

```php
foreach (DB::getQueryLog() as $i => $query) {
    echo ($i + 1) . ': ' . $query['query'] . "\n";
}
```

```
1: select * from `posts`
2: select * from `comments` where `comments`.`post_id` in (1, 2, 3, 4, 5)
```

The second query uses `IN (1, 2, 3, 4, 5)` to fetch all comments for all posts in one round-trip, rather than one query per post. Laravel then maps each comment to its parent post using the `post_id` value. This is why the query count stays constant at 2, no matter how many posts you have.

One thing `with()` does not do is filter which parent records are returned. `Post::with('comments')->get()` still returns all five posts, including any posts with zero comments. The `with()` call only controls how and when related data is loaded, not which parent records appear in the result.

### Conditional Eager Loading with `with()`

You can pass a closure to `with()` to apply conditions to the relationship query. For example, to load only the approved comments for each post:

```php
DB::enableQueryLog();

$posts = Post::with(['comments' => function ($query) {
    // Apply a WHERE condition inside the eager-loaded relationship query
    $query->where('approved', true);
}])->get();

foreach (DB::getQueryLog() as $i => $query) {
    echo ($i + 1) . ': ' . $query['query'] . "\n";
}
```

```
1: select * from `posts`
2: select * from `comments` where `comments`.`post_id` in (1, 2, 3, 4, 5) and `approved` = 1
```

All 5 posts come back, but each post's `$post->comments` collection now contains only the 3 approved comments. Importantly, posts with zero approved comments are still present in the result; they simply have an empty `comments` collection. This is the critical distinction that `whereHas()` addresses.

## Understanding `whereHas()`: Filtering by Relationship {#understanding-wherehas}

The `whereHas()` method filters parent records based on whether they have related records matching a condition. It answers the question: "Give me only posts that have at least one comment satisfying this condition." It does not load those comments. It only affects which parent records survive the filter. This distinction trips up many developers who expect relationship data to be accessible after calling `whereHas()`.

Think of `whereHas()` as a gatekeeper on the parent query, not a data loader. It decides who gets in; `with()` decides what they bring with them.

### How `whereHas()` Works Under the Hood

Here is a query that returns only posts which have at least one approved comment:

```php
DB::enableQueryLog();

$posts = Post::whereHas('comments', function ($query) {
    // This condition is used as the filter criterion, not for loading data
    $query->where('approved', true);
})->get();

foreach (DB::getQueryLog() as $i => $query) {
    echo ($i + 1) . ': ' . $query['query'] . "\n";
}
```

```
1: select * from `posts` where exists (select * from `comments` where `posts`.`id` = `comments`.`post_id` and `approved` = 1)
```

One query. Notice its structure. Laravel generates a `WHERE EXISTS` subquery: "return this post row only if at least one row exists in `comments` where `post_id` matches and `approved` is 1." This is pure filtering. The database checks for existence and discards parent rows that fail. No comment data is loaded or returned.

In our seeded dataset every post has at least one approved comment, so all 5 posts are returned. If you had posts with zero approved comments, those would be excluded from the result entirely.

### The Common Mistake: `whereHas()` Without `with()`

The mistake is assuming `whereHas()` also loads the comments. It does not. Accessing `$post->comments` after a plain `whereHas()` call brings lazy loading back, and with it, N+1:

```php
DB::enableQueryLog();

$posts = Post::whereHas('comments', function ($query) {
    $query->where('approved', true);
})->get();

// At this point, NO comment data has been loaded

foreach ($posts as $post) {
    // This fires a new query per post (N+1 is back)
    echo $post->title . ' has ' . $post->comments->count() . " total comments\n";
}

$queries = DB::getQueryLog();
echo count($queries) . " queries were executed.\n";
```

```
Post 1 has 5 total comments
Post 2 has 5 total comments
Post 3 has 5 total comments
Post 4 has 5 total comments
Post 5 has 5 total comments
6 queries were executed.
```

Two problems in one. First, N+1 is back because `whereHas()` did not load the comments. Second, the count shows 5 total comments per post, not 3 approved, because the lazy-loaded `$post->comments` has no `approved` condition applied. When you need both filtering and data access, you must combine `whereHas()` with `with()`. You will see exactly how in the Combining Methods section.

## Understanding `withCount()`: Counting Without Loading {#understanding-withcount}

The `withCount()` method appends an aggregate count as an attribute on each parent model, without loading any of the related records into memory. Instead of fetching all comments so you can call `->count()` on the collection in PHP, Laravel uses a correlated SQL subquery to compute the count at the database level. The result is attached to each model as `{relation}_count`. No comment objects are hydrated. No memory is consumed for the comment rows.

This is especially valuable on list pages and dashboards where you need to display a number next to each post, but you have no reason to iterate over or render the individual comments. Loading full comment records just to count them is wasteful in both query time and memory.

### How `withCount()` Works Under the Hood

```php
DB::enableQueryLog();

// Appends a comments_count attribute to each post model
$posts = Post::withCount('comments')->get();

foreach ($posts as $post) {
    // comments_count is a plain integer attribute, no additional query needed
    echo $post->title . ': ' . $post->comments_count . " comments\n";
}

$queries = DB::getQueryLog();
echo count($queries) . " queries were executed.\n";
```

```
Post 1: 5 comments
Post 2: 5 comments
Post 3: 5 comments
Post 4: 5 comments
Post 5: 5 comments
1 query was executed.
```

One query. Print it to see the structure:

```php
echo DB::getQueryLog()[0]['query'];
```

```
select `posts`.*, (select count(*) from `comments` where `posts`.`id` = `comments`.`post_id`) as `comments_count` from `posts`
```

The count is embedded as a correlated subquery directly in the SELECT clause. Each row in the result set already carries its `comments_count` value. There is no second query, no loading related models, and no PHP-side aggregation.

Compare this to the `with()` approach for the same goal. If you use `Post::with('comments')->get()` and then call `$post->comments->count()` in a loop, you load every comment row into PHP memory as a fully hydrated Eloquent model, only to throw those objects away after counting them. `withCount()` avoids that entirely.

### Conditional Count with `withCount()`

You can pass a closure to filter which related records are counted. To count only approved comments per post:

```php
DB::enableQueryLog();

$posts = Post::withCount(['comments' => function ($query) {
    // The count subquery only includes approved comments
    $query->where('approved', true);
}])->get();

foreach ($posts as $post) {
    echo $post->title . ': ' . $post->comments_count . " approved comments\n";
}

echo DB::getQueryLog()[0]['query'] . "\n";
```

```
Post 1: 3 approved comments
Post 2: 3 approved comments
Post 3: 3 approved comments
Post 4: 3 approved comments
Post 5: 3 approved comments
select `posts`.*, (select count(*) from `comments` where `posts`.`id` = `comments`.`post_id` and `approved` = 1) as `comments_count` from `posts`
```

You can also load multiple counts in a single call and alias each one to distinguish them:

```php
$posts = Post::withCount([
    'comments',                                               // all comments as comments_count
    'comments as approved_comments_count' => function ($q) {
        $q->where('approved', true);                          // approved only
    },
    'comments as pending_comments_count' => function ($q) {
        $q->where('approved', false);                         // pending only
    },
])->get();

foreach ($posts as $post) {
    echo "{$post->title}: {$post->comments_count} total, "
        . "{$post->approved_comments_count} approved, "
        . "{$post->pending_comments_count} pending\n";
}
```

```
Post 1: 5 total, 3 approved, 2 pending
Post 2: 5 total, 3 approved, 2 pending
Post 3: 5 total, 3 approved, 2 pending
Post 4: 5 total, 3 approved, 2 pending
Post 5: 5 total, 3 approved, 2 pending
```

All three counts are computed in a single SQL query with three correlated subqueries embedded in the SELECT clause.

## Combining Methods: The Right Patterns {#combining-methods}

Real-world features rarely need just one of these methods in isolation. A post list page might need to filter by a relationship condition, load related data for rendering, and display a count alongside each item. The good news is that `with()`, `whereHas()`, and `withCount()` are designed to be chained. Each one adds a distinct dimension to your query without interfering with the others.

This section covers the three most common combinations you will encounter in practice.

### Pattern 1: `with()` + `whereHas()` for Filtered Eager Loading

This is the most frequently needed combination. The goal: show only posts that have at least one approved comment, and load those approved comments for display. Neither method alone is sufficient. `whereHas()` handles the parent filter; `with()` handles the relationship load.

```php
DB::enableQueryLog();

$posts = Post::whereHas('comments', function ($query) {
        // Filter parent records: only include posts with at least one approved comment
        $query->where('approved', true);
    })
    ->with(['comments' => function ($query) {
        // Load relationship data: eager-load only approved comments
        $query->where('approved', true);
    }])
    ->get();

$queries = DB::getQueryLog();
echo count($queries) . " queries were executed.\n";

foreach ($queries as $i => $query) {
    echo ($i + 1) . ': ' . $query['query'] . "\n";
}
```

```
2 queries were executed.
1: select * from `posts` where exists (select * from `comments` where `posts`.`id` = `comments`.`post_id` and `approved` = 1)
2: select * from `comments` where `comments`.`post_id` in (1, 2, 3, 4, 5) and `approved` = 1
```

Two queries: one filtered parent query and one batched eager load. Notice that the same condition (`approved = 1`) appears in both queries. This is intentional and important to understand: you must repeat the condition in both `whereHas()` and `with()` because they operate on completely different parts of the SQL. `whereHas()` adds a `WHERE EXISTS` clause to the parent query; `with()` adds a condition to the relationship's separate SELECT query. They do not share conditions automatically.

If you omit `whereHas()` and keep only `with(['comments' => ...])`, you get all posts back including those with no approved comments. If you omit `with()` and keep only `whereHas()`, you get correctly filtered posts but N+1 when rendering.

### Pattern 2: `with()` + `withCount()` for List Pages with Preview

A common pattern on list pages is showing a total comment count badge alongside a preview of a few approved comments. The count is for all comments (total), while the loaded data is filtered to approved only. The count and the loaded collection serve different UI purposes and therefore carry different conditions.

```php
DB::enableQueryLog();

$posts = Post::withCount('comments')       // total count for the count badge
    ->with(['comments' => function ($q) {
        // Load only approved comments for the comment preview section
        $q->where('approved', true);
    }])
    ->get();

$queries = DB::getQueryLog();
echo count($queries) . " queries were executed.\n";

foreach ($posts as $post) {
    echo "{$post->title} ({$post->comments_count} total comments)\n";
    foreach ($post->comments as $comment) {
        echo "  [approved] {$comment->body}\n";
    }
}
```

```
2 queries were executed.
Post 1 (5 total comments)
  [approved] Approved comment 1 on post 1
  [approved] Approved comment 2 on post 1
  [approved] Approved comment 3 on post 1
Post 2 (5 total comments)
  [approved] Approved comment 1 on post 2
  [approved] Approved comment 2 on post 2
  [approved] Approved comment 3 on post 2
...
```

Two queries: one for the posts with the count subquery embedded, and one batched eager load for approved comments. The `comments_count` attribute reflects all comments while the `$post->comments` collection reflects only the approved subset. Both are available simultaneously because they come from independent query mechanisms.

### Pattern 3: `whereHas()` + `withCount()` for Filtered Stats

For a dashboard or moderation view you might want to list only posts that have approved comments, and show the count of those approved comments next to each one. No comment rendering needed, just filtering and counting.

```php
DB::enableQueryLog();

$posts = Post::whereHas('comments', function ($query) {
        // Only include posts that have at least one approved comment
        $query->where('approved', true);
    })
    ->withCount(['comments as approved_comments_count' => function ($query) {
        // Count only approved comments and alias the attribute
        $query->where('approved', true);
    }])
    ->get();

foreach ($posts as $post) {
    echo "{$post->title}: {$post->approved_comments_count} approved comments\n";
}

$queries = DB::getQueryLog();
echo count($queries) . " queries.\n";
echo DB::getQueryLog()[0]['query'] . "\n";
```

```
Post 1: 3 approved comments
Post 2: 3 approved comments
Post 3: 3 approved comments
Post 4: 3 approved comments
Post 5: 3 approved comments
1 query.
select `posts`.*, (select count(*) from `comments` where `posts`.`id` = `comments`.`post_id` and `approved` = 1) as `approved_comments_count` from `posts` where exists (select * from `comments` where `posts`.`id` = `comments`.`post_id` and `approved` = 1)
```

One query. Both the `WHERE EXISTS` filter from `whereHas()` and the `COUNT(*)` subquery from `withCount()` are embedded in the same SQL statement. Laravel merges the contributions of both methods into a single database round-trip.

## Choosing the Right Method {#decision-guide}

With the SQL behavior of each method established, you can make decisions based on what your feature actually needs at the query level. The three questions to ask are: do you need to exclude parent records that lack matching related records (filter), do you need to render relationship data in a loop (load), and do you need a numeric count for display (count)?

| Need | Method |
|------|--------|
| Prevent N+1 when accessing related data in a loop | `with()` |
| Filter parent records by a condition in the related table | `whereHas()` |
| Display a count of related records without loading them | `withCount()` |
| Filter parents AND render related data | `whereHas()` + `with()` |
| Filter parents AND display a count | `whereHas()` + `withCount()` |
| Render related data AND display a separate count | `with()` + `withCount()` |
| Filter, render, AND count | `whereHas()` + `with()` + `withCount()` |

A practical rule of thumb: if you only need a number, reach for `withCount()`. If you need to iterate over or render related records, reach for `with()`. If you need to exclude parent records that do not meet a condition in a related table, add `whereHas()`. These three rules cover the vast majority of real-world Eloquent scenarios.

## Conclusion {#conclusion}

The most important insight from this article is that `with()`, `whereHas()`, and `withCount()` are not three flavors of the same thing. They each solve exactly one problem at the SQL level, which is precisely why they compose so well together. Here are the key takeaways:

- **`with()` is for loading, not filtering.** It replaces N+1 lazy loading with two efficient queries: one for parent records and one batched query using `IN (...)` to load all related records at once. Accessing the relationship inside a loop no longer fires additional queries.
- **`whereHas()` is for filtering, not loading.** It adds a `WHERE EXISTS` subquery to the parent query, excluding parents that have no related records matching the condition. It does not load or return any relationship data.
- **`withCount()` is for counting without loading.** It embeds a correlated `COUNT(*)` subquery in the SELECT clause, appending the result as a `{relation}_count` attribute on each model. No related records are fetched or hydrated into memory.
- **`whereHas()` does not prevent N+1 on its own.** After filtering with `whereHas()`, accessing `$post->comments` in a loop still triggers a query per row. You must pair it with `with()` if you need the relationship data.
- **`with()` is not a substitute for `withCount()` when you only need a number.** Eager-loading full Eloquent models and calling `->count()` on the collection wastes memory proportional to the number and size of related records. Use `withCount()` when a number is all you need.
- **Conditions must be repeated when combining `with()` and `whereHas()`.** Because each method operates on a different part of the generated SQL, the filter closure must be provided to both independently. They do not share constraints automatically.
- **These methods are designed to be chained.** Combining all three on a single query is common, correct, and efficient. Laravel compiles their contributions into one or two SQL statements, never into separate parallel queries.