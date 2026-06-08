---
title: "Laravel 13 CRUD Tutorial: Build a Simple Blog Step by Step"
slug: "laravel-13-crud-tutorial-build-a-simple-blog-step-by-step"
category: "Laravel"
date: "2026-03-23"
status: "published"
---

Laravel 13 just landed with exciting new features like the `#[Fillable]` attribute and expanded PHP attributes. But if you are new to the framework or upgrading from an older version, figuring out how to apply these changes in a real project can be confusing. The official documentation covers the "what" but not always the "how" in a practical context. This tutorial bridges that gap. We will build a simple blog with full CRUD functionality using Laravel 13 step by step, so you can see exactly how the pieces fit together in a working application.


## Overview {#overview}

This tutorial walks you through building a basic blog application from scratch using Laravel 13. We will create a post management system where you can create, view, edit, and delete blog posts.

### What You'll Build

A simple blog application with the following features:

- A listing page that displays all posts with pagination.
- A form to create new posts with title, content, and status fields.
- A detail page to view a single post.
- A form to edit existing posts.
- A delete function with confirmation prompt.

![Project Preview](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/00-app-preview.webp)

### What You'll Learn

By following this tutorial, you will learn how to:

- Set up a new Laravel 13 project from scratch.
- Create models, migrations, and controllers using Artisan commands.
- Define database schemas and run migrations.
- Build CRUD operations with a resource controller.
- Create Blade views styled with Tailwind CSS.
- Use Laravel 13's new `#[Fillable]` attribute on Eloquent models.
- Set up resource routes for RESTful URL patterns.

### What You'll Need

Before getting started, make sure you have:

- PHP 8.3 or higher
- Composer installed globally
- MySQL (or another supported database)
- A code editor (Visual Studio Code recommended)
- Basic familiarity with PHP and Laravel concepts


## Step 1: Create a Laravel Project {#step-1-create-laravel-project}

Start by creating a fresh Laravel project using Composer. We will name the project `blog`:

```
composer create-project laravel/laravel --prefer-dist blog
```

```
$ composer create-project laravel/laravel --prefer-dist blog
Creating a "laravel/laravel" project at "./blog"
Installing laravel/laravel (v13.1.0)
.
.
.
```

Wait for Composer to finish downloading and installing all dependencies. The output confirms that Laravel v13.1.0 is being installed.

Once the installation is complete, navigate into the project directory:

```
cd blog
```

If you are using Visual Studio Code, you can open the project directly from the terminal:

```
code .
```

This opens the entire project folder in your editor, making it easy to navigate between files as we build the application.


## Step 2: Set Up Database Configuration {#step-2-setup-database-configuration}

Before we can store any data, we need to tell Laravel how to connect to our database. Open the `.env` file in your project root and update the database settings:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_belajar_laravel
DB_USERNAME=root
DB_PASSWORD=password
```

**Note:** Adjust the `DB_USERNAME` and `DB_PASSWORD` values to match your local MySQL credentials. The `DB_DATABASE` value is the name of the database that Laravel will use. You do not need to create the database manually, as Laravel will offer to create it for you when you run the migration command later.

Save the `.env` file after making your changes.


## Step 3: Create Model and Migration {#step-3-create-model-and-migration}

Laravel provides Artisan commands that generate boilerplate code for you. The following command creates both a `Post` model and its corresponding migration file in a single step:

```
php artisan make:model Post -m
```

```
$ php artisan make:model Post -m

   INFO  Model [app/Models/Post.php] created successfully.  

   INFO  Migration [database/migrations/2026_03_23_032654_create_posts_table.php] created successfully.  

```

The `-m` flag tells Artisan to generate a migration file alongside the model. This saves you from running two separate commands.

### Define the Database Schema

Open the generated migration file at `database/migrations/xxxx_xx_xx_xxxxxx_create_posts_table.php` and modify it with the following content:

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
            $table->enum('status', ['draft', 'publish'])->default('draft');
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

Here is what each column does:

- `id()` creates an auto-incrementing primary key.
- `string('title')` stores the post title as a VARCHAR column.
- `string('slug')->unique()` stores a URL-friendly version of the title. The `unique()` constraint ensures no two posts share the same slug.
- `text('content')` stores the post body, which can be longer than a VARCHAR allows.
- `enum('status', ['draft', 'publish'])->default('draft')` restricts the status to two possible values and defaults new posts to "draft."
- `timestamps()` adds `created_at` and `updated_at` columns that Laravel manages automatically.

Save the migration file.

### Configure the Model

Open `app/Models/Post.php` and replace its content with:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['title', 'slug', 'content', 'status'])]
class Post extends Model
{
    use HasFactory;
}
```

Notice the `#[Fillable]` attribute on the class declaration. This is a new feature in Laravel 13 that uses PHP's native attribute syntax to define which fields can be mass-assigned. In previous versions, you would set a `$fillable` property inside the class. The attribute approach keeps the configuration declarative and colocated with the class definition.

Save the model file.

### Run the Migration

Now execute the migration to create the `posts` table in your database:

```
php artisan migrate
```

```
$ php artisan migrate

   WARN  The database 'db_belajar_laravel' does not exist on the 'mysql' connection.  

 ┌ Would you like to create it? ────────────────────────────────┐
 │ ● Yes / ○ No                                                 │
 └──────────────────────────────────────────────────────────────┘

```

Since the database does not exist yet, Laravel asks if you want to create it. Select **Yes** and press Enter to continue. Laravel will create the database and run all pending migrations, including the `posts` table we just defined.


## Step 4: Build the Post Listing Feature {#step-4-build-post-listing}

With the database ready, let's start building the application layer. We will begin with the post listing page.

### Generate a Resource Controller

Use Artisan to generate a resource controller pre-wired to the `Post` model:

```
php artisan make:controller PostController --model=Post --resource
```

```
$ php artisan make:controller PostController --model=Post --resource

   INFO  Controller [app/Http/Controllers/PostController.php] created successfully.  

```

The `--resource` flag generates a controller with all seven RESTful methods (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`) already stubbed out. The `--model=Post` flag type-hints the `Post` model in methods that need it, such as `show`, `edit`, `update`, and `destroy`.

### Implement the Index Method

Open `app/Http/Controllers/PostController.php` and modify the `index()` method:

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
        $posts = Post::latest()->paginate(10);
        return view('posts.index', compact('posts'));
    }

    // ... [other lines of code]
}
```

`Post::latest()` orders the query by `created_at` in descending order, so the newest posts appear first. `paginate(10)` limits the results to 10 per page and automatically generates pagination links. The `compact('posts')` function passes the `$posts` variable to the Blade view.

Save the controller file.

### Create the Index View

Create a new file at `resources/views/posts/index.blade.php` and add the following content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Posts</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-7xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-3xl font-bold text-gray-900">Manage Posts</h1>
            <a href="{{ route('posts.create') }}" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm">
                Create New Post
            </a>
        </div>

        @if(session('success'))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative mb-6" role="alert">
                <span class="block sm:inline">{{ session('success') }}</span>
            </div>
        @endif

        <div class="overflow-x-auto">
            <table class="min-w-full bg-white border border-gray-200 shadow-sm rounded-lg overflow-hidden">
                <thead class="bg-gray-50 border-b border-gray-200">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-16">No</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Title</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Slug</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                    @forelse($posts as $post)
                    <tr class="hover:bg-gray-50 transition duration-150">
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center">{{ $posts->firstItem() + $loop->index }}</td>
                        <td class="px-6 py-4 text-sm font-medium text-gray-900">{{ $post->title }}</td>
                        <td class="px-6 py-4 text-sm text-gray-500 break-words">{{ $post->slug }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm">
                            <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full {{ $post->status === 'publish' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800' }}">
                                {{ ucfirst($post->status) }}
                            </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                            <a href="{{ route('posts.show', $post) }}" class="inline-flex items-center px-3 py-1.5 bg-blue-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-blue-700 focus:outline-none transition ease-in-out duration-150 shadow-sm">View</a>
                            <a href="{{ route('posts.edit', $post) }}" class="inline-flex items-center px-3 py-1.5 bg-amber-500 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-amber-600 focus:outline-none transition ease-in-out duration-150 shadow-sm">Edit</a>
                            <form action="{{ route('posts.destroy', $post) }}" method="POST" class="inline-block m-0">
                                @csrf
                                @method('DELETE')
                                <button type="submit" onclick="return confirm('Are you sure you want to delete this post?')" class="inline-flex items-center px-3 py-1.5 bg-red-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-red-700 focus:outline-none transition ease-in-out duration-150 shadow-sm">Delete</button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" class="px-6 py-4 text-center text-sm text-gray-500">No posts found.</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="mt-6">
            {{ $posts->links() }}
        </div>
    </div>
    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial CRUD Laravel 13 at qadrlabs.com</a>
    </div>
</body>
</html>
```

A few things to note about this view:

- We use **Tailwind CSS via CDN** for styling, which keeps the tutorial simple without requiring a build step.
- The `@forelse` / `@empty` directive handles both cases: when posts exist and when the table is empty.
- `$posts->firstItem() + $loop->index` calculates the correct row number across paginated pages. For example, on page 2 with 10 items per page, the numbering starts at 11 instead of resetting to 1.
- The delete button is wrapped in a form with `@method('DELETE')` because HTML forms only support GET and POST. Laravel uses this hidden field to interpret the request as a DELETE method.
- `{{ $posts->links() }}` renders the pagination controls automatically.

Save the view file.

### Register Routes

Open `routes/web.php` and register a resource route for the `PostController`:

```php
<?php

use App\Http\Controllers\PostController; // add this use statement
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::resource('posts', PostController::class); // add this resource route
```

`Route::resource()` registers all seven RESTful routes (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`) in a single line. This is equivalent to writing seven individual route definitions manually. Laravel maps each route to the corresponding method in `PostController`.

Save the route file.


## Step 5: Build the Create Post Feature {#step-5-build-create-post}

Now let's implement the ability to add new posts.

### Implement the Create Method

Open `app/Http/Controllers/PostController.php` and update the `create()` method:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;

class PostController extends Controller
{
    // ... [other lines of code]

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return view('posts.create');
    }

    // ... [other lines of code]
}
```

This method simply returns the create form view. No data needs to be passed since the form starts empty.

Save the controller file.

### Create the Form View

Create a new file at `resources/views/posts/create.blade.php` and add the following content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Post</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-gray-900">Create Post</h1>
            <a href="{{ route('posts.index') }}" class="text-gray-600 hover:text-gray-900 underline text-sm transition">Back to Manage Posts</a>
        </div>
        
        @if($errors->any())
            <div class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded mb-6">
                <ul class="list-disc list-inside text-sm">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('posts.store') }}" method="POST" class="space-y-6">
            @csrf
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input type="text" id="title" name="title" value="{{ old('title') }}" required 
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
            </div>
            

            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Content</label>
                <textarea name="content" rows="8" required 
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition resize-y">{{ old('content') }}</textarea>
            </div>
            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select name="status" required 
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition">
                    <option value="draft" {{ old('status') == 'draft' ? 'selected' : '' }}>Draft</option>
                    <option value="publish" {{ old('status') == 'publish' ? 'selected' : '' }}>Publish</option>
                </select>
            </div>
            
            <div class="pt-2 flex justify-end">
                <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-6 rounded-md transition duration-200 shadow-sm">
                    Submit Post
                </button>
            </div>
        </form>
    </div>


    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial CRUD Laravel 13 at qadrlabs.com</a>
    </div>
</body>
</html>
```

A few things to highlight in this form:

- `@csrf` generates a hidden CSRF token field. Laravel requires this on all POST, PUT, PATCH, and DELETE forms to prevent cross-site request forgery attacks.
- `{{ old('title') }}` repopulates the field with previously submitted data if validation fails, so the user does not have to re-type everything.
- The `@if($errors->any())` block at the top displays validation error messages when the form submission is rejected.

Save the view file.

### Implement the Store Method

Open `app/Http/Controllers/PostController.php` again and update the `store()` method:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Str; // add this line of code

class PostController extends Controller
{
    // ... [other lines of code]

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->merge([
            'slug' => Str::slug($request->title),
        ]);

        $validatedData = $request->validate([
            'title' => 'required|max:255',
            'slug' => 'required|unique:posts,slug|max:255',
            'content' => 'required',
            'status' => 'required|in:draft,publish',
        ]);

        Post::create($validatedData);

        return redirect()->route('posts.index')->with('success', 'Post created successfully.');
    }

    // ... [other lines of code]
}
```

Here is what happens step by step:

1. `$request->merge()` generates a slug from the title using `Str::slug()`. For example, "My First Post" becomes "my-first-post". This is merged into the request data before validation.
2. `$request->validate()` checks that all required fields are present and valid. The `unique:posts,slug` rule ensures no duplicate slugs exist in the database. The `in:draft,publish` rule restricts the status to only those two values. If validation fails, Laravel automatically redirects back to the form with error messages.
3. `Post::create($validatedData)` inserts a new record into the `posts` table using only the validated fields. This works because we defined the `#[Fillable]` attribute on the model earlier.
4. `redirect()->route('posts.index')->with('success', ...)` sends the user back to the listing page with a flash message confirming the post was created.

Since we are going to convert the title into a slug, we will use a helper class from the Laravel framework by adding `use Illuminate\Support\Str;`.

```php
use Illuminate\Support\Str; // add this line of code

class PostController extends Controller
{
    // ... [other lines of code]
}
```

Save the controller file.


## Step 6: Build the View Post Detail Feature {#step-6-build-view-post-detail}

Next, let's add the ability to view a single post in detail.

### Implement the Show Method

Open `app/Http/Controllers/PostController.php` and update the `show()` method:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PostController extends Controller
{
    // ... [other lines of code]

    /**
     * Display the specified resource.
     */
    public function show(Post $post)
    {
        return view('posts.show', compact('post'));
    }

    // ... [other lines of code]
}
```

The `Post $post` parameter uses Laravel's **route model binding**. When a user visits `/posts/1`, Laravel automatically finds the `Post` with ID 1 and injects it into the method. If no matching record is found, Laravel returns a 404 response.

Save the controller file.

### Create the Show View

Create a new file at `resources/views/posts/show.blade.php` and add:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>View Post - {{ $post->title }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-3xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md mt-6">
        <div class="flex justify-between items-start mb-6 pb-6 border-b border-gray-200">
            <div>
                <h1 class="text-3xl font-bold text-gray-900 mb-2">{{ $post->title }}</h1>
                <div class="flex items-center space-x-4 text-sm text-gray-500">
                    <span class="flex items-center">
                        <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                        </svg>
                        {{ $post->slug }}
                    </span>
                    <span class="px-2 py-0.5 inline-flex text-xs leading-5 font-semibold rounded-full {{ $post->status === 'publish' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800' }}">
                        {{ ucfirst($post->status) }}
                    </span>
                </div>
            </div>
            <div class="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-3 items-end sm:items-center">
                <a href="{{ route('posts.index') }}" class="text-sm font-medium text-gray-600 hover:text-gray-900 bg-gray-100 hover:bg-gray-200 px-4 py-2 rounded-md transition shadow-sm border border-gray-200">Back</a>
                <a href="{{ route('posts.edit', $post) }}" class="text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 px-4 py-2 rounded-md shadow-sm transition">Edit Post</a>
            </div>
        </div>
        
        <div class="prose max-w-none text-gray-800 leading-relaxed whitespace-pre-wrap text-[17px]">
{{ $post->content }}
        </div>
        
        <div class="mt-10 pt-6 border-t border-gray-100 flex flex-col sm:flex-row sm:justify-between text-sm text-gray-500">
            <span>Posted: {{ $post->created_at->format('M d, Y H:i') }}</span>
            @if($post->updated_at != $post->created_at)
                <span>Updated: {{ $post->updated_at->format('M d, Y H:i') }}</span>
            @endif
        </div>
    </div>
    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial CRUD Laravel 13 at qadrlabs.com</a>
    </div>
</body>
</html>
```

This view displays the post title, slug, status badge, full content, and timestamps. The `$post->created_at->format('M d, Y H:i')` call uses Carbon (which Laravel includes by default) to format the timestamp into a human-readable string like "Mar 23, 2026 15:30".

Save the view file.


## Step 7: Build the Update Post Feature {#step-7-build-update-post}

Now let's add the ability to edit existing posts.

### Implement the Edit Method

Open `app/Http/Controllers/PostController.php` and update the `edit()` method:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PostController extends Controller
{
    // ... [other lines of code]

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Post $post)
    {
        return view('posts.edit', compact('post'));
    }

    // ... [other lines of code]
}
```

Like the `show()` method, `edit()` uses route model binding to fetch the post. The existing post data is passed to the view so the form can be pre-filled.

Save the controller file.

### Create the Edit View

Create a new file at `resources/views/posts/edit.blade.php` and add:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Post - {{ $post->title }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold text-gray-900">Edit Post</h1>
            <a href="{{ route('posts.index') }}" class="text-gray-600 hover:text-gray-900 underline text-sm transition">Back to Manage Posts</a>
        </div>
        
        @if($errors->any())
            <div class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded mb-6">
                <ul class="list-disc list-inside text-sm">
                    @foreach($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('posts.update', $post) }}" method="POST" class="space-y-6">
            @csrf
            @method('PUT')
            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                <input type="text" id="title" name="title" value="{{ old('title', $post->title) }}" required 
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
            </div>
            

            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Content</label>
                <textarea name="content" rows="8" required 
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition resize-y">{{ old('content', $post->content) }}</textarea>
            </div>
            
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select name="status" required 
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition">
                    <option value="draft" {{ old('status', $post->status) == 'draft' ? 'selected' : '' }}>Draft</option>
                    <option value="publish" {{ old('status', $post->status) == 'publish' ? 'selected' : '' }}>Publish</option>
                </select>
            </div>
            
            <div class="pt-2 flex justify-end">
                <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-6 rounded-md transition duration-200 shadow-sm">
                    Update Post
                </button>
            </div>
        </form>
    </div>


    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition" target="_blank">Tutorial CRUD Laravel 13 at qadrlabs.com</a>
    </div>
</body>
</html>
```

The edit form is similar to the create form, with two key differences:

- `@method('PUT')` adds a hidden field that tells Laravel to treat this form submission as a PUT request, which maps to the `update()` controller method.
- `{{ old('title', $post->title) }}` uses the second parameter as a fallback. If there is no old input (i.e., the form has not been submitted yet), it displays the current value from the database. This ensures the form is pre-filled with existing data when the user first opens it.

Save the view file.

### Implement the Update Method

Open `app/Http/Controllers/PostController.php` and update the `update()` method:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PostController extends Controller
{
    // ... [other lines of code]

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Post $post)
    {
        $request->merge([
            'slug' => Str::slug($request->title),
        ]);

        $validatedData = $request->validate([
            'title' => 'required|max:255',
            'slug' => 'required|unique:posts,slug,' . $post->id . '|max:255',
            'content' => 'required',
            'status' => 'required|in:draft,publish',
        ]);

        $post->update($validatedData);

        return redirect()->route('posts.index')->with('success', 'Post updated successfully.');
    }

    // ... [other lines of code]
}
```

The `update()` method follows a similar pattern to `store()`, but with one important difference in the validation rule. The slug uniqueness check includes `$post->id` as an exception: `unique:posts,slug,' . $post->id`. This tells Laravel to ignore the current post when checking for duplicate slugs. Without this exception, updating a post without changing its title would fail validation because the existing slug would be flagged as a duplicate of itself.

Save the controller file.


## Step 8: Build the Delete Post Feature {#step-8-build-delete-post}

The final CRUD operation is deleting a post.

### Implement the Destroy Method

Open `app/Http/Controllers/PostController.php` and update the `destroy()` method:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PostController extends Controller
{
    // ... [other lines of code]

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Post $post)
    {
        $post->delete();

        return redirect()->route('posts.index')->with('success', 'Post deleted successfully.');
    }
}
```

The `destroy()` method is straightforward. It calls `$post->delete()` to remove the record from the database, then redirects back to the listing page with a success message. The delete button in the index view already includes a JavaScript `confirm()` dialog, so the user gets a confirmation prompt before the deletion is executed.

Save the controller file.


## Step 9: Test the Application {#step-9-test-the-application}

With all CRUD operations implemented, it is time to test the application. Start the development server:

```
php artisan serve
```

Open your browser and navigate to `http://127.0.0.1:8000/posts`. You should see the post listing page with an empty table and a "Create New Post" button.
![View Post listing page](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/01-view-post-lists.webp)

### Test Creating a Post

Click the **Create New Post** button. Fill in the form with a title, content, and status, then click **Submit Post**. You should be redirected back to the listing page with a green success message, and your new post should appear in the table.

![test create new post feature](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/02-test-create-new-post-feature.webp)

![post created](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/03-post-created.webp)

### Test Viewing a Post

Click the **View** button on any post in the table. You should see a detail page showing the post title, slug, status, full content, and timestamps.

![view post by id](https://cdn.jsdelivr.net/gh/gungunpriatna/qadrlabs-assets@main/laravel/laravel-13/crud-tutorial/04-test-view-post-by-id.webp)

### Test Editing a Post

Click the **Edit** button on any post. The form should be pre-filled with the current post data. Make some changes and click **Update Post**. You should be redirected back to the listing page with a success message, and the updated data should be reflected in the table.

![test view edit post form](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/05-test-view-edit-post-form.webp)

![test update post feature](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/06-test-update-post-feature.webp)

![post updated](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/07-post-updated.webp)

### Test Deleting a Post

Click the **Delete** button on any post. A browser confirmation dialog should appear. Click OK to confirm. The post should be removed from the table, and a success message should be displayed.

![test delete post feature](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/08-test-delete-post-feature.webp)

![post deleted](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/laravel/laravel-13/crud-tutorial/09-post-deleted.webp)

## Conclusion {#conclusion}

In this tutorial, we built a complete CRUD application using Laravel 13 from scratch. Starting with a fresh project, we set up the database, created a model with the new `#[Fillable]` attribute, generated a resource controller, built Blade views with Tailwind CSS, and implemented all four CRUD operations.

Here are the key takeaways:

- **Artisan makes scaffolding fast.** Commands like `make:model -m` and `make:controller --resource` generate boilerplate code so you can focus on business logic.
- **Resource controllers and routes reduce repetition.** A single `Route::resource()` line registers all seven RESTful routes, and the `--resource` flag on the controller generates matching method stubs.
- **The `#[Fillable]` attribute is a Laravel 13 addition.** Instead of defining a `$fillable` property inside your model, you can now use a PHP attribute on the class declaration for a cleaner, more declarative approach.
- **Validation and slug generation work together.** By merging the slug into the request before validation, you can validate it like any other field, including checking for uniqueness.
- **Route model binding simplifies data retrieval.** Type-hinting a model in your controller method lets Laravel automatically find the record or return a 404.
- **Always test after each feature.** Running the application and verifying each CRUD operation ensures that everything works before moving on to the next step.

The complete source code for this project is available for reference at [https://github.com/qadrLabs/laravel-13-crud-demo](https://github.com/qadrLabs/laravel-13-crud-demo). In the next tutorial, we’ll learn [how to test using Pest](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application) on the blog application we’ve developed in this tutorial.