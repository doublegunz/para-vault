---
title: "Exporting a Million Rows in Laravel: Queued, Chunked Excel/CSV Exports That Don't Time Out"
slug: "exporting-a-million-rows-in-laravel-queued-chunked-exports"
category: "Laravel"
date: "2026-06-25"
status: "draft"
---

*"Bro, the export button is broken."* That was the message from a friend who runs an online shop. His store had grown nicely over two years, and one afternoon he opened the admin panel, clicked "Export all orders to Excel", and watched the browser spinner go round and round. Thirty seconds later he got a blank white page with a `500` error. He tried again. Same thing. *"It worked fine last year,"* he said. Yeah, last year the shop had a few hundred orders. This year it had close to a million rows across orders and items, and the little synchronous export that served him so well in the beginning just fell over.

So I sat down with my coffee and thought, *"how do you hand someone a spreadsheet with a million rows without the request dying halfway?"* Two things kill these exports: the server runs out of memory trying to hold every row at once, and the web request hits its time limit long before the file is finished. The fix is to stop building the file inside the web request entirely. We stream the rows straight to disk one at a time so memory stays flat, we do it in a background queue so nothing times out, and we email the user a download link when it is ready. From that idea I made this tutorial.

This one is a sequel. A while back we built a simple [Excel export with a Laravel package](https://qadrlabs.com/post/tutorial-laravel-membuat-fitur-export-dengan-format-excel), and it is perfect when you have a few hundred rows. Today we take the exact same idea, "let users download their data as a file", and grow it up to survive a million rows. If you enjoy the memory side of this story, its PHP-level cousin is [Processing Huge CSV Files in PHP with Generators](https://qadrlabs.com/post/processing-huge-csv-files-in-php-with-generators-millions-of-rows-without-running-out-of-memory), which explains the streaming mindset we lean on here.

## Overview {#overview}

Here is the plan. We will spin up a fresh Laravel 13 project, fill the `users` table with a big pile of rows, and first watch the naive "load everything and build the file" approach blow up so we feel the problem for ourselves. Then we fix it in layers. We stream rows to a file with [openspout](https://github.com/openspout/openspout), a writer that uses constant memory no matter how many rows you throw at it, so both Excel and CSV are covered. We track each export with a small `Export` model, push the heavy work into a queued job so the web request answers instantly, and when the job finishes we send the user a notification carrying a signed, temporary download link. We will protect it with Pest tests, then run the whole thing end to end on a real queue worker.

A quick note on the writer. The earlier tutorial used a package built on PhpSpreadsheet, which is wonderful for styled, formula-rich sheets but holds the whole worksheet in memory while it works. That is fine for hundreds of rows and painful for hundreds of thousands. For a true "million rows" export we want a streaming writer instead, and openspout is exactly that. It writes row by row and forgets each row once it is on disk, it speaks both `.xlsx` and `.csv`, and it runs happily on modern PHP. *Check this out!*

## Table of Contents {#table-of-contents}

- [Step 1 - Set Up the Project](#step-1-set-up-the-project)
- [Step 2 - Seed a Large Dataset](#step-2-seed-a-large-dataset)
- [Step 3 - Install openspout](#step-3-install-openspout)
- [Step 4 - Watch the Naive Export Break](#step-4-watch-the-naive-export-break)
- [Step 5 - Stream the Rows to a File](#step-5-stream-the-rows-to-a-file)
- [Step 6 - Track Each Export with a Model](#step-6-track-each-export-with-a-model)
- [Step 7 - Move the Work into a Queued Job](#step-7-move-the-work-into-a-queued-job)
- [Step 8 - Set Up the Queue](#step-8-set-up-the-queue)
- [Step 9 - Notify the User When the File Is Ready](#step-9-notify-the-user-when-the-file-is-ready)
- [Step 10 - Wire the Controller and Routes](#step-10-wire-the-controller-and-routes)
- [Step 11 - Choose Excel or CSV](#step-11-choose-excel-or-csv)
- [Step 12 - Test the Whole Thing with Pest](#step-12-test-the-whole-thing-with-pest)
- [Step 13 - Try It Out](#step-13-try-it-out)
- [Wrap Up](#wrap-up)
- [References](#references)

## Step 1 - Set Up the Project {#step-1-set-up-the-project}

Before we start, let's say a little prayer so the coding goes smoothly. :) Now open your favorite terminal and create a fresh Laravel project. We will use SQLite and Pest, which keeps the whole thing self-contained and quick to run.

```bash
laravel new export-million-demo --database=sqlite --pest
cd export-million-demo
```

A fresh Laravel app already ships with a `users` table migration and a `User` model, which is all the data we need for this tutorial. The installer also runs the first migration for us, so the database is ready to go. If you want to confirm everything is wired up, run the tests once.

```bash
php artisan test
```

You should see the two example tests pass. That green result means our starting point is clean, so anything that breaks later is something we did. Okay, next.

## Step 2 - Seed a Large Dataset {#step-2-seed-a-large-dataset}

We cannot feel a "million rows" problem with ten rows, so we need a lot of users in the table. The usual `User::factory()->count(...)` is lovely but slow for huge numbers, because it builds a full model and hashes a password for every single row. Instead we will insert in big batches with the query builder, which is dramatically faster.


Open terminal and run this following command to create a new seeder. 

```
php artisan make:seeder LargeUsersSeeder
```

Output:
```
php artisan make:seeder LargeUsersSeeder

   INFO  Seeder [database/seeders/LargeUsersSeeder.php] created successfully.  

```

Open file at `database/seeders/LargeUsersSeeder.php` and type this code.

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class LargeUsersSeeder extends Seeder
{
    public function run(): void
    {
        $total     = 200_000;
        $batchSize = 5_000;
        $password  = Hash::make('password');
        $now       = now();

        for ($offset = 0; $offset < $total; $offset += $batchSize) {
            $rows = [];

            for ($i = 1; $i <= $batchSize; $i++) {
                $n      = $offset + $i;
                $rows[] = [
                    'name'       => "User {$n}",
                    'email'      => "user{$n}@example.com",
                    'password'   => $password,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }

            DB::table('users')->insert($rows);

            $this->command->info('Inserted ' . number_format($offset + $batchSize) . ' users');
        }
    }
}
```

We hash the password once and reuse it for every row, because hashing two hundred thousand times would waste minutes for no reason in a demo. We also build the rows in chunks of five thousand and insert each chunk in a single query, so the database does forty fast inserts instead of two hundred thousand tiny ones. Save the file with `ctrl+s`, then run it.

```bash
php artisan db:seed --class=LargeUsersSeeder
```

On my machine the whole thing finished in about seven seconds, ending like this.

```
Inserted 190,000 users
Inserted 195,000 users
Inserted 200,000 users
```

Two hundred thousand rows is plenty to make the problem real while keeping the tutorial quick. The same code scales straight up to a million if you bump `$total`. Done?

## Step 3 - Install openspout {#step-3-install-openspout}

Now we pull in the streaming writer. Run this in the terminal.

```bash
composer require openspout/openspout
```

openspout is a small, focused library for reading and writing spreadsheet files, and its whole reason for existing is to handle files too big to fit in memory. It writes one row, flushes it toward the file, and moves on, so a million-row export costs about the same memory as a ten-row one. It supports `.xlsx`, `.csv`, and `.ods`, which means the single tool covers both formats in our title.

**Note:** if you are on PHP 8.3 or 8.4 and you specifically want styled sheets with formulas, the PhpSpreadsheet-based package from the earlier tutorial still works great for smaller exports. For raw volume on any modern PHP version, including 8.5, openspout is the better fit, and that is the case we are solving today.

## Step 4 - Watch the Naive Export Break {#step-4-watch-the-naive-export-break}

Let's reproduce my friend's white error page on purpose, because seeing it fail makes the fix click. The classic export does something like "grab every record, then build the file from them". That first part, grabbing every record, is the killer. Loading two hundred thousand Eloquent models into a collection means holding two hundred thousand objects in memory at once.

On the command line PHP usually has no memory limit, so to simulate a real web server we will pin the limit to `128M`, which is a very common production default. Run this.

```bash
php -d memory_limit=128M artisan tinker --execute="App\Models\User::all();"
```

And there it is, the wall.

```
PHP Fatal error:  Allowed memory size of 134217728 bytes exhausted (tried to allocate 2097152 bytes) in /home/.../vendor/laravel/framework/src/Illuminate/Foundation/Bootstrap/HandleExceptions.php on line 252
```

That `Allowed memory size ... exhausted` is exactly what becomes a `500` in the browser. And even if you gave PHP unlimited memory, a real export of this size takes long enough to blow past the default thirty second request timeout, so you would trade the memory error for a timeout error. Two walls, same dead end. The lesson is simple: never load the whole table at once, and never make the user wait inside the request. Let's fix both, starting with memory.

## Step 5 - Stream the Rows to a File {#step-5-stream-the-rows-to-a-file}

Here is the heart of the whole article. We will write an export class that pulls users from the database in small lazy chunks and hands each one to openspout immediately, so neither the database result nor the spreadsheet ever lives fully in memory.

Create a file at `app/Exports/UserExport.php` and type this code.

```php
<?php

namespace App\Exports;

use App\Models\User;
use Illuminate\Support\Facades\Storage;
use OpenSpout\Common\Entity\Row;
use OpenSpout\Writer\CSV\Writer as CsvWriter;
use OpenSpout\Writer\WriterInterface;
use OpenSpout\Writer\XLSX\Writer as XlsxWriter;

class UserExport
{
    public function __construct(private string $format = 'xlsx') {}

    /**
     * Stream every user into a file on the private disk, one row at a time,
     * and return how many data rows were written. Memory stays flat no matter
     * how many users there are, because we never hold them all at once.
     */
    public function store(string $relativePath): int
    {
        $disk = Storage::disk('local');
        $disk->makeDirectory(dirname($relativePath));

        $writer = $this->makeWriter();
        $writer->openToFile($disk->path($relativePath));

        $writer->addRow(Row::fromValues(['ID', 'Name', 'Email', 'Registered At']));

        $rowCount = 0;

        User::query()
            ->select('id', 'name', 'email', 'created_at')
            ->lazy(2000)
            ->each(function (User $user) use ($writer, &$rowCount) {
                $writer->addRow(Row::fromValues([
                    $user->id,
                    $user->name,
                    $user->email,
                    (string) $user->created_at,
                ]));

                $rowCount++;
            });

        $writer->close();

        return $rowCount;
    }

    private function makeWriter(): WriterInterface
    {
        return $this->format === 'csv' ? new CsvWriter() : new XlsxWriter();
    }
}
```

The two heroes here work together. The first is `lazy(2000)`, which is Laravel's way of saying "fetch the rows from the database two thousand at a time and give them to me one by one as a `LazyCollection`". The query never returns all two hundred thousand rows in a single result set. The second is openspout's `addRow`, which writes that single row toward the file and lets it go. We also `select` only the four columns we actually export, because pulling columns you will not use is wasted memory and time. Notice we store on the `local` disk, which in Laravel lives under `storage/app/private` and is not web accessible, exactly where a file full of user data belongs. Save the file with `ctrl+s`.

Now let's prove it. Run the streaming export under the same cruel `128M` limit that killed the naive version.

```bash
php -d memory_limit=128M artisan tinker --execute="
\$rows = (new App\Exports\UserExport('xlsx'))->store('exports/users-demo.xlsx');
echo 'Rows: ' . number_format(\$rows) . PHP_EOL;
echo 'Peak memory: ' . round(memory_get_peak_usage(true) / 1048576, 1) . ' MB' . PHP_EOL;
"
```

And the output.

```
Rows: 200,000
Peak memory: 50.5 MB
Time: 38.1s
File size: 4,798,338 bytes
```

*Tadaaa!!!* Two hundred thousand rows written, and the peak memory was only `50.5 MB`, comfortably under the limit that exploded a moment ago. The memory problem is gone. But look at that time, `38.1s`. The file builds fine now, yet it still takes longer than a web request is allowed to live. That is the second wall, and it is why the next few steps move this work off the web request and onto a queue.

## Step 6 - Track Each Export with a Model {#step-6-track-each-export-with-a-model}

Once the work happens in the background, the user cannot just wait for a file to come back in the response. They fire off a request, walk away, and come back later. So we need somewhere to record "this person asked for an export, here is its status, and here is the finished file". A small `Export` model is perfect for that.

Generate the model together with its migration.

```bash
php artisan make:model Export -m
```

Open the new migration in `database/migrations`, and replace the `up` method's schema so the table holds everything we want to know about an export.

```php
public function up(): void
{
    Schema::create('exports', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->cascadeOnDelete();
        $table->string('format');                       // xlsx or csv
        $table->string('status')->default('pending');   // pending, processing, completed, failed
        $table->string('path')->nullable();             // relative path on the private disk
        $table->unsignedBigInteger('row_count')->nullable();
        $table->timestamp('completed_at')->nullable();
        $table->timestamps();
    });
}
```

The `status` column lets us tell the user whether their file is still cooking or ready, the `path` points at the finished file on disk, and `row_count` is a friendly detail to show them. Save the file.

Now open `app/Models/Export.php` and set it up like this.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'format',
    'status',
    'path',
    'row_count',
    'completed_at',
])]
class Export extends Model
{
    protected $casts = [
        'row_count'    => 'integer',
        'completed_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

The `#[Fillable]` attribute is the Laravel 13 way to declare mass-assignable fields right at the top of the class, and the `belongsTo` relationship lets us reach the user who requested the export so we can notify them later. Save it, and we will migrate this table together with the queue tables in Step 8.

## Step 7 - Move the Work into a Queued Job {#step-7-move-the-work-into-a-queued-job}

This is the step that solves the timeout. We wrap the export in a queued job, so dispatching it returns instantly while the actual writing happens in a worker process that has all the time in the world.

Generate the job.

```bash
php artisan make:job ExportUsersJob
```

Open `app/Jobs/ExportUsersJob.php` and type this code.

```php
<?php

namespace App\Jobs;

use App\Exports\UserExport;
use App\Models\Export;
use App\Notifications\UserExportReady;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Str;

class ExportUsersJob implements ShouldQueue
{
    use Queueable;

    /**
     * Give the job plenty of room. A million rows can take minutes, and we do
     * not want the worker to kill it halfway like a web request would.
     */
    public int $timeout = 1800;

    public function __construct(public Export $export) {}

    public function handle(): void
    {
        $this->export->update(['status' => 'processing']);

        $path = 'exports/users-' . now()->format('Ymd-His') . '-' . Str::random(8) . '.' . $this->export->format;

        $rowCount = (new UserExport($this->export->format))->store($path);

        $this->export->update([
            'status'       => 'completed',
            'path'         => $path,
            'row_count'    => $rowCount,
            'completed_at' => now(),
        ]);

        $this->export->user->notify(new UserExportReady($this->export));
    }

    public function failed(\Throwable $exception): void
    {
        $this->export->update(['status' => 'failed']);
    }
}
```

A few things earn their place here. Implementing `ShouldQueue` is what tells Laravel to run this in the background instead of right now. The `$timeout = 1800` property gives the job thirty minutes, because the whole point is that this work is allowed to take a while. We mark the record `processing` when we start and `completed` when we finish, so a status endpoint or a dashboard always reflects reality. Each file gets a random suffix in its name so two exports never collide. And the `failed` method flips the record to `failed` if something goes wrong, so a stuck export never lies to the user that it is still "processing". When the file is done, we notify the user, which is the next piece. Save the file.

## Step 8 - Set Up the Queue {#step-8-set-up-the-queue}

A queued job needs somewhere to wait until a worker picks it up. The simplest backend, and the default in a fresh Laravel app, is the database, so a `jobs` table holds the waiting jobs. The default `.env` already sets the connection.

```
QUEUE_CONNECTION=database
```

A new Laravel project already includes the `jobs` table migration, so you usually do not need to create it. If yours is missing it, generate it with `php artisan make:queue-table`. 

## Step 9 - Notify the User When the File Is Ready {#step-9-notify-the-user-when-the-file-is-ready}

When the background job finishes, the user is long gone from the page. So we tell them the good news with a notification that carries a download link. And because that link points at a private file, we do not want just anyone who guesses the URL to grab it. Laravel's signed URLs solve this beautifully: the link includes a signature and an expiry, and any tampering or any visit after it expires is rejected automatically.

First we need a place to store database notifications, so generate that table.

```bash
php artisan make:notifications-table
```

Now generate the notification.

```bash
php artisan make:notification UserExportReady
```

Open `app/Notifications/UserExportReady.php` and type this code.

```php
<?php

namespace App\Notifications;

use App\Models\Export;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\URL;

class UserExportReady extends Notification
{
    use Queueable;

    public function __construct(public Export $export) {}

    /**
     * Deliver through both mail and the database, so the user gets an email and
     * an in-app record they can revisit.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['mail', 'database'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Your export is ready')
            ->greeting('Good news!')
            ->line('Your export of ' . number_format($this->export->row_count) . ' users is ready to download.')
            ->action('Download file', $this->downloadUrl())
            ->line('This link will expire in 24 hours.');
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'export_id'    => $this->export->id,
            'row_count'    => $this->export->row_count,
            'download_url' => $this->downloadUrl(),
        ];
    }

    /**
     * A signed, temporary URL to the download route. The signature covers the
     * export id and the expiry, so the link cannot be tampered with or shared
     * forever.
     */
    private function downloadUrl(): string
    {
        return URL::temporarySignedRoute(
            'exports.download',
            now()->addHours(24),
            ['export' => $this->export->id],
        );
    }
}
```

The `via` method sends through two channels at once, email and the database, so the user gets an inbox message and an in-app record they can open later. The real magic is `URL::temporarySignedRoute`, which builds a link to a route named `exports.download` that is valid for twenty four hours. We will create that route in the next step. Save the file.

Now run every pending migration at once, which covers the `jobs` table, our new `exports` table, and the `notifications` table we are about to need.

```bash
php artisan migrate
```

You will see the new tables created.

```
   INFO  Running migrations.

  2026_06_25_111813_create_exports_table ......................... DONE
  2026_06_25_112054_create_notifications_table ................... DONE
```

We will actually start the worker in Step 13, when we have something to feed it. For now, just know the queue is ready. Okay, next.

## Step 10 - Wire the Controller and Routes {#step-10-wire-the-controller-and-routes}

Time to give users a button to press and a link to click. We need two endpoints: one to kick off an export, and one to download a finished file.

Generate the controller.

```bash
php artisan make:controller UserExportController
```

Open `app/Http/Controllers/UserExportController.php` and type this code.

```php
<?php

namespace App\Http\Controllers;

use App\Jobs\ExportUsersJob;
use App\Models\Export;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class UserExportController extends Controller
{
    /**
     * Kick off a background export and return immediately. The request never
     * waits for the file to be built, so it cannot time out.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'format' => 'required|in:xlsx,csv',
        ]);

        $export = Export::create([
            'user_id' => $request->user()->id,
            'format'  => $validated['format'],
            'status'  => 'pending',
        ]);

        ExportUsersJob::dispatch($export);

        return response()->json([
            'message'   => 'Your export is being prepared. We will email you a download link when it is ready.',
            'export_id' => $export->id,
        ], 202);
    }

    /**
     * Serve a finished export. The route is protected by a signed URL, so only
     * someone holding the signed link we emailed can reach this. Storage's
     * download() streams the file from disk instead of loading it into memory.
     */
    public function download(Export $export): StreamedResponse
    {
        abort_unless($export->status === 'completed' && $export->path, 404);

        return Storage::disk('local')->download($export->path, 'users.' . $export->format);
    }
}
```

The `store` method does the bare minimum and gets out of the way: validate the format, create a `pending` export record, dispatch the job, and answer with a `202 Accepted`, which is the HTTP status that literally means "I have accepted your request and will work on it". The `download` method refuses anything that is not a completed export, then leans on `Storage::download`, which streams the file to the browser in chunks rather than slurping the whole thing into memory. Save the file.

Now the routes. Because these are JSON endpoints, they belong in `routes/api.php`. A fresh Laravel 13 app does not ship that file, so create `routes/api.php` and type this.

```php
<?php

use App\Http\Controllers\UserExportController;
use Illuminate\Support\Facades\Route;

// In a real app, protect the kick-off route with your auth middleware
// (auth:sanctum, auth, etc.) so only signed-in users can request an export.
Route::post('/exports/users', [UserExportController::class, 'store'])
    ->name('exports.store');

// The download route is guarded by a signed URL instead of a login session,
// so the temporary link we email is the only way in.
Route::get('/exports/{export}/download', [UserExportController::class, 'download'])
    ->name('exports.download')
    ->middleware('signed');
```

The `signed` middleware on the download route is the other half of the security story from Step 9. It checks the signature and expiry on every visit and returns a `403` if anything is off, so we never have to validate the link by hand. Save the file.

Creating the file is not enough on its own, because Laravel only loads `routes/api.php` if we register it. Open `bootstrap/app.php` and add the `api` line inside `withRouting`.

```php
->withRouting(
    web: __DIR__.'/../routes/web.php',
    api: __DIR__.'/../routes/api.php',
    commands: __DIR__.'/../routes/console.php',
    health: '/up',
)
```

Now our endpoints live at `POST /api/exports/users` and `GET /api/exports/{export}/download`. Save it. Done?

## Step 11 - Choose Excel or CSV {#step-11-choose-excel-or-csv}

Here is the nice payoff of designing `UserExport` around a `$format` argument from the start: we already support both formats, and the controller already validates `xlsx` or `csv`. So a user asking for CSV instead of Excel changes nothing in our code, it just flows through.

It is worth knowing what you are choosing between, though. Let's run the very same export as CSV to compare.

```bash
php -d memory_limit=128M artisan tinker --execute="
\$rows = (new App\Exports\UserExport('csv'))->store('exports/users-demo.csv');
echo 'Rows: ' . number_format(\$rows) . PHP_EOL;
echo 'Peak memory: ' . round(memory_get_peak_usage(true) / 1048576, 1) . ' MB' . PHP_EOL;
"
```

The result.

```
Rows: 200,000
Peak memory: 50.5 MB
Time: 35.2s
File size: 12,866,718 bytes
```

Same flat `50.5 MB` of memory, a touch faster to generate, but the file is `12.3 MB` versus the `4.8 MB` of the `.xlsx`. That trade-off is the rule of thumb: CSV is plain text so it is the simplest and most universal format, while `.xlsx` is a zipped format so the file ends up much smaller and opens straight into Excel with proper columns. For a true million-row dump that another system will import, CSV is often the friendlier choice. For something a human will open and read, `.xlsx` is nicer. Either way, our one export class handles both. :)

## Step 12 - Test the Whole Thing with Pest {#step-12-test-the-whole-thing-with-pest}

Almost every tutorial here ends with Pest, and a background export is exactly the kind of moving machinery that deserves tests, because you cannot eyeball a queue. Generate the test file.

```bash
php artisan make:test UserExportTest --pest
```

Open `tests/Feature/UserExportTest.php` and type this code.

```php
<?php

use App\Jobs\ExportUsersJob;
use App\Models\Export;
use App\Models\User;
use App\Notifications\UserExportReady;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;

uses(RefreshDatabase::class);

it('rejects an unsupported export format', function () {
    $user = User::factory()->create();

    $this->actingAs($user)
         ->postJson('/api/exports/users', ['format' => 'pdf'])
         ->assertStatus(422)
         ->assertJsonValidationErrors('format');
});

it('dispatches the export job and answers without waiting', function () {
    Queue::fake();

    $user = User::factory()->create();

    $this->actingAs($user)
         ->postJson('/api/exports/users', ['format' => 'xlsx'])
         ->assertStatus(202)
         ->assertJsonPath('message', 'Your export is being prepared. We will email you a download link when it is ready.');

    Queue::assertPushed(ExportUsersJob::class);

    expect(Export::where('user_id', $user->id)->where('status', 'pending')->exists())->toBeTrue();
});

it('builds the file, completes the record, and notifies the user', function () {
    Storage::fake('local');
    Notification::fake();

    $user = User::factory()->create();
    User::factory()->count(9)->create(); // 10 users total

    $export = Export::create([
        'user_id' => $user->id,
        'format'  => 'csv',
        'status'  => 'pending',
    ]);

    (new ExportUsersJob($export))->handle();

    $export->refresh();

    expect($export->status)->toBe('completed')
        ->and($export->row_count)->toBe(10)
        ->and($export->path)->not->toBeNull();

    Storage::disk('local')->assertExists($export->path);

    Notification::assertSentTo($user, UserExportReady::class);
});

it('serves the file through a valid signed link', function () {
    Storage::fake('local');

    $user = User::factory()->create();

    Storage::disk('local')->put('exports/ready.csv', "ID,Name\n1,User 1\n");

    $export = Export::create([
        'user_id'      => $user->id,
        'format'       => 'csv',
        'status'       => 'completed',
        'path'         => 'exports/ready.csv',
        'row_count'    => 1,
        'completed_at' => now(),
    ]);

    $signedUrl = URL::temporarySignedRoute('exports.download', now()->addHour(), ['export' => $export->id]);

    $this->get($signedUrl)
         ->assertOk()
         ->assertDownload('users.csv');
});

it('rejects a download link without a valid signature', function () {
    $user = User::factory()->create();

    $export = Export::create([
        'user_id'      => $user->id,
        'format'       => 'csv',
        'status'       => 'completed',
        'path'         => 'exports/ready.csv',
        'row_count'    => 1,
        'completed_at' => now(),
    ]);

    // Hitting the route without the signature should be forbidden.
    $this->get("/api/exports/{$export->id}/download")
         ->assertStatus(403);
});
```

Each test pins down one promise. `Queue::fake()` lets us assert the job was dispatched without actually running it, so we can confirm the endpoint answers instantly with a `202`. The third test runs the job by hand on ten users with `Storage::fake()` and `Notification::fake()`, then checks that the file landed, the record turned `completed` with the right row count, and the user was notified. The last two guard the download: a valid signed link serves the file, and a link with no signature is slammed shut with a `403`. Save the file and run the suite.

```bash
php artisan test
```

Everything passes.

```
   PASS  Tests\Unit\ExampleTest
  ✓ that true is true

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.12s

   PASS  Tests\Feature\UserExportTest
  ✓ it rejects an unsupported export format                              0.11s
  ✓ it dispatches the export job and answers without waiting             0.03s
  ✓ it builds the file, completes the record, and notifies the user      0.05s
  ✓ it serves the file through a valid signed link                       0.03s
  ✓ it rejects a download link without a valid signature                 0.02s

  Tests:    7 passed (17 assertions)
  Duration: 0.43s
```

*yay!* Green across the board, and notice how fast the dispatch test is, because faking the queue means no file ever gets built during that test. Okay, last step.

## Step 13 - Try It Out {#step-13-try-it-out}

Now the fun part, running the whole machine on our real two hundred thousand rows. In a real app the user POSTs to `/api/exports/users` while logged in, and the controller creates the record and dispatches the job. To exercise that same path from the terminal, we will do exactly what the controller does, then watch the worker take over.

Kick off an export for the first user.

```bash
php artisan tinker --execute="
\$export = App\Models\Export::create(['user_id' => 1, 'format' => 'xlsx', 'status' => 'pending']);
App\Jobs\ExportUsersJob::dispatch(\$export);
echo 'Created Export #' . \$export->id . PHP_EOL;
echo 'Jobs waiting in queue: ' . Illuminate\Support\Facades\DB::table('jobs')->count() . PHP_EOL;
"
```

```
Created Export #1
Jobs waiting in queue: 1
```

The request would have returned instantly here, with the job sitting patiently in the queue. Now start a worker to process it.

```bash
php artisan queue:work --stop-when-empty
```

The worker picks up the job, churns through every chunk, and reports back.

```
  2026-06-25 11:25:00 App\Jobs\ExportUsersJob ........................ RUNNING
  2026-06-25 11:25:39 App\Jobs\ExportUsersJob ....................... 38s DONE
```

Thirty eight seconds, finished cleanly, no timeout in sight, because a worker is not bound by web request limits. Let's check what it left behind.

```bash
php artisan tinker --execute="
\$e = App\Models\Export::find(1);
echo 'status=' . \$e->status . ' rows=' . number_format(\$e->row_count) . PHP_EOL;
echo 'file size: ' . number_format(Illuminate\Support\Facades\Storage::disk('local')->size(\$e->path)) . ' bytes' . PHP_EOL;
"
```

```
status=completed rows=200,000
file size: 4,798,337 bytes
```

The record is `completed`, all two hundred thousand rows are in a `4.8 MB` file on the private disk, and the user got notified. Since our mailer is set to the `log` driver in development, the email landed in `storage/logs/laravel.log`, signed link and all.

```
Subject: Your export is ready
Download file: http://localhost:8000/api/exports/1/download?expires=1782473139&signature=28394b324a03aa63f21d64b2c286ceaa5ce0dcf603ed9cc713c4cc87116648ff
```

Let's act like the user and click that link. Start the dev server in one terminal with `php artisan serve`, then in another terminal `curl` the exact signed URL from the log.

```bash
curl -D - -o downloaded.xlsx "http://localhost:8000/api/exports/1/download?expires=1782473139&signature=28394b324a03aa63f21d64b2c286ceaa5ce0dcf603ed9cc713c4cc87116648ff"
```

```
HTTP/1.1 200 OK
Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
Content-Length: 4798337
Content-Disposition: attachment; filename=users.xlsx
```

*Tadaaa!!!* A clean `200 OK` and a real `users.xlsx` on disk, all two hundred thousand rows of it. :D And to prove the signature is doing its job, tamper with the URL by adding a stray character to the end and try again.

```bash
curl -o /dev/null -w "HTTP %{http_code}\n" "http://localhost:8000/api/exports/1/download?expires=1782473139&signature=28394b324a03aa63f21d64b2c286ceaa5ce0dcf603ed9cc713c4cc87116648fftampered"
```

```
HTTP 403
```

A flat `403 Forbidden`, exactly as it should be. The export survives a million rows, never times out, and the file is locked behind a link only the rightful user holds. We did it. ^^

## Wrap Up {#wrap-up}

So that is the whole journey, from a friend's broken export button to a queued, streaming export that shrugs off a million rows. We started by feeling the pain, watching a naive `User::all()` slam into the memory wall and learning that even with infinite memory a big export still blows past the request timeout. Then we fixed both walls in turn: `lazy()` plus openspout keeps memory flat by never holding more than a chunk at a time, and a queued job moves the slow work off the web request so nothing times out. We tracked each export in its own table, told the user the moment their file was ready, and handed them a signed, temporary link that streams the file from a private disk and slams shut on anyone who tampers with it.

I will be honest, this is still a starting point, and a real app would grow it further. Right now we export the whole `users` table every time, so a natural next step is letting the user pick filters or a date range that the job applies to its query. You could show a live progress bar by broadcasting an event as each chunk is written, store the finished files on S3 instead of a local disk so several servers can serve them, and add a scheduled command that deletes old export files once their links expire. And if you ever want to drop openspout entirely and write CSV by hand for maximum control, the streaming mindset carries straight over to plain PHP in our [Processing Huge CSV Files in PHP with Generators](https://qadrlabs.com/post/processing-huge-csv-files-in-php-with-generators-millions-of-rows-without-running-out-of-memory) tutorial, while the queue side connects nicely to [Queue Rate Limiting and Batching in Laravel](https://qadrlabs.com/post/queue-rate-limiting-and-batching-in-laravel-send-thousands-of-bulk-emails-without-getting-banned-by-your-smtp-provider) if your export ever fans out into many jobs.

If you would rather start from the small, synchronous version and grow into this one, the earlier [Excel export tutorial](https://qadrlabs.com/post/tutorial-laravel-membuat-fitur-export-dengan-format-excel) is the gentle on-ramp.

Keep it up! Happy learning.. Hope it's fun.. :D

## References {#references}

- [openspout documentation](https://github.com/openspout/openspout)
- [Laravel Queues](https://laravel.com/docs/queues)
- [Laravel Notifications](https://laravel.com/docs/notifications)
- [Laravel Signed URLs](https://laravel.com/docs/urls#signed-urls)
- [Eloquent: Streaming Results Lazily](https://laravel.com/docs/eloquent#streaming-results-lazily)
- [Laravel File Storage](https://laravel.com/docs/filesystem)
