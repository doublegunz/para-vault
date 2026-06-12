## 1. Before You Begin

A web application is often not the only way users interact with your data. A mobile app, a desktop client, a single-page application (SPA), and other systems may all need access. A REST API provides a standardized way to expose data over HTTP using JSON. This lesson teaches you to build API endpoints for Catatku that return JSON responses, which other applications can consume programmatically.

REST stands for Representational State Transfer. It is a set of conventions for designing APIs: use HTTP verbs (GET, POST, PUT, DELETE) for actions, use URLs to identify resources, and exchange data as JSON. Laravel has first-class support for building REST APIs, including a separate `routes/api.php` file, automatic JSON formatting for responses, and built-in exception handling that returns appropriate HTTP status codes. By the end of this lesson, Catatku will have a working JSON API that returns entries and lets external clients create new entries.

### What You'll Build

You will create JSON endpoints for listing entries, showing a single entry, creating entries, updating entries, and deleting entries. You will test them with `curl` or Postman.

### What You'll Learn

- ✅ REST conventions and HTTP verbs
- ✅ The `routes/api.php` file and API prefix
- ✅ Returning JSON responses
- ✅ HTTP status codes: 200, 201, 204, 404, 422
- ✅ Validating JSON input
- ✅ Using `abort` and exception handling for API errors

### What You'll Need

- Lesson 8 completed
- A tool to test APIs: `curl`, Postman, or your browser for GET requests

---

## 2. REST Conventions for Catatku

Before writing code, you need to understand the REST conventions. Each resource (like entries) has a standard set of endpoints that map to HTTP verbs. Following this convention makes your API predictable for other developers and easy to document.

| HTTP Verb | URL                  | Action        | Response          |
|-----------|----------------------|---------------|-------------------|
| GET       | `/api/entries`       | List all      | 200 + JSON array  |
| POST      | `/api/entries`       | Create new    | 201 + JSON object |
| GET       | `/api/entries/{id}`  | Show one      | 200 + JSON object |
| PUT       | `/api/entries/{id}`  | Update        | 200 + JSON object |
| DELETE    | `/api/entries/{id}`  | Delete        | 204 + empty       |

Notice how the same URL (`/api/entries`) behaves differently depending on the HTTP verb: GET reads, POST creates. This convention is shared across nearly every REST API on the web, which is why following it makes your API immediately familiar to any developer.

---

## 3. Install API Scaffolding

Laravel 11+ does not ship with API routing by default. You need to install it separately so that a dedicated `routes/api.php` file exists and a uniform `/api` prefix is applied to all routes within it.

### Step 1: Run the Install Command

Run the following Artisan command to set up the API infrastructure.

```bash
php artisan install:api
```

This command does three things. First, it creates `routes/api.php` where your API routes will live. Second, it registers the API route file in `bootstrap/app.php` so Laravel loads it on every request. Third, it installs Laravel Sanctum for token authentication (we will use Sanctum in Lesson 10). After this command, every route you put in `routes/api.php` automatically gets the `/api` URL prefix, so `Route::get('/entries', ...)` becomes accessible at `/api/entries`.

---

## 4. Create the API Controller

API controllers are separate from web controllers because they return JSON instead of views, and because the interaction pattern is different: no redirects, no session flash messages, no HTML forms. Keeping them separate prevents web concerns from leaking into API code and vice versa.

### Step 1: Generate the API Controller

Run the following command to create a controller in the `Api` namespace.

```bash
php artisan make:controller Api/EntryController --api
```

The `Api/` prefix organizes API controllers in their own namespace and directory, keeping them separate from web controllers. The `--api` flag omits the `create` and `edit` methods because APIs do not serve HTML forms; only the data endpoints (index, show, store, update, destroy) matter. The generated file lives at `app/Http/Controllers/Api/EntryController.php`.

### Step 2: Implement the Index and Show Methods

Open `app/Http/Controllers/Api/EntryController.php` and add the following implementation.

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Entry;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EntryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $entries = Entry::with('tags', 'user')
            ->withCount('comments')
            ->latest()
            ->paginate(15);

        return response()->json($entries);
    }

    public function show(Entry $entry): JsonResponse
    {
        $entry->load('tags', 'user', 'comments.user');

        return response()->json($entry);
    }
}
```

Let us examine each part carefully. The namespace `App\Http\Controllers\Api` matches the directory. Both method signatures declare `JsonResponse` as the return type, making the JSON nature of the response explicit to developers and IDEs.

In `index()`, we fetch entries with eager loading using `with('tags', 'user')`, add a comment count subquery with `withCount('comments')`, order by latest, and paginate to 15 per page. The `paginate()` return value is a `LengthAwarePaginator`, which Laravel automatically converts to JSON including pagination metadata: current page, per-page count, total items, and navigation links. `response()->json($entries)` serializes the object as JSON and sets the `Content-Type: application/json` response header.

In `show()`, route model binding receives the `$entry` by ID from the URL. We then eager load relationships before returning, because without loading them explicitly, the `tags` and `comments` keys would be absent from the JSON output. `response()->json($entry)` serializes the single entry with its loaded relationships.

### Step 3: Implement Store, Update, and Destroy

Still in `app/Http/Controllers/Api/EntryController.php`, add the `Gate` facade import to the existing `use` statements at the top, then add the following three methods after the existing `show` method.

```php
<?php
// ... others lines of code
use Illuminate\Support\Facades\Gate;

class EntryController extends Controller
{
    // ... other methods

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        $entry = $request->user()->entries()->create([
            'title' => $validated['title'],
            'content' => $validated['content'],
        ]);

        $entry->tags()->sync($validated['tags'] ?? []);

        $entry->load('tags', 'user');

        return response()->json($entry, 201);
    }

    public function update(Request $request, Entry $entry): JsonResponse
    {
        Gate::authorize('update', $entry);

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'content' => 'sometimes|required|string',
            'tags' => 'nullable|array',
            'tags.*' => 'exists:tags,id',
        ]);

        $entry->update($validated);

        if (isset($validated['tags'])) {
            $entry->tags()->sync($validated['tags']);
        }

        return response()->json($entry->fresh(['tags', 'user']));
    }

    public function destroy(Entry $entry): JsonResponse
    {
        Gate::authorize('delete', $entry);

        $entry->delete();

        return response()->json(null, 204);
    }
}
```

Walking through each method: `store()` validates the input, creates an entry owned by the authenticated user via the relationship, syncs tags, eager loads relationships for the response body, and returns HTTP 201 Created. The second argument to `response()->json($data, $status)` sets the HTTP status code. Returning 201 instead of 200 is important because API clients use status codes to determine what happened without parsing the body.

In `update()`, the first line calls `Gate::authorize('update', $entry)`, which enforces the ownership policy defined in Lesson 5 and returns HTTP 403 if the authenticated user does not own this entry. After authorization, notice the validation rules use `sometimes|required` instead of just `required`. The `sometimes` rule means "only validate this field if it was included in the request", which allows partial updates where the client sends only the fields that changed. We only sync tags if they were included in the request (checked with `isset($validated['tags'])`). The `fresh(['tags', 'user'])` call reloads the entry from the database with its relationships, ensuring the response reflects any database-level mutations.

In `destroy()`, `Gate::authorize('delete', $entry)` runs the same ownership check before deletion. We then delete the entry and return HTTP 204 No Content with `null` as the body. A 204 response has no body by REST convention; returning null tells `response()->json()` to produce an empty body while setting the correct status code.

---

## 5. Register the API Routes

Open `routes/api.php` and replace its content with the following, which separates public read-only endpoints from authenticated write endpoints.

```php
<?php

use App\Http\Controllers\Api\EntryController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/entries', [EntryController::class, 'index']);
Route::get('/entries/{entry}', [EntryController::class, 'show']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/entries', [EntryController::class, 'store']);
    Route::put('/entries/{entry}', [EntryController::class, 'update']);
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy']);
});
```

Looking at the route organization: we split routes into public (GET for reading) and authenticated (POST/PUT/DELETE for writing). Read-only endpoints are public because anyone with the API URL should be able to view Catatku's publicly listed entries. Write operations require authentication to prevent anonymous creation or modification. The `Route::middleware('auth:sanctum')->group(...)` wraps the write routes so they require a Sanctum bearer token, which we implement in Lesson 10. For now, these protected routes will reject every request because no token is being sent; the public routes work immediately without any token.

---

## 6. Run and Test

Let us verify the API endpoints respond correctly using `curl` commands from the terminal.

### Step 1: Test the Index Endpoint

Open a terminal and run the following curl command while the development server is running.

```bash
curl http://localhost:8000/api/entries
```

The curl command sends an HTTP GET request and prints the response body. You should see JSON output with pagination metadata wrapping an array of entries, similar to the following structure.

```json
{
    "current_page": 1,
    "data": [
        {
            "id": 1,
            "user_id": 1,
            "title": "My First Entry",
            "content": "...",
            "tags": [{"id": 1, "name": "Personal"}],
            "user": {"id": 1, "name": "Admin"},
            "comments_count": 0
        }
    ],
    "per_page": 15,
    "total": 5
}
```

If you want the output formatted for readability, pipe it through Python's JSON formatter: `curl http://localhost:8000/api/entries | python3 -m json.tool`.

### Step 2: Test the Show Endpoint

Request a specific entry by its ID.

```bash
curl http://localhost:8000/api/entries/1
```

You should see a single entry JSON object with all its relationships (tags, user, comments, comment authors) included. If the ID does not exist, Laravel automatically returns a 404 status code with a JSON error message because route model binding fails with an appropriate exception when using API routes.

### Step 3: Test a 404 Response

Request an ID that does not exist to verify error handling.

```bash
curl -i http://localhost:8000/api/entries/99999
```

The `-i` flag tells curl to include the HTTP response headers in the output. You should see `HTTP/1.1 404 Not Found` in the headers, followed by a JSON body with an error message. This behavior requires no code on your part; Laravel handles it automatically when route model binding fails and the request expects a JSON response.

### Step 4: Test Validation Errors

Try posting to the protected store endpoint without authentication.

```bash
curl -X POST http://localhost:8000/api/entries \
  -H "Content-Type: application/json" \
  -d '{"title":"Test"}'
```

The `-X POST` flag sets the HTTP method. The `-H` flag adds the Content-Type header so Laravel knows to parse the body as JSON. The `-d` flag sends the request body. You should see HTTP 401 Unauthorized because the route requires a Sanctum token. We will implement the token issuance flow in Lesson 10; at that point you can retry this with a valid bearer token and receive either a 201 on success or a 422 with validation errors if required fields are missing.

---

## 7. Fix the Errors in Your Code

These are the most common mistakes when building REST APIs in Laravel.

**Error 1: Returning Eloquent models from route closures, bypassing the controller.**

This error occurs when developers prototype routes by returning models directly from closures. While Laravel does convert Eloquent models to JSON automatically, this pattern skips eager loading, pagination, and authorization, resulting in incomplete or insecure responses.

```php
// Wrong: returns all entries without eager loading, pagination, or authorization
Route::get('/entries', function () {
    return Entry::all();
});

// Correct: route through a controller for structure, optimization, and security
Route::get('/entries', [EntryController::class, 'index']);
```

The wrong version loads every entry with no limit, exposes all columns including sensitive ones, and skips relationship loading, so `tags` and `comments` are absent from the output. The correct version routes through the controller where `paginate(15)`, `with('tags', 'user')`, and `withCount('comments')` apply consistently.

---

**Error 2: Returning 200 instead of 201 for successful resource creation.**

This error occurs when you forget to pass the status code as the second argument to `response()->json()` after creating a resource. REST convention specifies 201 (Created) for successful POST requests that create a new resource, not 200 (OK).

```php
// Wrong: returns 200 OK, which does not indicate a new resource was created
return response()->json($entry);

// Correct: returns 201 Created, signaling a new resource was successfully created
return response()->json($entry, 201);
```

Using 200 for a creation response is technically functional but incorrect by REST convention. API clients that follow the spec check for 201 to confirm that a resource was created. Using 200 can cause SDK generators and API clients to handle the response incorrectly. The fix is to pass `201` as the second argument to `json()`.

---

**Error 3: Using session flash messages in API responses, which are stateless.**

This error occurs when developers copy web controller patterns into API controllers and include `->with('success', '...')` after the JSON response. Session flash data only works with browser-based sessions, which API clients typically do not use.

```php
// Wrong: with() adds session data that API clients cannot read
return response()->json($entry)->with('success', 'Entry created!');

// Correct: put status information in the JSON body or rely on status codes
return response()->json(['data' => $entry, 'message' => 'Entry created.'], 201);
```

The wrong version calls `->with(...)` on a JSON response, which in some Laravel versions does nothing and in others throws an error, because the chained `with()` tries to write to the session which API clients do not maintain across requests. The correct version includes any required status message in the JSON body itself, or simply relies on the HTTP status code (201 signals success clearly enough for most clients). REST APIs should be stateless: every request must be self-contained.

---

## 8. Exercises

These exercises extend the API controller you built in this lesson. Each one adds a practical capability that real API consumers frequently expect. Try each exercise independently before checking the solution.

**Exercise 1:** Add filtering to the index endpoint. Accept a `tag` query parameter like `/api/entries?tag=travel`. In the controller, if the parameter is present, filter entries using `whereHas` to find entries with a tag matching that slug.

**Exercise 2:** Add a `search` parameter to the index endpoint so clients can call `/api/entries?search=keyword`. Reuse the `scopeSearch` scope from Lesson 3.

**Exercise 3:** Create an `Api/CommentController` with a `store` method that accepts JSON comments on entries. Return the created comment as JSON with status 201.

---

## 9. Solutions

Each solution below is complete and can be applied directly to your API controller. Exercises 1 and 2 both modify the `index` method, so apply them together in the order shown to avoid rewriting the same method twice.

**Solution for Exercise 1:**

In `app/Http/Controllers/Api/EntryController.php`, replace the fixed query in the `index` method with a builder that applies the filter conditionally.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index(Request $request): JsonResponse
    {
        $query = Entry::with('tags', 'user')->withCount('comments');

        if ($request->filled('tag')) {
            $query->whereHas('tags', function ($q) use ($request) {
                $q->where('slug', $request->input('tag'));
            });
        }

        $entries = $query->latest()->paginate(15);

        return response()->json($entries);
    }

    // ... other methods
}
```

`$request->filled('tag')` returns true only when the `tag` parameter is present and non-empty. `whereHas('tags', function ($q) { ... })` adds an `EXISTS` subquery that filters entries to only those with at least one tag matching the given slug. This approach runs in the database and is more efficient than loading all entries and filtering in PHP.

---

**Solution for Exercise 2:**

In `app/Http/Controllers/Api/EntryController.php`, update the `index` method to include the search filter after the existing tag filter. The complete method with both filters looks like this:

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index(Request $request): JsonResponse
    {
        $query = Entry::with('tags', 'user')->withCount('comments');

        if ($request->filled('tag')) {
            $query->whereHas('tags', function ($q) use ($request) {
                $q->where('slug', $request->input('tag'));
            });
        }

        if ($request->filled('search')) {
            $query->search($request->input('search'));
        }

        $entries = $query->latest()->paginate(15);

        return response()->json($entries);
    }

    // ... other methods
}
```

This calls the `scopeSearch` method defined on the Entry model in Lesson 3. The scope adds a `WHERE (title LIKE ? OR content LIKE ?)` condition with the search keyword. Because scopes modify the same underlying query builder, both filters can be applied independently: `/api/entries?tag=travel&search=beach` finds entries tagged "travel" that also mention "beach" in the title or content.

---

**Solution for Exercise 3:**

Generate the API comment controller.

```bash
php artisan make:controller Api/CommentController
```

Open `app/Http/Controllers/Api/CommentController.php` and add the store method.

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Entry;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommentController extends Controller
{
    public function store(Request $request, Entry $entry): JsonResponse
    {
        $validated = $request->validate([
            'body' => 'required|string|min:2|max:1000',
        ]);

        $comment = $entry->comments()->create([
            ...$validated,
            'user_id' => $request->user()->id,
        ]);

        $comment->load('user');

        return response()->json($comment, 201);
    }
}
```

Register the route in `routes/api.php` inside the `auth:sanctum` middleware group.

```php
Route::post('/entries/{entry}/comments', [CommentController::class, 'store']);
```

The method validates the comment body, creates the comment through the entry relationship (which automatically sets `entry_id`), manually sets `user_id` from the authenticated user, and eager loads the author before returning. Returning 201 signals that a new resource was created. The nested URL `/entries/{entry}/comments` mirrors the web route from Lesson 1 and clearly communicates that the comment belongs to a specific entry.

---

## Next Up - Lesson 10

In this lesson you built a functional JSON API for Catatku. You installed the API scaffolding with `php artisan install:api`, created a dedicated `Api/EntryController` that returns JSON via `response()->json()`, and applied REST conventions: 201 for creation, 204 for deletion, and proper route model binding that automatically returns 404 for missing resources. You organized routes into public and authenticated groups, used `sometimes|required` for partial update validation, and tested every endpoint with curl to verify response shape and status codes.

In Lesson 10, you will learn API Resources and Sanctum authentication: how to shape your JSON output precisely using Resource classes, and how to issue Sanctum bearer tokens so external clients can authenticate to the protected write endpoints you built today.