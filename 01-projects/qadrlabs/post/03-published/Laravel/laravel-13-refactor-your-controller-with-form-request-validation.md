---
title: "Laravel 13: Refactor Your Controller with Form Request Validation"
slug: "laravel-13-refactor-your-controller-with-form-request-validation"
category: "Laravel"
date: "2026-03-24"
status: "published"
---

In our [CRUD tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step), we built a working blog application with validation logic inside the controller. In our [testing tutorial](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application), we wrote 19 Pest tests to cover every CRUD operation and validation edge case.

Now we have a safety net. And that is exactly when refactoring becomes safe and productive.

In this tutorial, we will extract the validation logic from `PostController` into dedicated Form Request classes. The controller becomes thinner, the validation rules become reusable, and our existing tests ensure that nothing breaks along the way.


## Overview {#overview}

This tutorial picks up from the completed blog project with its Pest test suite. We will refactor the `store()` and `update()` methods in `PostController` by moving their validation logic into dedicated Form Request classes.

### What You'll Do

You will create two Form Request classes (`StorePostRequest` and `UpdatePostRequest`), move the validation rules and slug generation logic into them, simplify the controller methods, and run the existing test suite to confirm everything still works.

### What You'll Learn

By following this tutorial, you will learn how to:

- Generate Form Request classes using Artisan.
- Move validation rules from the controller to Form Request classes.
- Use the `prepareForValidation()` method to manipulate request data before validation.
- Handle slug uniqueness differently for store and update operations.
- Type-hint Form Requests in controller methods for automatic validation.
- Use existing tests to verify that a refactor does not introduce regressions.

### What You'll Need

- The completed blog project with the Pest test suite from the [testing tutorial](https://qadrlabs.com/post/laravel-13-testing-with-pest-write-tests-for-your-crud-application).
- PHP 8.3 or higher.
- Basic familiarity with Laravel controllers and validation.


## The Problem: Validation Logic in the Controller {#the-problem}

Let's look at the current `store()` and `update()` methods in `app/Http/Controllers/PostController.php`:

```php
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
```

This works, but there are a few issues as the application grows:

- **The controller is doing too much.** It handles slug generation, validation, database operations, and response logic all in the same method. Each method has multiple responsibilities.
- **Validation rules are duplicated.** The `store()` and `update()` methods share most of the same rules, with only the slug uniqueness rule being different. If you need to add a new field or change a rule, you have to update it in two places.
- **Slug generation is mixed with validation.** The `$request->merge()` call modifies the request before validation, which works but makes the flow harder to follow.

Laravel's Form Request classes solve all of these issues by giving validation its own dedicated class.


## Step 1: Run the Tests Before Refactoring {#step-1-run-tests-before}

Before changing any code, run the existing test suite to make sure everything passes:

```
php artisan test
```

All 19 tests should pass. This is our green baseline. If any test fails after refactoring, we will know immediately that the refactor introduced a problem.


## Step 2: Create the StorePostRequest {#step-2-create-store-post-request}

Generate a Form Request class for the store operation:

```
php artisan make:request StorePostRequest
```

This creates a new file at `app/Http/Requests/StorePostRequest.php`. Open it and replace the content with:

```php
<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str; // add this line

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
        ];
    }
}

```

Let's walk through each part:

**`authorize()`** determines whether the current user is allowed to make this request. Since our blog does not have authentication yet, we return `true` to allow all requests. In a real application, you would add authorization logic here, such as checking if the user has permission to create posts.

**`prepareForValidation()`** is called automatically before the validation rules are applied. This is the perfect place for the slug generation logic that was previously in the controller. It merges the generated slug into the request data, so by the time `rules()` runs, the `slug` field is already present and can be validated like any other field.

**`rules()`** returns the validation rules. These are the exact same rules that were in the controller's `store()` method. The `unique:posts,slug` rule ensures no duplicate slugs exist in the database.

Save the file.


## Step 3: Create the UpdatePostRequest {#step-3-create-update-post-request}

Generate a Form Request class for the update operation:

```
php artisan make:request UpdatePostRequest
```

Open `app/Http/Requests/UpdatePostRequest.php` and replace the content with:

```php
<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Str; // add this line

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
        ];
    }
}

```

The structure is almost identical to `StorePostRequest`, with one important difference in the slug validation rule.

**`'slug' => 'required|unique:posts,slug,' . $this->route('post')->id . '|max:255'`** adds an exception to the uniqueness check. `$this->route('post')` retrieves the `Post` model instance from the route parameter (thanks to route model binding), and `->id` gets its primary key. This tells the `unique` rule to ignore the current post when checking for duplicates. Without this, updating a post without changing its title would fail because the existing slug would be flagged as a duplicate of itself.

In the controller, we had access to the `$post` variable directly. Inside a Form Request, we use `$this->route('post')` to access the same route-bound model instance.

Save the file.


## Step 4: Refactor the Controller {#step-4-refactor-controller}

Now let's update `app/Http/Controllers/PostController.php` to use the new Form Request classes. Open the file and apply the following changes.

First, update the `use` statements at the top of the file. Remove the `Illuminate\Http\Request` and `Illuminate\Support\Str` imports (since they are no longer needed in the controller) and add the two Form Request classes:

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StorePostRequest;
use App\Http\Requests\UpdatePostRequest;
use App\Models\Post;

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
        Post::create($request->validated());

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
    public function edit(Post $post)
    {
        return view('posts.edit', compact('post'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdatePostRequest $request, Post $post)
    {
        $post->update($request->validated());

        return redirect()->route('posts.index')->with('success', 'Post updated successfully.');
    }

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

Compare the new `store()` and `update()` methods with the original versions. Here is what changed:

**Before (store):**
```php
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
```

**After (store):**
```php
public function store(StorePostRequest $request)
{
    Post::create($request->validated());

    return redirect()->route('posts.index')->with('success', 'Post created successfully.');
}
```

The method went from 13 lines to 4 lines. All the slug generation and validation logic has been moved to `StorePostRequest`. Here is what happens behind the scenes:

1. When Laravel sees `StorePostRequest` in the method signature, it automatically instantiates the class and runs validation before the controller method executes.
2. If validation fails, Laravel redirects back to the previous page with error messages. The controller method is never called.
3. If validation passes, `$request->validated()` returns only the fields that passed validation, which is then passed directly to `Post::create()`.

The same pattern applies to `update()`. Type-hinting `UpdatePostRequest` triggers automatic validation with the update-specific rules, and `$request->validated()` provides the clean data for `$post->update()`.

Notice that the `use Illuminate\Http\Request` and `use Illuminate\Support\Str` imports are no longer needed in the controller. The `Request` class has been replaced by the specific Form Request classes, and `Str` is now used inside the Form Request's `prepareForValidation()` method instead.

Save the controller file.


## Step 5: Run the Tests After Refactoring {#step-5-run-tests-after}

This is the moment of truth. Run the test suite to verify that the refactor did not break anything:

```
php artisan test
```

You should see the same result as before:

```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response

   PASS  Tests\Feature\PostControllerTest
  ✓ index page displays a list of posts
  ✓ index page shows empty state when no posts exist
  ✓ create page displays the form
  ✓ a new post can be stored
  ✓ slug is automatically generated from the title
  ✓ store validates required fields
  ✓ store validates title max length
  ✓ store validates status must be draft or publish
  ✓ store validates slug uniqueness
  ✓ show page displays a single post
  ✓ show returns 404 for non-existent post
  ✓ edit page displays the form with existing data
  ✓ a post can be updated
  ✓ update validates required fields
  ✓ update allows same slug for the same post
  ✓ a post can be deleted
  ✓ deleting a non-existent post returns 404

  Tests:    19 passed
  Duration: 0.52s
```

All 19 tests pass. The refactor is successful. The validation behavior is identical to what we had before, but the code is now better organized.

This is exactly why we wrote those tests in the previous tutorial. Without them, we would have to manually test every form submission, every validation scenario, and every edge case in the browser. With the test suite in place, a single `php artisan test` command confirms everything in seconds.


## What We Achieved {#what-we-achieved}

Let's summarize the structural changes and why they matter.

### Before: Controller Handles Everything

```
PostController
├── store()    → slug generation + validation rules + create + redirect
└── update()   → slug generation + validation rules + update + redirect
```

### After: Separated Responsibilities

```
StorePostRequest
├── prepareForValidation()  → slug generation
└── rules()                 → validation rules

UpdatePostRequest
├── prepareForValidation()  → slug generation
└── rules()                 → validation rules (with uniqueness exception)

PostController
├── store()    → create + redirect
└── update()   → update + redirect
```

Each class now has a single, clear responsibility:

- **Form Requests** handle data preparation and validation.
- **Controller** handles business logic (database operations) and response logic (redirects).

This separation makes the codebase easier to maintain. If you need to change a validation rule, you know exactly where to look. If you need to reuse the same validation in an API endpoint, you can type-hint the same Form Request class without duplicating the rules.


## Conclusion {#conclusion}

In this tutorial, we refactored the `PostController` by extracting validation logic into dedicated Form Request classes. The controller methods became significantly shorter and more focused, while the validation rules and slug generation logic found a proper home in `StorePostRequest` and `UpdatePostRequest`.

Here are the key takeaways:

- **Tests make refactoring safe.** The 19 Pest tests we wrote in the previous tutorial gave us the confidence to restructure the code without fear of breaking existing behavior. Running `php artisan test` after the refactor confirmed everything still works.
- **`prepareForValidation()` is the right place for data transformation.** Instead of calling `$request->merge()` in the controller, moving slug generation to `prepareForValidation()` keeps the data flow clean: transform first, then validate.
- **`$this->route('post')` gives access to route-bound models.** Inside a Form Request, you cannot access controller method parameters directly. Use `$this->route()` to retrieve the model instance from route model binding.
- **`$request->validated()` returns only validated data.** This is safer than using `$request->all()` because it ensures only the fields that passed validation are used for mass assignment.
- **Form Requests are reusable.** If you later build an API endpoint that also creates posts, you can type-hint the same `StorePostRequest` in the API controller. The validation logic does not need to be written again.
- **Thin controllers are easier to maintain.** When each method is only a few lines long, it is immediately clear what the method does. The complexity lives in dedicated classes where it is easier to find, test, and modify.

This refactoring pattern applies to any Laravel controller with inline validation. Start with the methods that have the most validation logic and work outward from there.

In the next tutorial, We will [add Authentication and Authorization with PHP Attributes](https://qadrlabs.com/post/laravel-13-add-authentication-and-authorization-with-php-attributes) to our project.