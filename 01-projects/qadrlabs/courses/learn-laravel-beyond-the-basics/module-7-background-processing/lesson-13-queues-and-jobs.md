## 1. Before You Begin

Some tasks take time. Sending an email makes a network request to an SMTP server. Generating a PDF involves image processing. Calling a third-party API might take several seconds to respond. If these happen during an HTTP request, the user waits for a loading spinner and may think your app is slow. Queues let you defer slow work to run in the background, so the request finishes immediately and the user sees a fast response.

This lesson teaches Laravel's queue system. You will convert the comment notification email from Lesson 8 into a queued job, set up a queue worker to process jobs, and understand how to use different queue drivers. The benefit is immediate: after posting a comment, users no longer wait for the email to send. Instead, the email is queued and the user sees the success message right away. A separate worker process handles the slow email delivery in the background.

### What You'll Build

You will convert the comment email into a queued job, configure the `database` queue driver, run a queue worker, and verify emails send in the background without blocking the HTTP request.

### What You'll Learn

- ✅ Queue drivers: `sync`, `database`, `redis`
- ✅ Queueable Mailables (the `ShouldQueue` interface)
- ✅ Creating custom jobs with `make:job`
- ✅ Running queue workers with `php artisan queue:work`
- ✅ Failed jobs and retries
- ✅ Monitoring the queue

### What You'll Need

- Lesson 12 completed

---

## 2. Configure the Queue Driver

The default queue driver in Laravel is `sync`, which means the job runs immediately and synchronously, not deferred at all. This is fine for local development when you are not testing queue behavior, but to actually see queues in action, we will switch to the `database` driver. The database driver stores pending jobs in a `jobs` table, and a separate `queue:work` process polls the table and processes them.

### Step 1: Update .env

Open `.env` and change the queue connection setting to use the database driver.

```env
QUEUE_CONNECTION=database
```

This tells Laravel to use the database driver for queueing. Alternative drivers include `redis` (fast, recommended for production), `sqs` (Amazon's managed queue service), and `beanstalkd` (a lightweight queue server). The database driver is a good starting point because it requires no additional services; you just need a database table.

### Step 2: Create the Jobs Table

Before running the migration command, check whether the `jobs` table migration already exists in your project. Laravel 11+ ships with `database/migrations/0001_01_01_000002_create_jobs_table.php` by default, so running `php artisan queue:table` in that case will produce an `ERROR Migration already exists.` message and `php artisan migrate` will report `Nothing to migrate.`

If that file is already present in your `database/migrations/` folder, skip the `queue:table` command and only run migrate:

```bash
php artisan migrate
```

If the file does not exist, run both commands to generate and apply the migration:

```bash
php artisan queue:table
php artisan migrate
```

Either way, the result is the same: a `jobs` table in your database where pending jobs are stored. Each row represents one pending job, with columns for the serialized job payload, the queue name, the number of attempts made so far, and the timestamp when it becomes available to run. Laravel also has a `failed_jobs` table (created automatically in Laravel 11+) that stores jobs that permanently failed after exhausting all their retry attempts.

---

## 3. Make an Email Queueable

In Lesson 8, the `NewCommentEmail` class already uses the `Queueable` trait. But that trait alone does not make it queued automatically. You also need to either implement `ShouldQueue` on the Mailable, or call `queue()` instead of `send()` from the controller. Using `ShouldQueue` is usually preferred because it makes the deferred behavior a property of the Mailable class itself, so every caller automatically queues it without having to remember to use a different method.

### Step 1: Implement ShouldQueue

Open `app/Mail/NewCommentEmail.php` and add the `ShouldQueue` interface to the class declaration.

```php
<?php
// ... others lines of code

use Illuminate\Contracts\Queue\ShouldQueue;

class NewCommentEmail extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;
    // ... other methods and properties
}
```

Adding `implements ShouldQueue` is the switch that turns synchronous mails into queued ones. Now whenever any controller calls `Mail::to(...)->send(new NewCommentEmail(...))`, Laravel automatically puts the job on the queue instead of sending immediately. The method name is still `send()`, but the behavior changes silently. This is deliberate: you do not need to update every caller, just the Mailable class.

### Step 2: Verify the Controller

Open `app/Http/Controllers/CommentController.php`. The `store()` method code from Lesson 8 does not need to change. The same `send()` call now queues the job because the Mailable implements `ShouldQueue`, and Laravel inspects the Mailable at dispatch time to determine whether to run immediately or defer.

```php
if ($entry->user_id !== $request->user()->id) {
    Mail::to($entry->user)->send(new NewCommentEmail($comment, $entry));
}
```

Laravel inspects the Mailable and chooses queueing automatically based on the `ShouldQueue` interface. This keeps the controller code clean and unaware of the deferral mechanism.

---

## 4. Run the Queue Worker

The `database` driver stores jobs in the table but does not process them on its own. A queue worker is a separate PHP process that polls the `jobs` table and runs pending jobs. This separation is intentional: your web server handles HTTP requests, and the worker handles background jobs. They can scale independently.

### Step 1: Start the Worker

Open a new terminal (keep `php artisan serve` running in the other one) and run the following command.

```bash
php artisan queue:work
```

You should see output similar to the following as jobs are processed.

```
[2026-04-17 10:30:45] Processing: App\Mail\NewCommentEmail
[2026-04-17 10:30:46] Processed:  App\Mail\NewCommentEmail
```

The worker process loops continuously, checking the `jobs` table every few seconds. When it finds a pending job, it deserializes and runs it, logs the result, and moves on to the next. Keep this terminal open and running while you test queued jobs.

### Step 2: Trigger a Comment

In the browser, post a comment on another user's entry. The form submission returns immediately (fast!) and shows the success message without delay. Switch to the worker terminal and you should see the `Processing` and `Processed` lines appear within a second or two, confirming the email sent asynchronously in the background.

### Step 3: Inspect the Jobs Table

Stop the worker by pressing `Ctrl+C`, then post another comment in the browser. Open Tinker to inspect the pending job in the database.

```bash
php artisan tinker
```

Run the following queries to see the job row.

```php
DB::table('jobs')->count();
DB::table('jobs')->first();
```

`DB::table('jobs')->count()` returns 1, confirming there is one queued but not-yet-processed job. `DB::table('jobs')->first()` shows the full record, including a `payload` column containing the serialized job data. This is how queues survive application restarts: jobs are data stored in the database, not in-memory state. Type `exit` to leave Tinker, then start the worker again with `php artisan queue:work`. It picks up and processes the pending job immediately.

---

## 5. Create a Custom Job

Mailables are one kind of queueable job. Custom jobs are another, useful for arbitrary background work like generating reports, processing uploads, or cleaning up old data. Custom jobs are more flexible because they can do anything, not just send email.

### Step 1: Generate a Job

Run the following command to create the job class.

```bash
php artisan make:job CleanupOldEntries
```

This creates `app/Jobs/CleanupOldEntries.php` with a skeleton `handle()` method. All jobs generated by `make:job` implement the `ShouldQueue` contract by default in newer Laravel versions.

### Step 2: Write the Logic

Open `app/Jobs/CleanupOldEntries.php` and update the `handle()` method with the following.

```php
<?php

namespace App\Jobs;

use App\Models\Entry;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class CleanupOldEntries implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        $count = Entry::onlyTrashed()
            ->where('deleted_at', '<', now()->subDays(30))
            ->forceDelete();

        \Log::info("Permanently deleted {$count} old entries.");
    }
}
```

Reading through this job class carefully: `implements ShouldQueue` makes this job queueable, and the `Queueable` trait provides queue-specific methods like `onQueue()` for specifying a named queue, `delay()` for scheduling the job to run after a delay, and `retryUntil()` for time-based retry limits. The `handle()` method is the entry point and contains all the actual work. Inside, `Entry::onlyTrashed()` scopes the query to soft-deleted entries (from Lesson 4), the `where` clause filters for entries soft-deleted more than 30 days ago, and `forceDelete()` permanently removes them from the database, bypassing soft delete. The return value (the count of permanently deleted rows) is logged with `\Log::info()` so you can verify the job ran and how many records were affected.

### Step 3: Dispatch the Job

Open Tinker and dispatch the job manually to test it.

```bash
php artisan tinker
```

Run the following dispatch call from the Tinker prompt.

```php
\App\Jobs\CleanupOldEntries::dispatch();
```

The `dispatch()` static method provided by the `Queueable` trait puts the job on the queue and returns immediately. If the worker is running in another terminal, it picks up the job within a few seconds and runs `handle()`. The response in Tinker is `null` because dispatch is fire-and-forget; it does not wait for the job to complete.

### Step 4: Schedule the Job

Jobs like this are often best run on a schedule rather than manually. Open `routes/console.php` and add the following schedule definition.

```php
use Illuminate\Support\Facades\Schedule;

Schedule::job(new \App\Jobs\CleanupOldEntries)->daily();
```

To run scheduled jobs in production, you add a single cron entry that calls `php artisan schedule:run` every minute. Laravel's scheduler then checks which tasks are due at that time (daily, hourly, weekly, on specific days) and dispatches them. Locally, you can run `php artisan schedule:work` to simulate the cron runner for testing without waiting for the real clock.

---

## 6. Run and Test

Let us verify the full queue flow end-to-end.

### Step 1: Start the Worker with Verbose Output

Run the following command to start the queue worker with additional output detail.

```bash
php artisan queue:work --verbose
```

The `--verbose` flag shows additional detail about each processed job, including the job class name and any output from `handle()`.

### Step 2: Post a Comment

In the browser, post a comment on another user's entry. The page should redirect and show the success message immediately, before the email is sent.

### Step 3: Watch the Worker Output

The worker terminal should show the two confirmation lines.

```
[2026-04-17 10:30:45] Processing: App\Mail\NewCommentEmail
[2026-04-17 10:30:46] Processed:  App\Mail\NewCommentEmail
```

This confirms the email was sent asynchronously after the HTTP request completed. Check `storage/logs/laravel.log` to see the email content that was rendered and sent by the log driver.

### Step 4: Test Failed Jobs

Temporarily break the email template with invalid syntax (for example, reference a variable that does not exist like `{{ $nonexistent->foo }}`), post a comment, and watch the worker. You should see an error message appear on each retry attempt. The job is retried three times by default, and then moved to the `failed_jobs` table. Inspect failed jobs with the following command.

```bash
php artisan queue:failed
```

You should see a list of failed jobs with their IDs and the error message that caused the failure. After fixing the template error, retry a specific job by its ID.

```bash
php artisan queue:retry 1
```

Or retry all failed jobs at once.

```bash
php artisan queue:retry all
```

Fix the template before retrying; otherwise the same error causes the job to fail again and return to the failed table.

---

## 7. Fix the Errors in Your Code

These are the most common mistakes when implementing queues and jobs in Laravel.

**Error 1: Jobs are queued but nothing processes them because no worker is running.**

This error occurs when you switch to the `database` queue driver and dispatch jobs, but forget that a separate worker process is required to actually execute them. Jobs accumulate in the `jobs` table indefinitely.

```bash
# Wrong: QUEUE_CONNECTION=database is set, jobs are dispatched, but no worker is running
# Result: jobs pile up in the jobs table, no emails send, no tasks complete

# Correct: run the worker in a separate terminal while testing
php artisan queue:work
```

Without a running worker, `DB::table('jobs')->count()` grows with every dispatched job but no work is done. The fix is always to run `php artisan queue:work` in a dedicated terminal during development. In production, use Supervisor or systemd to keep the worker running continuously and restart it if it crashes.

---

**Error 2: Modifying job code, but the worker continues running the old version.**

This error occurs when you edit a job class but do not restart the worker. The worker process loads PHP code once at startup for performance reasons, so it continues using the in-memory version of the old class even after you save new code to disk.

```bash
# Wrong: editing CleanupOldEntries.php while the worker is running
# Result: worker processes jobs using the old, unmodified code

# Correct: stop the worker with Ctrl+C after every code change, then restart
php artisan queue:work

# Alternative for development: use queue:listen, which reloads code for every job
php artisan queue:listen
```

The `queue:work` command is optimized for production (fast, no code reload). The `queue:listen` command is better for development because it re-bootstraps the application for each job, picking up code changes automatically. The trade-off is that `queue:listen` is slower.

---

**Error 3: Dispatching a job with an unsaved model, causing a serialization failure.**

This error occurs when you dispatch a job and pass a model that was never saved to the database. The `SerializesModels` trait (used by the `Queueable` trait) stores models by their primary key and reloads them from the database when the job runs. An unsaved model has no primary key, so serialization fails.

```php
// Wrong: dispatching a job with a model that has not been saved yet
$entry = new Entry(['title' => 'Draft', 'content' => 'Not saved']);
CleanupOldEntries::dispatch($entry); // Fails: $entry->id is null

// Correct: always save the model first, then dispatch
$entry = Entry::create(['title' => 'Draft', 'content' => 'Saved']);
CleanupOldEntries::dispatch($entry); // Works: $entry->id is now set
```

The wrong version creates an in-memory model without persisting it. When the job is serialized for the queue, `SerializesModels` tries to store the model's primary key, finds null, and either throws an error or silently stores a null reference. When the worker later tries to reload the model using that null ID, it finds nothing. The correct version calls `create()`, which inserts the row and sets the `id` before dispatching.

---

## 8. Exercises

Apply what you learned by extending the queue setup independently before checking the solutions below.

**Exercise 1:** Make the `WelcomeEmail` queueable by implementing `ShouldQueue` on it. Test by registering a new user and confirming the HTTP request returns quickly while the email processes in the background.

**Exercise 2:** Create a `GenerateEntryPDF` job that takes an Entry as a constructor argument and logs "PDF generated for entry {title}" inside `handle()`. Dispatch it from the entry store controller after creating an entry.

**Exercise 3:** Use `delay()` to schedule the welcome email to be sent 1 hour after registration instead of immediately. Use `Mail::to($user)->later(now()->addHour(), new WelcomeEmail($user))`.

---

## 9. Solutions

Compare your implementations with the ones below. Focus on where the dispatch call lives and how model arguments are passed to jobs.

**Solution for Exercise 1:**

Open `app/Mail/WelcomeEmail.php` and add the `ShouldQueue` interface to the class declaration.

```php
<?php
// ... others lines of code

use Illuminate\Contracts\Queue\ShouldQueue;

class WelcomeEmail extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;
    // ... other methods and properties
}
```

Adding `implements ShouldQueue` is the only required change. Every `Mail::to(...)->send(new WelcomeEmail(...))` call in the registration flow now places the email on the queue instead of sending synchronously. To confirm it is deferred, register a new user while the worker is running and watch the terminal: the browser response returns before the `Processing` line appears, which proves the email did not block the HTTP request.

---

**Solution for Exercise 2:**

Generate the job class with Artisan.

```bash
php artisan make:job GenerateEntryPDF --no-interaction
```

Open `app/Jobs/GenerateEntryPDF.php` and update the class with a constructor and the log statement inside `handle()`.

```php
<?php

namespace App\Jobs;

use App\Models\Entry;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class GenerateEntryPDF implements ShouldQueue
{
    use Queueable;

    public function __construct(public Entry $entry) {}

    public function handle(): void
    {
        \Log::info("PDF generated for entry {$this->entry->title}");
    }
}
```

Then open `app/Http/Controllers/EntryController.php` and add the dispatch call inside the `store()` method, immediately after `$entry` is created.

```php
<?php
// ... others lines of code

use App\Jobs\GenerateEntryPDF;

class EntryController extends Controller
{
    // ... other methods

    public function store(Request $request): RedirectResponse
    {
        // ... other code
        $entry = auth()->user()->entries()->create($data);
        $entry->tags()->sync($validated['tags'] ?? []);
        GenerateEntryPDF::dispatch($entry);

        return redirect()->route('entries.index');
    }

    // ... other methods
}
```

The constructor uses the `public` promoted property syntax so `$this->entry` is available inside `handle()` without writing a separate assignment. The `SerializesModels` behavior (inherited from `Queueable`) stores the entry by its primary key and reloads it fresh from the database when the worker runs the job, so `$this->entry` always reflects the current database state at execution time, not the state at dispatch time.

---

**Solution for Exercise 3:**

In the registration controller, after creating and logging in the user, replace the direct `send()` call with `later()`.

```php
Mail::to($user)->later(now()->addHour(), new WelcomeEmail($user));
```

The `later()` method is a convenience wrapper around `send()` with a built-in delay. It accepts the delay as the first argument (a `Carbon` datetime or an integer of seconds) and the Mailable as the second argument. Alternatively, you can use the fluent dispatch syntax if the Mailable implements `ShouldQueue`.

```php
dispatch(function () use ($user) {
    Mail::to($user)->send(new WelcomeEmail($user));
})->delay(now()->addHour());
```

The delay means the job row in the `jobs` table has a future `available_at` timestamp. Workers check this field and skip jobs that are not yet available, so the welcome email is not delivered until at least one hour after registration. This behavior is most reliable when using the `database` or `redis` driver; the `sync` driver ignores delays since it runs synchronously and immediately.

---

## Next Up - Lesson 14

In this lesson you built a full queue workflow for Catatku. You switched from the `sync` driver to the `database` driver, ran `queue:table` and `migrate` to create the `jobs` table, and implemented `ShouldQueue` on `NewCommentEmail` so comment notifications are sent asynchronously without blocking the HTTP request. You created the `CleanupOldEntries` custom job, learned to dispatch it from Tinker and the scheduler, and tested the failed job workflow by deliberately breaking the template and using `queue:failed`, `queue:retry`, and the difference between `queue:work` (production) and `queue:listen` (development).

In Lesson 14, you will learn events and listeners: how to decouple side effects from your controllers using Laravel's observer pattern, so adding new behaviors means creating new listeners rather than modifying existing code.