---
title: "Build a Blog with Laravel 13 + Inertia.js + Vue 3"
slug: "build-a-blog-with-laravel-13-inertiajs-vue-3"
category: "Laravel"
date: "2026-03-27"
status: "published"
---

In our [CRUD tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step), we built a blog using Blade templates. Blade works great for server-rendered pages, but if you want a more interactive, app-like experience without building a separate SPA and API, Inertia.js gives you the best of both worlds.

Inertia.js lets you build modern single-page applications using Vue (or React or Svelte) on the frontend while keeping your existing Laravel controllers, routes, and authentication on the backend. No API layer needed. No client-side routing. You write Laravel controllers that return Inertia responses instead of Blade views, and Vue components render the pages.

In this tutorial, we will build the same blog CRUD application from scratch using Laravel 13, Inertia.js, and Vue 3. At the end, we will compare the Inertia approach with the Blade approach to help you decide which one fits your next project.

> **Note:** This tutorial has not been fully tested end-to-end. The code is based on the official Laravel 13, Inertia.js, and Vue 3 documentation. If you encounter issues, please refer to the [Inertia.js docs](https://inertiajs.com) and the [Vue 3 docs](https://vuejs.org).


## How Inertia.js Works {#how-inertia-works}

Inertia sits between your Laravel backend and your Vue frontend. Here is the flow:

1. A user visits a URL (e.g., `/posts`).
2. Laravel's router calls a controller method, just like with Blade.
3. Instead of returning a Blade view, the controller returns an Inertia response: `Inertia::render('Posts/Index', ['posts' => $posts])`.
4. On the first visit, the server returns a full HTML page that boots the Vue app.
5. On subsequent navigations, Inertia intercepts the link click, makes an XHR request to the server, and swaps the Vue component on the page without a full reload.

The result feels like a SPA (no page reloads, smooth transitions) but uses server-side routing and controllers (no client-side router, no API endpoints).


## Overview {#overview}

We will build a blog with the same features as the Blade tutorial: listing, creating, viewing, editing, and deleting posts.

### What You'll Build

- A post listing page with pagination (Vue component).
- A create post form with validation error display.
- A view post detail page.
- An edit post form with pre-filled data.
- A delete function with confirmation.
- Flash message notifications.

### What You'll Learn

- How to set up a Laravel 13 project with Inertia.js and Vue 3.
- How to create Vue page components that replace Blade views.
- How to pass data from controllers to Vue components via Inertia.
- How to handle form submissions with `useForm()`.
- How to display validation errors from Laravel in Vue.
- How to handle flash messages across page visits.
- How Inertia compares to Blade for CRUD applications.

### What You'll Need

- PHP 8.3 or higher.
- Composer installed globally.
- Node.js 18+ and NPM.
- MySQL or another supported database.
- Basic familiarity with Laravel and Vue.js.


## Step 1: Create the Project with Vue Starter Kit {#step-1-create-project}

Open terminal, then create a new project:

```
composer create-project laravel/laravel --prefer-dist inertia-blog
```
Wait until the project creation process is complete. Next, we’ll navigate to the project directory using the following command.
```
cd inertia-blog
```
Next, we’ll install the server-side Inertia adapter:

```
composer require inertiajs/inertia-laravel
```

Then we'll install the client-side dependencies:

```
npm install @inertiajs/vue3 vue
```

After that, we install the Vite plugin for Vue:

```
npm install -D @vitejs/plugin-vue
```

### Set Up the Root Template

Create or update `resources/views/app.blade.php`. This is the only Blade file you need. It serves as the shell that boots the Vue application:

```html
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ config('app.name', 'Laravel') }}</title>
    @vite(['resources/js/app.js', 'resources/css/app.css'])
    @inertiaHead
</head>
<body>
    @inertia
</body>
</html>
```

`@inertia` renders the root `<div>` where Vue mounts. `@inertiaHead` manages the `<title>` and meta tags from Vue components. `@vite` loads the JavaScript and CSS assets.

### Set Up the Inertia Middleware

Publish the Inertia middleware:

```
php artisan inertia:middleware
```
Output:
```
$ php artisan inertia:middleware

   INFO  Middleware [app/Http/Middleware/HandleInertiaRequests.php] created successfully.  

```

Then register it in `bootstrap/app.php` inside the `withMiddleware` callback:

```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->web(append: [
        \App\Http\Middleware\HandleInertiaRequests::class,
    ]);
})
```

### Configure Vite

Open `vite.config.js` and add the Vue plugin:

```js
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import vue from '@vitejs/plugin-vue';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
        vue({
            template: {
                transformAssetUrls: {
                    base: null,
                    includeAbsolute: false,
                },
            },
        }),
        tailwindcss(),
    ],
});
```

### Set Up the Vue App

Open `resources/js/app.js` and configure the Inertia Vue app:

```js
import { createApp, h } from 'vue';
import { createInertiaApp } from '@inertiajs/vue3';
import { resolvePageComponent } from 'laravel-vite-plugin/inertia-helpers';

createInertiaApp({
    title: (title) => title ? `${title} - Blog` : 'Blog',
    resolve: (name) => resolvePageComponent(`./Pages/${name}.vue`, import.meta.glob('./Pages/**/*.vue')),
    setup({ el, App, props, plugin }) {
        return createApp({ render: () => h(App, props) })
            .use(plugin)
            .mount(el);
    },
});
```

`resolvePageComponent` automatically loads Vue components from `resources/js/Pages/`. When the controller returns `Inertia::render('Posts/Index', ...)`, it resolves to `resources/js/Pages/Posts/Index.vue`.

### Install Tailwind CSS

```
npm install -D tailwindcss @tailwindcss/vite
```

Update `resources/css/app.css`:

```css
@import "tailwindcss";
```

Now install all dependencies and verify the build works:

```
npm install
npm run build
```


## Step 2: Set Up the Database and Model {#step-2-database-and-model}

Configure `.env`:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_inertia_blog
DB_USERNAME=root
DB_PASSWORD=password
```

Create the Post model and migration:

```
php artisan make:model Post -m
```

Open the migration:

```php
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
```

Configure the model (`app/Models/Post.php`):

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

Run the migration:

```
php artisan migrate
```


## Step 3: Create the Controller {#step-3-create-controller}

```
php artisan make:controller PostController --model=Post --resource
```

Open `app/Http/Controllers/PostController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Post;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Inertia\Inertia;

class PostController extends Controller
{
    public function index()
    {
        $posts = Post::latest()->paginate(10);

        return Inertia::render('Posts/Index', [
            'posts' => $posts,
        ]);
    }

    public function create()
    {
        return Inertia::render('Posts/Create');
    }

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

    public function show(Post $post)
    {
        return Inertia::render('Posts/Show', [
            'post' => $post,
        ]);
    }

    public function edit(Post $post)
    {
        return Inertia::render('Posts/Edit', [
            'post' => $post,
        ]);
    }

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

    public function destroy(Post $post)
    {
        $post->delete();

        return redirect()->route('posts.index')->with('success', 'Post deleted successfully.');
    }
}
```

Compare this to the Blade controller from the CRUD tutorial. The structure is almost identical. The only difference is the return statement: `Inertia::render('Posts/Index', [...])` instead of `view('posts.index', compact(...))`. The first argument is the Vue component path (relative to `resources/js/Pages/`), and the second argument is the data passed as props.

Redirects and flash messages work exactly the same way. `redirect()->route(...)->with('success', ...)` sends a flash message that Inertia makes available to the Vue component.

Register the routes in `routes/web.php`:

```php
<?php

use App\Http\Controllers\PostController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('posts.index');
});

Route::resource('posts', PostController::class);
```

Save the files.


## Step 4: Create Vue Page Components {#step-4-create-vue-components}

Create the directory structure:

```bash
mkdir -p resources/js/Pages/Posts
```

### Shared Layout

Create `resources/js/Layouts/AppLayout.vue`:

```js
<script setup>
import { Link, usePage } from '@inertiajs/vue3';
import { computed } from 'vue';

const flash = computed(() => usePage().props.flash);
</script>

<template>
    <div class="min-h-screen bg-gray-100">
        <nav class="bg-white shadow-sm border-b border-gray-200">
            <div class="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
                <Link href="/posts" class="text-xl font-bold text-gray-900">Blog</Link>
            </div>
        </nav>

        <main class="max-w-7xl mx-auto py-8 px-4">
            <div v-if="flash?.success" class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
                {{ flash.success }}
            </div>

            <slot />
        </main>
    </div>
</template>
```

The `usePage()` composable gives access to shared Inertia props, including flash messages. The `<Link>` component from Inertia replaces standard `<a>` tags to enable client-side navigation without full page reloads.

### Share Flash Data

To make flash messages available in Vue, open `app/Http/Middleware/HandleInertiaRequests.php` and update the `share()` method:

```php
public function share(Request $request): array
{
    return [
        ...parent::share($request),
        'flash' => [
            'success' => fn () => $request->session()->get('success'),
        ],
    ];
}
```

### Index Page

Create `resources/js/Pages/Posts/Index.vue`:

```js
<script setup>
import { Link, router } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    posts: Object,
});

function destroy(id) {
    if (confirm('Are you sure you want to delete this post?')) {
        router.delete(`/posts/${id}`);
    }
}
</script>

<template>
    <AppLayout>
        <div class="bg-white p-6 md:p-8 rounded-lg shadow-md">
            <div class="flex justify-between items-center mb-6">
                <h1 class="text-3xl font-bold text-gray-900">Manage Posts</h1>
                <Link href="/posts/create" class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-md transition duration-200 shadow-sm">
                    Create New Post
                </Link>
            </div>

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
                        <tr v-for="(post, index) in posts.data" :key="post.id" class="hover:bg-gray-50 transition duration-150">
                            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center">{{ posts.from + index }}</td>
                            <td class="px-6 py-4 text-sm font-medium text-gray-900">{{ post.title }}</td>
                            <td class="px-6 py-4 text-sm text-gray-500">{{ post.slug }}</td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm">
                                <span :class="post.status === 'publish' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
                                    class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full">
                                    {{ post.status.charAt(0).toUpperCase() + post.status.slice(1) }}
                                </span>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                                <Link :href="`/posts/${post.id}`" class="inline-flex items-center px-3 py-1.5 bg-blue-600 rounded-md text-xs text-white uppercase hover:bg-blue-700 transition shadow-sm">View</Link>
                                <Link :href="`/posts/${post.id}/edit`" class="inline-flex items-center px-3 py-1.5 bg-amber-500 rounded-md text-xs text-white uppercase hover:bg-amber-600 transition shadow-sm">Edit</Link>
                                <button @click="destroy(post.id)" class="inline-flex items-center px-3 py-1.5 bg-red-600 rounded-md text-xs text-white uppercase hover:bg-red-700 transition shadow-sm">Delete</button>
                            </td>
                        </tr>
                        <tr v-if="posts.data.length === 0">
                            <td colspan="5" class="px-6 py-4 text-center text-sm text-gray-500">No posts found.</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <div v-if="posts.links.length > 3" class="mt-6 flex justify-center space-x-1">
                <template v-for="link in posts.links" :key="link.label">
                    <Link v-if="link.url" :href="link.url"
                        class="px-3 py-1 rounded text-sm"
                        :class="link.active ? 'bg-blue-600 text-white' : 'bg-white text-gray-700 hover:bg-gray-100 border border-gray-300'"
                        v-html="link.label" />
                    <span v-else class="px-3 py-1 rounded text-sm text-gray-400" v-html="link.label" />
                </template>
            </div>
        </div>
    </AppLayout>
</template>
```

Notice the differences from the Blade version:

- `v-for` replaces `@forelse`. Vue's template syntax handles iteration.
- `posts.data` is used because Laravel's paginator wraps the results in a `data` key when serialized to JSON.
- `posts.from + index` calculates the row number correctly across pages (same logic as `$posts->firstItem() + $loop->index` in Blade).
- `router.delete()` sends a DELETE request via Inertia instead of a form with `@method('DELETE')`.
- `<Link>` replaces `<a>` for client-side navigation.

### Create Page

Create `resources/js/Pages/Posts/Create.vue`:

```js
<script setup>
import { useForm, Link } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

const form = useForm({
    title: '',
    content: '',
    status: 'draft',
});

function submit() {
    form.post('/posts');
}
</script>

<template>
    <AppLayout>
        <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
            <div class="flex justify-between items-center mb-6">
                <h1 class="text-2xl font-bold text-gray-900">Create Post</h1>
                <Link href="/posts" class="text-gray-600 hover:text-gray-900 underline text-sm transition">Back to Manage Posts</Link>
            </div>

            <form @submit.prevent="submit" class="space-y-6">
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                    <input v-model="form.title" type="text" required
                        class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
                    <p v-if="form.errors.title" class="text-red-500 text-sm mt-1">{{ form.errors.title }}</p>
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Content</label>
                    <textarea v-model="form.content" rows="8" required
                        class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition resize-y"></textarea>
                    <p v-if="form.errors.content" class="text-red-500 text-sm mt-1">{{ form.errors.content }}</p>
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                    <select v-model="form.status" required
                        class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition">
                        <option value="draft">Draft</option>
                        <option value="publish">Publish</option>
                    </select>
                    <p v-if="form.errors.status" class="text-red-500 text-sm mt-1">{{ form.errors.status }}</p>
                </div>

                <div class="pt-2 flex justify-end">
                    <button type="submit" :disabled="form.processing"
                        class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-6 rounded-md transition duration-200 shadow-sm disabled:opacity-50">
                        {{ form.processing ? 'Saving...' : 'Submit Post' }}
                    </button>
                </div>
            </form>
        </div>
    </AppLayout>
</template>
```

`useForm()` is the key Inertia composable for form handling. It provides reactive form data, automatic error handling (`form.errors.title`), processing state (`form.processing`), and submission methods (`form.post()`, `form.put()`, `form.delete()`).

When `form.post('/posts')` is called, Inertia sends a POST request. If Laravel validation fails, the errors are automatically populated in `form.errors`. If validation passes, the controller redirects and Inertia follows the redirect, swapping the page component.

The `@submit.prevent` prevents the default form submission since Inertia handles it via XHR.

### Show Page

Create `resources/js/Pages/Posts/Show.vue`:

```js
<script setup>
import { Link } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    post: Object,
});
</script>

<template>
    <AppLayout>
        <div class="max-w-3xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
            <div class="flex justify-between items-start mb-6 pb-6 border-b border-gray-200">
                <div>
                    <h1 class="text-3xl font-bold text-gray-900 mb-2">{{ post.title }}</h1>
                    <div class="flex items-center space-x-4 text-sm text-gray-500">
                        <span>{{ post.slug }}</span>
                        <span :class="post.status === 'publish' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'"
                            class="px-2 py-0.5 text-xs font-semibold rounded-full">
                            {{ post.status.charAt(0).toUpperCase() + post.status.slice(1) }}
                        </span>
                    </div>
                </div>
                <div class="flex space-x-3">
                    <Link href="/posts" class="text-sm font-medium text-gray-600 hover:text-gray-900 bg-gray-100 hover:bg-gray-200 px-4 py-2 rounded-md transition shadow-sm border border-gray-200">Back</Link>
                    <Link :href="`/posts/${post.id}/edit`" class="text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 px-4 py-2 rounded-md shadow-sm transition">Edit Post</Link>
                </div>
            </div>

            <div class="prose max-w-none text-gray-800 leading-relaxed whitespace-pre-wrap">{{ post.content }}</div>

            <div class="mt-10 pt-6 border-t border-gray-100 text-sm text-gray-500">
                <span>Posted: {{ new Date(post.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }) }}</span>
            </div>
        </div>
    </AppLayout>
</template>
```

### Edit Page

Create `resources/js/Pages/Posts/Edit.vue`:

```js
<script setup>
import { useForm, Link } from '@inertiajs/vue3';
import AppLayout from '@/Layouts/AppLayout.vue';

const props = defineProps({
    post: Object,
});

const form = useForm({
    title: props.post.title,
    content: props.post.content,
    status: props.post.status,
});

function submit() {
    form.put(`/posts/${props.post.id}`);
}
</script>

<template>
    <AppLayout>
        <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
            <div class="flex justify-between items-center mb-6">
                <h1 class="text-2xl font-bold text-gray-900">Edit Post</h1>
                <Link href="/posts" class="text-gray-600 hover:text-gray-900 underline text-sm transition">Back to Manage Posts</Link>
            </div>

            <form @submit.prevent="submit" class="space-y-6">
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Title</label>
                    <input v-model="form.title" type="text" required
                        class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition">
                    <p v-if="form.errors.title" class="text-red-500 text-sm mt-1">{{ form.errors.title }}</p>
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Content</label>
                    <textarea v-model="form.content" rows="8" required
                        class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition resize-y"></textarea>
                    <p v-if="form.errors.content" class="text-red-500 text-sm mt-1">{{ form.errors.content }}</p>
                </div>

                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                    <select v-model="form.status" required
                        class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition">
                        <option value="draft">Draft</option>
                        <option value="publish">Publish</option>
                    </select>
                    <p v-if="form.errors.status" class="text-red-500 text-sm mt-1">{{ form.errors.status }}</p>
                </div>

                <div class="pt-2 flex justify-end">
                    <button type="submit" :disabled="form.processing"
                        class="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-2 px-6 rounded-md transition duration-200 shadow-sm disabled:opacity-50">
                        {{ form.processing ? 'Saving...' : 'Update Post' }}
                    </button>
                </div>
            </form>
        </div>
    </AppLayout>
</template>
```

The Edit component is similar to Create, with two differences: `useForm()` is initialized with the existing post data (`props.post.title`, etc.) so the form is pre-filled, and `form.put()` is used instead of `form.post()` to send a PUT request.

Save all Vue files.


## Step 5: Build and Run {#step-5-build-and-run}

Open terminal, then start the Laravel server and vite development server:

```
composer run dev
```

Open `http://127.0.0.1:8000/posts` and test all CRUD operations. Notice how page navigations feel instant compared to the Blade version. There are no full page reloads. The URL changes, the content swaps, and the browser history works correctly.


## Blade vs Inertia: A Comparison {#blade-vs-inertia-comparison}

Now that we have built the same application with both approaches, let's compare them.

### Controller Layer

| Aspect | Blade | Inertia |
|--------|-------|---------|
| Return statement | `return view('posts.index', compact('posts'))` | `return Inertia::render('Posts/Index', ['posts' => $posts])` |
| Redirects | Same | Same |
| Flash messages | Same | Same |
| Form Requests | Same | Same |
| Validation | Same | Same |

The controller is nearly identical. Swapping between Blade and Inertia requires changing only the return statements.

### View/Component Layer

| Aspect | Blade | Inertia + Vue |
|--------|-------|---------------|
| Template syntax | `{{ $post->title }}`, `@foreach`, `@if` | `{{ post.title }}`, `v-for`, `v-if` |
| Forms | HTML `<form>` with `@csrf`, `@method` | `useForm()` with `form.post()`, `form.put()` |
| Validation errors | `@if($errors->any())` | `form.errors.fieldName` |
| Links | `<a href>` | `<Link href>` (client-side navigation) |
| Page reloads | Yes (full reload on every navigation) | No (XHR + component swap) |
| Build step | None | Required (`npm run build`) |
| File format | `.blade.php` | `.vue` |

### Developer Experience

| Aspect | Blade | Inertia + Vue |
|--------|-------|---------------|
| Learning curve | Lower (just PHP) | Higher (need Vue.js + Inertia knowledge) |
| Setup complexity | None (built into Laravel) | Moderate (Vite, Vue, Inertia configuration) |
| Tooling | No build tools needed | Node.js, NPM, Vite required |
| Reactivity | Manual (JavaScript or Livewire) | Built-in (Vue reactivity system) |
| SEO | Good (server-rendered HTML) | Good (first visit is server-rendered) |
| UX feel | Traditional multi-page app | SPA-like (no page reloads) |

### When to Use Which

**Choose Blade when:**
- Your team is primarily PHP developers.
- The application is content-heavy with minimal interactivity.
- You want the simplest possible setup with no build step.
- SEO is critical and you want guaranteed server-rendered HTML.

**Choose Inertia + Vue when:**
- You want an SPA-like experience without building a separate API.
- Your team is comfortable with both PHP and JavaScript.
- The application has interactive UI elements (drag and drop, real-time updates, complex forms).
- You want to share components across pages for a consistent UI.
- You plan to eventually build a mobile app (the Vue components can inform the mobile UI design).


## Conclusion {#conclusion}

In this tutorial, we built a blog CRUD application using Laravel 13, Inertia.js, and Vue 3. The backend (controllers, routes, validation, models) is virtually the same as the Blade version. The difference is in how the frontend is rendered: Vue components replace Blade templates, and Inertia handles the communication between them.

Here are the key takeaways:

- **Inertia eliminates the need for an API.** Your controllers return Inertia responses instead of views. No API routes, no JSON resources, no client-side routing. The server controls the routing, the client renders the UI.
- **`useForm()` is Inertia's killer feature.** It handles form data, submission, validation errors, and processing state in a single composable. No manual XHR calls, no error parsing, no loading state management.
- **The controller barely changes.** Replacing `view()` with `Inertia::render()` is the only backend change. Redirects, flash messages, Form Requests, and Policies all work identically.
- **Vue provides reactivity that Blade lacks.** Conditional rendering, computed properties, and reactive state are native to Vue. In Blade, you would need additional JavaScript or Livewire for the same behavior.
- **A build step is required.** Unlike Blade, the Inertia + Vue stack needs Node.js and a Vite build. This adds complexity to your deployment pipeline.
- **First visit is server-rendered, subsequent visits are XHR.** This gives you SPA-like speed without sacrificing initial page load performance or SEO.

Both approaches are valid. Blade is simpler and requires less tooling. Inertia + Vue provides a better user experience with more frontend capabilities. The right choice depends on your team, your project requirements, and the kind of experience you want to deliver to your users.