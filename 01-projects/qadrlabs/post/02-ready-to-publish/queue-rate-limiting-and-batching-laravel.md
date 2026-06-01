# Queue Rate Limiting and Batching in Laravel 13: Send Thousands of Bulk Emails Without Getting Banned by Your SMTP Provider

You finally finished the newsletter feature, you loop over ten thousand subscribers, and you call `Mail::to($subscriber)->send(...)` inside a `foreach`. It works beautifully against your three test rows. Then you point it at the real list and everything falls apart. Your SMTP provider accepts the first few hundred messages, then starts returning `421 Too many messages` errors, drops the connection, and twenty minutes later you get an email from Mailgun saying your account has been temporarily suspended for suspicious sending behavior. The web request that triggered all of this timed out long ago, half your subscribers got an email, the other half did not, and you have no idea which is which.

The damage compounds quickly. A suspended sending account means even your transactional emails (password resets, receipts, login codes) stop going out. Your domain reputation drops, so the messages that do get through start landing in spam. And because you fired everything from a single synchronous loop, you have no record of what succeeded and what failed, so your only option is to guess or to send the whole batch again and risk double-emailing everyone.

The fix is to stop treating bulk email as one giant synchronous task. In this tutorial we move email sending into a queued job, throttle how fast those jobs run with Laravel's `RateLimited` middleware so we never exceed our provider's limits, and wrap the whole send in a job batch so we get progress tracking, aggregate failure handling, and the ability to cancel a run mid-flight. By the end you will be able to queue tens of thousands of emails, send them at a controlled pace, and know exactly how the run went.

## Overview {#overview}

The strategy has three moving parts that work together. A **queued job** takes the email send off the web request so nothing times out. The **`RateLimited` job middleware** caps how many of those jobs run per minute, which is what keeps your SMTP provider happy. And **job batching** groups all the per-recipient jobs into a single trackable unit so you can watch progress, react to failures, and cancel the run if you need to. We will build each piece on top of the others, run a real queue worker, and watch the rate limiter slow the send down in real time.

### What You'll Build

- A Laravel 13 command that broadcasts a newsletter to thousands of subscribers
- A queueable, batchable job that sends one email per subscriber
- A rate limiter that caps sending at a fixed number of emails per minute so your SMTP provider never throttles or bans you
- A dispatched job batch with progress tracking, aggregate failure handling, and cancellation support
- A Pest test suite that verifies the batch, the mail, and the rate limiting without sending a single real email

### What You'll Learn

- How to configure the database queue connection and the tables job batching needs
- How to make a Mailable that is sent from inside a queued job
- How to apply the `RateLimited` middleware to a job and register a named limiter with `RateLimiter::for()`
- Why `retryUntil()` is safer than `$tries` when a job can be released by a rate limiter
- How to dispatch a batch with `Bus::batch()` and use the `then`, `catch`, and `finally` callbacks
- How to inspect batch progress and cancel a running batch
- How job rate limiting actually works under the hood, and when batching beats a plain queue

### What You'll Need

- PHP 8.3 or newer
- Composer and the Laravel installer
- Basic familiarity with Eloquent models, Artisan commands, and how queues work conceptually
- An SMTP account is not required for this tutorial; we use the `log` mailer so every "sent" email is written to a log file you can inspect

## Step 1: Create the Project and Configure the Queue {#step-1-create-the-project-and-configure-the-queue}

Start with a fresh Laravel 13 application configured for SQLite and Pest. Run the installer, then move into the project directory.

```bash
laravel new bulk-mailer --no-interaction --database=sqlite --pest --no-boost
cd bulk-mailer
```

The `--database=sqlite` flag wires the application to a local SQLite file and uncomments the SQLite block in `phpunit.xml`, and `--pest` installs Pest as the test runner. Nothing else needs to be installed for queues or batching; both ship with the framework.

Next, tell Laravel to use the database queue connection and the log mailer. Open `.env` and set these two values.

```dotenv
QUEUE_CONNECTION=database
MAIL_MAILER=log
```

`QUEUE_CONNECTION=database` means dispatched jobs are stored as rows in a `jobs` table and a worker pulls them off one at a time, which is exactly the controlled, resumable behavior we want for bulk email. `MAIL_MAILER=log` writes each outgoing message to `storage/logs/laravel.log` instead of contacting a real SMTP server, so you can run the entire tutorial without credentials and still verify what would have been sent.

A fresh Laravel 13 app already includes the migrations for the tables we need. The default `database/migrations/0001_01_01_000002_create_jobs_table.php` migration creates the `jobs`, `job_batches`, and `failed_jobs` tables in one file, and the cache migration creates the `cache` table that the rate limiter uses for its counters. Run the migrations to create everything.

```bash
php artisan migrate
```

You should see output confirming the tables were created.

```
   INFO  Preparing database.

  Creating migration table ............................................ 4ms DONE

   INFO  Running migrations.

  0001_01_01_000000_create_users_table ............................... 9ms DONE
  0001_01_01_000001_create_cache_table ............................... 2ms DONE
  0001_01_01_000002_create_jobs_table ................................ 5ms DONE
```

The `jobs` table holds queued jobs waiting to run, `job_batches` tracks the aggregate state of each batch, and `cache` backs the rate limiter. With the queue and mail configured, we can build the data we are going to email.

## Step 2: Build the Subscriber Model and Seed Test Data {#step-2-build-the-subscriber-model-and-seed-test-data}

We need a list of recipients to send to. Generate a `Subscriber` model together with a migration and a factory in one command.

```bash
php artisan make:model Subscriber -mf
```

The `-mf` flags create the migration and factory alongside the model. Open the generated migration in `database/migrations` and define the columns.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscribers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('subscribers');
    }
};
```

This is a deliberately small table: a name and a unique email are all we need to address a message. The `unique` constraint on `email` mirrors a real subscriber list where one address appears once.

Run the new migration so the `subscribers` table exists before we seed it.

```bash
php artisan migrate
```

Laravel runs only the migration we just added because the default tables were already created in Step 1.

```
   INFO  Running migrations.

  2026_06_01_101506_create_subscribers_table ......................... 4ms DONE
```

Your timestamp will be different because Laravel prefixes generated migration files with the date and time they were created. That is fine as long as the migration name ends with `create_subscribers_table`.

Now open `app/Models/Subscriber.php` and declare which attributes are mass assignable using the `#[Fillable]` attribute.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['name', 'email'])]
class Subscriber extends Model
{
    use HasFactory;
}
```

The `#[Fillable(['name', 'email'])]` attribute marks `name` and `email` as safe to set through `create()` and `fill()`, which keeps mass assignment protection on without the older `protected $fillable` property.

Open the generated factory at `database/factories/SubscriberFactory.php` and define how a fake subscriber looks.

```php
<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

class SubscriberFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'email' => fake()->unique()->safeEmail(),
        ];
    }
}
```

Using `fake()->unique()->safeEmail()` guarantees every generated address is distinct, so we never hit the `unique` constraint when we seed a large list.

Finally, seed a sizable list so the rate limiting is actually observable. Open `database/seeders/DatabaseSeeder.php` and create one thousand subscribers.

```php
<?php

namespace Database\Seeders;

use App\Models\Subscriber;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        Subscriber::factory()->count(1000)->create();
    }
}
```

One thousand rows is enough to clearly see throttling in action without waiting all day. Run the seeder.

```bash
php artisan db:seed
```

The command reports the seeding result.

```
   INFO  Seeding database.
```

Confirm the count quickly with Tinker so you know the data is there before building the job.

```bash
php artisan tinker --execute="echo App\Models\Subscriber::count();"
```

```
1000
```

We now have a thousand recipients waiting. Next we build the message itself.

## Step 3: Create the Mailable {#step-3-create-the-mailable}

Generate a Mailable that represents the newsletter.

```bash
php artisan make:mail NewsletterMail
```

Open `app/Mail/NewsletterMail.php` and define it. Notice that this Mailable does not implement `ShouldQueue`. We are going to send it from inside a queued job, so the queueing happens at the job level, not the Mailable level. Putting it on both would queue the work twice.

```php
<?php

namespace App\Mail;

use App\Models\Subscriber;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class NewsletterMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public Subscriber $subscriber)
    {
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Our Monthly Newsletter',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.newsletter',
        );
    }
}
```

The constructor accepts the `Subscriber` so the template can greet the recipient by name, and `SerializesModels` lets the model survive being stored on the queue and reloaded when the job runs. The `envelope()` method sets the subject line and `content()` points at the Blade view we are about to create.

Create the view file at `resources/views/emails/newsletter.blade.php`.

```blade
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Our Monthly Newsletter</title>
</head>
<body style="font-family: sans-serif; color: #1f2937; line-height: 1.6;">
    <h1 style="font-size: 20px;">Hello {{ $subscriber->name }},</h1>

    <p>
        Thanks for staying subscribed. Here is what we have been working on this
        month, delivered safely at a pace your inbox provider is happy with.
    </p>

    <p>Talk soon,<br>The Team</p>

    <div style="margin-top: 32px; text-align: center; font-size: 12px; color: #6b7280;">
        <a href="https://qadrlabs.com" style="color: #2563eb;" target="_blank">
            Tutorial Queue Rate Limiting and Batching at qadrlabs.com
        </a>
    </div>
</body>
</html>
```

Because the `subscriber` property on the Mailable is public, it is automatically available inside the view as `$subscriber`, so `{{ $subscriber->name }}` renders the recipient's name. The inline styles keep the email self-contained, which is how real HTML emails are written since email clients ignore external stylesheets. With the message ready, we can build the job that sends it under rate control.

## Step 4: Build the Email Job with Rate Limiting {#step-4-build-the-email-job-with-rate-limiting}

This is the core of the tutorial. Generate the job.

```bash
php artisan make:job SendNewsletterEmail
```

Open `app/Jobs/SendNewsletterEmail.php`. We are going to make it batchable, apply the `RateLimited` middleware, and use `retryUntil()` instead of a fixed retry count. Each of those choices matters, and the explanation follows the code.

```php
<?php

namespace App\Jobs;

use App\Mail\NewsletterMail;
use App\Models\Subscriber;
use DateTime;
use Illuminate\Bus\Batchable;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Middleware\RateLimited;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Mail;

class SendNewsletterEmail implements ShouldQueue
{
    use Batchable, Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public Subscriber $subscriber)
    {
    }

    public function handle(): void
    {
        // If the batch was cancelled, skip the remaining jobs quietly.
        if ($this->batch()?->cancelled()) {
            return;
        }

        Mail::to($this->subscriber->email)
            ->send(new NewsletterMail($this->subscriber));
    }

    public function middleware(): array
    {
        // Throttle this job through the "emails" limiter we register in Step 4.
        return [new RateLimited('emails')];
    }

    public function retryUntil(): DateTime
    {
        // Keep retrying for two hours instead of counting fixed attempts,
        // so rate-limited releases never exhaust the job.
        return now()->addHours(2);
    }
}
```

There are three deliberate decisions here. The `Batchable` trait lets this job report its success or failure to a parent batch, and the `$this->batch()?->cancelled()` guard means a cancelled batch will short-circuit every remaining job instead of pushing more mail. The `middleware()` method attaches `RateLimited('emails')`, which routes every execution of this job through a named limiter so the worker never sends faster than we allow. And `retryUntil()` replaces the usual `$tries` property on purpose: a rate-limited job gets released back onto the queue to try again later, and each release counts as an attempt, so a fixed `$tries = 3` would burn through its attempts purely from throttling. Telling Laravel to keep trying until two hours from now means the job survives as many rate-limit releases as it takes.

The `RateLimited('emails')` middleware refers to a limiter named `emails`, which does not exist yet. Register it in the `boot()` method of `app/Providers/AppServiceProvider.php`.

```php
<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        // Allow at most 60 newsletter emails per minute across all workers.
        RateLimiter::for('emails', function () {
            return Limit::perMinute(60);
        });
    }
}
```

`RateLimiter::for('emails', ...)` registers a named limiter, and `Limit::perMinute(60)` caps the throughput at sixty executions per minute. When the limit is reached, the `RateLimited` middleware releases the job back to the queue and tells the worker to wait until the limiter resets before trying again. Set this number to match whatever your SMTP provider actually allows; sixty per minute is a conservative value that keeps the demo readable. With the job throttled and the limiter registered, the last piece is dispatching all thousand jobs as one batch.

## Step 5: Dispatch the Emails as a Batch {#step-5-dispatch-the-emails-as-a-batch}

We will trigger the send from an Artisan command so it is easy to run and easy to test. Generate the command.

```bash
php artisan make:command SendNewsletter
```

Open `app/Console/Commands/SendNewsletter.php` and build the batch.

```php
<?php

namespace App\Console\Commands;

use App\Jobs\SendNewsletterEmail;
use App\Models\Subscriber;
use Illuminate\Bus\Batch;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\Log;
use Throwable;

class SendNewsletter extends Command
{
    protected $signature = 'newsletter:send';

    protected $description = 'Queue the monthly newsletter to every subscriber as a rate-limited batch';

    public function handle(): int
    {
        // Build one job per subscriber.
        $jobs = Subscriber::all()
            ->map(fn (Subscriber $subscriber) => new SendNewsletterEmail($subscriber));

        $batch = Bus::batch($jobs)
            ->name('Monthly Newsletter')
            ->allowFailures()
            ->then(function (Batch $batch) {
                Log::info("Newsletter finished: {$batch->totalJobs} emails processed.");
            })
            ->catch(function (Batch $batch, Throwable $e) {
                Log::error("Newsletter batch hit an error: {$e->getMessage()}");
            })
            ->finally(function (Batch $batch) {
                Log::info("Batch {$batch->id} done. Failed jobs: {$batch->failedJobs}.");
            })
            ->dispatch();

        $this->info("Dispatched batch {$batch->id} with {$batch->totalJobs} emails queued.");

        return self::SUCCESS;
    }
}
```

`Bus::batch($jobs)` accepts the collection of jobs and returns a pending batch you configure with a chain of methods. `name('Monthly Newsletter')` gives the batch a human-readable label that shows up when you inspect it. `allowFailures()` tells the batch to keep processing the remaining jobs even if some fail, which is what you want for bulk email since one bad address should not stop the whole send. The three callbacks fire on different outcomes: `then` runs when every job has finished successfully, `catch` runs the first time any job throws, and `finally` runs once the batch is completely done regardless of outcome. Calling `dispatch()` writes the jobs to the queue and returns the `Batch` instance so we can print its id.

One note on scale: `Subscriber::all()` loads every subscriber into memory at once, which is fine for the thousand rows in this tutorial. For a list in the hundreds of thousands, you would instead dispatch a small number of "loader" jobs that each add a chunk of email jobs to the batch, so you never hold the entire list in memory at once. The batch API supports adding jobs after creation for exactly this reason. With the command in place, it is time to run a worker and watch the throttling happen.

## Step 6: Run the Worker and Try It Out {#step-6-run-the-worker-and-try-it-out}

Everything is wired up. Now we exercise it from three angles: a normal throttled run, inspecting the batch while it works, and cancelling a batch mid-flight.

### Scenario 1: Dispatch and Watch the Rate Limiter

Open one terminal and start a queue worker so jobs actually get processed. Dispatching the batch writes rows to the `jobs` table, but nothing sends until a worker is running.

```bash
php artisan queue:work
```

In a second terminal, dispatch the newsletter.

```bash
php artisan newsletter:send
```

The command returns immediately with the batch id and the number of queued emails.

```
Dispatched batch 9b1f4c2e-5a3d-4f8e-9c1a-7d2b6e0f3a55 with 1000 emails queued.
```

Switch back to the worker terminal. You will see jobs processing quickly until the limiter reaches sixty sends in the current minute. After that, Laravel may still show fast `DONE` lines because the middleware handled the attempt and released the job before `handle()` sent mail. The important detail is that only sixty messages are written to the mail log during that minute, and the remaining jobs stay pending for the next limiter window.

```
   INFO  Processing jobs from the [default] queue.

  2026-05-29 10:00:01 App\Jobs\SendNewsletterEmail ............ RUNNING
  2026-05-29 10:00:01 App\Jobs\SendNewsletterEmail ............ 38ms DONE
  2026-05-29 10:00:01 App\Jobs\SendNewsletterEmail ............ RUNNING
  2026-05-29 10:00:01 App\Jobs\SendNewsletterEmail ............ 33ms DONE
  ...
  2026-05-29 10:01:00 App\Jobs\SendNewsletterEmail ............ RUNNING
  2026-05-29 10:01:00 App\Jobs\SendNewsletterEmail ............ 1ms DONE
```

This is the whole point of the exercise: the job may be attempted more often than sixty times in a minute, but `handle()` only sends mail while the limiter has capacity. Your SMTP provider sees a steady, polite stream instead of a thousand messages at once. Because we set `MAIL_MAILER=log`, each "sent" email is written to `storage/logs/laravel.log`. Open that file and you will see the rendered messages.

```
[2026-05-29 10:00:01] local.DEBUG: Message-ID: <abc123@bulk-mailer>
Subject: Our Monthly Newsletter
To: kris.wolf@example.org

Hello Kristofer Wolf,

Thanks for staying subscribed. Here is what we have been working on this
month, delivered safely at a pace your inbox provider is happy with.
```

### Scenario 2: Inspect the Batch While It Runs

While the worker is still chewing through the queue, open a third terminal and inspect the batch with Tinker. Use the batch id that `newsletter:send` printed.

```bash
php artisan tinker
```

```php
> $batch = Bus::findBatch('9b1f4c2e-5a3d-4f8e-9c1a-7d2b6e0f3a55');
> $batch->totalJobs;
= 1000

> $batch->pendingJobs;
= 742

> $batch->progress();
= 25

> $batch->finished();
= false
```

`Bus::findBatch()` loads the live state of the batch from the `job_batches` table. `totalJobs` is the size of the run, `pendingJobs` counts how many have not finished yet, `progress()` returns the percentage complete, and `finished()` tells you whether the batch is fully done. This is the visibility a plain `foreach` loop can never give you.

### Scenario 3: Cancel a Running Batch

Suppose halfway through you realize the newsletter has a typo. Dispatch a fresh batch, grab its id, and cancel it from Tinker before the worker finishes.

```php
> $batch = Bus::findBatch('the-new-batch-id');
> $batch->cancel();
= null

> $batch->cancelled();
= true
```

Once `cancel()` is called, the `$this->batch()?->cancelled()` guard we added in `SendNewsletterEmail::handle()` kicks in. The worker still pulls the remaining jobs off the queue, but each one returns immediately without sending an email. You will see them complete in milliseconds in the worker terminal because they are doing nothing but checking the cancelled flag.

```
  2026-05-29 10:05:12 App\Jobs\SendNewsletterEmail ............ 1ms DONE
  2026-05-29 10:05:12 App\Jobs\SendNewsletterEmail ............ 1ms DONE
```

That is the full lifecycle: a throttled send, live progress, and a clean cancel. Now we lock the behavior in with tests.

### Optional Cleanup: Reset the Demo

If you only processed a few jobs while testing, the `jobs` table will still contain the remaining newsletter jobs. You can clear them before repeating the demo.

```bash
php artisan queue:clear
```

Laravel asks for confirmation because clearing a queue deletes pending jobs.

```
  WARN  Are you sure you want to delete all of the jobs from the [default] queue? (yes/no) [no]
❯ yes

   INFO  Jobs deleted successfully.
```

If you want to reset the database and seed the thousand subscribers again, use `migrate:fresh --seed`.

```bash
php artisan migrate:fresh --seed
```

This drops all tables, recreates the Laravel queue, cache, and subscriber tables, then runs `DatabaseSeeder` again. Use it only in a local tutorial project because it deletes existing data.

## Step 7: Write the Tests {#step-7-write-the-tests}

We will verify the important guarantees without sending a single real email or running a real worker, using Laravel's `Bus::fake()` and `Mail::fake()`. Create the test file.

```bash
php artisan make:test NewsletterBatchTest --pest
```

Open `tests/Feature/NewsletterBatchTest.php` and write the suite.

```php
<?php

use App\Jobs\SendNewsletterEmail;
use App\Mail\NewsletterMail;
use App\Models\Subscriber;
use Illuminate\Bus\PendingBatch;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Queue\Middleware\RateLimited;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\RateLimiter;

uses(RefreshDatabase::class);

it('dispatches a batch named Monthly Newsletter', function () {
    Bus::fake();
    Subscriber::factory()->count(5)->create();

    $this->artisan('newsletter:send')->assertExitCode(0);

    Bus::assertBatched(fn (PendingBatch $batch) => $batch->name === 'Monthly Newsletter'
        && $batch->jobs->count() === 5);
});

it('queues one job per subscriber', function () {
    Bus::fake();
    Subscriber::factory()->count(12)->create();

    $this->artisan('newsletter:send');

    Bus::assertBatched(fn (PendingBatch $batch) => $batch->jobs->count() === 12);
});

it('allows failures so one bad email does not stop the batch', function () {
    Bus::fake();
    Subscriber::factory()->count(3)->create();

    $this->artisan('newsletter:send');

    Bus::assertBatched(fn (PendingBatch $batch) => $batch->allowsFailures());
});

it('sends the newsletter mailable when a job runs', function () {
    Mail::fake();
    $subscriber = Subscriber::factory()->create();

    (new SendNewsletterEmail($subscriber))->handle();

    Mail::assertSent(NewsletterMail::class, fn (NewsletterMail $mail) => $mail->hasTo($subscriber->email));
});

it('applies the RateLimited middleware to the job', function () {
    $subscriber = Subscriber::factory()->create();

    $middleware = (new SendNewsletterEmail($subscriber))->middleware();

    expect($middleware)->toHaveCount(1)
        ->and($middleware[0])->toBeInstanceOf(RateLimited::class);
});

it('registers the emails rate limiter', function () {
    expect(RateLimiter::limiter('emails'))->not->toBeNull();
});

it('skips sending when the batch is cancelled', function () {
    Mail::fake();
    $subscriber = Subscriber::factory()->create();

    [$job, $batch] = (new SendNewsletterEmail($subscriber))->withFakeBatch();
    $batch->cancel();

    $job->handle();

    Mail::assertNothingSent();
});
```

Each test pins down one promise the feature makes. The first three use `Bus::fake()` to intercept the batch and assert its name, its job count, and that failures are allowed, all without touching the queue. The fourth runs the job's `handle()` directly with `Mail::fake()` and asserts the right Mailable went to the right address. The fifth and sixth confirm the throttling wiring is present: the job carries the `RateLimited` middleware and the `emails` limiter is registered. The last test uses `withFakeBatch()`, a helper that hands back the job already attached to a fake batch, so we can cancel the batch and prove the job sends nothing. Run this feature test file.

```bash
php artisan test tests/Feature/NewsletterBatchTest.php
```

```
   PASS  Tests\Feature\NewsletterBatchTest
  ✓ it dispatches a batch named Monthly Newsletter            0.18s
  ✓ it queues one job per subscriber                          0.02s
  ✓ it allows failures so one bad email does not stop the batch  0.02s
  ✓ it sends the newsletter mailable when a job runs          0.03s
  ✓ it applies the RateLimited middleware to the job          0.01s
  ✓ it registers the emails rate limiter                      0.01s
  ✓ it skips sending when the batch is cancelled              0.02s

  Tests:    7 passed (9 assertions)
  Duration: 0.30s
```

Seven green tests confirm the batch is built correctly, the mail is addressed correctly, the rate limiter is in place, and cancellation is honored. If you run `php artisan test` without a path, Laravel's generated example tests may also appear in the output. With the behavior verified, the rest of the article explains what is happening underneath.

## How Job Rate Limiting Works {#how-job-rate-limiting-works}

It is worth understanding what the `RateLimited` middleware actually does, because the behavior is not obvious and it changes how you should configure retries. When a job wrapped in `RateLimited` is about to run, the middleware asks the named limiter whether there is capacity left in the current window. If there is, the job runs and the limiter's counter increments. If the limiter is exhausted, the middleware does not run your `handle()` method at all; instead it releases the job back onto the queue with a delay equal to the number of seconds until the limiter resets.

This release-and-retry mechanism is why we used `retryUntil()` instead of `$tries`. Every release counts as an attempt, so a job that sits behind a busy limiter for several minutes can rack up dozens of attempts purely from throttling. If you had set `$tries = 3`, the job would be marked failed after three rate-limit releases even though nothing actually went wrong. Defining `retryUntil()` instead tells Laravel to keep retrying until a wall-clock deadline, so throttling can release the job as many times as it needs without ever exhausting it.

There are two flavors of the middleware. The `RateLimited` class we used is backed by the cache, which is perfect for the database queue and the default cache store. There is also `RateLimitedWithRedis`, which is functionally identical from your code's point of view but uses Redis commands that are atomic, so it stays accurate even when many workers hit the limiter at the same instant. If you scale up to a fleet of workers on Redis, switch the import and the class name; everything else stays the same.

You can also make the limiter conditional or segmented. Returning `Limit::none()` from inside the limiter closure removes the cap for certain conditions, and calling `->by(...)` on a limit gives each key its own bucket, for example throttling per sending domain rather than globally. For bulk email a single global `perMinute` limit is usually what you want, since the constraint is your provider's total throughput.

## When to Use Batching Versus a Plain Queue {#batching-versus-a-plain-queue}

Rate limiting and batching solve different problems, and you do not always need both. Rate limiting controls the pace. Batching controls the visibility and the aggregate lifecycle. You can rate-limit jobs without ever putting them in a batch, and that is completely fine when you only care that the work happens eventually and you do not need to know when the whole group is done.

Reach for batching when the group of jobs is a unit you care about as a whole. A newsletter send is a perfect example: you want to know the overall progress, you want a single callback to fire when the last email goes out, you want to count how many addresses bounced, and you want the option to cancel the entire run if you spot a mistake. None of that is possible with loose jobs on a queue, because each job knows nothing about the others. The `job_batches` table is what gives the group a shared identity and a place to record aggregate state.

If your task is a simple fire-and-forget (a single welcome email when one user signs up, say) a plain queued job with no batch is the right level of ceremony. Save batching for when you are dispatching many related jobs at once and the answer to "how did the whole run go?" actually matters.

## Conclusion {#conclusion}

Bulk email goes wrong when it is treated as one big synchronous loop. By moving the send onto the queue, throttling it, and wrapping it in a batch, you turn a fragile script that can get your account banned into a controlled, observable, resumable process. Here are the ideas worth keeping.

- **Send from a queued job, not a loop.** Taking the work off the web request is what prevents timeouts and lets a worker process emails one at a time at a pace you control.
- **The `RateLimited` middleware is your ban insurance.** Registering a named limiter with `RateLimiter::for()` and attaching `RateLimited` to the job caps throughput so your SMTP provider sees a steady stream instead of a flood.
- **Prefer `retryUntil()` over `$tries` for rate-limited jobs.** Because every rate-limit release counts as an attempt, a fixed retry count can fail a perfectly healthy job; a wall-clock deadline lets it survive as many throttled releases as it takes.
- **Batching gives you progress, callbacks, and cancellation.** `Bus::batch()` with `then`, `catch`, and `finally` plus `allowFailures()` turns a pile of loose jobs into a single trackable unit you can monitor and stop.
- **The cancelled check keeps cancellation cheap.** Guarding `handle()` with `$this->batch()?->cancelled()` means stopping a batch drains the remaining jobs instantly instead of sending mail you no longer want to send.
- **Choose the right tool for the scale.** A plain queued job is enough for one-off sends; reach for batching only when you are dispatching many related jobs and the aggregate outcome matters.
