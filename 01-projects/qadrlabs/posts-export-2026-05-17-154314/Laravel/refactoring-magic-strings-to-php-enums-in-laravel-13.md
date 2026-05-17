---
title: "Refactoring Magic Strings to PHP Enums in Laravel 13"
slug: "refactoring-magic-strings-to-php-enums-in-laravel-13"
category: "Laravel"
date: "2026-04-13"
status: "published"
---

One of the most practical uses of PHP Enum in a Laravel application is replacing magic strings on fields that have a fixed set of allowed values. A post status field that only accepts `'draft'` or `'publish'` is a perfect example. Those raw strings are scattered across the migration, the Form Request classes, and multiple Blade views. A single typo like `'pubish'` or `'drft'` will not trigger any error; it will just silently produce wrong behavior. As the application grows and more developers touch the codebase, these magic strings become harder to track and easier to break. In this tutorial, we will use a Laravel 13 blog application as the case study and walk through the complete refactoring process step by step, replacing those strings with a proper `PostStatus` enum. By the end, the status field will be type-safe, self-documenting, and easier to extend, without changing any of the application's behavior.

## What is PHP Enum? {#what-is-php-enum}

PHP 8.1 introduced native Enum support as a first-class language feature. An Enum, short for enumeration, is a special type that defines a fixed set of named values. Instead of representing a post status as the string `'draft'`, you represent it as `PostStatus::Draft`, a typed identifier that PHP understands at the language level.

PHP supports two kinds of enums. A pure enum has no underlying value and is useful for representing states that only ever live in PHP code. A backed enum attaches a scalar value, either a `string` or an `int`, to each case. The backed variant is what we will use here, because the value needs to be stored in the database and submitted through HTML forms. When you define `enum PostStatus: string`, you are telling PHP that each case maps to a concrete string, like `'draft'` or `'publish'`, that can travel across the boundary between PHP and the database without losing its meaning.

Laravel 9 and higher supports PHP native enums without any additional packages. You can cast model attributes directly to an enum class, use a built-in validation rule that reads the allowed values from the enum definition, and generate form options dynamically by iterating over the enum cases.

## Overview {#overview}

This tutorial uses the `dummy-project-laravel-13` repository as the working project. It is the same blog application from the [Laravel 13 CRUD Tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step), extended through the following four tutorials:

- [Laravel 13 Testing with Pest: Write Tests for Your CRUD Application](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application)
- [Laravel 13: Refactor Your Controller with Form Request Validation](https://qadrlabs.com/post/laravel-13-refactor-your-controller-with-form-request-validation)
- [Laravel 13: Add Authentication and Authorization with PHP Attributes](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes)
- [Laravel 13: Build a REST API for Your Blog with Sanctum Authentication](https://qadrlabs.com/post/laravel-13-build-a-rest-api-for-your-blog-with-sanctum-authentication)

The project is available on GitHub so you can clone it directly and follow along without having to complete all five tutorials first. If you have already been working through those tutorials, your existing project is ready to use as-is.

### What You'll Build

A refactored version of the blog application where the post status field is powered by a PHP Enum instead of raw strings. The end result will look and behave identically to the original, and all 63 existing tests will continue to pass.

### What You'll Learn

By following this tutorial, you will learn how to:

- Create a backed PHP Enum with helper methods for UI display.
- Update a migration to change a MySQL enum column to a string column.
- Register an Eloquent cast so Laravel automatically converts between the database value and the enum object.
- Replace the `in:draft,publish` validation rule with Laravel's built-in `Enum` rule inside Form Request classes.
- Generate dropdown options in Blade views dynamically from enum cases.
- Replace conditional string comparisons in views with enum method calls.
- Verify a refactoring is correct by running the existing test suite.

### What You'll Need

Before getting started, make sure you have:

- PHP 8.3 or higher (required by Laravel 13).
- Composer installed globally.
- MySQL or another supported database.
- Basic understanding of Laravel models, controllers, Form Requests, and Blade views.


## Step 1: Prepare the Project {#step-1-prepare-project}

If you have already completed the five tutorials listed in the Overview, your existing project is ready. Open it in your editor and proceed to Step 2.

If you prefer to start from the ready-made project, clone the repository and install its dependencies:

```
git clone https://github.com/qadrLabs/dummy-project-laravel-13
cd dummy-project-laravel-13
composer install
```

Copy the environment file and configure your database connection:

```
cp .env.example .env
php artisan key:generate
```

Open the `.env` file and update the database settings to match your local setup:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_dummy_laravel_13
DB_USERNAME=root
DB_PASSWORD=password
```

Run the migrations:

```
php artisan migrate
```

Before making any changes, run the full test suite to establish a baseline. Every test should pass at this point, confirming that the starting state of the project is clean:

```
php artisan test
```

```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\Api\AuthApiTest
  ✓ a user can register via the api                                      0.14s
  ✓ register validates required fields                                   0.01s
  ✓ register validates unique email                                      0.01s
  ✓ register validates password confirmation                             0.01s
  ✓ a user can login via the api                                         0.01s
  ✓ login fails with incorrect credentials                               0.01s
  ✓ login validates required fields                                      0.01s
  ✓ a user can logout via the api                                        0.01s
  ✓ logout requires authentication                                       0.01s

   PASS  Tests\Feature\Api\PostApiTest
  ✓ authenticated user can list posts                                    0.02s
  ✓ post list is paginated                                               0.03s
  ✓ unauthenticated user cannot list posts                               0.01s
  ✓ authenticated user can create a post                                 0.01s
  ✓ store validates required fields via api                              0.01s
  ✓ store validates slug uniqueness via api                              0.01s
  ✓ unauthenticated user cannot create a post                            0.01s
  ✓ authenticated user can view a single post                            0.01s
  ✓ show returns 404 for non-existent post                               0.01s
  ✓ unauthenticated user cannot view a post                              0.01s
  ✓ post owner can update their post via api                             0.01s
  ✓ user cannot update a post they do not own via api                    0.01s
  ✓ update validates required fields via api                             0.01s
  ✓ unauthenticated user cannot update a post                            0.01s
  ✓ post owner can delete their post via api                             0.01s
  ✓ user cannot delete a post they do not own via api                    0.01s
  ✓ unauthenticated user cannot delete a post                            0.01s

   PASS  Tests\Feature\Auth\LoginTest
  ✓ login page is displayed                                              0.02s
  ✓ user can login with correct credentials                              0.01s
  ✓ user cannot login with incorrect password                            0.21s
  ✓ user cannot login with non-existent email                            0.23s
  ✓ login validates required fields                                      0.03s
  ✓ user can logout                                                      0.02s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.01s

   PASS  Tests\Feature\PostControllerTest
  ✓ index page displays a list of posts                                  0.01s
  ✓ index page shows empty state when no posts exist                     0.01s
  ✓ create page displays the form                                        0.01s
  ✓ a new post can be stored                                             0.01s
  ✓ slug is automatically generated from the title                       0.01s
  ✓ store validates required fields                                      0.01s
  ✓ store validates title max length                                     0.01s
  ✓ store validates status must be draft or publish                      0.01s
  ✓ store validates slug uniqueness                                      0.01s
  ✓ show page displays a single post                                     0.01s
  ✓ show returns 404 for non-existent post                               0.01s
  ✓ edit page displays the form with existing data                       0.01s
  ✓ a post can be updated                                                0.01s
  ✓ update validates required fields                                     0.01s
  ✓ update allows same slug for the same post                            0.01s
  ✓ a post can be deleted                                                0.01s
  ✓ deleting a non-existent post returns 404                             0.01s
  ✓ unauthenticated user is redirected to login from index               0.01s
  ✓ unauthenticated user is redirected to login from create              0.01s
  ✓ unauthenticated user is redirected to login from store               0.01s
  ✓ unauthenticated user is redirected to login from show                0.01s
  ✓ unauthenticated user is redirected to login from edit                0.01s
  ✓ unauthenticated user is redirected to login from update              0.01s
  ✓ unauthenticated user is redirected to login from destroy             0.01s
  ✓ user cannot edit a post they do not own                              0.01s
  ✓ user cannot update a post they do not own                            0.01s
  ✓ user cannot delete a post they do not own                            0.01s
  ✓ post owner can edit their own post                                   0.01s
  ✓ post owner can delete their own post                                 0.01s

  Tests:    63 passed (194 assertions)
  Duration: 1.24s
```

All 63 tests pass. We now have a confirmed baseline to work from. Any refactoring change that breaks this output is a signal that something went wrong.


## Step 2: Create the PostStatus Enum {#step-2-create-post-status-enum}

The first thing we need is the enum class itself. Create a new directory at `app/Enums/` and inside it create a file named `PostStatus.php`. This directory does not exist by default in Laravel, so you will need to create it manually.

```php
<?php

namespace App\Enums;

enum PostStatus: string
{
    case Draft   = 'draft';
    case Publish = 'publish';

    /**
     * Return a human-readable label for display in the UI.
     */
    public function label(): string
    {
        return match ($this) {
            self::Draft   => 'Draft',
            self::Publish => 'Published',
        };
    }

    /**
     * Return Tailwind CSS classes for the status badge.
     */
    public function badgeClass(): string
    {
        return match ($this) {
            self::Draft   => 'bg-gray-100 text-gray-800',
            self::Publish => 'bg-green-100 text-green-800',
        };
    }
}
```

There are a few things worth noting about this enum. The `: string` declaration after `enum PostStatus` makes this a backed enum, meaning each case is tied to a concrete string value. The value `'draft'` or `'publish'` is what gets stored in the database, while the case name (`Draft`, `Publish`) is what we reference in PHP code.

The `label()` method returns a display-friendly string for each case. This is the text we will show in the UI and in dropdown options, replacing the `ucfirst($post->status)` calls that previously scattered formatting logic across the views.

The `badgeClass()` method returns the full Tailwind CSS class string for the status badge. By putting this logic directly inside the enum, we centralize what used to be an inline ternary expression repeated in both the index and show views. If you ever add a new status or change the badge color, you only need to update one place.

Save the file at `app/Enums/PostStatus.php`.


## Step 3: Update the Migration {#step-3-update-the-migration}

The original migration defined the status column as a MySQL `enum` type:

```php
$table->enum('status', ['draft', 'publish'])->default('draft');
```

MySQL enum columns are rigid. Every time you want to add a new case, you need to run another migration that alters the column definition. When we use a PHP Enum to manage the allowed values, the database column itself does not need to enforce that constraint. A plain `string` column is more flexible and pairs cleanly with PHP-level validation.

Create a new migration to change the column type:

```
php artisan make:migration change_status_column_in_posts_table
```

Open the generated migration file and update it with the following content:

```php
<?php

use App\Enums\PostStatus;
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
            // Change from MySQL enum type to a plain string column.
            // The default value references PostStatus::Draft->value directly,
            // so it always stays in sync with the enum definition.
            $table->string('status')->default(PostStatus::Draft->value)->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('posts', function (Blueprint $table) {
            $table->enum('status', ['draft', 'publish'])->default('draft')->change();
        });
    }
};
```

Notice that we import `PostStatus` at the top of the migration file and use `PostStatus::Draft->value` as the default value, rather than hardcoding the string `'draft'`. This is the same principle we are applying throughout the refactoring: the source of truth for what the valid values are should always be the enum class, never a scattered literal string.

Now run the migration:

```
php artisan migrate
```

```
$ php artisan migrate

   INFO  Running migrations.

  2026_03_23_100000_change_status_column_in_posts_table .............. 11ms DONE
```

The existing data in the `status` column is not affected because the values `'draft'` and `'publish'` are valid in both the old and new column types.


## Step 4: Update the Post Model {#step-4-update-the-post-model}

With the enum class in place, we need to tell Eloquent to automatically convert the raw string value from the database into a `PostStatus` object whenever we access the `status` attribute on a `Post` model. This is done through Eloquent's casting system.

Open `app/Models/Post.php` and update it:

```php
<?php

namespace App\Models;

use App\Enums\PostStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['title', 'slug', 'content', 'status', 'user_id'])]
class Post extends Model
{
    use HasFactory;

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    protected $casts = [
        // When reading: Eloquent calls PostStatus::from($rawValue),
        // converting the stored string 'draft' into PostStatus::Draft.
        // When writing: Eloquent calls $enumObject->value,
        // converting PostStatus::Publish back to 'publish' before saving.
        'status' => PostStatus::class,
    ];
}
```

We add two things here. First, we import the `PostStatus` enum at the top with a `use` statement. Second, we define the `$casts` property with `'status' => PostStatus::class`.

Once this cast is registered, `$post->status` will return a `PostStatus` enum object instead of a plain string. This means we can call `$post->status->label()` and `$post->status->badgeClass()` directly on any post instance. Eloquent also handles the reverse direction: when you save a model, it automatically writes the enum's `->value` back to the database column.

Save the model file.


## Step 5: Update the PostController {#step-5-update-the-post-controller}

In this project, validation logic lives in dedicated Form Request classes rather than inline in the controller methods. This means the controller itself needs fewer changes than you might expect. We only need to update two methods: `create()` and `edit()`, both of which need to pass the list of available statuses to their respective views so the dropdown can be rendered dynamically.

Open `app/Http/Controllers/PostController.php` and add the `PostStatus` import, then update the `create()` and `edit()` methods:

```php
<?php

namespace App\Http\Controllers;

use App\Enums\PostStatus;

// [ ... other use statements ... ]

#[Middleware('auth')]
class PostController extends Controller
{
    // [ ... other methods ... ]

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        // Pass all enum cases to the view so it can render the dropdown dynamically.
        $statuses = PostStatus::cases();
        return view('posts.create', compact('statuses'));
    }

    // [ ... other methods ... ]

    /**
     * Show the form for editing the specified resource.
     */
    #[Authorize('update', 'post')]
    public function edit(Post $post)
    {
        // Same as create: pass all enum cases for the dropdown.
        $statuses = PostStatus::cases();
        return view('posts.edit', compact('post', 'statuses'));
    }

    // [ ... other methods ... ]
}
```

`PostStatus::cases()` returns an array of all enum cases in the order they are declared. Passing this to the view means the dropdown is generated from the single source of truth. Adding a new status case in the future only requires one change in the enum class; the dropdown in every form will update automatically.

The `store()` and `update()` methods do not need to change here because their validation rules live in the `StorePostRequest` and `UpdatePostRequest` classes, which we will update in the next two steps.

Save the controller file.


## Step 6: Update StorePostRequest {#step-6-update-store-post-request}

The `StorePostRequest` class currently uses the `in:draft,publish` string rule to validate the status field. This means the list of valid values is hardcoded in the validation rule, separate from the enum definition. If we ever add a new case to the enum, we would have to remember to update this rule as well. The `Enum` validation rule solves this by reading the valid values directly from the enum class.

Open `app/Http/Requests/StorePostRequest.php` and update it:

```php
<?php

namespace App\Http\Requests;

use App\Enums\PostStatus;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Enum;

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
            'title'   => 'required|max:255',
            'slug'    => 'required|unique:posts,slug|max:255',
            'content' => 'required',
            // The Enum rule accepts only values defined in PostStatus.
            // No need to list 'draft,publish' manually — the rule reads PostStatus::cases() internally.
            'status'  => ['required', new Enum(PostStatus::class)],
        ];
    }
}
```

The two new `use` statements at the top are what make this possible. `use App\Enums\PostStatus` brings in our enum class, and `use Illuminate\Validation\Rules\Enum` brings in Laravel's built-in validation rule for enums. The validation rule itself, `new Enum(PostStatus::class)`, takes the class name as its argument and automatically validates that the submitted value matches one of the defined cases.

Save the file.


## Step 7: Update UpdatePostRequest {#step-7-update-update-post-request}

The `UpdatePostRequest` class needs the same change. Open `app/Http/Requests/UpdatePostRequest.php` and update it:

```php
<?php

namespace App\Http\Requests;

use App\Enums\PostStatus;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Enum;

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
            'title'   => 'required|max:255',
            // The unique rule excludes the current post from the uniqueness check,
            // so updating without changing the title does not fail validation.
            'slug'    => 'required|unique:posts,slug,' . $this->route('post')->id . '|max:255',
            'content' => 'required',
            'status'  => ['required', new Enum(PostStatus::class)],
        ];
    }
}
```

The structure mirrors `StorePostRequest` exactly for the status rule. The difference between the two classes is in the `slug` uniqueness rule: the update request adds `$this->route('post')->id` as an exception so that a post can be updated without changing its title without triggering a false duplicate slug error.

Save the file.


## Step 8: Update the Create View {#step-8-update-create-view}

Open `resources/views/posts/create.blade.php`. Find the status dropdown section and replace it:

Change this:

```html
<div>
    <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
    <select name="status" required
            class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition">
        <option value="draft" {{ old('status') == 'draft' ? 'selected' : '' }}>Draft</option>
        <option value="publish" {{ old('status') == 'publish' ? 'selected' : '' }}>Publish</option>
    </select>
</div>
```

To this:

```html
<div>
    <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
    <select name="status" required
        class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition">
        {{-- Loop through all PostStatus cases instead of hardcoding each option. --}}
        @foreach($statuses as $status)
            <option value="{{ $status->value }}" {{ old('status') == $status->value ? 'selected' : '' }}>
                {{ $status->label() }}
            </option>
        @endforeach
    </select>
</div>
```

Inside the loop, `$status->value` gives us the string `'draft'` or `'publish'` that gets submitted with the form, and `$status->label()` gives us the human-readable text to display in the dropdown option. The `old('status') == $status->value` comparison repopulates the correct option if the form fails validation and the page is reloaded.

Save the view file.


## Step 9: Update the Edit View {#step-9-update-edit-view}

Open `resources/views/posts/edit.blade.php`. Find the status dropdown section and replace it:

Change this:

```html
<div>
    <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
    <select name="status" required
            class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition">
        <option value="draft" {{ old('status', $post->status) == 'draft' ? 'selected' : '' }}>Draft</option>
        <option value="publish" {{ old('status', $post->status) == 'publish' ? 'selected' : '' }}>Publish</option>
    </select>
</div>
```

To this:

```html
<div>
    <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
    <select name="status" required
        class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none bg-white transition">
        {{-- Use $post->status->value to get the string for comparison,
             because $post->status is now a PostStatus enum object (not a string). --}}
        @foreach($statuses as $status)
            <option value="{{ $status->value }}" @selected(old('status', $post->status->value) === $status->value)>
                {{ $status->label() }}
            </option>
        @endforeach
    </select>
</div>
```

The edit form has one important difference from the create form. The fallback value in `old('status', $post->status->value)` uses `->value` to extract the raw string from the enum object. This is necessary because `$post->status` is now a `PostStatus` enum object after the Eloquent cast is applied, not a plain string. Without `->value`, the comparison would be between a string and an enum object, which would always be false, and the currently selected option would never be pre-populated.

We also use Blade's `@selected` directive here instead of a ternary expression. It is functionally identical but slightly more readable, and it is the idiomatic Blade approach for pre-selecting an option.

Save the view file.


## Step 10: Update the Index and Show Views {#step-10-update-index-show-views}

Two views still contain the old string-based status logic: the post listing page and the detail page. We need to update the status badge in each of them to use the enum's helper methods instead.

### Update the Index View

Open `resources/views/posts/index.blade.php`. Find the status badge cell inside the `@forelse` loop and replace it:

Change this:

```html
<td class="px-6 py-4 whitespace-nowrap text-sm">
    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full {{ $post->status === 'publish' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800' }}">
        {{ ucfirst($post->status) }}
    </span>
</td>
```

To this:

```html
<td class="px-6 py-4 whitespace-nowrap text-sm">
    {{-- badgeClass() returns the correct Tailwind classes based on the enum case. --}}
    {{-- label() returns the human-readable display text. --}}
    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full {{ $post->status->badgeClass() }}">
        {{ $post->status->label() }}
    </span>
</td>
```

With the Eloquent cast applied, `$post->status` is now an enum object, so the string comparison `=== 'publish'` no longer works. By calling `$post->status->badgeClass()`, we delegate the color logic to the enum itself. And `$post->status->label()` replaces `ucfirst($post->status)` with a proper method call, removing the formatting responsibility from the view entirely.

Save the index view file.

### Update the Show View

Open `resources/views/posts/show.blade.php`. Find the status badge and replace it:

Change this:

```html
<span class="px-2 py-0.5 inline-flex text-xs leading-5 font-semibold rounded-full {{ $post->status === 'publish' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800' }}">
    {{ ucfirst($post->status) }}
</span>
```

To this:

```html
<span class="px-2 py-0.5 inline-flex text-xs leading-5 font-semibold rounded-full {{ $post->status->badgeClass() }}">
    {{ $post->status->label() }}
</span>
```

The change is identical in nature to the index view. Both the badge class and the display text now come from the enum object, keeping the views clean and free of formatting logic.

Save the show view file.


## Step 11: Run the Tests {#step-11-run-the-tests}

With all the changes in place, run the full test suite to verify that the refactoring did not break anything:

```
php artisan test
```

```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\Api\AuthApiTest
  ✓ a user can register via the api                                      0.15s
  ✓ register validates required fields                                   0.01s
  ✓ register validates unique email                                      0.02s
  ✓ register validates password confirmation                             0.01s
  ✓ a user can login via the api                                         0.01s
  ✓ login fails with incorrect credentials                               0.01s
  ✓ login validates required fields                                      0.01s
  ✓ a user can logout via the api                                        0.01s
  ✓ logout requires authentication                                       0.01s

   PASS  Tests\Feature\Api\PostApiTest
  ✓ authenticated user can list posts                                    0.02s
  ✓ post list is paginated                                               0.03s
  ✓ unauthenticated user cannot list posts                               0.01s
  ✓ authenticated user can create a post                                 0.01s
  ✓ store validates required fields via api                              0.01s
  ✓ store validates slug uniqueness via api                              0.01s
  ✓ unauthenticated user cannot create a post                            0.01s
  ✓ authenticated user can view a single post                            0.01s
  ✓ show returns 404 for non-existent post                               0.01s
  ✓ unauthenticated user cannot view a post                              0.01s
  ✓ post owner can update their post via api                             0.01s
  ✓ user cannot update a post they do not own via api                    0.01s
  ✓ update validates required fields via api                             0.01s
  ✓ unauthenticated user cannot update a post                            0.01s
  ✓ post owner can delete their post via api                             0.01s
  ✓ user cannot delete a post they do not own via api                    0.01s
  ✓ unauthenticated user cannot delete a post                            0.01s

   PASS  Tests\Feature\Auth\LoginTest
  ✓ login page is displayed                                              0.02s
  ✓ user can login with correct credentials                              0.01s
  ✓ user cannot login with incorrect password                            0.21s
  ✓ user cannot login with non-existent email                            0.23s
  ✓ login validates required fields                                      0.02s
  ✓ user can logout                                                      0.01s

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.01s

   PASS  Tests\Feature\PostControllerTest
  ✓ index page displays a list of posts                                  0.02s
  ✓ index page shows empty state when no posts exist                     0.01s
  ✓ create page displays the form                                        0.01s
  ✓ a new post can be stored                                             0.02s
  ✓ slug is automatically generated from the title                       0.01s
  ✓ store validates required fields                                      0.01s
  ✓ store validates title max length                                     0.01s
  ✓ store validates status must be draft or publish                      0.01s
  ✓ store validates slug uniqueness                                      0.01s
  ✓ show page displays a single post                                     0.01s
  ✓ show returns 404 for non-existent post                               0.01s
  ✓ edit page displays the form with existing data                       0.01s
  ✓ a post can be updated                                                0.01s
  ✓ update validates required fields                                     0.01s
  ✓ update allows same slug for the same post                            0.01s
  ✓ a post can be deleted                                                0.01s
  ✓ deleting a non-existent post returns 404                             0.01s
  ✓ unauthenticated user is redirected to login from index               0.01s
  ✓ unauthenticated user is redirected to login from create              0.01s
  ✓ unauthenticated user is redirected to login from store               0.01s
  ✓ unauthenticated user is redirected to login from show                0.01s
  ✓ unauthenticated user is redirected to login from edit                0.01s
  ✓ unauthenticated user is redirected to login from update              0.01s
  ✓ unauthenticated user is redirected to login from destroy             0.01s
  ✓ user cannot edit a post they do not own                              0.02s
  ✓ user cannot update a post they do not own                            0.01s
  ✓ user cannot delete a post they do not own                            0.01s
  ✓ post owner can edit their own post                                   0.01s
  ✓ post owner can delete their own post                                 0.01s

  Tests:    63 passed (194 assertions)
  Duration: 1.32s
```

All 63 tests pass, the same count as before the refactoring. This is the most reliable confirmation that the changes are correct: the test suite covers unit tests, web controller tests, API tests, and auth tests, so a passing run means the enum is wired up correctly at every layer of the application.


## Understanding PHP Enum in Laravel {#understanding-php-enum-in-laravel}

Now that the refactoring is complete, it is worth stepping back to understand the concepts we applied and why each decision was made this way.

### Pure Enum vs Backed Enum

PHP 8.1 introduced two types of enums. A pure enum has no underlying value attached to its cases. It is useful for representing a fixed set of states within PHP code, but it cannot be stored directly in a database. A backed enum, on the other hand, associates each case with a scalar value, either a `string` or an `int`. When you write `enum PostStatus: string`, you are declaring a string-backed enum. Each case must be assigned a string literal, like `case Draft = 'draft'`. This is the type you want whenever enum values need to cross a boundary such as a database column, an HTTP form, or a JSON response.

### How Eloquent Casting Works

When you add `'status' => PostStatus::class` to the `$casts` property on a model, you are registering a two-way converter. On read, Eloquent takes the raw string from the database (e.g., `'draft'`) and calls `PostStatus::from('draft')`, which returns the `PostStatus::Draft` case object. On write, Eloquent takes the enum object and calls `->value` on it to get the string back before inserting or updating the database row. This conversion is invisible to you in most cases, which is exactly the point. You interact with a typed enum object, and Eloquent handles the database translation automatically.

### Why Enum Is Better Than Magic Strings

Magic strings create three categories of problems. First, they are easy to mistype, and PHP will not catch the error at runtime in most contexts. Second, the list of valid values lives in multiple places simultaneously: in the migration, in the `in:draft,publish` validation rule inside the Form Request classes, in the Blade view's `<option>` elements, and in any conditional that checks the status. When the list changes, you have to update all of those locations and hope you do not miss one. Third, they carry no semantic meaning: the string `'publish'` is just a string, so the code that consumes it cannot be certain it represents a valid application state.

A backed enum solves all three problems. Typos become compile-time errors because the case names are identifiers, not strings. The list of valid values lives in exactly one file. And each case is a strongly typed value that carries meaning, helper methods, and metadata.


## Conclusion {#conclusion}

In this tutorial, we refactored the Laravel 13 blog application to replace raw status strings with a proper PHP Enum across every layer of the application: the migration, the model, the controller, two Form Request classes, and four Blade views. The application behavior did not change at all, and all 63 tests continued to pass after the refactoring, confirming that the new implementation is a drop-in replacement for the old one.

Here are the key takeaways:

- **Create a backed enum for any field with a fixed set of string or integer values.** The `: string` declaration binds each case to a database-storable value, while the case name gives you a type-safe identifier to use in PHP code.
- **Add helper methods directly to the enum class.** Methods like `label()` and `badgeClass()` centralize display logic that used to be scattered across views as ternary expressions or `ucfirst()` calls.
- **Reference the enum in the migration default value.** Using `PostStatus::Draft->value` instead of the hardcoded string `'draft'` as the column default keeps the migration in sync with the enum definition.
- **Register an Eloquent cast with `$casts` to automate the conversion.** Once the cast is in place, you always interact with an enum object on your model, never with a raw string.
- **Update validation in Form Request classes, not just the controller.** In a project that uses dedicated Form Request classes, the `in:draft,publish` rule lives there. The built-in `Enum` validation rule reads the allowed values directly from the enum definition, eliminating the risk of the validation rule and the enum drifting out of sync.
- **Pass `PostStatus::cases()` from the controller to generate dropdowns dynamically.** This means adding a new status in the future requires one change in the enum class, and all dropdowns across the application update automatically.
- **Use `$post->status->value` when you need the raw string.** Because the model cast returns an enum object, you need `->value` in places like `old('status', $post->status->value)` where a plain string is expected.
- **Run the test suite to verify a refactoring.** When the existing tests still pass after the changes, you have objective evidence that the refactoring did not introduce regressions.