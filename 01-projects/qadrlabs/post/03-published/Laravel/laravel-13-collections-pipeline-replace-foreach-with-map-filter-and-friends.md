---
title: "Laravel 13: Collections Pipeline, Replace foreach with map, filter, and Friends"
slug: "laravel-13-collections-pipeline-replace-foreach-with-map-filter-and-friends"
category: "Laravel"
date: "2026-04-19"
status: "published"
---

Writing a `foreach` loop to process data feels natural until the requirements start piling up. You add a condition inside the loop, then another loop that processes the result of the first, then a temporary variable to carry a running total. By the time the feature is done, you have a nested structure that takes a full minute to trace mentally, and every future change means unpacking the whole thing again.

The deeper problem is that `foreach` is imperative. You describe *how* the computer should walk through the data rather than *what* you actually want out of it. The two concerns, iteration mechanics and transformation intent, are tangled together in the same block of code. The result is code that works but resists being read.

Laravel's Collection class offers a different model: a fluent pipeline of named methods where each step declares its intent clearly and passes its result directly to the next. Instead of three loops and four temporary variables, you write `->filter()->sortBy()->pluck()` and the code reads like a sentence. This tutorial adds a Post Statistics page to the Demo Project from the [Seeder tutorial](https://qadrlabs.com/post/laravel-13-how-to-seed-realistic-data-using-seeders-and-factories) and uses it to walk through eight core Collection methods in a context where the output is always visible and verifiable in the browser.

## Overview {#overview}

This tutorial builds directly on top of the demo project created and populated with data by the [Seeder tutorial](https://qadrlabs.com/post/how-to-seed-realistic-data-in-laravel-using-seeders-and-factories). No new models or migrations are needed. The focus is entirely on learning to work with the `Illuminate\Support\Collection` that `Post::get()` already returns, and replacing common `foreach` patterns with clean, readable pipeline expressions.

### What You'll Build

- A `GET /posts/stats` route and a `PostStatsController` with a fully implemented `index()` method
- A statistics dashboard view that displays the output of eight different Collection operations on real post data
- A chained pipeline expression that produces a "Top 5 Most Commented Published Posts" list in one single readable expression
- A suite of Pest tests that verify each Collection operation produces the expected output

### What You'll Learn

- How to create a Collection from a plain PHP array using `collect()`, and why Eloquent results are already Collections
- How `map()` transforms every item in a Collection without mutating the original
- How `filter()` and `reject()` differ in their approach to keeping or discarding items
- How `pluck()` extracts a single field more concisely than a full `map()`
- How `sortBy()` and `sortByDesc()` work with both field names and closures
- How `groupBy()` organizes a flat Collection into named sub-groups
- How `reduce()` collapses a Collection down to a single aggregated value
- How `partition()` splits a Collection into exactly two groups in a single call
- How to chain all of these methods into one readable, single-expression pipeline
- When to use Collection methods and when to push the logic back into the database query instead

### What You'll Need

- PHP 8.3 or higher
- Laravel 13
- The [Seeder tutorial](https://qadrlabs.com/post/laravel-13-how-to-seed-realistic-data-using-seeders-and-factories) completed, which populates the database with realistic sample data

## How the Pipeline Mental Model Works {#mental-model}

Before writing any code, it helps to see what a Collection pipeline actually does to your data at each stage. Think of it as an assembly line where raw data enters at the top and a clean, formatted result exits at the bottom. Each method on the line does exactly one job and hands the result to the next.

The pipeline you will build in this tutorial follows this sequence:

```
[All 60 Posts]
      |
      v  filter(fn => status === 'published')
[~30 Published Posts]
      |
      v  sortByDesc(fn => comments->count())
[~30 Posts, most commented first]
      |
      v  take(5)
[Top 5 Posts]
      |
      v  map(fn => ['title', 'category', 'comment_count'])
[5 Arrays, display-ready]
      |
      v  values()
[5 Arrays, re-indexed from 0]
```

Each step is a separate, named method. None of them know or care about the others. You can read the chain top to bottom and understand the transformation without holding any mental state across lines.

The key insight is that every Collection method returns a brand new Collection. The original data is never touched. This makes each step independent and the whole chain reversible: removing a step always produces a valid, if different, result.

## Before and After: The Real Cost of foreach {#before-and-after}

To make the comparison concrete, here is a real-world example: producing the top five most commented published posts.

The `foreach` version requires you to manage every piece of state yourself:

```php
// foreach approach: 3 temporary variables, 2 loops, 1 sort call
$publishedPosts = [];
foreach ($posts as $post) {
    if ($post->status === 'published') {
        $publishedPosts[] = $post;
    }
}

usort($publishedPosts, fn ($a, $b) => $b->comments->count() <=> $a->comments->count());

$topPosts = array_slice($publishedPosts, 0, 5);

$result = [];
foreach ($topPosts as $post) {
    $result[] = [
        'title'         => $post->title,
        'comment_count' => $post->comments->count(),
        'category'      => $post->category?->name ?? 'Uncategorized',
    ];
}
```

Every variable in this block exists only to carry state from one loop to the next. To understand the code, a reader must track `$publishedPosts`, `$topPosts`, and `$result` simultaneously across four separate statements.

The pipeline version expresses the same logic as a single expression:

```php
// Pipeline approach: one expression, reads like a sentence
$result = $posts
    ->filter(fn (Post $post) => $post->status === 'published')
    ->sortByDesc(fn (Post $post) => $post->comments->count())
    ->take(5)
    ->map(fn (Post $post) => [
        'title'         => $post->title,
        'comment_count' => $post->comments->count(),
        'category'      => $post->category?->name ?? 'Uncategorized',
    ])
    ->values();
```

There are no temporary variables because there is no state to carry. Each line answers "and then what?" and the result falls out at the bottom. You will build toward this expression one method at a time throughout the tutorial.

## Step 1: Add the Route {#step-1-add-route}

Open the file `routes/web.php` and update it to add both the new `use` statement and the stats route:

```php
<?php

use App\Http\Controllers\PostStatsController; // add this use statement
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/posts/stats', [PostStatsController::class, 'index'])->name('posts.stats'); // add before resource route
```

Save the file `routes/web.php`.

## Step 2: Create the PostStatsController {#step-2-create-controller}

This page only needs a single action, so a plain controller (not a resource controller) is the right choice here.

```bash
php artisan make:controller PostStatsController
```

```
$ php artisan make:controller PostStatsController

   INFO  Controller [app/Http/Controllers/PostStatsController.php] created successfully.
```

Open the file `app/Http/Controllers/PostStatsController.php`. You will find an empty class stub. Replace its entire contents with the following skeleton, which loads the posts and passes them to a view:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\View\View;

class PostStatsController extends Controller
{
    public function index(): View
    {
        // Eager-load relationships to avoid N+1 queries when collection methods access them
        $posts = Post::with(['category', 'user', 'comments'])->get();

        return view('posts.stats', compact('posts'));
    }
}
```

The eager loading on `category`, `user`, and `comments` is critical here. Every Collection method that accesses `$post->category->name` or `$post->comments->count()` would otherwise fire an individual SQL query per post. Eager loading resolves all related records in three additional queries up front, regardless of how many posts are in the Collection. Without it, looping over 60 posts with a `->comments->count()` call inside would fire 60 separate SQL queries.

Save the file `app/Http/Controllers/PostStatsController.php`.

### Load Posts and Understand collect()

Before adding the collection operations, it helps to understand what `$posts` actually is. When you call `Post::with(...)->get()`, Eloquent does not return a plain PHP array. It returns an instance of `Illuminate\Database\Eloquent\Collection`, which extends Laravel's base `Illuminate\Support\Collection` class.

This means that every post query result already has all Collection methods available on it immediately, with no additional wrapping needed.

The `collect()` helper is what you use when you want to create a Collection from a plain PHP array that is not coming from Eloquent:

```php
// Wrapping a plain array in a Collection manually
$numbers = collect([1, 2, 3, 4, 5]);

// Eloquent results are already Collections, no wrapping needed
$posts = Post::get(); // $posts is already an Illuminate\Database\Eloquent\Collection
```

The two types behave identically for all the methods covered in this tutorial, because `Eloquent\Collection` inherits everything from the base `Support\Collection` class.

## Step 3: Transform Items with map() {#step-3-map}

`map()` iterates over every item in a Collection, passes it through a callback, and collects all the return values into a brand new Collection. The original Collection is never changed.

Here is the same transformation written first with `foreach`, then with `map()`, so you can see what is being replaced:

```php
// The foreach approach: a temporary variable accumulates results
$postsWithCount = [];
foreach ($posts as $post) {
    $postsWithCount[] = [
        'title'         => $post->title,
        'status'        => $post->status,
        'category'      => $post->category?->name ?? 'Uncategorized',
        'comment_count' => $post->comments->count(),
    ];
}

// The map() approach: no temporary variable, no mutation
$postsWithCommentCount = $posts->map(fn (Post $post) => [
    'title'         => $post->title,
    'status'        => $post->status,
    'category'      => $post->category?->name ?? 'Uncategorized',
    'comment_count' => $post->comments->count(),
]);
```

Both produce the same result. The `map()` version makes it immediately clear that the operation is a one-to-one transformation: every input item produces exactly one output item. There is no ambiguity about whether items are added, skipped, or counted.

Notice the use of `$post->category?->name ?? 'Uncategorized'`. The null-safe operator `?->` prevents a fatal error if a post somehow has no category assigned. The `?->` chain short-circuits to `null` instead of throwing, and the `??` operator then substitutes the fallback string. In a well-seeded database this will never trigger, but in production, defensive access patterns like this prevent silent data issues from surfacing as 500 errors.

Open the file `app/Http/Controllers/PostStatsController.php` and add `$postsWithCommentCount` inside `index()`, above the `return view()` line. Also update `compact()` to include the new variable:

```php
$postsWithCommentCount = $posts->map(fn (Post $post) => [
    'title'         => $post->title,
    'status'        => $post->status,
    'category'      => $post->category?->name ?? 'Uncategorized',
    'comment_count' => $post->comments->count(),
]);

return view('posts.stats', compact('posts', 'postsWithCommentCount'));
```

Here is the complete state of the controller after this step:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\View\View;

class PostStatsController extends Controller
{
    public function index(): View
    {
        $posts = Post::with(['category', 'user', 'comments'])->get();

        // map: transform each item into a display-ready array
        $postsWithCommentCount = $posts->map(fn (Post $post) => [
            'title'         => $post->title,
            'status'        => $post->status,
            'category'      => $post->category?->name ?? 'Uncategorized',
            'comment_count' => $post->comments->count(),
        ]);

        return view('posts.stats', compact('posts', 'postsWithCommentCount'));
    }
}
```

Save the file `app/Http/Controllers/PostStatsController.php`.

## Step 4: Filter Items with filter() and reject() {#step-4-filter-reject}

`filter()` keeps every item for which the callback returns `true` and discards the rest. `reject()` is the inverse: it discards every item for which the callback returns `true`, keeping only the ones that fail the test.

They can always produce the same result when you flip the condition, but each reads more naturally in different contexts. Writing `->filter(fn ($post) => $post->status === 'published')` tells a reader you are keeping published posts. Writing `->reject(fn ($post) => $post->status === 'published')` tells a reader you are throwing published posts away. When your intent is primarily about exclusion, `reject()` communicates that intent more directly than a negated `filter()`.

Open the file `app/Http/Controllers/PostStatsController.php` and add both variables after `$postsWithCommentCount`:

```php
// filter: keep only items where the callback returns true
$publishedPosts = $posts->filter(fn (Post $post) => $post->status === 'published');

// reject: discard items where the callback returns true (the inverse of filter)
$nonPublishedPosts = $posts->reject(fn (Post $post) => $post->status === 'published');
```

Update `compact()` to include both new variables:

```php
return view('posts.stats', compact(
    'posts',
    'postsWithCommentCount',
    'publishedPosts',
    'nonPublishedPosts',
));
```

Here is the complete state of the controller after this step:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\View\View;

class PostStatsController extends Controller
{
    public function index(): View
    {
        $posts = Post::with(['category', 'user', 'comments'])->get();

        // map: transform each item into a display-ready array
        $postsWithCommentCount = $posts->map(fn (Post $post) => [
            'title'         => $post->title,
            'status'        => $post->status,
            'category'      => $post->category?->name ?? 'Uncategorized',
            'comment_count' => $post->comments->count(),
        ]);

        // filter: keep items where the callback returns true
        $publishedPosts = $posts->filter(fn (Post $post) => $post->status === 'published');

        // reject: discard items where the callback returns true
        $nonPublishedPosts = $posts->reject(fn (Post $post) => $post->status === 'published');

        return view('posts.stats', compact(
            'posts',
            'postsWithCommentCount',
            'publishedPosts',
            'nonPublishedPosts',
        ));
    }
}
```

Save the file `app/Http/Controllers/PostStatsController.php`.

## Step 5: Extract Fields with pluck() {#step-5-pluck}

`pluck()` is a shortcut for the common `map()` pattern of extracting a single field from every item. The two lines below produce identical results, but `pluck()` makes the intent cleaner and requires no closure:

```php
// map() version
$titles = $posts->map(fn (Post $post) => $post->title);

// pluck() version: cleaner for single-field extraction
$titles = $posts->pluck('title');
```

`pluck()` also accepts a second argument that sets the key for the resulting Collection. This is useful when you need a lookup map rather than a flat list:

```php
// Flat list: ['My First Post', 'Another Post', ...]
$titles = $posts->pluck('title');

// Keyed map: [1 => 'My First Post', 2 => 'Another Post', ...]
$titlesById = $posts->pluck('title', 'id');
```

Open the file `app/Http/Controllers/PostStatsController.php` and add both variables, then include them in `compact()`:

```php
$titles     = $posts->pluck('title');
$titlesById = $posts->pluck('title', 'id');
```

Here is the complete state of the controller after this step:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\View\View;

class PostStatsController extends Controller
{
    public function index(): View
    {
        $posts = Post::with(['category', 'user', 'comments'])->get();

        // map: transform each item into a display-ready array
        $postsWithCommentCount = $posts->map(fn (Post $post) => [
            'title'         => $post->title,
            'status'        => $post->status,
            'category'      => $post->category?->name ?? 'Uncategorized',
            'comment_count' => $post->comments->count(),
        ]);

        // filter: keep items where the callback returns true
        $publishedPosts = $posts->filter(fn (Post $post) => $post->status === 'published');

        // reject: discard items where the callback returns true
        $nonPublishedPosts = $posts->reject(fn (Post $post) => $post->status === 'published');

        // pluck: extract a single field as a flat list or a keyed map
        $titles     = $posts->pluck('title');
        $titlesById = $posts->pluck('title', 'id');

        return view('posts.stats', compact(
            'posts',
            'postsWithCommentCount',
            'publishedPosts',
            'nonPublishedPosts',
            'titles',
            'titlesById',
        ));
    }
}
```

Save the file `app/Http/Controllers/PostStatsController.php`.

---

**Progress check.** At this point you have covered the four most common Collection transformations:

- `map()` transforms every item, one input to one output, producing a new Collection of the same size.
- `filter()` keeps items that pass a test, shrinking the Collection.
- `reject()` discards items that pass a test, which reads more naturally when the intent is exclusion.
- `pluck()` is a focused `map()` for pulling a single field, useful for building flat lists or lookup maps.

All four return new Collections. The original `$posts` variable is untouched after each call.

---

## Step 6: Sort Items with sortBy() {#step-6-sortby}

`sortBy()` accepts either a field name string or a closure. When given a string, it sorts by that field's value. When given a closure, it sorts by whatever value the closure returns, which enables sorting by computed properties such as a relationship count.

`sortByDesc()` applies the same logic in descending order.

```php
// Sort alphabetically by the stored 'title' field
$sortedByTitle = $posts->sortBy('title');

// Sort by comment count descending, computed via closure since it is not a stored field
$sortedByComments = $posts->sortByDesc(fn (Post $post) => $post->comments->count());
```

The closure in `$sortedByComments` calls `$post->comments->count()` on each post. This works efficiently here because comments were eager-loaded at the start of `index()`. If comments had not been eager-loaded, each call to `$post->comments->count()` inside the closure would fire a separate SQL query, and sorting 60 posts would produce 60 extra database round trips.

Both `sortBy()` and `sortByDesc()` return a new Collection with the items in the new order. The original `$posts` variable still holds items in the order Eloquent returned them.

Open the file `app/Http/Controllers/PostStatsController.php`, add these two variables, and update `compact()`:

Here is the complete state of the controller after this step:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\View\View;

class PostStatsController extends Controller
{
    public function index(): View
    {
        $posts = Post::with(['category', 'user', 'comments'])->get();

        // map: transform each item into a display-ready array
        $postsWithCommentCount = $posts->map(fn (Post $post) => [
            'title'         => $post->title,
            'status'        => $post->status,
            'category'      => $post->category?->name ?? 'Uncategorized',
            'comment_count' => $post->comments->count(),
        ]);

        // filter: keep items where the callback returns true
        $publishedPosts = $posts->filter(fn (Post $post) => $post->status === 'published');

        // reject: discard items where the callback returns true
        $nonPublishedPosts = $posts->reject(fn (Post $post) => $post->status === 'published');

        // pluck: extract a single field as a flat list or a keyed map
        $titles     = $posts->pluck('title');
        $titlesById = $posts->pluck('title', 'id');

        // sortBy: alphabetical by title field
        $sortedByTitle = $posts->sortBy('title');

        // sortByDesc: by a computed value (comment count) via closure
        $sortedByComments = $posts->sortByDesc(fn (Post $post) => $post->comments->count());

        return view('posts.stats', compact(
            'posts',
            'postsWithCommentCount',
            'publishedPosts',
            'nonPublishedPosts',
            'titles',
            'titlesById',
            'sortedByTitle',
            'sortedByComments',
        ));
    }
}
```

Save the file `app/Http/Controllers/PostStatsController.php`.

## Step 7: Group Items with groupBy() {#step-7-groupby}

`groupBy()` transforms a flat Collection into a nested Collection of sub-Collections. Each key in the result is one distinct group value, and each value is a Collection of the items that belong to that group.

`groupBy()` accepts either a field name or a closure. The field name version is straightforward for stored columns. The closure version is necessary when the grouping key comes from a relationship or a computed value.

```php
// Group by the 'status' field: keys will be 'draft', 'published', 'archived'
$postsByStatus = $posts->groupBy('status');

// Group by category name via a closure, since it comes from a relationship
$postsByCategory = $posts->groupBy(fn (Post $post) => $post->category?->name ?? 'Uncategorized');
```

The `$postsByStatus` result is itself a Collection. Accessing `$postsByStatus['published']` returns another Collection containing only the published posts, which you can chain further. Open the file `app/Http/Controllers/PostStatsController.php` and add both variables, then update `compact()`.

Here is the complete state of the controller after this step:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\View\View;

class PostStatsController extends Controller
{
    public function index(): View
    {
        $posts = Post::with(['category', 'user', 'comments'])->get();

        // map: transform each item into a display-ready array
        $postsWithCommentCount = $posts->map(fn (Post $post) => [
            'title'         => $post->title,
            'status'        => $post->status,
            'category'      => $post->category?->name ?? 'Uncategorized',
            'comment_count' => $post->comments->count(),
        ]);

        // filter: keep items where the callback returns true
        $publishedPosts = $posts->filter(fn (Post $post) => $post->status === 'published');

        // reject: discard items where the callback returns true
        $nonPublishedPosts = $posts->reject(fn (Post $post) => $post->status === 'published');

        // pluck: extract a single field as a flat list or a keyed map
        $titles     = $posts->pluck('title');
        $titlesById = $posts->pluck('title', 'id');

        // sortBy: alphabetical by title field
        $sortedByTitle = $posts->sortBy('title');

        // sortByDesc: by a computed value (comment count) via closure
        $sortedByComments = $posts->sortByDesc(fn (Post $post) => $post->comments->count());

        // groupBy: nested Collection keyed by a field value
        $postsByStatus = $posts->groupBy('status');

        // groupBy: nested Collection keyed by a relationship value via closure
        $postsByCategory = $posts->groupBy(fn (Post $post) => $post->category?->name ?? 'Uncategorized');

        return view('posts.stats', compact(
            'posts',
            'postsWithCommentCount',
            'publishedPosts',
            'nonPublishedPosts',
            'titles',
            'titlesById',
            'sortedByTitle',
            'sortedByComments',
            'postsByStatus',
            'postsByCategory',
        ));
    }
}
```

Save the file `app/Http/Controllers/PostStatsController.php`.

## Step 8: Aggregate with reduce() {#step-8-reduce}

`reduce()` collapses the entire Collection down to a single value. The callback receives two arguments: the accumulated result so far (the carry) and the current item. The second argument to `reduce()` sets the starting value of the carry.

Comparing the `foreach` approach to `reduce()` makes the benefit clear:

```php
// The foreach approach: an external variable that accumulates mutations
$total = 0;
foreach ($posts as $post) {
    $total += $post->comments->count();
}

// The reduce() approach: self-contained, no external state
$totalComments = $posts->reduce(
    fn (int $carry, Post $post) => $carry + $post->comments->count(),
    0 // starting value for $carry
);
```

Both produce the same integer. The `reduce()` version keeps the starting value, the accumulation logic, and the result all inside one expression with no external variable to mutate.

Open the file `app/Http/Controllers/PostStatsController.php` and add `$totalComments`, then update `compact()`.

Here is the complete state of the controller after this step:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\View\View;

class PostStatsController extends Controller
{
    public function index(): View
    {
        $posts = Post::with(['category', 'user', 'comments'])->get();

        // map: transform each item into a display-ready array
        $postsWithCommentCount = $posts->map(fn (Post $post) => [
            'title'         => $post->title,
            'status'        => $post->status,
            'category'      => $post->category?->name ?? 'Uncategorized',
            'comment_count' => $post->comments->count(),
        ]);

        // filter: keep items where the callback returns true
        $publishedPosts = $posts->filter(fn (Post $post) => $post->status === 'published');

        // reject: discard items where the callback returns true
        $nonPublishedPosts = $posts->reject(fn (Post $post) => $post->status === 'published');

        // pluck: extract a single field as a flat list or a keyed map
        $titles     = $posts->pluck('title');
        $titlesById = $posts->pluck('title', 'id');

        // sortBy: alphabetical by title field
        $sortedByTitle = $posts->sortBy('title');

        // sortByDesc: by a computed value (comment count) via closure
        $sortedByComments = $posts->sortByDesc(fn (Post $post) => $post->comments->count());

        // groupBy: nested Collection keyed by a field value
        $postsByStatus = $posts->groupBy('status');

        // groupBy: nested Collection keyed by a relationship value via closure
        $postsByCategory = $posts->groupBy(fn (Post $post) => $post->category?->name ?? 'Uncategorized');

        // reduce: collapse the entire Collection to a single value
        $totalComments = $posts->reduce(
            fn (int $carry, Post $post) => $carry + $post->comments->count(),
            0
        );

        return view('posts.stats', compact(
            'posts',
            'postsWithCommentCount',
            'publishedPosts',
            'nonPublishedPosts',
            'titles',
            'titlesById',
            'sortedByTitle',
            'sortedByComments',
            'postsByStatus',
            'postsByCategory',
            'totalComments',
        ));
    }
}
```

Save the file `app/Http/Controllers/PostStatsController.php`.

---

**Progress check.** You now have five more tools in the pipeline:

- `sortBy()` and `sortByDesc()` reorder a Collection by a stored field or a closure-computed value. They work efficiently on relationship values only when those relationships are already eager-loaded.
- `groupBy()` turns a flat Collection into a nested one, keyed by any field or computed value. Useful for category breakdowns, status buckets, or any grouped display.
- `reduce()` collapses everything down to one scalar result. It replaces the external accumulator pattern of `foreach` with a self-contained expression.

---

## Step 9: Split a Collection with partition() {#step-9-partition}

`partition()` divides a Collection into exactly two Collections in one call: items that pass the test and items that do not. The result can be destructured directly using PHP's array unpacking syntax.

```php
[$published, $unpublished] = $posts->partition(fn (Post $post) => $post->status === 'published');
```

This is cleaner than calling `filter()` and `reject()` separately when you need both groups immediately. Instead of two assignments with mirrored conditions, you express the split once and get both sides in a single line.

Open the file `app/Http/Controllers/PostStatsController.php` and add the partition line. Update `compact()` to include both `'published'` and `'unpublished'`.

Here is the complete state of the controller after this step:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\View\View;

class PostStatsController extends Controller
{
    public function index(): View
    {
        $posts = Post::with(['category', 'user', 'comments'])->get();

        // map: transform each item into a display-ready array
        $postsWithCommentCount = $posts->map(fn (Post $post) => [
            'title'         => $post->title,
            'status'        => $post->status,
            'category'      => $post->category?->name ?? 'Uncategorized',
            'comment_count' => $post->comments->count(),
        ]);

        // filter: keep items where the callback returns true
        $publishedPosts = $posts->filter(fn (Post $post) => $post->status === 'published');

        // reject: discard items where the callback returns true
        $nonPublishedPosts = $posts->reject(fn (Post $post) => $post->status === 'published');

        // pluck: extract a single field as a flat list or a keyed map
        $titles     = $posts->pluck('title');
        $titlesById = $posts->pluck('title', 'id');

        // sortBy: alphabetical by title field
        $sortedByTitle = $posts->sortBy('title');

        // sortByDesc: by a computed value (comment count) via closure
        $sortedByComments = $posts->sortByDesc(fn (Post $post) => $post->comments->count());

        // groupBy: nested Collection keyed by a field value
        $postsByStatus = $posts->groupBy('status');

        // groupBy: nested Collection keyed by a relationship value via closure
        $postsByCategory = $posts->groupBy(fn (Post $post) => $post->category?->name ?? 'Uncategorized');

        // reduce: collapse the entire Collection to a single value
        $totalComments = $posts->reduce(
            fn (int $carry, Post $post) => $carry + $post->comments->count(),
            0
        );

        // partition: split into two Collections in one call
        [$published, $unpublished] = $posts->partition(fn (Post $post) => $post->status === 'published');

        return view('posts.stats', compact(
            'posts',
            'postsWithCommentCount',
            'publishedPosts',
            'nonPublishedPosts',
            'titles',
            'titlesById',
            'sortedByTitle',
            'sortedByComments',
            'postsByStatus',
            'postsByCategory',
            'totalComments',
            'published',
            'unpublished',
        ));
    }
}
```

Save the file `app/Http/Controllers/PostStatsController.php`.

## Step 10: Chain Methods into a Pipeline {#step-10-pipeline}

Each Collection method returns a new Collection instance, which means you can call the next method directly on the result without any intermediate assignment. This is the pipeline pattern: data flows through a sequence of named transformations, each declaring its intent on its own line.

The following expression produces the top five most commented published posts as a clean array of display-ready values, all in one chained expression:

```php
$topPosts = $posts
    ->filter(fn (Post $post) => $post->status === 'published')
    ->sortByDesc(fn (Post $post) => $post->comments->count())
    ->take(5)
    ->map(fn (Post $post) => [
        'title'         => $post->title,
        'slug'          => $post->slug,
        'comment_count' => $post->comments->count(),
        'category'      => $post->category?->name ?? 'Uncategorized',
    ])
    ->values(); // re-index keys after filter and sort
```

Reading the chain top to bottom, each line answers "and then what?": start with all posts, keep only the published ones, sort by comment count descending, take the first five, transform each into a display array, then re-index the keys. The equivalent `foreach` version would require at least three temporary variables and a sorting function call.

The `->values()` call at the end deserves a note. After `filter()` and `sortByDesc()`, the Collection preserves the original numeric keys from the Eloquent result. Calling `values()` re-indexes them from zero, which keeps `$loop->index` predictable in Blade and prevents unexpected gaps in the key sequence.

Open the file `app/Http/Controllers/PostStatsController.php` and add `$topPosts` above the `return view()` line. Then update `compact()` to include all variables. Here is the complete final state of the controller:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\View\View;

class PostStatsController extends Controller
{
    public function index(): View
    {
        $posts = Post::with(['category', 'user', 'comments'])->get();

        // map: transform each item into a display-ready array
        $postsWithCommentCount = $posts->map(fn (Post $post) => [
            'title'         => $post->title,
            'status'        => $post->status,
            'category'      => $post->category?->name ?? 'Uncategorized',
            'comment_count' => $post->comments->count(),
        ]);

        // filter: keep items where the callback returns true
        $publishedPosts = $posts->filter(fn (Post $post) => $post->status === 'published');

        // reject: discard items where the callback returns true
        $nonPublishedPosts = $posts->reject(fn (Post $post) => $post->status === 'published');

        // pluck: extract a single field as a flat list or a keyed map
        $titles     = $posts->pluck('title');
        $titlesById = $posts->pluck('title', 'id');

        // sortBy: alphabetical by title field
        $sortedByTitle = $posts->sortBy('title');

        // sortByDesc: by a computed value (comment count) via closure
        $sortedByComments = $posts->sortByDesc(fn (Post $post) => $post->comments->count());

        // groupBy: nested Collection keyed by a field value
        $postsByStatus = $posts->groupBy('status');

        // groupBy: nested Collection keyed by a relationship value via closure
        $postsByCategory = $posts->groupBy(fn (Post $post) => $post->category?->name ?? 'Uncategorized');

        // reduce: collapse the entire Collection to a single value
        $totalComments = $posts->reduce(
            fn (int $carry, Post $post) => $carry + $post->comments->count(),
            0
        );

        // partition: split into two Collections in one call
        [$published, $unpublished] = $posts->partition(fn (Post $post) => $post->status === 'published');

        // pipeline: chain multiple operations into one readable expression
        $topPosts = $posts
            ->filter(fn (Post $post) => $post->status === 'published')
            ->sortByDesc(fn (Post $post) => $post->comments->count())
            ->take(5)
            ->map(fn (Post $post) => [
                'title'         => $post->title,
                'slug'          => $post->slug,
                'comment_count' => $post->comments->count(),
                'category'      => $post->category?->name ?? 'Uncategorized',
            ])
            ->values();

        return view('posts.stats', compact(
            'posts',
            'postsWithCommentCount',
            'publishedPosts',
            'nonPublishedPosts',
            'titles',
            'titlesById',
            'sortedByTitle',
            'sortedByComments',
            'postsByStatus',
            'postsByCategory',
            'totalComments',
            'published',
            'unpublished',
            'topPosts',
        ));
    }
}
```

Save the file `app/Http/Controllers/PostStatsController.php`.

## Step 11: Build the Blade View {#step-11-blade-view}

The view displays the most meaningful outputs from the controller: a summary row of counts, the pipeline result table, posts grouped by status and category, and the partition split. Create a new file at `resources/views/posts/stats.blade.php` and add the following content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Post Statistics</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-7xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">

        <div class="flex justify-between items-center mb-8">
            <h1 class="text-3xl font-bold text-gray-900">Post Statistics</h1>
            <a href="{{ route('posts.index') }}"
               class="text-gray-600 hover:text-gray-900 underline text-sm transition">
                Back to Posts
            </a>
        </div>

        {{-- Summary Cards: counts from count(), reduce(), and partition() --}}
        <section class="mb-10">
            <h2 class="text-lg font-semibold text-gray-700 mb-4">Summary</h2>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 text-center">
                    <p class="text-3xl font-bold text-blue-700">{{ $posts->count() }}</p>
                    <p class="text-xs text-blue-500 mt-1 uppercase tracking-wide">Total Posts</p>
                    <p class="text-xs text-gray-400 mt-1">count()</p>
                </div>
                <div class="bg-green-50 border border-green-200 rounded-lg p-4 text-center">
                    <p class="text-3xl font-bold text-green-700">{{ $published->count() }}</p>
                    <p class="text-xs text-green-500 mt-1 uppercase tracking-wide">Published</p>
                    <p class="text-xs text-gray-400 mt-1">partition()</p>
                </div>
                <div class="bg-amber-50 border border-amber-200 rounded-lg p-4 text-center">
                    <p class="text-3xl font-bold text-amber-700">{{ $unpublished->count() }}</p>
                    <p class="text-xs text-amber-500 mt-1 uppercase tracking-wide">Draft / Archived</p>
                    <p class="text-xs text-gray-400 mt-1">partition()</p>
                </div>
                <div class="bg-purple-50 border border-purple-200 rounded-lg p-4 text-center">
                    <p class="text-3xl font-bold text-purple-700">{{ $totalComments }}</p>
                    <p class="text-xs text-purple-500 mt-1 uppercase tracking-wide">Total Comments</p>
                    <p class="text-xs text-gray-400 mt-1">reduce()</p>
                </div>
            </div>
        </section>

        {{-- Pipeline Result: Top 5 most commented published posts --}}
        <section class="mb-10">
            <h2 class="text-lg font-semibold text-gray-700 mb-1">Top 5 Most Commented Published Posts</h2>
            <p class="text-sm text-gray-400 mb-4 font-mono">
                filter() &rarr; sortByDesc() &rarr; take(5) &rarr; map() &rarr; values()
            </p>
            <div class="overflow-x-auto">
                <table class="min-w-full bg-white border border-gray-200 rounded-lg overflow-hidden">
                    <thead class="bg-gray-50 border-b border-gray-200">
                        <tr>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">#</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Title</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Category</th>
                            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Comments</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200">
                        @forelse($topPosts as $index => $post)
                        <tr class="hover:bg-gray-50 transition duration-150">
                            <td class="px-6 py-4 text-sm text-gray-400">{{ $index + 1 }}</td>
                            <td class="px-6 py-4 text-sm font-medium text-gray-900">{{ $post['title'] }}</td>
                            <td class="px-6 py-4 text-sm text-gray-500">{{ $post['category'] }}</td>
                            <td class="px-6 py-4 text-sm font-semibold text-gray-700">
                                {{ $post['comment_count'] }}
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="4" class="px-6 py-4 text-center text-gray-400 text-sm">
                                No published posts found.
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </section>

        {{-- Posts by Status: groupBy('status') --}}
        <section class="mb-10">
            <h2 class="text-lg font-semibold text-gray-700 mb-1">Posts by Status</h2>
            <p class="text-sm text-gray-400 mb-4 font-mono">groupBy('status')</p>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                @foreach($postsByStatus as $status => $group)
                <div class="border border-gray-200 rounded-lg p-5">
                    <p class="text-sm font-medium text-gray-500 capitalize mb-1">{{ $status }}</p>
                    <p class="text-3xl font-bold text-gray-900">{{ $group->count() }}</p>
                    <p class="text-xs text-gray-400 mt-1">posts</p>
                </div>
                @endforeach
            </div>
        </section>

        {{-- Posts by Category: groupBy with closure --}}
        <section class="mb-10">
            <h2 class="text-lg font-semibold text-gray-700 mb-1">Posts by Category</h2>
            <p class="text-sm text-gray-400 mb-4 font-mono">
                groupBy(fn ($post) =&gt; $post-&gt;category?-&gt;name ?? 'Uncategorized')
            </p>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
                @foreach($postsByCategory as $categoryName => $group)
                <div class="bg-indigo-50 border border-indigo-100 rounded-lg p-3 text-center">
                    <p class="text-xs font-medium text-indigo-700 mb-1">{{ $categoryName }}</p>
                    <p class="text-2xl font-bold text-indigo-900">{{ $group->count() }}</p>
                </div>
                @endforeach
            </div>
        </section>

        {{-- Partition result --}}
        <section class="mb-4">
            <h2 class="text-lg font-semibold text-gray-700 mb-1">Published vs. Everything Else</h2>
            <p class="text-sm text-gray-400 mb-4 font-mono">
                partition(fn ($post) =&gt; $post-&gt;status === 'published')
            </p>
            <div class="flex gap-4">
                <div class="flex-1 bg-green-50 border border-green-200 rounded-lg p-5 text-center">
                    <p class="text-3xl font-bold text-green-700">{{ $published->count() }}</p>
                    <p class="text-sm text-green-600 mt-2">Published</p>
                    <p class="text-xs text-gray-400 mt-1">passed the condition</p>
                </div>
                <div class="flex-1 bg-red-50 border border-red-200 rounded-lg p-5 text-center">
                    <p class="text-3xl font-bold text-red-700">{{ $unpublished->count() }}</p>
                    <p class="text-sm text-red-600 mt-2">Draft or Archived</p>
                    <p class="text-xs text-gray-400 mt-1">failed the condition</p>
                </div>
            </div>
        </section>

    </div>

    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
            target="_blank">Tutorial Collections Pipeline at qadrlabs.com</a>
    </div>
</body>
</html>
```

Save the file `resources/views/posts/stats.blade.php`.

## Step 12: Write the Pest Tests {#step-12-pest-tests}

If Pest is not yet installed in your project, run these three commands in order. Each command must complete before the next one starts.

```bash
composer remove phpunit/phpunit
```

```bash
composer require pestphp/pest --dev --with-all-dependencies
```

```bash
./vendor/bin/pest --init
```

With Pest ready, generate the test file:

```bash
php artisan make:test CollectionsPipelineTest
```

```
$ php artisan make:test CollectionsPipelineTest

   INFO  Test [tests/Feature/CollectionsPipelineTest.php] created successfully.
```

Open the file `tests/Feature/CollectionsPipelineTest.php` and replace its entire contents with the following. Each test focuses on a single Collection operation and seeds only the data it needs, keeping test isolation clean and execution fast.

```php
<?php

use App\Models\Category;
use App\Models\Comment;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

// Shared setup: a user and a category available in every test
beforeEach(function () {
    $this->user     = User::factory()->create();
    $this->category = Category::factory()->create();
});

it('renders the stats page and returns a 200 response', function () {
    Post::factory()->count(5)->create([
        'user_id'     => $this->user->id,
        'category_id' => $this->category->id,
        'status'      => 'published',
    ]);

    $this->get(route('posts.stats'))->assertStatus(200);
});

it('map produces a collection with the same item count as the source', function () {
    Post::factory()->count(10)->create([
        'user_id'     => $this->user->id,
        'category_id' => $this->category->id,
    ]);

    $posts  = Post::with(['category', 'comments'])->get();
    $mapped = $posts->map(fn (Post $post) => [
        'title'         => $post->title,
        'comment_count' => $post->comments->count(),
    ]);

    // map() is a one-to-one transformation: output count equals input count
    expect($mapped)->toHaveCount($posts->count());
});

it('filter returns only published posts', function () {
    Post::factory()->count(4)->create([
        'user_id'     => $this->user->id,
        'category_id' => $this->category->id,
        'status'      => 'published',
    ]);
    Post::factory()->count(3)->create([
        'user_id'     => $this->user->id,
        'category_id' => $this->category->id,
        'status'      => 'draft',
    ]);

    $posts     = Post::all();
    $published = $posts->filter(fn (Post $post) => $post->status === 'published');

    expect($published)->toHaveCount(4);
    expect($published->every(fn (Post $p) => $p->status === 'published'))->toBeTrue();
});

it('groupBy organizes posts under the correct status keys', function () {
    Post::factory()->count(3)->create([
        'user_id'     => $this->user->id,
        'category_id' => $this->category->id,
        'status'      => 'published',
    ]);
    Post::factory()->count(2)->create([
        'user_id'     => $this->user->id,
        'category_id' => $this->category->id,
        'status'      => 'draft',
    ]);

    $postsByStatus = Post::all()->groupBy('status');

    expect($postsByStatus->has('published'))->toBeTrue();
    expect($postsByStatus->has('draft'))->toBeTrue();
    expect($postsByStatus['published'])->toHaveCount(3);
    expect($postsByStatus['draft'])->toHaveCount(2);
});

it('reduce returns the correct total comment count across all posts', function () {
    $post1 = Post::factory()->create([
        'user_id'     => $this->user->id,
        'category_id' => $this->category->id,
    ]);
    $post2 = Post::factory()->create([
        'user_id'     => $this->user->id,
        'category_id' => $this->category->id,
    ]);

    Comment::factory()->count(3)->create(['post_id' => $post1->id, 'user_id' => $this->user->id]);
    Comment::factory()->count(5)->create(['post_id' => $post2->id, 'user_id' => $this->user->id]);

    $totalComments = Post::with('comments')->get()->reduce(
        fn (int $carry, Post $post) => $carry + $post->comments->count(),
        0
    );

    expect($totalComments)->toBe(8);
});

it('partition splits posts into published and non-published groups correctly', function () {
    Post::factory()->count(4)->create([
        'user_id'     => $this->user->id,
        'category_id' => $this->category->id,
        'status'      => 'published',
    ]);
    Post::factory()->count(6)->create([
        'user_id'     => $this->user->id,
        'category_id' => $this->category->id,
        'status'      => 'draft',
    ]);

    [$published, $unpublished] = Post::all()->partition(
        fn (Post $post) => $post->status === 'published'
    );

    expect($published)->toHaveCount(4);
    expect($unpublished)->toHaveCount(6);

    // The two groups together should account for all posts
    expect($published->count() + $unpublished->count())->toBe(Post::count());
});

it('the pipeline returns at most 5 published posts in descending comment order', function () {
    // Create published posts with known, fixed comment counts for deterministic ordering
    $post1 = Post::factory()->create([
        'user_id' => $this->user->id, 'category_id' => $this->category->id, 'status' => 'published',
    ]);
    $post2 = Post::factory()->create([
        'user_id' => $this->user->id, 'category_id' => $this->category->id, 'status' => 'published',
    ]);
    $post3 = Post::factory()->create([
        'user_id' => $this->user->id, 'category_id' => $this->category->id, 'status' => 'draft',
    ]);

    Comment::factory()->count(10)->create(['post_id' => $post1->id, 'user_id' => $this->user->id]);
    Comment::factory()->count(3)->create(['post_id' => $post2->id, 'user_id' => $this->user->id]);
    Comment::factory()->count(7)->create(['post_id' => $post3->id, 'user_id' => $this->user->id]);

    $posts    = Post::with(['category', 'comments'])->get();
    $topPosts = $posts
        ->filter(fn (Post $post) => $post->status === 'published')
        ->sortByDesc(fn (Post $post) => $post->comments->count())
        ->take(5)
        ->values();

    // Only 2 published posts exist, so the result should be 2
    expect($topPosts)->toHaveCount(2);

    // First item (10 comments) should have more comments than second item (3 comments)
    expect($topPosts[0]->comments->count())->toBeGreaterThan($topPosts[1]->comments->count());

    // Draft post should not appear in the result
    expect($topPosts->every(fn (Post $p) => $p->status === 'published'))->toBeTrue();
});
```

Save the file `tests/Feature/CollectionsPipelineTest.php`.

Run the full test suite for this feature:

```bash
./vendor/bin/pest tests/Feature/CollectionsPipelineTest.php
```

```
$ ./vendor/bin/pest tests/Feature/CollectionsPipelineTest.php

   PASS  Tests\Feature\CollectionsPipelineTest
  ✓ it renders the stats page and returns a 200 response                 0.16s
  ✓ it map produces a collection with the same item count as the source  0.01s
  ✓ it filter returns only published posts                               0.01s
  ✓ it groupBy organizes posts under the correct status keys             0.01s
  ✓ it reduce returns the correct total comment count across all posts   0.01s
  ✓ it partition splits posts into published and non-published groups c… 0.01s
  ✓ it the pipeline returns at most 5 published posts in descending com… 0.02s

  Tests:    7 passed (15 assertions)
  Duration: 0.27s
```

## Step 13: Try It Out {#step-13-try-it-out}

Start the development server:

```bash
php artisan serve
```

Open your browser and navigate to `http://127.0.0.1:8000/posts/stats`.

### Summary Cards

The four cards at the top pull from `$posts->count()`, `$published->count()`, `$unpublished->count()`, and `$totalComments`. If your seeder ran correctly, you should see 60 total posts with roughly 30 published, 30 in the unpublished group, and around 200 to 300 total comments depending on the random distribution from the seeder.

### Top 5 Most Commented Published Posts

The table shows the result of the chained pipeline. The posts are sorted with the highest comment count first. Each time you run `php artisan migrate:fresh --seed`, the data changes because the seeder randomizes both category assignment and comment counts per post.

### Posts by Status

The three cards show the output of `groupBy('status')`. You should see three groups: published, draft, and archived. Their counts reflect the Seeder's sequence configuration, which produces roughly 30 published, 15 draft, and 15 archived posts out of 60 total.

### Posts by Category

This section shows the output of `groupBy()` with a closure resolving the category name from the relationship. One card appears per category, and all eight categories created by the seeder should appear here.

### Published vs. Everything Else

The two values here come from `partition()`. Their sum should always equal `$posts->count()` exactly, because `partition()` places every item into one of the two groups without discarding any.

### Verify Key Operations in Tinker

Open Tinker to inspect a few operations interactively:

```bash
php artisan tinker
```

```
>>> $posts = App\Models\Post::with(['comments'])->get();
>>> $posts->count()
=> 60
>>> $posts->filter(fn ($p) => $p->status === 'published')->count()
=> 30
>>> $posts->reduce(fn ($carry, $p) => $carry + $p->comments->count(), 0)
=> 249
>>> $posts->groupBy('status')->keys()->all()
=> ["published", "draft", "archived"]
>>> $posts->pluck('title')->first()
=> "Aut rerum vel quisquam"
```

The comment count will vary from run to run since the seeder assigns a random number of comments to each post.

## How Collections Stay Immutable {#how-collections-stay-immutable}

Every method covered in this tutorial, including `map()`, `filter()`, `reject()`, `sortBy()`, `groupBy()`, `pluck()`, and `partition()`, returns a brand new Collection instance. The original Collection is not changed. This is what "immutable" means in the context of Collections.

You can verify this directly. After calling `filter()`, the original `$posts` still contains all 60 posts:

```php
$published = $posts->filter(fn ($p) => $p->status === 'published');

$posts->count();     // still 60
$published->count(); // 30
```

There is one exception worth knowing: `transform()`. Unlike `map()`, `transform()` mutates the Collection in place and returns the same instance, not a new one. It is rarely the right choice and should be avoided unless you explicitly want to discard the original. In the vast majority of cases, `map()` is the correct method to reach for.

## When NOT to Use Collections {#when-not-to-use-collections}

Collections are powerful, but they are not always the right tool. A few situations where you should push the work back to the database instead of reaching for a Collection method:

**Large datasets.** If your table has tens of thousands of rows, calling `Post::get()->filter(...)` loads every row into memory before discarding most of them. For large tables, `Post::where('status', 'published')->get()` tells the database engine to filter before sending data to PHP. The difference is not just speed: it is also the amount of memory your application holds during the request.

**Heavy aggregation.** If you need a count of comments per post across the whole table, a single SQL query with `withCount('comments')` is far more efficient than loading full Post models with their comment relationships and running `reduce()` in PHP. The database engine is built for aggregation; PHP is not.

**Paginated results.** Collection methods operate on a fixed set of items already in memory. If your page needs paginated results, use Eloquent's `paginate()` or `cursorPaginate()` on the query builder. Applying Collection methods after calling `get()` on a large table means you have already loaded every row before pagination logic can limit the result set.

The guiding rule is to treat the boundary between the database and PHP as a gate. Filter, sort, and aggregate on the database side using Eloquent's query builder whenever the data set is large or unbounded. Use Collection methods on the PHP side for transformations that the query builder cannot express: formatting output for a view, applying business logic that involves PHP code, or processing a small, already-loaded set of records in multiple ways at once, which is exactly the pattern this tutorial demonstrates.

## Collection vs. Query: When to Use Each {#collection-vs-query}

The methods in this tutorial are applied to a Collection that is already in memory, meaning the database has already returned all 60 posts before any filtering or grouping happens. For the stats page, where 60 records is a small and bounded set, this is perfectly appropriate.

The concern arises when you apply `filter()` or `groupBy()` to results from a large table. If you write `Post::get()->filter(...)` on a table with 50,000 rows, PHP loads all 50,000 models into memory before discarding most of them. The equivalent `Post::where('status', 'published')->get()` tells the database engine to do the filtering, returns only the matching rows, and uses a fraction of the memory.

A useful mental rule is to think of the boundary between the database and PHP as a gate. Push as much filtering, sorting, and aggregating through that gate as you can using Eloquent's query builder methods (`where`, `orderBy`, `groupBy`, `withCount`). Use Collection methods on the PHP side for transformations that the query builder cannot express, such as formatting output for a view, computing a value from a relationship that is already eager-loaded, or applying business logic that depends on PHP code.

In this tutorial, the data is already loaded because the stats page needs multiple views of the same dataset simultaneously. Loading once and processing the Collection multiple times in PHP is more efficient than running eight separate database queries.

## Conclusion {#conclusion}

Collections are not just a set of utility helpers. They represent a shift in thinking from control flow to data transformation. Instead of writing loops that describe *how* to walk through data, you compose pipelines that describe *what* you want out of it. The methods do the walking; you describe the intent.

This tutorial built a real statistics dashboard on top of existing blog data, demonstrating each Collection method in a context where the output is visible in the browser and verified by a Pest test. Here are the key takeaways:

- **Eloquent results are already Collections.** You do not need to wrap `Post::get()` in `collect()`. The Eloquent Collection class extends the base Collection and inherits all pipeline methods.
- **`map()` transforms without mutating.** Every call to `map()` returns a new Collection of the same size with each item replaced by what the callback returns. The original is preserved.
- **`filter()` keeps; `reject()` discards.** Use whichever reads more naturally for the intent of the operation. Keeping published posts is `filter()`. Throwing away published posts is `reject()`.
- **`pluck()` is `map()` for a single field.** Reach for `pluck()` whenever you only need one attribute from each item. It is more concise and communicates intent immediately.
- **`sortBy()` accepts closures for computed values.** When the sort key is not a stored field but a calculated one such as a comment count, pass a closure that returns the value to sort by. Always eager-load relationships before sorting by them to avoid N+1 queries inside the closure.
- **`groupBy()` produces a nested Collection.** Each key in the result is a group name, and each value is a Collection of items that belong to that group, fully chainable.
- **`reduce()` produces a single scalar.** Use it when you need one aggregated value from the entire Collection and want to keep the starting value and the accumulation logic self-contained.
- **`partition()` replaces two mirrored calls.** When you need both sides of a condition at the same time, one `partition()` call is cleaner and more readable than separate `filter()` and `reject()` calls.
- **Chain methods to build a pipeline.** Each method returns a Collection, so the next method can be called directly on the result. Chained pipelines read top to bottom and describe the transformation intent without intermediate variables.
- **Use null-safe access in closures.** The `?->` operator and `??` fallback prevent fatal errors when relationships are missing, turning a potential 500 error into a graceful default value.
- **Push filtering to the query for large datasets.** Collection methods operate on data already in memory. For large tables, use Eloquent's query builder to filter at the database level and limit what gets loaded into PHP.