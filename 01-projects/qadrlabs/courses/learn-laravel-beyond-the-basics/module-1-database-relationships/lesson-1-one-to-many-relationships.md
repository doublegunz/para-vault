## 1. Before You Begin

In the beginner course, Catatku had a single model: `Entry`. Every entry belonged to a user through the `user_id` column, but we never formally defined that relationship in Eloquent. We also never added related data like comments. In real applications, data is connected: users have many entries, entries have many comments, orders have many items. Eloquent relationships let you define these connections once and query across them effortlessly.

This lesson teaches the most common relationship in Laravel: one-to-many. One user has many entries. One entry has many comments. You will define `hasMany` and `belongsTo` relationships, create related records, and query across relationships. By the end, Catatku entries will have a working comment system that you can use in the browser.

### What You'll Build

You will add a `Comment` model to Catatku. Each entry can have many comments, and each comment belongs to one user and one entry. You will display comments below each entry and create a form to post new comments.

### What You'll Learn

- ✅ `hasMany()` on the parent model
- ✅ `belongsTo()` on the child model
- ✅ Creating related records with `$entry->comments()->create()`
- ✅ Querying relationships: `$user->entries`, `$entry->comments`
- ✅ Inverse relationships and foreign key conventions
- ✅ Migrations with foreign key constraints
- ✅ Displaying related data in Blade views

### What You'll Need

- The Catatku project from the beginner course with users and entries working
- Laravel 13 development server running (`php artisan serve`)

---

## 2. Create the Comments Migration

Every relationship starts with the database. Before Eloquent can connect entries to comments, the `comments` table must exist with the right foreign key columns. A comment belongs to an entry and a user, so it needs both `entry_id` and `user_id` foreign keys. In this section you will generate a model paired with its migration, define the table schema, and apply it to the database.

### Step 1: Generate the Migration and Model

Open your terminal in the Catatku project directory and run the following command. The `-m` flag tells Artisan to create a migration file alongside the model.

```bash
php artisan make:model Comment -m
```

This creates two files at once. The first is `app/Models/Comment.php`, which is the Eloquent model class you will use to query and manipulate comment records. The second is a migration file in `database/migrations/` whose filename begins with a timestamp (for example, `2026_04_17_093000_create_comments_table.php`). Laravel uses that timestamp to decide the order in which migrations run, so newer migrations always run after older ones.

### Step 2: Define the Migration

Open the newly created migration file in `database/migrations/`. The filename contains a timestamp followed by `_create_comments_table.php`. Replace the `up()` method content with the following schema definition.

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('comments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('entry_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->text('body');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('comments');
    }
};
```

Now let us walk through every line so you understand exactly what this migration does. The `use` statements at the top import the three classes Laravel needs for migrations: `Migration` is the base class, `Blueprint` is the object you use to define columns, and `Schema` is the facade that talks to the database. The `return new class extends Migration` syntax is an anonymous migration class, which Laravel introduced to avoid naming conflicts between migration files. Inside the `up()` method, the `Schema::create('comments', ...)` call tells Laravel to create a new table named `comments`. The closure receives a `Blueprint` object named `$table` that you use to define each column.

`$table->id()` creates an auto-incrementing primary key named `id`. The line `$table->foreignId('entry_id')->constrained()->cascadeOnDelete()` does three things at once: it creates a column called `entry_id` as an unsigned big integer, adds a foreign key constraint that points to the `id` column on the `entries` table (Laravel infers the table name from the column name), and sets a cascading delete rule so when an entry is deleted every comment belonging to that entry is automatically deleted too. The same pattern repeats for `user_id`, which links each comment to its author in the `users` table. `$table->text('body')` creates a `TEXT` column that can store long comment content without a character limit. `$table->timestamps()` adds two standard columns, `created_at` and `updated_at`, which Laravel manages automatically. The `down()` method defines the opposite operation: if you ever roll back this migration, `Schema::dropIfExists('comments')` drops the entire table.

### Step 3: Run the Migration

Execute the migration to create the table in the database.

```bash
php artisan migrate
```

You should see output confirming the `comments` table was created. If you get an error about the `entries` or `users` table not existing, make sure you have run all previous migrations from the beginner course first, because foreign keys cannot point to tables that do not yet exist.

---

## 3. Define the Relationships

Now that the database table exists, you need to tell Eloquent how the models are related. Relationships are defined as methods on the model classes. Once defined, the method name becomes a property you can use to access related data, and Laravel handles the underlying SQL joins for you automatically.

### Step 1: User Has Many Entries

The `entries()` relationship was already defined on the `User` model in the beginner course. Open `app/Models/User.php` and confirm the following method is present.

```php
use Illuminate\Database\Eloquent\Relations\HasMany;

public function entries(): HasMany
{
    return $this->hasMany(Entry::class);
}
```

Let us examine this code piece by piece. The `use` statement imports the `HasMany` class, which is the return type of the relationship method. The method name `entries` is significant because it becomes the property name you use to access related data: `$user->entries`. The return type `HasMany` is a type hint that makes the relationship self-documenting and helps your IDE provide autocomplete. Inside the method, `$this->hasMany(Entry::class)` tells Eloquent that one User can have many Entry records. Laravel automatically looks for a `user_id` column on the `entries` table to make the connection (this is the naming convention: parent model name in snake_case plus `_id`). You can now access all of a user's entries with `$user->entries` and get back a Collection of Entry models.

### Step 2: Entry Belongs To User, Has Many Comments

Open `app/Models/Entry.php` and update it to define both the existing `belongsTo` relationship with User and the new `hasMany` relationship with Comment.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['title', 'content'])]
class Entry extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function comments(): HasMany
    {
        return $this->hasMany(Comment::class);
    }
}
```

Reading through this class carefully, you see three important parts. The `use` statements bring in the `Fillable` attribute class alongside both relationship classes (`BelongsTo` and `HasMany`) so each can be type-hinted correctly. The `#[Fillable(['title', 'content'])]` attribute placed above the class declaration lists the columns that are allowed to be mass assigned when creating or updating an entry. This is a security feature carried over from the beginner course that prevents users from setting columns like `user_id` through request input. Laravel 13 uses this PHP attribute syntax as the modern replacement for the older `protected $fillable = [...]` property - if you have seen older tutorials, that is the equivalent. The `user()` method defines the inverse of the one-to-many relationship: this entry belongs to one user. Eloquent assumes the foreign key is `user_id` on the `entries` table (following the parent-name plus `_id` convention). The `comments()` method declares that this entry can have many comments, and Eloquent will look for an `entry_id` column on the `comments` table, which is exactly the column you defined in the migration. Notice how naming conventions do a lot of the work: because you followed the convention, you never had to write a single line of configuration to tell Laravel about the column names.

### Step 3: Comment Belongs To User and Entry

Open `app/Models/Comment.php` and replace the generated content with the following code.

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['body', 'user_id'])]
class Comment extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function entry(): BelongsTo
    {
        return $this->belongsTo(Entry::class);
    }
}
```

A comment has two `belongsTo` relationships because it lives at the intersection of two parents. The `user()` method says the comment belongs to the user who wrote it, and Eloquent looks up the `user_id` column to make that connection. The `entry()` method says the comment also belongs to the entry it was posted on, using the `entry_id` column. `#[Fillable]` includes `body` and `user_id` because the controller passes both through `create()`. `entry_id` is deliberately excluded: it is set automatically by the relationship method `$entry->comments()->create(...)`, which fills `entry_id` behind the scenes — you never need to pass it explicitly. The security concern is not whether `user_id` is fillable, but where its value comes from: the controller always takes it from `$request->user()->id` (the authenticated session), never from request input, so a malicious user cannot override it.

---

## 4. Create the Comment Controller

With the models and relationships defined, you need a controller to handle creating comments. Comments are always created in the context of a specific entry, so the store method receives an Entry as a route parameter, and the controller uses the relationship method to make the new comment inherit the entry's ID automatically.

### Step 1: Generate the Controller

Run the following Artisan command to create an empty controller file for comments.

```bash
php artisan make:controller CommentController
```

This creates `app/Http/Controllers/CommentController.php`, an empty controller class that extends Laravel's base controller. You will add the `store` method to this file in the next step.

### Step 2: Write the Store Method

Open `app/Http/Controllers/CommentController.php` and replace its content with the following.

```php
<?php

namespace App\Http\Controllers;

use App\Models\Entry;
use Illuminate\Http\Request;

class CommentController extends Controller
{
    public function store(Request $request, Entry $entry)
    {
        $validated = $request->validate([
            'body' => 'required|string|min:2|max:1000',
        ]);

        $entry->comments()->create([
            ...$validated,
            'user_id' => $request->user()->id,
        ]);

        return back()->with('success', 'Comment posted!');
    }
}
```

Let us break this method down into its stages. The method signature `store(Request $request, Entry $entry)` uses two dependency-injected objects. The `Request` object contains the form submission data. The `Entry $entry` parameter uses Laravel's route model binding: when the URL is something like `/entries/5/comments`, Laravel automatically fetches the Entry with ID 5 and injects it here, returning a 404 if it does not exist.

Inside the method, `$request->validate([...])` checks that the input meets the rules: `required` means the field must be present, `string` means it must be a string type, `min:2` means at least 2 characters, and `max:1000` caps it at 1000 characters. If validation fails, Laravel automatically redirects back with error messages, so no further code runs. The `$entry->comments()->create([...])` line is where the key interaction happens: it uses the `comments()` relationship method to create a new comment, and Laravel automatically fills in the `entry_id` because the relationship already knows which entry you are working with. The spread operator `...$validated` unpacks the validated data (just the `body` field) into the array, and we manually add `user_id` from the authenticated user. This is exactly the defense we talked about earlier: we never accept `user_id` from the user. Finally, `back()->with('success', 'Comment posted!')` redirects to the previous page and flashes a success message into the session so the next request can display it.

### Step 3: Register the Route

Before adding the comment route, give the existing entry routes names. The beginner course did not cover route names, but they are a convention used throughout this course and in nearly every real Laravel application. Open `routes/web.php` and add `->name(...)` to each entry route inside the `auth` middleware group.

```php
Route::middleware('auth')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/entries', [EntryController::class, 'index'])->name('entries.index');
    Route::get('/entries/create', [EntryController::class, 'create'])->name('entries.create');
    Route::post('/entries', [EntryController::class, 'store'])->name('entries.store');
    Route::get('/entries/{entry}', [EntryController::class, 'show'])->name('entries.show');
    Route::get('/entries/{entry}/edit', [EntryController::class, 'edit'])->name('entries.edit');
    Route::put('/entries/{entry}', [EntryController::class, 'update'])->name('entries.update');
    Route::delete('/entries/{entry}', [EntryController::class, 'destroy'])->name('entries.destroy');
});
```

These seven routes can also be declared in one line using `Route::resource()`, which generates the same seven names automatically.

```php
// Route::resource() generates all seven routes above with the same names
Route::resource('entries', EntryController::class);
```

In this course we write each route explicitly so every URL is visible, but `Route::resource()` is the shorthand most teams use once they understand what routes it produces.

Route names are used with the `route()` helper throughout views and controllers. Instead of hardcoding `href="/entries/{{ $entry->id }}"`, you write `href="{{ route('entries.show', $entry) }}"`. The helper resolves the name to the correct URL and fills in any route parameters from the model or array you pass as the second argument. The naming convention `resource.action` (for example, `entries.index`, `entries.show`, `entries.destroy`) is Laravel's standard pattern: you can always guess the name without looking it up. The other benefit is that if you ever rename a URL, you update one line in `routes/web.php` and every `route(...)` call in your views and controllers updates automatically, because they reference the name, not the raw path.

Now add the comment routes inside the same group, below the entry routes. We register two: one to create a comment, and one to delete it (which you will implement in Step 4).

```php
use App\Http\Controllers\CommentController;

Route::middleware('auth')->group(function () {
    // ... entry routes above ...
    Route::post('/entries/{entry}/comments', [CommentController::class, 'store'])
        ->name('comments.store');
    Route::delete('/comments/{comment}', [CommentController::class, 'destroy'])
        ->name('comments.destroy');
});
```

The URL pattern `/entries/{entry}/comments` nests the comment endpoint under the entry, and the `{entry}` segment is what triggers route model binding in the controller so Laravel resolves the Entry automatically from the URL. `Route::post(...)` means this route accepts only POST requests, which is correct for creating a resource. The `->name('comments.store')` assigns the name used in the form action: `route('comments.store', $entry)`. Passing the entry model as the second argument tells the `route()` helper to fill in `{entry}` with the entry's ID. The second route, `comments.destroy`, takes a `{comment}` parameter directly because deleting a comment only needs the comment's ID, not the entry's.

### Step 4: Add a Method to Delete Comments

A comment author should be able to remove their own comment. Open `app/Http/Controllers/CommentController.php` and add a `destroy` method below the existing `store` method.

```php
public function destroy(Comment $comment)
{
    if ($comment->user_id !== auth()->id()) {
        abort(403);
    }

    $comment->delete();

    return back()->with('success', 'Comment deleted.');
}
```

You will also need to import the `Comment` model at the top of the file, alongside the existing `use App\Models\Entry;` line:

```php
use App\Models\Comment;
```

The method receives a `Comment` through route model binding (the `{comment}` parameter in the route resolves to the matching record, returning 404 if it does not exist). The `if ($comment->user_id !== auth()->id())` check is an ownership guard: it compares the comment's author with the currently authenticated user and calls `abort(403)` if they do not match, so a user cannot delete someone else's comment by guessing the URL. This is the same manual check style used in the beginner course. In Lesson 5 you will replace this inline `if` with a dedicated **Policy** (`CommentPolicy`) and `Gate::authorize('delete', $comment)`, which centralizes authorization logic — but the manual check is correct and sufficient for now. After deleting, `back()->with('success', ...)` returns to the entry page with a flash message.

---

## 5. Display Comments and Comment Form

Now you need to update the entry detail view to show existing comments and provide a form for posting new ones. To keep this efficient, you will also eager load the comment authors so the view does not make a separate database query for each comment author.

### Step 1: Update the Entry Controller Show Method

Open your `EntryController.php` and update the `show` method to eager load comments along with their authors before passing the entry to the view.

```php
public function show(Entry $entry)
{
    if ($entry->user_id !== auth()->id()) {
        abort(403);
    }

    $entry->load('comments.user');

    return view('entries.show', compact('entry'));
}
```

The authorization check from the beginner course is preserved: if the entry does not belong to the currently authenticated user, `abort(403)` immediately returns a Forbidden response. The new line `$entry->load('comments.user')` eager loads two levels of relationships: all comments for this entry, and the user who wrote each comment. The dot notation `comments.user` tells Eloquent to traverse one more level after loading comments. Without this eager loading, every time your view renders `$comment->user->name`, Eloquent would run a new database query to fetch that user - an entry with 20 comments would produce 21 queries (this is called the N+1 problem, which Lesson 4 covers in depth). With eager loading, only three queries run total no matter how many comments exist: one for the entry, one for all its comments, and one for all the comment authors. The `compact('entry')` helper builds an array `['entry' => $entry]` to pass into the view.

### Step 2: Update the Show View

Open `resources/views/entries/show.blade.php` and update it with the comments section and form below the entry content.

```blade
<x-layout>
    <div style="max-width: 700px; margin: 0 auto;">

        {{-- Entry content --}}
        <h1 style="font-size: 1.5em; color: #1e293b; margin-bottom: 8px;">{{ $entry->title }}</h1>
        <p style="color: #888; font-size: 0.85em; margin-bottom: 16px;">
            Written {{ $entry->created_at->diffForHumans() }}
        </p>
        <div style="line-height: 1.7; color: #333; margin-bottom: 30px;">
            {{ $entry->content }}
        </div>

        <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 20px 0;">

        {{-- Comments section --}}
        <h2 style="font-size: 1.2em; color: #1e293b; margin-bottom: 16px;">
            Comments ({{ $entry->comments->count() }})
        </h2>

        @forelse ($entry->comments as $comment)
            <div style="padding: 12px 0; border-bottom: 1px solid #f3f4f6;">
                <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
                    <strong style="color: #1e293b;">{{ $comment->user->name }}</strong>
                    <span style="color: #9ca3af; font-size: 0.8em;">{{ $comment->created_at->diffForHumans() }}</span>
                </div>
                <p style="color: #4b5563; margin: 0;">{{ $comment->body }}</p>
                @if (auth()->id() === $comment->user_id)
                    <form method="POST" action="{{ route('comments.destroy', $comment) }}"
                          onsubmit="return confirm('Delete this comment?')" style="margin-top: 6px;">
                        @csrf
                        @method('DELETE')
                        <button type="submit"
                            style="font-size: 0.8em; color: #dc2626; background: none; border: none; cursor: pointer; padding: 0;">
                            Delete
                        </button>
                    </form>
                @endif
            </div>
        @empty
            <p style="color: #9ca3af; text-align: center; padding: 20px 0;">
                No comments yet. Be the first to comment!
            </p>
        @endforelse

        {{-- Comment form --}}
        <div style="margin-top: 20px; background: #f9fafb; padding: 16px; border-radius: 8px;">
            <h3 style="font-size: 1em; margin-bottom: 10px; color: #1e293b;">Write a Comment</h3>

            <form method="POST" action="{{ route('comments.store', $entry) }}">
                @csrf

                <textarea
                    name="body"
                    rows="3"
                    placeholder="Write your comment..."
                    style="width: 100%; padding: 10px; border: 1px solid #d1d5db; border-radius: 6px; resize: vertical; box-sizing: border-box; font-family: inherit;"
                >{{ old('body') }}</textarea>

                @error('body')
                    <p style="color: #dc2626; font-size: 0.85em; margin: 4px 0 0;">{{ $message }}</p>
                @enderror

                <button
                    type="submit"
                    style="margin-top: 10px; background: #2563eb; color: white; padding: 8px 20px; border: none; border-radius: 6px; cursor: pointer; font-weight: bold;"
                >
                    Post Comment
                </button>
            </form>
        </div>

        <a href="{{ route('entries.index') }}" style="display: inline-block; margin-top: 20px; color: #2563eb; text-decoration: none;">
            &larr; Back to entries
        </a>
    </div>
</x-layout>
```

Let us walk through the view section by section so you understand how every part contributes to the page. The `<x-layout>` component wraps everything in the shared page layout from the beginner course so you inherit the navigation bar and footer. The entry content block at the top displays the entry title with `{{ $entry->title }}`, uses Carbon's `diffForHumans()` method to produce a friendly relative timestamp like "3 hours ago", and renders the entry body.

The comments heading uses `$entry->comments->count()` to show how many comments exist. Note that `comments` here is accessed as a property (without parentheses) because we already loaded the collection with `$entry->load(...)`, so `count()` does not run another query. The `@forelse` directive is a Blade shortcut that combines `@foreach` with an `@empty` fallback: it loops through the comments if any exist, otherwise renders the "no comments yet" message. Inside the loop, each comment shows the author's name from the eager-loaded `user` relationship and a relative timestamp. The `@if (auth()->id() === $comment->user_id)` block renders a small **Delete** form only when the logged-in user wrote that comment, posting to the `comments.destroy` route via `@method('DELETE')`. Hiding the button is a UX convenience; the real protection is the `abort(403)` ownership guard in the `destroy` method, so the form is safe even if someone forges a request.

The comment form uses `method="POST"` and `action="{{ route('comments.store', $entry) }}"` to submit to the route you defined, passing the current entry as the route parameter. The `@csrf` directive inserts a hidden CSRF token that Laravel requires for all POST forms to prevent cross-site request forgery. The textarea uses `{{ old('body') }}` so that if validation fails, the user's typed text is preserved when the form re-renders. The `@error('body')` block displays the validation error message if one exists for the `body` field.

---

## 6. Run and Test

Now let us verify that everything works correctly by running the application and testing the comment system end to end.

### Step 1: Start the Development Server

Run the following command to start Laravel's built-in development server.

```bash
php artisan serve
```

You should see output similar to `INFO  Server running on [http://127.0.0.1:8000]`. Keep this terminal window open; closing it stops the server.

### Step 2: Test in the Browser

Open `http://localhost:8000` in your browser and log in with your existing account. Navigate to any entry's detail page by clicking on an entry title from the main listing. You should see the entry content followed by a "Comments (0)" section and a comment form below it.

Type a comment in the textarea (for example, "This is my first comment!") and click "Post Comment." The page should reload and show your comment displayed with your username on the left, a relative timestamp on the right (like "1 second ago"), and your comment body below. The comment count in the heading should also update to "Comments (1)".

### Step 3: Test Validation

Try submitting an empty comment form without typing anything. You should see a red error message below the textarea saying "The body field is required." This confirms that validation is working correctly. Now try submitting a single character like "a". You should see "The body field must be at least 2 characters." These messages come directly from the `required|string|min:2|max:1000` rules you wrote in the controller.

### Step 4: Verify Multiple Comments

Post two or three more comments on the same entry. Each new comment should appear in the list in chronological order, and the comment count in the heading should update each time (for example, "Comments (3)"). Try logging out, logging in as a different user, and commenting as that user; the new comments should show the correct username for each author.

### Step 5: Test in Tinker (Optional)

Tinker is a REPL that lets you interact with your application's code directly from the command line. It is invaluable for debugging and exploring relationships. Open a new terminal and run the following command to launch it.

```bash
php artisan tinker
```

Once inside Tinker, you can run any PHP code against your application. Try the following commands one at a time to explore the relationships you built.

```php
$entry = \App\Models\Entry::first();
$entry->comments->count();
$entry->comments->first()->user->name;

$user = \App\Models\User::first();
$user->entries->count();
$user->entries->flatMap->comments->count();
```

The first line fetches the first entry from the database. The second counts the comments on that entry using the eager-loaded collection. The third walks down two relationship levels to retrieve the comment author's name. The fourth switches to the User model and counts how many entries that user has written. The fifth is the most advanced: `flatMap->comments` takes the collection of entries, gets the comments for each, and flattens them all into a single collection so you can count the total. Type `exit` to leave Tinker when you are done.

---

## 7. Fix the Errors in Your Code

These are the most common mistakes when working with one-to-many relationships. Understanding them now will save you hours of debugging later.

**Error 1: Missing foreign key column in the migration.**

This error occurs when you define a `belongsTo` relationship in the model but forget to add the corresponding foreign key column in the migration. Eloquent cannot connect comments to entries if the `entry_id` column does not exist on the `comments` table.

```php
// Wrong: entry_id column is missing from the schema
Schema::create('comments', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->text('body');
    $table->timestamps();
});

// Correct: both foreign keys are present
Schema::create('comments', function (Blueprint $table) {
    $table->id();
    $table->foreignId('entry_id')->constrained()->cascadeOnDelete();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->text('body');
    $table->timestamps();
});
```

The wrong version defines `user_id` but omits `entry_id`, so Eloquent has no column to join on when you call `$entry->comments`. The correct version includes both foreign keys. Always check that every side of a relationship has the proper column defined before running the migration.

---

**Error 2: Accessing the relationship as a method instead of a property.**

This confusion is very common when you are learning relationships. Calling the method with parentheses and without parentheses return two completely different things, and using the wrong form in the wrong context produces unexpected results.

```php
// Wrong: method call returns a query builder, not a collection
$comments = $entry->comments();

// Correct: property access returns the collection of Comment models
$comments = $entry->comments;
```

`$entry->comments` (without parentheses) returns a Collection of Comment models that you can loop through in a Blade view. `$entry->comments()` (with parentheses) returns a `HasMany` query builder instance. You use the method form only when you need to chain additional query constraints, for example: `$entry->comments()->where('body', 'like', '%hello%')->get()`. In views, you almost always want the property form.

---

**Error 3: Forgetting `#[Fillable]` when creating related records.**

The `create()` method uses Laravel's mass assignment feature. If you do not declare any fields as fillable, Laravel throws a `MassAssignmentException` even if the value you are trying to save is otherwise valid.

```php
// Wrong: no #[Fillable] attribute defined on the Comment model
class Comment extends Model
{
}

// Correct: declare the fields that may be mass assigned
#[Fillable(['body', 'user_id'])]
class Comment extends Model
{
}
```

Without `#[Fillable]`, calling `$entry->comments()->create(['body' => 'Hello', 'user_id' => 1])` throws `MassAssignmentException: Add [body] to fillable property to allow mass assignment`. The correct version uses the `#[Fillable(['body', 'user_id'])]` attribute. `entry_id` is intentionally excluded because the relationship method `$entry->comments()->create(...)` fills it automatically. `user_id` is included because the controller passes it explicitly through `create()`, always taking its value from `$request->user()->id` rather than from request input.

---

## 8. Exercises

**Exercise 1:** Add a `hasMany` relationship from User to Comment so you can access all comments written by a user with `$user->comments`. Test it in Tinker by calling `User::first()->comments->count()`.

**Exercise 2:** Display a comment count badge next to each entry in the feed (index page). In the controller, use `Entry::withCount('comments')->latest()->get()` to load entries with a `comments_count` attribute. Display it in the view with `{{ $entry->comments_count }} comments`.

**Exercise 3:** Show a preview of each entry's most recent comment on the feed (index page). Add a `latestComment` relationship to the `Entry` model using `hasOne(Comment::class)->latestOfMany()`, eager load it in the controller, and display the latest comment's body and author under each entry. (Comment deletion is already built in the main lesson, so this exercise practices a different one-to-many tool: turning a `hasMany` into a single "latest" record.)

---

## 9. Solutions

**Solution for Exercise 1:**

Open `app/Models/User.php` and add the following method inside the class body.

```php
public function comments(): HasMany
{
    return $this->hasMany(Comment::class);
}
```

This method tells Eloquent that a user can have many comments. Eloquent looks for a `user_id` column on the `comments` table, which is already there from the migration you ran earlier. Once the method is in place, test it in Tinker by running the command below.

```php
\App\Models\User::first()->comments->count();
```

This line fetches the first user, accesses the `comments` relationship as a property (which triggers a query), and counts the resulting collection. The output is the total number of comments that user has posted.

---

**Solution for Exercise 2:**

In the `EntryController` index method, replace the existing query with the following.

```php
$entries = Entry::withCount('comments')->latest()->get();
```

The `withCount('comments')` method adds a `comments_count` attribute to each Entry model without loading all the comment records. Under the hood, Laravel runs a `SELECT COUNT(*)` subquery, which is far more efficient than loading every comment record just to call `count()` on the collection. In the Blade view, display the count alongside each entry.

```blade
<span style="color: #888; font-size: 0.85em;">{{ $entry->comments_count }} comments</span>
```

This expression reads the `comments_count` virtual attribute that `withCount` injected onto the model. No additional query runs when the view accesses it.

---

**Solution for Exercise 3:**

Open `app/Models/Entry.php` and add a `latestComment` relationship inside the class body.

```php
use Illuminate\Database\Eloquent\Relations\HasOne;

public function latestComment(): HasOne
{
    return $this->hasOne(Comment::class)->latestOfMany();
}
```

`hasOne(Comment::class)->latestOfMany()` is a one-to-one variant of the `hasMany` relationship: out of all the comments belonging to an entry, it resolves to the single most recent one (by primary key, or by a column you pass to `latestOfMany()`). This is the idiomatic way to grab "the latest related record" without loading the whole collection. Eager load it in the `EntryController` index method so the view does not run a query per entry.

```php
$entries = Entry::with('latestComment.user')->latest()->get();
```

The dotted `latestComment.user` preloads the latest comment and its author in one go. In the entry card (or index view), display the preview only when a comment exists.

```blade
@if ($entry->latestComment)
    <p style="color: #6b7280; font-size: 0.85em; margin-top: 6px;">
        Latest: "{{ $entry->latestComment->body }}" — {{ $entry->latestComment->user->name }}
    </p>
@endif
```

Because `latestComment` is a `hasOne`, `$entry->latestComment` is a single `Comment` model (or `null` when there are no comments), so the `@if` guard prevents a "property on null" error on entries without comments.

---

## Next Up - Lesson 2

In this lesson you built the foundation of relational data in Laravel. You created a migration with foreign key constraints, defined `hasMany` and `belongsTo` methods on your Eloquent models, and used those relationships to create comments through `$entry->comments()->create()`. You added a `destroy` method so a comment's author can delete it, guarded by a manual `abort(403)` ownership check (which Lesson 5 will upgrade to a Policy). You also learned the difference between accessing a relationship as a property (to get a Collection) and as a method (to get a query builder), and you protected your application with mass assignment restrictions and authentication-based authorization in the controller.

In Lesson 2, you will learn many-to-many relationships: adding tags to entries using a pivot table, and using the `attach`, `detach`, and `sync` methods to manage which tags belong to which entry.