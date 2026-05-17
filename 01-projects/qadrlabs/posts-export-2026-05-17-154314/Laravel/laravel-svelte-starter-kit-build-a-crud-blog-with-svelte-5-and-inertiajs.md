---
title: "Laravel Svelte Starter Kit: Build a CRUD Blog with Svelte 5 and Inertia.js"
slug: "laravel-svelte-starter-kit-build-a-crud-blog-with-svelte-5-and-inertiajs"
category: "Laravel"
date: "2026-04-05"
status: "published"
---

In our [Laravel Svelte Starter Kit](https://qadrlabs.com/post/laravel-12-svelte-starter-kit) article, we set up a Laravel project with the official Svelte starter kit and explored its structure: authentication pages, dashboard, settings, and all the frontend dependencies that come pre-configured. The starter kit gives you a solid foundation, but it does not include any application-specific features. The dashboard is empty. There are no models, no controllers, no data to display.

In this tutorial, we will build on that foundation by adding a complete CRUD blog feature to a Laravel 13 project using the Svelte starter kit. We will create a Post model, write Form Requests for validation, build a controller with Laravel 13's `#[Middleware]` attribute, construct three Svelte page components for listing, creating, and editing posts, and write Pest tests to verify everything works. By the end, you will have a fully functional blog management feature integrated into the starter kit's sidebar navigation.


## Overview {#overview}

This tutorial walks you through building a blog post management feature inside a Laravel 13 Svelte starter kit project. We will use Inertia.js to connect the Laravel backend with Svelte 5 components on the frontend, Laravel Wayfinder for type-safe routing, and the starter kit's built-in UI components (shadcn-svelte) for a consistent design.

### What You'll Build

- A post listing page with a table, pagination, and status badges.
- A create form with auto-generated slugs and server-side validation.
- An edit form with pre-filled data using Svelte 5's `$state.snapshot()`.
- A delete function with a confirmation prompt.
- Sidebar navigation integration with the starter kit's layout.

### What You'll Learn

- How to add CRUD features to an existing Laravel Svelte starter kit project.
- How to create models, migrations, factories, seeders, and Form Requests.
- How to build a controller with `Inertia::render()` and the `#[Middleware]` attribute.
- How to use Laravel Wayfinder for strongly typed routing in Svelte.
- How to build Svelte 5 page components with `useForm` from Inertia.
- How to use `$state.snapshot()` for form initialization in Svelte 5.
- How to write Pest tests for Inertia-based CRUD operations.

### What You'll Need

- PHP 8.3 or higher.
- Composer installed globally.
- Node.js and NPM installed.
- MySQL or SQLite (Laravel 13 uses SQLite by default).
- A code editor (Visual Studio Code recommended).
- Basic familiarity with PHP, Laravel, and Svelte.
- The Laravel Svelte starter kit installed. See our [starter kit article](https://qadrlabs.com/post/laravel-12-svelte-starter-kit) for setup instructions.


## Step 1: Create a Laravel Project with Svelte Starter Kit {#step-1-create-project}

Create a new Laravel project using the starter kit installer. Open your terminal and run:

```bash
laravel new svelte-crud-demo
```

When prompted, select the following options:

**Starter kit:** Svelte

```
 ┌ Which starter kit would you like to install? ────────────────┐
 │   ○ None                                                     │
 │   ○ React                                                    │
 │ › ● Svelte                                                   │
 │   ○ Vue                                                      │
 │   ○ Livewire                                                 │
 └──────────────────────────────────────────────────────────────┘
```

**Authentication:** Laravel's built-in authentication

```
 ┌ Which authentication provider do you prefer? ────────────────┐
 │ › ● Laravel's built-in authentication                        │
 │   ○ WorkOS (Requires WorkOS account)                         │
 │   ○ No authentication scaffolding                            │
 └──────────────────────────────────────────────────────────────┘
```

**Teams:** No

```
 ┌ Would you like to add teams support to your application? ────┐
 │ ○ Yes / ● No                                                 │
 └──────────────────────────────────────────────────────────────┘
```

**Testing framework:** Pest

```
 ┌ Which testing framework do you prefer? ──────────────────────┐
 │ › ● Pest                                                     │
 │   ○ PHPUnit                                                  │
 └──────────────────────────────────────────────────────────────┘
```

**Laravel Boost:** Optional, choose either option.

When prompted to install dependencies and build frontend assets, select **Yes**:

```
 ┌ Would you like to run npm install and npm run build? ─────────┐
 │ ● Yes                                                         │
 └───────────────────────────────────────────────────────────────┘
```

Wait for the installation to complete. Once done, navigate into the project directory:

```bash
cd svelte-crud-demo
```

The project now includes authentication (register, login, logout), a dashboard page, settings pages, and all the Svelte/Inertia/Tailwind configuration already wired up. For a detailed walkthrough of what the starter kit includes, see our [Laravel Svelte Starter Kit](https://qadrlabs.com/post/laravel-12-svelte-starter-kit) article.


## Step 2: Create Model, Migration, and Factory {#step-2-create-model-migration-factory}

We need a database structure to hold our blog posts. The following command creates the `Post` model, its database migration, and a factory for testing at the same time:

```bash
php artisan make:model Post -mf
```

The `-mf` flag tells Artisan to generate a migration and a factory file alongside the model.

### Define the Database Schema

Open the migration file at `database/migrations/xxxx_xx_xx_xxxxxx_create_posts_table.php` and update it:

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

Each column is chosen deliberately: `string('title')` stores the post headline, `string('slug')->unique()` stores a URL-friendly version of the title with a uniqueness constraint, `text('content')` stores the post body, and `enum('status', ['draft', 'publish'])` restricts the status to two values with "draft" as the default.

Save the file.

### Configure the Model

Open `app/Models/Post.php` and replace its content with:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['title', 'slug', 'content', 'status'])]
class Post extends Model
{
    use HasFactory;

    protected $attributes = [
        'status' => 'draft',
    ];

    public function getRouteKeyName(): string
    {
        return 'slug';
    }
}
```

The `#[Fillable]` attribute is Laravel 13's declarative way to define mass-assignable fields, replacing the old `protected $fillable` array. The `$attributes` property sets a default status value for new posts. The `getRouteKeyName()` method tells Laravel's route model binding to look up posts by their `slug` instead of their `id`, so URLs like `/posts/my-first-post` work automatically.

Save the file.

### Configure the Factory

Open `database/factories/PostFactory.php` and define the factory:

```php
<?php

namespace Database\Factories;

use App\Models\Post;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class PostFactory extends Factory
{
    public function definition(): array
    {
        $title = fake()->unique()->sentence();

        return [
            'title' => $title,
            'slug' => Str::slug($title),
            'content' => fake()->paragraphs(3, true),
            'status' => fake()->randomElement(['draft', 'publish']),
        ];
    }
}
```

The factory generates realistic dummy data: a unique sentence for the title, an auto-generated slug, three paragraphs of content, and a random status.

Save the file.


## Step 3: Create the Database Seeder {#step-3-database-seeder}

Create a seeder to populate the database with dummy posts:

```bash
php artisan make:seeder PostSeeder
```

Open `database/seeders/PostSeeder.php`:

```php
<?php

namespace Database\Seeders;

use App\Models\Post;
use Illuminate\Database\Seeder;

class PostSeeder extends Seeder
{
    public function run(): void
    {
        Post::factory(15)->create();
    }
}
```

Register the seeder in `database/seeders/DatabaseSeeder.php`:

```php
<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
        ]);

        $this->call(PostSeeder::class);
    }
}
```

By calling `PostSeeder` inside `DatabaseSeeder`, all records will be seeded at once when you run the artisan command.

Run the database migrations along with the seeders:

```bash
php artisan migrate --seed
```


## Step 4: Create Form Requests and Controller {#step-4-form-requests-and-controller}

### Generate Form Requests

```bash
php artisan make:request StorePostRequest
php artisan make:request UpdatePostRequest
```

Open `app/Http/Requests/StorePostRequest.php`:

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StorePostRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'slug' => ['required', 'string', 'max:255', Rule::unique('posts')],
            'content' => ['required', 'string'],
            'status' => ['required', Rule::in(['draft', 'publish'])],
        ];
    }
}
```

All fields are required. The `slug` must be unique across the `posts` table. The `status` must match one of the enum values.

Open `app/Http/Requests/UpdatePostRequest.php`:

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdatePostRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'slug' => ['required', 'string', 'max:255', Rule::unique('posts')->ignore($this->route('post'))],
            'content' => ['required', 'string'],
            'status' => ['required', Rule::in(['draft', 'publish'])],
        ];
    }
}
```

The key difference is `Rule::unique('posts')->ignore($this->route('post'))`. This prevents a validation error when the user updates a post without changing its slug. Without `ignore()`, Laravel would reject the slug because it already exists in the database (belonging to the post being updated).

Save both files.

### Create the Controller

```bash
php artisan make:controller PostController
```

Open `app/Http/Controllers/PostController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Models\Post;
use Illuminate\Http\RedirectResponse;
use Illuminate\Routing\Attributes\Controllers\Middleware;
use Inertia\Inertia;
use Inertia\Response;

#[Middleware('auth')]
class PostController extends Controller
{
    public function index(): Response
    {
        return Inertia::render('posts/Index', [
            'posts' => Post::query()->orderByDesc('id')->paginate(10),
        ]);
    }

    public function create(): Response
    {
        return Inertia::render('posts/Create');
    }

    public function store(StorePostRequest $request): RedirectResponse
    {
        Post::create($request->validated());
        return to_route('posts.index')->with('success', 'Post created successfully.');
    }

    public function edit(Post $post): Response
    {
        return Inertia::render('posts/Edit', [
            'post' => $post,
        ]);
    }

    public function update(UpdatePostRequest $request, Post $post): RedirectResponse
    {
        $post->update($request->validated());
        return to_route('posts.index')->with('success', 'Post updated successfully.');
    }

    public function destroy(Post $post): RedirectResponse
    {
        $post->delete();
        return to_route('posts.index')->with('success', 'Post deleted successfully.');
    }
}
```

The controller follows the same pattern as our [Laravel 13 Blade CRUD tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step), but with two key differences. First, `#[Middleware('auth')]` on the class uses Laravel 13's PHP attribute syntax to protect all methods, replacing the constructor-based approach. Second, `Inertia::render()` returns Svelte components instead of Blade views. The first argument is the component path (relative to `resources/js/pages/`), and the second argument is the data passed as props to the Svelte component.

Route model binding works automatically because we set `getRouteKeyName()` to `slug` on the model. When the URL is `/posts/my-first-post/edit`, Laravel resolves the `Post $post` parameter by querying `WHERE slug = 'my-first-post'`.

Save the file.


## Step 5: Register Routes {#step-5-register-routes}

Open `routes/web.php` and add the post resource route inside the authenticated group:

```php
<?php

use App\Http\Controllers\PostController;
use Illuminate\Support\Facades\Route;
use Laravel\Fortify\Features;

Route::inertia('/', 'Welcome', [
    'canRegister' => Features::enabled(Features::registration()),
])->name('home');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::inertia('dashboard', 'Dashboard')->name('dashboard');
    Route::resource('posts', PostController::class)->except(['show']);
});

require __DIR__.'/settings.php';
```

The `Route::resource('posts', PostController::class)->except(['show'])` registers all CRUD routes except the show page, which we omit for simplicity. The routes are inside the `['auth', 'verified']` middleware group, which means only authenticated and email-verified users can access them.

After defining the routes, generate the Wayfinder type definitions:

```bash
php artisan wayfinder:generate
```

Wayfinder generates strongly typed TypeScript functions that represent your Laravel routes. Instead of writing `/posts` or `/posts/${slug}/edit` as strings in your Svelte components, you use functions like `postsIndex()` and `postsEdit(slug)`. If you rename a route in Laravel, Wayfinder will catch the mismatch at build time instead of at runtime.

Save the file.


## Step 6: Create Svelte Page Components {#step-6-create-svelte-views}

Create a new directory `posts` inside `resources/js/pages/`:

```bash
mkdir -p resources/js/pages/posts
```

### Index Page

Create `resources/js/pages/posts/Index.svelte`:

```html
<script module lang="ts">
    import { index as postsIndex } from '@/routes/posts';

    export const layout = {
        breadcrumbs: [
            {
                title: 'Posts',
                href: postsIndex(),
            },
        ],
    };
</script>

<script lang="ts">
    import { Link, router } from '@inertiajs/svelte';
    import { create as postsCreate, edit as postsEdit, destroy as postsDestroy } from '@/routes/posts';
    import AppHead from '@/components/AppHead.svelte';
    import { Button } from '@/components/ui/button';
    import { Badge } from '@/components/ui/badge';
    import { toUrl } from '@/lib/utils';

    let { posts } = $props();

    function deletePost(post: any) {
        if (confirm(`Are you sure you want to delete "${post.title}"?`)) {
            router.delete(postsDestroy.url(post.slug));
        }
    }
</script>

<AppHead title="Posts" />

<div class="w-full space-y-6 p-4">
    <div class="flex items-center justify-between">
        <div>
            <h1 class="text-2xl font-bold tracking-tight">Posts</h1>
            <p class="text-sm text-muted-foreground">Manage your blog posts</p>
        </div>
        <Button asChild>
            {#snippet children(props)}
                <Link {...props} href={toUrl(postsCreate())} class={props.class}>
                    Create Post
                </Link>
            {/snippet}
        </Button>
    </div>

    <div class="rounded-lg border">
        <div class="overflow-x-auto">
            <table class="w-full text-sm">
                <thead>
                    <tr class="border-b bg-muted/50">
                        <th class="px-4 py-3 text-left font-medium">Title</th>
                        <th class="px-4 py-3 text-left font-medium">Slug</th>
                        <th class="px-4 py-3 text-left font-medium">Status</th>
                        <th class="px-4 py-3 text-right font-medium">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {#each posts.data as post (post.id)}
                        <tr class="border-b transition-colors hover:bg-muted/50">
                            <td class="px-4 py-3 font-medium">{post.title}</td>
                            <td class="px-4 py-3 text-muted-foreground">{post.slug}</td>
                            <td class="px-4 py-3">
                                <Badge variant={post.status === 'publish' ? 'default' : 'secondary'}>
                                    {post.status}
                                </Badge>
                            </td>
                            <td class="px-4 py-3 text-right">
                                <div class="flex items-center justify-end gap-2">
                                    <Button variant="outline" size="sm" asChild>
                                        {#snippet children(props)}
                                            <Link {...props} href={toUrl(postsEdit(post.slug))} class={props.class}>Edit</Link>
                                        {/snippet}
                                    </Button>
                                    <Button variant="destructive" size="sm" onclick={() => deletePost(post)}>Delete</Button>
                                </div>
                            </td>
                        </tr>
                    {:else}
                        <tr>
                            <td colspan="4" class="px-4 py-8 text-center text-muted-foreground">No posts found.</td>
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>
    </div>
</div>
```

A few things to note about this component:

**`<script module>`**: This block exports metadata for the persistent layout. The `breadcrumbs` array integrates with the starter kit's breadcrumb component in the sidebar layout.

**Wayfinder route functions**: Instead of hardcoding URL strings, we import generated functions like `postsCreate()`, `postsEdit(post.slug)`, and `postsDestroy.url(post.slug)` from `@/routes/posts`. These are type-safe and will break at build time if the Laravel route changes.

**`{#each posts.data as post (post.id)}`**: Iterates over the pagination payload from Laravel. The `posts.data` key contains the actual records because Laravel's paginator wraps results in a `data` key when serialized to JSON.

**`router.delete()`**: Sends a DELETE request via Inertia when the user confirms the deletion. No form submission needed.

Save the file.

### Create Page

Create `resources/js/pages/posts/Create.svelte`:

```html
<script module lang="ts">
    import { index as postsIndex, create as postsCreate } from '@/routes/posts';

    export const layout = {
        breadcrumbs: [
            { title: 'Posts', href: postsIndex() },
            { title: 'Create Post', href: postsCreate() },
        ],
    };
</script>

<script lang="ts">
    import { useForm } from '@inertiajs/svelte';
    import { store } from '@/actions/App/Http/Controllers/PostController';
    import AppHead from '@/components/AppHead.svelte';
    import InputError from '@/components/InputError.svelte';
    import { Button } from '@/components/ui/button';
    import { Input } from '@/components/ui/input';
    import { Label } from '@/components/ui/label';

    const form = useForm({
        title: '',
        slug: '',
        content: '',
        status: 'draft',
    });

    let slugManuallyEdited = false;

    function handleTitleInput(e: Event) {
        const target = e.target as HTMLInputElement;
        form.title = target.value;
        if (!slugManuallyEdited) {
            form.slug = target.value.toLowerCase().replace(/[\s_]+/g, '-').replace(/[^\w-]+/g, '');
        }
    }

    function submit(e: Event) {
        e.preventDefault();
        form.post(store.url());
    }
</script>

<AppHead title="Create Post" />

<div class="w-full space-y-6 p-4">
    <h1 class="text-2xl font-bold tracking-tight">Create Post</h1>

    <form onsubmit={submit} class="space-y-6">
        <div class="grid gap-2">
            <Label for="title">Title</Label>
            <Input id="title" bind:value={form.title} oninput={handleTitleInput} required />
            <InputError message={form.errors.title} />
        </div>

        <div class="grid gap-2">
            <Label for="slug">Slug</Label>
            <Input id="slug" bind:value={form.slug} oninput={() => slugManuallyEdited = true} required />
            <InputError message={form.errors.slug} />
        </div>

        <div class="grid gap-2">
            <Label for="content">Content</Label>
            <textarea id="content" bind:value={form.content} rows="10" required
                class="flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"></textarea>
            <InputError message={form.errors.content} />
        </div>

        <div class="grid gap-2">
            <Label for="status">Status</Label>
            <select id="status" bind:value={form.status}
                class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50">
                <option value="draft">Draft</option>
                <option value="publish">Publish</option>
            </select>
            <InputError message={form.errors.status} />
        </div>

        <Button type="submit" disabled={form.processing}>Create Post</Button>
    </form>
</div>
```

**`useForm`** from `@inertiajs/svelte` handles form state, submission, validation errors, and processing state in one object. Similar to Inertia's `useForm` in Vue, but with Svelte's reactivity system.

**`handleTitleInput`** auto-generates a slug as the user types the title. The `slugManuallyEdited` flag ensures that once the user manually edits the slug field, the auto-generation stops.

**`form.post(store.url())`** submits the form data to the `store` action URL generated by Wayfinder. If validation fails on the server, `form.errors` is automatically populated with the error messages from the Form Request.

**`InputError`** is a component from the starter kit that displays validation error messages below form fields.

Save the file.

### Edit Page

Create `resources/js/pages/posts/Edit.svelte`:

```html
<script module lang="ts">
    import { index as postsIndex } from '@/routes/posts';

    export const layout = {
        breadcrumbs: [
            { title: 'Posts', href: postsIndex() },
            { title: 'Edit Post', href: postsIndex() },
        ],
    };
</script>

<script lang="ts">
    import { useForm } from '@inertiajs/svelte';
    import { update } from '@/actions/App/Http/Controllers/PostController';
    import AppHead from '@/components/AppHead.svelte';
    import InputError from '@/components/InputError.svelte';
    import { Button } from '@/components/ui/button';
    import { Input } from '@/components/ui/input';
    import { Label } from '@/components/ui/label';

    let { post } = $props();

    const form = useForm({
        title: $state.snapshot(post).title,
        slug: $state.snapshot(post).slug,
        content: $state.snapshot(post).content,
        status: $state.snapshot(post).status,
    });

    function submit(e: Event) {
        e.preventDefault();
        form.put(update.url(post.slug));
    }
</script>

<AppHead title="Edit Post" />

<div class="w-full space-y-6 p-4">
    <h1 class="text-2xl font-bold tracking-tight">Edit Post</h1>

    <form onsubmit={submit} class="space-y-6">
        <div class="grid gap-2">
            <Label for="title">Title</Label>
            <Input id="title" bind:value={form.title} required />
            <InputError message={form.errors.title} />
        </div>

        <div class="grid gap-2">
            <Label for="slug">Slug</Label>
            <Input id="slug" bind:value={form.slug} required />
            <InputError message={form.errors.slug} />
        </div>

        <div class="grid gap-2">
            <Label for="content">Content</Label>
            <textarea id="content" bind:value={form.content} rows="10" required
                class="flex w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"></textarea>
            <InputError message={form.errors.content} />
        </div>

        <div class="grid gap-2">
            <Label for="status">Status</Label>
            <select id="status" bind:value={form.status}
                class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50">
                <option value="draft">Draft</option>
                <option value="publish">Publish</option>
            </select>
            <InputError message={form.errors.status} />
        </div>

        <Button type="submit" disabled={form.processing}>Update Post</Button>
    </form>
</div>
```

The key difference from the create component is how the form is initialized. The `$props()` rune receives the `post` data from the controller via Inertia. However, Svelte 5 wraps props in reactive proxies, which can cause issues when passed to Inertia's `useForm`. The `$state.snapshot()` call extracts a plain JavaScript object from the reactive proxy, preventing warnings and ensuring clean data initialization.

The `form.put(update.url(post.slug))` sends a PUT request to the update route with the current post's slug as the route parameter.

Save the file.


## Step 7: Add Navigation to the Sidebar {#step-7-add-navigation}

To access the posts feature from the starter kit's sidebar, we need to add a navigation link. Open `resources/js/components/AppSidebar.svelte` and add the posts route:

```html
<script lang="ts">
    import FileText from 'lucide-svelte/icons/file-text';
    import { dashboard } from '@/routes';
    import { index as postsIndex } from '@/routes/posts';
    // ...

    const mainNavItems: NavItem[] = [
        {
            title: 'Dashboard',
            href: dashboard(),
            icon: LayoutGrid,
        },
        {
            title: 'Posts',
            href: postsIndex(),
            icon: FileText,
        },
    ];
</script>
```

We import `FileText` from `lucide-svelte/icons` for the sidebar icon (a document icon) and `postsIndex` from the Wayfinder-generated routes. The new entry appears in the sidebar alongside the existing Dashboard link.

Save the file.


## Step 8: Write Tests {#step-8-write-tests}

The Svelte starter kit comes with Pest pre-installed and configured with SQLite in-memory in `phpunit.xml`. Create the test file:

```bash
php artisan make:test Posts/PostCrudTest --pest
```

Open `tests/Feature/Posts/PostCrudTest.php`:

```php
<?php

use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;

uses(LazilyRefreshDatabase::class);

test('authenticated users can view the posts index', function () {
    $user = User::factory()->create();
    Post::factory(3)->create();

    $this->actingAs($user)
        ->get(route('posts.index'))
        ->assertSuccessful()
        ->assertInertia(fn ($page) => $page
            ->component('posts/Index')
            ->has('posts.data', 3)
        );
});

test('unauthenticated users cannot view the posts index', function () {
    $this->get(route('posts.index'))
        ->assertRedirect(route('login'));
});

test('authenticated users can view the create form', function () {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->get(route('posts.create'))
        ->assertSuccessful()
        ->assertInertia(fn ($page) => $page
            ->component('posts/Create')
        );
});

test('authenticated users can store a new post', function () {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->post(route('posts.store'), [
            'title' => 'My First Post',
            'slug' => 'my-first-post',
            'content' => 'This is the content.',
            'status' => 'publish',
        ])
        ->assertRedirect(route('posts.index'))
        ->assertSessionHas('success', 'Post created successfully.');

    $this->assertDatabaseHas('posts', [
        'title' => 'My First Post',
        'slug' => 'my-first-post',
    ]);
});

test('store validates required fields', function () {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->post(route('posts.store'), [])
        ->assertSessionHasErrors(['title', 'slug', 'content', 'status']);
});

test('store validates slug is unique', function () {
    $user = User::factory()->create();
    Post::factory()->create(['slug' => 'existing-slug']);

    $this->actingAs($user)
        ->post(route('posts.store'), [
            'title' => 'New Post',
            'slug' => 'existing-slug',
            'content' => 'Content here',
            'status' => 'draft',
        ])
        ->assertSessionHasErrors('slug');
});

test('authenticated users can view the edit form', function () {
    $user = User::factory()->create();
    $post = Post::factory()->create();

    $this->actingAs($user)
        ->get(route('posts.edit', $post))
        ->assertSuccessful()
        ->assertInertia(fn ($page) => $page
            ->component('posts/Edit')
            ->has('post')
        );
});

test('authenticated users can update a post', function () {
    $user = User::factory()->create();
    $post = Post::factory()->create();

    $this->actingAs($user)
        ->put(route('posts.update', $post), [
            'title' => 'Updated Title',
            'slug' => 'updated-title',
            'content' => 'Updated content.',
            'status' => 'publish',
        ])
        ->assertRedirect(route('posts.index'))
        ->assertSessionHas('success', 'Post updated successfully.');

    $this->assertDatabaseHas('posts', [
        'id' => $post->id,
        'title' => 'Updated Title',
    ]);
});

test('update allows same slug for the same post', function () {
    $user = User::factory()->create();
    $post = Post::factory()->create(['slug' => 'my-slug']);

    $this->actingAs($user)
        ->put(route('posts.update', $post), [
            'title' => 'Updated Title',
            'slug' => 'my-slug',
            'content' => 'Updated content.',
            'status' => 'publish',
        ])
        ->assertRedirect(route('posts.index'))
        ->assertSessionHasNoErrors();
});

test('authenticated users can delete a post', function () {
    $user = User::factory()->create();
    $post = Post::factory()->create();

    $this->actingAs($user)
        ->delete(route('posts.destroy', $post))
        ->assertRedirect(route('posts.index'))
        ->assertSessionHas('success', 'Post deleted successfully.');

    $this->assertDatabaseMissing('posts', ['id' => $post->id]);
});
```

The tests use `assertInertia()` to verify that the correct Svelte component is rendered with the expected props. This is specific to Inertia-based applications. The `LazilyRefreshDatabase` trait ensures the database is only reset when a test actually touches it, making the test suite faster.

Save the file.


## Step 9: Run Tests {#step-9-run-tests}

```bash
php artisan test --compact
```

```
$ php artisan test --compact

  .........................

  Tests:    25 passed (101 assertions)
  Duration: 0.51s
```

All tests passing.


## Step 10: Try It Out {#step-10-try-it-out}

Start both the Laravel server and the Vite dev server with a single command:

```bash
composer run dev
```

This runs multiple processes simultaneously: the PHP development server on port 8000, the Vite dev server for hot-reload, and the queue worker.

Open your browser and navigate to `http://localhost:8000`. Log in using the test user credentials you seeded (`test@example.com` / `password`). Click **Posts** in the sidebar.

### Test Creating a Post

Click **Create Post**. Fill in the title and watch the slug auto-generate as you type. Add content, select a status, and click **Create Post**. You should be redirected to the index page with a success message.

### Test Editing a Post

Click **Edit** on any post. The form should be pre-filled with the existing data. Change the title and click **Update Post**. The success message should appear and the table should reflect the update.

### Test Validation

Try submitting the create form with empty fields. Validation errors should appear below each field without a page reload.

Try creating a post with a slug that already exists. You should see a validation error on the slug field.

### Test Deleting a Post

Click **Delete** on any post. A confirmation dialog should appear. Click OK. The post should disappear from the table with a success message.


## Svelte vs Vue vs Blade: A Quick Comparison {#svelte-vs-vue-vs-blade}

If you have followed our other CRUD tutorials in the [Learn Laravel 13 Tutorial Series](https://qadrlabs.com/series/learn-laravel-13-tutorial-series), here is how the Svelte approach compares:

| Aspect | Blade | Vue + Inertia | Svelte + Inertia |
|--------|-------|---------------|------------------|
| File format | `.blade.php` | `.vue` | `.svelte` |
| Reactivity | None (server-rendered) | Virtual DOM diffing | Compiled (no virtual DOM) |
| Bundle size | No JS bundle | Larger (Vue runtime) | Smaller (compiled away) |
| Form handling | HTML forms + `@csrf` | `useForm()` | `useForm()` |
| Data binding | `value="{{ old() }}"` | `v-model` | `bind:value` |
| Routing | `route()` helper | Wayfinder or string URLs | Wayfinder (type-safe) |
| Validation errors | `@error` directive | `form.errors.field` | `form.errors.field` |
| Build step | None | Required (Vite) | Required (Vite) |
| Starter kit | Not included | Official starter kit | Official starter kit |

The Svelte approach produces the smallest JavaScript bundle because Svelte compiles components to vanilla JavaScript at build time. There is no framework runtime shipped to the browser. The developer experience is similar to Vue + Inertia (both use `useForm`, both use Inertia for server-side routing), but the template syntax is closer to standard HTML.


## Conclusion {#conclusion}

In this tutorial, we built a complete CRUD blog feature on top of the Laravel Svelte starter kit. Starting from the pre-configured authentication and layout, we added a Post model, Form Requests, a controller with Inertia responses, three Svelte page components, sidebar navigation, and Pest tests.

Here are the key takeaways:

- **The starter kit provides the foundation, you build the features.** Authentication, layout, sidebar, and UI components are already configured. This tutorial shows how to add application-specific CRUD functionality on top of that foundation.
- **Wayfinder eliminates route string typos.** Instead of hardcoding `/posts` or `/posts/${slug}/edit`, you import type-safe functions like `postsIndex()` and `postsEdit(slug)`. Route changes in Laravel are caught at build time.
- **`useForm` from Inertia handles form complexity.** Form state, submission, validation errors, and processing state are managed in one object. No manual XHR calls or error parsing needed.
- **`$state.snapshot()` solves Svelte 5 proxy issues.** When initializing `useForm` with prop data, use `$state.snapshot()` to extract plain values from Svelte's reactive proxies. This prevents console warnings and ensures clean data transfer.
- **`#[Middleware('auth')]` keeps the controller clean.** Laravel 13's PHP attribute syntax declares middleware at the class level without a constructor or a separate static method.
- **Pest tests use `assertInertia()` for component verification.** This assertion checks both the rendered component name and the props passed to it, ensuring your controller returns the correct data to the correct Svelte component.
- **`composer run dev` starts everything at once.** The starter kit's Composer script runs the PHP server, Vite dev server, queue worker, and log viewer simultaneously. No need for multiple terminal tabs.