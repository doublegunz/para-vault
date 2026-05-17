---
title: "Laravel 13 Testing with Pest: Write Tests for Your CRUD Application"
slug: "laravel-13-testing-with-pest-write-tests-for-your-crud-application"
category: "Laravel"
date: "2026-03-24"
status: "published"
---

You have built a working CRUD application, and everything looks fine when you test it manually in the browser. But what happens when you add a new feature next week and accidentally break the create form? Or when a teammate changes a validation rule without realizing it affects the update flow? Without automated tests, you will not catch these regressions until a user reports them.

This tutorial picks up where our [Laravel 13 CRUD Tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step) left off. We will write feature tests for every CRUD operation in the blog application using Pest, the modern testing framework that ships with Laravel 13 by default.


## Overview {#overview}

In this tutorial, we will write automated tests for the blog application we built in the previous tutorial. The application has a `Post` model with `title`, `slug`, `content`, and `status` fields, managed through a resource controller with full CRUD functionality.

### What You'll Do

You will write Pest feature tests that cover every CRUD operation: listing posts, creating a new post, viewing a single post, editing a post, and deleting a post. Each test will verify both the HTTP response and the database state.

### What You'll Learn

By following this tutorial, you will learn how to:

- Replace PHPUnit with Pest in an existing Laravel 13 project.
- Create model factories for generating test data.
- Write feature tests for each CRUD operation.
- Use `RefreshDatabase` to keep tests isolated.
- Assert HTTP responses, redirects, session data, and database state.
- Validate that form validation rules work correctly.
- Run and interpret Pest test results.

### What You'll Need

- The completed blog project from the [Laravel 13 CRUD Tutorial](https://qadrlabs.com/post/laravel-13-crud-tutorial-build-a-simple-blog-step-by-step).
- PHP 8.3 or higher.
- Basic familiarity with Laravel and testing concepts.


## Step 1: Install Pest {#step-1-install-pest}

The blog project from the previous tutorial ships with PHPUnit as its testing framework. We need to replace it with Pest. Open `composer.json` and you will see PHPUnit listed in the dev dependencies:

```json
"require-dev": {
    "fakerphp/faker": "^1.23",
    "laravel/boost": "^2.3",
    "laravel/pail": "^1.2.5",
    "laravel/pint": "^1.27",
    "mockery/mockery": "^1.6",
    "nunomaduro/collision": "^8.6",
    "phpunit/phpunit": "^12.5.12"
},
```

First, remove PHPUnit, then install Pest with all its dependencies:

```
composer remove phpunit/phpunit
composer require pestphp/pest --dev --with-all-dependencies
```

The `--with-all-dependencies` flag tells Composer to also update any existing packages that need to be adjusted for compatibility with Pest.

Next, initialize Pest in your project:

```
./vendor/bin/pest --init
```

```
$ ./vendor/bin/pest --init
   INFO  Preparing tests directory.
  phpunit.xml ........................................... File already exists.  
  tests/Pest.php ............................................... File created.  
  tests/TestCase.php .................................... File already exists.  
  tests/Unit/ExampleTest.php ............................ File already exists.  
  tests/Feature/ExampleTest.php ......................... File already exists.  
```

The `--init` command creates a `tests/Pest.php` file, which is Pest's configuration file. The existing test files and `phpunit.xml` are left untouched since they are already compatible.

### Verify the Test Database Configuration

Open `phpunit.xml` and check the environment variables section. In this project, the SQLite in-memory database is already configured by default:

```xml
    <php>
        <env name="APP_ENV" value="testing"/>
        <env name="APP_MAINTENANCE_DRIVER" value="file"/>
        <env name="BCRYPT_ROUNDS" value="4"/>
        <env name="BROADCAST_CONNECTION" value="null"/>
        <env name="CACHE_STORE" value="array"/>
        <env name="DB_CONNECTION" value="sqlite"/>
        <env name="DB_DATABASE" value=":memory:"/>
        <env name="DB_URL" value=""/>
        <env name="MAIL_MAILER" value="array"/>
        <env name="QUEUE_CONNECTION" value="sync"/>
        <env name="SESSION_DRIVER" value="array"/>
        <env name="PULSE_ENABLED" value="false"/>
        <env name="TELESCOPE_ENABLED" value="false"/>
        <env name="NIGHTWATCH_ENABLED" value="false"/>
    </php>
```

The `DB_CONNECTION` is set to `sqlite` and `DB_DATABASE` is set to `:memory:`. This means tests will run against a fresh in-memory SQLite database that is created and destroyed with each test run, keeping your development database completely untouched.

### Verify Pest Is Working

Run Pest to confirm everything is set up correctly:

```
./vendor/bin/pest
```

```
$ ./vendor/bin/pest
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true
   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.09s  
  Tests:    2 passed (2 assertions)
  Duration: 0.13s
```

Both default tests pass. Pest is installed and working. You can also run tests using `php artisan test`, which internally calls Pest now that PHPUnit has been replaced.


## Step 2: Create a Post Factory {#step-2-create-post-factory}

Tests need sample data, and Laravel's model factories are the standard way to generate it. Create a factory for the `Post` model:

```
php artisan make:factory PostFactory --model=Post
```

Open `database/factories/PostFactory.php` and define the default state:

```php
<?php

namespace Database\Factories;

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
        ];
    }
}
```

Here is what each field generates:

- `title` uses Faker's `sentence()` to produce a realistic-looking title like "The quick brown fox jumps over."
- `slug` converts the generated title into a URL-friendly format using `Str::slug()`. For example, "The Quick Brown Fox" becomes "the-quick-brown-fox".
- `content` uses `paragraphs(3, true)` to generate three paragraphs of lorem ipsum text joined as a single string. The `true` parameter returns a string instead of an array.
- `status` randomly picks either "draft" or "publish" from the allowed enum values.

Save the file.


## Step 3: Write Tests for Listing Posts {#step-3-test-listing-posts}

Now let's start writing the actual tests. Create a new test file:

```
php artisan make:test PostControllerTest --pest
```

The `--pest` flag generates a Pest-style test file instead of a traditional PHPUnit class. Open `tests/Feature/PostControllerTest.php` and replace its content with:

```php
<?php

use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

test('index page displays a list of posts', function () {
    $posts = Post::factory()->count(3)->create();

    $response = $this->get(route('posts.index'));

    $response->assertStatus(200);
    $response->assertViewIs('posts.index');
    $response->assertViewHas('posts');

    foreach ($posts as $post) {
        $response->assertSee($post->title);
    }
});

test('index page shows empty state when no posts exist', function () {
    $response = $this->get(route('posts.index'));

    $response->assertStatus(200);
    $response->assertSee('No posts found.');
});
```

Let's break down the structure:

- `uses(RefreshDatabase::class)` is placed at the top of the file and applies to every test in this file. It runs migrations before the first test and wraps each test in a database transaction that rolls back when the test finishes. This ensures every test starts with a clean database.
- `test('description', function () { ... })` is Pest's syntax for defining a test case. The first argument is a human-readable description that appears in the test output.
- `Post::factory()->count(3)->create()` uses the factory we created in Step 2 to insert three post records into the database.
- `$this->get(route('posts.index'))` sends a GET request to the posts index route and captures the response.
- `assertStatus(200)` verifies the HTTP status code.
- `assertViewIs('posts.index')` confirms that the correct Blade view is returned.
- `assertViewHas('posts')` checks that a `posts` variable is passed to the view.
- `assertSee($post->title)` verifies that each post title appears somewhere in the rendered HTML.

The second test checks the empty state: when no posts exist in the database, the page should display "No posts found." as we defined in the Blade view.

Save the file.


## Step 4: Write Tests for Creating Posts {#step-4-test-creating-posts}

Add the following tests to the same file:

```php
test('create page displays the form', function () {
    $response = $this->get(route('posts.create'));

    $response->assertStatus(200);
    $response->assertViewIs('posts.create');
    $response->assertSee('Create Post');
});

test('a new post can be stored', function () {
    $response = $this->post(route('posts.store'), [
        'title' => 'My First Blog Post',
        'content' => 'This is the content of my first blog post.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post created successfully.');

    $this->assertDatabaseHas('posts', [
        'title' => 'My First Blog Post',
        'slug' => 'my-first-blog-post',
        'content' => 'This is the content of my first blog post.',
        'status' => 'publish',
    ]);
});

test('slug is automatically generated from the title', function () {
    $this->post(route('posts.store'), [
        'title' => 'Laravel 13 Is Amazing',
        'content' => 'Some content here.',
        'status' => 'draft',
    ]);

    $this->assertDatabaseHas('posts', [
        'title' => 'Laravel 13 Is Amazing',
        'slug' => 'laravel-13-is-amazing',
    ]);
});

test('store validates required fields', function () {
    $response = $this->post(route('posts.store'), []);

    $response->assertSessionHasErrors(['title', 'content', 'status']);
});

test('store validates title max length', function () {
    $response = $this->post(route('posts.store'), [
        'title' => str_repeat('a', 256),
        'content' => 'Some content.',
        'status' => 'publish',
    ]);

    $response->assertSessionHasErrors(['title']);
});

test('store validates status must be draft or publish', function () {
    $response = $this->post(route('posts.store'), [
        'title' => 'Test Post',
        'content' => 'Some content.',
        'status' => 'archived',
    ]);

    $response->assertSessionHasErrors(['status']);
});

test('store validates slug uniqueness', function () {
    Post::factory()->create(['title' => 'Duplicate Title', 'slug' => 'duplicate-title']);

    $response = $this->post(route('posts.store'), [
        'title' => 'Duplicate Title',
        'content' => 'Different content.',
        'status' => 'draft',
    ]);

    $response->assertSessionHasErrors(['slug']);
});
```

These tests cover both the happy path and the validation edge cases:

- The first test verifies that the create form page loads correctly.
- The store test sends a POST request with valid data, then checks three things: the response redirects to the index page, a success flash message is present in the session, and the data exists in the database with the correct slug.
- The slug test specifically verifies the auto-generation behavior. We send "Laravel 13 Is Amazing" as the title and confirm that "laravel-13-is-amazing" is stored as the slug.
- `assertSessionHasErrors(['title', 'content', 'status'])` verifies that validation errors are returned when required fields are missing.
- The max length test sends a title longer than 255 characters and expects a validation error.
- The status test sends an invalid status value ("archived") and expects it to be rejected since only "draft" and "publish" are allowed.
- The uniqueness test creates a post with a specific slug first, then attempts to create another post with the same title (and therefore the same slug) and expects a validation error.


## Step 5: Write Tests for Viewing a Post {#step-5-test-viewing-post}

Add these tests to verify the show page:

```php
test('show page displays a single post', function () {
    $post = Post::factory()->create();

    $response = $this->get(route('posts.show', $post));

    $response->assertStatus(200);
    $response->assertViewIs('posts.show');
    $response->assertSee($post->title);
    $response->assertSee($post->content);
});

test('show returns 404 for non-existent post', function () {
    $response = $this->get(route('posts.show', 9999));

    $response->assertStatus(404);
});
```

The first test creates a post, requests its detail page, and verifies that both the title and content are visible in the response. The second test requests a post ID that does not exist and confirms that Laravel returns a 404 status code, which is handled automatically by route model binding.


## Step 6: Write Tests for Updating Posts {#step-6-test-updating-posts}

Add tests for the edit form and update operation:

```php
test('edit page displays the form with existing data', function () {
    $post = Post::factory()->create();

    $response = $this->get(route('posts.edit', $post));

    $response->assertStatus(200);
    $response->assertViewIs('posts.edit');
    $response->assertSee($post->title);
    $response->assertSee($post->content);
});

test('a post can be updated', function () {
    $post = Post::factory()->create([
        'title' => 'Original Title',
        'slug' => 'original-title',
        'content' => 'Original content.',
        'status' => 'draft',
    ]);

    $response = $this->put(route('posts.update', $post), [
        'title' => 'Updated Title',
        'content' => 'Updated content.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post updated successfully.');

    $this->assertDatabaseHas('posts', [
        'id' => $post->id,
        'title' => 'Updated Title',
        'slug' => 'updated-title',
        'content' => 'Updated content.',
        'status' => 'publish',
    ]);
});

test('update validates required fields', function () {
    $post = Post::factory()->create();

    $response = $this->put(route('posts.update', $post), []);

    $response->assertSessionHasErrors(['title', 'content', 'status']);
});

test('update allows same slug for the same post', function () {
    $post = Post::factory()->create([
        'title' => 'Keep This Title',
        'slug' => 'keep-this-title',
    ]);

    $response = $this->put(route('posts.update', $post), [
        'title' => 'Keep This Title',
        'content' => 'Updated content only.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHasNoErrors();
});
```

The update test creates a post with known values, sends a PUT request with new data, and verifies that the database reflects the changes. Notice that we also assert the `id` to confirm the correct record was updated.

The last test is particularly important. It verifies that updating a post without changing its title does not trigger a slug uniqueness error. Recall from the CRUD tutorial that the controller's validation rule includes `unique:posts,slug,' . $post->id`, which excludes the current record from the uniqueness check. This test confirms that behavior.


## Step 7: Write Tests for Deleting Posts {#step-7-test-deleting-posts}

Add tests for the delete operation:

```php
test('a post can be deleted', function () {
    $post = Post::factory()->create();

    $response = $this->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post deleted successfully.');

    $this->assertDatabaseMissing('posts', [
        'id' => $post->id,
    ]);
});

test('deleting a non-existent post returns 404', function () {
    $response = $this->delete(route('posts.destroy', 9999));

    $response->assertStatus(404);
});
```

The first test creates a post, sends a DELETE request, and then verifies three things: the response redirects to the index page, a success message is flashed, and the record no longer exists in the database. `assertDatabaseMissing` is the counterpart to `assertDatabaseHas`, confirming that no row with the given ID exists.

The second test attempts to delete a post that does not exist and verifies that a 404 response is returned.


## Step 8: Run the Tests {#step-8-run-tests}

With all tests written, let's run them. Open your terminal and execute:

```
php artisan test
```

You should see output similar to this:

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

All 19 tests pass. Here is what we covered:

- 2 tests for the listing page (with data and empty state).
- 7 tests for creating posts (form display, successful store, slug generation, and 4 validation scenarios).
- 2 tests for viewing a post (existing and non-existent).
- 4 tests for updating posts (form display, successful update, validation, and slug uniqueness edge case).
- 2 tests for deleting posts (successful delete and non-existent post).

You can also run only the PostControllerTest file:

```
php artisan test --filter=PostControllerTest
```

Or run a specific test by name:

```
php artisan test --filter="a new post can be stored"
```


## The Complete Test File {#complete-test-file}

Here is the full `tests/Feature/PostControllerTest.php` for reference:

```php
<?php

use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

// Index Tests
test('index page displays a list of posts', function () {
    $posts = Post::factory()->count(3)->create();

    $response = $this->get(route('posts.index'));

    $response->assertStatus(200);
    $response->assertViewIs('posts.index');
    $response->assertViewHas('posts');

    foreach ($posts as $post) {
        $response->assertSee($post->title);
    }
});

test('index page shows empty state when no posts exist', function () {
    $response = $this->get(route('posts.index'));

    $response->assertStatus(200);
    $response->assertSee('No posts found.');
});

// Create Tests
test('create page displays the form', function () {
    $response = $this->get(route('posts.create'));

    $response->assertStatus(200);
    $response->assertViewIs('posts.create');
    $response->assertSee('Create Post');
});

test('a new post can be stored', function () {
    $response = $this->post(route('posts.store'), [
        'title' => 'My First Blog Post',
        'content' => 'This is the content of my first blog post.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post created successfully.');

    $this->assertDatabaseHas('posts', [
        'title' => 'My First Blog Post',
        'slug' => 'my-first-blog-post',
        'content' => 'This is the content of my first blog post.',
        'status' => 'publish',
    ]);
});

test('slug is automatically generated from the title', function () {
    $this->post(route('posts.store'), [
        'title' => 'Laravel 13 Is Amazing',
        'content' => 'Some content here.',
        'status' => 'draft',
    ]);

    $this->assertDatabaseHas('posts', [
        'title' => 'Laravel 13 Is Amazing',
        'slug' => 'laravel-13-is-amazing',
    ]);
});

test('store validates required fields', function () {
    $response = $this->post(route('posts.store'), []);

    $response->assertSessionHasErrors(['title', 'content', 'status']);
});

test('store validates title max length', function () {
    $response = $this->post(route('posts.store'), [
        'title' => str_repeat('a', 256),
        'content' => 'Some content.',
        'status' => 'publish',
    ]);

    $response->assertSessionHasErrors(['title']);
});

test('store validates status must be draft or publish', function () {
    $response = $this->post(route('posts.store'), [
        'title' => 'Test Post',
        'content' => 'Some content.',
        'status' => 'archived',
    ]);

    $response->assertSessionHasErrors(['status']);
});

test('store validates slug uniqueness', function () {
    Post::factory()->create(['title' => 'Duplicate Title', 'slug' => 'duplicate-title']);

    $response = $this->post(route('posts.store'), [
        'title' => 'Duplicate Title',
        'content' => 'Different content.',
        'status' => 'draft',
    ]);

    $response->assertSessionHasErrors(['slug']);
});

// Show Tests
test('show page displays a single post', function () {
    $post = Post::factory()->create();

    $response = $this->get(route('posts.show', $post));

    $response->assertStatus(200);
    $response->assertViewIs('posts.show');
    $response->assertSee($post->title);
    $response->assertSee($post->content);
});

test('show returns 404 for non-existent post', function () {
    $response = $this->get(route('posts.show', 9999));

    $response->assertStatus(404);
});

// Edit and Update Tests
test('edit page displays the form with existing data', function () {
    $post = Post::factory()->create();

    $response = $this->get(route('posts.edit', $post));

    $response->assertStatus(200);
    $response->assertViewIs('posts.edit');
    $response->assertSee($post->title);
    $response->assertSee($post->content);
});

test('a post can be updated', function () {
    $post = Post::factory()->create([
        'title' => 'Original Title',
        'slug' => 'original-title',
        'content' => 'Original content.',
        'status' => 'draft',
    ]);

    $response = $this->put(route('posts.update', $post), [
        'title' => 'Updated Title',
        'content' => 'Updated content.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post updated successfully.');

    $this->assertDatabaseHas('posts', [
        'id' => $post->id,
        'title' => 'Updated Title',
        'slug' => 'updated-title',
        'content' => 'Updated content.',
        'status' => 'publish',
    ]);
});

test('update validates required fields', function () {
    $post = Post::factory()->create();

    $response = $this->put(route('posts.update', $post), []);

    $response->assertSessionHasErrors(['title', 'content', 'status']);
});

test('update allows same slug for the same post', function () {
    $post = Post::factory()->create([
        'title' => 'Keep This Title',
        'slug' => 'keep-this-title',
    ]);

    $response = $this->put(route('posts.update', $post), [
        'title' => 'Keep This Title',
        'content' => 'Updated content only.',
        'status' => 'publish',
    ]);

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHasNoErrors();
});

// Delete Tests
test('a post can be deleted', function () {
    $post = Post::factory()->create();

    $response = $this->delete(route('posts.destroy', $post));

    $response->assertRedirect(route('posts.index'));
    $response->assertSessionHas('success', 'Post deleted successfully.');

    $this->assertDatabaseMissing('posts', [
        'id' => $post->id,
    ]);
});

test('deleting a non-existent post returns 404', function () {
    $response = $this->delete(route('posts.destroy', 9999));

    $response->assertStatus(404);
});
```


## Conclusion {#conclusion}

In this tutorial, we wrote 19 feature tests using Pest to cover every CRUD operation in our Laravel 13 blog application. Each test verifies not just the HTTP response, but also the database state, session data, and view content.

Here are the key takeaways:

- **Pest's syntax is cleaner than PHPUnit.** Writing `test('description', function () { ... })` is more readable than creating class methods with `/** @test */` annotations. The test descriptions read like plain English.
- **`RefreshDatabase` keeps tests isolated.** Each test starts with a clean database, so the order in which tests run does not matter.
- **Model factories make test data easy.** With `Post::factory()->create()`, you generate realistic data in one line. You can override specific fields when you need precise values for your assertions.
- **Test both happy paths and edge cases.** We tested not only that valid data gets stored correctly, but also that invalid data is rejected by validation. This catches bugs before they reach production.
- **Slug uniqueness needs a specific test.** The edge case where updating a post without changing its title should not trigger a uniqueness error is easy to overlook. Writing a test for it documents the expected behavior and prevents regressions.
- **Run tests frequently.** Get into the habit of running `php artisan test` after every change. The faster your feedback loop, the easier it is to track down issues.

From here, you can extend the test suite with additional scenarios like testing pagination, testing that draft posts display differently from published ones, or adding authentication tests when you introduce login functionality.

In the next tutorial, we will  [refactor our Controller with Form Request Validation](https://qadrlabs.com/post/laravel-13-refactor-your-controller-with-form-request-validation).