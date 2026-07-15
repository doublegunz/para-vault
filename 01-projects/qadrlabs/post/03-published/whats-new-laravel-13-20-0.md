# What's New in Laravel 13.20.0: Image Processing, New APIs, and Important Fixes

Laravel release notes can be difficult to evaluate quickly. A single release may contain new public APIs, internal refactoring, documentation updates, tests, and bug fixes, but the changelog does not always explain which changes will affect your application.

Skipping a minor framework release can also mean overlooking an API that removes custom code, improves test readability, or fixes an edge case already present in production. The challenge is not finding the list of pull requests. The challenge is understanding what each relevant change means in practical Laravel development.

Laravel 13.20.0 was released on July 14, 2026. Its most significant addition is first-party image processing, supported by a driver-based and immutable API. The release also improves Storage, Queue Fake, Mail Fake, Eloquent, Redis sessions, controller middleware attributes, number formatting, trusted proxies, S3, SQS, and several internal framework workflows. This article explains the changes that matter most and provides focused examples that you can try in a Laravel 13 application.

You can review the complete list of merged changes in the [official Laravel 13.20.0 release notes](https://github.com/laravel/framework/releases/tag/v13.20.0).

## Overview {#overview}

Laravel 13.20.0 combines a major framework capability with a collection of smaller APIs and maintenance fixes. The new image component is the headline feature, but the release also contains useful improvements for application testing, queue workflows, Eloquent counters, session isolation, middleware configuration, and production reliability.

### What You'll Build

This is a release overview rather than a sequential application tutorial. By the end of the article, you will have:

- A practical reference for the most important Laravel 13.20.0 changes.
- A runnable image processing example for an uploaded file.
- Focused examples for Storage Fake, Queue Fake, Mail Fake, Eloquent, Redis sessions, controller attributes, enums, and string helpers.
- An upgrade checklist for evaluating the release in an existing Laravel application.

### What You'll Learn

You will learn how to:

- Process uploaded and stored images through Laravel's new Image API.
- Choose between the GD, Imagick, and Cloudflare image drivers.
- Create multiple image variants without mutating the original image instance.
- Assert that an entire fake storage disk is empty.
- register callbacks before and after a job is pushed into `QueueFake`.
- Assert the exact number of times a mailable was queued.
- Increment or decrement multiple Eloquent columns without dispatching model events.
- Exclude middleware with the new `#[WithoutMiddleware]` controller attribute.
- Separate Redis session keys from cache keys with a dedicated prefix.
- Use an enum as a queue overlap key.
- Identify bug fixes that may affect existing applications.

### What You'll Need

To follow the examples, you need:

- PHP 8.3 or later.
- Laravel Framework 13.20.0.
- Composer.
- A Laravel 13 application.
- Basic familiarity with HTTP requests, Storage, queues, Eloquent, middleware, and automated testing.
- The GD or Imagick PHP extension for local image processing, or a Cloudflare Images account for remote processing.

You can confirm the installed framework version with:

```bash
php artisan --version
```

This command shows the Laravel version used by the current application. The examples in this article assume that the reported version is Laravel Framework 13.20.0 or later.

## First-Party Image Processing {#first-party-image-processing}

The most important feature in Laravel 13.20.0 is the new first-party image processing API. Laravel now provides a framework-level abstraction for loading, transforming, converting, inspecting, and storing images.

The API is driver-based, which allows the application code to remain consistent while the actual processing is handled by GD, Imagick, or Cloudflare Images. It is also immutable. Every transformation returns a new image instance, so the original image is not modified.

This design is especially useful when an application needs to create several outputs from one upload, such as a profile thumbnail, a larger display image, and a greyscale preview.

### Installing a Local Image Driver

The GD and Imagick drivers use Intervention Image v3. Install the required package with Composer:

```bash
composer require intervention/image:^3.11.7
```

This package provides the underlying local image manipulation implementation. Laravel provides the framework-facing API, configuration, request integration, storage integration, and driver selection.

The GD driver also requires the PHP GD extension. The Imagick driver requires the PHP Imagick extension. You can check the available extensions with:

```bash
php -m
```

Look for either `gd` or `imagick` in the output. Large source images can consume substantial memory when processed locally, so memory limits and upload limits should be reviewed for applications that accept high-resolution photos.

### Configuring the Image Driver

New Laravel 13 applications include an image configuration file. Existing Laravel 13 applications can publish it with:

```bash
php artisan config:publish image
```

The command publishes `config/image.php`, which contains the default driver and driver-specific configuration.

The most important setting is:

```php
<?php

return [
    // Select the driver used for image transformations.
    'default' => env('IMAGE_DRIVER', 'gd'),
];
```

The application reads the driver from the `IMAGE_DRIVER` environment variable and falls back to GD when the variable is not defined.

You can select a local driver in `.env`:

```ini
IMAGE_DRIVER=gd
```

Use `imagick` instead when the Imagick extension is installed and you prefer that processing engine.

### Processing Images with Cloudflare

The Cloudflare driver sends image processing work to the Cloudflare Images API. This reduces local memory and CPU usage because the transformation does not run inside the PHP process.

Add the required credentials to `.env`:

```ini
IMAGE_DRIVER=cloudflare
IMAGE_CLOUDFLARE_ACCOUNT_ID=your-account-id
IMAGE_CLOUDFLARE_API_TOKEN=your-api-token
```

The driver temporarily uploads the source image, requests the transformation, downloads the result, and removes the temporary image. This workflow avoids local image processing costs, but it introduces network latency and several HTTP requests for each operation.

Cloudflare flexible variants must be enabled for this driver. The output may also differ slightly from a local GD or Imagick result because the remote service controls parts of the encoding, compression, rounding, and format behavior.

The Cloudflare driver does not support BMP input. Validation should restrict uploads to formats supported by the driver:

```php
<?php

use Illuminate\Validation\Rules\File;

$request->validate([
    'avatar' => [
        'required',
        'image',
        File::types(['jpg', 'png', 'gif', 'webp']),
    ],
]);
```

The validation rule prevents an unsupported image type from reaching the Cloudflare processing workflow.

A terminated PHP process may occasionally leave a temporary Cloudflare image behind. Laravel provides `pruneOrphaned()` for scheduled cleanup:

```php
<?php

use Illuminate\Support\Facades\Image;
use Illuminate\Support\Facades\Schedule;

Schedule::call(function (): void {
    // Remove old temporary images created by the Laravel image driver.
    Image::pruneOrphaned('cloudflare');
})->hourly();
```

This scheduled task removes matching temporary images that are old enough to be considered orphaned.

### Obtaining an Image Instance

The most direct way to process an uploaded image is through the request:

```php
<?php

$image = $request->image('avatar');
```

The `image()` method reads the uploaded file and returns a Laravel image instance that can be transformed and stored.

Laravel can also create an image from several other sources:

```php
<?php

use Illuminate\Support\Facades\Image;
use Illuminate\Support\Facades\Storage;

// Create an image from a local file path.
$fromPath = Image::fromPath(storage_path('app/photos/source.jpg'));

// Download and create an image from a remote URL.
$fromUrl = Image::fromUrl('https://example.com/photo.jpg');

// Create an image from raw binary data.
$fromBytes = Image::fromBytes($bytes);

// Create an image from a Base64 encoded string.
$fromBase64 = Image::fromBase64($base64);

// Create an image from a file already stored on the S3 disk.
$fromStorage = Storage::disk('s3')->image('photos/avatar.jpg');
```

These entry points allow the same transformation API to be used for fresh uploads, imported images, existing files, remote assets, and generated binary content.

Remote URLs should only come from trusted or carefully validated sources. The server performs the outbound request, so unrestricted user-provided URLs can create security and infrastructure risks.

### Common Image Transformations

Laravel 13.20.0 includes common transformations for resizing, orientation correction, visual effects, format conversion, quality control, and storage.

The `cover()` method resizes and crops an image so that it exactly fills the requested dimensions:

```php
<?php

$thumbnail = $image->cover(300, 300);
```

The result is exactly 300 by 300 pixels. The original aspect ratio is preserved, but parts of the image may be cropped to fill the square.

The `scale()` method resizes proportionally within the requested boundaries:

```php
<?php

$displayImage = $image->scale(1600, 1200);
```

The result fits within 1600 by 1200 pixels without changing the aspect ratio. Smaller images are not enlarged, which helps avoid unnecessary quality loss.

The `orient()` method reads EXIF orientation data:

```php
<?php

$oriented = $image->orient();
```

This is useful for smartphone photos that contain orientation metadata and otherwise appear rotated after upload.

Laravel also provides visual effects:

```php
<?php

$blurred = $image->blur(15);
$greyscale = $image->greyscale();
$sharpened = $image->sharpen(10);
$verticalMirror = $image->flip();
$horizontalMirror = $image->flop();
```

`blur()` accepts an amount from 0 to 100. `sharpen()` is particularly useful after reducing image dimensions because downscaled images can appear slightly soft.

### Converting and Optimizing Images

An image can be converted to WebP or JPEG:

```php
<?php

$webp = $image->toWebp();
$jpeg = $image->toJpg();
```

Format conversion is useful when an application wants predictable output regardless of the uploaded file type.

You can control the quality of a lossy output:

```php
<?php

$webp = $image
    ->toWebp()
    ->quality(85);
```

A higher quality value generally produces a larger file. The appropriate value depends on the visual requirements and the acceptable storage and bandwidth cost.

Laravel also provides `optimize()` as a convenient combination of format and quality:

```php
<?php

$defaultOptimized = $image->optimize();
$highQualityJpeg = $image->optimize('jpg', 90);
```

Calling `optimize()` without arguments produces WebP at quality 75. The second example produces JPEG at quality 90.

### Processing an Uploaded Image

The following route is a compact example that can be added to `routes/web.php`:

```php
<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/photos', function (Request $request): array {
    $request->validate([
        'photo' => ['required', 'image', 'max:10240'],
    ]);

    $path = $request
        ->image('photo')
        ->orient()
        ->cover(1200, 800)
        ->optimize()
        ->store('photos', 'public');

    return [
        'path' => $path,
    ];
});
```

The validation limits the upload to an image with a maximum size of 10 MB. `orient()` corrects EXIF rotation before the dimensions are changed. `cover(1200, 800)` creates an exact 3:2 output. `optimize()` converts it to WebP with the default quality. `store()` writes the processed result to the `photos` directory on the public disk.

The order is intentional. Orientation correction happens before cropping, so the width and height used by `cover()` match the visual orientation of the photo.

### Creating Multiple Variants

Because transformations are immutable, one source image can safely produce several independent variants:

```php
<?php

$image = $request
    ->image('photo')
    ->orient();

$thumbnailPath = $image
    ->cover(300, 300)
    ->toWebp()
    ->quality(80)
    ->store('photos/thumbnails', 'public');

$largePath = $image
    ->scale(1600, 1200)
    ->toWebp()
    ->quality(85)
    ->store('photos/large', 'public');

$greyscalePath = $image
    ->greyscale()
    ->scale(1200, 900)
    ->toWebp()
    ->store('photos/greyscale', 'public');
```

Each chain starts from the same oriented source instance. Creating the thumbnail does not resize the source used by the large image. Applying greyscale does not affect the color versions.

This behavior removes the need to reload the uploaded file before every variant and reduces the risk of accidentally applying stale transformations to a later output.

### Inspecting and Exporting an Image

After transformations are defined, Laravel can return metadata and encoded representations:

```php
<?php

$processed = $image
    ->cover(300, 300)
    ->toWebp();

$mimeType = $processed->mimeType();
$extension = $processed->extension();
$dimensions = $processed->dimensions();
$width = $processed->width();
$height = $processed->height();

$bytes = $processed->toBytes();
$base64 = $processed->toBase64();
$dataUri = $processed->toDataUri();
```

The metadata methods help when an application needs to persist dimensions or verify the generated format. `toBytes()` returns the processed binary content. `toBase64()` returns an encoded string. `toDataUri()` produces a value that can be embedded directly in HTML or CSS, which can be useful for small placeholders.

### Storing Processed Images

The Image API mirrors familiar uploaded file storage methods:

```php
<?php

$randomPath = $image
    ->cover(300, 300)
    ->toWebp()
    ->store('avatars');

$namedPath = $image
    ->cover(300, 300)
    ->toWebp()
    ->storeAs('avatars', 'user-42.webp');

$s3Path = $image
    ->cover(300, 300)
    ->toWebp()
    ->store('avatars', 's3');
```

`store()` generates a filename automatically. `storeAs()` gives the application control over the filename. Passing a disk name sends the result to that configured filesystem disk.

Public storage variants are also available through `storePublicly()` and `storePubliclyAs()`.

## Storage Fake Can Assert That a Disk Is Empty {#storage-fake-can-assert-that-a-disk-is-empty}

Laravel 13.20.0 adds `assertEmpty()` to the filesystem adapter. The method asserts that the selected disk contains no files.

A focused Pest example looks like this:

```php
<?php

use Illuminate\Support\Facades\Storage;

it('leaves the temporary disk empty', function (): void {
    Storage::fake('temporary');

    // Run an operation that should create and then remove temporary files.

    Storage::disk('temporary')->assertEmpty();
});
```

The assertion checks the entire disk, not a specific directory. This distinction matters because Laravel already provides `assertDirectoryEmpty()` for a directory:

```php
<?php

Storage::disk('temporary')->assertDirectoryEmpty('imports');
```

Use the assertions according to the condition being tested:

- `assertEmpty()` confirms that the disk contains no files.
- `assertDirectoryEmpty('imports')` confirms that one directory contains no files.
- `assertMissing('imports/source.csv')` confirms that a specific file or directory does not exist.
- `assertExists('imports/source.csv')` confirms that a specific file or directory exists.

`assertEmpty()` is especially useful for temporary export disks, import staging areas, failed upload cleanup, and tests that must prove an operation leaves no filesystem artifacts behind.

## Queue Fake Lifecycle Callbacks {#queue-fake-lifecycle-callbacks}

`QueueFake` now supports `beforePushing()` and `afterPushing()` callbacks. These hooks allow tests to react immediately before or after a job is recorded by the fake queue.

The methods return the `QueueFake` instance, so they can be chained:

```php
<?php

use App\Jobs\GenerateReport;
use Illuminate\Support\Facades\Queue;

it('observes the queue push lifecycle', function (): void {
    $events = [];

    Queue::fake()
        ->beforePushing(function (GenerateReport $job) use (&$events): void {
            $events[] = 'before:'.$job->reportId;
        })
        ->afterPushing(function (GenerateReport $job) use (&$events): void {
            $events[] = 'after:'.$job->reportId;
        });

    GenerateReport::dispatch(reportId: 42);

    expect($events)->toBe([
        'before:42',
        'after:42',
    ]);

    Queue::assertPushed(GenerateReport::class);
});
```

The first callback runs before the fake stores the job. The second callback runs after the job has been pushed.

These hooks are useful when a test needs to:

- Advance or freeze time after a specific job is dispatched.
- Capture job state at the moment it enters the queue.
- Simulate an external side effect around a fake push.
- Inspect ordering in a job chain.
- Avoid extending `QueueFake` only to override its `push()` method.

The original pull request was motivated by a test that needed to change the current time after a particular job was dispatched. The new callbacks make that scenario possible without replacing the framework fake with a custom subclass.

## MailFake assertQueuedTimes Is Public {#mailfake-assertqueuedtimes-is-public}

`MailFake::assertQueuedTimes()` is now public. Tests can directly assert that a particular mailable was queued an exact number of times.

```php
<?php

use App\Mail\OrderShipped;
use Illuminate\Support\Facades\Mail;

it('queues three shipment emails', function (): void {
    Mail::fake();

    Mail::to('first@example.com')->queue(new OrderShipped());
    Mail::to('second@example.com')->queue(new OrderShipped());
    Mail::to('third@example.com')->queue(new OrderShipped());

    Mail::assertQueuedTimes(OrderShipped::class, 3);
});
```

`assertQueued()` is useful when you need to prove that at least one matching mailable was queued, optionally with a callback. `assertQueuedTimes()` communicates a stricter requirement: the exact number of queued instances must match.

Laravel also provides `assertQueuedCount()` when the test needs to assert the total number of all queued mailables rather than the count of one mailable class.

## Quiet Multi-Column Eloquent Updates {#quiet-multi-column-eloquent-updates}

Laravel 13.20.0 adds `incrementEachQuietly()` and `decrementEachQuietly()` to Eloquent models. These methods update several numeric columns while suppressing model events.

```php
<?php

$product->incrementEachQuietly([
    'views' => 1,
    'popularity_score' => 5,
]);
```

The example increments `views` by 1 and `popularity_score` by 5. Eloquent performs the update without dispatching model events such as `updating` and `updated`.

The inverse operation is also available:

```php
<?php

$product->decrementEachQuietly([
    'stock' => 1,
    'reserved_stock' => 1,
]);
```

This can be useful for counters, statistics, inventory adjustments, data repair scripts, and maintenance tasks where observers should not run.

The methods also accept an extra attributes array:

```php
<?php

$product->incrementEachQuietly(
    [
        'views' => 1,
        'popularity_score' => 5,
    ],
    [
        'last_counted_at' => now(),
    ],
);
```

The second array updates additional columns alongside the increments.

Quiet operations should be used deliberately. If an observer updates a search index, writes an audit entry, invalidates a cache, or performs another required action, suppressing the event may create inconsistent application state.

The same release also fixes dynamic calls to these new methods, which is important because model method forwarding is part of how they are exposed for normal model usage.

## WithoutMiddleware Controller Attribute {#withoutmiddleware-controller-attribute}

Laravel's controller attributes can add middleware with `#[Middleware]`. Laravel 13.20.0 adds the inverse operation through `#[WithoutMiddleware]`.

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Routing\Controllers\Attributes\Middleware;
use Illuminate\Routing\Controllers\Attributes\WithoutMiddleware;

#[Middleware('auth')]
class AccountController
{
    public function dashboard(): array
    {
        return [
            'page' => 'dashboard',
        ];
    }

    #[WithoutMiddleware('auth')]
    public function publicProfile(): array
    {
        return [
            'page' => 'public-profile',
        ];
    }
}
```

The controller applies the `auth` middleware by default. The `publicProfile()` method removes it for that action.

The attribute can exclude middleware from a specific controller method or from the controller class, depending on where it is placed. This provides an attribute-based equivalent to excluding middleware through route configuration.

Practical use cases include public profile actions, health checks, webhook endpoints, authentication callbacks, and controllers where most actions share middleware but one or two actions must remain public.

## Redis Session Prefixes {#redis-session-prefixes}

Applications that use managed Redis services may be limited to one logical Redis database. Sessions, cache entries, scheduler locks, and other data may therefore share the same keyspace.

Laravel 13.20.0 allows Redis-backed sessions to use a dedicated prefix:

```php
<?php

use Illuminate\Support\Str;

return [
    // Other session configuration...

    'prefix' => env(
        'SESSION_PREFIX',
        Str::slug((string) env('APP_NAME', 'laravel')).'-session-',
    ),
];
```

A deployment can override the value in `.env`:

```ini
SESSION_DRIVER=redis
SESSION_PREFIX=qadrlabs-production-session-
```

The prefix makes session keys easier to identify and separates them from cache keys that may use another prefix.

This is useful when:

- Several applications share one Redis cluster.
- Production, staging, and preview environments share infrastructure.
- A managed Redis service only exposes database zero.
- Operators need to inspect or remove cache keys without affecting sessions.
- Session keys need a predictable namespace for monitoring or cleanup.

The option is opt-in for existing configurations, so review `config/session.php` after updating the framework.

## Enums as Queue Overlap Keys {#enums-as-queue-overlap-keys}

Laravel's `WithoutOverlapping` queue middleware prevents multiple jobs with the same lock key from running at the same time. Laravel 13.20.0 includes support for using an enum as that key.

```php
<?php

namespace App\Enums;

enum ImportLock: string
{
    case Products = 'products';
    case Customers = 'customers';
}
```

The enum can be used in a queued job:

```php
<?php

namespace App\Jobs;

use App\Enums\ImportLock;
use Illuminate\Queue\Middleware\WithoutOverlapping;

class ImportProducts
{
    public function middleware(): array
    {
        return [
            new WithoutOverlapping(ImportLock::Products),
        ];
    }
}
```

Using an enum centralizes the available lock keys and removes repeated string literals. Renaming a case or discovering an invalid key becomes easier through static analysis and IDE support.

This is particularly helpful when several jobs coordinate around the same resource, import type, tenant, or processing category.

## Stringable Initials Can Be Capitalized {#stringable-initials-can-be-capitalized}

`Stringable::initials()` now accepts a `capitalize` argument:

```php
<?php

$originalCase = str('qadr labs')->initials();
$capitalized = str('qadr labs')->initials(capitalize: true);
```

The first call keeps the initials in their derived case. The second call capitalizes the result.

You can try it in Artisan Tinker:

```bash
php artisan tinker
```

Then run:

```php
str('qadr labs')->initials()->toString();
str('qadr labs')->initials(capitalize: true)->toString();
```

The option is useful for fallback avatars, user badges, company abbreviations, and compact labels where the source text may not already be capitalized.

## Worker, Security, and Developer Experience Improvements {#worker-security-and-developer-experience-improvements}

Several Laravel 13.20.0 changes improve observability, security, compatibility, type accuracy, and framework maintenance. Most do not require application code changes, but they can make production behavior and local development more predictable.

### WorkerStopping Includes Memory Usage

The `WorkerStopping` event now carries memory usage information when a queue worker stops. Applications that listen to worker lifecycle events can use this data for logging, metrics, memory leak analysis, and capacity planning.

This is especially useful for long-running workers where memory growth may only become visible after many jobs.

### Sensitive Parameters Are Marked

Laravel adds PHP's `#[SensitiveParameter]` attribute to parameters that carry secrets. PHP can use this metadata to redact sensitive values in stack traces.

The change reduces the chance that credentials, tokens, passwords, or other secrets appear in debugging output when an exception is thrown.

### Pail Registration Checks pcntl_fork

Laravel Pail is now registered in developer commands only when `pcntl_fork` is available.

This prevents the command from being exposed in environments that cannot support its process model, including some PHP installations and operating systems without the PCNTL extension.

### Migration Timestamps Are Collision-Free and Ordered

`php artisan make:migration` now generates ordered timestamp prefixes without collisions when several migrations are created in quick succession.

The fix is useful for code generators, automation scripts, package installers, and developers creating several related migrations within the same second.

### Fake Time Is Reset Globally

Laravel now resets fake time globally after each test and removes redundant manual Carbon cleanup from framework tests.

This reduces the risk that a frozen or modified time value leaks into another test and causes order-dependent failures.

### HTTP Header Lookups Are Normalized

HTTP client request header lookups are now normalized. Header names are case-insensitive by HTTP semantics, so lookups should behave consistently even when capitalization differs.

This improves tests and integrations that inspect headers written as `Authorization`, `authorization`, or another case variation.

### Getter Return Types Match Property Generics

Several getter return types now better reflect the generic types declared on their related properties.

This change mainly benefits static analysis, IDE completion, and developers maintaining code with stricter type checks.

### Internal Collection and Array Operations Are Simplified

Laravel replaces several manual loops with PHP's `array_all()` and `array_any()` where appropriate and uses clearer collection operations such as `contains()` or `doesntContain()` in internal code.

These are framework maintenance changes rather than new application APIs. Their value comes from simpler implementation, easier review, and alignment with modern PHP capabilities.

### Redundant Mockery Cleanup Is Removed

Redundant `Mockery::close()` calls were removed where Laravel's test lifecycle already performs the required cleanup.

This reduces duplicated test infrastructure code without changing the public testing API.

### PHPUnit Rector Configuration Is Simplified

Laravel's internal Rector configuration now uses PHPUnit Rector sets instead of listing individual rules.

This makes the framework's own automated code modernization configuration easier to maintain.

## Important Bug Fixes {#important-bug-fixes}

Minor releases are not only about new APIs. Laravel 13.20.0 fixes edge cases across strings, numbers, images, relationships, storage, SQS, proxies, JSON API resources, and command generation. These fixes may be more important than a new feature when an application already encounters the affected behavior.

### Str::containsAll with an Empty Needles Array

`Str::containsAll()` previously returned `true` when the needles array was empty. Laravel 13.20.0 corrects this edge case.

```php
<?php

use Illuminate\Support\Str;

$result = Str::containsAll('Laravel', []);
```

An empty list does not contain a meaningful set of values to match, so the corrected behavior avoids treating the check as successful.

This matters when the needles array is produced dynamically. A validation or filtering bug could otherwise convert an empty input into an unintended positive match.

### Tiny Negative Numbers No Longer Produce Negative Zero

`Number::forHumans()` and `Number::abbreviate()` could return `-0` when a tiny negative number rounded to zero at the requested precision.

```php
<?php

use Illuminate\Support\Number;

Number::forHumans(-0.4);
Number::abbreviate(-0.05);
```

Laravel now returns `0` when the formatted magnitude rounds to zero. Negative values that remain non-zero at the selected precision still keep their sign.

The release also fixes scaling behavior for tiny decimal values. These changes improve dashboards, analytics, financial summaries, and any UI that formats values close to zero.

### Image Branching No Longer Reapplies Stale Transformations

The new image component received a related bug fix in the same release. Stale transformations could be reapplied when an image was branched after `toBytes()`.

The fix protects workflows that export one representation and then continue creating other variants from the same immutable source.

```php
<?php

$image = $request
    ->image('photo')
    ->orient();

$previewBytes = $image
    ->cover(600, 400)
    ->toWebp()
    ->toBytes();

$thumbnailPath = $image
    ->cover(200, 200)
    ->toWebp()
    ->store('thumbnails');
```

The thumbnail chain should only contain its own transformations. It should not inherit the earlier 600 by 400 preview transformation.

### BelongsToMany touch() Supports Custom Related Keys

`BelongsToMany::touch()` is fixed for relationships where the related key is not `id`.

This affects models that use UUIDs, ULIDs, legacy identifiers, or another custom primary key:

```php
<?php

class Role extends Model
{
    protected $primaryKey = 'uuid';

    public $incrementing = false;

    protected $keyType = 'string';
}
```

Touching timestamps through a many-to-many relationship should now target the configured related key instead of assuming that the column is named `id`.

### S3 Reports Temporary Upload URL Support Correctly

`providesTemporaryUploadUrls()` now correctly returns `true` for the S3 driver.

Applications can use this capability check before requesting a temporary upload URL:

```php
<?php

use Illuminate\Support\Facades\Storage;

if (Storage::disk('s3')->providesTemporaryUploadUrls()) {
    $upload = Storage::disk('s3')->temporaryUploadUrl(
        'uploads/photo.jpg',
        now()->addMinutes(10),
    );
}
```

The fix is relevant to direct-to-S3 upload flows that conditionally enable temporary upload URLs based on driver capabilities.

### SQS Queue Size Fallbacks Use Correct Operator Precedence

Laravel fixes operator precedence in SQS queue size fallback calculations.

Queue size information is often used by dashboards, scaling logic, alerts, and operational tooling. A precedence error in fallback logic can produce an incorrect value even when the queue itself is operating normally.

### TrustProxies Handles Multiple Proxies with at:*

The `TrustProxies` behavior for `at:*` is fixed when a request passes through multiple proxies.

This matters for applications behind several infrastructure layers, such as a CDN, load balancer, reverse proxy, ingress controller, or platform router. Correct proxy trust configuration affects the detected client IP, scheme, host, and secure request state.

Applications using multi-proxy deployments should verify forwarded header behavior after updating.

### JsonApiResource Resolves Closure Relationships Correctly

Laravel fixes relationships on `JsonApiResource` when the relationship is resolved through a closure.

The correction helps resource definitions that defer relationship resolution until serialization. The relationship should now be evaluated and represented consistently instead of being mishandled as the closure itself.

### Resource Name Guessing Avoids Namespace Collisions

`guessResourceName()` is fixed for a case where a class name is also a substring of a parent namespace segment.

For example, a resource class name could accidentally match part of a longer namespace segment. The corrected logic distinguishes the actual class name from text that merely appears elsewhere in the namespace.

### HTTP Client Header Lookup Is Case-Normalized

The header normalization improvement also resolves practical lookup bugs. Tests and middleware that inspect request headers should no longer depend on the exact capitalization used when the header was added.

### Dynamic Quiet Increment and Decrement Calls Are Fixed

The release fixes dynamic calls to `incrementEachQuietly()` and `decrementEachQuietly()`.

This correction ensures that the newly added model operations behave correctly through Eloquent's method forwarding mechanisms.

### Scheduler quarterlyOn Receives Additional Coverage

Laravel adds a test for the scheduler's `quarterlyOn()` method. This is not a new public API, but the additional coverage protects its existing date scheduling behavior from regressions.

### URI Stringable and Strict Email Rules Receive Coverage

The release adds tests for the URI `toStringable()` method and the Email validation rule's strict mode.

These changes do not introduce new syntax. They strengthen regression protection for existing behavior.

### Console Option Metadata Supports a Null Shortcut

`HasParameters::getOptions()` now reflects that the shortcut field may be `null` in its returned array type.

The change improves type correctness for console command metadata and tools that analyze Artisan command definitions.

### Storage append() and prepend() Docblocks Include separator

The Storage facade docblocks now include the existing `$separator` parameter for `append()` and `prepend()`:

```php
<?php

use Illuminate\Support\Facades\Storage;

Storage::append('logs/activity.log', 'New entry', PHP_EOL);
Storage::prepend('logs/activity.log', 'Log started', PHP_EOL);
```

This is a documentation and IDE support correction. The separator capability already exists on the filesystem adapter, but the facade metadata now represents it accurately.

## Should You Upgrade to Laravel 13.20.0? {#should-you-upgrade-to-laravel-13-20-0}

Laravel 13.20.0 is a minor framework release, but it contains enough public API changes and bug fixes to justify evaluation.

The release is especially relevant when your application:

- Processes uploaded images or generates thumbnails.
- Uses Storage fakes for temporary file workflows.
- Has complex queue tests that need lifecycle control.
- Asserts exact queued mailable counts.
- Maintains several counters on Eloquent models.
- Stores sessions in Redis.
- Uses controller middleware attributes.
- Uses queue overlap locks across several job types.
- Uses S3 temporary upload URLs.
- Monitors SQS queue size.
- Uses UUIDs or other custom Eloquent keys.
- Runs behind multiple trusted proxies.
- Formats very small numeric values.

Review the installed constraint first:

```bash
composer show laravel/framework
```

This command displays the installed framework version and package metadata.

Update the framework within the version constraints declared by the application:

```bash
composer update laravel/framework
```

After the update, run the full test suite:

```bash
php artisan test
```

A practical upgrade review should include:

- Confirming the PHP version is 8.3 or later.
- Reviewing the new image driver dependencies before using the Image API.
- Checking local PHP memory limits for GD or Imagick processing.
- Testing Cloudflare image latency and cleanup when using the remote driver.
- Verifying Storage, S3, Redis, SQS, and proxy configuration in a staging environment.
- Reviewing application code that relies on empty `Str::containsAll()` input.
- Checking numeric displays that previously rendered tiny values as `-0`.
- Running static analysis after the getter and return type improvements.
- Running the complete automated test suite, not only tests related to the new features.

You do not need to adopt every new API immediately. Updating the framework can still provide the bug fixes, while image processing or the new testing helpers can be introduced when a suitable application requirement appears.

## Conclusion {#conclusion}

Laravel 13.20.0 is a notable minor release because it adds a complete framework-level image processing abstraction while also improving several everyday development and testing workflows. The image component will receive the most attention, but the Storage, Queue Fake, Mail Fake, Eloquent, Redis, middleware, and production fixes are also valuable.

The most important takeaways are:

- **First-party image processing.** Laravel now provides an immutable and driver-based API for loading, transforming, converting, inspecting, and storing images.
- **Three image drivers.** Applications can process locally with GD or Imagick, or remotely through Cloudflare Images.
- **Safer image variants.** Immutable transformations make it easier to create thumbnails, large images, and visual variants from one source.
- **More expressive filesystem tests.** `assertEmpty()` confirms that an entire storage disk contains no files.
- **Better queue test control.** `beforePushing()` and `afterPushing()` let tests react around fake queue pushes without extending `QueueFake`.
- **Exact queued mail assertions.** `MailFake::assertQueuedTimes()` is now publicly available.
- **Quiet multi-column updates.** Eloquent can increment or decrement several attributes without dispatching model events.
- **Attribute-based middleware exclusion.** `#[WithoutMiddleware]` complements the existing controller `#[Middleware]` attribute.
- **Redis session isolation.** A dedicated session prefix helps separate sessions from cache and other Redis data.
- **Important maintenance fixes.** The release corrects edge cases involving strings, numbers, images, custom relationship keys, S3, SQS, trusted proxies, resources, headers, and migration timestamps.
