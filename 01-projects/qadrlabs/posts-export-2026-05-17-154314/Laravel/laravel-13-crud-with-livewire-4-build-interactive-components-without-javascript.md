---
title: "Laravel 13 CRUD with Livewire 4: Build Interactive Components Without JavaScript"
slug: "laravel-13-crud-with-livewire-4-build-interactive-components-without-javascript"
category: "Laravel"
date: "2026-03-28"
status: "published"
---

Livewire 4 was [released on January 14, 2026](https://github.com/livewire/livewire/releases/tag/v4.0.0), two months before Laravel 13 launched on March 17, 2026. This major release introduces Single-File Components (the `⚡` convention), `Route::livewire()` for cleaner routing, and the `$this->view()` rendering method, making the developer experience significantly different from Livewire 3.

If you followed our previous [CRUD with Laravel Livewire](https://qadrlabs.com/post/belajar-laravel-10-crud-with-laravel-livewire) tutorial using Laravel 10 and Livewire 3, you will notice substantial changes in this version. In Livewire 3, we used separate class and view files, a single component with toggle flags (`$addPost`, `$updatePost`) to switch between list/create/edit views, and a `$rules` array for validation. In Livewire 4, we use multiple Single-File Components (one per page), `#[Validate]` attributes, `Route::livewire()`, and SPA-like navigation with `wire:navigate`.

In this tutorial, we will rebuild the same CRUD application from scratch using Laravel 13 and Livewire 4 to demonstrate the new patterns.

## Overview {#overview}

We will build a blog post management system with full CRUD functionality using Livewire 4's Single-File Components. Every interaction (creating, editing, deleting, paginating) happens without a full page reload.

### What You'll Build

- A post listing page with pagination, status badges, and inline delete with confirmation.
- A create form with real-time validation using PHP attributes.
- An edit form that loads existing data and updates it reactively.
- SPA-like navigation between pages using `wire:navigate`.
- A polished UI styled with Bootstrap 5.

### What You'll Learn

- How to install and configure Livewire 4 in a Laravel 13 project.
- How to create Single-File Components (the `⚡` file convention).
- How to use `$this->view()`, `->layout()`, and `->title()` for rendering.
- How to bind form inputs with `wire:model` and validate with `#[Validate]` attributes.
- How to handle user actions with `wire:click` and `wire:navigate`.
- How to register routes using `Route::livewire()`.
- How to implement pagination with Livewire's `WithPagination` trait.

### What You'll Need

- PHP 8.3 or higher.
- Composer installed globally.
- MySQL or another supported database.
- A code editor (Visual Studio Code recommended).
- Basic familiarity with Laravel and Blade templates.


## Step 1: Create Project {#step-1-create-project}

Let's start by creating a fresh Laravel 13 project using Composer. Open your terminal and run:

```bash
composer create-project --prefer-dist laravel/laravel crud-livewire-4
```

This command downloads and installs the latest Laravel 13 release into a new directory called `crud-livewire-4`. The `--prefer-dist` flag ensures Composer downloads the pre-built distribution package, which is faster than cloning the repository.

Once the installation is complete, navigate into the project directory and open it in your editor:

```bash
cd crud-livewire-4/
code .
```

Configure your database in `.env`:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_crud_livewire
DB_USERNAME=root
DB_PASSWORD=password
```

**Note:** Adjust the credentials to match your local MySQL setup.

At this point, you have a clean Laravel 13 installation ready for development.


## Step 2: Create Migration and Model {#step-2-create-migration-and-model}

Before building our interface, we need a database table and an Eloquent model to represent our posts. Laravel's Artisan CLI makes this easy with a single command:

```bash
php artisan make:model Post -m
```

The `-m` flag tells Artisan to also generate a migration file alongside the model. You should see output similar to:

```
$ php artisan make:model Post -m

   INFO  Model [app/Models/Post.php] created successfully.  

   INFO  Migration [database/migrations/2026_03_28_112648_create_posts_table.php] created successfully.  

```

### Configure the Model

Open `app/Models/Post.php` and update it to define the fillable attributes using Laravel 13's `#[Fillable]` attribute:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable(['title', 'slug', 'content', 'status'])]
class Post extends Model
{
    //
}
```

The `#[Fillable]` attribute is a Laravel 13 feature that replaces the traditional `protected $fillable` property with a cleaner, declarative syntax. It tells Laravel which fields are safe for mass assignment when using `Post::create()` or `$post->update()`. We define four fields: `title` for the post headline, `slug` for a URL-friendly version of the title, `content` for the body text, and `status` to indicate whether the post is a draft or published.

Save the file.

### Define the Migration

Open the migration file at `database/migrations/xxxx_xx_xx_xxxxxx_create_posts_table.php` and update the `up()` method to define our table columns:

```php
public function up(): void
{
    Schema::create('posts', function (Blueprint $table) {
        $table->id();
        $table->string('title');
        $table->text('content');
        $table->string('slug');
        $table->smallInteger('status');
        $table->timestamps();
    });
}
```

Each column type is chosen deliberately: `string` for shorter text like titles and slugs, `text` for longer content, and `smallInteger` for the status flag (where `1` represents a draft and `2` represents a published post). The `timestamps()` method automatically adds `created_at` and `updated_at` columns.

Save the file.

### Run the Migration

Execute the migration to create the table in your database:

```bash
php artisan migrate
```

You should see confirmation that the migration ran successfully:

```
$ php artisan migrate

   INFO  Running migrations.  

  2026_03_28_112648_create_posts_table ........................... 4.67ms DONE

```


## Step 3: Install Livewire 4 Package {#step-3-install-livewire-package}

Now let's add Livewire 4 to our project. Install it via Composer:

```bash
composer require livewire/livewire:^4.0
```

Wait for the installation to complete. This pulls in Livewire 4 and all its dependencies.

### Publish the Configuration

Next, publish Livewire's configuration file so we can customize its behavior:

```bash
php artisan livewire:config
```

This copies the default configuration to `config/livewire.php`:

```
INFO  Publishing [livewire:config] assets.

  Copying file [vendor/livewire/livewire/config/livewire.php] to [config/livewire.php]  DONE
```

### Configure Pagination Theme

Since we will be using Bootstrap for our UI (rather than Tailwind), we need to tell Livewire to render Bootstrap-styled pagination links. Open `config/livewire.php`, find the following line:

```php
'pagination_theme' => 'tailwind',
```

And change it to:

```php
'pagination_theme' => 'bootstrap',
```

This ensures that when we call `$posts->links()` in our views, Livewire generates pagination markup compatible with Bootstrap 5.


## Step 4: Create Layout File {#step-4-create-layout-file}

Every full-page Livewire component needs a layout to wrap its content. Livewire 4 provides an Artisan command to generate the default layout:

```bash
php artisan livewire:layout
```

Output:

```
LAYOUT CREATED 🤙

CLASS: resources/views/layouts/app.blade.php
```

This creates a basic layout file. However, we want a polished, professional-looking interface, so let's replace the default content with a custom layout that includes Bootstrap 5, a navigation bar, and a footer.

Open `resources/views/layouts/app.blade.php` and replace its contents with:

```html
<!doctype html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'CRUD Livewire 4' }} - QadrLabs</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" rel="stylesheet"
        integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB" crossorigin="anonymous">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --color-primary: #111827;
            --color-secondary: #6b7280;
            --color-accent: #2563eb;
            --color-accent-hover: #1d4ed8;
            --color-surface: #ffffff;
            --color-border: #e5e7eb;
            --color-bg: #f9fafb;
            --color-success: #059669;
            --color-danger: #dc2626;
            --color-warning: #d97706;
            --radius: 8px;
        }

        * {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
        }

        body {
            background-color: var(--color-bg);
            color: var(--color-primary);
            display: flex;
            flex-direction: column;
            min-height: 100vh;
        }

        .navbar {
            background-color: var(--color-surface) !important;
            border-bottom: 1px solid var(--color-border);
            padding: 1rem 0;
        }

        .navbar-brand {
            font-weight: 700;
            font-size: 1.125rem;
            color: var(--color-primary) !important;
            letter-spacing: -0.025em;
        }

        .nav-link {
            font-size: 0.875rem;
            font-weight: 500;
            color: var(--color-secondary) !important;
            padding: 0.5rem 1rem !important;
            border-radius: var(--radius);
            transition: color 0.15s ease, background-color 0.15s ease;
        }

        .nav-link:hover,
        .nav-link.active {
            color: var(--color-primary) !important;
            background-color: var(--color-bg);
        }

        .main-content {
            flex: 1;
            padding-top: 2rem;
            padding-bottom: 4rem;
        }

        .site-footer {
            background-color: var(--color-surface);
            border-top: 1px solid var(--color-border);
            padding: 1.25rem 0;
            margin-top: auto;
        }

        .site-footer p {
            margin: 0;
            font-size: 0.8125rem;
            color: var(--color-secondary);
        }

        .site-footer a {
            color: var(--color-accent);
            text-decoration: none;
            font-weight: 500;
        }

        .site-footer a:hover {
            text-decoration: underline;
        }

        .card {
            background-color: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius);
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
        }

        .card-header {
            background-color: transparent;
            border-bottom: 1px solid var(--color-border);
            padding: 1.25rem 1.5rem;
        }

        .card-body {
            padding: 1.5rem;
        }

        .btn {
            font-size: 0.875rem;
            font-weight: 500;
            border-radius: var(--radius);
            padding: 0.5rem 1rem;
            transition: all 0.15s ease;
        }

        .btn-primary {
            background-color: var(--color-accent) !important;
            border-color: var(--color-accent) !important;
        }

        .btn-primary:hover {
            background-color: var(--color-accent-hover) !important;
            border-color: var(--color-accent-hover) !important;
        }

        .btn-success {
            background-color: var(--color-success) !important;
            border-color: var(--color-success) !important;
        }

        .btn-danger {
            background-color: var(--color-danger) !important;
            border-color: var(--color-danger) !important;
        }

        .btn-secondary {
            background-color: transparent !important;
            border: 1px solid var(--color-border) !important;
            color: var(--color-secondary) !important;
        }

        .btn-secondary:hover {
            background-color: var(--color-bg) !important;
            color: var(--color-primary) !important;
        }

        .form-control,
        .form-select {
            border: 1px solid var(--color-border);
            border-radius: var(--radius);
            font-size: 0.875rem;
            padding: 0.625rem 0.875rem;
            transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }

        .form-control:focus,
        .form-select:focus {
            border-color: var(--color-accent);
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
        }

        .form-label {
            font-size: 0.8125rem;
            font-weight: 600;
            color: var(--color-primary);
            margin-bottom: 0.375rem;
        }

        .table {
            font-size: 0.875rem;
        }

        .table thead th {
            font-weight: 600;
            font-size: 0.75rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--color-secondary);
            border-bottom: 1px solid var(--color-border);
            padding: 0.75rem 1rem;
        }

        .table tbody td {
            padding: 0.875rem 1rem;
            vertical-align: middle;
            border-bottom: 1px solid var(--color-border);
        }

        .table tbody tr:last-child td {
            border-bottom: none;
        }

        .badge-status {
            display: inline-block;
            font-size: 0.75rem;
            font-weight: 500;
            padding: 0.25rem 0.625rem;
            border-radius: 9999px;
        }

        .badge-draft {
            background-color: #fef3c7;
            color: var(--color-warning);
        }

        .badge-publish {
            background-color: #d1fae5;
            color: var(--color-success);
        }

        .alert {
            font-size: 0.875rem;
            border-radius: var(--radius);
            border: none;
            padding: 0.875rem 1.25rem;
        }

        .alert-success {
            background-color: #ecfdf5;
            color: var(--color-success);
        }

        .page-header {
            margin-bottom: 1.5rem;
        }

        .page-header h1 {
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--color-primary);
            margin: 0;
            letter-spacing: -0.025em;
        }

        .page-header p {
            font-size: 0.875rem;
            color: var(--color-secondary);
            margin: 0.25rem 0 0;
        }
    </style>
    @livewireStyles
</head>

<body>
    <nav class="navbar">
        <div class="container">
            <div class="d-flex align-items-center justify-content-between w-100">
                <a class="navbar-brand" href="/">⚡ Livewire 4 CRUD</a>
                <ul class="nav">
                    <li class="nav-item">
                        <a class="nav-link {{ request()->is('/') ? 'active' : '' }}" href="/" wire:navigate>Posts</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->is('create') ? 'active' : '' }}" href="/create" wire:navigate>New Post</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <main class="main-content">
        <div class="container">
            {{ $slot }}
        </div>
    </main>

    <footer class="site-footer">
        <div class="container text-center">
            <p>CRUD with Laravel & Livewire 4 - A Tutorial Demo Project from <a href="https://qadrlabs.com" target="_blank" rel="noopener">qadrlabs.com</a></p>
        </div>
    </footer>

    @livewireScripts
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js"
        integrity="sha384-FKyoEForCGlyvwx9Hj09JcYn3nv7wiPVlz7YYwJrWVcXK/BmnVDxM+D2scQbITxI" crossorigin="anonymous">
    </script>
</body>

</html>
```

There are several important things happening in this layout:

- **`@livewireStyles` and `@livewireScripts`**: These Blade directives inject the CSS and JavaScript that Livewire needs to function. Without them, your components will not be reactive.
- **`{{ $slot }}`**: This is where each Livewire full-page component's content will be rendered. It works just like a standard Blade layout slot.
- **`wire:navigate`**: This attribute on the navigation links enables Livewire's SPA-like navigation. Instead of triggering a full page reload, Livewire intercepts the click and swaps the page content seamlessly, resulting in a much faster user experience.
- **`{{ $title ?? 'CRUD Livewire 4' }}`**: Livewire 4 allows components to set a page title via the `->title()` method, which is then passed to the layout through this variable.

Save the file.


## Step 5: Create View Post List Feature {#step-5-create-view-post-list-feature}

Now we get to the heart of Livewire 4: creating our first Single-File Component. Run the following Artisan command:

```bash
php artisan make:livewire pages::posts.index
```

Output:

```
INFO  Livewire component [resources/views/pages/posts/⚡index.blade.php] created successfully.
```

Notice the ⚡ (lightning bolt) in the filename. This is a Livewire 4 convention for Single-File Components. It is a valid Unicode character that helps these files stand out in your file explorer and sort to the top of directory listings.

### Build the Component

Open `resources/views/pages/posts/⚡index.blade.php` and replace its contents with:

```php
<?php

use App\Models\Post;
use Livewire\Component;
use Livewire\WithPagination;

new class extends Component
{
    use WithPagination;

    public function render()
    {
        return $this->view([
            'posts' => Post::latest()->paginate(10),
        ])
            ->layout('layouts::app')
            ->title('Posts List');
    }
};
?>

<div>
    @if(session()->has('message'))
    <div class="alert alert-success d-flex align-items-center" role="alert">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16" class="me-2 flex-shrink-0">
            <path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0m-3.97-3.03a.75.75 0 0 0-1.08.022L7.477 9.417 5.384 7.323a.75.75 0 0 0-1.06 1.06L6.97 11.03a.75.75 0 0 0 1.079-.02l3.992-4.99a.75.75 0 0 0-.01-1.05z"/>
        </svg>
        {{ session('message') }}
    </div>
    @endif

    <div class="page-header d-flex align-items-center justify-content-between">
        <div>
            <h1>Posts</h1>
            <p>Manage and organize your content</p>
        </div>
        <a href="/create" wire:navigate class="btn btn-primary">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16" class="me-1">
                <path d="M8 4a.5.5 0 0 1 .5.5v3h3a.5.5 0 0 1 0 1h-3v3a.5.5 0 0 1-1 0v-3h-3a.5.5 0 0 1 0-1h3v-3A.5.5 0 0 1 8 4"/>
            </svg>
            New Post
        </a>
    </div>

    <div class="card">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-borderless mb-0">
                    <thead>
                        <tr>
                            <th>Title</th>
                            <th>Content</th>
                            <th>Status</th>
                            <th class="text-end">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse ($posts as $post)
                        <tr>
                            <td>
                                <span class="fw-medium">{{ $post->title }}</span>
                            </td>
                            <td>
                                <span class="text-secondary">{{ Str::limit($post->content, 50) }}</span>
                            </td>
                            <td>
                                @if($post->status == 1)
                                    <span class="badge-status badge-draft">Draft</span>
                                @else
                                    <span class="badge-status badge-publish">Published</span>
                                @endif
                            </td>
                            <td class="text-end">
                                <a href="/edit/{{ $post->id }}" wire:navigate class="btn btn-sm btn-secondary me-1">
                                    Edit
                                </a>
                                <button class="btn btn-sm btn-danger"
                                    onclick="confirm('Are you sure you want to delete this post?') || event.stopImmediatePropagation()"
                                    wire:click="delete({{ $post->id }})">
                                    Delete
                                </button>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="4" class="text-center py-5">
                                <div class="text-secondary">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" fill="currentColor" viewBox="0 0 16 16" class="mb-2 opacity-50">
                                        <path d="M4 0h5.293A1 1 0 0 1 10 .293L13.707 4a1 1 0 0 1 .293.707V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2m5.5 1.5v2a1 1 0 0 0 1 1h2z"/>
                                    </svg>
                                    <p class="mb-0 mt-1">No posts found</p>
                                    <a href="/create" wire:navigate class="btn btn-sm btn-primary mt-3">Create your first post</a>
                                </div>
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    {{ $posts->links() }}
</div>
```

Let's break down the key concepts in this component:

**The PHP Section**: At the top of the file, the `<?php ... ?>` block contains the component's logic as an anonymous class that extends `Livewire\Component`. This is the Single-File Component pattern in Livewire 4. The `WithPagination` trait adds automatic pagination support.

**`$this->view()`**: In the `render()` method, we pass data to the template using `$this->view([...])`. The array keys become available as variables in the Blade template below. Here, `Post::latest()->paginate(10)` fetches the 10 most recent posts with pagination.

**`->layout()` and `->title()`**: These chain methods tell Livewire which layout to wrap this component in and what page title to set. The `layouts::app` syntax uses the double-colon notation introduced in Livewire 4 for referencing views in subdirectories.

**`@forelse ... @empty`**: This Blade directive handles both cases: when posts exist and when the table is empty. The `@empty` block shows a friendly placeholder encouraging the user to create their first post.

**`wire:click="delete({{ $post->id }})"`**: This binds the button click to a `delete` method on the component (which we will add in Step 8), passing the post's ID as an argument. The `onclick` handler with `confirm()` provides a browser-native confirmation dialog before the deletion proceeds.

### Register the Route

Open `routes/web.php` and replace its contents with:

```php
<?php

use Illuminate\Support\Facades\Route;

Route::livewire('/', 'pages::posts.index')->name('posts.index');
```

The `Route::livewire()` method is new in Livewire 4 and is the preferred way to register full-page Livewire components as routes. It replaces the older pattern of using a regular `Route::get()` with a component class reference. The `pages::posts.index` string tells Livewire to look for the component at `resources/views/pages/posts/⚡index.blade.php`.

Save the file.


## Step 6: Create Add New Post Feature {#step-6-create-add-new-post-feature}

Next, let's create the component that handles creating new posts:

```bash
php artisan make:livewire pages::posts.create
```

Output:

```
INFO  Livewire component [resources/views/pages/posts/⚡create.blade.php] created successfully.
```

Open `resources/views/pages/posts/⚡create.blade.php` and replace its contents with:

```php
<?php

use App\Models\Post;
use Livewire\Component;
use Livewire\Attributes\Validate;

new class extends Component
{
    #[Validate('required')]
    public $title;

    #[Validate('required')]
    public $content;

    #[Validate('required')]
    public $status;

    public function store()
    {
        $this->validate();

        Post::create([
            'title'   => $this->title,
            'content' => $this->content,
            'status'  => $this->status,
            'slug'    => \Str::slug($this->title),
        ]);

        session()->flash('message', 'Post created successfully.');

        return redirect()->route('posts.index');
    }

    public function render()
    {
        return $this->view()
            ->layout('layouts::app')
            ->title('Create Post');
    }
};
?>

<div>
    <div class="page-header">
        <h1>Create Post</h1>
        <p>Add a new post to your collection</p>
    </div>

    <div class="card">
        <div class="card-body">
            <form>
                <div class="mb-4">
                    <label for="title" class="form-label">Title</label>
                    <input type="text" class="form-control @error('title') is-invalid @enderror" id="title"
                        placeholder="Enter post title" wire:model="title">
                    @error('title')
                    <small class="text-danger mt-1 d-block">{{ $message }}</small>
                    @enderror
                </div>

                <div class="mb-4">
                    <label for="content" class="form-label">Content</label>
                    <textarea class="form-control @error('content') is-invalid @enderror" id="content"
                        wire:model="content" placeholder="Write your content here..." rows="5"></textarea>
                    @error('content')
                    <small class="text-danger mt-1 d-block">{{ $message }}</small>
                    @enderror
                </div>

                <div class="mb-4">
                    <label for="status" class="form-label">Status</label>
                    <select id="status" class="form-select @error('status') is-invalid @enderror" wire:model="status">
                        <option value="">Select status</option>
                        <option value="1">Draft</option>
                        <option value="2">Publish</option>
                    </select>
                    @error('status')
                    <small class="text-danger mt-1 d-block">{{ $message }}</small>
                    @enderror
                </div>

                <div class="d-flex align-items-center gap-2 pt-2">
                    <button wire:click.prevent="store()" class="btn btn-primary">
                        Save Post
                    </button>
                    <a href="/" wire:navigate class="btn btn-secondary">Cancel</a>
                </div>
            </form>
        </div>
    </div>
</div>
```

Here is what is new in this component:

**`#[Validate('required')]`**: Livewire 4 uses PHP 8 Attributes for validation rules. Each public property is decorated with a `#[Validate]` attribute that specifies its validation constraints. This is much cleaner than defining a separate `$rules` array.

**`wire:model`**: This directive creates a two-way binding between the form input and the corresponding PHP property. When the user types into the title input, `$this->title` is automatically updated on the server. In Livewire 4, `wire:model` syncs on the `change` event by default (when the input loses focus). If you want real-time syncing as the user types, use `wire:model.live`.

**`$this->validate()`**: When the `store()` method is called, this line triggers validation against the rules defined in the `#[Validate]` attributes. If validation fails, Livewire automatically returns errors to the view without proceeding further.

**`wire:click.prevent="store()"`**: The `.prevent` modifier calls `event.preventDefault()`, stopping the form from submitting traditionally. Instead, it triggers the `store()` method on the Livewire component via an AJAX request.

**`session()->flash()`**: After saving the post, we flash a success message to the session. This message will be displayed on the index page after the redirect, thanks to the flash message block we built in Step 5.

### Register the Route

Open `routes/web.php` and add the create route:

```php
Route::livewire('/create', 'pages::posts.create')->name('posts.create');
```

Save the file.


## Step 7: Create Edit Existing Post Feature {#step-7-create-edit-existing-post-feature}

The edit feature is similar to create, but it needs to load existing data first. Generate the component:

```bash
php artisan make:livewire pages::posts.edit
```

Open `resources/views/pages/posts/⚡edit.blade.php` and replace its contents:

```php
<?php

use App\Models\Post;
use Livewire\Component;
use Livewire\Attributes\Validate;

new class extends Component
{
    #[Validate('required')]
    public $title;

    #[Validate('required')]
    public $content;

    #[Validate('required')]
    public $status;

    public $postId;

    public function mount($id)
    {
        $post = Post::findOrFail($id);

        $this->postId  = $post->id;
        $this->title   = $post->title;
        $this->content = $post->content;
        $this->status  = $post->status;
    }

    public function update()
    {
        $this->validate();

        $post = Post::findOrFail($this->postId);

        $post->update([
            'title'   => $this->title,
            'content' => $this->content,
            'status'  => $this->status,
            'slug'    => \Str::slug($this->title),
        ]);

        session()->flash('message', 'Post updated successfully.');

        return redirect()->route('posts.index');
    }

    public function render()
    {
        return $this->view()
            ->layout('layouts::app')
            ->title('Edit Post');
    }
};
?>

<div>
    <div class="page-header">
        <h1>Edit Post</h1>
        <p>Update the details of your post</p>
    </div>

    <div class="card">
        <div class="card-body">
            <form>
                <div class="mb-4">
                    <label for="title" class="form-label">Title</label>
                    <input type="text" class="form-control @error('title') is-invalid @enderror" id="title"
                        placeholder="Enter post title" wire:model="title">
                    @error('title')
                    <small class="text-danger mt-1 d-block">{{ $message }}</small>
                    @enderror
                </div>

                <div class="mb-4">
                    <label for="content" class="form-label">Content</label>
                    <textarea class="form-control @error('content') is-invalid @enderror" id="content"
                        wire:model="content" placeholder="Write your content here..." rows="5"></textarea>
                    @error('content')
                    <small class="text-danger mt-1 d-block">{{ $message }}</small>
                    @enderror
                </div>

                <div class="mb-4">
                    <label for="status" class="form-label">Status</label>
                    <select id="status" class="form-select @error('status') is-invalid @enderror" wire:model="status">
                        <option value="">Select status</option>
                        <option value="1">Draft</option>
                        <option value="2">Publish</option>
                    </select>
                    @error('status')
                    <small class="text-danger mt-1 d-block">{{ $message }}</small>
                    @enderror
                </div>

                <div class="d-flex align-items-center gap-2 pt-2">
                    <button wire:click.prevent="update()" class="btn btn-primary">
                        Update Post
                    </button>
                    <a href="/" wire:navigate class="btn btn-secondary">Cancel</a>
                </div>
            </form>
        </div>
    </div>
</div>
```

The key difference from the create component is the `mount()` method:

**`mount($id)`**: This is a Livewire lifecycle hook that runs once when the component is first loaded. It receives the `$id` parameter from the route (e.g., `/edit/5` passes `5` as `$id`). We use `Post::findOrFail($id)` to retrieve the post. If the post does not exist, Laravel automatically returns a 404 error. Once the post is found, we populate the component's public properties with the existing values, so the form fields are pre-filled when the page loads.

**`$this->postId`**: We store the post's ID separately because we need it later in the `update()` method. Since this property does not have a `#[Validate]` attribute, it will not be affected by validation.

### Register the Route

Add the edit route to `routes/web.php`:

```php
Route::livewire('/edit/{id}', 'pages::posts.edit')->name('posts.edit');
```

The `{id}` segment is a route parameter that gets passed to the component's `mount()` method.

Save the file.


## Step 8: Create Delete Existing Post Feature {#step-8-create-delete-existing-post-feature}

For the delete feature, we do not need a separate component. We will add a `delete()` method directly to our index component. This makes sense because the delete button already lives in the posts list table.

Open `resources/views/pages/posts/⚡index.blade.php` and add the `delete()` method to the anonymous class, right before the `render()` method:

```php
public function delete($id)
{
    $post = Post::findOrFail($id);

    $post->delete();

    session()->flash('message', 'Post deleted successfully.');
}
```

The complete PHP section of the index component should now look like this:

```php
<?php

use App\Models\Post;
use Livewire\Component;
use Livewire\WithPagination;

new class extends Component
{
    use WithPagination;

    public function delete($id)
    {
        $post = Post::findOrFail($id);

        $post->delete();

        session()->flash('message', 'Post deleted successfully.');
    }

    public function render()
    {
        return $this->view([
            'posts' => Post::latest()->paginate(10),
        ])
            ->layout('layouts::app')
            ->title('Posts List');
    }
};
?>
```

When the user clicks the Delete button, the `wire:click="delete({{ $post->id }})"` directive sends an AJAX request to the server, which calls this method. After deleting, `session()->flash()` sets a success message. Since Livewire re-renders the component after the method call, the deleted post disappears from the table and the flash message appears at the top, all without a full page reload.

Save the file.

### Complete Routes File

Here is the final `routes/web.php` with all three routes:

```php
<?php

use Illuminate\Support\Facades\Route;

Route::livewire('/', 'pages::posts.index')->name('posts.index');
Route::livewire('/create', 'pages::posts.create')->name('posts.create');
Route::livewire('/edit/{id}', 'pages::posts.edit')->name('posts.edit');
```

Notice how clean the routes file is. Three lines for three pages. No controller imports needed because the logic lives inside the Livewire components themselves.


## Step 9: Try It Out {#step-9-try-it-out}

Everything is in place. Start the Laravel development server:

```bash
php artisan serve
```

Open your browser and navigate to `http://127.0.0.1:8000/`. You should see the posts index page with an empty state message and a "Create your first post" button.

### Test Creating a Post

Click **New Post** in the navigation bar or the "Create your first post" button. Fill in the title, content, and select a status. Click **Save Post**. You should be redirected to the index page with a green success message, and your new post should appear in the table. Notice that the page transition feels instant thanks to `wire:navigate`.

### Test Validation

Try submitting the create form with empty fields. You should see validation error messages appear below each field without a page reload. This is Livewire handling the validation server-side and updating the view reactively.

### Test Editing a Post

Click the **Edit** button on any post. The form should be pre-filled with the existing data. Change the title or content and click **Update Post**. You should be redirected back to the index page with a success message and the updated data reflected in the table.

### Test Deleting a Post

Click the **Delete** button on any post. A browser confirmation dialog should appear asking "Are you sure you want to delete this post?" Click OK. The post should disappear from the table and a success message should appear, all without a full page reload. This is Livewire at work: the `wire:click` sends the delete request, the component re-renders, and the DOM is updated.


## Livewire 3 vs Livewire 4: What Changed {#livewire-3-vs-4}

If you followed our [previous tutorial](https://qadrlabs.com/post/belajar-laravel-10-crud-with-laravel-livewire) using Laravel 10 and Livewire 3, here are the key differences:

| Aspect | Livewire 3 (Previous Tutorial) | Livewire 4 (This Tutorial) |
|--------|-------------------------------|---------------------------|
| Component structure | Separate class (`app/Livewire/Post.php`) + view (`resources/views/livewire/post.blade.php`) | Single-File Component (`resources/views/pages/posts/⚡index.blade.php`) |
| File count for CRUD | 1 class + 3 views (post, create, update) | 3 Single-File Components (index, create, edit) |
| UI switching | Toggle flags (`$addPost`, `$updatePost`) on one component | Separate page per action with `wire:navigate` |
| Validation | `protected $rules = [...]` array | `#[Validate('required')]` PHP attributes |
| Routing | `Route::get('/', fn() => view('home'))` with `@livewire('post')` | `Route::livewire('/', 'pages::posts.index')` |
| Component generation | `php artisan make:livewire post` (creates class + view) | `php artisan make:livewire pages::posts.index` (creates `⚡` file) |
| Data passing | `return view('livewire.post', compact('posts'))` | `return $this->view(['posts' => ...])` |
| Layout | Separate `home.blade.php` with `@livewire('post')` directive | `->layout('layouts::app')` chain on render |
| Page title | Set in parent Blade file | `->title('Posts List')` on component |
| Navigation | All operations on one page (no navigation) | SPA-like page transitions with `wire:navigate` |
| Form display | `@include('livewire.create')` toggled by flag | Dedicated page component at `/create` |

The biggest architectural change is moving from a single-component-does-everything approach to a multi-component-per-page approach. In Livewire 3, we managed all CRUD operations in one component with boolean flags to show/hide forms. In Livewire 4, each page gets its own Single-File Component, and `wire:navigate` provides seamless transitions between them.


## Livewire 4 vs Blade: Key Differences {#livewire-vs-blade}

If you have followed our [Blade CRUD tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step), here is how the Livewire approach compares:

| Aspect | Blade | Livewire 4 |
|--------|-------|------------|
| Architecture | Controller + Blade view (separate files) | Single-File Component (PHP + Blade in one file) |
| Routing | `Route::resource()` with controller | `Route::livewire()` with component path |
| Form submission | HTML form POST with `@csrf` | `wire:click` triggers PHP method via AJAX |
| Validation errors | Redirect back with errors | Errors appear inline without page reload |
| Navigation | Full page reload on every click | SPA-like transitions with `wire:navigate` |
| Delete confirmation | Form with `onclick="return confirm()"` | `wire:click` with inline confirm |
| Data binding | Manual `value="{{ old() }}"` | Automatic `wire:model` two-way binding |
| JavaScript needed | Sometimes (for dynamic behavior) | Rarely (Livewire handles reactivity) |
| Build step | None | None |
| Page title | Set in Blade `<title>` tag | `->title()` method on component |

The biggest practical difference is that Livewire eliminates the controller layer entirely. In the Blade approach, you have `PostController` with seven methods, plus seven Blade view files. In the Livewire approach, you have three Single-File Components that contain both the logic and the template. Each component is self-contained.


## Conclusion {#conclusion}

In this tutorial, we built a complete CRUD application using Laravel 13 and Livewire 4. We created three Single-File Components for listing, creating, and editing posts, added inline delete functionality, and configured Bootstrap-styled pagination.

Here are the key takeaways:

- **Single-File Components keep logic and template together.** The `⚡` file convention puts your PHP class and Blade template in the same file. No need to switch between a controller and a view.
- **`Route::livewire()` simplifies routing.** One line registers a full-page component as a route. No controller imports, no middleware chain (unless you need one).
- **`#[Validate]` attributes make validation declarative.** Instead of a `$rules` array, each property gets its validation rule as a PHP attribute. Validation errors appear inline without a page reload.
- **`wire:model` handles two-way data binding automatically.** Form inputs sync with server-side properties. No manual `value="{{ old() }}"` needed.
- **`wire:navigate` provides SPA-like navigation.** Page transitions feel instant because Livewire swaps content via AJAX instead of triggering full reloads.
- **`wire:click` eliminates JavaScript for actions.** Delete confirmations, form submissions, and other interactions are handled entirely in PHP. The `confirm()` in the `onclick` handler is the only JavaScript in the entire application.
- **No build step required.** Unlike Inertia.js + Vue, Livewire works with plain Blade templates and requires no Node.js, NPM, or Vite configuration.
- **The delete method lives in the index component.** Since the delete button is rendered in the post list, the `delete()` method belongs in the same component. No separate controller method or component needed.
- **Livewire 4 is a significant upgrade from Livewire 3.** If you are migrating from our [previous tutorial](https://qadrlabs.com/post/belajar-laravel-10-crud-with-laravel-livewire), the biggest change is moving from one component with toggle flags to multiple Single-File Components with page-based routing. The code is more organized, but the mental model is different.


## Reference {#reference}

- [Previous Tutorial: CRUD with Laravel 10 and Livewire 3](https://qadrlabs.com/post/belajar-laravel-10-crud-with-laravel-livewire)
- [Livewire 4 Installation Guide](https://livewire.laravel.com/docs/4.x/installation)
- [Livewire 4 Upgrade Guide](https://livewire.laravel.com/docs/4.x/upgrading)
- [Laravel 13 Documentation](https://laravel.com/docs/13.x)