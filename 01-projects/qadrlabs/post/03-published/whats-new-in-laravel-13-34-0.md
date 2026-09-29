# What's New in Laravel 13.34.0: Job Duration, Timeout Warnings, IAM Disks, and More

A queue can look perfectly healthy on a dashboard while one of its jobs gets a little slower every week. Nothing fails, nothing alerts, and the worker keeps reporting `DONE`. Until now, measuring how long a job actually ran meant listening to `JobProcessing`, stashing a timestamp somewhere, and subtracting it again inside `JobProcessed`. That is bookkeeping most teams never get around to writing, so the slowdown stays invisible.

The same blind spot exists at the other end of a job's life. A long import that hits its timeout is killed by the worker without warning. Every row it processed is forgotten, and the retry starts again from row one. When a third party API goes down and five hundred jobs pile up in `failed_jobs`, the only bulk cleanup command wipes the failed jobs of every other queue along with them. None of this is dramatic on its own, but each one turns into a long evening once it reaches production.

Laravel 13.34.0, released on 29 September 2026, targets exactly these gaps. The release adds a `duration` to the `JobProcessed` event, lets interruptible jobs react before a timeout kills them, scopes `queue:flush` to a single queue, and makes worker crashes count toward `maxExceptions`. Outside the queue, it brings keyless S3 disks through IAM credential providers, a `Schema::getColumn()` method, stricter polymorphic reads, and a long list of correctness fixes. This article walks through the changes that affect application code and shows each one running in a fresh 13.34.0 project.

## Overview {#overview}

This is an informational release roundup rather than a build-along tutorial. Each section explains one change, the problem it solves, and what the code looks like after upgrading. Where a change can be observed directly, the section includes a runnable example together with the real output from a fresh Laravel 13.34.0 installation, so the behavior can be verified in any existing project.

### What This Article Covers

- The queue and job changes: job duration, timeout notifications, crash counting, scoped flushing, and enum support.
- The infrastructure and database changes: IAM credential providers for S3, `Schema::getColumn()`, polymorphic relation fixes, and deadlock handling in `DatabaseLock`.
- The testing and HTTP changes: array support in `assertDatabaseCount()` and multipart retries that keep their file contents.
- A short tour of the smaller bug fixes that ship in the same release.

### What You'll Learn

- How to log job runtime from a single event listener without tracking timestamps manually.
- How to checkpoint a long running job when the worker is about to time out.
- How to opt a job into counting out of memory kills and segfaults toward `maxExceptions`.
- How to flush failed jobs for one queue while leaving the rest untouched.
- How to configure an S3 disk that reads credentials from ECS or an EC2 instance profile instead of static keys.
- How to read the metadata of a single database column and assert row counts across several tables in one call.

### What You'll Need

- PHP 8.3 or newer.
- A Laravel 13.x application that can be upgraded to 13.34.0, or a fresh project created with `laravel new`.
- The `pcntl` extension if you want to reproduce the timeout example, since worker timeouts rely on process signals.
- Basic familiarity with Laravel queues, Eloquent relationships, and Pest.

## The Changes at a Glance {#the-changes-at-a-glance}

The full changelog lists more than fifty entries, but many of them are test refactors, CI workflow updates, and docblock adjustments. The table below keeps only the changes that alter how application code behaves, grouped by the area they touch.

| Change                                                | Area              | Pull Request   |
| ----------------------------------------------------- | ----------------- | -------------- |
| `JobProcessed` carries a `duration` in milliseconds   | Queue             | #61672         |
| Interruptible jobs receive `SIGALRM` before a timeout | Queue             | #61651         |
| Worker crashes can count toward `maxExceptions`       | Queue             | #61737         |
| `queue:flush --queue=`                                | Queue             | #61630         |
| Enums in `Queue::isPaused()` and environment checks   | Queue, Foundation | #61725, #61730 |
| Named S3 credential providers (`ecs`, `instance`)     | Filesystem        | #61676         |
| `Schema::getColumn()`                                 | Database          | #61759         |
| Morph map enforced when reading polymorphic types     | Eloquent          | #61711         |
| `whereMorphedTo()` respects the relation's owner key  | Eloquent          | #61712         |
| `DatabaseLock` rethrows deadlocks inside transactions | Cache             | #61708         |
| `assertDatabaseCount()` accepts an array              | Testing           | #61727         |
| Multipart retries keep attached stream contents       | HTTP Client       | #61728         |

The sections that follow go through these in the same order, starting with the queue.

## Measuring Job Runtime With JobProcessed::$duration {#measuring-job-runtime-with-jobprocessed-duration}

The `JobProcessed` event has always told listeners which job finished and on which connection. It never said how long the job took, so any runtime metric had to be assembled from two events. In 13.34.0, the worker records the time right before it fires the job and passes the elapsed time to the event as a new `duration` property.

Here is a listener registered in `app/Providers/AppServiceProvider.php`:

```php
<?php

namespace App\Providers;

use Illuminate\Queue\Events\JobProcessed;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Event::listen(function (JobProcessed $event) {
            Log::info("{$event->job->resolveName()} took {$event->duration}ms");
        });
    }
}
```

The closure type hints `JobProcessed`, so Laravel registers it for that event automatically. `$event->job->resolveName()` returns the class name of the queued job, and `$event->duration` is a float in milliseconds, rounded to two decimal places by the worker.

To see it working, a small job that simulates some work is enough:

```php
<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class GenerateReport implements ShouldQueue
{
    use Queueable;

    public function handle(): void
    {
        // Simulate a report that takes a little while to build.
        usleep(350_000);
    }
}
```

The `usleep()` call pauses for 350 milliseconds, which gives the duration something measurable. After dispatching the job with `php artisan tinker --execute="App\Jobs\GenerateReport::dispatch();"`, process it with a worker:

```bash
php artisan queue:work --once
```

```
 2026-09-29 14:26:27 App\Jobs\GenerateReport .. RUNNING
 2026-09-29 14:26:27 App\Jobs\GenerateReport .. 373.68ms DONE
```

The worker's own console output already showed a runtime before this release, but only on screen. The new property puts the same kind of number into application code. The log file now contains:

```
[2026-09-29 14:26:27] local.INFO: App\Jobs\GenerateReport took 360.46ms  
```

The two numbers differ slightly because the console timer wraps more of the worker's lifecycle, while `duration` measures only `$job->fire()`. With the value available in a listener, it can be sent to a metrics backend, compared against a threshold for alerting, or stored per job class to spot regressions after a deploy. Note that the property is nullable: events raised outside the worker, such as those from the `sync` driver, do not carry a duration.

## Reacting Before a Job Times Out {#reacting-before-a-job-times-out}

Laravel already supported the `Illuminate\Contracts\Queue\Interruptible` contract. A job implementing it gets its `interrupted(int $signal)` method called when the worker receives a signal like `SIGTERM` during a deploy. The one case left out was the timeout itself: when a job exceeded `$timeout`, the worker's `SIGALRM` handler marked the job as failed and killed the process without telling the job anything.

Starting with 13.34.0, the timeout handler forwards `SIGALRM` to the running job first. That creates a small window to save progress before the process exits. The following job imports ten chunks of data, one per second, but is only allowed three seconds:

```php
<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\Interruptible;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class ImportProducts implements ShouldQueue, Interruptible
{
    use Queueable;

    public $timeout = 3;

    public $tries = 1;

    protected int $chunk = 0;

    public function handle(): void
    {
        // Resume from the last saved checkpoint, if any.
        $this->chunk = Cache::get('import-products:chunk', 0);

        while ($this->chunk < 10) {
            sleep(1); // Simulate importing one chunk of rows.
            $this->chunk++;
        }

        Cache::forget('import-products:chunk');
    }

    public function interrupted(int $signal): void
    {
        Cache::forever('import-products:chunk', $this->chunk);

        Log::warning("ImportProducts interrupted by signal {$signal} after chunk {$this->chunk}");
    }
}
```

The `handle()` method reads a checkpoint from the cache and continues from there, so a retry does not have to start over. The `interrupted()` method is the new hook for timeouts: it writes the current chunk number to the cache and logs which signal arrived. Because the job keeps its progress in a property, `interrupted()` can read the latest value even though it runs from inside the signal handler.

Timeouts are only enforced when the worker runs as a daemon, so `--once` will not trigger them. Use `--stop-when-empty` instead:

```bash
php artisan queue:work --stop-when-empty
```

```
 2026-09-29 14:26:54 App\Jobs\ImportProducts .. RUNNING
 2026-09-29 14:26:57 App\Jobs\ImportProducts .. 3s FAIL
 2026-09-29 14:26:57 Worker STOPPED Job timed out
```

The job still fails and the worker still stops, which is expected. The difference shows up in the log and in the cache:

```
[2026-09-29 14:26:57] local.WARNING: ImportProducts interrupted by signal 14 after chunk 2  
```

```bash
php artisan tinker --execute="dump(Cache::get('import-products:chunk'));"
```

```
2 // vendor/psy/psysh/src/ExecutionClosure.php(41) : eval()'d code:1
```

Signal `14` is `SIGALRM`. The job completed two chunks before the timeout and saved that number, so the next attempt resumes from chunk 2 instead of chunk 0. This pattern fits AI inference calls, video processing, large CSV imports, and report generation, where redoing finished work is expensive. Keep the `interrupted()` method short, since the worker kills the process right after it returns.

## Counting Worker Crashes Toward maxExceptions {#counting-worker-crashes-toward-maxexceptions}

`$maxExceptions` limits how many times a job may throw before it is marked as failed. It is often paired with `$tries = 0` and `retryUntil()` for jobs that use rate limiting middleware, since rate limiting releases count as attempts. The weak spot is that an exception has to be thrown for the counter to move. When the process dies from an out of memory error, a segfault, or a container being killed, no exception is ever recorded, and the job can retry indefinitely.

13.34.0 adds an opt-in fix. Mark the job with the new `CountCrashesAsExceptions` attribute:

```php
<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Queue\Attributes\CountCrashesAsExceptions;

#[CountCrashesAsExceptions]
class TranscodeVideo implements ShouldQueue
{
    use Queueable;

    public $tries = 0;

    public $maxExceptions = 3;

    public function retryUntil(): \DateTime
    {
        return now()->addHours(1);
    }

    public function handle(): void
    {
        // Memory hungry work that might crash the worker process.
    }
}
```

The attribute sets a `countCrashesAsExceptions` flag in the job payload. Setting `public $countCrashesAsExceptions = true;` on the class has the same effect for anyone who prefers properties over attributes.

When a flagged job starts, the worker writes a `job-processing:{uuid}` marker to the cache and clears it once the attempt finishes, whether it succeeded or threw. If the process crashes, the marker is left behind. The next time the job is picked up, the worker finds the stale marker, concludes that the previous attempt died, and counts it as one exception through the existing `maxExceptions` logic. After three crashes, this job is failed instead of looping.

The feature is opt-in because it costs two extra cache calls per attempt, and it requires a cache store shared by all workers.

## Flushing Failed Jobs for a Single Queue {#flushing-failed-jobs-for-a-single-queue}

Before this release, cleaning up failed jobs came down to two options: `queue:flush`, which deletes every failed job across every queue, or `queue:forget`, which removes one job ID at a time. Neither fits the common situation where one integration goes down and floods `failed_jobs` while the other queues have failures worth keeping.

The command now accepts a `--queue` option:

```bash
php artisan queue:flush --queue=sftp-sync
```

```

 INFO All failed jobs on the [sftp-sync] queue have been deleted successfully. 

```

Only failed jobs whose `queue` column matches `sftp-sync` are removed. The option combines with the existing `--hours` flag, so `php artisan queue:flush --queue=sftp-sync --hours=48` deletes failures from that queue that are older than two days. Running the command without options behaves as before:

```bash
php artisan queue:flush
```

```

 INFO All failed jobs deleted successfully. 

```

The option works with the database, file, and DynamoDB failed job providers. According to the pull request, the Laravel Cloud queue does not support `queue:flush` yet.

## Enums in Queue::isPaused() and Environment Checks {#enums-in-queue-ispaused-and-environment-checks}

Laravel has been accepting backed enums in more places with every release, and 13.34.0 closes two gaps. `Queue::pause()` and `Queue::resume()` already accepted enums, but `Queue::isPaused()` required `->value`. Environment checks were worse: `App::environment(Environment::Production)` threw a string conversion error, and `->environments(Environment::Production)` on a scheduled task silently prevented the task from ever running.

With these two enums in `app/Enums`:

```php
<?php

namespace App\Enums;

enum QueueName: string
{
    case Emails = 'emails';
    case Reports = 'reports';
}
```

```php
<?php

namespace App\Enums;

enum Environment: string
{
    case Local = 'local';
    case Testing = 'testing';
    case Staging = 'staging';
    case Production = 'production';
}
```

both of the following now work without `->value`:

```php
Queue::pause('database', QueueName::Reports);
Queue::isPaused('database', QueueName::Reports); // true

App::environment(Environment::Production); // false outside production

Schedule::command('reports:send')->daily()->environments(Environment::Production);
```

The framework passes the values through `enum_value()`, so plain strings and wildcard patterns keep working exactly as before. The `@env` Blade directive compiles down to `App::environment()`, which means `@env(Environment::Staging)` works as well. These enums are exercised in a Pest test later in the article.

## Keyless S3 Disks With Named Credential Providers {#keyless-s3-disks-with-named-credential-providers}

A typical S3 disk in `config/filesystems.php` reads a static access key and secret from `.env`. That works, but it puts long lived credentials on every server and makes rotation a manual task. On AWS, the better practice is to let the runtime supply short lived credentials through an ECS task role, EKS Pod Identity, or an EC2 instance profile.

SQS connections in Laravel already supported this through named credential providers, and 13.34.0 brings the same configuration to S3 disks. Here is the default disk before the change:

```php
's3' => [
    'driver' => 's3',
    'key' => env('AWS_ACCESS_KEY_ID'),
    'secret' => env('AWS_SECRET_ACCESS_KEY'),
    'region' => env('AWS_DEFAULT_REGION'),
    'bucket' => env('AWS_BUCKET'),
    'url' => env('AWS_URL'),
    'endpoint' => env('AWS_ENDPOINT'),
    'use_path_style_endpoint' => env('AWS_USE_PATH_STYLE_ENDPOINT', false),
    'throw' => false,
    'report' => false,
],
```

And here is a disk that relies on the container's IAM role instead:

```php
's3' => [
    'driver' => 's3',
    'credentials' => 'ecs',
    'region' => env('AWS_DEFAULT_REGION'),
    'bucket' => env('AWS_BUCKET'),
    'throw' => false,
    'report' => false,
],
```

The `credentials` key accepts `'ecs'` for ECS and EKS container credentials, or `'instance'` for an EC2 instance profile. Any other name throws an `InvalidArgumentException` with the message `Invalid credential provider [name].` To pass options to the AWS SDK provider, use the array form:

```php
'credentials' => [
    'provider' => 'ecs',
    'timeout' => 5,
],
```

Everything except `provider` is forwarded to the SDK's `CredentialProvider::ecsCredentials()` or `instanceProfile()`. The provider is resolved and memoized when the disk is created rather than in the config file, which keeps the configuration serializable for `php artisan config:cache`. Static keys, `false`, and callables still behave exactly as before. The same pull request also teaches Laravel Cloud to configure IAM backed S3 disks alongside the existing R2 disks.

## Inspecting a Single Column With Schema::getColumn() {#inspecting-a-single-column-with-schema-getcolumn}

`Schema::getColumns()` returns metadata for every column in a table. When only one column matters, the usual workaround has been to wrap the result in a collection and search it:

```php
$column = collect(Schema::getColumns('users'))->firstWhere('name', 'email');
```

13.34.0 adds a direct method for this:

```php
$column = Schema::getColumn('users', 'email');
```

Internally it calls `getColumns()` and returns the matching entry, or an empty array when the column or table does not exist. Running it against the default `users` table in Tinker shows the shape of the result:

```bash
php artisan tinker --execute="dump(Schema::getColumn('users', 'email')); dump(Schema::getColumn('users', 'missing'));"
```

```
array:9 [
  "name" => "email"
  "type_name" => "varchar"
  "type" => "varchar"
  "collation" => null
  "nullable" => false
  "default" => null
  "auto_increment" => false
  "comment" => null
  "generation" => null
] // vendor/psy/psysh/src/ExecutionClosure.php(41) : eval()'d code:1
[] // vendor/psy/psysh/src/ExecutionClosure.php(41) : eval()'d code:2
```

The keys match what `getColumns()` has always returned for each column, so existing code that reads `nullable`, `default`, or `type_name` works unchanged. The empty array for a missing column means the result can be checked with `empty()` or `=== []` rather than `null`. This is handy in admin tooling, data importers that map CSV headers to columns, and migration helpers that need to know whether a column is nullable before altering it.

## Stricter Polymorphic Relations {#stricter-polymorphic-relations}

Two separate fixes in this release make polymorphic relations more predictable. Neither needs code changes, but both can change behavior in applications that rely on them.

### Morph Map Enforcement on the Read Side

`Relation::enforceMorphMap()` registers aliases for polymorphic types and turns on `requireMorphMap()`. Until now, that requirement only applied to writes: saving a model without an alias threw `ClassMorphViolationException`. Reads were lenient. If a `commentable_type` column contained a value that was not in the map, Laravel treated it as a class name and instantiated it.

```php
use App\Models\Post;
use App\Models\Video;
use Illuminate\Database\Eloquent\Relations\Relation;

Relation::enforceMorphMap([
    'post' => Post::class,
    'video' => Video::class,
]);
```

With this configuration in 13.34.0, reading a relation whose stored type is not `post` or `video` throws `ClassMorphViolationException`, both for lazy loading through `morphTo()` and for eager loading. This closes a defense in depth gap where a tampered `*_type` value could resolve to an arbitrary class. Applications that do not call `enforceMorphMap()` or `requireMorphMap()` see no change, since an unmapped type still falls back to the raw class string. Applications that do enforce the map should check for legacy rows that still store fully qualified class names, because loading them will now throw.

### whereMorphedTo() Respects the Owner Key

`whereMorphedTo()` and `whereNotMorphedTo()` filter a query by the model on the other side of a `morphTo` relation. They previously compared against the related model's primary key even when the relation defined a different owner key. For a relation such as `morphTo(ownerKey: 'uuid')`, the generated query used the wrong column. The methods now read the owner key from the relation, so polymorphic relations keyed by `uuid`, `public_id`, or another custom column filter correctly.

## DatabaseLock No Longer Hides Deadlocks {#databaselock-no-longer-hides-deadlocks}

The `database` cache driver implements atomic locks by inserting a row into the `cache_locks` table. If the insert failed, `acquire()` caught the exception and tried an update instead. That is fine for a unique key collision, but not for a deadlock inside a transaction. MySQL rolls the whole transaction back when it detects a deadlock, while Laravel kept assuming the transaction was still open. The application then continued with its earlier writes silently gone and later writes committing on their own.

In 13.34.0, a concurrency error raised while the connection is inside a transaction is rethrown. That lets `DB::transaction()` roll back and retry with its `attempts` argument, the same way it handles any other deadlock. Code running outside a transaction behaves as before.

## assertDatabaseCount() Accepts an Array {#assertdatabasecount-accepts-an-array}

`assertDatabaseHas()` and `assertDatabaseMissing()` already accept arrays, but `assertDatabaseCount()` took one table per call. Tests that seed several tables tended to end with a stack of nearly identical assertions. The method now accepts an array of table and count pairs, and model class names work as keys too.

The test file below exercises this change together with `Schema::getColumn()` and the enum support from earlier. Create `tests/Feature/ReleaseFeaturesTest.php`:

```php
<?php

use App\Enums\Environment;
use App\Enums\QueueName;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Schema;

uses(RefreshDatabase::class);

test('assertDatabaseCount accepts several tables at once', function () {
    User::factory()->count(3)->create();

    $this->assertDatabaseCount([
        'users' => 3,
        'failed_jobs' => 0,
    ]);
});

test('Schema::getColumn returns metadata for a single column', function () {
    $column = Schema::getColumn('users', 'email');

    expect($column['name'])->toBe('email')
        ->and($column['nullable'])->toBeFalse()
        ->and(Schema::getColumn('users', 'nickname'))->toBe([]);
});

test('Queue::isPaused accepts a backed enum', function () {
    Queue::pause('database', QueueName::Reports);

    expect(Queue::isPaused('database', QueueName::Reports))->toBeTrue()
        ->and(Queue::isPaused('database', QueueName::Emails))->toBeFalse();
});

test('App::environment accepts a backed enum', function () {
    expect(App::environment(Environment::Testing))->toBeTrue()
        ->and(App::environment(Environment::Production))->toBeFalse();
});
```

The first test creates three users and checks two tables in a single `assertDatabaseCount()` call. The second confirms that `getColumn()` returns the `email` metadata and an empty array for a column that does not exist. The last two pass enums straight into `Queue::isPaused()` and `App::environment()`, which would have failed before this release. The environment test uses `Environment::Testing` because Pest runs with `APP_ENV=testing`.

```bash
php artisan test --filter=ReleaseFeaturesTest
```

```

   PASS  Tests\Feature\ReleaseFeaturesTest
  ✓ assertDatabaseCount accepts several tables at once                   0.16s  
  ✓ Schema::getColumn returns metadata for a single column               0.01s  
  ✓ Queue::isPaused accepts a backed enum                                0.02s  
  ✓ App::environment accepts a backed enum                               0.01s  

  Tests:    4 passed (9 assertions)
  Duration: 0.29s
```

All four tests pass on 13.34.0.

## Multipart Retries Keep Their Stream Contents {#multipart-retries-keep-their-stream-contents}

The HTTP client allows attaching a file as a stream resource and retrying the request on connection failures. Combining the two was broken:

```php
Http::retry(3, 100)
    ->attach('file', fopen($path, 'rb'), 'report.pdf')
    ->post('https://api.example.com/upload');
```

Guzzle builds a new multipart body for every attempt, and each body wrapped the same PHP resource. The first attempt read the resource to the end, so the second attempt sent the part with no file contents. By the third attempt the resource had been closed by a garbage collected wrapper, and the request threw `Invalid resource type: resource (closed)` instead of a `ConnectionException`. The worst case was the silent one: with a low retry count, a retry could succeed and upload an empty file.

13.34.0 wraps attached resources in a PSR-7 stream once and rewinds it before each attempt. Every retry now sends the full file, and code that uploads to S3 compatible storage, media processing APIs, or document services through `attach()` needs no changes to benefit.

## Other Fixes Worth a Mention {#other-fixes-worth-a-mention}

Beyond the headline changes, the release carries a batch of smaller fixes. Most of them correct edge cases that are rare but painful when they show up in production.

- **Redis throttle:** the Redis rate limiter no longer returns a timestamp as the number of remaining attempts.
- **Memcached locks:** locks longer than 30 days no longer expire immediately, since Memcached treats large TTLs as Unix timestamps.
- **`Number::parseInt()`:** values above the 32 bit range no longer return `false`.
- **`Number::format()`, `percentage()`, `currency()`:** small negative values no longer render as `-0`.
- **`trans_choice()`:** negative numbers now pick the correct plural form.
- **`sortBy()` with multiple columns and `SORT_NUMERIC`:** fractional values are no longer truncated.
- **`Collection::mode()`:** no longer returns values that are not in the data when nulls are present.
- **`shift($count)`:** returns an empty collection when called on an empty collection.
- **`LazyCollection::combine()`:** throws `ValueError` when the key and value lengths do not match, and `whereBetween()` accepts `LazyCollection` values.
- **`wherePivotBetween()`:** the constraint is no longer ignored by `sync()`, `detach()`, and `updateExistingPivot()`.
- **`whereNot()` with array conditions:** no longer applies a double negation.
- **`findOrFail()` with an array of enum IDs:** now resolves the models correctly.
- **`through()` on `MorphMany`:** no longer returns a `HasOneThrough` relation.
- **`increment()` and `decrement()`:** refreshed attributes are synced to the original state, and `replicate()` excludes them.
- **Memoized tagged cache:** `many()` no longer returns `null` for numeric keys.
- **`@elsePushIf`:** works with complex conditions.
- **`queue:restart`:** now shows an error when the worker cannot be restarted.
- **Exception reports:** file details now include the MIME type.

Some of these change return values that existing code may accidentally depend on, such as `Number::parseInt()` or `trans_choice()` with negatives. A quick run of the test suite after upgrading is enough to catch them.

## Getting the Update {#getting-the-update}

13.34.0 is a minor release within the Laravel 13 line, so there are no upgrade steps beyond updating the package. From the root of an existing project:

```bash
composer update laravel/framework
```

Then confirm the installed version:

```bash
php artisan --version
```

```
Laravel Framework 13.34.0
```

New projects created with `laravel new` pick up the release automatically. If the application uses `Relation::enforceMorphMap()`, check the `*_type` columns for unmapped legacy values before deploying, since those rows will now throw when loaded.

## Conclusion {#conclusion}

Laravel 13.34.0 is mostly about making background work easier to observe and harder to lose. Job runtime is now one property away, long jobs get a warning before a timeout ends them, and crashes that never throw an exception can finally stop an endless retry loop. Around that, the release trims configuration and boilerplate with keyless S3 disks, `Schema::getColumn()`, and array counts in tests, while tightening several Eloquent and cache edge cases.

- **`JobProcessed::$duration`.** The worker now measures each job and passes the runtime in milliseconds to the event, so metrics need a single listener instead of two events and a timestamp store.
- **Timeout notifications.** Jobs implementing `Interruptible` receive `SIGALRM` before a timeout kills the worker, which gives them a chance to save a checkpoint and resume later.
- **`CountCrashesAsExceptions`.** An opt-in attribute that counts out of memory kills and segfaults toward `maxExceptions`, using a cache marker to detect attempts that never finished.
- **`queue:flush --queue=`.** Failed jobs can be cleared for one queue at a time, optionally combined with `--hours`, without touching failures from other queues.
- **Named S3 credential providers.** Setting `'credentials' => 'ecs'` or `'instance'` lets an S3 disk use IAM roles instead of static keys, and the config stays cacheable.
- **`Schema::getColumn()`.** Returns the metadata of a single column, or an empty array when it does not exist, replacing the `collect()->firstWhere()` workaround.
- **Stricter polymorphic reads.** With an enforced morph map, unmapped `*_type` values now throw on read, and `whereMorphedTo()` respects custom owner keys.
- **Safer internals.** `DatabaseLock` rethrows deadlocks inside transactions, and multipart HTTP retries resend the full file instead of an empty part.
