## 1. Before You Begin

Journal entries become more expressive with images. A vacation entry is more vivid with a photo from the beach. A recipe note is clearer with a picture of the finished dish. Laravel's `Storage` facade provides a clean, unified API for storing files on local disk or cloud services like Amazon S3, using the same code for both.

This lesson teaches you to handle file uploads in Laravel: validating file types and sizes, storing files on disk, displaying uploaded images in views, and cleaning up old files during updates. You will add a cover image feature to Catatku entries, and along the way you will learn why the storage symlink exists and how to avoid the common trap of orphaned files.

### What You'll Build

You will add an optional cover image to each journal entry. Users can upload an image when creating or editing an entry, and the image displays at the top of the entry detail page.

### What You'll Learn

- ✅ Handling file uploads with `$request->file()`
- ✅ Validating files: `image`, `mimes`, `max`, `dimensions`
- ✅ Storing files: `store()` and the public disk
- ✅ Creating the storage symbolic link
- ✅ Displaying uploaded images with `asset('storage/...')`
- ✅ Deleting old files during updates

### What You'll Need

- Lesson 6 completed

---

## 2. Setup: Storage Link and Migration

Before uploading files, you need two things: a symbolic link so browsers can access stored files, and a database column to store the file path. Without the symbolic link, your files would be saved correctly but unreachable via URL.

### Step 1: Create the Symbolic Link

Laravel stores uploaded files in `storage/app/public/`, which is not directly accessible from the browser. The symbolic link creates a shortcut from `public/storage` to `storage/app/public/`, so a file at `storage/app/public/avatars/foo.jpg` becomes accessible at `http://yoursite.com/storage/avatars/foo.jpg`.

```bash
php artisan storage:link
```

You should see: "The [public/storage] link has been connected to [storage/app/public]." This command only needs to run once per environment (local, staging, production). You do not need to re-run it on every deployment unless the symlink was manually removed.

### Step 2: Add the Cover Image Column

Generate a migration to add the cover image path column to the entries table.

```bash
php artisan make:migration add_cover_image_to_entries --table=entries
```

The `--table=entries` flag produces a migration skeleton that modifies the existing `entries` table instead of creating a new one. Open the migration file and add the column definition.

```php
public function up(): void
{
    Schema::table('entries', function (Blueprint $table) {
        $table->string('cover_image')->nullable()->after('content');
    });
}

public function down(): void
{
    Schema::table('entries', function (Blueprint $table) {
        $table->dropColumn('cover_image');
    });
}
```

Let us look at each part. `Schema::table('entries', ...)` opens the existing entries table for modification. `$table->string('cover_image')` creates a VARCHAR column to hold the file path (not the file itself; the file lives on disk, not in the database). `->nullable()` makes the column optional, which is important because cover images are not required for an entry. `->after('content')` places the column after the content column for readability when you inspect the database schema. The `down()` method uses `$table->dropColumn('cover_image')` to reverse the change if needed. Run the migration to apply the change.

```bash
php artisan migrate
```

### Step 3: Update the Entry Model

Open `app/Models/Entry.php` and add `'cover_image'` to the `#[Fillable]` attribute at the top of the class.

```php
<?php
// ... others lines of code

#[Fillable(['title', 'content', 'cover_image'])]
class Entry extends Model
{
    // ... other methods and properties
}
```

Without adding `cover_image` to `#[Fillable]`, the `create()` and `update()` methods would silently ignore the field, and the image path would never be saved to the database. This would cause a frustrating bug where uploads appear to "work" (the file ends up on disk) but the entry has no reference to it.

---

## 3. Handle the Upload in the Controller

File upload handling has three parts: validation, storage, and path saving. The controller manages all three in sequence.

### Step 1: Update the Store Method

Open `app/Http/Controllers/EntryController.php` and update the `store` method. Add the `Storage` import to the top of the file alongside the existing `use` statements, then replace the `store` method body as shown below.

```php
<?php
// ... others lines of code
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class EntryController extends Controller
{
    // ... other methods

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'cover_image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        if ($request->hasFile('cover_image')) {
            $validated['cover_image'] = $request->file('cover_image')
                ->store('entries/covers', 'public');
        }

        $entry = $request->user()->entries()->create([
            'title' => $validated['title'],
            'content' => $validated['content'],
            'cover_image' => $validated['cover_image'] ?? null,
        ]);

        $entry->tags()->sync($validated['tags'] ?? []);

        return redirect()->route('entries.index')->with('success', 'Entry created!');
    }

    // ... other methods
}
```

Walking through this method piece by piece: the `use Illuminate\Support\Facades\Storage;` import allows us to reference the Storage facade for file deletion in later methods. The validation array includes a new rule for `cover_image`: `nullable` makes it optional, `image` confirms the uploaded file is an image based on its contents rather than just the extension, `mimes:jpg,jpeg,png,webp` restricts to four common image formats, and `max:2048` caps the file at 2048 kilobytes (2 MB).

The `if ($request->hasFile('cover_image'))` check returns true only when an actual file was uploaded; it returns false when the user submits the form without selecting a file. Inside, `$request->file('cover_image')->store('entries/covers', 'public')` does three things: it generates a unique filename (UUID-based) to prevent collisions, saves the file to `storage/app/public/entries/covers/`, and returns the relative path like `entries/covers/abc123.jpg`. We assign this returned path to `$validated['cover_image']` so it ends up in the database. When creating the entry, `$validated['cover_image'] ?? null` uses the uploaded path if available or null otherwise.

### Step 2: Update the Update Method

The update method needs additional logic to delete the old image when a new one is uploaded. Without this cleanup, storage fills up with orphaned files that nothing references. Still in `app/Http/Controllers/EntryController.php`, add the `Gate` facade import to the existing `use` statements at the top, then update the `update` method as shown below.

```php
<?php
// ... others lines of code
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;

class EntryController extends Controller
{
    // ... other methods

    public function update(Request $request, Entry $entry)
    {
        Gate::authorize('update', $entry);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'cover_image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        if ($request->hasFile('cover_image')) {
            if ($entry->cover_image) {
                Storage::disk('public')->delete($entry->cover_image);
            }
            $validated['cover_image'] = $request->file('cover_image')
                ->store('entries/covers', 'public');
        }

        $entry->update([
            'title' => $validated['title'],
            'content' => $validated['content'],
            'cover_image' => $validated['cover_image'] ?? $entry->cover_image,
        ]);

        $entry->tags()->sync($validated['tags'] ?? []);

        return redirect()->route('entries.index')->with('success', 'Entry updated!');
    }

    // ... other methods
}
```

Reading through this update method carefully: the method starts like other update methods, with authorization and validation. The outer `if ($request->hasFile('cover_image'))` only runs when a new image is actually uploaded. Inside that block, the nested `if ($entry->cover_image)` checks whether an old image path exists in the database. If so, `Storage::disk('public')->delete($entry->cover_image)` deletes the old file from disk to prevent accumulation of orphaned files. Then we store the new file using the same pattern as the store method.

The `$entry->update(...)` call uses `$validated['cover_image'] ?? $entry->cover_image` as the value: if the user uploaded a new image, use that new path; if not, keep the existing path. This ensures that editing an entry without uploading a new image does not blank out the existing cover image.

---

## 4. Update the Views

The create and edit forms both need a file input and the `enctype` attribute, and the show view needs to display the uploaded image. Each is a separate file that needs updating.

### Step 1: Add File Input to the Create Form

Open `resources/views/entries/create.blade.php` and make two changes: add `enctype="multipart/form-data"` to the form tag, and add a cover image section below the content textarea and above the tags section.

The `enctype="multipart/form-data"` attribute on the `<form>` tag is critical and easy to forget. Without it, the browser sends the form as URL-encoded text, and `$request->file()` returns null because the file data never reaches the server. The `<input type="file" name="cover_image">` creates the file picker button. The `accept="image/*"` attribute shows only image files in the OS file picker dialog as a convenience hint, but this is not security — server-side validation is the actual enforcement. The `@error('cover_image')` block displays validation error messages specific to this field.

After the change, the full `create.blade.php` looks like this:

```blade
<x-layout title="Write Entry — Catatku">

    <div class="mb-6">
        <a href="{{ route('entries.index') }}" class="text-sm text-gray-400 hover:text-gray-700">
            ← Back to list
        </a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Write New Entry</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="{{ route('entries.store') }}" enctype="multipart/form-data">
            @csrf

            {{-- Title --}}
            <div class="mb-5">
                <label for="title" class="block text-sm font-medium text-gray-700 mb-1">
                    Title
                </label>
                <input type="text" id="title" name="title" value="{{ old('title') }}" placeholder="Entry title..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent
                           {{ $errors->has('title') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}" autofocus>
                @error('title')
                <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Content --}}
            <div class="mb-6">
                <label for="content" class="block text-sm font-medium text-gray-700 mb-1">
                    Content
                </label>
                <textarea id="content" name="content" rows="12" placeholder="Write your entry here..."
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y
                           {{ $errors->has('content') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}">{{ old('content') }}</textarea>
                @error('content')
                <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Cover image --}}
            <div style="margin-bottom: 16px;">
                <label style="display: block; font-weight: bold; margin-bottom: 6px; color: #1e293b;">
                    Cover Image (optional)
                </label>
                <input type="file" name="cover_image" accept="image/*"
                       style="border: 1px solid #d1d5db; border-radius: 6px; padding: 8px; width: 100%; box-sizing: border-box;">
                <p style="color: #9ca3af; font-size: 0.8em; margin-top: 4px;">
                    JPG, PNG, or WebP. Max 2MB.
                </p>
                @error('cover_image')
                    <p style="color: #dc2626; font-size: 0.85em; margin-top: 4px;">{{ $message }}</p>
                @enderror
            </div>

            {{-- Tags --}}
            <div style="margin-bottom: 16px;">
                <label style="display: block; font-weight: bold; margin-bottom: 6px; color: #1e293b;">Tags</label>
                <div style="display: flex; flex-wrap: wrap; gap: 10px;">
                    @foreach ($tags as $tag)
                        <label style="display: flex; align-items: center; gap: 4px; cursor: pointer;">
                            <input
                                type="checkbox"
                                name="tags[]"
                                value="{{ $tag->id }}"
                                @checked(is_array(old('tags')) && in_array($tag->id, old('tags')))
                            >
                            {{ $tag->name }}
                        </label>
                    @endforeach
                </div>
            </div>

            {{-- Buttons --}}
            <div class="flex items-center justify-between">
                <a href="{{ route('entries.index') }}" class="text-sm text-gray-500 hover:text-gray-900">
                    Cancel
                </a>
                <button type="submit" class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg
                           hover:bg-gray-700 transition-colors">
                    Save Entry
                </button>
            </div>

        </form>
    </div>

</x-layout>
```

### Step 2: Add File Input to the Edit Form

Open `resources/views/entries/edit.blade.php` and make three changes: add `enctype="multipart/form-data"` to the form tag, add a block that displays the current cover image (if any) with a remove checkbox, and add a file input for uploading a new image. Place the cover image section below the content textarea and above the tags section.

The edit form differs from the create form in two ways. First, it shows the existing cover image so the user can see what is currently saved. Second, it gives the user the option to remove the image without replacing it, using a simple checkbox. The file input itself works identically to the create form: leaving it empty means "keep the existing image," which the `$validated['cover_image'] ?? $entry->cover_image` fallback in the update method already handles.

After the change, the full `edit.blade.php` looks like this:

```blade
<x-layout :title="'Edit: ' . $entry->title . ' — Catatku'">

    <div class="mb-6">
        <a href="{{ route('entries.show', $entry) }}" class="text-sm text-gray-400 hover:text-gray-700">
            ← Back to entry
        </a>
    </div>

    <h2 class="text-lg font-semibold text-gray-900 mb-4">Edit Entry</h2>

    <div class="bg-white rounded-xl border border-gray-200 p-6">
        <form method="POST" action="{{ route('entries.update', $entry) }}" enctype="multipart/form-data">
            @csrf
            @method('PUT')

            {{-- Title --}}
            <div class="mb-5">
                <label for="title" class="block text-sm font-medium text-gray-700 mb-1">
                    Title
                </label>
                <input type="text" id="title" name="title" value="{{ old('title', $entry->title) }}"
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent
                           {{ $errors->has('title') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}" autofocus>
                @error('title')
                <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Content --}}
            <div class="mb-6">
                <label for="content" class="block text-sm font-medium text-gray-700 mb-1">
                    Content
                </label>
                <textarea id="content" name="content" rows="12"
                    class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none
                           focus:ring-2 focus:ring-gray-900 focus:border-transparent resize-y
                           {{ $errors->has('content') ? 'border-red-400 bg-red-50' : 'border-gray-300' }}">{{ old('content', $entry->content) }}</textarea>
                @error('content')
                <p class="text-xs text-red-500 mt-1">{{ $message }}</p>
                @enderror
            </div>

            {{-- Cover image --}}
            <div style="margin-bottom: 16px;">
                <label style="display: block; font-weight: bold; margin-bottom: 6px; color: #1e293b;">
                    Cover Image (optional)
                </label>
                @if($entry->cover_image)
                    <img src="{{ asset('storage/' . $entry->cover_image) }}"
                         alt="{{ $entry->title }}"
                         style="max-width: 100%; height: 120px; object-fit: cover; border-radius: 6px; margin-bottom: 8px;">
                    <label style="display: flex; align-items: center; gap: 6px; color: #dc2626; font-size: 0.9em; cursor: pointer; margin-bottom: 8px;">
                        <input type="checkbox" name="remove_image" value="1">
                        Remove current image
                    </label>
                @endif
                <input type="file" name="cover_image" accept="image/*"
                       style="border: 1px solid #d1d5db; border-radius: 6px; padding: 8px; width: 100%; box-sizing: border-box;">
                <p style="color: #9ca3af; font-size: 0.8em; margin-top: 4px;">
                    JPG, PNG, or WebP. Max 2MB. Leave empty to keep the current image.
                </p>
                @error('cover_image')
                    <p style="color: #dc2626; font-size: 0.85em; margin-top: 4px;">{{ $message }}</p>
                @enderror
            </div>

            {{-- Tags --}}
            <div style="margin-bottom: 16px;">
                <label style="display: block; font-weight: bold; margin-bottom: 6px; color: #1e293b;">Tags</label>
                <div style="display: flex; flex-wrap: wrap; gap: 10px;">
                    @foreach ($tags as $tag)
                        <label style="display: flex; align-items: center; gap: 4px; cursor: pointer;">
                            <input
                                type="checkbox"
                                name="tags[]"
                                value="{{ $tag->id }}"
                                @checked(
                                    (is_array(old('tags')) && in_array($tag->id, old('tags')))
                                    || (!old('tags') && $entry->tags->contains($tag->id))
                                )
                            >
                            {{ $tag->name }}
                        </label>
                    @endforeach
                </div>
            </div>

            {{-- Buttons --}}
            <div class="flex items-center justify-between">
                <a href="{{ route('entries.show', $entry) }}" class="text-sm text-gray-500 hover:text-gray-900">
                    Cancel
                </a>
                <button type="submit" class="bg-gray-900 text-white text-sm px-5 py-2 rounded-lg
                           hover:bg-gray-700 transition-colors">
                    Save Changes
                </button>
            </div>

        </form>
    </div>

</x-layout>
```

### Step 3: Display the Image in the Show View

Open `resources/views/entries/show.blade.php` and add the image display block at the very top of the `<div>` container, above the entry title.

The `@if($entry->cover_image)` check ensures we only render the image tag when the entry has one, avoiding a broken image icon when there is no cover. The `asset('storage/' . $entry->cover_image)` helper generates the full public URL to the image. The `storage/` prefix maps to the `public/storage` symbolic link, which points to `storage/app/public/`, so a stored path like `entries/covers/abc.jpg` becomes `http://yoursite.com/storage/entries/covers/abc.jpg`. The `alt` attribute uses the entry title for screen reader accessibility. The `object-fit: cover` CSS property crops the image proportionally so it fills the frame at the maximum height without distortion.

After the change, the full `show.blade.php` looks like this:

```blade
<x-layout>
    <div style="max-width: 700px; margin: 0 auto;">

        @if($entry->cover_image)
            <img src="{{ asset('storage/' . $entry->cover_image) }}"
                 alt="{{ $entry->title }}"
                 style="width: 100%; max-height: 300px; object-fit: cover; border-radius: 8px; margin-bottom: 16px;">
        @endif

        {{-- Entry content --}}
        <h1 style="font-size: 1.5em; color: #1e293b; margin-bottom: 8px;">{{ $entry->title }}</h1>
        <p style="color: #888; font-size: 0.85em; margin-bottom: 16px;">
            Written {{ $entry->created_at->diffForHumans() }}
        </p>
        <div style="line-height: 1.7; color: #333; margin-bottom: 30px;">
            {{ $entry->content }}
        </div>

        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 20px 0;">

        {{-- Comments section --}}
        <h2 style="font-size: 1.2em; color: #1e293b; margin-bottom: 16px;">
            Comments ({{ $entry->comments->count() }})
        </h2>

        @forelse ($entry->comments as $comment)
            <div style="padding: 12px 0; border-bottom: 1px solid #f3f4f6;">
                <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
                    <strong style="color: #1e293b;">{{ $comment->user->name }}</strong>
                    <span style="color: #9ca3af; font-size: 0.8em;">{{ $comment->created_at->diffForHumans() }}</span>
                </div>
                <p style="color: #4b5563; margin: 0;">{{ $comment->body }}</p>
            </div>
        @empty
            <p style="color: #9ca3af; text-align: center; padding: 20px 0;">
                No comments yet. Be the first to comment!
            </p>
        @endforelse

        {{-- Comment form --}}
        <div style="margin-top: 20px; background: #f9fafb; padding: 16px; border-radius: 8px;">
            <h3 style="font-size: 1em; margin-bottom: 10px; color: #1e293b;">Write a Comment</h3>

            <form method="POST" action="{{ route('comments.store', $entry) }}">
                @csrf

                <textarea
                    name="body"
                    rows="3"
                    placeholder="Write your comment..."
                    style="width: 100%; padding: 10px; border: 1px solid #d1d5db; border-radius: 6px; resize: vertical; box-sizing: border-box; font-family: inherit;"
                >{{ old('body') }}</textarea>

                @error('body')
                    <p style="color: #dc2626; font-size: 0.85em; margin: 4px 0 0;">{{ $message }}</p>
                @enderror

                <button
                    type="submit"
                    style="margin-top: 10px; background: #2563eb; color: white; padding: 8px 20px; border: none; border-radius: 6px; cursor: pointer; font-weight: bold;"
                >
                    Post Comment
                </button>
            </form>
        </div>

        <a href="{{ route('entries.index') }}" style="display: inline-block; margin-top: 20px; color: #2563eb; text-decoration: none;">
            &larr; Back to entries
        </a>
    </div>
</x-layout>
```

---

## 5. Run and Test

Let us verify the complete upload flow works end to end in the browser.

### Step 1: Start the Server

Run the development server and keep it running throughout your testing.

```bash
php artisan serve
```

### Step 2: Create an Entry with a Cover Image

Open `http://localhost:8000` and log in. Navigate to the create entry page. Fill in the title and content as usual. Click the file input and select a JPG or PNG image under 2 MB. Submit the form. You should be redirected to the entries list with a success message.

### Step 3: View the Entry

Click on the entry you just created. The cover image should appear at the top of the entry, above the title, fitted to the frame. If the image does not appear, check that you ran `php artisan storage:link` and that the `storage/app/public/entries/covers/` directory contains the uploaded file. You can inspect the HTML source to see the generated URL; it should look like `http://localhost:8000/storage/entries/covers/xxx.jpg`.

### Step 4: Test Validation

Try uploading a file that is not an image, such as a PDF. You should see a validation error: "The cover image field must be an image." Try uploading an image larger than 2 MB. You should see: "The cover image field must not be greater than 2048 kilobytes." These messages confirm the validation rules fire correctly.

### Step 5: Test Update with New Image

Edit the entry and upload a different image. After saving, the detail page should show the new image. Check the `storage/app/public/entries/covers/` directory: the old image file should be deleted and only the new one should remain.

### Step 6: Test Update Without Uploading a New Image

Edit the entry, change only the title or content, and submit without touching the file input. The existing cover image should still be present after saving, proving that the `?? $entry->cover_image` fallback in the update method works correctly.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes when implementing file uploads in Laravel.

**Error 1: Missing `enctype` on the form tag.**

This is the single most common file upload mistake. Without the `multipart/form-data` encoding type, the browser sends the form as URL-encoded text and omits the file data entirely. The server receives the request but the file is absent.

```blade
{{-- Wrong: no enctype, file data is never sent to the server --}}
<form method="POST" action="{{ route('entries.store') }}">

{{-- Correct: enctype tells the browser to include file data in the request --}}
<form method="POST" action="{{ route('entries.store') }}" enctype="multipart/form-data">
```

Without `enctype="multipart/form-data"`, `$request->hasFile('cover_image')` always returns false and `$request->file('cover_image')` returns null, even when the user selected a file. Adding `enctype="multipart/form-data"` to the opening `<form>` tag is the fix. This attribute is required on every form that includes a file input.

---

**Error 2: Storing on the wrong disk.**

This error occurs when you call `store()` without specifying the `public` disk. Laravel's default disk is `local`, which stores files in `storage/app/` - a private directory that is not accessible via URL. Files stored there cannot be displayed in a browser.

```php
// Wrong: stores in storage/app/entries/covers/ which is private
$request->file('cover_image')->store('entries/covers');

// Correct: stores in storage/app/public/entries/covers/ which is accessible via symlink
$request->file('cover_image')->store('entries/covers', 'public');
```

Without the second argument `'public'`, the file ends up in `storage/app/entries/covers/` and the URL generated by `asset('storage/...')` points to a file that does not exist in the public directory. Adding `'public'` as the second argument stores the file in `storage/app/public/entries/covers/`, which is accessible through the symbolic link at `public/storage`.

---

**Error 3: Files stored correctly but URLs return 404.**

This error occurs when you forgot to run `php artisan storage:link`. The files are stored on the correct disk, but the `public/storage` directory does not exist as a symbolic link, so every URL pointing to `storage/` returns a 404.

```bash
# Wrong: storage:link never run, public/storage directory does not exist
# Result: all image URLs return 404

# Correct: run this once per environment to create the symbolic link
php artisan storage:link
```

Without the symbolic link, requests to `http://yoursite.com/storage/entries/covers/abc.jpg` fail because the web server has no `storage` directory under `public/`. Running `php artisan storage:link` creates `public/storage` as a symlink pointing to `storage/app/public/`, making all files on the public disk accessible via URL. Run this command once when setting up a new environment.

---

## 7. Exercises

These exercises extend the file upload pattern to other parts of Catatku. Exercise 1 applies the same storage technique to a different model, Exercise 2 adds a removal flow for existing files, and Exercise 3 tightens validation with dimension constraints.

**Exercise 1:** Add an avatar upload to user profiles. Create a migration for the `avatar` column on users, add the upload handling to the profile controller, and display the avatar next to the user's name in comments.

**Exercise 2:** Add a "Remove image" checkbox to the edit form that deletes the cover image without uploading a new one. In the controller, check for the checkbox and call `Storage::disk('public')->delete()`.

**Exercise 3:** Add image dimension validation: `'cover_image' => 'nullable|image|dimensions:min_width=400,min_height=200|max:2048'`. Test with an image that is too small.

---

## 8. Solutions

Each solution below is a complete implementation. Solutions for Exercise 1 and 2 require multiple files, so follow the steps in order to ensure each piece is in place before the next one depends on it.

**Solution for Exercise 1:**

Create a migration to add the `avatar` column to the users table.

```bash
php artisan make:migration add_avatar_to_users --table=users
```

Open the migration file and define the column.

```php
public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('avatar')->nullable()->after('name');
    });
}

public function down(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn('avatar');
    });
}
```

`$table->string('avatar')->nullable()` stores the relative file path, not the image itself. Nullable is required because existing users have no avatar yet. Run `php artisan migrate` to apply the change. Next, create a `ProfileController` to handle avatar updates.

```bash
php artisan make:controller ProfileController
```

Open `app/Http/Controllers/ProfileController.php` and add the update method.

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    public function edit()
    {
        return view('profile.edit');
    }

    public function update(Request $request)
    {
        $request->validate([
            'avatar' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:1024',
        ]);

        $user = $request->user();

        if ($request->hasFile('avatar')) {
            if ($user->avatar) {
                Storage::disk('public')->delete($user->avatar);
            }
            $user->avatar = $request->file('avatar')->store('avatars', 'public');
            $user->save();
        }

        return back()->with('success', 'Avatar updated.');
    }
}
```

`$user->avatar` stores the path returned by `store('avatars', 'public')`. The nested `if ($user->avatar)` deletes the old file before saving a new one, following the same orphan-prevention pattern used in the entry update method. Register the routes inside the `auth` middleware group in `routes/web.php`.

```php
Route::get('/profile/edit', [ProfileController::class, 'edit'])->name('profile.edit');
Route::post('/profile', [ProfileController::class, 'update'])->name('profile.update');
```

To display the avatar next to each comment author's name, open the comment partial in `entries/show.blade.php` and add the image before the username.

```blade
@if($comment->user->avatar)
    <img src="{{ asset('storage/' . $comment->user->avatar) }}"
         alt="{{ $comment->user->name }}"
         style="width: 28px; height: 28px; border-radius: 50%; object-fit: cover;">
@endif
<strong style="color: #1e293b;">{{ $comment->user->name }}</strong>
```

The `border-radius: 50%` makes the image circular, which is the standard visual convention for user avatars. The `object-fit: cover` crops the image proportionally to fill the fixed 28x28 square. Note that `$comment->user` must be eager loaded in the controller with `$entry->load('comments.user')`, which is already in place from Lesson 1.

---

**Solution for Exercise 2:**

In the edit form, add the remove checkbox below the existing cover image display block.

```blade
@if($entry->cover_image)
    <img src="{{ asset('storage/' . $entry->cover_image) }}"
         alt="{{ $entry->title }}"
         style="max-width: 100%; height: 120px; object-fit: cover; border-radius: 6px; margin-bottom: 8px;">
    <label style="display: flex; align-items: center; gap: 6px; color: #dc2626; font-size: 0.9em; cursor: pointer;">
        <input type="checkbox" name="remove_image" value="1">
        Remove current image
    </label>
@endif
```

In `app/Http/Controllers/EntryController.php`, add the remove-image block inside the `update` method, before the existing `hasFile` check. The complete `update` method should look like this:

```php
<?php
// ... others lines of code
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;

class EntryController extends Controller
{
    // ... other methods

    public function update(Request $request, Entry $entry)
    {
        Gate::authorize('update', $entry);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'cover_image' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        if ($request->boolean('remove_image') && $entry->cover_image) {
            Storage::disk('public')->delete($entry->cover_image);
            $validated['cover_image'] = null;
        }

        if ($request->hasFile('cover_image')) {
            if ($entry->cover_image) {
                Storage::disk('public')->delete($entry->cover_image);
            }
            $validated['cover_image'] = $request->file('cover_image')
                ->store('entries/covers', 'public');
        }

        $entry->update([
            'title' => $validated['title'],
            'content' => $validated['content'],
            'cover_image' => $validated['cover_image'] ?? $entry->cover_image,
        ]);

        $entry->tags()->sync($validated['tags'] ?? []);

        return redirect()->route('entries.index')->with('success', 'Entry updated!');
    }

    // ... other methods
}
```

`$request->boolean('remove_image')` returns `true` if the checkbox was checked and submitted with the form. The nested `&& $entry->cover_image` guard ensures we only call delete when a file path actually exists in the database, avoiding a delete call on an empty path. `Storage::disk('public')->delete($entry->cover_image)` removes the physical file. Setting `$validated['cover_image'] = null` then causes the database update to clear the column. When the entry is subsequently updated, the `$validated['cover_image'] ?? $entry->cover_image` expression evaluates to `null`, removing the reference. Note that the `remove_image` block runs before the `hasFile` block: if the user somehow checks the remove box and also uploads a new file, the new upload takes precedence because `hasFile` runs second and overwrites `$validated['cover_image']`.

---

**Solution for Exercise 3:**

Open `app/Http/Controllers/EntryController.php` and update the `cover_image` validation rule in both the `store` and `update` methods to include the `dimensions` constraint. The rule is identical in both methods. Below is how it looks in the `store` method; apply the same change to `update`.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'cover_image' => 'nullable|image|mimes:jpg,jpeg,png,webp|dimensions:min_width=400,min_height=200|max:2048',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        // ... rest of method unchanged
    }

    // ... other methods
}
```

The `dimensions` rule accepts a comma-separated list of constraints: `min_width=400` requires the image to be at least 400 pixels wide, and `min_height=200` requires at least 200 pixels tall. You can also combine constraints such as `max_width`, `max_height`, and `ratio` (for example, `ratio=16/9`). When an image fails this rule, Laravel returns the validation error "The cover image field has invalid image dimensions." To test it, upload an image smaller than 400x200 pixels. Note that the `dimensions` rule only works with images where PHP can read the file's dimensions through `getimagesize()`, so it requires the `image` rule to appear before it in the rule chain to guarantee the file is a valid image first.

---

## Next Up - Lesson 8

In this lesson you built a complete file upload feature for Catatku. You created the `public/storage` symbolic link so uploaded files are accessible via URL, added a nullable `cover_image` column to the entries table, and handled file validation with the `image`, `mimes`, and `max` rules in the controller. You learned that `store('path', 'public')` generates a unique filename and returns the relative path for database storage, and that `Storage::disk('public')->delete()` removes old files during updates to prevent orphaned files from accumulating on disk.

In Lesson 8, you will learn sending email with Mailables: how to create Mailable classes, design Blade Markdown email templates, send a welcome email on registration, and notify entry authors when someone comments on their entries.