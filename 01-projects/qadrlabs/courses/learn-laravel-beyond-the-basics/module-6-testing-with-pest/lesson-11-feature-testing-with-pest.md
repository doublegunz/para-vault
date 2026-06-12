## 1. Before You Begin

Every time you add a feature, you introduce the possibility of breaking something else. Without tests, you have to manually click through the app to verify nothing regressed. With tests, a single command verifies the entire application in seconds. Feature tests simulate HTTP requests and check responses, behaving like a very fast and very patient user who never gets bored clicking every link.

This lesson teaches you to write feature tests for Catatku using Pest, a modern PHP testing framework that is friendly and readable. Pest is built on top of PHPUnit (the traditional PHP test runner), but has a cleaner syntax inspired by JavaScript's Jest. You will write tests that create users, make HTTP requests, and assert that the responses contain what you expect. Tests run in an isolated test database so they do not pollute your development data.

### What You'll Build

You will install Pest, configure a test database using SQLite in-memory, and write feature tests for the entry CRUD flow: guests are redirected, authenticated users can create entries, only owners can edit their own entries, and comment notifications are dispatched.

### What You'll Learn

- ✅ Installing Pest
- ✅ The `RefreshDatabase` trait
- ✅ Writing feature tests with `it()`, `test()`, `expect()`
- ✅ HTTP assertions: `get()`, `post()`, `assertStatus()`, `assertSee()`
- ✅ Authenticating in tests with `actingAs()`
- ✅ Using factories to create test data
- ✅ Running tests with `php artisan test`

### What You'll Need

- Lesson 10 completed

---

## 2. Install Pest

The Catatku app was set up with PHPUnit, Laravel's default test runner. Before installing Pest, you need to remove PHPUnit to avoid dependency conflicts. You will then install two packages: `pestphp/pest` (the core test framework) and `pestphp/pest-plugin-laravel` (the Laravel integration that provides test helpers like `actingAs()`, `get()`, and `post()` inside Pest test functions).

### Step 1: Remove PHPUnit

Run the following command to uninstall PHPUnit from the project.

```bash
composer remove phpunit/phpunit
```

Removing PHPUnit before installing Pest prevents version conflicts between the two frameworks, since Pest is built on top of PHPUnit internally but manages its own compatible version.

### Step 2: Install the Pest Packages

Run the following command to install Pest and the Laravel plugin together.

```bash
composer require pestphp/pest pestphp/pest-plugin-laravel --dev --with-all-dependencies
```

The `--dev` flag marks both packages as development-only dependencies. The `--with-all-dependencies` flag resolves compatible versions for all transitive dependencies at once. The `pestphp/pest-plugin-laravel` package is required for Laravel-specific helpers: without it, calling `actingAs()`, `get()`, or `post()` inside a test function will throw a fatal error saying the function is undefined.

### Step 3: Initialize Pest

Run the following command to complete the Pest setup.

```bash
./vendor/bin/pest --init
```

This command creates `tests/Pest.php`, which is the global configuration file where you can define shared helpers, dataset providers, and `uses()` calls that apply to all test files. It also updates `phpunit.xml` to register Pest as the test runner.

### Step 4: Verify Installation

Run the test suite to confirm Pest is working correctly.

```bash
php artisan test
```

You should see Pest's output with colored pass/fail indicators. If a default example test exists at `tests/Feature/ExampleTest.php`, it should pass. If you see red failures, the error message usually points directly to what needs to be configured.

---

## 3. Configure the Test Database

Tests should run against a separate database so they do not affect your development data. The fastest approach is SQLite in-memory, which creates a fresh database per test run entirely in RAM. This keeps the test suite fast (no disk I/O) and guarantees isolation between runs.

### Step 1: Edit phpunit.xml

Open `phpunit.xml` and update the `<php>` section to configure all test-specific environment variables.

```xml
<php>
    <env name="APP_ENV" value="testing"/>
    <env name="DB_CONNECTION" value="sqlite"/>
    <env name="DB_DATABASE" value=":memory:"/>
    <env name="MAIL_MAILER" value="array"/>
    <env name="QUEUE_CONNECTION" value="sync"/>
    <env name="SESSION_DRIVER" value="array"/>
    <env name="CACHE_STORE" value="array"/>
</php>
```

Each of these environment variables serves a specific purpose in the test environment. `APP_ENV=testing` switches Laravel into testing mode, which disables certain safety checks and enables test-specific behavior. `DB_CONNECTION=sqlite` with `DB_DATABASE=:memory:` uses an in-memory SQLite database that exists only during the test run; no file is written and nothing persists between runs. `MAIL_MAILER=array` captures sent emails in memory instead of actually delivering them, so you can assert that a specific email was dispatched without contacting an external mail server. `QUEUE_CONNECTION=sync` processes queued jobs immediately rather than deferring them to a background worker. `SESSION_DRIVER=array` and `CACHE_STORE=array` use memory-based storage for the same reason. These values override the settings in `.env`, but only when running tests.

---

## 4. Write Your First Feature Test

Feature tests cover entire HTTP request cycles: request in, response out. You will write tests that cover the main entry flows, including guest redirects, authenticated access, authorization enforcement, soft deletes, and validation. Each test is a single scenario that should pass or fail independently of the others.

### Step 1: Generate a Test File

Run the following command to create the feature test file.

```bash
php artisan make:test EntryTest
```

This creates `tests/Feature/EntryTest.php`. By default it uses the PHPUnit class style; we will rewrite it in Pest's functional style, which is cleaner and more readable.

### Step 2: Write the Tests

Open `tests/Feature/EntryTest.php` and replace its content with the following.

```php
<?php

use App\Models\Entry;
use App\Models\User;

use function Pest\Laravel\{actingAs, get, post, put, delete};

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

test('guest is redirected from entries index to login', function () {
    get('/entries')->assertRedirect('/login');
});

test('authenticated user can view entries index', function () {
    $user = User::factory()->create();

    actingAs($user)->get('/entries')
        ->assertStatus(200)
        ->assertSee('Entries');
});

test('authenticated user can create an entry', function () {
    $user = User::factory()->create();

    actingAs($user)->post('/entries', [
        'title' => 'Test Entry',
        'content' => 'This is a test entry.',
    ])->assertRedirect(route('entries.index'));

    expect(Entry::count())->toBe(1);
    expect(Entry::first())
        ->title->toBe('Test Entry')
        ->user_id->toBe($user->id);
});

test('user cannot edit another user entry', function () {
    $userA = User::factory()->create();
    $userB = User::factory()->create();
    $entry = Entry::factory()->for($userA)->create();

    actingAs($userB)->get(route('entries.edit', $entry))
        ->assertStatus(403);
});

test('user can delete their own entry', function () {
    $user = User::factory()->create();
    $entry = Entry::factory()->for($user)->create();

    actingAs($user)->delete(route('entries.destroy', $entry))
        ->assertRedirect(route('entries.index'));

    expect($entry->fresh()->trashed())->toBeTrue();
});

test('validation fails on empty title', function () {
    $user = User::factory()->create();

    actingAs($user)->post('/entries', ['content' => 'No title'])
        ->assertSessionHasErrors('title');
});
```

Let us walk through each part of this test file slowly, because there is a lot of functionality packed into a small amount of code. At the top, the `use` statements import the models we will use and import Pest's HTTP helper functions (`actingAs`, `get`, `post`, etc.) as named function imports from the `Pest\Laravel` namespace. The `uses(\Illuminate\Foundation\Testing\RefreshDatabase::class)` call applies the `RefreshDatabase` trait to every test in this file, which wipes the database and re-runs migrations before each test to guarantee isolation. Without this, tests could contaminate each other based on execution order.

The first test verifies unauthenticated access. `get('/entries')` simulates an HTTP GET request, and `assertRedirect('/login')` asserts the response is a redirect to the login page. No browser runs; Laravel dispatches the request internally through its routing system, which is what makes tests fast. The second test creates a user with `User::factory()->create()` (which uses the factory to generate fake data), calls `actingAs($user)` to authenticate as that user, and chains `->get('/entries')` for the HTTP request. The assertions confirm the response is OK and contains expected text.

The third test (entry creation) sends a POST request with form data and expects a redirect on success. After the request, we use `expect()` to make Pest-style assertions about the database state: exactly one entry should exist, and its title and `user_id` should match. The chained `->title->toBe(...)` syntax is Pest's fluent property access that reads naturally.

The fourth test proves that the policy from Lesson 5 works: User B attempting to edit User A's entry gets a 403 Forbidden. The `->for($userA)` helper on the factory sets the ownership relationship automatically. The fifth test verifies soft delete from Lesson 4: after deletion, the entry should be trashed. The sixth test verifies validation: submitting without a title should flash errors, which `assertSessionHasErrors('title')` checks.

### Step 3: Create an Entry Factory

Tests reference `Entry::factory()`, but the factory only exists if you generate it.

```bash
php artisan make:factory EntryFactory --model=Entry
```

Open `database/factories/EntryFactory.php` and define the default data.

```php
<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class EntryFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'title' => fake()->sentence(6),
            'content' => fake()->paragraphs(3, true),
        ];
    }
}
```

Examining the factory: the `definition()` method returns an array of default column values for a new entry. `User::factory()` is a nested factory reference: if you create an Entry without specifying a user, a new user is auto-generated and its ID is used. The `fake()` helper returns a `Faker` instance that generates realistic test data: `sentence(6)` produces something like "The quick brown fox jumps over", and `paragraphs(3, true)` produces three paragraphs of lorem ipsum as a single concatenated string. Using generated data makes tests less brittle than hardcoded strings because each run uses slightly different values.

You also need to add the `HasFactory` trait to the Entry model if it is not already there. Open `app/Models/Entry.php` and ensure the trait is included.

```php
<?php
// ... others lines of code
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Entry extends Model
{
    use HasFactory, SoftDeletes;

    // ... other methods and properties
}
```

The `HasFactory` trait adds the `factory()` static method to the model, which returns an `EntryFactory` instance ready to build entries with chained methods like `->for($user)` and `->create()`.

---

## 5. Run the Tests

Pest provides several ways to run tests depending on how much feedback you need. Running the full suite after every change is slow; filtering to a specific file or test name gives you faster iteration while you are fixing a failure.

### Step 1: Run All Tests

Run the following command to execute the full test suite.

```bash
php artisan test
```

You should see output similar to the following.

```
  PASS  Tests\Feature\EntryTest
  ✓ guest is redirected from entries index to login
  ✓ authenticated user can view entries index
  ✓ authenticated user can create an entry
  ✓ user cannot edit another user entry
  ✓ user can delete their own entry
  ✓ validation fails on empty title

  Tests:    6 passed (12 assertions)
  Duration: 0.45s
```

Pest shows a green check for every passing test and a red X for failures, along with a failure reason that usually points directly at the problem. The assertion count reflects that a single test can make multiple assertions.

### Step 2: Run a Single Test File

To run only the tests in a specific file, pass its class name to the `--filter` flag.

```bash
php artisan test --filter=EntryTest
```

The `--filter` flag lets you focus on one file or one specific test by name. This is useful when you are fixing a single failing test and do not want to wait for the entire suite.

### Step 3: Run a Single Test

To run a single test by name, pass the exact test description string to `--filter`.

```bash
php artisan test --filter="user can delete their own entry"
```

Passing the exact test name to `--filter` runs only that test, which is the fastest feedback loop when iterating on a specific failure.

### Step 4: Debug a Failing Test

If a test fails, Pest shows the failure with a helpful message. A response status of 500 means an exception happened in the controller. Check `storage/logs/laravel.log` for the exception details, or add `->dumpSession()` inside the test chain to inspect session data (which often reveals validation errors or other clues) at the point where the assertion fails.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes when writing feature tests with Pest and Laravel.

**Error 1: Forgetting the `RefreshDatabase` trait, causing tests to share database state.**

This error occurs when tests write to the database but the `RefreshDatabase` trait is not applied. Each test leaves its data behind, and the next test sees it. Assertions about record counts become unreliable because the count depends on which tests ran before.

```php
// Wrong: no database reset, tests contaminate each other
uses(); // RefreshDatabase not included

test('can create entry', function () {
    $user = User::factory()->create();
    actingAs($user)->post('/entries', ['title' => 'A', 'content' => 'B']);
    expect(Entry::count())->toBe(1); // Passes only if no previous tests created entries
});

// Correct: RefreshDatabase resets the database before each test
uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

test('can create entry', function () {
    $user = User::factory()->create();
    actingAs($user)->post('/entries', ['title' => 'A', 'content' => 'B']);
    expect(Entry::count())->toBe(1); // Always correct because database is clean
});
```

Without `RefreshDatabase`, a test that asserts `Entry::count() === 1` would fail if a previous test already created entries. With `RefreshDatabase`, each test starts with a completely empty database, so count assertions are reliable and test execution order does not matter.

---

**Error 2: Not calling `actingAs()` before hitting a protected route.**

This error occurs when you test a protected route (one behind the `auth` middleware) without authenticating first. The `auth` middleware redirects unauthenticated requests to the login page with a 302 response, causing an assertion that expects a 200 to fail.

```php
// Wrong: no authentication, auth middleware redirects to /login
test('can view entries', function () {
    get('/entries')->assertStatus(200); // Fails! Receives 302 redirect
});

// Correct: authenticate as a user before accessing protected routes
test('can view entries', function () {
    $user = User::factory()->create();
    actingAs($user)->get('/entries')->assertStatus(200);
});
```

The wrong version makes a bare `get('/entries')` call with no authenticated user. Since the entries route requires authentication, the middleware returns a 302 redirect and the `assertStatus(200)` assertion fails. The correct version creates a real user with the factory and passes them to `actingAs()`, which authenticates the request without going through the login form.

---

**Error 3: Asserting on a stale in-memory model after an HTTP request modified the database.**

This error occurs when you capture a model variable before making a request, then assert on it after. The variable holds the in-memory state from before the request, not the current database state.

```php
// Wrong: $entry is the in-memory copy, it was not refreshed after the delete request
test('entry is deleted', function () {
    $user = User::factory()->create();
    $entry = Entry::factory()->for($user)->create();

    actingAs($user)->delete(route('entries.destroy', $entry));

    expect($entry->trashed())->toBeTrue(); // Fails! $entry still has deleted_at = null
});

// Correct: call fresh() to reload the model from the database after the request
test('entry is deleted', function () {
    $user = User::factory()->create();
    $entry = Entry::factory()->for($user)->create();

    actingAs($user)->delete(route('entries.destroy', $entry));

    expect($entry->fresh()->trashed())->toBeTrue(); // Passes! fresh() reloads from DB
});
```

The wrong version asserts `$entry->trashed()` on the original object, which still has `deleted_at = null` in memory because the deletion happened inside the HTTP request (not directly on this variable). The correct version calls `$entry->fresh()`, which executes a new `SELECT` query and returns a new model instance reflecting the current database row, where `deleted_at` is now set.

---

## 7. Exercises

Write each test independently, using the patterns from this lesson. Each test should be self-contained: create its own users, entries, and any other data it needs, and make no assumptions about what other tests have left in the database.

**Exercise 1:** Write a test that verifies comments can be posted: create a user, create an entry, act as the user, POST to `/entries/{id}/comments`, and assert the comment was created in the database.

**Exercise 2:** Write a test that verifies the entry list shows entries from the authenticated user but not from others. Create two users, each with one entry, then act as one user and check that only their entry appears in the response.

**Exercise 3:** Write a test that verifies an email is sent when a comment is posted. Use `Mail::fake()` at the start, perform the comment action, then use `Mail::assertSent(NewCommentEmail::class)` to verify.

---

## 8. Solutions

Each solution adds a new test function to `tests/Feature/EntryTest.php`. All tests in that file already have `RefreshDatabase` applied via `uses()`, so they each start with a clean database automatically.

**Solution for Exercise 1:**

Add the following test to `tests/Feature/EntryTest.php`.

```php
test('authenticated user can post a comment', function () {
    $author = User::factory()->create();
    $commenter = User::factory()->create();
    $entry = Entry::factory()->for($author)->create();

    actingAs($commenter)->post("/entries/{$entry->id}/comments", [
        'body' => 'Great entry!',
    ])->assertRedirect();

    expect(\App\Models\Comment::count())->toBe(1);
    expect(\App\Models\Comment::first())
        ->body->toBe('Great entry!')
        ->user_id->toBe($commenter->id)
        ->entry_id->toBe($entry->id);
});
```

The test creates two users so that the comment is posted by someone other than the entry author, which is the realistic scenario. `assertRedirect()` verifies that the controller returned a redirect (the `back()` redirect from Lesson 1) without checking the specific destination. The three `expect()` assertions then confirm the database record was created with the correct body, owner, and entry association. Pest's chained property syntax (`->body->toBe(...)`) reads the model attribute directly, making the assertion clear and concise.

---

**Solution for Exercise 2:**

Add the following test to `tests/Feature/EntryTest.php`.

```php
test('entry index shows only the authenticated users own entries', function () {
    $userA = User::factory()->create();
    $userB = User::factory()->create();

    Entry::factory()->for($userA)->create(['title' => 'User A Entry']);
    Entry::factory()->for($userB)->create(['title' => 'User B Entry']);

    actingAs($userA)->get('/entries')
        ->assertStatus(200)
        ->assertSee('User A Entry')
        ->assertDontSee('User B Entry');
});
```

The test creates two entries with distinct, recognizable titles. After authenticating as User A, the response should contain "User A Entry" but not "User B Entry". `assertSee()` searches the full response body for the given string and fails if it is absent. `assertDontSee()` is the inverse: it fails if the string is found. This test proves that the controller's `auth()->user()->entries()` scope filters correctly, because if it used `Entry::all()` instead, both titles would appear in the response.

---

**Solution for Exercise 3:**

Add the following test to `tests/Feature/EntryTest.php`.

```php
use App\Mail\NewCommentEmail;
use Illuminate\Support\Facades\Mail;

test('email sent when comment is posted on another users entry', function () {
    Mail::fake();

    $author = User::factory()->create();
    $commenter = User::factory()->create();
    $entry = Entry::factory()->for($author)->create();

    actingAs($commenter)->post("/entries/{$entry->id}/comments", [
        'body' => 'Nice entry!',
    ]);

    Mail::assertSent(NewCommentEmail::class, function ($mail) use ($author) {
        return $mail->hasTo($author->email);
    });
});
```

`Mail::fake()` intercepts all mail sending for the duration of this test, preventing actual emails from going out and keeping the test self-contained. After the comment POST, `Mail::assertSent(NewCommentEmail::class, ...)` verifies that at least one `NewCommentEmail` was dispatched. The closure receives the Mailable instance and must return true for the assertion to pass; here we verify the `to` address matches the entry author's email. If the comment notification is missing from the controller or the self-comment guard fires incorrectly, this assertion will fail and tell you which email was (or was not) sent.

---

## Next Up - Lesson 12

In this lesson you set up a complete feature test suite for Catatku using Pest. You configured SQLite in-memory for fast, isolated test runs and applied `RefreshDatabase` to guarantee each test starts with a clean slate. You used `User::factory()->create()` and `Entry::factory()->for($user)->create()` to build realistic test data without manual SQL, and `actingAs($user)` to authenticate requests without going through the login form. You tested authorization (403 for unauthorized access), soft deletes (checking `trashed()` after deletion), validation (asserting on session errors), and email dispatch (using `Mail::fake()` and `Mail::assertSent`).

In Lesson 12, you will learn unit testing: how to test individual methods, accessors, mutators, and scopes in isolation without HTTP, routing, or views, using Pest's `dataset()` helper to test multiple inputs in a single test.