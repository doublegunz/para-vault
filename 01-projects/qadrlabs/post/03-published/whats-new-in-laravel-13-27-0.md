# What's New in Laravel 13.27.0: refreshForUpdate, MariaDB Vector Search, and More

Laravel ships a patch release almost every week, and the release notes for each one are a wall of pull request titles written by contributors for contributors. You open the page, scroll a list of forty entries mixing test refactors with genuine API additions, decide nothing looks urgent, and close the tab. Three months later you write fifteen lines of pessimistic locking code by hand and only discover afterwards that a single method has been sitting in the framework the whole time.

The cost of skimming is not that you miss a headline feature. Headline features get blog posts, conference talks, and documentation updates. The cost is that you miss the small ergonomic additions, the ones that quietly replace a workaround you have been copying between projects for years. Those additions never get announced anywhere, because from the framework's point of view they are one-line changelog entries.

Laravel 13.27.0 was released on 25 August 2026, and it is a good example of that pattern. Filter out the internal test and CI work and roughly six changes are left that actually touch application code: a new Eloquent locking method, vector similarity queries on MariaDB, cheaper queue metrics, byte-exact string comparison in the query builder, a `Cloud` facade, and a fix that makes read-through disks usable for file moves. This article walks through each of them, explains what problem it solves, and shows what the code looks like before and after.

## Overview {#overview}

This is an informational release roundup rather than a build-along tutorial. There is no project to scaffold and nothing to run at the end. What you get instead is a clear picture of what changed in 13.27.0, why each change exists, and where in your own codebase it applies. The code samples are written so you can lift them into an application you already have, and each one is paired with an explanation of what the framework does with it internally.

### What This Article Covers

- The six changes in Laravel 13.27.0 that affect application code rather than framework internals.
- The problem each change solves, with the workaround it replaces shown next to the new API.
- The constraints attached to each feature, including which database drivers and queue drivers support it.
- A shorter tour of the smaller improvements in the same release.

### What You'll Learn

- How `refreshForUpdate()` locks an already-resolved Eloquent model without a second manual query.
- How Laravel's vector query API now compiles for MariaDB, and how that differs from the PostgreSQL path.
- Why `totalPendingSize()` and its siblings are cheaper than summing per-queue counts.
- What `whereBinary()` compiles to, and why it only works on MySQL and MariaDB.
- What the new `Cloud` facade reports, and the one method on it that throws when misconfigured.
- Which read-through filesystem operations were broken before 13.27.0 and how they behave now.

### What You'll Need

- PHP 8.3 or newer, which is the minimum for Laravel 13.
- A Laravel 13.27.0 application, or any later 13.x release, since every feature here carries forward.
- MariaDB 11.7 or newer if you want to use the vector query section.
- Working familiarity with Eloquent, the query builder, and Laravel queues.

## The Six Changes at a Glance {#the-six-changes-at-a-glance}

Before going through each change in detail, it helps to see them side by side. The table below summarizes what each addition does and where it applies, so you can jump straight to the sections relevant to your stack. Two of these are database-driver specific and one only matters if you deploy to Laravel Cloud, so not every entry will apply to every project.

| Change | What it gives you | Where it applies |
| --- | --- | --- |
| `Model::refreshForUpdate()` | Refreshes an existing model instance under a `FOR UPDATE` lock | Any driver supporting pessimistic locking |
| MariaDB vector distance | Vector similarity queries against native `VECTOR` columns | MariaDB 11.7+ |
| Queue `totalXSize()` methods | Job counts across every queue in one call | Database, Redis, Beanstalkd, SQS, Sync |
| `whereBinary()` family | Byte-exact comparison without `whereRaw()` | MySQL and MariaDB |
| `Cloud` facade | One API for Laravel Cloud environment checks | Laravel Cloud deployments |
| Read-through `move()` and `copy()` | File operations on paths that exist only on the fallback disk | Read-through filesystem disks |

## Pessimistic Locking Without a Second Query {#pessimistic-locking-without-a-second-query}

This is the most broadly useful change in the release, because the problem it solves appears in almost every application that handles inventory, balances, or quotas. The awkwardness comes from a timing mismatch: Laravel resolves your model early, usually through route model binding, but you do not need the database lock until later, once a transaction has started. By then you are holding a model instance that was read without a lock, and its attributes may already be stale.

The standard workaround is to throw that instance away and query the same row again, this time with a lock attached.

```php
DB::transaction(function () use ($product) {
    // The $product resolved by route model binding was read without a lock,
    // so it must be discarded and fetched again inside the transaction.
    $product = Product::query()
        ->lockForUpdate()
        ->findOrFail($product->getKey());

    if ($product->stock === 0) {
        throw new RuntimeException('Out of stock.');
    }

    $product->decrement('stock');
});
```

This works, but notice how much ceremony it takes to express a simple intent. You reach for the primary key of a model you already have, run a query that returns a row you already fetched once, and then shadow the original variable so the rest of the closure uses the locked copy. Forgetting that last part is a real bug: if you assign to a differently named variable, the checks below silently run against the unlocked instance.

Laravel 13.27.0 collapses all of that into one method call.

```php
DB::transaction(function () use ($product) {
    // Re-reads the same row with a "for update" lock and updates
    // the attributes on the instance already in memory.
    $product->refreshForUpdate();

    if ($product->stock === 0) {
        throw new RuntimeException('Out of stock.');
    }

    $product->decrement('stock');
});
```

`refreshForUpdate()` behaves exactly like the familiar `refresh()`, with one difference: the query it uses to reload the model has `lockForUpdate()` applied. Internally both methods delegate to the same `refreshUsingQuery()` helper, and the new one simply hands it a locked query builder. The result is that the same object you were already holding gets both fresh attribute values and a row lock that lasts until the transaction commits or rolls back.

There is one behavior worth knowing before you rely on it. Like `refresh()`, the method returns early if the model does not exist in the database yet, meaning an unsaved model returns `$this` untouched and no lock is acquired. That is the correct behavior, but it also means the method is not a guard against calling it on the wrong object. Calling it outside a transaction is likewise legal and mostly pointless, since the lock is released as soon as the implicit transaction around the query ends.

The workloads that benefit most are the ones where two requests racing on the same row produce a wrong number rather than an error: stock inventory, wallet balances, ticket availability, coupon quotas, seat booking, and order processing. In all of those, the read and the write must be separated by a lock or the check becomes advisory.

## Vector Similarity Queries on MariaDB {#vector-similarity-queries-on-mariadb}

Laravel already had a vector query API before this release, covering `selectVectorDistance()`, `whereVectorSimilarTo()`, `whereVectorDistanceLessThan()`, and `orderByVectorDistance()`. In practice that API had one home, which was PostgreSQL with the pgvector extension installed. If your application ran on MariaDB, calling any of those methods threw a runtime exception telling you the connection did not support vector queries, and your only option was raw SQL.

Laravel 13.27.0 adds native MariaDB support to the same API. The methods do not change at all; what changes is the SQL each grammar compiles them into. On PostgreSQL, a vector distance expression compiles to the pgvector cosine distance operator.

```sql
("embedding" <=> ?)
```

On MariaDB, the same builder call now compiles to MariaDB's own native vector functions instead.

```sql
vec_distance_cosine(`embedding`, vec_fromtext(?))
```

The important part is that this happens below your application code. The same Eloquent query works on either driver, and the grammar decides how to express it.

```php
// Identical code on PostgreSQL and MariaDB; only the compiled SQL differs.
$results = Document::query()
    ->orderByVectorDistance('embedding', $embedding)
    ->limit(10)
    ->get();
```

Here `$embedding` is an array of floats, a `Collection` of floats, or anything `Arrayable`. Laravel JSON encodes it and binds it as a parameter, which is why the MariaDB expression wraps the placeholder in `vec_fromtext()`: MariaDB parses the JSON array text back into a vector value at query time.

Schema support comes from the `vector()` column type on the blueprint, with the dimension count passed as the second argument.

```php
Schema::create('documents', function (Blueprint $table) {
    $table->id();
    $table->text('content');
    // Compiles to a native VECTOR(1536) column on MariaDB.
    $table->vector('embedding', 1536);
    $table->timestamps();
});
```

For anything beyond a small table you also want an index, and `vectorIndex()` handles the driver differences for you. On PostgreSQL it produces an HNSW index using the `vector_cosine_ops` operator class; on MariaDB it produces a native `VECTOR INDEX` with `M=6 DISTANCE=cosine` options attached.

```php
Schema::table('documents', function (Blueprint $table) {
    $table->vectorIndex('embedding');
});
```

If you prefer a similarity threshold to a plain nearest-neighbor ordering, `whereVectorSimilarTo()` expresses that directly. It takes a minimum similarity between 0.0 and 1.0, converts it internally to a maximum distance of `1 - $minSimilarity`, and orders the results by distance unless you pass `false` as the fourth argument.

```php
$related = Document::query()
    ->whereVectorSimilarTo('embedding', $embedding, minSimilarity: 0.75)
    ->limit(5)
    ->get();
```

Two caveats matter here. The first is the version requirement: this depends on MariaDB's native `VECTOR` type, which arrived in MariaDB 11.7, so older MariaDB installations and plain MySQL still throw when these methods are called. The framework's own error message is explicit that vector distance queries are supported by PostgreSQL and MariaDB only. The second is that Laravel gives you the query layer, not the embeddings. Generating the vectors is still your application's job, whether that means calling an embedding API or running a local model.

## Counting Jobs Across Every Queue {#counting-jobs-across-every-queue}

Queue dashboards, health checks, and autoscaling rules all need the same number: how many jobs are waiting right now. Applications that split work across several named queues had to assemble that number themselves, one call per queue.

```php
$total = Queue::reservedSize('queue1')
    + Queue::reservedSize('queue2')
    + Queue::reservedSize('queue3');
```

That is tedious to write, but the real problem is that it is fragile. The list of queue names is duplicated between your worker configuration and your metrics code, so adding a fourth queue means remembering to update a dashboard that nobody looks at until it is already wrong.

Laravel 13.27.0 adds three methods that count across every queue at once.

```php
$metrics = [
    'pending' => Queue::totalPendingSize(),
    'reserved' => Queue::totalReservedSize(),
    'delayed' => Queue::totalDelayedSize(),
];
```

The shorter syntax is the visible benefit; the design intent is the more interesting one. These methods are deliberately lightweight counterparts to the existing inspection API. Methods such as `pendingJobs()` retrieve job records and decode each payload into an `InspectedJob` instance, which is exactly what you want when you are showing job details in an admin panel and exactly what you do not want when you only need a number. On the database driver, for example, `totalPendingSize()` issues a single `count()` query filtered by `reserved_at` and `available_at`, with no payload decoding at any point. Across ten queues holding half a million jobs, that is the difference between one aggregate query and a great deal of wasted work.

The three methods are implemented across the queue drivers, including the database, Redis, Beanstalkd, SQS, and sync connections, so the same metrics code works regardless of which driver an environment uses. The natural places to use them are queue monitoring endpoints, admin dashboards, autoscaling signals, worker metrics, health checks, and capacity planning reports.

## Byte-Exact Comparisons With whereBinary() {#byte-exact-comparisons-with-wherebinary}

MySQL and MariaDB default to case-insensitive collations, which is convenient for names and email addresses and dangerous for everything else. Under a collation like `utf8mb4_unicode_ci`, the strings `Laravel`, `laravel`, and `LARAVEL` are all equal as far as a `WHERE` clause is concerned. When the column holds an API token, an external identifier, or a hash, that is not a convenience; it is a correctness bug waiting for the right pair of values.

The traditional fix was to drop into raw SQL and apply the `BINARY` operator by hand.

```php
DB::table('queues')
    ->whereRaw('name = BINARY ?', [$queueName])
    ->first();
```

It works, but it costs you everything the query builder normally provides. The column name is no longer wrapped by the grammar, the fragment is MySQL-specific in a way that is invisible until it runs elsewhere, and the clause cannot be composed with the builder's `or` and `not` variants without writing more raw strings.

Laravel 13.27.0 adds a first-class method for it.

```php
DB::table('queues')
    ->whereBinary('name', $queueName)
    ->first();
```

The MySQL grammar compiles this to a basic where clause whose operator is `= binary`, so the column still goes through normal identifier wrapping and the value is still a bound parameter. Four variants ship together, covering the usual combinations.

```php
$query->whereBinary('token', $token);        // = binary ?
$query->orWhereBinary('token', $token);      // or ... = binary ?
$query->whereNotBinary('token', $token);     // != binary ?
$query->orWhereNotBinary('token', $token);   // or ... != binary ?
```

Be aware that this is a MySQL and MariaDB feature, not a portable one. The base query grammar implements `whereBinary()` by throwing a `RuntimeException` stating that the database engine does not support binary comparison operations, and only the MySQL grammar overrides it. MariaDB inherits the working implementation, while PostgreSQL, SQLite, and SQL Server all hit the exception. In practice that is less limiting than it sounds, since PostgreSQL and SQLite compare strings case-sensitively by default and do not need the method. It does mean that a test suite running on SQLite will fail on a query that works fine against MySQL in production, which is worth knowing before you reach for it.

Good candidates for `whereBinary()` are columns holding tokens, identifiers, external IDs, case-sensitive codes, hash-like values, and queue identifiers. Anything where two values differing only in case are genuinely different values.

## The New Cloud Facade {#the-new-cloud-facade}

The remaining two changes say more about where the framework is heading than about any single line of code. The first is a new facade for Laravel Cloud, which gives applications one place to ask about their relationship with the hosting platform instead of assembling that answer from driver checks, environment variables, and hand-rolled feature flags.

```php
use Illuminate\Support\Facades\Cloud;

if (Cloud::hosted()) {
    // The application is currently running on Laravel Cloud.
}
```

`Cloud::hosted()` wraps the existing `laravel_cloud()` helper and returns a boolean, which makes it a tidy way to gate behavior that only makes sense on the platform. A second method reports whether the application is configured to use the platform's managed queues, by checking whether the `cloud` queue connection uses the `cloud` driver.

```php
if (Cloud::usesManagedQueues()) {
    // The "cloud" queue connection is configured with the cloud driver.
}
```

The third method returns the managed queue connection itself, and this is the one that needs care. `Cloud::queue()` throws a `RuntimeException` when managed queues are not configured, so it is not safe to call unconditionally. Pair it with the check above.

```php
$reserved = Cloud::usesManagedQueues()
    ? Cloud::queue()->totalReservedSize()
    : Queue::totalReservedSize();
```

Notice that this example also uses one of the new queue counting methods from the previous section. The managed queue object forwards those calls to the underlying queue implementation, so the same metrics API works whether the queue is managed by the platform or by your own infrastructure.

The facade is macroable, and the pull request that introduced it described it as a starting point rather than a finished API, so it is reasonable to expect more Cloud resources to appear behind it in later releases. For now, the value is that platform detection has a canonical location instead of being reinvented per project.

## Read-Through Disks Can Now Move and Copy From the Fallback {#read-through-disks-can-now-move-and-copy-from-the-fallback}

The read-through filesystem driver arrived one release earlier, in 13.26.0, as a way to run a storage migration without downtime. It stacks two ordinary disks behind one logical disk: a primary that receives all writes, and a fallback that is consulted only when the primary reports a path as missing. If you have not met the driver before, the full mechanics are covered in [Laravel 13 Read-Through Filesystem Driver Explained](https://qadrlabs.com/post/laravel-13-read-through-filesystem-driver-explained-migrate-object-storage-without-downtime).

The gap in that first version was that reads understood the two-disk arrangement and file operations did not. Reading a path that lived only on the fallback worked exactly as intended.

```php
// Works in 13.26: the read falls through to the fallback disk.
Storage::disk('read-through')->get('source.txt');
```

Moving or copying that same path did not, because both operations ran against the primary disk alone. With the file present only on the fallback, the primary saw a missing source and the operation failed. The workaround was to force a read first so that promotion would copy the object into the primary, then perform the move against a path that now existed there.

In 13.27.0 both operations understand the fallback.

```php
Storage::disk('read-through')
    ->copy('source.txt', 'archive/source.txt');

Storage::disk('read-through')
    ->move('source.txt', 'archive/source.txt');
```

When the source exists only on the fallback, the adapter now streams it from the fallback directly into the destination path on the primary. `copy()` stops there, leaving the fallback source in place, which means the original path can still be promoted later by an ordinary read. `move()` goes one step further and deletes the fallback source once the primary write succeeds, so a moved path leaves nothing behind that a later read could resurrect.

The practical effect is that gradual storage migrations, the legacy S3 bucket to Cloudflare R2 kind, no longer have a category of operation that silently fails on files that have not been migrated yet. Any code path that reorganizes files, such as archiving old uploads or renaming objects during a cleanup job, now behaves the same whether the file has been promoted yet or not.

## Other Changes Worth a Mention {#other-changes-worth-a-mention}

Beyond the six features above, the release includes a set of smaller improvements that are unlikely to change how you design anything but are pleasant to know about. Most are refinements to APIs that already existed.

`orWhereKey()` and `orWhereKeyNot()` return to the Eloquent builder with an implementation that no longer breaks custom builder subclasses. Both now wrap their condition in a nested closure, so a subclass that overrides `whereKey()` keeps its behavior when the `or` variant is used.

The process fake gained `stop()` and `ensureNotTimedOut()`, closing gaps where tests that exercised long-running or cancellable processes could not fully use `Process::fake()`.

PostgreSQL connections accept keepalive DSN options. Setting `keepalives`, `keepalives_idle`, `keepalives_interval`, or `keepalives_count` in a connection's configuration appends them to the DSN, which helps with connections dropped by aggressive network middleboxes.

SQS can share cached AWS credentials across processes. When no explicit key and secret are configured, the connector can memoize resolved credentials through the cache, so many workers on the same host stop each hitting the credential provider independently.

Redis `mget()` and `hmget()` handle a `false` return safely. Both now convert a failed command into an array of nulls matching the number of keys requested, rather than returning `false` into code that expects an array. Individual missing values are normalized to null as well.

The release also carries hardening in validation and request input handling, plus the usual test and CI maintenance that makes up most of the raw changelog.

## Getting the Update {#getting-the-update}

Because 13.27.0 is a patch release within the 13.x line, upgrading requires no code changes and no configuration changes. A standard dependency update is enough.

```bash
composer update laravel/framework
```

The default `^13.0` constraint in a Laravel 13 application's `composer.json` already allows it, so the command pulls in 13.27.0 or whatever later 13.x release is current. Every feature described here is additive, which means nothing in your existing code changes behavior as a result of the upgrade.

## Conclusion {#conclusion}

Laravel 13.27.0 is a patch release with a better than usual ratio of useful additions to internal maintenance. Nothing here forces a rewrite, but several of these changes replace a workaround you have probably written more than once. Here is what to take away.

- **`refreshForUpdate()` removes the re-query dance.** When a model was resolved before your transaction started, one method call now gives it both fresh attributes and a `FOR UPDATE` lock, without you having to fetch the row a second time and shadow the original variable.
- **Vector search is no longer PostgreSQL only.** The same `orderByVectorDistance()` and `whereVectorSimilarTo()` calls now compile to MariaDB's native `vec_distance_cosine()` on MariaDB 11.7 and newer, so semantic search does not automatically mean adding pgvector to your stack.
- **Queue totals are a single cheap call.** `totalPendingSize()`, `totalReservedSize()`, and `totalDelayedSize()` count across every queue without decoding job payloads, which makes them the right tool for dashboards, health checks, and autoscaling signals.
- **`whereBinary()` replaces raw SQL for case-sensitive matching.** Byte-exact comparison on MySQL and MariaDB no longer costs you identifier wrapping or composability, though the method throws on PostgreSQL, SQLite, and SQL Server, so watch out for test suites running on a different driver than production.
- **The `Cloud` facade centralizes platform checks.** `hosted()` and `usesManagedQueues()` are safe to call anywhere, while `queue()` throws unless managed queues are configured, so guard it with the check rather than calling it directly.
- **Read-through disks finally handle move and copy.** Files that exist only on the fallback disk can now be moved or copied straight into the primary, which removes the last common operation that failed mid-migration.
