## 1. Before You Begin

Three features separate beginner Laravel applications from production-ready ones. Eager loading prevents the N+1 query problem that makes pages load slowly. Soft deletes let users recover accidentally deleted entries instead of losing them permanently. Pagination breaks large datasets into manageable pages instead of loading thousands of records at once. This lesson adds all three to Catatku.

The N+1 problem is one of the most common performance issues in Laravel applications. If the feed page shows 50 entries, and each entry displays its author's name, that is 51 database queries: 1 for the entries and 50 more for each author. Eager loading reduces this to 2 queries. Soft deletes add a `deleted_at` column that marks entries as deleted without removing them. Pagination loads only 15 (or however many you configure) entries per page. By the end of this lesson, Catatku's feed will be fast, its delete behavior will be forgiving, and long lists will be navigable.

### What You'll Build

You will optimize the Catatku feed with eager loading, add a "trash" feature using soft deletes, and paginate the entry listing with navigation links.

### What You'll Learn

- ✅ The N+1 query problem and how `with()` solves it
- ✅ `SoftDeletes` trait: `delete()`, `trashed()`, `restore()`, `forceDelete()`
- ✅ `paginate()`, `simplePaginate()`, and `$entries->links()` in Blade
- ✅ `withTrashed()` and `onlyTrashed()` for querying deleted entries

### What You'll Need

- Lesson 3 completed with scopes and accessors

---

## 2. The N+1 Problem

To understand eager loading, you first need to understand the problem it solves. The N+1 problem happens when you access a relationship inside a loop without preloading the related data, which causes Laravel to run one extra query per iteration.

### Step 1: See the Problem

Open `app/Http/Controllers/EntryController.php` and temporarily set the `index` method in the `EntryController` class to the following to create the problem on purpose.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index()
    {
        $entries = auth()->user()->entries()->latest()->get();

        return view('entries.index', compact('entries'));
    }

    // ... other methods
}
```

This code fetches the authenticated user's entries in reverse chronological order. On the surface it looks fine, but notice that we call `get()` without any `with(...)` calls. When the Blade view accesses `$entry->tags` or `$entry->comments_count`, Eloquent runs a separate query for each entry because those relationships were not preloaded. With 50 entries, that is 50+ additional queries. The database handles each one quickly, but the accumulated round trips add up to noticeable lag.

### Step 2: Measure the Problem

Temporarily replace the body of the `index` method in `app/Http/Controllers/EntryController.php` with the following diagnostic code to count queries using Laravel's built-in query log.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index()
    {
        \DB::enableQueryLog();

        $entries = auth()->user()->entries()->latest()->get();

        foreach ($entries as $entry) {
            $_ = $entry->user->name;
            $_ = $entry->tags->count();
            $_ = $entry->comments->count();
        }

        dd(count(\DB::getQueryLog()));
    }

    // ... other methods
}
```

`\DB::enableQueryLog()` tells Laravel to start recording every SQL query it runs during this request. The `get()` call produces the first query that fetches all entries. Inside the foreach loop, each property access triggers a new query because those relationships were not loaded. The `dd(count(\DB::getQueryLog()))` prints the total query count and halts execution so you can see the number. For 50 entries with three relationship accesses each, you get 1 + (50 × 3) = 151 queries, which is the N+1 problem in full force. Remove this diagnostic code after observing the count.

### Step 3: Fix with Eager Loading

Update the `index` method in `app/Http/Controllers/EntryController.php` with eager loading while keeping the diagnostic code, so you can compare the query count directly with the number you saw in Step 2.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index()
    {
        \DB::enableQueryLog();

        $entries = auth()->user()->entries()
            ->with('tags')
            ->withCount('comments')
            ->latest()
            ->get();

        foreach ($entries as $entry) {
            $_ = $entry->user->name;
            $_ = $entry->tags->count();
            $_ = $entry->comments->count();
        }

        dd(count(\DB::getQueryLog()));
    }

    // ... other methods
}
```

The key additions are `->with('tags')` and `->withCount('comments')` on the query. The `with('tags')` method preloads all tags for all entries in a single query. Instead of running 50 queries when you access `$entry->tags` in the view, Eloquent runs one query using `WHERE entry_tag.entry_id IN (1, 2, 3, ...)` and distributes the results among the entries in memory. The `withCount('comments')` adds a `comments_count` attribute to each entry using a subquery, which is far cheaper than loading every comment record. The total is now 3 queries regardless of how many entries you have. Refresh the page and compare the number from `dd()` with what you saw in Step 2 — the difference is the N+1 problem eliminated.

After confirming the query count has dropped, remove all the diagnostic code and restore the `index` method to its final state from Lesson 3, which already includes eager loading alongside the search scope.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index(Request $request)
    {
        $query = auth()->user()->entries()->with('tags')->withCount('comments');

        if ($request->filled('search')) {
            $query->search($request->input('search'));
        }

        $entries = $query->latest()->get();

        return view('entries.index', compact('entries'));
    }

    // ... other methods
}
```

---

## 3. Soft Deletes

Soft deletes mark records as deleted by setting a `deleted_at` timestamp. The record stays in the database but is excluded from normal queries. This lets users recover accidentally deleted entries, which is a pattern users expect from modern apps that have a trash or recycle bin.

### Step 1: Add the Deleted At Column

Generate a migration to add the soft delete column to the existing entries table.

```bash
php artisan make:migration add_soft_deletes_to_entries --table=entries
```

The `--table=entries` flag tells Artisan this migration modifies an existing table rather than creating a new one, so the generated file uses `Schema::table` instead of `Schema::create`. Open the generated migration file and update the `up()` and `down()` methods as follows.

```php
public function up(): void
{
    Schema::table('entries', function (Blueprint $table) {
        $table->softDeletes();
    });
}

public function down(): void
{
    Schema::table('entries', function (Blueprint $table) {
        $table->dropSoftDeletes();
    });
}
```

Each line does something specific. `Schema::table('entries', function (Blueprint $table) { ... })` opens the existing `entries` table for modification without dropping it. `$table->softDeletes()` is a Blueprint shortcut that adds a nullable `deleted_at` timestamp column. When this column is NULL, the entry is active. When it has a timestamp value, the entry is "deleted" but still present in the database. The `down()` method reverses the change using `$table->dropSoftDeletes()`, removing the column if you roll back the migration. Run the migration to apply the change.

```bash
php artisan migrate
```

You should see output confirming the column was added to the entries table.

### Step 2: Add the Trait to the Entry Model

Open `app/Models/Entry.php` and add the `SoftDeletes` import and the `use SoftDeletes;` declaration to the `Entry` class.

```php
<?php
// ... others lines of code
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['title', 'content'])]
class Entry extends Model
{
    use SoftDeletes;

    // ... other methods and properties
}
```

The `use Illuminate\Database\Eloquent\SoftDeletes;` import pulls in the trait class. Adding `use SoftDeletes;` inside the class body mixes its methods into the Entry model. Behind the scenes, the trait modifies Eloquent's default behavior: every query now automatically adds `WHERE deleted_at IS NULL`, so soft-deleted entries are invisible to normal queries. The `delete()` method is overridden to set `deleted_at = NOW()` instead of running a SQL `DELETE`. No other code changes are needed; the trait handles everything transparently.

### Step 3: Understand the Soft Delete Methods

Once the trait is active, five key methods become available on any Entry instance or query builder. The table below summarizes what each one does.

| Method | What it does |
|---|---|
| `$entry->delete()` | Sets `deleted_at` to the current timestamp |
| `$entry->trashed()` | Returns `true` if the entry is soft-deleted |
| `Entry::withTrashed()->get()` | Includes soft-deleted entries in results |
| `Entry::onlyTrashed()->get()` | Returns only soft-deleted entries |
| `$entry->restore()` | Sets `deleted_at` back to NULL |
| `$entry->forceDelete()` | Permanently removes the row from the database |

`delete()` still works the same as before from your code's perspective, but internally it now soft-deletes. `trashed()` is a boolean helper to check the state. `withTrashed()` and `onlyTrashed()` are scopes provided by the trait for querying the trash. `restore()` undoes a soft delete by nulling the timestamp. `forceDelete()` bypasses soft deletes entirely and really removes the row; use this for "Empty Trash" style actions.

The existing delete functionality in your controller already works correctly; calling `$entry->delete()` in `EntryController@destroy` now soft-deletes instead of permanently deleting without requiring any changes to your controller code.

---

## 4. Pagination

Loading all entries is fine when a user has 10. But when they have 500, the page becomes slow and the browser struggles to render the list. Pagination loads a fixed number of entries per page and provides navigation controls so users can move through their data.

### Step 1: Update the Controller

Open `app/Http/Controllers/EntryController.php` and update the `index` method in the `EntryController` class — the only change from Lesson 3 is replacing `->get()` with `->paginate(15)` at the end of the query chain.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index(Request $request)
    {
        $query = auth()->user()->entries()->with('tags')->withCount('comments');

        if ($request->filled('search')) {
            $query->search($request->input('search'));
        }

        $entries = $query->latest()->paginate(15);

        return view('entries.index', compact('entries'));
    }

    // ... other methods
}
```

The only change from Lesson 3 is `paginate(15)` in place of `get()`. The `paginate(15)` method loads 15 entries per page. It automatically reads the `page` query parameter from the URL (for example, `?page=2`) and calculates the SQL offset, so you do not need to track page numbers manually. The returned object is not a Collection but a `LengthAwarePaginator`, which wraps the entries and includes pagination metadata: current page number, total pages, total items, and link URLs for Previous and Next.

### Step 2: Add Pagination Links to the View

Open `resources/views/entries/index.blade.php` and add the pagination links after the closing `</div>` of the `space-y-4` entry list container.

```blade
{{-- Pagination links --}}
<div style="margin-top: 20px;">
    {{ $entries->links() }}
</div>
```

The `$entries->links()` method renders pagination HTML with Previous/Next buttons and page numbers. Laravel automatically styles this when using Tailwind CSS (covered in Lesson 16). For now, the unstyled links are functional: clicking them updates the `?page=N` query parameter, and Laravel's `paginate()` call reads it on the next request to return the correct slice of data.

After the change, the full `index.blade.php` looks like this:

```blade
<x-layout title="My Entries — Catatku">

    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900">My Entries</h2>
        <a href="/entries/create"
            class="bg-gray-900 text-white text-sm px-4 py-2 rounded-lg hover:bg-gray-700 transition-colors">
            + Write New Entry
        </a>
    </div>

    <div class="space-y-4">
        @forelse ($entries as $entry)
        <x-entry-card :entry="$entry" />
        @empty
        <div class="text-center py-16">
            <p class="text-5xl mb-4">📓</p>
            <p class="font-medium text-gray-600">No entries yet</p>
            <p class="text-sm text-gray-400 mt-1">
                Start writing your first entry!
            </p>
            <a href="/entries/create" class="inline-block mt-4 text-sm text-blue-600 hover:underline">
                Write now →
            </a>
        </div>
        @endforelse
    </div>

    {{-- Pagination links --}}
    <div style="margin-top: 20px;">
        {{ $entries->links() }}
    </div>

</x-layout>
```

---

## 5. Add a Trash Page

Now that soft deletes are active, users should be able to see and restore their deleted entries. This section adds a simple trash page to give them that ability.

### Step 1: Add Trash Routes

Open `routes/web.php` and add the two new routes inside the authenticated route group. The GET trash route **must be placed before** the existing `Route::get('/entries/{entry}', ...)` wildcard route, otherwise Laravel will match the literal string "trash" as the `{entry}` parameter and call `show()` instead.

```php
Route::get('/entries', [EntryController::class, 'index'])->name('entries.index');
Route::get('/entries/create', [EntryController::class, 'create'])->name('entries.create');
Route::post('/entries', [EntryController::class, 'store'])->name('entries.store');
Route::get('/entries/trash', [EntryController::class, 'trash'])->name('entries.trash'); // must be here, before {entry}
Route::get('/entries/{entry}', [EntryController::class, 'show'])->name('entries.show');
Route::get('/entries/{entry}/edit', [EntryController::class, 'edit'])->name('entries.edit');
Route::put('/entries/{entry}', [EntryController::class, 'update'])->name('entries.update');
Route::delete('/entries/{entry}', [EntryController::class, 'destroy'])->name('entries.destroy');
Route::patch('/entries/{entry}/restore', [EntryController::class, 'restore'])
    ->name('entries.restore')
    ->withTrashed();
Route::post('/entries/{entry}/comments', [CommentController::class, 'store'])->name('comments.store');
```

Laravel matches routes in the order they are registered. Because `/entries/trash` is a literal path and `/entries/{entry}` is a wildcard, placing trash first ensures the specific route wins. The `->withTrashed()` modifier on the restore route tells Laravel's route model binding to include soft-deleted entries when resolving the `{entry}` parameter. Without it, visiting `/entries/42/restore` would return a 404 because entry 42 has a non-null `deleted_at` and is invisible to normal queries.

### Step 2: Add Controller Methods

Open `app/Http/Controllers/EntryController.php` and add the following two methods to the `EntryController` class, after the existing `destroy` method.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function trash()
    {
        $entries = auth()->user()->entries()
            ->onlyTrashed()
            ->latest('deleted_at')
            ->paginate(15);

        return view('entries.trash', compact('entries'));
    }

    public function restore(Entry $entry)
    {
        if ($entry->user_id !== auth()->id()) {
            abort(403);
        }

        $entry->restore();

        return redirect()->route('entries.trash')->with('success', 'Entry restored!');
    }
}
```

The `trash` method uses `onlyTrashed()` to show only soft-deleted entries, which is the inverse of the default behavior. It orders by `deleted_at` descending so recently-trashed items appear first, and paginates the results. The `restore` method accepts an Entry via route model binding; the `->withTrashed()` in the route definition ensures the binding can find trashed entries. The ownership check `if ($entry->user_id !== auth()->id())` follows the same pattern used throughout the basic course — if the authenticated user does not own the entry, the request is rejected with a 403. `$entry->restore()` sets `deleted_at` back to NULL, returning the entry to the normal listing. Lesson 5 will replace this manual check with a Policy, which centralizes authorization logic in one place.

### Step 3: Create the Trash View

Create a new file at `resources/views/entries/trash.blade.php` with the following content.

```blade
<x-layout title="Trash — Catatku">

    <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-semibold text-gray-900">Trash</h2>
        <a href="{{ route('entries.index') }}" class="text-sm text-blue-600 hover:underline">
            ← Back to Entries
        </a>
    </div>

    <div class="space-y-4">
        @forelse ($entries as $entry)
        <div class="bg-white rounded-xl border border-gray-200 p-5">
            <div class="flex items-start justify-between gap-3">
                <div>
                    <p class="font-semibold text-gray-900">{{ $entry->title }}</p>
                    <p style="color: #9ca3af; font-size: 0.8em; margin-top: 4px;">
                        Deleted {{ $entry->deleted_at->diffForHumans() }}
                    </p>
                </div>
                <form method="POST" action="{{ route('entries.restore', $entry) }}">
                    @csrf
                    @method('PATCH')
                    <button type="submit" class="text-xs text-blue-600 hover:text-blue-800">
                        Restore
                    </button>
                </form>
            </div>
        </div>
        @empty
        <div class="text-center py-16">
            <p class="text-5xl mb-4">🗑️</p>
            <p class="font-medium text-gray-600">Trash is empty</p>
            <p class="text-sm text-gray-400 mt-1">Deleted entries will appear here.</p>
        </div>
        @endforelse
    </div>

    <div style="margin-top: 20px;">
        {{ $entries->links() }}
    </div>

</x-layout>
```

The view uses `<x-layout>` to wrap content in the shared application shell. The `@forelse` directive loops over the paginated `$entries` and falls back to an empty state when the trash has no items. For each entry, the title and `deleted_at->diffForHumans()` are displayed so users know when the entry was deleted. The Restore form uses `@method('PATCH')` because browsers only support GET and POST natively; the hidden `_method` field tells Laravel's router to treat it as a PATCH request, matching the `entries.restore` route defined in Step 1. Pagination links at the bottom work identically to the main listing because both use `paginate(15)`.

---

## 6. Run and Test

Let us verify all three features work together in the browser and in Tinker.

### Step 1: Test Eager Loading

Start the server and navigate to the entries page.

```bash
php artisan serve
```

The page should load quickly. To verify the query count, reapply the query log diagnostic from Step 2 of Section 2, this time with eager loading in place. The total query count should drop from ~150 to around 3, regardless of how many entries the user has.

### Step 2: Test Soft Deletes

Delete an entry from the UI using your existing delete button. The entry should disappear from the main listing as before. Navigate to `/entries/trash`. The deleted entry should appear there with its title and a timestamp showing when it was deleted. Add a "Restore" button to your trash view that submits a form with the PATCH method pointing to the restore route. Click Restore and confirm the entry returns to the main listing.

### Step 3: Test in Tinker

Open a new terminal and run Tinker to verify soft delete behavior from the command line.

```bash
php artisan tinker
```

Run the following commands in sequence to observe how soft deletes affect query results.

```php
$entry = \App\Models\Entry::first();
$entry->delete();

\App\Models\Entry::count();
\App\Models\Entry::withTrashed()->count();

$entry->restore();
\App\Models\Entry::count();
```

After calling `delete()`, the first `count()` returns a smaller number because normal queries skip trashed rows. `withTrashed()->count()` includes them, so the total is unchanged. After calling `restore()`, the normal `count()` returns to its original value. This demonstrates the invisible-but-present nature of soft deletes: the record never left the database, only its visibility changed. Type `exit` to leave Tinker.

### Step 4: Test Pagination

If you have fewer than 15 entries, pagination links will not appear because there is only one page. Temporarily change `paginate(15)` to `paginate(2)` to force pagination with fewer entries. Navigate between pages and verify the correct entries appear on each page, then restore the original value.

---

## 7. Fix the Errors in Your Code

These are the most common mistakes when working with eager loading, soft deletes, and pagination.

**Error 1: Using the `SoftDeletes` trait without running the migration.**

This error occurs when you add `use SoftDeletes;` to the model but forget to create and run the migration that adds the `deleted_at` column. Every query then fails because Eloquent adds `WHERE deleted_at IS NULL` referencing a column that does not exist.

```php
// Wrong: trait added to model without a deleted_at column in the database
class Entry extends Model
{
    use SoftDeletes;
}

// Correct: migration creates the column first, then the trait manages it
Schema::table('entries', function (Blueprint $table) {
    $table->softDeletes();
});

class Entry extends Model
{
    use SoftDeletes;
}
```

The wrong version activates the trait on the model before any migration has added the `deleted_at` column to the database. Every query immediately throws "Unknown column 'entries.deleted_at'" because Eloquent appends `WHERE deleted_at IS NULL` to every Entry query the moment the trait is in use. The correct version runs the migration first so the column exists before the trait references it. The required sequence is: generate the migration with `php artisan make:migration add_soft_deletes_to_entries --table=entries`, add `$table->softDeletes()` to its `up()` method, run `php artisan migrate` to apply it, and only after confirming the column exists add `use SoftDeletes;` to the model.

---

**Error 2: Calling `links()` on a Collection instead of a Paginator.**

This error occurs when you use `all()` or `get()` in the controller and then try to call `->links()` in the view. Both `all()` and `get()` return a `Collection`, which does not have a `links()` method. Only `paginate()` and `simplePaginate()` return a Paginator that supports `links()`.

```php
// Wrong: get() returns a Collection which has no links() method
$entries = Entry::latest()->get();

// Correct: paginate() returns a LengthAwarePaginator that supports links()
$entries = Entry::latest()->paginate(15);
```

The wrong version calls `get()`, so `$entries->links()` in the view throws "Method links does not exist". The correct version calls `paginate(15)`, which returns a `LengthAwarePaginator` that includes both the entries and the metadata needed to render page navigation.

---

**Error 3: Route model binding returning 404 for soft-deleted entries.**

This error occurs when you define a restore route but forget to add `->withTrashed()`. By default, `{entry}` in a route URL only resolves active (non-deleted) entries, so requesting a trashed entry's restore URL returns a 404 instead of finding the record.

```php
// Wrong: missing withTrashed(), soft-deleted entries cannot be resolved
Route::patch('/entries/{entry}/restore', [EntryController::class, 'restore'])
    ->name('entries.restore');

// Correct: withTrashed() tells route model binding to include soft-deleted records
Route::patch('/entries/{entry}/restore', [EntryController::class, 'restore'])
    ->name('entries.restore')
    ->withTrashed();
```

Without `->withTrashed()`, visiting `/entries/42/restore` returns 404 because entry 42 has a non-null `deleted_at` and Eloquent's default query excludes it. Adding `->withTrashed()` explicitly allows the route model binding to find the trashed record so the restore method receives it correctly.

---

## 8. Exercises

Practice the three features from this lesson by extending what you have already built. Each exercise targets one specific concept so you can verify your understanding independently before moving on.

**Exercise 1:** Use `DB::enableQueryLog()` and `DB::getQueryLog()` to compare the exact number of queries with and without eager loading on the entries feed. Document the difference for 10 entries.

**Exercise 2:** Add a "Permanently Delete" button on the trash page that calls `$entry->forceDelete()`. Add a confirmation dialog with JavaScript `confirm()` before the form submits.

**Exercise 3:** Switch from `paginate(15)` to `simplePaginate(15)`. Compare the rendered HTML. `simplePaginate` only shows Previous/Next buttons with no page numbers, which is faster for very large tables because it skips the total count query.

---

## 9. Solutions

Each solution below provides a complete implementation for the corresponding exercise. Read the explanation after each code block to understand why the code works, not just what it does.

**Solution for Exercise 1:**

Temporarily replace the body of the `index` method in `app/Http/Controllers/EntryController.php` with the following diagnostic code, run the page, and compare with and without the `with()` calls.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index()
    {
        \DB::enableQueryLog();

        $entries = Entry::with('user', 'tags')->withCount('comments')->get();

        foreach ($entries as $entry) {
            $_ = $entry->user->name;
            $_ = $entry->tags->count();
        }

        dd(count(\DB::getQueryLog()));
    }

    // ... other methods
}
```

`\DB::enableQueryLog()` starts recording queries. The `with('user', 'tags')` preloads both relationships in bulk. The foreach loop accesses those properties, but because they were eager loaded, no new queries run. `dd(count(\DB::getQueryLog()))` outputs the total and stops execution. With eager loading in place, the count should be 3 to 4 queries regardless of the number of entries. Without eager loading, the same loop on 10 entries produces 1 + (10 × 2) = 21 queries. The difference grows linearly with the number of entries.

---

**Solution for Exercise 2:**

Register the force-delete route inside the authenticated route group in `routes/web.php`.

```php
Route::delete('/entries/{entry}/force-delete', [EntryController::class, 'forceDestroy'])
    ->name('entries.force-destroy')
    ->withTrashed();
```

Add the controller method to `app/Http/Controllers/EntryController.php`.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function forceDestroy(Entry $entry)
    {
        if ($entry->user_id !== auth()->id()) {
            abort(403);
        }

        $entry->forceDelete();

        return redirect()->route('entries.trash')->with('success', 'Entry permanently deleted.');
    }
}
```

In `resources/views/entries/trash.blade.php`, add the permanently delete button with a confirmation dialog.

```blade
<form method="POST" action="{{ route('entries.force-destroy', $entry) }}"
      onsubmit="return confirm('This cannot be undone. Permanently delete?')">
    @csrf
    @method('DELETE')
    <button type="submit" style="color: #dc2626; background: none; border: none; cursor: pointer;">
        Permanently Delete
    </button>
</form>
```

The ownership check `if ($entry->user_id !== auth()->id())` prevents a user from permanently deleting another user's trashed entry. `forceDelete()` bypasses soft deletes and removes the record permanently from the database. The JavaScript `confirm()` in `onsubmit` shows a browser dialog and cancels the form submission if the user clicks Cancel. The `->withTrashed()` on the route is required so route model binding can find soft-deleted entries.

---

**Solution for Exercise 3:**

Open `app/Http/Controllers/EntryController.php` and replace `paginate(15)` with `simplePaginate(15)` in the `index` method of the `EntryController` class.

```php
<?php
// ... others lines of code

class EntryController extends Controller
{
    // ... other methods

    public function index(Request $request)
    {
        $query = auth()->user()->entries()->with('tags')->withCount('comments');

        if ($request->filled('search')) {
            $query->search($request->input('search'));
        }

        $entries = $query->latest()->simplePaginate(15);

        return view('entries.index', compact('entries'));
    }

    // ... other methods
}
```

The return type changes from `LengthAwarePaginator` to `Paginator`. The practical difference is that `simplePaginate` runs only one SQL query to fetch the current page's records, while `paginate` runs a second `SELECT COUNT(*)` query to determine the total number of pages. For large tables with millions of rows, that count query can be slow. The trade-off is that `$entries->links()` in the view now renders only Previous and Next buttons, with no numbered page links, because `simplePaginate` does not know the total record count. Change the value back to `paginate(15)` for Catatku unless the entry count grows large enough to justify the switch.

---

## Next Up - Lesson 5

In this lesson you applied three production-grade features to Catatku. Eager loading with `with()` eliminates the N+1 query problem by preloading relationships in bulk, reducing dozens of queries to a handful regardless of dataset size. Soft deletes with the `SoftDeletes` trait and a `deleted_at` column make deletion forgiving: entries can be restored from a trash page without any data loss. Pagination with `paginate(15)` and `$entries->links()` ensures the feed stays fast and navigable even when a user has hundreds of entries.

In Lesson 5, you will learn Gates and Policies: how to define and enforce authorization rules so that users can only view, edit, and delete their own entries, no matter how they try to reach those pages.