# Laravel 13 Read-Through Filesystem Driver Explained: Migrate Object Storage Without Downtime

Moving an application from one object store to another looks simple on a whiteboard and turns awkward the moment real traffic is involved. The cutover and the object transfer happen on two different timelines. New uploads can start landing in the destination bucket the second you flip a config value, but the millions of files already sitting in the source bucket do not move themselves. During that gap, which can last hours or weeks, every read your application performs has to work against two stores at once.

The usual answers are unpleasant. You can freeze writes, copy everything, and accept the downtime, which is a hard sell for a product people are actively using. Or you can teach the application to check both stores by hand, sprinkling `if (existsInDestination) { ... } else { ... }` through controllers, jobs, and mailers. That second option works, but it drags infrastructure migration logic into business code, and in practice those branches outlive the migration by years because nobody is confident enough to delete them.

Laravel 13 adds a read-through filesystem driver built for exactly this window. It stacks two ordinary disks behind a single logical disk: a primary that receives all writes, and a fallback that is consulted only when primary reports a path missing. Application code keeps calling `Storage::disk('assets')->get($path)` and never learns which store answered. Better still, a fallback hit can copy the object into primary during the same request, so ordinary traffic gradually migrates your hottest files for you. This article explains how that driver works, how each filesystem operation is routed, what promotion does and does not carry across, and how to finish a migration that read-through alone will never complete.

## Overview {#overview}

This is a conceptual explainer rather than a sequential build-along tutorial. There is no project to scaffold and no test suite to run. What you get instead is an accurate mental model of the driver plus configuration and API snippets you can lift directly into an application you already have. The examples use an Amazon S3 to Cloudflare R2 migration because it is the most common shape of this problem, but nothing in the driver is specific to those two providers.

### What You'll Build

- A mental model of the three concepts the driver runs on: primary, fallback, and promotion.
- A composite disk configuration for `config/filesystems.php` that puts two stores behind one disk name.
- A realistic migration plan that begins with a read-through disk and ends with the source bucket retired.

### What You'll Learn

- How the read path resolves a path and when it promotes an object from fallback into primary.
- Which filesystem operation goes to which disk, and why directory listings only ever show primary.
- The difference between best-effort promotion and strict promotion, and the config gotcha that makes strict mode silently do nothing.
- Why `readStream()` is the safer read for large objects and what `php://temp` costs you.
- What promotion does not carry over, including provider-specific object metadata.
- Why serving files through direct storage URLs means almost nothing gets promoted.
- How delete ordering prevents a deleted object from being resurrected by the next read.
- The operation and egress cost profile of a fallback read, with public rates as of August 2026.
- How to enumerate and copy the cold tail of objects that traffic never touches.

### What You'll Need

- A Laravel 13 application. The read-through driver is a Laravel 13 filesystem feature.
- PHP 8.3 or newer, which is the baseline for a Laravel 13 environment.
- Two configured Laravel disks, such as an existing S3 disk and a new R2 disk.
- Credentials for both stores. The permissions each one needs are covered in the delete section, and they are probably not what you would guess.
- Familiarity with the `Storage` facade and the `disks` array in `config/filesystems.php`.

## What the Read-Through Driver Actually Does {#what-the-read-through-driver-actually-does}

The read-through driver is a composite disk. It does not talk to a storage provider itself. It wraps two disks you have already configured and decides, per operation, which one should handle the call. Three terms carry the whole design, and it is worth pinning them down before any code appears.

**Primary** is the destination, the store you are migrating to. Every write goes here. **Fallback** is the source, the store you are migrating away from. It is consulted only for reads, and only when primary reports that the path does not exist. **Promotion** is the copy that happens when a read misses primary and hits fallback: Laravel writes the fallback contents into primary on the way back to the caller, so the next read for that path never touches fallback again.

The word "only" in that middle sentence is doing real work. Fallback is not a general-purpose retry. If primary throws while checking whether a path exists, or throws while reading it, that is a primary failure and it surfaces as one. The driver does not quietly ask fallback whether it has a copy. This matters because the alternative would mask an outage or a credential problem on your new store as a slow but successful response, and you would not discover the breakage until the fallback bucket was already gone.

## Configuring One Logical Disk Across Two Stores {#configuring-one-logical-disk-across-two-stores}

A read-through disk is defined like any other disk, in the `disks` array of `config/filesystems.php`. The difference is that its configuration points at two other disk names rather than at a bucket and a set of credentials.

```php
'disks' => [

    'r2' => [
        'driver' => 's3',
        // Destination credentials...
    ],

    'legacy-s3' => [
        'driver' => 's3',
        // Source credentials...
    ],

    'assets' => [
        'driver' => 'read-through',
        'primary' => 'r2',
        'fallback' => 'legacy-s3',
    ],

],
```

The `r2` and `legacy-s3` entries are completely ordinary S3 disks; nothing about them is aware of the migration. The `assets` disk is the composite one. Its `driver` is `read-through`, `primary` names the disk that receives writes, and `fallback` names the disk that answers misses. Both `primary` and `fallback` accept either a configured disk name, as shown here, or an inline configuration array if you would rather not expose the underlying disks as separately addressable names.

With the disks in place, point the application's default filesystem at the composite disk for the duration of the migration.

```dotenv
FILESYSTEM_DISK=assets
```

From this point on, `Storage::put()` and `Storage::get()` with no explicit disk argument route through `assets`. A newly uploaded post image is written to `r2`, while a request for a post image uploaded last year can still be served from `legacy-s3`. No calling code changed.

The driver is not limited to S3 and R2. It can compose any pair of Laravel disks whose adapters support the operations your application performs. The default promoting read path needs existence checks and reads on both disks plus writes to primary, and any adapter offering those will work. An S3 bucket can feed R2, a local disk can feed object storage, and R2 to R2, B2 to S3, or FTP to B2 are all valid combinations.

Scoped disks open up a variant worth knowing about: migrating between prefixes rather than between providers.

```php
'disks' => [

    'legacy-prefix' => [
        'driver' => 'scoped',
        'disk' => 'r2',
        'prefix' => 'legacy',
    ],

    'current-prefix' => [
        'driver' => 'scoped',
        'disk' => 'r2',
        'prefix' => 'current',
    ],

    'assets' => [
        'driver' => 'read-through',
        'primary' => 'current-prefix',
        'fallback' => 'legacy-prefix',
    ],

],
```

Here a read of `posts/19.jpg` checks `current/posts/19.jpg` first, falls back to `legacy/posts/19.jpg`, and writes the object under the `current` prefix when it promotes. The two prefixes can live in the same bucket, as above, or in entirely different stores. This is how you reorganize a bucket's key layout without a maintenance window.

## How the Read Path Works {#how-the-read-path-works}

Configuration is the easy half. The interesting behavior is what happens inside a single read, because that is where promotion, concurrency, and correctness meet. Consider one ordinary call.

```php
$contents = Storage::disk('assets')->get('posts/19.jpg');
```

Laravel follows this path:

```text
get("posts/19.jpg")
        │
        ▼
primary contains path?
        │
   ┌────┴────┐
  yes        no
   │          │
   ▼          ▼
 read     read fallback
primary         │
                ▼
        primary contains path?
                │
           ┌────┴────┐
          yes        no
           │          │
           ▼          ▼
        read       write primary
        primary         │
                        ▼
                  return contents
```

The happy path is the left branch and costs nothing extra: primary has the object, primary serves it. The right branch is where promotion lives, and it contains a detail that is easy to skim past. After reading from fallback, Laravel checks primary a second time. If another request populated primary while this request was busy downloading from fallback, Laravel throws away the fallback contents it just fetched and reads primary instead.

That second check exists for two reasons. It prevents duplicate promotions of the same object under concurrent traffic, and more importantly it protects an object that is already visible on primary from being overwritten by an older copy pulled out of the source bucket. Without it, two simultaneous requests for a recently updated file could race, and the loser could stamp stale bytes over fresh ones.

It is worth being honest about the limit of that protection. The final existence check and the write to primary are still two separate operations, so a concurrent write can land in the gap between them. Applications that use immutable or versioned object keys, where a given path's contents never change, sidestep the problem entirely. Applications that overwrite paths in place need to coordinate writes during the transition, or accept a narrow window where a promotion can clobber a concurrent update.

Once a path has been promoted successfully, later reads are served from primary. Any change made only to the fallback copy after that point is invisible to the application.

## Operation Routing in the Filesystem Contract {#operation-routing-in-the-filesystem-contract}

Reads are the operation the driver is named for, but a filesystem disk has to answer a much wider contract. The composite disk routes every operation deliberately, and the routing is not uniform: some operations check both disks, some go straight to primary, and one deliberately starts with fallback.

| Operation | Disk selection | Promotion behavior |
| --- | --- | --- |
| `get`, `read`, `readStream` | Primary, then fallback on a miss | Promotes fallback hits by default |
| `exists`, `size`, `mimeType`, `lastModified`, `visibility` | Primary, then fallback | Inspects the object in place |
| `put`, `writeStream`, directory creation, visibility changes | Primary | Writes directly |
| Directory listings | Primary | Reports destination state |
| `delete`, `deleteDirectory` | Fallback, then primary | Removes the path from both stores |
| `move` | Primary, then fallback | Moves on primary and deletes the fallback source |
| `copy` | Primary | Operates on destination state |
| Public and temporary download URLs | The disk currently containing the path | Resolves a URL in place |
| Temporary upload URLs | Primary | Uploads directly |

Three rows in that table have consequences big enough to plan around.

The first is directory listings. `files()`, `allFiles()`, and their directory equivalents report primary only. This is the correct behavior for a destination-state view, but it means you cannot use the composite disk to discover what still needs migrating. A bulk transfer has to enumerate the fallback disk directly and skip paths already present on primary.

The second is `move` and `copy`. Both operate on primary, which is a problem when the source path exists only on fallback. The fix is to read the path through the read-through disk first. With promotion enabled, that read copies the object into primary, and the move or copy can then proceed normally against a path that now exists there.

The third is the asymmetry between those two operations after the fact. `move` also deletes the fallback source once the primary move succeeds, so a moved path leaves nothing behind for a later read to promote back. If that fallback delete fails, the failure surfaces as an `UnableToMoveFile` error rather than being swallowed. `copy` leaves the fallback source in place, which is usually what you want, but it does mean the original path can still be promoted by a subsequent read.

## Promotion Failures: Best-Effort vs Strict {#promotion-failures-best-effort-vs-strict}

Promotion involves a network write to a second provider, so sooner or later it fails. The driver's default posture is best effort, and understanding that default is important because it is deliberately forgiving in a way that can hide problems.

In best-effort mode, if the fallback read succeeds and the primary write fails, Laravel returns the fallback contents anyway. The caller gets valid bytes and has no idea anything went wrong. The object stays on fallback, and the next read for that path simply tries the promotion again. The promotion exception is absorbed: no filesystem event is emitted and nothing is reported.

For most migrations that is the right trade. The user's request succeeded, the migration just made no forward progress on that one file. But some applications need a failed copy to be loud, and that requires two configuration keys, not one.

```php
'assets' => [
    'driver' => 'read-through',
    'primary' => 'r2',
    'fallback' => 'legacy-s3',
    'throw' => true,
    'throw_on_promotion_failure' => true,
],
```

`throw_on_promotion_failure` decides whether a failed copy should also fail the read. Its default is `false`, which produces the best-effort behavior described above. Set it to `true` and the driver treats a promotion write failure as an `UnableToReadFile` error.

The gotcha is the `throw` key sitting above it. That is the standard Laravel disk option controlling whether filesystem exceptions reach application code at all. If you set `throw_on_promotion_failure => true` but leave `throw` at its default of `false`, the driver raises `UnableToReadFile`, `get()` catches it, and your code receives `null`. You get neither the fallback contents nor an exception, which is strictly worse than either mode. Both keys have to be `true` together.

Choosing between the two comes down to what a silent non-promotion costs you. If you are running a background copy job over the whole bucket anyway, best effort is fine, because the cold-tail pass will catch whatever traffic failed to move. If your plan depends on traffic-driven promotion doing the bulk of the work and you need to know when the destination store starts rejecting writes, strict mode turns a silent stall into an error your monitoring can see.

## Streamed Reads and Temporary Storage {#streamed-reads-and-temporary-storage}

There is a memory characteristic of promotion that is easy to miss until a large file takes down a worker. `get()` loads the entire object into a PHP string before it can be promoted, so peak memory use scales directly with file size. A 500 MB video read through a read-through disk needs 500 MB of PHP memory, on top of everything else the request is holding.

`readStream()` is the safer read for anything large, because it never materializes the object as a single string.

```php
use Illuminate\Support\Facades\Storage;

public function download(string $path)
{
    $stream = Storage::disk('assets')->readStream($path);

    return response()->stream(function () use ($stream) {
        fpassthru($stream);
    }, 200, [
        'Content-Type' => Storage::disk('assets')->mimeType($path),
    ]);
}
```

On a fallback stream hit, Laravel copies the source stream into `php://temp`, writes that stream to primary, rewinds it, and hands it back to the caller. The controller above then passes it straight to the response. By default PHP keeps a `php://temp` stream in memory until it exceeds 2 MiB, then transparently switches to a file in the system temporary directory, as described in the PHP stream wrapper documentation.

That buys bounded PHP memory, but it is not free. You need enough temporary disk capacity to hold the object, since a large file spills out of memory and onto disk. The first request for a fallback-only object also pays for a full download from the source plus a full upload to the destination before the response completes, which can be well beyond a normal request timeout for large files.

Applications handling large objects should size temporary storage and request timeouts to match the largest object they expect to promote through the request path. A better answer for genuinely large files is to move them with a background bulk transfer before they ever enter a user-facing request.

## What Promotion Does Not Carry Over {#what-promotion-does-not-carry-over}

Promotion looks like a file copy, but it is narrower than that, and the difference shows up in production as broken caching or wrong download filenames rather than as an error.

Objects in different stores carry their own metadata. Promotion passes only the path and the object contents through Flysystem's generic write contract. The destination disk then applies its own configured upload defaults to the new object.

Everything provider-specific sits outside that contract and is simply not transferred. That includes cache-control headers, content disposition, storage class, custom user metadata, and the original modification timestamp. Visibility after promotion comes from primary's configuration, not from whatever the object had on the source. A promoted object is a new object on the destination that happens to share a path and a byte stream with the original.

If any of that metadata matters to your delivery path, and it usually does for anything served directly to browsers, promotion alone will not preserve it. You need a provider-aware bulk transfer that copies metadata explicitly, or a separate metadata pass over the destination after the objects have landed. The practical advice is to audit which headers your delivery path actually depends on before you retire the source bucket, while you still have the original objects to compare against.

## URL Resolution and Direct Delivery {#url-resolution-and-direct-delivery}

Many Laravel applications never stream file contents through PHP at all. They generate a URL and let the browser fetch from the provider. The driver handles this correctly, but the implication for your migration timeline is significant and frequently overlooked.

```php
$url = Storage::disk('assets')->url('posts/19.jpg');

$temporaryUrl = Storage::disk('assets')->temporaryUrl('posts/19.jpg', now()->addMinutes(5));
```

Both calls locate the disk currently containing the path and delegate URL generation to it. If the object has already been promoted, you get an R2 URL. If it still lives only on the source, you get an S3 URL. Either way the returned link works.

What does not happen is promotion. URL generation leaves the object exactly where it is, because the actual content request travels from the browser or API client to the provider and never passes through the read-through adapter. Laravel does not see that download and therefore has no opportunity to copy anything.

The consequence is worth stating bluntly: a workload that delivers most of its objects through direct URLs will promote almost nothing through application traffic. If your images are served by signed R2 or S3 links from Blade templates, the read-through disk will sit there looking healthy while the source bucket stays full. Those applications need a background bulk transfer to do the real work, or a dedicated download route that pulls content through the application so promotion can happen.

Temporary upload URLs are the exception in the other direction. They always come from primary, so client-side direct uploads land in the destination store from the first day of the migration, exactly like server-side writes.

## Deletes and Mutable Keys {#deletes-and-mutable-keys}

Deletion is the one operation where the driver reaches for fallback first, and the ordering is a correctness decision rather than an optimization.

```php
Storage::disk('assets')->delete('posts/19.jpg');
```

This removes the path from both disks. Laravel deletes the fallback object first, when one exists, and then deletes the primary object. A path deleted through the composite disk stays deleted, and no later read can promote it back.

The failure mode this prevents is worth naming, because it is genuinely surprising the first time you hit it. Call it a ghost delete: you delete an object from the destination store, the next request for that path misses primary, the driver dutifully finds the object still sitting on fallback, promotes it, and the file you deleted is back. Deleting fallback first closes that loop. Directory deletion follows the same rules and the same ordering.

This has a permissions implication that catches teams out. Deleting through the composite disk requires a source credential with delete permission. A read-only source credential does not silently skip the fallback delete; it fails, and that failure also prevents the primary delete from running. Whether your application sees an exception or a `false` return depends on the disk's `throw` option, but either way the object remains in both stores.

If your team intends to hold the source bucket immutable until cutover, which is a perfectly reasonable rollback posture, you need another durable record of deletion. Application-level tombstones work, as does a workflow that queues destructive operations and defers them until after the fallback disk has been retired.

Mutable keys need the same kind of care. Promotion is a one-time event per path. After a path has been promoted, reads come from primary, so any later change written only to the fallback copy is invisible to the application. The rules that keep this safe are simple: send every new write to primary from the moment of cutover, and make background copy jobs skip any path that already exists on primary.

## Egress and Operation Costs During Migration {#egress-and-operation-costs-during-migration}

A read-through migration spreads its cost across ordinary traffic instead of concentrating it in one bulk job, which is pleasant operationally and slightly harder to forecast financially. It helps to count what a single fallback-only read actually costs.

In the S3 to R2 configuration from earlier, the first content read of an object that exists only on fallback can perform up to two R2 existence checks, one S3 GET, and one logical R2 write. Moving those bytes out of AWS may incur AWS data transfer out charges. On the R2 side, existence checks bill as Class B operations and writes bill as Class A operations, and multipart uploads consume additional Class A operations.

As of the time of writing, August 2026, the public rates are listed below. See [Cloudflare R2 pricing](https://developers.cloudflare.com/r2/pricing/), [Amazon S3 pricing](https://aws.amazon.com/s3/pricing/), and [AWS data transfer pricing](https://aws.amazon.com/ec2/pricing/on-demand/#Data_Transfer) for current figures.

| Charge | Public rate |
| --- | --- |
| R2 Standard storage | $0.015 per GB-month |
| R2 Class A operations | $4.50 per million; first 1 million per month free |
| R2 Class B operations | $0.36 per million; first 10 million per month free |
| R2 internet egress | Free |
| AWS internet data transfer out | First 100 GB per month free across AWS; common US paid tiers begin at $0.09 per GB |
| S3 Standard GET requests in US East | $0.0004 per 1,000 requests |

The shape of these numbers explains why traffic-driven promotion is attractive. A fallback read pays source egress exactly once for that object, copies it to R2, and every subsequent read is served from a store with free egress. Your most requested files, the ones generating the most egress, are also the first ones to stop generating it.

It is worth resisting the conclusion that this makes the migration cheaper overall. Cold objects stay on the source until a bulk migration moves them, and if every object eventually has to move, the total source transfer is roughly the same either way. What read-through actually buys is timing and risk: a lower upfront bill, immediate migration of the active working set, and no big-bang copy that has to succeed all at once.

## Completing the Migration {#completing-the-migration}

Traffic-driven promotion moves the working set, and only the working set. Rarely requested objects form a cold tail that can sit on fallback indefinitely, and a migration is not finished until that tail is gone. A complete migration usually follows this sequence:

1. Configure the destination as `primary` and the current store as `fallback` on a read-through disk.
2. Point application filesystem traffic at that disk. New writes now land on primary from this moment forward.
3. Enumerate the remaining keys through the fallback disk and dispatch background copy jobs. Preserve any path already present on primary.
4. Track transferred bytes, transferred keys, skipped keys, retries, and failed keys.
5. Verify the destination key set. Object counts are one signal, but key comparison, object sizes, and checksums are stronger evidence wherever the providers expose them.
6. Point the application directly at primary once the background copy and an observation window have both completed.
7. Remove the read-through disk, revoke the fallback credentials, and retire the source according to your retention policy.

The third item is where most of the engineering effort goes, and the guard that makes it safe is short.

```php
use Illuminate\Support\Facades\Storage;

public function handle(): void
{
    $primary = Storage::disk('r2');
    $fallback = Storage::disk('legacy-s3');

    // Never overwrite an object that already exists on the destination.
    // It may be a post-cutover upload that is newer than the source copy.
    if ($primary->exists($this->path)) {
        return;
    }

    $stream = $fallback->readStream($this->path);

    $primary->writeStream($this->path, $stream);
}
```

The important line is the early return. Background workers must preserve primary objects by default, because by the time the copy job runs, that path may hold an upload or an update created after cutover. Overwriting it with the source copy would silently roll back a user's change. Note also that this job talks to the underlying disks directly rather than through the composite disk, which is deliberate: it needs to inspect and write each store explicitly rather than let the driver decide.

Enumeration deserves one warning. `allFiles()` returns a plain array and will consume a great deal of application memory on a bucket with millions of keys. For large sources, use the provider's paginated listing API or a dedicated migration service to feed the job queue instead.

The reassuring property throughout all of this is that promotion never deletes fallback content. Copying an object to primary leaves the source object untouched. The source therefore stays intact and available for verification and rollback right up until the team explicitly retires it, which is what makes the whole approach safe to run against production traffic.

## Alternatives to Read-Through Promotion {#alternatives-to-read-through-promotion}

Laravel's read-through driver occupies a specific niche: it is the right tool when the migration should follow the application's own filesystem abstraction, when the objects that matter most are the ones the application actually requests, and when you want the transition expressed in configuration rather than in operations tooling. Several other tools solve adjacent parts of the same problem, and a real migration frequently combines them.

- **Cloudflare Sippy** performs on-demand migration at the R2 service layer. Because it operates below your application, requests through Workers, the S3 API, and public buckets can all trigger a copy, which covers the direct-URL delivery paths that never reach Laravel.
- **Cloudflare Super Slurper** runs a managed bulk copy into R2 and can skip objects already present in the destination. That skip behavior makes it a natural fit for the cold tail after an incremental cutover.
- **rclone** and **MinIO `mc mirror`** run operator-managed copies between storage providers. They offer the most direct control over concurrency, filtering, and the handling of very large objects.
- **AWS DataSync** supports managed transfers between Amazon S3 and Cloudflare R2, which suits teams that prefer to define and verify transfer tasks from the AWS side.

The most common combination is an incremental mechanism paired with a bulk one. Read-through promotion or Sippy moves the active working set while the application keeps serving traffic normally, then a bulk tool sweeps up whatever traffic never touched. Choosing read-through does not commit you to finishing the migration with it.

## Conclusion {#conclusion}

The read-through filesystem driver turns a storage migration from a scheduled event into a background process. Both stores sit behind one disk name, the application stops caring which one answers, and ordinary traffic migrates the files that matter most. The details that decide whether it works well for you are less about the driver and more about how your application reads files: through PHP or through direct URLs, with immutable keys or mutable ones, at sizes that fit in memory or sizes that do not.

- **One logical disk, two stores.** A `read-through` disk composes a primary and a fallback disk so application code keeps calling one disk name throughout the migration.
- **Fallback is consulted only on a miss.** An error checking or reading primary stays a primary error, so a broken destination store never hides behind the source.
- **Promotion is a copy, not a move.** Fallback content survives every promotion, which is what keeps verification and rollback available until you explicitly retire the source.
- **Promotion is best effort unless you say otherwise.** Set both `throw` and `throw_on_promotion_failure` to `true` to make a failed copy fail the read, because either one alone gives you the worst of both behaviors.
- **`readStream()` bounds memory, `get()` does not.** `get()` holds the whole object as a PHP string before promoting, while `readStream()` buffers through `php://temp` and spills to disk past 2 MiB.
- **Deletes hit fallback first, then primary.** That ordering is what prevents a deleted object from being promoted back on the next read.
- **URLs resolve in place and never promote.** Direct-URL delivery bypasses the adapter entirely, so URL-heavy applications must plan on a bulk transfer doing nearly all the work.
- **Provider metadata does not travel.** Cache headers, content disposition, storage class, custom metadata, and original timestamps need a provider-aware copy or a separate metadata pass.
- **The cold tail still needs a bulk pass.** Traffic only ever migrates the objects traffic requests, so plan the background copy, the verification step, and the retirement of the source disk from the start.
