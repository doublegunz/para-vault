---
title: "Fixing the N+1 Query Problem in Your Laravel Project"
slug: "fixing-the-n1-query-problem-in-your-laravel-project"
category: "Laravel"
date: "2024-12-27"
status: "draft"
id_version: "mengatasi-n1-query-problem-di-project-laravel"
---

## Introduction {#introduction}
The N+1 Query Problem is one of the biggest performance challenges Laravel developers face. This problem appears when an application runs inefficient database queries while accessing relationships between models, resulting in excessive query execution that impacts application performance and server load.

This article will take an in-depth look at the N+1 query problem in Laravel, how to identify it, and how to implement a solution using Laravel's built-in features to optimize your application's performance.

## Overview {#overview}
This tutorial will cover three important aspects:

1. The basic concept of the N+1 Query Problem in the context of Laravel
2. Implementing eager loading as an optimization solution
3. A performance demonstration through a practical case study with a simple blog feature

Through this case study, we will learn how to identify the N+1 query problem and apply the right solution to improve the performance of a Laravel application.


## What Is the N+1 Query Problem? {#apa-itu-n-plus-one-query-problem}

Before jumping into the solution, it is important to understand the problem first. The **N+1 Query Problem** is an inefficient database query pattern, where:

1. **1 query** is used to fetch the main data (such as a list of posts).
2. **N additional queries** are used to fetch the related data (such as each post's category).

For example, if we have 100 posts and each post has a category, by default Laravel will run **1 query to fetch all posts** and **100 additional queries** to fetch the category data. That adds up to **101 queries** just to load data that should be retrievable with **2 queries**.

### Example of the Problem {#contoh-masalah}

The following code is often the cause of the N+1 query problem:

```php
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->title . ' - ' .$post->category->name . '<br/>';
}
```

#### Generated Queries:

1. The first query to fetch all posts:

   ```sql
   SELECT * FROM posts;
   ```

2. An additional query for each category (for example, for `category_id = 1`):

   ```sql
   SELECT * FROM categories WHERE id = 1 LIMIT 1;
   ```

If there are 100 posts, Laravel will run **1 query to fetch the posts** and **100 additional queries** to fetch the related categories.

------

## Identifying N+1 Queries in Laravel {#mengidentifikasi-n-plus-one-query-di-laravel}

To identify the N+1 query problem in a Laravel application, we can use a debugging tool like **Laravel Debugbar**. Debugbar displays all the queries executed during an HTTP request, so we can easily see whether an N+1 pattern exists.

### Identification Steps

1. First, we install Laravel Debugbar by running the following command:

   ```bash
   composer require fruitcake/laravel-debugbar --dev
   ```

2. Run the application using `php artisan serve`, access a page, and look at the **Queries** tab in Debugbar.

3. On the **Queries** tab in Debugbar, pay attention to the number of queries executed. If the query count does not make sense (for example, hundreds for a small dataset), there is most likely an N+1 problem.

------

## The Solution: Using Eager Loading {#solusi-menggunakan-eager-loading}

Laravel provides a built-in solution for this problem: **eager loading**. With eager loading, Laravel loads the relationship data all at once in a single additional query, eliminating the need to run a query per item.

### Implementing Eager Loading {#implementasi-eager-loading}

Here is how to fix the previous code using `with()`:

```php
$posts = Post::with('category')->get();
foreach ($posts as $post) {
    echo $post->title . ' - ' .$post->category->name . '<br/>';
}
```

#### Generated Queries:

1. The first query to fetch all posts:

   ```sql
   SELECT * FROM posts;
   ```

2. The second query to fetch all related categories:

   ```sql
   SELECT * FROM categories WHERE id IN (1, 2, 3, ...);
   ```

As a result, there are only **2 queries** regardless of the number of posts.

## How It Works and Optimization {#cara-kerja-dan-optimisasi}

Laravel provides two approaches for loading relationships between models:

**Lazy Loading**
- The default approach in Laravel
- Loads relationship data only when it is accessed in the code
- Causes the N+1 query problem because every relationship access triggers a new query
- Example:
```php
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->category->name; // Trigger a new query
}
```

**Eager Loading**
- Loads relationship data up front together with the main query
- Uses the `with()` method to specify which relationships to load
- Produces a minimal and consistent number of queries
- Example:
```php
$posts = Post::with('category')->get(); // Load all data at once
foreach ($posts as $post) {
    echo $post->category->name; // Using the loaded data
}
```

The performance difference between these two approaches is significant, especially when handling large datasets. Eager loading produces more efficient queries and substantially reduces the load on the database.



## Simulation and Case Study {#simulasi-dan-studi-kasus}
For a practical demonstration, we will use a simple project available at the [N+1 query problem example repository](https://github.com/qadrLabs/n-1-query-problem-example). This project displays a list of blog posts along with their categories, with 100 dummy records generated using a seeder.

The project uses two main models: `App\Models\Category` and `App\Models\Post`.

Here is `App\Models\Category`.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
    ];
}
```

And here is `App\Models\Post`.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'content',
        'slug',
        'status',
        'category_id',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}
```

As you can see in the code above, there is a relationship to the `Category` model.

In this project, we will use a `PostController` controller with an `index()` method that we use to display the list of posts along with each post's category name.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;

class PostController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $posts = Post::all();
//        $posts = Post::with('category')->get();

        return view('posts.index', compact('posts'));
    }
}

```


```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fix N+1 Query Problem</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body>

    @forelse ($posts as $post)
        <p>{{ $post->title . ' - ' .$post->category->name }}</p>
    @empty
        <p>No posts found.</p>
    @endforelse
</body>
</html>

```


As you can see in the code above, we fetch all post data using `Post::all()`, then we try to display that data using `foreach`.

Now let's run our project using `php artisan serve`, then access `http://127.0.0.1:8000/posts`. In Debugbar, click the **Queries** tab as shown in the following image.

![contoh N+1 Query Problem](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/n%2B1-query-problem/1-contoh-n-plus-one-query-problem.png)

As you can see in the image above, when the page is accessed, the number of queries executed to display 100 posts is **101**, which is the **N+1 Query Problem**, where **N=100**. 

To fix this problem, we will use Eager Loading. Now open `PostController` again, then modify the `index()` method to look like the following.

```php
    public function index()
    {
        $posts = Post::with('category')->get();

        return view('posts.index', compact('posts'));
    }
```

Here we change the code:

```php
$posts = Post::all();
```

Into:

```php
$posts = Post::with('category')->get();
```

Save `PostController` again, then access `http://127.0.0.1:8000/posts` once more. 

![implementasi eager loading sebagai solusi N+1 query problem](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/n%2B1-query-problem/2-implementasi-solusi-untuk-n-plus-one-query-problem.png)

As you can see in the image above, the number of executed queries is **2**.

Let's compare the performance before and after using eager loading.

#### Before Eager Loading:

- Data: 100 posts, 10 categories.
- Queries: **101 queries**.

#### After Eager Loading:

- Data: 100 posts, 10 categories.
- Queries: **2 queries**.

These results show that eager loading can reduce the number of queries by up to 98%.

## Conclusion {#kesimpulan}

The N+1 query problem is a performance challenge that can be overcome with the right understanding and implementation. By using eager loading, the number of queries can drop significantly, from 101 queries to just 2 queries for 100 records, resulting in a performance improvement of up to 98%.

Key points to remember:
1. Use Laravel Debugbar to identify N+1 queries
2. Implement eager loading with the `with()` method on model relationships
3. Monitor query performance before and after optimization

By applying the practices covered here, developers can build Laravel applications that are more efficient and responsive.
