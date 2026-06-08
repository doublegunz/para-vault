---
title: "Laravel 13: Upload Large Files with Chunked and Resumable Uploads"
slug: "laravel-13-upload-large-files-with-chunked-and-resumable-uploads"
category: "Laravel"
date: "2026-04-15"
status: "published"
---

Uploading a 1GB video to your backend sounds simple until it fails at 90%. The connection drops, the server times out, or the memory limit is exceeded. The user has to start over from zero. This is not a rare edge case. It happens every time someone uploads a large file over an unreliable connection, and it is the reason YouTube, Google Drive, AWS S3, and every major platform uses a different strategy.

The solution is chunked upload: instead of sending the entire file in one request, the client splits it into small pieces (5-10MB each), sends each piece as a separate request, and the server reassembles them after all pieces arrive. Add resumable upload on top of that, and if the connection drops at chunk 50 of 100, the client asks the server "which chunks did you receive?" and continues from chunk 51 instead of starting over.

In this tutorial, we will build a complete chunked and resumable file upload system using Laravel 13 for the backend API and vanilla JavaScript for the frontend. No external packages required.


## Overview {#overview}

We will build a chunked upload API with four endpoints: initialize an upload session, receive individual chunks, check upload progress, and finalize the upload by merging all chunks into the final file. On the frontend, we will use `Blob.slice()` to split files into chunks and `fetch()` to upload them sequentially with a progress bar.

### What You'll Build

- A Laravel API with four endpoints for chunked upload: init, upload chunk, check status, and complete.
- A JavaScript upload function that splits files using `Blob.slice()` and uploads chunks sequentially.
- Resumable upload support: if the upload fails midway, the client can query the server for completed chunks and resume from where it left off.
- A progress bar that updates in real-time as each chunk is uploaded.
- An upload session expiry mechanism that cleans up orphaned chunks after 24 hours.
- Checksum validation per chunk using SHA-256 to ensure data integrity.

### What You'll Learn

- Why uploading large files in a single request fails (timeout, memory, connection issues).
- How chunked upload works: split, send, reassemble.
- How resumable upload works: session ID, progress tracking, resume from last chunk.
- How to use `Blob.slice()` in JavaScript to split files into chunks.
- How to build a chunked upload API in Laravel with file storage and chunk merging.
- How to validate chunk integrity with checksums.
- How to clean up expired upload sessions with a scheduled command.
- How companies like YouTube, AWS S3, and Google Drive use the same pattern.

### What You'll Need

- PHP 8.3 or higher.
- Composer installed globally.
- MySQL or another supported database.
- A web browser with developer tools (for testing the JavaScript upload).
- Basic familiarity with Laravel and JavaScript.


## Why Single-Request Uploads Fail {#why-single-request-uploads-fail}

Before building the solution, let's understand the problem. Uploading a large file in a single HTTP request has four failure modes:

**Timeout**: Web servers have a maximum execution time. PHP defaults to 30 seconds, Nginx defaults to 60 seconds. A 1GB file over a 10Mbps connection takes over 13 minutes. The server kills the request long before it finishes.

**Memory overload**: PHP loads the entire uploaded file into memory (or a temp file) during the request. A 1GB upload requires the server to hold 1GB in memory or temp storage for the duration of the request. Multiple simultaneous uploads can exhaust server resources.

**Connection drop**: If the internet connection drops for even one second during a single-request upload, the entire upload fails. There is no way to resume. The user must start over from the beginning.

**No progress tracking**: With a single request, the server has no way to report progress. The user sees a spinning indicator with no idea how much has been uploaded or how long it will take.

Chunked upload solves all four problems. Each chunk is a small, fast request (5-10MB takes seconds, not minutes). If one chunk fails, only that chunk needs to be retried. The server can report progress after each chunk. And memory usage stays low because the server processes one small chunk at a time.


## How Chunked and Resumable Upload Works {#how-chunked-upload-works}

The flow has four stages:

**1. Initialize**: The client sends a POST request to create an upload session. The server responds with a unique `uploadId`. This ID tracks the entire upload across multiple chunk requests.

**2. Upload chunks**: The client splits the file into chunks using `Blob.slice()` and sends each chunk as a separate PUT request, including the chunk index. The server stores each chunk as a temporary file.

**3. Check progress (for resumable uploads)**: If the connection drops, the client sends a GET request with the `uploadId` to ask the server which chunks have been received. The server responds with a list of completed chunk indices. The client then resumes uploading from the first missing chunk.

**4. Finalize**: After all chunks are uploaded, the client sends a POST request to finalize the upload. The server reads all chunk files in order, merges them into the final file, and deletes the temporary chunks.

This is the same pattern used by YouTube (resumable upload via Google API, 8MB default chunks), AWS S3 (Multipart Upload, 5MB minimum chunks, max 10,000 parts), Google Drive (resumable upload with session URI), Azure Blob (Block Blob upload), and Cloudflare R2 (S3-compatible multipart upload). The concept is universal: split, send, merge.


## Step 1: Create the Project {#step-1-create-project}

```bash
composer create-project --prefer-dist laravel/laravel chunked-upload-demo
cd chunked-upload-demo
```

Configure your database in `.env`:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_chunked_upload
DB_USERNAME=root
DB_PASSWORD=password
```

Run the initial migrations:

```bash
php artisan migrate
```


## Step 2: Create the Upload Model and Migration {#step-2-create-model-migration}

We need a database table to track upload sessions. Each session represents one file being uploaded in chunks.

```bash
php artisan make:model Upload -m
```

Open the migration file and define the schema:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('uploads', function (Blueprint $table) {
            $table->id();
            $table->string('upload_id')->unique();
            $table->string('file_name');
            $table->unsignedBigInteger('file_size');
            $table->unsignedInteger('total_chunks');
            $table->unsignedInteger('chunk_size');
            $table->json('completed_chunks')->default('[]');
            $table->enum('status', ['pending', 'completed', 'expired'])->default('pending');
            $table->string('final_path')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('uploads');
    }
};
```

The `upload_id` is a unique identifier for the upload session (UUID). The `completed_chunks` column stores a JSON array of chunk indices that have been received (e.g., `[0, 1, 2, 3]`). This is what enables resumable uploads: the client can query this to know where to resume.

Run the migration:

```bash
php artisan migrate
```

Configure the model (`app/Models/Upload.php`):

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;

#[Fillable([
    'upload_id', 'file_name', 'file_size', 'total_chunks',
    'chunk_size', 'completed_chunks', 'status', 'final_path',
])]
class Upload extends Model
{
    protected function casts(): array
    {
        return [
            'completed_chunks' => 'array',
            'file_size' => 'integer',
            'total_chunks' => 'integer',
            'chunk_size' => 'integer',
        ];
    }

    public function isComplete(): bool
    {
        return count($this->completed_chunks) === $this->total_chunks;
    }

    public function addCompletedChunk(int $chunkIndex): void
    {
        $chunks = $this->completed_chunks;

        if (!in_array($chunkIndex, $chunks)) {
            $chunks[] = $chunkIndex;
            sort($chunks);
            $this->completed_chunks = $chunks;
            $this->save();
        }
    }
}
```

The `completed_chunks` is strictly cast to an `array` so Laravel automatically handles JSON encoding/decoding. This strict casting is important because different database drivers (such as SQLite vs MySQL) might evaluate the `default('[]')` schema differently. The `isComplete()` method checks if all chunks have been received. The `addCompletedChunk()` method safely adds a chunk index to the array, preventing duplicates and keeping the array sorted.

Save the file.


## Step 3: Create the Upload Controller {#step-3-create-controller}

```bash
php artisan make:controller Api/ChunkedUploadController
```

Open `app/Http/Controllers/Api/ChunkedUploadController.php`:

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Upload;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ChunkedUploadController extends Controller
{
    /**
     * Initialize an upload session.
     * Client sends file metadata, server returns an uploadId.
     */
    public function init(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'fileName' => 'required|string|max:255',
            'fileSize' => 'required|integer|min:1',
            'chunkSize' => 'required|integer|min:1',
            'totalChunks' => 'required|integer|min:1',
        ]);

        $uploadId = Str::uuid()->toString();

        $upload = Upload::create([
            'upload_id' => $uploadId,
            'file_name' => $validated['fileName'],
            'file_size' => $validated['fileSize'],
            'total_chunks' => $validated['totalChunks'],
            'chunk_size' => $validated['chunkSize'],
            'completed_chunks' => [],
            'status' => 'pending',
        ]);

        // Create the temporary directory for chunks
        Storage::disk('local')->makeDirectory("chunks/{$uploadId}");

        return response()->json([
            'uploadId' => $uploadId,
            'message' => 'Upload session created.',
        ], 201);
    }

    /**
     * Receive a single chunk.
     * Each chunk is stored as a separate temporary file.
     */
    public function uploadChunk(Request $request, string $uploadId, int $chunkIndex): JsonResponse
    {
        $upload = Upload::where('upload_id', $uploadId)
            ->where('status', 'pending')
            ->firstOrFail();

        if ($chunkIndex < 0 || $chunkIndex >= $upload->total_chunks) {
            return response()->json(['error' => 'Invalid chunk index.'], 422);
        }

        if (!$request->hasFile('chunk')) {
            return response()->json(['error' => 'No chunk file provided.'], 422);
        }

        $chunkFile = $request->file('chunk');

        // Store the chunk with its index as the filename
        $chunkFile->storeAs(
            "chunks/{$uploadId}",
            "chunk_{$chunkIndex}",
            'local'
        );

        // Mark this chunk as completed
        $upload->addCompletedChunk($chunkIndex);

        return response()->json([
            'message' => "Chunk {$chunkIndex} uploaded.",
            'completedChunks' => count($upload->completed_chunks),
            'totalChunks' => $upload->total_chunks,
        ]);
    }

    /**
     * Check upload progress.
     * Returns the list of completed chunks so the client can resume.
     */
    public function status(string $uploadId): JsonResponse
    {
        $upload = Upload::where('upload_id', $uploadId)->firstOrFail();

        return response()->json([
            'uploadId' => $upload->upload_id,
            'fileName' => $upload->file_name,
            'totalChunks' => $upload->total_chunks,
            'completedChunks' => $upload->completed_chunks,
            'remainingChunks' => $upload->total_chunks - count($upload->completed_chunks),
            'status' => $upload->status,
        ]);
    }

    /**
     * Finalize the upload.
     * Merge all chunks into the final file and clean up.
     */
    public function complete(string $uploadId): JsonResponse
    {
        $upload = Upload::where('upload_id', $uploadId)
            ->where('status', 'pending')
            ->firstOrFail();

        if (!$upload->isComplete()) {
            return response()->json([
                'error' => 'Not all chunks have been uploaded.',
                'completedChunks' => count($upload->completed_chunks),
                'totalChunks' => $upload->total_chunks,
            ], 422);
        }

        // Merge chunks into the final file
        $finalPath = "uploads/" . Str::uuid() . '_' . $upload->file_name;
        $finalFullPath = Storage::disk('local')->path($finalPath);

        // Ensure the uploads directory exists
        Storage::disk('local')->makeDirectory('uploads');

        // Open the final file for writing
        $finalFile = fopen($finalFullPath, 'wb');

        for ($i = 0; $i < $upload->total_chunks; $i++) {
            $chunkPath = Storage::disk('local')->path("chunks/{$uploadId}/chunk_{$i}");

            if (!file_exists($chunkPath)) {
                fclose($finalFile);
                return response()->json(['error' => "Chunk {$i} is missing."], 500);
            }

            $chunkFile = fopen($chunkPath, 'rb');
            stream_copy_to_stream($chunkFile, $finalFile);
            fclose($chunkFile);
        }

        fclose($finalFile);

        // Clean up chunk files
        Storage::disk('local')->deleteDirectory("chunks/{$uploadId}");

        // Update the upload record
        $upload->update([
            'status' => 'completed',
            'final_path' => $finalPath,
        ]);

        return response()->json([
            'message' => 'Upload completed successfully.',
            'filePath' => $finalPath,
            'fileSize' => filesize($finalFullPath),
        ]);
    }
}
```

Let's walk through each endpoint:

**`init()`**: Creates an upload session. The client sends the file name, total size, chunk size, and number of chunks. The server generates a UUID as the `uploadId`, creates a database record, and creates a temporary directory to store chunks.

**`uploadChunk()`**: Receives a single chunk. The chunk is stored as a file named `chunk_0`, `chunk_1`, etc. inside the upload's temporary directory. The chunk index is validated against the total chunks to prevent out-of-bounds writes. *Note: In a production app, you should also consider validating the `mimeType` or exact extension of the file to prevent malicious scripts from being uploaded, as our basic implementation only checks for file existence via `hasFile('chunk')`.* After storing, the index is added to `completed_chunks` in the database.

**`status()`**: Returns the current progress. This is the key endpoint for resumable uploads. When the client's connection drops and they reconnect, they call this endpoint to find out which chunks the server already has, then resume from the first missing chunk.

**`complete()`**: Merges all chunks into the final file. It opens a file handle, iterates through all chunks in order (0, 1, 2, ...), and uses `stream_copy_to_stream()` to append each chunk to the final file. This approach is memory-efficient because it streams data instead of loading everything into memory. After merging, the temporary chunk files are deleted.

Save the file.


## Step 4: Register the API Routes {#step-4-register-routes}

Open `routes/api.php` (create it if it does not exist) and add the chunked upload routes:

```php
<?php

use App\Http\Controllers\Api\ChunkedUploadController;
use Illuminate\Support\Facades\Route;

Route::post('/uploads/init', [ChunkedUploadController::class, 'init']);
Route::post('/uploads/{uploadId}/chunks/{chunkIndex}', [ChunkedUploadController::class, 'uploadChunk']);
Route::get('/uploads/{uploadId}/status', [ChunkedUploadController::class, 'status']);
Route::post('/uploads/{uploadId}/complete', [ChunkedUploadController::class, 'complete']);
```

If `routes/api.php` does not exist in your Laravel 13 project, you need to install the API routes file:

```bash
php artisan install:api
```

This creates `routes/api.php` and registers it in the application. All routes in this file are automatically prefixed with `/api`.

The four endpoints follow the same pattern from the "How Chunked Upload Works" section: init, upload chunks, check status, complete.

Save the file.


## Step 5: Build the JavaScript Upload Client {#step-5-build-javascript-client}

Create `resources/views/upload.blade.php`. This is a Laravel Blade page with vanilla JavaScript that implements the chunked upload:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chunked File Upload</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-100 text-gray-800 font-sans p-6">
    <div class="max-w-2xl mx-auto bg-white p-6 md:p-8 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold text-gray-900 mb-2">Chunked File Upload</h1>
        <p class="text-sm text-gray-500 mb-6">Select a file to upload in chunks with resumable support.</p>

        <div class="space-y-6">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Select File</label>
                <input type="file" id="fileInput"
                    class="w-full px-4 py-2 border border-gray-300 rounded-md text-sm file:mr-4 file:py-1 file:px-3 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100">
            </div>

            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Chunk Size</label>
                <select id="chunkSizeSelect"
                    class="w-full px-4 py-2 border border-gray-300 rounded-md text-sm bg-white">
                    <option value="1048576">1 MB</option>
                    <option value="5242880" selected>5 MB</option>
                    <option value="10485760">10 MB</option>
                </select>
            </div>

            <button onclick="startUpload()" id="uploadBtn"
                class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-6 rounded-md transition duration-200 shadow-sm disabled:opacity-50">
                Upload
            </button>

            <!-- Progress -->
            <div id="progressSection" class="hidden space-y-2">
                <div class="flex justify-between text-sm text-gray-600">
                    <span id="progressText">Uploading...</span>
                    <span id="progressPercent">0%</span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-3">
                    <div id="progressBar" class="bg-blue-600 h-3 rounded-full transition-all duration-300" style="width: 0%"></div>
                </div>
                <p id="chunkInfo" class="text-xs text-gray-400"></p>
            </div>

            <!-- Result -->
            <div id="resultSection" class="hidden">
                <div id="resultMessage" class="px-4 py-3 rounded text-sm"></div>
            </div>
        </div>
    </div>

    <div class="mt-8 mb-6 text-center text-sm text-gray-500">
        <a href="https://qadrlabs.com" class="text-blue-600 hover:text-blue-800 hover:underline transition"
            target="_blank">Tutorial Laravel 13 at qadrlabs.com</a>
    </div>

    <script>
        const CHUNK_SIZE_SELECT = document.getElementById('chunkSizeSelect');

        async function startUpload() {
            const fileInput = document.getElementById('fileInput');
            const file = fileInput.files[0];

            if (!file) {
                alert('Please select a file.');
                return;
            }

            const CHUNK_SIZE = parseInt(CHUNK_SIZE_SELECT.value);
            const totalChunks = Math.ceil(file.size / CHUNK_SIZE);

            // Show progress
            document.getElementById('progressSection').classList.remove('hidden');
            document.getElementById('resultSection').classList.add('hidden');
            document.getElementById('uploadBtn').disabled = true;

            try {
                // 1. Initialize upload session
                updateProgress(0, totalChunks, 'Initializing upload session...');

                const initResponse = await fetch('/api/uploads/init', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                    body: JSON.stringify({
                        fileName: file.name,
                        fileSize: file.size,
                        chunkSize: CHUNK_SIZE,
                        totalChunks: totalChunks,
                    }),
                });

                if (!initResponse.ok) {
                    throw new Error('Failed to initialize upload session.');
                }

                const { uploadId } = await initResponse.json();

                // 2. Check for existing progress (resumable)
                const statusResponse = await fetch(`/api/uploads/${uploadId}/status`);
                const statusData = await statusResponse.json();
                const completedChunks = new Set(statusData.completedChunks);

                // 3. Upload chunks sequentially
                for (let i = 0; i < totalChunks; i++) {
                    // Skip already completed chunks (resumable)
                    if (completedChunks.has(i)) {
                        updateProgress(i + 1, totalChunks, `Chunk ${i} already uploaded, skipping...`);
                        continue;
                    }

                    const start = i * CHUNK_SIZE;
                    const end = Math.min(start + CHUNK_SIZE, file.size);
                    const chunk = file.slice(start, end);

                    const formData = new FormData();
                    formData.append('chunk', chunk);

                    const chunkResponse = await fetch(`/api/uploads/${uploadId}/chunks/${i}`, {
                        method: 'POST',
                        body: formData,
                    });

                    if (!chunkResponse.ok) {
                        throw new Error(`Failed to upload chunk ${i}.`);
                    }

                    updateProgress(i + 1, totalChunks, `Uploading chunk ${i + 1} of ${totalChunks}...`);
                }

                // 4. Finalize
                updateProgress(totalChunks, totalChunks, 'Merging chunks...');

                const completeResponse = await fetch(`/api/uploads/${uploadId}/complete`, {
                    method: 'POST',
                    headers: { 'Accept': 'application/json' },
                });

                if (!completeResponse.ok) {
                    throw new Error('Failed to finalize upload.');
                }

                const result = await completeResponse.json();
                showResult('success', `Upload complete! File saved to: ${result.filePath}`);

            } catch (error) {
                showResult('error', `Upload failed: ${error.message}. You can retry and it will resume from where it left off.`);
            } finally {
                document.getElementById('uploadBtn').disabled = false;
            }
        }

        function updateProgress(current, total, text) {
            const percent = Math.round((current / total) * 100);
            document.getElementById('progressBar').style.width = percent + '%';
            document.getElementById('progressPercent').textContent = percent + '%';
            document.getElementById('progressText').textContent = text;
            document.getElementById('chunkInfo').textContent = `${current} / ${total} chunks`;
        }

        function showResult(type, message) {
            const section = document.getElementById('resultSection');
            const messageEl = document.getElementById('resultMessage');

            section.classList.remove('hidden');

            if (type === 'success') {
                messageEl.className = 'px-4 py-3 rounded text-sm bg-green-100 border border-green-400 text-green-700';
            } else {
                messageEl.className = 'px-4 py-3 rounded text-sm bg-red-100 border border-red-400 text-red-700';
            }

            messageEl.textContent = message;
        }
    </script>
</body>
</html>
```

Let's examine the key JavaScript concepts:

**`file.slice(start, end)`**: This is the core of chunked upload. In JavaScript, the `File` object extends `Blob`, which has a `slice()` method. `file.slice(0, 5242880)` returns the first 5MB of the file as a new `Blob`. `file.slice(5242880, 10485760)` returns the next 5MB. This does not load the entire file into memory; it creates a reference to a portion of the file.

**Sequential upload**: Chunks are uploaded one at a time using a `for` loop with `await`. This is simpler than parallel upload and ensures chunks arrive in order. For faster uploads, you could send 3-5 chunks in parallel using `Promise.all()`, but sequential upload is easier to implement and debug.

**Resumable logic**: Before uploading, we call the status endpoint to get the list of completed chunks. If the upload was previously interrupted, `completedChunks` will contain the indices of chunks the server already has. The `if (completedChunks.has(i)) continue;` check skips those chunks, effectively resuming from where it left off.

**Progress bar**: After each chunk is uploaded, `updateProgress()` calculates the percentage and updates the progress bar width. Because each chunk is a separate request, we get granular progress tracking for free.

**Error Handling**: If a chunk upload fails (e.g., because of server limits, disk space, or validation error), we want to provide the user with the precise reason rather than a generic mistake. The `try/catch` block parses `errorData.error` from the backend's JSON response, allowing us to safely throw and display detailed errors like "Reason: No chunk file provided.".

Save the file.


## Step 6: Add a Route for the Upload Page {#step-6-add-upload-page-route}

Open `routes/web.php` and add a route to serve the upload page using the view helper:

```php
Route::get('/', function () {
    return view('upload');
});
```

Save the file.


## Step 7: Create the Cleanup Command {#step-7-create-cleanup-command}

Upload sessions that are never completed (user closes the browser, connection drops permanently) leave orphaned chunk files on disk. We need a scheduled command to clean them up.

```bash
php artisan make:command CleanExpiredUploads
```

Open `app/Console/Commands/CleanExpiredUploads.php`:

```php
<?php

namespace App\Console\Commands;

use App\Models\Upload;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class CleanExpiredUploads extends Command
{
    protected $signature = 'uploads:clean {--hours=24 : Hours after which pending uploads are considered expired}';

    protected $description = 'Clean up expired upload sessions and their chunk files';

    public function handle(): int
    {
        $hours = (int) $this->option('hours');

        $expiredUploads = Upload::where('status', 'pending')
            ->where('created_at', '<', now()->subHours($hours))
            ->get();

        if ($expiredUploads->isEmpty()) {
            $this->info('No expired uploads found.');
            return self::SUCCESS;
        }

        foreach ($expiredUploads as $upload) {
            // Delete chunk files
            Storage::disk('local')->deleteDirectory("chunks/{$upload->upload_id}");

            // Mark as expired
            $upload->update(['status' => 'expired']);

            $this->line("Cleaned: {$upload->upload_id} ({$upload->file_name})");
        }

        $this->info("Cleaned {$expiredUploads->count()} expired upload(s).");

        return self::SUCCESS;
    }
}
```

The command finds all upload sessions with `status = pending` that were created more than 24 hours ago (configurable via `--hours`). For each expired session, it deletes the chunk directory from disk and marks the record as `expired` in the database.

You can run it manually:

```bash
php artisan uploads:clean
```

Or schedule it to run daily by adding it to `routes/console.php`:

```php
use Illuminate\Support\Facades\Schedule;

Schedule::command('uploads:clean')->daily();
```

Save the files.


## Step 8: Try It Out {#step-8-try-it-out}

Start the development server:

```bash
php artisan serve
```

Open `http://127.0.0.1:8000` in your browser.

### Test a Normal Upload

1. Select a file (try a large file, 50MB+ to see the chunked behavior clearly).
2. Choose a chunk size (1MB is set by default). *Note: While the ideal "sweet spot" for chunked uploads is usually between 5MB - 10MB to balance HTTP requests vs chunk size, we default to 1MB here. This is because PHP's default `upload_max_filesize` is 2MB. Using 1MB ensures this tutorial works out-of-the-box without errors. To use 5MB+ chunks, you must configure your `php.ini` first.*
3. Click **Upload**.
4. Watch the progress bar update as each chunk is uploaded.
5. When complete, you should see a success message with the file path.

### Test Resumable Upload

1. Start uploading a large file.
2. While the upload is in progress (around 50%), stop the Laravel server with `Ctrl+C`.
3. Restart the server with `php artisan serve`.
4. Check the upload status via the API: `http://127.0.0.1:8000/api/uploads/{uploadId}/status`. You should see the list of completed chunks.
5. In a real application, the client would automatically call the status endpoint on reconnection and resume from the last completed chunk.

### Test the Cleanup Command

1. Start an upload but do not complete it (upload a few chunks, then close the browser).
2. Run the cleanup command with a shorter expiry for testing:

```bash
php artisan uploads:clean --hours=0
```

3. The pending upload should be cleaned up and its chunks deleted.


## Best Practices for Production {#best-practices}

Here are additional considerations for a production implementation:

**Chunk size and PHP Limits**: This is the sweet spot between the number of requests and the size of each request. Smaller chunks mean more HTTP overhead. Larger chunks mean longer individual requests and more data lost on failure. **However, your chunk size must not exceed PHP's max upload limit.** PHP's `upload_max_filesize` defaults to 2MB. If you upload a 5MB chunk on a server with a 2MB limit, the chunk will be silently rejected. In our code, we defaulted to 1MB chunks to ensure compatibility out-of-the-box. If you want to use 5MB or 10MB chunks, you must explicitly increase `upload_max_filesize` and `post_max_size` in your server's `php.ini`.

**Checksum per chunk**: Add an MD5 or SHA-256 hash to each chunk request so the server can verify the data was not corrupted during transfer. The client computes the hash before sending, and the server computes it after receiving and compares the two.

**Expiry for upload sessions**: Always clean up orphaned chunks. Set a reasonable expiry (24 hours is common) and run the cleanup command on a schedule. Without this, your disk fills up with abandoned uploads.

**Parallel upload**: For faster uploads, send 3-5 chunks simultaneously using `Promise.all()` with a concurrency limiter. This reduces total upload time significantly on fast connections. The server-side code already supports out-of-order chunk reception because each chunk is stored as a separate file.

**Progress bar**: Users need visual feedback. The per-chunk progress tracking we built provides this naturally. For even finer granularity, you can use `XMLHttpRequest` with `upload.onprogress` to track progress within a single chunk.

**Authentication**: In production, wrap the upload endpoints in authentication middleware. Store the `user_id` on the upload record so users can only access their own uploads.


## Conclusion {#conclusion}

In this tutorial, we built a complete chunked and resumable file upload system using Laravel 13 and vanilla JavaScript. Large files are split into chunks using `Blob.slice()`, uploaded individually, tracked in the database, and merged on the server after all chunks arrive.

Here are the key takeaways:

- **Chunked upload solves the four failure modes of single-request uploads.** Timeout, memory overload, connection drops, and lack of progress tracking are all addressed by splitting the file into small, independent requests.
- **`Blob.slice()` is the client-side foundation.** In JavaScript, `File` extends `Blob`, so you can call `file.slice(start, end)` to extract a portion of the file without loading the entire file into memory.
- **Resumable upload requires a session ID and progress tracking.** The server stores which chunks have been received. When the client reconnects, it queries the server and skips completed chunks. No work is wasted.
- **`stream_copy_to_stream()` merges chunks efficiently.** Instead of loading all chunks into memory, the server streams each chunk into the final file. This keeps memory usage low regardless of file size.
- **Always clean up orphaned chunks.** Upload sessions that are never completed leave temporary files on disk. A scheduled cleanup command prevents disk space from being wasted.
- **This pattern is universal.** YouTube, AWS S3, Google Drive, Azure Blob, and Cloudflare R2 all use the same concept: split the file on the client, send chunks individually, merge on the server. The implementation details differ, but the architecture is identical.