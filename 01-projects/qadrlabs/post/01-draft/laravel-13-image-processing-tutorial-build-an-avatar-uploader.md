# Laravel 13 Image Processing Tutorial: Build an Avatar Uploader

User-uploaded profile photos rarely arrive in a consistent shape. One user uploads a large landscape JPEG, another uploads a portrait PNG, and a third uploads a photo that appears rotated because of its EXIF metadata. Storing these files unchanged creates uneven layouts, wastes bandwidth, and pushes image cleanup into every view that displays an avatar.

[Laravel 13.20.0 introduced first-party image processing](https://qadrlabs.com/post/whats-new-in-laravel-13200-image-processing-new-apis-and-important-fixes), giving Laravel applications a fluent API for reading, transforming, converting, and storing images. In this tutorial, you will use the current Laravel 13 Image API to turn different uploads into consistent 400 by 400 pixel WebP avatars.

The feature first appeared in the [Laravel Framework 13.20.0 release](https://github.com/laravel/framework/releases/tag/v13.20.0). Its API continued to evolve after that release, so this tutorial follows the [current Laravel 13 image manipulation documentation](https://laravel.com/docs/13.x/images) and was tested with Laravel Framework 13.23.0 and Intervention Image 4.2.0.

## Overview {#overview}

You will build a small standalone avatar processor. It does not require a database or authentication, which keeps the tutorial focused on the image pipeline itself. A user selects a photo, Laravel validates and processes it, and the page displays the stored WebP result.

### What You'll Build

- A public avatar upload form.
- Server-side validation for file type, size, and dimensions.
- A processing pipeline that corrects orientation and creates a square avatar.
- WebP output with a predictable quality setting.
- Public storage with an automatically generated filename.
- Pest tests that inspect the stored image's MIME type and dimensions.

### What You'll Learn

- How to install and configure Laravel's Image API.
- How to retrieve an uploaded image with `$request->image()`.
- How immutable image transformations form an ordered processing pipeline.
- How `orient()`, `cover()`, `toWebp()`, and `quality()` work together.
- How to store a processed image on Laravel's public disk.
- How to test image uploads and inspect the processed result.

### What You'll Need

- PHP 8.3 or later.
- Composer.
- Laravel Installer 5.31.0 or later.
- The PHP GD extension.
- Basic knowledge of Laravel routes, controllers, Blade, validation, and Pest.
- The previous [Laravel 13.20.0 release overview](https://qadrlabs.com/post/whats-new-in-laravel-13200-image-processing-new-apis-and-important-fixes) for background on when the Image API was introduced.

## Step 1: Create the Laravel Project {#step-1-create-the-laravel-project}

Start with a fresh Laravel application so that the files and test results in this tutorial are reproducible. Open a terminal and run:

```bash
laravel new avatar-image-demo --no-interaction --database=sqlite --pest --no-boost
cd avatar-image-demo
```

The command creates a Laravel project with SQLite and Pest already configured. The `--no-boost` option keeps this small demonstration focused on the application itself.

Confirm the framework version:

```bash
php artisan --version
```

The tested project returned:

```text
Laravel Framework 13.23.0
```

Laravel 13.20.0 introduced the feature, but using the current Laravel 13 release ensures that the code matches the current documented API.

Before changing the application, run the two tests included with a new Laravel project:

```bash
PAO_DISABLE=true php artisan test tests/Unit/ExampleTest.php tests/Feature/ExampleTest.php --colors=never
```

The `PAO_DISABLE=true` prefix disables Laravel's agent-oriented compact test output so that Pest prints its normal human-readable report:

```text

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.11s  

  Tests:    2 passed (2 assertions)
  Duration: 0.18s
```

The passing baseline confirms that the new project works before image processing is added.

## Step 2: Install and Configure Image Processing {#step-2-install-and-configure-image-processing}

Laravel provides the framework-facing Image API, while Intervention Image performs local image manipulation through GD or Imagick. Install the version required by the current Laravel 13 documentation:

```bash
composer require intervention/image:^4.0
```

Verify the installed package:

```bash
composer show intervention/image | sed -n '1,8p'
```

The tested project installed Intervention Image 4.2.0:

```text
name     : intervention/image
descrip. : PHP Image Processing
keywords : gd, image, imagick, resize, thumbnail, watermark
versions : * 4.2.0
released : 2026-07-09, 2 weeks ago
type     : library
license  : MIT License (MIT) (OSI approved) https://spdx.org/licenses/MIT.html#licenseText
homepage : https://image.intervention.io
```

Laravel's local drivers require either GD or Imagick. This tutorial uses GD because it is widely available and sufficient for a small avatar processor. Confirm that PHP has loaded it:

```bash
php -m | grep -i '^gd$'
```

The command should print:

```text
gd
```

Publish Laravel's image configuration:

```bash
php artisan config:publish images
```

The command creates `config/images.php`:

```text
 INFO Published 'images' configuration file. 
```

Open `config/images.php` and confirm its contents:

```php
<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default Image Driver
    |--------------------------------------------------------------------------
    |
    | This option controls the default image processing driver that will be
    | used when manipulating or converting images. This driver is always
    | utilized unless another driver is explicitly specified instead.
    |
    | Supported: "gd", "imagick"
    |
    */

    'default' => env('IMAGE_DRIVER', 'gd'),

];
```

The `IMAGE_DRIVER` environment variable can override the driver. Add an explicit value to `.env`:

```ini
IMAGE_DRIVER=gd
```

Verify the resolved configuration:

```bash
php artisan config:show images --no-ansi
```

The command should show GD as the active driver:

```text

 images .. 
 default .. gd 
```

Finally, connect `public/storage` to `storage/app/public`:

```bash
php artisan storage:link
```

Laravel confirms the link:

```text
 INFO The [public/storage] link has been connected to [storage/app/public]. 
```

The link allows the browser to request processed avatars stored on the `public` disk.

## Step 3: Create the Avatar Upload Page {#step-3-create-the-avatar-upload-page}

The application needs two routes, a controller action for the form, and a Blade view. Begin by creating the controller:

```bash
php artisan make:controller AvatarController
```

Open `app/Http/Controllers/AvatarController.php` and replace it with:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

class AvatarController extends Controller
{
    public function create(): View
    {
        // Display the form that accepts a source image.
        return view('avatar');
    }
}
```

The `create()` action only renders the form. Image processing will be added after the upload interface is working.

Next, open `routes/web.php` and replace it with:

```php
<?php

use App\Http\Controllers\AvatarController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/avatar', [AvatarController::class, 'create'])
    ->name('avatar.create');

Route::post('/avatar', [AvatarController::class, 'store'])
    ->name('avatar.store');
```

The GET route displays the form. The POST route will receive the uploaded file in the next step. Naming both routes keeps URLs out of the controller and view.

Create `resources/views/avatar.blade.php` with the initial upload form:

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laravel Avatar Processor</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-3xl font-bold text-gray-900">Avatar Processor</h1>
        <p class="mt-2 text-gray-600">
            Upload a photo and Laravel will create a square 400 by 400 pixel WebP avatar.
        </p>

        <form action="{{ route('avatar.store') }}" method="POST" enctype="multipart/form-data"
            class="mt-8 space-y-5">
            @csrf

            <div>
                <label for="avatar" class="block text-sm font-medium text-gray-700">
                    Choose an image
                </label>
                <input id="avatar" name="avatar" type="file" required
                    accept="image/jpeg,image/png,image/webp"
                    class="mt-2 block w-full rounded-md border border-gray-300 p-2 text-sm
                        file:mr-4 file:rounded-md file:border-0 file:bg-blue-50 file:px-4 file:py-2
                        file:text-sm file:font-semibold file:text-blue-700 hover:file:bg-blue-100">
                <p class="mt-2 text-sm text-gray-500">
                    JPG, PNG, or WebP. Use an image from 400 by 400 to 4000 by 4000 pixels, up to 5 MB.
                </p>

                @error('avatar')
                    <p class="mt-2 text-sm text-red-600">{{ $message }}</p>
                @enderror
            </div>

            <button type="submit"
                class="rounded-md bg-blue-600 px-5 py-2.5 font-semibold text-white hover:bg-blue-700">
                Process Avatar
            </button>
        </form>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Laravel Image Processing at qadrlabs.com</a>
        </div>
    </div>
</body>

</html>
```

The `multipart/form-data` encoding is required because a normal URL-encoded form does not transmit file contents. The `accept` attribute helps users choose a supported file, but the server must still validate every upload.

Save the files, then inspect the avatar routes:

```bash
php artisan route:list --path=avatar --no-ansi
```

The two routes should appear:

```text

 GET|HEAD avatar .. avatar.create › AvatarController@create
 POST avatar .. avatar.store › AvatarController@store

 Showing [2] routes
```

The form route is now ready. Submitting it will fail because `store()` does not exist yet, which is the behavior the next step will implement.

## Step 4: Validate and Process the Avatar {#step-4-validate-and-process-the-avatar}

The POST action must reject unsuitable files before GD decodes them. It will then create one processed image and store it on the public disk.

Open `app/Http/Controllers/AvatarController.php` and replace it with the complete controller:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\File;
use Illuminate\View\View;

class AvatarController extends Controller
{
    public function create(): View
    {
        // Display the upload form and any flashed avatar path.
        return view('avatar');
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'avatar' => [
                'required',
                File::image()
                    // Accept the formats that this application promises.
                    ->types(['jpg', 'jpeg', 'png', 'webp'])
                    // Limit both compressed file size and decoded dimensions.
                    ->max('5mb')
                    ->dimensions(
                        Rule::dimensions()
                            ->minWidth(400)
                            ->minHeight(400)
                            ->maxWidth(4000)
                            ->maxHeight(4000),
                    ),
            ],
        ]);

        $path = $request->image('avatar')
            // Correct photos that store their rotation in EXIF metadata.
            ->orient()
            // Resize and center-crop the image to an exact square.
            ->cover(400, 400)
            // Produce one predictable web-friendly output format.
            ->toWebp()
            ->quality(80)
            // Store the result with public visibility and a hashed name.
            ->storePublicly(path: 'avatars', disk: 'public');

        abort_if($path === false, 500, 'The processed avatar could not be stored.');

        return to_route('avatar.create')
            ->with('avatar_path', $path);
    }
}
```

Laravel's [fluent file validation rules](https://laravel.com/docs/13.x/validation#validating-files) inspect the uploaded file's MIME type rather than trusting its extension. The 5 MB limit controls the uploaded file size, while the dimension limits reject very small images and unusually large pixel canvases.

After validation, `$request->image('avatar')` returns an `Illuminate\Image\Image` instance. Each following call adds an operation to an immutable pipeline:

- `orient()` applies EXIF orientation before any dimension calculation.
- `cover(400, 400)` preserves the aspect ratio while cropping the result to an exact square.
- `toWebp()` selects WebP as the output format.
- `quality(80)` balances visual quality and file size.
- `storePublicly()` writes the processed result to `storage/app/public/avatars`.

The storage call generates a hashed filename with the correct `.webp` extension. If writing fails, the controller returns a server error instead of flashing an invalid path.

## Step 5: Display the Processed Avatar {#step-5-display-the-processed-avatar}

The controller redirects back with `avatar_path` in the session. The view can use that path to display the generated file without adding a database table.

Open `resources/views/avatar.blade.php` and replace it with the final view:

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laravel Avatar Processor</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-3xl font-bold text-gray-900">Avatar Processor</h1>
        <p class="mt-2 text-gray-600">
            Upload a photo and Laravel will create a square 400 by 400 pixel WebP avatar.
        </p>

        <form action="{{ route('avatar.store') }}" method="POST" enctype="multipart/form-data"
            class="mt-8 space-y-5">
            @csrf

            <div>
                <label for="avatar" class="block text-sm font-medium text-gray-700">
                    Choose an image
                </label>
                <input id="avatar" name="avatar" type="file" required
                    accept="image/jpeg,image/png,image/webp"
                    class="mt-2 block w-full rounded-md border border-gray-300 p-2 text-sm
                        file:mr-4 file:rounded-md file:border-0 file:bg-blue-50 file:px-4 file:py-2
                        file:text-sm file:font-semibold file:text-blue-700 hover:file:bg-blue-100">
                <p class="mt-2 text-sm text-gray-500">
                    JPG, PNG, or WebP. Use an image from 400 by 400 to 4000 by 4000 pixels, up to 5 MB.
                </p>

                @error('avatar')
                    <p class="mt-2 text-sm text-red-600">{{ $message }}</p>
                @enderror
            </div>

            <button type="submit"
                class="rounded-md bg-blue-600 px-5 py-2.5 font-semibold text-white hover:bg-blue-700">
                Process Avatar
            </button>
        </form>

        @if (session('avatar_path'))
            <div class="mt-8 border-t border-gray-200 pt-6">
                <h2 class="text-xl font-semibold text-gray-900">Processed Avatar</h2>
                <img src="{{ asset('storage/' . session('avatar_path')) }}"
                    alt="Processed 400 by 400 pixel avatar"
                    class="mt-4 h-48 w-48 rounded-full border-4 border-white object-cover shadow-lg">
                <a href="{{ asset('storage/' . session('avatar_path')) }}" target="_blank"
                    class="mt-4 inline-block text-sm font-medium text-blue-600 hover:text-blue-800 hover:underline">
                    Open the WebP image
                </a>
            </div>
        @endif

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
                target="_blank">Tutorial Laravel Image Processing at qadrlabs.com</a>
        </div>
    </div>
</body>

</html>
```

The conditional block appears only after a successful upload. `asset('storage/' . session('avatar_path'))` converts a relative storage path such as `avatars/random-name.webp` into a public URL.

The CSS displays the square image as a circle, but the stored file remains a normal 400 by 400 pixel WebP. The link opens the actual processed file so that you can inspect it independently from the circular preview.

## Step 6: Test the Image Processing Workflow {#step-6-test-the-image-processing-workflow}

Automated tests should prove more than the redirect. They should verify validation, storage, output format, and output dimensions.

Create `tests/Feature/AvatarUploadTest.php` with:

```php
<?php

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

beforeEach(function () {
    // Keep every test isolated from the real public disk.
    Storage::fake('public');
});

test('the avatar upload form can be viewed', function () {
    $this->get(route('avatar.create'))
        ->assertOk()
        ->assertSee('Avatar Processor');
});

test('an avatar is required', function () {
    $this->post(route('avatar.store'))
        ->assertSessionHasErrors(['avatar']);
});

test('a non-image file is rejected', function () {
    $file = UploadedFile::fake()->create('notes.txt', 10, 'text/plain');

    $this->post(route('avatar.store'), ['avatar' => $file])
        ->assertSessionHasErrors(['avatar']);
});

test('an unsupported image format is rejected', function () {
    $avatar = UploadedFile::fake()->image('avatar.gif', 800, 800);

    $this->post(route('avatar.store'), ['avatar' => $avatar])
        ->assertSessionHasErrors(['avatar']);
});

test('an avatar larger than five megabytes is rejected', function () {
    $avatar = UploadedFile::fake()
        ->image('large-avatar.jpg', 800, 800)
        ->size(5121);

    $this->post(route('avatar.store'), ['avatar' => $avatar])
        ->assertSessionHasErrors(['avatar']);
});

test('an avatar smaller than the minimum dimensions is rejected', function () {
    $avatar = UploadedFile::fake()->image('small-avatar.png', 300, 300);

    $this->post(route('avatar.store'), ['avatar' => $avatar])
        ->assertSessionHasErrors(['avatar']);
});

test('a valid avatar is stored as a 400 pixel square webp image', function () {
    $avatar = UploadedFile::fake()->image('profile-photo.jpg', 800, 600);

    $response = $this->post(route('avatar.store'), ['avatar' => $avatar]);

    $response
        ->assertRedirect(route('avatar.create'))
        ->assertSessionHas('avatar_path');

    $files = Storage::disk('public')->allFiles('avatars');

    expect($files)->toHaveCount(1);

    $path = $files[0];
    $processedAvatar = Storage::disk('public')->image($path);

    Storage::disk('public')->assertExists($path);

    expect(pathinfo($path, PATHINFO_EXTENSION))->toBe('webp')
        ->and($processedAvatar->mimeType())->toBe('image/webp')
        ->and($processedAvatar->dimensions())->toBe([400, 400]);
});
```

Laravel's [HTTP testing documentation](https://laravel.com/docs/13.x/http-tests#testing-file-uploads) recommends `Storage::fake()` and `UploadedFile::fake()` for isolated upload tests. The fake image helper requires GD, which is another reason the extension was verified during setup.

The last test performs the important end-to-end check. It uploads an 800 by 600 JPEG, finds the generated file on the fake disk, reads that file through Laravel's Image API, and proves that the result is a 400 by 400 WebP image.

Save the file and run the complete suite:

```bash
PAO_DISABLE=true php artisan test --colors=never
```

The tested project produced:

```text

   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\AvatarUploadTest
  ✓ the avatar upload form can be viewed                                 0.12s  
  ✓ an avatar is required                                                0.02s  
  ✓ a non-image file is rejected                                         0.03s  
  ✓ an unsupported image format is rejected                              0.04s  
  ✓ an avatar larger than five megabytes is rejected                     0.03s  
  ✓ an avatar smaller than the minimum dimensions is rejected            0.03s  
  ✓ a valid avatar is stored as a 400 pixel square webp image            0.06s  

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.06s  

  Tests:    9 passed (22 assertions)
  Duration: 0.47s
```

All nine tests pass, including the seven avatar scenarios.

## Step 7: Try It Out {#step-7-try-it-out}

The automated suite proves the processing result, but using the form helps you see how different source images behave. Start Laravel's local development server:

```bash
php artisan serve
```

Laravel prints the local address:

```text
 INFO Server running on [http://127.0.0.1:8000]. 

 Press Ctrl+C to stop the server
```

Open `http://127.0.0.1:8000/avatar` in your browser.

### Process a Landscape JPEG

Select a landscape JPEG between 400 by 400 and 4000 by 4000 pixels, then click **Process Avatar**. The request redirects back to the form and displays a circular preview. Click **Open the WebP image** to view the underlying square file.

The output URL should resemble:

```text
http://127.0.0.1:8000/storage/avatars/H71DDl0c9JEFGoNohUvvqVzGv6dYjJVeTWvtXvwP.webp
```

The generated filename will be different in your application because Laravel creates a new hashed name for each upload.

### Process a Portrait PNG

Upload a portrait PNG. The output still becomes exactly 400 by 400 pixels because `cover()` crops excess content after resizing the image proportionally.

### Verify Validation

Try submitting each of these files:

- A PDF or text file.
- A GIF image.
- An image larger than 5 MB.
- An image smaller than 400 by 400 pixels.
- An image wider or taller than 4000 pixels.

Laravel redirects back and displays a validation error below the file input. Invalid files never reach the image processing pipeline.

## How Laravel's Image Pipeline Works {#how-laravels-image-pipeline-works}

Laravel image instances are immutable. A transformation does not modify the existing object. Instead, it returns a new image instance containing the additional pipeline operation. This behavior makes it safe to derive several variants from one source image.

For this tutorial, the pipeline is:

```php
$request->image('avatar')
    ->orient()
    ->cover(400, 400)
    ->toWebp()
    ->quality(80)
    ->storePublicly(path: 'avatars', disk: 'public');
```

Laravel records these operations in order and processes them when the final image bytes are needed for storage.

### Why Orientation Comes First

Smartphone photos often store their rotation as EXIF metadata instead of rotating the pixel data. Calling `orient()` first ensures that the visual width and height are correct before Laravel calculates the square crop.

### Cover Versus Scale

`cover(400, 400)` guarantees an exact 400 by 400 result. It preserves the aspect ratio but crops content that falls outside the square.

`scale(400, 400)` would preserve the entire image and fit it within those boundaries. A landscape source could become 400 by 300, which is useful for content images but not for consistent avatars.

### WebP Format and Quality

`toWebp()` gives every processed avatar the same output format regardless of whether the source was JPEG, PNG, or WebP. `quality(80)` controls the lossy encoding quality. Higher values usually preserve more detail and create larger files.

The generated hashed filename prevents the application from trusting or reusing the user's original name. Its extension also follows the processed format, so the stored path ends in `.webp`.

### When to Move Processing to a Queue

This demonstration processes images during the HTTP request because it limits both compressed file size and pixel dimensions. Image decoding and resizing can consume significant CPU and memory. The [official image documentation](https://laravel.com/docs/13.x/images#introduction) recommends queued jobs for large image processing workloads.

A production account system would also associate each path with a user, delete the previous avatar after a successful replacement, and remove stored files when the account is deleted. Those responsibilities are intentionally outside this standalone processor.

## Conclusion {#conclusion}

You now have a tested Laravel 13 avatar processor that turns varied uploads into consistent web-ready images. The application validates the source, builds an immutable processing pipeline, stores the result, and verifies the actual output rather than only checking that a request succeeded.

- **Current Laravel Image API.** The tutorial uses Intervention Image 4 and `config/images.php`, matching the current Laravel 13 documentation.
- **Layered validation.** File type, compressed size, and pixel dimensions are checked before image processing begins.
- **Ordered transformations.** Orientation correction runs before the square crop, followed by WebP conversion and quality selection.
- **Predictable output.** Every accepted upload becomes a 400 by 400 pixel WebP with a hashed filename.
- **Public storage.** `storePublicly()` writes the processed avatar to the public disk, while `storage:link` makes it available to the browser.
- **Verified behavior.** Seven focused Pest tests cover the form, validation failures, storage, MIME type, extension, and final dimensions.
- **Production path.** User ownership, replacement cleanup, and queued processing are the logical next additions for a full account avatar feature.
