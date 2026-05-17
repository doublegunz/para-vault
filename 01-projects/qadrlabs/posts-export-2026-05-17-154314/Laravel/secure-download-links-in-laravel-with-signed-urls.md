---
title: "Secure Download Links in Laravel with Signed URLs"
slug: "secure-download-links-in-laravel-with-signed-urls"
category: "Laravel"
date: "2026-05-02"
status: "published"
---

When you need to protect a file download, the simplest approach is to put the filename directly in the URL: `/download?file=laravel-guide.pdf`. The problem is that this approach has no protection whatsoever. Anyone who can guess a filename can access the file, and anyone who holds a link can share it freely, forever. Even if you move the logic into a route parameter like `/ebooks/1/download`, a curious user can simply change the `1` to a `2` and attempt to access someone else's purchase.

The consequence of this is real. If you are selling digital products such as ebooks, invoice PDFs, or course materials, an unprotected download route is a security hole that undercuts your entire business model. You cannot enforce ownership, you cannot control distribution, and you cannot set expiration windows on access.

Laravel's Signed URLs solve this at the framework level. Every signed URL carries a cryptographic signature computed from the full URL string and your `APP_KEY`. If anyone changes any part of the URL: the route parameters, the query string, or even a single character, the signature will not match and Laravel will refuse the request with a 403. You can also embed an expiration timestamp that Laravel checks automatically. Once the window closes, the link simply stops working.

## Overview {#overview}

In this tutorial, you will build **EbookHub**, a minimal digital download platform that demonstrates signed URLs in a realistic context. The core mechanic is straightforward: a user requests a download link for an ebook, the system generates a temporary signed URL valid for 24 hours, and the download route validates that signature automatically before serving the file.

### What You'll Build

- An `Ebook` model backed by a database table and local file storage
- A controller with three methods: one to list ebooks, one to generate a signed download URL, and one to serve the file
- Three views: a library page, a "your link is ready" page, and a friendly error page for expired or tampered links
- A custom exception handler that intercepts `InvalidSignatureException` and renders a human-readable error instead of Laravel's generic 403 page
- Six Pest tests covering the full range of valid and invalid link scenarios

### What You'll Learn

- The difference between `URL::signedRoute()` (no expiration) and `URL::temporarySignedRoute()` (expires at a given time)
- How the `signed` middleware automates signature validation on protected routes
- How to customize the error page shown when a signed URL is invalid or expired
- How to use `$request->hasValidSignature()` as a manual alternative to middleware when you need more control
- How to test signed URLs in Pest, including simulating expired and tampered links

### What You'll Need

- PHP 8.3 or higher
- Laravel 13
- Composer
- Familiarity with Laravel routing, Eloquent models, and Blade views
- Basic knowledge of Pest for the testing section

## Step 1: Create the Ebook Model and Migration {#step-1-create-the-ebook-model-and-migration}

The foundation of EbookHub is an `Ebook` model representing a digital product available in the library. You will generate the model, migration, factory, and controller all at once using Artisan's shorthand flags.

Run this command from your project root:

```bash
php artisan make:model Ebook -mfc
```

The `-m` flag creates the migration, `-f` creates the factory, and `-c` creates the plain controller. Next, create the seeder separately:

```bash
php artisan make:seeder EbookSeeder
```

### Edit the Migration

Open `database/migrations/xxxx_xx_xx_xxxxxx_create_ebooks_table.php` and define the table structure:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ebooks', function (Blueprint $table) {
            $table->id();
            $table->string('title');

            // A URL-friendly identifier used for route model binding.
            // Using a slug instead of a numeric ID keeps URLs readable
            // and avoids leaking the sequential ID of your records.
            $table->string('slug')->unique();

            // The filename of the PDF stored in storage/app/private/
            $table->string('file_path');

            $table->text('description')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ebooks');
    }
};
```

### Edit the Model

Open `app/Models/Ebook.php` and configure it for route model binding by slug. In Laravel 13, mass-assignable attributes are declared with the `#[Fillable]` attribute rather than a `$fillable` property:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['title', 'slug', 'file_path', 'description'])]
class Ebook extends Model
{
    use HasFactory;

    // By default, route model binding resolves records by their primary key (id).
    // Returning 'slug' here tells Laravel to look up ebooks by the slug column
    // instead. A route like /ebooks/{ebook} will query WHERE slug = '{ebook}'.
    public function getRouteKeyName(): string
    {
        return 'slug';
    }
}
```

### Run the Migration

```bash
php artisan migrate
```

You should see output confirming the `ebooks` table was created:

```
   INFO  Running migrations.

  2025_01_01_000000_create_ebooks_table ......................................... 9ms DONE
```

## Step 2: Create the Factory and Seed Sample Data {#step-2-create-the-factory-and-seed-sample-data}

Before writing the download logic, you need some ebooks in the database and corresponding files on disk. The factory handles random data generation for automated tests, while the seeder populates the database with realistic entries for manual testing in the browser.

### Edit the Factory

Open `database/factories/EbookFactory.php`:

```php
<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

class EbookFactory extends Factory
{
    public function definition(): array
    {
        // Generate a random three-word phrase for the title.
        // Str::slug() converts it to a URL-safe format for the slug
        // and file_path columns.
        $title = $this->faker->words(nb: 3, asText: true);

        return [
            'title'       => ucwords($title),
            'slug'        => Str::slug($title),
            'file_path'   => Str::slug($title) . '.pdf',
            'description' => $this->faker->sentence(nbWords: 12),
        ];
    }
}
```

### Edit the Seeder

Open `database/seeders/EbookSeeder.php`. The seeder creates three realistic ebooks and writes a placeholder file to `storage/app/private/` for each one, so the download route has something to serve during development:

```php
<?php

namespace Database\Seeders;

use App\Models\Ebook;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Storage;

class EbookSeeder extends Seeder
{
    public function run(): void
    {
        $ebooks = [
            [
                'title'       => 'Laravel for Beginners',
                'slug'        => 'laravel-for-beginners',
                'file_path'   => 'laravel-for-beginners.pdf',
                'description' => 'A complete guide to getting started with the Laravel framework.',
            ],
            [
                'title'       => 'Mastering Eloquent ORM',
                'slug'        => 'mastering-eloquent-orm',
                'file_path'   => 'mastering-eloquent-orm.pdf',
                'description' => 'Deep dive into Eloquent relationships, scopes, and advanced queries.',
            ],
            [
                'title'       => 'API Development with Laravel',
                'slug'        => 'api-development-with-laravel',
                'file_path'   => 'api-development-with-laravel.pdf',
                'description' => 'Build robust RESTful APIs using Laravel Sanctum and resources.',
            ],
        ];

        foreach ($ebooks as $data) {
            Ebook::create($data);

            // Storage::disk('local') writes to storage/app/private/ in Laravel 13.
            // We place a text placeholder here so the download controller has a
            // real file to serve. In production, replace this with your actual PDF.
            Storage::disk('local')->put(
                $data['file_path'],
                "Placeholder for: {$data['title']}\n\nReplace this file with a real PDF in production."
            );
        }
    }
}
```

Now wire the seeder into `database/seeders/DatabaseSeeder.php`:

```php
public function run(): void
{
    $this->call(EbookSeeder::class);
}
```

Run the seeder:

```bash
php artisan db:seed
```

Expected output:

```
   INFO  Seeding database.

  Database\Seeders\EbookSeeder .................................................. RUNNING
  Database\Seeders\EbookSeeder .................................................. DONE
```

At this point your database has three ebook records, and each one has a corresponding file in `storage/app/private/`.

## Step 3: Build the Download Controller {#step-3-build-the-download-controller}

The controller is the heart of this tutorial. It contains three methods: `index()` to list all ebooks, `generate()` to produce a temporary signed URL, and `download()` to validate the signature (via middleware) and serve the file. Open `app/Http/Controllers/EbookController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Ebook;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class EbookController extends Controller
{
    /**
     * Show the full list of ebooks with a "Get Download Link" button for each.
     */
    public function index(): View
    {
        $ebooks = Ebook::all();

        return view('ebooks.index', compact('ebooks'));
    }

    /**
     * Generate a temporary signed download URL for the given ebook.
     *
     * URL::temporarySignedRoute() embeds two extra query parameters into the URL:
     *   - 'expires': a Unix timestamp marking when the link stops being valid
     *   - 'signature': an HMAC-SHA256 hash of the full URL computed with APP_KEY
     *
     * Because the signature covers the entire URL string (path plus all query
     * parameters), any modification — changing the slug, altering 'expires',
     * or tweaking the signature itself — will produce a hash mismatch and a 403.
     */
    public function generate(Ebook $ebook): View
    {
        // Set the expiry window. The link will stop working 24 hours from now.
        $expiresAt = now()->addHours(24);

        $downloadUrl = URL::temporarySignedRoute(
            'ebooks.download',        // The named route this URL points to
            $expiresAt,               // A Carbon instance or DateTime object
            ['ebook' => $ebook->slug] // Route parameters baked into the signature
        );

        return view('ebooks.link', compact('ebook', 'downloadUrl', 'expiresAt'));
    }

    /**
     * Serve the ebook file.
     *
     * By the time execution reaches this method, the 'signed' middleware on
     * this route has already performed two checks:
     *   1. Does the 'signature' parameter match a fresh hash of the current URL?
     *   2. Has the 'expires' timestamp already passed?
     *
     * If either check fails, the middleware returns a 403 and this method never
     * runs. We do not need to call $request->hasValidSignature() here.
     */
    public function download(Request $request, Ebook $ebook): BinaryFileResponse
    {
        // Resolve the absolute filesystem path using the local disk helper.
        // In Laravel 13, Storage::disk('local') roots at storage/app/private/.
        $filePath = Storage::disk('local')->path($ebook->file_path);

        // This is a file-existence check, not a security check.
        // If a record exists in the database but its file was accidentally deleted
        // from disk, we return a 404 rather than crashing with an exception.
        abort_unless(file_exists($filePath), 404, 'The requested file could not be found.');

        // response()->download() sends the file with Content-Disposition: attachment,
        // so the browser prompts a Save dialog rather than displaying the content inline.
        // The second argument sets the filename the user sees in that dialog.
        return response()->download($filePath, $ebook->title . '.pdf');
    }
}
```

## Step 4: Register the Routes and Configure the Error Handler {#step-4-register-the-routes-and-configure-the-error-handler}

You need three routes and a custom exception handler. The routes themselves are straightforward, but the error handler deserves special attention. Without it, Laravel displays a generic 403 page when a signed URL fails validation. A custom view that explains the problem and offers a way forward makes a much better user experience.

### Define the Routes

Open `routes/web.php` and replace the default content:

```php
<?php

use App\Http\Controllers\EbookController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => redirect()->route('ebooks.index'));

// Lists all available ebooks.
Route::get('/ebooks', [EbookController::class, 'index'])
    ->name('ebooks.index');

// Generates a new signed download URL for a specific ebook.
// In a production application you would guard this route with
// authentication and a purchase check. We keep it public here
// to stay focused on the signed URL mechanics.
Route::get('/ebooks/{ebook}/generate', [EbookController::class, 'generate'])
    ->name('ebooks.generate');

// The download route is protected by the 'signed' middleware.
// Laravel registers 'signed' as an alias for ValidateSignature automatically
// in Laravel 11 and later; you do not need to add anything to a kernel.
// Any request without a valid, unexpired signature receives a 403 response.
Route::get('/ebooks/{ebook}/download', [EbookController::class, 'download'])
    ->name('ebooks.download')
    ->middleware('signed');
```

### Configure the Custom Error Page

When a signed URL fails validation, Laravel throws an `InvalidSignatureException`. In Laravel 13, you register exception renderers inside the `withExceptions` closure in `bootstrap/app.php`. Open that file and add the handler:

```php
<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Routing\Exceptions\InvalidSignatureException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        //
    })
    ->withExceptions(function (Exceptions $exceptions) {
        // Intercept InvalidSignatureException and render a friendly view.
        // This fires whenever the 'signed' middleware rejects a request,
        // regardless of whether the URL was expired or tampered with.
        $exceptions->render(function (InvalidSignatureException $e, Request $request) {
            return response()->view('errors.link-expired', [], 403);
        });
    })->create();
```

## Step 5: Create the Views {#step-5-create-the-views}

EbookHub needs three views. Each one is a standalone HTML file with Tailwind loaded from CDN, so there is no layout inheritance to manage.

### The Library Index Page

Create `resources/views/ebooks/index.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EbookHub - Digital Library</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold text-gray-900 mb-1">EbookHub</h1>
        <p class="text-gray-500 text-sm mb-6">
            Click "Get Download Link" to receive a secure link valid for 24 hours.
        </p>

        <div class="space-y-4">
            @foreach ($ebooks as $ebook)
                <div class="border border-gray-200 rounded-lg p-4 flex items-start justify-between gap-4">
                    <div>
                        <h2 class="font-semibold text-gray-800">{{ $ebook->title }}</h2>
                        <p class="text-sm text-gray-500 mt-1">{{ $ebook->description }}</p>
                    </div>
                    <a href="{{ route('ebooks.generate', $ebook) }}"
                       class="shrink-0 bg-blue-600 text-white text-sm font-medium px-4 py-2 rounded hover:bg-blue-700 transition">
                        Get Download Link
                    </a>
                </div>
            @endforeach
        </div>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com"
               class="text-blue-600 hover:text-blue-800 hover:underline transition"
               target="_blank">Tutorial Signed URLs at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

### The Download Link Page

Create `resources/views/ebooks/link.blade.php`. This view receives `$ebook`, `$downloadUrl`, and `$expiresAt` from the controller:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Your Download Link - EbookHub</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex items-center gap-2 mb-4">
            <svg class="w-6 h-6 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <h1 class="text-xl font-bold text-gray-900">Your download link is ready</h1>
        </div>

        <p class="text-gray-600 mb-3">
            Here is your secure download link for <strong>{{ $ebook->title }}</strong>.
        </p>

        {{-- $expiresAt is a Carbon instance passed from the controller. --}}
        <div class="text-sm text-amber-700 bg-amber-50 border border-amber-200 rounded px-3 py-2 mb-6">
            This link expires on
            <strong>{{ $expiresAt->format('D, d M Y \a\t H:i T') }}</strong>.
            Do not share it with others.
        </div>

        <a href="{{ $downloadUrl }}"
           class="inline-flex items-center gap-2 bg-blue-600 text-white font-semibold px-6 py-3 rounded-lg hover:bg-blue-700 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
            </svg>
            Download {{ $ebook->title }}
        </a>

        <div class="mt-6 pt-4 border-t border-gray-100">
            <a href="{{ route('ebooks.index') }}" class="text-sm text-blue-600 hover:underline">
                &larr; Back to library
            </a>
        </div>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com"
               class="text-blue-600 hover:text-blue-800 hover:underline transition"
               target="_blank">Tutorial Signed URLs at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

### The Link Expired Error Page

Create `resources/views/errors/link-expired.blade.php`. This view is rendered by the exception handler you registered in `bootstrap/app.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Link Expired - EbookHub</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md text-center">
        <div class="flex justify-center mb-4">
            <svg class="w-16 h-16 text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                      d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0
                         2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898
                         0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"/>
            </svg>
        </div>

        <h1 class="text-2xl font-bold text-gray-900 mb-2">This link has expired</h1>
        <p class="text-gray-500 mb-6">
            The download link you followed is no longer valid. It may have expired after 24 hours
            or been modified. Please return to the library and request a new one.
        </p>

        <a href="{{ route('ebooks.index') }}"
           class="inline-block bg-blue-600 text-white font-semibold px-6 py-3 rounded-lg hover:bg-blue-700 transition">
            Back to Library
        </a>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com"
               class="text-blue-600 hover:text-blue-800 hover:underline transition"
               target="_blank">Tutorial Signed URLs at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

## Step 6: Try It Out {#step-6-try-it-out}

With all the pieces in place, start your development server and run through three scenarios to see signed URLs at work:

```bash
php artisan serve
```

### Scenario A: Generate and Use a Valid Link

Navigate to `http://localhost:8000/ebooks`. You should see the three ebooks from the seeder. Click "Get Download Link" next to "Laravel for Beginners". The controller calls `URL::temporarySignedRoute()` and you land on the link page, which shows a URL similar to this:

```
http://localhost:8000/ebooks/laravel-for-beginners/download?expires=1714384800&signature=3a9f2c...
```

Notice the two query parameters appended by Laravel. The `expires` parameter holds a Unix timestamp 24 hours from now, and the `signature` parameter holds the cryptographic hash. Click the download button. The browser triggers a file download prompt for `Laravel for Beginners.pdf`. The server served the file because the middleware confirmed the signature was intact and the expiry had not passed.

### Scenario B: Use a Tampered Link

Copy the URL from the link page and paste it into your browser's address bar. Now manually change `laravel-for-beginners` in the path to `mastering-eloquent-orm`, keeping the `signature` and `expires` parameters unchanged. Press Enter. You should see the "This link has expired" error page.

What happened is straightforward: the signature was originally computed from a URL containing `laravel-for-beginners`. When you changed the slug, the URL reaching the server no longer matched the stored hash. Laravel's validation failed, threw `InvalidSignatureException`, and your exception handler rendered the custom error view.

### Scenario C: Use an Expired Link

To test expiry without waiting 24 hours, temporarily change the controller's `generate()` method to use a very short window:

```php
// Temporarily shorten the expiry for testing only
$expiresAt = now()->addSeconds(5);
```

Generate a new link, copy the URL from the link page, wait six seconds, then paste the URL into a new browser tab. You will see the expired link error page. Remember to revert the expiry back to `addHours(24)` after testing.

## Step 7: Write the Pest Tests {#step-7-write-the-pest-tests}

Automated tests are particularly valuable for signed URL logic because they let you simulate edge cases — expired links, tampered parameters — without manual URL manipulation in the browser. The key tool is `URL::temporarySignedRoute()` called directly inside your test, which lets you generate URLs with fully controlled expiry times.

If you do not yet have Pest installed, run:

```bash
composer remove phpunit/phpunit
composer require pestphp/pest --dev --with-all-dependencies
./vendor/bin/pest --init
```

Create the test file:

```bash
php artisan make:test EbookDownloadTest
```

Open `tests/Feature/EbookDownloadTest.php` and replace its contents:

```php
<?php

use App\Models\Ebook;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;

uses(RefreshDatabase::class);

// Replace the local disk with a fake in-memory version before each test.
// This prevents tests from reading or writing real files in storage/app/private/,
// and ensures every test starts with a clean slate.
beforeEach(function () {
    Storage::fake('local');
});

it('shows all ebooks on the index page', function () {
    Ebook::factory()->count(3)->create();

    $this->get(route('ebooks.index'))
        ->assertOk()
        ->assertViewIs('ebooks.index')
        ->assertViewHas('ebooks');
});

it('generates a temporary signed URL when a download link is requested', function () {
    $ebook = Ebook::factory()->create();

    $this->get(route('ebooks.generate', $ebook))
        ->assertOk()
        ->assertViewIs('ebooks.link')
        ->assertViewHas('downloadUrl', function (string $url) {
            // A valid temporary signed URL must contain both query parameters.
            // 'expires' is the Unix timestamp and 'signature' is the hash.
            return str_contains($url, 'expires=') && str_contains($url, 'signature=');
        });
});

it('allows a file download when the signed URL is valid', function () {
    $ebook = Ebook::factory()->create(['file_path' => 'test-ebook.pdf']);

    // Put a placeholder file on the fake disk before the request.
    // Without this, the controller's abort_unless(file_exists(...)) check
    // would return a 404 before we even reach the signature validation logic.
    Storage::disk('local')->put('test-ebook.pdf', 'Dummy PDF content');

    $validUrl = URL::temporarySignedRoute(
        'ebooks.download',
        now()->addHours(24),
        ['ebook' => $ebook->slug]
    );

    $this->get($validUrl)->assertOk();
});

it('rejects a download request that has no signature at all', function () {
    $ebook = Ebook::factory()->create();

    // route() generates a plain URL with no 'signature' or 'expires' parameters,
    // so the middleware will reject it immediately.
    $this->get(route('ebooks.download', $ebook))->assertStatus(403);
});

it('rejects a download request with an expired signed URL', function () {
    $ebook = Ebook::factory()->create();

    // now()->subHour() produces a timestamp one hour in the past,
    // so this URL was already expired the moment it was generated.
    $expiredUrl = URL::temporarySignedRoute(
        'ebooks.download',
        now()->subHour(),
        ['ebook' => $ebook->slug]
    );

    $this->get($expiredUrl)->assertStatus(403);
});

it('rejects a download request with a tampered slug', function () {
    $ebook1 = Ebook::factory()->create(['slug' => 'original-ebook']);
    $ebook2 = Ebook::factory()->create(['slug' => 'another-ebook']);

    // Generate a legitimately signed URL for the first ebook.
    $signedUrl = URL::temporarySignedRoute(
        'ebooks.download',
        now()->addHours(24),
        ['ebook' => $ebook1->slug]
    );

    // Replace the slug in the URL to point at the second ebook while keeping
    // the original signature. This simulates an attacker trying to use someone
    // else's download link.
    $tamperedUrl = str_replace('original-ebook', 'another-ebook', $signedUrl);

    // The signature now refers to a URL that no longer matches the actual URL,
    // so Laravel detects the mismatch and rejects the request.
    $this->get($tamperedUrl)->assertStatus(403);
});
```

Run the tests:

```bash
./vendor/bin/pest tests/Feature/EbookDownloadTest.php
```

Expected output:

```
   PASS  Tests\Feature\EbookDownloadTest
  ✓ shows all ebooks on the index page                                     0.15s
  ✓ generates a temporary signed URL when a download link is requested     0.08s
  ✓ allows a file download when the signed URL is valid                    0.06s
  ✓ rejects a download request that has no signature at all                0.05s
  ✓ rejects a download request with an expired signed URL                  0.04s
  ✓ rejects a download request with a tampered slug                        0.05s

  Tests:  6 passed (6 assertions)
  Duration: 0.55s
```

All six pass. Each test runs in isolation because `beforeEach` replaces the local disk with a fresh fake before every case.

## How Signed URLs Work Under the Hood {#how-signed-urls-work-under-the-hood}

Understanding the mechanics helps you reason about edge cases and design your implementation with confidence.

When you call `URL::temporarySignedRoute('ebooks.download', $expiresAt, ['ebook' => $ebook->slug])`, Laravel performs the following steps. First, it builds the full URL as it normally would, with the path and route parameters assembled. Then it appends the `expires` parameter as a Unix timestamp. At this point the URL looks like:

```
http://localhost:8000/ebooks/laravel-for-beginners/download?expires=1714384800
```

Next, Laravel sorts all of the URL's query parameters alphabetically to ensure a consistent order regardless of how they were assembled. It then computes an HMAC-SHA256 hash of the full URL string using your `APP_KEY` as the secret key. This hash becomes the `signature` parameter. The final URL looks like:

```
http://localhost:8000/ebooks/laravel-for-beginners/download?expires=1714384800&signature=3a9f2c...
```

When a request arrives at the `signed` middleware, Laravel reconstructs the expected hash: it removes the `signature` parameter from the incoming URL, sorts the remaining parameters, and runs the same HMAC-SHA256 operation with `APP_KEY`. If the computed hash matches the `signature` in the request, the URL is authentic. If not, `InvalidSignatureException` is thrown. For temporary URLs, the middleware also checks whether `now()->timestamp` is still less than the `expires` value.

The security guarantee rests on two properties. First, without knowing `APP_KEY`, it is computationally infeasible to produce a valid signature for any URL. Second, the hash covers the entire URL including the `expires` timestamp, so an attacker cannot extend the expiry by editing that parameter: doing so would immediately invalidate the signature.

One practical implication is worth calling out explicitly. If you ever rotate your `APP_KEY`, all previously generated signed URLs become invalid instantly. This is particularly important if you use permanent signed URLs (without expiry) for things like unsubscribe links embedded in emails sent months ago.

## Signed URLs Without Expiration {#signed-urls-without-expiration}

The tutorial has focused on `URL::temporarySignedRoute()`, but Laravel also provides `URL::signedRoute()` for situations where you want tamper protection without a time limit. The most common use case is a one-click unsubscribe link included in a newsletter email. The link should work forever — if a user finds a six-month-old email and clicks unsubscribe, that action should still succeed — but you must ensure that nobody can craft a URL that unsubscribes a different user by modifying the `id` parameter.

Here is how you would implement that:

```php
// In a Mailable or Notification class
use Illuminate\Support\Facades\URL;

// Generate a permanent signed URL. There is no 'expires' parameter, so the
// link works indefinitely. The signature still prevents parameter tampering.
$unsubscribeUrl = URL::signedRoute('newsletter.unsubscribe', ['user' => $user->id]);
```

The corresponding route uses the same `signed` middleware:

```php
Route::get('/newsletter/unsubscribe/{user}', [NewsletterController::class, 'unsubscribe'])
    ->name('newsletter.unsubscribe')
    ->middleware('signed');
```

The middleware works identically here. The only difference from the temporary variant is the absence of the `expires` check: the signature still protects the URL against manipulation, but the link has no built-in expiry.

If you need even more control — for example, you want to log the unsubscribe attempt before deciding how to respond — you can skip the middleware entirely and validate manually inside the controller using `$request->hasValidSignature()`:

```php
public function unsubscribe(Request $request, User $user): RedirectResponse
{
    // hasValidSignature() returns a boolean, giving you the flexibility
    // to handle the failure however you choose rather than relying on
    // the middleware's automatic 403 response.
    if (! $request->hasValidSignature()) {
        abort(403, 'This link is invalid.');
    }

    // You can run custom logic here before acting on the request.
    $user->unsubscribeFromNewsletter();

    return redirect('/')->with('success', 'You have been unsubscribed.');
}
```

There is also `$request->hasValidSignatureWhileIgnoring(['page', 'order'])` for cases where your frontend appends its own query parameters to a signed URL (for instance, client-side pagination). Parameters listed in `hasValidSignatureWhileIgnoring()` are excluded from the hash comparison, so they can be appended freely without breaking the signature.

## Conclusion {#conclusion}

Signed URLs are one of those Laravel features that feel almost too simple for how much security they provide. With two method calls and one middleware alias, you get cryptographic tamper protection and time-limited access on any route in your application. Here are the key takeaways from this tutorial:

- **`URL::temporarySignedRoute()` is for time-limited access.** Use it for download links, password reset links, or any URL that should stop working after a defined window. The `expires` timestamp is embedded in and covered by the signature, so it cannot be extended without invalidating the URL.
- **`URL::signedRoute()` is for permanent tamper-proof links.** Use it for unsubscribe links, email confirmation links, or any URL that should be valid indefinitely but must not allow parameter manipulation.
- **The `signed` middleware automates validation.** Attach `->middleware('signed')` to your route and Laravel handles the signature and expiry check before your controller ever runs. Reach for `$request->hasValidSignature()` only when you need custom failure handling inside the controller.
- **`InvalidSignatureException` is catchable.** Register a renderer in `bootstrap/app.php` to replace Laravel's generic 403 page with a user-friendly view that explains the situation and offers a path forward.
- **`APP_KEY` is the root of trust.** The signature's security depends entirely on `APP_KEY` remaining secret and stable. Rotating the key invalidates all previously generated signed URLs across the board.
- **Testing signed URLs in Pest is straightforward.** Call `URL::temporarySignedRoute()` directly in your test to generate URLs with controlled expiry times, and use `now()->subHour()` to simulate expired links without any waiting.