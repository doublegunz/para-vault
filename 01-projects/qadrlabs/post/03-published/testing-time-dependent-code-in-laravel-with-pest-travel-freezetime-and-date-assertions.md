# Testing Time-Dependent Code in Laravel with Pest: travel(), freezeTime, and Date Assertions

You wrote a test for your 14 day trial logic, it passed, you pushed, and three days later the same test failed in CI without anyone touching the code. The error was something like `Failed asserting that false is true` on a date comparison, and re-running the pipeline made it pass again. That is the signature of a time-dependent test, and it is the single most common source of flaky tests in a Laravel codebase. Anything that calls `now()`, checks an expiry, counts days remaining, or compares two timestamps is quietly tied to the exact microsecond the test happened to run.

The cost of ignoring this is not just an annoying red build. A flaky test trains your team to re-run CI instead of reading failures, which means the day a real bug hides behind the same flicker, nobody notices. Worse, the logic these tests cover is usually money sensitive: trial periods, subscription expiry, token lifetimes, scheduled jobs. If the test is unreliable, your confidence in that logic is unreliable too.

The fix is built into Laravel and works the same way in Pest. The base test case ships with a small set of time helpers, `freezeTime()`, `freezeSecond()`, `travel()`, `travelTo()`, and `travelBack()`, that let you stop the clock or move it forward and backward on demand. In this tutorial we build a small subscription model with real trial logic, write a naive test that genuinely fails, and then make the whole suite deterministic with those helpers. Almost every Laravel tutorial on qadrlabs ends with a Pest suite; this one fills the gap none of them cover, which is how to test the passage of time itself.

## Overview {#overview}

We are going to build the smallest piece of code that still has interesting time behavior: a `Subscription` model with a trial period and a paid period. It will answer questions like "is this subscription still on trial?", "how many days are left?", and "is it active right now?". Every one of those answers depends on the current moment, which makes the model a perfect target for the time helpers. We will start by letting a test fail honestly so you can see the problem with your own eyes, then introduce `freezeTime()` to stop the clock, `travel()` and `travelTo()` to jump into the future and the past, and finish with date assertions that compare stored timestamps without the microsecond trap.

### What You'll Build

- A `Subscription` Eloquent model with `trial_ends_at` and `ends_at` columns and four time-aware methods: `onTrial()`, `trialExpired()`, `daysLeftOnTrial()`, and `isActive()`.
- A factory that creates subscriptions for testing.
- A Pest feature suite of seven tests that is fully deterministic, meaning it passes every single run, not most of them.

### What You'll Learn

- Why calling `now()` in both your code and your test makes assertions flaky.
- How `freezeTime()` and `freezeSecond()` stop the clock so every `now()` agrees.
- How `travel()`, `travelTo()`, and `travelBack()` move the current time forward and backward.
- How the closure form of these helpers resets time automatically when the block ends.
- How to write date assertions that survive the database truncating microseconds.
- Which timezone pitfalls bite when you compare timestamps.

### What You'll Need

- PHP 8.3 or newer.
- A Laravel 13 project with Pest installed.
- Basic familiarity with Eloquent models, factories, and writing a simple Pest test.

## Step 1: Create the Laravel Project {#step-1-create-the-laravel-project}

There are two kinds of readers here, so let us handle both before going further. If you are starting fresh, create a new Laravel project with Pest and SQLite already wired up. If you already have a Laravel 13 project with Pest, you can skip the creation command and simply follow along inside it.

For a fresh project, run the following:

```bash
laravel new time-testing-demo --no-interaction --database=sqlite --pest --no-boost
cd time-testing-demo
```

This command scaffolds a Laravel 13 application, selects SQLite as the database, and installs Pest as the test runner instead of plain PHPUnit. In Laravel 13 the generated `phpunit.xml` already points the test database at an in-memory SQLite connection, so your tests run fast and never touch your real data. You do not need to configure anything else to start testing.

If you are working inside an existing project that was created without Pest, install it once with the following:

```bash
composer require pestphp/pest pestphp/pest-plugin-laravel --dev --with-all-dependencies
php artisan pest:install
```

Either way, the important thing is that you can run `php artisan test` and see Pest report results. With the project ready, we can build the code that actually cares about time.

## Step 2: Build the Time-Dependent Subscription Model {#step-2-build-the-time-dependent-subscription-model}

A model is only worth testing for time if it asks questions about the present moment. Our `Subscription` will store two dates, the end of the free trial and the end of the paid period, and expose methods that compare those dates against `now()`. Generate the model together with a migration and a factory in one command:

```bash
php artisan make:model Subscription -mf
```

The `-mf` flags tell Artisan to create a migration and a factory alongside the model, so we have everything we need in a single step. Open the new migration in `database/migrations` and define the two date columns plus the plan name:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->string('plan');
            $table->dateTime('trial_ends_at')->nullable();
            $table->dateTime('ends_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
    }
};
```

Both date columns are nullable because a subscription might have no trial, or no paid period yet. The `trial_ends_at` column marks the moment the free trial stops, and `ends_at` marks the moment the paid access stops. Save the file, then open `app/Models/Subscription.php` and write the model:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['plan', 'trial_ends_at', 'ends_at'])]
class Subscription extends Model
{
    /** @use HasFactory<\Database\Factories\SubscriptionFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'trial_ends_at' => 'datetime',
            'ends_at' => 'datetime',
        ];
    }

    public function onTrial(): bool
    {
        return $this->trial_ends_at !== null && $this->trial_ends_at->isFuture();
    }

    public function trialExpired(): bool
    {
        return $this->trial_ends_at !== null && $this->trial_ends_at->isPast();
    }

    public function daysLeftOnTrial(): int
    {
        if (! $this->onTrial()) {
            return 0;
        }

        return (int) ceil(now()->diffInDays($this->trial_ends_at, false));
    }

    public function isActive(): bool
    {
        return $this->onTrial()
            || ($this->ends_at !== null && $this->ends_at->isFuture());
    }
}
```

There are a few things worth pointing out here. The `#[Fillable([...])]` attribute is the Laravel 13 way to declare mass-assignable columns; it replaces the old `protected $fillable` property. The `casts()` method turns the two raw date strings from the database into Carbon instances, which is what gives us convenient methods like `isFuture()` and `isPast()`. Those two methods are the heart of the time dependency: `isFuture()` returns true when the date is later than `now()`, and `isPast()` returns true when it is earlier. The `daysLeftOnTrial()` method uses `now()->diffInDays($this->trial_ends_at, false)` to measure the gap between the present and the trial end, and the `false` argument keeps the result signed so a past date would come back negative. Every single one of these answers changes depending on what `now()` returns at the instant the method runs.

The factory needs sensible defaults so a fresh subscription starts on a trial. Open `database/factories/SubscriptionFactory.php` and fill in the definition:

```php
<?php

namespace Database\Factories;

use App\Models\Subscription;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Subscription>
 */
class SubscriptionFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'plan' => 'pro',
            'trial_ends_at' => now()->addDays(14),
            'ends_at' => null,
        ];
    }
}
```

By default a new subscription is on the `pro` plan with a trial that ends 14 days from now and no paid period yet. Notice that the default itself calls `now()`, which means the factory is just as time-dependent as the model. Finally, run the migration so the table exists:

```bash
php artisan migrate
```

```
 INFO Running migrations.

 2026_06_15_130051_create_subscriptions_table .. 10.41ms DONE
```

The table is in place and the model knows how to read it. Now we can write a test, and watch it betray us.

## Step 3: Watch a Naive Test Turn Flaky {#step-3-watch-a-naive-test-turn-flaky}

The natural first test is to assert that a fresh subscription ends its trial 14 days from now. It reads cleanly and looks obviously correct, which is exactly what makes it dangerous. Create `tests/Feature/SubscriptionTest.php` with this single test:

```php
<?php

use App\Models\Subscription;

test('a fresh subscription ends its trial 14 days from now', function () {
    $subscription = Subscription::factory()->create([
        'trial_ends_at' => now()->addDays(14),
    ]);

    expect($subscription->trial_ends_at->equalTo(now()->addDays(14)))->toBeTrue();
});
```

Before running it, make sure the feature suite resets the database between tests so the in-memory table is created. Open `tests/Pest.php` and enable `RefreshDatabase`:

```php
pest()->extend(TestCase::class)
    ->use(RefreshDatabase::class)
    ->in('Feature');
```

The `RefreshDatabase` trait migrates the schema into the in-memory SQLite database for each test, which is why our `subscriptions` table is available inside the test. Now run the suite:

```bash
php artisan test --filter=SubscriptionTest
```

```
   FAIL  Tests\Feature\SubscriptionTest
  ⨯ a fresh subscription ends its trial 14 days from now                 0.18s
  ────────────────────────────────────────────────────────────────────────────
   FAILED  Tests\Feature\SubscriptionTest > a fresh subscription ends its tr…
  Failed asserting that false is true.

  at tests/Feature/SubscriptionTest.php:10
      6▕     $subscription = Subscription::factory()->create([
      7▕         'trial_ends_at' => now()->addDays(14),
      8▕     ]);
      9▕
  ➜  10▕     expect($subscription->trial_ends_at->equalTo(now()->addDays(14)))->toBeTrue();
     11▕ });
     12▕

  1   tests/Feature/SubscriptionTest.php:10


  Tests:    1 failed (1 assertions)
  Duration: 0.24s
```

The test failed, and the reason is subtle. There are two different calls to `now()` in this test. The first happens inside the factory when the row is created and written to the database. The second happens inside the assertion, a few microseconds later. Those two moments are not the same instant, so `now()->addDays(14)` produces a different value each time. On top of that, the database stores the timestamp with one second precision and drops the microseconds, while the `now()` in the assertion still carries them. The comparison is asking whether two timestamps taken at different moments, one of them rounded, are exactly equal. They are not, so `equalTo()` returns false. This is the same mechanism that makes a passing build flicker red later: the test is comparing the clock against itself, and the clock never stops moving.

## Step 4: Stabilize Tests with freezeTime() {#step-4-stabilize-tests-with-freezetime}

The cure is to stop the clock so that every call to `now()` returns the exact same instant for the duration of the test. Laravel's base test case provides `freezeTime()` for this, and because Pest tests are bound to that same test case, you call it through `$this`. Update the test:

```php
<?php

use App\Models\Subscription;

test('a fresh subscription ends its trial 14 days from now', function () {
    $this->freezeTime();

    $subscription = Subscription::factory()->create([
        'trial_ends_at' => now()->addDays(14),
    ]);

    expect($subscription->trial_ends_at->toDateTimeString())
        ->toBe(now()->addDays(14)->toDateTimeString());
});
```

Two things changed. First, `$this->freezeTime()` pins the current time in place, so the `now()` inside the factory and the `now()` inside the assertion are guaranteed to be the same moment. Second, we compare with `toDateTimeString()` instead of `equalTo()`, which formats both Carbon instances down to one second precision. That second change matters because the database itself stores the value to the second, so comparing at second precision matches how the data is actually persisted. Run the test again:

```bash
php artisan test --filter="a fresh subscription ends its trial 14 days from now"
```

```
   PASS  Tests\Feature\SubscriptionTest
  ✓ a fresh subscription ends its trial 14 days from now                 0.17s
  Tests:    1 passed (1 assertions)
  Duration: 0.24s
```

The test passes, and it will keep passing no matter what microsecond you run it on, because there is no longer any moving clock for it to trip over. With time frozen, counting days becomes reliable too. Add a second test that pins the trial length and a third that checks the day counter:

```php
test('a subscription is on trial while the trial date is in the future', function () {
    $subscription = Subscription::factory()->create([
        'trial_ends_at' => now()->addDays(14),
    ]);

    expect($subscription->onTrial())->toBeTrue()
        ->and($subscription->trialExpired())->toBeFalse();
});

test('it reports the number of days left on the trial', function () {
    $this->freezeTime();

    $subscription = Subscription::factory()->create([
        'trial_ends_at' => now()->addDays(14),
    ]);

    expect($subscription->daysLeftOnTrial())->toBe(14);
});
```

The second test does not need a frozen clock because `onTrial()` only asks whether the date is in the future, and 14 days of margin is far larger than the microseconds between two `now()` calls. The third test, however, depends on `freezeTime()`. Without it, `daysLeftOnTrial()` could measure something like 13.9999 days between the assertion's `now()` and the stored date, and although `ceil()` would round that back to 14 here, the margin is thin enough that you do not want to rely on it. Freezing the clock removes the ambiguity entirely and makes the expectation of exactly 14 days honest.

## Step 5: Test Expiry by Traveling Through Time {#step-5-test-expiry-by-traveling-through-time}

Freezing the clock proves how code behaves right now, but the interesting bugs live in the future, when a trial ends or a subscription lapses. You cannot wait 15 real days for a test, so Laravel lets you move the clock instead. The `travel()` helper jumps a relative amount of time, and `travelTo()` jumps to an explicit moment. Add a test that fast forwards past the trial:

```php
test('the trial expires once 15 days have passed', function () {
    $subscription = Subscription::factory()->create([
        'trial_ends_at' => now()->addDays(14),
    ]);

    $this->travel(15)->days();

    expect($subscription->onTrial())->toBeFalse()
        ->and($subscription->trialExpired())->toBeTrue()
        ->and($subscription->daysLeftOnTrial())->toBe(0);
});
```

The call `$this->travel(15)->days()` moves the current time forward by 15 days. The subscription was created with a trial ending in 14 days, so after the jump the trial end sits one day in the past. Now `onTrial()` returns false, `trialExpired()` returns true, and `daysLeftOnTrial()` returns zero, exactly as a real expired trial would behave two weeks from now. The fluent unit reads naturally, and you can swap `days()` for `hours()`, `weeks()`, `years()`, and the others. Passing a negative number such as `$this->travel(-1)->day()` moves the clock backward instead, which is handy for testing how code treats dates in the past.

Sometimes you need to land on a specific moment rather than a relative offset, and that is what `travelTo()` is for. Add a test for the paid period using an explicit jump:

```php
test('a subscription stays active until its paid period ends', function () {
    $subscription = Subscription::factory()->create([
        'trial_ends_at' => now()->subDay(),
        'ends_at' => now()->addMonth(),
    ]);

    expect($subscription->isActive())->toBeTrue();

    $this->travelTo(now()->addMonths(2));

    expect($subscription->isActive())->toBeFalse();
});
```

Here the subscription's trial already ended yesterday, but its paid period runs for another month, so `isActive()` is true to begin with. The call `$this->travelTo(now()->addMonths(2))` jumps the clock to two months from now, well past the paid period's end. After the jump `isActive()` flips to false, which is precisely what should happen when a paid subscription lapses. Using `travelTo()` makes the destination explicit, which reads more clearly than chaining several relative `travel()` calls when you are aiming at one specific deadline.

There is one more form worth knowing, the closure version, which moves time only for the duration of a block and then puts it back. Add a test that checks expiry inside a closure:

```php
test('time travel inside a closure resets when the closure ends', function () {
    $this->freezeTime();

    $subscription = Subscription::factory()->create([
        'trial_ends_at' => now()->addDays(14),
    ]);

    $this->travel(30)->days(function () use ($subscription) {
        expect($subscription->trialExpired())->toBeTrue();
    });

    expect($subscription->onTrial())->toBeTrue();
});
```

Inside the closure the clock is 30 days ahead, so the trial has expired and `trialExpired()` is true. The moment the closure finishes, Laravel restores the clock to where it was before the jump, so the final assertion outside the closure sees the subscription back on its trial. This scoping is useful when a single test needs to check behavior at two different moments without leaking the time change into the rest of the test. Run the three new tests together:

```bash
php artisan test --filter="expires once 15 days|stays active until its paid period|resets when the closure ends"
```

```
   PASS  Tests\Feature\SubscriptionTest
  ✓ the trial expires once 15 days have passed                           0.17s
  ✓ a subscription stays active until its paid period ends               0.02s
  ✓ time travel inside a closure resets when the closure ends            0.02s

  Tests:    3 passed (7 assertions)
  Duration: 0.27s
```

All three pass, and they describe behavior across days and months that you never had to wait for.

## Step 6: Assert Exact Dates and Durations {#step-6-assert-exact-dates-and-durations}

Sometimes a boolean is not enough and you genuinely need to assert that a stored timestamp equals a specific value to the second. This is where the microsecond trap from Step 3 comes back, because the database wrote the date without microseconds while a fresh `now()` still carries them. The cleanest way to make an exact equality hold is `freezeSecond()`, which freezes the clock at the very start of the current second, so the microsecond component is zero on both sides of the comparison. Add this final test:

```php
test('the stored trial date matches the expected timestamp to the second', function () {
    $this->freezeSecond();

    $subscription = Subscription::factory()->create([
        'trial_ends_at' => now()->addDays(14),
    ]);

    expect($subscription->trial_ends_at->equalTo(now()->addDays(14)))->toBeTrue()
        ->and($subscription->trial_ends_at->toDateTimeString())
        ->toBe(Carbon::now()->addDays(14)->toDateTimeString());
});
```

Remember to import Carbon at the top of the file with `use Illuminate\Support\Carbon;`. Because `freezeSecond()` zeroes the microseconds, the value written to the database and the value produced by `now()->addDays(14)` are identical down to the microsecond, so even the strict `equalTo()` comparison that failed in Step 3 now succeeds. The second expectation compares the formatted date strings as a more readable safety net. This is the difference between `freezeTime()` and `freezeSecond()` in practice: freeze the exact instant when you only care that the clock stopped, and freeze the start of the second when you need exact equality against a value that gets truncated on its way into the database. Run it:

```bash
php artisan test --filter="matches the expected timestamp to the second"
```

```
   PASS  Tests\Feature\SubscriptionTest
  ✓ the stored trial date matches the expected timestamp to the second   0.17s

  Tests:    1 passed (2 assertions)
  Duration: 0.24s
```

The strict equality holds because we removed the only thing that ever made it fail, which was the moving, microsecond-bearing clock.

## Step 7: Try It Out {#step-7-try-it-out}

With all seven tests written, run the complete suite to see the whole picture:

```bash
php artisan test
```

```
   PASS  Tests\Feature\SubscriptionTest
  ✓ a fresh subscription ends its trial 14 days from now                 0.17s
  ✓ a subscription is on trial while the trial date is in the future     0.02s
  ✓ it reports the number of days left on the trial                      0.02s
  ✓ the trial expires once 15 days have passed                           0.02s
  ✓ a subscription stays active until its paid period ends               0.02s
  ✓ time travel inside a closure resets when the closure ends            0.02s
  ✓ the stored trial date matches the expected timestamp to the second   0.02s

  Tests:    7 passed (13 assertions)
  Duration: 0.34s
```

Seven tests, thirteen assertions, all green. The real proof of a time-dependent suite is not that it passes once but that it passes every time, so run it a few times in a row. Because nothing in these tests reads the real wall clock anymore, the result is identical on every run, at any hour of the day, in any pipeline. That is the deterministic suite we set out to build.

## Understanding freezeTime, travel, travelTo, and travelBack {#understanding-the-time-helpers}

Now that you have used the helpers, it is worth seeing how they relate to each other, because they all do the same underlying thing through one mechanism. Each helper calls `Carbon::setTestNow()` behind the scenes, which overrides what `now()`, `Carbon::now()`, and `today()` return for the rest of the test. That single override is why freezing or traveling affects your model code, your factory, and your assertions all at once, without you passing a fake clock into anything.

The differences are only about how each helper chooses the moment to set. `freezeTime()` sets the override to the current instant and leaves it there, so the clock stops. `freezeSecond()` does the same but trims the moment to the start of the current second. `travel($value)` returns a small fluent object that, once you chain a unit like `->days()`, moves the override forward or backward by that amount. `travelTo($date)` sets the override to an explicit Carbon instance you provide. And `travelBack()` clears the override entirely, returning to the real system clock. As a rule of thumb, freeze when you are testing what is true right now, travel when you are testing what becomes true after some time passes, and travel to an explicit date when you are aiming at one specific deadline.

## The Closure Form and Automatic Reset {#the-closure-form-and-automatic-reset}

You saw the closure version of `travel()` in Step 5, and it deserves a closer look because it solves a real hazard. Any time you call `Carbon::setTestNow()`, you are mutating global state, and global state that you forget to clean up leaks into the next test. The closure form removes that risk: `freezeTime()`, `freezeSecond()`, `travel()->days()`, and `travelTo()` all accept a closure, run it with the clock set, and then restore the previous time the instant the closure returns. The frozen Carbon instance is even handed to your closure as an argument, so you can write `$this->freezeTime(function ($time) { ... })` and work with the exact moment you froze.

Laravel also protects you at the boundary of each test. The framework automatically calls `Carbon::setTestNow(null)` when a test finishes, so even a plain `$this->travel(15)->days()` with no closure cannot bleed into the test that runs after it. That is why our suite never needed an explicit `travelBack()` anywhere. The closure form is still the better choice when a single test inspects two different moments, because it scopes the time change to exactly the block that needs it and keeps the rest of the test running at the frozen baseline.

## Timezone Pitfalls When Testing Time {#timezone-pitfalls-when-testing-time}

The last thing that bites people is timezones, and it usually shows up as a test that is wrong by a fixed number of hours rather than flaky. The helpers all operate in your application's configured timezone, which is whatever `config('app.timezone')` returns, defaulting to UTC. As long as you build your expected values from `now()` and Carbon, like `now()->addDays(14)`, everything stays inside that same timezone and the comparison is consistent. The trouble starts when you hardcode a string such as `'2026-06-29 13:00:00'` in an assertion, because that literal carries no timezone and you are implicitly assuming it matches the application's. If the app runs in `Asia/Jakarta` while you wrote the literal as if it were UTC, the test is off by seven hours.

The safe habit is to never compare against hardcoded date strings in time tests. Freeze the clock, then derive every expected value from that frozen `now()` using Carbon arithmetic, so both sides of the assertion live in the same timezone by construction. If you must assert against an absolute moment, build it explicitly with the timezone attached, for example `Carbon::parse('2026-06-29 13:00:00', 'UTC')`, so there is no ambiguity about which clock you meant. Keeping expected values relative to a frozen `now()` is what makes the whole approach in this tutorial portable across machines and CI environments that may not share your local timezone.

## Conclusion {#conclusion}

Time-dependent logic does not have to be a source of flaky tests. Once you stop letting your tests read the real wall clock, the same trial, expiry, and scheduling code that used to flicker red becomes some of the most reliable in your suite. Here are the key takeaways to carry forward:

- **Flaky time tests come from two moving clocks.** When your code and your assertion each call `now()`, they capture different instants, and the database truncating microseconds widens the gap, so an exact comparison fails unpredictably.
- **`freezeTime()` stops the clock.** It pins `now()` to a single instant for the whole test, so every call agrees and assertions about the present become deterministic.
- **`freezeSecond()` enables exact equality.** By trimming the frozen moment to the start of the second, it matches the one second precision the database stores, so strict `equalTo()` comparisons hold.
- **`travel()` and `travelTo()` test the future and the past.** Use `travel(15)->days()` for relative jumps and `travelTo($date)` for an explicit deadline, so you can verify expiry behavior without waiting real time.
- **The closure form resets automatically.** Passing a closure scopes the time change to that block, and Laravel also clears the override after every test, so time changes never leak between tests.
- **Keep expected values relative to a frozen `now()`.** Deriving dates with Carbon arithmetic instead of hardcoded strings keeps both sides of an assertion in the same timezone and keeps the suite portable across environments.
