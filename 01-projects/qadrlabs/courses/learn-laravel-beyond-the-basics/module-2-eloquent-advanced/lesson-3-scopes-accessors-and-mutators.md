## 1. Before You Begin

Every application repeats certain queries: "get only recent entries", "get entries by the current user", "search entries by keyword". Writing `where('created_at', '>=', now()->subDays(7))` every time is tedious and error-prone. Eloquent scopes let you define reusable query filters on the model itself. Similarly, you often need to transform data: display a formatted date when reading, or auto-capitalize a title when writing. Accessors transform data on read, and mutators transform data on write.

This lesson covers local scopes for reusable query filters, accessors for formatting output, and mutators for cleaning input. All three are applied to the Entry model in Catatku, keeping transformation logic in the model and out of controllers and views. By centralizing these patterns, your code stays consistent whether data flows through controllers, Tinker, seeders, or tests.

### What You'll Build

You will add scopes for common queries (recent entries, search, entries with comments), an excerpt accessor for displaying content previews, a reading time accessor, and a title mutator that auto-capitalizes.

### What You'll Learn

- ✅ Local scopes: `scopeRecent`, `scopeSearch`, `scopeByUser`
- ✅ Using scopes: `Entry::recent()->get()`
- ✅ Accessors: `Attribute::get()` (Laravel 11+ syntax)
- ✅ Mutators: `Attribute::set()`
- ✅ Combining scopes for complex queries

### What You'll Need

- Lesson 2 completed with tags working

---

## 2. Local Scopes

A local scope is a method on the model prefixed with `scope`. It receives a query builder and adds constraints. When you call the scope, you omit the `scope` prefix: `scopeRecent` becomes `Entry::recent()`. This naming convention is how Eloquent recognizes which methods are scopes versus normal model methods.

### Step 1: Add Scopes to the Entry Model

Open `app/Models/Entry.php` and add the four scope methods below to the `Entry` class. Add the `Builder` import alongside the existing `use` statements at the top of the file.

```php
<?php
// ... others lines of code
use Illuminate\Database\Eloquent\Builder;

#[Fillable(['title', 'content'])]
class Entry extends Model
{
    // ... other methods and properties

    public function scopeRecent(Builder $query): Builder
    {
        return $query->where('created_at', '>=', now()->subDays(7));
    }

    public function scopeByUser(Builder $query, int $userId): Builder
    {
        return $query->where('user_id', $userId);
    }

    public function scopeHasComments(Builder $query): Builder
    {
        return $query->has('comments');
    }

    public function scopeSearch(Builder $query, string $keyword): Builder
    {
        return $query->where(function (Builder $q) use ($keyword) {
            $q->where('title', 'like', "%{$keyword}%")
              ->orWhere('content', 'like', "%{$keyword}%");
        });
    }
}
```

Let us inspect each scope in detail so you understand how they are structured. Every scope method follows the same pattern: its name starts with `scope`, it accepts a `Builder $query` as the first parameter (which Laravel injects automatically when you call the scope), it adds query conditions, and it returns the modified builder.

`scopeRecent` adds a `where` clause filtering `created_at` to the last 7 days using Carbon's `now()->subDays(7)` helper. `scopeByUser` takes an additional `int $userId` parameter; arguments you pass when calling the scope map to these extra parameters after the injected `$query`. `scopeHasComments` uses Eloquent's `has()` method, which adds a `WHERE EXISTS` subquery checking that at least one related comment exists.

`scopeSearch` is the most complex. It wraps its conditions inside `where(function (Builder $q) use ($keyword) { ... })` so that the `OR` condition between title and content is properly grouped in parentheses. Without this grouping, chaining `->recent()->search('hello')` could produce SQL like `WHERE created_at >= ? AND title LIKE ? OR content LIKE ?`, which is semantically wrong because `OR` has lower precedence than `AND`. The closure-wrapped version produces `WHERE created_at >= ? AND (title LIKE ? OR content LIKE ?)`, which correctly groups the search conditions.

### Step 2: Use Scopes in Controllers

Open `app/Http/Controllers/EntryController.php` and update the `index` method in the `EntryController` class to apply the search scope conditionally based on the incoming request.

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

Reading through this code: the first line starts a query builder for the authenticated user's entries, eager loads tags, and adds a subquery for comment counts. Because we do not call `get()` yet, this remains a query builder we can modify further. The `if ($request->filled('search'))` check returns true only when the `search` input is present and non-empty, so submitting `?search=` with nothing typed does not trigger filtering. When non-empty, `$query->search(...)` calls the `scopeSearch` method you defined, appending the title/content LIKE conditions to the existing builder. Finally, `latest()->get()` orders by `created_at` descending and executes the full query. Scopes compose naturally with any other query methods because they all modify the same underlying builder.

---

## 3. Accessors

Accessors transform data when you read a model property. They do not change what is stored in the database; they change what you see when you access the property. Think of them as computed properties, similar to getter methods in traditional OOP but with a cleaner property-like syntax. Laravel 11+ uses the `Attribute` class for defining accessors and mutators, which is a newer and more expressive API than the older `getXxxAttribute` method style.

### Step 1: Add Accessors to the Entry Model

Open `app/Models/Entry.php` and add the three accessor methods below to the `Entry` class. Add the `Attribute` import alongside the existing `use` statements at the top of the file.

```php
<?php
// ... others lines of code
use Illuminate\Database\Eloquent\Casts\Attribute;

#[Fillable(['title', 'content'])]
class Entry extends Model
{
    // ... other methods and properties

    protected function excerpt(): Attribute
    {
        return Attribute::get(fn () => str($this->content)->limit(100)->toString());
    }

    protected function readingTime(): Attribute
    {
        return Attribute::get(fn () => max(1, (int) ceil(str_word_count($this->content) / 200)));
    }

    protected function createdAtHuman(): Attribute
    {
        return Attribute::get(fn () => $this->created_at?->diffForHumans());
    }
}
```

Walking through each accessor carefully: the `use` statement imports the `Attribute` class. Each method is `protected` (accessors do not need to be public since you do not call them directly) and returns an `Attribute` instance. The `Attribute::get(...)` factory accepts a closure that computes the value whenever you read the property.

The `excerpt` accessor wraps the content in Laravel's fluent string helper using `str($this->content)`, calls `limit(100)` to truncate to 100 characters and append a default ellipsis, and converts the result back to a plain string with `toString()`. The `readingTime` accessor estimates reading duration: `str_word_count($this->content)` counts the words using PHP's built-in function, divides by 200 (the average reading speed in words per minute), rounds up with `ceil()` so 0.3 becomes 1, casts to integer for clean output, and wraps in `max(1, ...)` to guarantee at least one minute even for very short entries. The `createdAtHuman` accessor uses Carbon's `diffForHumans()` to produce strings like "3 hours ago", with the null-safe operator `?->` preventing an error if `created_at` is somehow null.

The method names use camelCase, but Laravel automatically converts them to snake_case when you access them as properties: `$entry->excerpt`, `$entry->reading_time`, `$entry->created_at_human`.

### Step 2: Use Accessors in Views

Open `resources/views/components/entry-card.blade.php`. In the content snippet section, replace the existing `<p>` block with the following two elements — the first uses `$entry->excerpt` instead of the raw content, and the second adds reading time and relative date below it.

```blade
{{-- Content snippet --}}
<p class="text-sm text-gray-500 line-clamp-2 mb-2">
    {{ $entry->excerpt }}
</p>
<span style="color: #9ca3af; font-size: 0.8em;">
    {{ $entry->reading_time }} min read · {{ $entry->created_at_human }}
</span>
```

Notice how the accessors are accessed like regular properties with no function call syntax. `{{ $entry->excerpt }}` triggers the excerpt closure behind the scenes and outputs the computed string. Similarly, `{{ $entry->reading_time }}` executes the calculation. Laravel automatically converts the camelCase method name (`readingTime`) to snake_case (`reading_time`) when matching property access, which is why you must use snake_case in the template even though your method uses camelCase.

After the change, the full `entry-card.blade.php` looks like this:

```
@props(['entry'])

<div class="bg-white rounded-xl border border-gray-200 p-5 hover:border-gray-300 transition-colors">

    {{-- Header: title and date --}}
    <div class="flex items-start justify-between gap-3 mb-3">
        <a href="/entries/{{ $entry->id }}" class="font-semibold text-gray-900 hover:text-gray-600 leading-snug">
            {{ $entry->title }}
        </a>
        <span class="text-xs text-gray-400 whitespace-nowrap mt-0.5">
            {{ $entry->created_at->format('d M Y') }}
        </span>
    </div>

    {{-- Content snippet --}}
    <p class="text-sm text-gray-500 line-clamp-2 mb-2">
        {{ $entry->excerpt }}
    </p>
    <span style="color: #9ca3af; font-size: 0.8em;">
        {{ $entry->reading_time }} min read · {{ $entry->created_at_human }}
    </span>

    {{-- Tags --}}
    @if($entry->tags->isNotEmpty())
        <div style="margin-top: 8px; display: flex; flex-wrap: wrap; gap: 4px;">
            @foreach ($entry->tags as $tag)
                <span style="background: #dbeafe; color: #1e40af; padding: 2px 10px; border-radius: 12px; font-size: 0.75em; font-weight: 600;">
                    {{ $tag->name }}
                </span>
            @endforeach
        </div>
    @endif

    {{-- Action buttons --}}
    <div class="flex items-center gap-3 pt-3 border-t border-gray-100">
        <a href="/entries/{{ $entry->id }}" class="text-xs text-blue-600 hover:text-blue-800">
            Read
        </a>
        <a href="/entries/{{ $entry->id }}/edit" class="text-xs text-gray-500 hover:text-gray-800">
            Edit
        </a>
        <form method="POST" action="/entries/{{ $entry->id }}" onsubmit="return confirm('Delete this entry?')"
            class="ml-auto">
            @csrf
            @method('DELETE')
            <button type="submit" class="text-xs text-red-400 hover:text-red-600">
                Delete
            </button>
        </form>
    </div>

</div>
```

---

## 4. Mutators

Mutators transform data before it is saved to the database. They are the opposite of accessors: they change what is stored, not what is displayed. This is the right place for data cleanup and normalization because it runs automatically no matter where the data comes from, whether that is a controller, a seeder, a queue job, or Tinker.

### Step 1: Add a Title Mutator

Open `app/Models/Entry.php` and add the following method to the `Entry` class.

```php
<?php
// ... others lines of code

#[Fillable(['title', 'content'])]
class Entry extends Model
{
    // ... other methods and properties

    protected function title(): Attribute
    {
        return Attribute::make(
            get: fn (string $value) => $value,
            set: fn (string $value) => ucfirst(trim($value)),
        );
    }
}
```

This mutator uses `Attribute::make()` instead of separate `get()` or `set()` calls because we want to define both read and write behavior in one method. The `get` callback receives the raw value from the database and returns what you see when you read `$entry->title`; here we return it unchanged because we do not want to alter the display. The `set` callback receives what the user tries to save and returns the normalized version. Inside, `trim($value)` removes whitespace from both ends, and `ucfirst()` capitalizes the first character of the result. So when a user types "  my vacation diary  ", the database stores "My vacation diary". When using `Attribute::make()`, both `get` and `set` keys are required; if you only need one direction, use `Attribute::get()` or `Attribute::set()` separately.

---

## 5. Run and Test

Let us verify that scopes, accessors, and mutators all work correctly by exercising each one in sequence.

### Step 1: Test Scopes in Tinker

Open a terminal and launch Tinker.

```bash
php artisan tinker
```

Once inside Tinker, run the following commands one at a time to verify each scope.

```php
use App\Models\Entry;

Entry::recent()->count();

Entry::search('vacation')->get()->pluck('title');

Entry::recent()->hasComments()->count();
```

The first line counts entries from the last seven days using `scopeRecent`. The second finds entries whose title or content contains "vacation" using `scopeSearch`, then `pluck('title')` extracts just the title column into a simple array for easy viewing. The third chains two scopes together to find entries that are both recent and have at least one comment, proving that scopes compose naturally. Type `exit` to leave Tinker.

### Step 2: Test Accessors in Tinker

Launch Tinker again and access the new computed properties on an existing entry.

```bash
php artisan tinker
```

Run the following commands to verify each accessor returns the expected output.

```php
$entry = \App\Models\Entry::first();

$entry->excerpt;

$entry->reading_time;

$entry->created_at_human;
```

Each property access triggers the corresponding accessor closure. `$entry->excerpt` returns a truncated snippet of the content with an ellipsis. `$entry->reading_time` returns an integer representing the estimated minutes to read the entry. `$entry->created_at_human` returns a relative string like "2 days ago". Notice that you read them as properties, not by calling methods, which is the key advantage of the Attribute API. Type `exit` to leave Tinker.

### Step 3: Test the Mutator

Still in Tinker (or a fresh session), test that the title mutator normalizes input before saving.

```php
$entry = \App\Models\Entry::first();
$entry->title = "  hello world  ";
$entry->save();
$entry->fresh()->title;
```

The assignment `$entry->title = "  hello world  "` triggers the `set` callback of the title mutator, which trims whitespace and capitalizes the first character. Calling `save()` persists the transformed value to the database. `fresh()` reloads the model from the database to prove the stored value really is "Hello world" and not just an in-memory transformation that would be lost on the next request.

### Step 4: Test Search in the Browser

Start the development server and test the search scope through the UI.

```bash
php artisan serve
```

Log in, navigate to the entries page, and add `?search=vacation` to the URL in the address bar. Only entries containing "vacation" in the title or content should appear. Try a few different keywords to confirm the search works consistently. This proves that the scope integrates properly with controller logic and view rendering.

---

## 6. Fix the Errors in Your Code

These are the most common mistakes when working with scopes, accessors, and mutators. Each one is easy to make and easy to fix once you know what to look for.

**Error 1: Scope method without the `scope` prefix.**

This error occurs when you define a method on the model with the intent of using it as a scope but forget to add the `scope` prefix. Laravel only recognizes scope methods by their prefix, so without it the method is treated as a regular instance method and cannot be called as a static scope.

```php
// Wrong: no scope prefix, this is just a regular method
public function recent(Builder $query): Builder
{
    return $query->where('created_at', '>=', now()->subDays(7));
}

// Correct: scope prefix tells Eloquent this is a scope
public function scopeRecent(Builder $query): Builder
{
    return $query->where('created_at', '>=', now()->subDays(7));
}
```

The wrong version defines `recent` without the `scope` prefix. Calling `Entry::recent()` then fails with a "Call to undefined method" error. The correct version names the method `scopeRecent`, allowing you to call it as `Entry::recent()` where Laravel strips the prefix automatically.

---

**Error 2: Accessing an accessor property using camelCase instead of snake_case.**

This error occurs when you define an accessor as `readingTime()` but try to access it in a view or controller as `$entry->readingTime` instead of `$entry->reading_time`. Laravel uses snake_case convention for property access regardless of the method name's casing.

```php
// Wrong: camelCase access returns null
$entry->readingTime;

// Correct: snake_case access triggers the accessor
$entry->reading_time;
```

The wrong version accesses the property in camelCase and gets `null` because Laravel does not match it to the `readingTime()` method. The correct version uses snake_case (`reading_time`), which Laravel converts back to camelCase internally to find the right accessor method. Always access custom accessor properties in snake_case in views and controllers.

---

**Error 3: Mutator causes infinite recursion by assigning to `$this`.**

This error occurs when you write the set callback of a mutator so that it assigns a value back to the same property on the model, which triggers the mutator again, creating an infinite recursive loop that eventually crashes with a stack overflow.

```php
// Wrong: assigning to $this->title triggers the mutator again
protected function title(): Attribute
{
    return Attribute::set(fn ($value) => $this->title = ucfirst($value));
}

// Correct: return the transformed value directly
protected function title(): Attribute
{
    return Attribute::set(fn ($value) => ucfirst($value));
}
```

The wrong version assigns the result back to `$this->title` inside the set callback. That assignment triggers the title mutator again, which triggers it again, and so on until the execution stack overflows. The correct version returns the transformed value directly from the closure. Eloquent takes the returned value and stores it in the model's attribute array without triggering the mutator again.

---

## 7. Exercises

Practice extending the Entry model using the three patterns from this lesson. Each exercise is self-contained and builds directly on what you added in the steps above. Try each one on your own before checking the solutions.

**Exercise 1:** Add a `scopePopular` scope that filters entries with more than a given number of comments. Use `$query->withCount('comments')->having('comments_count', '>=', $min)`. Call it with `Entry::popular(3)->get()`.

**Exercise 2:** Add a `word_count` accessor that returns the number of words in the content. Display it in the view next to the reading time: "245 words · 2 min read".

**Exercise 3:** Add a `content` mutator that trims leading and trailing whitespace from the content before saving. Test by creating an entry with extra spaces and verifying the stored content is trimmed.

---

## 8. Solutions

Each solution below shows one correct implementation for the exercise. Your code may differ in minor details as long as the behavior matches what the exercise describes.

**Solution for Exercise 1:**

Open `app/Models/Entry.php` and add the following method inside the class body.

```php
public function scopePopular(Builder $query, int $min = 3): Builder
{
    return $query->withCount('comments')->having('comments_count', '>=', $min);
}
```

The `withCount('comments')` adds a `comments_count` column to the query results via a subquery. The `having()` clause filters by that count after the subquery runs. We use `having` instead of `where` because `comments_count` is an aggregate produced by the subquery, not a real column on the `entries` table, and `having` is designed for filtering on aggregates. The default value of `$min = 3` allows you to call `Entry::popular()->get()` without an argument to get entries with three or more comments, while `Entry::popular(5)->get()` raises the threshold to five.

---

**Solution for Exercise 2:**

Open `app/Models/Entry.php` and add the following accessor inside the class body.

```php
protected function wordCount(): Attribute
{
    return Attribute::get(fn () => str_word_count($this->content));
}
```

This accessor calls PHP's built-in `str_word_count()` function, which counts the number of words in a string and returns an integer. Access it in views as `$entry->word_count` (snake_case). Update the view to show both word count and reading time together.

```blade
<span style="color: #9ca3af; font-size: 0.8em;">
    {{ $entry->word_count }} words · {{ $entry->reading_time }} min read
</span>
```

`$entry->word_count` reads the integer returned by the accessor, and the dot in between is a plain text separator. No additional query runs to produce this output.

---

**Solution for Exercise 3:**

Open `app/Models/Entry.php` and add the following method inside the class body.

```php
protected function content(): Attribute
{
    return Attribute::make(
        get: fn (string $value) => $value,
        set: fn (string $value) => trim($value),
    );
}
```

The `set` callback calls `trim()` on the incoming value before it is stored in the database. The `get` callback returns the stored value unchanged. This means every time content is written to the model (through `create()`, `update()`, or direct assignment followed by `save()`), the leading and trailing whitespace is automatically removed. To verify it, open Tinker and create an entry with extra spaces, then use `fresh()` to reload from the database and confirm the stored content has no surrounding whitespace.

---

## Next Up - Lesson 4

In this lesson you added three types of model intelligence to Catatku's Entry model. Local scopes encapsulate reusable query filters so you can call `Entry::recent()` or chain `->search('keyword')` from any controller without rewriting the SQL conditions. Accessors like `excerpt` and `reading_time` compute derived values on the fly without changing what is stored in the database, and your views access them exactly like regular columns. Mutators like `title` normalize input automatically before it reaches the database, ensuring consistency across every code path that creates or updates entries.

In Lesson 4, you will learn eager loading, soft deletes, and pagination: how to eliminate N+1 queries with `with()`, how to safely "delete" entries by keeping them in the database with a timestamp, and how to paginate large result sets with Laravel's built-in paginator.