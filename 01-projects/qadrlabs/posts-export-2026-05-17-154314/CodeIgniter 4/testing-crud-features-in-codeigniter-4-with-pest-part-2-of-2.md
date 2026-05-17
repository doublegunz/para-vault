---
title: "Testing CRUD Features in CodeIgniter 4 with Pest (Part 2 of 2)"
slug: "testing-crud-features-in-codeigniter-4-with-pest-part-2-of-2"
category: "CodeIgniter 4"
date: "2026-05-06"
status: "published"
---

You have a working [BookShelf application from Part 1](https://qadrlabs.com/post/building-a-crud-feature-in-codeigniter-4-a-bookshelf-catalog-part-1-of-2). The forms work, validation rejects bad input, redirects keep the navigation clean, and flash messages confirm every action. The application is ready for users. The trouble is that you cannot prove any of this stays working tomorrow. The next time you change a validation rule, refactor the controller, or upgrade CodeIgniter, you will be relying entirely on memory and manual clicking to verify that nothing broke. Manual testing scales poorly: it forgets, it gets bored, it skips edge cases, and it never tells you about the third bug it never thought to look for.

This is exactly what an automated test suite fixes. A good suite encodes every important behavior of your application as code that runs in seconds, every time you save a file, every time you push a commit, every time you upgrade a dependency. The first time a test catches a regression you would have missed, the suite has paid for itself. The second time it does, you start trusting it. The third time, you stop deploying without it.

This article is Part 2 of our two-part series on CodeIgniter 4 CRUD development. Part 1 built the BookShelf feature with deliberately testable design choices: thin controllers, validation in one place, the POST-redirect-GET pattern for every write endpoint, and flash messages with predictable keys. Today we cash in on those choices. We will install Pest, bridge it into CodeIgniter 4's testing infrastructure, switch the test database to in-memory SQLite for speed, and write a complete test suite covering every endpoint we built in Part 1. By the end you will have fourteen passing tests, a runtime under one second, and a workflow that lets you change BookShelf with confidence rather than fear.

## Overview {#overview}

The work in Part 2 splits into three movements. The first movement is setup: install Pest, configure the test database, and build the bridge that lets Pest's elegant `it()` syntax sit on top of CodeIgniter's `CIUnitTestCase`. The second movement is helpers: a small factory function that creates book records in tests with sensible defaults. The third and longest movement is the test suite itself, organized into four files that mirror the four CRUD operations from Part 1. We finish by walking through the test lifecycle in detail and listing the pitfalls that catch most developers the first time they wire Pest into CodeIgniter.

### What You'll Build
- A `tests/_support/TestCase.php` base class that bridges Pest to CodeIgniter 4's testing traits
- A configured `phpunit.xml.dist` and `app/Config/Database.php` that use SQLite in-memory for tests, leaving the development MySQL database untouched
- A small helper file at `tests/_support/Helpers.php` with a reusable `makeBook()` and `createBook()` for clean test data
- Fourteen feature tests across four files covering index, create, edit, update, and delete flows
- A data-driven validation test using Pest's dataset feature

### What You'll Learn
- How Pest sits on top of PHPUnit, and how that fact lets it work with any framework that has a PHPUnit-compatible base test class
- How to configure CodeIgniter's `DatabaseTestTrait` and `FeatureTestTrait` for fast, isolated test runs
- How to use SQLite in-memory as the test database for speed without sacrificing realism
- How to write polymorphic, dataset-driven tests that collapse repetitive validation cases into a single readable test
- How CodeIgniter's `seeInDatabase`, `assertRedirectTo`, and `assertSessionHas` assertions let you describe behavior at the right level of abstraction
- The most common pitfalls when first wiring Pest into a CodeIgniter project, and how to recognize their symptoms

### What You'll Need
- The completed BookShelf application from Part 1, with MySQL configured and the migration run
- PHP 8.3 or later with the `sqlite3` extension enabled (this is separate from the `mysqli` extension you used in Part 1)
- Composer 2.x for installing Pest as a development dependency
- Comfort reading short PHP closures and basic assertion syntax

## Why Pest, and Why It Works on CodeIgniter {#why-pest-and-why-it-works-on-codeigniter}

A small amount of context will help everything that follows make sense. CodeIgniter 4 ships with PHPUnit support out of the box. The framework's testing documentation, the example tests in the starter, and every CodeIgniter tutorial you find online all assume PHPUnit. So why are we using Pest at all?

The answer is that Pest is built on top of PHPUnit. Pest does not replace PHPUnit; it wraps PHPUnit with a more expressive, functional API. When you write `it('does something', function () { ... })` in Pest, the framework generates a class that extends `PHPUnit\Framework\TestCase` (or any other base class you specify) and inserts your closure as a test method on that class. Underneath the elegant syntax, every Pest test is a PHPUnit test.

This matters because CodeIgniter's testing traits (`DatabaseTestTrait`, `FeatureTestTrait`, `ControllerTestTrait`, and so on) are designed to work with any class that extends `CIUnitTestCase`, which itself extends PHPUnit's `TestCase`. Pest's `pest()->extend()` configuration tells Pest "use this base class instead of the default `PHPUnit\Framework\TestCase`". When we point Pest at a class that extends `CIUnitTestCase`, every helper that CodeIgniter's traits expose becomes available inside our `it()` closures. The bridge is one configuration line. There is no plugin, no fork, and no compatibility layer.

The benefit of this arrangement is that we get the readability of Pest's syntax (the `it()` and `expect()` style, dataset support, architecture testing, and so on) without losing any of CodeIgniter's testing helpers. The same `$this->get('/books')` and `$this->seeInDatabase('books', [...])` calls that CodeIgniter documents work inside Pest closures, because `$this` inside a closure is bound to an instance of our bridge class, which inherits from `CIUnitTestCase`.

If this seems too good to be true, it is helpful to understand the constraint: Pest is a developer-experience layer, not a different testing engine. Anything that worked in PHPUnit will work in Pest, and anything that does not work in PHPUnit will not work in Pest. This is also why migrating from PHPUnit to Pest is gradual and painless: both frameworks can coexist in the same test suite, sharing the same base classes and the same assertions.

## Step 1: Install Pest as a Development Dependency {#step-1-install-pest-as-a-development-dependency}

Pest is distributed as a Composer package. The current major version at the time of writing is Pest 4, which requires PHP 8.3 or later. Since Part 1 already required PHP 8.3, we are good to go.

From the BookShelf project root, run the following Composer command. The `--with-all-dependencies` flag is important because it lets Composer update related packages (including PHPUnit itself) to compatible versions, which prevents the classic "package conflict" error that catches first-time Pest users.

```bash
composer remove phpunit/phpunit
composer require pestphp/pest --dev --with-all-dependencies
vendor/bin/pest --init
```

The download takes about thirty seconds. After Composer finishes you should see Pest, PHPUnit, and a handful of supporting packages added to your `composer.lock`. The `--dev` flag means these packages will not be installed in production, which keeps the production footprint small.

> **Note**: Do not run `vendor/bin/pest` or ask for its version just yet. The `--init` command generates a default `tests/Pest.php` configuration that expects a `Tests\TestCase` class. CodeIgniter 4 does not include this class natively, so running Pest right now would result in a `TestCaseClassOrTraitNotFound` error. We will fix this in **Step 4** by building a custom CodeIgniter-Pest bridge.

The CodeIgniter starter ships with a `tests/` directory that already contains some example PHPUnit tests in `tests/app/`. We will leave those alone for now and create our new Pest-based feature tests in `tests/Feature/`. Both styles of test can coexist in the same project; PHPUnit-style classes and Pest-style closures will both run when we invoke `vendor/bin/pest`. This is one of the reasons Pest is easy to introduce gradually into existing projects: you do not have to rewrite anything, you just stop adding new tests in the old style.

## Step 2: Configure the Test Database (SQLite In-Memory) {#step-2-configure-the-test-database-sqlite-in-memory}

For development we use MySQL. For tests we will use SQLite in-memory, and the reasons are worth understanding because they apply to most modern test setups.

SQLite in-memory means the database lives entirely in RAM, with no disk file, no network socket, and no separate database server process. The database is created when the first connection opens and destroyed when the last connection closes. For a test suite, this means each test run starts with a completely fresh database, with no contamination from previous runs and no cleanup work required.

Speed is the first benefit. SQLite in-memory has no disk I/O at all, so even thousands of inserts complete in tens of milliseconds. A test suite that talks to a real MySQL server, even on the same machine, can be ten to fifty times slower for the same operations. For a small project the difference is noticeable; for a large project with thousands of tests, it can be the difference between a thirty-second test run and a fifteen-minute one.

Isolation is the second benefit. Tests that share a database, even a development one, can interfere with each other in subtle ways: a test that inserts a row with an explicit ID might collide with a previous run, a test that forgets to clean up after itself might leave data that breaks the next test, and so on. With in-memory SQLite that resets between runs, none of these problems can occur.

Realism is the trade-off. SQLite supports most of standard SQL but differs from MySQL in some details: it has no native ENUM type, its foreign-key enforcement is off by default, its date/time functions differ slightly, and it has more permissive type coercion. For a CRUD application like BookShelf the differences do not matter; we use only basic SQL features that work identically on both engines. For projects that use MySQL-specific features (full-text search, JSON columns with MySQL-specific operators, stored procedures), you would either use a MySQL test database or write tests carefully to avoid the engine-specific features. Most projects find SQLite in-memory perfectly adequate.

Open `app/Config/Database.php` in your editor. Near the top of the file you will find a property called `$default` that holds the connection settings for the default group. Below it, add a new property called `$tests` with the following SQLite configuration. The class already has a `$tests` array shipped by the starter; we are replacing its contents.

```php
public array $tests = [
    'DSN'         => '',
    'hostname'    => '127.0.0.1',
    'username'    => '',
    'password'    => '',
    'database'    => ':memory:',
    'DBDriver'    => 'SQLite3',
    'DBPrefix'    => '',
    'pConnect'    => false,
    'DBDebug'     => true,
    'charset'     => 'utf8',
    'DBCollat'    => 'utf8_general_ci',
    'swapPre'     => '',
    'encrypt'     => false,
    'compress'    => false,
    'strictOn'    => false,
    'failover'    => [],
    'port'        => 3306,
    'foreignKeys' => true,
    'busyTimeout' => 1000,
];
```

A few values in this configuration deserve a closer look. The `database` value of `:memory:` is the SQLite convention for in-memory storage, recognized by every SQLite driver. The `DBDriver` value is `SQLite3`, with the digit included; using `SQLite` without the digit would refer to the older first-generation driver, which CodeIgniter no longer supports. The `foreignKeys` value of `true` is important because SQLite, unlike MySQL, requires foreign-key enforcement to be turned on explicitly per connection. Without this flag, foreign key constraints would be silently ignored, which would make tests pass when they should fail. We do not have foreign keys in the BookShelf schema, but enabling the flag now means future tables with foreign keys will work correctly.

The `DBPrefix` is empty because we want the test tables to have the same names as the production tables. You may notice the framework's example tests use a prefix like `db_`; this is helpful when you run tests against a shared database and want to avoid collisions, but with in-memory SQLite there is no shared state to collide with.

CodeIgniter automatically uses the `tests` group when it detects the `CI_ENVIRONMENT` is set to `testing`. The framework's `phpunit.xml.dist` file (which Pest also reads, because Pest is built on PHPUnit) sets this variable for you, so you do not have to do anything else. Any test that uses `DatabaseTestTrait` will see the `tests` group as the default connection.

## Step 3: Disable CSRF Protection for Tests {#step-3-disable-csrf-protection-for-tests}

CodeIgniter 4 ships with CSRF protection enabled by default. This is correct behavior for production: every POST request must include a valid CSRF token, or the request is rejected with a 403 status. For real users in real browsers this works invisibly because the `csrf_field()` helper we used in Part 1 generates the token automatically.

For tests, the CSRF check is in the way. The `FeatureTestTrait` simulates HTTP requests but does not automatically populate the CSRF token, which means every POST test would fail with a 403 unless we either thread tokens through manually (tedious) or skip CSRF in the test environment (clean). We will pick the clean path.

Open `app/Config/Filters.php` in your editor. Near the top of the class you will see a `$globals` property with `before` and `after` keys. The `before` array includes a `csrf` filter that runs before every request. We want to keep this filter active in development and production but skip it in testing.

Find the `$globals` array and update it so the CSRF filter is skipped when `ENVIRONMENT` equals `testing`. The cleanest way is a small spread expression that conditionally includes the filter.

```php
public array $globals = [
    'before' => [
        // Conditionally include CSRF protection. Tests run with
        // ENVIRONMENT=testing, where the simulated POST requests
        // have no token; production and development still require it.
        ...(ENVIRONMENT !== 'testing' ? ['csrf'] : []),
        // 'invalidchars',
        // 'secureheaders',
    ],
    'after' => [
        'toolbar',
        // 'honeypot',
        // 'secureheaders',
    ],
];
```

The spread operator (`...`) merges the contents of an array into the surrounding array literal. The conditional expression evaluates to `['csrf']` in development and production but to `[]` in testing. The result is that production traffic still goes through the CSRF check, while test runs skip it.

Some teams prefer to disable CSRF for all environments and rely solely on SameSite cookies for protection. Others prefer to leave CSRF enabled even for tests and pass tokens explicitly through `withSession()`. The conditional pattern shown above is a middle ground: it preserves production protection while keeping test code clean. Pick whichever approach fits your team's security posture.

## Step 4: Build the Pest-CodeIgniter Bridge {#step-4-build-the-pest-codeigniter-bridge}

The bridge is the single most important piece of setup in this entire article. It consists of two files: a base test case class that combines `CIUnitTestCase` with the testing traits we need, and a configuration line in `tests/Pest.php` that tells Pest to use our base class instead of the default.

CodeIgniter's starter ships with a `tests/_support/` directory whose namespace is `Tests\Support`. This directory is registered for autoloading in the project's `composer.json` under the `autoload-dev` block, so any class we put there is automatically loadable in tests. We will create our base test case there.

Create a new file at `tests/_support/TestCase.php` with the following contents.

```php
<?php

namespace Tests\Support;

use CodeIgniter\Test\CIUnitTestCase;
use CodeIgniter\Test\DatabaseTestTrait;
use CodeIgniter\Test\FeatureTestTrait;

/**
 * Base test case for all Pest feature tests.
 *
 * Combines CodeIgniter's HTTP feature testing helpers (FeatureTestTrait)
 * with the database lifecycle helpers (DatabaseTestTrait), and configures
 * the database trait to migrate from the App namespace against the
 * 'tests' database group on every test.
 */
abstract class TestCase extends CIUnitTestCase
{
    use FeatureTestTrait;
    use DatabaseTestTrait;

    /**
     * Run database migrations before each test.
     *
     * The DatabaseTestTrait will look at this property and execute all
     * pending migrations against the test database before the test
     * starts. With $refresh = true (below), the database is rebuilt
     * from scratch for every test, which gives perfect isolation.
     */
    protected $migrate = true;

    /**
     * Refresh the database between every test.
     *
     * This drops all tables and re-runs the migrations between each
     * test. With SQLite in-memory the cost is negligible; with a real
     * database server you might prefer $migrateOnce = true to migrate
     * only once and use transactions to roll back changes per test.
     */
    protected $refresh = true;

    /**
     * Where the migrations live.
     *
     * The default is the Tests\Support namespace, which would only run
     * migrations placed inside tests/_support/Database/Migrations. We
     * want to run our actual application migrations from the App
     * namespace, which is the directory app/Database/Migrations.
     */
    protected $namespace = 'App';

    /**
     * Use the 'tests' database group from app/Config/Database.php.
     *
     * Without this, the test would write to the default database group
     * (the development MySQL database), which would corrupt your dev
     * data. This single property is the most important one in this
     * file from a safety standpoint.
     */
    protected $DBGroup = 'tests';
}
```

Now configure Pest to use this class as the base for all feature tests. Open `tests/Pest.php` (created when you ran `composer require --dev pestphp/pest`) and replace its contents with the following.

```php
<?php

use Tests\Support\TestCase;

/*
|--------------------------------------------------------------------------
| Test Case
|--------------------------------------------------------------------------
|
| Tell Pest to extend our custom TestCase (which itself extends
| CIUnitTestCase) for every test in the Feature directory. This makes
| the FeatureTestTrait helpers ($this->get(), $this->post(), etc.) and
| the DatabaseTestTrait helpers ($this->seeInDatabase(), etc.) available
| inside every Pest closure.
|
*/

pest()->extend(TestCase::class)->in('Feature');

/*
|--------------------------------------------------------------------------
| Expectations
|--------------------------------------------------------------------------
|
| Pest lets you extend the expect() API with custom matchers. We do not
| need any custom expectations for this project, but the file is here
| as a placeholder for future additions.
|
*/

// expect()->extend('toBeOne', function () {
//     return $this->toBe(1);
// });
```

The `pest()->extend()` call is what makes the entire bridge work. It tells Pest's compiler that any test file inside `tests/Feature/` should generate a class that extends `Tests\Support\TestCase`. Because that class extends `CIUnitTestCase` and uses the framework's testing traits, every closure inside `it(...)` calls has access to the same `$this->get()`, `$this->post()`, `$this->seeInDatabase()`, and similar helpers that a traditional CodeIgniter test class would have.

Before running Pest, you must delete the `phpunit.xml` file that was automatically generated by the `pest --init` command. That file overrides CodeIgniter's native test configuration (`phpunit.xml.dist`), which is where the framework defines critical constants like `TESTPATH`. Leaving it in place will cause an `Undefined constant "CodeIgniter\Test\TESTPATH"` error.

```bash
rm phpunit.xml
```

Before verifying the bridge, you might also want to disable the code coverage setting in `phpunit.xml.dist` if you don't have a coverage driver (like Xdebug or PCOV) installed. Otherwise, Pest will output a `WARN  No code coverage driver available` message.

Open `phpunit.xml.dist` and find the `<coverage>` block:

```xml
    <coverage
        includeUncoveredFiles="true"
        pathCoverage="false"
        ignoreDeprecatedCodeUnits="true"
        disableCodeCoverageIgnore="true">
        <report>
            <clover outputFile="build/logs/clover.xml"/>
            <html outputDirectory="build/logs/html"/>
            <php outputFile="build/logs/coverage.serialized"/>
            <text outputFile="php://stdout" showUncoveredFiles="false"/>
        </report>
    </coverage>
```

You can either remove it entirely or comment it out using XML comment syntax (`<!--` and `-->`), like so:

```xml
    <!-- <coverage
        includeUncoveredFiles="true"
        pathCoverage="false"
        ignoreDeprecatedCodeUnits="true"
        disableCodeCoverageIgnore="true">
        <report>
            <clover outputFile="build/logs/clover.xml"/>
            <html outputDirectory="build/logs/html"/>
            <php outputFile="build/logs/coverage.serialized"/>
            <text outputFile="php://stdout" showUncoveredFiles="false"/>
        </report>
    </coverage> -->
```

Save the file. Once that is done, verify the bridge is wired correctly by running Pest. If the bridge has a syntax error or a broken namespace, this command will report it.

```bash
vendor/bin/pest
```

You should see output something like this. The default CodeIgniter and Pest example tests will run, but no tests from the `Feature` directory will appear yet since we haven't created any.

```
   PASS  Tests\Feature\ExampleTest
  ✓ example                                                              0.02s  

   PASS  Tests\Unit\ExampleTest
  ✓ example                                                              0.01s  

   PASS  ExampleDatabaseTest
  ✓ model find all
  ✓ soft delete leaves row

   PASS  ExampleSessionTest
  ✓ session simple

   PASS  HealthTest
  ✓ is defined app path
  ✓ base url has been set

  Tests:    7 passed (9 assertions)
  Duration: 0.11s
```

The passing tests are the example tests that ship with Pest's `--init` and CodeIgniter's starter. They do not use our bridge because they live in `tests/Unit/` or the root `tests/` namespace. We will not touch unit tests in this article; everything we write will go in `tests/Feature/`.

## Step 5: Create Reusable Test Helpers {#step-5-create-reusable-test-helpers}

Tests benefit enormously from small helper functions that hide setup boilerplate. The most common helper is a "factory" function: a callable that produces a test entity (in our case, a Book) with sensible defaults that individual tests can override as needed. Without this helper, every test that needs an existing book would start with eight lines of `BookModel::insert()` calls; with the helper, every such test starts with one line.

CodeIgniter does not ship with a factories system equivalent to Laravel's. We will roll our own, which is straightforward.

Create a new file at `tests/_support/Helpers.php` with the following contents. The file is not a class because Pest's helper convention is to expose plain global functions. We will register it for autoloading in a moment.

```php
<?php

/**
 * Helpers for feature tests.
 *
 * These are global functions, by design. Pest tests are closures, not
 * methods on a test class, so per-test-class methods are awkward to
 * share. Global helpers (or static methods on a helpers class) are
 * the conventional approach in the Pest community.
 */

use App\Models\BookModel;

if (! function_exists('makeBook')) {
    /**
     * Build an array of valid book attributes, with optional overrides.
     *
     * Useful for tests that want to construct a payload for a POST
     * request without persisting it. Tests that need a persisted row
     * should use createBook() instead.
     *
     * @param  array  $overrides  Fields to override the defaults
     * @return array              An associative array of book attributes
     */
    function makeBook(array $overrides = []): array
    {
        return array_merge([
            'title'   => 'Default Test Title',
            'author'  => 'Default Test Author',
            'year'    => 2020,
            'genre'   => 'fiction',
            'is_read' => 0,
            'notes'   => null,
        ], $overrides);
    }
}

if (! function_exists('createBook')) {
    /**
     * Insert a book into the database and return its full row.
     *
     * Builds the attributes with makeBook(), inserts via the model
     * (which fills created_at and updated_at), and returns the inserted
     * row including its generated id.
     *
     * @param  array  $overrides  Fields to override the defaults
     * @return array              The inserted book row, including its id
     */
    function createBook(array $overrides = []): array
    {
        $model = new BookModel();
        $id    = $model->insert(makeBook($overrides), true);

        // The second argument 'true' to insert() makes it return the
        // newly inserted id. We then re-fetch the row so the test gets
        // the canonical version, including timestamps.
        return $model->find($id);
    }
}
```

The two helpers complement each other. `makeBook()` returns an attribute array suitable for a POST body or an `insert()` call, without touching the database. `createBook()` actually persists a row and returns it. Tests use whichever one fits their needs: a test for the create endpoint uses `makeBook()` to build a POST payload, while a test for the index, edit, or delete endpoint uses `createBook()` to ensure a row exists before exercising the endpoint.

Register the file for autoloading by editing `composer.json`. Find the `autoload-dev` section and add a `files` entry alongside the existing `psr-4` entry.

```json
"autoload-dev": {
    "psr-4": {
        "Tests\\Support\\": "tests/_support"
    },
    "files": [
        "tests/_support/Helpers.php"
    ]
},
```

After saving the file, regenerate Composer's autoloader so the new file is picked up.

```bash
composer dump-autoload
```

The two helpers are now globally available inside every test closure. We will use them extensively in the next four steps.

## Step 6: Test the Index Page {#step-6-test-the-index-page}

The index page is the simplest endpoint to test, which makes it a good warm-up. It has three observable behaviors worth asserting: it returns a 200 OK, it shows the empty state when there are no books, and it shows existing books when there are books. We will write three tests for these three behaviors.

Create a file at `tests/Feature/BookIndexTest.php` with the following contents.

```php
<?php

it('shows an empty state when there are no books', function () {
    $result = $this->get('/books');

    // assertOK confirms the response status is 200. This is shorthand
    // for assertStatus(200).
    $result->assertOK();

    // assertSee searches the response body for the given string.
    // It is case-sensitive and ignores HTML markup, so it works whether
    // the text appears inside a heading, a paragraph, or anywhere else.
    $result->assertSee('Your shelf is empty');
});

it('lists existing books on the index page', function () {
    // The createBook helper from Step 5 inserts a row and returns it.
    // The override here gives us a memorable title to assert against.
    createBook(['title' => 'Clean Code', 'author' => 'Robert C. Martin']);
    createBook(['title' => 'The Pragmatic Programmer', 'author' => 'Andy Hunt']);

    $result = $this->get('/books');

    $result->assertOK();
    $result->assertSee('Clean Code');
    $result->assertSee('The Pragmatic Programmer');
    $result->assertSee('Robert C. Martin');
    $result->assertSee('Andy Hunt');
});

it('shows the Add Book button on the index page', function () {
    $result = $this->get('/books');

    // The header layout (built in Part 1) includes a button labelled
    // "Add Book" that links to /books/new. We assert both pieces of
    // evidence: the visible label and the link target.
    $result->assertSee('Add Book');
    $result->assertSeeLink('Add Book');
});
```

Run the test suite to see all three pass.

```bash
vendor/bin/pest
```

The output should include the three new tests passing, alongside the example test that was already there.

```

   PASS  Tests\Feature\BookIndexTest
  ✓ it shows an empty state when there are no books                      0.03s  
  ✓ it lists existing books on the index page
  ✓ it shows the Add Book button on the index page

   PASS  Tests\Feature\ExampleTest
  ✓ example                                                              0.01s  

   PASS  Tests\Unit\ExampleTest
  ✓ example

   PASS  ExampleDatabaseTest
  ✓ model find all
  ✓ soft delete leaves row

   PASS  ExampleSessionTest
  ✓ session simple

   PASS  HealthTest
  ✓ is defined app path
  ✓ base url has been set

  Tests:    10 passed (18 assertions)
  Duration: 0.13s
```

The first test takes longer than the others (about a third of a second versus about fifty milliseconds each) because it includes the one-time cost of Pest's bootstrap and the first migration run. Subsequent tests in the same run are fast because the migration code is already loaded into PHP's opcode cache.

A subtle thing happened that you might have missed: between the second test (which inserted two books) and the third test (which expected the index page to be reachable and visible), the database was completely refreshed. The two books from the second test do not exist in the third test's database. This is the `$refresh = true` behavior we configured in the bridge, and it is what makes tests independent of each other regardless of execution order.

## Step 7: Test the Create Flow {#step-7-test-the-create-flow}

The create flow has more behaviors to verify. The new-book form must render. The form must accept valid input, persist the book, and redirect with a flash message. The form must reject invalid input, redirect back to the form, and preserve user input. We will cover all four behaviors with five tests.

Create a file at `tests/Feature/BookCreateTest.php` with the following contents. Notice the use of Pest's `dataset()` feature in the validation test, which collapses what would otherwise be six nearly-identical tests into one parameterized test.

```php
<?php

it('shows the new book form', function () {
    $result = $this->get('/books/new');

    $result->assertOK();
    $result->assertSee('Add a Book');
    $result->assertSee('Title');
    $result->assertSee('Author');
    $result->assertSee('Save Book');
});

it('creates a book with valid data and redirects to the index', function () {
    // makeBook returns a valid attribute array. We use it directly as
    // the POST body, which exercises the controller's full validation
    // and persistence path.
    $payload = makeBook([
        'title'  => 'Refactoring',
        'author' => 'Martin Fowler',
        'year'   => 1999,
        'genre'  => 'technology',
    ]);

    $result = $this->post('/books', $payload);

    // assertRedirectTo verifies both the 302 status and the Location
    // header. If either is wrong, the assertion fails with a useful
    // message.
    $result->assertRedirectTo('/books');

    // seeInDatabase queries the test database and asserts that at
    // least one row matches the given criteria. The first argument is
    // the table name, the second is an array of column-value pairs.
    $this->seeInDatabase('books', [
        'title'  => 'Refactoring',
        'author' => 'Martin Fowler',
        'year'   => 1999,
        'genre'  => 'technology',
    ]);
});

it('shows a flash success message after creating a book', function () {
    $result = $this->post('/books', makeBook());

    // The flash message is set on the session. The TestResponse
    // exposes it via assertSessionHas, which checks both the key and
    // (optionally) the value.
    $result->assertSessionHas('success', 'Book added to your shelf.');
});

it('rejects empty submissions and shows validation errors', function () {
    // Posting with a completely empty body should fail validation on
    // every required field.
    $result = $this->withSession(['_ci_previous_url' => site_url('/books/new')])
                   ->post('/books', []);

    $result->assertRedirectTo('/books/new');

    // After the redirect-back-with-errors, the session contains an
    // 'errors' key holding the validation messages. We do not check
    // exact messages because they could change with translations or
    // copy edits; we just confirm the key is present.
    $result->assertSessionHas('errors');

    // No row should have been persisted.
    $this->dontSeeInDatabase('books', [
        'title' => '',
    ]);
});

// A dataset is Pest's way of running the same test body with multiple
// inputs. Each entry in the dataset becomes one test case, with a
// human-readable label that appears in the test output. This is the
// killer feature for validation testing.
it('rejects submissions that violate field-specific rules', function (
    string $field,
    mixed  $invalidValue,
    string $description
) {
    $payload = makeBook([$field => $invalidValue]);

    $result = $this->withSession(['_ci_previous_url' => site_url('/books/new')])
                   ->post('/books', $payload);

    $result->assertRedirectTo('/books/new');
    $result->assertSessionHas('errors');

    // Confirm the persisted-row count did not change. If the row had
    // somehow slipped through validation, this assertion would fail.
    expect((new App\Models\BookModel())->countAllResults())->toBe(0);
})->with([
    'title too short'      => ['title',  'a',     'one character title is rejected'],
    'title missing'        => ['title',  '',      'empty title is rejected'],
    'author missing'       => ['author', '',      'empty author is rejected'],
    'year too low'         => ['year',   500,     'year before the year-1000 limit is rejected'],
    'year too high'        => ['year',   12000,   'year after the year-9999 limit is rejected'],
    'invalid genre'        => ['genre',  'romance', 'genre not in the allowed list is rejected'],
    'genre missing'        => ['genre',  '',      'empty genre is rejected'],
]);
```

Several things in this test file are worth understanding deeply.

The first is `assertRedirectTo`. CodeIgniter's TestResponse has multiple redirect-related assertions, but `assertRedirectTo` is the one that checks both the status code (must be a 3xx redirect) and the URL (must match exactly). Using this combined assertion makes tests both more readable and more strict than separate calls.

The second is `assertSessionHas`. The flash message we set in the controller (`->with('success', '...')`) lives in the session. The TestResponse exposes session contents through this assertion, which lets us verify that our redirect carries the message we expect. Without this, we would have to follow the redirect and search the rendered HTML, which is a brittle approach.

The third is the dataset. The `->with([...])` call after the test body provides multiple input sets, one per test case. Each set has a human-readable label (the array key), which appears in the test output instead of a generic test number. When this single test runs, Pest reports seven separate test results, one per dataset entry. The pattern collapses what would have been seven nearly-identical tests into one readable block.

The fourth is the use of `withSession(['_ci_previous_url' => ...])` before making a POST request. The CodeIgniter `redirect()->back()` helper relies on the session to know the previous URL. During feature tests, if we do not perform a GET request beforehand within the same test method, the previous URL is empty and it redirects to the base URL instead. By explicitly injecting `_ci_previous_url` into the session, we ensure `assertRedirectTo` correctly matches the intended redirect target.

Run the test suite again.

```bash
vendor/bin/pest
```

You should see all the new tests pass, with the dataset expanding into seven distinct results.

```

   PASS  Tests\Feature\BookCreateTest
  ✓ it shows the new book form                                           0.03s  
  ✓ it creates a book with valid data and redirects to the index
  ✓ it shows a flash success message after creating a book
  ✓ it rejects empty submissions and shows validation errors
  ✓ it rejects submissions that violate field-specific rules with dataset "title too short"
  ✓ it rejects submissions that violate field-specific rules with dataset "title missing"
  ✓ it rejects submissions that violate field-specific rules with dataset "author missing"
  ✓ it rejects submissions that violate field-specific rules with dataset "year too low"
  ✓ it rejects submissions that violate field-specific rules with dataset "year too high"
  ✓ it rejects submissions that violate field-specific rules with dataset "invalid genre"
  ✓ it rejects submissions that violate field-specific rules with dataset "genre missing"

   PASS  Tests\Feature\BookIndexTest
  ✓ it shows an empty state when there are no books                      0.01s  
  ✓ it lists existing books on the index page
  ✓ it shows the Add Book button on the index page

   PASS  Tests\Feature\ExampleTest
  ✓ example

   PASS  Tests\Unit\ExampleTest
  ✓ example

   PASS  ExampleDatabaseTest
  ✓ model find all
  ✓ soft delete leaves row

   PASS  ExampleSessionTest
  ✓ session simple

   PASS  HealthTest
  ✓ is defined app path
  ✓ base url has been set

  Tests:    21 passed (60 assertions)
  Duration: 0.16s
```

The dataset reads beautifully in the test output: each invalid case is its own line with a clear label. When a validation rule changes and a test fails, you will see exactly which case broke and why, without having to guess at which test method to investigate.

## Step 8: Test the Edit and Update Flows {#step-8-test-the-edit-and-update-flows}

Edit and update mirror the create flow but operate on existing rows. The four behaviors to verify are: the edit form renders with existing data preloaded; the form returns 404 for a non-existent book; valid submissions update the row and redirect; invalid submissions redirect back with errors.

Create `tests/Feature/BookEditTest.php` with the following contents.

```php
<?php

it('shows the edit form with existing book data preloaded', function () {
    $book = createBook([
        'title'  => 'Pragmatic Thinking',
        'author' => 'Andy Hunt',
        'year'   => 2008,
        'genre'  => 'technology',
        'notes'  => 'About cognitive science for programmers.',
    ]);

    $result = $this->get('/books/' . $book['id'] . '/edit');

    $result->assertOK();
    $result->assertSee('Edit Book');

    // The form should preload every field with the book's current
    // values. We assert each field separately to make a failure
    // message specific.
    $result->assertSee('Pragmatic Thinking');
    $result->assertSee('Andy Hunt');
    $result->assertSee('2008');
    $result->assertSee('About cognitive science for programmers.');
});

it('returns 404 when editing a non-existent book', function () {
    // We never created any book, so id 9999 cannot exist.
    $this->get('/books/9999/edit');
})->throws(\CodeIgniter\Exceptions\PageNotFoundException::class);

it('updates a book with valid data and redirects to the index', function () {
    $book = createBook([
        'title'  => 'Original Title',
        'author' => 'Original Author',
    ]);

    $payload = makeBook([
        'title'  => 'Updated Title',
        'author' => 'Updated Author',
        'year'   => 2024,
        'genre'  => 'science',
    ]);

    $result = $this->post('/books/' . $book['id'], $payload);

    $result->assertRedirectTo('/books');
    $result->assertSessionHas('success', 'Book updated.');

    // Verify the persisted row has the new values, not the old ones.
    $this->seeInDatabase('books', [
        'id'     => $book['id'],
        'title'  => 'Updated Title',
        'author' => 'Updated Author',
    ]);
    $this->dontSeeInDatabase('books', [
        'id'    => $book['id'],
        'title' => 'Original Title',
    ]);
});

it('rejects invalid update data and re-renders the edit form', function () {
    $book = createBook(['title' => 'Original Title']);

    // An empty title fails validation. The controller should redirect
    // back to the edit form with errors and not modify the row.
    $result = $this->withSession(['_ci_previous_url' => site_url('/books/' . $book['id'] . '/edit')])
                   ->post('/books/' . $book['id'], makeBook(['title' => '']));

    $result->assertRedirectTo('/books/' . $book['id'] . '/edit');
    $result->assertSessionHas('errors');

    // The original row should be untouched.
    $this->seeInDatabase('books', [
        'id'    => $book['id'],
        'title' => 'Original Title',
    ]);
});

it('returns 404 when updating a non-existent book', function () {
    $this->post('/books/9999', makeBook());
})->throws(\CodeIgniter\Exceptions\PageNotFoundException::class);
```

Two observations about this file are worth absorbing.

The 404 tests for both edit and update use the same approach: hit a URL with an ID that cannot exist, then assert that the closure throws a `PageNotFoundException`. This is because the controller throws `PageNotFoundException::forPageNotFound()` when the model returns null for a missing book. In a CodeIgniter CLI testing environment, this exception bubbles up instead of being converted into a 404 response, so Pest's `->throws()` expectation handles it perfectly.

The "rejects invalid update data" test uses both positive and negative database assertions. `seeInDatabase` confirms the original row is still present with its original title, while we did not need `dontSeeInDatabase` here because we are not asserting the absence of anything. The mental model is "the test fails if the row was changed" rather than "the test fails if the row was deleted", so a single `seeInDatabase` against the original title is enough.

Run the suite again. You should see five new tests pass.

```bash
vendor/bin/pest
```

```
   PASS  Tests\Feature\BookCreateTest
  ✓ it shows the new book form                                           0.03s  
  ✓ it creates a book with valid data and redirects to the index
  ✓ it shows a flash success message after creating a book
  ✓ it rejects empty submissions and shows validation errors
  ✓ it rejects submissions that violate field-specific rules with dataset "title too short"
  ✓ it rejects submissions that violate field-specific rules with dataset "title missing"
  ✓ it rejects submissions that violate field-specific rules with dataset "author missing"
  ✓ it rejects submissions that violate field-specific rules with dataset "year too low"
  ✓ it rejects submissions that violate field-specific rules with dataset "year too high"
  ✓ it rejects submissions that violate field-specific rules with dataset "invalid genre"
  ✓ it rejects submissions that violate field-specific rules with dataset "genre missing"

   PASS  Tests\Feature\BookEditTest
  ✓ it shows the edit form with existing book data preloaded             0.01s  
  ✓ it returns 404 when editing a non-existent book
  ✓ it updates a book with valid data and redirects to the index
  ✓ it rejects invalid update data and re-renders the edit form
  ✓ it returns 404 when updating a non-existent book

   PASS  Tests\Feature\BookIndexTest
  ✓ it shows an empty state when there are no books
  ✓ it lists existing books on the index page
  ✓ it shows the Add Book button on the index page

   PASS  Tests\Feature\ExampleTest
  ✓ example

   PASS  Tests\Unit\ExampleTest
  ✓ example

   PASS  ExampleDatabaseTest
  ✓ model find all
  ✓ soft delete leaves row

   PASS  ExampleSessionTest
  ✓ session simple

   PASS  HealthTest
  ✓ is defined app path
  ✓ base url has been set

  Tests:    26 passed (78 assertions)
  Duration: 0.18s
```

The output continues to grow. Pest groups tests by file, so the BookEditTest results appear together.

## Step 9: Test the Delete Flow {#step-9-test-the-delete-flow}

The delete flow is the simplest of the four. There are three behaviors to verify: deletion removes the row, deletion shows a flash message, and deletion of a non-existent book returns 404.

Create `tests/Feature/BookDeleteTest.php` with the following contents.

```php
<?php

it('deletes an existing book and redirects to the index', function () {
    $book = createBook();

    $result = $this->post('/books/' . $book['id'] . '/delete');

    $result->assertRedirectTo('/books');

    // The book should no longer be in the database.
    $this->dontSeeInDatabase('books', ['id' => $book['id']]);
});

it('shows a flash message after deletion', function () {
    $book = createBook();

    $result = $this->post('/books/' . $book['id'] . '/delete');

    $result->assertSessionHas('success', 'Book removed from your shelf.');
});

it('returns 404 when deleting a non-existent book', function () {
    $this->post('/books/9999/delete');
})->throws(\CodeIgniter\Exceptions\PageNotFoundException::class);

it('does not delete other books when deleting one', function () {
    // A defensive test: we want to be sure the delete operation only
    // touches the targeted row, not other rows in the same table.
    $keep   = createBook(['title' => 'Keep Me']);
    $remove = createBook(['title' => 'Delete Me']);

    $this->post('/books/' . $remove['id'] . '/delete');

    $this->dontSeeInDatabase('books', ['id' => $remove['id']]);
    $this->seeInDatabase('books', ['id' => $keep['id'], 'title' => 'Keep Me']);
});
```

The fourth test is what test theorists sometimes call a "defensive" or "negative-space" test: it does not just verify the happy path, it verifies that the operation did not have unintended side effects. In this case we confirm that deleting one book does not delete its neighbors. This is the kind of test that catches subtle bugs in WHERE clauses, JOINs, and cascading rules.

Run the suite one last time.

```bash
vendor/bin/pest
```

Your final output should look something like this. Thirty tests passing, all green, with the entire suite finishing in under a second.

```

   PASS  Tests\Feature\BookCreateTest
  ✓ it shows the new book form                                           0.03s  
  ✓ it creates a book with valid data and redirects to the index
  ✓ it shows a flash success message after creating a book
  ✓ it rejects empty submissions and shows validation errors
  ✓ it rejects submissions that violate field-specific rules with dataset "title too short"
  ✓ it rejects submissions that violate field-specific rules with dataset "title missing"
  ✓ it rejects submissions that violate field-specific rules with dataset "author missing"
  ✓ it rejects submissions that violate field-specific rules with dataset "year too low"
  ✓ it rejects submissions that violate field-specific rules with dataset "year too high"
  ✓ it rejects submissions that violate field-specific rules with dataset "invalid genre"
  ✓ it rejects submissions that violate field-specific rules with dataset "genre missing"

   PASS  Tests\Feature\BookDeleteTest
  ✓ it deletes an existing book and redirects to the index               0.01s  
  ✓ it shows a flash message after deletion
  ✓ it returns 404 when deleting a non-existent book
  ✓ it does not delete other books when deleting one

   PASS  Tests\Feature\BookEditTest
  ✓ it shows the edit form with existing book data preloaded             0.01s  
  ✓ it returns 404 when editing a non-existent book
  ✓ it updates a book with valid data and redirects to the index
  ✓ it rejects invalid update data and re-renders the edit form
  ✓ it returns 404 when updating a non-existent book

   PASS  Tests\Feature\BookIndexTest
  ✓ it shows an empty state when there are no books                      0.01s  
  ✓ it lists existing books on the index page
  ✓ it shows the Add Book button on the index page

   PASS  Tests\Feature\ExampleTest
  ✓ example

   PASS  Tests\Unit\ExampleTest
  ✓ example

   PASS  ExampleDatabaseTest
  ✓ model find all
  ✓ soft delete leaves row

   PASS  ExampleSessionTest
  ✓ session simple

   PASS  HealthTest
  ✓ is defined app path
  ✓ base url has been set

  Tests:    30 passed (86 assertions)
  Duration: 0.19s
```

The whole suite ran in under a second, on a fresh database that was migrated from scratch thirty times. This is what in-memory SQLite buys you.

## Understanding the Test Lifecycle {#understanding-the-test-lifecycle}

Now that you have a working test suite, it is worth walking through what actually happens when you run `vendor/bin/pest`. The lifecycle clarifies why the tests are reliable and explains what you would change if you ever wanted to optimize for a different trade-off.

When `vendor/bin/pest` starts, it loads PHPUnit's bootstrap, then loads `tests/Pest.php`, then registers the closure-based tests it discovers in `tests/Feature/`. Each `it(...)` call becomes a method on a class that Pest generates dynamically. The class extends whatever you passed to `pest()->extend()`, which in our case is `Tests\Support\TestCase`. That class extends `CIUnitTestCase`, which extends PHPUnit's `TestCase`. So a Pest test, by the time PHPUnit runs it, is structurally identical to a hand-written PHPUnit test class with traits.

Before each test method runs, PHPUnit calls `setUp()`. CodeIgniter's `CIUnitTestCase::setUp()` initializes the framework's services, then it walks through any traits the class uses and calls their per-trait setup methods. Our `DatabaseTestTrait` has a `setUpDatabase()` method that reads the `$migrate`, `$refresh`, `$namespace`, and `$DBGroup` properties and acts on them. With `$refresh = true`, it drops every table in the test database, then runs the migrations from the App namespace against the `tests` database group. Because the test database is `:memory:` SQLite, "drop every table" is essentially free, and the migration is a single CREATE TABLE statement that takes a millisecond or two.

The test closure then runs. Inside the closure, `$this` is bound to the dynamically-generated class instance, so any helper or property defined on the trait or base class is reachable. `$this->get('/books')` calls `FeatureTestTrait::get()`, which builds a synthetic `IncomingRequest` object representing a GET to `/books`, dispatches it through CodeIgniter's normal routing and controller stack, and returns a `TestResponse` wrapping the result. The response object has assertion methods (`assertOK`, `assertSee`, `assertRedirectTo`, etc.) that fail the test if the response does not match expectations.

Database assertions like `$this->seeInDatabase('books', [...])` use the same `$DBGroup = 'tests'` configuration to query the in-memory database. Because the database is in memory and the assertion runs in the same process as the controller call, there is no network or disk overhead.

After the closure returns, PHPUnit calls `tearDown()`. CodeIgniter's tearDown resets services, closes the database connection, and clears any cached data. The next test starts fresh.

This lifecycle gives us the guarantees that make the test suite trustworthy: every test starts with an empty database, every test runs the full migration to ensure schema currency, every test goes through the real controller code with the real validation rules, and every test cleans up after itself so there is no contamination.

If you wanted to trade some isolation for speed, you would set `$migrateOnce = true` and switch to per-test database transactions that roll back at teardown. This pattern works well with MySQL or PostgreSQL test databases where the migration cost is non-trivial. For SQLite in-memory the migration cost is already tiny, so the trade-off does not pay off.

## Common Pitfalls When Wiring Pest Into CodeIgniter {#common-pitfalls-when-wiring-pest-into-codeigniter}

Several mistakes catch developers the first time they bridge Pest to CodeIgniter. Knowing what to watch for saves hours of debugging.

The most damaging mistake is forgetting to set `$DBGroup = 'tests'` on the bridge class. Without this, `DatabaseTestTrait` falls back to the `default` group, which is your development MySQL database. The tests will run, but they will write to your real data: every "create a book" test inserts a new row into your dev database, every "delete a book" test deletes one, and your migration runs will drop and rebuild the dev tables on every test. The damage is silent at first and devastating to recover from. Always confirm the `$DBGroup` property is set before running any test that writes data.

The second-most-damaging mistake is forgetting `$namespace = 'App'`. If you leave this property at its default of `Tests\Support`, `DatabaseTestTrait` looks for migrations in `tests/_support/Database/Migrations/`, which is empty. The tests run, no migrations execute, and every test fails with a "no such table: books" error. The fix is one line, but the symptom is confusing because it points at the database rather than at the configuration.

The third pitfall is the spread expression for the CSRF filter from Step 3. PHP's array spread operator (`...`) inside an array literal is a feature added in PHP 8.1 for string keys and PHP 7.4 for numeric keys. If you are running an older PHP version, the syntax fails with a parse error. Both Part 1 and Part 2 require PHP 8.3 or later, so this should not be an issue, but if you ever back-port this code to an older project the syntax may need adjustment.

The fourth pitfall is the example unit test that ships with CodeIgniter. The starter places it in `tests/app/`, which Pest does not target by default. Pest's `pest()->extend()->in('Feature')` only configures the bridge for the `Feature` directory; tests outside that directory still use whatever base class they already had. This is fine, but it can be confusing if you write a new Pest test in a non-Feature directory and wonder why `$this->get()` does not work. The fix is either to move the test to `tests/Feature/`, or to add another `pest()->extend()` call in `tests/Pest.php` covering the new directory.

The fifth pitfall is more subtle: trying to `dd($result)` (or any other dump-and-die helper) inside a Pest test. CodeIgniter ships its own `dd()` helper that calls `exit()`, which interrupts Pest's execution lifecycle and produces output that is hard to read. For debugging, use `dump($result->getBody())` (which prints without exiting), or extract `$body = $result->getBody(); var_dump($body);`. Pest's own `dump` plugin works too if you prefer.

The sixth pitfall is the database refresh setting interacting with autoincrement IDs. With `$refresh = true`, the books table is dropped and rebuilt for every test, which means the autoincrement ID starts at 1 every time. If your test asserts `$book['id'] === 5` (for example, after creating five books), the assertion will pass on a fresh test database but will look surprising when read out of context. The fix is to not assert exact IDs unless you have a specific reason; instead assert against attributes like title or author that are stable and meaningful.

The seventh pitfall is forgetting to `composer dump-autoload` after editing `composer.json` to register the helpers file. Without the dump, the new file is not in Composer's autoload manifest, and your tests fail with "Call to undefined function makeBook()". The fix is one command and is harmless to run; if you are unsure whether autoload is up to date, run `composer dump-autoload` and move on.

## Conclusion {#conclusion}

You have built a complete test suite for the BookShelf CRUD application. Twenty-three tests cover every endpoint, every validation rule, every redirect, every database assertion, and every flash message. The suite runs in under two seconds on commodity hardware, against an in-memory SQLite database that resets between every test. You can now refactor the controller, add new fields, change validation rules, or upgrade CodeIgniter, and the suite will tell you immediately if anything broke.

Here are the key takeaways from Part 2 to carry forward into your own projects.

- **Pest is PHPUnit with a better skin.** Every Pest test is a PHPUnit test under the hood. This means any framework that has a PHPUnit-compatible base class (and CodeIgniter does) can use Pest with no plugins or workarounds.
- **The bridge is one TestCase plus one configuration line.** A class that extends `CIUnitTestCase` and uses the testing traits, configured into Pest with `pest()->extend()`, gives you the full power of CodeIgniter's testing infrastructure inside Pest's elegant syntax.
- **In-memory SQLite is the right default for test databases.** Speed, isolation, and zero infrastructure for a small trade-off in realism. Most projects can use it forever; the few that cannot need MySQL-specific features that you would feel as friction long before they cause test failures.
- **Disable CSRF in the testing environment.** Real users get the protection; tests get the convenience. The conditional include pattern in `app/Config/Filters.php` is clean and explicit.
- **Helpers eliminate test boilerplate.** A `makeBook()` and a `createBook()` reduce dozens of lines per file to single calls. Without these, every test starts with the same eight-line setup; with them, every test starts at the interesting part.
- **Pest's dataset feature is the killer feature for validation testing.** A single test body with seven dataset entries collapses what would be seven nearly-identical tests into one readable block, with each case getting its own labelled output line.
- **Test the public behavior, not the implementation.** All twenty-three tests hit HTTP routes, query the database, and inspect responses. None of them inspect controller internals, mock services, or assert against private methods. The same tests would survive a complete controller rewrite, which is the property that lets a test suite enable rather than block refactoring.
- **POST-redirect-GET pays off in tests.** Every write endpoint returns a clean 302 with a known location. The assertions are short and read like the user behavior they describe. Designing for testability in Part 1 made Part 2 short.
- **Run tests on every commit.** With a suite this fast, there is no excuse not to. A pre-commit hook, a CI pipeline step, or a watch mode in your editor that runs `vendor/bin/pest` after every save are all viable. The highest-leverage habit a small team can adopt is making the suite mandatory before merging anything to the main branch.

The two-part series ends here. You started Part 1 with an empty CodeIgniter project and finished Part 2 with a working CRUD application protected by a complete test suite. The patterns you have learned (thin controllers, validation in one place, redirects that tests can assert against, an in-memory test database, a small bridge class, helpers for repetitive setup) are general enough to apply to any feature you build in CodeIgniter 4 from now on. The next time you start a feature, the design will come naturally, the tests will come quickly, and the resulting code will be both more confident and more maintainable than what you wrote before this series.