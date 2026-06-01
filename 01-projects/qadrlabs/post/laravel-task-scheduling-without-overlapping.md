# Laravel 13 Task Scheduling: Stop Heavy Cron Jobs From Overlapping With withoutOverlapping()

You schedule a sales report command to run every five minutes, and for months it behaves perfectly because it always finishes in under two minutes. Then a big promotion lands, your orders table triples in size overnight, and the aggregation that used to take two minutes now takes seven. The scheduler does not know or care that the previous run is still going; at the five minute mark it fires a fresh copy right on top of the one still grinding through the data.

Now two instances of the same heavy job are reading and writing the same tables at the same time. You get duplicate report rows, double-counted totals, and a CPU and memory spike as a third and fourth copy stack up behind them. If the job touches shared counters or locks rows, you can deadlock the database outright. The worst part is that this only happens when the data is large and the system is already under load, which is exactly when you can least afford it, and it is nearly impossible to reproduce on your laptop.

Laravel solves this with a single chained method. Calling `withoutOverlapping()` on a scheduled task wraps it in an atomic lock, so when the scheduler comes around to start a new run and the previous one is still holding the lock, it quietly skips the new run instead of piling on. The lock also carries an expiration, so a job that crashes without releasing it does not block the task forever. In this tutorial we build a deliberately slow report command, reproduce the overlap problem with our own eyes, then fix it and harden it for production.

## Overview {#overview}

The plan is to make the failure visible before we prevent it, because overlap bugs are so much easier to trust once you have watched them happen. We build a `report:generate` command that simulates a long job, schedule it to run every minute, and then fire the scheduler twice at once to force two copies to overlap. After confirming the damage in the logs and the database, we add `withoutOverlapping()` and watch the second run get skipped. Finally we layer on the production concerns: bounding the lock with an expiry, running the task in the background so it does not block other scheduled work, and guarding against duplication when more than one server runs the scheduler.

### What You'll Build

- A heavy `report:generate` Artisan command that aggregates orders into a report row and logs its start and end so overlaps are visible
- A scheduled task that runs the command every minute, defined in `routes/console.php`
- A reproducible demonstration of two runs overlapping, then the same scenario made safe with `withoutOverlapping()`
- A production-hardened schedule using lock expiry, `runInBackground()`, and `onOneServer()`
- A Pest test suite that verifies the command's output and the schedule's overlap protection

### What You'll Learn

- How to register scheduled tasks in Laravel 13 using the `Schedule` facade in `routes/console.php`
- How to reproduce overlapping runs by firing `schedule:run` concurrently
- How `withoutOverlapping()` uses an atomic cache lock, and how to tune its expiration
- The difference between `withoutOverlapping()`, `onOneServer()`, and `runInBackground()`
- How to inspect and debug schedules with `schedule:list`, `schedule:test`, and `schedule:clear-cache`
- How to assert overlap protection in a Pest test

### What You'll Need

- PHP 8.3 or newer
- Laravel 13 with the default SQLite database
- Basic familiarity with writing Artisan commands and Eloquent models
- The single system cron entry that drives Laravel's scheduler, which we cover in Step 3

## Step 1: Create the Project {#step-1-create-the-project}

Create a fresh Laravel 13 application configured for SQLite and Pest, then move into it.

```bash
laravel new schedule-demo --no-interaction --database=sqlite --pest --no-boost
cd schedule-demo
```

The Laravel installer may run the default migrations for you. Run `migrate` once anyway so you can confirm the framework tables exist, including the `cache` and `cache_locks` tables that the scheduler's overlap lock relies on.

```bash
php artisan migrate
```

```
   INFO  Nothing to migrate.
```

The `create_cache_table` migration is the important one here. If your installer did not already run the default migrations, this command will create the users, cache, and jobs tables instead of showing `Nothing to migrate`. The default `database` cache store supports atomic locks in Laravel 13, and `withoutOverlapping()` stores its lock there, so we get overlap protection without installing Redis or any other service. With the project ready, let us build something slow enough to overlap.

## Step 2: Build the Heavy Command {#step-2-build-the-heavy-command}

We need a realistic heavy job. Ours will aggregate every order into a daily sales report, with an artificial delay so we can reliably catch two runs in the act. First, generate the data models. Create an `Order` model with a migration and factory, and a `Report` model with a migration.

```bash
php artisan make:model Order -mf
php artisan make:model Report -m
```

Open the orders migration in `database/migrations` and give it an amount column.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->decimal('amount', 10, 2);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
```

An order is just an amount for our purposes, which is enough to sum into a report. Now open the reports migration and define where the aggregated result lands.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->unsignedInteger('total_orders');
            $table->decimal('total_amount', 12, 2);
            $table->timestamp('generated_at');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reports');
    }
};
```

Each report row records how many orders were counted, their total value, and when it was generated. Counting the rows in this table after our experiments is how we will prove whether one run happened or two. Open `app/Models/Order.php` and declare its fillable column.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['amount'])]
class Order extends Model
{
    use HasFactory;
}
```

The `#[Fillable(['amount'])]` attribute marks `amount` as mass assignable. Now open `app/Models/Report.php` and set up its fillable columns and a cast for the timestamp.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['total_orders', 'total_amount', 'generated_at'])]
class Report extends Model
{
    protected function casts(): array
    {
        return [
            'generated_at' => 'datetime',
        ];
    }
}
```

The `casts()` method tells Eloquent to treat `generated_at` as a Carbon date instance when you read it. Open the order factory at `database/factories/OrderFactory.php` and define a fake order.

```php
<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

class OrderFactory extends Factory
{
    public function definition(): array
    {
        return [
            'amount' => fake()->randomFloat(2, 10, 500),
        ];
    }
}
```

This gives each order a random amount between ten and five hundred with two decimal places. Seed a batch of orders by editing `database/seeders/DatabaseSeeder.php`.

```php
<?php

namespace Database\Seeders;

use App\Models\Order;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        Order::factory()->count(50)->create();
    }
}
```

Run the new migrations so the `orders` and `reports` tables exist before the seeder tries to insert order rows.

```bash
php artisan migrate
```

Run the seeder so the report has something to aggregate.

```bash
php artisan db:seed
```

```
   INFO  Seeding database.
```

Now build the command itself. Generate it with Artisan.

```bash
php artisan make:command GenerateReport
```

Open `app/Console/Commands/GenerateReport.php` and write the report logic with a configurable delay.

```php
<?php

namespace App\Console\Commands;

use App\Models\Order;
use App\Models\Report;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class GenerateReport extends Command
{
    protected $signature = 'report:generate {--sleep=30 : Seconds to simulate heavy work}';

    protected $description = 'Aggregate orders into a sales report (simulated heavy job)';

    public function handle(): int
    {
        Log::info('START report:generate at ' . now()->toTimeString());

        // Simulate a long-running aggregation so we can catch overlaps.
        $seconds = (int) $this->option('sleep');

        if ($seconds > 0) {
            sleep($seconds);
        }

        $report = Report::create([
            'total_orders' => Order::count(),
            'total_amount' => Order::sum('amount'),
            'generated_at' => now(),
        ]);

        Log::info("END report:generate at " . now()->toTimeString() . " (report #{$report->id})");

        $this->info("Report #{$report->id}: {$report->total_orders} orders, {$report->total_amount} total.");

        return self::SUCCESS;
    }
}
```

The `--sleep` option defaults to thirty seconds so the scheduled job behaves like a genuinely slow task, but tests can pass `--sleep=0` to run instantly. The two `Log::info` calls bracket the work with a start and end timestamp, which is our window into whether two copies ran at once. Run the command once by hand to confirm it works.

```bash
php artisan report:generate --sleep=0
```

```
Report #1: 50 orders, 13245.67 total.
```

The command produced one report from the fifty seeded orders. Now we put it on a schedule.

## Step 3: Schedule the Command and Reproduce the Overlap {#step-3-schedule-the-command-and-reproduce-the-overlap}

In Laravel 13, scheduled tasks are defined in `routes/console.php` using the `Schedule` facade. Open that file and register the command to run every minute, deliberately without any overlap protection yet so we can see the problem.

```php
<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Run the heavy report every minute. No overlap protection yet.
Schedule::command('report:generate')->everyMinute();
```

The line `Schedule::command('report:generate')->everyMinute()` tells Laravel the command is due at the top of every minute. In production, the scheduler is driven by a single system cron entry that calls `schedule:run` once a minute. Open the crontab for the Linux user that owns the Laravel project.

```bash
crontab -e
```

Paste this line into the file, replacing `/path-to-your-project` with the absolute path to your deployed Laravel project.

```
* * * * * cd /path-to-your-project && php artisan schedule:run >> /dev/null 2>&1
```

Save and close the editor. On most servers, cron installs the updated crontab automatically after the editor exits. You can confirm the entry was saved with this command.

```bash
crontab -l
```

That one entry is all the cron configuration Laravel ever needs; every scheduled task lives in your PHP code, not in crontab. For the local demo, you do not need to wait for system cron. Confirm the task is registered with `schedule:list`.

```bash
php artisan schedule:list
```

```
  * * * * *  php artisan report:generate ........... Next Due: 59 seconds from now
```

The task is scheduled. Now reproduce the overlap. Because `everyMinute()` is due during the current minute, we can simulate the cron firing twice in quick succession by launching two `schedule:run` processes at once. The first will start the thirty second job; the second fires while the first is still running.

```bash
php artisan schedule:run & php artisan schedule:run & wait
```

Both processes run the command because nothing stops them. Once they finish, open `storage/logs/laravel.log` and you will see two overlapping runs: two START lines within the same second, both still open while the work happens.

```
[2026-05-29 10:00:01] local.INFO: START report:generate at 10:00:01
[2026-05-29 10:00:01] local.INFO: START report:generate at 10:00:01
[2026-05-29 10:00:31] local.INFO: END report:generate at 10:00:31 (report #2)
[2026-05-29 10:00:31] local.INFO: END report:generate at 10:00:31 (report #3)
```

Two copies ran shoulder to shoulder and each wrote its own report row. Confirm the duplication in the database.

```bash
php artisan tinker --execute="echo App\Models\Report::count();"
```

```
3
```

We expected one new report for this minute but got two, on top of the one from Step 2, for a total of three. In a real job this is where double-counted totals and deadlocks come from. Let us stop it.

## Step 4: Prevent Overlap With withoutOverlapping() {#step-4-prevent-overlap-with-withoutoverlapping}

The fix is a single chained method. Open `routes/console.php` and add `withoutOverlapping()` to the scheduled task.

```php
// Run the heavy report every minute, skipping a run if the
// previous one is still going.
Schedule::command('report:generate')->everyMinute()->withoutOverlapping();
```

The `withoutOverlapping()` method tells the scheduler to acquire an atomic lock before running the task and to release it when the task finishes. If a new run starts while the lock is still held, the scheduler skips it entirely instead of running a second copy. Run the exact same concurrent experiment again.

```bash
php artisan schedule:run & php artisan schedule:run & wait
```

This time, only the first process acquires the lock and runs; the second sees the lock is held and skips the task without doing any work. The log proves it with a single START and END pair for this run.

```
[2026-05-29 10:05:01] local.INFO: START report:generate at 10:05:01
[2026-05-29 10:05:31] local.INFO: END report:generate at 10:05:31 (report #4)
```

Check the report count to confirm exactly one new row was added.

```bash
php artisan tinker --execute="echo App\Models\Report::count();"
```

```
4
```

The count went from three to four, a single increment, even though we fired the scheduler twice. The overlap is gone. Now we tune this for the realities of production.

## Step 5: Harden for Production {#step-5-harden-for-production}

A bare `withoutOverlapping()` is good, but it carries an implicit risk and leaves two related problems unsolved. The risk: by default the lock expires after twenty four hours, so if the job is killed before it releases the lock, the task stays blocked for a full day. The unsolved problems: a long task run inline by `schedule:run` blocks every other due task behind it, and on a multi-server setup every server's cron will run its own copy. We address all three. Open `routes/console.php` and expand the schedule definition.

The current line looks like this.

```php
Schedule::command('report:generate')->everyMinute()->withoutOverlapping();
```

Replace it with the hardened version.

```php
Schedule::command('report:generate')
    ->everyMinute()
    ->withoutOverlapping(10)
    ->runInBackground()
    ->onOneServer();
```

Each addition solves one concern. Passing `10` to `withoutOverlapping(10)` sets the lock to expire after ten minutes, so a crashed run frees the lock automatically within ten minutes instead of holding it for a day; choose a value comfortably longer than the job's worst-case runtime. `runInBackground()` runs the command in its own process so a slow report does not delay other tasks that are due in the same `schedule:run` tick. `onOneServer()` ensures that when several servers share the schedule, only the first one to grab the lock runs the task, which prevents duplication across machines. Confirm the schedule still lists correctly.

```bash
php artisan schedule:list
```

```
  * * * * *  php artisan report:generate ........... Next Due: 42 seconds from now
```

Both `withoutOverlapping()` and `onOneServer()` rely on a cache store that supports atomic locks. Our default `database` store does, which is why this works out of the box. The one rule to remember on multi-server setups is that every server must point at the same shared cache store, otherwise each server has its own private lock and `onOneServer()` cannot coordinate them. With the schedule production ready, let us walk through the tooling.

## Step 6: Try It Out {#step-6-try-it-out}

Beyond firing the scheduler, Laravel ships several commands for inspecting and debugging schedules. Here are the ones you will reach for most.

### Scenario 1: List Everything That Is Scheduled

`schedule:list` shows every registered task, its cron expression, and when it next runs. It is the fastest way to confirm a task is actually wired up.

```bash
php artisan schedule:list
```

```
  * * * * *  php artisan report:generate ........... Next Due: 30 seconds from now
```

### Scenario 2: Run a Single Task On Demand

When you want to run one scheduled task immediately without waiting for its cron time, use `schedule:test`. It lists your tasks and lets you pick one to run right now.

```bash
php artisan schedule:test
```

```
 Which command would you like to run?
  › '/usr/bin/php8.5' 'artisan' report:generate

Running ['artisan' report:generate] normally in background .. 30s DONE
⇂ '/usr/bin/php8.5' 'artisan' report:generate > '/dev/null' 2>&1
```

Because our task now uses `runInBackground()`, Laravel runs it as a background process and redirects the command output to `/dev/null`. The report still gets created; check the logs or database if you want to confirm the result after the command finishes. This is handy for confirming the scheduled event itself behaves before you trust it to cron.

### Scenario 3: Watch the Overlap Lock Skip a Run

Repeat the concurrent fire from Step 4 and tail the log to watch one run proceed while the other is skipped.

```bash
php artisan schedule:run & php artisan schedule:run & wait
```

```
[2026-05-29 10:10:01] local.INFO: START report:generate at 10:10:01
[2026-05-29 10:10:31] local.INFO: END report:generate at 10:10:31 (report #6)
```

A single START and END pair confirms the lock did its job; the second process found the lock held and moved on.

### Scenario 4: Clear a Stuck Lock

If a job is force-killed and you do not want to wait for the lock to expire, you can clear all schedule overlap locks manually with `schedule:clear-cache`.

```bash
php artisan schedule:clear-cache
```

```
   INFO  Deleting mutex for ['/usr/bin/php8.5' 'artisan' report:generate].
```

This releases the locks immediately so the next scheduled run can proceed. With the behavior understood, we lock it down with tests.

## Step 7: Write the Tests {#step-7-write-the-tests}

We can verify two things in automated tests: that the command produces the right output, and that the schedule is configured with the overlap protection we expect. The schedule definition is inspectable through the scheduler instance's `events()` method, so we can assert on it directly. Create the test file.

```bash
php artisan make:test ReportScheduleTest --pest
```

Open `tests/Feature/ReportScheduleTest.php` and write the suite.

```php
<?php

use App\Models\Order;
use App\Models\Report;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

function reportEvent()
{
    return collect(app(Schedule::class)->events())
        ->first(fn ($event) => str_contains($event->command ?? '', 'report:generate'));
}

it('generates a single report from the orders', function () {
    Order::factory()->count(5)->create(['amount' => 100]);

    $this->artisan('report:generate', ['--sleep' => 0])->assertExitCode(0);

    expect(Report::count())->toBe(1);

    $report = Report::first();

    expect($report->total_orders)->toBe(5)
        ->and((float) $report->total_amount)->toBe(500.0);
});

it('schedules the report command to run every minute', function () {
    $event = reportEvent();

    expect($event)->not->toBeNull()
        ->and($event->expression)->toBe('* * * * *');
});

it('protects the scheduled report from overlapping', function () {
    expect(reportEvent()->withoutOverlapping)->toBeTrue();
});

it('runs the scheduled report on one server only', function () {
    expect(reportEvent()->onOneServer)->toBeTrue();
});

it('writes one report per direct invocation because the lock is a scheduler guard', function () {
    Order::factory()->count(3)->create();

    $this->artisan('report:generate', ['--sleep' => 0]);
    $this->artisan('report:generate', ['--sleep' => 0]);

    expect(Report::count())->toBe(2);
});
```

The shared `reportEvent()` helper finds our task among the registered schedule events so each test can assert on it. The first test runs the command and proves it produces exactly one report with the correct totals. The next three inspect the schedule definition itself: that it runs every minute, that `withoutOverlapping` is enabled, and that `onOneServer` is enabled. The last test makes an important point explicit: calling the command directly twice writes two reports, because `withoutOverlapping()` guards the scheduler, not the command. Invoking the command by hand or from code bypasses the lock entirely. Run the suite.

```bash
php artisan test
```

```
$ php artisan test

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true                                                    0.01s  

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.11s  

   PASS  Tests\Feature\ReportScheduleTest
  ✓ it generates a single report from the orders                         0.10s  
  ✓ it schedules the report command to run every minute                  0.03s  
  ✓ it protects the scheduled report from overlapping                    0.02s  
  ✓ it runs the scheduled report on one server only                      0.02s  
  ✓ it writes one report per direct invocation because the lock is a sc… 0.03s  

  Tests:    7 passed (11 assertions)
  Duration: 0.38s

```

Five green tests confirm the command works and the schedule carries the protection we configured. With the behavior verified, here is what is happening underneath.

## How withoutOverlapping Works Under the Hood {#how-withoutoverlapping-works-under-the-hood}

The mechanism behind `withoutOverlapping()` is an atomic lock, also called a mutex, stored in your cache. When `schedule:run` decides a protected task is due, it first asks the cache to create a lock keyed to that specific task. Creating an atomic lock is an all-or-nothing operation: either this process is the one that created it, or the lock already exists and the request fails. If the lock is created successfully, the task runs and the lock is released in a `finally` block when the task completes. If the lock already exists, meaning a previous run is still holding it, the task is skipped and nothing runs.

This is why the lock has an expiration. The release happens in normal code flow, but if the process is killed hard, for example by an out-of-memory killer or a `kill -9`, that release never executes and the lock lingers. Without an expiry the task would be blocked forever. By default the lock is set to expire after twenty four hours, which is safe but slow to recover; passing a number of minutes, as in `withoutOverlapping(10)`, shortens that recovery window to something matched to your job. The right value is a little longer than the longest run you ever expect, so a healthy slow run is never cut off but a dead lock frees quickly. When you cannot wait even that long, `schedule:clear-cache` removes the lock immediately.

It also explains a subtlety that the last test demonstrated. The lock is created and checked inside the scheduler's run cycle, not inside the command. If you dispatch the command yourself with `Artisan::call('report:generate')` or run it manually, no lock is involved and nothing prevents two copies from running. The protection is a property of how the task is scheduled, so overlap safety only applies to runs that go through `schedule:run`.

## withoutOverlapping vs onOneServer vs runInBackground {#withoutoverlapping-vs-ononeserver-vs-runinbackground}

These three methods are easy to confuse because they all relate to how a scheduled task runs, but each solves a distinct problem, and knowing which is which keeps you from reaching for the wrong one. `withoutOverlapping()` prevents a task from running on top of itself on a single server, which is the slow-job-firing-again situation we built this tutorial around. It answers the question "what if the last run is not finished yet?"

`onOneServer()` solves a different problem that only appears when several servers share the same schedule. Without it, every server's cron runs `schedule:run`, so a task fires once per server and you get one report per machine instead of one report total. `onOneServer()` uses a lock so that only the first server to claim the task actually runs it, which answers "what if many servers all try to run this at the same minute?" Because it depends on a shared lock, every server must use the same central cache store.

`runInBackground()` is not about preventing duplication at all; it is about throughput. Normally `schedule:run` executes due tasks one after another in the same process, so a task that takes thirty seconds delays everything queued behind it. `runInBackground()` forks the task into its own process so the scheduler can move on immediately, which answers "what if this slow task is holding up my other scheduled jobs?" In practice a heavy, frequently scheduled job like ours often wants all three together, exactly as we configured it in Step 5.

## Conclusion {#conclusion}

A scheduled job that runs longer than its interval is a quiet bug that only bites under load, and the default behavior of stacking a fresh copy on top of a running one is rarely what you want for anything heavy. Laravel gives you precise, declarative control over this with a few chained methods. Here are the ideas worth keeping.

- **Overlap happens when a run outlasts its interval.** A job scheduled every five minutes that takes seven will have two copies running at once, leading to duplicated work, doubled totals, and deadlocks under load.
- **`withoutOverlapping()` is a one-line fix.** It wraps the task in an atomic cache lock so the scheduler skips a new run while the previous one is still holding the lock.
- **Always bound the lock with an expiry.** Passing minutes to `withoutOverlapping(10)` means a crashed run frees its lock within ten minutes instead of the twenty four hour default, so the task is never blocked indefinitely.
- **The lock guards the scheduler, not the command.** Overlap protection applies only to runs that go through `schedule:run`; calling the command directly bypasses it entirely.
- **Know which method solves which problem.** `withoutOverlapping()` stops same-server overlap, `onOneServer()` stops multi-server duplication, and `runInBackground()` stops a slow task from blocking other due tasks.
- **The database cache store is enough.** Because Laravel 13's `database` store supports atomic locks, overlap protection works without Redis, as long as every server in a fleet shares the same cache store.
