---
title: "Laravel 13: Add Image Upload to Your Blog with Storage and Validation"
slug: "laravel-13-add-image-upload-to-your-blog-with-storage-and-validation"
category: "Laravel"
date: "2026-03-27"
status: "published"
---

Our blog has authentication, authorization, Form Request validation, and 36 passing tests. But every post is just text. A featured image makes posts more engaging, improves social media sharing, and gives the listing page a visual anchor.

In this tutorial, we will add image upload functionality to the blog. We will update the migration, add file validation rules to the Form Requests, handle uploads in the controller, display images in the views, and update the test suite to cover the new feature.

This is Part 5 of our Laravel 13 blog tutorial series (main branch), following the [CRUD tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step), the [testing tutorial](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application), the [Form Request refactoring tutorial](https://qadrlabs.com/post/laravel-13-refactor-your-controller-with-form-request-validation), and the [authentication and authorization tutorial](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes).


## Overview {#overview}

We will add a featured image field to posts. Users can upload an image when creating or editing a post, and the image will be displayed on the listing page and the detail page.

### What You'll Build

- A migration to add an `image` column to the posts table.
- Image validation rules (file type, max size) in the Form Requests.
- File upload handling in the controller using Laravel's Storage facade.
- Image display on the index, show, and edit pages.
- Old image cleanup when a post is updated or deleted.
- Updated Pest tests covering image upload, validation, and cleanup.

### What You'll Learn

- How to add file validation rules to Form Requests (`image`, `mimes`, `max`).
- How to store uploaded files using `storeAs()` and the `public` disk.
- How to create the storage symlink with `php artisan storage:link`.
- How to handle image replacement (delete old, store new) on update.
- How to clean up images when a post is deleted.
- How to test file uploads with `UploadedFile::fake()`.

### What You'll Need

- The completed blog project with authentication and authorization from the [previous tutorial](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes).
- PHP 8.3 or higher.
- The GD or Imagick PHP extension (for image validation).


## Step 1: Run the Tests Before Changes {#step-1-run-tests-before}

As always, confirm the baseline:

```
php artisan test
```

All 36 tests should pass.


## Step 2: Create the Storage Symlink {#step-2-storage-link}

Laravel stores uploaded files in the `storage/app/public` directory. For these files to be accessible from the browser, you need to create a symbolic link from `public/storage` to `storage/app/public`:

```
php artisan storage:link
```

```
$ php artisan storage:link

   INFO  The [public/storage] link has been connected to [storage/app/public].
```

This is a one-time setup. After running this command, any file stored in the `public` disk becomes accessible via URLs like `http://127.0.0.1:8000/storage/filename.jpg`.


## Step 3: Add the Image Column {#step-3-add-image-column}

Create a migration to add an `image` column to the posts table:

```
php artisan make:migration add_image_to_posts_table --table=posts
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
            $table->string('image')->nullable()->after('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->dropColumn('image');
        });
    }
};
```

The column is `string` because it stores the file path (e.g., `posts/abc123.jpg`), not the actual image data. It is `nullable()` because a featured image is optional. The `after('status')` places the column right after the `status` column for a clean table structure.

Run the migration:

```
php artisan migrate
```

### Update the Post Model

Open `app/Models/Post.php` and add `image` to the `#[Fillable]` attribute:

```php
#[Fillable(['title', 'slug', 'content', 'status', 'user_id', 'image'])]
```

Save the file.


## Step 4: Update the Form Requests {#step-4-update-form-requests}

This is where the file validation happens. Since we already have dedicated Form Request classes, we just need to add the image rules.

### Update StorePostRequest

Open `app/Http/Requests/StorePostRequest.php` and add the image rule:

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;

class StorePostRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        $this->merge([
            'slug' => Str::slug($this->title),
        ]);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'title' => 'required|max:255',
            'slug' => 'required|unique:posts,slug|max:255',
            'content' => 'required',
            'status' => 'required|in:draft,publish',
            'image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
        ];
    }
}
```

The image validation rule chain works as follows:

- `nullable` allows the field to be empty. A featured image is optional.
- `image` validates that the uploaded file is an image (checks MIME type against jpeg, png, bmp, gif, svg, or webp).
- `mimes:jpg,jpeg,png,webp` restricts the allowed file types to these four formats. This is stricter than the `image` rule alone, which also allows bmp, gif, and svg.
- `max:2048` limits the file size to 2048 kilobytes (2 MB). Adjust this based on your application's needs.

### Update UpdatePostRequest

Open `app/Http/Requests/UpdatePostRequest.php` and add the same image rule:

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;

class UpdatePostRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Prepare the data for validation.
     */
    protected function prepareForValidation(): void
    {
        $this->merge([
            'slug' => Str::slug($this->title),
        ]);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'title' => 'required|max:255',
            'slug' => 'required|unique:posts,slug,' . $this->route('post')->id . '|max:255',
            'content' => 'required',
            'status' => 'required|in:draft,publish',
            'image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
        ];
    }
}
```

The image rule is identical in both Form Requests because the validation requirements are the same for creating and updating.

Save both files.


## Step 5: Update the Controller {#step-5-update-controller}

Open `app/Http/Controllers/PostController.php` and update the `store()`, `update()`, and `destroy()` methods to handle image uploads:

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Models\Post;
use Illuminate\Routing\Attributes\Controllers\Middleware;
use Illuminate\Routing\Attributes\Controllers\Authorize;
use Illuminate\Support\Facades\Storage;

#[Middleware('auth')]
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

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return view('posts.create');
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StorePostRequest $request)
    {
        $data = $request->validated();

        if ($request->hasFile('image')) {
            $data['image'] = $request->file('image')->store('posts', 'public');
        }

        $request->user()->posts()->create($data);

        return redirect()->route('posts.index')->with('success', 'Post created successfully.');
    }

    /**
     * Display the specified resource.
     */
    public function show(Post $post)
    {
        return view('posts.show', compact('post'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    #[Authorize('update', 'post')]
    public function edit(Post $post)
    {
        return view('posts.edit', compact('post'));
    }

    /**
     * Update the specified resource in storage.
     */
    #[Authorize('update', 'post')]
    public function update(UpdatePostRequest $request, Post $post)
    {
        $data = $request->validated();

        if ($request->hasFile('image')) {
            // Delete old image if it exists
            if ($post->image) {
                Storage::disk('public')->delete($post->image);
            }

            $data['image'] = $request->file('image')->store('posts', 'public');
        }

        $post->update($data);

        return redirect()->route('posts.index')->with('success', 'Post updated successfully.');
    }

    /**
     * Remove the specified resource from storage.
     */
    #[Authorize('delete', 'post')]
    public function destroy(Post $post)
    {
        // Delete image file if it exists
        if ($post->image) {
            Storage::disk('public')->delete($post->image);
        }

        $post->delete();

        return redirect()->route('posts.index')->with('success', 'Post deleted successfully.');
    }
}
```

Let's examine the image handling in each method:

**store():** `$request->hasFile('image')` checks if a file was uploaded. `$request->file('image')->store('posts', 'public')` stores the file in `storage/app/public/posts/` with an auto-generated filename and returns the relative path (e.g., `posts/abc123def456.jpg`). This path is saved in the database.

**update():** Before storing the new image, we check if the post already has an image. If it does, `Storage::disk('public')->delete($post->image)` removes the old file from disk. Without this cleanup, old images would accumulate and waste disk space.

**destroy():** When a post is deleted, we also delete its image file. This prevents orphaned files.

The `Storage` facade is imported from `Illuminate\Support\Facades\Storage`. We specify the `'public'` disk explicitly in both `store()` and `delete()` to make the code clear about where files live.

Save the file.


## Step 6: Update the Views {#step-6-update-views}

### Update the Create Form

Open `resources/views/posts/create.blade.php`. Add `enctype="multipart/form-data"` to the `<form>` tag and add the image upload field.

Update the form tag:

```html
<form action="{{ route('posts.store') }}" method="POST" enctype="multipart/form-data" class="space-y-6">
```

The `enctype="multipart/form-data"` attribute is essential. Without it, the browser will not send the file data in the request. This is a common mistake that causes `$request->hasFile('image')` to always return `false`.

Add the image field after the title field:

```html
<div>
    <label class="block text-sm font-medium text-gray-700 mb-1">Featured Image</label>
    <input type="file" name="image" accept="image/jpeg,image/png,image/webp"
        class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition text-sm file:mr-4 file:py-1 file:px-3 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100">
    <p class="text-xs text-gray-500 mt-1">JPG, PNG, or WebP. Max 2 MB.</p>
</div>
```

The `accept` attribute filters the file picker dialog to show only the allowed image types. This is a client-side convenience; the actual validation happens server-side in the Form Request.

Save the file.

### Update the Edit Form

Open `resources/views/posts/edit.blade.php`. Add `enctype="multipart/form-data"` to the form tag and add the image field with a preview of the current image:

Update the form tag:

```html
<form action="{{ route('posts.update', $post) }}" method="POST" enctype="multipart/form-data" class="space-y-6">
```

Add the image field after the title field:

```html
<div>
    <label class="block text-sm font-medium text-gray-700 mb-1">Featured Image</label>
    @if($post->image)
        <div class="mb-3">
            <img src="{{ asset('storage/' . $post->image) }}" alt="{{ $post->title }}" class="w-48 h-32 object-cover rounded-md border border-gray-200">
            <p class="text-xs text-gray-500 mt-1">Current image. Upload a new one to replace it.</p>
        </div>
    @endif
    <input type="file" name="image" accept="image/jpeg,image/png,image/webp"
        class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition text-sm file:mr-4 file:py-1 file:px-3 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100">
    <p class="text-xs text-gray-500 mt-1">JPG, PNG, or WebP. Max 2 MB. Leave empty to keep the current image.</p>
</div>
```

The `@if($post->image)` block shows a thumbnail preview of the current image. `asset('storage/' . $post->image)` generates the full URL to the file via the storage symlink. The text below the preview tells the user they can leave the field empty to keep the existing image.

Save the file.

### Update the Index Page

Open `resources/views/posts/index.blade.php`. Add an image column to the table.

Add a new `<th>` in the table header after the "No" column:

```html
<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Image</th>
```

Add a corresponding `<td>` in the table body after the "No" cell:

```html
<td class="px-6 py-4 whitespace-nowrap">
    @if($post->image)
        <img src="{{ asset('storage/' . $post->image) }}" alt="{{ $post->title }}" class="w-16 h-12 object-cover rounded">
    @else
        <span class="text-xs text-gray-400">No image</span>
    @endif
</td>
```

Also update the `colspan` in the empty state row from `5` to `6` to match the new column count.

Save the file.

### Update the Show Page

Open `resources/views/posts/show.blade.php`. Add the featured image above the content.

Add the following block after the header section and before the content `<div>`:

```html
@if($post->image)
    <div class="mb-6">
        <img src="{{ asset('storage/' . $post->image) }}" alt="{{ $post->title }}" class="w-full max-h-96 object-cover rounded-lg">
    </div>
@endif
```

The image spans the full width of the content area with a max height of 384px (`max-h-96`). `object-cover` ensures the image fills the area without distortion.

Save the file.


## Step 7: Update the Post Factory {#step-7-update-factory}

Open `database/factories/PostFactory.php` and add the `image` field:

```php
<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Post>
 */
class PostFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $title = $this->faker->sentence();

        return [
            'title' => $title,
            'slug' => Str::slug($title),
            'content' => $this->faker->paragraphs(3, true),
            'status' => $this->faker->randomElement(['draft', 'publish']),
            'user_id' => User::factory(),
            'image' => null,
        ];
    }
}
```

The `image` field defaults to `null`. Tests that need an image will provide one explicitly using `UploadedFile::fake()`.

Save the file.


## Step 8: Update and Add Tests {#step-8-update-tests}

Open `tests/Feature/PostControllerTest.php`. We need to add the `Storage` and `UploadedFile` imports and write tests for image upload functionality.

Add these imports at the top of the file:

```php
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
```

### Add Image Upload Tests

Add the following tests at the end of the file (before the authentication and authorization tests, or at the very end):

```php
// ============================================================
// Image Upload Tests
// ============================================================

test('a post can be created with an image', function () {
    Storage::fake('public');

    $image = UploadedFile::fake()->image('featured.jpg', 800, 600)->size(1024);

    $response = $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => 'Post with Image',
        'content' => 'This post has a featured image.',
        'status' => 'publish',
        'image' => $image,
    ]);

    $response->assertRedirect(route('posts.index'));

    $post = Post::where('title', 'Post with Image')->first();

    $this->assertNotNull($post->image);
    Storage::disk('public')->assertExists($post->image);
});

test('a post can be created without an image', function () {
    $response = $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => 'Post without Image',
        'content' => 'This post has no featured image.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));

    $post = Post::where('title', 'Post without Image')->first();

    $this->assertNull($post->image);
});

test('image upload validates file type', function () {
    Storage::fake('public');

    $file = UploadedFile::fake()->create('document.pdf', 500, 'application/pdf');

    $response = $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => 'Post with PDF',
        'content' => 'This should fail.',
        'status' => 'publish',
        'image' => $file,
    ]);

    $response->assertSessionHasErrors(['image']);
});

test('image upload validates file size', function () {
    Storage::fake('public');

    $image = UploadedFile::fake()->image('huge.jpg', 800, 600)->size(3000);

    $response = $this->actingAs($this->user)->post(route('posts.store'), [
        'title' => 'Post with Huge Image',
        'content' => 'This should fail.',
        'status' => 'publish',
        'image' => $image,
    ]);

    $response->assertSessionHasErrors(['image']);
});

test('image is replaced when a new one is uploaded on update', function () {
    Storage::fake('public');

    // Create a post with an initial image
    $oldImage = UploadedFile::fake()->image('old.jpg', 800, 600);
    $oldPath = $oldImage->store('posts', 'public');

    $post = Post::factory()->create([
        'user_id' => $this->user->id,
        'image' => $oldPath,
    ]);

    Storage::disk('public')->assertExists($oldPath);

    // Update with a new image
    $newImage = UploadedFile::fake()->image('new.jpg', 800, 600);

    $response = $this->actingAs($this->user)->put(route('posts.update', $post), [
        'title' => $post->title,
        'content' => $post->content,
        'status' => $post->status,
        'image' => $newImage,
    ]);

    $response->assertRedirect(route('posts.index'));

    $post->refresh();

    // Old image should be deleted
    Storage::disk('public')->assertMissing($oldPath);

    // New image should exist
    Storage::disk('public')->assertExists($post->image);
    $this->assertNotEquals($oldPath, $post->image);
});

test('image is kept when no new image is uploaded on update', function () {
    Storage::fake('public');

    $image = UploadedFile::fake()->image('keep.jpg', 800, 600);
    $imagePath = $image->store('posts', 'public');

    $post = Post::factory()->create([
        'user_id' => $this->user->id,
        'image' => $imagePath,
    ]);

    $response = $this->actingAs($this->user)->put(route('posts.update', $post), [
        'title' => 'Updated Title Only',
        'content' => $post->content,
        'status' => $post->status,
    ]);

    $response->assertRedirect(route('posts.index'));

    $post->refresh();

    // Image should remain the same
    $this->assertEquals($imagePath, $post->image);
    Storage::disk('public')->assertExists($imagePath);
});

test('image is deleted when a post is deleted', function () {
    Storage::fake('public');

    $image = UploadedFile::fake()->image('delete-me.jpg', 800, 600);
    $imagePath = $image->store('posts', 'public');

    $post = Post::factory()->create([
        'user_id' => $this->user->id,
        'image' => $imagePath,
    ]);

    Storage::disk('public')->assertExists($imagePath);

    $response = $this->actingAs($this->user)->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('posts.index'));

    // Image file should be deleted from disk
    Storage::disk('public')->assertMissing($imagePath);

    // Post should be deleted from database
    $this->assertDatabaseMissing('posts', ['id' => $post->id]);
});
```

Let's walk through the key testing patterns:

**`Storage::fake('public')`** replaces the real `public` disk with a fake one that lives in memory. Files stored during the test never touch the real filesystem. This is essential for keeping tests isolated and fast.

**`UploadedFile::fake()->image('featured.jpg', 800, 600)->size(1024)`** creates a fake JPEG image that is 800x600 pixels and 1024 KB (1 MB). The `image()` method generates a real image file with valid headers, so the `image` validation rule passes.

**`UploadedFile::fake()->create('document.pdf', 500, 'application/pdf')`** creates a fake PDF file. We use this to test that non-image files are rejected by the validation.

**`Storage::disk('public')->assertExists($path)`** and **`assertMissing($path)`** verify that files exist or have been removed from the fake disk. These are provided by `Storage::fake()`.

**The replacement test** is the most complex. It creates a post with an initial image, then updates the post with a new image and verifies three things: the old image was deleted, the new image exists, and the paths are different.

**The preservation test** verifies that updating a post without uploading a new image keeps the existing image intact.

Save the file.


## Step 9: Run the Tests {#step-9-run-tests}

Run the complete test suite:

```
php artisan test
```

You should see all tests passing, including the 7 new image upload tests. The total should now be 43 tests (36 from the previous tutorial + 7 new image tests).

```
   PASS  Tests\Feature\PostControllerTest
  ...
  ✓ a post can be created with an image
  ✓ a post can be created without an image
  ✓ image upload validates file type
  ✓ image upload validates file size
  ✓ image is replaced when a new one is uploaded on update
  ✓ image is kept when no new image is uploaded on update
  ✓ image is deleted when a post is deleted
  ...

  Tests:    43 passed
```


## Step 10: Try It Out {#step-10-try-it-out}

Start the development server:

```
php artisan serve
```

Open `http://127.0.0.1:8000/posts` and log in.

### Test Creating a Post with an Image

Click **Create New Post**. Fill in the title, content, and status. Click the file input to select an image (JPG, PNG, or WebP under 2 MB). Submit the form. You should be redirected to the listing page, and the post should appear with a thumbnail of the uploaded image.

### Test Viewing the Image

Click **View** on the post. The featured image should appear at full width above the content.

### Test Editing with Image Replacement

Click **Edit** on the post. You should see a thumbnail preview of the current image. Upload a new image and save. The old image should be replaced.

### Test Editing without Changing the Image

Edit the same post again but only change the title. Do not upload a new image. Save. The existing image should remain unchanged.

### Test Deleting a Post with an Image

Delete a post that has an image. The post and its image file should both be removed.

### Test Validation

Try uploading a PDF file or an image larger than 2 MB. You should see validation error messages.


## Conclusion {#conclusion}

In this tutorial, we added featured image upload functionality to our Laravel 13 blog. We created a migration for the image column, added file validation rules to the existing Form Requests, handled uploads and cleanup in the controller, updated all views to display images, and wrote 7 new tests to cover the feature.

Here are the key takeaways:

- **`enctype="multipart/form-data"` is required on the form tag.** Without it, file uploads silently fail. This is one of the most common mistakes when adding file upload to an existing form.
- **Store file paths, not file contents.** The `image` column holds a relative path like `posts/abc123.jpg`. The `store()` method saves the file to disk and returns this path. Use `asset('storage/' . $post->image)` to generate the URL for display.
- **Clean up old files on update and delete.** Always delete the previous image before storing a new one on update. Always delete the image when deleting the post. Without cleanup, orphaned files accumulate on disk.
- **File validation goes in the Form Request.** The `image|mimes:jpg,jpeg,png,webp|max:2048` rule chain handles type and size validation in the same place as the rest of your validation rules. No separate logic needed.
- **`Storage::fake()` makes file upload tests clean.** The fake disk keeps tests isolated from the real filesystem. `assertExists()` and `assertMissing()` verify file operations without touching actual storage.
- **`UploadedFile::fake()->image()` generates valid test images.** It creates real image files with correct MIME types and headers, so validation rules behave the same as in production.
- **The test suite grew from 36 to 43 tests.** Each new feature comes with tests. The image upload, validation, replacement, preservation, and cleanup are all verified automatically.

From here, you could add image resizing using Intervention Image, implement drag-and-drop uploads, generate thumbnails for the listing page, or add multiple image support per post.