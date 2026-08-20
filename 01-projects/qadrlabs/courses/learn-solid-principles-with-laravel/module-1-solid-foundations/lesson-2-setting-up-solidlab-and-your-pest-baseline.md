## 1. Before You Begin

Lesson 1 gave you the vocabulary. You can name the five principles and describe the pain each one prevents. That knowledge stays theoretical until you use it on code that runs, which is what the rest of this course is about.

Every remaining lesson follows the same shape. You build a feature the wrong way on purpose, write Pest tests against its public behavior, run those tests green to capture a baseline, refactor the internals toward one principle, and then run the identical tests again. If the second run matches the first, the refactor changed structure without changing behavior, which is exactly what a refactor is supposed to do. That loop only works if your test output is trustworthy and readable, so this lesson sets that up before anything else.

This is the shortest lesson in the course and the only one with no refactoring in it. It is also the one everything else depends on, because Lessons 3 through 8 all assume the application, the directory layout, and the test command that you create here.

### What You'll Build

SolidLab, a fresh Laravel 13 application backed by SQLite and tested with Pest. You will strip out the one default package that makes test output unreadable, add the `app/Contracts` directory that every later lesson writes interfaces into, and write a three test smoke suite that proves the setup is correct.

### What You'll Learn

- ✅ How to scaffold a Laravel 13 application with SQLite and Pest in one command
- ✅ Why a fresh Laravel 13 install prints test results as JSON, and how to change that
- ✅ How to run a single test file instead of the whole suite, and why this course always does
- ✅ How to read every part of a Pest run: the PASS header, the test lines, the timings, and the summary
- ✅ Why each principle lesson captures a baseline before refactoring anything

### What You'll Need

- PHP 8.3 or later, checked with `php -v`
- Composer 2.x, checked with `composer --version`
- The Laravel installer available as `laravel` on your PATH, or Composer as a fallback
- A terminal and a code editor
- Lesson 1 read, so the principle names mean something when the later lessons use them

---

## 2. Create the SolidLab Application

Everything in this course lives inside a single application. The five principle lessons each claim their own feature area (invoicing, payments, notifications, reporting, newsletter), so the code never collides, and by the end you have one project that demonstrates all five principles side by side rather than five disconnected demos.

### Step 1: Run the Laravel Installer

Pick a directory where you keep projects, then run the installer. The flags matter, so here is what each one does before you run it.

```bash
laravel new solidlab --no-interaction --database=sqlite --pest --no-boost
cd solidlab
```

`--no-interaction` skips the prompts and accepts the defaults, which keeps the command reproducible. `--database=sqlite` selects SQLite, so you do not need a MySQL or PostgreSQL server running anywhere; the whole database is one file inside the project. `--pest` scaffolds Pest as the test framework instead of plain PHPUnit, which gives you the `tests/Pest.php` bootstrapper and a couple of example tests. `--no-boost` skips the optional Boost starter tooling, which this course does not use.

If the `laravel` command is not on your PATH, Composer can do the same job:

```bash
composer create-project laravel/laravel solidlab
cd solidlab
composer require pestphp/pest pestphp/pest-plugin-laravel --dev --with-all-dependencies
```

The installer prints its progress as it downloads the framework and its dependencies, which takes a minute or two on a normal connection. When it finishes you have a complete Laravel application in the `solidlab` directory.

### Step 2: Confirm the Framework Version

Before trusting anything else, confirm which Laravel version you actually got. This course is written against Laravel 13, and a few things it relies on (notably the `#[Fillable]` attribute you meet in Lesson 3) do not exist in Laravel 12 or earlier.

```bash
php artisan --version
```

The output names the framework and the exact patch release:

```
Laravel Framework 13.26.0
```

Your patch number will differ as new releases ship. The major version is the part that matters: it must be 13. If it says 12, your installer is out of date, and running `composer global update laravel/installer` will fix it.

---

## 3. Fix Your Test Output Before You Write Any Tests

This section exists because of a surprise in fresh Laravel 13 installs, and running into it mid course would be confusing. Deal with it now, once, while the project is still empty.

### Step 1: Run the Default Test Suite

A fresh install ships with two example tests, one unit and one feature. Run them to confirm the toolchain works end to end.

```bash
php artisan test
```

Instead of the familiar green list of passing tests, you get a single line of JSON:

```
{"tool":"pest","result":"passed","tests":2,"passed":2,"assertions":2,"duration_ms":112}
```

Nothing is broken. The tests passed, and the JSON says so. Laravel 13 ships a development package called `laravel/pao`, described by its authors as agent optimized output for PHP testing tools. It intercepts the test runner and rewrites its output into compact machine readable JSON, which is genuinely useful when an AI coding assistant is reading the results and paying per token. It is much less useful when a human is trying to see which of thirty tests went red.

### Step 2: Remove laravel/pao

You will be reading test output constantly for the rest of this course, comparing a baseline run to a post refactor run line by line. That comparison needs the human readable format, so remove the package.

```bash
composer remove --dev laravel/pao
```

Composer removes the package, updates `composer.json` and `composer.lock`, and regenerates the autoloader. Nothing else in the application depends on it, so there is no cascade of removals and no version conflict to resolve. If you ever want the JSON output back, `composer require --dev laravel/pao` restores it.

### Step 3: Run the Suite Again

Run the identical command and watch the output change.

```bash
php artisan test
```

```

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.11s  

  Tests:    2 passed (2 assertions)
  Duration: 0.18s
```

Same two tests, same result, readable format. This is what every test run in the rest of the course looks like. Section 6 breaks down what each part of that output means.

---

## 4. Set Up the Conventions This Course Uses

Three small conventions run through every later lesson. Setting them up now means Lessons 3 through 8 can get straight to the interesting part instead of repeating boilerplate.

### Step 1: Create the Contracts Directory

Every principle except SRP ends up introducing at least one interface, and Laravel has no generator that puts interfaces in a sensible place by default. This course keeps them all in `app/Contracts`, mirroring how the framework itself organizes `Illuminate\Contracts`.

```bash
mkdir app/Contracts
```

The directory maps to the `App\Contracts` namespace automatically, because Laravel's `composer.json` registers `App\` as a PSR-4 root pointing at `app/`. There is no configuration to write and no autoload dump to run; create the folder and any interface you put in it is importable immediately.

### Step 2: Check the SQLite Database

The installer created the database file and pointed the default connection at it. Confirm both.

```bash
ls database/database.sqlite
grep DB_CONNECTION .env
```

The first command should list the file, and the second should print `DB_CONNECTION=sqlite`. Note what is not in `.env`: there is no `DB_DATABASE`, no host, no port, and no credentials. With the SQLite driver, Laravel defaults to `database/database.sqlite`, so the absence of those lines is correct rather than a missing configuration.

### Step 3: Learn the Scoped Test Command

`php artisan test` runs everything. That is the right command in a real project and the wrong one for this course, because SolidLab accumulates a feature area per lesson. By Lesson 7 a full run would mix invoice tests, payment tests, notification tests, report tests, and newsletter tests into one wall of output, and the pass count printed at the bottom would tell you nothing about the refactor you just did.

So every test run in this course names its file:

```bash
php artisan test tests/Feature/InvoiceTest.php
```

Pest accepts a path as its argument and runs only that file. The baseline you capture before a refactor and the run you do after it then cover exactly the same tests, which makes the comparison meaningful. Occasionally you will still run the full suite to confirm that a change in one feature area did not disturb another, and the lessons say so explicitly when that is the point.

---

## 5. Run and Test

The setup is done. Now prove it, by writing a small suite that asserts the three things the later lessons depend on: the application boots in the testing environment, the database connection is SQLite, and the contracts directory exists.

Create `tests/Feature/SetupTest.php` with the following content.

```php
<?php

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;

uses(RefreshDatabase::class);

it('boots the application in the testing environment', function () {
    expect(app()->environment())->toBe('testing');
});

it('uses the sqlite connection', function () {
    expect(DB::connection()->getDriverName())->toBe('sqlite');
});

it('has an app contracts directory ready', function () {
    expect(is_dir(app_path('Contracts')))->toBeTrue();
});
```

The `uses(RefreshDatabase::class)` line at the top applies that trait to every test in this file. It wraps each test in a database transaction and rolls it back afterwards, so tests never leave rows behind for the next test to trip over. Note that it is applied per file rather than globally: the generated `tests/Pest.php` has the equivalent line commented out, and this course leaves it that way so each test file states its own requirements.

Each `it(...)` call defines one test, where the string becomes the test name in the output. `expect(...)->toBe(...)` is Pest's assertion syntax, readable left to right as a sentence. `app()->environment()` returns the current environment name, which Laravel forces to `testing` during a test run via `phpunit.xml`. `DB::connection()->getDriverName()` returns the driver actually in use, which is a stronger check than reading the config, because it confirms a real connection was established. `app_path('Contracts')` resolves to the `app/Contracts` folder you created in section 4.

Run just this file.

```bash
php artisan test tests/Feature/SetupTest.php
```

```
   PASS  Tests\Feature\SetupTest
  ✓ it boots the application in the testing environment                  0.25s  
  ✓ it uses the sqlite connection                                        0.02s  
  ✓ it has an app contracts directory ready                              0.02s  

  Tests:    3 passed (3 assertions)
  Duration: 0.38s
```

Three passing tests and no mention of the two example tests, because you scoped the run to one file. SolidLab is ready.

---

## 6. How to Read a Pest Run

You will compare test output dozens of times in this course, so it is worth spending two minutes on what each part of it means. Take the run you just did.

The `PASS` header names the test class, `Tests\Feature\SetupTest`, derived from the file path. When a file has failures, this header reads `FAIL` instead, in red, and this is the line your eye should go to first in a long run.

Each line below the header is one test. The `✓` marks a pass, `⨯` marks a failure, and `-` marks a skipped or todo test. The text is the string you passed to `it()`, with the word "it" prefixed, which is why phrasing test names as sentence fragments starting with a verb reads well.

The number at the right of each line is that test's duration. Pest omits it for tests that finish almost instantly, which is why the first test here shows `0.25s` and the others show much less: the first test in a run pays the cost of booting the framework and migrating the database, and the rest reuse that warm state. A test that suddenly takes far longer than its neighbours usually means it is hitting the network or the filesystem when you thought it was not.

The summary is the line that matters most for refactoring. `Tests: 3 passed (3 assertions)` reports two separate counts. The first is how many tests ran, the second is how many individual `expect()` assertions fired inside them. Both numbers must match between your baseline run and your post refactor run. If the test count matches but the assertion count dropped, you accidentally deleted an assertion. If the test count dropped, you deleted or accidentally skipped a test. Watching both numbers is what makes the before and after comparison trustworthy rather than reassuring.

`Duration` is wall clock time for the whole run. It is useful for spotting a refactor that accidentally introduced a slow path, but it varies between runs on the same machine, so do not read too much into small differences.

---

## 7. Why Every Lesson Starts With a Baseline

The order of operations in the coming lessons is deliberate, and it is worth understanding before you follow it five times.

You write the bad version first. Not a sketch of it, the actual working thing: a controller that really does five jobs, a service with a real if/else chain. This matters because a refactor you have not felt the need for is an academic exercise. Writing the painful version, then changing it, is what makes the principle land.

You write tests against public behavior, not internals. The tests in Lesson 3 assert what the HTTP endpoint returns and what lands in the database. They say nothing about which class computed the tax. That is precisely why they survive the refactor: you are about to move that computation into a new class, and a test coupled to the old structure would have to be rewritten, which would destroy its value as evidence. A test that has to change alongside the code it guards proves nothing about the change.

You capture the baseline before touching anything. Green tests against the bad version are your proof that the starting point worked. Without that, a green run after the refactor only tells you the code passes tests now; it cannot tell you whether the behavior is the same as before.

Then you refactor and re-run. Identical test count, identical assertion count, all green. That is the whole discipline, and it is the reason a SOLID refactor is a safe thing to do on a Friday afternoon rather than a gamble.

---

## 8. Fix the Errors in Your Code

Three setup mistakes account for most of the confusion at this stage. All three produce symptoms that look like broken code rather than broken setup, which is what makes them worth naming.

**Error 1: Expecting the readable test output while `laravel/pao` is still installed.**

You follow a lesson, get a wall of JSON instead of the green list shown in the text, and assume you did something wrong. The tests are fine; the reporter is different.

```bash
# Wrong: reading this as a failure, or as evidence you mis-scaffolded the project
{"tool":"pest","result":"passed","tests":2,"passed":2,"assertions":2,"duration_ms":112}

# Correct: remove the package, then the same command reports normally
composer remove --dev laravel/pao
php artisan test
```

Read the JSON before you panic. `"result":"passed"` means the suite passed. The fix is a reporter change, not a code change, and it only needs doing once per project.

**Error 2: Putting `uses(RefreshDatabase::class)` inside the test closure instead of at file scope.**

`uses()` configures the file. Calling it inside a test is too late, because the trait has to be applied when Pest builds the test case, before any test body runs.

```php
// Wrong: the trait never applies, and rows leak from one test into the next
it('creates an invoice', function () {
    uses(RefreshDatabase::class);

    // ...
});

// Correct: file scope, above the tests, applied once to all of them
uses(RefreshDatabase::class);

it('creates an invoice', function () {
    // ...
});
```

The wrong version produces a nasty class of bug: each test passes when run alone and fails when run with its siblings, because leftover rows change what the next test sees. Any time a test passes in isolation but fails in a suite, check this line first.

**Error 3: Comparing a scoped baseline against a full suite run.**

You capture a baseline with a file path, refactor, then run `php artisan test` with no argument and see a different count. Nothing regressed; you measured two different things.

```bash
# Wrong: the counts cannot match, because the second command runs more tests
php artisan test tests/Feature/InvoiceTest.php   # baseline: 8 passed
php artisan test                                  # after: 13 passed

# Correct: identical commands on both sides of the refactor
php artisan test tests/Feature/InvoiceTest.php   # baseline: 8 passed
php artisan test tests/Feature/InvoiceTest.php   # after: 8 passed
```

The before and after commands must be character for character identical. The moment they differ, the comparison stops being evidence of anything.

---

## 9. Exercises

**Exercise 1:** Add a fourth test to `tests/Feature/SetupTest.php` that asserts the application is running on PHP 8.3 or later, so the setup fails loudly on an old runtime instead of failing mysteriously in Lesson 3 when the `#[Fillable]` attribute appears. Run the file and confirm you see four passing tests.

**Exercise 2:** Deliberately break one assertion, for example by changing `toBe('sqlite')` to `toBe('mysql')`, and run the file. Read the failure output carefully and write down three things it tells you that the JSON reporter would not have. Then change it back and confirm the suite is green again.

**Exercise 3:** Without deleting any test, make `php artisan test` report a different total than `php artisan test tests/Feature/SetupTest.php`, then explain in one sentence which number you would use as a refactoring baseline and why.

---

## 10. Solutions

**Solution for Exercise 1:**

Add this test to the bottom of the file. `PHP_VERSION_ID` is an integer built from the version parts, where 8.3.0 is `80300`, which makes it easier to compare than the version string.

```php
it('runs on php 8.3 or later', function () {
    expect(PHP_VERSION_ID)->toBeGreaterThanOrEqual(80300);
});
```

Run the file and you get four passing tests instead of three.

```bash
php artisan test tests/Feature/SetupTest.php
```

A test like this is cheap insurance. Environment problems otherwise surface as a confusing parse error deep in a later lesson, and a developer new to attributes will reasonably assume they typed the attribute wrong rather than that their runtime is too old.

**Solution for Exercise 2:**

Changing the expectation to `toBe('mysql')` produces a failure, and the readable reporter gives you at least these three things that the single line of JSON does not:

First, which test failed by name, so you know it is the connection test rather than one of the other three. Second, the expected value against the actual value, printed side by side, which tells you the driver really is `sqlite` and your expectation was the wrong part. Third, the file and line number of the failing assertion, so you can jump straight to it. The JSON reporter would have told you only that something in the suite failed.

This is the entire argument for section 3. Both reporters are correct; only one of them helps a human debug.

**Solution for Exercise 3:**

The example tests that shipped with the installer, `tests/Unit/ExampleTest.php` and `tests/Feature/ExampleTest.php`, are still there. So the two commands already report different totals without you touching anything:

```bash
php artisan test tests/Feature/SetupTest.php   # 3 passed
php artisan test                               # 5 passed
```

The scoped number is the one to use as a refactoring baseline, because it covers exactly the code you are about to change and nothing else. A total that includes unrelated tests can stay green while the tests you actually care about silently drop out of the run, and it can also change for reasons that have nothing to do with your refactor.

The full suite still has a job, just a different one: run it after the scoped comparison passes, to confirm your change did not break a neighbouring feature area. Scoped runs prove the refactor preserved behavior; the full run proves it did not leak.

---

## Next Up - Lesson 3

SolidLab exists, its test output is readable, `app/Contracts` is waiting for the interfaces you will write, and you know how to scope a test run and read what comes back. You also know why the coming lessons insist on writing the bad version first and freezing a baseline before improving anything.

In Lesson 3 you write that bad version for real. You will build an invoice creation endpoint whose `store` method validates input, calculates a subtotal, applies an 11 percent tax, applies a discount code, persists the invoice, generates a PDF, and sends an email, all in one ninety line method. You will write Pest tests against its HTTP behavior, capture a green baseline, and then split that method into four focused services without a single test changing. It is the Single Responsibility Principle applied to the exact kind of controller you have almost certainly inherited at some point.
