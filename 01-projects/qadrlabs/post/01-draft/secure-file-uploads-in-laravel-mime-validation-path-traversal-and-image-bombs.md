# Secure File Uploads in Laravel: MIME Validation, Path Traversal, and Image Bombs

A file upload form looks like one of the simplest features you can build. You add an `<input type="file">`, write `mimes:jpg` in a validation rule, call `store()`, and ship it. The code passes review because it looks exactly like every upload tutorial on the internet, including our own [image upload tutorial](https://qadrlabs.com/post/laravel-13-add-image-upload-to-your-blog-with-storage-and-validation). It works in the demo, so it must be safe.

It is not safe. An attacker does not upload the file you expected. They upload a PHP web shell renamed to `avatar.jpg`, and if your server ever runs that file, they own your box. They upload a file named `../../public/index.php` and overwrite your application. They upload a 100 kilobyte PNG that decompresses into a 30,000 by 30,000 pixel canvas and watch your worker run out of memory the moment you try to resize it. None of these break the happy path, so none of them show up in the demo. They show up later, in production, in the logs you read after the incident.

The fix is not one magic rule. It is a short stack of independent defenses, each one closing a specific hole: validate the real file type and not just the name, store the file under a random name on a disk the public can never reach, rebuild the image from scratch to throw away anything hidden inside it, and serve it back through a temporary signed URL. In this tutorial we will build that hardened upload endpoint in Laravel 13 from an empty project, and then we will write a Pest test suite that fires each of these attacks at it and proves they fail.

## Overview {#overview}

We are going to build a single image upload feature the secure way, and we will explain the attack that each step defends against as we go. The application accepts an image, validates it on content rather than on its claimed name, re-encodes it through a fresh canvas to strip any embedded payload, saves it with a random filename on a private disk, and hands the user a signed link that expires. Every layer is small on its own, and together they remove the entire class of upload vulnerabilities.

### What You'll Build

- An upload form backed by an `UploadController` and a dedicated Form Request.
- A validation rule chain that checks real MIME type, real file extension, image dimensions, and size.
- A private `uploads` disk that the browser cannot reach directly.
- Storage with a random UUID filename, so the client never controls the path on disk.
- An image re-encode step using Intervention Image that neutralizes disguised payloads and strips metadata.
- A download route protected by a temporary signed URL.
- A Pest suite of eight tests that fire real exploit payloads and assert they are rejected.

### What You'll Learn

- Why `mimes` and `extensions` check different things, and why the browser `Content-Type` header is worthless for security.
- How the `dimensions` rule stops decompression bombs before any image library touches the file.
- Why a private disk plus a random filename kills both direct execution and path traversal.
- How re-encoding an image with Intervention Image removes anything hidden in the original bytes.
- How to serve private files through `temporarySignedRoute` without building a full authentication system.
- How to write tests that prove an exploit fails, which is the only proof that actually counts.

### What You'll Need

- PHP 8.3 or higher and Composer.
- The GD or Imagick PHP extension, which Intervention Image needs to process images.
- Basic familiarity with Laravel file uploads. If you have never built one, read the [image upload tutorial](https://qadrlabs.com/post/laravel-13-add-image-upload-to-your-blog-with-storage-and-validation) first, because this article hardens the pattern it teaches.

## Step 1: Create the Laravel Project {#step-1-create-project}

Start from a clean Laravel 13 application so there is nothing else to distract from the upload code. Create the project with Pest already wired in:

```
laravel new secure-uploads-demo --no-interaction --database=sqlite --pest --no-boost
cd secure-uploads-demo
```

This gives you a fresh app using SQLite, which means there is no database server to configure. Confirm the framework version and run the default test suite to establish a baseline:

```
php artisan --version
php artisan test
```

You should see Laravel 13 and two passing example tests:

```
Laravel Framework 13.16.1

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response

  Tests:    2 passed (2 assertions)
  Duration: 0.17s
```

We will replace these example tests with our own security tests at the end, so you can delete the two `ExampleTest.php` files now or leave them until Step 10.

## Step 2: Configure a Private Disk {#step-2-private-disk}

Before we write any upload code, we decide where the files will live, because that decision is itself a security control. The single most common upload mistake is storing user files on the `public` disk and running `php artisan storage:link`. That makes every uploaded file reachable at a predictable URL like `http://yoursite.com/storage/avatar.php`. If an attacker manages to upload a PHP file there, the web server will happily execute it. A file the public web server can both reach and execute is a remote code execution waiting to happen.

The defense is to store uploads on a disk that lives outside the web root and has no public URL at all. Laravel 13 already ships a private `local` disk rooted at `storage/app/private`, but we will add a dedicated `uploads` disk so our intent is explicit and our files stay separated from anything else the app stores.

Open `config/filesystems.php`. You will find the existing `local` and `public` disks inside the `disks` array. Add a new `uploads` disk right after the `local` one:

```php
'local' => [
    'driver' => 'local',
    'root' => storage_path('app/private'),
    'serve' => true,
    'throw' => false,
    'report' => false,
],

'uploads' => [
    'driver' => 'local',
    'root' => storage_path('app/private/uploads'),
    'visibility' => 'private',
    'throw' => true,
    'report' => false,
],
```

Two settings here matter for security. The `root` points inside `storage/app/private`, which is never served by the web server, so there is no URL an attacker can guess to reach these files. We deliberately do not create a `storage:link` symlink for this disk, and that omission is the whole point. The `throw => true` option tells the disk to raise an exception on a failed operation instead of silently returning `false`, so a write that does not happen becomes a loud error rather than a quiet hole.

Save the file. There is nothing to run yet; this disk becomes active the moment we reference it.

## Step 3: Create the Upload Model and Migration {#step-3-model-migration}

We need a place to record each upload. We will not store the image bytes in the database; we will store the metadata and the path on disk. Generate a model with its migration in one command:

```
php artisan make:model Upload -m
```

```
 INFO  Model [app/Models/Upload.php] created successfully.

 INFO  Migration [database/migrations/2026_06_21_150542_create_uploads_table.php] created successfully.
```

Open the generated migration in `database/migrations`. Its filename starts with the current timestamp. Define the columns we need:

```php
public function up(): void
{
    Schema::create('uploads', function (Blueprint $table) {
        $table->id();
        $table->string('original_name');
        $table->string('path');
        $table->string('mime');
        $table->unsignedBigInteger('size');
        $table->timestamps();
    });
}
```

Each column has a job. `original_name` keeps the name the user's browser sent, which we use only as a friendly download filename and never as a path. `path` is the random location on disk where the file actually lives. `mime` records the type we re-encoded the file into, and `size` records the byte count after re-encoding. Notice that the database stores a path, never the file contents, and never trusts the original name as anything but a label.

Run the migration:

```
php artisan migrate
```

```
 INFO  Running migrations.

  2026_06_21_150542_create_uploads_table ..................... 10.08ms DONE
```

Now tell the model which fields may be mass assigned. Open `app/Models/Upload.php`. The generated class is empty. Add the `#[Fillable]` attribute, which is the Laravel 13 way to declare fillable fields directly on the class:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['original_name', 'path', 'mime', 'size'])]
class Upload extends Model
{
    //
}
```

We add the `Fillable` attribute so that the `Upload::create([...])` call in the controller is allowed to set these four columns. Without it, Laravel's mass assignment protection would block the insert. Save the file.

## Step 4: Build the Upload Form and Routes {#step-4-form-and-routes}

With storage and the model in place, we can build the user-facing parts: a controller, the routes, and a form. Generate the controller first so the file exists before we reference it:

```
php artisan make:controller UploadController
```

```
 INFO  Controller [app/Http/Controllers/UploadController.php] created successfully.
```

For now we only need the method that shows the form. Open `app/Http/Controllers/UploadController.php` and replace the empty class body with a `create` method:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class UploadController extends Controller
{
    /**
     * Show the upload form.
     */
    public function create()
    {
        return view('uploads.create');
    }
}
```

We start with just `create` so we have something to look at in the browser; we will add the `store` and `show` methods in the next steps as each defense is introduced. Save the file.

Next, register the routes. Open `routes/web.php` and add the three routes our feature needs:

```php
use App\Http\Controllers\UploadController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/uploads', [UploadController::class, 'create'])->name('uploads.create');
Route::post('/uploads', [UploadController::class, 'store'])->name('uploads.store');

// The signed middleware rejects any request whose signature is missing,
// altered, or expired, returning a 403 before the controller runs.
Route::get('/uploads/{upload}', [UploadController::class, 'show'])
    ->name('uploads.show')
    ->middleware('signed');
```

The `uploads.create` route shows the form, `uploads.store` receives the upload, and `uploads.show` serves a file back. The `signed` middleware on the show route is the access control for downloads, and we will explain it fully in Step 8. The `store` and `show` controller methods do not exist yet, so do not load those routes until we add them in the steps that follow.

Now create the form. Make the directory and file `resources/views/uploads/create.blade.php`. This is a standalone HTML page using the Tailwind CDN, so it does not depend on any layout:

```blade
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Secure Image Upload</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold mb-6">Upload an Image</h1>

        @if (session('uploaded_url'))
            <div class="mb-6 p-4 bg-green-50 border border-green-200 rounded-md">
                <p class="text-sm text-green-800 font-medium mb-1">Upload successful.</p>
                <a href="{{ session('uploaded_url') }}"
                    class="text-sm text-blue-600 hover:underline break-all" target="_blank">
                    {{ session('uploaded_url') }}
                </a>
                <p class="text-xs text-gray-500 mt-1">This signed link expires in 5 minutes.</p>
            </div>
        @endif

        @if ($errors->any())
            <div class="mb-6 p-4 bg-red-50 border border-red-200 rounded-md">
                <ul class="list-disc list-inside text-sm text-red-700">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('uploads.store') }}" method="POST" enctype="multipart/form-data" class="space-y-6">
            @csrf
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Image</label>
                <input type="file" name="image" accept="image/jpeg,image/png,image/webp"
                    class="w-full px-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500 outline-none transition text-sm file:mr-4 file:py-1 file:px-3 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100">
                <p class="text-xs text-gray-500 mt-1">JPG, PNG, or WebP. Max 2 MB and 2000x2000 pixels.</p>
            </div>

            <button type="submit"
                class="px-5 py-2 bg-blue-600 text-white text-sm font-semibold rounded-md hover:bg-blue-700 transition">
                Upload
            </button>
        </form>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Secure File Uploads in Laravel at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

Two attributes on the form deserve attention. The `enctype="multipart/form-data"` is required for the browser to send file bytes at all; without it the upload field arrives empty. The `accept` attribute on the input filters the file picker dialog to image types, which is a convenience for honest users and nothing more. It is a client-side hint that an attacker bypasses in seconds, which is exactly why the real validation lives on the server in the next step. Save the file.

## Step 5: Validate Real File Type, Extension, and Dimensions {#step-5-validation}

This is the first true security layer, and it is where most upload code goes wrong. A naive rule like `mimes:jpg` feels like validation but trusts the wrong things. We will put the rules in a dedicated Form Request so the controller stays clean. Generate it:

```
php artisan make:request StoreUploadRequest
```

```
 INFO  Request [app/Http/Requests/StoreUploadRequest.php] created successfully.
```

Open `app/Http/Requests/StoreUploadRequest.php`. The generated `authorize` method returns `false`, which would block every request, so change it to `true` and fill in the rules:

```php
public function authorize(): bool
{
    return true;
}

/**
 * Get the validation rules that apply to the request.
 *
 * @return array<string, ValidationRule|array<mixed>|string>
 */
public function rules(): array
{
    return [
        'image' => [
            'required',
            'file',
            'image',
            'mimes:jpg,jpeg,png,webp',
            'extensions:jpg,jpeg,png,webp',
            'dimensions:max_width=2000,max_height=2000',
            'max:2048',
        ],
    ];
}
```

Each rule in this chain blocks a different bypass, so it is worth understanding what each one actually inspects:

- `file` and `image` confirm the upload is a real file and that PHP can read it as an image. The `image` rule reads the file's contents and checks for valid image headers, so a text file renamed to `.jpg` fails here.
- `mimes:jpg,jpeg,png,webp` checks the MIME type that Laravel guesses by reading the file's bytes, not the `Content-Type` header the browser sent. The browser header is attacker-controlled and means nothing; this rule looks at the actual content.
- `extensions:jpg,jpeg,png,webp` checks the real, trailing file extension. This is a separate concern from `mimes`, and using both together is the point. A file named `shell.php.jpg` can be crafted so that one check passes, but it cannot satisfy a content check and an extension check that both demand an image at the same time.
- `dimensions:max_width=2000,max_height=2000` rejects images whose pixel dimensions are absurd. This is your first defense against a decompression bomb, a tiny compressed file that expands into an enormous canvas. Because Laravel reads only the image header to learn the dimensions, this rule rejects the bomb before any resizing code allocates memory for it.
- `max:2048` caps the upload at 2048 kilobytes, which is the coarse size limit on the raw bytes.

Notice that no single rule here is sufficient on its own. The `mimes` rule does not catch a malicious extension, the `extensions` rule does not catch malicious content, and neither catches an image bomb. Stacked together they cover each other's blind spots, which is what defense in depth means in practice. Save the file.

## Step 6: Store on a Private Disk with a Random Filename {#step-6-store-random-name}

Now we write the method that receives a valid upload and saves it. This step defends against path traversal, the attack where a malicious filename like `../../public/index.php` escapes the intended folder and overwrites a file somewhere else on the server. The defense is simple and absolute: never use any part of the client-supplied name to build the path on disk. We generate our own random name instead.

Open `app/Http/Controllers/UploadController.php` and add the imports and a `store` method. We will write the re-encode logic in the next step, so for now the method validates, generates a random name, and stores the raw file:

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreUploadRequest;
use App\Models\Upload;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Str;

class UploadController extends Controller
{
    /**
     * Show the upload form.
     */
    public function create()
    {
        return view('uploads.create');
    }

    /**
     * Validate and store the uploaded image.
     */
    public function store(StoreUploadRequest $request)
    {
        $file = $request->file('image');

        // Generate a random, server-controlled filename. We never reuse the
        // client supplied name, so "../../" path traversal is impossible. The
        // extension is derived from the file's content, not its claimed name.
        $filename = Str::uuid() . '.' . $file->guessExtension();
        $path = Storage::disk('uploads')->putFileAs('images', $file, $filename);

        $upload = Upload::create([
            'original_name' => $file->getClientOriginalName(),
            'path' => $path,
            'mime' => $file->getMimeType(),
            'size' => $file->getSize(),
        ]);

        return redirect()
            ->route('uploads.create')
            ->with('uploaded_url', URL::temporarySignedRoute(
                'uploads.show',
                now()->addMinutes(5),
                ['upload' => $upload->id]
            ));
    }
}
```

The important line is the path. We build it from `Str::uuid()`, a random value the attacker has no influence over, and we save the user's `getClientOriginalName()` only into the `original_name` column as a display label. Because the storage path is random and lives on the private `uploads` disk, a filename like `../../public/index.php` is harmless; it never becomes part of where the file is written. Compare this to the dangerous pattern `storeAs($folder, $file->getClientOriginalName())`, which hands the attacker direct control over the path and is the root cause of most path traversal bugs.

This version is already far safer than a typical upload handler, but it still writes the original bytes to disk. In the next step we replace that with a re-encode so that even a perfectly valid image cannot smuggle a payload through. Do not run anything yet; the `getMimeType()` and raw store here are temporary and get rewritten in Step 7. Save the file.

## Step 7: Re-encode the Image to Strip Hidden Payloads {#step-7-re-encode}

The validation in Step 5 confirms the file is a real image, but a file can be a perfectly valid image and still carry something nasty. A polyglot file is valid as two formats at once, for example a real GIF that is also a working PHP script, so it sails through an `image` check while still containing executable code. Images also carry EXIF metadata, which can leak a user's GPS location or hide a payload in a comment field. The cleanest way to destroy all of it is to never keep the uploaded bytes. We decode the image into raw pixels and encode a brand new file from those pixels. Anything that was not actual image data, the appended PHP, the metadata, the comment payload, does not survive the round trip.

Install Intervention Image, the standard PHP image processing library:

```
composer require intervention/image
```

```
Using version ^4.1 for intervention/image
```

This pulls in Intervention Image v4, which drives the GD or Imagick extension under the hood. Now rewrite the `store` method in `app/Http/Controllers/UploadController.php` to decode and re-encode the image instead of storing the raw upload. Update the imports at the top of the file to add the three Intervention classes:

```php
use App\Http\Requests\StoreUploadRequest;
use App\Models\Upload;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Str;
use Intervention\Image\Drivers\Gd\Driver;
use Intervention\Image\Encoders\WebpEncoder;
use Intervention\Image\ImageManager;
```

Then replace the body of the `store` method. Here is the old version from Step 6, which stored the raw file:

```php
$file = $request->file('image');

// Generate a random, server-controlled filename. We never reuse the
// client supplied name, so "../../" path traversal is impossible. The
// extension is derived from the file's content, not its claimed name.
$filename = Str::uuid() . '.' . $file->guessExtension();
$path = Storage::disk('uploads')->putFileAs('images', $file, $filename);

$upload = Upload::create([
    'original_name' => $file->getClientOriginalName(),
    'path' => $path,
    'mime' => $file->getMimeType(),
    'size' => $file->getSize(),
]);
```

Replace it with this version, which rebuilds the image before storing it:

```php
$file = $request->file('image');

// Re-encode the image through a fresh GD canvas. This rebuilds the
// pixels from scratch, so any PHP code, EXIF metadata, or polyglot
// payload glued onto the original bytes is discarded. A malformed or
// booby-trapped file throws here and never reaches storage.
$manager = new ImageManager(new Driver());
$image = $manager->decode($file->getRealPath());
$image->scaleDown(width: 2000, height: 2000);
$encoded = $image->encode(new WebpEncoder(quality: 80));

// Generate a random, server-controlled filename. We never reuse the
// client supplied name, so "../../" path traversal is impossible.
$path = 'images/' . Str::uuid() . '.webp';
Storage::disk('uploads')->put($path, (string) $encoded);

$upload = Upload::create([
    'original_name' => $file->getClientOriginalName(),
    'path' => $path,
    'mime' => 'image/webp',
    'size' => Storage::disk('uploads')->size($path),
]);
```

Walk through what changed. We create an `ImageManager` on the GD driver and call `decode()` to read the uploaded file into an in-memory image. If the file is not a real, parseable image, `decode()` throws and the request fails before anything is written, which is exactly the behavior we want. `scaleDown(width: 2000, height: 2000)` shrinks anything larger than our bounds while leaving smaller images untouched, a second guard against oversized canvases on top of the `dimensions` rule. Then `encode(new WebpEncoder(quality: 80))` produces a completely new WebP file from the decoded pixels. We store those new bytes, set the `mime` to `image/webp` because that is what we actually wrote, and read the size back from disk. The original uploaded bytes are never saved, so whatever was hiding in them is gone.

We chose the GD driver because it ships with most PHP installations. If your server has the Imagick extension instead, swap `Intervention\Image\Drivers\Gd\Driver` for `Intervention\Image\Drivers\Imagick\Driver` and everything else stays the same. Save the file.

## Step 8: Serve Files Through a Temporary Signed URL {#step-8-signed-url}

Our files now sit on a private disk with no public URL, which is great for security but means the browser cannot load them. We need a controlled way to serve a file to someone who is allowed to see it, without exposing the whole disk to the world. A temporary signed URL does exactly this. Laravel appends a cryptographic signature to the URL, and the `signed` middleware we attached to the `uploads.show` route in Step 4 rejects any request whose signature is missing, altered, or expired. This gives us access control with no login system, and the same idea powers our [secure download links tutorial](https://qadrlabs.com/post/secure-download-links-in-laravel-with-signed-urls).

The `store` method already generates the link. Look again at the redirect at the end of it:

```php
return redirect()
    ->route('uploads.create')
    ->with('uploaded_url', URL::temporarySignedRoute(
        'uploads.show',
        now()->addMinutes(5),
        ['upload' => $upload->id]
    ));
```

`URL::temporarySignedRoute` builds a URL to the `uploads.show` route that is valid for five minutes and carries a signature derived from your application key. Change a single character of the URL, or wait past the five minutes, and the signature no longer matches.

Now add the `show` method that actually serves the file. Append it to `app/Http/Controllers/UploadController.php` after the `store` method:

```php
/**
 * Serve a stored file behind a temporary signed URL.
 */
public function show(Request $request, Upload $upload)
{
    return Storage::disk('uploads')->download($upload->path, $upload->original_name);
}
```

By the time this method runs, the `signed` middleware has already verified the signature, so we know the request is legitimate. We look up the `Upload` record, read the file from the private `uploads` disk, and stream it back as a download named after the original filename the user uploaded. The actual stored file keeps its random UUID name on disk; the friendly name is only the label in the download dialog. Save the file.

## Step 9: Try It Out {#step-9-try-it-out}

Start the development server:

```
php artisan serve
```

Open `http://127.0.0.1:8000/uploads` in your browser and try each scenario.

### Upload a Valid Image

Pick a normal JPG or PNG under 2 MB and submit. The page reloads with a green success box containing a long signed URL. Click it, and the browser downloads your image, now converted to WebP. This is the happy path working end to end.

### Upload a Disguised PHP Shell

Create a fake shell on your machine and rename it to look like an image:

```
echo '<?php system($_GET["c"]); ?>' > shell.jpg
```

Upload `shell.jpg` through the form. It is rejected with validation errors, because the `image` and `mimes` rules read the bytes and find PHP source where image data should be:

```
The image field must be an image.
The image field must be a file of type: jpg, jpeg, png, webp.
```

Nothing is written to disk, and no `Upload` record is created.

### Upload an Oversized Image Bomb

Try to upload an image whose pixel dimensions are far larger than the 2000 by 2000 limit, for example a 8000 by 8000 PNG. The `dimensions` rule rejects it from the header alone, before the re-encode step ever allocates memory:

```
The image field has invalid image dimensions.
```

### Tamper with the Signed URL

Copy a working signed URL from a successful upload, change one character in the long signature at the end, and load it. Instead of the file you get a `403 Forbidden`, because the signature no longer matches what Laravel expects.

## Step 10: Prove the Exploits Fail with Pest {#step-10-tests}

Manual checks are reassuring, but the only durable proof is an automated test that fires each attack and asserts it fails. If someone later loosens a validation rule, these tests break and tell them why. Generate a feature test:

```
php artisan make:test UploadSecurityTest --pest
```

```
 INFO  Test [tests/Feature/UploadSecurityTest.php] created successfully.
```

Open `tests/Feature/UploadSecurityTest.php` and replace its contents with the full suite:

```php
<?php

use App\Models\Upload;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;

uses(RefreshDatabase::class);

test('a valid image is stored with a random webp name', function () {
    Storage::fake('uploads');

    $image = UploadedFile::fake()->image('vacation.png', 800, 600);

    $response = $this->post(route('uploads.store'), ['image' => $image]);

    $response->assertRedirect(route('uploads.create'));

    $upload = Upload::first();

    expect($upload)->not->toBeNull();
    expect($upload->path)->toEndWith('.webp');
    expect($upload->path)->not->toContain('vacation');
    expect($upload->original_name)->toBe('vacation.png');
    Storage::disk('uploads')->assertExists($upload->path);
});

test('a php script disguised as a jpg is rejected', function () {
    Storage::fake('uploads');

    $shell = UploadedFile::fake()->createWithContent(
        'avatar.jpg',
        '<?php system($_GET["cmd"]); ?>'
    );

    $response = $this->post(route('uploads.store'), ['image' => $shell]);

    $response->assertSessionHasErrors('image');
    expect(Upload::count())->toBe(0);
});

test('a double extension shell is rejected', function () {
    Storage::fake('uploads');

    $shell = UploadedFile::fake()->createWithContent(
        'photo.php.jpg',
        '<?php echo "pwned"; ?>'
    );

    $response = $this->post(route('uploads.store'), ['image' => $shell]);

    $response->assertSessionHasErrors('image');
    expect(Upload::count())->toBe(0);
});

test('an oversized image bomb is rejected by the dimensions rule', function () {
    Storage::fake('uploads');

    $bomb = UploadedFile::fake()->image('bomb.png', 8000, 8000);

    $response = $this->post(route('uploads.store'), ['image' => $bomb]);

    $response->assertSessionHasErrors('image');
    expect(Upload::count())->toBe(0);
});

test('a file larger than the max size is rejected', function () {
    Storage::fake('uploads');

    $big = UploadedFile::fake()->image('huge.jpg', 1000, 1000)->size(3000);

    $response = $this->post(route('uploads.store'), ['image' => $big]);

    $response->assertSessionHasErrors('image');
    expect(Upload::count())->toBe(0);
});

test('the stored file is re-encoded to webp regardless of input format', function () {
    Storage::fake('uploads');

    $image = UploadedFile::fake()->image('snapshot.jpg', 500, 500);

    $this->post(route('uploads.store'), ['image' => $image]);

    $upload = Upload::first();

    expect($upload->mime)->toBe('image/webp');
    expect($upload->path)->toEndWith('.webp');
});

test('a stored file cannot be downloaded without a valid signature', function () {
    Storage::fake('uploads');

    $upload = Upload::create([
        'original_name' => 'secret.png',
        'path' => 'images/example.webp',
        'mime' => 'image/webp',
        'size' => 1234,
    ]);

    $response = $this->get(route('uploads.show', $upload));

    $response->assertForbidden();
});

test('a valid signed url serves the stored file', function () {
    Storage::fake('uploads');
    Storage::disk('uploads')->put('images/example.webp', 'fake-webp-bytes');

    $upload = Upload::create([
        'original_name' => 'secret.png',
        'path' => 'images/example.webp',
        'mime' => 'image/webp',
        'size' => 15,
    ]);

    $url = URL::temporarySignedRoute('uploads.show', now()->addMinutes(5), ['upload' => $upload->id]);

    $response = $this->get($url);

    $response->assertOk();
    $response->assertDownload('secret.png');
});
```

A few patterns are worth pointing out. `Storage::fake('uploads')` swaps our private disk for an in-memory fake, so tests never touch the real filesystem. `UploadedFile::fake()->image('vacation.png', 800, 600)` builds a genuine image with valid headers, which passes validation and survives the re-encode. `UploadedFile::fake()->createWithContent('avatar.jpg', '<?php ... ?>')` builds a file with the right name but PHP source inside, which is exactly the disguised-shell payload our validation must reject. The first test proves the stored path is a random `.webp` and does not contain the original name, which confirms both the re-encode and the path traversal defense in one assertion. The last two tests pin down the signed URL behavior: no signature is forbidden, a valid signature succeeds.

Run the suite:

```
php artisan test
```

```
   PASS  Tests\Feature\UploadSecurityTest
  ✓ a valid image is stored with a random webp name                      0.26s
  ✓ a php script disguised as a jpg is rejected                          0.02s
  ✓ a double extension shell is rejected                                 0.02s
  ✓ an oversized image bomb is rejected by the dimensions rule           2.26s
  ✓ a file larger than the max size is rejected                          0.03s
  ✓ the stored file is re-encoded to webp regardless of input format     0.05s
  ✓ a stored file cannot be downloaded without a valid signature         0.03s
  ✓ a valid signed url serves the stored file                            0.02s

  Tests:    8 passed (24 assertions)
  Duration: 2.76s
```

Every attack we discussed is now a passing test that asserts the attack fails. The disguised shell, the double extension, the image bomb, the oversized file, and the unsigned download request are all rejected, and the valid path still works.

## Understanding the Three Attacks {#understanding-the-attacks}

Now that the code is in place, it is worth stepping back to see why each attack works and which layer stops it, because understanding the mechanism is what lets you recognize the same class of bug in code you did not write. These three attacks cover the vast majority of real upload vulnerabilities.

### MIME and Extension Spoofing

The browser sends a `Content-Type` header with every uploaded file, and a surprising amount of code trusts it. An attacker sends `Content-Type: image/jpeg` for a file full of PHP, and any check based on that header passes. The defense is to ignore what the request claims and inspect the bytes yourself. Our `image` and `mimes` rules read the file's actual content, and the `extensions` rule independently checks the trailing extension. A polyglot file that is valid as both an image and a script can sometimes satisfy a content check, which is precisely why we also re-encode: rebuilding the image from decoded pixels discards the script half of the polyglot entirely.

### Path Traversal

When code builds the storage path from the user's filename, the user controls where the file lands. A name like `../../public/index.php` walks up out of the intended folder and overwrites application files; on some systems it can plant an executable in a web-served directory. The defense is to never let the client name reach the path. We generate the path from `Str::uuid()` and keep the original name only as a display label, so no sequence of dots and slashes in the upload can change where the bytes are written.

### Decompression and Image Bombs

A decompression bomb is a small file that expands into something huge. An image bomb is the specific case where a tiny compressed image declares enormous pixel dimensions, so the moment an image library decodes it to resize or process it, it tries to allocate gigabytes and the process dies. The defense has two parts. The `dimensions` rule reads only the header and rejects absurd dimensions before any pixels are decoded, and the `scaleDown` call during re-encoding caps the working size as a second guard. The cheap header check comes first on purpose, so the expensive decode never runs on a hostile file.

The thread running through all three is that no single rule is enough. Validation without re-encoding misses polyglots, re-encoding without a private disk still risks direct execution, and a private disk without signed URLs cannot serve files safely. Security here comes from the stack, not from any one line.

## Conclusion {#conclusion}

We built a file upload feature in Laravel 13 that treats every uploaded file as hostile until proven otherwise. We validated on real content instead of the claimed name, stored files under random names on a disk the public cannot reach, rebuilt each image from scratch to strip anything hidden inside, and served files back only through expiring signed URLs. Then we proved the whole thing works by firing the actual attacks at it in a Pest suite that passes.

Here are the key takeaways:

- **Never trust the filename or the Content-Type header.** Both are fully controlled by the client. Validate on the file's real content with `image` and `mimes`, and check the real extension with `extensions`, because the two rules cover different bypasses.
- **Stack independent rules.** `mimes`, `extensions`, `dimensions`, and `max` each block a different attack, and stacking them is what defense in depth means. No single rule is enough on its own.
- **Store on a private disk with a random name.** A private disk with no public URL removes the direct-execution risk, and a `Str::uuid()` filename removes path traversal, because the client never influences where the file is written.
- **Re-encode images to neutralize hidden payloads.** Decoding to pixels and encoding a fresh file discards appended scripts, EXIF metadata, and polyglot tricks, and a malformed file simply throws during decode and never reaches storage.
- **Serve private files through temporary signed URLs.** `temporarySignedRoute` plus the `signed` middleware gives you expiring, tamper-proof access control without building a login system, as covered in our [signed URLs tutorial](https://qadrlabs.com/post/secure-download-links-in-laravel-with-signed-urls).
- **Prove the exploit fails with a test.** A passing test that fires the real payload is the only durable guarantee. If a future change weakens a rule, the test breaks and explains why.

From here you can extend the same foundation: scan uploads with ClamAV for known malware signatures, rate limit the upload endpoint to slow down abuse, or push the antivirus scan into a queued job so large files do not block the request. If you want a broader tour of Laravel security beyond uploads, read our [comprehensive secure coding guide](https://qadrlabs.com/post/secure-coding-laravel-panduan-komprehensif-keamanan-aplikasi-web).
