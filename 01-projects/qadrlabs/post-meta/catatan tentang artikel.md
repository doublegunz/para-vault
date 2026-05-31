Article Title

  Queue Rate Limiting and Batching in Laravel 13: Send Thousands of Bulk Emails
  Without Getting Banned by Your SMTP Provider

  Short Description (160 char max)

  ▎ Send thousands of bulk emails in Laravel 13 without getting banned. Throttle
  ▎ queued jobs with RateLimited middleware and track progress using job
  ▎ batching.

  Character count: 152 ✅

  Category and Tags

  - Category: Laravel
  - Tags: laravel, laravel-13, queues, job-batching, rate-limiting, bulk-email,
  php


Article Title

  Laravel 13 Cache Tags: Invalidate a Single Article's Cache Without Flushing
  Your Entire Application

  Short Description (160 char max)

  ▎ Use Laravel 13 cache tags to invalidate one article's cache without flushing
  ▎ the whole app. Per-id tags, a model observer, and Redis-backed examples.

  Character count: 148 ✅

  Category and Tags

  - Category: Laravel
  - Tags: laravel, laravel-13, cache, cache-tags, redis, performance, php

  ---
  Key technical decisions baked in, for your sanity check before publishing:

  1. Redis via predis/predis as the taggable store (Step 1 first demonstrates
  the BadMethodCallException on the default database driver so the reader
  understands why we switch).
  2. Two-tag design (['articles', "article:{id}"]) gives both single-item and
  group invalidation; flushing any one tag invalidates the entry.
  3. Untagged homepage:stats acts as the control that survives every flush.
  4. Model observer with #[ObservedBy] replaces the manual controller flush in
  Step 5 (I showed old method vs new method for that edit).
  5. Tests use the array store so CI needs no Redis.

  Want me to actually scaffold the project and run php artisan test to verify
  the code, or leave it as-is? Social media captions are ready whenever you ask.

Article Title

  Laravel 13 Task Scheduling: Stop Heavy Cron Jobs From Overlapping With
  withoutOverlapping()

  Short Description (160 char max)

  ▎ Stop heavy Laravel cron jobs from overlapping. Use withoutOverlapping() with
  ▎ lock expiry, runInBackground, and onOneServer to run slow scheduled tasks
  ▎ safely.

  Character count: 157 ✅

  Category and Tags

  - Category: Laravel
  - Tags: laravel, laravel-13, task-scheduling, cron, withoutoverlapping,
  artisan, php

  ---
  Key technical decisions baked in, for your sanity check before publishing:

  1. Database lock store — relies on cache/cache_locks tables (Laravel 13's
  database store supports atomic locks), so no Redis needed.
  2. Problem-then-fix structure — Step 3 reproduces the overlap (two START
  lines, Report::count() jumps by 2), Step 4 fixes it (one START, count +1).
  3. --sleep option on the command so the schedule runs a real 30s heavy job
  while Pest tests run instantly with --sleep=0.
  4. Tests inspect the schedule definition via app(Schedule::class)->events()
  and assert expression, withoutOverlapping, and onOneServer properties; the
  last test deliberately proves the lock guards the scheduler, not direct
  command calls.
  5. Step 5 hardening layers withoutOverlapping(10) + runInBackground() +
  onOneServer(), each explained against its specific failure mode.

  Want me to scaffold the project and actually run php artisan test to verify,
  or leave it as-is? Social captions are ready whenever you ask.

Article Title

  Laravel 13 Database Transactions and Rollbacks: Stop Multi-Table Inserts From
  Half-Failing

  Short Description (160 char max)

  Use Laravel 13 database transactions to make multi-table inserts all-or-nothing. Roll back a failed checkout cleanly with DB::transaction and avoid partial data.

  Character count: 159 ✅

  Category and Tags

  - Category: Laravel
  - Tags: laravel, laravel-13, database, transactions, eloquent, data-integrity,
  php

  ---
  Key technical decisions baked in, for your sanity check before publishing:

  1. Problem-then-fix structure — Step 3 proves the partial write (order + 1
  item survive, stock dropped to 8 after a failed checkout); Step 4 wraps the
  same logic in DB::transaction() and shows a clean rollback (counts 0, stock
  back to 10).
  2. Service + HTTP endpoint — CheckoutService called from CheckoutController
  POST /checkout with validation; tests hit the endpoint via postJson (CSRF
  auto-disabled in tests), and one test also calls the service directly.
  3. Insufficient stock is the failure trigger (out-of-stock keyboard mid-loop).
  4. Three reference sections cover the BEGIN/COMMIT/ROLLBACK mechanics +
  deadlock retries, closure vs manual transactions (with lockForUpdate
  concurrency note for MySQL/Postgres since SQLite row locks are a no-op), and
  the afterCommit gotcha for queued jobs/events.

  Want me to scaffold the project and run php artisan test to verify, or leave
  it as-is? Social captions are ready whenever you ask.