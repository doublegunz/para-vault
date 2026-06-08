---
title: "Eloquent Encrypted Cast: Auto-Encrypt Sensitive Data at the Model Level in Laravel 13"
slug: "eloquent-encrypted-cast-auto-encrypt-sensitive-data-at-the-model-level-in-laravel-13"
category: "Laravel"
date: "2026-05-12"
status: "published"
---

Most Laravel applications store sensitive fields like NIK, passport numbers, or home addresses as plain text in the database. The reasoning is familiar: the database has access controls, so it should be safe enough. But if an attacker gains direct access to your database through a backup leak, a misconfigured firewall, or SQL injection, every sensitive record is immediately readable with no extra effort required.

Encrypting sensitive data at rest adds a second, independent layer of defense. Even with a raw database dump in hand, an attacker cannot read the values without also obtaining your application's encryption key, which lives on the server, not in the database. Laravel makes this straightforward with the built-in `encrypted` Eloquent cast. You declare which columns are sensitive in your model, and Laravel silently encrypts before every write and decrypts after every read. Your controller and view code never changes; you still read `$resident->nik` and get the plain NIK back.

In this tutorial, you will build a standalone resident data management app that stores NIK and home address as encrypted values in the database. You will also solve the most common limitation of encrypted fields: the inability to search them. By the end, you will have a working application that encrypts sensitive data automatically and can still locate a resident by their exact NIK using a blind index.

## Overview {#overview}

This is a standalone tutorial. You do not need to complete any previous article to follow along.

### What You'll Build

- A registration form that accepts resident data (name, NIK, date of birth, and address)
- A listing page that displays all residents with their NIK automatically decrypted by Eloquent
- A search form that finds a resident by NIK without scanning or decrypting any stored ciphertext
- A detail page showing the full resident profile

### What You'll Learn

- How to apply the `encrypted` cast to Eloquent model attributes with a single line
- Why encrypted columns require `TEXT` type instead of `VARCHAR` in your migration
- How to verify that a field is genuinely stored as ciphertext in the database using Tinker
- How to build a blind index so an encrypted field remains searchable via exact match
- How a custom `Attribute` mutator replaces the `encrypted` cast when setting a field must also update a derived column
- How to write Pest tests that verify encryption behavior at the raw database level

### What You'll Need

- PHP 8.3 or higher
- Composer
- Basic familiarity with Laravel Eloquent models, migrations, and controllers

## Step 1: Create the Project {#step-1-create-the-project}

Create a new Laravel 13 project with SQLite and Pest pre-configured:

```bash
laravel new resident-data --no-interaction --database=sqlite --pest --no-boost
cd resident-data
```

The `--database=sqlite` flag configures a local SQLite file so the setup requires no external database server. The `--pest` flag installs Pest as the testing framework. Confirm the project is running:

```bash
php artisan serve
```

You should see the default Laravel welcome page at `http://127.0.0.1:8000`. Stop the server with `Ctrl+C` before continuing.

## Step 2: Create the Migration and Model {#step-2-create-the-migration-and-model}

Run the Artisan generator to create the migration and model together:

```bash
php artisan make:model Resident -m
```

The `-m` flag creates a matching migration file alongside the model. You will configure both files in this step.

### Write the Migration

Open `database/migrations/[timestamp]_create_residents_table.php` and replace the `up()` method body with the following:

```php
public function up(): void
{
    Schema::create('residents', function (Blueprint $table) {
        $table->id();
        $table->string('name');
        $table->text('nik');           // Encrypted value — must use TEXT, not VARCHAR
        $table->date('date_of_birth');
        $table->text('address');       // Also encrypted — also needs TEXT
        $table->string('nik_hash')->nullable()->unique(); // Blind index for search
        $table->timestamps();
    });
}
```

Two decisions here deserve explanation. First, both `nik` and `address` use `text()` instead of `string()`. When Laravel encrypts a value, the resulting ciphertext is significantly longer than the original plain text, and its length is not predictable. A `VARCHAR(255)` column will truncate long ciphertext and silently corrupt your data with no error thrown. A `TEXT` column has no meaningful length limit, so the encrypted payload always fits regardless of how long the original value was.

Second, `nik_hash` is a plain `string` column with a `unique` index. This column will hold a deterministic SHA-256 hash of the NIK, not the NIK itself. It is what makes the NIK searchable later in this tutorial, and because it is a one-way hash rather than the sensitive value, it does not need to be encrypted.

Run the migration:

```bash
php artisan migrate
```

Expected output:

```
INFO  Running migrations.

  2025_05_08_000000_create_residents_table ......... 8ms DONE
```

### Configure the Model

Open `app/Models/Resident.php` and replace its content:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['name', 'nik', 'date_of_birth', 'address'])]
class Resident extends Model
{
    /**
     * The 'encrypted' cast instructs Eloquent to call Crypt::encryptString()
     * before every write and Crypt::decryptString() after every read
     * for the listed columns. Your controllers and views never see ciphertext.
     */
    protected function casts(): array
    {
        return [
            'nik'           => 'encrypted',
            'address'       => 'encrypted',
            'date_of_birth' => 'date',
        ];
    }
}
```

The `'nik' => 'encrypted'` cast entry is the core of this tutorial. Declaring it here is all you need for transparent, automatic encryption. Your application code treats `$resident->nik` as a normal string in every other file.

Note that `nik_hash` is intentionally absent from `#[Fillable]`. It is a derived value that your code computes internally. It should never be writable by incoming user input.

## Step 3: Create the Controller and Routes {#step-3-create-the-controller-and-routes}

Create the controller:

```bash
php artisan make:controller ResidentController
```

Open `app/Http/Controllers/ResidentController.php` and replace its content:

```php
<?php

namespace App\Http\Controllers;

use App\Models\Resident;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ResidentController extends Controller
{
    /**
     * List all residents.
     * The NIK search filter will be wired up in Step 6.
     */
    public function index(Request $request): View
    {
        $residents = Resident::latest()->get();

        return view('residents.index', compact('residents'));
    }

    /**
     * Show the registration form.
     */
    public function create(): View
    {
        return view('residents.create');
    }

    /**
     * Validate and persist a new resident.
     */
    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name'          => ['required', 'string', 'max:255'],
            'nik'           => ['required', 'digits:16'],
            'date_of_birth' => ['required', 'date'],
            'address'       => ['required', 'string', 'max:1000'],
        ]);

        Resident::create($validated);

        return redirect()
            ->route('residents.index')
            ->with('success', 'Resident data has been saved.');
    }

    /**
     * Show a single resident's full detail.
     */
    public function show(Resident $resident): View
    {
        return view('residents.show', compact('resident'));
    }
}
```

Now register the routes. Open `routes/web.php` and replace its content:

```php
<?php

use App\Http\Controllers\ResidentController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => redirect()->route('residents.index'));

Route::resource('residents', ResidentController::class)
    ->only(['index', 'create', 'store', 'show']);
```

The `only()` call restricts the resource to the four actions this application needs, keeping the route list clean. Confirm the routes registered:

```bash
php artisan route:list
```

Expected output:

```
  GET|HEAD  /                      ....
  GET|HEAD  residents              residents.index   › ResidentController@index
  POST      residents              residents.store   › ResidentController@store
  GET|HEAD  residents/create       residents.create  › ResidentController@create
  GET|HEAD  residents/{resident}   residents.show    › ResidentController@show
```

## Step 4: Create the Views {#step-4-create-the-views}

Create the views directory:

```bash
mkdir -p resources/views/residents
```

### residents/index.blade.php

Create `resources/views/residents/index.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resident Data</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-4xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex items-center justify-between mb-6">
            <h1 class="text-2xl font-bold">Resident Data</h1>
            <a href="{{ route('residents.create') }}"
               class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 text-sm">
                + Register Resident
            </a>
        </div>

        @if (session('success'))
            <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4 text-sm">
                {{ session('success') }}
            </div>
        @endif

        {{-- Search form: uses nik_hash under the hood, wired up in Step 6 --}}
        <form method="GET" action="{{ route('residents.index') }}" class="mb-6">
            <div class="flex gap-2">
                <input type="text" name="nik" value="{{ request('nik') }}"
                       placeholder="Search by NIK (16 digits)..."
                       class="flex-1 border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400">
                <button type="submit"
                        class="bg-gray-700 text-white px-4 py-2 rounded hover:bg-gray-800 text-sm">
                    Search
                </button>
                @if (request('nik'))
                    <a href="{{ route('residents.index') }}"
                       class="bg-gray-200 text-gray-700 px-4 py-2 rounded hover:bg-gray-300 text-sm">
                        Clear
                    </a>
                @endif
            </div>
        </form>

        @if ($residents->isEmpty())
            <p class="text-gray-500 text-sm">No residents found.</p>
        @else
            <table class="w-full text-sm border-collapse">
                <thead>
                    <tr class="bg-gray-50 text-left">
                        <th class="p-3 border-b font-semibold">Name</th>
                        <th class="p-3 border-b font-semibold">NIK</th>
                        <th class="p-3 border-b font-semibold">Date of Birth</th>
                        <th class="p-3 border-b font-semibold">Action</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($residents as $resident)
                        <tr class="hover:bg-gray-50">
                            <td class="p-3 border-b">{{ $resident->name }}</td>
                            {{--
                                $resident->nik is automatically decrypted by Eloquent
                                before it reaches this view. The database stores
                                ciphertext; the view receives plain NIK.
                            --}}
                            <td class="p-3 border-b font-mono text-xs">{{ $resident->nik }}</td>
                            <td class="p-3 border-b">{{ $resident->date_of_birth->format('d M Y') }}</td>
                            <td class="p-3 border-b">
                                <a href="{{ route('residents.show', $resident) }}"
                                   class="text-blue-600 hover:underline">View</a>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        @endif

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com"
               class="text-blue-600 hover:text-blue-800 hover:underline transition"
               target="_blank">Tutorial Eloquent Encrypted Cast at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

### residents/create.blade.php

Create `resources/views/residents/create.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register Resident</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex items-center gap-4 mb-6">
            <a href="{{ route('residents.index') }}" class="text-gray-500 hover:text-gray-700 text-sm">
                &larr; Back
            </a>
            <h1 class="text-2xl font-bold">Register New Resident</h1>
        </div>

        @if ($errors->any())
            <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                <ul class="list-disc list-inside text-sm">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form method="POST" action="{{ route('residents.store') }}">
            @csrf

            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                <input type="text" name="name" value="{{ old('name') }}"
                       class="w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
                       placeholder="e.g. Budi Santoso">
            </div>

            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-1">
                    NIK
                    <span class="text-gray-400 font-normal">(16 digits)</span>
                </label>
                <input type="text" name="nik" value="{{ old('nik') }}" maxlength="16"
                       class="w-full border border-gray-300 rounded px-3 py-2 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-blue-400"
                       placeholder="e.g. 3273010101900001">
                <p class="text-xs text-gray-400 mt-1">
                    This value will be encrypted before being stored in the database.
                </p>
            </div>

            <div class="mb-4">
                <label class="block text-sm font-medium text-gray-700 mb-1">Date of Birth</label>
                <input type="date" name="date_of_birth" value="{{ old('date_of_birth') }}"
                       class="w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400">
            </div>

            <div class="mb-6">
                <label class="block text-sm font-medium text-gray-700 mb-1">
                    Address
                    <span class="text-gray-400 font-normal">(will also be encrypted)</span>
                </label>
                <textarea name="address" rows="3"
                          class="w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
                          placeholder="e.g. Jl. Merdeka No. 1, RT 01/RW 02, Jakarta Pusat">{{ old('address') }}</textarea>
            </div>

            <button type="submit"
                    class="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 font-medium text-sm">
                Save Resident Data
            </button>
        </form>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com"
               class="text-blue-600 hover:text-blue-800 hover:underline transition"
               target="_blank">Tutorial Eloquent Encrypted Cast at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

### residents/show.blade.php

Create `resources/views/residents/show.blade.php`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Resident Detail</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <div class="flex items-center gap-4 mb-6">
            <a href="{{ route('residents.index') }}" class="text-gray-500 hover:text-gray-700 text-sm">
                &larr; Back to List
            </a>
            <h1 class="text-2xl font-bold">Resident Detail</h1>
        </div>

        <dl class="divide-y divide-gray-100">
            <div class="py-3 flex">
                <dt class="w-40 text-sm font-medium text-gray-500 shrink-0">Full Name</dt>
                <dd class="text-sm text-gray-900">{{ $resident->name }}</dd>
            </div>
            <div class="py-3 flex">
                <dt class="w-40 text-sm font-medium text-gray-500 shrink-0">NIK</dt>
                {{-- Eloquent decrypts this automatically; the view sees plain NIK --}}
                <dd class="text-sm text-gray-900 font-mono">{{ $resident->nik }}</dd>
            </div>
            <div class="py-3 flex">
                <dt class="w-40 text-sm font-medium text-gray-500 shrink-0">Date of Birth</dt>
                <dd class="text-sm text-gray-900">{{ $resident->date_of_birth->format('d F Y') }}</dd>
            </div>
            <div class="py-3 flex">
                <dt class="w-40 text-sm font-medium text-gray-500 shrink-0">Address</dt>
                <dd class="text-sm text-gray-900">{{ $resident->address }}</dd>
            </div>
            <div class="py-3 flex">
                <dt class="w-40 text-sm font-medium text-gray-500 shrink-0">Registered</dt>
                <dd class="text-sm text-gray-900">{{ $resident->created_at->format('d M Y, H:i') }}</dd>
            </div>
        </dl>

        <div class="mt-8 mb-6 text-center text-sm text-gray-500">
            <a href="https://qadrlabs.com"
               class="text-blue-600 hover:text-blue-800 hover:underline transition"
               target="_blank">Tutorial Eloquent Encrypted Cast at qadrlabs.com</a>
        </div>
    </div>
</body>
</html>
```

## Step 5: Try It Out - Verify Encryption {#step-5-try-it-out-verify-encryption}

Start the development server:

```bash
php artisan serve
```

Open `http://127.0.0.1:8000/residents/create` and register a resident. Enter any 16-digit NIK such as `3273010101900001`. After submitting, you will be redirected to the index page where the NIK appears in plain text. That is the first confirmation: Eloquent is decrypting the NIK before the view receives it.

The more important verification is confirming the raw database value is actually ciphertext. Open Artisan Tinker in a second terminal:

```bash
php artisan tinker
```

First, retrieve the resident through Eloquent and read its NIK:

```php
$r = App\Models\Resident::first();
$r->nik;
```

Expected output:

```
= "3273010101900001"
```

The model returns the plain NIK because the `encrypted` cast decrypts it on every read.

Now bypass Eloquent entirely and query the database directly:

```php
\DB::table('residents')->first()->nik;
```

Expected output (your specific value will differ, but the format will be the same):

```
= "eyJpdiI6InVOdnZhM3VQT3k1YXF4cjl5Z3RNQUE9PSIsInZhbHVlIjoiYkM1YjBk..."
```

That long base64 string is the actual value stored on disk. It is the JSON payload produced by Laravel's AES-256-CBC encrypter, encoded as base64. Anyone who obtains the database file without your server's `APP_KEY` cannot read the NIK from this string.

Exit Tinker:

```php
exit
```

At this point, NIK and address are stored encrypted, and the application reads them back correctly. The search form is visible on the index page but does not yet filter results. That changes in the next step.

## Step 6: Add NIK Searchability with Blind Index {#step-6-add-nik-searchability-with-blind-index}

The `encrypted` cast is convenient, but it creates a fundamental search problem: SQL cannot compare encrypted ciphertext against a plain search term. You cannot run `WHERE nik = '3273010101900001'` because the stored value is ciphertext, not plain text. You also cannot encrypt the search term and compare ciphertexts, because AES-256-CBC produces a different ciphertext every time due to a randomly generated initialization vector.

The solution is a blind index. Instead of searching the encrypted `nik` column, you store a deterministic SHA-256 hash of the NIK in the separate `nik_hash` column. A SHA-256 hash of a given NIK always produces the same 64-character hex string. When searching, you hash the search term the same way and compare hashes. Because hashing is deterministic, the comparison works reliably. Because hashing is one-way, an attacker who obtains `nik_hash` cannot reconstruct the original NIK from it.

### Update the Model

To compute and store `nik_hash` automatically whenever a NIK is assigned, you need a custom `Attribute` mutator. This mutator replaces the `'nik' => 'encrypted'` cast entry, because the `encrypted` cast can only encrypt the value. When setting a field must also update a second column, a cast is not enough; a full `Attribute` mutator takes over.

Open `app/Models/Resident.php`. The change involves two parts: removing `nik` from `casts()`, and adding a `nik()` method that handles both encryption and the hash.

**Before (your current `casts()` method):**

```php
protected function casts(): array
{
    return [
        'nik'           => 'encrypted',
        'address'       => 'encrypted',
        'date_of_birth' => 'date',
    ];
}
```

**After (replace with):**

```php
protected function casts(): array
{
    return [
        // nik is now fully managed by the nik() attribute mutator below
        'address'       => 'encrypted',
        'date_of_birth' => 'date',
    ];
}
```

Now add the `nik()` method. Your complete updated model should look like this:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Crypt;

#[Fillable(['name', 'nik', 'date_of_birth', 'address'])]
class Resident extends Model
{
    protected function casts(): array
    {
        return [
            'address'       => 'encrypted',
            'date_of_birth' => 'date',
        ];
    }

    /**
     * Handle encryption and blind index for NIK in a single operation.
     *
     * The 'encrypted' cast encrypts one column at a time. When setting
     * a field must also write to a second column (nik_hash), a custom
     * Attribute mutator is the right tool.
     *
     * Returning an array from the `set` function tells Eloquent to write
     * all provided key-value pairs as individual columns in the same save
     * operation. No extra query is needed.
     */
    protected function nik(): Attribute
    {
        return Attribute::make(
            get: fn (?string $value) => $value ? Crypt::decryptString($value) : null,
            set: fn (?string $value) => [
                'nik'      => $value ? Crypt::encryptString($value) : null,
                'nik_hash' => $value ? hash('sha256', $value) : null,
            ]
        );
    }
}
```

The `get` function decrypts the stored ciphertext when you read `$resident->nik`. The `set` function encrypts the incoming value for the `nik` column and simultaneously computes the SHA-256 hash for `nik_hash`. Eloquent receives both columns as a single array and persists them together. Your controller still calls `Resident::create(['nik' => '3273010101900001'])`, and both `nik` and `nik_hash` are written automatically.

### Update the Controller

Open `app/Http/Controllers/ResidentController.php` and make two targeted changes.

**Update `index()` to filter by `nik_hash`.**

**Before:**

```php
public function index(Request $request): View
{
    $residents = Resident::latest()->get();

    return view('residents.index', compact('residents'));
}
```

**After:**

```php
public function index(Request $request): View
{
    $residents = Resident::query()
        ->when(
            $request->filled('nik'),
            // Hash the search term exactly as the model hashes on save
            fn ($q) => $q->where('nik_hash', hash('sha256', $request->nik))
        )
        ->latest()
        ->get();

    return view('residents.index', compact('residents'));
}
```

The `when()` clause only applies the filter when the `nik` query parameter is present and non-empty. When searching, the incoming NIK is hashed with the same SHA-256 algorithm used during save, and the result is compared against the `nik_hash` column. No encrypted column is read or compared during this query.

**Update `store()` to enforce NIK uniqueness.**

The standard `Rule::unique('residents', 'nik')` rule cannot work here because the `nik` column holds ciphertext. Instead, a closure validator hashes the incoming NIK and checks whether that hash already exists in `nik_hash`.

**Before:**

```php
public function store(Request $request): RedirectResponse
{
    $validated = $request->validate([
        'name'          => ['required', 'string', 'max:255'],
        'nik'           => ['required', 'digits:16'],
        'date_of_birth' => ['required', 'date'],
        'address'       => ['required', 'string', 'max:1000'],
    ]);

    Resident::create($validated);

    return redirect()
        ->route('residents.index')
        ->with('success', 'Resident data has been saved.');
}
```

**After:**

```php
public function store(Request $request): RedirectResponse
{
    $validated = $request->validate([
        'name'          => ['required', 'string', 'max:255'],
        'nik'           => [
            'required',
            'digits:16',
            // Rule::unique cannot compare against an encrypted column.
            // We hash the incoming NIK and check for an existing match in nik_hash.
            function (string $attribute, mixed $value, \Closure $fail) {
                if (Resident::where('nik_hash', hash('sha256', $value))->exists()) {
                    $fail('This NIK is already registered.');
                }
            },
        ],
        'date_of_birth' => ['required', 'date'],
        'address'       => ['required', 'string', 'max:1000'],
    ]);

    Resident::create($validated);

    return redirect()
        ->route('residents.index')
        ->with('success', 'Resident data has been saved.');
}
```

## Step 7: Try It Out - Search and Uniqueness {#step-7-try-it-out-search-and-uniqueness}

Restart the server if it is not running. If you registered residents in Step 5, those records were saved before the `nik()` mutator existed, so their `nik_hash` column is `NULL`. Register at least one new resident now so you have a record with a valid `nik_hash`.

Open `http://127.0.0.1:8000/residents`, type the NIK you just registered into the search box, and submit. The table should filter to show only that resident.

Try searching for a NIK that is not in the database. The page should show "No residents found."

Try registering the same NIK a second time. You should see the validation error "This NIK is already registered."

To confirm the blind index is stored correctly, open Tinker:

```bash
php artisan tinker
```

```php
$r = App\Models\Resident::latest()->first();
$r->nik;
$r->nik_hash;
hash('sha256', $r->nik);
```

Expected output:

```
= "3273010101900002"
= "1a79a4d60de6718e8e5b326e338ae533ab820eea8697a69b57f4b6c948586e74"
= "1a79a4d60de6718e8e5b326e338ae533ab820eea8697a69b57f4b6c948586e74"
```

The last two lines are identical: the stored `nik_hash` matches the result of hashing the decrypted NIK manually. Exit Tinker with `exit`.

## Step 8: Write Pest Tests {#step-8-write-pest-tests}

Create the test file:

```bash
php artisan make:test ResidentEncryptionTest
```

Open `tests/Feature/ResidentEncryptionTest.php` and replace its content:

```php
<?php

use App\Models\Resident;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;

uses(RefreshDatabase::class);

// Helper to generate valid resident payload; override specific keys as needed
function residentData(array $overrides = []): array
{
    return array_merge([
        'name'          => 'Budi Santoso',
        'nik'           => '3273010101900001',
        'date_of_birth' => '1990-05-15',
        'address'       => 'Jl. Merdeka No. 1, Jakarta Pusat',
    ], $overrides);
}

it('creates a resident and redirects to the index page', function () {
    $response = $this->post(route('residents.store'), residentData());

    $response->assertRedirect(route('residents.index'));
    $this->assertDatabaseHas('residents', ['name' => 'Budi Santoso']);
});

it('stores NIK as encrypted ciphertext in the database', function () {
    Resident::create(residentData());

    // Bypass Eloquent to read the raw value as stored on disk
    $rawNik = DB::table('residents')->where('name', 'Budi Santoso')->value('nik');

    // The raw column value must not be the plain NIK
    expect($rawNik)->not->toBe('3273010101900001');

    // It must be a valid Laravel ciphertext that decrypts back to the original
    expect(Crypt::decryptString($rawNik))->toBe('3273010101900001');
});

it('decrypts NIK automatically when accessed via the Eloquent model', function () {
    Resident::create(residentData());

    $resident = Resident::where('name', 'Budi Santoso')->first();

    // The Eloquent model attribute should return plain NIK, not ciphertext
    expect($resident->nik)->toBe('3273010101900001');
});

it('stores address as encrypted ciphertext in the database', function () {
    Resident::create(residentData());

    $rawAddress = DB::table('residents')->where('name', 'Budi Santoso')->value('address');

    expect($rawAddress)->not->toBe('Jl. Merdeka No. 1, Jakarta Pusat');
    expect(Crypt::decryptString($rawAddress))->toBe('Jl. Merdeka No. 1, Jakarta Pusat');
});

it('saves nik_hash as the SHA-256 hash of the plain NIK', function () {
    Resident::create(residentData());

    $nikHash = DB::table('residents')->where('name', 'Budi Santoso')->value('nik_hash');

    // nik_hash must equal the SHA-256 of the plain NIK, not of the ciphertext
    expect($nikHash)->toBe(hash('sha256', '3273010101900001'));
});

it('finds a resident by NIK using the blind index search', function () {
    Resident::create(residentData());
    Resident::create(residentData([
        'name' => 'Siti Rahayu',
        'nik'  => '3273010101900002',
    ]));

    $response = $this->get(route('residents.index', ['nik' => '3273010101900001']));

    $response->assertOk()
        ->assertSee('Budi Santoso')
        ->assertDontSee('Siti Rahayu');
});

it('rejects a duplicate NIK at validation', function () {
    Resident::create(residentData());

    $response = $this->post(route('residents.store'), residentData());

    $response->assertSessionHasErrors('nik');
});

it('validates that NIK must be exactly 16 digits', function () {
    $response = $this->post(route('residents.store'), residentData(['nik' => '12345']));

    $response->assertSessionHasErrors('nik');
});

it('shows the resident detail page with the decrypted NIK', function () {
    $resident = Resident::create(residentData());

    $response = $this->get(route('residents.show', $resident));

    $response->assertOk()
        ->assertSee('Budi Santoso')
        ->assertSee('3273010101900001'); // Decrypted NIK visible in the view
});
```

Run the suite:

```bash
./vendor/bin/pest tests/Feature/ResidentEncryptionTest.php
```

Expected output:

```
$ ./vendor/bin/pest tests/Feature/ResidentEncryptionTest.php

   PASS  Tests\Feature\ResidentEncryptionTest
  ✓ it creates a resident and redirects to the index page                0.17s  
  ✓ it stores NIK as encrypted ciphertext in the database                0.02s  
  ✓ it decrypts NIK automatically when accessed via the Eloquent model   0.02s  
  ✓ it stores address as encrypted ciphertext in the database            0.02s  
  ✓ it saves nik_hash as the SHA-256 hash of the plain NIK               0.02s  
  ✓ it finds a resident by NIK using the blind index search              0.03s  
  ✓ it rejects a duplicate NIK at validation                             0.02s  
  ✓ it validates that NIK must be exactly 16 digits                      0.02s  
  ✓ it shows the resident detail page with the decrypted NIK             0.02s  

  Tests:    9 passed (19 assertions)
  Duration: 0.39s

```

All nine tests pass, covering encryption, decryption, blind index integrity, search, uniqueness validation, and UI rendering.

## How Eloquent Encrypted Cast Works Under the Hood {#how-eloquent-encrypted-cast-works}

Understanding the mechanism helps you make better decisions about when the `encrypted` cast is sufficient and when you need a custom `Attribute` mutator instead.

When you declare `'nik' => 'encrypted'` in `casts()`, Eloquent registers the built-in `EncryptedCast` class for that attribute. This class implements the `CastsAttributes` interface with two methods.

The `set` method calls `Crypt::encryptString($value)`. Under the hood, `Crypt` uses AES-256-CBC with your `APP_KEY` as the secret. The output is a JSON structure containing the initialization vector (IV), the ciphertext, and a MAC (message authentication code), all base64-encoded into a single string. Because the IV is generated randomly for every encryption call, the same plain NIK produces a different ciphertext every time it is saved. This is why direct SQL comparison is impossible: two identical NIKs produce two different ciphertexts, so `WHERE nik = 'eyJpdiI6...'` will never find a match for a freshly encrypted search term.

The `get` method calls `Crypt::decryptString($value)`. It first verifies the MAC to confirm the value was not modified after being stored. If the MAC check fails, Laravel throws a `DecryptException`. This means you cannot silently corrupt encrypted data; any tampering is detected on read.

Laravel also supports compound encrypted casts. Declaring `'config' => 'encrypted:array'` will JSON-encode an array and then encrypt the resulting string before storing it. On read, it decrypts and then JSON-decodes. This lets you encrypt complex structures like arrays or objects in a single `TEXT` column.

One operational note: `APP_KEY` drives both session/cookie encryption and model encrypted casts. If you rotate `APP_KEY`, all existing encrypted database values become unreadable until they are re-encrypted with the new key. If your security policy requires frequent `APP_KEY` rotation, use `Model::encryptUsing()` in `AppServiceProvider` to register a separate `Encrypter` instance driven by its own dedicated key (stored as `DB_ENCRYPTION_KEY` in your `.env` file). The encrypted cast will use that separate key, leaving `APP_KEY` free to rotate independently.

## The Search Problem: Why Encrypted Fields Cannot Be Queried Directly {#the-search-problem}

This section clarifies a fundamental limitation that often surprises developers when they first use encrypted casts in a production application.

When you run `SELECT * FROM residents WHERE nik = '3273010101900001'`, the database compares stored bytes against the search term. For an encrypted column, the stored value is a long base64-encoded ciphertext. The search term is a plain NIK. They will never match. You also cannot encrypt the search term and compare ciphertexts, because two encryptions of the same NIK produce different ciphertexts due to the random IV.

The blind index pattern solves this problem for exact-match lookups. You store a deterministic, one-way hash of the sensitive value alongside the encrypted value. Hashing is deterministic: the same NIK always produces the same hash. The SHA-256 hash is also irreversible: an attacker who obtains `nik_hash` values cannot reconstruct the original NIK from them.

The limitation of a blind index is that it only supports exact matches. Partial matches (`WHERE nik LIKE '3273%'`) and range queries are not possible with this approach. For use cases requiring full-text search across encrypted fields, more advanced techniques like order-preserving encryption or searchable symmetric encryption are needed, but those are beyond the scope of this tutorial. For the vast majority of applications, exact-match search via blind index is the right tool.

## Conclusion {#conclusion}

You have built a resident data application that encrypts sensitive fields at the model level and makes them searchable through a deterministic blind index. Here are the key takeaways:

- **The `encrypted` cast requires one line in `casts()`.** Declaring `'nik' => 'encrypted'` in the model's `casts()` method is all you need for automatic encryption on write and decryption on read.
- **Encrypted columns must use `TEXT`, not `VARCHAR`.** The ciphertext produced by AES-256-CBC is longer than the original value and its length is unpredictable. A `VARCHAR(255)` column silently truncates and corrupts data.
- **Decryption is transparent to the rest of the application.** Once the cast is declared, `$resident->nik` always returns plain NIK in every controller, view, and test. No `Crypt::decryptString()` call is needed anywhere outside the model.
- **Encrypted values cannot be queried with SQL `WHERE`.** AES-256-CBC produces a different ciphertext on every call, making direct column comparison impossible.
- **A blind index enables exact-match search.** Storing a SHA-256 hash of the NIK in a separate column allows searching by NIK without ever touching the encrypted column.
- **A custom `Attribute` mutator replaces `encrypted` cast when side effects are needed.** When setting a field must also write to another column, return an array from the `set` function. Eloquent persists all array entries as individual columns in the same operation.
- **`APP_KEY` is the default encryption key for all encrypted casts.** If you need to rotate `APP_KEY` independently from your database encryption, use `Model::encryptUsing()` in `AppServiceProvider` to supply a dedicated key for model-level encryption.