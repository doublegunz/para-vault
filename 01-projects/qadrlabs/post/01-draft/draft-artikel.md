Object storage migrations with Laravel's read-through filesystem
Migrate from S3 to R2 without downtime using Laravel 13's read-through filesystem driver. New writes land on the destination, legacy reads promote on access.

Object storage cutover and object transfer happen on different timelines. New uploads begin landing in the destination immediately, while existing objects remain in the source until they are copied. Application reads must work across both stores during that interval.

Laravel 13 adds a read-through filesystem driver for this transition. It stacks a primary disk and a fallback disk behind Laravel's filesystem API. Primary receives writes, while the fallback is used only when primary reports the path missing. Failures checking or reading primary remain primary failures.

A fallback hit can copy the file into primary during the same request. The copy from fallback to primary is called a "promotion." Once a path has been promoted, later reads use primary.

One logical disk across two stores
A read-through disk references two ordinary Laravel disks:


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
The primary and fallback values can be configured disk names, as above, or contain inline disk configuration arrays.

Point the application's default filesystem at the composite disk during the migration:


FILESYSTEM_DISK=assets
The assets disk now owns application storage traffic. A new upload goes to r2, but a request for a legacy path can still reach legacy-s3.

The driver can compose any set of Laravel disks whose adapters support the operations your application uses. The default promoting read path requires existence checks and reads on both disks, plus writes to primary. An S3 bucket can feed R2. A local disk can feed object storage. R2→R2, B2→S3, and FTP→B2 all fit the model.

Scoped disks also make it possible to migrate between prefixes.

Configure one scoped disk with prefix => 'legacy' and another with prefix => 'current'. A read of avatars/42.jpg checks current/avatars/42.jpg, falls back to legacy/avatars/42.jpg, and writes the object under the current prefix when promoted. The prefixes can share one bucket or belong to different stores.

The read path
Given this call:


$contents = Storage::disk('assets')->get('avatars/42.jpg');
Laravel follows this path:


get("avatars/42.jpg")
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
On a primary miss, Laravel reads fallback and checks primary again before promoting. If another request populated primary during the fallback read, Laravel discards the fallback contents and reads primary to prevent overwriting it or returning stale data. Otherwise it writes the fallback contents to primary and returns them.

The second check reduces duplicate promotions and protects an object already visible on primary. The final check and write remain separate, so a concurrent write can still land between them. Immutable or versioned object keys avoid that race. Applications that overwrite paths should coordinate writes during the transition.

After a successful promotion, later reads use primary and changes made only to fallback are no longer visible for that file.

The filesystem contract
The composite disk routes each filesystem operation deliberately:

Operation	Disk selection	Promotion behavior
get, read, readStream	Primary, then fallback on a miss	Promotes fallback hits by default
exists, size, mimeType, lastModified, visibility	Primary, then fallback	Inspects the object in place
put, writeStream, directory creation, visibility changes	Primary	Writes directly
Directory listings	Primary	Reports destination state
delete, deleteDirectory	Fallback, then primary	Removes the path from both stores
move	Primary, then fallback	Moves on primary and deletes the fallback source
copy	Primary	Operates on destination state
Public and temporary download URLs	The disk currently containing the path	Resolves a URL in place
Temporary upload URLs	Primary	Uploads directly
Directory listings show primary only. For a bulk migration, list fallback directly and skip paths already present on primary. (More on that below.)

Move and copy operate on primary. If a source exists only on fallback, read it through the read-through disk first. With promotion enabled, the read copies it to primary, after which the move or copy can proceed.

Move also deletes the fallback source once the primary move succeeds, so a moved path leaves nothing behind for the read path to promote. If that fails, the source surfaces as an UnableToMoveFile error. Copy leaves the fallback source in place, and the read path can still promote the original path.

Promotion failures
Promotion is best effort by default, and things can always fail! If the fallback read succeeds and the primary write fails, Laravel returns the fallback contents. The object remains on fallback, and a later read can attempt promotion again.

Best-effort mode absorbs the promotion exception. It emits no filesystem event or report.

Applications that require a failed promotion to fail the read can enable strict promotion behavior:


'assets' => [
    'driver' => 'read-through',
    'primary' => 'r2',
    'fallback' => 'legacy-s3',
    'throw' => true,
    'throw_on_promotion_failure' => true,
],
throw_on_promotion_failure decides whether a failed copy should also fail the read. With its default value of false, Laravel returns the fallback contents even when the copy to primary fails.

If you need to surface that error, set it to true and the driver treats that copy failure as an UnableToReadFile error. The disk's standard throw option must also be true for application code to receive that exception; otherwise, get() catches it and returns null.

Best-effort mode preserves a successful fallback read when the promotion write fails. Strict mode makes that failed copy visible to application code.

Streamed reads and temporary storage
Do remember that get() loads the entire object into a PHP string before promotion, so memory use grows with file size. A nice alternative is readStream(), which buffers the object in temporary storage, limiting PHP memory use during promotion.

On a fallback stream hit, Laravel copies the source stream into php://temp, writes that stream to primary, rewinds it, and returns it to the caller. By default, PHP keeps the stream in memory until it exceeds 2 MiB, then switches to a file in the system temporary directory, according to the PHP stream wrapper documentation.

This avoids materializing the whole object as one PHP string, but it does require enough temporary disk capacity for the object, and the first response includes the time needed to download from fallback and upload to primary.

Applications with large objects should size temporary storage and request timeouts to meet their needs. A background bulk transfer could also move large objects before they enter the request path.

Object metadata
Objects in different stores have their own metadata. Promotion passes the path and object contents through Flysystem's generic write contract. The destination disk supplies its configured upload defaults.

Provider-specific object metadata sits outside of that contract. Cache headers, content disposition, storage class, custom metadata, and the original modification timestamp may need a provider-aware bulk transfer or a separate metadata pass. Visibility after promotion comes from primary.

Applications that serve objects directly from storage should audit the headers used by their delivery path before retiring the source bucket.

URL resolution
When generating publicly accessible URLs, Storage::url($path) finds the disk currently containing the path and delegates URL generation to that disk. Temporary download URLs follow the same rule.

This does not affect promotion! URL generation leaves file contents in place. The browser or API client fetches from the returned provider URL, so the content request travels outside the read-through adapter. Workloads that deliver most objects through direct URLs may promote few objects through application traffic. A background transfer or a dedicated application-controlled download route can cover those paths.

Temporary upload URLs always come from primary so that your new uploads land in the primary destination from the beginning of the migration.

Deletes and mutable keys
Delete operations remove the path from both disks. Laravel deletes the fallback object first, when one exists, then deletes the primary object. A path deleted through the read-through disk stays deleted, and no later read can promote it back.


Storage::disk('assets')->delete('avatars/42.jpg');
This prevents a sort of "ghost delete" where you delete from the primary, only to have the fallback file later re-promoted. Directory deletion follows the same rules and ordering.

Remember that deleting through the composite disk requires a credential with delete permission. A read-only source credential fails the fallback delete instead of silently leaving the object in place, and that failure also prevents the primary delete from running. The disk's throw option decides whether application code receives the error.

If your team intends to hold the source bucket immutable until cutover, you will need another durable record of deletion, such as an application tombstone, or a workflow that defers destructive operations until fallback has been retired.

Paths that are overwritten or updated in place still need care! Once a path has been promoted, reads use the primary copy, so later changes to the fallback copy are no longer visible. Successful promotion only happens once. Send all new writes to primary at cutover, and make background copy jobs skip paths that already exist there.

Egress costs during migration
In the S3-to-R2 configuration above, the first content read of a fallback-only object can perform up to two R2 existence checks, one S3 GET, and one logical R2 write. Moving the bytes from AWS to R2 may incur AWS data transfer out.

R2 bills existence checks as Class B operations and writes as Class A operations. (Multipart uploads can use additional Class A operations.)

As of the time of writing (August 2026) the public rates are listed below. See Cloudflare R2 pricing, Amazon S3 pricing, and AWS data transfer pricing.

Charge	Public rate
R2 Standard storage	$0.015 per GB-month
R2 Class A operations	$4.50 per million; first 1 million per month free
R2 Class B operations	$0.36 per million; first 10 million per month free
R2 internet egress	Free
AWS internet data transfer out	First 100 GB per month free across AWS; common US paid tiers begin at $0.09 per GB
S3 Standard GET requests in US East	$0.0004 per 1,000 requests
The good news is that read-through migration lets application traffic choose which objects move first.

A fallback read incurs source egress once, copies the object to R2, and sends later reads through R2 with free egress. Cold objects remain on the source until a bulk migration moves the remainder. If every object eventually moves, total source transfer requires a bulk migration to capture the cold tail of objects.

Even with a bulk migration at the end, the benefit is lower upfront cost and immediate migration of the active working set.

Completing the migration
As we mention above, this sort of "traffic-driven promotion" moves the most active working set of objects. Rarely requested objects form a cold tail that can remain on fallback indefinitely.

A complete migration usually follows this pattern:

Configure the destination as primary and the current store as fallback.
Point application filesystem traffic at the read-through disk. New writes now land on primary.
Enumerate remaining keys through the fallback disk and dispatch background copy jobs. Preserve any path already present on primary.
Track transferred bytes, transferred keys, skipped keys, retries, and failed keys.
Verify the destination key set. Object counts provide one signal. Key comparison, object sizes, and checksums provide stronger evidence where the providers expose them.
Point the application directly at primary after the background copy and an observation window have completed.
Remove the read-through disk, revoke fallback credentials, and retire the source according to the application's retention policy.
If your source bucket is large, it should use paginated provider listings or a migration service. allFiles() returns an array and can consume a lot of application memory for a bucket with millions of keys.

In general, background workers should preserve primary objects by default. This protects uploads and updates created after cutover.

Promotion alone never deletes fallback content. The source therefore remains available for verification and rollback until the team explicitly retires it through a bulk migration or other similar mechanism.

Alternatives
Laravel's read-through driver is useful when migration needs to follow the application's filesystem abstraction. Other tools fit different transfer paths:

Cloudflare Sippy performs on-demand migration at the R2 service layer. Requests through Workers, the S3 API, and public buckets can trigger a copy, including delivery paths that bypass Laravel.
Cloudflare Super Slurper runs a managed bulk copy into R2. It can skip objects already in the destination, making it useful for the cold tail after an incremental cutover.
rclone and MinIO mc mirror run operator-managed copies between storage providers. They provide more control over concurrency, filtering, and very large objects.
AWS DataSync supports managed transfers between Amazon S3 and Cloudflare R2. It fits teams that want transfer tasks and verification managed from AWS.
A migration can combine these approaches. Read-through promotion or Sippy moves the active working set, then a bulk tool copies the remaining objects.

