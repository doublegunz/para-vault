---
title: "Laravel 13: Add Soft Deletes to Your Blog"
slug: "laravel-13-add-soft-deletes-to-your-blog"
category: "Laravel"
date: "2026-04-04"
status: "published"
---

When you delete a post in our [blog tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step), it is gone forever. The row is removed from the database, and there is no way to recover it. In a real application, this is risky. An admin accidentally deletes a popular post, a team member removes the wrong record, or a client changes their mind five minutes later. Permanent deletion leaves no safety net.

Soft deletes solve this by marking records as deleted without removing them from the database. The row stays in the table with a `deleted_at` timestamp, Eloquent automatically hides it from normal queries, and you can restore it at any time. In this tutorial, we will add soft delete functionality to our blog, build a trash management page, update the existing tests to account for the new behavior, and write new tests for restore and force delete.


## Overview {#overview}

We will add soft delete functionality to the blog application from our [CRUD tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step). Posts will no longer be permanently deleted by default. Instead, they will be hidden from the listing but recoverable from a trash page. We will also add a force delete option for when you truly want to remove a record permanently.

### What You'll Build

- Soft delete functionality on the Post model (marking records as deleted without removing them).
- A "Trash" page that lists soft-deleted posts with restore and permanent delete options.
- Updated existing tests to verify soft delete behavior.
- New Pest tests for the trash page, restore, and force delete.

### What You'll Learn

- How to add the `SoftDeletes` trait and `deleted_at` migration column to an existing model.
- How to query soft-deleted records with `onlyTrashed()`, `withTrashed()`, and `withoutTrashed()`.
- How to restore and force-delete soft-deleted records.
- How to handle route ordering when adding custom routes alongside `Route::resource()`.
- How to use `assertSoftDeleted()` in Pest tests.
- How existing delete tests change when soft deletes are enabled.

### What You'll Need

- PHP 8.3 or higher.
- Composer installed globally.
- MySQL or another supported database.
- A Laravel 13 blog project with authentication. You can follow the [CRUD tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step) and [auth tutorial](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes) to set up the base project.


## Step 1: Add the Soft Deletes Migration {#step-1-add-migration}

Create a migration to add the `deleted_at` column to the posts table:

```bash
php artisan make:migration add_soft_deletes_to_posts_table --table=posts
```

Open the generated migration file:

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
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->dropSoftDeletes();
        });
    }
};
```

The `$table->softDeletes()` method adds a nullable `deleted_at` timestamp column. When this column is `null`, the record is active. When it contains a timestamp, the record is considered deleted.

Run the migration:

```bash
php artisan migrate
```


## Step 2: Update the Post Model {#step-2-update-model}

Open `app/Models/Post.php` and add the `SoftDeletes` trait:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['title', 'slug', 'content', 'status', 'user_id'])]
class Post extends Model
{
    use HasFactory, SoftDeletes;

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

With this single trait added, several things change automatically:

- Calling `$post->delete()` now sets `deleted_at` to the current timestamp instead of removing the row.
- All Eloquent queries (`Post::all()`, `Post::where(...)`, `Post::paginate()`) automatically exclude records where `deleted_at` is not null.
- Three new query scopes become available: `Post::withTrashed()` includes both active and soft-deleted records, `Post::onlyTrashed()` returns only soft-deleted records, and `Post::withoutTrashed()` is the default behavior.
- `$post->restore()` sets `deleted_at` back to `null`, making the record active again.
- `$post->forceDelete()` permanently removes the row from the database, bypassing the soft delete mechanism.

Save the file.


## Step 3: Add Trash, Restore, and Force Delete to the Controller {#step-3-update-controller}

Open `app/Http/Controllers/PostController.php` and add three new methods:

```php
/**
 * Display a listing of trashed posts.
 */
public function trash()
{
    $posts = Post::onlyTrashed()->latest('deleted_at')->paginate(10);

    return view('posts.trash', compact('posts'));
}

/**
 * Restore a soft-deleted post.
 */
public function restore(int $id)
{
    $post = Post::onlyTrashed()->findOrFail($id);

    $post->restore();

    return redirect()->route('posts.trash')->with('success', 'Post restored successfully.');
}

/**
 * Permanently delete a soft-deleted post.
 */
public function forceDelete(int $id)
{
    $post = Post::onlyTrashed()->findOrFail($id);

    $post->forceDelete();

    return redirect()->route('posts.trash')->with('success', 'Post permanently deleted.');
}
```

**Why `int $id` instead of route model binding?** Laravel's route model binding excludes soft-deleted records by default. If you use `Post $post` in the method signature, Laravel will return a 404 for any soft-deleted post. By accepting `int $id` and manually querying with `Post::onlyTrashed()->findOrFail($id)`, we can find the trashed record.

**`Post::onlyTrashed()`** returns only records where `deleted_at` is not null. This is the inverse of the default behavior and is exactly what we need for the trash page, restore, and force delete.

Save the file.


## Step 4: Create the Trash View {#step-4-create-trash-view}

Create `resources/views/posts/trash.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trash</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-7xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-3xl font-bold text-gray-900">Trash</h1>
            <a href="{{ route('posts.index') }}" class="text-gray-600 hover:text-gray-900 underline text-sm transition">Back to Posts</a>
        </div>

        @if(session('success'))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative mb-6">
                {{ session('success') }}
            </div>
        @endif

        <div class="overflow-x-auto">
            <table class="min-w-full bg-white border border-gray-200 shadow-sm rounded-lg overflow-hidden">
                <thead class="bg-gray-50 border-b border-gray-200">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Title</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Deleted At</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                    @forelse($posts as $post)
                    <tr class="hover:bg-gray-50 transition duration-150">
                        <td class="px-6 py-4 text-sm font-medium text-gray-900">{{ $post->title }}</td>
                        <td class="px-6 py-4 text-sm text-gray-500">{{ $post->deleted_at->diffForHumans() }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                            <form action="{{ route('posts.restore', $post->id) }}" method="POST" class="inline">
                                @csrf
                                @method('PATCH')
                                <button type="submit" class="inline-flex items-center px-3 py-1.5 bg-green-600 rounded-md text-xs text-white uppercase hover:bg-green-700 transition shadow-sm">Restore</button>
                            </form>
                            <form action="{{ route('posts.force-delete', $post->id) }}" method="POST" class="inline" onsubmit="return confirm('This action is permanent and cannot be undone. Are you sure?')">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="inline-flex items-center px-3 py-1.5 bg-red-600 rounded-md text-xs text-white uppercase hover:bg-red-700 transition shadow-sm">Delete Permanently</button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="3" class="px-6 py-4 text-center text-sm text-gray-500">Trash is empty.</td>
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
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
            target="_blank">Tutorial CRUD Laravel 13 at qadrlabs.com</a>
    </div>
</body>

</html>
```

The `$post->deleted_at->diffForHumans()` call displays timestamps in a readable format like "2 hours ago" or "3 days ago". The permanent delete button has an extra `confirm()` dialog because this action cannot be undone.

Save the file.

### Add a Trash Link to the Index Page

Open `resources/views/posts/index.blade.php` and add a link to the trash page near the "Create New Post" button:

```html
<a href="{{ route('posts.trash') }}" class="text-gray-600 hover:text-gray-900 underline text-sm transition">
    View Trash
</a>
```

Save the file.


## Step 5: Register the Routes {#step-5-register-routes}

Open `routes/web.php` and add the soft delete routes. These custom routes must be defined **before** `Route::resource('posts', ...)` to avoid being caught by the `posts/{post}` show route:

```php
// Soft delete routes (before resource to avoid route conflicts)
Route::get('/posts/trash', [PostController::class, 'trash'])->name('posts.trash');
Route::patch('/posts/{id}/restore', [PostController::class, 'restore'])->name('posts.restore');
Route::delete('/posts/{id}/force-delete', [PostController::class, 'forceDelete'])->name('posts.force-delete');

// Resource routes
Route::resource('posts', PostController::class);
```

If you place `/posts/trash` after `Route::resource()`, Laravel will try to find a post with the slug "trash" and return a 404.

Save the file.


## Step 6: Update Existing Tests {#step-6-update-existing-tests}

Adding soft deletes changes how deletion works, so existing tests that verify deletion behavior need to be updated. The post is no longer removed from the database; it is soft-deleted. Two tests need to change: `a post can be deleted` and `post owner can delete their own post`.

Open `tests/Feature/PostControllerTest.php` and find the `a post can be deleted` test. It currently uses `assertDatabaseMissing`:

```php
test('a post can be deleted', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user)->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post deleted successfully.');

    $this->assertDatabaseMissing('posts', [
        'id' => $post->id,
    ]);
});
```

Replace `assertDatabaseMissing` with `assertSoftDeleted`:

```php
test('a post can be deleted', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user)->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post deleted successfully.');

    $this->assertSoftDeleted('posts', [
        'id' => $post->id,
    ]);
});
```

Next, find the `post owner can delete their own post` test and apply the same change:

```php
test('post owner can delete their own post', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);

    $response = $this->actingAs($this->user)->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('posts.index'));
    $this->assertSoftDeleted('posts', ['id' => $post->id]);
});
```

`assertSoftDeleted()` verifies that the record exists in the database AND has a non-null `deleted_at` value. This is exactly what we want: the row is still there, but it is marked as deleted.

Save the file.


## Step 7: Write New Tests {#step-7-write-new-tests}

Add the following tests to `tests/Feature/PostControllerTest.php`:

```php
// ============================================================
// Soft Delete Tests
// ============================================================

test('soft deleted posts do not appear in the main listing', function () {
    $activePost = Post::factory()->create(['user_id' => $this->user->id, 'title' => 'Active Post']);
    $deletedPost = Post::factory()->create(['user_id' => $this->user->id, 'title' => 'Deleted Post']);

    $deletedPost->delete();

    $response = $this->actingAs($this->user)->get(route('posts.index'));

    $response->assertSee('Active Post');
    $response->assertDontSee('Deleted Post');
});

test('trash page shows only soft deleted posts', function () {
    $activePost = Post::factory()->create(['user_id' => $this->user->id, 'title' => 'Active Post']);
    $deletedPost = Post::factory()->create(['user_id' => $this->user->id, 'title' => 'Deleted Post']);

    $deletedPost->delete();

    $response = $this->actingAs($this->user)->get(route('posts.trash'));

    $response->assertStatus(200);
    $response->assertSee('Deleted Post');
    $response->assertDontSee('Active Post');
});

test('a soft deleted post can be restored', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);
    $post->delete();

    $this->assertSoftDeleted('posts', ['id' => $post->id]);

    $response = $this->actingAs($this->user)->patch(route('posts.restore', $post->id));

    $response->assertRedirect(route('posts.trash'));

    $post->refresh();
    $this->assertNull($post->deleted_at);
});

test('a soft deleted post can be permanently deleted', function () {
    $post = Post::factory()->create(['user_id' => $this->user->id]);
    $post->delete();

    $response = $this->actingAs($this->user)->delete(route('posts.force-delete', $post->id));

    $response->assertRedirect(route('posts.trash'));
    $this->assertDatabaseMissing('posts', ['id' => $post->id]);
});

test('trash page shows empty state when no posts are trashed', function () {
    $response = $this->actingAs($this->user)->get(route('posts.trash'));

    $response->assertStatus(200);
    $response->assertSee('Trash is empty.');
});
```

The tests verify five behaviors: soft-deleted posts are hidden from the main listing, the trash page shows only trashed posts, restore works and clears `deleted_at`, force delete permanently removes the record, and the trash page shows an empty state when there are no trashed posts.

Note the use of `assertDatabaseMissing` in the force delete test. Unlike the regular delete test (which uses `assertSoftDeleted`), force delete truly removes the row, so `assertDatabaseMissing` is correct here.

Save the file.


## Step 8: Run the Tests {#step-8-run-tests}

```bash
php artisan test
```

All tests should pass, including both the updated existing tests and the 5 new soft delete tests.


## Step 9: Try It Out {#step-9-try-it-out}

Start the development server:

```bash
php artisan serve
```

### Test the Soft Delete Flow

1. Create a new post.
2. Click **Delete** on the post from the index page. The post disappears from the listing.
3. Click **View Trash**. The deleted post should appear with its title and "Deleted At" timestamp.
4. Click **Restore**. The post should reappear on the main listing page.
5. Delete the post again, go to trash, and click **Delete Permanently**. A confirmation dialog appears. Click OK. The post is gone from both the listing and the trash.


## How Soft Deletes Work Under the Hood {#how-soft-deletes-work}

When you add the `SoftDeletes` trait to a model, Laravel modifies three core behaviors:

**Default queries add a global scope.** Every Eloquent query automatically appends `WHERE deleted_at IS NULL`. This means `Post::all()`, `Post::where(...)`, and `Post::paginate()` all exclude soft-deleted records without you writing any extra conditions.

**`delete()` becomes an update.** Instead of running `DELETE FROM posts WHERE id = ?`, Laravel runs `UPDATE posts SET deleted_at = '2026-04-03 10:00:00' WHERE id = ?`. The row stays in the database.

**`forceDelete()` permanently removes the row.** This bypasses the soft delete mechanism and runs a real `DELETE` statement. Use it only when you are certain the record should never be recoverable.


## Conclusion {#conclusion}

In this tutorial, we added soft delete functionality to our blog application. Posts are no longer permanently removed when deleted. Instead, they are marked with a `deleted_at` timestamp and hidden from normal queries.

Here are the key takeaways:

- **Soft deletes are a one-trait solution.** Adding `use SoftDeletes` and a `deleted_at` column is all you need. All existing queries automatically exclude soft-deleted records without code changes.
- **Existing delete tests need updating.** Replace `assertDatabaseMissing` with `assertSoftDeleted` for regular delete actions. Keep `assertDatabaseMissing` only for force delete tests.
- **Route custom actions before `Route::resource()`.** Custom routes like `/posts/trash` must be defined before the resource routes, or they will be caught by the `{post}` parameter and return 404.
- **Use `onlyTrashed()` and `findOrFail()` for trashed records.** Route model binding does not work with soft-deleted records by default. Query them manually with `Post::onlyTrashed()->findOrFail($id)`.
- **`assertSoftDeleted()` is the correct assertion for soft-deleted records.** It verifies that the record exists in the database AND has a non-null `deleted_at` value.
- **Soft deletes are reversible, force deletes are not.** Always confirm before force-deleting. Consider adding role-based access so only admins can permanently delete records.