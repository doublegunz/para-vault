## 1. Before You Begin

Feature tests exercise the whole application, which is valuable but slow. Some logic is self-contained enough that you do not need the database, routing, or views to test it. Unit tests focus on small, isolated pieces of code: a single method, a single accessor, a single calculation. They run in milliseconds because they do not touch external resources, which encourages you to write many of them and run them frequently.

This lesson teaches unit testing in Laravel using Pest. You will test the Entry model's accessors (excerpt, reading time) and scopes (search, recent) without involving the database. You will also learn when to choose unit tests versus feature tests, because each type has its place. By the end, you will have a small unit test suite alongside the feature tests, giving you two layers of test coverage: fast focused tests for individual logic and broader tests for end-to-end flows.

### What You'll Build

You will write unit tests for the excerpt accessor, reading time accessor, title mutator, and the `scopeSearch` method.

### What You'll Learn

- ✅ Unit test vs. feature test: when to use each
- ✅ Testing accessors without the database
- ✅ Testing mutators
- ✅ Testing scopes with a minimal database setup
- ✅ The `dataset()` helper for testing with multiple inputs
- ✅ Running only unit tests with `--testsuite=Unit`

### What You'll Need

- Lesson 11 completed with Pest installed

---

## 2. Feature Test vs. Unit Test

Before writing unit tests, you need to understand when to prefer them. Feature tests are broader but slower. Unit tests are narrower but faster. A good test suite uses both: many unit tests for individual logic, fewer feature tests for important user flows.

Consider the `excerpt` accessor from Lesson 3. A feature test would create a user, create an entry, visit the index page, and check the HTML for the truncated text. That works, but it requires a database, HTTP routing, and Blade rendering. A unit test just creates an Entry in memory, sets its content, and checks the excerpt output. Same logic is tested, but the unit test runs in under 1 ms while the feature test takes 50 ms or more.

The rule of thumb is: write unit tests for pure logic that does not need HTTP or the database, and write feature tests for user-facing flows (login, CRUD, authorization). Scopes, accessors, mutators, and helper classes are perfect unit test candidates because they are stateless or operate entirely on in-memory data.

---

## 3. Your First Unit Test

The Entry model has several accessors and a mutator that are pure PHP logic: they operate on in-memory properties and do not touch the database. These are ideal unit test candidates. In this section you will generate the unit test file and write tests for the `excerpt` accessor, `reading_time` accessor, and `title` mutator.

### Step 1: Generate the Unit Test

Run the following Artisan command to create a unit test file.

```bash
php artisan make:test EntryUnitTest --unit
```

The `--unit` flag places the test in `tests/Unit/` instead of `tests/Feature/`, and the skeleton does not include HTTP helpers by default, which keeps unit tests focused on pure PHP logic.

### Step 2: Test the Excerpt Accessor

Open `tests/Unit/EntryUnitTest.php` and replace its content with the following two tests.

```php
<?php

use App\Models\Entry;

test('excerpt truncates content to 100 characters', function () {
    $entry = new Entry([
        'content' => str_repeat('A', 200),
    ]);

    expect($entry->excerpt)->toHaveLength(103);
});

test('excerpt keeps short content as-is', function () {
    $entry = new Entry(['content' => 'Short content']);

    expect($entry->excerpt)->toBe('Short content');
});
```

Examining these tests carefully: we use `new Entry([...])` to create an Entry model in memory without saving it to the database. Mass assignment through the constructor works because `content` is listed in the `#[Fillable]` attribute. The key insight is that we do not call `->save()`, so no database query happens at all. We test the accessor logic in pure PHP.

The first test creates content of 200 characters using PHP's `str_repeat` function and expects the excerpt to be 103 characters total: the first 100 characters plus the default three-character "..." ellipsis appended by Laravel's `str()->limit()` helper. The second test uses content shorter than 100 characters, so no truncation should happen and the `excerpt` output should match the original content exactly.

### Step 3: Test the Reading Time Accessor

Add two more tests to the same file, below the excerpt tests.

```php
test('reading time is at least 1 minute for short content', function () {
    $entry = new Entry(['content' => 'Just a few words.']);

    expect($entry->reading_time)->toBe(1);
});

test('reading time calculates based on 200 words per minute', function () {
    $entry = new Entry([
        'content' => str_repeat('word ', 400),
    ]);

    expect($entry->reading_time)->toBe(2);
});
```

Each test exercises a specific edge case of the accessor. The first confirms the `max(1, ...)` minimum floor: even with fewer than 200 words, `reading_time` is never less than 1 minute. The second confirms the division formula: 400 words divided by 200 words-per-minute equals exactly 2 minutes. These two tests give you confidence that the formula is correct, and any future refactoring that breaks the math will be caught immediately.

### Step 4: Test the Title Mutator

Add one more test for the title mutator.

```php
test('title mutator capitalizes and trims', function () {
    $entry = new Entry();
    $entry->title = '  hello world  ';

    expect($entry->title)->toBe('Hello world');
});
```

Assigning to `$entry->title` triggers the mutator's `set` callback, which trims whitespace and capitalizes the first character. After the assignment, reading `$entry->title` returns the transformed value. No database interaction is needed because mutators run on the model object itself during property assignment; the result reflects what would be stored if you called `save()`.

---

## 4. Testing Scopes with a Minimal Database

Some tests need the database, like scope tests that actually execute SQL queries. Use `RefreshDatabase` selectively in unit tests for these cases. Some purists argue that scope tests belong in feature tests because they touch the database, but they remain narrow and fast enough to fit comfortably in the unit test folder.

### Step 1: Test the Search Scope

Open `tests/Unit/EntryUnitTest.php` and add the `User` import and the `uses()` configuration, then add the following scope tests.

```php
use App\Models\User;

uses(Tests\TestCase::class, \Illuminate\Foundation\Testing\RefreshDatabase::class);

test('search scope finds entries by title', function () {
    $user = User::factory()->create();
    Entry::factory()->for($user)->create(['title' => 'Vacation Diary']);
    Entry::factory()->for($user)->create(['title' => 'Work Notes']);

    $results = Entry::search('vacation')->get();

    expect($results)->toHaveCount(1);
    expect($results->first()->title)->toBe('Vacation Diary');
});

test('search scope finds entries by content', function () {
    $user = User::factory()->create();
    Entry::factory()->for($user)->create([
        'title' => 'Random title',
        'content' => 'I went on vacation yesterday.',
    ]);

    $results = Entry::search('vacation')->get();

    expect($results)->toHaveCount(1);
});

test('search scope is case insensitive', function () {
    $user = User::factory()->create();
    Entry::factory()->for($user)->create(['title' => 'Vacation Diary']);

    expect(Entry::search('VACATION')->count())->toBe(1);
    expect(Entry::search('vacation')->count())->toBe(1);
    expect(Entry::search('VaCaTiOn')->count())->toBe(1);
});
```

Let us look at these scope tests closely. The `uses(...)` call takes two arguments: `Tests\TestCase::class` bootstraps the full Laravel application (service container, database connection, facades) so that Eloquent factories and query scopes work correctly inside unit tests. Without it, calling `User::factory()->create()` throws a "facade root has not been set" error because there is no application container running. `\Illuminate\Foundation\Testing\RefreshDatabase::class` ensures each test starts with a clean database. In the first test, we create two entries with different titles, then call the scope and expect exactly one result matching "vacation". The `expect(...)->toHaveCount(1)` assertion confirms the Collection's size, and `toBe(...)` on `title` confirms the correct entry was matched.

The second test confirms that the scope also searches the content field, not just the title. The third test verifies case insensitivity by running the same search with three different capitalizations and expecting the same count each time. This is important because SQL LIKE is case-insensitive by default in MySQL but case-sensitive in some databases like PostgreSQL with certain collations, so explicit tests catch subtle differences when switching databases.

### Step 2: Test Multiple Inputs with Datasets

Pest lets you run the same test with multiple inputs using `->with(...)`. Add the following dataset-driven test to replace the three separate case sensitivity tests with a single parametrized test.

```php
test('search scope matches various capitalizations', function (string $query) {
    $user = User::factory()->create();
    Entry::factory()->for($user)->create(['title' => 'Vacation Diary']);

    expect(Entry::search($query)->count())->toBe(1);
})->with([
    'lowercase' => 'vacation',
    'uppercase' => 'VACATION',
    'mixed case' => 'VaCaTiOn',
    'partial match' => 'acat',
]);
```

This single test runs four times, once per dataset entry. The associative array keys become the test labels in Pest's output, making failures easy to identify because the label "uppercase" or "partial match" appears next to the failure. This pattern is cleaner than writing four separate tests because the setup and assertion logic is defined once. Using `->with()` is especially valuable for validation tests with many valid and invalid inputs, or boundary tests with edge values.

---

## 5. Run the Unit Tests

With the accessor, mutator, and scope tests in place, you can now run the suite to confirm everything passes. Pest provides several flags for controlling which tests run and how much detail to show. The commands below take you from a full run down to a targeted unit-only run with profiling.

### Step 1: Run All Tests

Run the following command to execute the full test suite.

```bash
php artisan test
```

You should see the unit tests listed alongside the feature tests, with Pest clearly labeling each group. Pay attention to the duration column; unit tests should be noticeably faster than feature tests.

### Step 2: Run Only Unit Tests

Run the following command to execute only the unit test suite.

```bash
php artisan test --testsuite=Unit
```

The `--testsuite` flag runs only tests in the specified suite. This is useful during development when you are iterating on a specific piece of logic; running the fast unit tests alone gives tight feedback without waiting for the slower feature tests.

### Step 3: See Timing

Run the following command to see how long each test takes.

```bash
php artisan test --profile
```

The `--profile` flag shows the slowest tests so you can identify candidates for optimization. Tests taking over 500 ms are usually good candidates: extract logic into a smaller unit, mock expensive dependencies, or avoid database calls where possible.

### Step 4: Check Test Coverage (Optional)

If Xdebug is installed, you can measure code coverage by running the following command.

```bash
php artisan test --coverage
```

This reports what percentage of your code is exercised by tests. A score of 100% is not always the goal (some code like configuration files or CLI commands is hard to test), but seeing which files have 0% coverage often reveals untested critical paths that need attention.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes when writing unit tests for model accessors, mutators, and scopes.

**Error 1: Calling `->save()` inside a unit test for accessor testing, unnecessarily touching the database.**

This error occurs when a developer saves the model to the database just to test an accessor, even though accessors work entirely on in-memory model instances without any persistence.

```php
// Wrong: save() queries the database, requires a connection, and slows the test
test('excerpt works', function () {
    $entry = new Entry(['content' => str_repeat('A', 200)]);
    $entry->save();
    expect($entry->excerpt)->toHaveLength(103);
});

// Correct: accessors work on unsaved models, no database needed
test('excerpt works', function () {
    $entry = new Entry(['content' => str_repeat('A', 200)]);
    expect($entry->excerpt)->toHaveLength(103);
});
```

The wrong version calls `save()` before testing the accessor. This requires a database connection, triggers migrations (if `RefreshDatabase` is used), and makes the test an order of magnitude slower than necessary. The correct version skips `save()` entirely because the `excerpt` accessor reads `$this->content`, which is available the moment the model is instantiated with the array constructor.

---

**Error 2: Using `Entry::factory()` without the `HasFactory` trait on the Entry model.**

This error occurs when you try to use the factory helper on a model that does not include the `HasFactory` trait. Laravel cannot find the static `factory()` method and throws a BadMethodCallException.

```php
// Wrong: HasFactory trait not present on the Entry model
class Entry extends Model
{
    use SoftDeletes;
    // HasFactory is missing
}

Entry::factory()->create(); // Throws BadMethodCallException: factory method not found

// Correct: include HasFactory so the factory() method is available
class Entry extends Model
{
    use HasFactory, SoftDeletes;
}

Entry::factory()->create(); // Works correctly
```

The wrong version omits `HasFactory` from the Entry model's trait list. Every `Entry::factory()` call in tests then throws an exception, breaking all tests that use the factory. The correct version adds `use HasFactory, SoftDeletes;` to the model. Most Laravel models have `HasFactory` by default when generated with `make:model --factory`, but models created manually may not.

---

**Error 3: Tests sharing database state without `RefreshDatabase`, causing count assertions to fail unpredictably.**

This error occurs when multiple tests write to the database and `RefreshDatabase` is not applied. Earlier tests leave records behind, and later tests see them, causing assertions about record counts to pass or fail depending on test execution order.

```php
// Wrong: no database reset, tests contaminate each other
test('first test creates one entry', function () {
    $user = User::factory()->create();
    Entry::factory()->for($user)->create(['title' => 'A']);
    expect(Entry::count())->toBe(1); // Passes only if this runs before other entry-creating tests
});

test('second test expects empty database', function () {
    expect(Entry::count())->toBe(0); // Fails if first test already ran
});

// Correct: RefreshDatabase resets the database before each test
uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

test('first test creates one entry', function () {
    $user = User::factory()->create();
    Entry::factory()->for($user)->create(['title' => 'A']);
    expect(Entry::count())->toBe(1); // Always passes because database is clean
});

test('second test expects empty database', function () {
    expect(Entry::count())->toBe(0); // Always passes because database was reset
});
```

Without `RefreshDatabase`, the `Entry::count()` in the second test includes entries from the first test, causing a false failure. With `RefreshDatabase`, each test starts with a completely empty database, so count assertions are always correct regardless of execution order.

---

## 7. Exercises

Practice writing unit tests independently before looking at the solutions. Each exercise extends the `EntryUnitTest.php` file you built in this lesson.

**Exercise 1:** Write unit tests for the `scopeRecent` method. Create entries with different `created_at` timestamps and verify the scope returns only those from within the last 7 days.

**Exercise 2:** Write unit tests for the `scopeByUser` method. Create two users, each with two entries, and assert that `Entry::byUser($user1->id)->count()` returns exactly 2.

**Exercise 3:** Write a dataset test for the reading time accessor with multiple content lengths: 50 words, 200 words, 400 words, and 500 words, each with their expected reading time in minutes.

---

## 8. Solutions

Compare your solutions with the ones below. Pay attention to the factory calls and assertion style, not just the code structure.

**Solution for Exercise 1:**

Add the following test to `tests/Unit/EntryUnitTest.php`.

```php
test('recent scope returns only entries from the last 7 days', function () {
    $user = User::factory()->create();

    Entry::factory()->for($user)->create(['created_at' => now()->subDays(3)]);
    Entry::factory()->for($user)->create(['created_at' => now()->subDays(10)]);

    expect(Entry::recent()->count())->toBe(1);
});
```

We create two entries with explicit `created_at` values: one from 3 days ago (within the 7-day window) and one from 10 days ago (outside the window). The `created_at` array key on the factory overrides the default timestamp. The `scopeRecent` adds a `WHERE created_at >= ?` constraint using `now()->subDays(7)`, so only the 3-day-old entry matches. The `toBe(1)` assertion verifies exactly one entry was found.

---

**Solution for Exercise 2:**

Add the following test to `tests/Unit/EntryUnitTest.php`.

```php
test('byUser scope returns only entries belonging to the given user', function () {
    $user1 = User::factory()->create();
    $user2 = User::factory()->create();

    Entry::factory()->for($user1)->count(2)->create();
    Entry::factory()->for($user2)->count(2)->create();

    expect(Entry::byUser($user1->id)->count())->toBe(2);
    expect(Entry::byUser($user2->id)->count())->toBe(2);
});
```

We create two users with two entries each, four entries total in the database. The `scopeByUser` adds a `WHERE user_id = ?` constraint, so each call returns exactly the 2 entries belonging to that user. Running the assertion for both users confirms the scope does not bleed across user boundaries: `$user2`'s entries are invisible when filtering by `$user1->id`, and vice versa. `RefreshDatabase` ensures the four entries are the only records present, making the count assertion reliable.

---

**Solution for Exercise 3:**

Add the following dataset test to `tests/Unit/EntryUnitTest.php`.

```php
test('reading time calculates correctly for various word counts', function (int $wordCount, int $expectedMinutes) {
    $content = str_repeat('word ', $wordCount);
    $entry = new Entry(['content' => $content]);

    expect($entry->reading_time)->toBe($expectedMinutes);
})->with([
    [50, 1],
    [200, 1],
    [400, 2],
    [500, 3],
]);
```

Each dataset row is an array of `[$wordCount, $expectedMinutes]`. The test function receives them as typed parameters. The first row (50 words) confirms the minimum floor of 1 minute. The second (200 words) verifies that the exact boundary of one reading-minute is still rounded to 1. The third (400 words) verifies 400 / 200 = exactly 2 minutes. The fourth (500 words) verifies that 500 / 200 = 2.5, which `ceil()` rounds up to 3, confirming that partial minutes always round up. This pattern catches off-by-one errors and rounding bugs that a single test case would miss.

---

## Next Up - Lesson 13

In this lesson you built a focused unit test suite for Catatku's model logic. You tested the `excerpt` accessor by instantiating the Entry model in memory without saving to the database, verifying both the truncation case (103 characters including "...") and the short content case (returned unchanged). You tested the `reading_time` accessor at its minimum floor and at the exact formula boundary. You tested the title mutator by assigning directly and reading the transformed result. For scope tests that require SQL, you applied `RefreshDatabase`, used the Entry factory to create records with controlled timestamps, and used `->with([...])` datasets to test multiple search queries in a single parametrized test.

In Lesson 13, you will learn queues and jobs: how to defer slow operations like sending emails to background workers, keeping web requests fast and responsive even when triggering expensive tasks.